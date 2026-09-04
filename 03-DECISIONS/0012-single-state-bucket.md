# 0012 — One state bucket: projections and meta share a prefixed keyspace

**Date:** 2026-09-04

## Context

The fleet keeps its folded state in three KV buckets: `hits-items`
(per-key history 10, a quarter of the ops budget), `hits-projects`
(8 MiB), and `hits-meta` (8 MiB, holding only the item-ID counter).
Daan's proposal: one bucket, with key prefixes telling the kinds apart —
`item.>`, `project.>`, `system.>`.

The three-way split was never its own decision. Decision
[0001](0001-item-store-architecture.md) says "project the log into **a**
JetStream KV bucket"; the split emerged in implementation, and
[0002](0002-projects-and-actors.md) and [0005](0005-byte-budgets.md)
inherited it as given. What it costs: every KV bucket is a JetStream
stream, so a fleet occupies four streams where two would serve —
material on accounts that meter resources, and Synadia Cloud, the
flagship target ([0004](0004-hits-up.md)) and the account every release
candidate validates on, is exactly such an account (issues 003 and 004
were both account-limits failures at the front door).

Verified against the code before deciding:

- **Prefixing is collision-free by construction.** Item IDs are dense
  decimals and project slugs match `^[a-z0-9][a-z0-9-]{0,63}$` — neither
  contains a dot, so `item.`/`project.`/`system.` prefixes cannot be
  forged by a key.
- **The counter is the one real wrinkle.** `hits-meta` describes itself
  as "operational state that is not derived from the log", and `replay`
  never restores it — so today's delete-and-replay guarantee (FR-31)
  quietly excludes the counter, and deleting a merged bucket would reset
  IDs to 1. But the counter *is* derivable: every minted ID appears in
  the log as the `entity` of its item's ops.
- The items bucket's history of 10 is configured but nothing reads it
  yet (the `get`-with-revisions option in
  [`services.md`](../02-DESIGN/services.md) is unimplemented).

## Decision

- **One KV bucket, `hits-state`, replaces `hits-items`, `hits-projects`,
  and `hits-meta`.** The name pairs with `hits-ops`: the log and its
  fold. The keyspace is split by prefix: `item.<id>` for snapshots,
  `project.<slug>` for the registry, `system.<key>` for operational keys
  — today only `system.item-counter`.

- **The bucket takes the items bucket's shape:** per-key history 10 and
  a byte budget of a quarter of the ops budget, scaled by `--max-bytes`
  as before. The two fixed 8 MiB budgets fold into it; project and
  system keys gain history 10, a negligible cost in bytes.

- **Replay derives the counter.** Folding the log raises
  `system.item-counter` to at least the highest item ID the log names.
  This makes the whole bucket disposable — FR-31 now covers everything
  in it, counter included — and it is what makes the merge safe rather
  than merely smaller. `mintID`'s CAS loop is unchanged in normal
  operation. One accepted edge: an ID minted for an op that never landed
  is reissued after a rebuild — harmless, since the log never named it.

- **Names stay bare and centralized** (0004 stands): one bucket constant
  in `contract` instead of three.

- **Migration is replay.** A new binary self-provisions `hits-state` on
  boot and replay fills it from `hits-ops`; no carry-over code. The
  three old buckets linger until the operator deletes them
  (`nats kv del hits-items hits-projects hits-meta`) — a release-note
  line, not cleanup code.

## Alternatives rejected

- **Keep the three buckets.** Four streams per fleet where two serve, on
  the metered account the mission aims at; three bucket configs where
  one covers; and a split that was never decided, only accreted.

- **Merge, but keep the counter non-derived.** One bucket with two
  disposability rules — `item.>`/`project.>` rebuildable, `system.>`
  precious — muddies the projection story FR-31 states plainly, and
  migration would then need counter carry-over code. Deriving it is both
  smaller and stronger.

- **Per-prefix budgets or history inside the bucket.** JetStream KV has
  neither; building the enforcement in code is machinery with no
  consumer — the same sprawl 0005 rejected as per-resource knobs. The
  isolation lost is one case: a full state bucket refuses project
  registrations along with item writes. Acceptable — at that point item
  creation is refused anyway, and the operator's move (raise the budget)
  is identical.

- **Delete the old buckets on boot.** A binary that removes buckets on
  sight is a hazard on shared accounts, and `hits-meta`'s counter is the
  one value that is data until the deriving replay has run. One operator
  command against a near-zero installed base does not justify deletion
  code.

## Consequences

- [`ops-log.md`](../02-DESIGN/ops-log.md) is amended: the budget
  paragraph, § identifiers, and § the state projection take the
  single-bucket shape; [`services.md`](../02-DESIGN/services.md) and
  [`hits-up.md`](../02-DESIGN/hits-up.md) rename in passing. Both
  amended docs return to `status: designed` until hits' main implements
  the shape ([playbook 04](../00-META/process/04-build-handoff.md)).
- 0005's budget shares collapse to two: the ops stream (1 GiB default)
  and the state bucket (a quarter of it). The 8 MiB small-bucket figures
  retire.
- In `hits`: `contract` loses two bucket constants, `openStore` creates
  one bucket, the store prefixes keys, `replay` grows the counter
  derivation, and the client tests that hardcode bucket names move to
  the `contract` constants. An issue in `04-ISSUES` carries the rework.
- A fleet's JetStream footprint halves: `hits-ops` and `KV_hits-state`.
- FR-31 strengthens from per-projection to whole-state: delete
  `hits-state`, boot, and snapshots, registry, and counter all
  reproduce.
