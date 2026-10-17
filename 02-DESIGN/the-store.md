---
status: in-progress
code: hits
updated: 2026-10-17
---

# The store

What HITS keeps, and where: one chronicle store holding four types, their
operations with the preconditions that encode the lifecycle, the trail as
history, references as paths, and three declared indexes. Settled by
decision [0020](../03-DECISIONS/0020-the-store-four-types-their-preconditions-the-trail-as-history-and-three-indexes.md)
out of research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md);
the model it keeps is [`item-model.md`](item-model.md), the writer is
[`the-client.md`](the-client.md), the account it lives in is
[`the-cutover.md`](the-cutover.md). This document replaces
[`ops-log.md`](ops-log.md), which described the stream, the envelope and
the state projection HITS ran by hand: all three are chronicle's now
(chronicle-hq designs 02 and 03).

```mermaid
flowchart LR
    subgraph store hits — full history
        I[item/&lt;id&gt;]
        P[project/&lt;slug&gt;]
        N[initiative/&lt;slug&gt;] --> R[releases/&lt;id&gt;]
    end
    I -. located-in .-> P
    I -. initiative .-> N
    I -. target .-> R
    I -. relates-to, duplicates .-> I
    subgraph indexes
        T[text — search, history]
        M[meaning — semantic, history]
        G[rel — graph, state]
    end
```

## The store

One store, **`hits`**, created with **full history**: items are kept
forever, so their operations are too, and chronicle declines a snapshot
on it. The store does not require verified authors — the migrated corpus
carries authors chronicle cannot vouch for (decision
[0019](../03-DECISIONS/0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md))
— but every live write goes through chronicle's node and is verified,
and a history read says so per operation. The store's byte budget is the
account's plan's; the corpus of 2026-10-17 weighs under 2 MB.

## The types

Every type's history policy is `full`. Each operation's effect is
`merge` unless said otherwise; each has a precondition — a JSON Schema the
instance's current state must satisfy (chronicle-hq decision 0059) — and
chronicle refuses an operation whose precondition fails before it is
sent, or marks it *invalid* when a bare writer gets it past. Two
preconditions recur: **not tombstoned** (the state has no
`tombstoned: true`) and **create only** (the state is empty).

### `item`

| Field | What it holds |
|---|---|
| `type`, `status`, `priority` | the enums of [`item-model.md`](item-model.md); `priority` defaults to `normal` at filing |
| `initiative` | the path `initiative/<slug>` — the ID's prefix, as state; absent only on a legacy bare-id item not yet assigned |
| `target` | the release's path, `initiative/<slug>/releases/<id>`, while the item aims at one |
| `report`, `reporter`, `created` | the filing: the text (at most 8192 characters), `member/<login>`, the time |
| `claimed-by`, `claimed`, `stolen-from` | the claim: `member/<login>`, the time, and the displaced claimant on a steal |
| `blocked-by`, `interrupted` | while blocked: the blocker (an item's path, or prose) and the status to restore |
| `located-in` | the projects' paths |
| `discovered-while`, `lands`, `fixed-by`, `amended-design`, `closed` | as the model has them |
| `links` | a map from link type (`duplicates`, `relates-to`) to the linked items' paths |
| `tombstoned`, `tombstone-reason` | the void |

The schema states the shapes every state keeps, which chronicle judges
after every merge: `closed` is present exactly when the status is
`resolved` or `wontfix`; `located-in` is present when the status is
`located` and when the type is `task`.

| Operation | Precondition | Data |
|---|---|---|
| `create` | create only | the filing: type, status `open`, priority, initiative, report, reporter, created, and `located-in`, `target`, `discovered-while` when known |
| `note` (effect `none`) | not tombstoned | `text` only — the author and the time are the operation's own |
| `edit` | not tombstoned, not terminal | the changed properties: priority, target, located-in, discovered-while, lands |
| `assign` | not tombstoned | `initiative` — the legacy backfill; the client admits it on a bare-id item only |
| `transition` | not tombstoned; status `open`, `diagnosing` or `located` | `status`; on a close, `closed`, `fixed-by`, `amended-design`, and the claim cleared |
| `claim` | not tombstoned, not terminal, not claimed | `claimed-by`, `claimed` |
| `steal` | not tombstoned, not terminal, claimed | `claimed-by`, `claimed`, `stolen-from` |
| `release` | not tombstoned, claimed | the claim's fields cleared |
| `block` | not tombstoned; status `open`, `diagnosing` or `located` | `status: blocked`, `blocked-by`, `interrupted` |
| `unblock` | not tombstoned; status `blocked` | `status` restored, `blocked-by` and `interrupted` cleared |
| `link`, `unlink` | not tombstoned | the `links` map, whole |
| `tombstone` | not tombstoned | `tombstoned: true`, `tombstone-reason` |

A cleared field is sent as `null`, which a merge deletes. The client
computes every operation's data as the difference between the state
before and the state `contract.Apply` produces ([`the-client.md`](the-client.md)).

### `project`, `initiative`, `release`

The vocabularies keep their shape: `slug`, `name`, `description`, and
`retired` with `retire-reason` once retired; a project's `initiative` is
a path; an initiative carries **`next`**, the number its next item takes
(§ the counter); a release carries `shipped`, `ship-refs` and
`ship-note` once shipped. Their operations: `create` (create only);
`assign` on a project and `retire` on all three (not retired); `ship` on
a release (neither shipped nor retired); `mint` on an initiative (§ the
counter). A release lives under its initiative — `children: releases →
release` — at the id that is its slug with every dot an underscore
(`0.7.0` is `0_7_0`), the slug itself in state; uniqueness per initiative
is the nesting.

## The counter

An initiative's `next` is the dense counter of
[`item-model.md`](item-model.md) § identity, kept as state under
chronicle's expected-sequence guard: filing reads the initiative, writes
`mint` with `next + 1` expecting the sequence it read — a loser of the
race is refused and reads again — and then writes the item's `create`
with the create-only guard, which refuses a duplicate on its own. Two
writes on two instances: a crash between them spends a number and files
nothing, a gap the audit lists and never a reuse. Legacy bare ids are
outside every counter; `next` on `initiative/<slug>` counts the prefixed
ids alone.

## References as paths

Every field that names another thing names it by its path, so that the
graph has a node to walk from: `member/<login>` for a person (a member's
GitHub login, or a service account's name — not an instance, and the
graph treats it as an opaque target), `project/<slug>`,
`initiative/<slug>`, the release's path, `item/<id>`. `blocked-by` is the
one field that may hold prose, when the blocker is not an item.

## The trail

A note is an operation with effect `none`: it moves no state and lives
in the history. Reading an item reads its state and then its history for
the notes, each with the author and time chronicle recorded — which is
what `hits get` prints as the trail. A note's text is its only data.

## The indexes

Declared once by `hits store init` ([`the-cutover.md`](the-cutover.md)):

| Index | Kind, source | What it answers |
|---|---|---|
| `text` | search, history — reading `create` and `note` | full text over reports and notes; a hit names the item |
| `meaning` | semantic, history — `report` and `text` | the nearest items to a text |
| `rel` | graph, state | the edges: `duplicates`, `relates-to` (from `links`), `located-in`, `initiative`, `targets` (from `target`), `reported-by` (from `reporter`), `claimed-by`, `blocked-by`; neighbours in either direction, and walks |

Chronicle's search takes no filters; the type, status, initiative and
target filters of `hits search` are the client's join of the hits with
their states. The status view — every open item — is a listing of the
type with a filter, no index. Tombstoned items are kept and indexed by
chronicle like any other; every HITS reader drops them.

## The announcement

`hits store init` writes `solution/hits` in the store — chronicle's
`solution` type (chronicle-hq design 14): the name, one sentence, the
version, the home at `hits-hq`, and no `url`, since HITS has no interface
of its own. The console lists it as installed; nothing else of chronicle
knows what a tracker is.

## What this does not do

No stream, bucket, consumer or subject of HITS's own: the store's history
is the record and chronicle derives every view. No second counter, no
tombstone deletion, no filter on the wire. No store per initiative. No
verified-authors requirement on the store, until an attested import
exists for a corpus that needs one.
