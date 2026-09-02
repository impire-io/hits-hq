# Playbook 05 — external sync

**Trigger:** anything changed in papa-hq that papa-docs retells — design content, a research conclusion, an implementation-status flip.
**Who:** an agent drafts; an engineer reviews before publish. Review is never skipped.

## The derivation contract

- papa-docs (sibling repo, Astro Starlight) is a **derived view**. Every page carries `derived_from:` frontmatter listing the papa-hq files it retells.
- Page status badges and the "Where things stand" page are generated from papa-hq design-doc frontmatter.
- papa-docs' own writing rules hold: plain language a non-technical reader follows, status stated under each opener, research pages never reading as commitments.

## Steps

1. Diff papa-hq since the last sync — the papa-hq commit recorded as the sync marker in papa-docs' README.
2. Map the changed files to affected pages via their `derived_from:` frontmatter. A changed file no page derives from may warrant a new page — judge by audience value, not completeness.
3. Redraft the affected pages in plain language. Update badges and status lines from the design docs' frontmatter.
4. An engineer reviews the drafts. Publish only after review.
5. Update the sync marker in papa-docs to the papa-hq commit just synced.
