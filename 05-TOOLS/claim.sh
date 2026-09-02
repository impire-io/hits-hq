#!/usr/bin/env bash
#
# Claim an issue — intent, not started work (playbook 03 step 3). Writes
# claimed-by/claimed into the report's frontmatter and commits to main.
#
#   claim.sh <NNN>            claim it (refused if someone else holds it)
#   claim.sh <NNN> --release  hand it back
#   claim.sh <NNN> --steal    take over an abandoned claim, attributed in the commit
set -euo pipefail

die() { echo "claim: $*" >&2; exit 1; }

NNN="" MODE=claim
while [ $# -gt 0 ]; do
  case "$1" in
    --release) MODE=release; shift ;;
    --steal)   MODE=steal; shift ;;
    *) [ -z "$NNN" ] || die "unknown argument: $1"; NNN=$1; shift ;;
  esac
done
[ -n "$NNN" ] || die "usage: claim.sh <NNN> [--release|--steal]"
NNN=$(printf '%03d' $((10#$NNN))) || die "not a number: $NNN"

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || true)
[ "$BRANCH" = main ] || die "claims are recorded on main, not '$BRANCH'"

matches=(04-ISSUES/"$NNN"-*/00-report.md)
[ -e "${matches[0]}" ] || die "no issue $NNN in 04-ISSUES/"
[ ${#matches[@]} -eq 1 ] || die "more than one folder numbered $NNN — fix that first"
REPORT=${matches[0]}
ISSUE=$(basename "$(dirname "$REPORT")")

WHO=$(git config user.name || true)
[ -n "$WHO" ] || die "git config user.name is unset"

fm() { # fm <key> — first value of a frontmatter key in the report
  awk -v key="$1" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---"  { exit }
    $0 ~ "^"key":" { sub("^"key":[[:space:]]*", ""); print; exit }
  ' "$REPORT"
}
CURRENT=$(fm claimed-by)
STATUS=$(fm status)

case "$STATUS" in
  resolved|wontfix) [ "$MODE" = release ] || die "$ISSUE is $STATUS — nothing to claim" ;;
esac

case "$MODE" in
  claim)
    if [ "$CURRENT" = "$WHO" ]; then echo "already yours: $ISSUE"; exit 0; fi
    [ -z "$CURRENT" ] \
      || die "$ISSUE is claimed by '$CURRENT' — talk to them, or --steal if truly abandoned"
    ;;
  release)
    [ -n "$CURRENT" ] || die "$ISSUE is not claimed"
    ;;
  steal)
    [ -n "$CURRENT" ] || die "$ISSUE is not claimed — plain claim will do"
    [ "$CURRENT" != "$WHO" ] || die "you already hold $ISSUE"
    ;;
esac

TMP=$(mktemp)
awk -v who="$WHO" -v date="$(date +%F)" -v mode="$MODE" '
  BEGIN { infm = 0; written = 0 }
  NR==1 && $0=="---" { infm = 1; print; next }
  infm && $0=="---" && !written {
    if (mode != "release") { print "claimed-by: " who; print "claimed: " date }
    written = 1; infm = 0; print; next
  }
  infm && (/^claimed-by:/ || /^claimed:/) { next }
  { print }
' "$REPORT" > "$TMP"
mv "$TMP" "$REPORT"

case "$MODE" in
  claim)   MSG="claim $ISSUE: $WHO" ;;
  release) MSG="release $ISSUE: $WHO" ;;
  steal)   MSG="steal $ISSUE: $WHO takes over from $CURRENT" ;;
esac
git add -- "$REPORT"
git commit -q -m "$MSG" -- "$REPORT"

if git remote get-url origin >/dev/null 2>&1; then
  git push -q origin main || die "push rejected — pull --rebase and push by hand"
fi

echo "$MODE $ISSUE ($WHO)"
