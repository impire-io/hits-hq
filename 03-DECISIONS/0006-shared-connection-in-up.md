# 0006 — `hits up` runs the fleet on one shared connection

**Date:** 2026-09-03

## Context

Validating the issue-003 fix on Synadia Cloud surfaced the next wall
(issue
[004](../04-ISSUES/004-hits-up-on-synadia-cloud-fails-partway-on-connection/00-report.md)):
`hits up` opens one connection per service — four in total, the shape
decision [0004](0004-hits-up.md) chose so the composition would be
indistinguishable from four binaries in the account's connection view —
and accounts with small concurrent-connection allowances refuse the third
connect (`maximum account active connections exceeded`). The fail-fast
teardown worked exactly as designed; the account simply cannot seat the
fleet. The mission conflict is direct: onboarding on the operator's
existing account is what `up` exists for, and observability parity is what
it was spending connections on.

## Decision

- **`hits up` runs all four services on one shared connection**, under
  `nats.Name("hits-up")`. NATS micro services multiplex on one connection
  by design; nothing about the services changes — the same `Start`
  entrypoints receive the same `*nats.Conn`, there is just one of it. The
  whole platform costs one connection, plus one for the client operating
  it: two concurrent, bootable on the tightest plans.

- **The standalone fleet binaries keep their own connections and names.**
  They are separate processes; per-service connections are their natural
  shape, and composed production keeps full per-service observability.

- This partially reverses 0004's "packaging change, not a topology
  change": in the account's connection view, `hits up` is now visibly one
  client named `hits-up` running four micro services — which micro
  discovery still lists individually. The parity 0004 bought is retired
  where it priced the product out of its own flagship target.

## Alternatives rejected

- **Keep four connections and document "raise your connection limit".**
  Onboarding friction moved into the operator's billing settings — the
  exact evening of setup `up` exists to delete.

- **A `--shared-connection` flag, per-service by default.** A knob whose
  wrong default breaks the first run on the flagship target; the flag
  would be mandatory advice, which is what a default is for. No consumer
  asked for the per-service shape inside one process.

- **Fewer services instead of fewer connections** (skip indexes at boot).
  Degrades the product to save a connection the shared shape saves for
  free.

## Consequences

- `hits up` boots within an allowance of two concurrent connections.
- Server-side attribution changes: one client `hits-up` instead of four
  named clients. Micro discovery (`$SRV`) still reports the four services
  separately; per-service disconnect behavior inside `up` disappears (one
  connection means shared fate — which a one-process composition already
  implied).
- [`hits-up.md`](../02-DESIGN/hits-up.md) § connections is rewritten;
  decision 0004's connection bullet is superseded by this record.
- `internal/fleet` connects once; its Connector is called once. The
  standalone binaries are untouched.
