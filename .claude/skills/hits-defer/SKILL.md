---
name: hits-defer
description: File a deferred follow-up (type task) in the HITS tracker mid-flow, without breaking stride. Use when something needs doing later — a doc sync, a rename, a handoff — is noticed while doing something else and must not be lost.
---

# hits-defer — file a deferred follow-up

The one-line way to capture a `task` without breaking stride (playbook [03](../../../00-META/process/03-issues.md)). A task is a known follow-up, not a defect: it already knows its repo and skips diagnosis entirely. Items live in the running HITS install (decision [0013](../../../03-DECISIONS/0013-issue-tracking-cutover.md)).

## Steps

1. **Curate first.** File only what is worth surfacing when someone next works in that repo — "deferred, not filed" is a valid, deliberate outcome. If the user gave you a batch of minor items, propose one rollup task pointing at the trail rather than one item per entry.
2. Determine the owning repo(s) from [`00-META/repos.md`](../../../00-META/repos.md) — the registry mirrors it, one slug per row. If no code repo owns it yet, `hits-hq` is a valid owner.
3. File the item (the MCP `create_item` tool is the same call):

   ```
   hits create --type task --project <slug> \
     --discovered-while "<the context it was noticed in>" \
     "<what needs doing, in plain terms>"
   ```

   `--discovered-while` is optional but cheap — it is the context the next reader will otherwise have to rediscover. `--priority high|low` only when it genuinely differs from normal.
4. Report the printed integer ID back to the user — that ID is the work ID if anyone picks it up.

## Do not

- Do not expand the report beyond the symptom — the report is set at creation and never edited; detail is added later as notes, by whoever works it.
- Do not file a defect this way. A bug takes the normal playbook 03 route (`--type bug`, no project), because it usually does not know its owning repo yet.
- Do not file into `04-ISSUES/` — the folders froze at cutover (decision 0013).
