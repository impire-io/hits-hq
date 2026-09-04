---
kind: task
status: open
located-in: [hits]
claimed-by: Daan Gerits
claimed: 2026-09-04
---

# 010-release-v0-4-0

cut hits v0.4.0 carrying the single-state-bucket collapse (PR #16, spec 010) and the plain connection settings for hits up (PR #17, spec 011): both close-outs defer delivery to this release; the notes must carry the operator cleanup (nats kv del hits-items hits-projects hits-meta) and the RC validates on the Synadia context per the release flow
