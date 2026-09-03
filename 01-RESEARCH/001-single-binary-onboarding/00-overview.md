---
status: graduated
became: ../../02-DESIGN/hits-up.md
---

# 001 — Single-binary onboarding against an existing NATS system

## What is being investigated

Making it trivial to run HITS against a NATS system someone already has —
Synadia Cloud or a self-hosted server: download one binary, point it at the
system through a NATS context, and start working. The candidate shape is an
all-in-one process (`hits up` or a dedicated binary) that runs the whole
service fleet in one process against that system.

## Why

Adoption. HITS deliberately has no infrastructure of its own beyond NATS
([decision 0001](../../03-DECISIONS/0001-item-store-architecture.md)), so for
anyone already running NATS the distance to a working HITS should be minutes,
not an evening of composing four service binaries. Today the connection story
is already right — every binary resolves through NATS contexts — but the
startup story is not: getting started means launching `hits-node` and three
indexers by hand.

## What it touches

- [`02-DESIGN/services.md`](../../02-DESIGN/services.md) — the code-layout
  boundary ("no service imports another, nothing outside a service's tree
  imports its internals") is the main tension: a composition binary must
  start all four services.
- The `hits` repo — where the composition entrypoint lives, and whether the
  semantic index becomes optional at boot (today it refuses to start without
  an embedding provider).
- [`00-META/how-we-deploy.md`](../../00-META/how-we-deploy.md) — the
  download-a-binary story is the first real distribution story; the doc
  currently says no release flow exists, which is stale (the repo ships
  goreleaser and a release workflow — sync filed as issue 001).

[`01-current-state.md`](01-current-state.md) records what already exists on
`hits` main and the open questions. [`02-proposal.md`](02-proposal.md)
proposes the answers: `hits up` as a subcommand of the one `hits` binary,
composed through a bounded `internal/fleet` tree, semantic optional at the
`up` surface, an embedded NATS server as a recorded non-goal, and one HITS
per account with no prefix knob. Graduated as decision
[0004](../../03-DECISIONS/0004-hits-up.md) and design
[`hits-up.md`](../../02-DESIGN/hits-up.md).
