---
status: implemented
code: hits
updated: 2026-09-04
lands:
---

# The ops-log

The single canonical record of the HITS platform: every change to every item
is an op appended here, and everything a caller reads is a projection of it
(posture: [`how-we-build.md`](../00-META/how-we-build.md)). Settled by
decisions [0001](../03-DECISIONS/0001-item-store-architecture.md) and
[0012](../03-DECISIONS/0012-single-state-bucket.md). What the ops
describe is [`item-model.md`](item-model.md); who reads and writes them is
[`services.md`](services.md).

## Stream and subjects

One JetStream stream, `hits-ops`, capturing `hits.ops.>`, file-backed,
with a declared byte budget and `DiscardNew` (decision
[0005](../03-DECISIONS/0005-byte-budgets.md)): 1 GiB by default,
`--max-bytes` to change it, and at the cap appends are refused loudly —
the operator raises the budget; history is never trimmed. Items are kept
forever, so their ops are too — the budget bounds growth, not memory. The
state bucket carries a budget of its own — a quarter of the ops budget
(decision [0012](../03-DECISIONS/0012-single-state-bucket.md)); some
accounts (Synadia Cloud among them) require every stream to declare one,
and HITS declares them on every account so there is one shape everywhere.

Every op for an entity is published to exactly one subject:

```
hits.ops.item.<id>
hits.ops.project.<slug>
```

The op type lives in the envelope, **not** in the subject. This is
deliberate: JetStream's per-subject compare-and-swap
(`Nats-Expected-Last-Subject-Sequence`) works on the exact subject, and that
CAS is what serializes writes per entity. A varying trailing token would
break it. Consumers consume `hits.ops.>` and switch on the subject kind and
the envelope.

## The envelope

The envelope is the platform's wire contract — every service shares it, and
changing it is a design amendment. Each op carries:

```yaml
id:       # unique op id — doubles as Nats-Msg-Id for publish dedupe
op:       # the op type, from the catalog below
entity:   # what the subject names — the item id or project slug
actor:    # who did it — a stable handle; claims and notes are attributable
at:       # timestamp, RFC 3339
v: 1      # envelope schema version
payload:  # op-specific fields
```

### Op catalog

Ops are semantic — what happened, never "state is now X". Projections fold
them; the log reads as the item's history.

| Op | Payload carries |
|---|---|
| `created` | type, report body, reporter, priority, and — when known at filing — `located-in`, `discovered-while` |
| `noted` | a trail entry: text, author ([`item-model.md`](item-model.md) § bodies) |
| `edited` | property changes outside the lifecycle: priority, `located-in`, `lands`, `discovered-while` |
| `transitioned` | target status; a closing transition also carries `fixed-by` / `amended-design` and the close date |
| `claimed` | claimant; on a steal, the displaced claimant — attribution survives |
| `released` | — |
| `blocked` | `blocked-by` — an item ref or prose — and the status it interrupted |
| `unblocked` | — (the restored status comes from the matching `blocked` op) |
| `linked` / `unlinked` | link type, target item |
| `tombstoned` | reason |

On `hits.ops.project.<slug>`, one op for now — a project is vocabulary, not
workflow ([`item-model.md`](item-model.md) § projects and actors):

| Op | Payload carries |
|---|---|
| `registered` | display name, description |

## Ordering

There is no global ordering requirement. Per item, ordering is absolute — and
it is a property with two halves, both binding on every consumer of the log:

**At rest — free.** A stream ingests in arrival order and stamps a total
order; the ops of one item, all on one subject, are a suborder of it. Nothing
to do.

**Writes — serialized by CAS.** `hits-node` is the only writer, and every
append is a read-validate-append loop: read the item's snapshot and the
stream sequence of its last op, validate the command against the invariants,
publish with `Nats-Expected-Last-Subject-Sequence` set to that sequence. Two
racing commands cannot interleave — the loser's publish is rejected by the
server and retries against fresh state. This holds across multiple
`hits-node` instances with no coordination beyond the stream itself.
Publishes for an item are synchronous (no async batching on the write path),
and the envelope `id` doubles as `Nats-Msg-Id` so a retried publish cannot
land twice.

**Reads — in order or wrong.** In-order *delivery* is not free: redelivery
after a missed ack, or a shared consumer across instances, reorders. So:

- **Indexers use ordered consumers** — single-instance, in-order,
  gap-detected delivery with no ack bookkeeping. This pairs exactly with
  rebuild-on-boot: an indexer starts at sequence 1, replays, and serves; on a
  gap the consumer re-creates itself and delivery stays ordered.
- **The KV projection is idempotent.** Each snapshot records the stream
  sequence of the last op folded into it; an op at or below that sequence is
  skipped on replay, and snapshot writes CAS on KV revision so concurrent
  `hits-node` instances cannot overwrite fresh state with stale.
- **Across entities, consumers tolerate disorder.** A `linked` op may arrive
  before any op of the item it points at; indexers hold the dangling edge
  rather than assuming the reference resolves. The same holds at the writer:
  validating `located-in` against a registry projection that has not seen a
  fresh registration yet fails toward rejection and a retry, never toward
  accepting an unregistered name.

## Identifiers

Item IDs come from the `system.item-counter` key in the state bucket,
advanced by a CAS-update loop: read, increment, update-at-revision, retry on
conflict. Same atomicity as `05-TOOLS/allocate-issue.sh`'s commit-and-retry
trick, without the git. IDs are dense, ordered, and never reused.

The counter is also derived: replay raises it to at least the highest item ID
the log names, so it carries the same delete-and-replay guarantee as the
snapshots (§ the state projection). The one edge this accepts: an ID minted
for an op that never landed is reissued after a rebuild — harmless, since the
log never named it and nothing can refer to it.

Project slugs are chosen, not minted. Uniqueness needs no counter: the
`registered` op publishes with expected subject sequence zero, so a second
registration of the same slug is rejected by the same CAS that orders item
writes.

## The state projection

`hits-node` folds ops into one KV bucket, `hits-state` (decision
[0012](../03-DECISIONS/0012-single-state-bucket.md)), its keyspace split by
prefix:

```
item.<id>        the item snapshot plus the last-applied sequence
project.<slug>   the registry hits-node validates located-in against
system.<key>     operational keys — today only system.item-counter
```

The prefixes are collision-free by construction: item IDs are dense decimals
and project slugs are lowercase `[a-z0-9-]`, so no key of one kind can spell
a prefix of another. Per-key history on the bucket serves "the last few
states" natively — no extra machinery. The whole bucket is a projection like
any other: delete it and replay reproduces everything in it — snapshots,
registry, and counter alike — and it is wrong by definition wherever it
disagrees with the log.
