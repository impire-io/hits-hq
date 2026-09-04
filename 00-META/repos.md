# The HITS repositories

The map of every repository in the HITS project: what each owns and how it relates to this one. Humans use it for orientation; agents use it for issue triage (playbook [`process/03-issues.md`](process/03-issues.md)). The `code:` frontmatter field in design docs points at entries here.

| Repository | Owns |
|---|---|
| `hits-hq` | This repo — mission, research, design, decisions, issue diagnosis. The source of truth. |
| `hits` | The product code: the `hits` CLI (the terminal view of the full client surface — item verbs, projects, search, semantic, graph — and, through `hits up`, the whole fleet in one process, [`02-DESIGN/hits-up.md`](../02-DESIGN/hits-up.md)), the `hits-mcp` MCP server (the agent action surface, [`02-DESIGN/mcp-server.md`](../02-DESIGN/mcp-server.md)), the public Go `client` package, and the service fleet — `hits-node` plus the three index services (`hits-index-graph`, `hits-index-search`, `hits-index-semantic`), separate binaries with lint-enforced boundaries per [`02-DESIGN/services.md`](../02-DESIGN/services.md). Started as a walking skeleton; designed capabilities land here through [playbook 04](process/04-build-handoff.md). |
| `impire-marketplace` | The public distribution channel: agent skills and Claude Code plugins for Impire products, laid out per the Agent Skills open standard (decision [0007](../03-DECISIONS/0007-impire-marketplace.md)). A **derived view** under playbook [06](process/06-builder-skill-sync.md)'s contract — no contract is decided or first recorded there. |

The component split was settled by decision [0001](../03-DECISIONS/0001-item-store-architecture.md): the projector and client API sketched earlier are one service (`hits-node`), and the query projections are the three index services rather than in-process views of the client API.

## Foreseen components (not yet repos)

The MCP server was foreseen here and settled by decision [0003](../03-DECISIONS/0003-mcp-server.md) into `hits` code (`cmd/hits-mcp`), where it now runs — see the `hits` row.

Also open: whether a shared platform library (the common bootstrap for the Go fleet) precedes the first service, or is extracted from it later.
