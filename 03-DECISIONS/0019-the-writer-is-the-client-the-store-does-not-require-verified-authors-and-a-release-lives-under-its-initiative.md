# 0019 — The writer is the client, the store does not require verified authors, and a release lives under its initiative

**Date:** 2026-10-15 · **Status:** decided (settles research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md) questions 3 and 6 and the release row of question 1; tracker hits-6; the ask it files is chronicle-75, answered by chronicle-hq decision 0059)

## Context

[`01-the-mapping.md`](../01-RESEARCH/005-hits-on-chronicle/01-the-mapping.md)
ended in three gaps: an author a verified writer names, a dot inside an
instance id, and lifecycle rules chronicle does not enforce. Daan's
direction (2026-10-15): address them. Four facts were checked against
chronicle's code and record that day, where the mapping had only its
designs:

- An instance id segment is `[a-zA-Z0-9_-]+` (the `bad-instance` code of
  the SDK contract): an underscore is legal, a dot is not.
- The verified write stamps `Op-Author` from the caller's subject and
  **refuses a header naming another** (chronicle-hq 0057 point 3, design
  02 § the verified write): a verified writer cannot name an author it
  acts for, by design.
- The fold judges an operation's data against the operation's schema and
  a snapshot's state against the type's schema, and nothing about the
  state an operation meets or the state a merge leaves
  (`contract/judge.go`).
- `Op-Ts` is a header on every operation — the author-claimed clock,
  informational, never used for order (design 02 § the operation record).

## Decision

1. **The writer is the client.** The invariants of
   [`item-model.md`](../02-DESIGN/item-model.md) live in the `client`
   package — one package, the CLI's and the MCP server's — and every
   write is a read of the state, a check, and an apply through chronicle's
   node with the expected-sequence guard, so that the author is verified
   and a stale check is refused rather than applied. No HITS service
   stands on the write path. The single-instance rules — the lifecycle,
   the claim pair, terminal and tombstoned items, `located` with a
   project — are also declared on the types as preconditions and as the
   type's schema, which is the ask filed as chronicle-75 and answered by
   chronicle-hq decision 0059: once built, a raw writer's violation is
   marked *invalid* by the fold instead of folded; until then the audit
   is the net, as it is for refs today. Cross-instance rules — a
   registered project, an unshipped release, the ship gate — stay the
   client's read followed by a guarded write, the per-subject window
   `hits-node` has today.

2. **The store does not require verified authors; every live write is
   verified anyway.** `hits store init` creates the store with `full`
   history and without `--verified-authors`. The client always writes
   through the node, so every operation HITS itself writes carries a
   verified author, and `hits get` and `instance history` say so per
   operation. The requirement is forgone for one reason: the migrated
   corpus carries authors chronicle cannot vouch for, and in a store that
   requires verification every migrated operation would be marked and
   move no state. An attested import is not asked of chronicle; the
   condition that would make it an ask is a second solution importing a
   history. The audit lists an unverified operation after the cutover
   sequence as suspect.

3. **The corpus's authors and times ride on the record, not in the
   data.** A migrated operation's author is its original actor as
   `Op-Author`, asserted — the writer's word, which is exactly what it was
   in `hits-ops` ([0002](0002-projects-and-actors.md)); its original time
   is `Op-Ts`; its original op id is the message id. The mapping's sixth
   row closes as *holds*: chronicle's record has a place for every field
   the envelope had.

4. **A release lives under its initiative, and a dot becomes an
   underscore.** The path is `initiative/<initiative>/releases/<id>`, a
   child of the initiative, with the id the release slug's dots replaced
   by underscores — `0.7.0` is `0_7_0` — reversible because neither slug
   grammar admits an underscore, and the slug itself in state.
   Per-initiative uniqueness is the nesting; `hits release list` is a
   listing of the initiative's children; a `targets` edge points at the
   path. Nothing is asked of chronicle.

5. **The mapping's other conventions stand as written**: the counter as
   two guarded writes with a gap on a crash and never a reuse; search
   filters as the client's join; tombstones filtered by every reader;
   arrays in state replaced whole under the guard.

## Alternatives rejected

- **A sole-writer service in front of the store.** It keeps the hard
  refusal and loses either the real author (the service is what chronicle
  vouches for) or the verification (the service asserts the author in a
  store that does not require it); it is a workload to run, which on the
  hosted form waits on chronicle-hq research 014; and with chronicle-hq
  0059 the fold refuses what the service would have.
- **Require verified authors and re-attribute the import** to an importer
  with the original actor in the data. Re-attribution is what
  [0018](0018-hits-runs-on-chronicle.md) point 5 forbids: the record
  would say `importer` did a hundred and twenty-five items' worth of work.
- **A dot encoded as a hyphen.** `0-7-0-rc-1` cannot be read back; the
  underscore can.
- **A release at the top level with a composite id** (`release/hits-0_7_0`).
  Initiative slugs and release slugs both admit hyphens, so two different
  pairs can spell one id; nesting is the model's own per-initiative
  uniqueness, said in the path.
- **Wait for chronicle's answer before choosing the writer.** The client
  package carries the rules under every shape; what 0059 changes is
  whether a raw writer's violation is seen, not where HITS checks.

## Consequences

- Research 005: questions 3 and 6 are settled, and the release row of
  question 1; the rest of question 1 and questions 2, 4, 5 and 7 to 12
  stay open and the spike runs under these choices. The mapping is
  annotated, not rewritten.
- chronicle-75 is filed in the `chronicle` initiative with its landing
  order on chronicle-hq's side; HITS's types declare their preconditions
  in the design that graduates question 1, and the build that first runs
  on chronicle may precede chronicle's, with the audit as the net.
- At graduation the posture *every component is a NATS micro service* in
  [`how-we-build.md`](../00-META/how-we-build.md) is re-read against a
  HITS that has no service: declarations plus a client, the shape
  chronicle-hq research 013 question 7 named for a solution.
  [`services.md`](../02-DESIGN/services.md) retires then, not now.
- The audit gains two reads when the port lands: the gaps in each
  initiative's numbering, and the unverified operations after the cutover
  sequence.
