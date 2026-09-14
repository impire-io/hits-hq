# 0017 — Release targeting: items aim at a release, releases ship with evidence

**Date:** 2026-09-14

## Context

Research [004](../01-RESEARCH/004-release-targeting/00-overview.md)
opened when cutting a release surfaced a gap live: some open items
still had to land in it, others were for the next release, others were
"some day" — and the model had nowhere to say any of that. Priority is
a triage signal, not a scoping one; links relate items to items, not
to a release, which had no identity in the system. Tracked as
[hits-3](https://github.com/impire-io/hits-hq).

The known risk was the mechanism itself: milestone planning is a
documented pandora's box, and the effort surveyed the outside world
before shaping anything
([01-survey.md](../01-RESEARCH/004-release-targeting/01-survey.md)).
The survey converged: the minimal milestone shape — a named bucket
with open/closed state, referenced by a single nullable field, with
progress derived — is proven and liked (GitHub); the box opens through
four specific hinges — dated commitments, an unowned free-for-all
field, versions that never leave the vocabulary, and an unbounded
"later" pile demanding grooming (JIRA's fixVersion literature, the
icebox rot canon); the timebox axis (sprints, cycles) is where the
ceremony lives and is separable from the deliverable axis (Linear);
and the minimal mechanism proven at scale is a one-bit in-or-out
decision owned by one release manager, with the release view as a
query (CPython, Debian). The shape questions were settled at owner
review, 2026-09-14
([02-shape.md](../01-RESEARCH/004-release-targeting/02-shape.md)).

Checked against `00-META`: the need is real and present — discovered
by an actual cut, not hypothesized (minimal build); a release is
registered vocabulary with a thin lifecycle, not workflow machinery
(the 0002/0015/0016 grain); everything below is ops on the log with
projections following, and the surface grows in lockstep for all
callers (headless).

## Decision

- **A release is the third registered vocabulary: a named ship point
  within an initiative.** `{slug, name, description}`, registered per
  initiative on its own ops subject,
  `hits.ops.release.<initiative>.<slug>`. Release slugs are lowercase
  `[a-z0-9.-]` with every dot-separated segment non-empty — dots are
  wanted, releases are usually versions (`0.5`) — and uniqueness per
  initiative comes from the same subject-sequence-zero CAS as
  projects and initiatives (decision
  [0015](0015-project-retirement.md)). The subject parse is
  unambiguous by construction: initiative slugs contain no dots, so
  the initiative is the first token after the kind and the release
  slug is everything after it, dots literal.

- **The lifecycle is register → shipped | retired.** `shipped` is the
  terminal op for a release that happened, carrying verifiable refs —
  tag, commit, artifact — plus an optional note, the way a resolving
  transition carries `fixed-by`. This closes a gap the survey found
  everywhere: GitHub's milestones and releases are disconnected
  objects, GitLab bolted the association on late — here the milestone
  and the release artifact are the same fact. `retired` stays what
  0015 made it: the exit for the mistyped or abandoned slug, reason
  required. Both are terminal; a shipped or retired slug is never
  re-registered or reused — the CAS gives that for free.

- **Items get one nullable `target` property: the release the item
  aims at.** Set optionally at creation or by edit while the item is
  active; it stores the bare release slug, validated against the item's
  own initiative's releases — mirroring `located-in`'s rule, so there
  is no global reference form and no collision with item-ID parsing.
  `target` may name only an unshipped, unretired release. The release
  view — "what must still land in 0.5" — is a query over open items,
  never a curated document, and progress is derivable, never tracked.

- **Shipping is refused while any non-terminal item targets the
  release.** The cut *is* the triage pass: re-target or clear each
  straggler first, so the moment of shipping is also the moment the
  next release's scope gets honest. This is the one place the model
  demands a human pass, and it is deliberately the only one. GitLab
  documented the wedge this refuses: items carrying the version of a
  release already cut.

- **Plan becomes record by composition; there is no second field.**
  `target` on an active item is plan. Terminal-is-terminal freezes it
  at close, the unshipped-target invariant stops late writes, and the
  straggler gate empties the release before it ships — so "resolved,
  targeted `0.5`, `0.5` shipped" *is* "shipped in 0.5", airtight,
  with no reinterpretation. JIRA's fixVersion rotted precisely by
  letting one unowned field answer plan and record at once; here the
  explicit shipping op is the boundary between the two.

- **Absence of target is "someday" — and that is the whole someday
  mechanism.** No someday release, no icebox object, no horizon
  buckets, no dates on releases, no timebox axis, no tracked
  progress, no release hierarchy, no multi-release items. An
  untargeted item sits in the corpus as what the corpus already is —
  searchable symptom→component memory — and `wontfix` with reasoning
  on the record is the pressure valve that keeps the untargeted pool
  honest. Every one of these refusals maps to a documented failure
  mode in the survey; they are part of the design, not omissions.

- **The surface grows in lockstep, and the audit nets the
  invariants.** `release.register / ship / retire / list` endpoints
  with their CLI verbs and MCP tools (the 1:1 rule), `target` on
  create and edit, a target filter on search. The graph materializes
  release nodes and derives item → release `targets` edges while a
  target is set, exactly as `located-in` derives today. `hits audit`
  validates the release invariants in its existing whole-corpus walk
  — every target names a known release of the item's initiative, no
  open item targets a terminal release — catching what slips past
  write-time checks; no dedicated release pass, no new surface.

## Alternatives rejected

- **A release as an ordinary item that others link to.** Reuses item
  machinery, but overloads item lifecycle with vocabulary semantics:
  "which releases exist and are unshipped" becomes a naming
  convention rather than a registry query, and `target` would have
  nothing to validate against.
- **A timebox axis — cycles, sprints, iterations.** The survey is
  unambiguous that this is where sprint ceremony lives, and that the
  deliverable axis alone answers the actual need. Cadence is rhythm,
  not a tracked object.
- **Dates on releases.** Dated columns turn every date into a
  commitment (the Now/Next/Later origin argument). A release ships
  when it ships; the shipping op dates it, after the fact.
- **A someday bucket — an icebox, a horizon property, a backlog
  object.** Every unreviewed holding area in the literature earned a
  "where X goes to die" epithet; a bucket demands grooming or rots.
  Untargeted-is-someday carries no maintenance obligation at all.
- **Multi-release targets (the fixVersion shape).** The pressure for
  many-per-item comes only from overloading releases as sprints,
  which this design refuses; a multi-valued unowned field is the
  documented rot vector.
- **A global release reference form (`hits-0.5`).** Parse-collision
  machinery against item IDs, serving no consumer: `target` is scoped
  by the item's own initiative, display composes the pair, and the
  collision dissolves instead of being managed.
- **Auto-clearing or ignoring stragglers at ship time.** Auto-clear
  silently discards scoping decisions someone made; ignoring them
  recreates the stale-version wedge. Refusal makes the triage pass
  explicit and cheap.
- **An explicit freeze of `target` at resolution.** A second field
  that says what composition already says, and can only ever agree
  with it or be a bug.

## Consequences

- The op catalog grows: `registered` / `shipped` / `retired` on
  `hits.ops.release.<initiative>.<slug>`; `target` joins the
  `created` payload (when known at filing) and the properties
  `edited` may carry
  ([`../02-DESIGN/ops-log.md`](../02-DESIGN/ops-log.md)).
- The state bucket gains `release.<initiative>.<slug>` keys. The
  ship-time straggler check reads open-item snapshots at validation —
  shipping is rare, a scan is acceptable, and no reverse index enters
  the write model.
- New invariants: `target` names a registered, unshipped, unretired
  release of the item's own initiative (refusals named
  `unknown-release`, `release-shipped`, `release-retired`); `ship` is
  refused while any non-terminal item targets the release
  (`open-targets`); shipped and retired releases accept no further
  ops. The terminal-item edit refusal already freezes `target` at
  close.
- The client surface, CLI, and MCP tools grow in lockstep
  ([`../02-DESIGN/services.md`](../02-DESIGN/services.md),
  [`../02-DESIGN/mcp-server.md`](../02-DESIGN/mcp-server.md)); the
  search index learns the target filter; the audit walk nets the
  target invariants.
- Retirement stays guardless, as 0015 made it for projects: a release
  some item still targets can retire; new `target` writes refuse the
  retired slug, existing values stand, and the audit's
  terminal-release check nets the strays.
- The `impire-marketplace` builder skill follows under playbook 06
  once a release carries the verbs, as with 0015 and 0016.
- The build routes through playbook 04 in the `hits` repo; hits-3
  carries the landing order (hits-hq leads, hits follows).
