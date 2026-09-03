# Current state and open questions

Verified against `hits` main, 2026-09-03.

## Already true — the connection story is done

- **Every binary resolves its connection through a NATS context** via
  `github.com/synadia-io/orbit.go/natscontext`: the `hits` CLI
  (`hits --context <name> ...`), `hits-mcp`, and all four fleet services take
  a `--context` flag and fall back to the selected context. Synadia Cloud is
  therefore already reachable — a context carrying its creds file is all it
  takes. Nothing new to design here.
- **`hits-node` self-provisions.** It creates or updates the `hits-ops`
  stream and the KV buckets on boot (`CreateOrUpdateStream`,
  `CreateOrUpdateKeyValue`), so a fresh JetStream-enabled account bootstraps
  itself; no separate provisioning step exists or is needed.
- **Binaries are already downloadable.** The repo carries a goreleaser
  config and a release workflow. (`how-we-deploy.md` still says no release
  flow exists — stale, flag for correction.)

## The gap

"Getting started" today means running four service binaries with the right
flags and env. Nothing composes them. And one of them refuses a bare-bones
start: `hits-index-semantic` errors out unless `--embedding-url` and
`--embedding-model` are given, even though the design says the fleet
functions fully without the embedding provider
([`services.md`](../../02-DESIGN/services.md) § embeddings).

## Open questions

1. **Shape: `hits up` subcommand or a separate binary?** A subcommand makes
   one download the whole story — CLI, MCP client surface, and fleet in a
   single artifact — but turns the lean client binary into one carrying
   Bleve and chromem-go. A separate binary (`hitsd`?) keeps the CLI a pure
   client at the cost of a second download. Either way the fleet binaries
   stay: the all-in-one is a getting-started composition, not a replacement
   for running services separately.
2. **The lint-enforced boundary.** `services.md` binds: no service imports
   another, nothing outside a service's tree imports its internals. A
   composition binary must start all four. Candidate resolutions:
   a public `Run(ctx, nc, cfg)` entrypoint package per service (internals
   stay private, the entrypoint is contract); or a single sanctioned
   composition root exempted by the lint. Supervising the four as child
   processes avoids the import but reintroduces exactly the multi-binary
   orchestration the idea exists to remove.
3. **Semantic index optionality.** The trivial path must boot without an
   embedding provider — skip the semantic service and degrade, exactly as
   the design already promises for provider outages. Does that flag move
   into the standalone binary too?
4. **Embedded NATS server: in or out?** The idea as stated points at an
   *existing* NATS system, which keeps HITS free of infrastructure of its
   own. An embedded server (`hits up --standalone`?) would make demos
   zero-dependency but is a scope expansion; propose stating it a non-goal
   until asked for.
5. **Sharing an account.** On Synadia Cloud the stream and KV names
   (`hits-ops`, `hits-items`, …) and the `hits.>` subject space land in a
   shared account. Does one account host at most one HITS, or does the
   fleet need a prefix/JS-domain knob? Today there is no knob — worth an
   explicit decision either way.
