---
kind: task
status: open
located-in: [hits]
---

# 009-up-plain-nats-connection-flags

hits up connects only through a context; it should also take plain NATS connection settings - server URL, creds file, user/password, nkey, TLS - as flags and as the nats CLI NATS_* env vars, for CI and container runs where minting a context first is friction
