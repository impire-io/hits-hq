# Playbook 04 — build handoff

**Trigger:** a design in `02-DESIGN` is ready to be built, or must be re-built after an amendment.
**Who:** an engineer initiates; an agent executes in the owning code repo.

papa-hq documents the handoff; the code repos run spec-kit ([decision 0010](../../03-DECISIONS/0010-spec-driven-constitution-governed-development.md)). Spec-kit is referenced, not absorbed.

## Steps

1. Identify the owning code repo(s) via [`../repos.md`](../repos.md). A **new Go
   service builds on `papa-platform-go`** (the `platform` package: `Connect`,
   `Common`, `NewLogger`, `Build`) rather than re-rolling the bootstrap — a Go
   fleet convention, not a platform requirement ([ADR 0016](../../03-DECISIONS/0016-go-services-build-on-papa-platform-go.md)).
2. Open the workspace via [playbook 07](07-parallel-work.md) — one worktree per owning repo, all on the design's work ID.
3. In the owning repo, create the spec-kit spec. It must cite the papa-hq design doc by **path and commit hash**.
4. Check the repo's constitution against the design. A conflict is resolved in papa-hq first ([playbook 02](02-graduation.md)) — never by quietly diverging in the code repo.
5. In the design doc's frontmatter: set `code:` to the owning repo(s), `status: in-progress`, and `updated:` to today. When the build spans more than one repo, add the ordered `lands:` block ([playbook 07](07-parallel-work.md)) — the landing order is declared here, never left as prose.
6. Build in the code repo through its spec-kit flow, pushing to a draft MR from the first commit ([playbook 07](07-parallel-work.md)).
7. When the design's core contract runs on the owning repo's **main branch**, set `status: implemented` and `updated:`. The claim must be defensible from main, not from intent.
8. Run [playbook 05](05-external-sync.md) after every status flip.
9. If the built contract is one a `papa-marketplace` builder skill teaches, run [playbook 06](06-builder-skill-sync.md). `papa-marketplace/DERIVATION.md` says which contracts those are.
10. Tear the workspace down once every MR of the work item has merged ([playbook 07](07-parallel-work.md)).
