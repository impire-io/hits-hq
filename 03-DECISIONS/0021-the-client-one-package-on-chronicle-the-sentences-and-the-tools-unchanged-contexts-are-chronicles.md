# 0021 — The client: one package on chronicle's client, the sentences and the tools unchanged, contexts are chronicle's

**Date:** 2026-10-17 · **Status:** decided (graduates research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md) questions 7 and 8; with [0020](0020-the-store-four-types-their-preconditions-the-trail-as-history-and-three-indexes.md) and [0022](0022-where-hits-runs-and-the-cutover.md))

## Context

Decision [0019](0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md)
made the `client` package the writer. The research's remaining questions
on the surfaces were how the package reads and writes through chronicle,
what the CLI and the MCP server keep, what the connection seam becomes
once hits contexts and the token exchange retire
([0018](0018-hits-runs-on-chronicle.md) point 3), and what of the repo
stays. chronicle's own CLI exports the seam a solution needs (chronicle
spec 035: `LoadContext` then `Dial`, the store the context selected), and
its Go client carries the guard, the verified write, the state read, the
history and the index queries the mapping used.

## Decision

1. **The `client` package keeps its surface and stands on chronicle's.**
   Every request type and method of today's package stays; underneath,
   a write is a read of the instance's state, the invariant checks of
   [`contract`](../02-DESIGN/item-model.md) § invariants that chronicle
   cannot make, the next state computed by `contract.Apply` — the same
   fold the install runs — and the **diff** between the two sent as a
   `merge` through chronicle's node with the expected sequence: a
   verified author, and a refusal rather than a stale write. A guard miss
   is re-read, re-checked and retried, as `hits-node`'s CAS loop did. The
   replay proved this write model reproduces every state the install
   holds.

2. **Reads are chronicle's reads.** `get` is the instance's state with
   the trail from its history; the vocabulary listings and the status
   view are listings of a type with the client's filter; search,
   semantic and graph queries are the three indexes' streamed replies,
   the hits joined with state for the filters HITS offers; paging is a
   limit. Nothing of HITS serves a query.

3. **The sentences and the tools do not change.** `hits create`, `claim`,
   `resolve`, `search`, `graph` and the rest keep their words and flags;
   `hits-mcp` keeps one tool per client method, stdio, fail-fast. What
   leaves: `hits up`, `hits auth`, `hits context` and `hits ping`, and
   the `--actor` flag with `HITS_ACTOR`. What arrives: `hits store init`
   ([0022](0022-where-hits-runs-and-the-cutover.md)), and `--context`
   naming a **chronicle** context.

4. **Contexts, identity and the actor are chronicle's.** `hits` and
   `hits-mcp` connect through chronicle's saved contexts — `chronicle
   login` for the hosted account, `chronicle context add` for a
   credential on any NATS — loaded and dialled as chronicle's own CLI
   does. The actor is the context's principal: a person's GitHub login,
   an agent's service-account name, vouched for by chronicle on every
   write. hits contexts, the token exchange and the OAuth cache retire
   with decisions [0008](0008-client-idp-auth.md) to
   [0011](0011-standalone-hits-contexts.md); `hits context import` of a
   nats context becomes `chronicle context add`.

5. **The fleet leaves the repo.** `hits-node`, the three index binaries,
   `internal/fleet`, `internal/node`, `internal/index` and
   `internal/connect` are removed; the repo keeps `cmd/hits`,
   `cmd/hits-mcp`, `client` and `contract` — the model, the invariants
   and the fold the client computes with. The lint boundaries that kept
   the services apart retire with them; the one that keeps the adapters
   on the client stays.

6. **The audit stays a client, and reads two more things.** Beside the
   refs against git: the gaps in each initiative's numbering, and the
   operations after the cutover sequence whose author chronicle did not
   vouch for.

7. **`hits-mcp` stays until chronicle's MCP server subsumes it.**
   chronicle-hq research 013 is open; when a chronicle MCP server with a
   `hits` skill does what the tools do, retiring `hits-mcp` is its own
   decision, with the skill's home in `impire-marketplace` unchanged.

## Alternatives rejected

- **A thinner client that sends the fields the caller named.** The
  install's invariants and its fold are in `contract`; computing the
  next state and sending the diff keeps every rule in one place and let
  the replay prove the result equal.
- **New sentences for a new substrate.** The words are the model's and
  the skill teaches them; the substrate is nobody's business at the
  prompt.
- **Keeping hits contexts as a wrapper over chronicle's.** Two context
  stores for one connection; chronicle's `Dial` is the seam, and
  `chronicle login` is the sign-in HITS could never offer.
- **Retiring `hits-mcp` now.** Nothing replaces it yet.

## Consequences

- [`the-client.md`](../02-DESIGN/the-client.md) is written: the write
  loop, the reads, the connection, the sentences and flags that leave
  and arrive, the audit's reads. [`mcp-server.md`](../02-DESIGN/mcp-server.md)
  is amended: it fronts the client on chronicle, and its actor is the
  context's. [`services.md`](../02-DESIGN/services.md),
  [`hits-up.md`](../02-DESIGN/hits-up.md) and
  [`idp-auth.md`](../02-DESIGN/idp-auth.md) are retired.
- [`how-we-build.md`](../00-META/how-we-build.md)'s postures are
  restated: the history is the record and chronicle keeps it; HITS runs
  no service of its own and every surface is a client of chronicle's
  API; headless stands. [`repos.md`](../00-META/repos.md)'s `hits` row
  and [`context.md`](../00-META/context.md)'s open identity question
  follow.
- The `hits-cli` skill in `impire-marketplace` is synced through
  [playbook 06](../00-META/process/06-builder-skill-sync.md) when the
  release of [0022](0022-where-hits-runs-and-the-cutover.md) ships: the
  connection and actor sections change, the item sentences do not.
