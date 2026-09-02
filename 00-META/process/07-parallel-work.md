# Playbook 07 — parallel work

**Trigger:** any piece of work is about to start in a code repo or in papa-hq — rooted in a design or issue, or not.
**Who:** engineers and agents alike; an agent runs the whole playbook except the merge.

Several agents run on one machine and several engineers work the same fleet. This playbook is what keeps them out of each other's working trees and makes the start of work visible to everyone else the moment it happens. The posture is [`../how-we-build.md`](../how-we-build.md#work-in-isolation-push-continuously-land-in-a-declared-order); the decisions are [ADR 0038](../../03-DECISIONS/0038-isolated-workspaces-and-continuous-mr-flow.md) and [ADR 0049](../../03-DECISIONS/0049-clones-are-read-only-and-workspaces-are-opened-by-command.md).

## The clones are read-only

`~/Work/PAPA/<repo>` is shared with every other agent and engineer on the machine. It is the refresh point and the thing worktrees are cut from — never a workspace. Work happens in `.work/<work-id>/<repo>/`, and nowhere else.

| In a clone | |
|---|---|
| Reading anything | ✅ |
| `git fetch`, `git pull --ff-only`, [`05-TOOLS/sync.sh`](../../05-TOOLS/sync.sh) | ✅ |
| `git worktree add\|list\|remove`, [`05-TOOLS/open-workspace.sh`](../../05-TOOLS/open-workspace.sh), [`05-TOOLS/teardown-workspace.sh`](../../05-TOOLS/teardown-workspace.sh) | ✅ |
| Editing a file, committing, switching branches, pushing, deleting | ❌ refused |

Refused, not discouraged: [`05-TOOLS/guard-readonly-clone.py`](../../05-TOOLS/guard-readonly-clone.py) denies those writes as a PreToolUse hook, and its refusal names the command that fixes it. It is a rail rather than a sandbox — it does not read shell redirects or `sed -i`, so it stops drift, not determination. A session that opens in a clone is told so at the start by [`05-TOOLS/session-workspace-notice.sh`](../../05-TOOLS/session-workspace-notice.sh).

## The work ID

One string — the branch name in **every** repo the work touches, the workspace directory name, and the MR label.

**An ID is only ever taken from a record that already exists.** Never from one the work is going to produce: a number you have not allocated yet is not yours, and minting an ID from it means renaming the branch when someone else takes it first ([ADR 0041](../../03-DECISIONS/0041-work-ids-come-from-records-that-already-exist.md)).

| Work | ID |
|---|---|
| Rooted in a papa-hq design or issue | that record's number and slug (`018-observe-streams`) |
| Rooted in a code repo's spec-kit feature | that feature's number and slug (`019-whoami-context`) |
| Anything else — a chore, a bugfix, a process change | a bare descriptive slug, no number (`work-id-rule-takes-existing-numbers`) |

A slug is a first-class ID, not a fallback. It is still the branch name everywhere, still the workspace directory, still the MR label, and `glab mr list --group` still recovers the whole piece of work. The number buys a link to a record; where no record exists yet, there is nothing to link to and nothing is lost.

Records the work *produces* — an ADR, an issue — take their number when they are written, from whatever is free at that moment. The branch never renames.

No `spec/`, `fix/`, or `feat/` prefix. The ID is the query.

**Work that spans repos must be rooted in papa-hq.** Per-repo spec-kit numbers differ from repo to repo, so unrooted cross-repo work has no single ID and the whole scheme collapses. If a change turns out to span repos and has no design or issue behind it, open one ([playbook 03](03-issues.md)) before opening the workspace — that number becomes the work ID.

## Steps

1. **Check what is already in flight.** Before anything else:

   ```
   glab mr list --group data-and-insights/papa-platform
   ```

   Every open MR across every repo in the group — which, under this playbook, is every piece of work anyone has started. If the work is already claimed, join it instead of duplicating it.

   For issue-rooted work, also check the report's `claimed-by:` (visible in `05-TOOLS/status.sh`) — a claim without an MR yet is still someone's declared intent; talk to them before taking it, or `05-TOOLS/claim.sh <NNN> --steal` if it is truly abandoned.

   **When the work is rooted in an existing record, confirm that record is on `origin/main`** — an MR query cannot show a number claimed by work that already merged:

   ```
   git -C ~/Work/PAPA/papa-hq fetch origin
   git -C ~/Work/PAPA/papa-hq ls-tree --name-only origin/main 03-DECISIONS/ 04-ISSUES/
   ```

   Use the same listing when *allocating* a number for a record you are about to write — but allocate it at write time, not at workspace time, and never use it as the work ID.

2. **Open the workspace.** One command, naming the work id and the repos the work touches:

   ```
   ~/Work/PAPA/papa-hq/05-TOOLS/open-workspace.sh <work-id> <repo> [repo...]
   ```

   It creates one worktree per repo under `.work/<work-id>/`, all on branch `<work-id>`:

   ```
   ~/Work/PAPA/.work/018-observe-streams/
   ├── papa-ops/        worktree, branch 018-observe-streams
   ├── papa-gateway/    worktree, branch 018-observe-streams
   └── papa-hq/         worktree, branch 018-observe-streams
   ```

   **papa-hq is always included, named or not** — it holds the work item, the `lands:` block, and the edit that closes the record. **Name only the code repos the work actually touches**; a repo you do not need gets no worktree.

   **Needing another repo later is the same command run again**, with the new repo named. Repos already open are left alone.

   Where the branch already exists on `origin`, the worktree is cut from it and tracks it — joining work someone else has claimed rather than forking beside it.

   What the script does that a hand-typed `worktree add` keeps getting wrong: it derives the path instead of accepting one, so the workspace cannot land inside a clone or beside `.work/`; it forces the branch name to equal the work id, so the one string stays one string; and it runs `branch --unset-upstream` on a branch cut from main. That last one matters — `worktree add -b <id> … origin/main` leaves the branch *tracking* `origin/main`, so a plain `git push` in that worktree targets main, refused only because git's `simple` default requires matching branch names. One config difference away from pushing to main by accident.

   A harness-provided worktree is an acceptable equivalent for **single-repo** work, provided the branch is renamed to the work ID.

3. **Declare the landing order — only if the work spans repos.** Add a `lands:` block to the papa-hq work item's frontmatter, `mr:` empty until each MR exists:

   ```yaml
   lands:
     - { repo: papa-ops,       mr: "", after: [] }
     - { repo: papa-tool-echo, mr: "", after: [papa-ops] }
     - { repo: papa-gateway,   mr: "", after: [papa-tool-echo] }
   ```

   **The last entry is always papa-hq, and it is the one that closes the record.** papa-hq appears twice in a cross-repo block, doing two different jobs:

   ```yaml
   lands:
     - { repo: papa-ops,       mr: "", after: [] }
     - { repo: papa-tool-echo, mr: "", after: [papa-ops] }
     - { repo: papa-gateway,   mr: "", after: [papa-tool-echo] }
     - { repo: papa-hq,        mr: "", after: [papa-gateway], closes: true }
   ```

   Where the work is rooted in a design amendment, papa-hq also leads the block (`after: []`) — the amendment is what the code is built against. The `closes: true` entry is a separate, later MR: it sets `status: resolved` and fills in `fixed-by:`.

   It must land **after** every code MR, and the constraint is mechanical rather than stylistic. A `fixed-by:` reference has to be an ancestor of that repo's `origin/main` to be verifiable ([ADR 0042](../../03-DECISIONS/0042-fixed-by-is-a-verifiable-reference.md)); a commit cannot cite itself, and a claim written before its fix merges is one `05-TOOLS/check-claims.sh` rejects.

   Without that entry the closing step belongs to nobody. papa-hq's only MR merged days before the work finished, its worktree is stale or already torn down, and recording completion becomes a job someone has to decide to start from nothing. That is where papa-hq measurably rots: issues 013, 014, 025 and 046 were all found fixed-but-still-open on a single afternoon, each by hand. [`05-TOOLS/check-unclaimed.sh`](../../05-TOOLS/check-unclaimed.sh) now fails CI on the strong form of it, but a check that catches the omission is a poorer instrument than a step that prevents it.

   Single-repo work gets no block — the MR is its own record, and carries the fix and the closing edit together.

4. **Push the first commit and open the draft MR.** Do this as early as there is anything to push; the draft MR is the claim, not the finish line.

   ```
   glab mr create --draft --push --yes \
     --label "work/<work-id>" \
     --title "<work-id>: <what it does>" \
     --description "papa-hq: <path/to/work-item.md>
   Blocked by: <predecessor MR url, or none>"
   ```

   Fill the MR number back into the work item's `lands:` block.

5. **Keep pushing.** Commit at every green checkpoint and push every commit — work never sits local overnight. Refresh from `origin/main` daily and before step 6; `git push --force-with-lease` is expected on a work branch after a rebase, and never used on main.

6. **Mark it ready.** The agent does this itself — it is the last step of the work, not a courtesy left to the reviewer. The moment **both** hold:
   - the blocking quality gate is green — `make fmt && make test && make lint`, race detector where it applies ([decision 0010](../../03-DECISIONS/0010-spec-driven-constitution-governed-development.md));
   - every predecessor in the item's `after:` list has merged,

   flip it:

   ```
   glab mr update --ready
   ```

   Draft and ready are the only two signals the reviewer gets. Draft says "not yet mergeable — don't spend review on this"; ready says "read it and merge it". A finished MR left in draft sends the first signal about the second state, and the human has to re-derive readiness by inspecting the branch — the one job the flag exists to spare them. Never flip earlier than the two conditions above, and never leave a finished MR sitting in draft.

7. **A human merges.** An agent never merges. Where a `lands:` order exists, merge in that order.

8. **Tear down.** Once every MR of the work item has merged:

   ```
   ~/Work/PAPA/papa-hq/05-TOOLS/teardown-workspace.sh <work-id>
   ```

   It removes that item's worktrees, deletes the local branch, and removes `~/Work/PAPA/.work/<work-id>/` — nothing wider. `--dry-run` prints what it would do; `--delete-remote` also deletes the branch on origin, which is off by default because the branch may be the only copy of an unmerged idea. A leftover workspace reads as work in flight.

   **`.work/` is shared, and a delete that is not scoped to one work id destroys other people's work.** Every agent and engineer on the machine keeps their worktrees beside yours. `rm -rf .work`, `rm -rf .work/*`, and any loop over `.work/*/` reach across all of them, including anything they have not committed — this has happened, which is why the script exists and why a [PreToolUse hook](../../.claude/settings.json) refuses those forms outright ([`05-TOOLS/guard-workspace-delete.py`](../../05-TOOLS/guard-workspace-delete.py), `--self-test` covers the cases). If you tear down by hand, name the one directory and nothing above it.

   If the work moved or renamed anything papa-hq publishes, run `./05-TOOLS/check-refs.sh` from papa-hq first — sibling repos cite papa-hq by relative path and those links break silently ([ADR 0039](../../03-DECISIONS/0039-papa-hq-ci-verifies-cross-repo-references.md)). papa-hq CI runs it too, so this is a courtesy, not the safety net.

## Do not

- Do not work in `~/Work/PAPA/<repo>` directly — that clone is shared with every other agent on the machine, and writing to it is refused rather than merely discouraged.
- Do not compose a `worktree add` by hand when `05-TOOLS/open-workspace.sh` does it. Every workspace found at the wrong level, and every branch whose name was not its work id, came from retyping this step.
- Do not hold a finished branch back from being pushed because it "isn't ready". Push it as a draft; that is what draft is for.
- Do not flip to ready with an unmerged predecessor, and do not merge as an agent.
- Do not leave a finished MR in draft. Once the gate is green and every predecessor is in, marking it ready is the agent's own closing move — a human should only ever read and merge.
- Do not record cross-repo ordering as prose in a report. It goes in `lands:`.
- Do not leave a cross-repo `lands:` block without a trailing `closes: true` papa-hq entry. Work whose last act is a code merge closes nothing in papa-hq, and no one comes back for it.
