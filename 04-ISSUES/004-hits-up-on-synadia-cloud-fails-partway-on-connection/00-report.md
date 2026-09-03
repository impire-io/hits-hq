---
kind: bug
status: resolved
resolved: 2026-09-03
located-in: [hits]
discovered-while: validating the v0.1.0-rc.2 release of the issue 003 fix on Synadia Cloud
claimed-by: Daan Gerits
claimed: 2026-09-03
fixed-by:
  - { repo: hits, pr: "#10" }
  - { action: deploy, note: "v0.1.0-rc.3 downloaded from the GitHub release and run against the same NGS account: 'hits up --context personal' booted the full fleet — 'hits-node, hits-index-graph, hits-index-search serving on tls://connect.ngs.global:4222' — and a client ping answered 'hits 0.1.0-rc.3'. Both prior failure modes (10113 at provisioning, connection refusal at the third seat) fail differently and neither occurred; SIGTERM produced the graceful stop." }
lands:
  - { repo: hits-hq, pr: "", after: [] }
  - { repo: hits,    pr: "#10", after: [hits-hq] }
  - { repo: hits-hq, pr: "", after: [hits], closes: true }
---

# 004-hits-up-on-synadia-cloud-fails-partway-on-connection

hits up on Synadia Cloud fails partway on connection-limited accounts: hits-node and hits-index-graph start, then hits-index-search's connect is refused with 'nats: maximum account active connections exceeded'. up opens one connection per service (four total, decision 0004), exceeding the account's concurrent-connection allowance; fail-fast tears everything down cleanly. Observed with v0.1.0-rc.2 against the same NGS account as issue 003, immediately after the 003 fix validated there.

**Resolution:** decision
[0006](../../03-DECISIONS/0006-shared-connection-in-up.md) — `hits up`
runs the fleet on one shared connection named `hits-up`, superseding
decision 0004's per-service stance; two concurrent connections end to end
with the client. Fixed in `hits` by impire-io/hits#10, shipped in
`v0.1.0-rc.3`, and validated on the account that surfaced it (the
`action: deploy` entry above). Diagnosis trail in
[`01-diagnosis.md`](01-diagnosis.md).
