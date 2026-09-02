# How We Build

The cross-repo engineering posture for every HITS repo. Where `mission.md`
says *why* and `context.md` says *in what environment*, this document says
*how* — the durable engineering stances every repo is expected to share.

It is **stable by nature** (see the folder [README](README.md)): a posture
lands here once it is settled, not while it is still being argued. Each repo's
own brief (`AGENTS.md` / `CLAUDE.md`) refines this for its context; when a repo
brief and this document disagree, **this document wins** until the brief is
corrected.

> **Decision records.** Each posture is meant to be backed by its own dated
> record under `03-DECISIONS/`. That folder is not scaffolded yet; the postures
> below are binding now, and their records are backfilled when it is. This file
> states the durable form; the record carries the context and consequences.

One section per posture. Add deliberately.

## Build the minimal feature; expand only for a real, present need

HITS is built to the requirement in front of it, not the one imagined for
later. A capability earns its place by a consumer that exists *today*;
speculative generality — a config knob nothing sets, a store nothing reads, a
mode no caller selects — is carrying cost with no power drawn against it, and it
is left out rather than kept "just in case." Scope grows when a genuine gap
surfaces, never by default.

- **The minimal build is the default; every addition carries the burden of
  proof.** An addition must name the present need it serves — "we might want it
  later" is not that need. When two designs both satisfy the requirement, the
  smaller one wins.

- **"What this does not do" is part of the design.** A service states its
  non-goals as plainly as its goals. Naming the boundary keeps scope creep
  visible instead of accreting silently.

- **A missed requirement is the reason to expand — a hypothetical is not.** If
  real use shows something genuinely necessary was left out, add it,
  deliberately, to that need. The guard is against speculative scope, not
  against doing the job completely.

## The ops-log is the source of truth; everything else is a projection

Every change to the system — an issue filed, claimed, blocked, resolved — is an
event appended to the **ops-log**, a JetStream stream. That log is the single
canonical record. Everything a caller reads is a *projection* of it, and every
projection is derived, disposable, and rebuildable by replay.

- **Current state is a KV lookup.** A projection service consumes the ops-log
  and maintains the current-state view in a KV store, so "what is the state of
  issue N" is a cheap read, never a fold over history at request time.

- **Query views are in-process projections.** Fast lookups the client API needs
  — full-text search, semantic search, relations — live as embedded, in-memory
  or in-process indexes (Bleve, an embedded vector or graph store) built from
  the same log. They are caches with a rebuild story, not stores with authority.

- **No projection is written directly.** Writes go through the log; readers go
  through projections. A projection that disagrees with the log is wrong by
  definition, and fixing it is a replay, not a patch.

## Every component is a NATS micro service

All components of the solution are NATS micro services — the projector, the
client API, and anything an install adds. One mechanical shape, whatever the
job.

- **Discoverable and manageable by construction.** Every service answers the
  standard micro discovery surface and exposes management endpoints alongside
  its functional ones. Finding what is running, and how it is doing, is a
  platform property — not something each service reinvents.

- **Subscription is the capability declaration.** An instance serves what it
  subscribes to; adding capacity or capability is starting a process, not
  editing a router.

- **NATS is the only transport at the core.** There is no HTTP-first parallel
  surface. Anything that needs another protocol — the MCP server included —
  is a client or adapter *on* the NATS surface, not a second front door.

## Headless: the client API is the product surface

There is no UI in the core, and no capability that exists only behind one.

- **One surface, all callers.** The client API — NATS micro endpoints — is the
  complete way to interact with the platform. The MCP server exposes that
  surface to agents; future dashboards consume the same surface for humans.
  Neither gets a side door, and nothing is callable that isn't part of the
  surface.

- **Agents are the first-class operators.** The API is designed for
  programmatic callers first: explicit contracts, machine-legible errors,
  operations that compose. Human ergonomics are the job of the views built on
  top.

## Spec-driven, constitution-governed development

Every repo develops the same way: a versioned constitution states its
principles and a binding Constitution Check gates non-trivial work, which flows
Specify → Plan → Tasks → Implement with the artifacts committed. This document
is the cross-repo layer above those constitutions.

- **The wire contract is the thing under test, against real NATS.** Anything
  that exercises a subject, header, or stream contract runs against a real or
  embedded NATS server; mocking the NATS client is forbidden. Tests are written
  first or alongside.

- **The quality gate is blocking.** `make fmt && make test && make lint` green
  — with the race detector where it applies — is when a *change* is done. Hook
  failures stop the line; commits are signed; local settings are never
  committed.

- **An *issue* is done when the work is delivered.** Built, released where the
  repo cuts releases, deployed where deployment is what makes a change take
  effect, and validated by one live read of the running system that could not
  succeed if the thing were broken. Nothing beyond that holds a record open.
  The mechanics are [playbook 03](process/03-issues.md).

## Work in isolation; push continuously; land in a declared order

Several agents and engineers work the same fleet, so a change must be isolated
where it is made and visible from the moment it is started.

- **One work ID names everything.** A single string — taken only from a record
  that already exists, or a bare descriptive slug — is the branch name in every
  repo the change touches, the workspace directory, and the PR label.

- **The draft PR is the claim, and it opens on the first push.** Work is pushed
  as it is made; the PR exists from the beginning of the work, so one query
  answers what everyone is working on. An agent may open, push, and flip the PR
  out of draft; **merging stays with a human.**

- **Cross-repo landing order is declared, not inferred.** A change spanning
  repos carries an ordered `lands:` block on its hits-hq work item. hits-hq
  states the plan; GitHub holds the live state.

The executable steps are [playbook 07](process/07-parallel-work.md).
