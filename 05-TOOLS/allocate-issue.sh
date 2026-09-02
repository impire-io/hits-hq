#!/usr/bin/env bash
#
# Mint the next-numbered issue record in 04-ISSUES/ and commit it to main.
# Playbook 03 step 1: the printed ID is the work ID.
#
#   allocate-issue.sh --symptom "<the symptom in plain terms>" [options]
#
# Options:
#   --symptom "<text>"        required — the symptom (bug) or the follow-up (task)
#   --kind bug|task           default: bug
#   --slug <slug>             override the slug derived from the symptom
#   --located-in <repo>       required for tasks; repeatable (a task knows its repo)
#   --discovered-while "<t>"  tasks, optional — the context it was noticed in
#   --priority high|normal|low  optional; defaults to normal (omitted from frontmatter)
#
# Commits straight to main. If an origin remote exists, pushes with a
# fetch-renumber-retry loop so two parallel filings cannot collide.
set -euo pipefail

die() { echo "allocate-issue: $*" >&2; exit 1; }

KIND=bug SYMPTOM="" SLUG="" PRIORITY="" DISCOVERED=""
LOCATED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --symptom)          SYMPTOM=${2:?}; shift 2 ;;
    --kind)             KIND=${2:?}; shift 2 ;;
    --slug)             SLUG=${2:?}; shift 2 ;;
    --located-in)       LOCATED+=("${2:?}"); shift 2 ;;
    --discovered-while) DISCOVERED=${2:?}; shift 2 ;;
    --priority)         PRIORITY=${2:?}; shift 2 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$SYMPTOM" ] || die "--symptom is required"
case "$KIND" in bug|task) ;; *) die "--kind must be bug or task" ;; esac
if [ "$KIND" = task ] && [ ${#LOCATED[@]} -eq 0 ]; then
  die "a task opens with --located-in set (playbook 03)"
fi
case "$PRIORITY" in ""|high|normal|low) ;; *) die "--priority must be high, normal or low" ;; esac

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || true)
[ "$BRANCH" = main ] || die "records are minted on main, not '$BRANCH'"

if [ -z "$SLUG" ]; then
  SLUG=$(printf '%s' "$SYMPTOM" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  if [ ${#SLUG} -gt 60 ]; then
    # truncate on a word boundary, not mid-word
    SLUG=$(printf '%s' "$SLUG" | cut -c1-60 | sed -E 's/-[^-]*$//; s/-+$//')
  fi
  [ -n "$SLUG" ] || die "could not derive a slug; pass --slug"
fi

HAVE_ORIGIN=""
if git remote get-url origin >/dev/null 2>&1; then
  HAVE_ORIGIN=yes
  git fetch origin main >/dev/null 2>&1 || true
fi

next_number() {
  local last
  last=$({
    ls -d 04-ISSUES/[0-9][0-9][0-9]-* 2>/dev/null || true
    git ls-tree --name-only main -- 04-ISSUES/ 2>/dev/null || true
    git ls-tree --name-only origin/main -- 04-ISSUES/ 2>/dev/null || true
  } | sed -nE 's|^04-ISSUES/([0-9]{3})-.*|\1|p' | sort -n | tail -1)
  printf '%03d' $((10#${last:-0} + 1))
}

write_report() { # $1 = issue dir
  {
    echo "---"
    echo "kind: $KIND"
    echo "status: open"
    [ -n "$PRIORITY" ] && [ "$PRIORITY" != normal ] && echo "priority: $PRIORITY"
    if [ ${#LOCATED[@]} -gt 0 ]; then
      printf 'located-in: [%s]\n' "$(IFS=', '; echo "${LOCATED[*]}")"
    fi
    [ -n "$DISCOVERED" ] && echo "discovered-while: $DISCOVERED"
    echo "---"
    echo
    echo "# ${1#04-ISSUES/}"
    echo
    echo "$SYMPTOM"
  } > "$1/00-report.md"
}

NNN=$(next_number)
DIR="04-ISSUES/$NNN-$SLUG"
[ -e "$DIR" ] && die "$DIR already exists"
mkdir -p "$DIR"
write_report "$DIR"
git add -- "$DIR"
git commit -q -m "issue $NNN: $SLUG" -- "$DIR"

if [ -n "$HAVE_ORIGIN" ]; then
  for _ in 1 2 3; do
    git push -q origin main 2>/dev/null && break
    # Rejected: someone else advanced main. Rebase, and renumber if our number
    # was taken in the meantime.
    git fetch -q origin main
    git rebase -q origin/main || die "rebase onto origin/main failed; resolve by hand"
    taken=$(git ls-tree --name-only origin/main -- "04-ISSUES/" \
      | sed -nE "s|^04-ISSUES/($NNN)-.*|\1|p")
    if [ -n "$taken" ]; then
      NEW=$(next_number)
      NEWDIR="04-ISSUES/$NEW-$SLUG"
      git mv "$DIR" "$NEWDIR"
      git commit -q --amend -m "issue $NEW: $SLUG"
      NNN=$NEW DIR=$NEWDIR
    fi
  done
fi

echo "$NNN-$SLUG"
