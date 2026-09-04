# 0007 — The skill marketplace: one company-wide repo, `impire-marketplace`

**Date:** 2026-09-04

## Context

Playbook [06](../00-META/process/06-builder-skill-sync.md) foresaw a dormant
`hits-marketplace` sibling repo holding the skills that teach people to
build on the platform, and defined the derivation contract it would sign up
to. The first such skill now exists (`hits-cli`, teaching the CLI), and
keeping it only in this repo's `.claude/skills/` reaches nobody outside it.

The distribution landscape settled while the playbook was dormant. The
Agent Skills standard (agentskills.io) — a folder with a `SKILL.md`, six
frontmatter fields — is adopted by 40+ agent products; the one real
fragmentation left is discovery paths (`.claude/skills/` for Claude Code,
`.agents/skills/` for most others), which the dominant cross-agent
installer (`npx skills add`) resolves per agent. Vendors (Cloudflare,
Supabase) publish **one** repo: `skills/<name>/SKILL.md` at the root, plus
a small `.claude-plugin/marketplace.json` whose plugin points at
`source: "./"` — the same folders feed the Claude plugin marketplace, the
generic installers, and manual copies. The counter-example (Stripe:
per-agent skill copies kept in sync by CI) has already drifted versions
between agents.

## Decision

- **One public repo, `impire-io/impire-marketplace`, company-wide** — not
  the hits-specific `hits-marketplace` playbook 06 foresaw. Impire products
  beyond HITS will want the same channel, and marketplaces are added by
  users once, not per product. Playbook 06 is amended to name it; its
  derivation contract applies unchanged.
- **Cloudflare's dual-purpose layout:** `skills/<name>/SKILL.md` at the
  root serving the Agent Skills standard and generic installers, with
  `.claude-plugin/marketplace.json` + `plugin.json` making the repo itself
  the Claude Code plugin. HITS is the first plugin (`hits`), holding the
  `hits-cli` skill; future Impire products land as further plugins in the
  same manifest.
- **Skills stay within the open spec's six frontmatter fields** (`name`,
  `description`, `license`, `compatibility`, `metadata`, `allowed-tools`)
  so one file loads unchanged in every consumer, and state semantics only —
  flag signatures are pointed at (`hits <command> -h`), never restated,
  exactly the playbook 06 contract.
- **The missing-binary problem is solved in the skill body**, not
  packaging: a leading "check the binary" section (verify `hits version`,
  then brew tap / release tarball / `go install`) plus a troubleshooting
  table. Claude Code plugins have no post-install hook today, and a
  SessionStart hook would run every session; prose the agent executes is
  the pattern the ecosystem converged on.

## Alternatives rejected

- **Per-agent marketplace repos or per-agent skill copies** (Stripe's
  shape): buys nothing over the dual-purpose layout and costs a sync
  pipeline that has already produced version drift at Stripe.
- **`hits-marketplace` as foreseen**: a second Impire product would force
  either a second marketplace for users to add or a rename; starting
  company-wide costs nothing now.
- **Publishing only the Claude plugin format**: unreachable from the
  `.agents/skills/` world (Codex, Gemini CLI, Cursor and the rest), which
  is the larger half of the audience.

## Consequences

- Playbook 06 wakes up: every `hits-cli`-relevant contract change in
  `hits-hq` or `hits` triggers a marketplace redraft, engineer review, and
  a version bump in both `marketplace.json` and `plugin.json`. The sync
  marker lives in `impire-marketplace`'s README; `DERIVATION.md` rows are
  the map.
- This repo's own `.claude/skills/hits-cli` remains the HQ-internal
  variant (it links HQ docs and assumes HQ context); the marketplace copy
  is the derived, self-contained public one. Divergence between them is a
  playbook 06 defect.
- The marketplace repo carries no license yet; one must be chosen before
  the repo is made public.
- [`00-META/repos.md`](../00-META/repos.md) gains the repo's row.
