# Playbook 03 — issues

**Trigger:** something needs doing in the platform — a **defect** (`kind: bug`, often without knowing which repo owns it), or a **known follow-up** (`kind: task`) noticed while doing something else and deferred so it isn't lost.
**Who:** anyone reports; agent and engineer diagnose together.

## Why the front door is here

The reporter usually cannot localize a symptom — the portal and the inference service are often both suspects. papa-hq is the one place that sees the whole platform (the repo map, every design, every decision), so diagnosis starts here. The fix still lands in the owning code repo.

## Steps

1. **Report.** First **check for a duplicate**: `grep` across `04-ISSUES/` — *including resolved issues* — for the symptom. The kept-forever corpus is the platform's symptom→component memory; if this symptom was seen before, link that prior issue in the new report (and if it is truly the same open problem, add to it rather than opening a second). Then mint the record with [`05-TOOLS/allocate-issue.sh`](../../05-TOOLS/allocate-issue.sh) `--symptom "<the symptom in plain terms and how it was observed>"` — it commits a minimal real report straight to `origin/main`, taking the next number atomically ([ADR 0054](../../03-DECISIONS/0054-a-tools-tree-and-allocation-and-claims-commit-directly-to-main.md); a rejected push retries against the new main, so two parallel filings cannot collide; `check-numbers` remains the CI backstop for hand-made folders). The printed ID is the work ID. Expand the report body by MR from the workspace. No localization required. Frontmatter:

   ```yaml
   ---
   kind: bug          # bug (default) | task — a task is a known follow-up, not a defect
   status: open
   priority: normal   # high | normal | low — optional, defaults to normal; triage signal only
   claimed-by:        # optional — set via 05-TOOLS/claim.sh, never by hand; intent, not started work
   claimed:           # YYYY-MM-DD, written by claim.sh alongside claimed-by
   blocked-by:        # only with status: blocked — what is being waited on: an issue/MR ref or plain prose
   ---
   ```

   A **`kind: task`** is a deferred follow-up (sync docs, rename, hand a design off). It already knows its repo, so it opens with `located-in:` set and skips straight to step 4 — no diagnosis. Optionally carry `discovered-while:` so the context you noticed it in isn't lost. The one-line way to file one mid-flow, without stopping to number folders, is the [`hits-defer`](../../.claude/skills/hits-defer/SKILL.md) skill.

   **Curate; do not dump.** File only what is worth surfacing when someone next works in that repo. Filing every minor buries the few that matter. "Deferred, not filed" is a valid, deliberate outcome — leave triaged-out polish in the trail (the review, the diagnosis, git), not in a record. A large dropped batch may warrant **one** rollup task pointing at the trail, never one record per item.

2. **Diagnose** (bugs only — a `kind: task` already knows its repo and skips to step 4). Using [`../repos.md`](../repos.md) and the design docs' `code:` fields to see the platform's shape, reproduce and localize. Record the trail — hypotheses, evidence, dead ends — in `01-diagnosis.md`. Set `status: diagnosing` while working; `status: located` with `located-in: [repo, ...]` once the owner is known.
3. **Resolve.** Before opening the workspace, **claim the issue**: `05-TOOLS/claim.sh <NNN>`. A claim is intent — "this is mine, don't start it" — recorded in the report's frontmatter on main; the draft MR ([playbook 07](07-parallel-work.md)) remains the signal that work has *started*. `claim.sh <NNN> --release` hands it back; `--steal` takes over an abandoned claim, attributed in the commit message. Open the workspace via [playbook 07](07-parallel-work.md) — the issue number is the work ID — and push to a draft MR from the first commit. When the fix spans repos, declare the landing order in this report's `lands:` block rather than as prose.
   - Implementation bug → hand the fix to the owning repo's spec-kit bugfix flow; record `fixed-by:` (PR/spec links).
   - Design gap or ambiguity → amend the design **first** ([playbook 02](02-graduation.md)), record `amended-design:`; the code fix follows the amended design via [playbook 04](04-build-handoff.md).

   **Blocked is a status, not a comment.** At any point — reported, diagnosing, or located — an issue that cannot move gets `status: blocked`, with the reason in `blocked-by:`: an issue number, an MR, an external party, a pending decision — whatever names the thing being waited on. Blocked is active, not terminal: the record stays on the triage board with its reason beside it, and a claim on it stays meaningful. When the blocker lifts, restore the status the issue was in and clear `blocked-by:`. A blocked issue with no `blocked-by:` is legal but weak — the next reader has to rediscover the blocker, so name it when you know it.
4. **Close.** Set `status: resolved` with `resolved: <YYYY-MM-DD>`, or `wontfix` with the reasoning in the report.

   ### The definition of done: delivered, not verified-by-someone-eventually

   An issue is done when its work is **built**, **released** where the repo cuts releases, **deployed** where the change only takes effect once deployed, and **validated on the install**. All four, and nothing beyond them.

   **Validated means one live read of the running system that could not succeed if the thing were broken.** Not a merge — a merged fix has repeatedly changed nothing ([043](../../04-ISSUES/043-persona-provisioning-hook-has-never-run/00-report.md): the enabling change merged and Helm still rendered no Job). Not a command that exited zero ([044](../../04-ISSUES/044-configure-nats-swallows-die-in-subshell/00-report.md)). Prefer a read whose *failure modes differ*, so a pass is evidence rather than coincidence: [027](../../04-ISSUES/027-persona-credential-linking-flow-missing/00-report.md) closed on a member request returning the registrar's **owner check**, because a missing export, a missing import, a missing grant and an unset scope each fail differently — no-responders, permissions violation, timeout — and none of them produces an owner check.

   Record that read as a `fixed-by:` entry with **`action: deploy`** and the evidence in the note, beside the `mr:`/`commit:` entries for the code ([054](../../04-ISSUES/054-persona-member-surface-built-but-not-deployed/00-report.md) is the model). `05-TOOLS/check-claims.sh` counts these as operational and does not try to resolve them to a commit — the note is the proof, so write what you actually observed, not what you ran.

   **What does not hold a record open:**

   - **A manual exercise nobody has scheduled.** "Someone should try it end to end once" is a wish, not a blocker. If the exercise genuinely matters, it is its own record with its own owner — exactly as [054](../../04-ISSUES/054-persona-member-surface-built-but-not-deployed/00-report.md) was filed against [046](../../04-ISSUES/046-personas-has-no-member-surface/00-report.md), rather than 046 being held open for a deploy.
   - **Work owned by another repo or another issue.** Name the dependency and close; do not inherit someone else's worklist.
   - **The possibility of a defect.** A defect found afterwards is a **new issue** against the repo that owns it, never a reopening. The corpus is symptom→component memory; reopening corrupts the record of when a thing was delivered.

   The reason this bar exists rather than a stricter one: an issue held open for something nobody is scheduled to do stops being a worklist item and becomes indistinguishable from undelivered work. A triage board where half the open records are actually finished is a board no one can act on — the same rot as [`05-TOOLS/check-unclaimed.sh`](../../05-TOOLS/check-unclaimed.sh) catches, arrived at from the opposite direction.

   ### Recording the refs

   Where the work spanned repos, closing is the `closes: true` entry declared in this report's own `lands:` block ([playbook 07](07-parallel-work.md) step 3): a papa-hq MR landing **after** every code MR, so each `fixed-by:` reference is already an ancestor of its repo's main and `05-TOOLS/check-claims.sh` can verify it. Closing has a declared place in the landing order rather than being remembered afterwards — the omission is the single most common way papa-hq goes stale, and [`05-TOOLS/check-unclaimed.sh`](../../05-TOOLS/check-unclaimed.sh) fails CI when a repo's main names an issue papa-hq still shows as open.

   Two ref forms bite at exactly this moment, because flipping to `resolved` is what makes `05-TOOLS/check-claims.sh` read the *whole* record rather than only the parts already claimed as done — so refs that sat unverified for months all fail at once, on the closing branch:

   - **`mr:` only where merges carry a trailer.** A `mr: "!N"` ref is verified by finding a merge commit whose message ends `See merge request <group>/<repo>!N`. A repo that fast-forwards produces no such commit, so `mr:` there is unverifiable no matter how real the MR was — `commit: <sha>` is the only honest form ([ADR 0042](../../03-DECISIONS/0042-fixed-by-is-a-verifiable-reference.md)). `papa-mcp-adapter` is the standing example, and a `lands:` block that *says so in a comment* while still using `mr:` is not protection; 027 carried exactly that for three waves.
   - **A closing entry cannot cite its own MR.** The ref must be an ancestor of `origin/main` and a commit cannot cite itself, so filling the closing entry's `mr:` in makes CI fail on the very branch carrying the closure. Leave it `mr: ""` — git history recovers it.

   Closed issues are kept forever, **in place** — they are the platform's symptom→component memory and the corpus the duplicate-check in step 1 searches. Deleting them (leaving only git history) or moving them to an archive folder both defeat that: the first makes the memory unreachable by a working-tree `grep`, the second splits the searchable corpus in two. There is no archive directory by design; the "what's open" view is generated on demand by [`hits-status`](../../.claude/skills/hits-status/SKILL.md), so resolved records never clutter it.
