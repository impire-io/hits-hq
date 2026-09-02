---
name: hits-defer
description: File a deferred follow-up (kind:task) in 04-ISSUES mid-flow, without stopping to number folders. Use when something needs doing later — a doc sync, a rename, a handoff — is noticed while doing something else and must not be lost.
---

# hits-defer — file a deferred follow-up

The one-line way to capture a `kind: task` without breaking stride (playbook [03](../../../00-META/process/03-issues.md)). A task is a known follow-up, not a defect: it already knows its repo and skips diagnosis entirely.

## Steps

1. **Curate first.** File only what is worth surfacing when someone next works in that repo — "deferred, not filed" is a valid, deliberate outcome. If the user gave you a batch of minor items, propose one rollup task pointing at the trail rather than one record per item.
2. Determine the owning repo(s) from [`00-META/repos.md`](../../../00-META/repos.md). If no code repo owns it yet, `hits-hq` is a valid owner.
3. Mint the record:

   ```
   ./05-TOOLS/allocate-issue.sh --kind task \
     --located-in <repo> \
     --symptom "<what needs doing, in plain terms>" \
     --discovered-while "<the context it was noticed in>"
   ```

   `--discovered-while` is optional but cheap — it is the context the next reader will otherwise have to rediscover. `--priority high|low` only when it genuinely differs from normal.
4. Report the printed ID (`NNN-slug`) back to the user — that ID is the work ID if anyone picks it up.

## Do not

- Do not expand the report inline beyond the symptom — detail is added later, by whoever works it.
- Do not file a defect this way. A bug takes the normal playbook 03 route (no `--kind task`), because it usually does not know its owning repo yet.
