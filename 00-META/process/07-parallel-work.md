# Playbook 07 — parallel work

**Trigger:** any piece of work is about to start in a code repo or in hits-hq — rooted in a design, a tracker item, or not.
**Who:** engineers and agents alike; an agent runs the whole playbook except the merge.

Several agents run on one machine and several engineers work the same fleet. This playbook is what keeps them out of each other's working trees and makes the start of work visible to everyone else the moment it happens. The posture is [`../how-we-build.md`](../how-we-build.md#work-in-isolation-push-continuously-land-in-a-declared-order).

> **Status:** the workspace tooling and guards this playbook references — `open-workspace.sh`, `teardown-workspace.sh`, `sync.sh`, the read-only-clone and workspace-delete guards — are not yet ported ([`05-TOOLS/README.md`](../../05-TOOLS/README.md) tracks them). The playbook is written to the target state; until the rails exist, the discipline is manual.

## The clones are read-only

`~/Impire/<repo>` is shared with every other agent and engineer on the machine. It is the refresh point and the thing worktrees are cut from — never a workspace. Work happens in `.work/<work-id>/<repo>/`, and nowhere else.

| In a clone | |
|---|---|
| Reading anything | ✅ |
| `git fetch`, `git pull --ff-only`, `05-TOOLS/sync.sh` | ✅ |
| `git worktree add\|list\|remove`, `05-TOOLS/open-workspace.sh`, `05-TOOLS/teardown-workspace.sh` | ✅ |
| Editing a file, committing, switching branches, pushing, deleting | ❌ refused |

Refused, not discouraged: a guard denies those writes as a PreToolUse hook, and its refusal names the command that fixes it. It is a rail rather than a sandbox — it does not read shell redirects or `sed -i`, so it stops drift, not determination. A session that opens in a clone is told so at the start by a session notice hook.

## The work ID

One string — the branch name in **every** repo the work touches, the workspace directory name, and the PR label.

**An ID is only ever taken from a record that already exists.** Never from one the work is going to produce: a number you have not allocated yet is not yours, and minting an ID from it means renaming the branch when someone else takes it first. For tracker items the excuse is gone entirely — `hits create` returns the ID the moment the item is filed.

| Work | ID |
|---|---|
| Rooted in a tracker item — a bug, task, or improvement (decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)) | that item's bare integer ID (`17`): branch `17`, workspace `.work/17/`, label `work/17` |
| Rooted in a hits-hq research or decision record | that record's number and slug (`002-idp-token-exchange`) |
| Rooted in a code repo's spec-kit feature | that feature's number and slug (`019-search-endpoint`) |
| Anything else — a chore, a bugfix, a process change | a bare descriptive slug, no number (`work-id-rule-takes-existing-numbers`) |

A bare integer is always a tracker item — spec-kit features cannot collide with it because a feature always carries a slug. Spec-kit numbers stay per-repo; cross-repo work roots in a tracker item or an hq record, as below. An integer ID always fits GitHub's 50-char label cap, which the old folder slugs did not (the pain item 3 recorded cannot recur).

A slug is a first-class ID, not a fallback. It is still the branch name everywhere, still the workspace directory, still the PR label, and one org-wide PR query still recovers the whole piece of work. The ID buys a link to a record; where no record exists yet, there is nothing to link to and nothing is lost.

Records the work *produces* — an ADR, a tracker item — take their ID when they are written, from whatever is free at that moment. The branch never renames.

No `spec/`, `fix/`, or `feat/` prefix. The ID is the query.

**Work that spans repos must be rooted in one shared record — a tracker item or an hq record.** Per-repo spec-kit numbers differ from repo to repo, so unrooted cross-repo work has no single ID and the whole scheme collapses. If a change turns out to span repos and has no design or item behind it, file one ([playbook 03](03-issues.md)) before opening the workspace — the ID it returns becomes the work ID.

## Steps

1. **Check what is already in flight.** Before anything else:

   ```
   gh search prs --owner impire-io --state open
   ```

   Every open PR across every repo in the org — which, under this playbook, is every piece of work anyone has started. If the work is already claimed, join it instead of duplicating it.

   For item-rooted work, also check the item's claim: `hits get <id>` shows who holds it and since when. A claim without a PR yet is still someone's declared intent; talk to them before taking it, or `hits claim <id> --steal` if it is truly abandoned — the record keeps who it was taken from.

   **When the work is rooted in an hq record, confirm that record is on `origin/main`** — a PR query cannot show a number claimed by work that already merged:

   ```
   git -C ~/Impire/hits-hq fetch origin
   git -C ~/Impire/hits-hq ls-tree --name-only origin/main 01-RESEARCH/ 03-DECISIONS/
   ```

   Use the same listing when *allocating* a number for a record you are about to write — but allocate it at write time, not at workspace time, and never use it as the work ID.

2. **Open the workspace.** One command, naming the work id and the repos the work touches:

   ```
   ~/Impire/hits-hq/05-TOOLS/open-workspace.sh <work-id> <repo> [repo...]
   ```

   It creates one worktree per repo under `.work/<work-id>/`, all on branch `<work-id>`:

   ```
   ~/Impire/.work/012-oplog-compaction/
   ├── hits-projector/  worktree, branch 012-oplog-compaction
   ├── hits-api/        worktree, branch 012-oplog-compaction
   └── hits-hq/         worktree, branch 012-oplog-compaction
   ```

   **hits-hq joins the workspace only when hq documents change as part of the work** — the item, its `lands` block, and its close live in the tracker, not in a commit (decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)). **Name only the repos the work actually touches**; a repo you do not need gets no worktree.

   **Needing another repo later is the same command run again**, with the new repo named. Repos already open are left alone.

   Where the branch already exists on `origin`, the worktree is cut from it and tracks it — joining work someone else has claimed rather than forking beside it.

   What the script does that a hand-typed `worktree add` keeps getting wrong: it derives the path instead of accepting one, so the workspace cannot land inside a clone or beside `.work/`; it forces the branch name to equal the work id, so the one string stays one string; and it runs `branch --unset-upstream` on a branch cut from main. That last one matters — `worktree add -b <id> … origin/main` leaves the branch *tracking* `origin/main`, so a plain `git push` in that worktree targets main, refused only because git's `simple` default requires matching branch names. One config difference away from pushing to main by accident.

   A harness-provided worktree is an acceptable equivalent for **single-repo** work, provided the branch is renamed to the work ID.

3. **Declare the landing order — only if the work spans repos.** The block lives where the root lives: on a tracker item, `hits edit <id> --lands '<json>'`; on a design-rooted build, the design doc's frontmatter ([playbook 04](04-build-handoff.md)). `pr` stays empty until each PR exists:

   ```json
   [
     { "repo": "hits-projector", "pr": "", "after": [] },
     { "repo": "hits-api",       "pr": "", "after": ["hits-projector"] },
     { "repo": "hits-mcp",       "pr": "", "after": ["hits-api"] }
   ]
   ```

   The entry shape is convention, not validated by the server — a typo is stored silently, so read the block back after setting it. Where the work is rooted in a design amendment, hits-hq leads the block (`after: []`) — the amendment is what the code is built against. And the item must still be **open** whenever the block is set or updated: the tracker refuses edits on terminal items, so fill PR numbers back in as they open, never after the close.

   **Closing is a tracker op, not a landing entry.** The old process ended every cross-repo block with a `closes: true` hits-hq entry, because closing the record was itself a commit to hits-hq; that row is gone (decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)). The last entry is simply the last repo the code lands in. Once it merges — and the deploy/validation read is done where [playbook 03](03-issues.md) requires one — the claimant runs `hits resolve <id>`, citing every landed PR. The close keeps its declared owner (whoever holds the claim) and its declared moment (after the final merge), which is what `closes: true` existed to force. What nothing forces anymore: a merged fix with a still-open item no longer fails CI — the frontmatter checker died with the file-based process, and its tracker-side replacement does not exist yet (item 17). Until it does, the close is the claimant's last act, and skipping it is exactly the rot this playbook exists to prevent: in the parent project, four issues were found fixed-but-still-open on a single afternoon, each by hand.

   Single-repo work gets no block, and the item still closes by the same rule: merge, validate, resolve.

4. **Push the first commit and open the draft PR.** Do this as early as there is anything to push; the draft PR is the claim, not the finish line.

   ```
   git push -u origin <work-id>
   gh pr create --draft \
     --title "<work-id>: <what it does>" \
     --label "work/<work-id>" \
     --body "hits: <item id — or the hq record path where that is the root>
   Blocked by: <predecessor PR url, or none>"
   ```

   (Create the label first if it does not exist yet: `gh label create "work/<work-id>"`.) Fill the PR number back into the item's `lands` block (`hits edit <id> --lands ...`) while the item is still open.

5. **Keep pushing.** Commit at every green checkpoint and push every commit — work never sits local overnight. Refresh from `origin/main` daily and before step 6; `git push --force-with-lease` is expected on a work branch after a rebase, and never used on main.

6. **Mark it ready.** The agent does this itself — it is the last step of the work, not a courtesy left to the reviewer. The moment **both** hold:
   - the blocking quality gate is green — `make fmt && make test && make lint`, race detector where it applies ([`../how-we-build.md`](../how-we-build.md#spec-driven-constitution-governed-development));
   - every predecessor in the item's `after:` list has merged,

   flip it:

   ```
   gh pr ready
   ```

   Draft and ready are the only two signals the reviewer gets. Draft says "not yet mergeable — don't spend review on this"; ready says "read it and merge it". A finished PR left in draft sends the first signal about the second state, and the human has to re-derive readiness by inspecting the branch — the one job the flag exists to spare them. Never flip earlier than the two conditions above, and never leave a finished PR sitting in draft.

7. **A human merges.** An agent never merges. Where a `lands:` order exists, merge in that order.

8. **Tear down.** Once every PR of the work item has merged:

   ```
   ~/Impire/hits-hq/05-TOOLS/teardown-workspace.sh <work-id>
   ```

   It removes that item's worktrees, deletes the local branch, and removes `~/Impire/.work/<work-id>/` — nothing wider. `--dry-run` prints what it would do; `--delete-remote` also deletes the branch on origin, which is off by default because the branch may be the only copy of an unmerged idea. A leftover workspace reads as work in flight.

   **`.work/` is shared, and a delete that is not scoped to one work id destroys other people's work.** Every agent and engineer on the machine keeps their worktrees beside yours. `rm -rf .work`, `rm -rf .work/*`, and any loop over `.work/*/` reach across all of them, including anything they have not committed — this has happened, which is why the teardown script and a PreToolUse guard refusing those forms belong to the rails. If you tear down by hand, name the one directory and nothing above it.

   If the work moved or renamed anything hits-hq publishes, run `./05-TOOLS/check-refs.sh` from hits-hq first — sibling repos cite hits-hq by relative path and those links break silently. hits-hq CI runs it too, so this is a courtesy, not the safety net.

## Do not

- Do not work in `~/Impire/<repo>` directly — that clone is shared with every other agent on the machine, and writing to it is refused rather than merely discouraged.
- Do not compose a `worktree add` by hand when `05-TOOLS/open-workspace.sh` does it. Every workspace found at the wrong level, and every branch whose name was not its work id, came from retyping this step.
- Do not hold a finished branch back from being pushed because it "isn't ready". Push it as a draft; that is what draft is for.
- Do not flip to ready with an unmerged predecessor, and do not merge as an agent.
- Do not leave a finished PR in draft. Once the gate is green and every predecessor is in, marking it ready is the agent's own closing move — a human should only ever read and merge.
- Do not record cross-repo ordering as prose or as a note on the item. It goes in the item's `lands` block.
- Do not merge the last PR and walk away. Resolving the item — validation read done, refs cited — is part of the work, not an afterthought; nothing fails CI for you anymore when you skip it.
