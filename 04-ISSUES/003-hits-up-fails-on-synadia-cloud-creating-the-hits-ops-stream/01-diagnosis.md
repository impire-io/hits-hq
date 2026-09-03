# Diagnosis

**Cause, one glance:** `openStore` (`hits` repo, `internal/node/store.go`)
creates the `hits-ops` stream — and the three KV projection buckets — with
no `MaxBytes`. Accounts with the max-bytes requirement (Synadia Cloud NGS
among them) reject any stream config without a byte budget: err 10113,
exactly the error observed. The buckets would fail the same way right
after the stream, since KV buckets are streams underneath.

**Design gap, not a code slip:** [`ops-log.md`](../../02-DESIGN/ops-log.md)
prescribed "unlimited retention", so the code faithfully implemented a
config a whole class of accounts refuses — and the flagship onboarding
target (research 001, decision 0004) is in that class. Per playbook 03 the
amendment leads: decision
[0005](../../03-DECISIONS/0005-byte-budgets.md) settles byte budgets
(defaults everywhere, `DiscardNew` on the ops stream so full refuses
writes rather than trimming history, one `--max-bytes` override), the
design docs are amended, and the code fix follows through playbook 04.

**Why rc.1 shipped this:** every environment exercised before the RC —
embedded test servers, the local smoke server — ran without account
limits, where an uncapped stream is accepted. The first limits-required
account was the first real user run.
