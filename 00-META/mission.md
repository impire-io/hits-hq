# Mission

## Vision

Issue tracking that lives where the work actually happens. Agents and engineers file, triage, diagnose, and close work through the same tools they do the work with — tracking becomes a byproduct of working, not a parallel bookkeeping chore. Humans steer and follow along; nothing gets lost, every step is replayable, and the state of the work is always one lookup away.

## Mission

We build HITS: a **headless issue tracking system** — the backend for keeping track of everything that needs doing: bugs, tasks, improvements, research. It is the agentic replacement for tools like JIRA, and the productized form of the issue system this HQ repo itself runs on.

There is no UI at the core. The action surface is the API, exposed to agents through an MCP server; agents are the first-class operators. Dashboards for humans — management following what is being done, what is blocked, what is being researched — come later, as views built on top of the same API, never as a side door.

## Core Values

- **Headless first** — the API is the product. Every capability exists as a callable surface before any screen shows it; human views are derived, downstream, and replaceable.
- **Agent-native** — the primary operator is an agent acting through MCP. Humans direct, review, and consume; agents do the recording as part of doing the work.
- **Nothing is lost** — every change is an event on the ops-log. Current state is a projection of history, history is replayable, and every action is traceable to who did it and why.
- **Simple to operate** — discoverable micro services with management endpoints, and derived state that can always be rebuilt. Losing a projection is a replay, not an incident.
