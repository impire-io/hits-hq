# The HITS repositories

The map of every repository in the HITS project: what each owns and how it relates to this one. Humans use it for orientation; agents use it for issue triage (playbook [`process/03-issues.md`](process/03-issues.md)). The `code:` frontmatter field in design docs points at entries here.

| Repository | Owns |
|---|---|
| `hits-hq` | This repo — mission, research, design, decisions, issue diagnosis. The source of truth. The only repository that exists today. |

## Foreseen components (not yet repos)

The components below are foreseen from the architecture sketch; whether each is its own repo, and what the repos are named, is design work — settle it through [playbook 02](process/02-graduation.md) and record the outcome in the table above.

- **Projector** — consumes the ops-log stream and maintains the current-state KV projection, so state reads are simple lookups.
- **Client API** — the NATS micro endpoints callers interact with, holding the in-process query projections (full-text via Bleve; embedded vector and graph stores are candidates under research).
- **MCP server** — the agent action surface; a client of the client API, not a privileged component.

Also open: whether a shared platform library (the common bootstrap for the Go fleet) precedes the first service, or is extracted from it later.
