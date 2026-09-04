# 0009 — Connection profiles: hits-native connection config, OAuth never rides a context

**Date:** 2026-09-04

## Context

Decision [0008](0008-client-idp-auth.md) keyed IDP settings off NATS
context names: the context supplied the server and TLS, the hits config
supplied the IDP block, and a conflict rule forbade the context's own
`token` field. Daan's direction on review: that split is wrong. With OAuth
the connection credentials come from **outside** the context system — the
context contributes nothing but a URL, so the OAuth path should not touch
contexts at all. And once hits owns any connection configuration, it must
be complete: a deployment configured outside the nats CLI needs creds
files, static tokens, other auth mechanisms, and the TLS options in the
same place.

## Decision

- **The client config gains `connections`: named, self-contained
  profiles.** A profile carries the server `url`, at most one auth
  mechanism — `oauth`, `creds`, `token`, `user`/`password`, or `nkey` —
  and an optional `tls` block (ca, cert, key). For a profile, the seam
  builds the NATS options itself; natscontext is not involved.
- **OAuth exists only in profiles.** 0008's context-keyed `auth` blocks
  and their token-conflict rule are superseded before any build; an OAuth
  connection is a profile with `url` + `oauth`.
- **One selector, one namespace.** The existing `--context` global flag
  names a connection: hits profiles resolve first, then NATS contexts. A
  name defined as both is a hard, plainly-worded error — one source of
  truth per name.
- **NATS contexts remain first-class** for everything they already do;
  profiles serve connections configured outside the nats CLI, they do not
  deprecate contexts. A context-selected connection passes through the
  seam exactly as today.
- Everything else in 0008 stands: the dividing line (HITS owns the
  exchange, the deployment owns validation), the `internal/connect` seam,
  device flow as the only grant, explicit login with transparent
  serialized refresh, the XDG state cache, and the non-goals.

## Alternatives rejected

- **Layering OAuth on contexts (0008's shape):** splits one connection's
  truth across two config systems, multiplies conflict rules, and buys
  only a URL from the context. Superseded by this record.
- **A separate `--profile` flag:** two flags for one concept. One name,
  one flag, and a hard error on collision is the smaller surface.
- **Extending NATS context files with hits fields:** rejected in 0008,
  still rejected — the format is the nats CLI's contract.
- **Profiles without the non-OAuth mechanisms:** would force context-free
  deployments to keep half their connection in each system — exactly the
  split this record removes.

## Consequences

- [`02-DESIGN/idp-auth.md`](../02-DESIGN/idp-auth.md) is amended: the
  config section becomes connection profiles, the seam resolves
  profile-first, the token cache keys by connection name.
- Issue [`005-cli-config-file`](../04-ISSUES/005-cli-config-file/00-report.md)
  inherits the `connections` section as settled shape alongside its
  defaults.
- The seam gains a second construction path: profile → nats options
  (URL, auth option, TLS options, and for OAuth the token handler);
  context → `natscontext.Connect`, unchanged.
- TLS knobs start at ca/cert/key; further options (handshake-first and
  friends) expand on a real, present need per
  [how-we-build](../00-META/how-we-build.md).
