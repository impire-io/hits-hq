# 003 / 02 — Proposal: initiatives

Question 1 of [`01-current-state.md`](01-current-state.md) is answered,
by the owner (Daan, 2026-09-07): the sharing is wanted, not drift. One
HITS system should track **multiple groups of projects** — many teams
combine several groups of repos, and a single person runs several
efforts side by side. The name for the grouping: **initiative**. This
reverses the effort's initial position (one install per group), which
stands in 01-current-state as the record of where the thinking started.

Two further calls from the owner, same day, folded in below: item IDs
are **initiative-prefixed**, not one global sequence; and the
lens-not-wall stance is confirmed — multiple initiatives being readable
is a feature, with harder restrictions arriving later at the account
edge (e.g. NATS auth-callout) if ever needed, never in the model.

## What an initiative is

A named group of projects inside one install. Every project belongs to
exactly one initiative; items group through their projects. The account
holds one corpus, one ID sequence, one registry — initiatives organize
it.

**An initiative is a lens, not a wall.** Decision
[0004](../../03-DECISIONS/0004-hits-up.md) stands untouched: the NATS
account (or JetStream domain) remains the only *isolation* boundary,
and everyone on an account can read everything on it — confirmed as
the desired behavior, not a compromise: seeing across initiatives is a
feature. What initiatives change is scope-by-default: tools and views
operate within an initiative unless told otherwise, so the chronicle
incident's failure mode — tooling drifting into another group's
territory because nothing marked the line — gets a marked line. If
harder restrictions are ever needed, they arrive at the account edge —
ad-hoc per-caller permissions via NATS auth-callout is the named
candidate — never as model machinery. A team that needs a hard wall
today still gets its own account.

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
- **Item IDs are initiative-prefixed: `<initiative>-<n>`,** minted from
  a dense per-initiative sequence (owner's call, replacing this
  proposal's first draft of one global sequence). `hits-19`,
  `chronicle-4`. The ID carries the initiative, which makes the
  initiative **intrinsic to the item from filing**: every create names
  its initiative (flag or config default), because the mint needs it.
  That dissolves two questions the derivation model left open — an
  unlocated bug has an initiative before it has a project, and
  `located-in` is *validated* against the item's initiative, so
  spanning items are refused by construction rather than by rule.
- **Work IDs stay one string.** The prefixed ID is the branch name,
  workspace directory, and PR label (playbook 07) — `hits-19` is
  branch-safe, label-safe, and NATS-subject-safe, and cross-initiative
  collision-freedom now holds by construction instead of by a shared
  counter. The dense per-initiative sequence keeps the auditor's
  walk-to-first-gap enumeration, run per initiative off the registry.
- **Existing bare IDs are grandfathered, never renumbered.** Items 1–28
  keep their IDs forever: refs in closed records, merged branches named
  `17`, and the ops-log all cite them, and terminal is terminal.
  Backfill ops assign each legacy item an initiative without touching
  its ID; the bare sequence freezes — no new bare mints. The audit's
  check B keeps resolving historical bare-integer branches against the
  legacy range while parsing prefixed work IDs going forward.

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
  this graduates into; hard restrictions, if ever, live at the account
  edge (auth-callout), outside this design.
- No renumbering of history. Legacy bare IDs stand forever; migration
  is assignment ops, never rewritten identity.
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

Two of the first draft's questions dissolved when the ID became
initiative-prefixed: an unlocated item has an initiative because its ID
does, and spanning items are refused because `located-in` validates
against the item's initiative. What remains:

1. **The filing default.** Every create now needs an initiative for
   the mint. Lean: a client-config default initiative beside the
   default actor, `--initiative` to override — filing must stay one
   command.
2. **The ID parse rule.** Initiative slugs may contain hyphens
   (`chronicle-hq-4` must parse), so the item number is the trailing
   all-digit segment and initiative slugs are refused a trailing
   all-digit segment at registration. Verify the full charset is
   branch-, label-, and subject-safe at graduation.
3. **Scope defaults.** Do search/status/audit default to the config's
   initiative or to the whole corpus? Lean: whole corpus stays the
   no-flag behavior (backwards-honest); the config default arrives
   only with question 1's knob.
4. **The graph index** — whether initiative nodes materialize as
   derived edges (project → initiative, item → initiative) the way
   project and actor nodes do today.
5. **Legacy assignment.** Which initiative each of items 1–28 backfills
   into, and whether the frozen bare sequence needs anything beyond
   "no new mints" (lean: nothing — the audit walks it as a fixed
   range).

## Path from here

Graduation through [playbook 02](../../00-META/process/02-graduation.md):
a decision record for the initiative concept and its non-goals, an
item-model.md amendment (vocabulary section) plus ops-log.md op-catalog
rows, then the build handoff ([playbook 04](../../00-META/process/04-build-handoff.md))
to the `hits` repo — contract, node, client, CLI, MCP, in the spec-kit
flow. Backfill of the existing registry rides the same work, as ops
with provenance.
