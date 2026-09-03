---
kind: task
status: resolved
resolved: 2026-09-03
located-in: [hits-hq]
discovered-while: research 001 (single-binary onboarding), verifying the download-a-binary story against hits main
claimed-by: Daan Gerits
claimed: 2026-09-03
---

# 001-00-meta-how-we-deploy-md-claims-no-release-flow-exists-but

00-META/how-we-deploy.md claims no release flow exists, but the hits repo ships a goreleaser config and a GitHub release workflow (currently building only the hits and hits-node binaries). Rewrite the doc to describe the actual release/distribution story once research 001 settles the shipped-binary set.

**Resolution:** the shipped set was settled by decision
[0004](../../03-DECISIONS/0004-hits-up.md) and runs on `hits` main
(impire-io/hits#7), so the doc was rewritten in this same change:
distributed-not-deployed as the standing posture, the tag-driven release
flow (`v*` → tests → goreleaser → GitHub release, `hits` + `hits-mcp`),
what running it takes, and the note that `v0.0.1` predates the decision
and shipped the old set. The fix rides this record's own PR — single-repo
work carries the fix and the closing edit together (playbook 07).
