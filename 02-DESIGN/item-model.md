---
status: designed
code:
updated:
lands:
---

# The item model

The unit of work in HITS: what `04-ISSUES/` folders and their frontmatter
become once the platform holds them. Settled by decision
[0001](../03-DECISIONS/0001-item-store-architecture.md); the storage contract
is [`ops-log.md`](ops-log.md), the surface is [`services.md`](services.md).

## Identity

An item's ID is a decimal integer, minted atomically at creation
([`ops-log.md`](ops-log.md)), rendered as a string without padding. It is
subject-token-safe by construction and it is the **work ID**: the branch name,
the workspace directory, the PR label ([playbook
07](../00-META/process/07-parallel-work.md)). IDs are never reused, including
for tombstoned items.

## Type

| Type | Meaning | Lifecycle |
|---|---|---|
| `bug` | a defect, usually with unknown owner | full: diagnosis before resolution |
| `task` | a known follow-up, deferred so it isn't lost | opens with `located-in` set; skips diagnosis |
| `improvement` | a deliberate betterment, not a defect | either path: skips diagnosis when the owner is known at filing |

## Properties

| Property | Set | Meaning |
|---|---|---|
| `type` | at creation | `bug` \| `task` \| `improvement` |
| `status` | by transition | see lifecycle below |
| `priority` | anytime | `high` \| `normal` \| `low` — triage signal only, defaults `normal` |
| `created`, `reporter` | at creation | explicit now — git history no longer carries them |
| `claimed-by`, `claimed` | claim/release | intent to work it, not started work; both set or neither |
| `blocked-by` | while blocked | the thing being waited on: an item ref or plain prose |
| `located-in` | at creation or on locating | `[project, ...]` once the owner is known — registered projects only ([below](#projects-and-actors)) |
| `discovered-while` | at creation | optional — the context it was noticed in |
| `lands` | before close | cross-repo work only: the ordered landing block |
| `fixed-by` | at close | verifiable refs (commit/PR) plus `action: deploy` entries with evidence |
| `amended-design` | at close | where the fix was a design amendment |
| `closed` | at close | date, on either terminal status — generalizes the old `resolved:` field, which dated only resolutions and left `wontfix` undated |

## Lifecycle

Statuses: `open`, `diagnosing`, `located`, `blocked`, `resolved`, `wontfix`.

- A **bug** moves `open → diagnosing → located → resolved | wontfix`.
  `diagnosing` and `located` are the localization stages; `located` requires a
  non-empty `located-in`.
- A **task** opens with `located-in` set and moves `open → resolved | wontfix`
  — no localization stages.
- An **improvement** takes either path: filed with `located-in` it behaves
  like a task; filed without, like a bug.

**Blocked is a status with memory.** Any active status can move to `blocked`;
the op records the status it interrupted, and unblocking restores exactly that
status and clears `blocked-by`. The old frontmatter flattened this — "restore
the status the issue was in" relied on a human remembering it; here the record
remembers.

**Terminal is terminal.** `resolved` and `wontfix` accept no further
transitions. A defect found later is a new item — the corpus is
symptom→component memory, and reopening corrupts the record of when a thing
was delivered ([playbook 03](../00-META/process/03-issues.md)).

**Tombstone is not a status.** It voids a filing mistake — a duplicate filed
in error, a test record — at any point in the lifecycle. A tombstoned item
keeps its ID and its history in the log, but projections drop it from every
view. It is never a way to remove a real item, closed or open.

## Invariants

Enforced by `hits-node` before any op is appended; a command that would
violate one is rejected, never partially applied.

- Status transitions follow the lifecycle above; no transition leaves a
  terminal status.
- `blocked-by` may be set only while `blocked`, and is cleared on unblock.
- `claimed-by` and `claimed` are set together and cleared together.
- `status: located` requires non-empty `located-in`.
- A `task` cannot be created without `located-in`.
- `located-in` names only registered projects — the registry is what makes
  this and the previous invariant real checks rather than shape checks.
- Every command carries an `actor`, validated for form.
- `closed` is set exactly when status becomes terminal; `fixed-by` and
  `amended-design` are carried by the closing transition.
- A tombstoned item accepts no further ops.

## Bodies and trail

The report — the symptom in plain terms and how it was observed — is part of
the creation op. Everything after it is a **note**: an appended trail entry
with an author and a timestamp. The diagnosis trail of a bug (hypotheses,
evidence, dead ends — the old `01-diagnosis.md`) is its notes; so is closing
reasoning on a `wontfix`. Notes are append-only: the trail is history, and
history is not edited.

## Links

Links are typed, directed edges **between items**, asserted and retracted
explicitly: `duplicates`, `relates-to`. The set grows by need, not by
default. Links may reference items the reader has not seen yet; consumers
tolerate that ([`ops-log.md`](ops-log.md)).

Not every relation an item has is a link. The line is drawn by what kind of
fact each one is:

- **Asserted relations between items** are links: both ends have identity in
  the system, and the relation exists because someone stated it and someone
  can retract it.
- **References outside the item graph** — `located-in` (projects),
  `discovered-while`, a `blocked-by` naming an external party — stay
  properties. A project is registered vocabulary with no lifecycle
  ([below](#projects-and-actors)); the reference is a fact about the item,
  consumed by the item's own invariants ("a task opens with `located-in`"),
  not an edge asserted and retracted in its own right.
- **Attribution** — `reporter`, `claimed-by` — is never assertable at all: it
  is derived from the `actor` on the `created` and `claimed` ops. A link can
  be added and removed; provenance cannot.

The graph still sees all of it. The graph index is a projection, and a
projection may reshape: it materializes project and actor nodes and derives
edges from properties and ops — `located-in`, `reported-by`, `claimed-by`,
and `blocked-by` for the duration of a block whose blocker is an item
([`services.md`](services.md)). So "everything located in one project" and
"everything one actor claimed" are graph queries, and the write model carries
none of it. This also removes a wart: a block on another item needs no
hand-made companion link — the edge is derived while the block stands and
drops when it lifts, which is why `blocks` is not in the assertable set.

## Projects and actors

A **project** is the unit of ownership — what `located-in` points at. In the
hits install today, a project is a repo; the model term is deliberately more
general. Projects are registered vocabulary, not workflow: a thin entity
with a chosen subject-token-safe slug, a display name, and a description,
created by a registration op on its own subject ([`ops-log.md`](ops-log.md))
and referenced by items from then on. No status, no lifecycle, no notes —
machinery a vocabulary does not need. Registration is what keeps one typo
from silently splitting the symptom→component memory, and the install's
registry mirrors [`repos.md`](../00-META/repos.md) by hand.

An **actor** is a stable lowercase handle (`daan`, `claude`), not a record:
carried as `actor` on every op, validated for form, not existence. There is
no user entity — nothing consumes one today. Authority is the caller's claim
for now; when identity later derives from NATS authentication, the same
field is verified rather than claimed, with no change to the envelope.
(Decision [0002](../03-DECISIONS/0002-projects-and-actors.md).)
