# Candidate shape: releases in hits

A sketch mapping the survey's convergent findings
([`01-survey.md`](01-survey.md)) onto the existing model — for owner
review, not yet a proposal. The design bar: answer "what must still
land in this release" as a query, and refuse every hinge the survey
identified as the opening of the box.

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
  turns plan into record — see open question 3.

## Open questions

1. **Vocabulary or item?** The sketch says vocabulary: a release is
   referenced by many items, has a registered slug and a thin
   lifecycle, and `target` stays a property like `located-in` — no
   new link type, no workflow machinery on the release itself. The
   alternative — a release as an ordinary `task` that other items
   link to — reuses more, but overloads item lifecycle with
   vocabulary semantics and makes "unshipped releases" a convention
   rather than a query.
2. **What does shipping require of stragglers?** GitLab documented
   the wedge: cutting a release while open items still carry its
   version. Proposed invariant: shipping is refused while any open
   item targets the release — the cut *is* the triage pass
   (re-target or clear each straggler first), so the moment of
   shipping is also the moment the next release's scope gets honest.
3. **Plan versus record.** JIRA's fixVersion rotted by answering
   both. Here: `target` on an *active* item is plan; once the item
   resolves and the release ships, the same field is record —
   "resolved, targeted hits-0.5, hits-0.5 shipped" composes into
   "shipped in 0.5" without a second field. Is that composition
   enough, or does the resolving transition need to freeze the
   target explicitly?
4. **Slug hygiene.** Release slugs live in the same flat
   subject-token space as project slugs, scoped per initiative —
   `hits-0.5` reads naturally but must not collide with item ID
   parsing (`hits-19`). Dots make release slugs parse-distinct from
   item numbers; is that rule enough, or do releases need their own
   namespace marker?
5. **Does `hits audit` learn releases?** The audit's whole-corpus
   walk could flag targets naming shipped releases on still-open
   items — the one staleness this model can produce.
