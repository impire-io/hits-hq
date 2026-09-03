---
status: implemented
code: hits
updated: 2026-09-03
---

# `hits up` — the fleet as one process

The getting-started shape: the whole service fleet running as one process
inside the one `hits` binary, against whatever NATS system a context points
at — Synadia Cloud or a self-hosted server. Settled by decision
[0004](../03-DECISIONS/0004-hits-up.md); the services it composes are
[`services.md`](services.md), unchanged. Download `hits`, run
`hits up --context <name>`, and the same binary is the client you then work
with.

```mermaid
flowchart LR
    subgraph hits binary
        UP[up] --> F[internal/fleet]
        CLI[client commands] --> CP[client package]
    end
    F -->|Start| N[hits-node]
    F -->|Start| G[hits-index-graph]
    F -->|Start| S[hits-index-search]
    F -->|Start| E[hits-index-semantic, when configured]
    N & G & S & E -->|own connection, own nats.Name| NATS[(the NATS system)]
    CP --> NATS
```

## The composition

One bounded tree, `internal/fleet`, exposes one `Start`: it connects and
starts all four services, fail-fast — any service that cannot start stops
the ones already running and exits non-zero. Stopping is the reverse:
signal, stop the services, close the connections. The tree may import the
four service package roots and `contract`, and nothing else; nothing
imports it back. The services themselves are untouched — `fleet` calls the
same `Start(ctx, nc)` entrypoints the standalone `cmd/` mains call.

`cmd/hits/main.go` dispatches `up` **before** delegating to the client
CLI's parser, so `internal/cli` stays a pure client and its depguard
denials stay untouched. `up`'s flags follow the subcommand, under its own
flagset:

```
hits up [--context <name>] [--embedding-url <url> --embedding-model <m>]
```

## Connections

Each service connects for itself, through the same NATS context, under its
standalone `nats.Name` (`hits-node`, `hits-index-graph`, …). Server-side,
`hits up` is indistinguishable from running four binaries: a packaging
change, not a topology change. Monitoring, per-service disconnects, and the
account's connection view all match the separate-binary shape.

## The semantic index is optional here

`up` starts `hits-index-semantic` only when the provider is configured
(`--embedding-url` and `--embedding-model`; key from
`HITS_EMBEDDING_API_KEY`). Unconfigured, the other three services boot and
one clear line says semantic search is off and which flags turn it on —
the fleet's stated degradation ([`services.md`](services.md) § embeddings)
made true at the getting-started surface. The standalone
`hits-index-semantic` binary keeps requiring its flags: running it at all
declares the intent to have embeddings.

## What ships

The release archives carry `hits` and `hits-mcp` — together they cover
every way of using HITS: `up` runs the platform, the client commands and
the MCP server operate it. The standalone fleet binaries stay buildable
and leave the archives; they return when a production consumer asks.

## Boundaries

The depguard amendment that admits `internal/fleet` also closes the hole
research 001 found: `cmd/**` was constrained by nothing. After it:

- `internal/fleet` may import the four service roots and `contract`;
  denied the adapters and `client`.
- Services and adapters are denied `internal/fleet` — composition is a
  one-way street.
- Each `cmd/` main is pinned to its own tree: `cmd/hits` to
  `internal/cli` + `internal/fleet`, each service main to its service,
  `cmd/hits-mcp` to `internal/mcp`.

The ops-log names (`hits-ops`, `hits-items`, the `hits.ops.>` subjects) —
previously declared once per service tree — live in `contract`, declared
once. One HITS per account or JetStream domain; the names carry no prefix
and there is no knob (decision 0004).

## What this does not do

- No embedded NATS server — `up` connects to a NATS system, it never
  becomes one. Returns only through a new decision.
- No new endpoints, no new surface — `up` runs the fleet of
  [`services.md`](services.md) exactly as designed; agents and humans still
  operate HITS through the client surface.
- No daemonizing, no supervision, no restarts — `up` is a foreground
  process; process management belongs to whatever runs it.
- No multi-tenancy — one account, one HITS, stated in the getting-started
  text.
