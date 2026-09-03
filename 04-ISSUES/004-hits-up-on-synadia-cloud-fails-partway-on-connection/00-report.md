---
kind: bug
status: located
located-in: [hits]
discovered-while: validating the v0.1.0-rc.2 release of the issue 003 fix on Synadia Cloud
claimed-by: Daan Gerits
claimed: 2026-09-03
lands:
  - { repo: hits-hq, pr: "", after: [] }
  - { repo: hits,    pr: "#10", after: [hits-hq] }
  - { repo: hits-hq, pr: "", after: [hits], closes: true }
---

# 004-hits-up-on-synadia-cloud-fails-partway-on-connection

hits up on Synadia Cloud fails partway on connection-limited accounts: hits-node and hits-index-graph start, then hits-index-search's connect is refused with 'nats: maximum account active connections exceeded'. up opens one connection per service (four total, decision 0004), exceeding the account's concurrent-connection allowance; fail-fast tears everything down cleanly. Observed with v0.1.0-rc.2 against the same NGS account as issue 003, immediately after the 003 fix validated there.
