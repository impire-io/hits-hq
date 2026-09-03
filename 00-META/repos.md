# The HITS repositories

The map of every repository in the HITS project: what each owns and how it relates to this one. Humans use it for orientation; agents use it for issue triage (playbook [`process/03-issues.md`](process/03-issues.md)). The `code:` frontmatter field in design docs points at entries here.

| Repository | Owns |
|---|---|
| `hits-hq` | This repo — mission, research, design, decisions, issue diagnosis. The source of truth. |
| `hits` | The product code: the `hits` CLI (the terminal view of the full client surface — item verbs, projects, search, semantic, graph), the public Go `client` package, and the service fleet — `hits-node` plus the three index services (`hits-index-graph`, `hits-index-search`, `hits-index-semantic`), separate binaries with lint-enforced boundaries per [`02-DESIGN/services.md`](../02-DESIGN/services.md). Started as a walking skeleton; designed capabilities land here through [playbook 04](process/04-build-handoff.md). |

The component split was settled by decision [0001](../03-DECISIONS/0001-item-store-architecture.md): the projector and client API sketched earlier are one service (`hits-node`), and the query projections are the three index services rather than in-process views of the client API.

## Foreseen components (not yet repos)

- **MCP server** — the agent action surface; a client of the `hits` service fleet, not a privileged component.

Also open: whether a shared platform library (the common bootstrap for the Go fleet) precedes the first service, or is extracted from it later.
