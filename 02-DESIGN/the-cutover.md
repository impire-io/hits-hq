---
status: implemented
code: hits
updated: 2026-10-17
---

# Where HITS runs, and the cutover

A HITS is one store in one chronicle account; `hits store init` makes
one; the running install moves by one replay, verified, and two releases
mark the move. Settled by decision [0022](../03-DECISIONS/0022-where-hits-runs-and-the-cutover.md);
the store is [`the-store.md`](the-store.md), the client is
[`the-client.md`](the-client.md), the replay's proof is research
[005](../01-RESEARCH/005-hits-on-chronicle/03-the-replay.md).

## The account

The account is the isolation boundary, as it was under
[`hits-up.md`](hits-up.md): one HITS per account, one store `hits` in
it, initiatives as lenses inside. Self-hosted, the account is the one
chronicle's node serves on the operator's own NATS; hosted, it is an
account at chronicle.impire.dev with a plan. **The shared Impire install
lives in the hosted account `impire`**: its members are the people who
file, by GitHub login, invited by its admin; its service accounts are the
agents that act, each with a credential handed down once. The hosted
environment hosts nothing of HITS — no binary, no unit, no page.

## `hits store init`

The installer, against a chronicle context whose principal is an admin
of the account:

1. create the store `hits` with full history (an existing one is fine);
2. define the four types, `release` first (an initiative names it as a
   child), then `initiative`, `project`, `item` — each as
   [`the-store.md`](the-store.md) states it, a current definition fine;
3. declare the three indexes, `text`, `meaning` and `rel`;
4. write the announcement `solution/hits`, create-if-absent.

Every step is idempotent; running it again finishes what was left, and
running it on a store that already holds items changes nothing but the
declarations. The same declaration is published as the **install
manifest** — chronicle-hq decision 0054's shape — as `install.json` in
the `hits` release, so a hosted console can enable HITS for an account
the day it wants to; the manifest's `url` is empty, because HITS has no
interface.

## The cutover

The moment the shared install moves, run by a person on the day, in this
order; every step names its evidence.

| Step | Act | Evidence |
|---|---|---|
| 0. Before | The `impire` account exists with its admin; every member who files is invited; every agent has a service account and its credential; `hits store init` has been run; the release of § the releases is on every machine that will write. | `chronicle store get hits` in the account; `instance list --type solution` shows `solution/hits` |
| 1. Freeze | Announce; stop `hits-node` on the old install — every writer wrote through it, so nothing lands after this. | `hits ping` refuses; `hits-ops`'s last sequence noted |
| 2. Replay | `hits migrate --from <old hits context> --to <chronicle context>`: every op of `hits-ops` from sequence 1 as an operation on its mapped path, its id as the message id, its actor as the author, its time as `Op-Ts`; a `claimed` with a steal as `steal`; the counters minted last. | the count of operations written equals the stream's; the time it took |
| 3. Verify | The replay's own comparison: every item's, project's, initiative's and release's state equal to the old install's snapshot, every note's author and time equal, no operation marked. | `0 mismatches, 0 marks`; anything else stops the cutover, and the account's admin destroys the store's contents by the account's own hand before a second attempt |
| 4. Repoint | Every person: `chronicle login`, the `impire` account, the `hits` release installed. Every agent: its service-account credential as a chronicle context, `hits-mcp` restarted on it. The hq skills and playbooks that name `hits` contexts or `HITS_ACTOR` are corrected the same day. | `hits get <id>` from a member's machine reads the state chronicle derives; a note written through `hits-mcp` shows the agent as a verified author |
| 5. Retire | The old stream's final export to the offline store; the old `hits up` host left stopped for a week, then its account's streams deleted. | the export's name and digest in the hits initiative's release note |

The tracker is the one record every Impire hq files into; the freeze is
minutes, and nothing is filed during it. A defect found in the week after
is a new item on the new install, never a reason to revive the old one.

## The releases

Two, registered under [0017](../03-DECISIONS/0017-release-targeting.md):

- **`hits 0.8.0`** — the client on chronicle ([`the-client.md`](the-client.md)),
  the fleet gone, `hits store init`, `hits migrate`, the install
  manifest. Cut when the build lands; shipped with the cutover's reads
  as its evidence, since the cutover is the first live use of it.
- **`hits 0.9.0`** — `hits migrate` removed, its one use spent.

Items that must land in the port target `0.8.0`; nothing targets `0.9.0`
but the removal.

## What this does not do

No dual-write transition, no second record of the tracker, no cutover a
machine runs on its own. No account per project, no store per
initiative. No hosted HITS of any kind. No `migrate` beyond the release
that needs it.
