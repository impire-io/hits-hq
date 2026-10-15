---
status: active
---

# Research 005 — HITS on chronicle: the model mapped, the gaps named

## What is being investigated

How HITS keeps its model and sheds its substrate, as decision
[0018](../../03-DECISIONS/0018-hits-runs-on-chronicle.md) binds it to: an
item, a project, an initiative and a release as instances of types in a
chronicle store; every op of the catalog an authored operation in that
store's history; the invariants still refused before anything lands; the
three queries as declared indexes; the actor as chronicle's author; the
corpus moved as history with its IDs, authors and order standing. The
effort maps each piece of [`item-model.md`](../../02-DESIGN/item-model.md),
[`ops-log.md`](../../02-DESIGN/ops-log.md) and
[`services.md`](../../02-DESIGN/services.md) onto chronicle as it stands —
0.6.0 and its record — says which pieces hold, which hold under a
convention, and which need chronicle to grow, and files the last kind on
chronicle's tracker. It starts on paper and proves itself with a spike.

## Why now

The direction is recorded on both sides (0018 here, chronicle-hq 0058) and
three chronicle decisions were made for this port a month ago without a
record of what they were for. chronicle-hq's research 014 (tenant
workloads) names HITS as the workload it tests against and waits on this
walk; its item chronicle-38 asks for the gap list this effort's first
document is. The corpus grows daily, and every day it grows the migration
is larger.

## What it touches

- **chronicle's model** — types with a schema, operations with an effect
  (`merge`, `none`), children under a parent's prefix, the history policy,
  the expected-sequence guard, the fold's marking of invalid writes
  (chronicle-hq designs 02 and 03; decisions 0011, 0018, 0019, 0021,
  0022, 0045). Every HITS entity and op becomes one of these.
- **chronicle's indexes** — search and semantic reading state or history,
  graph reading edges from state fields, the streamed query reply with no
  filters and no offset (chronicle-hq design 05; decisions 0012, 0015,
  0016, 0020). Every HITS query becomes one of these.
- **chronicle's identity** — members, service accounts, roles, the
  verified author and a store that requires one (chronicle-hq design 01;
  decisions 0052, 0057). The `actor` and decisions
  [0002](../../03-DECISIONS/0002-projects-and-actors.md) and
  [0008](../../03-DECISIONS/0008-client-idp-auth.md) to
  [0011](../../03-DECISIONS/0011-standalone-hits-contexts.md).
- **chronicle's surfaces** — the SDKs and the CLI (chronicle-hq designs 07
  and 12), the MCP server in research there (013), the quick start, the
  install manifest a solution publishes (chronicle-hq decision 0054).
  [`mcp-server.md`](../../02-DESIGN/mcp-server.md),
  [`hits-up.md`](../../02-DESIGN/hits-up.md), the `client` package.
- **chronicle's plan and forms** — the per-store byte budget, the hosted
  account at chronicle.impire.dev where the shared install would live,
  the open form on an operator's NATS (chronicle-hq decisions 0031,
  0035, 0039).
- **chronicle-hq research 014** — whether a HITS service, if one remains,
  runs as a tenant workload; its question 8 reads this effort's findings.
- **The running install** — 0.7.0 on the shared context, its `hits-ops`
  stream from sequence 1, every item every Impire hq cites.

## Questions to answer

1. **The types.** `item`, `project`, `initiative`, `release` as chronicle
   types: schema, operations with their effect, children, history policy.
   Whether a note is an operation with effect `none` (the trail is the
   history) or a child instance (the trail is state); whether a link is
   state or a child. How blocked-with-memory, the claim pair and the
   closing stamp are written when the fold can only merge.
2. **The ID.** How a dense per-initiative counter is minted without a
   lock: a guarded operation on the initiative instance followed by a
   create-only write, and what a crash between the two leaves (a gap,
   never a reuse). Whether dense still means dense, and whether it needs
   to.
3. **The invariants, and where they are enforced.** Chronicle refuses an
   operation whose data fails its schema and nothing else; lifecycle
   transitions, the claim pair, a located status without a project, a
   project that is not registered, a target that has shipped, a ship with
   open targets, a terminal item, a tombstoned one — all are the writer's.
   Which writer: one HITS service as the store's only writer, every client
   through the shared `client` package under the guard, or a rule
   chronicle grows. What each does to the author (a service writing for a
   person is the author chronicle sees), to raw writers (a credential that
   bypasses the package), and to the audit.
4. **Bodies and the trail.** The report in the create, notes as
   effect-`none` operations, both found by one history-sourced search
   index — the shape chronicle's 0020 was validated with. Byte budgets as
   schema limits. What `hits get` reads to print the trail.
5. **Links and the graph.** Asserted links as a map in state, one field
   per link type, read-modify-write under the guard; graph rules deriving
   `located-in`, `targets`, `claimed-by`, `blocked-by` and the initiative
   from state fields with the targets written as paths. What the graph
   loses: edges derived from ops, if any.
6. **Identity and the account.** One account for the shared install, one
   store for the corpus (an initiative is a lens, decision
   [0016](../../03-DECISIONS/0016-initiatives.md)); the actor as the
   author; a person's handle as their GitHub login; an agent as a service
   account. Whether the store requires verified authors — and what that
   does to a sole-writer service and to a migrated history, whose
   authors chronicle cannot vouch for.
7. **The indexes and the queries.** Search over report and notes with the
   type, status, initiative and target filters HITS has and chronicle's
   search does not; semantic with its field narrowing; neighbors and walk;
   the status view as a listing with a filter; paging under a streamed
   reply with no offset.
8. **The surfaces.** The CLI's sentences composing reads and a guarded
   write; whether `hits-mcp` stays a stdio client with its one-tool-per-
   endpoint rule, or chronicle's MCP server with a `hits` skill makes it
   unnecessary; `hits up` as `chronicle up` plus an install manifest; the
   audit as the client it already is.
9. **The corpus.** Replaying `hits-ops` from sequence 1 into the store:
   each op as one operation on its mapped path with its actor as the
   author, its original time and op id carried in the data, order kept
   by replaying in stream order; legacy bare IDs; tombstoned items;
   retired vocabularies; release slugs with dots in a path grammar where
   a dot separates segments. How the result is verified (every snapshot
   against every state, the audit against both), and the cutover: freeze,
   replay, verify, repoint every context, retire the stream.
10. **Where it runs.** Self-hosted: an operator's NATS with chronicle's
    node, the HITS types applied by `hits store init` from the manifest.
    Hosted: an account at chronicle.impire.dev for the shared install;
    whatever service HITS still runs as a tenant workload (chronicle-hq
    research 014) or on an operator's host until then.
11. **Releases and the gate.** `release.ship`'s refusal while open items
    target the release, as a listing followed by a guarded write on the
    release instance; what the window between them permits.
12. **The spike.** Against chronicle as it stands: define the four types
    with the CLI, mint an ID, file an item, walk it through the lifecycle
    with the guard, claim, block, note, link, resolve; declare a
    history-sourced search and a graph; query both; replay a slice of the
    real corpus and compare the state to the install's snapshots. Record
    every refusal and every awkwardness.

## How it closes

Expected: a decision per settled group — the types and the trail; the
invariants and the writer; identity and the account; the corpus and the
cutover — the designs `ops-log`, `services`, `item-model`, `mcp-server`,
`hits-up` and `idp-auth` rewritten or retired and handed to `hits`
through [playbook 04](../../00-META/process/04-build-handoff.md); every
gap filed on chronicle-hq's tracker in the `chronicle` initiative; and
the two releases of decision 0018 point 5 registered. "The model holds,
and chronicle has to grow these things" is the expected shape of the
close.

## Where it stands

**Opened 2026-10-14** with decision
[0018](../../03-DECISIONS/0018-hits-runs-on-chronicle.md). The first
document, [`01-the-mapping.md`](01-the-mapping.md), was written the same
day on paper against chronicle 0.6.0's record: every entity, op, invariant,
index and surface of HITS beside what chronicle offers for it, with the
gap list at the end — the list chronicle-38's fourth ask wanted. The spike
(question 12) has not run yet; it is the next step, and the mapping says
which rows it has to check.

**2026-10-15 — the gaps addressed** (Daan's direction). Checked against
chronicle's code: an underscore is legal in an instance id, `Op-Ts` is an
author-claimed time on every operation, the verified write refuses a
header naming another author, and the fold judges nothing about the state
an operation meets or leaves. Decision
[0019](../../03-DECISIONS/0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md)
settles questions 3 and 6 and the release row of question 1: the writer
is the client package under the guard, through the node; the store does
not require verified authors and every live write is verified anyway; a
migrated operation's author and time ride on `Op-Author` and `Op-Ts`; a
release is a child of its initiative with its dots as underscores. The
one ask, lifecycle rules, is chronicle-75 on chronicle's tracker — an
operation may declare a precondition and the type's schema is the shape
every state keeps — answered by chronicle-hq decision 0059 the same day.
The spike is still the next step.

**The spike ran 2026-10-15** ([`02-the-spike.md`](02-the-spike.md)),
against chronicle 0.6.0: the model holds as mapped — the four types, the
counter under the guard, the lifecycle with blocked-with-memory and the
claim pair, the release child with its underscore id, the legacy id, one
history-sourced search over report and trail, the graph from fields in
both directions. The lifecycle gap was shown live: a transition out of a
terminal status folded at sequence 11, which chronicle-hq 0059 answers.
The history's time is `Op-Ts`, so a migrated operation shows its original
time. One piece stays unproven: the corpus replay with the original
author and time, which needs the Go client and is the next step before
the cutover (question 9) is designed; questions 1 (the rest), 2, 4, 5, 7,
8, 10 and 11 graduate from here.
