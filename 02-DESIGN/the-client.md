---
status: in-progress
code: hits
updated: 2026-10-17
---

# The client

How HITS reads and writes its store, and what the two surfaces on it keep:
one `client` package on chronicle's Go client, the CLI's sentences and the
MCP server's tools unchanged above it, chronicle's contexts underneath.
Settled by decision [0021](../03-DECISIONS/0021-the-client-one-package-on-chronicle-the-sentences-and-the-tools-unchanged-contexts-are-chronicles.md);
the store it speaks to is [`the-store.md`](the-store.md), the model it
enforces is [`item-model.md`](item-model.md). This document replaces
[`services.md`](services.md) (the fleet is gone), [`hits-up.md`](hits-up.md)
(nothing runs) and [`idp-auth.md`](idp-auth.md) (the connection is
chronicle's); [`mcp-server.md`](mcp-server.md) stands, amended.

```mermaid
flowchart LR
    CLI[hits] --> C[client package]
    MCP[hits-mcp] --> C
    C -->|contract.Apply: the next state| C
    C -->|read state, history, listings| S[(store hits)]
    C -->|apply the diff through the node, guarded| S
    C -->|query| X[text · meaning · rel]
```

## The write loop

Every write of the `client` package is one loop, the same for an item
and for a vocabulary:

1. **Read** the instance's state and the sequence it stands at — and,
   for the rules chronicle cannot judge, the other instances the rule
   names: the project or release `located-in` and `target` point at, the
   initiative a filing mints from, the open items a `ship` must find
   none of.
2. **Check** the command against [`item-model.md`](item-model.md)'s
   invariants with `contract`'s checks — every rule, as `hits-node`
   checked them, so a refusal is the same machine-legible invariant name
   it has always been.
3. **Fold** the next state with `contract.Apply`, the install's own fold.
4. **Send the difference**: every field that changed as its new value,
   every field that was cleared as `null`, as the operation
   [`the-store.md`](the-store.md) names for the command — through
   chronicle's node (a verified author) with the expected sequence read
   in step 1. A `create` carries the whole state with the create-only
   guard; a `note` carries its text.
5. **On a guard miss**, read again and go to step 2: the instance moved
   under the check, as it could under `hits-node`'s CAS, and the retry
   is the same judgement.

Chronicle refuses, before the send, what a precondition or the type's
schema forbids; the client's checks run first and say it in the model's
words, so a user sees `terminal-status`, not a schema's detail. Filing is
two loops: `mint` on the initiative, then `create` on the item.

## Reads

| Sentence | Read |
|---|---|
| `get` | the instance's state, then its history for the notes — each note's author and time are the operation's; `--revisions` is the state's per-key history, as before |
| `project list`, `initiative list`, `release list` | a listing of the type (a release listing under its initiative), retired entries dropped by the client |
| the status view, `search` with filters | a listing of `item` with the client's filter; a search's hits joined with their states and filtered |
| `search`, `semantic` | the `text` and `meaning` indexes' streamed replies; `--limit` caps, there is no page |
| `graph neighbors`, `graph walk` | the `rel` index's two verbs, with direction, labels and depth |
| `audit` | states and histories read through the package, held against git as before — and two reads of its own: the gaps in each initiative's numbering, and the operations after the cutover's sequence whose author chronicle did not vouch for |

Tombstoned items are dropped from every read by the client.

## The connection

`hits` and `hits-mcp` connect the way chronicle's own CLI does: a saved
**chronicle context** — loaded by name, or the selection — dialled as
chronicle dials it: `chronicle login` for a sign-in to the hosted
account, a credential file or an nkey for any NATS. `--context NAME` on
every sentence names one; `CHRONICLE_CONTEXT` is the fallback; the
store is the context's selected store or `hits`. There is no hits
context, no token exchange and no cache of HITS's own: what decisions
[0008](../03-DECISIONS/0008-client-idp-auth.md) to
[0011](../03-DECISIONS/0011-standalone-hits-contexts.md) built retires,
and a nats context an operator used to import is added with
`chronicle context add`.

**The actor is the principal.** Every write's author is who the context
connects as — a person's GitHub login, an agent's service-account name —
stamped and vouched for by chronicle. `--actor` and `HITS_ACTOR` leave;
`hits-mcp`'s startup actor leaves with them: one process is one context,
and the context is somebody.

## The sentences

Unchanged: every item verb, the three vocabularies, `search`, `semantic`,
`graph`, `audit`, `version`, and every flag of theirs but `--actor`.
Leaving: `up` (nothing runs — [`the-cutover.md`](the-cutover.md)),
`context` (chronicle's), `auth` (chronicle's `login`), `ping` (a context
that dials is the health check). Arriving: `store init`
([`the-cutover.md`](the-cutover.md)), and for one release, `migrate`.
The `hits-cli` skill's item sections stand; its connection and actor
sections are rewritten with the release, through
[playbook 06](../00-META/process/06-builder-skill-sync.md).

## The MCP server

[`mcp-server.md`](mcp-server.md) as amended: one tool per client
method, stdio, fail-fast — resolve the chronicle context, dial, read the
store's types, then serve. The actor flag is gone; the tools carry no
actor and never did. Chronicle's own MCP server (chronicle-hq research
013) may one day do what the tools do; until a decision says so,
`hits-mcp` is the agent's door.

## The repository

`cmd/hits` and `cmd/hits-mcp` over `client` and `contract`; nothing
else. `contract` keeps the model, the invariants and the fold —
`contract.Apply` is what the write loop folds with. `internal/node`,
`internal/index`, `internal/fleet` and `internal/connect` leave with the
four fleet binaries, and the lint rules that fenced the services from
one another leave with them; the rule that keeps the adapters on the
client stays. The release carries two binaries and the install manifest.

## What this does not do

No service, no endpoint, no projection of HITS's own; no cache of state
or history in a client. No write that is not the difference the fold
produced. No filter on the wire: chronicle's search is no-knobs and the
client joins. No actor a caller may name: the author is the connection's.
