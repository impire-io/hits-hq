# 003 / 01 — Current state and open questions

Facts below verified against the running install and the `hits` repo at
`main` (post spec 014), 2026-09-07.

## What the platform provides today

- **The model is flat.** A project is `{slug, name, description,
  retired, retire-reason, seq}` (`contract/model.go`) — no owner,
  group, or tenant field. Items carry flat `located-in` slugs and
  server-minted dense integer IDs, one sequence per install.
- **Reads are corpus-wide by design.** The client API has no scoping:
  any caller on the account reads every item and every project —
  "one surface, all callers" (how-we-build.md § headless). Search,
  semantic, graph, the status board, and `hits audit`'s dense-ID walk
  all operate on the whole corpus.
- **The isolation unit is the NATS account.** Decision 0004: one HITS
  per account (or JetStream domain), bare stream/bucket/subject names,
  explicitly no prefix knob. Everything inside one account is one
  install, one corpus, one ID sequence, one registry.
- **History is append-only.** The ops-log is the source of truth;
  projections rebuild by replay. Nothing supports deleting another
  group's history out of an install — by mission, not by omission.

## The observed state of our install

- The registry carries our three repos.md rows (`hits-hq`, `hits`,
  `impire-marketplace`), the retired `001-hits` — and `chronicle-hq`,
  which appears in no repos.md this repo governs.
- Item 27 is located in `chronicle-hq`, carrying a commit ref our
  audit mapping rightly reports `unverifiable` (the audit vouches only
  for clones it is explicitly handed — the one surface that turned out
  to be group-safe by construction).
- The corpus is one ID sequence: their items and ours interleave, and
  the work-ID convention (bare item ID as branch name, playbook 07)
  only stays collision-free across groups *because* the sequence is
  shared. A split changes that arithmetic for whichever corpus moves.

## The incident that triggered this

A routine `hits audit` surfaced the foreign item as a warning, and the
natural next step — proposed by an agent, refused by a human — was to
map the other group's clone into our tooling. The boundary held on
attention, not on structure. That is the failure mode to design away.

## Open questions

1. **Is the sharing intentional?** Whether `chronicle-hq` was
   registered here deliberately (one install serving two groups on
   purpose) or as drift determines everything downstream. Needs the
   humans on both sides; nothing below is decidable without it.
2. **If groups separate:** decision 0004 already names the mechanism —
   one HITS per group, each in its own account or JetStream domain.
   The research question is the untangling: can the other group's
   items replay into a fresh install (new IDs, provenance notes — the
   decision 0013 import is the precedent), what happens to work-ID
   branches and refs already named against old IDs, and is the
   permanent residue of their history in our ops-log acceptable under
   "nothing is lost" (it is kept, not leaked — but it is visible)?
3. **If groups stay together:** does the model grow a group field with
   scoped reads — a wire-contract and auth change that decision 0004's
   no-tenancy stance and the minimal-build posture both push back on —
   or do the corpus-wide surfaces (search dedup, status, audit) gain
   scope filters instead, leaving the model flat?
4. **Where do the rails live either way?** The audit is scope-by-
   mapping already. Search and status have no group filter today; the
   registry-mirrors-repos.md rule needs either restoring (split) or
   rewriting (shared, with per-group repos.md ownership stated).
5. **Who owns the conversation?** The other group's install, items,
   and migration are theirs to run; this effort can prepare the
   options and the replay tooling story, not execute across the line.

## Initial position

Held loosely, stated for honesty: decision 0004 already answered where
the boundary lives — the account. One HITS per group is the shape that
keeps the model flat, the surfaces simple, and the minimal-build
posture intact; the real work is the untangling story and the
cross-group coordination, not new tenancy machinery. The proposal doc
should either confirm this against question 1's answer or record why
the shared-install path wins despite it.
