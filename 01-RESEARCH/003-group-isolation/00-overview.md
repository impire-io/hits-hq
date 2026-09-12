---
status: graduated
became: ../../02-DESIGN/item-model.md
---

# 003 — Group isolation: multiple groups of projects in one HITS install

## What is being investigated

The HITS install this project runs on has turned out to be shared: its
project registry and item corpus carry another group's work beside our
own. The effort opened on the question of where the boundary between
groups of projects belongs — install topology, data model, or
discipline. That question is now answered by the owner: sharing is
**wanted** — one HITS system should track multiple groups of projects,
named **initiatives**. What remains under investigation is the shape:
the initiative vocabulary, how projects and items group under it, which
surfaces scope by it, and how the existing registry backfills.
[`02-proposal.md`](02-proposal.md) carries the proposed shape — an
initiative as a lens, not a wall, with decision
[0004](../../03-DECISIONS/0004-hits-up.md)'s account boundary untouched
as the only hard isolation, and item IDs initiative-prefixed
(`hits-19`) from dense per-initiative sequences, legacy bare IDs
grandfathered. Graduated as decision
[0016](../../03-DECISIONS/0016-initiatives.md) with amendments to
[`item-model.md`](../../02-DESIGN/item-model.md),
[`ops-log.md`](../../02-DESIGN/ops-log.md),
[`services.md`](../../02-DESIGN/services.md), and
[`mcp-server.md`](../../02-DESIGN/mcp-server.md).

## Why

Discovered live, not hypothesized. A `hits audit` run over our three
repos surfaced item 27, located in `chronicle-hq` — a project slug
belonging to a different group — sitting in the same corpus as ours.
Three consequences were on the table within minutes:

- **A standing rule is silently false.** Decision
  [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md) and
  [item-model.md](../../02-DESIGN/item-model.md) say the project
  registry hand-mirrors [`repos.md`](../../00-META/repos.md), one slug
  per row. `chronicle-hq` is in the registry and not in repos.md; the
  invariant did not bend, it stopped being true without anyone
  deciding that.
- **Every corpus-wide surface crosses the group line.** Playbook 03's
  dedup-first search, the status board, the graph, semantic search
  once it returns, and the auditor's whole-corpus walk all read both
  groups' items — by design, since the corpus is flat.
- **Agents inherit the confusion.** The audit run led straight to a
  suggestion to map the other group's clone into our tooling — caught
  by a human objection, not by any rail. Discipline notes were added,
  but discipline is not a boundary.

## What it touches

- Decision [0004](../../03-DECISIONS/0004-hits-up.md) — the recorded
  grain: one HITS per account (or JetStream domain); the account is
  the only isolation boundary the platform has or wants.
- Decision [0013](../../03-DECISIONS/0013-issue-tracking-cutover.md)
  and [item-model.md](../../02-DESIGN/item-model.md) — the
  registry-mirrors-repos.md rule now in tension with observed state.
- [`00-META/mission.md`](../../00-META/mission.md) — "nothing is lost"
  constrains any untangling: ops-log history cannot be edited away.
- [ops-log.md](../../02-DESIGN/ops-log.md) and the single state bucket
  (hits spec 010) — dense global item IDs and one bucket per install
  are what make a split a replay question rather than a config change.
- The other group's own setup and intent — coordination, not ours to
  decide unilaterally.

[`01-current-state.md`](01-current-state.md) records the verified
facts, the incident, and the open questions — including the effort's
initial position (one install per group), kept as the record of where
the thinking started. [`02-proposal.md`](02-proposal.md) reverses it on
question 1's answer and proposes initiatives: the model, the surfaces,
the non-goals — and, as of the owner review of 2026-09-11, every open
question settled (`initiative select` filing, trailing-digits parse,
whole-corpus defaults, graph nodes now, `hits`/`chronicle` backfill).
The effort graduated through playbook 02 on 2026-09-12; the build
handoff (playbook 04) to the `hits` repo follows.
