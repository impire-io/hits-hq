# 0010 — They are contexts: hits-owned context files in the nats context schema

**Date:** 2026-09-04

## Context

Decision [0009](0009-connection-profiles.md) gave hits its own connection
config — self-contained profiles in a `connections` map — but named them
one thing while the selecting flag said `--context`, and invented a new
schema for what is the same concept the nats CLI already has. Daan's
review: if we are building our own named connection configurations, call
them contexts, and use the same mechanism nats contexts use. Verification
against orbit natscontext v0.1.3 shows the mechanism is directly reusable:
its `Settings` schema already carries url, token, user/password, creds,
nkey, cert/key/ca, and `tls_first`; its loader accepts an absolute file
path in place of a name; and unknown JSON fields pass through the
unmarshaler harmlessly.

## Decision

- **hits contexts: one file per context in
  `$XDG_CONFIG_HOME/hits/context/<name>.json`, in the exact nats context
  schema, plus one hits extension — the optional `oauth` block.** A nats
  context file copied into the directory is a working hits context,
  unchanged.
- **The seam feeds the file to natscontext itself** (absolute path to
  `natscontext.Connect`), reusing its loader for url, creds, TLS, and
  every other field; when the file carries `oauth`, hits layers
  `nats.TokenHandler` through the variadic options. An `oauth` context
  whose file also sets `token` is a hard, plainly-worded error — the
  conflict rule now lives inside one file instead of across two systems.
- **Resolution under the one `--context` flag:** hits' own context
  directory first, then the nats CLI's contexts; a name defined in both is
  a hard error. With no flag: the 005 config's default context, else the
  nats CLI's selected context.
- **The 005 config file shrinks to client defaults** (context, actor):
  connection configuration lives in context files, not in `config.json`.
  0009's `connections` map is superseded before any build.
- Everything upstream stands: 0008's dividing line, seam, device flow,
  verbs, cache, serialized refresh; 0009's rule that OAuth never rides a
  *nats CLI* context, its one-flag-one-namespace selection, and nats
  contexts staying first-class and untouched.

## Alternatives rejected

- **0009's `connections` map in `config.json`:** a second name for the
  flag's concept, a new schema for operators to learn, and a bespoke
  loader to write and maintain. Superseded by this record.
- **Extending files in the nats CLI's own context directory:** still
  squatting on another tool's contract — rejected in 0008 and 0009, still
  rejected. The schema is borrowed; the directory is ours.
- **A hits-own selected-context marker (`hits context select`):** the 005
  default covers selection; a select verb is speculative surface until a
  real need shows up.

## Consequences

- [`02-DESIGN/idp-auth.md`](../02-DESIGN/idp-auth.md) is amended: the
  profiles section becomes hits contexts; the seam's profile branch
  becomes "hand the file path to natscontext, layer the token handler".
- The implementation shrinks: no hits-side connection schema or loader —
  the delta over today is the context-directory lookup, the `oauth` block,
  and the token handler.
- hits inherits schema evolution from orbit natscontext (new fields work
  in hits contexts the moment the library understands them) and accepts
  the coupling: a breaking upstream schema change breaks hits context
  files too, mitigated by the library being pinned in `go.mod`.
- Docs and the marketplace skill must say "context" carefully: a context
  is hits' own first, else the nats CLI's — one word, two directories,
  fixed precedence.
