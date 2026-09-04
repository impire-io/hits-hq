---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
claimed-by: Daan Gerits
claimed: 2026-09-04
fixed-by:
  - { repo: hits, tag: "v0.4.0" }
  - { action: deploy, note: "RC v0.4.0-rc.1 validated on the personal Synadia context: the released darwin_arm64 binary reads back 0.4.0-rc.1; the fleet booted on tls://connect.ngs.global three ways — --context personal, plain --server/--creds flags, and NATS_URL/NATS_CREDS alone — each printing the serving line and stopping cleanly. Boot-and-replay provisioned hits-state live: nats kv ls hits-state showed project.001-hits, item.1, and system.item-counter, all folded from the 3-message ops-log. Client-through-fleet reads (ping, project list) were refused by the account's 2-connection cap with one non-hits seat held elsewhere — a lone client connected fine and got no-responders with the fleet down, so the cap, not the code, is what refused; CI's real-NATS fleet tests cover that wiring. Environmental, the same class 007 recorded." }
---

# 010-release-v0-4-0

cut hits v0.4.0 carrying the single-state-bucket collapse (PR #16, spec 010) and the plain connection settings for hits up (PR #17, spec 011): both close-outs defer delivery to this release; the notes must carry the operator cleanup (nats kv del hits-items hits-projects hits-meta) and the RC validates on the Synadia context per the release flow

**Resolution:** v0.4.0 released (tag on `26476f9`, the same commit as
the validated rc — safe since #15 pinned `GORELEASER_CURRENT_TAG`),
assets and checksums published for all six platforms, tap bumped
(`brew: hits v0.4.0`), the released darwin_arm64 binary reads back
`0.4.0`. The release notes lead with the migration: the operator
cleanup command, the two-streams-total footprint, and the new plain
connection settings with their `NATS_*` fallbacks.

Left to the operator on the personal account (the delete is theirs by
design, and this session's rails refused it): the account still holds
the three obsolete buckets at 5 of 5 streams —
`nats --context personal kv del hits-items hits-projects hits-meta`
frees three slots.
