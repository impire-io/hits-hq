# Proposal — the answers

Proposed answers to the overview's open questions, sized to the
[minimal-feature posture](../../00-META/how-we-build.md): the present need
is Daan's direction — SSO'd humans and agents against an auth-callout
deployment — and nothing speculative rides along.

## One seam: `internal/connect`

A small shared package through which all seven connect sites resolve. It
loads the hits config, resolves the effective context name (explicit flag,
else the nats CLI's selected-context marker), and:

- **no `auth` block for that context** — behaves exactly as today:
  `natscontext.Connect` with the caller's options, nothing added.
- **an `auth` block** — attaches `nats.TokenHandler` backed by the token
  cache, and refuses to proceed (clear error, not `ErrTokenAlreadySet`) if
  the context file also carries a static `token`. One source of truth per
  context.

This is the first brick of the shared bootstrap library
[`repos.md`](../../00-META/repos.md) foresees; it stays inside `hits` under
the same lint-enforced boundaries as everything else.

## Grants: device flow now, nothing else yet

Device authorization (RFC 8628) is the only grant in scope. It serves both
present consumers — a human at a terminal and an agent whose human can
follow a URL — with no callback server, no client secret, no browser
requirement. PKCE covers no case device flow cannot; client credentials has
no consumer today (unattended fleets have creds files as the operator
path). Both are named non-goals; a real, present need reopens them through
playbook 02.

## Explicit login, transparent refresh

- `hits auth login [--context <name>]` runs the device flow against the
  block's IDP and writes the token cache. Login is the **only** interactive
  moment: connect paths never launch a flow uninvited — an agent or service
  hitting an empty cache fails fast with *"no token for context X: run
  `hits auth login --context X`"* rather than hanging on a poll.
- `hits auth status [--context <name>]` prints the block, subject, and
  expiries; `hits auth logout` deletes the cache.
- The token handler is the refresh engine: called by nats.go on every
  connect and reconnect, it returns the cached access token, first
  refreshing it through the refresh token when it is expired or within 60
  seconds of it. Refresh failure returns the stale token — the server
  rejects, nats.go backs off and retries, the handler tries again: recovery
  is automatic once the IDP is reachable. The refresh token itself dying
  means the next failure names the fix (`hits auth login`).

Long-lived processes need no timer of their own: the deployment's callout
bounds the session by the JWT expiry it mints, the server disconnects, and
the reconnect path refreshes. The loop closes without HITS scheduling
anything.

## Config: the `auth` section of the 005 file

IDP settings live in the client config file planned by issue
[`005`](../../04-ISSUES/005-cli-config-file/00-report.md)
(`$XDG_CONFIG_HOME/hits/config.json`), keyed by context name:

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

`issuer` and `client_id` required; `scopes` defaults to
`openid offline_access`. Everything else (endpoints) comes from OIDC
discovery. One IDP per context; a second is a second context.

## Tokens: a file, not a keychain

`$XDG_STATE_HOME/hits/tokens/<context>.json`, directory `0700`, file
`0600`: access token, refresh token, expiry. The OS keychain is a named
non-goal for now — agents and services need non-interactive reads, and a
keychain prompt is exactly the hang the explicit-login rule exists to
prevent. Revisit if a real deployment rejects file storage.

## Non-goals

Server-side anything (validation is the deployment's auth callout — the
fixed dividing line); PKCE; client credentials; keychain storage; verified
actor identity. On the last: the IDP subject is *in* the tokens we now
hold, so mapping it to the actor (amending decision
[0002](../../03-DECISIONS/0002-projects-and-actors.md)) becomes possible —
deliberately left for its own research, and this design must not preclude
it.
