---
name: hits-cli
description: Operate the HITS tracker with the `hits` CLI — file items, move them through the lifecycle, claim work, append notes, and query by text, meaning, or graph. Use when asked to create, update, or look up items in a running HITS instance, or to work an issue tracked in hits.
---

# hits-cli — using the hits client

The `hits` binary is the terminal view of the full client surface. This skill teaches the semantics — the lifecycle and the flows; for exact flags, `hits <command> -h` is authoritative (semantics are stable, signatures drift — playbook [06](../../../00-META/process/06-builder-skill-sync.md)).

Note: this repo's own process records live in `04-ISSUES/` and have their own skills (`hits-defer`, `hits-status`). This skill is for the product tracker itself.

## Setup

- **Global flags go before the command, command flags after the leading `<id>`.**
- `--context <name>` selects the context the service runs on (e.g. `personal` for Synadia Cloud): hits' own context first (`~/.config/hits/context/<name>.json` — the nats context schema plus an optional `oauth` block, design [idp-auth](../../../02-DESIGN/idp-auth.md)), else the nats CLI's context of that name. `hits ping` verifies the service is reachable before anything else.
- An `oauth` context needs one interactive login before anything connects: `hits auth login --context <name>` (device flow — open the URL, enter the code). Refresh is transparent afterward; `hits auth status` shows where things stand. If a command fails with "no token for context", that login is the fix.
- Every write carries an **actor**: a stable lowercase handle (`daan`, `claude`) from `--actor`, `$HITS_ACTOR`, or `defaults.actor` in `~/.config/hits/config.json` (which also takes `defaults.context`). Set one before writing; commands without one are rejected.
- `--json` for machine-readable output — prefer it when you are parsing.
- `hits up` runs the whole service fleet in this process, in the foreground, against whatever the context points at — or, without a context, plain connection flags (`--server`, `--creds`, `--user`/`--password`, ...) and their nats CLI `NATS_*` env vars (design [hits-up](../../../02-DESIGN/hits-up.md)).

## The model in one breath

Items are `bug` | `task` | `improvement`. Statuses: `open → diagnosing → located → resolved | wontfix`. A **bug** walks the localization stages (`located` requires a project in `located-in`); a **task** already knows its project — it must be created with `--project` and moves straight from `open` to a terminal status; an **improvement** takes either path depending on whether it was filed with a project. Projects are registered slugs (`hits project list`), never free text. Full model: [item-model.md](../../../02-DESIGN/item-model.md).

## Flows

**File:** `hits create --type bug "<report>"` — the report is the symptom in plain terms and how it was observed, not a diagnosis. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal. It prints the item ID — report that back.

**Work:** `hits claim <id>` records intent before starting (steal only abandoned claims, with `--steal`); `hits release <id>` hands it back. Move status with `hits transition <id> --to <status>`; append the diagnosis trail — hypotheses, evidence, dead ends — as you go with `hits note <id> "<text>"`.

**Blocked:** `hits block <id> --by "<what>"` from any active status; `hits unblock <id>` restores exactly the status it interrupted. The record remembers — do not track the prior status yourself.

**Close:** `hits resolve <id> --fixed-by pr:<ref>` (also `commit:<ref>` or `action:<what>` with evidence), or `hits wontfix <id>` with the reasoning in a note. Terminal is terminal: a defect found later is a **new item**, never a reopen.

**Query:** `hits get <id>` for one snapshot; `hits search [<query>]` for full-text with status/type filters; `hits semantic "<text>"` for nearest-by-meaning (use it to check for an existing item before filing); `hits graph neighbors|walk <id>` for the edges — links (`hits link <id> --type duplicates|relates-to <to-id>`), projects, and actors.

## Do not

- Do not reopen a terminal item — file a new one and `link` it if related.
- Do not edit or rewrite the trail; notes are append-only history.
- Do not tombstone a real item — `tombstone` voids filing mistakes (a duplicate filed in error, a test record) and nothing else.
- Do not invent project slugs; `located-in` accepts registered projects only.
- Do not restate flag lists from this skill in other docs — point at `hits <command> -h`.
