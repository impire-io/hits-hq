---
status: in-progress
code: hits
updated: 2026-09-04
---

# IDP auth & hits contexts — the client-side token exchange

How `hits` authenticates against an identity provider and keeps a NATS
connection fed with a fresh access token — and, carrying it, **hits
contexts**: hits-owned context documents, the one place hits reads
connection configuration from. Settled by decisions
[0008](../03-DECISIONS/0008-client-idp-auth.md),
[0009](../03-DECISIONS/0009-connection-profiles.md),
[0010](../03-DECISIONS/0010-hits-contexts.md), and
[0011](../03-DECISIONS/0011-standalone-hits-contexts.md); grew out of
research [002](../01-RESEARCH/002-idp-token-exchange/).

**The dividing line:** HITS owns the exchange — obtaining, storing, and
refreshing tokens, and presenting the current access token as the
connection's token on every connect and reconnect. The deployment owns
validation: a NATS auth callout that accepts the token and mints whatever
user JWT its policy dictates. Nothing in HITS validates, maps, or even
inspects the token beyond its expiry; how a deployment makes the token
mean something is up to them.

## hits contexts

A hits context is a hits-owned document — one file per context in
`$XDG_CONFIG_HOME/hits/context/<name>.json` — and the **only** place
hits reads connection configuration from. hits fields sit at the top
level (today: the optional `oauth` block); the NATS connection nests
under a `nats` key in the **exact orbit natscontext `Settings` schema**
— url, creds, token, user/password, nkey, cert/key/ca, `tls_first`, all
of it. hits borrows the schema, not the file contract, so hits fields
can never collide with upstream ones.

```json
{
  "nats": {
    "url": "tls://nats.acme.example:4222",
    "ca": "~/.config/hits/acme-ca.pem"
  },
  "oauth": {
    "issuer": "https://idp.acme.example",
    "client_id": "hits-cli",
    "scopes": ["openid", "offline_access"]
  }
}
```

- Every non-OAuth auth mechanism — creds files, static tokens,
  user/password, nkeys — and the TLS options work exactly as they do in
  a nats context, because the same library loads the `nats` subtree.
- Inside `oauth`: `issuer` and `client_id` required, `scopes` defaulting
  to `openid offline_access` (the refresh token rides on
  `offline_access`); endpoints come from OIDC discovery
  (`/.well-known/openid-configuration`), never from config. One IDP per
  context.
- An `oauth` block alongside a `nats.token` value is a hard,
  plainly-worded error — one auth source per file, checked before
  connecting, never surfaced as nats.go's `ErrTokenAlreadySet`.
- **The nats CLI's contexts are an import source, nothing more.**
  `hits context import <name>` wraps one under `nats`; hits never reads
  the nats CLI's directory at connect time and never writes into it.
- The 005 config file ([`005-cli-config-file`](../04-ISSUES/005-cli-config-file/00-report.md))
  holds client *defaults* — context, actor — not connection config.

## The seam: `internal/connect`

One shared package every binary connects through — the CLI, the fleet
(`hits up`), `hits-mcp`, and the four standalone service mains. Per
connection it:

1. Resolves the **context name**: the explicit `--context` value, else
   the 005 config's default context. Nothing falls back to the nats CLI;
   a name that resolves to nothing is a plainly-worded error pointing at
   `hits context add` / `import`.
2. Loads the file from **hits' context directory only** and extracts the
   `nats` subtree to a 0600 temp file in a private directory, hands its
   absolute path to `natscontext.Connect`, and deletes it after connect —
   full loader reuse (homedir/env expansion, nsc lookup, SOCKS,
   `tls_first`) for a few lines of owned code. The shim disappears if
   orbit accepts the proposed `Settings`-to-options export
   ([0011](../03-DECISIONS/0011-standalone-hits-contexts.md)).
3. A context with an `oauth` block gets `nats.TokenHandler` layered
   through the variadic options, backed by the token cache.

The package is the first brick of the shared bootstrap library
[`repos.md`](../00-META/repos.md) foresees. It lives in `hits` under the
same depguard rules as every bounded tree: services and `cmd` mains may
import it; it imports no service internals.

## The verbs

**The `hits context` family** is the paved path to the context
directory, and operates only there:

- **`hits context ls`** — every context hits knows, the default marked.
- **`hits context add <name>`** — scaffold a context file (url plus the
  asked-for auth block) and open it in `$EDITOR`.
- **`hits context import <nats-context> [<name>]`** — read a nats CLI
  context (read-only) and wrap it under `nats`.
- **`hits context edit <name>`** / **`hits context rm <name>`** —
  `$EDITOR` on the file; delete the file.
- **`hits context select <name>`** — sugar: writes `defaults.context` in
  the 005 config. No selection state exists outside that default.

**The `hits auth` family** works the token cache:

- **`hits auth login [--context <name>]`** — the one interactive moment.
  Requires the name to resolve to a context with an `oauth` block (a
  context without one is a plainly-worded error). Runs
  the device authorization grant (RFC 8628): request a device code, print
  the verification URL and user code, poll the token endpoint at the
  server's interval, write the token cache. Works over SSH, needs no
  browser on the machine, no callback listener, no client secret; a human
  supervising an agent completes the same flow.
- **`hits auth status [--context <name>]`** — the context in effect, the
  token subject, and both expiries; says plainly when there is no cache.
- **`hits auth logout [--context <name>]`** — deletes the cache. Nothing
  is revoked at the IDP; that is the deployment's lever.

Connect paths never launch a flow uninvited. An agent, service, or
scripted call that finds no usable cache fails fast:
`no token for context "acme-prod": run 'hits auth login --context acme-prod'`.

## Tokens and refresh

The cache is `$XDG_STATE_HOME/hits/tokens/<context>.json` (directory
`0700`, file `0600`): access token, refresh token, access-token expiry. The
OS keychain is a named non-goal — a keychain prompt is an interactive hang
for exactly the unattended processes this serves.

The token handler is the refresh engine. nats.go invokes it on **every
connect and reconnect attempt**; it returns the cached access token,
first refreshing through the refresh token when the access token is
expired or within 60 seconds of it, rewriting the cache on success.
Failure modes degrade in order, and the loop is self-healing:

- **IDP unreachable / refresh fails:** return the cached token anyway. The
  server rejects it, nats.go backs off and retries, the handler tries the
  IDP again — recovery is automatic the moment the IDP is back.
- **Refresh token expired or revoked:** every retry fails the same way;
  the surfaced error names the fix (`hits auth login`). Long-lived
  processes stay in their reconnect loop rather than exiting — the
  operator logs say why.
- **Mid-session expiry:** no HITS timer. The deployment's callout bounds
  the session with the JWT expiry it mints; the server disconnects at that
  boundary, reconnect fires the handler, the handler refreshes. The loop
  closes with HITS scheduling nothing.

Several processes share one cache: `hits-mcp` and `hits up` hold a context
long-lived while one-shot CLI calls come and go beside them. Refresh is
therefore **serialized, not merely atomic**: the handler takes a file lock
on the cache entry, re-checks freshness once it holds the lock (another
process may have refreshed first), and only then spends the refresh token.
This matters because IDPs commonly *rotate* refresh tokens on use — two
processes spending the same refresh token concurrently can trip reuse
detection and revoke the whole grant, stranding every process on that
context. The lock bounds who spends the token; reads stay lock-free, and
the cache write stays an atomic rename.

A long-lived process and the login verb meet through the same cache, so
`hits auth login` must run as the same OS user (and `HOME`) the process
runs under — the practical note for `hits-mcp`, which is typically
launched by an agent host, not a terminal.

## What this does not do

- **No server-side anything.** No callout service, no validation, no JWKS,
  no IDP guidance beyond "your callout accepts the access token".
- **No PKCE, no client credentials.** Device flow covers the present
  consumers; a real need reopens these through playbook
  [02](../00-META/process/02-graduation.md).
- **No verified actor.** The actor stays self-declared per decision
  [0002](../03-DECISIONS/0002-projects-and-actors.md). The IDP subject now
  rides along in the cache, which is exactly why mapping it to the actor
  is future research — nothing here may preclude it, and nothing here
  attempts it.
- **No selection state beyond the 005 default.** `hits context select`
  writes `defaults.context`; there is no separate selected-context
  marker to drift from it.
- **No touching the nats CLI's directory at connect time.** Its contexts
  are an import source for `hits context import`, read-only, and no hits
  field is ever written into it.
