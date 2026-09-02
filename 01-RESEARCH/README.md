# 01-RESEARCH

Ideas, technologies, and approaches being investigated before they are committed to design. Worked through [playbook 01](../00-META/process/01-research.md); closed through [playbook 02](../00-META/process/02-graduation.md).

## Structure

One folder per effort, numbered with the next free `NNN`:

```
NNN-descriptive-name/
├── 00-overview.md    what is being investigated, why, what it touches
└── ...               anything goes: notes, surveys, option analyses, draft designs
```

## Frontmatter schema (`00-overview.md`)

```yaml
---
status: active   # active | graduated | concluded-artifact | abandoned
became:          # set on close — the design doc, artifact, or successor it turned into
---
```

## Rules

- The overview's summary is kept current as the effort changes shape.
- Every close states `became:` — graduated efforts point at their design, concluded ones at their artifact in [`99-ARTIFACTS`](../99-ARTIFACTS/), abandoned ones at whatever superseded them.
- Nothing is deleted. Closed research is the record of why we did or didn't proceed.
