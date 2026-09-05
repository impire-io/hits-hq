# Playbook 03 — issues

**Trigger:** something needs doing in the platform — a **defect** (`bug`, often without knowing which repo owns it), a **known follow-up** (`task`) noticed while doing something else and deferred so it isn't lost, or a **deliberate betterment** (`improvement`).
**Who:** anyone reports; agent and engineer diagnose together.

Items live in the running HITS install — the platform tracks its own issues (decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)). This playbook states the process rules the tracker does not enforce and names the CLI verb for each step; `hits <command> -h` is authoritative for flags, and the `hits` plugin's commands (`hits:file`, `hits:work`, `hits:resolve`, …) script the same flows over the MCP server. The pre-cutover records are archived long-form in [`04-ISSUES/`](../../04-ISSUES/), frozen, with the folder→item map in its README.

## Why the front door is the tracker, and diagnosis still starts here

The reporter usually cannot localize a symptom — the client API and the projector are often both suspects. The record lives in the tracker; the map lives in this repo: [`repos.md`](../repos.md) is the hand-mirrored source of the tracker's project registry, the design docs' `code:` fields say who owns what, and diagnosis conclusions that change designs still land here. The fix still lands in the owning code repo.

If the install is unreachable, capture the symptom in the session trail and file on recovery — the tracker cannot file its own outage.

## Steps

1. **Report.** First **check for a duplicate**: `hits search "<symptom terms>"` — the corpus is one query wide, resolved items and the imported pre-cutover records included; it is the platform's symptom→component memory. (`hits semantic` adds the check by meaning once the embedding provider is configured — item 14 tracks the gap.) A near-match is a link, not a second filing: if it is truly the same open problem, add a note to the existing item; if it is related but distinct, file and `hits link <new> --type relates-to <prior>`.

   Then file:

   ```
   hits create --type bug "<the symptom in plain terms and how it was observed>"
   ```

   The report is the **symptom, not a diagnosis** — it is set at creation and never edited, so what was actually observed is exactly what the record keeps. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal. The printed integer ID names the item forever, and it is the **work ID** ([playbook 07](07-parallel-work.md)) if anyone picks the work up.

   A **task** is a deferred follow-up (sync docs, rename, hand a design off). It already knows its repo, so it files with `--project <slug>` — the tracker enforces this — and skips straight to step 4: no diagnosis. An **improvement** takes either path, by whether its owner is known at filing. The one-line way to file a task mid-flow is the [`hits-defer`](../../.claude/skills/hits-defer/SKILL.md) skill.

   **Curate; do not dump.** File only what is worth surfacing when someone next works in that repo. Filing every minor buries the few that matter. "Deferred, not filed" is a valid, deliberate outcome — leave triaged-out polish in the trail (the review, the diagnosis, git), not in an item. A large dropped batch may warrant **one** rollup task pointing at the trail, never one item per entry.

2. **Diagnose** (bugs only — a task already knows its repo and skips to step 4). Using [`../repos.md`](../repos.md) and the design docs' `code:` fields to see the platform's shape, reproduce and localize. **The trail is notes**: append hypotheses, evidence, and dead ends with `hits note <id> "<text>"` *as you find them*, not as a write-up afterwards — notes are append-only history, and a dead end recorded is a dead end nobody re-walks. Move the status as reality changes: `hits transition <id> --to diagnosing` while working, `--to located --project <slug>` once the owner is known (registered slugs only).

3. **Resolve.** Before opening the workspace, **claim the item**: `hits claim <id>`. A claim is intent — "this is mine, don't start it"; the draft PR ([playbook 07](07-parallel-work.md)) remains the signal that work has *started*. `hits release <id>` hands it back — note first what was tried and ruled out, so the release is a handoff rather than an abandonment. `hits claim <id> --steal` takes over a truly abandoned claim; the record keeps who it was taken from. Open the workspace via playbook 07 — the item ID is the work ID — and push to a draft PR from the first commit. When the fix spans repos, declare the landing order in the item's `lands` block (`hits edit <id> --lands '<json>'`, playbook 07 owns the shape) rather than as prose or a note.
   - Implementation bug → hand the fix to the owning repo's spec-kit bugfix flow; the refs ride the close (step 4).
   - Design gap or ambiguity → amend the design **first** ([playbook 02](02-graduation.md)) and record it with `--amended-design` on the close; the code fix follows the amended design via [playbook 04](04-build-handoff.md).

   **Blocked is a status the record keeps for you.** At any point — reported, diagnosing, or located — an item that cannot move gets `hits block <id> --by "<what>"`: an item ref, a PR, an external party, a pending decision — whatever names the thing being waited on. Blocked is active, not terminal: the item stays on the board with its reason beside it, and a claim on it stays meaningful. The record remembers the status it interrupted, and `hits unblock <id>` restores exactly that status — no human memory required, never a manual transition. A block without `--by` is legal but weak — name the blocker when you know it, and if the blocker is itself a tracked item, link it `relates-to` too.

4. **Close.** Append the closing reasoning as a note, then `hits resolve <id>` carrying the refs — or `hits wontfix <id>` with the reasoning noted first: too costly, obsolete, working as intended, superseded (link the successor). Closing stamps the date, and **terminal is terminal by machine rule** — the tracker refuses every further transition. A defect found afterwards is a **new item** against the repo that owns it, never a reopening: the corpus is symptom→component memory, and reopening would corrupt the record of when a thing was delivered.

   ### The definition of done: delivered, not verified-by-someone-eventually

   An item is done when its work is **built**, **released** where the repo cuts releases, **deployed** where the change only takes effect once deployed, and **validated on the install**. All four, and nothing beyond them.

   **Validated means one live read of the running system that could not succeed if the thing were broken.** Not a merge — the parent project repeatedly saw a merged fix change nothing on the running install. Not a command that exited zero. Prefer a read whose *failure modes differ*, so a pass is evidence rather than coincidence: when each missing piece — a missing export, a missing import, an unset scope — fails differently (no-responders, permissions violation, timeout), a read that produces the one correct answer rules them all out at once.

   Record that read as a `fixed-by` entry with **`action:deploy`** and the evidence in the note, beside the `pr:`/`commit:` entries for the code. The note is the proof — write what you actually observed, not what you ran.

   **What does not hold a record open:**

   - **A manual exercise nobody has scheduled.** "Someone should try it end to end once" is a wish, not a blocker. If the exercise genuinely matters, it is its own item with its own owner — filed against the delivered one, rather than the delivered one being held open for it.
   - **Work owned by another repo or another item.** Name the dependency and close; do not inherit someone else's worklist.
   - **The possibility of a defect.** A defect found afterwards is a **new item**, never a reopening — and here the tracker enforces the rule this playbook used to carry alone.

   The reason this bar exists rather than a stricter one: an item held open for something nobody is scheduled to do stops being a worklist entry and becomes indistinguishable from undelivered work. A board where half the open items are actually finished is a board no one can act on.

   ### Recording the refs

   Refs ride the closing op only — `hits resolve <id> --fixed-by "<form>" [--amended-design <doc>]` — in three forms: `pr:`, `commit:`, `action:`.

   - **Qualify PR refs with the repo:** `pr:impire-io/hits#9`. The ref form carries no repo field of its own, and once more than one project is in play a bare `#9` answers nothing.
   - **`pr:` only where merges reference the PR.** A PR ref is verifiable by finding a commit on main whose message references the pull request — GitHub's merge commits (`Merge pull request #N …`) and squash merges (`… (#N)`) both qualify. A repo that fast-forwards or rebase-merges without that reference produces no such commit, so `pr:` there is unverifiable no matter how real the PR was — `commit: <sha>` is the only honest form.
   - **Releases are `action:release <product> <version>`** with the evidence in the note — there is no tag ref form, so the tag is named in prose.
   - **Deploy validation is `action:deploy`** with what you actually observed, as above.

   Nothing verifies these refs today: the planned frontmatter checkers died with the file-based process (decision 0013), and their replacement — a tracker-side auditor against the client API — does not exist yet (item 17). Until it does, the honesty is yours.

   **Closing is a tracker op, not a landing entry.** Where the work spanned repos, the close happens after the last PR in the item's `lands` block merges and the validation read is done — [playbook 07](07-parallel-work.md) owns the ordering and the closing rule.

   Closed items are kept forever in the tracker, searchable beside open ones — one query covers the whole memory, and the "what's open" view ([`hits-status`](../../.claude/skills/hits-status/SKILL.md)) never shows them. The pre-cutover corpus is additionally archived long-form in [`04-ISSUES/`](../../04-ISSUES/), frozen in place.
