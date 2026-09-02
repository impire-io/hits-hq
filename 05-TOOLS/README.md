# 05-TOOLS

The executable rails of the process: scripts that make the playbooks' steps one command instead of a retyped recipe, and guards that refuse the mistakes discipline alone failed to prevent.

## What exists

| Tool | Referenced by | Job |
|---|---|---|
| [`allocate-issue.sh`](allocate-issue.sh) | playbook 03 | Mint the next-numbered issue record and commit it to main; prints the ID, which is the work ID. Pushes with a renumber-retry loop once an origin exists. |
| [`claim.sh`](claim.sh) | playbook 03 | Record intent to work an issue in its frontmatter (`--release`, `--steal`). Attribution comes from `git config user.name`. |
| [`status.sh`](status.sh) | playbooks 03, 07 | The on-demand "what's open" view: open issues with claims and blockers, active research, designs in flight. |

## Not yet ported

The playbooks were carried over from a parent project together with tooling that has not been ported yet. Port or rewrite each tool when the need first arises — not speculatively (`how-we-build.md`: minimal feature). Most of these presuppose the shared-clones-plus-worktrees layout and a forge remote, neither of which exists for HITS yet:

| Tool | Referenced by | Job |
|---|---|---|
| `open-workspace.sh` | playbook 07 | Create the per-work-item worktrees, one per repo, branch = work ID |
| `teardown-workspace.sh` | playbook 07 | Remove one work item's worktrees and branch, nothing wider |
| `sync.sh` | playbook 07 | Refresh the shared clones |
| `check-refs.sh` | playbook 07 | Verify cross-repo references to this repo's paths |
| `check-claims.sh` | playbook 03 | Verify `fixed-by:` refs are ancestors of the owning repo's main |
| `check-unclaimed.sh` | playbook 03 | Fail when a repo's main names an issue still shown as open |
| guard hooks | playbooks 03, 07 | Refuse writes to shared clones and unscoped workspace deletes |
