#!/usr/bin/env bash
# import-issues.sh — one-shot replay of the 04-ISSUES corpus into the tracker
# (decision 0013). Ran once against the `personal` context on 2026-09-05 and
# kept as the record of exactly what the import did; the guard below refuses a
# second run.
#
# Each folder replays as: create (report = the symptom paragraph, links
# flattened) → provenance note (the true dates and actors — item timestamps
# stamp migration-time as the importing actor by design) → claim where the
# record was claimed → diagnosis / resolution prose as notes → the status walk
# the record shows → lands (converted to the post-cutover shape: no
# closes-true row) → close with converted refs (PRs repo-qualified; the dead
# {repo, tag} form becomes action:release).
#
# Recovery from a partial run: `hits tombstone <id> "botched import run
# (decision 0013)"` each partially imported item, then rerun. The mapping
# table in 04-ISSUES/README.md comes from the successful run's output, never
# from the expected map.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "import-issues: $*" >&2; exit 1; }
say() { echo "==> $*"; }

command -v jq >/dev/null || die "jq is required"
hits ping >/dev/null || die "no reachable hits install"

# ---- guard: one-shot --------------------------------------------------------
if hits get 2 >/dev/null 2>&1; then
  die "import already ran (item 2 exists)"
fi

# ---- readers ----------------------------------------------------------------
# fm <file> <key> — a single-line frontmatter value
fm() {
  awk -v k="$2" '
    /^---$/ { n++; next }
    n == 1 && index($0, k ":") == 1 { sub("^" k ":[ ]*", ""); print; exit }
  ' "$1"
}

# flatten_links — [text](target) becomes text
flatten_links() { sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g'; }

# report_text <file> — the symptom paragraph: after the H1, before any
# **Resolution:** or ## section, links flattened, joined to one line
report_text() {
  awk '
    /^# / { inbody = 1; next }
    !inbody { next }
    /^\*\*Resolution:\*\*/ { exit }
    /^## / { exit }
    { print }
  ' "$1" | flatten_links | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//'
}

# resolution_text <file> — everything from **Resolution:** on, links flattened
resolution_text() {
  awk '/^\*\*Resolution:\*\*/ { found = 1 } found { print }' "$1" |
    sed -E '1s/^\*\*Resolution:\*\* ?//' | flatten_links
}

# settled_shape_text <file> — 009's "## The settled shape" section
settled_shape_text() {
  awk '
    /^## The settled shape/ { found = 1; next }
    found && /^\*\*Resolution:\*\*/ { exit }
    found { print }
  ' "$1" | flatten_links
}

# deploy_note <file> — the note string of the { action: deploy, note: "…" } ref
deploy_note() {
  grep -o 'action: deploy, note: ".*" }' "$1" |
    sed -E 's/^action: deploy, note: "(.*)" }$/\1/'
}

# filed_date <path> — the date the report was first committed
filed_date() {
  git log --follow --diff-filter=A --format=%as -- "$1" | tail -1
}

# ---- replay -----------------------------------------------------------------
MAP_ROWS=()
expected=2

for dir in 04-ISSUES/[0-9][0-9][0-9]-*/; do
  folder=$(basename "$dir")
  num=${folder:0:3}
  rpt="${dir}00-report.md"
  [ -f "$rpt" ] || die "$rpt missing"

  kind=$(fm "$rpt" kind); [ -n "$kind" ] || kind=bug
  dw=$(fm "$rpt" discovered-while)
  claimed=$(fm "$rpt" claimed)
  resolved=$(fm "$rpt" resolved)
  project=$(fm "$rpt" located-in | tr -d '[]' | sed 's/,.*//')
  filed=$(filed_date "$rpt")
  report=$(report_text "$rpt")
  [ -n "$report" ] || die "$folder: empty report"

  say "create $folder"
  args=(--type "$kind")
  if [ "$kind" = task ]; then
    [ -n "$project" ] || die "$folder: task without located-in"
    args+=(--project "$project")
  fi
  if [ -n "$dw" ]; then args+=(--discovered-while "$dw"); fi
  id=$(hits --json create "${args[@]}" "$report" | jq -r .id)
  [ "$id" = "$expected" ] || die "$folder: expected item $expected, got $id"

  prov="Imported from hits-hq 04-ISSUES/$folder at cutover (decision 0013). Originally filed $filed by Daan Gerits"
  if [ -n "$claimed" ]; then prov+="; claimed $claimed by Daan Gerits"; fi
  if [ -n "$resolved" ]; then prov+="; resolved $resolved"; else prov+="; open at cutover"; fi
  prov+=". This item's created/claimed/closed timestamps and actor are migration-time artifacts — this note, the frozen folder, and the hits-hq git log are the true history."
  hits note "$id" "$prov" >/dev/null

  if [ -n "$claimed" ]; then
    say "claim $id"
    hits claim "$id" >/dev/null
  fi

  final=open
  case "$num" in
    001)
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      say "resolve $id (fix rode the record's own PR; the record carries no refs)"
      hits resolve "$id" >/dev/null
      final=resolved
      ;;
    002 | 011)
      say "item $id stays open"
      ;;
    003 | 004)
      diag="${dir}01-diagnosis.md"
      hits note "$id" "Diagnosis (imported from 01-diagnosis.md):

$(flatten_links <"$diag")" >/dev/null
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      say "walk $id: diagnosing -> located -> resolved"
      hits transition "$id" --to diagnosing >/dev/null
      hits transition "$id" --to located --project hits >/dev/null
      if [ "$num" = 003 ]; then pr="#9"; else pr="#10"; fi
      hits edit "$id" --lands "[{\"repo\":\"hits-hq\",\"pr\":\"\",\"after\":[]},{\"repo\":\"hits\",\"pr\":\"$pr\",\"after\":[\"hits-hq\"]}]" >/dev/null
      hits resolve "$id" \
        --fixed-by "pr:impire-io/hits$pr" \
        --fixed-by "action:deploy $(deploy_note "$rpt")" >/dev/null
      final=resolved
      ;;
    005 | 006 | 008)
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      case "$num" in
        005) pr="#13" ;; 006) pr="#14" ;; 008) pr="#16" ;;
      esac
      say "resolve $id (pr:impire-io/hits$pr)"
      hits resolve "$id" --fixed-by "pr:impire-io/hits$pr" >/dev/null
      final=resolved
      ;;
    007)
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      say "resolve $id (release v0.3.0 — the {repo, tag} ref form has no tracker equivalent)"
      hits resolve "$id" \
        --fixed-by "action:release hits v0.3.0 — tag pushed, tap formula bumped, assets and checksums for six platforms; RC v0.3.0-rc.1 validated on the personal Synadia context" \
        --fixed-by "pr:impire-io/hits#15" >/dev/null
      final=resolved
      ;;
    009)
      hits note "$id" "The settled shape (imported):

$(settled_shape_text "$rpt")" >/dev/null
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      say "resolve $id (pr:impire-io/hits#17, amended 02-DESIGN/hits-up.md)"
      hits edit "$id" --lands '[{"repo":"hits-hq","pr":"#4","after":[]},{"repo":"hits","pr":"#17","after":["hits-hq"]}]' >/dev/null
      hits resolve "$id" \
        --fixed-by "pr:impire-io/hits#17" \
        --amended-design "02-DESIGN/hits-up.md" >/dev/null
      final=resolved
      ;;
    010)
      hits note "$id" "Resolution (imported): $(resolution_text "$rpt")" >/dev/null
      say "resolve $id (release v0.4.0 — the {repo, tag} ref form has no tracker equivalent)"
      hits resolve "$id" \
        --fixed-by "action:release hits v0.4.0 — tag on 26476f9, assets and checksums for six platforms, tap bumped; released darwin_arm64 binary reads back 0.4.0" \
        --fixed-by "action:deploy $(deploy_note "$rpt")" >/dev/null
      final=resolved
      ;;
    *)
      die "$folder: no replay case"
      ;;
  esac

  MAP_ROWS+=("| [\`$folder\`]($folder/00-report.md) | $id | $final |")
  expected=$((expected + 1))
done

# ---- links (only where a record references another) --------------------------
say "links"
hits link 3 --type relates-to 2 >/dev/null   # 002 cites 001's folder name
hits link 5 --type relates-to 4 >/dev/null   # 004: same account, right after the 003 fix validated
hits link 8 --type relates-to 7 >/dev/null   # 007 carries 006's rework (referenced by PR)
hits link 11 --type relates-to 9 >/dev/null  # 010 delivers 008
hits link 11 --type relates-to 10 >/dev/null # 010 delivers 009

# ---- the map ----------------------------------------------------------------
echo
echo "| Folder | Tracker item | Imported as |"
echo "|---|---|---|"
for row in "${MAP_ROWS[@]}"; do echo "$row"; done
echo
say "import complete: items 2-12"
