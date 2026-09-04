---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
discovered-while: reviewing 0010 after the idp-auth close-out
claimed-by: Daan Gerits
claimed: 2026-09-04
fixed-by:
  - { repo: hits, pr: "#14" }
---

# 006-standalone-contexts-rework

rework the shipped context implementation (impire-io/hits#13, spec 008) to decision 0011: hits-owned context documents with the NATS settings nested under 'nats', resolution without nats CLI fallback, the temp-file shim into natscontext.Connect, and the 'hits context' verb family (ls/add/import/edit/rm, select as sugar over defaults.context); migration is one 'hits context import' per existing nats-context workflow

**Resolution:** shipped as impire-io/hits#14 (spec 009), merged to hits
main. The 0011 shape landed whole: nested document, hits-directory-only
resolution (no context at all still means the default URL, so the
zero-config quickstart survives), the temp-file shim, and the full verb
family with `select` writing `defaults.context`. Validated by the green
`make check` gate (race-detector wire tests included) and a live smoke of
the built binary: add / select / ls / rm, and an import that preserved a
field hits does not know, byte-for-byte under `nats`.
