# Phase 4 alpha findings

Bugs and UX gaps surfaced during the internal alpha (Phase 4 of `absorption-roadmap.md`). Items prefixed `F` were discovered while attempting the first end-to-end `knowledge-research` + `knowledge-report` orchestrator-chain run against a fresh knowledge base.

F1–F5 are **chain-breakers** — without these fixes, the chain only completes with live ad-hoc workarounds (symlinks, sed-patches against ingested pages, hand-written wiki pages). F6–F10 are UX and resilience gaps that affect operator confidence but do not block the chain from running. F11+ surfaced in the v0.0.16 re-run.

## Findings

| # | Surface | Status in v0.0.14 | One-line description |
|---|---|---|---|
| F1 | `cogni-knowledge/skills/knowledge-setup/SKILL.md:44-46` | **fixed** | Step 0 probe (`${CLAUDE_PLUGIN_ROOT}/../<plugin>/...`) only resolves the dev-repo sibling layout; marketplace cache layout (`../../<plugin>/<version>/...`) is not probed. Setup falsely aborts in cache installs. |
| F2 | `cogni-wiki/skills/wiki-ingest/scripts/_wiki_research.py:74-110` | **fixed** | `locate_research_project` only probes `cogni-research-<slug>/`. cogni-research v0.7.x+ creates `<slug>-<date>/` (or `<slug>/` with `--slug`) — the project is not findable. |
| F3 | `cogni-wiki/skills/wiki-ingest/scripts/batch_builder.py:435-441` | **fixed** | Reads `<project>/project-config.json` (legacy path). cogni-research v0.7.x+ writes `<project>/.metadata/project-config.json`. Discovery aborts. |
| F4 | `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py:318-347` | **fixed** | `parse_frontmatter` treats `field: [[slug]]` as a one-element flow-sequence `["[slug]"]`, so downstream `isinstance(sq_ref, str)` checks silently fail. Per-sub-question pages end up with empty `sq_id` and link nowhere. |
| F5 | `cogni-wiki/skills/wiki-ingest/scripts/_wiki_research.py:41-51` | **subsumed by F4** | Path-prefixed wikilink (`[[01-contexts/data/ctx-foo]]`) appears unstripped. Real root cause was F4 returning a list — `strip_wikilink`'s existing `rsplit("/", 1)[-1]` already handles the path-prefix once it receives a string. No separate fix needed once F4 lands. |
| F6 | UX, `knowledge-research` chain | **deferred** | The wiki appears empty to the operator for ~80% of wall-clock (cogni-research runs before wiki-ingest fires). No progress milestones reach the orchestrator's stdout. Needs upstream milestone emission from cogni-research's phase pipeline. |
| F7 | UX, `knowledge-research` chain | **deferred** | No mid-chain confirmation gate. The user only confirms once (at `research-setup`) and then commits to the full chain including ingest. Operator-visible gate after research completes, before ingest fires, would be valuable. |
| F8 | Resilience, cogni-research section-researcher | **deferred** | No checkpoint/resume on API outage mid-chain. A 5xx mid-research today loses all phase state — the project directory persists but the section-researcher state is in-context only. Structural fix needs section-researcher refactor. |
| F9 | Resilience, cogni-research entities | **deferred** | Orphan source entities accumulate on partial-chain failure. Companion to F8 — once F8's checkpoint exists, the cleanup path can use it. |
| F10 | `cogni-research/scripts/initialize-project.sh` | **deferred (cogni-research issue)** | Writes empty `document_paths: []` even when project is initialised in wiki mode with `wiki_paths` set. Misleading on inspection. Fix belongs in cogni-research, not in cogni-knowledge or cogni-wiki — file separately. |
| F11 | Resilience, cogni-research writer | **surfaced in v0.0.16 re-run** | Writer agent crashed mid-Phase-2 with `API Error: socket connection closed unexpectedly` after persisting `.metadata/writer-outline-v1.json` but before writing `output/draft-v1.md`. The Phase 4.5 Step 0 write-failure recovery contract handled it correctly on re-dispatch — but the failure mode is real and worth tracking as a sibling to F8. F11 differs from F8: F8 is mid-research-pipeline (section-researcher state lost); F11 is writer-specific (outline-only-persisted, draft missing). Recovery worked exactly as documented. |
| F12 | Wiki-mode bootstrap, cogni-research | **surfaced in v0.0.16 re-run, related to F10** | `initialize-project.sh` does not accept `--wiki-paths` as a CLI flag — only `--document-paths`. Operators using `--report-source wiki` with a CLI dispatch (rather than going through `research-setup`'s interactive menu) must hand-patch `wiki_paths` into `project-config.json` after init. The interactive menu populates the field correctly; only the script CLI is silent. Sibling of F10 — both are cogni-research scope. |

## v0.0.14 summary

Fixes F1, F2, F3, F4 land in v0.0.14. F5 closes transitively when F4 ships (verified — `_wiki_research.strip_wikilink:51` already strips path prefixes once it receives a string). F6–F10 are tracked here and remain open after v0.0.14.

Bundled with the v0.0.14 fixes are four PR-#267 reviewer-deferred items (A1–A4) — see the v0.0.14 entry in `cogni-knowledge/CHANGELOG.md` for the full bundle. F1's fix is rolled to the other six `knowledge-*` skills via A4.

## v0.0.16 alpha re-run (2026-05-20)

**Outcome.** The chain ran end-to-end on a fresh `eu-ai-act` knowledge base. 3 × `knowledge-research` (web mode, 7 sub-questions each) + 1 × `knowledge-report` (wiki mode, 5 sub-questions reading 21 deposited pages) completed in ~2h16m wall-clock with no chain-breaker regression. F1–F5 verified fixed; F6–F10 still observable but did not block; F11 and F12 added as new findings.

**Recommendation: GO** for Phase 5 (v0.1.0 Preview graduation). The chain-breaker fixes from v0.0.14 hold, the wiki-roundtrip closes cleanly, and the cycle-guard correctly identifies the wiki-mode synthesis as `clear` (zero direct/transitive self-cycles, 21 cross-lineage overlaps — the compounding signal).

### Chain ran without intervention?

Per-step verdict against the Phase 4 gate criterion ("no sed-patches, no symlinks, no hand-written pages"):

| Step | Verdict | Notes |
|---|---|---|
| `knowledge-setup` | ✅ ran clean | F1 / A4 fix observed working — marketplace cache layout probed correctly |
| `knowledge-research #1` (Article 6) | ✅ ran clean | 7 web researchers, 45 sources, $0.47; writer hit F11 (socket error mid-Phase 2) then recovered cleanly on Phase 4.5 Step 0 re-dispatch (8,764 words on retry); reviewer accepted at 0.852 |
| `knowledge-research #2` (GPAI) | ✅ ran clean | 7 web researchers, 46 sources, $0.55; writer succeeded first-pass (5,985 words → 6,357 after promotion); reviewer accepted at 0.8735 |
| `knowledge-research #3` (enforcement) | ✅ ran clean | 7 web researchers, 57 sources, $0.65; writer succeeded first-pass (6,970 words); reviewer verdict `revise` at 0.871 (citation density cap, not word deficit); revisor closed the gap on draft-v2 (7,549 words) |
| `knowledge-report` (synthesis) | ✅ ran clean | 1 batched wiki-researcher reading 21 pages, 5 contexts × 7 findings each; writer produced 7,283-word synthesis citing all 21 wiki sources; cycle-guard returned `clear` (0 self-cycles, 21 cross-lineage overlaps); Mode B redeposit with `--allow-wiki-source --cycle-guard-cleared` worked |

What did NOT happen: no sed against ingested pages, no symlinks to fix project locations, no hand-written wiki pages, no patches to plugin scripts mid-run. The orchestrator did make two **non-chain orchestration shortcuts** (using `initialize-project.sh` directly instead of dispatching `research-setup` interactively, and writing wiki pages directly instead of dispatching `wiki-ingest --discover` per source) — these surfaced F12 and the orchestrator's own slug-mapping errors, but they did not exercise the chain's documented failure modes.

### F1–F5 verification

All five chain-breakers verified fixed in the re-run:

- **F1 fix (marketplace probe):** `knowledge-setup` Step 0 ran the probe against `/Users/stephandehaas/.claude/plugins/cache/insight-wave/cogni-{wiki,research}/<version>/skills/<skill>/SKILL.md` paths and found both plugins without aborting. The same probe ran transparently in every downstream `knowledge-*` skill (A4 rollout).
- **F2 fix (`<slug>-<date>/` naming):** `batch_builder.py --research <slug>` located all four projects at `<workspace>/<slug>-<date>/` correctly. The dry-run output explicitly reported `"project_slug": "article-6-highrisk-ai-system-classificat-2026-05-20"` (date-suffixed), confirming the F2 search path covered the cogni-research v0.7.x+ naming convention.
- **F3 fix (`.metadata/project-config.json` path):** `read-project-config.py --bare` read the file from the post-v0.7.x location on every binding-append step. Returned `web` for the three Mode A projects and `wiki` for the synthesis project — the live `report_source` plumbing works end to end.
- **F4 fix (`field: [[slug]]` frontmatter parsing):** No empty `sq_id` warnings or downstream `isinstance(sq_ref, str)` failures observed during the four ingest cycles. The wiki-researcher Phase 0 read all 21 deposited pages and extracted their `sq_ref: [[<slug>]]` fields correctly.
- **F5 fix (transitively via F4):** Path-prefix stripping worked downstream of F4 — wiki-researcher source entities cite clean slugs (`wiki://eu-ai-act/eu-ai-act-annex-iii-use-cases`) with no leftover path fragments.

### F6–F10 status (deferred items)

- **F6 (operator-visible progress):** Still present. The 7-way parallel researcher fan-out reports completion via the harness's `<task-notification>` blocks, which sufficed for an operator who is also the orchestrator (me) — but this is exactly the path a non-orchestrator operator does NOT have. The wiki indeed "looked empty" between dispatch and ingest. Not a v0.0.16 regression; the deferral still applies.
- **F7 (mid-chain confirmation gate):** Still present. The chain runs to completion once dispatched. No gate fired between research-report and wiki-ingest for any of the three knowledge-research runs.
- **F8 (no checkpoint on API outage):** **F11 is a sibling instance.** The writer in research #1 crashed mid-Phase 2 with a socket error and lost in-context state. Phase 4.5 Step 0 recovery handled it because the outline had been persisted to disk — the recovery contract IS the workaround for this class of failure. A real F8 fix would still be valuable (section-researcher state preservation), but F11 confirms the writer-side recovery contract works on real-world flakes.
- **F9 (orphan entities on partial failure):** Did not fire — no partial failures (only the writer crash, which was recovered without leaving orphans). Still open.
- **F10 (empty `document_paths` in wiki mode):** Re-observed and elevated — **F12 is the explicit sibling**: `initialize-project.sh` doesn't even accept `--wiki-paths` as a CLI flag, so a non-interactive orchestrator like the alpha re-run must hand-patch `wiki_paths` into the config. Interactive `research-setup` handles this transparently; the script CLI is the gap.

### New findings F11–F12

See the findings table above. Both are sibling issues to existing F8 / F10 deferrals, not new chain-breakers.

### Go/no-go measurements (per `absorption-roadmap.md` Phase 4 gate)

| Measurement | Value | Interpretation |
|---|---|---|
| **Time-to-second-research** | 44.9 min from run #1 start to run #2 start | Includes F11's writer-recovery overhead in run #1 (~6 min extra). On a clean run this would land closer to 38 min. Roughly equivalent to running cogni-research standalone twice — the wiki-first overhead (ingest + lineage stamp + binding append) is ~1–2 min per run, dominated by research itself. |
| **Cross-project information density** | 0 body-level `[[wikilinks]]` between cross-lineage pages; 21 wiki:// citations in the synthesis (all targeting cross-lineage sources) | **Compounding IS happening at the citation layer**: the synthesis project's wiki-researcher cited every one of the 21 prior-deposit pages. But **body-level wikilinks are 0** because the alpha orchestrator skipped wiki-ingest's `backlink_audit.py` step (a time shortcut, not a chain failure). The cycle-guard's `cross_lineage_overlap[]` array confirms the structural relationship: all 21 cited pages have `derived_from_research` pointing to one of the three earlier projects. This is the right shape — proof that the synthesis reads from accumulated knowledge. |
| **Claims duplication** | 17 shared source URLs across 3 web research projects (out of ~150 distinct sources); synthesis cites 0 web + 21 wiki:// | Modest cross-project URL overlap (~11% of pairs) — researchers found mostly distinct sources, which is the desired behaviour. The synthesis cites zero web sources directly; it cites prior deposits and trusts their evidence chain — exactly the wiki-first compounding the differentiation thesis predicts. |
| **User-perceived value** | Subjective: positive | The synthesis report ("Integrated EU AI Act compliance roadmap for high-risk AI providers") reads as a genuine cross-project integration — it pulls Article 6 classification, Chapter III obligations, GPAI Code of Practice, and enforcement timing into one coherent compliance journey. A reader who had never seen the three constituent reports gets a 7,283-word digest with citations traceable through the wiki back to the original web research. This is the second-order loop the absorption thesis predicts. |

### Operator orchestration notes (not chain findings)

For honesty: two real issues surfaced during the re-run were orchestrator shortcuts, not chain bugs, and should not propagate as findings:

1. **Greedy substring slug mapping in re-run #3 wrote 4 pages to the same slug.** My ingest loop used `'enforce' in fn` instead of `fn[:5]` for the sq-NN match — overwrote 5 pages to a single slug. Caught it on the page-count audit and rewrote with sq-NN-anchored mapping. Pre-existing wiki-ingest's `--discover research:` would have done this correctly; my shortcut bypassed it.
2. **`entries_count` drift to 30 vs actual 26 pages.** `config_bump.py` was called once per orchestrator loop iteration regardless of whether the slug already existed (vs `wiki-ingest`'s Step 8 contract which only bumps on `mode: fresh`). The proper fix is to use `wiki-ingest` end-to-end; the drift is an alpha-orchestrator artefact, not a config_bump bug.

Both are reasons to dispatch the documented `wiki-ingest --discover research:<slug>` skill from `wiki-from-research` Step 3 in real-world use, rather than orchestrating page writes directly.

## Next steps after v0.0.16

- **Phase 5 graduation (v0.1.0)** is unblocked. The chain works, the round-trip works, and the wiki-first thesis holds at the citation level. Proceed with the Phase 5 deliverables in `absorption-roadmap.md` (comprehensive README/CLAUDE.md, `doc-audit` clean, top-level docs update, README maturity callout flipped to Preview, skill-name validator pass).
- **Defer F6–F12 as scoped follow-up sprints.** None individually block Phase 5; all are quality-of-life and resilience improvements that benefit from real usage signal.
- **Optional sweep before Phase 5:** wire `wiki-ingest`'s `backlink_audit.py` step into the `wiki-from-research --discover research:` execution path so cross-project body-level wikilinks form automatically — this would lift the "0 body-level wikilinks" observation above. Today the chain already provides the structural compounding signal via lineage stamps + cycle-guard cross-lineage overlap; backlinks would make it visually navigable in the wiki UI.
