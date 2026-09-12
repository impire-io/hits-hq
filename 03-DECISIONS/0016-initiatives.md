# 0016 — Initiatives: one install tracks many groups of projects

**Date:** 2026-09-12

## Context

Research [003](../01-RESEARCH/003-group-isolation/00-overview.md) opened
when a `hits audit` run surfaced another group's project (`chronicle-hq`,
item 27) in this install's corpus. The flat model made three things true
at once: the registry-mirrors-repos.md rule (decision
[0013](0013-issue-tracking-cutover.md)) had become silently false, every
corpus-wide surface read across the group line, and only a human
objection stopped tooling from reaching into the other group's clone.
The research's initial position — one install per group, decision
[0004](0004-hits-up.md)'s grain — was reversed by the owner: sharing is
wanted. Many teams combine several groups of repos, and one person runs
several efforts side by side. The remaining shape questions were settled
at owner review, 2026-09-11
([02-proposal.md](../01-RESEARCH/003-group-isolation/02-proposal.md)).

Checked against `00-META`: the need is real and present (mission /
minimal build), the surface stays one API for all callers (headless),
and everything below is ops on the log with projections following
(effect).

## Decision

- **An initiative is a second registered vocabulary: a named group of
  projects.** `{slug, name, description}` on its own ops subject, with
  exactly the project lifecycle of decision
  [0015](0015-project-retirement.md): register and retire, reason
  required, retired slugs never re-registered or reused, history
  standing. Slugs are lowercase `[a-z0-9-]` and are refused a trailing
  all-digit segment at registration — the ID parse rule below depends
  on it.

- **A lens, not a wall.** Decision 0004 stands untouched: the NATS
  account (or JetStream domain) remains the only isolation boundary,
  and every caller on an account reads the whole corpus — confirmed as
  a feature, not a compromise. Initiatives give tools and views a
  marked line to scope by; they restrict nothing. If hard restrictions
  are ever needed they arrive at the account edge (NATS auth-callout is
  the named candidate), never as model machinery.

- **Item IDs are initiative-prefixed: `<initiative>-<n>`.** Each
  initiative mints from its own dense counter; `hits-19`,
  `chronicle-hq-4`. The item number is the trailing all-digit segment —
  unambiguous by the slug rule above. The ID makes the initiative
  intrinsic to the item at filing: every create names its initiative
  (explicitly, or by the client's selected default), because the mint
  needs it. The prefixed ID is subject-, branch-, and label-safe, and
  remains the one-string work ID (playbook 07); cross-initiative
  collision-freedom now holds by construction.

- **Every project belongs to exactly one initiative.** New
  registrations carry it; a project moves (and the existing registry
  backfills) by an `assigned` op. An item's `located-in` is validated
  against the item's own initiative — an item cannot span initiatives,
  by construction rather than by rule.

- **Legacy bare IDs are grandfathered, never renumbered.** Items 1–28
  keep their IDs forever: refs, merged branches, and the ops-log cite
  them, and terminal is terminal. The bare counter freezes — no new
  bare mints. A legacy item takes its initiative by an ordinary edit
  (the one place an item's initiative is writable; on prefixed items it
  is immutable in the ID). The backfill: every legacy item to the
  `hits` initiative, except item 27 to `chronicle` — registered and
  assigned by us as install operators, the owner accepting that this
  names the other group's slug without their input to unblock the
  migration.

- **The surface grows in lockstep, and selection is client-side.**
  `initiative.register / retire / list` endpoints with their CLI verbs
  and MCP tools (the 1:1 rule), `project.assign`, an `initiative`
  parameter on create, and an initiative filter on search. `hits
  initiative select` stores the selected initiative in the client
  config beside the default actor — a filing default only, never a
  read scope, and no wire op. Readers untouched by a flag keep the
  whole corpus: scoping is always explicit.

- **The graph materializes initiative nodes now.** Derived edges —
  project → initiative from registration and assignment, item →
  initiative from the ID prefix (or the legacy assignment) — the same
  way project and actor nodes derive today.

## Alternatives rejected

- **One install per group.** The research's initial position; rejected
  by the owner as missing the real shape of the work — groups of repos
  combine, and one person runs several. 0004's per-account grain
  remains available to anyone who wants a hard wall.
- **One global ID sequence with initiatives as pure grouping.** The
  first proposal draft. Prefixed IDs won: the ID carries its
  initiative, filing gets its initiative before any project is known,
  and spanning items become impossible instead of merely refused.
- **Tenancy in the model — walls, per-initiative auth, scoped reads.**
  Speculative machinery against the headless one-surface posture;
  restrictions, if ever, belong at the account edge.
- **Renumbering history into prefixed IDs.** Refs in closed records,
  merged branches named by bare IDs, and immutable ops all cite the old
  identity; renumbering would corrupt exactly the memory the tracker
  exists to keep.
- **Deriving legacy items' initiative through located-in only.**
  Leaves unlocated legacy items initiative-less and makes the
  assignment invisible in the log; an explicit edit op keeps the
  backfill attributable, with provenance.

## Consequences

- The op catalog grows: `registered` / `retired` on
  `hits.ops.initiative.<slug>`, `assigned` on the project subject, an
  `initiative` field in the project `registered` payload and the item
  `created` payload, and `initiative` among the properties `edited` may
  carry — legal only on bare-ID items
  ([`../02-DESIGN/ops-log.md`](../02-DESIGN/ops-log.md)).
- The state bucket gains `initiative.<slug>` keys and per-initiative
  counters `system.item-counter.<slug>`; the bare `system.item-counter`
  freezes as the legacy range's marker.
- The client surface, CLI, and MCP tools grow in lockstep
  ([`../02-DESIGN/services.md`](../02-DESIGN/services.md),
  [`../02-DESIGN/mcp-server.md`](../02-DESIGN/mcp-server.md)); the
  search index learns the initiative filter; `hits audit` gains
  `--initiative` over its walk.
- New work IDs are prefixed (`hits-29`), so branch names and PR labels
  carry their initiative; historical bare-integer branches keep
  resolving against the frozen legacy range (the audit's merged-work
  scan handles both).
- The registry-mirrors-repos.md rule rewrites per-initiative: each
  initiative names a governing hq repo whose repos.md mirrors that
  initiative's projects. That rewrite — playbooks 03 and 07, repos.md,
  and the item-model prose — rides the build's landing PR, as 0013's
  did.
- The `hits-marketplace` builder skill follows under playbook 06 once a
  release carries the verbs, as with 0015.
