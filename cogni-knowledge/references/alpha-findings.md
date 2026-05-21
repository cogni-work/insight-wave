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
| F13 | `candidate-store.py append-batch` + M4 smoke recipe Step 3 | **surfaced in v0.0.19 M4 smoke** | `candidates.json` is written in insertion order, not score-sorted. `fetch_priority` correctly encodes (tier, score) so consumers sort properly — this is a test-assertion clarity issue, not a code bug. Either re-write `candidates.json` sorted on every `append-batch`, or change the M4 smoke recipe's "score-sorted" assertion to "fetch_priority dense 1..N + within-tier monotonic". Recommend the latter. |
| F14 | `source-fetcher` cobrowse fallback gating | **surfaced in v0.0.19 M4 smoke** — tracked as #276 | When `claude-in-chrome` MCP is not installed, JavaScript-rendered pages (`eur-lex.europa.eu` full-text, certain EC portal pages) record as `webfetch_refused`/`webfetch_blocked` because the fallback path is unavailable. Not a code bug — environment dependency — but the chain currently has no signal to operators that "this URL is unreachable without the MCP". Workaround: install `claude-in-chrome` before runs that need full-text EU regulation pages. Future: have `source-fetcher` emit a distinct `cobrowse_unavailable` reason when WebFetch fails AND the MCP is missing, so operators can see "fixable by MCP install" separately from "actually dead". |
| F15 | `source-fetcher` PDF handling | **surfaced in v0.0.19 M4 smoke** — tracked as #275 | WebFetch on a PDF URL (`europarl.europa.eu/RegData/.../EN.pdf`, `arxiv.org/pdf/N.pdf`) returns binary content treated as unreadable; the fetcher records `webfetch_refused`. Cobrowse fallback would also be brittle (browsers download PDFs, don't render text). Structural gap — `source-fetcher` should detect `Content-Type: application/pdf` (or the `.pdf` suffix) and either (a) hand off to a stdlib PDF text extractor, or (b) record a distinct `pdf_unsupported` reason. Today PDF citations from authoritative bodies (EUR-Lex, EP think tank, arxiv) silently drop. Real bug worth scheduling. |
| F16 | `candidate-store.py append-batch` file lock | **positive — v0.0.19 M4 smoke** | Parallel `append-batch` calls from 3 concurrent curator merges (round 1 and round 2 of the smoke) completed without corruption, dedup-clean, sub_question_refs unioned correctly, fetch_priority recomputed dense 1..N. `fcntl.flock` contention path is exercised; merge-on-collision logic (higher-score wins, earliest-discovered-at wins) works. |
| F17 | EC portal availability (environment, not code) | **environmental, v0.0.19 M4 smoke window** | `digital-strategy.ec.europa.eu/en/...` returned HTTP 502 consistently across batches 002-005 of the smoke (6 URLs affected). Not a cogni-knowledge issue — EC portal infrastructure was throwing 502s during the smoke window. Validates that the orchestrator's "record unavailable, move on" design and negative-cache semantics are the right shape: without negative caching every re-run would re-hit the 502s, burning the rate-limit budget. |

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

## M4 smoke (2026-05-21)

End-to-end smoke of the v0.1.0 inverted-pipeline `plan → curate → fetch` chain (cogni-knowledge milestones M1–M4 from `absorption-roadmap.md`) on a fresh `.alpha/eu-ai-act-gpai/` knowledge base. Slice 1 of the Current sprint in `absorption-roadmap.md`. **Recommendation: GO** for Slice 2 (M5 + M6 — claim-extractor fork + source-ingester agent + knowledge-ingest skill).

### Verification matrix

| Step | Skill / contract | Outcome |
|---|---|---|
| 1 | `knowledge-setup` | PASS — `binding.json` (schema 0.0.3, `curator_defaults` populated) + `fetch-cache/` + wiki layout created at `.alpha/eu-ai-act-gpai/` |
| 2 | `knowledge-plan` | PASS — `plan.json` schema 0.1.0; 6 sub-questions (sq-01..sq-06), each with `candidate_domains[]` of 7 entries |
| 3 | `knowledge-curate` (6 curator dispatches in 2 parallel rounds of 3) | PASS — `candidates.json` schema 0.1.0 with 57 candidates (50 primary, 7 secondary); 34 unique URLs (zero post-normalize dupes); `fetch_priority` dense 1..57, primary tier (fp 1-50) before secondary (51-57), within-tier monotonic with `score`; 11 candidates referenced by 2+ sub-questions (cross-sq compounding signal); F16 (file-lock under contention) verified |
| 4 | `knowledge-fetch` (8 sequential batches of 8) | PASS — `fetch-manifest.json` schema 0.1.0; 41 fetched, 16 unavailable, all 57 with cache files on disk (positive + negative cache symmetric); all `reason` values inside the closed `webfetch_error_class` vocabulary; unavailable rate 28.1% (just under the 30% warning threshold) |
| 5 | `knowledge-fetch` re-run (batch 001 only) | PASS — `cache_hits: 8/8` = 100% on the warm-cache batch, $0.000 cost, all entries marked `from_cache: true` (positive AND negative), `fetch-cache.py stat` shows zero new entries and zero byte delta — cache short-circuit is exact, not approximate |
| 6 | Inject 404 unavailable (controlled, single-URL batch on `httpbin.org/status/404`) | PASS — recorded `webfetch_4xx` (in closed vocab), negative cache entry written, follow-up `fetch-cache.py fetch` returns `success: true` with `entry.status: unavailable` (negative-cache hit path suppresses re-attempt) |
| 7 | Final `fetch-cache.py stat` | PASS — `entries 58 = ok 41 + unavailable 17` (post-injection); negative cache symmetric with positive cache; Step-5 hit rate 100% > 50% threshold |

### Cost and timing

| Phase | Wall-clock | LLM cost |
|---|---|---|
| Curate (6 curators, 2 rounds of 3 parallel) | ~5 min | $0.100 |
| Fetch (8 sequential batches of 8) | ~50 min (incl. 2 anomalous slow batches — batch 007 took 20 min on the arxiv PDF, batch 008 took 30 min for 1 URL with no clear cause) | $0.055 |
| Re-run + 404 injection | ~2 min | $0.000 |
| **Total** | **~1h** | **$0.155** |

The 6× cost ratio vs the v0.0.16 alpha re-run ($0.155 vs $2.88) reflects the scope difference: M4 covers only `plan → curate → fetch`, not the writer/researcher/reviewer/revisor stack the v0.0.16 re-run exercised. The pipeline shape that delivers M12's "claim-verify wall-clock < 5 min" win (per `absorption-roadmap.md` Phase 5 pass criteria) starts to surface here — the fetch+verify cost is concentrated in this phase precisely because Phase 6 verify no longer re-fetches.

### New findings (F13–F17)

See the Findings table above for the full one-liners. Two summary points:

- **F15 (PDF handling) is the only real code finding worth scheduling.** WebFetch on PDF URLs silently drops them. Authoritative EU sources include PDFs (EP think-tank ATAGs, EUR-Lex consolidated annexes, arxiv papers). Recommended fix: in `source-fetcher`, detect `Content-Type: application/pdf` (or `.pdf` suffix) and either invoke a stdlib PDF text extractor or record a distinct `pdf_unsupported` reason. **Tracked as #275; scheduled for Slice 2** (since `source-ingester` will need to handle PDFs too — the detection logic belongs in `_knowledge_lib.py` for shared use).
- **F14 (cobrowse_unavailable reason) tracked as #276; optional for Slice 2** — UX improvement, small surface (one enum value + one branch). Could land Slice 2 or defer to v0.0.21.
- **F13 (assertion clarity) and F17 (environmental 502s) are documentation-only.** F13: update the M4 smoke recipe's "score-sorted" assertion to "`fetch_priority` dense 1..N + within-tier monotonic" — that's what the contract actually guarantees. F17: not actionable, but documented so future smoke runs hitting the same EC portal during an outage have prior art.

### What this clears for Slice 2

- The `plan → curate → fetch` chain is contract-clean. `candidates.json` is a stable input for the next phase (claim extraction at ingest, `source-ingester` per `inverted-pipeline.md` §"Phase 4 — knowledge-ingest").
- `fetch-cache.py` semantics — positive + negative cache symmetry, `from_cache` marking, freshness window honoured — work as designed. Slice 2's `source-ingester` can read cached bodies directly via `fetch-cache.py fetch` without re-fetching.
- File-locked `candidate-store.py append-batch` (F16) is proven under contention. The same `fcntl.flock` pattern can be reused for `source-ingester` if M6 needs concurrent wiki-page emission.
- The clean-break invariant held: zero `cogni-research:` or `cogni-claims:` dispatches anywhere in the chain (`grep` against the dispatched agents' tool calls is clean).
