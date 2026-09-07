# 003 / 02 — Proposal: initiatives

Question 1 of [`01-current-state.md`](01-current-state.md) is answered,
by the owner (Daan, 2026-09-07): the sharing is wanted, not drift. One
HITS system should track **multiple groups of projects** — many teams
combine several groups of repos, and a single person runs several
efforts side by side. The name for the grouping: **initiative**. This
reverses the effort's initial position (one install per group), which
stands in 01-current-state as the record of where the thinking started.

## What an initiative is

A named group of projects inside one install. Every project belongs to
exactly one initiative; items group through their projects. The account
holds one corpus, one ID sequence, one registry — initiatives organize
it.

**An initiative is a lens, not a wall.** Decision
[0004](../../03-DECISIONS/0004-hits-up.md) stands untouched: the NATS
account (or JetStream domain) remains the only *isolation* boundary,
and everyone on an account can read everything on it. What initiatives
change is scope-by-default: tools and views operate within an
initiative unless told otherwise, so the chronicle incident's failure
mode — tooling drifting into another group's territory because nothing
marked the line — gets a marked line. A team that needs a hard wall
still gets its own account.

## Proposed model shape

- **A second registry vocabulary beside projects.** An initiative is
  `{slug, name, description}` with the same lifecycle projects got in
  decision [0015](../../03-DECISIONS/0015-project-retirement.md):
  register and retire, reason required, slug never reused. Same CAS
  machinery, same op-catalog pattern.
- **A project names its initiative at registration.** Required on new
  registrations; existing projects are backfilled by an explicit op
  (provenance in the op, decision 0013's import precedent). The
  registry stays the flat located-in vocabulary — the initiative field
  is how it folds into groups.
- **Items derive their initiative through `located-in`.** No new field
  on items where derivation answers it. The two gaps derivation leaves
  are open questions below: items filed with no project yet, and items
  whose projects would span initiatives.
- **Dense global IDs stay.** One sequence per install means item IDs —
  and therefore work-ID branch names (playbook 07) — remain
  collision-free *across* initiatives. Sharing the sequence is a
  feature of the shared install, and worth stating in the design.

## Proposed surface shape

- `hits initiative register|retire|list` on the CLI, matching MCP
  tools under the 1:1 rule, `client.RegisterInitiative` etc. on the
  one surface.
- The corpus-wide readers grow an initiative scope: `--initiative` on
  search and the status view, and on `hits audit` (whose `--repo`
  mapping already scopes the git side — the flag scopes the tracker
  walk's findings to match). Defaults are an open question below.
- No read authorization changes: scoping is filtering, on the client
  side of the one surface, consistent with headless ("human ergonomics
  are the job of the views built on top").

## What this does not do

- No per-initiative accounts, streams, buckets, or subject prefixes —
  0004's no-prefix stance is untouched.
- No access control. A lens, not a wall, stated plainly in every doc
  this graduates into.
- No item-level initiative field while derivation through projects
  suffices.
- No cross-install federation. One install, several initiatives; several
  installs remain several installs.

## Governance consequence

The registry-mirrors-repos.md rule (decision 0013, item-model.md)
rewrites per-initiative: each initiative names a governing hq repo, and
that repo's repos.md mirrors that initiative's projects. Our repos.md
governs the `hits` initiative's rows; `chronicle-hq` moves under a
chronicle initiative governed by its own group — which also restores
the rule's truthfulness without touching their records.

## Open questions for graduation

1. **Unlocated items.** A bug filed before diagnosis has no project,
   hence no derived initiative. Options: require `--initiative` at
   creation when no project is given; or a client-config default
   initiative beside the default actor. Lean: config default, explicit
   flag to override — filing must stay one command.
2. **Spanning items.** `located-in` is a list; two projects from two
   initiatives on one item makes its initiative ambiguous. Lean:
   refuse at write time (minimal, revisit on a real case).
3. **Scope defaults.** Do search/status/audit default to the config's
   initiative or to the whole corpus? Lean: whole corpus stays the
   no-flag behavior (backwards-honest), the config default arrives
   only with the config knob from question 1.
4. **The graph index** — whether initiative nodes materialize as
   derived edges (project → initiative) the way project and actor
   nodes do today.

## Path from here

Graduation through [playbook 02](../../00-META/process/02-graduation.md):
a decision record for the initiative concept and its non-goals, an
item-model.md amendment (vocabulary section) plus ops-log.md op-catalog
rows, then the build handoff ([playbook 04](../../00-META/process/04-build-handoff.md))
to the `hits` repo — contract, node, client, CLI, MCP, in the spec-kit
flow. Backfill of the existing registry rides the same work, as ops
with provenance.
