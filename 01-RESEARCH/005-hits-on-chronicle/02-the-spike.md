# The spike — HITS's model on chronicle as it stands

Question 12 of the [overview](00-overview.md), run on 2026-10-15 against
chronicle 0.6.0 — the brew-installed binary, which does not yet carry
chronicle-hq 0057's build (`--verified`, the verified write) — with the
types [`01-the-mapping.md`](01-the-mapping.md) describes and the choices
decision [0019](../../03-DECISIONS/0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md)
made. One quick start on port 4571 with its own data dir, one store, four
types, one initiative, one project, one release, two items, three indexes.
Everything below is what happened, in order; the findings follow, then
what they change in the mapping.

## What was run

**The store and the types.** `chronicle store create hits --history full`,
then four type files ([appendix](#appendix--the-type-files)): `release`
first, because `initiative` names it as a child, then `initiative`,
`project`, `item`. Every one was accepted on the first try, and the echo
listed what it defined — for `initiative`, `children: releases→release`;
for `item`, eleven operations, `note (none)` among ten merges.

**The counter.** `instance create initiative/chronicle` with `next: 1`
(sequence 1) and `instance create project/chronicle-hq` with its
initiative written as the path `initiative/chronicle` (sequence 2). Then
the mint under the guard:

```
chronicle instance get initiative/chronicle --output json      # seq 1
chronicle instance apply initiative/chronicle mint --data '{"next":2}' --expect 1
    applied mint to initiative/chronicle (sequence 3)
chronicle instance apply initiative/chronicle mint --data '{"next":3}' --expect 1
    chronicle: initiative/chronicle moved past the expected sequence: read it again
    (chronicle instance get initiative/chronicle) and retry with its sequence
```

**The item and its lifecycle.** `instance create item/chronicle-1` with
the created payload — type, status `open`, priority, the initiative and
`located-in` as paths, the report, the reporter, `created` (sequence 4).
A second create of the same path: *item/chronicle-1 already exists in
store hits* — the create-only guard. Then, each one accepted:

| Sequence | Operation | Data | State afterwards |
|---|---|---|---|
| 5 | `claim` | `claimed-by: member/calmera`, `claimed` | both fields present |
| 6 | `note` (effect `none`) | the text, author, at | unchanged |
| 7 | `block` | `status: blocked`, `blocked-by: item/chronicle-2`, `interrupted: open` | all three present |
| 8 | `unblock` | `status: open`, `blocked-by: null`, `interrupted: null` | the two fields gone, status `open` |
| 9 | `link` | `links: {relates-to: [item/chronicle-2]}` | the map present |
| 10 | `transition` | `status: resolved`, `closed`, `fixed-by`, the claim fields `null` | resolved, closed, the claim gone |
| 11 | `transition` | `status: open` | **applied**: status `open`, `closed` and `fixed-by` still there |
| 12 | `transition` | `status: resolved` | put back |

Sequence 11 is the illegal one — a transition out of a terminal status —
and chronicle folded it, as the mapping said it would. Two refusals that
were expected came as expected: an undefined operation (*item defines no
operation "bogus". It defines: block, claim, create, …*) and a `claim`
without `claimed` (*the data does not fit the operation's schema … missing
property 'claimed'*), both before anything was sent.

**The release and the legacy id.**
`instance create initiative/chronicle/releases/0_7_0` with `slug: 0.7.0`
(sequence 13); the same path with the dot, refused: *path
"initiative/chronicle/releases/0.7.0": segments are separated by "/", not
"." (a path is type/id, with /name/id for each child)*.
`instance create item/23` (sequence 14): a bare legacy id is an id.

**Listings and history.** `instance list --in initiative/chronicle`
printed the release with `NAME` and `SLUG` columns from its state;
`instance list --type item --where status=open` printed `item/23` only;
`instance list --type release` printed *no instances of type release* —
a type listing excludes children; `instance list --type initiative`
printed `NEXT 2`. `instance history item/chronicle-1` printed nine rows,
author `admin` — the quick start's one user — and a `TIME` column;
`instance history initiative/chronicle --children` printed the create,
the mint and the release child in one order with a `PATH` column.

**The indexes.** Three declared, each *serves once it has read the
history*, and all three served within the next sentence:

```
chronicle index create text       --kind search --source history
chronicle index create text-state --kind search
chronicle index create rel        --kind graph --config rel.json   # seven field rules
chronicle index query text pumpernickel          →  item/chronicle-1  0.5669   1 of 1
chronicle index query text-state pumpernickel    →  0 of 0
chronicle index query text spike                 →  item/chronicle-1  0.5291   1 of 1
chronicle index query rel --from item/chronicle-1
    item/chronicle-1  initiative  initiative/chronicle
    item/chronicle-1  located-in  project/chronicle-hq
    item/chronicle-1  relates-to  item/chronicle-2                 3 of 3
chronicle index query rel --from project/chronicle-hq --direction in
    item/chronicle-1  located-in  project/chronicle-hq             1 of 1
chronicle index query rel --from initiative/chronicle --direction in
    item/23, item/chronicle-1, project/chronicle-hq → initiative   3 of 3
chronicle index query rel --from item/chronicle-1 --depth 2 --direction both
    initiative/chronicle 1, project/chronicle-hq 1, item/chronicle-2 1, item/23 2 (via initiative)
```

*pumpernickel* lives only in the note; *spike* in the report, which is
the create's data.

## Findings

1. **The model holds on chronicle as it stands.** Every row the mapping
   marked *holds* or *convention* did what the mapping said, on the first
   try, with no refusal but the expected ones. The four types, the
   counter under the guard, the create-only guard, blocked-with-memory
   written and restored by the client, the claim pair deleted by `null`,
   the links map, the closing stamp, the legacy id: all as mapped.
2. **The lifecycle gap is real and visible** — sequence 11. The
   transition out of a terminal status folded, and it also left `closed`
   and `fixed-by` behind on an open item. chronicle-hq decision 0059's two
   rules answer both halves: a precondition on `transition` (`status` not
   terminal) marks the operation, and the type's schema as the shape every
   state keeps marks the leftovers if HITS's schema says an open item
   carries no `closed`. HITS's own client never writes either; the mark
   is for the raw writer.
3. **The dot and the underscore.** The path grammar refused the dot with
   a teaching message and accepted `0_7_0`; the slug itself in state
   prints as a column. A type listing excludes children, so a release
   listing is `instance list --in initiative/<slug>` — which is what
   `hits release list` is today, per initiative.
4. **One history-sourced search covers the report and the trail.** The
   note's word was found by the history-sourced index and not by the
   state-sourced one (chronicle-hq 0020, as chronicle-12 validated it),
   and the report's word was found too, because a create's data is an
   operation like any other.
5. **The graph from fields is the graph HITS has.** Every edge
   `services.md` § the graph derives that the spike declared appeared,
   in both directions and on a walk, and the dangling `item/chronicle-2`
   was an edge. **Targets must be paths**: the in-direction query on
   `project/chronicle-hq` found the item because the field held
   `project/chronicle-hq`, not `chronicle-hq`.
6. **The history's time is `Op-Ts`.** The `TIME` column prints the
   operation's `Op-Ts` (`cli/instances.go`), the author-claimed clock —
   so an import that sets `Op-Ts` to the original `at` shows the
   original time on every history read, and decision 0019 point 3 holds
   on the surface, not only in the record.
7. **A note's data is its text.** The spike wrote `author` and `at`
   into the note's data as HITS's envelope has them; on chronicle both are
   the operation's own — `Op-Author` and `Op-Ts` — and a trail read
   takes them from the record. The data shrinks to `{text}`.
8. **Not exercised, and why.** The verified write and `--verified`
   (0.6.0 predates the 0057 build); the semantic kind (no provider
   configured); `tombstone` (a merge like the others); and **the corpus
   replay** — the CLI stamps its own `Op-Author` and `Op-Ts`, so writing
   an operation with the original actor and time needs the Go client,
   and that is the one piece of the mapping the spike leaves unproven.

## What this changes in the mapping

- The `note` operation's schema requires `text` only; author and time
  are the record's (finding 7).
- HITS's `item` schema states the terminal shape — `closed` required when
  `status` is `resolved` or `wontfix`, absent otherwise — so that
  chronicle-hq 0059's second rule has something to judge (finding 2); the
  preconditions per operation are question 1's to write.
- A release listing is per initiative (finding 3); the mapping's query
  table gains the sentence.
- The corpus replay (question 9) is the next thing to prove, with a
  small Go program on the `client` package against the real `hits-ops`
  stream, before the cutover is designed.

## Appendix — the type files

```yaml
# initiative.yaml — the counter lives here
schema:
  type: object
  properties:
    slug: { type: string }
    name: { type: string }
    description: { type: string }
    next: { type: integer, minimum: 1 }
    retired: { type: boolean }
    reason: { type: string }
  required: [slug, name, next]
history: full
children:
  releases: release
operations:
  create: { schema: { type: object, required: [slug, name, next] }, effect: merge }
  mint:   { schema: { type: object, required: [next], properties: { next: { type: integer, minimum: 1 } } }, effect: merge }
  retire: { schema: { type: object, required: [retired, reason] }, effect: merge }
```

```yaml
# release.yaml — a child of its initiative; the id is the slug's dots as underscores
schema:
  type: object
  properties:
    slug: { type: string }
    name: { type: string }
    description: { type: string }
    shipped: { type: boolean }
    refs: { type: array, items: { type: string } }
    note: { type: string }
    retired: { type: boolean }
    reason: { type: string }
  required: [slug, name]
history: full
children: {}
operations:
  create: { schema: { type: object, required: [slug, name] }, effect: merge }
  ship:   { schema: { type: object, required: [shipped, refs] }, effect: merge }
  retire: { schema: { type: object, required: [retired, reason] }, effect: merge }
```

```yaml
# project.yaml
schema:
  type: object
  properties:
    slug: { type: string }
    name: { type: string }
    description: { type: string }
    initiative: { type: string }
    retired: { type: boolean }
    reason: { type: string }
  required: [slug, name, initiative]
history: full
children: {}
operations:
  create: { schema: { type: object, required: [slug, name, initiative] }, effect: merge }
  assign: { schema: { type: object, required: [initiative] }, effect: merge }
  retire: { schema: { type: object, required: [retired, reason] }, effect: merge }
```

```yaml
# item.yaml — as run; finding 7 shrinks note's schema to text only
schema:
  type: object
  properties:
    type: { type: string, enum: [bug, task, improvement] }
    status: { type: string, enum: [open, diagnosing, located, blocked, resolved, wontfix] }
    priority: { type: string, enum: [high, normal, low] }
    initiative: { type: string }
    target: { type: string }
    report: { type: string, maxLength: 8192 }
    reporter: { type: string }
    created: { type: string }
    claimed-by: { type: string }
    claimed: { type: string }
    blocked-by: { type: string }
    interrupted: { type: string }
    located-in: { type: array, items: { type: string } }
    discovered-while: { type: string }
    lands: { type: array }
    fixed-by: { type: array, items: { type: string } }
    amended-design: { type: array, items: { type: string } }
    closed: { type: string }
    links: { type: object }
    tombstoned: { type: boolean }
    tombstone-reason: { type: string }
  required: [type, status, priority, report, reporter, created, initiative]
history: full
children: {}
operations:
  create:     { schema: { type: object, required: [type, status, priority, report, reporter, created, initiative] }, effect: merge }
  note:       { schema: { type: object, required: [text, author, at] }, effect: none }
  edit:       { schema: { type: object }, effect: merge }
  transition: { schema: { type: object, required: [status] }, effect: merge }
  claim:      { schema: { type: object, required: [claimed-by, claimed] }, effect: merge }
  release:    { schema: { type: object }, effect: merge }
  block:      { schema: { type: object, required: [status, blocked-by, interrupted] }, effect: merge }
  unblock:    { schema: { type: object, required: [status] }, effect: merge }
  link:       { schema: { type: object, required: [links] }, effect: merge }
  unlink:     { schema: { type: object, required: [links] }, effect: merge }
  tombstone:  { schema: { type: object, required: [tombstoned, tombstone-reason] }, effect: merge }
```

```json
{"edges":[{"field":"links.relates-to","label":"relates-to"},{"field":"links.duplicates","label":"duplicates"},
          {"field":"located-in","label":"located-in"},{"field":"initiative","label":"initiative"},
          {"field":"target","label":"targets"},{"field":"claimed-by","label":"claimed-by"},{"field":"blocked-by","label":"blocked-by"}]}
```
