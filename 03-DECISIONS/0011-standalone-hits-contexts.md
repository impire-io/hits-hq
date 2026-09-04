# 0011 — hits contexts stand alone: a hits document that embeds NATS settings

**Date:** 2026-09-04

## Context

Decision [0010](0010-hits-contexts.md) defined a hits context as a file
in the exact nats context schema plus a top-level `oauth` extension,
resolved hits-directory-first with fallback to the nats CLI's contexts.
Daan's review: a hits context carries more than NATS configuration — it
is a hits-level concept (connection plus identity, with room for more)
that *embeds* NATS settings, not a nats context with a patch. The 0010
shape also has a latent break: `oauth` squats at the top level of
another tool's schema, so any future nats field of the same name
collides — additive upstream changes become dangerous, not just breaking
ones. And 0010 itself flagged the "one word, two directories, fixed
precedence" docs burden its resolution rule created.

Verification against orbit natscontext v0.1.3 (the version pinned in
hits): the package exports exactly one entry point,
`Connect(name, opts...)`, taking a context name or an absolute file
path. There is no exported path from a loaded `Settings` to a
connection — `natsOptions`, `newFromFile`, and `connect` are
unexported, and `SocksDialer` cannot be constructed outside the package.
The loader carries behavior worth keeping: homedir and env expansion on
creds, `nsc` profile lookup, SOCKS proxy, `tls_first`. A nested schema
therefore cannot be fed to the library directly.

## Decision

- **A hits context is a hits-owned document:** one file per context in
  `$XDG_CONFIG_HOME/hits/context/<name>.json`, hits fields at the top
  level (today: the optional `oauth` block), and the NATS connection
  nested under a `nats` key in the **exact orbit `Settings` schema**.
  hits borrows the schema, not the file contract; hits fields can never
  collide with upstream fields because they live outside the subtree.
- **Resolution is standalone:** the explicit `--context` value, else the
  005 config's `defaults.context`, looked up **only** in hits' context
  directory. No fallback to the nats CLI's contexts or its
  selected-context marker. A name that resolves to nothing is a
  plainly-worded error pointing at `hits context import` / `add`.
- **The seam keeps the borrowed loader via a shim:** it extracts the
  `nats` subtree to a 0600 temp file in a private directory, hands the
  absolute path to `natscontext.Connect`, and deletes it after connect —
  preserving expansion, nsc lookup, SOCKS, and `tls_first` with a few
  lines of owned code. When the context carries `oauth`, hits layers
  `nats.TokenHandler` through the variadic options, as before. An
  `oauth` block alongside a `nats.token` value stays a hard,
  plainly-worded error.
- **The verb family is in scope, as the paved path:** `hits context ls`,
  `add`, `import <nats-context-name>`, `edit`, `rm`. Verbs operate only
  on hits' own directory; `import` reads the nats CLI's directory
  read-only and wraps the file under `nats`. `select` is sugar that
  writes `defaults.context` in the 005 config — no new selection state,
  keeping 0010's rejection of a hits-own marker.
- **Everything upstream stands where not named here:** 0008's dividing
  line, seam, device flow, auth verbs, XDG token cache keyed by context
  name, serialized refresh; the rule that OAuth never rides a nats CLI
  context (now structural — nats CLI contexts are no longer in the
  namespace); the 005 config holding client defaults only.

## Alternatives rejected

- **0010's shape (exact nats schema, top-level extension, two-directory
  fallback):** collision-prone extension point, a two-namespace
  resolution story with hard-error collisions, and a docs burden 0010
  itself named. Superseded by this record.
- **A hits-owned option builder from the embedded `Settings`:**
  reimplements the library's ~50-line `natsOptions`, loses nsc lookup
  and the SOCKS dialer outright (unexported), and owns drift with
  upstream forever. Rejected while the temp-file shim stays small;
  revisit if orbit exports a `Settings`-to-options path.
- **Two files per context (hits doc plus a sibling exact-schema nats
  file fed to `Connect` directly):** avoids the shim but splits one
  context's truth across two files — the split 0009 removed across
  systems is no better within one.
- **Keeping a read-only fallback to nats CLI contexts:** preserves
  zero-config passthrough but keeps the two-namespace story alive.
  Import is one command, and the break lands now, while the installed
  base is zero.

## Consequences

- [`02-DESIGN/idp-auth.md`](../02-DESIGN/idp-auth.md) is amended: the
  hits-contexts section takes the nested schema, resolution drops the
  nats fallback, the seam gains the temp-file shim, and the non-goals
  trade "no `hits context` verb family" for "no hits-own selection
  state beyond the 005 default".
- The shipped implementation (impire-io/hits#13, spec 008) is reworked
  to this shape — an issue in `04-ISSUES` carries it. Migration for
  existing workflows is one command per context, e.g.
  `hits context import personal` before `hits up --context personal`.
- Propose upstream to orbit natscontext an exported
  `Settings`-to-options (or connect-from-`Settings`) API; if accepted,
  the temp-file shim disappears.
- Docs and the marketplace skill get the simpler story: a context is
  hits' own, one word, one directory; nats CLI contexts are an import
  source, nothing more.
- Schema coupling to orbit continues for the `nats` subtree exactly as
  0010 accepted it, pinned in `go.mod` — minus the collision risk,
  since hits fields live outside the subtree.
