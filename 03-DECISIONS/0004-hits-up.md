# 0004 — `hits up`: the fleet as one process in the one `hits` binary

**Date:** 2026-09-03

## Context

HITS deliberately owns no infrastructure beyond NATS (decision
[0001](0001-item-store-architecture.md)), so for anyone already running NATS
— Synadia Cloud or their own server — the distance to a working HITS should
be minutes. It is not: getting started means composing four service binaries
by hand, and the release ships only two of them (`hits`, `hits-node`), so a
download-only user cannot run the fleet at all. Research
[001](../01-RESEARCH/001-single-binary-onboarding/) verified that the
connection story is already done (every binary resolves through NATS
contexts), that every service already exposes a `Start(ctx, nc)` entrypoint
at its package root, and that carrying all four service trees costs a
measured ~11 MB (6.6 MB client alone, 17.6 MB with the fleet linked,
stripped). Open were: the shape of the composition, where it lives against
the lint-enforced service boundary, whether the semantic index blocks a
bare-bones start, whether a NATS server gets embedded, and whether one
account can host more than one HITS.

## Decision

- **`up` is a subcommand of the one `hits` binary.** Download `hits`, run
  `hits up --context <name>`, and the same binary is the client you then
  work with. The standalone fleet binaries remain — `up` is the
  getting-started and small-team shape, not a replacement for composing
  services separately.

- **Composition lives in a bounded `internal/fleet` tree, dispatched from
  `cmd/hits`.** `fleet` exposes one `Start` that runs all four services; it
  may import the four service package roots and `contract`, nothing else,
  and nothing imports it back — depguard-enforced in both directions, with
  the existing adapter denials untouched: `cmd/hits/main.go` intercepts
  `up` before `cli.Run` ever parses, so the client tree never sees service
  code. The same amendment closes a hole the research found: depguard
  constrained nothing under `cmd/**`, so each main is now pinned to its own
  service's tree.

- **Inside `up`, each service keeps its own connection under its standalone
  `nats.Name`.** Server-side, `hits up` is indistinguishable from four
  binaries: a packaging change, not a topology change.

- **The semantic index is conditional in `up`, strict standalone.** `up`
  starts it only when the embedding provider is configured, and says in one
  line when it is off and how to turn it on; the standalone
  `hits-index-semantic` keeps failing fast on missing config, because
  running it at all declares the intent to have embeddings.

- **The release ships `hits` and `hits-mcp` — together they cover every way
  of using HITS.** The fleet binaries leave the archive (`hits-node` was
  shipped alone, which ran nothing); they return when a production consumer
  asks. Nothing is deployed yet, so nothing regresses.

- **An embedded NATS server is a recorded non-goal.** `up` connects to a
  NATS system; it never becomes one. It would hand HITS its own storage,
  upgrade, and operations story — what 0001 exists to avoid. It returns
  only through a new decision.

- **One HITS per account (or JetStream domain), stated, no prefix knob.**
  The stream, bucket, and subject names stay bare. As preparation for a
  future knob, the ops-log names — today declared once per service tree —
  converge into the `contract` package, making them a one-place change and
  removing a standing drift risk.

## Alternatives rejected

- **A separate all-in-one binary** (`hitsd`, `hits-fleet`). A second
  download and a second name for no gain: the only thing it protects — the
  client's separation from service code — is protected by where the
  composition root lives. The measured ~11 MB removed the size argument.

- **Supervising the four binaries as child processes.** Reintroduces
  exactly the multi-binary orchestration `up` exists to remove, plus binary
  discovery and version-skew failure modes.

- **Composing in `cmd/` without a named tree.** `cmd/**` was uncovered by
  depguard, so this would have been frictionless — and untestable in
  exactly the way `internal/cli` was built to avoid, while leaving the
  boundary hole open.

- **A name-prefix knob now.** Configuration every fleet member and client
  must agree on, where a mismatch is a silent split-brain — the worst
  failure mode to hand a first-time user. No second-tenant need exists;
  bare names stay the default if a knob ever comes.

- **Embedding `nats-server` behind a flag now.** Zero-dependency demos are
  not the stated need; pointing at an existing system is. The option stays
  cheap (nats-server embeds as a library) and waits for real demand.

## Consequences

- The onboarding story is one sentence: download `hits`, `hits up
  --context <name>`, start working — against Synadia Cloud or any
  JetStream-enabled server. `hits-node` self-provisions the stream and
  buckets, so there is no setup step to document.
- A release consumer can finally run HITS: the shipped set is `hits` and
  `hits-mcp`, and the goreleaser matrix answers to this decision.
- `internal/fleet` joins the depguard rules as a first-class tree, and
  `cmd/**` stops being an unconstrained zone — the boundary "enforced by
  lint in CI" is now actually total.
- The ops-log names live in `contract`; a service declaring its own copy is
  a defect.
- One account hosts one HITS, and the getting-started text says so out
  loud. A second-tenant need reopens this as its own decision.
- [`02-DESIGN/hits-up.md`](../02-DESIGN/hits-up.md) carries the design;
  [`services.md`](../02-DESIGN/services.md) § code layout is amended to
  name the composition root exception.
