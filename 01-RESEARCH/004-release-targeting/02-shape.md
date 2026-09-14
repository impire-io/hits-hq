# Candidate shape: releases in hits

A sketch mapping the survey's convergent findings
([`01-survey.md`](01-survey.md)) onto the existing model. The design
bar: answer "what must still land in this release" as a query, and
refuse every hinge the survey identified as the opening of the box.
Reviewed by the owner on 2026-09-14; every open question settled —
the settlements are recorded [below](#settled-by-owner-review-2026-09-14)
and folded into the shape.

## The shape

**A release is a third registered vocabulary**, beside projects and
initiatives ([`item-model.md`](../../02-DESIGN/item-model.md)):
`{slug, name, description}`, scoped to an initiative the way projects
are, with the register/retire lifecycle of decision
[0015](../../03-DECISIONS/0015-project-retirement.md) — plus one
state neither existing vocabulary needs: **shipped**. Shipping is the
terminal op for a release that happened, carrying verifiable evidence
(tag, artifact ref) the way a resolving transition carries `fixed-by`;
retirement stays what it is — the exit for the mistyped or abandoned
slug. This fills the gap the survey found in GitHub and GitLab both:
the milestone object and the release artifact are finally the same
fact.

**Items get one nullable `target` property** — GitHub's cardinality,
sufficient because releases here are not also sprints (survey finding
2 and 3). Editable any time while the item is active, like
`priority`. The graph projection materializes release nodes and
derives `targets` edges exactly as it derives `located-in` today
([`services.md`](../../02-DESIGN/services.md)) — the write model
carries one property, and "everything targeting hits-0.5" is a graph
query. The release view — open items with `target: hits-0.5` — is a
query, never a curated document.

**Absence of target is "someday."** No someday release, no icebox
object, no horizon buckets. An untargeted item just sits in the
corpus, which is already the defensible use of a backlog: searchable
symptom→component memory, not a plan demanding grooming. The pressure
valve keeping the untargeted pool honest already exists —
`wontfix` with reasoning on the record.

**One owner cuts the release.** Process, not model: the cut is a fast
triage pass over the initiative's open items — target it here, target
it next, or leave it untargeted — and one person's judgment decides
in-or-out (CPython's rule). No betting table, no grooming session.

## Deliberately not built

The survey's four hinges, refused by construction:

- **No dates on releases.** Dated columns turn every date into a
  commitment. A release ships when it ships; the slug says what, the
  shipping op says when, after the fact.
- **No timebox axis.** No cycles, no sprints, no iterations. Cadence
  is rhythm, not a tracked object.
- **No tracked progress, no hierarchy.** Progress is derivable
  (closed/total over `targets` edges) if a view ever wants it;
  releases do not contain releases; items target at most one.
- **No plan/record split.** One field, and the shipping op is what
  turns plan into record — settlement 3 below.

## Settled by owner review (2026-09-14)

1. **Vocabulary, not item.** A release is the third registered
   vocabulary: referenced by many items, a registered slug with a
   thin lifecycle, `target` a property like `located-in` — no new
   link type, no workflow machinery on the release. The alternative
   (a release as an ordinary `task` other items link to) was
   rejected: it overloads item lifecycle with vocabulary semantics
   and makes "unshipped releases" a convention rather than a query.
2. **Shipping is refused while any open item targets the release.**
   GitLab documented the wedge — cutting a release while open items
   still carry its version. Here the cut *is* the triage pass:
   re-target or clear each straggler first, so the moment of
   shipping is also the moment the next release's scope gets honest.
3. **Composition is the record; no second field.** `target` on an
   active item is plan; terminal-is-terminal freezes it at
   resolution, and with the invariant that `target` may only name an
   *unshipped* release, "resolved, targeted 0.5, 0.5 shipped"
   composes airtight into "shipped in 0.5". Plan becomes record at
   the explicit shipping op, never by reinterpretation — the
   fixVersion two-questions rot is closed by construction. No
   explicit freeze on the resolving transition.
4. **Bare slug, initiative-scoped; no global reference form.**
   `target` stores just the release's slug (`0.5`), validated
   against the item's own initiative's releases — mirroring the rule
   that `located-in` names only the item's initiative's projects.
   With no global `<initiative>-<slug>` form, the item-ID parse
   collision dissolves entirely; display composes it (`hits 0.5`).
5. **Audit as invariant net, nothing dedicated.** The existing
   whole-corpus walk also validates the release invariants — every
   `target` names a known release of the item's initiative, no open
   item targets a terminal release — catching only what slips past
   write-time checks (replay drift, legacy paths), the way it
   already nets other invariants. No release section, no new
   surface: the cut-time readout is already one scoped query away.

Consistency note on retirement: as with projects (decision
[0015](../../03-DECISIONS/0015-project-retirement.md)), no guard
prevents retiring a release some item still targets — new `target`
writes refuse the retired slug, existing values stand, and the audit
nets the strays via settlement 5's terminal-release check.
