# Process — overview

How work moves through hits-hq, and who may do what. Every other document in this folder is a playbook: trigger, who runs it, steps, outputs. Engineers and agents follow the same playbooks; agents must not act outside them.

## The audiences

| Audience | Contract |
|---|---|
| **Engineers** | Read and write everything. hits-hq is the single source of truth for mission, research, design, decisions, and issue diagnosis. |
| **AI agents** | The same rights as engineers, exercised through these playbooks. |
| **External readers** | Read the `hits-docs` site only, never this repo. External is strictly downstream: no decision is ever made or first recorded there. |

## The knowledge flow

```
idea ──► 01-RESEARCH ──► decision (03-DECISIONS) ──► 02-DESIGN ──► spec-kit spec ──► implemented
 │            │  │                                                  (code repo)
 │            │  └──► artifact (99-ARTIFACTS)
 │            └────► abandoned (recorded, kept)
 └─(small/obvious, decision recorded)──────────────► 02-DESIGN directly

bug/symptom ─────────► tracker item (hits) ──► diagnosis in notes ──► code-repo fix and/or design amendment
deferred follow-up ──► tracker item (task, knows its repo) ──► done in its repo
```

## The playbooks

| # | Playbook | Trigger |
|---|---|---|
| [01](01-research.md) | Research | An idea worth investigating before committing to design |
| [02](02-graduation.md) | Graduation & design change | Research concludes, or a design must change |
| [03](03-issues.md) | Issues | Something needs doing — a defect, follow-up, or improvement; the record lives in the tracker |
| [04](04-build-handoff.md) | Build handoff | A design is ready to be built |
| [05](05-external-sync.md) | External sync | hits-hq changed something hits-docs retells |
| [06](06-builder-skill-sync.md) | Builder-skill sync | A contract a hits-marketplace skill teaches changed in the repo that owns it |
| [07](07-parallel-work.md) | Parallel work | Any piece of work is about to start — how it is isolated, pushed, and landed |

Playbook 07 is the odd one out: it is not a stage of the knowledge flow but the mechanics **every** other playbook runs on. Whenever a playbook says work happens in a repo, 07 says where on disk, how it is pushed, and how it lands.

## Status lives at the source

Work items carry their status in the tracker — the platform is its own front door (decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)). Research overviews and design docs carry theirs as YAML frontmatter, as before (schemas in the section READMEs). There are still **no central status files**: cross-cutting views — the open board, a status matrix, hits-docs badges — are generated on demand from the tracker and the frontmatter, never hand-maintained.
