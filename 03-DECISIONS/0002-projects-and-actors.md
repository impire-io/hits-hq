# 0002 — Projects are registered vocabulary; actors are unregistered handles

**Date:** 2026-09-03

## Context

The item model ([`02-DESIGN/item-model.md`](../02-DESIGN/item-model.md)) left
`located-in` and `actor` as freeform strings. Two things make that untenable
as-is. First, decision [0001](0001-item-store-architecture.md) and its links
refinement made the graph index materialize project and actor nodes and
answer queries over them — "everything located in one repo", "everything one
actor claimed" — so spelling drift is no longer cosmetic: a typo'd
`located-in` silently splits the symptom→component memory the corpus exists
to be, and an inconsistent actor spelling breaks claim attribution. Second,
ops are immutable and kept forever, so identifier hygiene compounds: whatever
discipline the fields lack at the start is polluted history at the end. The
open question was whether to fix this with first-class entities, and for
which fields.

## Decision

- **Project becomes a first-class concept — as vocabulary, not workflow.**
  "Project" replaces "repo" as the model term (in the hits install today, a
  project *is* a repo). A project is a thin registered entity: a chosen
  subject-token-safe slug, a display name, a description — registered by an
  op on its own subject (`hits.ops.project.<slug>`), carried in the same
  ops-log, folded into its own small KV projection. No status, no lifecycle,
  no notes. `hits-node` validates every `located-in` against the registry,
  which turns the "a task opens with `located-in`" invariant from a shape
  check into a real one.

- **Actors stay unregistered.** An actor is a stable lowercase handle
  (`daan`, `claude`) required on every op and validated for *form*, not
  existence. There is no user entity — nothing consumes one today. Authority
  is the caller's claim for now; when identity later derives from NATS
  authentication, the same envelope field is verified rather than claimed —
  a tightening, not a migration.

- The op envelope's `item` field generalizes to `entity` — the id the
  subject names, item or project. Log consumers consume `hits.ops.>`.

## Alternatives rejected

- **Keep projects freeform.** Rejected: the two consumers that exist today —
  invariant validation and the graph's project nodes — both need a closed
  vocabulary, and every typo written before validation arrives is permanent
  log history.

- **Full user entities.** Rejected for now: no present consumer.
  User metadata serves nothing yet, and the eventual authority for "who is
  this" is authentication, not a registry — a user record would fake the
  guarantee that NATS auth will later actually provide.

- **Projects in configuration instead of the log.** Rejected: a second
  source of truth. Indexers could no longer rebuild the full vocabulary by
  replay, and registration would stop being an audited change to the system.

- **Modeling projects as items.** Rejected: the item's lifecycle, claims,
  and trail are dead weight on a vocabulary entry, and the invariants would
  need carve-outs everywhere.

## Consequences

- Registration precedes first reference. The race — an item op validated
  against a registry projection that has not yet seen the registration —
  fails toward rejection and retry, never toward corruption.
- Project slugs are chosen, not minted; uniqueness is enforced by
  publish-CAS on the project's subject (expected sequence zero), the same
  mechanism that orders item writes.
- The hits install's registry mirrors
  [`00-META/repos.md`](../00-META/repos.md) by hand. No sync tooling until
  drift is a demonstrated problem, per the minimal-feature posture.
- Introducing a user entity later remains open as its own decision; nothing
  in the envelope or model blocks it.
