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

## Amendment — 2026-09-05: the MCP server is the packaging exception

The "solved in the skill body, not packaging" bullet assumed every
consumer is an agent reading prose before touching a binary. The plugin
now also ships an MCP server (`hits-mcp`), and there the assumption
fails: the harness launches the server at session start, before any
skill body loads — no agent is in the loop to execute install
instructions.

So for the MCP server, and only for it, packaging does solve the
missing binary. The plugin's `.mcp.json` launches `scripts/hits-mcp.sh`,
a wrapper that resolves the binary in order: `$HITS_MCP_BIN` (developer
override), `hits-mcp` on PATH (a user-managed install), a cached copy
re-verified against its recorded sha256, and finally a checksum-verified
download of the pinned hits release from GitHub. A failed download or
verification never leaves a cached binary behind, and every failure
exits with the same manual install options the skill body teaches.
User-managed installs still win — the download is the out-of-the-box
fallback, not a replacement for brew or `go install`.

**The pin-bump rule:** the wrapper pins `HITS_VERSION`, the hits release
this plugin version is paired with; it is bumped alongside the plugin
version in `.claude-plugin/plugin.json` (and the matching entry in
`marketplace.json`), so a plugin release always names the server release
it ships. Landed in impire-marketplace `9e5eeb3` (plugin v0.4.0).

The skill-body pattern stands unchanged for everything an agent runs
itself: the `hits` CLI, and `hits-mcp` when installed by hand.
