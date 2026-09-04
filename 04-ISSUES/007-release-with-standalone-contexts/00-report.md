---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
discovered-while: reviewing the hits-cli skill sync for 0011
claimed-by: Daan Gerits
claimed: 2026-09-04
fixed-by:
  - { repo: hits, tag: "v0.3.0" }
  - { repo: hits, pr: "#15" }
---

# 007-release-with-standalone-contexts

cut a hits release carrying the standalone-contexts rework (PR #14, spec 009): the marketplace skill v0.3.0 teaches the 0011 shape but the newest release v0.2.0 still resolves nats CLI contexts and lacks the 'hits context' verbs, so installed binaries and the published skill disagree until a release lands; validate the RC on the Synadia context per the release flow

**Resolution:** v0.3.0 released, tap formula bumped (`brew: hits
v0.3.0`), assets and checksums published for all six platforms. The RC
(v0.3.0-rc.1) validated on the personal Synadia context per the flow:
`hits context import personal` produced a working nested context, the
fleet booted on `tls://connect.ngs.global` through the temp-file shim
(TLS + creds), and the client answered `ping` and `project list` against
the live service. The one error seen was the account's max-connections
cap, hit only because a v0.2.0 fleet was already running on the account
— environmental, and exactly what this validation exists to surface.

The first v0.3.0 tag push failed: it sat on the same commit as the rc
tag, and goreleaser resolved the current tag as the rc, rebuilding rc
artifacts into `already_exists` upload errors. Fixed for good in
impire-io/hits#15 (`GORELEASER_CURRENT_TAG` pinned to the pushed ref);
the final tag was re-cut on that merge commit. The released
darwin_arm64 binary reads back `0.3.0`.
