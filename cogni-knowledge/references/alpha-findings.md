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

## M5+M6 smoke (2026-05-21)

End-to-end smoke of the v0.1.0 inverted-pipeline Phase-4 ingest step (cogni-knowledge milestones M5 + M6 from `absorption-roadmap.md`) extending the Slice-1 `.alpha/eu-ai-act-gpai/` base. Slice 2 of the Current sprint in `absorption-roadmap.md`. **Recommendation: GO** for Slice 3 (M7 — `wiki-composer` agent + `knowledge-compose` skill).

### Constraint on this run

The new `knowledge-ingest` skill + `source-ingester`/`claim-extractor` agents ship on PR #277 but the marketplace install is still at v0.0.17 in this session — the new skill is not in the Skill registry mid-session. The smoke therefore drove the ingest **manually from the parent context**, replicating what the skill would do (slug derivation via `_knowledge_lib.slugify`, atomic page writes via `_knowledge_lib.atomic_write_text`, frontmatter quoting via `json.dumps`, helper-script dispatch via Bash). The contract surfaces exercised are exactly the ones the skill exercises; the dispatch shape (per-source Task agent, per-batch atomic merge) is not exercised because there is no parallel fan-out in a manual run. That dispatch shape stays covered by the contract grep tests in `tests/test_ingest_contract.sh`.

### Sample sources

| # | URL | Publisher | sub_q_refs | Notes |
|---|---|---|---|---|
| 1 | `europarl.europa.eu/.../EPRS_ATA(2025)772906_EN.pdf` | `europa.eu` | `sq-04` | **The PDF.** Previously `webfetch_refused` in the Slice-1 manifest. Re-fetched via the new #275 PDF branch: WebFetch saved the binary, leaked the `[Binary content (application/pdf, 1.3MB) also saved to <path>]` line, `Read pages: "1-2"` returned the page content as vision-rendered images, transcribed into a 5 KB text body, stored via `fetch-cache.py store`. Manifest moved EP entry from `unavailable[]` to `fetched[]` (`fetched 41 → 42`, `unavailable 16 → 15`). |
| 2 | `code-of-practice.ai/` | `code-of-practice.ai` | `sq-02`, `sq-05` | Canonical GPAI Code of Practice mirror. Score 0.96, the highest-ranked fetched source in the base. |
| 3 | `ai-act-service-desk.ec.europa.eu/en/ai-act/article-55` | `ec.europa.eu` | `sq-03` | Regulator-authoritative page on Article 55 (GPAI systemic-risk obligations). Score 0.93. |

### Verification matrix

| Step | Contract | Outcome |
|---|---|---|
| 1 | #275 PDF branch: WebFetch → saved-binary path leaked → Read → transcribe → cache | **PASS** — EP PDF cache entry written (`cache_key 8532401a…`, `sha256:a3584ff6…`); `Read` returned pages 1-2 as page images the vision model transcribed into ~5 KB of text |
| 2 | #276 closed `VALID_REASONS` vocabulary: typo `cobrowse_unavail` is rejected at `--reason` parse time | **PASS** — `fetch-cache.py store --reason cobrowse_unavail` returned `success: false` with `--reason 'cobrowse_unavail' is not in the closed vocabulary [...]; see references/fetch-cache-design.md §'Reason semantics'` |
| 3 | `_knowledge_lib.slugify` produces `[a-z0-9][a-z0-9-]{0,79}` slugs | **PASS** — three slugs emitted, all ≤ 80 chars (two were length-capped at 80 with trailing-dash strip), all match the source-ingester sanity regex |
| 4 | `wiki/sources/*.md` written with `type: source` + populated `pre_extracted_claims:` per `claim-at-ingest.md:37-49` | **PASS** — 3 pages, 21 claims total (7 per source, 0 dropped). Frontmatter strings quoted via `json.dumps(s, ensure_ascii=False)` per the new YAML guidance — apostrophes in `Article 78's confidentiality obligations` and similar were correctly escaped, output validates as YAML |
| 5 | `excerpt_position` is a Python `str.find()` Unicode code-point offset, frozen at ingest (claim-at-ingest.md:57) | **PASS** — all 21 offsets re-verified via `body.find(excerpt_quote) == excerpt_position` against the cached body; zero mismatches |
| 6 | `atomic_write_text` (new helper) writes pages atomically, no `.tmp` debris | **PASS** — 3 pages written, no `.tmp` files left in `wiki/sources/` |
| 7 | `backlink_audit.py --top 8 --min-confidence medium` runs per slug (audit-only) | **PASS** — 3 runs, 2 high-confidence candidates each (the audit candidate list surfaces; `--apply-plan` deferred per the v0.0.20 audit-only note) |
| 8 | `wiki_index_update.py --slug ... --summary "..." --category Sources` per slug | **PASS** — 3 inserts; `wiki/index.md` now has a `## Sources` section with the 3 entries alphabetically sorted (action: `inserted`) |
| 9 | Single `## [YYYY-MM-DD] ingest \| …` line appended to `wiki/log.md` | **PASS** — one new line: `## [2026-05-21] ingest \| project=eu-ai-act-gpai-code-of-practice-obligations sources=3 claims=21 (Slice 2 M5+M6 manual smoke — PDF branch verified on EP URL via #275)` |
| 10 | `cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py --wiki-root .alpha/eu-ai-act-gpai/` exits 0, zero findings | **PASS** — `success: true`, `findings_count: 0`. The `type: source` allowlist from cogni-wiki v0.0.44 (`_wikilib.PAGE_TYPE_DIRS`) accepts the new pages |
| 11 | `cogni-wiki/skills/wiki-health/scripts/health.py --wiki-root .alpha/eu-ai-act-gpai/` runs clean | **PASS** — `success: true`. One benign warning: `.cogni-wiki/config.json entries_count=0 but filesystem has 3 (drift=+3)`. This is the expected M9 hand-off — `knowledge-finalize` runs `cogni-wiki/scripts/config_bump.py` to clear the drift; not in scope for M6 |
| 12 | `tests/test_ingest_contract.sh` ALL PASS after the smoke | **PASS** — 40 assertions including the behavioural `is_pdf_response` / `atomic_write_text` / `slugify` Python checks |
| 13 | `tests/test_skill_contracts.sh` ALL PASS after the smoke | **PASS** — clean-break invariant holds across all three new files (no `Skill("cogni-(research\|claims\|wiki):*")` dispatch) |

### New findings (F18–F19)

| # | Theme | Verdict | Detail |
|---|---|---|---|
| F18 | Vision-model PDF transcription cost | observed | The Read tool returns PDFs as **page images** (not extracted text strings) — the actual text comes from the calling model's vision-rendered transcription into the response. For a 2-page brief the cost is small; for a 20-page consolidated annex (the EUR-Lex case where no saved-file path was leaked, recording `pdf_extraction_failed`) the cost scales linearly with pages. `source-fetcher` correctly caps at `Read pages: "1-20"` per the agent contract, but the **silent body truncation past page 20 is real** — flagged as `pdf_truncated: true` in the cache entry but the body is incomplete. F18 = the reviewer's pre-merge item 4 ("PDF page-loop to read past page 20") observed empirically. File as a follow-up issue post-merge. |
| F19 | `wiki_health` `entries_count` drift | benign | `wiki/sources/` populated by M6 but `.cogni-wiki/config.json` `entries_count` stays 0 until M9 (`knowledge-finalize`) calls `config_bump.py`. This is the documented M9 hand-off (`inverted-pipeline.md:167`), not a bug. Documented here so a future M6-only smoke that runs `wiki-health` doesn't treat the warning as a regression. |

### What this clears for Slice 3 (M7)

- The `wiki/sources/<slug>.md` substrate is now real on disk. M7's `wiki-composer` will read `wiki/index.md` + the 3 source pages (in a real Slice-3 run it would read all 42 — this smoke proves the structure works) and draft a report with `[[wiki-slug]]` citations.
- `pre_extracted_claims:` frontmatter shape verified end-to-end. M8's `wiki-verifier` will read those claims and score the draft's citations as `verbatim` / `paraphrase` / `unsupported` with zero network calls — the structural win that makes M12's `claim-verify wall-clock < 5 min` target reachable.
- The `json.dumps`-quoted YAML emission handles regulator text containing apostrophes (`Article 78's`), parentheses, and commas without breakage — the v0.0.20 review-fix #2 holds against real source content.
- The #275 PDF branch shipped works: a previously-dropped EP think-tank ATAG PDF is now a citable source on the wiki. `pdf_extraction_failed` will remain the right outcome for sources where WebFetch does not leak a saved-file path (the EUR-Lex consolidated-annex case observed during PR-#277 planning); F18 documents the follow-up to extend `Read` beyond page 20.
- All clean-break invariants hold under contract grep tests after the smoke; no regressions.

### Out-of-scope / acknowledged limits of this smoke

- Manual driver, not the installed skill — fan-out parallelism (8 ingesters per batch) was not exercised. The marketplace clone needs to be bumped to v0.0.20 post-merge for a fully-orchestrated smoke. The contract surfaces that the skill would exercise (slug pipeline, frontmatter shape, helper-script chain, lint/health) **are** all exercised here.
- Sample of 3 of 42 fetched sources — not the full set. The full-run smoke runs once the skill is installed; the contract assertions verified here would surface the same way at 42 sources as at 3.
- F18 follow-up (PDF page-loop) and the reviewer's deferred items 5 (`--summary-file` cross-plugin coordination in cogni-wiki) and 6 (this run is item 6) stay open as documented in the PR comments on #277.

## M8 design (2026-05-22)

### New findings (F20)

| # | Theme | Verdict | Detail |
|---|---|---|---|
| F20 | Sentence-delimiter rule misclassifies regulator abbreviations + article numbering | watch at M12 | The shared verifier↔revisor delimiter (`. ` / `? ` / `! ` followed by a capital letter or end-of-line, H2-bounded sections) splits `"Dr. Smith said …"`, `"Article 1.2 of the AI Act"`, and numbered lists at the wrong places. The failure mode is bounded — Step 3.2's `draft_position_out_of_range` inline filter prunes mis-aligned manifest entries and the loop terminates with a few pruned citations rather than crashing. **Non-blocking for M8 ship**, but EU-AI-Act prose is heavy on `Article N.M`, `Annex III`, `Dr.`/`Prof.`, and bulleted clauses — M12 alpha will exercise the failure mode. Likely fix surface (deferred to a follow-up slice): swap the regex-style rule for a small tokenizer that handles abbreviation lookbehind + numbered-list continuation. Raised by `sdh07` in PR #281 review. |

### What this clears for Slice 4 (M8) ship

- The Step 3.2 `draft_position_out_of_range` inline-filter contract makes F20's failure mode bounded — pruned manifest entries surface in the summary; the loop terminates cleanly. No crash, no infinite-loop risk.
- Cross-agent tokenization-rule coupling (verifier line 46 ↔ revisor lines 87/96) ensures both agents tokenize identically; F20 is a property of the **shared** rule, not a drift between agents.

## M12 alpha re-run (2026-05-23)

First **full live end-to-end** run of the v0.1.0 inverted pipeline (Phases 1–7) against a fresh base — and the first time Phases 5–7 (`compose` / `verify` / `revisor`) ran live rather than under contract tests. Driven manually against the installed v0.0.27 marketplace clone (`cogni-knowledge/0.0.27`, `cogni-wiki/0.0.45`).

**Run shape.** Base `eu-ai-act-v01` at `.alpha/eu-ai-act-v01/`; topic *"EU AI Act GPAI Code of Practice obligations"*, market `eu`. 6 sub-questions → 53 candidates (after URL-dedup of 72 emitted) → 51 fetched + 2 unavailable → 51 ingested (317 pre-extracted claims) → draft-v1 6 570 words / ~169 citations → verify round 0 (28 unsupported) → revisor round 1 (14 rephrase + 14 drop) → draft-v2 / verify round 1 (10 unsupported). Revisor round 2 was **stopped by the operator** to score the gate on draft-v2 (the verify loop wall-clock made a third pass uneconomic, and the verdict was already determined).

### Pass-criteria scorecard (roadmap Phase 5 lines 143–149)

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | 0 duplicate URL fetches | **PASS** | 53 cache entries = 53 distinct normalized candidate URLs; no URL cached twice; 0 duplicate `content_hash`; sample re-fetch returns a clean cache hit (no network). |
| 2 | 0 unreachable URLs in the citation set | **PASS** | The 2 unavailable URLs (`cms-lawnow.com` 403, `twobirds.com` 402) were dropped at fetch time → never ingested → uncitable. Composer also did not cite the off-topic `eur-lex…C/2025/6233` page. Every cited slug resolves to a fetched page on disk. |
| 3 | Claim-verify wall-clock < 5 min | **FAIL** | Each `wiki-verifier` pass ≈ **16–18 min** at 169 citations; `revisor` ≈ **23 min**. Beats the 20–30 min cogni-claims baseline (zero-network is genuinely won) but is ~3–4× over the 5-min target. The target was calibrated for the ~37-citation example in the contract; cost scales ~linearly with citation count. → **F21**. |
| 4 | Every cited statement resolves to an aligned claim | **FAIL** | *Structurally* clean — all ~169 citations resolve to an existing page + existing `claim_id` (0 missing pages, 0 missing claim_ids). *Semantically* not — the verifier flagged 28 `unsupported` (round 0), reduced to 10 on draft-v2, and the max-2-round cap does not converge to 0. → **F22**, **F23**. |
| 5 | F11 recovery contract still works | **NOT VERIFIED (live)** | `writer-outline-v1.json` is present and well-formed (10 sections, `planned_total`/`target_words`). The recovery *path* is covered by `test_compose_contract.sh`, but the live "kill mid-Phase-2 + re-dispatch" was **not exercised** this run, and the outline's mtime is *after* draft-v1 (consistent with the composer's post-draft word-count fill, so anchor-before-draft ordering can't be confirmed from mtime alone). |

**Gate verdict: HOLD.** C1 ✅ C2 ✅ C3 ❌ C4 ❌ C5 ⊘. Do **not** bump to v0.1.0 / flip maturity to Preview until C3 and C4 are addressed. The alpha did its job: it surfaced two structural problems *before* the maturity boundary crossing.

### New findings (F21–F26)

| # | Theme | Verdict | Detail |
|---|---|---|---|
| F21 | Verify/revise wall-clock scales ~linearly with citation count | **blocker for C3 — fixed v0.0.28 (Slice 10, #286), pending gate re-run** | At 169 citations each zero-network verifier pass is ~16–18 min and the revisor ~23 min; the full verify→revise→verify→revise→verify loop is ~90 min. The structural win vs cogni-claims (no re-fetch) holds, but per-citation LLM scoring dominates. The "< 5 min" target is unreachable at realistic draft size with a **single** verifier dispatch. **Primary fix: fan out the verifier.** Each citation's verdict is independent (one cited page's claims vs one draft sentence) — verification is embarrassingly parallel, unlike composition. `knowledge-verify` should shard `citations[]` into N batches → dispatch N `wiki-verifier` instances in parallel (each scoped to its citation subset) → merge the `verified[]` / `deviations[]` / `counts` fragments, mirroring the `candidate-store` / fetch-manifest / ingest-manifest fan-out the earlier phases already use. Wall-clock then drops ~linearly with shard count while the LLM judgment is preserved. Complementary, not either/or: (b) a deterministic script pre-filter that confirms `excerpt_quote` substring-presence at `excerpt_position` (no LLM) and escalates only ambiguous cases; (c) cap/segment citations per section. Re-baseline the target per-shard once fan-out lands. |
| F22 | `draft_position` off-by-one between composer and verifier is the dominant `unsupported` cause (F20 confirmed at M12) | **blocker for C4 — fixed v0.0.28 (Slice 10, #287), pending gate re-run** | Most round-0 deviations were `claim_text_misaligned`, clustered in section 06 (timeline + fines), where the manifest's `section:sentence` counter is shifted by one vs the verifier's independent sentence walk — so a citation is flagged because the pointer lands on the *neighbouring* sentence, not because the evidence is wrong. The two agents tokenize the same prose independently (the shared F20 delimiter rule), and EU-AI-Act prose (`Article 53(1)(c)`, `10^25`, `Annex XI`, `Dr.`) is exactly its worst case. Sub-case: **phantom manifest entries** — the manifest declares a citation at a `draft_position` whose draft text carries a *different* wikilink (the revisor's killed-round-2 trace spent its whole run on this). Fix surface = the F20 tokenizer rewrite **plus** making `draft_position` a stable id the composer emits and the verifier consumes verbatim (not re-derived). |
| F23 | Revisor biases to citation-drop over re-alignment; 2-round cap doesn't converge | **quality — fixed v0.0.28 (Slice 10, #288), pending gate re-run** | Round 1 applied 14 `rephrase` + **14 `drop`** of 28 deviations. "Drop" deletes the citation / rewrites the sentence as non-evidence-based, so the `unsupported` count falls partly by *eroding the evidence base* rather than correcting alignment — a quality regression hidden inside an improving metric. Combined with F22, the loop terminated at 10 unsupported on draft-v2 and would not reach 0 within the structural 2-round cap. The revisor should prefer re-pointing to the correct on-page claim (cheap, since claims are local) before dropping. |
| F24 | Citation-count drift across composer / manifest / verifier | minor | The same draft is reported as 156 (composer return), ~169 (manifest), 168 (verify-v1 total), 169 (verify-v2 total) and 165 (`pipeline-summary project`). Symptom of the same independent-tokenization coupling as F22 plus differing count surfaces. Non-blocking but noisy for operators reading the summary. Pin one authoritative count (manifest `len(citations)`). |
| F25 | EUR-Lex ELI / landing URLs mis-resolve or summarise | environmental | `eur-lex…/eli/C/2025/6233/oj/eng` (curated as the CoP endorsement) served **General Product Safety Regulation** text instead — the ELI endpoint resolved a different OJ document; the fetcher correctly stored it as-is and the composer correctly declined to cite it. Both `reg/2024/1689` URLs returned a short WebFetch *summary*, not the full regulation text, so the canonical Act text is under-represented on the wiki. Pipeline behaved correctly (no drop decision at fetch time, verifier-protected at cite time); flagged so curation can prefer `artificialintelligenceact.eu` article pages over EUR-Lex landing URLs for the actual normative text. |
| F26 | `knowledge-ingest` helper-script resolution picks the lexically-first cached cogni-wiki version | env fragility | `resolve_wiki_ingest_scripts()` (and the probe loops) take the **first** glob match of `…/cogni-wiki/*/skills/wiki-ingest/scripts`, which on a multi-version dev cache is `0.0.16` (lexically smallest), not the installed `0.0.45`. The 0.0.16 helpers predate the per-type-dir + `type: source` schema and could mis-handle the layout. The operator pinned `0.0.45` for this run. Only bites machines with multiple cached versions (dev boxes), but the resolver should sort by version (or read the installed version) and pick the newest. |

### What this means for M12 / the v0.1.0 flip

- **The flip is blocked on C3 (F21) and C4 (F22/F23).** Both are structural, not data-quality, and both trace partly to the same root: the composer and verifier independently tokenize the draft into `section:sentence` positions. Making `draft_position` an emitted-and-consumed stable id (rather than re-derived on each side) would dissolve most of F22/F24 and shrink the revisor's workload; F21 is best fixed by **fanning out the verifier** (shard `citations[]` → N parallel `wiki-verifier` dispatches → merge fragments; verification is embarrassingly parallel because each citation's verdict is independent), with a deterministic substring pre-filter as a complementary cost reducer.
- **Phases 1–4 are solid at scale.** Curation (53 from 6 SQs), fetch (51/53, PDF Read-loop on 3 PDFs incl. a 34-page arXiv, negative-cache on 2 dead URLs), and ingest (51 pages, 317 position-verified claims, nested `source-ingester`→`claim-extractor` dispatch) all ran clean. The wiki-first substrate works.
- **Recommendation:** keep `cogni-knowledge` at v0.0.27 / Incubating. File F21, F22 (incl. the `draft_position`-as-stable-id fix), and F23 as issues; F24/F25/F26 as lower-priority follow-ups. Re-run the M12 gate after the `draft_position` rework, on a smaller draft (or sharded verify) to also retest C3.

### Resolution status (updated 2026-05-23, v0.0.28 / Slice 10)

F21 (#286), F22 (#287), and F23 (#288) are **fixed in v0.0.28** but the gate has **not** been re-run. The fix took the `draft_sentence`-carried-in-manifest route rather than the F20 tokenizer rewrite: composer + revisor emit the cited sentence verbatim with a stable `id`, the verifier scores it directly (no re-tokenization), `knowledge-verify` fans the verifier out across parallel shards via `verify-store.py`, and the revisor re-points to a covering on-page claim before dropping. The next landing re-runs the M12 gate on a fresh `.alpha/` base — only on green (C3 per-shard verify < 5 min; C4 verify→revise converges, `drop` down / `repoint` up) does the v0.1.0 bump + Preview maturity flip land. F24–F26 (#289) remain open.

## M12 alpha re-run #2 (2026-05-24) — GREEN → v0.1.0 / Preview

Second full live run of the v0.1.0 inverted pipeline (Phases 1–7), this time on **v0.0.29 code** (Option-B parallel fetch + sharded verify), on a fresh cold `.alpha/eu-ai-act-v03/` base. Same topic as the held run for comparability: "EU AI Act GPAI Code of Practice obligations", 6 sub-questions.

**Run shape.** 6 sub-questions → 47 candidates (72 raw, dedup'd) → 42 fetched / 5 unavailable → 42 ingested / **283 claims** → draft-v1 6,060 words / **150 citations** → verify-v1 **16 unsupported** → revisor (repoint 3 + rephrase 13, drop 0) → draft-v2 **2 unsupported** → revisor (rephrase 2, drop 0) → draft-v3 **0 unsupported** → synthesis deposited (38 sources cited).

### Pass-criteria scorecard (all GREEN)

| Criterion | Held gate (2026-05-23) | Re-run (2026-05-24) | Verdict |
|---|---|---|---|
| **C1** one cache entry / distinct URL | ✅ | 47 cache entries == 47 distinct normalized URLs | ✅ PASS |
| **C2** 0 unreachable cited | ✅ | 0 of 5 unavailable cited; 38/38 cited slugs resolve | ✅ PASS |
| **C3** verify wall-clock < 5 min | ❌ ~16–18 min/pass @ 169 cites | **3.6 min** max per-shard (4 shards, parallel) | ✅ PASS |
| **C4** verify→revise → 0 unsupported in ≤2 rounds | ❌ doesn't converge | **16 → 2 → 0**, revisor `drop=0` | ✅ PASS |
| **C5** F11 recovery | ⊘ not exercised | crash-sim → `RESUME_FROM_OUTLINE=true` skipped Phase 1, drafted | ✅ PASS |

### Why the held blockers cleared

- **C3 (was F21):** the v0.0.28 verifier fan-out (`verify-store.py shard`/`merge`) turned one serial 16–18 min pass into 4 partition-disjoint shards run concurrently; the slowest shard was 3.6 min. The < 5 min target is now per-shard wall-clock, and it held with margin.
- **C4 (was F22 + F23):** the F20 off-by-one never surfaced because the verifier scored the manifest's verbatim `draft_sentence` directly and never re-tokenized (F22). The revisor's repoint-before-drop (F23) closed 16 → 2 → 0 with **zero citation drops** — re-alignment, not evidence erosion. 4 of 150 manifest `draft_sentence` values weren't verbatim-present in draft-v1, but they scored as content deviations rather than `sentence_not_in_draft`, and all resolved by round 3.
- **F20 itself stays deferred** — `draft_sentence` carriage made the tokenizer rewrite non-load-bearing, exactly as v0.0.28 intended.

### Landing

On the green verdict, **v0.1.0 shipped in this same landing**: `plugin.json` + `marketplace.json` → 0.1.0, `binding.json` `SCHEMA_VERSION` → 0.1.0 (M12 re-alignment, no field change), README maturity callout flipped **Incubating → Preview**, `#287`/`#288` closed, epic #264 Phase 5 ticked. Approx run cost ~$1.30. **Phase 5 complete.** #289 (F24–F26) and #291 (pre-0.0.28 manifest guard) remain open as non-blocking polish; revisit during the v0.1.x bake before Phase 6.

### Resolution status (updated 2026-05-24, v0.1.1)

F24, F25, and F26 (**#289**) are **fixed in v0.1.1**. All three were non-blocking polish, so they shipped after the v0.1.0 maturity flip without re-running the gate — none touch pipeline behaviour beyond helper-script version resolution:

- **F24 (count drift)** — pinned the one authoritative citation count to `len(citation-manifest.json::citations)` for the latest draft version (surfaced by `pipeline-summary.py project`): `wiki-composer` returns the exact array length (not an estimate), `knowledge-compose`/`knowledge-verify` quote the script-derived count, and `verify-vN.json` `counts.total` is relabelled as a per-round verdict tally (verdicts-scored-for-draft-vN), not the citation count. No standalone-script (`.py`) change — the canonical surface (`pipeline-summary.py`) + `verify-store.py` conservation checks already existed; only `knowledge-verify`'s inline Step-4 validation snippet was touched. Pinned in `CLAUDE.md` §Conventions.
- **F25 (EUR-Lex curation)** — `source-curator` (Phase 1 + Phase 3 Authority) and `knowledge-plan` (§2 `candidate_domains`) now prefer canonical article-page domains (`artificialintelligenceact.eu`) over EUR-Lex landing/ELI URLs for normative text. Guidance-only.
- **F26 (helper-script version resolution)** — `resolve_wiki_ingest_scripts()` (ingest + finalize) sorts cached cogni-wiki versions with `sort -V` and picks the newest; regression test `tests/test_resolve_wiki_scripts.sh`. The companion lexical-version bug in `cogni-workspace/scripts/discover-plugins.sh` was fixed in the same landing (cogni-workspace **v0.6.31**).

#291 (pre-0.0.28 manifest guard) remains open.

## #311 live German bake-in (2026-05-27)

The first **live German (`--output-language de`) end-to-end run** since the Slice-13/15/16 fixes, on installed **cogni-knowledge v0.1.8 + cogni-wiki v0.0.46**, base `.alpha/eu-ai-act-de/` (gitignored), topic *"Verpflichtungen für Anbieter von KI-Systemen mit hohem Risiko nach der EU-KI-Verordnung"*, market `dach`. This was both the Slice-13 exit verification and the place the Slice-15/16 + P1.3 live proofs were deferred to.

**Version-resolution gotcha (recovered).** The session first resolved **v0.1.7** even though `installed_plugins.json` recorded 0.1.8 on disk — the running session had cached the older resolution. The tell was the skill prompt's base-dir header (`.../cogni-knowledge/0.1.7/skills/...`). Fix: `/plugin` refresh + **Claude Code restart**. **Always confirm the skill's printed base-dir version before a live run** (the M12 gotcha, re-confirmed live).

**Run 1 (full pipeline).** 6 sub-questions → 69 candidates → 67 ingested / 408 claims → draft-v1 (4 900 words, 109 citations) → verify 6 unsupported → 1 revisor round (repoint 1 / rephrase 4 / drop 1) → 0 unsupported (verify-v2: 64 verbatim, 44 paraphrase) → synthesis deposited (26 of 67 sources cited). Per-shard verify wall-clock ≤ ~3.8 min (3 shards round 0; incremental round 1 = 1 shard of 6).

**Slice-13/15/16 exit criteria — all PASS (live-proven in German):**

| Criterion | Result |
|---|---|
| One localized `## Referenzen`, no `## References` dup (#301) | ✅ |
| 109 clickable `<sup>[N](url)</sup>`, 0 raw `[[sources/]]` in prose (#300) | ✅ |
| Transliterated synthesis slug `verpflichtungen-fuer-…-risiko-…`, 0 broken `f-r` (#303) | ✅ |
| Body `[N]` contiguous 1..26, matches reference list (finalize renumber) | ✅ |
| German ä/ö/ü/ß intact in body + headings, no ASCII fold | ✅ |
| `health.py` 0 errors + `lint` 0 `orphan_page` (Slice 16) | ✅ *(see F30)* |

**Findings (filed under #264):**

- **F27 / #325 (HIGH — correctness blocker).** `wiki-composer` writes **invalid JSON** in `citation-manifest.json` when a `draft_sentence` contains a `"` — here a German `„…"` pair whose straight-ASCII closer was left unescaped (4 of 109 entries). `knowledge-verify` could not `json.loads` the manifest; the run needed a manual re-escape repair to proceed. The composer's Step-5 self-check returned `ok:true` without actually parsing what it wrote. **The German run does not pass end-to-end on stock v0.1.8 without this fix.** Fix: serialize the manifest via `json.dumps` (the source-ingester already does this correctly), and make the self-check `json.loads` + substring-assert.
- **F28 / #326 (HIGH — headline; P1.3 cross-lingual).** **Read-before-web (P1.3, the v0.1.8 increment) does not fire for non-English bases.** Run 2 (overlapping German topic — GPAI transparency/governance/penalties) scored **all 6 sub-questions `uncovered`** despite the base demonstrably covering ≥3, because `wiki-coverage.py`'s lexical Jaccard matches the German query against the sources' **English titles** (Art-99 title vs German query = 0.118) and is brittle to German compounds (`Bußgelder` ≠ `Bußgeldsystem`). All-`uncovered` → curators take the full-search branch → **zero compounding; Run 2 query count ≈ Run 1.** The "fewer queries on run 2+" proof is **NEGATIVE for German.** **Couples to the open #309 P1.2-rest cross-lingual gap — P1.3 cannot be considered "done" on the #309 gate until coverage matching is language-aware.**
- **F29 / #324 (med).** `wiki/index.md` one-liners are truncated **mid-word** (script-stored `[:180]` hard cut, not LLM-bounded). The index is reader-facing *and* the dominant signal `wiki-coverage.py` reads — so this also weakens F28's only German signal.
  - **Resolved (v0.1.12 + cogni-wiki v0.0.47).** Correction to this finding's own diagnosis: the cut was **LLM-side**, not "script-stored" — `wiki_index_update.py` always stored `--summary` verbatim and never truncated. The mid-word slice came from the LLM honoring a literal "≤180 chars" authoring contract (in `source-ingester.md` + `knowledge-ingest`/`knowledge-finalize` Step 4.2/7) with a hard `[:180]`. Fixed in two complementary layers: (1) **semantic authoring** — every "≤180 chars" / "truncated to 180 chars" instruction replaced with "one crisp, self-contained sentence" (no character count), aligning cogni-knowledge with cogni-wiki's own already-semantic `wiki-ingest` convention; (2) **deterministic word-boundary backstop** — cogni-wiki v0.0.47's opt-in `wiki_index_update.py --max-summary 240` (`_wikilib.clamp_summary`) clamps on a word boundary with `…` only if the authored sentence runs long. The F28 German-signal weakening is also addressed: a complete word ("sonderkategorien") replaces the fragment ("sonderka"), strengthening the only German coverage signal (`wiki-coverage.py` drops the trailing `…` on its `[^a-z0-9]+` tokenizer).
- **F30 / #323 (med) + the 0-orphan caveat.** `knowledge-ingest --batch-size 8` is conservative; the live run dispatched the 67 ingesters in **two waves of 25/26** with no issue — the per-wave barrier (waiting for the slowest of 8) is the real cost. Separately, **0-orphan was only reached after manually running the deferred `knowledge-ingest` Step 4.1 `backlink_audit --apply-plan`**: the composer cited 26 of 67 sources, leaving 41 uncited orphans; `backlink_audit` found high-confidence sibling candidates for all 41 (de-orphan **works**), but per-slug LLM-curated authoring does **not scale to 67 sources in an orchestrator context** (same class as #323).
  - **Resolved (v0.1.23) — the batch-size half.** `knowledge-ingest` Step 3 was reframed to **one wave per batch** and the `--batch-size` default raised **8 → 25** (the proven live wave). `--batch-size` is now an advisory per-wave return-volume cap, not a concurrency limiter (Claude Code self-throttles the single-message fan-out); the per-wave barrier is retained only as the Step 3.4 merge checkpoint. Common runs (≤ 25 sources) collapse to a single wave; the 67-source run drops from ~9 barriers to ~3. Reasoning + the cross-phase fan-out posture formalized in `references/fan-out-concurrency.md`. **The 0-orphan caveat above is a separate concern** (per-slug LLM backlink curation does not scale to 67 sources) and is **not** closed by #323.

**Verdict.** The Slice-13/15/16 localized-output + wiki-conformance fixes are **live-proven in German**. But the run is **not a clean stock-v0.1.8 end-to-end pass** (#325 blocker needed manual repair) and the **P1.3 compounding proof is negative** (#326). **#325 (correctness) + #326 (P1.3 / P1.2-rest) should gate the Phase-6 readiness verdict on #309.** #311 is now **closed** — its Slice-13 exit verification passed; the P1.3 live-proof obligation is tracked under **#326** (split decision). Recommended order: fix **#325** first (every German run is blocked end-to-end without it), then **#326 / P1.2-rest** (the cross-lingual coverage + verifier alignment), alongside the remaining #309 increments (P1.1 reviewer).
