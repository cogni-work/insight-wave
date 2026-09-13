# Wiki-tree reconciliation — decisions record

insight-wave carries two copies of the same wiki. `wiki/` at the repository root is edited by
maintainers; `cogni-workspace/wiki/` is the vendored copy that ships inside the plugin so
marketplace users get it in their plugin cache on install. `scripts/release-bundle-wiki.sh`
copies the first over the second. This document records what was decided about every way the
two copies currently disagree.

This is a decisions record, not a delivery plan. Each decision below states what was decided,
the rule behind it, and the consequence of reversing it. Items marked *recorded, not executed*
are decided here and carried out elsewhere; the issue that carries them is named inline.

## On the figures in this document

Every count below is attributed to the command that produced it, measured against the ref named
beside it. Where a previously-quoted figure could not be reproduced, that is recorded plainly
rather than smoothed over.

The figures were re-measured when Decision 3 was executed. The table now carries the **post-
execution** state; the pre-execution values it replaces are kept in the paragraph below rather
than overwritten, because the difference between them is what Decision 3 actually did.

| Figure | Command | Value | Measured at |
|---|---|---|---|
| Substantive pending changes | `rsync -anci --delete wiki/ cogni-workspace/wiki/`, excluding attribute-only lines | 3 content + 7 delete + 1 add = **11** | Decision 3 execution branch |
| Raw pending changes | `bash scripts/release-bundle-wiki.sh --check` | `changes_pending: 167` on a fresh checkout | Decision 3 execution branch |
| Root page count | same command, `source_page_count` | `151` | Decision 3 execution branch |
| Bundled page count | `find cogni-workspace/wiki/wiki/pages -maxdepth 1 -name '*.md' \| wc -l` | `157` | Decision 3 execution branch |

**Read the substantive row, not the raw one.** The two rows disagree by 156 lines and neither is
wrong: `changes_pending` counts every `rsync` itemise line, and on a freshly-checked-out tree 152
`.f..t....` files plus 4 `.d..t....` directories are attribute-only mtime differences rather than
content. This is the same artefact class described below, and it is why the substantive figure is
quoted first and derived from the itemised command.

**The moving figures, in order.** The originating issue said 29. Measurement at `bab6a9cd` said
`128`, of which 100 lines were attribute-only. Measurement at `0698cb2c` said `28` with that class
empty. Measurement at `563098e0` — the base of the Decision 3 execution branch — said **21**
substantive lines (13 content + 7 delete + 1 add). None of those moves is a miscount; each is the
metric moving. The `28` → `21` step was not reconciliation work at all: it is the cogni-claims and
cogni-narrative/cogni-copywriting absorptions deleting pages out of both trees, which retired five
group-A entries outright and left two more already identical. Executing Decision 3 then took the
substantive figure from 21 to **11** by closing 10 of the 13 content deltas.

## Decision 1 — `entries_count` is corrected by hand, per tree

**Decision.** Set each tree's `.cogni-wiki/config.json` `entries_count` to that tree's own
measured page count. Root `179` → `170`; bundled `178` → `176`.

**Why.** The field had drifted in both trees, in both cases by omission rather than by error.
It was last set correctly by hand; three later commits deleted pages from one tree or the other
without updating either config.

| Tree | Config path | Recorded | Measured | Drift |
|---|---|---:|---:|---:|
| Root | `wiki/.cogni-wiki/config.json` | 179 | 170 | +9 overstated |
| Bundled | `cogni-workspace/wiki/.cogni-wiki/config.json` | 178 | 176 | +2 overstated |

**The two values stay different, and that is correct.** Each config describes its own tree, and
the trees hold different numbers of pages — since #1402 executed Decision 4, the remaining
difference is Decision 5's root-only lint page, not the seven held pages. A future reader
should not read `170 != 176` as fresh drift.

**Reversing it** restores a count that overstates both trees, which is the state that let three
page-deleting commits pass unnoticed.

## Decision 2 — the expected substantive residual is 4 lines, and every one is explained

**Decision.** After this reconciliation *and* the execution of Decision 3, the itemised
`rsync -anci --delete wiki/ cogni-workspace/wiki/` is expected to keep reporting **4 substantive
lines**, plus a checkout-dependent number of attribute-only lines that carry no meaning. That
residual is understood and intended. It was 11 until #1402 executed Decision 4: promoting the seven
bundled-only pages removed the whole `*deleting` class, which was 7 of the 11.

**Why.** Each surviving line belongs to a decision that deliberately keeps the two trees apart:

| Class | Lines | Why it survives |
|---|---:|---|
| `>f+++++++` | 1 | The dated lint page is root-only by design (Decision 5) |
| Content delta — `.cogni-wiki/config.json` | 1 | Each config describes its own tree; the values are *supposed* to differ (Decision 1) |
| Content delta — `wiki/log.md` | 1 | Frozen dated history, divergent on purpose (Decision 5) |
| Content delta — `wiki/index.md` | 1 | Merged, never copied: since #1402 both trees carry the seven promoted bullets, so the only surviving delta is the root's maintenance section (Decision 3, group C) |

Decision 3's execution closed the other 10 content deltas — the six live group-A pages and the
four group-B pages are now byte-identical across the trees. The wikilink change in Decision 6
lands identically on both sides, so it adds no line. The `entries_count` change in Decision 1
does not add a line either: the two configs already differed, and they still differ.

**Do not gate on `changes_pending`.** `bash scripts/release-bundle-wiki.sh --check` reported
`changes_pending: 167` on the execution branch, and 156 of those were attribute-only. The
substantive figure is the one to compare against, and it comes from the itemised command.

**Reversing it** means the next person to read a large `changes_pending` treats it as unexplained
drift and reaches for the sync script — the outcome Decision 3's rejected alternative exists to
prevent.

## Decision 3 — the content deltas resolve in two opposite directions

*Executed in issue #1401.* Six live group-A pages were copied root → bundle, four group-B pages
were back-ported bundle → root, and `wiki/index.md` was merged. The three structural files remain
divergent by design; see Decision 2's residual table.

**Rule.** Direction is decided per group, never by a blanket copy. The group-A files are newer at
the root; four are newer in the bundle; three are structural and take bespoke handling.

**Why.** The root copy is the editing surface, so the reflex is to treat it as correct
everywhere. For four pages that reflex would delete work. Commit `c44d52c3` appended
`## Steps` and `## Common pitfalls` sections — and a `## Two scenarios` section on one page —
directly to the *bundled* copies. Those sections have no root counterpart, so copying root over
bundle discards them.

### Group A — originally 13 files, 6 live at execution, root copy wins

Re-ingest commits enriched the root pages; the bundle was never re-synced afterwards and still
held the thinner generated stub. The six that were still divergent when Decision 3 executed were
copied root → bundle verbatim and are now byte-identical:

`agent-cogni-portfolio-proposition-generator.md`,
`agent-cogni-portfolio-proposition-quality-assessor.md`, `plugin-cogni-portfolio.md`,
`skill-cogni-portfolio-portfolio-verify.md`, `skill-cogni-portfolio-propositions.md`,
`skill-cogni-trends-trend-report.md`

The copy was verified non-destructive before it ran: on all six the root copy strictly enriched
the bundled one — added `related:` entries, added wikilinks, expanded summary lines, and on
`skill-cogni-portfolio-propositions.md` an 87-line rewrite over a 19-line stub — so no bundled
line was lost. Every wikilink the copies carry already resolved in the destination tree, which is
what kept parity cases W4 and W5 green.

**Already identical at execution — 2 entries.** `concept-claim-lifecycle.md` and
`concept-claims-propagation.md` were byte-identical in both trees by the time Decision 3 ran, so
nothing was copied for them. They were live group-A entries when this was recorded; the re-ingest
that closed them is the same class of movement the figures section describes.

**Resolved by deletion — 5 former entries.** `agent-cogni-claims-claim-verifier.md`,
`agent-cogni-claims-source-inspector.md`, `plugin-cogni-claims.md`,
`skill-cogni-claims-claim-entity.md` and `skill-cogni-claims-claims.md` were deleted from **both**
trees when cogni-claims was absorbed into cogni-workspace: `test-wiki-namespace-sync.sh` case C1
derives its roster from `marketplace.json`, so dropping the plugin entry took all five off-roster.
The root-wins direction above is moot for them — there is no copy left on either side to win.

They are recorded here rather than silently dropped because a reconciliation run that still
expected them would look for files that no longer exist, and the deletion is the *reason* the
enrichment asymmetry stopped mattering, not evidence the ledger was wrong. `concept-claim-lifecycle.md`
and `concept-claims-propagation.md` survive in both trees — they are claim *concepts*, not
namespaced plugin pages, so C1 never covered them. They were live Group A entries when this was
recorded and had converged to byte-identical by the time Decision 3 executed, as noted above.

**Resolved by deletion — 14 further entries per tree.** The same mechanism fired again when
cogni-narrative and cogni-copywriting were absorbed: `plugin-cogni-narrative.md`,
`plugin-cogni-copywriting.md`, the three `skill-cogni-narrative-*` and four
`skill-cogni-copywriting-*` pages, and the three `agent-cogni-narrative-*` and two
`agent-cogni-copywriting-*` pages went off-roster the moment both `plugins[]` entries were
removed, and were deleted from **both** trees in that same commit.

Two consequences worth stating, because neither is obvious from the page list and both turned a
suite red before they were handled:

- **Both trees' `entries_count` had to move with the page count** — 165 → 151 for the root tree and
  171 → 157 for the bundled one. `test-wiki-tree-parity.sh` cases W1 and W2 count live pages per
  tree, so a stale count reads as drift rather than as a deletion.
- **Six prose references across four pages pointed at the deleted plugin pages.**
  `ecosystem-overview.md`, `workflow-content-pipeline.md` and `workflow-portfolio-to-pitch.md` in
  both trees, plus `workflow-research-to-report.md` in the bundled tree only, linked
  `[[plugin-cogni-narrative]]` / `[[plugin-cogni-copywriting]]` in pipeline prose and in
  `related:` front-matter. They were rewritten to name the adopting plugin and the relocated skill
  rather than repointed link-for-link — "feeds cogni-workspace which feeds cogni-workspace" is not
  a sentence — and each tree's `index.md` lost its two roster bullets.

The dated ingest lines in each tree's `log.md` keep the retired names. They record what was ingested
on the date they name, which is the same treatment the cogni-claims re-ingest lines already had.

### Group B — 4 files, bundled copy wins

| Page | Root lines | Bundled lines | Sections only in the bundle |
|---|---:|---:|---|
| `workflow-portfolio-to-website.md` | 55 | 76 | Steps, Common pitfalls |
| `workflow-content-pipeline.md` | 50 | 79 | Steps, Common pitfalls |
| `workflow-portfolio-to-pitch.md` | 56 | 72 | Steps, Common pitfalls |
| `workflow-trends-to-solutions.md` | 52 | 79 | Two scenarios, Steps, Common pitfalls |

These were back-ported bundle → root *before* any sync ran, and are now maintained from the root
like everything else. Each was a pure insertion — the shared prefix was byte-identical on both
sides and `**Source**:` was the last line of both — so the back-port was a verbatim copy with zero
root-only lines to lose.

All four are now pinned to byte-identity by `PAGE_PARITY` in
`cogni-workspace/tests/test-layering-claim-reconciled.sh`, so the sections that once existed only
in the bundle cannot drift back out of the root tree unnoticed.

The seven Decision-4 pages promoted by #1402 are pinned by the same constant since #1843 —
`concept-canonical-workflow-ids`, `ecosystem-command-reference`, `ecosystem-plugin-selection`,
`workflow-consulting-engagement`, `workflow-docs-pipeline`, `workflow-full-onboarding` and
`workflow-research-to-report`. Promotion is what created the exposure: one copy per stem needs no
guard, two copies do. The list stands at 19 entries and L10's floor at 19 with them; the two move
together, per the note on the constant.

### Group C — 3 structural files

`wiki/index.md` — merged, not copied, and **still divergent after the merge, on purpose**. The
bundle's seven extra bullets were correct for the tree that then held those seven pages, so they
were not drift and were left in place; copying them into the root tree would have created seven
dangling references there and pre-decided Decision 4. That reason is now spent: #1402 promoted the
seven pages, so the root holds them too and its index carries the same seven bullets — added
alongside the pages, never ahead of them. The root's `### Maintenance` section stays root-only
for the same reason in reverse: it links `[[lint-2026-04-20]]`, a root-only page.

Measured at execution, the two copies differed on **four** description/intro lines, not the five
recorded here. Three resolved root-wins: the `### Skills` and `### Agents` preambles (the bundle
asserted "across all 11 plugins", which the marketplace roster contradicts — it registered
nine plugins when this reconciliation ran and registers eight today) and the
`skill-cogni-portfolio-propositions` bullet (the bundle still carried the terse stub, matching the
stub page group A replaced).

The fourth is the case this rule was written for — **neither side was right.** The root said the
website-setup skill discovers content from "cogni-portfolio, cogni-marketing, cogni-trends, and
cogni-research"; the bundle omitted the fourth source entirely. `cogni-research` has no directory
and is not on the marketplace roster, and the generating source
`cogni-website/skills/website-setup/SKILL.md` names `cogni-knowledge`. Both trees now carry that
corrected text. A blanket root-wins merge would have propagated a plugin name that does not exist;
a blanket bundle-wins merge would have dropped a real source.

Both `.cogni-wiki/config.json` files — closed by Decision 1.

`wiki/log.md` — frozen by Decision 5.

**Reversing it** and running a blanket sync destroys the group-B sections and cannot be
recovered from the bundled tree afterwards.

### Extension — the same rule applied to bare prose names

*Carried out in issue #1426.*

The pass above reached only references shaped as `[[wikilink]]`s or `related:` frontmatter — the
mechanically detectable set. A **bare** plugin name in prose carries no wrapper, so the wikilink
resolvers behind W4/W5 never saw that class and the suites stayed green with it fully present. The
same rule — name the adopting plugin and the relocated skill — now applies to bare prose too.

**The surface is the two-tree intersection of `wiki/wiki/pages/*.md`, non-recursive.** Measured at
the time of the sweep: 150 pages in the intersection, all 150 byte-identical; 25 of them carried a
bare retired name. Everything else is outside the surface **structurally, with no exclusion list**:

- `index.md`, `log.md` and `overview.md` fall out of **this** surface by **depth** — they sit at
  `wiki/wiki/` level. `index.md` and `overview.md` are covered instead by the separate per-tree
  tree-level arm ruled by Decision 7; `log.md` alone is outside every arm, by Decision 5.
- `lint-2026-04-20.md` falls out because it is the only **root-only** page (and Decision 5 freezes it).
- The 7 pages of Decision 4 *used to* fall out because they were **bundled-only** — the very
  property that decision was about. Since #1402 promoted them they sit in the intersection and are
  scanned by the two-tree arm, which is exactly the self-heal the next paragraph predicts.

A surface with no exclusion entries cannot be widened by accident, which matters here: the
substring-matching `is_excluded()` in `tests/test-layering-claim-reconciled.sh` turns one loose
fragment into a repo-wide exemption. It also self-heals — when #1402 rules, the held pages enter or
leave the surface with no guard edit.

**Adopters used.** `cogni-narrative` and `cogni-copywriting` → cogni-workspace, citing its
`narrative` and `copywriter` skills (`audit-copywriter` was deleted, not adopted, and is never cited
as live). `cogni-research` → cogni-knowledge. `cogni-consulting` → cogni-consult, **but not as a
rename**: several pages described the retired plugin's *phase-gated* architecture, which
cogni-consult does not have, so those were rewritten against the live model (action fields as WBS
containers, a per-deliverable design-thinking loop, `consult-project.json`) rather than
substituted. `cogni-wiki` had zero bare occurrences in the surface.

The pages Decision 4 held, promoted by #1402, follow that same adopter mapping: the sweep that
reconciled the intersection pages has since been applied to their bundled copies, so the two no
longer disagree about who owns narrative and copywriting. That confirmed the parenthetical above by
execution — `audit-copywriter` exists in neither `cogni-workspace/commands/` nor
`cogni-workspace/skills/`, so it was dropped on `ecosystem-command-reference` rather than carried
onto the adopter.

**Five claims were false, not merely stale**, and were corrected as content: cogni-knowledge ships
no `hooks/` (the four that do are cogni-consult, cogni-portfolio, cogni-visual, cogni-workspace);
the "no `scripts/`" census named plugins whose code now lives in cogni-workspace, which has one —
only cogni-marketing and cogni-website lack it; cogni-knowledge's entity vocabulary is not
SubQuestion/Context/Source/ReportClaim; the `portfolio_path` frontmatter edge had no cogni-consult
consumer at all; and the `canvas-{slug}.md` bridge row named a file no plugin emits — removed per
Decision 6 rather than repointed.

**`cogni-claims/` paths are preserved deliberately.** Per `cogni-workspace/CLAUDE.md`, the
discriminator is the colon: a `cogni-claims:` dispatch token is rewritten, a `cogni-claims/` path is
not. All 8 surviving occurrences in the surface (4 per tree) are paths. Two of them share a line
with a rewritten `cogni-research` token.

**`cogni-docs` and `cogni-service` are not retired** — they are live plugins hosted in a different
marketplace, already allowlisted as `EXTRA_ALLOWED` in `tests/test-wiki-namespace-sync.sh`. They are
out of scope here, and any future roster-derived scan needs that same allowance or it reports false
positives on them.

## Decision 4 — the 7 bundled-only pages, held pending a maintainer ruling and now promoted

*Executed in issue #1402.*

**Decision.** Originally: neither promote these pages into the root tree nor delete them from the
bundle, so the state stayed deliberate rather than forgotten.

**Ruling — given 2026-08-18.** The maintainer lifted the gate: *correct `ecosystem-command-reference`'s
three stale rows first, then promote all 7 pages into the root tree.* The order was part of the
ruling — promoting a stale page makes `cogni-workspace:ask` answer confidently and wrongly rather
than degrade gracefully. #1402 executed it: the seven pages were copied byte-for-byte into
`wiki/wiki/pages/`, their bullets added to the root `wiki/index.md`, and the root `entries_count`
re-derived. The bundle is unchanged — this was a promotion, not a move.

**After promotion.** Byte-for-byte held at #1402's base ref, not at its merge. The branch forked
before #1893 retired `narrative` and the `story-to-*` producers, and before #1897 and #1929 swept
the bundled copies again, so the root received the pre-retirement text of
`ecosystem-command-reference`, `ecosystem-plugin-selection`, `workflow-full-onboarding` and
`workflow-research-to-report` while the bundle had moved on; the conflict resolved at merge time
touched `entries_count` only. No arm compared the pairs, so the four drifted one-sided and
silently. #1843 re-synced them bundle → root — the bundle is the tree the retirement sweeps
maintained, so it wins — and pinned all seven under `PAGE_PARITY` (group B above), restoring the
identity this paragraph asserts and Decision 2's 4-line residual.

**Step 1 was already satisfied when the ruling was executed, so no row was edited.** By then
`ecosystem-command-reference` already named five of eight plugins as shipping no `commands/`
directory with cogni-workspace *not* among them, already listed cogni-workspace's slash commands,
and already placed `render-infographic-editorial` among the commands rather than the skills — the
settlement this section's own "What is held, and what is not" paragraph records. Verified at #1402's
base ref: the page's two tables name exactly the 12 `cogni-workspace/commands/*.md` and the 21
`cogni-workspace/skills/*/SKILL.md` present there, matching in both directions. "Three table rows,
not a rewrite" was therefore satisfied by **zero** row edits.

**What is held, and what is not.** Their **content** is a separate matter from the ruling,
and it has since been swept: four of them carried bare names of plugins retired after this record
was written, and leaving those in place would have meant promotion could only ever land red. The
sweep touches the bundled copies only, so it decides nothing about promotion.

| Page | Named entities resolved | Verdict | Outcome (#1402) |
|---|---|---|---|
| `concept-canonical-workflow-ids` | none asserted | current | promoted |
| `ecosystem-plugin-selection` | 12/12 resolve | current | promoted |
| `workflow-consulting-engagement` | 8 resolve, 1 self-documented removal | current | promoted |
| `workflow-docs-pipeline` | 9 resolve, all in another marketplace | current | promoted |
| `workflow-full-onboarding` | 5/5 resolve | current | promoted |
| `workflow-research-to-report` | 7/7 resolve | current | promoted |
| `ecosystem-command-reference` | 18 resolve, previously 1 mislabelled + 2 stale, now settled | current | promoted as-is, no row edited |

**Why the ruling was reserved.** Accepting a page into the root tree is what puts it in the grounded
answer set — the pages `wiki/index.md` catalogues and Claude reads directly when answering.
Promoting a stale page therefore does not degrade gracefully — it makes the assistant answer
confidently and wrongly, which is worse than the dangling reference it would have fixed.

**The page that was stale, and how it was settled.** `ecosystem-command-reference` stated that
cogni-workspace ships no commands directory, listed 9 of its then-11 skills, and counted
`render-infographic-editorial` as a skill when it is a command. The first two were the cogni-help
retirement seam: `troubleshoot` and `cogni-issues` moved into cogni-workspace and the page predated
the move. All three are now fixed, and both lists are rebuilt from the live tree — 13 commands and 26
skills, an arithmetic the sweep re-derives rather than trusts.
The row above therefore reads `current`, and promotion no longer carries a stale-page cost.

**Reversing it** — promoting all seven without the ruling — ships seven unruled pages into the
grounded answer set.

## Decision 5 — dated records are history and are never rewritten

**Rule.** A dated snapshot records what was true on its date. Editing it is not reconciliation.

This extends an exemption the repository already recorded for `lint-2026-04-20.md`, and applies
it to the other dated record carrying the same figure.

| Path | Content | Treatment |
|---|---|---|
| `wiki/wiki/pages/lint-2026-04-20.md` | quotes a roster count true on its date | byte-identical, both trees |
| `wiki/wiki/log.md` | ingest entries quoting the same count | byte-identical, both trees |

The two trees' `log.md` copies additionally record two genuinely separate cleanup events on
different dates. That is divergent history, not staleness, and merging them would fabricate a
record of something that did not happen.

**Consequence for grading.** The requirement that no document assert a roster count disagreeing
with the marketplace manifest applies to current-state documents only. A change that "corrects"
a count inside a dated record violates this decision rather than satisfying that requirement.

## Decision 6 — the two unresolved references are removed from both copies, and restored on promotion

*Executed in issue #1402 — see **On promotion.** below.*

**Decision.** `workflow-install-to-infographic.md` line 60 listed six follow-on workflows, two
of which named pages absent from the root tree. Both were removed, identically, from both copies.

**Why not the other direction.** The obvious fix was to make the two pages exist at the root —
but those were two of the seven pages Decision 4 then held, so taking that route would have
decided Decision 4 as a side effect. Removing the two references decided nothing and left four
valid options in the sentence.

**Why both copies.** This page is one of eight pinned to byte-identity between the trees by
`cogni-workspace/tests/test-layering-claim-reconciled.sh`. A one-sided edit turns that suite red.

**On promotion.** If Decision 4 resolved toward promoting, both references were to be restored
— in both copies — as part of that work. Issue #1402 carried this and **has done it**: Decision 4
was ruled promote, so line 60 lists six follow-on workflows again, restored to its exact
pre-removal wording in both copies, which stay byte-identical.

## Decision 7 — the tree-level pages are ruled by removal, and guarded per tree

**Decision.** In `wiki/wiki/index.md` and `wiki/wiki/overview.md` of **both** trees, an entry
naming a page or a plugin that no longer exists is **removed**, following Decision 6's precedent —
never rewritten onto the adopting plugin. These two files are catalogues, so a rewritten entry
fabricates a pointer to a page that does not exist, trading a dead name for a dangling link that
reds the parity suite. The Extension rule above still governs a live **prose sentence** on those
pages: there, name the adopting plugin and the relocated skill. Both halves are stated so the next
retirement is decidable without re-litigating this.

**State at execution — no tree-level wiki file was edited by this decision.** The class was already
cleared: the retired-plugin catalogue subsections went with the page deletions recorded in
Decision 3, group A, where each tree's `index.md` lost its two roster bullets. This entry records
and guards; it does not sweep. Every figure below was produced by running the command beside it on
the branch that added this section, per `## On the figures in this document`.

| Figure | Command | Value | Measured at |
|---|---|---|---|
| `cogni-…` tokens across both `index.md` copies, all on-roster | `grep -ohE 'cogni-[a-z0-9-]+[/:]?' wiki/wiki/index.md cogni-workspace/wiki/wiki/index.md \| wc -l` | 318 | this branch |
| The two `overview.md` copies are byte-identical | `diff wiki/wiki/overview.md cogni-workspace/wiki/wiki/overview.md` | no output | this branch |
| The preserved `index.md` divergence | `wc -l wiki/wiki/index.md cogni-workspace/wiki/wiki/index.md` | 221 root, 224 bundled | this branch |
| Bare-name guard, both surfaces | `bash cogni-workspace/tests/test-wiki-bare-name-roster.sh` | exit 0, 23 cases | this branch |
| Tree-parity guard | `bash cogni-workspace/tests/test-wiki-tree-parity.sh` | exit 0, 12 cases | this branch |

**Why the guard arm is per tree, not an intersection.** The two `index.md` copies diverge **by
design** (Decision 3, group C: the root keeps its Maintenance section, the bundle keeps its
Decision-4 bullets). An intersection-shaped arm compares the trees to each other, so it would skip
exactly the pair this arm exists to watch. `scan_tree_level` therefore takes no `shared` argument
and is called once per tree — each copy is graded against the runtime roster on its own terms, and
neither is ever compared to the other. Two red cases, one per tree, keep both arms independently
falsifiable.

**Why the surface is an explicit set, not a directory scan.** Decision 5 freezes both `log.md`
copies, whose dated ingest lines name plugins retired since they were written. Scanning
`wiki/wiki/*.md` would therefore be red on arrival, and the reflexive repair is a `log.md`
exclusion — the substring-matched exemption this suite deliberately carries none of, where one
loose fragment becomes a repo-wide hole. The arm instead reads a two-name **allowlist**,
`{index.md, overview.md}`, which is why widening the guard cost the suite no exclusion entry.

**The wikilink class is closed elsewhere, not carried.** `cogni-workspace/tests/test-wiki-tree-parity.sh`
scans each tree's top-level `index.md` as a link **source**, so a catalogue entry pointing at a
deleted page reds that suite today. No follow-up is owed for it.

**Reversing it.** Leaving these two files outside every content guard restores the state this
decision closes: the intersection arm reports clean while a catalogue in either tree names a plugin
that no longer ships, with nothing anywhere reporting it.

## Rejected alternative — run the sync script and accept the deletions

Rejected on three grounds:

1. It deletes the seven pages of Decision 4 — at the time, converting a held decision into an
   executed one with no ruling; #1402 has since ruled and promoted them, so a delete would now
   contradict the ruling rather than pre-empt it.
2. It overwrites the four group-B pages with shorter root copies, destroying content that
   exists nowhere else.
3. Its post-sync check compares page *counts*, so it cannot detect the second failure at all —
   the counts still match after the content is gone.

The script's own header states the root tree is the editing surface, so the deletion is
intentional in principle. What was missing was any refusal when the bundle holds something the
sync is about to destroy.

The script now carries that refusal. It classifies the bundled tree *before* writing any bytes
and exits non-zero, naming every path it would have destroyed, in two classes: a bundled file
with no source counterpart (ground 1), and a bundled file carrying non-blank lines the source
copy lacks (ground 2 — the class the count-based check of ground 3 structurally cannot see,
since an overwrite leaves the file count unchanged). Taking this rejected alternative therefore
now requires passing `--force` explicitly, which makes converting a held decision into an
executed one a deliberate act rather than an accident.

Ground 3 still describes the post-sync check accurately. That check is left in place, and it is
the new pre-sync gate rather than any change to it that supplies the defence.

On the tree as originally recorded here a bare sync refused on 27 paths: the 7 of Decision 4, the
4 group-B pages, and — because the root re-ingest reworded lines rather than only appending — the
13 group-A pages together with `wiki/index.md`, `wiki/log.md` and `.cogni-wiki/config.json`.

Once Decision 3 executed, that inventory narrowed to **10**: the 7 of Decision 4, plus
`wiki/index.md`, `wiki/log.md` and `.cogni-wiki/config.json`. The group-A and group-B pages no
longer appear, because they are now byte-identical across the trees and a sync has nothing to
change on them. The gate is deliberately blind to Decision 3's ruling that root wins for group A: a
script cannot read this document, so it refuses and defers to the operator. Decision 4 was the
only decision standing between a bare sync and silence; #1402 has since executed it, so the
seven pages no longer appear in that inventory and the refusal now rests on the remaining
by-design divergences.

## Rejected alternative — regenerate `entries_count` with the wiki linter

The repository does contain a writer for this field, reached through the wiki linter's
drift fix. It does not apply here. That tool enumerates pages by walking a fixed set of
per-type subdirectories, and this wiki stores every page in one flat directory that is not in
that set — pointed at either tree it would count zero pages rather than 170 or 176, and write
that. The field is informational for this wiki, no test asserts on it, no schema documents it,
and the sync script never reads it. Setting it by hand matches how it was last set correctly.

## Known remaining contradictions

Kept as a permanent inventory so the set stays auditable rather than being rediscovered.

| Item | State | Carried by |
|---|---|---|
| Group-A pages thinner in the bundle | closed — the 6 still divergent were copied root → bundle; 5 had been deleted from both trees and 2 had already converged | #1401 |
| 4 group-B pages missing sections at the root | closed — back-ported bundle → root and pinned by `PAGE_PARITY` | #1401 |
| `wiki/index.md` needs a merge, not a copy | closed — merged per the group-C rule; the two copies still differ by design | #1401 |
| 7 bundled-only pages held | closed — the maintainer ruled promote on 2026-08-18 and all seven were promoted into the root tree | #1402 |
| `ecosystem-command-reference` names a retired command surface | closed — the three rows were already corrected by the time the ruling was executed, so the page was promoted as it stood | #1402 |
| Sync script destroys bundle-only content | closed — refuses by default; `--force` is the opt-in | #1403 |
| This record and its guard are unregistered in the plugin guide | closed — `cogni-workspace/CLAUDE.md` names both under `## Wiki Trees` | #1404 |
| Bare prose plugin names are invisible to every resolver | closed — swept over the two-tree `pages/*.md` intersection and pinned by `tests/test-wiki-bare-name-roster.sh`, a runtime-roster-derived body scan with one arm per tree | #1426, guard in #1438 |
| The 5 bundled-only pages still name retired plugins | held with the pages themselves — editing them would pre-decide the ruling | #1402, sweep in #1440 |
| `index.md` and `overview.md` carry the same bare-name class | closed — verified clean at this branch's base, and the removal landed with the Decision 3 group-A page deletions rather than with the work that closed this row. The remove-not-rewrite ruling is now Decision 7, and both files are pinned per tree by the tree-level arm of `tests/test-wiki-bare-name-roster.sh` | #1439 |
| The `docs/` ER diagram repeats the dead `portfolio_path` edge | closed — the one falsified cell now names the live consumers. The "generated mirror" framing this row previously carried was itself wrong: `docs/architecture/er-diagram.md` is hand-maintained, not cogni-docs output — that plugin's document-type routing table covers only `design-philosophy` and `plugin-anatomy` under `architecture/`, it ships no ER-diagram template, its own structure reference lists the file as an input rather than an output, its audit checks only that the file exists, and it contains zero `portfolio_path` occurrences. So no upstream filing is owed and no regeneration can revert the cell. No guard added — see the guard-decision note below | #1441 |
| `consulting-project.json` occurrences name a manifest no plugin writes | closed — the real set was six hits over four files, not two. Both `concept-slug-based-lookups.md` copies were rewritten onto a live `consult-project.json` → `plugin_refs.knowledge_base` slug and pinned by `PAGE_PARITY`; `troubleshoot/known-issues.md` and the `SKILL.md` §5 probe moved from a dead rename to archive-not-rename. The two `docs/contributing/cogni-consult-evaluation.md` hits are accurate cogni-consulting history — a comparison-table cell and a dated run record — so they stand, and are not residues to re-file | #1442 |
| The 7 promoted pairs were unguarded after promotion | closed — four had already drifted one-sided (the root held the pre-retirement text, see Decision 4 "After promotion"); re-synced bundle → root and all seven pinned by `PAGE_PARITY`, floor raised to 19 | #1843 |

### Guard decision for the `docs/` ER diagram

**No guard, because** the two forms available both cost more than they are worth here.

A roster-derived scan of `docs/` prose for names absent from `.claude-plugin/marketplace.json` is
red on arrival. It would flag the deliberate past-tense history in `docs/audit-report.md`,
`docs/relicensing/vendored-license-audit.md`, `docs/contributing/cogni-consult-evaluation.md`,
`docs/plugin-guide/cogni-consult.md` and `docs/workflows/consulting-engagement.md`, the four
"the archived cogni-consulting" sentences inside the corrected files themselves, and the
`cogni-claims/` directory paths, which are a data location and never a plugin. Its only green
state is one reached by deleting correct prose. It could not have caught this defect in any case:
the falsified cell named cogni-consult, a live roster plugin, so the fault was a wrong consumer
rather than a retired name, and no roster comparison sees it.

The narrower form — pinning the corrected cell as a forbidden literal — is satisfiable locally,
since `docs/` sits inside the sweep `test-layering-claim-reconciled.sh` already performs. It is
declined because the failure mode it would guard against does not exist. That pin earns its cost
only if something can silently rewrite the cell back, and nothing can: this file is not cogni-docs
output. Four checks against that plugin agree — its document-type routing table emits only
`design-philosophy` and `plugin-anatomy` under `architecture/`, it defines no ER-diagram template,
its structure reference names `er-diagram.md` an existing relocated file and lists it as a content
source for other documents, and its audit asserts only that the path exists, never what it says.
It also holds zero `portfolio_path` occurrences, so it could not emit this cell even by accident.
Secondarily, grafting the literal onto that suite would put an unrelated pin inside cases scoped
end to end to the retired layering claim, and a separate suite for one string is not worth its own
file.

**Revisit trigger:** if cogni-docs ever adds an `er-diagram` entry to its document-type routing
table, this file becomes generated output and the guard question reopens on the terms above.

## Observed, out of scope here

Four current-state documents asserted an `11-plugin` roster, not the two this section first named.
The original pair cited one copy of each page and not its twin — the bundled
`ecosystem-overview.md:13` and the root `index.md:9` — leaving the root `ecosystem-overview` copy
and the bundled `index.md` copy unrecorded. None of the four was corrected by this record's own
sweep, for the reasons given at the time: `ecosystem-overview` sits in the two-tree intersection,
so a one-sided edit would break the byte-identity Decision 3 records across the shared pages, and
`index.md` is a tree-level page whose root twin lay outside this record's editable surface.

The class is now closed. All four sites were re-derived to `8-plugin` against
`.claude-plugin/marketplace.json` in one change that edits both trees symmetrically, so the
`ecosystem-overview` pair stays byte-identical and the substantive residual stays at the count
Decision 2 records (11 at the time of that sweep; 4 since #1402 executed Decision 4). The two
`index.md` copies are edited on both sides and still differ from each other, so
Decision 3's group-C divergence is preserved. The statement in the next section that no
tree-level file is edited describes this record's own sweep, not every later change.

## Deliberately left standing

The two `log.md` copies and `lint-2026-04-20.md` are untouched, per Decision 5 — a future reader
should not read them as misses. The two `entries_count` values remain different from each other,
per Decision 1. The substantive residual remains 4 lines, per Decision 2 — and the two
`wiki/index.md` copies remain different from each other, per Decision 3's group-C rule. The
seven bundled-only pages are no longer
held: #1402 executed Decision 4's ruling and promoted all seven into the root tree, so they now
exist in both. Their **content** had been swept earlier, which that decision's own section
records. None of the four
tree-level wiki files — `index.md` and `overview.md` in either tree — is edited either, per
Decision 7: they were already clean when that decision was recorded, so the absence of edits there
is the expected outcome and not a miss.

`troubleshoot/SKILL.md` §5's stale-state probe and `troubleshoot/references/known-issues.md`'s
`Leftover engagement file from a retired consulting plugin` entry both still name
`consulting-project.json`, deliberately. Neither is a residue: they are detection surfaces, where
the dead name is the thing being searched for on a user's disk and the thing a reader matches their
own situation against. Stripping it would leave `/troubleshoot` unable to find or describe the very
artefact the sweep was about — a documentation fix traded for a functional regression. This is the
same exemption the neighbouring `Leftover course-progress file` entry already relies on, naming its
two retired `.claude/*.local.md` files verbatim in both its Symptom line and its `rm -f` remedy. A
literal zero-hit bar over `cogni-workspace/skills/` is therefore unmeetable by construction, and a
future sweep should not re-file either occurrence.

> **Superseded in part (2026-09-02):** the two detection surfaces this paragraph names moved when `troubleshoot` was folded into `workspace-status` (#1644). The `Leftover engagement file from a retired consulting plugin` entry now lives in `cogni-workspace/skills/workspace-status/references/known-issues.md`; the stale-state probe is now summarised as row `7e Stale state from retirements` under `### 7. Plugin-Level Diagnostics` in `cogni-workspace/skills/workspace-status/SKILL.md` and is detailed in `cogni-workspace/skills/workspace-status/references/plugin-diagnostics.md`. `/troubleshoot` itself survives as a command, `cogni-workspace/commands/troubleshoot.md`, which dispatches into `workspace-status`. Both live addresses that discuss the artefact — `known-issues.md` and `plugin-diagnostics.md` — still name `consulting-project.json` verbatim (the `7e` row is the summary entry that routes to that probe, not a site that names the artefact), so the argument above holds unchanged at the new addresses: neither occurrence is a residue, and a future sweep should not re-file either one. The paragraph is kept byte-identical as a record of what was decided — the bare relative paths inside it are the addresses as they stood on that date and are deliberately not repointed, per `## Decision 5 — dated records are history and are never rewritten`. The mention of these same two detection surfaces in the `#1442` row under `## Known remaining contradictions` is covered by this note and is likewise left unchanged.

## What guards this

`cogni-workspace/tests/test-wiki-tree-parity.sh` asserts, per tree and never tree-wide: that
each `.cogni-wiki/config.json` `entries_count` equals a live count of that same tree's pages;
that every wiki reference in a tree resolves to a page in that same tree; and that every page
present in only one tree is named in this document. The last of those is what makes adding or
promoting a page without recording a decision here fail rather than pass silently. It does not
assert the two trees are equal — they are not, by Decisions 1, 4 and 5.

`tests/test_release_bundle_wiki.sh` guards the other direction: that
`scripts/release-bundle-wiki.sh` refuses, by default, to destroy what this document holds. It
covers both refused classes, the `--force` opt-in, and — as the case that matters most for the
gate staying usable — that a bundle which loses nothing still syncs without `--force`. It runs
entirely against `mktemp` fixtures, never these two trees, because a bare sync against them is
the data loss the gate exists to prevent.

`cogni-workspace/tests/test-wiki-bare-name-roster.sh` closes the prose gap the two guards above leave
open. It asserts that no `cogni-…` token in the body of a page present in both trees names something
absent from the live roster, with the allowed set read at runtime from `plugins[].name` rather than
written down — so the next retirement is caught without anyone remembering to edit the suite. Its
declared surface has two parts, and every page outside both is excluded by construction rather than
by a list: the two-tree basename intersection of the page directories, where the one-sided pages
fall out by symmetric difference; and a per-tree arm over the explicit `{index.md, overview.md}`
tree-level set, ruled by Decision 7 and carrying its own named liveness floor. Only `log.md` is now
outside both, by Decision 5. That distinction is what keeps the suite honest here: editing a page
merely to satisfy a guard would have pre-decided the ruling Decision 4 held open, and still
would pre-decide Decision 5's. The bundled-only
pages were swept on their own merits, and a promotion probe scanned them against the live roster —
so a residue would have redded before promotion landed rather than after. That probe **derives** the
bundled-only set as the complement of the intersection it cannot reach, rather than naming pages — a
literal list would go stale one page at a time, and the arm's floor only fires when every named page
vanishes, so the narrowing would be silent. Since #1402 promoted all seven, that derived set is
empty and the probe is dormant by construction: its call site answers the empty case directly rather
than handing the floor a set it would correctly refuse, and the pages it used to reach are now
scanned by the intersection arm. Five allowances are declared, each
keyed to an exact token rather than a substring: plugins hosted in a different marketplace, the
GitHub org token, the preserved `cogni-claims/` store path whose dispatch form is still caught, one
frozen past-tense historical sentence (keyed to the token *plus* containment of the whole sentence,
so the same name in a live framing still flags), and the skill names of live-roster plugins
(derived at runtime from their skill directories, never written down, so a skill that stops
shipping stops being blessed). That last one exists because the matcher cannot span a colon:
`cogni-workspace:cogni-issues` tokenizes as a clean `cogni-workspace:` and then a bare
`cogni-issues`, so writing the qualified form rescues nothing and the alternative would have been
rewriting correct prose to satisfy a scanner. Each carries both halves
of its case, so an allowance cannot quietly widen into an escape hatch. Two per-arm liveness floors —
one on shared pages scanned, one on roster size — make a half-dead arm fail with a named error
instead of reporting clean, which is the failure mode a guard over an already-clean surface is
otherwise blind to.
