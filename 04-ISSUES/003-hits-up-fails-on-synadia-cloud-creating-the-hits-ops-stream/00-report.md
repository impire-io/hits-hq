---
kind: bug
status: open
discovered-while: first real run of the v0.1.0-rc.1 release candidate against Synadia Cloud
claimed-by: Daan Gerits
claimed: 2026-09-03
---

# 003-hits-up-fails-on-synadia-cloud-creating-the-hits-ops-stream

hits up fails on Synadia Cloud: creating the hits-ops stream is rejected with 'nats: API error: code=400 err_code=10113 description=account requires a stream config to have max bytes set'. Accounts that require max bytes reject any stream config without a byte budget, and the KV projection buckets will hit the same wall. Observed with the v0.1.0-rc.1 hits binary against an NGS account context ('hits up --context personal').
