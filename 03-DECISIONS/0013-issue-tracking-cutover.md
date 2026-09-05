# 0013 — Issue tracking cuts over to the tracker

**Date:** 2026-09-05

## Context

Decision [0001](0001-item-store-architecture.md) built HITS to replace the
file-based issue storage this repo runs on, and closed with: "`04-ISSUES/`
remains the working front door until the platform is live; its corpus is
currently empty, so cutover needs no migration." Both clauses are stale. The
platform is live — hits 0.4.0 running on the personal Synadia context, filing,
claiming, and closing through the CLI and the MCP server, with the `hits`
plugin shipping fourteen lifecycle commands — and the corpus holds eleven
records, two of them open. That closing clause is superseded by this record;
0001 itself is immutable and otherwise stands.

What a cutover has to respect, verified against the shipped 0.4.0 contract:

- Item IDs are server-minted dense integers; ID 1 is already spent on a
  tombstoned test record, so folder numbers cannot survive as item IDs.
- `created`, `reporter`, claim attribution, and `closed` stamp the acting
  actor and the current time by design. History cannot be back-dated or
  re-attributed.
- `fixed-by` refs take `pr:`, `commit:`, and `action:` forms only — no repo
  field and no `{repo, tag}` form. Projects are register-only: no rename, no
  unregister.
- Roughly twenty relative-path links point into `04-ISSUES/` from decision
  records (immutable) and research/design docs.

## Decision

- **The tracker is the front door from 2026-09-05.** Bugs, tasks, and
  improvements are filed, claimed, worked, and closed in the running HITS
  install — the platform tracks its own issues. Playbooks
  [03](../00-META/process/03-issues.md) and
  [07](../00-META/process/07-parallel-work.md) bind to it; the repo skills
  delegate to it.

- **Full import, frozen archive.** All eleven records replay into the tracker
  (items 2–12): report, a provenance note carrying the true dates and actors,
  diagnosis and resolution prose as notes, claim, status walk, converted
  refs, terminal transition. The `04-ISSUES/` folders freeze in place as the
  read-only long-form archive — the tracker is authoritative, the folders are
  history, and every existing link keeps resolving. The folder→item map lives
  in [`04-ISSUES/README.md`](../04-ISSUES/README.md); the replay itself is
  [`05-TOOLS/import-issues.sh`](../05-TOOLS/import-issues.sh), kept as it
  ran.

- **The project registry mirrors [`repos.md`](../00-META/repos.md) by hand**
  (item-model.md's standing rule): `hits-hq`, `hits`, and
  `impire-marketplace` registered at cutover, one slug per repos.md row.

- **The file-based rails retire.** `allocate-issue.sh` and `claim.sh` are
  removed — tools are rails, not records, and git history keeps them.
  `status.sh` slims to the sections that stay file-based: research and
  designs.

- **Ref conventions change where the tracker's forms differ.** PR refs are
  repo-qualified (`pr:impire-io/hits#9`), since `fixed-by` has no repo field.
  Releases are recorded as `action:release <product> <version>` with the
  evidence in the note, replacing the dead `{repo, tag}` form.

- **A tracker-rooted piece of work is named by its bare item ID** — branch,
  workspace directory, PR label — per
  [item-model.md](../02-DESIGN/item-model.md)'s standing design.

## Alternatives rejected

- **Freeze only; re-file the open records.** It splits the symptom→component
  memory in two forever — `hits search` would never see the pre-cutover
  corpus, so playbook 03's dedup-first discipline would need two search
  systems indefinitely.

- **Import and delete the folders.** Immutable decision records (0005, 0006,
  0008, 0009) and research/design docs link into `04-ISSUES/` by relative
  path; deleting breaks records that may not be edited, and violates "kept
  forever, in place."

- **Import with fabricated history.** Not available by design: timestamps and
  attribution derive from the op, and faking them is exactly the kind of
  retroactive edit the ops-log exists to prevent. The import accepts
  migration-time stamps and puts the true history in each item's first note.

## Consequences

- `04-ISSUES/` is frozen: banner in its README, no new folders, no edits —
  including the two records that were open at cutover (folder 002 → item 3,
  closed wontfix at import since its subject retires with
  `allocate-issue.sh`; folder 011 → item 12, open in the tracker).
- Imported items' `created`/`claimed`/`closed` fields are migration
  artifacts. The provenance notes, the frozen folders, and this repo's git
  log are the true history.
- Folder `NNN` maps to item `NNN+1`; the authoritative map is in
  `04-ISSUES/README.md`, emitted by the import run.
- `001-hits` — a registration made during setup validation — is permanent
  dead vocabulary beside the real `hits` slug; projects cannot be renamed or
  unregistered (item 15 tracks the improvement).
- The planned `check-claims.sh`/`check-unclaimed.sh` CI guards can never
  exist as designed — they read frontmatter that no longer changes. Their job
  moves to a tracker-side auditor (item 17); until it exists, ref honesty and
  close-after-merge are manual discipline with no net.
- Playbooks 03 and 07, the process overview's status principle, the
  `hits-defer` and `hits-status` skills, and the hits-cli skill's boundary
  note are rewritten to the tracker in this record's landing PR. The
  marketplace copy of the hits-cli skill follows under playbook
  [06](../00-META/process/06-builder-skill-sync.md) (item 16).
- Semantic search is down at cutover — no embedding provider configured
  (item 14) — so playbook 03's dedup step leans on full-text `hits search`
  until it is fixed.
