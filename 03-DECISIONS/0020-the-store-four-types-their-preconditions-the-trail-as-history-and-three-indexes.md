# 0020 — The store: four types with their preconditions, the trail as history, references as paths, and three declared indexes

**Date:** 2026-10-17 · **Status:** decided (graduates research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md) questions 1, 2, 4, 5 and 11; with [0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md) and [0022](0022-where-hits-runs-and-the-cutover.md) the research graduates into [`the-store.md`](../02-DESIGN/the-store.md), [`the-client.md`](../02-DESIGN/the-client.md) and [`the-cutover.md`](../02-DESIGN/the-cutover.md))

## Context

Decision [0018](0018-hits-runs-on-chronicle.md) bound HITS to run on
chronicle with its model unchanged; [0019](0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md)
made the client the writer and put a release under its initiative. The
research then proved the rest: the [mapping](../01-RESEARCH/005-hits-on-chronicle/01-the-mapping.md)
on paper, the [spike](../01-RESEARCH/005-hits-on-chronicle/02-the-spike.md)
on chronicle 0.6.0, and the [replay](../01-RESEARCH/005-hits-on-chronicle/03-the-replay.md)
of the install's 940 operations onto chronicle v0.10.0 — every state
equal, no operation marked under the lifecycle rules declared as
preconditions, which chronicle-hq decision 0059 added for this port. What
remained of questions 1, 2, 4, 5 and 11 was choices, not proofs: which
facts are state and which are history, how references are spelled, which
rules chronicle refuses and which the client checks, and how a release's
gate is kept.

## Decision

1. **One store, `hits`, with full history, and four types.** `item`,
   `project`, `initiative` and `release`, the last a child of its
   initiative (`initiative/<slug>/releases/<id>`). Every op of
   [`ops-log.md`](../02-DESIGN/ops-log.md)'s catalog is an operation of
   one of them, with effect `merge` — except `note`, with effect `none`:
   the trail is the history, read back with the item, and a note's data
   is its text alone; its author and time are the operation's own.
   [`the-store.md`](../02-DESIGN/the-store.md) states each type's schema,
   operations and preconditions.

2. **The lifecycle is declared, and chronicle refuses it out of turn.**
   Every operation carries the precondition that encodes its invariant —
   no operation on a tombstoned item; `transition` and `block` only from
   an active status; `claim` only on an unclaimed, non-terminal item and
   **`steal`**, its own operation, only on a claimed one; `release` only
   when claimed; `unblock` only when blocked; `create` only onto nothing;
   a vocabulary's `retire` and `assign` only when not retired, a
   release's `ship` only when neither shipped nor retired — and the item
   schema states the shapes a state must keep: `closed` exactly when the
   status is terminal, `located-in` present when the status is `located`
   and when the type is `task`. Chronicle refuses what fails them before
   the write is sent and marks what a bare writer gets past. What a
   precondition cannot see, the client checks before writing: a
   registered, unretired project or release of the item's own initiative;
   the legacy rule that `initiative` is assignable only on a bare-id
   item. The promise of [`item-model.md`](../02-DESIGN/item-model.md)
   stands: a command that would violate an invariant is refused, never
   partially applied.

3. **The counter is state under the guard.** The initiative's state
   carries `next`; filing is a `mint` with the expected sequence, then a
   `create` with the create-only guard. A crash between them spends a
   number and files nothing — a gap, never a reuse — and the audit lists
   gaps. Legacy bare ids stay outside every counter.

4. **References are paths.** `reporter`, `claimed-by` and `stolen-from`
   are `member/<login>`; `located-in` holds `project/<slug>`;
   `initiative` holds `initiative/<slug>`; `target` holds the release's
   path, its id the slug with dots as underscores; `links` is a map from
   link type to item paths, written whole under the guard; `blocked-by`
   is an item's path when it names one and prose otherwise. The graph
   reads every edge [`services.md`](../02-DESIGN/services.md) derived
   from these fields, in both directions.

5. **Three indexes, declared by `hits store init`.** `text` — search over
   the history, reading `create` and `note`, so the report and the trail
   are one query; `meaning` — semantic over the same operations' `report`
   and `text`; `rel` — the graph from the fields of point 4. The filters
   HITS's search has — type, status, initiative, target — are the client's
   join of hits with state; a listing with a filter is the status view.

6. **The ship gate is a read and a guarded write.** `ship` lists the
   non-terminal items targeting the release and refuses when any exist,
   then writes under the release's expected sequence with `ship`'s
   precondition; an item re-targeted in the window between the two is
   what the audit nets, as retirement's strays are today.

7. **Budgets are `maxLength` on the schemas** — 8192 for a report and a
   note's text, 1024 for every label — counted in characters where the
   envelope counted bytes; the budget's purpose, prose and not pasted
   logs, is served either way. Tombstoned items are kept by chronicle
   like any other and filtered by every HITS reader.

## Alternatives rejected

- **Notes as child instances.** The trail would be state and a listing;
  it is history, as the model says, and a history-sourced search finds
  it where it is. A child adds a path per note and gains nothing.
- **Links as children.** Chronicle has no delete; a retracted link would
  need a tombstone of its own. A map in state written whole under the
  guard is one operation and one read.
- **A `steal` flag on `claim`.** A precondition cannot see the data; one
  operation per intent lets chronicle refuse a claim on a claimed item
  and allow a steal, which the client otherwise had to carry alone.
- **Bare handles and slugs in the fields.** The spike showed a dangling
  string is data to the graph but nothing to walk from; the path makes
  `walk` from a project or a member answer.
- **A counter chronicle grows.** Two guarded writes and a possible gap
  cost nothing a tracker notices; the ask waits for a gap that matters.

## Consequences

- [`the-store.md`](../02-DESIGN/the-store.md) is written: the types with
  their schemas, operations, effects and preconditions in prose and
  tables; the counter; the references; the indexes; the announcement as
  an instance of chronicle's `solution` type.
- [`item-model.md`](../02-DESIGN/item-model.md) is amended: § identity
  (the counter), § invariants (where each is enforced), § bodies (the
  note's data), § links (the map and the paths), § releases (the path).
  [`ops-log.md`](../02-DESIGN/ops-log.md) is retired: the envelope, the
  subjects and the state projection are chronicle's.
- The migration of [0022](0022-where-hits-runs-and-the-cutover.md) maps
  `claimed` with a steal to `steal` and every other op to its namesake;
  the replay proved the rest.
- The `hits-cli` skill's words for items do not change; the audit gains
  the gap and the stray reads ([0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md)).
