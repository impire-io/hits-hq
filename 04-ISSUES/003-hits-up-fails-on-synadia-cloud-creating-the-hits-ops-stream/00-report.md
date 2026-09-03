---
kind: bug
status: resolved
resolved: 2026-09-03
located-in: [hits]
discovered-while: first real run of the v0.1.0-rc.1 release candidate against Synadia Cloud
claimed-by: Daan Gerits
claimed: 2026-09-03
fixed-by:
  - { repo: hits, pr: "#9" }
  - { action: deploy, note: "v0.1.0-rc.2 downloaded from the GitHub release and run against the NGS account that refused rc.1: 'nats stream info hits-ops' on that account now shows max_bytes 1073741824 and discard new — the exact decided shape, created by the released binary. Boot proceeded past provisioning; the later connection-limit failure on the same account is issue 004, a distinct defect." }
lands:
  - { repo: hits-hq, pr: "", after: [] }
  - { repo: hits,    pr: "#9", after: [hits-hq] }
  - { repo: hits-hq, pr: "", after: [hits], closes: true }
---

# 003-hits-up-fails-on-synadia-cloud-creating-the-hits-ops-stream

hits up fails on Synadia Cloud: creating the hits-ops stream is rejected with 'nats: API error: code=400 err_code=10113 description=account requires a stream config to have max bytes set'. Accounts that require max bytes reject any stream config without a byte budget, and the KV projection buckets will hit the same wall. Observed with the v0.1.0-rc.1 hits binary against an NGS account context ('hits up --context personal').

**Resolution:** decision
[0005](../../03-DECISIONS/0005-byte-budgets.md) — every resource HITS
creates declares a byte budget by default, and the ops stream refuses new
writes at its cap (`DiscardNew`) rather than trimming the source of
record; one `--max-bytes` override. Fixed in `hits` by
impire-io/hits#9, shipped in `v0.1.0-rc.2`, and validated on the account
that surfaced it (the `action: deploy` entry above). Diagnosis trail in
[`01-diagnosis.md`](01-diagnosis.md).
