---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
claimed-by: Daan Gerits
claimed: 2026-09-04
fixed-by:
  - { repo: hits, pr: "#16" }
---

# 008-single-state-bucket

collapse the three KV buckets (hits-items, hits-projects, hits-meta) into the one prefixed hits-state bucket decision 0012 settles: item.>/project.>/system.> keys, history 10, quarter-of-ops budget, and replay deriving system.item-counter so the whole bucket is disposable; migration is boot-and-replay, old buckets are deleted by the operator per the release notes

**Resolution:** spec 010 (impire-io/hits#16, merged as `acb5426`).
`contract` carries the one `StateBucket` constant; the store prefixes
keys, lists projects server-filtered on `project.>`, and `replay` lifts
`system.item-counter` to the highest item ID the log names through a
monotone CAS loop. The FR-31 test now deletes the whole state bucket —
counter included, which the old test spared — and proves the derivation
by minting the next dense ID after replay; the fleet tests assert
`KV_hits-state` at a quarter of the ops budget on a max-bytes-required
account. Full gate green (`make check`: build, race tests, lint).

Still to ride the next release, not held here (playbook 03's bar): the
release notes carry the operator cleanup —
`nats kv del hits-items hits-projects hits-meta` — and the RC validates
on the Synadia context per the release flow.
