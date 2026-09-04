---
kind: task
status: open
located-in: [hits]
claimed-by: Daan Gerits
claimed: 2026-09-04
lands:
  - { repo: hits-hq, pr: "#4", after: [] }
  - { repo: hits, pr: "#17", after: [hits-hq] }
  - { repo: hits-hq, pr: "", after: [hits], closes: true }
---

# 009-up-plain-nats-connection-flags

hits up connects only through a context; it should also take plain NATS connection settings - server URL, creds file, user/password, nkey, TLS - as flags and as the nats CLI NATS_* env vars, for CI and container runs where minting a context first is friction.

## The settled shape

Amended into [`02-DESIGN/hits-up.md`](../../02-DESIGN/hits-up.md) § plain
connection settings (the leading PR of the `lands:` block): flags named as
the nats CLI names them (`--server`, `--creds`, `--user`/`--password`,
`--nkey`, `--tlscert`/`--tlskey`, `--tlsca`), each falling back to the
nats CLI's `NATS_*` environment variable. The settings assemble the
`nats` subtree of an ephemeral hits context and connect through the
existing `internal/connect` seam, so their semantics are the context
schema's by construction. `--context` alongside any connection flag is an
error; per setting, precedence is flag → environment → configuration.
