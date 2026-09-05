---
name: hits-status
description: Generate the "what's open" view of the HITS project — open tracker items with claims and blockers, active research, designs in flight. Use when asked where things stand, what is open, blocked, or being worked on.
---

# hits-status — where things stand

There are **no central status files** in this repo by design: work items carry their status in the tracker, research and design docs in their frontmatter, and cross-cutting views are generated on demand (process [overview](../../../00-META/process/00-overview.md), decision [0013](../../../03-DECISIONS/0013-issue-tracking-cutover.md)).

## Steps

1. **The tracker side** — open and blocked items (there is no `hits status` command; the view composes search):

   ```
   hits --json search --status open --limit 100
   hits --json search --status blocked --limit 100
   ```

   Search renders a table of item fields and its `--json` carries each hit's full snapshot under `item` (hits main since spec 012; a binary still on v0.4.0 prints IDs and scores only — there, `hits --json get <id>` each hit). `--columns` narrows the table; `hits get <id>` fetches a trail when the notes matter. To scope to one project, use the graph instead: `hits graph neighbors <slug> --kind project`. Repeat with `--status diagnosing` and `--status located` when the full board matters.

2. **The file side** — what stays frontmatter-based:

   ```
   ./05-TOOLS/status.sh
   ```

   Active research and designs in flight.

3. Summarize for the user, ordered by what needs attention:
   - **Blocked items first**, each with the thing it is waiting on and whether anyone owns that blocker.
   - **High-priority open items**, then the rest, with who has claimed what — call out long-held claims with no recent notes.
   - **Active research** and **designs in flight** (`in-progress` before `designed`).
4. Where useful, follow into the records — an item's notes name its blocker and trail; a design's `code:` field names the owning repo.

## Do not

- Do not answer status questions from memory or a previous run — regenerate both views.
- Do not write the generated view into a file in the repo; hand-maintained status files are exactly what this replaces.
