---
status: active
---

# 004 — Release targeting: assigning items to a release

## What is being investigated

Whether and how items can be assigned to a release, so that at release
time the corpus can answer "what must still land", "what waits for the
next one", and "what is someday" — without importing the
milestone-planning apparatus that made JIRA's release management a
known failure. The effort opened with an external survey
([`01-survey.md`](01-survey.md)): how trackers people actually like
model milestones/releases, which lightweight planning methodologies
survive contact with practice, and the specific mechanisms by which
JIRA-style fix-version planning rots. The survey converged cleanly,
and [`02-shape.md`](02-shape.md) carries the shape for hits — a
release as a third registered vocabulary, one nullable `target`
property per item, and a short list of things deliberately not built.
As of the owner review of 2026-09-14, every open question is settled
(vocabulary not item; shipping refused while open items target the
release; composition as the record with no second field; bare
initiative-scoped slugs with no global reference form; audit as
invariant net only). The effort is ready to graduate through
[playbook 02](../../00-META/process/02-graduation.md) into a design
amendment and decision.

## Why

Discovered live, not hypothesized. Cutting a release surfaced the gap:
some open items still needed to go in, others were for the next
release, others were "some day" — and the model has nowhere to say
any of that. Priority is a triage signal, not a scoping one; links
relate items to items, not items to a release that has no identity in
the system. The gap is real, but so is the risk: milestone planning is
a known pandora's box (the operator's JIRA experience, confirmed at
length by the survey), so the investigation is as much about what to
refuse as what to add.

## What it touches

- [`item-model.md`](../../02-DESIGN/item-model.md) — a new item
  property (`target`), a third registered vocabulary beside projects
  and initiatives, and its invariants.
- [`ops-log.md`](../../02-DESIGN/ops-log.md) — registration ops and
  subjects for the new vocabulary, a shipping/closing op carrying
  evidence.
- [`services.md`](../../02-DESIGN/services.md) — the release view as a
  query; graph projection of release nodes and derived `targets`
  edges, parallel to how `located-in` is projected today.
- [`mcp-server.md`](../../02-DESIGN/mcp-server.md) and the CLI — the
  filing/edit surface for `target`, the release-cut triage pass.
- Decision [0015](../../03-DECISIONS/0015-project-retirement.md) — the
  register/retire lifecycle the vocabulary would reuse, extended with
  a shipped terminal state.
- Decision [0016](../../03-DECISIONS/0016-initiatives.md) — releases
  scope per initiative, as items and projects already do.
