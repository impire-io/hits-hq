# 0001 — The item store: ops-log, hits-node, and three index services

**Date:** 2026-09-02

## Context

HITS exists to replace the file-based issue storage (`04-ISSUES/` folders with
frontmatter) with a platform. The postures in
[`00-META/how-we-build.md`](../00-META/how-we-build.md) already bind the shape:
the ops-log is the source of truth, everything else is a rebuildable
projection, every component is a NATS micro service, and the client API is the
whole product surface. What they leave open — flagged explicitly in
[`00-META/repos.md`](../00-META/repos.md) — is the component split: whether the
projector and client API are one service or two, where the query projections
live, and what the repos are.

## Decision

- **One stream is the source of record.** Every change to an item is an op
  appended to a JetStream stream, one subject per item
  (`hits.ops.item.<id>`), with the op type in the envelope — not in the
  subject. Per-item ordering is guaranteed at the stream and enforced at the
  writer; there is no global ordering requirement. The contract is
  [`02-DESIGN/ops-log.md`](../02-DESIGN/ops-log.md).

- **`hits-node` is the single writer and the state server.** It validates
  every command against current state before appending, projects the log into
  a JetStream KV bucket (current state plus recent history per item), and
  exposes the **`hits`** micro service: create, get, edit, transition, claim,
  release, block, unblock, link, unlink, note, tombstone.

- **Query is three separate index services**, each a NATS micro service
  consuming the ops-log with its own ordered consumer, each an embedded,
  pure-Go, rebuild-on-boot projection:
  - `hits-index-graph` → **`hits-graph`** — link exploration; in-memory
    adjacency behind a store interface.
  - `hits-index-search` → **`hits-search`** — full-text; Bleve (scorch).
  - `hits-index-semantic` → **`hits-semantic`** — embedding search;
    chromem-go, with embeddings produced by a configurable
    OpenAI-API-compatible provider (base URL, API key, model).

- **All four are separate binaries in the `hits` repo**, with the code of each
  service cleanly separated: one package tree per service, a single shared
  contract package (op envelope + item model) that every service may import,
  and no service importing another. The boundary is lint-enforced, so
  extracting a service into its own repo later is mechanical.

## Alternatives rejected

- **Op type as a subject token** (`hits.ops.item.<id>.<op>`). Rejected because
  per-item compare-and-swap on publish uses JetStream's per-subject sequence,
  which works on the exact subject; a varying trailing token breaks the
  single-writer serialization that per-item ordering rests on.

- **Query indexes inside the client API process** (the earlier sketch in
  `repos.md`). Rejected in favor of separate services: index rebuilds and
  embedding-provider latency must not gate the write path, and the micro
  posture makes an extra service cheap. The indexes stay embedded and
  in-process *within each indexer* — caches with a rebuild story, never
  authority.

- **An embedded graph database** (goraphdb or similar). Rejected for now:
  the candidates are young and barely maintained, and at this corpus's scale
  in-memory adjacency rebuilt by replay is simpler and faster. The store
  interface keeps the door open.

- **Persisted indexes with checkpointed consumer positions.** Deferred, not
  rejected: persistence requires atomically storing the index and its last
  applied sequence, which buys boot time we do not yet need at the cost of a
  corruption class we cannot yet afford to debug. Revisit when replay-on-boot
  measurably hurts.

- **One repo per service.** Deferred: the services share one young contract;
  separate repos would version it before it has settled. The lint-enforced
  boundary preserves the option.

## Consequences

- Per-item ordering is a *system* property with two halves: serialized writes
  (CAS at publish) and in-order application (ordered consumers, idempotent
  projection). Both halves are binding on every future consumer of the log;
  a consumer that shares work across instances or acks out of order is wrong
  by construction.
- The op envelope is the platform's wire contract. Changing it is a design
  amendment, not a refactor.
- The semantic index depends on an external embedding provider; the other
  three services must stay fully functional without it.
- Items are kept forever and never reopened; `tombstone` exists solely to void
  filing mistakes. The kept-forever corpus rule of `04-ISSUES` carries over
  unchanged.
- `04-ISSUES/` remains the working front door until the platform is live;
  its corpus is currently empty, so cutover needs no migration.
