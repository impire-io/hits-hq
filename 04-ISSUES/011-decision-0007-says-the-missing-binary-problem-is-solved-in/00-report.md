---
kind: task
status: open
located-in: [hits-hq]
discovered-while: building out the hits plugin (MCP server + lifecycle commands) in impire-marketplace
---

# 011-decision-0007-says-the-missing-binary-problem-is-solved-in

Decision 0007 says the missing-binary problem is solved in the skill body, not packaging; the hits plugin now ships hits-mcp via a download wrapper (impire-marketplace scripts/hits-mcp.sh, pinned HITS_VERSION bumping with the plugin version) — amend the decision to record the MCP-server exception and the pin-bump rule
