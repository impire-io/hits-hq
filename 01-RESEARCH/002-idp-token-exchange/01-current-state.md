# Current state — what `hits` main already does, and where the gap is

Facts checked against `hits` main (v0.1.1, nats.go v1.53.1, orbit.go
natscontext v0.1.3) on 2026-09-04.

## The connect surface

Every production connection resolves through `natscontext.Connect(name,
opts...)`, at exactly seven sites:

| Site | Connection |
|---|---|
| `internal/cli/cli.go` `ContextConnector` | one per CLI invocation |
| `internal/fleet/fleet.go` `ContextConnector` | the fleet's one shared connection (decision [0006](../../03-DECISIONS/0006-shared-connection-in-up.md)) |
| `internal/mcp/server.go` | `hits-mcp`'s one long-lived connection |
| `cmd/hits-node`, `cmd/hits-index-{graph,search,semantic}` | one each, standalone-service shape |

The CLI and fleet already route through a `Connector` seam (tests inject an
embedded server), so wrapping the connect path is a designed-for move, not
surgery. `natscontext.Connect` takes variadic `nats.Option`s, so injecting
auth options is mechanical at every site.

## Token pass-through already works

A NATS context's `token` field is applied as `nats.Token(...)` by
natscontext (`context.go:122-123`). A deployment fronting NATS with an auth
callout that accepts access tokens works with `hits` **today**, unchanged:

```sh
nats context save hits --server tls://... --token "$ACCESS_TOKEN"
```

## The gap: acquisition and freshness

Nothing in HITS can obtain a token, refresh one, or supply a fresh one on
reconnect:

- The context token is **static per process**. One-shot CLI calls re-read
  the context file each run, so an *external* refresher keeps the CLI
  working. Long-lived processes — `hits up`, `hits-mcp`, the standalone
  services — replay the token they started with on every reconnect: once
  it expires, a dropped connection stays dropped until restart.
- nats.go has the exact primitive for freshness: `nats.TokenHandler(func()
  string)` is invoked on **every connect and reconnect attempt** when the
  CONNECT proto is built (`nats.go:3094`). A handler that refreshes against
  the IDP makes reconnect self-healing.
- The two mechanisms are mutually exclusive: a static token *and* a handler
  is a hard error, `ErrTokenAlreadySet` ("nats: token and token handler
  both set", `nats.go:143`). An IDP-authenticated context therefore must
  not also carry a `token` field.
- NATS contexts have no IDP fields (natscontext `context.go` config
  struct), and nothing upstream suggests they will: issuer, client id, and
  scopes need a home of our own. Issue
  [`005-cli-config-file`](../../04-ISSUES/005-cli-config-file/00-report.md)
  already plans `$XDG_CONFIG_HOME/hits` for client defaults.
- One wrinkle: natscontext resolves the *selected* context (empty name)
  internally and only reports the resolved settings alongside the opened
  connection. Deciding whether to attach a token handler requires knowing
  the context name *before* connecting, so the seam must resolve the
  selection itself (the nats CLI records it in a well-known file).

## The grant landscape

Three OAuth 2 grants matter for a CLI-shaped client, all off-the-shelf
against any OIDC-discoverable IDP (`/.well-known/openid-configuration`):

- **Device authorization (RFC 8628)** — print a URL and code, poll the
  token endpoint. No browser on the machine, no callback server, no client
  secret; works over SSH and for a human supervising an agent. The
  standard CLI choice (gh, az, gcloud all ship it).
- **Authorization code + PKCE** — full browser round-trip with a local
  callback listener. Slicker for desktop humans, strictly more moving
  parts, covers no case device flow cannot.
- **Client credentials** — machine identity with a secret, no human. The
  fit for unattended fleets, but the deployment that runs one today has
  creds files as the operator path.

A refresh token comes back when the request asks for it (`offline_access`
scope on most IDPs); refreshing is one POST to the token endpoint.
