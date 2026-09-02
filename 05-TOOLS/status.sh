#!/usr/bin/env bash
#
# The on-demand "what's open" view (playbook 03): open issues with claims and
# blockers, active research, designs in flight — read from frontmatter, never
# from a hand-maintained status file.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

fm() { # fm <file> <key> — first value of a frontmatter key, quotes stripped
  awk -v key="$2" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---"  { exit }
    $0 ~ "^"key":" {
      sub("^"key":[[:space:]]*", "")
      gsub(/^["'\'']|["'\'']$/, "")
      print; exit
    }
  ' "$1"
}

echo "== Issues (04-ISSUES) =="
open=0 resolved=0
found=""
for report in 04-ISSUES/[0-9]*/00-report.md; do
  [ -e "$report" ] || continue
  issue=$(basename "$(dirname "$report")")
  status=$(fm "$report" status); status=${status:-open}
  case "$status" in
    resolved|wontfix) resolved=$((resolved + 1)); continue ;;
  esac
  open=$((open + 1))
  kind=$(fm "$report" kind);         kind=${kind:-bug}
  priority=$(fm "$report" priority); priority=${priority:-normal}
  claimed=$(fm "$report" claimed-by)
  blocked=$(fm "$report" blocked-by)
  line=$(printf '%-66s %-5s %-11s %-7s %s' \
    "$issue" "$kind" "$status" "$priority" "${claimed:--}")
  [ -n "$blocked" ] && line="$line  [blocked by: $blocked]"
  found+="$line"$'\n'
done
if [ "$open" -gt 0 ]; then
  printf '%-66s %-5s %-11s %-7s %s\n' "issue" "kind" "status" "prio" "claimed-by"
  printf '%s' "$found"
else
  echo "(no open issues)"
fi
echo "open: $open   resolved/wontfix: $resolved"
echo

echo "== Research (01-RESEARCH) =="
active=0
for overview in 01-RESEARCH/[0-9]*/00-overview.md; do
  [ -e "$overview" ] || continue
  status=$(fm "$overview" status); status=${status:-active}
  [ "$status" = active ] || continue
  active=$((active + 1))
  echo "$(basename "$(dirname "$overview")")  ($status)"
done
[ "$active" -gt 0 ] || echo "(no active efforts)"
echo

echo "== Designs (02-DESIGN) =="
designs=0
for doc in 02-DESIGN/*.md 02-DESIGN/*/*.md; do
  [ -e "$doc" ] || continue
  [ "$(basename "$doc")" = README.md ] && continue
  status=$(fm "$doc" status)
  [ -n "$status" ] || continue
  designs=$((designs + 1))
  code=$(fm "$doc" code)
  printf '%-55s %-12s %s\n' "${doc#02-DESIGN/}" "$status" "${code:+→ $code}"
done
[ "$designs" -gt 0 ] || echo "(no design docs yet)"
