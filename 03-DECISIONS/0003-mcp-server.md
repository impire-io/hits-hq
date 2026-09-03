# 0003 — The MCP server: a fifth binary in `hits`, mirroring the client surface

**Date:** 2026-09-03

## Context

The mission names the MCP server as *the* agent action surface: agents are
the first-class operators, and MCP is how they reach the platform. The
surface it fronts is done — the service fleet and the full client surface
run on `hits` main, and the CLI already proved the adapter pattern (a caller
of the `client` package, resolving connections through NATS contexts).
[`00-META/repos.md`](../00-META/repos.md) listed the MCP server as a
foreseen component "not yet a repo". Open were: where it lives, what shape
its tool surface takes, how actor identity flows through it, and which MCP
transport it speaks.

## Decision

- **It lands in the `hits` repo as `cmd/hits-mcp`**, a fifth binary with its
  own package tree, bounded exactly like the CLI: it imports the `client`
  package (and `contract`), never `internal/node` or `internal/index`, and
  no service imports it — depguard-enforced in both directions. This
  mirrors decision [0001](0001-item-store-architecture.md)'s deferral of
  one-repo-per-service: the contract is young, and the lint boundary keeps
  extraction mechanical if its release cadence ever diverges.

- **The tool surface mirrors the client surface one for one.** Every
  `client` package endpoint is one MCP tool; nothing else is callable.
  Query tools carry the MCP read-only annotation. Tool input schemas
  restate the client request types field for field, and replies return the
  reply JSON unchanged — the MCP layer adds no vocabulary of its own.

- **The actor is server-level configuration, fixed at startup.** One stdio
  server serves one agent, so the acting handle comes from config (flag or
  `HITS_ACTOR`, the CLI's convention), is validated for form at boot, and
  stamps every write. There is no per-call override. When identity later
  derives from NATS authentication (decision
  [0002](0002-projects-and-actors.md)), the startup actor is verified
  rather than claimed — the same tightening, not a migration.

- **Transport is stdio only.** The server is an agent-local process, like
  the CLI is an engineer-local one. The implementation uses the official Go
  MCP SDK (`github.com/modelcontextprotocol/go-sdk`).

## Alternatives rejected

- **Its own repo (`hits-mcp`) now.** Rejected for the same reason 0001
  deferred one-repo-per-service: it would version the young client contract
  across repos before it has settled. The depguard boundary preserves the
  option at mechanical cost.

- **A curated, folded tool set** (one `item_update` covering edit,
  transition, claim, …). Rejected: agents-first means explicit contracts —
  a mode parameter muddies which invariants apply to which call, and a
  second vocabulary needs its own documentation and drifts from the
  endpoint names the rest of the platform speaks.

- **Actor as a per-call tool argument** (with or without a server default).
  Rejected: no shared server exists today, so a per-call actor only invites
  misattribution — an agent filling in someone else's handle — and weakens
  the one-process-one-actor story that NATS authentication will later
  verify.

- **Streamable HTTP alongside stdio.** Rejected for now:
  [`how-we-deploy.md`](../00-META/how-we-deploy.md) says nothing is
  deployed, so a network transport would build to a deployment story that
  does not exist. It returns as its own decision when a shared install
  does.

- **MCP resources and prompts.** Rejected: no present consumer. Tools
  compose; an item-as-resource view is a convenience with nothing asking
  for it yet.

## Consequences

- `repos.md` retires the "not yet a repo" framing: the MCP server is
  `hits` code, recorded on the repo's row at build handoff like the CLI.
- The MCP SDK joins the `hits` module's dependencies. The import boundary,
  not the module graph, is what keeps it out of the fleet's service trees.
- One agent process is one actor; a host running several agents runs
  several servers. Multi-tenancy arrives with NATS authentication or not at
  all.
- The 1:1 rule makes the tool surface a derived view of the client surface:
  adding an endpoint means adding its tool in the same change. Drift
  between them is a defect, not a style choice.
