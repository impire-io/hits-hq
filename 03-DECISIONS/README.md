# 03-DECISIONS

The decision records of the HITS project. Every significant choice — an engineering posture, a graduation from research, a design amendment that settles something — lands here as its own numbered record before the design or code moves.

## Structure

One file per record, numbered with the next free `NNNN`:

```
NNNN-short-slug.md
```

Each record states, in order: **context** (what forced a choice), **decision** (what was chosen), **alternatives rejected** (and why), **consequences** (what this binds us to).

## Rules

- **Records are immutable once made.** A record that turns out wrong is not edited away — it is amended with a dated amendment section, or superseded by a new record that names it.
- Records are dated and numbered in allocation order; the number is never reused.
- The durable form of a posture lives in [`00-META/how-we-build.md`](../00-META/how-we-build.md); the record here carries its context and consequences.

## Backlog

The postures already stated in `how-we-build.md` predate this folder and need their records backfilled: the ops-log as source of truth, every component a NATS micro service, the headless client-API surface, minimal-feature, spec-driven development, and isolated parallel work.
