# 0008 — Client-side IDP auth: hits owns the exchange, the deployment owns validation

**Date:** 2026-09-04

## Context

Organizations fronting NATS with an auth callout that accepts access
tokens should get SSO'd humans and agents on HITS without HITS shipping any
server-side auth. The pass-through half already works — every binary
connects through NATS contexts, and a context's static `token` reaches the
server untouched — but a static token is not an exchange: nothing in HITS
can obtain a token, refresh one, or supply a fresh one when a long-lived
process reconnects, so an expired token strands `hits up` and `hits-mcp`
until restart. Research [002](../01-RESEARCH/002-idp-token-exchange/)
established the mechanics: nats.go's `TokenHandler` is invoked on every
connect and reconnect, it conflicts with a static token by design, and NATS
contexts have no IDP fields, so the settings need a home of our own.

## Decision

- **The dividing line is fixed: HITS performs the OAuth/OIDC exchange and
  feeds the current access token in as the connection token; validating it
  is the deployment's auth callout, and how is up to them.** No callout
  code, no validation, no IDP-side anything ships in HITS.
- **One connect seam, `internal/connect`,** through which all seven connect
  sites resolve. Contexts with an `auth` block in the client config get a
  `nats.TokenHandler` backed by the token cache; contexts without one
  behave exactly as today. A context carrying both an `auth` block and a
  static `token` is a hard, plainly-worded error. This package is the first
  brick of the shared bootstrap library `repos.md` foresees.
- **Device authorization (RFC 8628) is the only grant**, run explicitly by
  `hits auth login`; connect paths never start an interactive flow. Refresh
  is transparent, in the token handler, on every (re)connect. Session
  length is bounded by the deployment (the JWT expiry its callout mints),
  not by timers in HITS.
- **IDP settings live in the 005 config file** (`$XDG_CONFIG_HOME/hits`),
  keyed by context name; **tokens live in
  `$XDG_STATE_HOME/hits/tokens/<context>.json`**, mode 0600.

## Alternatives rejected

- **Leave the exchange to the deployment** (context token + external
  refresher): works for one-shot CLI calls and is why pass-through stays
  supported, but cannot heal a long-lived process's reconnect — the token
  is fixed at process start. The gap is precisely what this decision
  closes.
- **PKCE with a local callback server**: slicker for desktop humans,
  strictly more moving parts, and covers no case device flow cannot.
  Non-goal until a real need reopens it.
- **Client credentials for unattended fleets**: no present consumer —
  operator-shaped deployments hold creds files. Non-goal.
- **OS keychain for token storage**: a keychain prompt is an interactive
  hang for exactly the agents and services this serves. File storage with
  tight modes now; revisit on a real deployment's objection.
- **Extending NATS contexts with IDP fields**: not our file format —
  contexts are the nats CLI's contract, and squatting extra fields in it
  couples us to an upstream that owes us nothing.

## Consequences

- All seven connect sites route through `internal/connect`; the change is
  mechanical at each (`natscontext.Connect` already takes options), and the
  CLI/fleet `Connector` seams keep tests on embedded servers untouched.
- The CLI grows an `auth` verb family: `login`, `status`, `logout`.
- Issue [`005-cli-config-file`](../04-ISSUES/005-cli-config-file/00-report.md)
  stops being hypothetical: this design defines the config file's first
  concrete section, and 005's work inherits that shape as a constraint.
- When this reaches `implemented`, playbook [06](../00-META/process/06-builder-skill-sync.md)
  fires: the `hits-cli` skill's setup section gains the auth story.
- Verified actor identity (the IDP subject is now in hand) becomes
  *possible*; it is deliberately not attempted here and needs its own
  research before touching decision [0002](0002-projects-and-actors.md).
- The design lands as [`02-DESIGN/idp-auth.md`](../02-DESIGN/idp-auth.md);
  build handoff follows playbook [04](../00-META/process/04-build-handoff.md).
