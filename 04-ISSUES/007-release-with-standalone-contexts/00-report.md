---
kind: task
status: open
located-in: [hits]
discovered-while: reviewing the hits-cli skill sync for 0011
---

# 007-release-with-standalone-contexts

cut a hits release carrying the standalone-contexts rework (PR #14, spec 009): the marketplace skill v0.3.0 teaches the 0011 shape but the newest release v0.2.0 still resolves nats CLI contexts and lacks the 'hits context' verbs, so installed binaries and the published skill disagree until a release lands; validate the RC on the Synadia context per the release flow
