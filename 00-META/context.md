# Engineering Context

HITS is built inside Impire as its own product. Unlike a platform embedded in a large enterprise, it starts with few imposed constraints. What is below is the environment as it stands — recorded so decisions can lean on it, and so new constraints land here first when reality imposes them.

## Mandatory

Nothing external is mandated yet. HITS carries no imposed identity provider, cloud, or data-residency requirement today. When a deployment context imposes one, it is recorded here **before** any design assumes it.

## Default

These are the working defaults. Defaults, not mandates — deviations are allowed when justified.

- **Go** for services. The fleet language of preference.
- **The NATS ecosystem** for infrastructure tooling: NATS for transport and discovery, JetStream for persistence, KV for lookup state. (Why NATS is the substrate at all is an engineering posture, not a default — see [how-we-build.md](how-we-build.md).)
- **Embedded over external** for query infrastructure: in-process engines (e.g. Bleve for full-text, an embedded vector or graph store) before operating a separate database.

## Deviations

When a research or design decision deviates from a default, the justification must be written inline in the document that introduces the deviation — typically under a heading such as "Why not Go" or "Why an external store".

A deviation without a written defense is not a valid decision.

## Open

Environment facts not yet settled, listed so designs don't silently assume an answer:

- **Identity** — how humans and agents authenticate, and how an action is attributed to a principal.
- **Deployment target** — where HITS runs when it first runs anywhere.
- **Data residency / compliance** — none imposed today; revisit at first external deployment.
