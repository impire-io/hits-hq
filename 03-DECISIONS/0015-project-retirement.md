# 0015 — Projects retire; slugs are never renamed or reused

**Date:** 2026-09-06

## Context

Decision [0002](0002-projects-and-actors.md) made projects registered
vocabulary — one `registered` op per slug, CAS-published at expected
subject sequence zero — and deliberately gave them no lifecycle. That left
no way out of the vocabulary: a mistyped or superseded slug is permanent,
and validation offers it to every `located-in` forever. The motivating
case is real, not hypothetical: the `001-hits` registration from setup
validation sits beside the real `hits` slug in the install's registry,
referenced by nothing and removable by nothing (item 15). Items solved
the same problem with the tombstone; projects have no equivalent.

## Decision

- **Projects gain one lifecycle op: `retired`.** A second op on
  `hits.ops.project.<slug>`, carrying a required reason (label budget).
  Retirement removes the slug from the *vocabulary*, not from history:
  the registry projection keeps the key but marks it retired,
  `project.list` drops it, and `located-in` validation refuses new
  references with a `retired-project` invariant.

- **Retirement is permanent, and the slug is never reused.** A retired
  slug cannot be re-registered — this falls out of the existing
  CAS: `registered` publishes at expected subject sequence zero, and a
  retired slug's subject already carries ops. No un-retire op; the
  registry never says one slug meant two things at different times.

- **History stands.** Items whose `located-in` already names the slug
  keep it — ops are immutable and the trail is not edited. Closing such
  an item still works (a closing transition carries no `located-in`);
  only a *new* op writing `located-in` must drop the retired slug.
  Re-pointing an open item at a successor project is an ordinary edit.

- **No rename.** A rename would either rewrite `located-in` references
  held in immutable ops — impossible by design — or add aliasing
  machinery with no present need. The path is: register the successor
  slug, re-point open items by edit, retire the old slug. Closed items
  keep the old name as history.

- **No guard against retiring a referenced slug.** The check would need
  a full item scan the write path does not have, to protect against a
  state that is still fully workable (see above). Minimal build: the
  verb trusts its operator.

## Alternatives rejected

- **A rename verb.** Rejected as above: immutable ops hold the old slug,
  so a rename is either a lie in the projections or an alias table no
  present need justifies.

- **Deleting the registry key on retirement.** Rejected: the snapshot
  carries the last-applied sequence that makes folding idempotent;
  deleting the key loses that marker and lets a replayed `registered`
  op resurrect the slug. Marking the kept key retired preserves the
  delete-and-replay guarantee unchanged.

- **Reusing the item tombstone op for projects.** Rejected: the item
  tombstone voids a filing *mistake* and silences the entity entirely.
  Retirement is vocabulary management — the common case is a superseded
  slug whose history remains legitimate. Different meaning, different op.

- **Allowing re-registration of a retired slug.** Rejected: the registry
  is what keeps one name meaning one thing; a reused slug would make old
  items point at the new project's meaning. It would also cost the CAS
  simplification for free permanence.

## Consequences

- The project op catalog ([`../02-DESIGN/ops-log.md`](../02-DESIGN/ops-log.md))
  is no longer single-entry; `registered` and `retired` are the whole
  lifecycle, and nothing else is planned.
- The client surface grows `project.retire`, with its CLI subcommand and
  MCP tool ([`../02-DESIGN/services.md`](../02-DESIGN/services.md),
  [`../02-DESIGN/mcp-server.md`](../02-DESIGN/mcp-server.md)) — the 1:1
  endpoint/tool rule of decision [0003](0003-mcp-server.md) holds.
- The graph index ignores `retired`: project nodes materialize only
  through item edges, so an unreferenced retired project already appears
  nowhere, and a referenced one keeps serving history.
- The install's registry can finally shed `001-hits` — the validation
  act for the build that implements this.
