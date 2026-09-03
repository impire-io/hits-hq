# 0005 — Byte budgets: every resource declares one, and full refuses writes

**Date:** 2026-09-03

## Context

The first real run of `v0.1.0-rc.1` against Synadia Cloud failed at boot
(issue [003](../04-ISSUES/003-hits-up-fails-on-synadia-cloud-creating-the-hits-ops-stream/00-report.md)):
accounts can require every stream config to declare `max bytes`, and
`hits-node` creates the ops-log stream — and would next create the KV
projection buckets — with no byte budget at all, as
[`ops-log.md`](../02-DESIGN/ops-log.md) prescribed ("unlimited retention").
Synadia Cloud is the flagship target the onboarding work aimed at (research
001, decision [0004](0004-hits-up.md)), so this is the front door failing.
The tension: the mission's "nothing is lost" versus accounts that refuse
uncapped resources.

## Decision

- **Every JetStream resource HITS creates declares a byte budget by
  default.** The ops stream defaults to 1 GiB; the `hits-items` bucket to a
  quarter of the ops budget; `hits-projects` and `hits-meta` to a small
  fixed 8 MiB. Budgets exist on every account, not only on the ones that
  demand them — one shape everywhere.

- **Full refuses writes; it never trims history.** The ops stream is
  created with `DiscardNew`: at the cap, appends fail with a loud,
  machine-legible error and the operator raises the budget. JetStream's
  default (`DiscardOld`) would silently delete the oldest ops — the source
  of record — and is never acceptable here. The KV buckets already refuse
  at their cap by KV's own construction.

- **One override: `--max-bytes <size>`** on `hits-node` and `hits up`,
  accepting human-readable sizes (K/M/G/T, base 1024). It sets the ops
  stream budget; the items bucket scales with it. Raising it later is a
  config change picked up on next boot (`CreateOrUpdateStream`); shrinking
  below current usage is refused by the server.

## Alternatives rejected

- **Unlimited by default, a flag only for capped accounts.** Breaks
  zero-config on the flagship target and forks the deployment story into
  two shapes; the account that requires a budget is the one the mission
  aims at.

- **`DiscardOld` (JetStream's default) with a cap.** Silent deletion of
  the canonical record — the one failure mode the mission forbids
  outright. A full stream must be an operational signal, not a shredder.

- **Detect the rejection (err 10113) and retry with a cap.** The same
  outcome with the decision hidden inside a retry path, and config drift
  between accounts that do and do not enforce the requirement.

- **Per-resource budget knobs.** Sprawl with no consumer; one budget with
  derived shares covers the need, and a real second need reopens this.

## Consequences

- [`ops-log.md`](../02-DESIGN/ops-log.md) retires "unlimited retention":
  the stream carries a declared budget that refuses new writes when
  reached. History is still never trimmed — the budget bounds growth, not
  memory.
- `hits up` and `hits-node` work out of the box on Synadia Cloud and any
  other limits-required account.
- `node.Start` grows a config carrying the budget; `hits up` and
  `cmd/hits-node` wire the flag through.
- The default numbers are conservative starting points, not commitments —
  revisited on evidence, per the minimal-feature posture.
