# How We Deploy

Where [`how-we-build.md`](how-we-build.md) says the durable engineering posture a service is built to, this document says how a built service actually reaches someone running it.

It describes **today's reality**, and today's reality is: **HITS is distributed, not deployed**. There is no HITS-operated environment — by design, not by immaturity: NATS is the only infrastructure (decision [0001](../03-DECISIONS/0001-item-store-architecture.md)), and HITS runs against the NATS system its operator already has (decision [0004](../03-DECISIONS/0004-hits-up.md)). The story therefore ends at the download; everything after it belongs to the operator.

## The release flow

Releases are cut from the `hits` repo, which owns the whole story — the goreleaser config and the release workflow live there, and there are no deployment repos.

Pushing a `v*` tag runs the release workflow: the race-detected test suite first, then goreleaser builds and publishes a GitHub release on `impire-io/hits` — one archive per platform (linux, darwin, windows × amd64, arm64) with checksums and a changelog, the version stamped into every binary.

**The shipped set is `hits` and `hits-mcp`** (decision [0004](../03-DECISIONS/0004-hits-up.md)): together they cover every way of using HITS — `hits up` runs the whole service fleet in one process, the client commands and the MCP server operate it. The standalone fleet binaries stay buildable from source and join the archives when a production consumer asks.

The first release, `v0.0.1` (2026-09-02), predates decision 0004 and shipped `hits` and `hits-node` — a set that could not actually run the fleet. Releases cut since carry the decided set.

## What running it takes

Nothing is pre-provisioned. The operator points at a JetStream-enabled NATS system through a NATS context — Synadia Cloud or their own server — and `hits-node` creates the ops-log stream and the projection buckets on boot. One HITS per account or JetStream domain ([`../02-DESIGN/hits-up.md`](../02-DESIGN/hits-up.md)). Getting started is `hits up --context <name>`; composed production runs the standalone fleet binaries the same way.

## If a live environment ever exists

A HITS-operated install — a shared demo, a hosted offering — would be a new decision, and this document would take on the deployment content the placeholder here used to promise: which repos own the desired state, how it is applied, what must exist before first enable, and what "deployed" means beyond a green pipeline. Until that decision, any deployment assumption in a design is a deviation and needs its defense inline ([context.md](context.md)).
