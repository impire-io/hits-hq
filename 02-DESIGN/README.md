# 02-DESIGN

The designs of the HITS platform: what we are building and how the pieces fit. Written when research graduates ([playbook 02](../00-META/process/02-graduation.md)); handed to code repos through [playbook 04](../00-META/process/04-build-handoff.md).

## Rules

- **Prose and diagrams only, no code.** Implementation lives in the code repos; a design describes contracts and shape.
- Every design must be traceable back to [`00-META`](../00-META/) — mission, context, and the postures in `how-we-build.md`.
- Significant changes are recorded in [`03-DECISIONS`](../03-DECISIONS/) first; the design doc follows the decision.
- A retracted design is never deleted: set `status: abandoned` and put a banner line at the top. The doc stays.

## Frontmatter schema

```yaml
---
status: designed   # designed | in-progress | implemented | abandoned
code:              # owning repo(s) from 00-META/repos.md — set at build handoff, absent before
updated:           # YYYY-MM-DD — changes only on implementation-status flips, not text edits
lands:             # cross-repo builds only: the ordered landing block (playbook 07)
---
```

`status: implemented` is claimed only when the design's core contract runs on the owning repo's **main branch** — defensible from main, not from intent.
