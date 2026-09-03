# Proposed answers to the five questions

Worked 2026-09-03 against `hits` main. Three findings made during this pass
sharpen the picture before the answers:

- **The entrypoint pattern already exists.** Every service exposes
  `Start(ctx, nc)` (semantic: `Start(ctx, nc, cfg)`) at its package root,
  and the `cmd/` mains are already thin wrappers over it — connect, `Start`,
  wait for a signal. The composition binary invents nothing; it calls four
  functions that exist today.
- **The release gap is worse than recorded.** goreleaser builds only `hits`
  and `hits-node`; the three indexers and `hits-mcp` are not shipped at all.
  A release consumer today cannot run the fleet, period. (Corrected in
  [`01-current-state.md`](01-current-state.md); the doc sync is filed as
  issue 001.)
- **Measured, the size objection collapses.** Stripped darwin/arm64 builds:
  the `hits` client alone is 6.6 MB; a scratch main linking all four service
  trees is 17.6 MB. Everything is pure Go, `CGO_ENABLED=0` as released.
  Carrying the fleet costs ~11 MB, not the feared bloat.

## 1. Shape — `hits up`, a subcommand of the one `hits` binary

Download `hits`, run `hits up --context <name>`, and the same binary is the
client you then work with. That is the whole onboarding story, and it is the
strongest version of the idea: one name to remember, one artifact to fetch.
The size cost is measured at ~11 MB; the purity cost is handled by the
boundary answer below, which keeps the client tree free of service imports.

This also repairs the release gap in one move: the shipped set becomes
`hits` (client + `up`) and `hits-mcp` (the agent surface), and together they
cover every way of using HITS. The standalone fleet binaries remain — `up`
is the getting-started and small-team shape, not a replacement for composing
services separately — and they can join the archives when a production
consumer asks.

**Rejected:** a separate all-in-one binary (`hitsd`, `hits-fleet`). It costs
a second download and a second name for no gain: the only thing it protects
— the client's separation from service code — is protected anyway by where
the composition root lives.

## 2. Boundary — a bounded composition tree, dispatched from `cmd/hits`

The depguard rules deny `internal/cli` and `internal/mcp` any import of
`internal/node` and `internal/index`, and those rules should not bend.
Instead:

- A new tree, `internal/fleet`, is the composition root: one
  `Start(ctx, Config)` that starts all four services. It gets its own
  depguard rule — may import the four service package roots and `contract`,
  denied the adapters and `client`; the service and adapter rules gain a
  matching deny of `internal/fleet` so composition stays a one-way street.
- `cmd/hits/main.go` intercepts `up` before delegating to `cli.Run`, so the
  client tree never sees service code. `up`'s flags follow the subcommand
  (`hits up --context <name> ...`) under its own flagset.
- Inside `up`, each service keeps its own connection under its standalone
  `nats.Name` (`hits-node`, `hits-index-graph`, …). Server-side, `hits up`
  is then indistinguishable from four binaries: a packaging change, not a
  topology change.

**Finding for the design to close:** depguard today constrains no file under
`cmd/**` — the boundary "enforced by lint in CI" has a silent hole where any
main may import anything. The amendment that blesses `internal/fleet` should
also pin each `cmd/` main to its own service's tree.

**Rejected:** supervising the four binaries as child processes (reintroduces
the multi-binary orchestration the idea removes, plus path/version
discovery); exempting `cmd/` as the composition zone without a named tree
(leaves the composition logic untestable in exactly the way `internal/cli`
was built to avoid).

## 3. Semantic optionality — conditional in `up`, strict standalone

`hits up` starts `hits-index-semantic` only when the embedding provider is
configured (`--embedding-url` and `--embedding-model`, key from
`HITS_EMBEDDING_API_KEY`); otherwise it boots the other three and prints one
clear line that semantic search is off and which flags turn it on. That
makes the design's existing promise — the fleet functions fully without the
provider — true at the getting-started surface.

The standalone binary stays strict: running `hits-index-semantic` at all
declares the intent to have embeddings, and failing fast on missing config
is correct there.

## 4. Embedded NATS server — a recorded non-goal

`up` connects to a NATS system; it never becomes one. Embedding
`nats-server` would hand HITS its own storage, upgrade, and operations story
— precisely what decision
[0001](../../03-DECISIONS/0001-item-store-architecture.md) avoided by making
NATS the only infrastructure. The revisit stays cheap (nats-server embeds as
a library behind a flag) if demo feedback ever demands zero-dependency, but
it enters only through a new decision. State the non-goal explicitly in the
design so it is a boundary, not an oversight.

## 5. Account sharing — one HITS per account, stated, no knob

The stream, bucket, and subject names (`hits-ops`, `hits-items`, `hits.>`)
are unprefixed constants today, so one account (or one JetStream domain)
hosts exactly one HITS. Propose keeping it that way and saying so out loud —
in the design and in the getting-started text — rather than adding a prefix
knob now:

- A prefix is configuration that every fleet member and every client must
  agree on; a mismatch is a silent split-brain, the worst failure mode to
  hand a first-time user.
- No second-tenant need exists yet; minimal-feature says the knob waits for
  a real consumer, and retrofitting one later is compatible (bare names stay
  the default).

One preparatory move is worth taking when `up` lands: the name constants are
currently declared four times, once per service tree. Converging them into
the contract package makes a future prefix a one-place change and removes a
standing drift risk between services.

## What graduation looks like

If these answers hold, the effort graduates (playbook
[02](../../00-META/process/02-graduation.md)) into a decision record — the
all-in-one composition: `hits up`, the `internal/fleet` tree, the shipped
set, the embedded-server non-goal, one-HITS-per-account — and an amendment
to [`services.md`](../../02-DESIGN/services.md) § code layout, then a build
handoff (playbook 04) to `hits`.
