# 0014 — Text budgets on ops: bodies 8 KiB, labels 1 KiB, full refuses

**Date:** 2026-09-06

## Context

Tracker item 22, raised while chunking the semantic index (item 21,
PR impire-io/hits#20): the same whole-trail-in-one-value shape that broke
embedding also exists in storage. The fold marshals an item — trail
included — into one `item.<id>` entry in `hits-state`, every `get` reply
carries that same document over the wire, and NATS caps both at the
account's max payload (512 KiB on the Synadia personal account). Decision
[0005](0005-byte-budgets.md) gave every JetStream resource a byte budget,
but the ops themselves have none: `CheckOp` requires text fields to be
non-empty and nothing more, so nothing bounds how fast a snapshot grows or
how large a single op can be. Nothing is near the wall — the fattest
snapshot today is ~10 KiB, about 2% of the cap — but the growth is
unbounded by design, and the wall it approaches is the projection
diverging from the log: an op that appends fine whose fold cannot be
stored.

## Decision

- **Every free-text field on an op has a byte budget, checked at the
  front door.** Two classes, by role: **bodies** — the report and note
  text, the fields that carry prose — are budgeted at **8 KiB** each;
  **labels** — every other free-text field: `discovered-while`,
  `blocked-by`, a tombstone's reason, `fixed-by` refs and their evidence
  notes, `amended-design` entries, `lands` fields, a project's display
  name and description — at **1 KiB** each. Fields already bounded by
  form (actor handles, slugs) keep their regexes.

- **Over budget refuses loudly, never trims** — 0005's posture applied
  to ops. `CheckOp` rejects with a machine-legible `over-budget`
  invariant whose message names the field, its size, and the budget.
  Nothing is truncated: what the log records is always exactly what
  someone wrote (the same principle that settled item 21 against
  truncating embed chunks).

- **The numbers are starting points, not commitments** (0005's stance).
  8 KiB holds ~5× the fattest real note written to date; 1 KiB holds ~3×
  the longest real blocker text. Raising them later is a contract change
  recorded here; no deployed op becomes invalid retroactively since
  checks run at write time only.

- **The note-keyspace split is named and deferred.** Bounding per-op
  size bounds the growth rate, not the total: a snapshot still grows
  with its trail toward the payload cap, budget floor ~64 max-size
  notes, in practice several hundred typical ones. When a real snapshot
  approaches a meaningful share of the cap (~25%), the split returns as
  its own decision: per-note keys `item.<id>.note.<seq>` — the note op's
  zero-padded stream sequence, so lexicographic prefix-listing returns
  trail order and replay reproduces identical keys — paired with paging
  on the `get` reply, because splitting storage without paging the wire
  only moves the wall. Item 22's trail carries the full sketch.

## Alternatives rejected

- **The keyspace split now.** It drags `get` paging with it, changes the
  read surface, and answers a wall that is fifty times away; deciding it
  on evidence instead keeps today's change at the size of the actual
  risk — a single oversized op.

- **One budget on the marshaled payload.** Opaque to the caller — a fat
  `lands` list could crowd out a report, and the error could not name
  the field to shrink. Field-class budgets produce actionable errors.

- **Truncating oversized text.** 0005 forbids trimming the record, and
  item 21 already showed truncation masking real failures; the log holds
  what was written or refuses it.

- **Leaving it unbounded (status quo).** The projection-diverges-from-
  the-log failure arrives silently at the worst possible time, on the
  most-worked item.

## Consequences

- [`ops-log.md`](../02-DESIGN/ops-log.md) § the envelope and
  [`item-model.md`](../02-DESIGN/item-model.md) § invariants and
  § bodies and trail are amended; both docs return to `status: designed`
  until hits' main implements the checks
  ([playbook 04](../00-META/process/04-build-handoff.md)).
- In `hits`: two budget constants in `contract`, an `over-budget`
  invariant in `CheckOp`/`CheckProjectOp` covering every free-text
  payload field, and tests per field class. No storage or wire change.
- Clients see a new refusal they could not see before; the message is
  self-describing, so no skill or doc teaches the numbers
  (playbook 06: semantics, never surface).
- Item 22 closes on the landing PR; the deferred split needs no standing
  item — this record carries its trigger, and the trail of 22 its
  design.
