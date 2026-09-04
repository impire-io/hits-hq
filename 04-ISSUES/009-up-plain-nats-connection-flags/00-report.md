---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
claimed-by: Daan Gerits
claimed: 2026-09-04
lands:
  - { repo: hits-hq, pr: "#4", after: [] }
  - { repo: hits, pr: "#17", after: [hits-hq] }
  - { repo: hits-hq, pr: "", after: [hits], closes: true }
fixed-by:
  - { repo: hits, pr: "#17" }
amended-design: 02-DESIGN/hits-up.md
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

**Resolution:** spec 011 (impire-io/hits#17, merged as `26476f9`),
built against the design amendment (hits-hq#4, `48b72da`).
`connect.Dial` is the seam's front door — env fill dormant without a
server URL, context-over-env, env-over-configured-default, and hard
errors on the half-pairs natscontext swallows silently (password
without user, half a TLS pair). `hits up` grows the eight flags;
the README getting-started drops the stale pre-0011 `nats context save`
instructions. Wire truth proven against real NATS: `$NATS_URL` alone
connects, flag beats dead env, context beats dead env, user/password
reach a server requiring them (flagged and from env). Full gate green
(`make check`: build, race tests, lint) and CI on the PR.

Rides the next release with 008, not held here (playbook 03's bar): the
RC validates on the Synadia context per the release flow.
