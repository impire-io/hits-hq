# How We Deploy

Where [`how-we-build.md`](how-we-build.md) says the durable engineering posture a service is built to, this document says how a built service actually reaches a running environment.

It describes **today's reality**, and today's reality is: **nothing is deployed**. HITS has no live environment, no release flow, and no deployment repos yet. This file exists so the structure has its place and so no design silently invents a deployment story — any deployment assumption in a design is currently a deviation and needs its defense inline ([context.md](context.md)).

When the first service reaches a running environment, this document takes on its real content:

- **The pieces** — which repos own what at deploy time (charts, images, desired state, the cluster connection).
- **The release flow** — how a build of a service is cut, versioned, and published.
- **The deploy flow** — how desired state is applied, and what the single source of desired state is.
- **What is expected before enabling a service** — the prerequisites that must exist so first deploy doesn't crash-loop.
- **What "deployed" means** — the running workload, not the green pipeline.

Until then, the honest answer to "how do we deploy?" is: we don't, yet.
