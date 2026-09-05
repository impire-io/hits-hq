# 05-TOOLS

The executable rails of the process: scripts that make the playbooks' steps
one command instead of a retyped recipe, and guards that refuse the mistakes
discipline alone failed to prevent. Since decision
[0013](../03-DECISIONS/0013-issue-tracking-cutover.md) the tracker itself is
the biggest rail: filing, claiming, and closing are `hits` verbs, not scripts
here.

## What exists

| Tool | Referenced by | Job |
|---|---|---|
| [`status.sh`](status.sh) | playbook 03 | The on-demand view of what stays file-based: active research and designs in flight. Open work items come from the tracker (`hits search --status open`); the [`hits-status`](../.claude/skills/hits-status/SKILL.md) skill merges both views. |

## Historical (one-shot, already run)

| Tool | Job |
|---|---|
| [`import-issues.sh`](import-issues.sh) | The decision 0013 cutover: replayed the eleven `04-ISSUES/` records into the tracker as items 2–12. Kept as the record of exactly what the import did; its guard refuses a second run. |

Retired at cutover, recoverable from git history: `allocate-issue.sh`
(minting numbered issue folders — `hits create` prints the ID now) and
`claim.sh` (frontmatter claims — `hits claim` / `release` / `--steal` now).

## Not yet ported

The playbooks were carried over from a parent project together with tooling
that has not been ported yet. Port or rewrite each tool when the need first
arises — not speculatively (`how-we-build.md`: minimal feature). Most of
these presuppose the shared-clones-plus-worktrees layout, which does not
exist for HITS yet:

| Tool | Referenced by | Job |
|---|---|---|
| `open-workspace.sh` | playbook 07 | Create the per-work-item worktrees, one per repo, branch = work ID. hits-hq joins only when hq documents change (decision 0013). |
| `teardown-workspace.sh` | playbook 07 | Remove one work item's worktrees and branch, nothing wider |
| `sync.sh` | playbook 07 | Refresh the shared clones |
| `check-refs.sh` | playbook 07 | Verify cross-repo references to this repo's paths |
| guard hooks | playbook 07 | Refuse writes to shared clones and unscoped workspace deletes |

Re-scoped by decision 0013, tracked as a hits item (17) rather than rows
here: the planned `check-claims.sh` and `check-unclaimed.sh` guards read
issue frontmatter that no longer changes — their job (verify `fixed-by` refs
are ancestors of the owning repo's main; flag merged work whose item is still
open) moves to a tracker-side auditor built against the client API.
