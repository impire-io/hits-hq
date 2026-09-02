---
name: hits-status
description: Generate the "what's open" view of the HITS project — open issues with claims and blockers, active research, designs in flight. Use when asked where things stand, what is open, blocked, or being worked on.
---

# hits-status — where things stand

There are **no central status files** in this repo by design: status lives in each record's frontmatter, and cross-cutting views are generated on demand (process [overview](../../../00-META/process/00-overview.md)).

## Steps

1. Run the generator:

   ```
   ./05-TOOLS/status.sh
   ```

2. Summarize the output for the user, ordered by what needs attention:
   - **Blocked issues first**, each with the thing it is waiting on (`blocked-by:`).
   - **High-priority open issues**, then the rest, with who has claimed what.
   - **Active research** and **designs in flight** (`in-progress` before `designed`).
3. Where useful, follow up into the records themselves — a blocked issue's report names the blocker; a design's `code:` field names the owning repo.

## Do not

- Do not answer status questions from memory or a previous run — regenerate.
- Do not write the generated view into a file in the repo; hand-maintained status files are exactly what this replaces.
