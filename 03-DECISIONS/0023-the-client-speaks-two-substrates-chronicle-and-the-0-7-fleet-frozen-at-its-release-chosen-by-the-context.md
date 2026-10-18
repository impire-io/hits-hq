# 0023 — The client speaks two substrates: chronicle, and the 0.7 fleet frozen at its release, chosen by the context

**Date:** 2026-10-18 · **Status:** decided (amends [0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md) points 3 to 5, [0022](0022-where-hits-runs-and-the-cutover.md) point 4 and [0018](0018-hits-runs-on-chronicle.md) point 3)

## Context

Decisions [0018](0018-hits-runs-on-chronicle.md) to [0022](0022-where-hits-runs-and-the-cutover.md) moved HITS onto chronicle and
took the fleet out of the repository: hits 0.8.0 and 0.8.1 are cut, their
client speaks chronicle alone, and the shared Impire install waits for
its cutover (tracker hits-8). HITS installs on the fleet of release 0.7.0
— `hits up` on an operator's NATS, hits-node and the three index services
— stay in use beyond that cutover, and 0.8.x cannot reach them: a person
who upgrades the client loses the tracker. Daan Gerits stated the
requirement on 2026-10-18: the fleet is not built further, it is frozen
at the v0.7.0 release, and the client must keep speaking to it.

The 0.7 wire contract is small — one request and one reply per sentence
over the `hits.api.*`, `hits.graph.*`, `hits.search.query`,
`hits.semantic.query` and `hits.ping` subjects — and the client that
spoke it is in the repository's history. The hits-context and
token-exchange code of decisions 0008 to 0011 is still on main because
`hits migrate` reads through it.

## Decision

1. **The `client` package is an interface, with two implementations.**
   The request and reply types stay what [0021](0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md) made them;
   `Client` becomes the interface the CLI, `hits-mcp` and the audit call.
   `client/chronicle` is 0021's implementation, unchanged. `client/fleet`
   is the v0.7.0 client restored — one request, one reply per method,
   over the subjects of the frozen contract — with the actor given at
   construction, so no request type carries one. The sentences and the
   tools stay identical on both substrates (0021 point 3 holds).

2. **The context chooses the substrate.** `--context NAME`, or the
   selection, resolves against chronicle's contexts first, then against
   hits's own (the documents of
   [0011](0011-standalone-hits-contexts.md), kept with
   `internal/connect`); a name both hold is refused as ambiguous. With no
   name: chronicle's selection, else hits's default context, else the
   refusal that names both ways to get one. A chronicle context dials the
   store of 0021; a hits context dials the fleet.

3. **The actor returns for the fleet alone.** On a hits context a write
   needs an actor — `--actor`, `HITS_ACTOR`, or the hits config's default,
   in that order, as 0.7 had it — and the 0.7 node validates it as it
   always did; `hits-mcp` takes it at startup, as before. On a chronicle
   context an actor is refused: the author is the context's principal
   (0021 point 4 stands there), and chronicle vouches for nobody on a
   fleet write.

4. **`context`, `auth` and `ping` return.** `hits context` and
   `hits auth` manage hits contexts and the token exchange for them, as
   0.7 had them; they say nothing about chronicle contexts, which
   chronicle's own CLI manages. `hits ping` answers on both substrates
   with the name and version of what answered: the node's on the fleet,
   the store's announcement (`solution/hits`) on chronicle.

5. **The fleet is frozen at the v0.7.0 release.** No fix and no feature
   reaches hits-node or the index services; an install that needs either
   moves to chronicle with `hits migrate`. The client's compatibility
   target is that release's wire contract and nothing else, proven by
   tests that build the v0.7.0 binaries from the tag
   (`go install …@v0.7.0`) and run them on the embedded NATS beside
   chronicle's quick start; a test that cannot build them fails, it does
   not skip. Nothing of the fleet returns to the repository (0021 point 5
   stands).

6. **`hits migrate` stays while a 0.7 fleet exists.** The release that
   was to remove it, 0.9.0 as registered under
   [0017](0017-release-targeting.md), is retired and its slug is spent;
   the two-substrate client is release `0.10.0`, and 0022 point 4's
   "nothing between them is planned" is withdrawn. The cutover of the
   shared install (0022 point 3) is unchanged.

## Alternatives rejected

- **A release branch for 0.7.** The 0.7 line kept alive with fixes beside
  0.8: two codebases, every feature twice or never — and a frozen fleet
  needs no fixes by the requirement.
- **The fleet back in the repository behind a seam.** Node, indexes and
  `hits up` maintained again for a release that is not built further; the
  requirement is a client that speaks, not a fleet that is served.
- **The actor on every request type again.** It would put the fleet's
  identity model back into the chronicle implementation's surface; given
  at construction it stays where it is needed.
- **A flag that names the substrate.** The context already says what it
  dials; a second knob could disagree with it.

## Consequences

- [`the-client.md`](../02-DESIGN/the-client.md) amended (the connection,
  the sentences, the MCP server, the repository, what this does not do)
  and back to `in-progress` until 0.10.0 runs on main;
  [`mcp-server.md`](../02-DESIGN/mcp-server.md) amended (the actor);
  [`the-cutover.md`](../02-DESIGN/the-cutover.md) amended (the account,
  the releases); the posture in
  [`how-we-build.md`](../00-META/how-we-build.md) amended. The `hits-cli`
  skill in impire-marketplace follows through
  [playbook 06](../00-META/process/06-builder-skill-sync.md); the draft
  prepared for the cutover day (impire-marketplace#1) is redrafted.
- The build is tracker hits-10 as release 0.10.0: `internal/connect`
  stays, the lint rule that keeps the adapters on the client stays, the
  test harness gains the v0.7.0 fleet beside the quick start.
- A 0.7 install gets no fix: a defect found on one is answered by its
  move to chronicle, never by a 0.7.1.
- The tap formula, which goreleaser moves on every release, points at
  0.8.1 until 0.10.0 ships; moving it back to 0.7.0 meanwhile is one
  commit on the tap by its operator.
