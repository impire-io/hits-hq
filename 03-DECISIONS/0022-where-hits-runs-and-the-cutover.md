# 0022 — Where HITS runs, and the cutover: an account per install, `hits store init`, one replay, two releases

**Date:** 2026-10-17 · **Status:** decided (graduates research [005](../01-RESEARCH/005-hits-on-chronicle/00-overview.md) questions 6, 9 and 10; with [0020](0020-the-store-four-types-their-preconditions-the-trail-as-history-and-three-indexes.md) and [0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md))

## Context

HITS owned no infrastructure beyond NATS (decision
[0004](0004-hits-up.md)); on chronicle it owns none at all. What is left
to say is where a HITS lives — an account — how one comes to exist, and
how the running install, with its hundred and thirty-four items that four
hqs cite by id, moves without re-filing a single one. The
[replay](../01-RESEARCH/005-hits-on-chronicle/03-the-replay.md) proved the
move reproduces the install exactly and is the cutover's acceptance test;
decision [0018](0018-hits-runs-on-chronicle.md) point 5 said the moment is
a release of this project.

## Decision

1. **A HITS is one store in one account.** The account is the isolation
   boundary, as it was ([0004](0004-hits-up.md)); the store is `hits`;
   an initiative is a lens inside it ([0016](0016-initiatives.md)).
   Self-hosted, the account is whatever chronicle's node serves on the
   operator's NATS; hosted, it is an account at chronicle.impire.dev.
   **The shared Impire install is a hosted account, `impire`**, whose
   members are the people who file — by GitHub login — and whose service
   accounts are the agents that act.

2. **`hits store init` is the installer, and the install manifest is its
   declaration.** Against a chronicle context, it creates the store with
   full history, defines the four types, declares the three indexes and
   writes the announcement — an instance of chronicle's `solution` type
   (chronicle-hq design 14) — all create-if-absent, so running it again
   finishes what was left. The same declaration is published as the
   install manifest chronicle-hq decision 0054 shapes, `install.json` in
   the `hits` release, so that a hosted console may one day enable it;
   HITS has no interface of its own, and the manifest's `url` stays
   empty until it has one.

3. **The cutover is one freeze, one replay, one verification, one
   repoint.** On the day: the install's writers stop (`hits-node` is
   stopped; every writer connects through it, so nothing lands);
   `hits migrate` reads `hits-ops` from sequence 1 and writes every op
   into the `impire` account's `hits` store with its id, actor and time
   on the record, as the replay did; the verification compares every
   entity's state to the install's own snapshot, every note's author and
   time, and counts the marks — zero, or the cutover stops and the store
   is destroyed with the account's own hands; then every member and agent
   repoints: `chronicle login` for a person, a service-account credential
   for an agent, the `hits` release of point 4 installed. The old
   stream's final export goes to the offline store; the old install is
   not deleted until the first week on chronicle has passed.

4. **Two releases, registered under [0017](0017-release-targeting.md).**
   `hits 0.8.0` — the client on chronicle, the fleet gone, `hits store
   init`, `hits migrate`, the install manifest; it ships the day the
   cutover is done, with the cutover's reads as its evidence. `hits
   0.9.0` — `hits migrate` removed, the migration's one use spent.
   Nothing between them is planned.

5. **The hosted environment hosts nothing of HITS.** No binary on a
   chronicle host, no unit, no page: a member's `hits` on their own
   machine and an agent's `hits-mcp` beside the agent are the whole
   deployment. A tenant workload for HITS (chronicle-hq research 014
   question 8) has nothing to run.

## Alternatives rejected

- **A store per initiative, or an account per project.** The corpus is
  one query wide and a tracker's value is the cross-initiative memory;
  an initiative is a lens by decision.
- **A dual-write transition** — the old node writing to both stores for
  a while. Two records of one tracker, and a node that can disagree with
  itself; the freeze is minutes and the replay reproduces everything.
- **Re-filing the corpus.** Refused in [0018](0018-hits-runs-on-chronicle.md).
- **A hosted HITS service or page.** Nothing to serve: the store and the
  indexes are chronicle's, the clients are the members'.
- **Keeping `hits migrate` in the binary.** A migration is one act; a
  verb that reads another tracker's stream has no second user and is a
  side door waiting to be misused.

## Consequences

- [`the-cutover.md`](../02-DESIGN/the-cutover.md) is written: the
  account and its members, `hits store init` and the manifest, the
  cutover's steps and its acceptance test, the two releases.
- Releases `0.8.0` and `0.9.0` are registered in the `hits` initiative
  when the build opens; the build of [0020](0020-the-store-four-types-their-preconditions-the-trail-as-history-and-three-indexes.md)
  and [0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md)
  targets `0.8.0`.
- The `impire` account is created on chronicle.impire.dev by Daan's
  sign-in before the cutover, its members invited by login; the cutover
  itself is run by a person on the day, with the design's checklist.
- chronicle-hq research 014 question 8 gets its answer: HITS runs no
  workload; what the port asked of chronicle was chronicle-hq decision 0059,
  and nothing else.
