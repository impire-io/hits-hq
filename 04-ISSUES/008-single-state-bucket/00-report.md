---
kind: task
status: open
located-in: [hits]
---

# 008-single-state-bucket

collapse the three KV buckets (hits-items, hits-projects, hits-meta) into the one prefixed hits-state bucket decision 0012 settles: item.>/project.>/system.> keys, history 10, quarter-of-ops budget, and replay deriving system.item-counter so the whole bucket is disposable; migration is boot-and-replay, old buckets are deleted by the operator per the release notes
