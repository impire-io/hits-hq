---
kind: task
status: resolved
resolved: 2026-09-04
located-in: [hits]
discovered-while: publishing the hits-cli skill to impire-marketplace
claimed-by: Daan Gerits
claimed: 2026-09-04
fixed-by:
  - { repo: hits, pr: "#13" }
---

# 005-cli-config-file

the CLI reads defaults only from flags and HITS_ACTOR; support a per-user config file under $HOME/.config (XDG) for defaults like context and actor, with flags > env > file precedence

**Resolution:** shipped inside the idp-auth build (impire-io/hits#13,
spec 008): `$XDG_CONFIG_HOME/hits/config.json` with `defaults.context`
and `defaults.actor`, precedence flag > env > default, honored by the CLI
and hits-mcp. Scope was settled narrower than filed: decisions
[0009](../../03-DECISIONS/0009-connection-profiles.md)/[0010](../../03-DECISIONS/0010-hits-contexts.md)
put connection configuration in hits context files, so this file holds
client defaults only ([`02-DESIGN/idp-auth.md`](../../02-DESIGN/idp-auth.md)).
