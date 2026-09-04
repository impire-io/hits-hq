---
status: active
---

# 002 — IDP token exchange in the client

## What is being investigated

Letting the `hits` client authenticate against an identity provider itself:
perform the OAuth/OIDC exchange, hold the access and refresh tokens, and
feed the current access token into the NATS connection as `nats.Token()` on
every (re)connect. The dividing line is deliberate and fixed: **HITS owns
the exchange; the deployment owns validation.** A deployment that runs a
NATS auth callout accepting access tokens gets SSO'd humans and agents with
no HITS-side server work — how the callout validates the token is up to
them.

## Why

Daan's direction (2026-09-04): organizations fronting NATS with auth
callout should be able to point `hits` at their IDP and have the system
just work. The pass-through half already exists — every binary connects
through NATS contexts, and a context's static `token` field reaches the
server untouched — but a static token is not an exchange: access tokens
expire, and today nothing in HITS can obtain one, refresh one, or supply a
fresh one when a long-lived process (`hits up`, `hits-mcp`) reconnects. An
expired token currently means a dropped fleet connection stays dropped
until restart.

## What it touches

- The `hits` repo connect path — `internal/cli` and `internal/fleet` both
  call `natscontext.Connect(name, ...)`; the exchange would wrap or extend
  this with a token-handler option so reconnects get a fresh token.
  `hits-mcp` shares whatever the client surface grows.
- Issue [`005-cli-config-file`](../../04-ISSUES/005-cli-config-file/00-report.md)
  — NATS contexts have no IDP fields, so issuer, client id, scopes, and
  token storage location need a home; the planned `$XDG_CONFIG_HOME/hits`
  config is the natural one.
- [Decision 0002](../../03-DECISIONS/0002-projects-and-actors.md) — actor
  identity stays self-declared for now; deriving a *verified* actor from
  the IDP subject is explicitly out of scope here, but the exchange is the
  prerequisite, so the design should not close that door.

## Open questions

- Which grants: device authorization (RFC 8628) fits terminals and agents;
  authorization code + PKCE fits humans with a browser; client credentials
  fits headless fleets. Which land first, and what does the config name?
- Refresh mechanics: refresh ahead of expiry versus on reconnect
  (`nats.TokenHandler`), and what happens when the refresh token itself
  expires mid-session.
- Token storage: OS keychain versus a file next to the config, and what
  the security posture says about agents reading it.
- Shape: a `hits auth login` verb, transparent exchange on first connect,
  or both — and how a NATS context selects its IDP config.
