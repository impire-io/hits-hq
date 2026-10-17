# The replay — the corpus on chronicle, with its authors and times

Question 9 of the [overview](00-overview.md), run on 2026-10-17: the
running install's `hits-ops` stream, read from sequence 1, written into a
chronicle store as operations, and chronicle's derived state compared to
the install's own fold. The one piece [`02-the-spike.md`](02-the-spike.md)
left unproven — a writer stating another actor's name and time — needs
the Go client, so this is a Go program on the `hits` module's own
packages ([appendix](#appendix--the-program)), run against a quick start
built from chronicle's `chronicle-75` branch (chronicle-hq decision 0059
built: preconditions and the type schema judged on every merge), with
the types [`01-the-mapping.md`](01-the-mapping.md) describes and the
choices of decision [0019](../../03-DECISIONS/0019-the-writer-is-the-client-the-store-does-not-require-verified-authors-and-a-release-lives-under-its-initiative.md).

## What was run

**The reader.** The install's stream through the `personal` hits
context, read-only: an ordered consumer from sequence 1 to the stream's
last. Every op's envelope decoded as `contract.Op`; every op folded on the
hits side with `contract.Apply`, `ApplyProject`, `ApplyInitiative`,
`ApplyRelease` — the install's own fold, kept per entity as the expected
state.

**The writer.** For every op, one operation on the mapped path, published
directly on the store's subject — the bare client's route, which an
importer is — with the record's own headers: the op's id as `Nats-Msg-Id`,
its `actor` as `Op-Author`, its `at` as `Op-Ts`, the create-if-absent
guard on every create. The data is the mapping's: for a `created`, the
item's state after the op; for a `noted`, `{text}`; for everything else,
the **diff** between the item's state before and after the hits fold —
changed fields as their new value, removed fields as `null` — which is
exactly the read-modify-write a HITS client on chronicle performs. The
vocabularies the same way: `registered` as `create` with the whole state,
`assigned`, `retired` and `shipped` as diffs. A release lands at
`initiative/<initiative>/releases/<slug with . → _>`. After the stream,
one `mint` per initiative writes the counter: the next number after the
highest the corpus holds under its prefix.

**The types**, as the mapping and the spike declare them, now with the
preconditions decision 0059 makes possible: no operation on a tombstoned
item; `transition` and `block` only from `open`, `diagnosing` or
`located`; `claim` on anything not terminal; `release` only when claimed;
`unblock` only when blocked; `create` only onto nothing; a vocabulary's
`retire` and `assign` only when not retired, a release's `ship` only when
neither shipped nor retired. The item schema states the terminal shape:
`closed` required when the status is `resolved` or `wontfix`, forbidden
otherwise.

**The verification.** For every item, chronicle's state (`instance get`,
through the Go client) compared field for field to the mapping of the
install's final snapshot; its history read back and every `note` matched
to the snapshot's notes by author and time; and every operation of the
history judged with `contract.FoldStep` under the declared types — the
same judgement the node's fold makes — so that an operation the
preconditions or the schema refuse shows as a mark. The projects,
initiatives (with their counters) and the release compared the same way.

## What happened

```
hits-ops: 940 ops, sequences 1..940
replayed 940 ops in 3m36s: 134 items, 13 projects, 4 initiatives, 1 releases
  assign 5  block 9  claim 104  create 152  edit 163  link 54  mint 4  note 307
  release 1  retire 1  ship 1  tombstone 1  transition 134  unblock 8
verified 134 items, 13 projects, 4 initiatives, 1 releases: 0 mismatches, 0 marks
the replay reproduces the install: every state, every note's author and time, no operation marked
```

Read back with the CLI built from the same branch:

```
$ chronicle instance history item/chronicle-38
SEQ  OPERATION  AUTHOR   VERIFIED  TIME                  MARK  DATA
516  create     calmera            2026-09-22T09:13:46Z        {"created":"2026-09-22T09:13:46.017795861Z","discovered-while":"Daan's positioning conversation …
664  claim      calmera            2026-10-11T16:55:11Z        {"claimed":"2026-10-11T16:55:11.622384507Z","claimed-by":"member/calmera"}
668  note       calmera            2026-10-11T17:07:26Z        {"text":"Direction recorded: chronicle-hq decision 0047 …
669  release    calmera            2026-10-11T17:14:43Z        {"claimed":null,"claimed-by":null}
…
$ chronicle instance list --type item --where status=open      # 22 open items, as the tracker says
$ chronicle instance list --in initiative/hits
PATH                            TYPE     SEQ  NAME                             SHIP-NOTE
initiative/hits/releases/0_7_0  release  310  hits v0.7.0 — release targeting  first live use of the verb; the straggler …
$ chronicle instance get initiative/chronicle                  # "next": 80
```

The three and a half minutes are the read, not the write: each `Next` on
the ordered consumer is a round trip to the hosted install (about 230 ms);
the local publishes are not measurable beside it. A migration reads the
stream once; a batched read would make it seconds.

## Findings

1. **The corpus moves as history, exactly.** Every one of 134 items, 13
   projects, 4 initiatives and the release derives to the install's own
   snapshot from the replayed operations, with the install's op ids as
   message ids, the actors as authors and the times as `Op-Ts` — decision
   0018 point 5 and 0019 point 3, proven on the whole corpus. Nothing was
   re-filed, re-attributed or re-dated, and nothing rode in the data that
   the record has a field for.
2. **The corpus obeys the preconditions.** Not one of 940 operations is
   marked under the lifecycle rules as declared — the invariants
   `hits-node` enforced before every append hold in the history it wrote,
   and the preconditions encode them faithfully enough to let every real
   operation through. The two rules the mapping could not express as a
   precondition — a `claim` on a claimed item without a steal, and the
   terminal item's exception for the legacy initiative edit — did not
   need one: the corpus holds no such operation that a precondition would
   have had to let through.
3. **The schema's terminal shape holds too.** `closed` is present on
   every terminal item and absent on every open one, through every
   transition the corpus made — the `if`/`then`/`else` on the item schema
   marked nothing, so decision 0059's second rule costs the corpus
   nothing and would catch a reopen.
4. **The diff is the write model.** A HITS client on chronicle sends, per
   op, the fields the op changed and `null` for the ones it cleared; the
   replay shows that write model reproduces every state the hits fold
   produces, so the client package keeps `contract.Apply` as the thing
   that computes the merge and sends the diff — no second fold to write.
5. **The counters.** `next` on each initiative is the number the install
   would mint next; the legacy bare ids stay outside every counter, as
   the model says.
6. **One thing to decide, not a gap:** `reporter` and `claimed-by` are
   written as `member/<handle>`, so that the graph's edges have a target
   to walk from; the spike wrote `reporter` as a bare handle. The design
   that graduates question 1 states one spelling; the replay used the
   path on both.

## What this changes

- Question 9 is answered: the migration is one read of `hits-ops` and
  one direct publish per op; the cutover design (freeze, replay, verify
  with this comparison, repoint the contexts, retire the stream) can be
  written from it.
- The verification above is the cutover's acceptance test: every
  snapshot equal, every note's author and time equal, no mark. The
  program is its first implementation.
- Research 005 has nothing unproven left against chronicle as it stands;
  what remains is to decide (questions 1 (the rest), 2, 4, 5, 7, 8, 10
  and 11) and to design.

## Appendix — the program

`cmd/hits-replay/main.go` on a throwaway branch of `hits`
(`research-005-replay`, never merged), with `go.mod` carrying
`replace github.com/impire-io/chronicle => <the chronicle-75 worktree>`.
Run as `hits-replay --url nats://127.0.0.1:4572 --nkey <dir>/user.nk
--store hits` against `chronicle up --dir <dir> --port 4572`.

```go
// Command hits-replay is research 005's replay proof (hits-hq
// 01-RESEARCH/005-hits-on-chronicle, question 9): it reads the running
// install's hits-ops stream from sequence 1 and writes every op into a
// chronicle store as an operation on the mapped path — the original actor
// as Op-Author, the original time as Op-Ts, the original op id as the
// message id — then verifies that chronicle's derived state equals the
// install's own fold, item for item, that the trail's notes are in the
// history with their authors and times, and that no operation of the
// corpus is marked under the types' preconditions.
//
// It is a spike: never shipped, never merged; the research document keeps
// it as an appendix. It reads the install and never writes to it.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"reflect"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	chron "github.com/impire-io/chronicle/client"
	ccontract "github.com/impire-io/chronicle/contract"

	"github.com/impire-io/hits/contract"
	"github.com/impire-io/hits/internal/connect"
)

func main() {
	hitsCtx := flag.String("context", "personal", "the hits context to read hits-ops from (read-only)")
	stream := flag.String("stream", contract.OpsStream, "the ops stream to read")
	url := flag.String("url", "", "chronicle's NATS url (the quick start prints it)")
	nkey := flag.String("nkey", "", "the quick start's member key (dir/user.nk)")
	principal := flag.String("principal", "admin", "the principal the key belongs to")
	store := flag.String("store", "hits", "the store to replay into (created)")
	actor := flag.String("actor", "calmera", "the author of the ops the replay itself writes (the counters)")
	limit := flag.Int("limit", 0, "replay at most this many ops (0: all)")
	flag.Parse()
	if *url == "" || *nkey == "" {
		fmt.Fprintln(os.Stderr, "hits-replay: --url and --nkey are required")
		os.Exit(2)
	}
	if err := run(*hitsCtx, *stream, *url, *nkey, *principal, *store, *actor, *limit); err != nil {
		fmt.Fprintln(os.Stderr, "hits-replay:", err)
		os.Exit(1)
	}
}

// --- the types, as research 005 maps them ---------------------------------

const (
	notTombstoned = `{"not":{"properties":{"tombstoned":{"const":true}},"required":["tombstoned"]}}`
	active        = `{"properties":{"status":{"enum":["open","diagnosing","located"]}},"required":["status"]}`
	notTerminal   = `{"properties":{"status":{"enum":["open","diagnosing","located","blocked"]}},"required":["status"]}`
	isBlocked     = `{"properties":{"status":{"const":"blocked"}},"required":["status"]}`
	isClaimed     = `{"required":["claimed-by"]}`
	notRetired    = `{"not":{"properties":{"retired":{"const":true}},"required":["retired"]}}`
	notShipped    = `{"not":{"anyOf":[{"properties":{"shipped":{"const":true}},"required":["shipped"]},{"properties":{"retired":{"const":true}},"required":["retired"]}]}}`
	createOnly    = `{"maxProperties":0}`
	anyObject     = `{"type":"object"}`
)

func allOf(schemas ...string) json.RawMessage {
	return json.RawMessage(`{"allOf":[` + strings.Join(schemas, ",") + `]}`)
}

func op(schema string, effect string, precondition json.RawMessage) ccontract.OpDef {
	return ccontract.OpDef{Schema: json.RawMessage(schema), Effect: effect, Precondition: precondition}
}

var itemSchema = json.RawMessage(`{
  "type": "object",
  "required": ["type", "status", "priority", "report", "reporter", "created"],
  "properties": {
    "type": {"enum": ["bug", "task", "improvement"]},
    "status": {"enum": ["open", "diagnosing", "located", "blocked", "resolved", "wontfix"]},
    "priority": {"enum": ["high", "normal", "low"]},
    "report": {"type": "string", "maxLength": 8192},
    "located-in": {"type": "array", "items": {"type": "string"}},
    "links": {"type": "object"},
    "tombstoned": {"type": "boolean"}
  },
  "if": {"properties": {"status": {"enum": ["resolved", "wontfix"]}}},
  "then": {"required": ["closed"]},
  "else": {"not": {"required": ["closed"]}}
}`)

func defineTypes(ctx context.Context, c *chron.Client, store string) error {
	merge, none := ccontract.EffectMerge, ccontract.EffectNone
	types := []struct {
		name string
		def  chron.TypeDefinition
	}{
		{"release", chron.TypeDefinition{
			Schema: json.RawMessage(`{"type":"object","required":["slug","name"]}`), History: ccontract.HistoryFull,
			Operations: map[string]ccontract.OpDef{
				"create": op(anyObject, merge, json.RawMessage(createOnly)),
				"ship":   op(anyObject, merge, json.RawMessage(notShipped)),
				"retire": op(anyObject, merge, json.RawMessage(notShipped)),
			}}},
		{"initiative", chron.TypeDefinition{
			Schema: json.RawMessage(`{"type":"object","required":["slug","name"]}`), History: ccontract.HistoryFull,
			Children: map[string]string{"releases": "release"},
			Operations: map[string]ccontract.OpDef{
				"create": op(anyObject, merge, json.RawMessage(createOnly)),
				"retire": op(anyObject, merge, json.RawMessage(notRetired)),
				"mint":   op(`{"type":"object","required":["next"]}`, merge, nil),
			}}},
		{"project", chron.TypeDefinition{
			Schema: json.RawMessage(`{"type":"object","required":["slug","name"]}`), History: ccontract.HistoryFull,
			Operations: map[string]ccontract.OpDef{
				"create": op(anyObject, merge, json.RawMessage(createOnly)),
				"assign": op(anyObject, merge, json.RawMessage(notRetired)),
				"retire": op(anyObject, merge, json.RawMessage(notRetired)),
			}}},
		{"item", chron.TypeDefinition{
			Schema: itemSchema, History: ccontract.HistoryFull,
			Operations: map[string]ccontract.OpDef{
				"create":     op(`{"type":"object","required":["type","status","report","reporter","created"]}`, merge, json.RawMessage(createOnly)),
				"note":       op(`{"type":"object","required":["text"]}`, none, json.RawMessage(notTombstoned)),
				"edit":       op(anyObject, merge, json.RawMessage(notTombstoned)),
				"transition": op(anyObject, merge, allOf(notTombstoned, active)),
				"claim":      op(anyObject, merge, allOf(notTombstoned, notTerminal)),
				"release":    op(anyObject, merge, allOf(notTombstoned, isClaimed)),
				"block":      op(anyObject, merge, allOf(notTombstoned, active)),
				"unblock":    op(anyObject, merge, allOf(notTombstoned, isBlocked)),
				"link":       op(anyObject, merge, json.RawMessage(notTombstoned)),
				"unlink":     op(anyObject, merge, json.RawMessage(notTombstoned)),
				"tombstone":  op(anyObject, merge, json.RawMessage(notTombstoned)),
			}}},
	}
	for _, t := range types {
		if _, err := c.DefineType(ctx, store, t.name, t.def); err != nil {
			return fmt.Errorf("define %s: %w", t.name, err)
		}
	}
	return nil
}

// --- the mapping: HITS state as chronicle state ----------------------------

var itemRef = regexp.MustCompile(`^([a-z][a-z0-9-]*-)?[0-9]+$`)

func refPath(ref string) string {
	if itemRef.MatchString(ref) {
		return "item/" + ref
	}
	return ref // prose: a dangling string, harmless
}

func releaseID(slug string) string { return strings.ReplaceAll(slug, ".", "_") }

func releasePath(initiative, slug string) string {
	return "initiative/" + initiative + "/releases/" + releaseID(slug)
}

func stamp(t time.Time) string { return t.UTC().Format(time.RFC3339Nano) }

// normalize round-trips through JSON so that reflect.DeepEqual compares
// what chronicle will hand back (maps, slices, float64).
func normalize(v any) map[string]any {
	b, _ := json.Marshal(v)
	var m map[string]any
	_ = json.Unmarshal(b, &m)
	return m
}

func itemState(it *contract.Item) map[string]any {
	priority := string(it.Priority)
	if priority == "" {
		priority = string(contract.Normal)
	}
	m := map[string]any{
		"type": string(it.Type), "status": string(it.Status), "priority": priority,
		"report": it.Report, "reporter": "member/" + it.Reporter, "created": stamp(it.Created),
	}
	if it.Initiative != "" {
		m["initiative"] = "initiative/" + it.Initiative
	}
	if it.Target != "" {
		m["target"] = releasePath(it.Initiative, it.Target)
	}
	if it.Claim != nil {
		m["claimed-by"] = "member/" + it.Claim.By
		m["claimed"] = stamp(it.Claim.At)
		if it.Claim.StolenFrom != "" {
			m["stolen-from"] = "member/" + it.Claim.StolenFrom
		}
	}
	if it.BlockedBy != "" {
		m["blocked-by"] = refPath(it.BlockedBy)
	}
	if it.Interrupted != "" {
		m["interrupted"] = string(it.Interrupted)
	}
	if len(it.LocatedIn) > 0 {
		paths := make([]string, 0, len(it.LocatedIn))
		for _, p := range it.LocatedIn {
			paths = append(paths, "project/"+p)
		}
		m["located-in"] = paths
	}
	if it.DiscoveredWhile != "" {
		m["discovered-while"] = it.DiscoveredWhile
	}
	if len(it.Lands) > 0 {
		m["lands"] = it.Lands
	}
	if len(it.FixedBy) > 0 {
		m["fixed-by"] = it.FixedBy
	}
	if len(it.AmendedDesign) > 0 {
		m["amended-design"] = it.AmendedDesign
	}
	if it.Closed != "" {
		m["closed"] = it.Closed
	}
	if len(it.Links) > 0 {
		links := map[string][]string{}
		for _, l := range it.Links {
			links[string(l.Type)] = append(links[string(l.Type)], "item/"+l.To)
		}
		m["links"] = links
	}
	if it.Tombstoned {
		m["tombstoned"] = true
		if it.TombstoneReason != "" {
			m["tombstone-reason"] = it.TombstoneReason
		}
	}
	return normalize(m)
}

func projectState(p *contract.Project) map[string]any {
	m := map[string]any{"slug": p.Slug, "name": p.Name}
	if p.Description != "" {
		m["description"] = p.Description
	}
	if p.Initiative != "" {
		m["initiative"] = "initiative/" + p.Initiative
	}
	if p.Retired {
		m["retired"] = true
		if p.RetireReason != "" {
			m["retire-reason"] = p.RetireReason
		}
	}
	return normalize(m)
}

func initiativeState(i *contract.Initiative) map[string]any {
	m := map[string]any{"slug": i.Slug, "name": i.Name}
	if i.Description != "" {
		m["description"] = i.Description
	}
	if i.Retired {
		m["retired"] = true
		if i.RetireReason != "" {
			m["retire-reason"] = i.RetireReason
		}
	}
	return normalize(m)
}

func releaseState(r *contract.Release) map[string]any {
	m := map[string]any{"slug": r.Slug, "name": r.Name}
	if r.Description != "" {
		m["description"] = r.Description
	}
	if r.Shipped {
		m["shipped"] = true
		if len(r.ShipRefs) > 0 {
			m["ship-refs"] = r.ShipRefs
		}
		if r.ShipNote != "" {
			m["ship-note"] = r.ShipNote
		}
	}
	if r.Retired {
		m["retired"] = true
		if r.RetireReason != "" {
			m["retire-reason"] = r.RetireReason
		}
	}
	return normalize(m)
}

// diff is what the writer sends as a merge: every field that changed,
// a deleted field as null — the read-modify-write a HITS client on
// chronicle performs.
func diff(before, after map[string]any) map[string]any {
	d := map[string]any{}
	for k, v := range after {
		if !reflect.DeepEqual(before[k], v) {
			d[k] = v
		}
	}
	for k := range before {
		if _, ok := after[k]; !ok {
			d[k] = nil
		}
	}
	return d
}

var itemOps = map[contract.OpType]string{
	contract.OpCreated: "create", contract.OpNoted: "note", contract.OpEdited: "edit", contract.OpTransitioned: "transition",
	contract.OpClaimed: "claim", contract.OpReleased: "release", contract.OpBlocked: "block", contract.OpUnblocked: "unblock",
	contract.OpLinked: "link", contract.OpUnlinked: "unlink", contract.OpTombstoned: "tombstone",
}

var vocabOps = map[contract.OpType]string{
	contract.OpRegistered: "create", contract.OpAssigned: "assign", contract.OpRetired: "retire", contract.OpShipped: "ship",
}

// --- the replay --------------------------------------------------------------

type replay struct {
	ctx   context.Context
	js    jetstream.JetStream
	store string

	items       map[string]*contract.Item
	projects    map[string]*contract.Project
	initiatives map[string]*contract.Initiative
	releases    map[string]*contract.Release // key initiative + "/" + slug

	counts map[string]int
	seqs   map[string]uint64 // chronicle sequence per path, for the report
}

func (r *replay) publish(path, opType string, data map[string]any, op contract.Op) error {
	payload, err := json.Marshal(data)
	if err != nil {
		return err
	}
	tail, err := ccontract.PathTail(path)
	if err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	rec := ccontract.Op{ID: op.ID, Type: opType, Author: op.Actor, Ts: op.At, Payload: payload}
	msg := nats.NewMsg(ccontract.OpsSubject(r.store, tail))
	msg.Header = rec.Header()
	if opType == "create" {
		msg.Header.Set(ccontract.HdrExpectedLastSubjSeq, "0")
	}
	msg.Data = payload
	ack, err := r.js.PublishMsg(r.ctx, msg)
	if err != nil {
		return fmt.Errorf("publish %s %s (%s): %w", path, opType, op.ID, err)
	}
	r.seqs[path] = ack.Sequence
	r.counts[opType]++
	return nil
}

func (r *replay) one(subject string, raw []byte, seq uint64) error {
	tokens := strings.Split(subject, ".")
	if len(tokens) < 4 || tokens[0] != "hits" || tokens[1] != "ops" {
		return fmt.Errorf("subject %q is not an ops subject", subject)
	}
	var op contract.Op
	if err := json.Unmarshal(raw, &op); err != nil {
		return fmt.Errorf("%s @%d: decode envelope: %w", subject, seq, err)
	}
	switch tokens[2] {
	case "item":
		id := tokens[3]
		prev := r.items[id]
		next, err := contract.Apply(prev, op, seq)
		if err != nil {
			return fmt.Errorf("item %s @%d (%s): hits fold refuses: %w", id, seq, op.Op, err)
		}
		r.items[id] = next
		opType, ok := itemOps[op.Op]
		if !ok {
			return fmt.Errorf("item %s @%d: unmapped op %s", id, seq, op.Op)
		}
		var data map[string]any
		switch op.Op {
		case contract.OpCreated:
			data = itemState(next)
		case contract.OpNoted:
			var p contract.NotedPayload
			if err := json.Unmarshal(op.Payload, &p); err != nil {
				return err
			}
			data = map[string]any{"text": p.Text}
		default:
			data = diff(itemState(prev), itemState(next))
		}
		return r.publish("item/"+id, opType, data, op)
	case "project":
		slug := tokens[3]
		prev := r.projects[slug]
		next, err := contract.ApplyProject(prev, op, seq)
		if err != nil {
			return fmt.Errorf("project %s @%d (%s): %w", slug, seq, op.Op, err)
		}
		r.projects[slug] = next
		return r.vocab("project/"+slug, op, before(prev, projectState), projectState(next))
	case "initiative":
		slug := tokens[3]
		prev := r.initiatives[slug]
		next, err := contract.ApplyInitiative(prev, op, seq)
		if err != nil {
			return fmt.Errorf("initiative %s @%d (%s): %w", slug, seq, op.Op, err)
		}
		r.initiatives[slug] = next
		return r.vocab("initiative/"+slug, op, before(prev, initiativeState), initiativeState(next))
	case "release":
		initiative := tokens[3]
		slug := strings.Join(tokens[4:], ".")
		key := initiative + "/" + slug
		prev := r.releases[key]
		next, err := contract.ApplyRelease(prev, op, seq)
		if err != nil {
			return fmt.Errorf("release %s @%d (%s): %w", key, seq, op.Op, err)
		}
		if next.Initiative == "" {
			next.Initiative = initiative
		}
		r.releases[key] = next
		return r.vocab(releasePath(initiative, slug), op, before(prev, releaseState), releaseState(next))
	}
	return fmt.Errorf("subject %q: unknown kind %q", subject, tokens[2])
}

func before[T any](prev *T, state func(*T) map[string]any) map[string]any {
	if prev == nil {
		return nil
	}
	return state(prev)
}

func (r *replay) vocab(path string, op contract.Op, prev, next map[string]any) error {
	opType, ok := vocabOps[op.Op]
	if !ok {
		return fmt.Errorf("%s: unmapped op %s", path, op.Op)
	}
	if op.Op == contract.OpRegistered {
		return r.publish(path, opType, next, op)
	}
	return r.publish(path, opType, diff(prev, next), op)
}

// mint writes each initiative's counter: the next number after the highest
// the corpus holds under its prefix — what hits-node's dense counter is at.
func (r *replay) mint(actor string) (map[string]int, error) {
	next := map[string]int{}
	for id := range r.items {
		i := strings.LastIndex(id, "-")
		if i < 0 {
			continue // a legacy bare id: its counter is frozen
		}
		n, err := strconv.Atoi(id[i+1:])
		if err != nil {
			continue
		}
		if slug := id[:i]; n >= next[slug] {
			next[slug] = n + 1
		}
	}
	for slug := range r.initiatives {
		if next[slug] == 0 {
			next[slug] = 1
		}
		op := contract.Op{ID: "mint-" + slug, Op: "mint", Entity: slug, Actor: actor, At: time.Now().UTC(), V: 1}
		if err := r.publish("initiative/"+slug, "mint", map[string]any{"next": next[slug]}, op); err != nil {
			return nil, err
		}
	}
	return next, nil
}

// --- the verification --------------------------------------------------------

type mismatch struct {
	path, field string
	want, got   any
}

func (r *replay) verifyState(c *chron.Client, path string, want map[string]any, out *[]mismatch) error {
	sv, err := c.State(r.ctx, r.store, path)
	if err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	var got map[string]any
	if err := json.Unmarshal(sv.State, &got); err != nil {
		return fmt.Errorf("%s: state is not an object: %w", path, err)
	}
	for k, v := range want {
		if !reflect.DeepEqual(got[k], v) {
			*out = append(*out, mismatch{path, k, v, got[k]})
		}
	}
	for k, v := range got {
		if _, ok := want[k]; !ok {
			*out = append(*out, mismatch{path, k, nil, v})
		}
	}
	return nil
}

type mark struct {
	path, decision, detail string
	seq                    uint64
}

// trail reads an item's history back: the notes with their authors and
// times, and every operation judged as the fold judges it under the
// declared types — a mark is an operation the corpus wrote that the
// preconditions or the schema refuse.
func (r *replay) trail(c *chron.Client, path string, it *contract.Item, marks *[]mark, out *[]mismatch) error {
	res, err := c.Resolve(r.ctx, r.store, path)
	if err != nil {
		return fmt.Errorf("%s: resolve: %w", path, err)
	}
	var state json.RawMessage
	notes := 0
	for op, err := range c.History(r.ctx, r.store, path) {
		if err != nil {
			return fmt.Errorf("%s: history: %w", path, err)
		}
		if op.Type == "note" {
			if notes < len(it.Notes) {
				n := it.Notes[notes]
				if op.Author != n.Author {
					*out = append(*out, mismatch{path, fmt.Sprintf("note %d author", notes+1), n.Author, op.Author})
				}
				if !op.Ts.Equal(n.At) {
					*out = append(*out, mismatch{path, fmt.Sprintf("note %d time", notes+1), stamp(n.At), stamp(op.Ts)})
				}
			}
			notes++
		}
		step := ccontract.FoldStep(res, state, op)
		if step.Moved {
			state = step.State
		}
		switch step.Decision {
		case ccontract.Merge, ccontract.None, ccontract.Reset:
		default:
			*marks = append(*marks, mark{path, step.Decision.String(), step.Detail, op.Seq})
		}
	}
	if notes != len(it.Notes) {
		*out = append(*out, mismatch{path, "notes", len(it.Notes), notes})
	}
	return nil
}

func run(hitsCtx, stream, url, nkey, principal, store, actor string, limit int) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	// The install: read-only, from sequence 1.
	hc, err := connect.Connect(hitsCtx, "hits-replay")
	if err != nil {
		return fmt.Errorf("hits context %q: %w", hitsCtx, err)
	}
	defer hc.Close()
	hjs, err := jetstream.New(hc)
	if err != nil {
		return err
	}
	st, err := hjs.Stream(ctx, stream)
	if err != nil {
		return fmt.Errorf("stream %s: %w", stream, err)
	}
	info, err := st.Info(ctx)
	if err != nil {
		return err
	}
	last := info.State.LastSeq
	fmt.Printf("%s: %d ops, sequences %d..%d\n", stream, info.State.Msgs, info.State.FirstSeq, last)

	// Chronicle: the store and the types.
	c, err := chron.ConnectNkeyFile(url, nkey, principal)
	if err != nil {
		return fmt.Errorf("chronicle: %w", err)
	}
	defer c.Close()
	if _, err := c.CreateStore(ctx, store, "the HITS corpus, replayed by research 005", chron.WithHistory(ccontract.HistoryFull)); err != nil {
		return fmt.Errorf("create store %s: %w", store, err)
	}
	if err := defineTypes(ctx, c, store); err != nil {
		return err
	}
	cjs, err := jetstream.New(c.Conn())
	if err != nil {
		return err
	}
	r := &replay{ctx: ctx, js: cjs, store: store,
		items: map[string]*contract.Item{}, projects: map[string]*contract.Project{}, initiatives: map[string]*contract.Initiative{}, releases: map[string]*contract.Release{},
		counts: map[string]int{}, seqs: map[string]uint64{}}

	// The replay, in stream order.
	cons, err := st.OrderedConsumer(ctx, jetstream.OrderedConsumerConfig{DeliverPolicy: jetstream.DeliverAllPolicy})
	if err != nil {
		return err
	}
	started := time.Now()
	n := 0
	for info.State.Msgs > 0 {
		msg, err := cons.Next(jetstream.FetchMaxWait(15 * time.Second))
		if err != nil {
			return fmt.Errorf("after %d ops: %w", n, err)
		}
		meta, err := msg.Metadata()
		if err != nil {
			return err
		}
		if err := r.one(msg.Subject(), msg.Data(), meta.Sequence.Stream); err != nil {
			return err
		}
		n++
		if n%100 == 0 {
			fmt.Printf("  %d ops replayed (%s)\n", n, time.Since(started).Round(time.Millisecond))
		}
		if meta.Sequence.Stream >= last || (limit > 0 && n >= limit) {
			break
		}
	}
	nexts, err := r.mint(actor)
	if err != nil {
		return err
	}
	fmt.Printf("replayed %d ops in %s: %d items, %d projects, %d initiatives, %d releases\n", n, time.Since(started).Round(time.Millisecond), len(r.items), len(r.projects), len(r.initiatives), len(r.releases))
	kinds := make([]string, 0, len(r.counts))
	for k := range r.counts {
		kinds = append(kinds, k)
	}
	sort.Strings(kinds)
	for _, k := range kinds {
		fmt.Printf("  %-11s %d\n", k, r.counts[k])
	}

	// The verification: let the fold catch up, then compare.
	time.Sleep(2 * time.Second)
	var mismatches []mismatch
	var marks []mark
	for id, it := range r.items {
		path := "item/" + id
		if err := r.verifyState(c, path, itemState(it), &mismatches); err != nil {
			return err
		}
		if err := r.trail(c, path, it, &marks, &mismatches); err != nil {
			return err
		}
	}
	for slug, p := range r.projects {
		if err := r.verifyState(c, "project/"+slug, projectState(p), &mismatches); err != nil {
			return err
		}
	}
	for slug, i := range r.initiatives {
		want := initiativeState(i)
		want["next"] = float64(nexts[slug])
		if err := r.verifyState(c, "initiative/"+slug, want, &mismatches); err != nil {
			return err
		}
	}
	for key, rel := range r.releases {
		if err := r.verifyState(c, releasePath(rel.Initiative, rel.Slug), releaseState(rel), &mismatches); err != nil {
			return fmt.Errorf("release %s: %w", key, err)
		}
	}
	sort.Slice(mismatches, func(i, j int) bool { return mismatches[i].path+mismatches[i].field < mismatches[j].path+mismatches[j].field })
	sort.Slice(marks, func(i, j int) bool { return marks[i].seq < marks[j].seq })
	fmt.Printf("verified %d items, %d projects, %d initiatives, %d releases: %d mismatches, %d marks\n", len(r.items), len(r.projects), len(r.initiatives), len(r.releases), len(mismatches), len(marks))
	for _, m := range mismatches {
		w, _ := json.Marshal(m.want)
		g, _ := json.Marshal(m.got)
		fmt.Printf("  mismatch %s %s: want %s, got %s\n", m.path, m.field, w, g)
	}
	for _, m := range marks {
		fmt.Printf("  mark %s @%d %s: %s\n", m.path, m.seq, m.decision, m.detail)
	}
	if len(mismatches) > 0 || len(marks) > 0 {
		return errors.New("the replay does not reproduce the install")
	}
	fmt.Println("the replay reproduces the install: every state, every note's author and time, no operation marked")
	return nil
}
```
