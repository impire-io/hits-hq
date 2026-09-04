---
status: designed
---

# IDP auth & connection profiles — the client-side token exchange

How `hits` authenticates against an identity provider and keeps a NATS
connection fed with a fresh access token — and, carrying it, the
`connections` config: hits-native, self-contained connection profiles for
deployments configured outside the nats CLI's context system. Settled by
decisions [0008](../03-DECISIONS/0008-client-idp-auth.md) and
[0009](../03-DECISIONS/0009-connection-profiles.md); grew out of research
[002](../01-RESEARCH/002-idp-token-exchange/).

**The dividing line:** HITS owns the exchange — obtaining, storing, and
refreshing tokens, and presenting the current access token as the
connection's token on every connect and reconnect. The deployment owns
validation: a NATS auth callout that accepts the token and mints whatever
user JWT its policy dictates. Nothing in HITS validates, maps, or even
inspects the token beyond its expiry; how a deployment makes the token
mean something is up to them.

## Connection profiles: the `connections` section

OAuth credentials come from outside the context system, so an OAuth
connection never rides a NATS context — it is a **profile** in the client
config ([005](../04-ISSUES/005-cli-config-file/00-report.md) file,
`$XDG_CONFIG_HOME/hits/config.json`), and a profile is complete: server,
auth, TLS, all in one place.

```json
{
  "connections": {
    "acme-prod": {
      "url": "tls://nats.acme.example:4222",
      "oauth": {
        "issuer": "https://idp.acme.example",
        "client_id": "hits-cli",
        "scopes": ["openid", "offline_access"]
      },
      "tls": { "ca": "~/.config/hits/acme-ca.pem" }
    },
    "backstage": {
      "url": "nats://10.0.0.7:4222",
      "creds": "~/keys/backstage.creds"
    }
  }
}
```

| Field | | |
|---|---|---|
| `url` | required | the NATS server(s), as `nats.Connect` accepts them |
| auth | at most one | `oauth` \| `creds` (file path) \| `token` (static) \| `user` + `password` \| `nkey` (seed file) — none means an unauthenticated server |
| `tls` | optional | `ca`, `cert`, `key` file paths; further knobs expand on a real, present need |

Inside `oauth`: `issuer` and `client_id` required, `scopes` defaulting to
`openid offline_access` (the refresh token rides on `offline_access`);
endpoints come from OIDC discovery (`/.well-known/openid-configuration`),
never from config. One IDP per profile; a second IDP is a second profile.

**NATS contexts remain first-class.** Everything the nats CLI can put in a
context — creds, static tokens, TLS — keeps working through it, unchanged.
Profiles do not deprecate contexts; they serve connections whose
configuration lives outside the nats CLI, OAuth being the case that forces
them. NATS context files are the nats CLI's format and are not extended.

## The seam: `internal/connect`

One shared package every binary connects through — the CLI, the fleet
(`hits up`), `hits-mcp`, and the four standalone service mains. Per
connection it:

1. Resolves the **connection name**: the explicit `--context` value, else
   the nats CLI's selected-context marker.
2. Looks the name up: **hits profile first, then NATS context.** A name
   defined as both is a hard, plainly-worded error — one source of truth
   per name.
3. **A profile:** builds the NATS options itself — URL, the profile's auth
   option, TLS options — and for `oauth`, attaches `nats.TokenHandler`
   backed by the token cache. natscontext is not involved.
4. **A context:** `natscontext.Connect` with the caller's options, exactly
   as today — same options, nothing added, zero behavior change. OAuth is
   never layered onto a context.

The package is the first brick of the shared bootstrap library
[`repos.md`](../00-META/repos.md) foresees. It lives in `hits` under the
same depguard rules as every bounded tree: services and `cmd` mains may
import it; it imports no service internals.

## The verbs

- **`hits auth login [--context <name>]`** — the one interactive moment.
  Requires the name to resolve to a profile with an `oauth` block (a NATS
  context or non-OAuth profile is a plainly-worded error). Runs the device
  authorization grant (RFC 8628): request a device code, print the
  verification URL and user code, poll the token endpoint at the server's
  interval, write the token cache. Works over SSH, needs no browser on the
  machine, no callback listener, no client secret; a human supervising an
  agent completes the same flow.
- **`hits auth status [--context <name>]`** — the profile in effect, the
  token subject, and both expiries; says plainly when there is no cache.
- **`hits auth logout [--context <name>]`** — deletes the cache. Nothing
  is revoked at the IDP; that is the deployment's lever.

Connect paths never launch a flow uninvited. An agent, service, or
scripted call that finds no usable cache fails fast:
`no token for connection "acme-prod": run 'hits auth login --context acme-prod'`.

## Tokens and refresh

The cache is `$XDG_STATE_HOME/hits/tokens/<connection>.json` (directory
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

Several processes share one cache: `hits-mcp` and `hits up` hold a
connection long-lived while one-shot CLI calls come and go beside them.
Refresh is therefore **serialized, not merely atomic**: the handler takes
a file lock on the cache entry, re-checks freshness once it holds the lock
(another process may have refreshed first), and only then spends the
refresh token. This matters because IDPs commonly *rotate* refresh tokens
on use — two processes spending the same refresh token concurrently can
trip reuse detection and revoke the whole grant, stranding every process
on that connection. The lock bounds who spends the token; reads stay
lock-free, and the cache write stays an atomic rename.

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
- **No change for context users.** NATS contexts pass through the seam
  untouched, and no hits field is ever squatted into a context file.
