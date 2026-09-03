---
kind: task
status: open
located-in: [hits-hq]
discovered-while: working issue 001, creating its work/<id> PR label
---

# 002-allocate-issue-sh-should-cap-slug-length-issue-001-s-64

allocate-issue.sh should cap slug length: issue 001's 64-char folder name broke the playbook-07 label contract (GitHub caps labels at 50 chars, so work/<id> was rejected and truncated by hand). Cap the generated slug at a word boundary (~40 chars) so a work ID always fits work/<id>.
