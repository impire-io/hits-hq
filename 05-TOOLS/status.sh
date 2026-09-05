#!/usr/bin/env bash
#
# The on-demand view of what stays file-based: active research and designs in
# flight — read from frontmatter, never from a hand-maintained status file.
# Work items live in the tracker since decision 0013: `hits search --status
# open` (the hits-status skill merges both views).
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
