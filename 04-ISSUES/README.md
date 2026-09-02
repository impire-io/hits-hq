# 04-ISSUES

The front door for anything that needs doing in the platform: defects (`kind: bug`, often without knowing which repo owns them) and deferred follow-ups (`kind: task`). Diagnosis starts here because this repo is the one place that sees the whole platform; the fix lands in the owning code repo. The playbook is [03](../00-META/process/03-issues.md).

## Structure

One folder per issue, numbered with the next free `NNN`:

```
NNN-short-slug/
├── 00-report.md      the symptom in plain terms and how it was observed
└── 01-diagnosis.md   bugs only: the trail — hypotheses, evidence, dead ends
```

## Frontmatter schema (`00-report.md`)

```yaml
---
kind: bug            # bug (default) | task — a task is a known follow-up, not a defect
status: open         # open | diagnosing | located | blocked | resolved | wontfix
priority: normal     # high | normal | low — optional; triage signal only
claimed-by:          # intent to work it — not started work
claimed:             # YYYY-MM-DD, alongside claimed-by
blocked-by:          # only with status: blocked — the thing being waited on
located-in:          # [repo, ...] once the owner is known (tasks open with this set)
discovered-while:    # tasks, optional — the context it was noticed in
lands:               # cross-repo fixes only: the ordered landing block (playbook 07)
fixed-by:            # on close — verifiable refs (commit/PR), plus action: deploy entries with evidence
amended-design:      # on close, where the fix was a design amendment
resolved:            # YYYY-MM-DD, with status: resolved
---
```

## Rules

- **Check for a duplicate first** — `grep` the whole folder, resolved issues included. This corpus is the platform's symptom→component memory.
- **Curate; do not dump.** File only what is worth surfacing when someone next works in that repo. "Deferred, not filed" is a valid outcome.
- **Done means delivered:** built, released, deployed where that is what makes it take effect, and validated by one live read of the running system that could not succeed if the thing were broken. Nothing beyond that holds a record open; a defect found later is a new issue, never a reopening.
- Closed issues are kept forever, **in place**. There is no archive folder by design.
