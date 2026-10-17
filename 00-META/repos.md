# The HITS repositories

The map of every repository in the HITS project: what each owns and how it relates to this one. Humans use it for orientation; agents use it for issue triage (playbook [`process/03-issues.md`](process/03-issues.md)). The `code:` frontmatter field in design docs points at entries here, and this file is the hand-mirrored source of the **`hits` initiative's rows** in the tracker's project registry (decisions [0013](../03-DECISIONS/0013-issue-tracking-cutover.md) and [0016](../03-DECISIONS/0016-initiatives.md)): one registered slug per row below, each registered into the `hits` initiative. Other initiatives sharing the install govern their own rows through their own repos' maps.

| Repository | Owns |
|---|---|
| `hits-hq` | This repo — mission, research, design, decisions, issue diagnosis. The source of truth. |
| `hits` | The product code: the `hits` CLI (the terminal view of the full client surface — item verbs, the three vocabularies, search, semantic, graph, the audit — and `hits store init`, which declares a HITS in a chronicle account), the `hits-mcp` MCP server (the agent action surface, [`02-DESIGN/mcp-server.md`](../02-DESIGN/mcp-server.md)), the public Go `client` package on chronicle's client ([`02-DESIGN/the-client.md`](../02-DESIGN/the-client.md)), and the `contract` package — the model, the invariants and the fold. Since decision [0018](../03-DECISIONS/0018-hits-runs-on-chronicle.md) and the graduation of research 005 (decisions 0020–0022) nothing of HITS runs as a service: the store and its indexes are chronicle's ([`02-DESIGN/the-store.md`](../02-DESIGN/the-store.md)); the fleet of decision [0001](../03-DECISIONS/0001-item-store-architecture.md) — `hits-node` and the three index services — leaves the repo with the release that runs on chronicle ([`02-DESIGN/the-cutover.md`](../02-DESIGN/the-cutover.md)). |
| `impire-marketplace` | The public distribution channel: agent skills and Claude Code plugins for Impire products, laid out per the Agent Skills open standard (decision [0007](../03-DECISIONS/0007-impire-marketplace.md)). A **derived view** under playbook [06](process/06-builder-skill-sync.md)'s contract — no contract is decided or first recorded there. |

The component split was settled by decision [0001](../03-DECISIONS/0001-item-store-architecture.md): the projector and client API sketched earlier are one service (`hits-node`), and the query projections are the three index services rather than in-process views of the client API.

## Foreseen components (not yet repos)

The MCP server was foreseen here and settled by decision [0003](../03-DECISIONS/0003-mcp-server.md) into `hits` code (`cmd/hits-mcp`), where it now runs — see the `hits` row.

Also open: whether a shared platform library (the common bootstrap for the Go fleet) precedes the first service, or is extracted from it later.
