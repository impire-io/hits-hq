# 04-ISSUES

> **Frozen (2026-09-05, decision [0013](../03-DECISIONS/0013-issue-tracking-cutover.md)).**
> Issue tracking moved into the running HITS install — the platform now
> tracks its own issues. These eleven folders are the pre-cutover archive:
> read-only, kept in place so decision and design records' links keep
> resolving. Nothing is added or edited here, including the two records that
> were open at cutover. The front door is playbook
> [03](../00-META/process/03-issues.md) and the `hits` CLI / MCP server.

## The corpus, in the tracker

Every record was replayed into the tracker at cutover
([`05-TOOLS/import-issues.sh`](../05-TOOLS/import-issues.sh), kept as it
ran). Item timestamps and actors are migration-time artifacts; each item's
first note carries the true dates and attribution, and these folders keep the
long-form prose. Item 1 predates the import — a tombstoned test filing from
setup validation.

| Folder | Tracker item | Imported as |
|---|---|---|
| [`001-00-meta-how-we-deploy-md-claims-no-release-flow-exists-but`](001-00-meta-how-we-deploy-md-claims-no-release-flow-exists-but/00-report.md) | 2 | resolved |
| [`002-allocate-issue-sh-should-cap-slug-length-issue-001-s-64`](002-allocate-issue-sh-should-cap-slug-length-issue-001-s-64/00-report.md) | 3 | open — closed `wontfix` at cutover (`allocate-issue.sh` retires; integer work IDs always fit the label cap) |
| [`003-hits-up-fails-on-synadia-cloud-creating-the-hits-ops-stream`](003-hits-up-fails-on-synadia-cloud-creating-the-hits-ops-stream/00-report.md) | 4 | resolved |
| [`004-hits-up-on-synadia-cloud-fails-partway-on-connection`](004-hits-up-on-synadia-cloud-fails-partway-on-connection/00-report.md) | 5 | resolved |
| [`005-cli-config-file`](005-cli-config-file/00-report.md) | 6 | resolved |
| [`006-standalone-contexts-rework`](006-standalone-contexts-rework/00-report.md) | 7 | resolved |
| [`007-release-with-standalone-contexts`](007-release-with-standalone-contexts/00-report.md) | 8 | resolved |
| [`008-single-state-bucket`](008-single-state-bucket/00-report.md) | 9 | resolved |
| [`009-up-plain-nats-connection-flags`](009-up-plain-nats-connection-flags/00-report.md) | 10 | resolved |
| [`010-release-v0-4-0`](010-release-v0-4-0/00-report.md) | 11 | resolved |
| [`011-decision-0007-says-the-missing-binary-problem-is-solved-in`](011-decision-0007-says-the-missing-binary-problem-is-solved-in/00-report.md) | 12 | open |

## Historical schema

One folder per issue, numbered `NNN-short-slug/`, holding `00-report.md`
(the symptom in plain terms and how it was observed) and, for diagnosed bugs,
`01-diagnosis.md` (the trail — hypotheses, evidence, dead ends). The
frontmatter these records carry:

```yaml
---
kind: bug            # bug (default) | task — a task is a known follow-up, not a defect
status: open         # open | diagnosing | located | blocked | resolved | wontfix
priority: normal     # high | normal | low — optional; triage signal only
claimed-by:          # intent to work it — not started work
claimed:             # YYYY-MM-DD, alongside claimed-by
blocked-by:          # only with status: blocked — the thing being waited on
located-in:          # [repo, ...] once the owner is known (tasks open with this set)
discovered-while:    # tasks, optional — the context it was noticed in
lands:               # cross-repo fixes only: the ordered landing block (playbook 07)
fixed-by:            # on close — verifiable refs (commit/PR), plus action: deploy entries with evidence
amended-design:      # on close, where the fix was a design amendment
resolved:            # YYYY-MM-DD, with status: resolved
---
```

The rules that governed this corpus — dedup-first, curate-don't-dump, done
means delivered, kept forever in place — carried over into playbook 03; only
the storage moved.
