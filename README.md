# hits-hq

The HQ of the HITS project — the single source of truth for mission, research, design, and decisions. HITS is a headless issue tracking system: the agentic replacement for tools like JIRA, operated by agents through an MCP server, with human dashboards as later, derived views. Since 2026-09-05 the project tracks its own issues in the running HITS install (decision [0013](03-DECISIONS/0013-issue-tracking-cutover.md)). Start with [`00-META/mission.md`](00-META/mission.md).

## Layout

| Folder | What it holds |
|---|---|
| [`00-META/`](00-META/) | The northern star: mission, context, effect, engineering postures, and the process playbooks. |
| [`01-RESEARCH/`](01-RESEARCH/) | Efforts investigating something before it is committed to design. |
| [`02-DESIGN/`](02-DESIGN/) | The designs — prose and diagrams, no code. |
| [`03-DECISIONS/`](03-DECISIONS/) | Numbered, immutable decision records. |
| [`04-ISSUES/`](04-ISSUES/) | The pre-cutover issue records, frozen as the long-form archive — live tracking is in the HITS install itself. |
| [`05-TOOLS/`](05-TOOLS/) | The executable rails of the process (being stood up). |
| [`99-ARTIFACTS/`](99-ARTIFACTS/) | Concluded research that became reference material rather than design. |

## How work moves

```
idea ──► 01-RESEARCH ──► decision (03-DECISIONS) ──► 02-DESIGN ──► spec-kit spec ──► implemented
                                                                    (code repo)
bug/symptom ─────────► tracker item (hits) ──► diagnosis in notes ──► code-repo fix and/or design amendment
```

The playbooks in [`00-META/process/`](00-META/process/) are the contract: engineers and agents follow the same ones, and agents must not act outside them.

Two derived views leave this repo: the code lands in [`hits`](https://github.com/impire-io/hits), and the skills that teach agents to operate the platform are published through [`impire-marketplace`](https://github.com/impire-io/impire-marketplace) under playbook [06](00-META/process/06-builder-skill-sync.md)'s derivation contract (decision [0007](03-DECISIONS/0007-impire-marketplace.md)). The full repo map is [`00-META/repos.md`](00-META/repos.md).

## License

[Sustainable Use License](LICENSE) — free for internal business, non-commercial, and personal use.
