# Playbook 05 — external sync

**Trigger:** anything changed in hits-hq that hits-docs retells — design content, a research conclusion, an implementation-status flip.
**Who:** an agent drafts; an engineer reviews before publish. Review is never skipped.

> **Status:** `hits-docs` does not exist yet. This playbook is dormant until it does; it is kept because external publication is strictly downstream by design, and the contract below is what a docs site signs up to when it is created.

## The derivation contract

- hits-docs (sibling repo) is a **derived view**. Every page carries `derived_from:` frontmatter listing the hits-hq files it retells.
- Page status badges and the "Where things stand" page are generated from hits-hq design-doc frontmatter.
- hits-docs' own writing rules hold: plain language a non-technical reader follows, status stated under each opener, research pages never reading as commitments.

## Steps

1. Diff hits-hq since the last sync — the hits-hq commit recorded as the sync marker in hits-docs' README.
2. Map the changed files to affected pages via their `derived_from:` frontmatter. A changed file no page derives from may warrant a new page — judge by audience value, not completeness.
3. Redraft the affected pages in plain language. Update badges and status lines from the design docs' frontmatter.
4. An engineer reviews the drafts. Publish only after review.
5. Update the sync marker in hits-docs to the hits-hq commit just synced.
