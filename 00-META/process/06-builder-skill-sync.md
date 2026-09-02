# Playbook 06 — builder-skill sync

**Trigger:** a contract that a `papa-marketplace` builder skill teaches changed in the repo that owns it — an SDK release, a design amendment reaching `implemented`, or a wire-contract change landing on a code repo's main branch.
**Who:** an agent drafts; an engineer reviews before the plugin version is bumped. Review is never skipped.

## The derivation contract

- `papa-marketplace` (sibling repo) holds the skills that teach people to **build on** the platform. It is a **derived view**, like papa-docs: no contract is ever decided or first recorded there.
- Every skill declares its upstream sources in `papa-marketplace/DERIVATION.md` — repo, path, and what the skill takes from each. A skill with no row cannot be kept current and is not published.
- Skills restate **decisions and semantics** (stable) and never restate **signatures or identifier strings** (they drift). A signature change should therefore require no skill edit; if it does, the skill has drifted toward restating the surface and is pulled back rather than patched.

## Steps

1. Identify what changed: the contract commits in the owning code repo since the papa-hq commit recorded as the sync marker in `papa-marketplace`'s README.
2. Map changed contracts to affected skills via `DERIVATION.md`.
3. For each affected skill, check the two failure modes separately:
   - **Wrong** — a decision or semantic the skill states is no longer true. Fix it.
   - **Over-specified** — a signature change forced an edit. Remove the restated surface and point at the source instead.
4. Redraft the affected skills. Where a skill names something as stale (a superseded doc, a retired value), re-check that the warning is still accurate.
5. An engineer reviews. Bump the version in both `.claude-plugin/marketplace.json` and the plugin's `.claude-plugin/plugin.json` only after review.
6. Update the sync marker in `papa-marketplace`'s README to the papa-hq commit just synced.

## Note on the trigger

This playbook fires reliably from papa-hq events — [playbook 04](04-build-handoff.md) step 7 runs it on every status flip. It does **not** observe an SDK release that happens without a papa-hq design change. Closing that gap needs a line in the owning code repo's `AGENTS.md`, pointing here when the wire contract changes.
