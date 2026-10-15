# 0018 — HITS runs on chronicle: the model stays, the substrate goes

**Date:** 2026-10-14 · **Status:** decided (Daan's direction of 2026-10-14; tracker hits-6; the solution's side of chronicle-hq decision 0058)

## Context

Daan's direction (2026-10-14): port HITS onto chronicle. Behind it is the
older one tracker item chronicle-38 recorded on 2026-09-22 — hits and
soulstream inspired chronicle and are meant to move onto it — which
chronicle-hq answered for soulstream on 2026-10-11 (its decision 0048,
chronicle-agents) and for HITS on this record's date (its decision 0058).

HITS is the issue system this repo runs on and the one every Impire hq
files into (decision [0013](0013-issue-tracking-cutover.md); chronicle-hq
0009; chronicle-agents-hq 0002). Decision
[0001](0001-item-store-architecture.md) built it by hand on the ops-log
pattern: one stream `hits-ops`, one subject per entity, the op type in the
envelope; `hits-node` the single writer, validating every command against
the item invariants before a compare-and-swap append and folding the log
into the `hits-state` bucket; three index binaries as ordered consumers
rebuilt on boot. Around it: the MCP server ([0003](0003-mcp-server.md)),
`hits up` ([0004](0004-hits-up.md)), the IDP token exchange and hits
contexts ([0008](0008-client-idp-auth.md) to
[0011](0011-standalone-hits-contexts.md)), the single state bucket
([0012](0012-single-state-bucket.md)), initiatives
([0016](0016-initiatives.md)) and releases
([0017](0017-release-targeting.md)). All of it works, is released as
0.7.0, and holds a corpus of a hundred and twenty-five items across four
initiatives that branch names, pull requests, decision records and notes
in every Impire hq cite by ID.

Chronicle began on 2026-09-05 as the productized form of the same
pattern, and now owns what 0001 had to build: a store with types whose
operations declare their effect, children under a parent's prefix, state
derived by the fold, an expected-sequence guard, a full-history store,
search and semantic indexes that read the history and a graph that reads
state, members and service accounts with an author the node vouches for,
SDKs, a CLI, a console, and the shape of a solution — an announcement, an
install manifest, a hosted interface. Three of its decisions were made for
HITS on 2026-09-16, while the migration was assessed from this side and
asks were filed on chronicle's tracker (chronicle-10, 11, 12) without this
repo recording why: the guard on append, the preserved history, the index
that reads the history so that text living only in a note is findable.

What is left is the solution's side: what HITS keeps, what it sheds, and
what it does not yet know.

## Decision

1. **HITS runs on chronicle, as a client.** An item, a project, an
   initiative and a release are instances of types declared in a
   chronicle store; every op of the catalog in
   [`ops-log.md`](../02-DESIGN/ops-log.md) becomes an operation with an
   author in that store's history; the state the CLI prints is
   chronicle's derived state; search, graph and semantic queries are
   chronicle's declared indexes. Chronicle is reached through its SDKs
   and its API only — nothing of HITS touches chronicle's streams,
   buckets or internals, and nothing keeps a second copy of what the
   store holds ([`how-we-build.md`](../00-META/how-we-build.md)).

2. **The model stays; the substrate goes.** What HITS *is* — the item
   model with its types, lifecycle, blocked-with-memory,
   terminal-is-terminal and tombstone; the invariants; the three
   registered vocabularies; the trail of notes; the typed links; the work
   ID; the audit; the definition of done — is HITS's, and moves with its
   meaning unchanged. What HITS built because nothing else offered it —
   `hits-ops`, `hits-state`, `hits-node`'s fold, the three index
   binaries, the token exchange and hits contexts, `hits up` — is
   replaced by chronicle's. Where a piece of the model cannot be kept on
   chronicle as it stands, research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md)
   says so and the answer is an ask of chronicle-hq or an amendment here
   by decision — never a silent drop, never a workaround that keeps a
   piece of the old substrate alive.

3. **Identity is chronicle's.** A person is a member, an agent is a
   service account, and the `actor` every command carries becomes the
   operation's author — vouched for by chronicle where the store requires
   it. The exchange decisions 0008 to 0011 built retire with the port;
   HITS validates no actor of its own once it lands.

4. **The invariants stay enforced; where is research 005's first
   question.** Three shapes are on the table: one HITS service in front
   of the store as its only writer (today's `hits-node`, its storage
   swapped for chronicle); every client enforcing under chronicle's
   expected-sequence guard, through the one `client` package the CLI and
   the MCP server already share; or an admission rule chronicle grows.
   This record does not choose. It binds the outcome: a command that
   would violate an invariant is refused, never partially applied — the
   promise [`item-model.md`](../02-DESIGN/item-model.md) makes today.

5. **The corpus moves as history.** Every op in the running install,
   with its actor, its time and its order, becomes an operation in the
   HITS store — never re-filed, never re-attributed, never re-dated, IDs
   standing. If chronicle's history cannot carry an operation's original
   author or time, that is an ask of chronicle-hq, not a reason to
   re-file. The moment the shared install moves is a release of this
   project, named under [0017](0017-release-targeting.md) when the
   research says what it takes.

6. **The repositories stay.** `hits-hq` is the source of truth, `hits`
   the code — public under the Sustainable Use License, contributions
   under the DCO — and `impire-marketplace` the skill's home. None of
   them joins chronicle's fleet; chronicle-hq's `repos.md` names HITS
   among the solutions built on chronicle.

7. **Gaps are asks of chronicle-hq, by its playbooks.** What chronicle
   lacks for HITS is filed as a tracker item in the `chronicle`
   initiative or proposed as research there, the way chronicle-agents'
   spike did; chronicle decides what it grows. Nothing is worked around
   here, and nothing is decided for chronicle here.

## Alternatives rejected

- **Stay on the hand-rolled substrate.** Two implementations of one
  pattern inside one company, the hand-rolled one maintained beside the
  product that exists to replace it, and the product's own tracker the
  one record not kept on it. The direction says the opposite, and three
  chronicle decisions were already made to make the move possible.
- **Rewrite the model while porting.** Six weeks of daily use across four
  hqs have proven the item model; a port that also redesigns it cannot be
  validated against the live install, and every "while we are at it"
  becomes a reason the corpus no longer folds. One change at a time: the
  substrate now, the model by its own decisions, after.
- **Re-file the corpus by hand**, as the 0013 cutover did for eleven
  records. The cutover's "no migration" was for an empty corpus; this one
  is cited by ID from branches, pull requests and immutable decision
  records in four repositories, and the IDs are the work IDs. A re-filed
  item is a different item.
- **Keep the `hits` wire and put chronicle behind it** — `hits-node` as
  an adapter translating `hits.api.*` into chronicle writes. It keeps the
  second implementation alive, keeps every client blind to chronicle's
  history, verified authors and live reads, and makes the port invisible
  to exactly the readers it is for.
- **Build HITS into chronicle as a chronicle feature.** chronicle-hq
  refused it (0058, as 0048 refused rooms): chronicle is the datastore;
  a solution is what tracks.

## Consequences

- Research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md)
  opens with this record: the mapping of the model onto chronicle's
  constructs, the invariants question, identity, the indexes and the
  surfaces, the corpus migration, where it runs, and a spike against
  chronicle as it stands.
- The postures in [`how-we-build.md`](../00-META/how-we-build.md) are
  re-read at graduation, not now: *the ops-log is the source of truth*
  holds with chronicle's history as the log; *every component is a NATS
  micro service* narrows to whatever service HITS still runs; *headless*
  stands. The posture records are amended by the graduating decisions.
- The designs [`ops-log.md`](../02-DESIGN/ops-log.md),
  [`services.md`](../02-DESIGN/services.md),
  [`item-model.md`](../02-DESIGN/item-model.md) (§ identity,
  § invariants), [`mcp-server.md`](../02-DESIGN/mcp-server.md),
  [`hits-up.md`](../02-DESIGN/hits-up.md) and
  [`idp-auth.md`](../02-DESIGN/idp-auth.md) are rewritten or retired by
  the graduating decisions, and `repos.md`'s `hits` row with them. Until
  then they describe the running install, which keeps running.
- [`context.md`](../00-META/context.md)'s open identity question is
  answered by chronicle's identity when the port lands.
- The `hits-cli` skill and the plugin in `impire-marketplace` follow the
  surface through [playbook 06](../00-META/process/06-builder-skill-sync.md)
  when it changes; the surface's sentences are expected to survive.
- Code lands in `hits` through [playbook 04](../00-META/process/04-build-handoff.md)
  from the rewritten designs, not before. The release that first runs on
  chronicle, and the one that moves the shared install, are registered
  under 0017 when the research names what each takes.
- chronicle-hq decision 0058 is this record's other half; tracker items
  hits-6 and chronicle-73 track the pair.
