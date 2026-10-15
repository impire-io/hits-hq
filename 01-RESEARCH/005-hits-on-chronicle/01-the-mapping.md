# The mapping — HITS's model on chronicle as it stands

Written 2026-10-14, on paper, against chronicle 0.6.0 and its record
(chronicle-hq designs 02, 03, 05, 07 and 12; decisions 0011, 0015, 0018
to 0022, 0045, 0049, 0054 and 0057) and HITS 0.7.0 and its
([`item-model.md`](../../02-DESIGN/item-model.md),
[`ops-log.md`](../../02-DESIGN/ops-log.md),
[`services.md`](../../02-DESIGN/services.md)). Nothing here has run yet;
the spike (overview question 12) checks the rows marked for it. Each row
ends in one of three verdicts: **holds** — chronicle offers it as is;
**convention** — it holds once HITS writes it a particular way, with no
ask of chronicle; **gap** — chronicle has to grow, or HITS has to give
something up, and the choice is a decision. The gap list at the end is the
one chronicle-38's fourth ask wanted.

## The account and the store

A HITS install is one account — the account is the isolation boundary
(decision [0004](../../03-DECISIONS/0004-hits-up.md)), and chronicle's
unit of tenancy is the account. The whole corpus is one store: an
initiative is a lens, not a wall ([0016](../../03-DECISIONS/0016-initiatives.md)),
every reader keeps the whole corpus by default, and chronicle has no
cross-store query, so one store is what keeps the corpus one query wide.
The store's history policy is `full` — items are kept forever, and
chronicle's 0019 was made on 2026-09-16 for exactly this (chronicle-11).
Whether the store requires verified authors is question 6 below.
**Holds.**

## The entities as types

| HITS entity | Chronicle | Verdict |
|---|---|---|
| item `chronicle-38`, legacy `23` | type `item`, path `item/chronicle-38`, `item/23`. IDs are `[a-z0-9-]`, no dots — legal as an instance id. | holds |
| project `chronicle-hq` | type `project`, path `project/chronicle-hq`. | holds |
| initiative `chronicle` | type `initiative`, path `initiative/chronicle`; its state carries the counter (below). | holds |
| release `hits` / `0.7.0` | type `release`. **The slug contains dots and a dot is chronicle's stored path separator** (`invoice/inv-1/comments/c-3` is stored `invoice.inv-1.comments.c-3`): `release/0.7.0` would read back as a path of three segments. Per-initiative uniqueness also needs the initiative in the path — `initiative/hits/releases/0.7.0` as a child keeps the uniqueness and still has the dots. An encoding of the slug in the id with the slug itself in state, or a path grammar that admits a dot inside a segment, is the choice. | **gap** — spike checks what ids chronicle accepts |
| note | an operation `note` with effect `none` on the item: the trail *is* the history, as [`item-model.md`](../../02-DESIGN/item-model.md) § bodies says, and `instance history item/x` prints it. The alternative, a child `item/x/notes/n-1`, makes the trail state and lets `instance list --in item/x` list it; chronicle's 0049 reads an item and its children in one order either way. | holds — question 1 picks |
| link | a map in state, one field per link type: `links: {duplicates: [paths], relates-to: [paths]}`; `link` and `unlink` are read-modify-write of the field under the guard, since a merge replaces an array whole. A child per link would need a delete chronicle does not have. | convention |
| claim | state fields `claimed-by`, `claimed`, written by `claim`; `release` writes both `null`, which a merge deletes. A steal carries the displaced claimant in the op's data, so attribution survives in history as today. | holds |
| block with memory | `block` merges `status: blocked`, `blocked-by` and `interrupted`; `unblock` merges `status: <interrupted>` and nulls the two. The memory lives in state and the *writer* restores it — chronicle's merge cannot compute, so the client reads the state under the guard and writes the restore. The record still remembers; the restoring hand changes. | convention |
| tombstone | `tombstone` merges `tombstoned: true` and the reason. HITS's projections drop a tombstoned item from every view; chronicle's indexes and listings do not know the field, so **every reader filters it**. | convention |
| the closing stamp | `transition` to a terminal status merges `status`, `closed`, `fixed-by`, `amended-design`; the writer stamps the date, as `hits-node` does now. | holds |

A type's history policy is `full` for all four. The item's `create`
carries the report, the type, the priority, the initiative echoed from the
ID and, when known, `located-in`, `target` and `discovered-while` — the
`created` payload as it is.

## The op catalog as operations

Chronicle's effect vocabulary is `merge` and `none`
(chronicle-hq decision 0011);
the writer computes every field a merge needs.

| HITS op | Operation on `item` | Effect | Data the writer sends |
|---|---|---|---|
| `created` | `create` | merge | the created payload; chronicle's create-only guard refuses a second create on the path |
| `noted` | `note` | none | text, author, at |
| `edited` | `edit` | merge | the changed properties; `lands` and `located-in` whole |
| `transitioned` | `transition` | merge | status; on close `closed`, `fixed-by`, `amended-design` |
| `claimed` | `claim` | merge | `claimed-by`, `claimed`; on a steal the displaced claimant |
| `released` | `release` | merge | `claimed-by: null`, `claimed: null` |
| `blocked` | `block` | merge | `status: blocked`, `blocked-by`, `interrupted` |
| `unblocked` | `unblock` | merge | `status` restored, `blocked-by: null`, `interrupted: null` |
| `linked`, `unlinked` | `link`, `unlink` | merge | the `links` map, whole |
| `tombstoned` | `tombstone` | merge | `tombstoned: true`, reason |

On `project`: `create` (the registration — name, description,
initiative), `assign` (merge, the initiative), `retire` (merge, the
reason, `retired: true`). On `initiative`: `create`, `retire`, and `mint`
(below). On `release`: `create`, `ship` (merge, the refs and the note,
`shipped: true`), `retire`.

The envelope maps field for field: the op `id` is the SDK's message id
(chronicle's publish dedup); `actor` is `Op-Author`; `entity` is the
path; `v` is `Op-Version`; `payload` is the data. **`at` does not map**:
chronicle's history time is the stream's time of the write, so an
operation's original time — which only matters for migrated ops — rides
in the data. **Holds** for live writes; **convention** for migrated ones
(§ the corpus).

## The ID mint

HITS mints `<initiative>-<n>` from a dense per-initiative counter,
atomically ([`ops-log.md`](../../02-DESIGN/ops-log.md) § identifiers).
Chronicle has no counter and no lock; it has the expected-sequence guard
(chronicle-hq decision 0018,
made for this on 2026-09-16, chronicle-10). The shape: the initiative's
state carries `next`; a `mint` operation merges `next: n+1` with
`--expect` on the sequence the writer read; the loser of a race is refused
and retries; the winner's `n` is its ID; then `create item/<slug>-<n>`,
which the create-only guard makes refuse a duplicate. Two writes on two
subjects, not one atomic act: a crash between them spends `n` and files
nothing — **a gap in the numbering, never a reuse**. `hits-node` today has
the same two subjects and the same window, serialized by the same
per-subject CAS, so the guarantee is equal; what changes is that the
retry loop moves to wherever the writer lives (question 3).
**Convention**; an ask only if a gap ever matters, and the audit can list
them.

## The invariants and where they are enforced

Chronicle checks one thing on a write: the operation's data against the
operation's schema — pre-flight in the SDK and the CLI, and in the fold,
where a failing operation is kept in history, marked *invalid*, and moves
no state. It checks nothing across operations, nothing across instances,
and nothing about the order of statuses. `hits-node` checks all of that
before it appends.

| Invariant ([`item-model.md`](../../02-DESIGN/item-model.md)) | Chronicle | Left to the writer |
|---|---|---|
| each op's payload has its shape; budgets 8 KiB and 1 KiB | the op schema; `maxLength` counts characters, not bytes — close, not equal | the byte count, if it must be bytes |
| transitions follow the lifecycle; terminal accepts nothing | nothing — a `transition` to `open` on a resolved item folds | all of it |
| `blocked-by` only while blocked; the claim pair set and cleared together; `located` needs `located-in`; a task is created with `located-in` | the *type* schema can state some of this on state with `if`/`then` — whether the fold marks state that fails the type schema, or only op data, the spike checks | the rest |
| `located-in` names registered, unretired projects of the item's initiative; `target` names a registered, unshipped, unretired release; creation names an unretired initiative | nothing across instances | a read of the other instance, then a write guarded on this one — the same per-subject window `hits-node` has today |
| `ship` refused while any non-terminal item targets the release | nothing | a listing of open items with the target, then a guarded write on the release (question 11) |
| a tombstoned item accepts no further ops | nothing | all of it |
| every command names an actor of the right form | `Op-Author` is chronicle's, validated by chronicle | nothing |

So the per-op schemas move to chronicle and **everything lifecycle-shaped
stays with a writer**. Three places it can live, each with a cost:

- **One HITS service, the store's only writer** — `hits-node` with
  chronicle underneath. The invariants stay where they are, raw writers
  are kept out by giving nobody else a writer credential, and the author
  chronicle sees is the service. Under chronicle's 0057 the node vouches
  for the *connected* principal: a service writing for `calmera` either
  writes `Op-Author: calmera` unverified — legal in a store that does not
  require verified authors, and exactly today's trust, where the actor is
  the caller's claim ([0002](../../03-DECISIONS/0002-projects-and-actors.md))
  — or chronicle grows a way for a verified writer to name the author it
  acts for. The service is also the thing research 014 on chronicle's
  side would have to run as a workload.
- **Every client, under the guard** — the one `client` package the CLI
  and the MCP server already share carries the invariants; a write is a
  read, a check and a guarded apply; the author is the real one, verified
  where the store asks. A raw writer with a writer credential can bypass
  the package, and the fold folds what it writes; the audit catches it
  after the fact, the way `hits audit` catches a stale ref today. No
  service remains, and nothing of HITS runs anywhere but on the caller's
  machine.
- **A rule chronicle grows** — a transition table or a scripted effect on
  the type, which chronicle's 0044 § 3 foresees and nothing yet asks for.
  The fold would mark an illegal transition the way it marks a schema
  failure. This is the ask if HITS wants the first shape's guarantee with
  the second shape's authors.

**Gap** — the choice is question 3's, and whichever shape loses the
verified author or the hard refusal names an ask.

## Bodies and the trail

The report is in `create`'s data and a note is an effect-`none` `note`:
one history-sourced search index (chronicle's 0020, chronicle-12 —
validated with "text living only in an effect-none note op") finds both,
reading every operation's payload and answering with the item. `fields`
on a semantic index narrows the same way. The budgets become `maxLength`
on the schemas. `hits get` prints the trail from `instance history`
rather than from the snapshot, unless notes are children (question 1).
**Holds.**

## Links and the graph

Chronicle's graph kind derives edges from state fields: a rule names a
dotted path and a label, a string is one edge, an array one per element,
and the target is an opaque instance path stored as is — a dangling edge
is data (chronicle-hq decision 0015).
`services.md` § the graph lists what HITS derives; every row has a field:

| Edge | Rule | Note |
|---|---|---|
| `duplicates`, `relates-to` | `links.duplicates`, `links.relates-to` | one rule per link type, because a label is per rule |
| `located-in` | `located-in` | the state stores **paths** — `project/chronicle-hq`, not the slug — so that `walk` from the project finds the items; a bare slug would be a dangling string nobody walks from |
| `targets` | `target` | a path to the release instance, so the encoding of § the entities decides its spelling |
| `reported-by`, `claimed-by` | `reporter`, `claimed-by` | an actor is not an instance; the target is `member/<login>` as an opaque path, and `neighbors` in-direction on that string answers "everything one actor claimed" |
| `blocked-by` while blocked | `blocked-by` | an item ref is a path; prose is a dangling string, harmless |
| item → initiative | `initiative` | a path; the ID prefix is state already |
| project → initiative | `initiative` on the project | |

Edges are a pure function of current state, recomputed per fold step, so
a lifted block drops its edge and a release ends its `targets` edge
exactly as HITS's graph does. What chronicle's graph does not do is read
history (0020 § 4), and nothing HITS derives needs it.
**Convention** — the fields hold paths.

## Identity and the account

The `actor` becomes the operation's author; a person's handle is their
GitHub login (chronicle's member), and the handles in the corpus today
(`calmera`) already are; an agent is a service account with a writer
role. hits contexts and the token exchange
([0008](../../03-DECISIONS/0008-client-idp-auth.md) to
[0011](../../03-DECISIONS/0011-standalone-hits-contexts.md)) retire for
chronicle's contexts and `chronicle login`.

The one decision is **whether the HITS store requires verified authors**
(chronicle's 0057: `--verified-authors`, set at creation, immutable).
Wanting it is natural — a tracker where every claim is one chronicle
vouched for. It collides with two things: a sole-writer service (above),
and **the migrated corpus**, whose hundred and twenty-five items carry
authors chronicle cannot vouch for; in a store that requires verified
authors every migrated operation would be marked and move no state. So:
the store does not require verified authors and the actor stays the
writer's word, as it is today; or chronicle grows an attested import —
a verified writer naming the author it imports for. The same ask as the
service's, from the other side. **Gap** — one ask, two consumers.

## The indexes and the queries

| HITS | Chronicle | Verdict |
|---|---|---|
| `hits.search.query` — full text over reports and notes, filtered by type, status, initiative, target, paged | a search index, `source: history`, `types: [create, note]`; **no filters** — search is no-knobs on chronicle's side, so the client joins the hits with state (`instance list --type item` is one bucket scan) and filters; a streamed reply with `limit`, no offset | convention — an ask when the corpus makes the join slow |
| `hits.semantic.query` | a semantic index, `source: history`, `fields: [report, text]`; the provider is install configuration on chronicle's side | holds |
| `hits.graph.neighbors`, `walk` | `neighbors` and `walk`, direction, labels, depth — the same two verbs | holds |
| `project.list`, `initiative.list`, `release.list` | `instance list --type project`, retired ones filtered by the client | holds |
| `get` with recent revisions | `instance get` and the state bucket's per-key history | holds |
| the status view | `instance list --type item --where status=open` | holds |

## The surfaces

The CLI's sentences survive: `hits create` composes a mint, a create and
the invariants; `hits resolve` a read and a guarded transition — every
sentence a read, a check and a write through the `client` package,
whichever writer question 3 picks. `hits-mcp` stays what it is, a stdio
client with one tool per endpoint, unless chronicle's MCP server with a
`hits` skill (chronicle-hq research 013) does the job — question 8.
`hits up` becomes `chronicle up` plus `hits store init`, which applies
the install manifest chronicle's 0054 has a solution publish; the same
manifest is what a hosted account enables from the console. `hits audit`
is a client already and stays one. **Holds.**

## The corpus

`hits-ops` from sequence 1, every op one operation on its mapped path in
stream order — which keeps per-item order and the global order alike —
with the actor as `Op-Author`, and the original `at` and op `id` in the
data, because chronicle's history time is the write's. Legacy bare IDs
map as they are (`item/23`); tombstoned items replay as written and stay
filtered; retired projects replay as written and stay retired. Release
slugs hit the dot (§ the entities). The result is verified by reading
every item's state from chronicle and comparing it, field for field, to
the install's snapshot, and by running `hits audit` against both. The
cutover: freeze every writer (every one is a hits context pointing at the
old install), replay, verify, repoint the contexts, retire the stream.
Authors are unverified by construction (§ identity).
**Convention** for time and IDs; **gap** for authors.

## The gap list

> **Addressed 2026-10-15** — see [§ the gaps, addressed](#the-gaps-addressed) below; the list stands as it was found.

What chronicle-38's fourth ask called the maturity gap list, from the
rows above. Each item is an ask of chronicle-hq, a convention HITS
adopts, or a decision of this effort — stated as which.

1. **An author a verified writer names.** A service writing for a person,
   and an import writing the corpus, both need chronicle to let a writer
   it vouches for name the author it acts for — or the HITS store forgoes
   verified authors and the actor stays the writer's word, as today. *An
   ask, or a decision to forgo.*
2. **A dot inside an instance id.** Release slugs are versions; a dot is
   chronicle's path separator. *The spike checks the grammar; then an
   encoding here, or an ask.*
3. **Lifecycle rules.** Chronicle enforces per-op schemas only;
   transitions, the claim pair, terminal and tombstoned items, and every
   cross-instance reference are a writer's. *Question 3's decision; the
   ask, if the writer is to be chronicle, is a transition table or a
   scripted effect on the type.*
4. **A dense counter.** Two guarded writes; a crash leaves a gap, never a
   reuse. *A convention, and the audit lists gaps.*
5. **Search filters.** None on chronicle's side; the client joins hits
   with state. *A convention until the join is slow.*
6. **Original time.** Chronicle's history time is the write's; a migrated
   operation's time is data. *A convention for the migration.*
7. **Tombstones.** No chronicle view drops them; every reader filters.
   *A convention.*
8. **Arrays in state.** A merge replaces an array whole; links and
   `located-in` are read-modify-write under the guard. *Holds; noted so
   nobody expects an append.*

What holds as is, and needs no row: the effects, children, the full
history, the guard, the create-only guard, history-sourced search and
semantic over notes, the graph from fields, the streamed queries, the
listings, and identity for every live writer.

## The gaps, addressed

2026-10-15, decision
[0019](../../03-DECISIONS/0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md),
after checking the four facts its context lists against chronicle's code.

| Gap | Outcome |
|---|---|
| 1 — an author a verified writer names | **Decided, no ask.** No sole-writer service, so no writer acts for a person; the store does not require verified authors, every live write goes through the node and is verified, the import writes the original actor as an asserted `Op-Author` — the writer's word, as it was in `hits-ops`. An attested import waits for a second solution that imports a history. |
| 2 — a dot inside an instance id | **Convention.** An id segment is `[a-zA-Z0-9_-]+`: the underscore is legal, and neither slug grammar admits one, so `0.7.0` is `0_7_0`, reversibly. A release is a child of its initiative, `initiative/<initiative>/releases/<id>`. |
| 3 — lifecycle rules | **Asked, and answered.** chronicle-75: an operation may declare a `precondition` — a JSON Schema the current state must satisfy — and the fold judges a merge's result against the type's schema as it judges a snapshot's; pre-flight on the SDK and on `APPLY` refuses what the fold would mark. chronicle-hq decision 0059, designs 03, 07 and 12 amended; the build follows. HITS's client package enforces regardless; the audit is the net until the build lands. |
| 4 — a dense counter | Convention, as listed; the audit lists gaps. |
| 5 — search filters | Convention, as listed. |
| 6 — original time | **Holds, not a convention.** `Op-Ts` is the author-claimed clock on every operation; the import writes the original `at` there, and nothing goes in the data. |
| 7 — tombstones | Convention, as listed. |
| 8 — arrays in state | Holds, as listed. |
