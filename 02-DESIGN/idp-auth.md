---
status: designed
---

# IDP auth — the client-side token exchange

How `hits` authenticates against an identity provider and keeps a NATS
connection fed with a fresh access token. Settled by decision
[0008](../03-DECISIONS/0008-client-idp-auth.md); grew out of research
[002](../01-RESEARCH/002-idp-token-exchange/).

**The dividing line:** HITS owns the exchange — obtaining, storing, and
refreshing tokens, and presenting the current access token as the
connection's token on every connect and reconnect. The deployment owns
validation: a NATS auth callout that accepts the token and mints whatever
user JWT its policy dictates. Nothing in HITS validates, maps, or even
inspects the token beyond its expiry; how a deployment makes the token
mean something is up to them.

## The seam: `internal/connect`

One shared package every binary connects through — the CLI, the fleet
(`hits up`), `hits-mcp`, and the four standalone service mains. It wraps
`natscontext.Connect` and decides per connection:

1. Resolve the **effective context name**: the explicit `--context` value,
   else the nats CLI's selected-context marker. (natscontext resolves the
   selection only *while* connecting; the auth decision needs the name
   first.)
2. Load the client config ([005](../04-ISSUES/005-cli-config-file/00-report.md)
   file). **No `auth` block for that context:** connect exactly as today —
   same options, nothing added, zero behavior change.
3. **An `auth` block:** attach `nats.TokenHandler` backed by the token
   cache. If the context file also carries a static `token`, fail before
   connecting with a plainly-worded error naming both sources — never
   surface nats.go's `ErrTokenAlreadySet`. One source of truth per
   context.

The package is the first brick of the shared bootstrap library
[`repos.md`](../00-META/repos.md) foresees. It lives in `hits` under the
same depguard rules as every bounded tree: services and `cmd` mains may
import it; it imports no service internals.

## Config: the `auth` section

IDP settings are client configuration, keyed by context name, in the 005
config file (`$XDG_CONFIG_HOME/hits/config.json`):

```json
{
  "auth": {
    "acme-prod": {
      "issuer": "https://idp.acme.example",
      "client_id": "hits-cli",
      "scopes": ["openid", "offline_access"]
    }
  }
}
```

| Field | | |
|---|---|---|
| `issuer` | required | OIDC issuer; endpoints come from `/.well-known/openid-configuration`, never config |
| `client_id` | required | the public client registered for HITS at the IDP |
| `scopes` | optional | defaults to `openid offline_access` — the refresh token rides on `offline_access` |

One IDP per context; a second IDP is a second context. NATS contexts are
the nats CLI's file format and are not extended.

## The verbs

- **`hits auth login [--context <name>]`** — the one interactive moment.
  Runs the device authorization grant (RFC 8628): request a device code,
  print the verification URL and user code, poll the token endpoint at the
  server's interval, write the token cache. Works over SSH, needs no
  browser on the machine, no callback listener, no client secret; a human
  supervising an agent completes the same flow.
- **`hits auth status [--context <name>]`** — the block in effect, the
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
- **No change for everyone else.** Contexts without an `auth` block —
  creds files, static tokens, plain servers — pass through the seam
  untouched.
