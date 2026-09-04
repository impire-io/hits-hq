---
kind: task
status: open
located-in: [hits]
discovered-while: reviewing 0010 after the idp-auth close-out
claimed-by: Daan Gerits
claimed: 2026-09-04
---

# 006-standalone-contexts-rework

rework the shipped context implementation (impire-io/hits#13, spec 008) to decision 0011: hits-owned context documents with the NATS settings nested under 'nats', resolution without nats CLI fallback, the temp-file shim into natscontext.Connect, and the 'hits context' verb family (ls/add/import/edit/rm, select as sugar over defaults.context); migration is one 'hits context import' per existing nats-context workflow
