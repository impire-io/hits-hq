# Diagnosis

**Cause, one glance:** `internal/fleet.Start` (`hits` repo) opens one
connection per service — four in total, decision
[0004](../../03-DECISIONS/0004-hits-up.md)'s observability-parity choice.
The account's concurrent-connection allowance seats two of them;
`hits-index-search`'s connect (the third) is refused with
`maximum account active connections exceeded`, and the fail-fast teardown
stops node and graph cleanly. Nothing else is wrong: provisioning (issue
003's fix) had already succeeded on the same boot.

**Design decision, not a code slip:** the code faithfully implements
0004's per-service connections; the account model prices that shape out.
Decision [0006](../../03-DECISIONS/0006-shared-connection-in-up.md)
supersedes the connection bullet: `up` runs the fleet on one shared
connection (`hits-up`), two concurrent connections end to end with the
client. [`hits-up.md`](../../02-DESIGN/hits-up.md) § connections is
amended; the fix follows through playbook 04.

**Why rc.2 shipped this:** every environment before the real account —
embedded test servers, local smoke servers — had no connection limit, so
four connections were as free as one.
