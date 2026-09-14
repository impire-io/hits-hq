# Survey: how milestone/release assignment works where people like it

External evidence, gathered 2026-09-14 across three passes: tracker
data models, planning methodologies, and the JIRA failure literature.
Raw findings condensed; every load-bearing claim cited.

## 1. Tracker data models

### GitHub Milestones — the proven minimum

A first-class per-repository object: title, optional description,
optional due date, open/closed state. An issue carries **at most one**
milestone — a single nullable field, not a label or a many-to-many
relation. Progress is derived (closed/total), never tracked. Filtering
and a milestone view come free.
([docs](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work))

Liked: it is the minimal viable release bucket. OSS projects name
milestones after versions and the closed-milestone list doubles as
release history. Every recorded complaint targets the *constraints*,
not the concept: one milestone per issue (workaround: labels for the
sprint dimension), and repo scope — complained about for a decade
([dear-github#93](https://github.com/dear-github/dear-github/issues/93))
until cross-repo milestones shipped in January 2025
([roadmap#1086](https://github.com/github/roadmap/issues/1086)).
Notable gap: GitHub Milestones and GitHub Releases (tags) are
disconnected objects — nothing closes a milestone when a release is
cut.

### Linear — the two-axis insight

Four first-class objects at different altitudes, deliberately not
interchangeable
([conceptual model](https://linear.app/docs/conceptual-model)):
**Cycles** (a team's repeating timebox — pure cadence, no goal
semantics, unfinished issues roll over automatically so there is no
end-of-sprint accounting;
[docs](https://linear.app/docs/use-cycles)), **Projects** (issues
grouped around a deliverable — the release-shaped object), **project
milestones** (ordered named stages *inside* a project, optional dates,
derived progress;
[docs](https://linear.app/docs/project-milestones)), and
**Initiatives** above projects. An issue can be in a cycle *and* a
project at once: the timebox dimension and the deliverable dimension
are orthogonal fields. The
[Linear Method](https://linear.app/method/introduction) is explicitly
anti-ceremony: momentum over sprints, "keep a manageable backlog" —
discard low-priority items, important things resurface.

Liked (HN [23693029](https://news.ycombinator.com/item?id=23693029),
[25596300](https://news.ycombinator.com/item?id=25596300)): speed, and
that the model enforces proven structure instead of infinite
configurability. The cycle/project split is the most-copied design in
the space — Plane clones it directly as Cycles + Modules and is
praised for exactly that simplicity
([hatica.io](https://www.hatica.io/blog/plane-the-open-source-project-management-tool/)).
Skeptics note fresh-start bias, and the loudest sentiment in the 2026
"Issue Tracking Is Dead" thread
([47507253](https://news.ycombinator.com/item?id=47507253)) is people
begging Linear to stay "just a goddamn issue tracker".

### Shortcut — the drift cautionary tale

Hierarchy: Roadmap → Milestones (collections of epics) → Epics →
Stories, plus Iterations as the timebox
([blog](https://www.shortcut.com/blog/how-we-use-milestones-epics-product-management-clubhouse/)).
In January 2024 Shortcut renamed Milestones to "Objectives," split
into Tactical and OKR-style Strategic variants
([blog](https://www.shortcut.com/blog/from-milestones-to-objectives-how-teams-move-from-shipping-work-to-achieving-outcomes/))
— the milestone concept drifting upward into OKR machinery, with users
reporting disruptive migration and a real learning curve for the
four-level hierarchy.

### GitLab — one object under two duties

Milestones have title, description, optional start *and* due dates,
project or group scope; same cardinality as GitHub — one milestone per
issue ([docs](https://docs.gitlab.com/user/project/milestones/)).
GitLab's docs bless milestones for *both* sprints and releases, and
that overload is exactly what generated the pressure: a separate
Iterations feature, a still-open multi-milestone request from ~2016
([#26408](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/26408)),
and a Release object whose association to milestones was bolted on
later by popular demand
([#29020](https://gitlab.com/gitlab-org/gitlab/-/issues/29020)) —
teams reported 2–3 sprint-milestones making up one release.

### Fossil — the minimalist pole

No milestone concept at all; tickets are append-only artifacts with a
per-repository custom schema, and release planning is deliberately out
of scope
([bugtheory](https://fossil-scm.org/home/doc/tip/www/bugtheory.wiki)).
Projects that want milestones add a field or use tags.

## 2. Planning methodologies that survive practice

### Shape Up: bets, not backlogs

No central backlog exists. Work is chosen at a betting table each
six-week cycle from freshly shaped pitches; unselected pitches simply
expire. Each pitch carries an *appetite* — the time it is worth —
rather than an estimate
([ch. 7](https://basecamp.com/shapeup/2.1-chapter-07),
[ch. 8](https://basecamp.com/shapeup/2.2-chapter-08)). The
load-bearing belief: "Really important ideas come back." Experience
reports praise the betting meeting ("infrequent, short, and intensely
productive") and the psychological relief of carrying no pile; failure
modes are the six-week box itself and cool-down as a bug-latency trap
([2 years with Shape Up](https://scalex.dev/blog/2-years-with-shape-up/),
[mindtheproduct](https://www.mindtheproduct.com/7-lessons-from-trialling-basecamps-shape-up-methodology/)).

### Now / Next / Later: horizons, not dates

Three buckets ordered by *confidence*, invented explicitly as the
antidote to timeline roadmaps, where "putting features in dated
columns turns every date into a commitment"
([origin story](https://www.prodpad.com/blog/invented-now-next-later-roadmap/)).
The further out, the vaguer an item is allowed to be. Known failure:
"Later" degenerates into a dumping ground — "don't let your Later
roadmap become your Never roadmap" (Jen Swanson) — and undefined
horizons get mentally translated back into quarters.

### Trains and decoupled deployment

Release trains fix the date and flex the scope: whatever is done gets
on, everything else waits — the release-time question becomes
mechanical ("is it done?"), never negotiated ("can we squeeze it
in?"). Continuous delivery dissolves the question further by making
"release" a flag-flip decoupled from deployment. The JIRA pathology is
date-fixed *and* scope-fixed — precisely the combination both refuse.
The SAFe-style governance apparatus *around* trains is itself the
pandora's box; the useful kernel is only the cadence rule.

### Someday/maybe and the icebox: the rot law

The best-documented cautionary tale for a tracker author. Pivotal
Tracker's Icebox earned the canonical epithet — thoughtbot's
["The Icebox is where stories go to die"](https://thoughtbot.com/blog/the-icebox-is-where-stories-go-to-die):
hundreds of stories accumulate, and "anything that's been in there
longer than a couple of weeks is never going to get done." Their fix
is aggressive deletion, trusting that real ideas resurface via
stakeholders — the same belief as Shape Up. GTD's Someday/Maybe list
works only because the weekly review forcibly re-scans it. Even
Pivotal's own
["Defrosting Your Icebox"](https://www.pivotaltracker.com/blog/defrosting-your-icebox)
concedes regular deletion is required.

### Bounded inventory and zero-bug

Joel Spolsky, ["Software Inventory"](https://www.joelonsoftware.com/2012/07/09/software-inventory/):
"90% of the things in the feature backlog will never get implemented,
ever," so cap the backlog at a month or two of work, one-in-one-out.
Zero-bug policy is the same move for defects: every incoming bug is
immediately scheduled or closed wontfix; no deferred holding area
exists. The HN counterargument
([34742385](https://news.ycombinator.com/item?id=34742385)) defends
backlogs as *searchable memory* — a knowledge base of decisions — not
as a plan; the reported compromises all bound the planned portion and
demote the rest.

## 3. Why JIRA release planning rots — the mechanisms

- **One field, two questions.** `fixVersion` is read both as plan
  ("intended for 2.0") and record ("shipped in 2.0"); the two drift,
  release notes duplicate multi-version fixes, and teams grow "Target
  Version" custom fields to escape their own field
  ([Atlassian community](https://community.atlassian.com/forums/Jira-questions/Best-Practice-for-Fix-Version/qaq-p/806281),
  [onpointserv](https://www.onpointserv.com/post/the-jira-fix-version-mistake-that-duplicates-your-release-notes)).
- **No owner.** The field is multi-valued and writable by anyone, so
  it becomes an aspiration dump. Atlassian's own community answers say
  Jira "is not intended for heavy use of release version management."
- **Versions accumulate forever**, cluttering dropdowns; "it's
  alarmingly easy to assign next quarter's work to last quarter's
  release."
- **Planning inventory rots** (Shape Up ch. 7); "backlog bankruptcy"
  is a named recovery practice
  ([productplan](https://www.productplan.com/backlog-bankruptcy/)).
- **Decomposition eats the macro picture** — Jon Evans,
  ["JIRA is an antipattern"](https://techcrunch.com/2018/12/09/jira-is-an-antipattern/)
  and ["Death to JIRA"](https://techcrunch.com/2016/12/11/death-to-jira/):
  tickets assume work is discrete and individually estimable, and devs
  end up architecting software to map to the tickets.
- **Estimates become bludgeons** — Ron Jeffries on story points
  ([regret essay](https://ronjeffries.com/articles/019-01ff/story-points/Index.html)).
- **Config becomes its own job** — a documented Jira→Linear migration:
  bug filing 48s → 11s, ~4 h/sprint of ceremony gone, satisfaction
  3.2 → 7.8/10
  ([cotera](https://cotera.co/articles/linear-vs-jira-comparison)).
  Counterpoint at scale: Swimm outgrew GitHub's minimal model and
  moved *to* heavier tooling
  ([swimm](https://swimm.io/blog/why-we-switched-from-github-issues-to-jira-to-clickup)).

## 4. Minimal mechanisms proven at scale

- **CPython:** two markers — `release-blocker` ("must be fixed before
  any release is made") and `deferred-blocker` (blocks the *next*
  release) — with one rule: "whether a bug is a release blocker is a
  decision better left to the release manager"
  ([devguide](https://devguide.python.org/triage/triaging/)).
- **Debian:** severity ≥ *important* makes a bug release-critical; the
  entire release status is one number — the
  [RC bug count](https://bugs.debian.org/release-critical/debian/all.html)
  trending to zero. Resolution: fix, downgrade, or drop the package.
- **Rust:** features ride trains — a slipped feature costs six weeks,
  not a negotiation
  ([stability post](https://blog.rust-lang.org/2014/10/30/Stability/)).
- **Linux:** merge window, then regressions-only stabilization; in/out
  is a calendar boundary plus one rule
  ([process docs](https://www.kernel.org/doc/html/latest/process/2.Process.html)).
- **Release checklist as one issue:** Rocq instantiates
  `release-process.md` as a fresh tracking issue per release
  ([rocq#18882](https://github.com/rocq-prover/rocq/issues/18882));
  blockers are whatever that issue links to.

Common shape: (a) releases are cut by time or one owner's judgment,
never by feature-list completion; (b) "in or out" is a one-bit
decision made per item at triage, not a continuously maintained
planning field; (c) the release view is a *query*, not a curated
document; (d) exactly one human owns the bit's semantics.

## 5. Convergent findings

1. The milestone concept is not the pandora's box — the minimal shape
   (named bucket, optional date, open/closed, single nullable field on
   the item, derived progress) is proven and liked. The box opens
   through four specific hinges: dated commitments, an unowned
   free-for-all field, versions that never leave the vocabulary, and
   an unbounded "later" pile that demands grooming.
2. Timebox and deliverable are different dimensions. Systems that
   overload one object with both (GitLab, pre-Projects GitHub)
   accumulate workarounds; systems that separate them (Linear, Plane)
   get praised. For "assign items to a release" only the deliverable
   axis is needed — the timebox axis is where sprint ceremony lives,
   and it can be skipped entirely.
3. One release per item is sufficient exactly when releases are not
   also sprints — the pressure for many-per-item comes only from the
   overload.
4. A "not now" bucket survives only if deletable-without-guilt or
   forcibly bounded/reviewed; every unreviewed holding area in the
   literature earned a "where X goes to die" epithet. The enabling
   belief, stated identically by Basecamp and thoughtbot: important
   things come back.
5. Nobody ties the milestone object to the release artifact well —
   GitHub's are disconnected, GitLab bolted the association on late.
   Closing a release with verifiable evidence is a gap most tools
   still have, and one hits' `fixed-by` pattern already knows how to
   fill.
