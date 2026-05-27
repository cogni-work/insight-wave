# cogni-knowledge changelog

## 0.1.10 — 2026-05-27

Fixes **#326** — the read-before-web coverage scorer (`wiki-coverage.py`, P1.3, shipped v0.1.8) was a **no-op on every non-English base**, closing the cross-lingual-scoring half of the **#309 P1.2-rest** gate item. The #311 German bake-in (Run 2, 2026-05-27) proved it: a deliberately-overlapping German plan — transparency (Art 13/14), governance (Art 71/72), penalties (Art 99), all demonstrably present from Run 1 — scored **all 6 sub-questions `uncovered`, 0 covering pages**, so every curator took the full-search branch and the promised "fewer queries on run 2+" compounding never materialized. Because cogni-knowledge targets DACH/DE/FR/IT/PL/NL/ES, P1.3 was dead for all non-English markets. Maturity stays **Preview**.

Root cause: the original matcher was **symmetric Jaccard** over a single pooled token bag. Five compounding defects — (1) the `<3`-char drop discarded the article-number anchors (`99`, `13`) that are the only reliable cross-lingual bridge; (2) source pages keep English titles even on a German base, so Jaccard's *union* was bloated by cross-lingual tokens and the score collapsed; (3) German compounds (`Bußgelder` ≠ `Bußgeldsystem`) never intersected; (4) the 0.30 threshold was unreachable (German overlap capped at ~0.09–0.19 even at `--threshold 0.01`); (5) boilerplate tokens (`verordnung`, `artikel`, `system`, `hochrisiko`) on ~60/68 pages dominated ranking, so naively lowering the threshold surfaced the *wrong* pages.

### Changed

- **#326 — `wiki-coverage.py` matcher rewrite (language-robust weighted directional coverage).** Replaces symmetric Jaccard. (a) **Anchor-preserving tokenization** keeps all-digit tokens at any length (article numbers, weighted ×3.0) and adds folded German stopwords. (b) A fixed **`GENERIC_DENYLIST`** zeroes the weight of EU-regulatory boilerplate (`verordnung`, `artikel`, `system`, `hochrisiko`, `eu`, ubiquitous years, …) so it can't dominate ranking — the single calibration lever for precision. (c) **Prefix-only compound matching** (`bussgelder`~`bussgeldsystem`, length-guarded) handles German concatenation while rejecting suffix false-matches (`system` inside `risikomanagementsystem`) and boilerplate-headed collisions (`systemverwaltung`~`systeme`, shared prefix `system`). (d) **Directional weighted recall** (`matched_sq_weight / total_sq_weight`) kills the cross-lingual union bloat. (e) The cover predicate is the recall ratio (`DEFAULT_THRESHOLD` 0.30 → **0.20**) **AND** an absolute `MIN_MATCHED_WEIGHT` floor — the floor is what keeps genuinely-novel sub-questions `uncovered`. (f) Page signal gains **`pre_extracted_claims[].text`** (the richest target-language content, via `_knowledge_lib.parse_pre_extracted_claims`). (g) The emitted `covered_pages[]` is capped at 8 (verdict computed on the full passing set first). The **output envelope schema is byte-stable** (`overlap_score` stays a `[0,1]` float, now weighted recall rather than Jaccard), so `source-curator` and `knowledge-curate` Step 0.5 are unchanged. File: `scripts/wiki-coverage.py`.

### Tests

- `tests/test_wiki_coverage_bilingual.sh` (new) — the committed cross-lingual regression guard (`.alpha` is gitignored, so the live re-score is a manual follow-up). German fixtures (English page titles + German index one-liners + German `pre_extracted_claims`) assert: a German covering page is surfaced while an unrelated page is excluded; a lone article-number anchor clears the floor; an all-boilerplate sub-question stays `uncovered`; a novel sub-question (Art 51/52 absent) stays `uncovered`; the topically-correct page outranks a generic page (defect-5 ranking); the compound false-positive guard holds; a one-page German base → `partial`.
- `tests/test_wiki_coverage.sh` — re-confirmed green under the new default (English fixtures rely on discriminating tokens the denylist excludes); `tests/test_skill_contracts.sh` doc guards unchanged.

### Notes

- No schema bump: `wiki-coverage.json`'s envelope shape is unchanged; only `overlap_score`'s *meaning* shifts (Jaccard → weighted recall), documented in the script docstring. The matcher is no longer a "point-in-time replica of `cogni-wiki/.../refresh_planner.py`" — that framing was dropped from the docstring. **Deferred (out of scope):** ingester-emitted target-language `keywords`/`title_<lang>` frontmatter (the index one-liner + claim text already supply enough signal, and a frontmatter change would force re-ingesting every base); true cross-lingual *semantic* matching (`Verordnung`↔`Gesetz`) — impossible under the stdlib-only / no-pip constraint without an embedding model, with structural anchors + localized one-liner + compound matching the pragmatic substitute; and the wiki-verifier cross-lingual half of #309 P1.2-rest (verify-time alignment, a separate item). The live "curators issue measurably fewer queries" re-proof folds into the open **#311** German bake-in re-run. Remaining #309 increment: **P1.1** (structural reviewer), then **P2**.

## 0.1.8 — 2026-05-26

First increment of the **#309 Phase-6 readiness gate** (epic **#264**) — **P1.3: read-before-web compounding**. #309 audits the cogni-research capabilities that must be ported into cogni-knowledge before cogni-research can be retired, and recommends the order **P1.3 → P1.1 → P1.2-rest → P2**. This release lands P1.3 only; it **references but does not close** #309 (the gate stays open until the last P1 increment lands). Maturity stays **Preview**.

The plugin's thesis (`references/differentiation-thesis.md`: *"The next research run reads the base before going to the web"*) was unrealized at **research time**: `knowledge-curate` (Phase 2) fanned one `source-curator` per sub-question and each one WebSearched immediately, never consulting the bound wiki — so every run was a full web run and the promised decreasing cost-per-run never materialized. The only compounding was `wiki-composer` reading prior syntheses at *compose* time, too late to save fetches.

### Added

- **#309 (P1.3) — wiki-coverage pre-step.** New `scripts/wiki-coverage.py` (`score`, stdlib-only, JSON envelope): for each `plan.json` sub-question it scores the bound wiki's `wiki/sources/*.md` + `wiki/syntheses/*.md` by token-overlap (Jaccard) — a point-in-time replica of `cogni-wiki/.../refresh_planner.py`'s proven matcher, replicated not imported per the clean-break pattern — and emits a per-sub-question verdict (`covered` / `partial` / `uncovered`) plus the covering pages (each with a wiki-root-relative `page_path`). The dominant per-page signal is `title` + the `wiki/index.md` one-liner (page `tags` default to `[source]`/`[synthesis]`, so they carry almost no signal). An empty / unreadable / fresh base yields all-`uncovered`, so run 1 behaves exactly like today. File: `scripts/wiki-coverage.py`.
- **#309 (P1.3) — `knowledge-curate` Step 0.5.** The orchestrator resolves coverage **once** (mirroring the #304 resolve-market-config-once posture), writes the verbatim envelope to `<project>/.metadata/wiki-coverage.json`, and threads `WIKI_ROOT` + `WIKI_COVERAGE_PATH` to every curator. The pre-check is **fail-soft** — a scorer error or unreadable wiki degrades to an all-`uncovered` manifest and curation proceeds (the deliberate opposite of the #304 market-config hard-abort: a wrong authority list corrupts scoring, but a missing coverage read only costs a full search). `--dry-run` prints a per-sub-question `COVERAGE=<verdict>` line and writes nothing. File: `skills/knowledge-curate/SKILL.md`.
- **#309 (P1.3) — `source-curator` read-before-web narrowing.** New `WIKI_ROOT` (required) + `WIKI_COVERAGE_PATH` (optional) params. Phase 0 loads this sub-question's verdict; Phase 1 branches on it — `uncovered` (or no coverage data) keeps today's 5–7-query full search, while `covered`/`partial` `Read`s the covering pages under `WIKI_ROOT` and issues **fewer queries (2–4) targeted at the gaps + a recency refresh**. The narrowing is in the *query budget*, never the *quality bar*: good new candidates are still scored and emitted, and the pages already in the wiki stay citable at compose time (the composer reads the wiki directly), so coverage is preserved while new web work shrinks. Return summary gains `wiki_coverage_verdict` / `wiki_covered_pages` / `queries_issued`. File: `agents/source-curator.md`.

### Tests

- `tests/test_wiki_coverage.sh` (new) — empty/missing wiki → all `uncovered` + `success:true` (run-1 no-regression); a `sources/` page that overlaps a sub-question → `covered`/`partial` with the right slug + `page_path`; a `syntheses/` page → `page_path` is `wiki/syntheses/…` (guards the `synthesis`→`syntheses` pluralization); `--threshold` boundary; malformed / sub-question-less `plan.json` → clean `success:false`.
- `tests/test_skill_contracts.sh` — knowledge-curate Step 0.5 (`wiki-coverage.py`, `wiki-coverage.json`, `WIKI_ROOT=`/`WIKI_COVERAGE_PATH=` threading, fail-soft) + source-curator (`WIKI_COVERAGE_PATH`, `coverage_verdict`, `WIKI_ROOT`).

### Notes

- Ships on deterministic-gate + contract coverage, consistent with Slices 13–16. No schema bump (`wiki-coverage.json` is a new project-local artifact; `plan.json` / `binding.json` unchanged). `knowledge-plan` is intentionally untouched — the coverage check belongs at curate, where WebSearch happens (the issue's verbatim minimum: *"pro Sub-Question prüfen, ob die Wiki sie schon deckt, bevor WebSearch läuft"*). The live "fewer queries on run 2+" proof folds into the open **#311** German bake-in re-run, matching how Slices 15/16 shipped. Remaining #309 increments: **P1.1** (structural reviewer), **P1.2-rest** (cross-lingual scoring + language-config UX), then **P2**.

### Review fixes

A multi-angle review of the scorer + its tests surfaced ways coverage could be silently blinded or under-tested. Hardened:

- **Title-less pages no longer go invisible.** `_collect_pages` now falls back to the page **slug** when frontmatter has no parseable `title:` (block-scalar title, leading-blank/BOM that defeats `_FRONTMATTER_RE`, or a genuinely title-less page) — mirroring the replicated `refresh_planner`'s `title or slug`. Without it such a page tokenized to just its `[source]`/`[synthesis]` tag and scored ~0 against every sub-question, defeating read-before-web exactly when it should help.
- **German tokens stay whole.** `tokenize()` now de-accents via a `_fold()` step (NFC → the `_knowledge_lib` umlaut/ß map → NFKD), so `Geschäftsidee` → `geschaeftsidee` (not `gesch`+`ftsidee`) and `Straße` → `strasse`. The ASCII-only `[^a-z0-9]+` split previously fragmented every umlaut word on the German/EU corpus this plugin targets. Applied identically to both sides, so Jaccard stays symmetric.
- **`--threshold 0` is rejected.** The lower bound is now exclusive (`0.0 < threshold <= 1.0`): jaccard returns `0.0` for disjoint sets, so `score >= 0.0` would have marked every page as covering every sub-question.
- **Inline `#` comments no longer leak into the title token set** (unquoted scalars only — mirrors `_knowledge_lib._absorb_claim_kv`).
- **Tests.** `test_wiki_coverage.sh` gained the previously-unexercised `partial` branch (single covering page; mutation-confirmed it now catches a `partial`→`covered` regression), a genuinely-missing-`wiki/` case (not just empty dirs), a title-less-page slug-fallback case, and a `--threshold 0` rejection; valid-plan runs are now guarded so a happy-path regression fails loudly instead of `set -e`-aborting the script silently. `test_skill_contracts.sh` now asserts the source-curator **Phase-1 branch** prose (`Branch on the`, `fewer queries`), not just the `coverage_verdict` field name (which also matched the return-summary JSON example).
- **Contract clarity.** `knowledge-curate` Step 0 now explicitly captures `data.binding.wiki_path`, and the `--dry-run` wording no longer reads "stop" before the step it says still runs (Step 0.5 runs read-only, then the run stops before dispatching curators).

## 0.1.7 — 2026-05-26

Slice 16 of the Phase 5 v0.1.x bake-in (**#264**) — **wiki conformance**: the deposited base must pass cogni-wiki's own `wiki-health` / `wiki-lint` gates. One systemic root: the inverted pipeline writes the wiki via forked agents + direct script calls, bypassing cogni-wiki's LLM skills, so it never ran those gates. Maturity stays **Preview**. Closes **#306**, **#307**, **#308** (umbrella); the live `0 errors` / `0 orphan_page` proof on a fresh German base folds into **#311**. Paired with cogni-wiki **v0.0.46** (#306 seed-placeholder self-clean + a `lint_wiki.py --fix` fresh-read fix so the conformance gate's `reverse_link_missing` de-orphaning isn't clobbered by `frontmatter_defaults`).

### Fixed

- **#308 — 100% orphan rate (the linchpin).** `knowledge-finalize` emitted reference-list backlinks as path-prefixed `[[sources/<slug>]]` / `[[syntheses/<slug>]]`. cogni-wiki's `WIKILINK_RE` (`_wikilib.py`) matches only a bare, slash-free slug, so every reference link was **invisible** to the link graph — neither an inbound link (each cited source counted as an orphan: the literal 100% rate) nor a broken link. Reference backlinks are now **bare `[[<slug>]]`** (slugs are globally unique across the per-type dirs, so no path is needed), which registers the synthesis→source forward edge. A cited page **missing on disk** emits its reference row with **no** wikilink (a bare link to a missing page would be a `broken_wikilink` error that fails the new health gate). File: `skills/knowledge-finalize/SKILL.md`.
- **#308 — quoted `id:` on source pages.** `source-ingester` could emit `id: "<slug>"` (the json.dumps-quoting rule was ambiguous about `id:`); `_wikilib.parse_frontmatter` keeps the surrounding quotes on scalars, so the parsed id `'"<slug>"'` ≠ filename → `wiki-health` `id_mismatch` error. The frontmatter rule now makes `id:` an explicit exception — always emitted **unquoted** (the slug is always safe kebab-case). File: `agents/source-ingester.md`.
- **#308 — empty `tags: []` and stale `overview.md`.** Synthesis pages default to `tags: [synthesis]` and source pages to `tags: [source]`; `knowledge-finalize` refreshes `wiki/overview.md` with a `## Recent syntheses` bullet (deterministic, idempotent on slug) so the "state of the wiki" page no longer goes stale. Files: `skills/knowledge-finalize/SKILL.md`, `agents/source-ingester.md`.

### Added

- **#308 — conformance gate at the finalize tail (Step 10.5).** After the deposit + index + context-brief land, `knowledge-finalize` runs `lint_wiki.py --wiki-root … --fix=all` then `health.py --wiki-root …`. `--fix=reverse_link_missing` backfills the source→synthesis reverse `[[<synthesis>]]` edge (a `## See also` append on each cited source), de-orphaning the synthesis; `entries_count_drift` / `frontmatter_defaults` / `alphabetisation` reconcile the rest. The health pass asserts `data.errors == []` and surfaces any residual error **loudly and non-fatally** (the deposit already landed). `orphan_page` is not a `--fix` class — 0 orphans comes from the inbound links the bare refs + reverse-link backfill create. A generalized `resolve_wiki_scripts <skill>` pre-flight resolver now locates the `wiki-lint` and `wiki-health` script dirs alongside `wiki-ingest`. File: `skills/knowledge-finalize/SKILL.md`.
- **#308 — `knowledge-ingest` writes backlinks (de-orphans ingested sources).** Replaces the v0.0.20 audit-only path: after `backlink_audit.py … --top 8 --min-confidence medium`, the orchestrator curates a `targets[]` plan from the candidates (each `sentence` carries a bare `[[<slug>]]` trailer) and applies it via `backlink_audit.py … --apply-plan -` (idempotent, fail-soft per target). This gives ingested-but-never-cited sources an inbound link so they are not orphans. The script still never auto-selects targets. File: `skills/knowledge-ingest/SKILL.md`.
- **#307 — thematic index.** `knowledge-plan` now emits a `theme_label` per sub-question (LLM-authored alongside `query` / `search_guidance`, in `output_language`). `knowledge-ingest` files each source under its first-listed sub-question's `theme_label` (`--category "<theme_label>"`, joined via `sub_question_refs[0]` → `plan.json`; best-effort, since `candidate-store.py` unions refs existing-first), so `wiki/index.md` groups sources thematically instead of under one flat `## Sources`. Falls back to `"Sources"` for legacy plans without `theme_label`. The synthesis stays under `## Syntheses`. Files: `skills/knowledge-plan/SKILL.md`, `skills/knowledge-ingest/SKILL.md`, `references/inverted-pipeline.md`.

### Tests

- `tests/test_finalize_contract.sh` — bare `[[<slug>]]` reference construction + `assert_not_grep` on the old `link_dir + "/" + slug` prefix form; Step 10.5 gate (`lint_wiki.py`, `--fix=all`, `health.py`, `data.errors`); `overview.md` refresh; `tags: [synthesis]`; generalized resolver.
- `tests/test_ingest_contract.sh` — `--apply-plan` invoked (no "audit-only" wording); `--category "<theme_label>"` join (no hard-coded `"Sources"`-only); `tags: [source]` + unquoted `id:` on source-ingester.
- `tests/test_skill_contracts.sh` — audit-grep so the prefixed-link and audit-only patterns can't creep back; `theme_label` present in knowledge-plan's schema.

### Notes

- Ships on contract coverage, consistent with Slices 3–15. No schema bump (`plan.json` `theme_label` is additive — legacy plans `.get()` to the `"Sources"` fallback). The live `health=0 errors` / `lint=0 orphan_page` proof on a freshly finalized German base is #311's job.

## 0.1.6 — 2026-05-25

Slice 15 of the Phase 5 v0.1.x bake-in (**#264**) — two cost / wall-clock wins for the inverted pipeline. Maturity stays **Preview**. Closes **#299**, **#305**; epic **#264**.

### Changed

- **#299 — Phase 2 fans all sub-questions in one wave.** `knowledge-curate` Step 3 previously dispatched curators in waves of ≤3, so a 6-sub-question plan ran two sequential waves (~doubled fetch wall-clock now that each curator does its own WebFetch under Option B). It now emits **one assistant message containing all N `Task(source-curator, …)` calls** — the same single-message fan-out `knowledge-verify` already uses for its verifier shards. The plan cap bounds the wave: `knowledge-plan` hard-caps a plan at 3–7 sub-questions, so N ≤ 7 and one wave always covers the whole plan; peak concurrent web calls = N (each curator's WebSearch/WebFetch are sequential within itself), the scale the verifier fan-out already runs at M12-green. Batch merges (`candidate-store.py append-batch`, already `flock`-safe) now run after the wave. File: `skills/knowledge-curate/SKILL.md`.

### Fixed (performance)

- **#305 — Phase 6 verify is incremental and the revisor patches in place.** Three coupled changes cut the verify→revise loop's cost:
  - **Patch-in-place revisor.** The orchestrator pre-creates `draft-v{N+1}.md` as a verbatim `cp` of the verified draft, and `revisor` now `Edit`s only the changed sentences in place (gained `Edit` in its tools) instead of regenerating the whole ~5k-word draft. This keeps untouched sentences byte-identical across versions — the precondition that makes incremental re-verify sound — and stops a global rewrite from introducing fresh deviations in prose it was not asked to touch.
  - **Incremental re-verify.** `verify-store.py` gains `shard --only-ids`, `merge --manifest` (conservation against the current manifest id-set), and `merge --carry-forward-from` (fold untouched verdicts from the prior round). After a revisor round, `knowledge-verify` re-scores only `DELTA_IDS` (the citations the revisor rephrased/repointed) and carries the rest forward, so the verifier shards shrink to the touched-citation delta while the canonical `verify-vN.json` stays complete (`knowledge-finalize` reads `counts`).
  - **Deterministic substring pre-filter.** New `verify-store.py prefilter` classifies a citation `verbatim` without an LLM call when the manifest's `draft_sentence` contains the cited claim's `excerpt_quote` (fallback `text`) as an exact substring. It is **fail-safe** — a page it cannot parse, or a cross-language sentence, simply falls through to the LLM verifier; it never emits a deviation or a drop, so correctness is independent of the parser's completeness. Backed by a new narrow, stdlib-only `_knowledge_lib.parse_pre_extracted_claims()` (no PyYAML).
  - Files: `agents/revisor.md`, `skills/knowledge-verify/SKILL.md`, `scripts/verify-store.py`, `scripts/_knowledge_lib.py`.

### Tests

- `tests/test_verify_store.sh` — `shard --only-ids`; `prefilter` (match / cross-language no-match / unparseable-page fail-safe / no-deviation invariant); `merge --manifest` conservation (and why a non-manifest merge of prefilter+delta is rejected); `merge --carry-forward-from` (delta re-scored + untouched carried == manifest, empty-delta round, missing-`--manifest` and missing-prior-verdict rejections); reshard preserves the prefilter fragment.
- `tests/test_knowledge_lib.sh` — `parse_pre_extracted_claims()` units (block-list dicts incl. colon-bearing values; malformed / empty frontmatter → `[]`).
- `tests/test_verify_contract.sh` — revisor `Edit` tool + patch-in-place language (no whole-draft compose); knowledge-verify `cp` substrate, prefilter, `--only-ids`, `--carry-forward-from`, `DELTA_IDS`.
- `tests/test_skill_contracts.sh` — knowledge-curate one-wave fan-out assertion + `assert_not_grep '3 or fewer'`.

### Notes

- Ships on deterministic-gate + contract coverage, consistent with Slices 3–14. No schema bump. The live convergence re-run folds into the open #311 German bake-in.

### Review fixes

A multi-angle review of the prefilter surfaced several ways it could emit a wrong-too-strong `verbatim` (silently skipping verification) — the fail-safe guarantee did not actually hold. Hardened:

- **No false `verbatim` from a degenerate needle.** A YAML block-scalar value (`excerpt_quote: >` / `|`) was parsed as the bare indicator `>`/`|`, which substring-matches the `<sup>…</sup>` marker in every cited sentence. The parser now drops block-scalar headers (the field is simply absent), and the prefilter requires a **substantial** needle (`MIN_PREFILTER_NEEDLE_LEN = 24`) so short/coincidental matches (`"AI"`, stray punctuation) fall through to the LLM.
- **Draft-staleness guard.** The prefilter now reads the current draft (new `--draft`, threaded by `knowledge-verify`) and only asserts `verbatim` when the manifest `draft_sentence` is actually present in it — matching the `sentence_not_in_draft` check the wiki-verifier applies; it never auto-passes a stale sentence.
- **NFC normalization.** Both sides of the substring test are NFC-normalized, so genuinely-verbatim non-ASCII citations (German/French/Polish/… — the markets the plugin targets) are matched across NFC/NFD composition instead of silently missing.
- **Deterministic re-verify delta.** `DELTA_IDS` is now derived from a deterministic diff of a pre-revisor manifest **snapshot** vs the rewritten manifest, not the LLM revisor's self-reported `fixes_applied` — an under-report can no longer carry a stale verdict forward.
- **Stale-fragment cleanup.** `knowledge-verify` runs `shard` every round (even when nothing remains to score) so a numbered fragment left by an interrupted prior attempt at the same draft version cannot leak into the merge.
- **Robustness guards in `verify-store.py`:** `merge --manifest` rejects a manifest with null/duplicate ids (instead of a self-contradictory conservation error); `merge --carry-forward-from` rejects a prior file with duplicate ids (instead of silent last-write-wins); the prefilter treats a duplicate `claim_id` on one page as ambiguous and falls through. `_unquote_scalar` decodes double-quoted values via `json.loads` (the ingester's writer), handling escaped quotes / `\n` / `\uXXXX` correctly. The revisor's empty-deviations invariant was reworded for patch-in-place.

Follow-up review (PR #316) — one LOW + one NIT:

- **`verbatim` now means "is the quote", not "contains the quote".** The prefilter matched `excerpt_quote in draft_sentence`, so a sentence embedding the excerpt verbatim but adding an unsupported qualifier/negation ("…only after 2027", "Contrary to…") would auto-pass and skip the LLM that would flag it. The match now strips the inline `<sup>[N](url)</sup>` marker(s) (new `_knowledge_lib.strip_inline_citation_markers`) and requires the needle to cover ≥ `PREFILTER_COVERAGE_RATIO` (0.9) of the resulting sentence — a qualifier-wrapped excerpt drops below that and falls through to the LLM.
- **Per-round manifest snapshots are cleaned up.** `knowledge-verify` Step 4 now `rm -f`s the `.metadata/.citation-manifest.pre-r*.json` diff snapshots once the run is validated, instead of leaving them in `.metadata/`.
- Tests: `test_verify_store.sh` + `test_knowledge_lib.sh` gained cases for every guard above (block-scalar, short-needle, qualifier-wrapped, stale-sentence, NFC/NFD, duplicate-claim, duplicate-manifest-id, duplicate-carry-forward-id, inline-comment, column-0 bullets, marker-stripping); `test_verify_contract.sh` asserts the deterministic-diff DELTA, manifest snapshot, `--draft`, and always-run-shard wiring.

## 0.1.5 — 2026-05-25

Slice 14 of the Phase 5 v0.1.x bake-in (**#264**) — two pipeline state / config-robustness bugs from the first real DACH run. No schema bump, no script change (both fixes reuse existing helpers). Maturity stays **Preview**. Closes **#302**, **#304**; epic **#264**.

### Fixed

- **#302 — `knowledge-ingest` bumps `entries_count` for the source pages it writes.** Phase 4 wrote N `wiki/sources/<slug>.md` pages but only `knowledge-finalize` ever bumped `.cogni-wiki/config.json::entries_count` (+1 for the synthesis), so a 49-source base left the counter ~49 pages short and cogni-wiki's `wiki-health` / `wiki-resume` reported a standing `entries_count_drift`. Step 4 now counts source pages whose per-slug `wiki_index_update.py` returned `action: "inserted"` into `n_new` (skipping `"updated"` re-ingests and failed index updates), then calls `config_bump.py --key entries_count --delta <n_new>` **once** after the loop — the same Step 7→8 lockstep invariant `knowledge-finalize` already uses (counter and on-disk page count move together). A clean re-run skips already-ingested URLs at Step 1.3, so it reaches the bump with `n_new == 0` → no bump → no drift (re-run no-op). Non-fatal on failure (operator reconciles via `wiki-lint --fix=entries_count_drift`). Prose-only — `config_bump.py` already supports `--delta`. File: `skills/knowledge-ingest/SKILL.md`.
- **#304 — the market config is resolved once in the orchestrator, not N times per curator.** Each `source-curator` subagent re-resolved the market config via an env-gated glob (`${WORKSPACE_PLUGIN_ROOT:-$(ls -td …/cogni-workspace/*/)}`); `WORKSPACE_PLUGIN_ROOT` is usually unset in a subagent, so the resolution was flaky and one shard (sq-05 in the DACH run) silently fell back to `_default` while siblings loaded DACH — N independent, non-deterministic resolutions, and a wrong authority list silently degrades that shard's scoring. `knowledge-curate` now resolves the config **once** in Step 0 (three-layer locate of `get-market-config.py`, mirroring the script's own `_resolve_sibling_plugin`), validates it, writes the verbatim envelope to `<project>/.metadata/market-config.json`, and threads `MARKET_CONFIG_PATH` to every curator. **Fails loudly on a `_default` resolution:** because the cogni-research overlay carries a `_default` entry, an unknown/unsupported market returns `success: true` with the `_default` config (no `data.code`), so a bare `success` check is insufficient — the orchestrator aborts when `data.code` is absent. `source-curator` Phase 0 now reads the resolved file (parsing the envelope's `data` field — also correcting the stale `data.config` reference) and treats a missing/unreadable config as a **hard error** (`{"ok": false, … "reason": "market_config_unavailable"}`) recorded in `failed_curators[]`, never a silent `_default`. Files: `skills/knowledge-curate/SKILL.md`, `agents/source-curator.md`.

### Tests

- `tests/test_ingest_contract.sh` — asserts Step 4 calls `config_bump.py` with `--delta`/`entries_count`, gates the bump on `action == "inserted"` (lockstep), counts into `n_new`, and states the re-run no-op (#302).
- `tests/test_skill_contracts.sh` — curate block asserts the once-resolution (`get-market-config.py` + `market-config.json` + `MARKET_CONFIG_PATH=` dispatch); curator block reconciled to the new contract (reads `MARKET_CONFIG_PATH`, missing config is a `hard error`) with an `assert_not_grep` guarding the old env-gated `ls -td …/cogni-workspace` glob from creeping back into the agent (#304).

### Contract docs

- `references/inverted-pipeline.md` — Phase 4 now documents the `config_bump.py --delta <n_new>` lockstep bump; Phase 2 documents the orchestrator's once-resolution + loud `_default` abort + `MARKET_CONFIG_PATH` threading.
- `README.md` — the cogni-workspace dependency note no longer says the `source-curator` agent calls `get-market-config.py` at runtime or that a missing config silently falls back to the unlocalized default; it now reflects that `knowledge-curate` resolves the config once and fails loudly (#304). `knowledge-curate`'s `--dry-run` now explicitly stops before the curator dispatch so the not-written `market-config.json` is never referenced.

### Review fixes (PR #314)

- **Gate tightened to `data.code == <market>`.** The `_default` detection now requires the resolved `data.code` to equal the *requested* market (not merely a non-empty `code`), confirming the config is for the right market, not merely *a* market. Strictly stronger; all supported markets echo their own code (`dach`→`dach`, `eu`→`eu`).
- **Contract test for the fail-loudly gate.** `test_skill_contracts.sh` now asserts the gate keys on `data.code` and carries the `Abort unless` instruction, so a future edit can't silently drop the gate and reintroduce the `_default` degrade — the subtlest, most regression-prone line in the slice.
- **Orchestrator write-verification.** `knowledge-curate` Step 0 now confirms `market-config.json` exists and is non-empty after writing; a write failure aborts cleanly rather than surfacing as N confusing per-curator `market_config_unavailable` failures.
- **doc-audit / Dependencies note.** Confirmed the README Dependencies section is hand-authored narrative (no auto-gen sentinels; doc-generate preserves hand-written content), so the cogni-workspace note edit is not at risk of being clobbered.

### Version

- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — `0.1.4` → `0.1.5` (mirrored). Maturity stays `preview`.

## 0.1.4 — 2026-05-25

Slice 13 of the Phase 5 v0.1.x bake-in (**#264**) — the first real DACH run ("Lean Canvas für Insight-Wave", market `dach`, German output) surfaced three German / localized-output bugs, fixed here in foundational order (**#303 → #301 → #300**). The enabling fact: `output_language` was already captured in `plan.json` (schema 0.1.0) but never threaded into the composer or read by finalize — this slice closes that gap with no new config and no schema bump. Maturity stays **Preview**. Closes **#303**, **#301**, **#300**; epic **#264**.

### Fixed

- **#303 — `slugify` transliterates instead of dropping non-ASCII.** `_knowledge_lib.slugify` lowercased then stripped every non-`[a-z0-9]` run, so `für` → `f-r` and `Geschäftsidee` → `gesch-ftsidee`. It now applies a German transliteration pass (`ä→ae`, `ö→oe`, `ü→ue`, `ß→ss`) — the German convention NFKD alone does not give — then NFKD + combining-mark removal to de-accent the remaining Latin scripts (`Café`→`cafe`). `für insight-wave` → `fuer-insight-wave`. Single source of truth, so both callers (`knowledge-ingest` source slugs, `knowledge-finalize` synthesis slug) inherit the fix with no edit; the empty/non-alnum → `""` fallback contract is preserved. Added `import unicodedata` (stdlib). File: `scripts/_knowledge_lib.py`.
- **#301 — `knowledge-finalize` reference handling is language-aware.** Finalize stripped the composer's reference section with a hardcoded English `## References` regex and re-emitted a hardcoded English heading — so a German draft's `## Referenzen` slipped through and finalize appended a *second* (English) list. It now reads `plan.json::output_language`, derives the heading from the new `_knowledge_lib.ref_heading()` map (`de→Referenzen`, default/unknown → English), strips **language-independently** (localized heading + English, with a safety-net that strips a trailing pure-citation H2 under an unrecognized synonym), and re-emits one localized list. The deposited list is numbered `**[N]**` in citation-manifest first-appearance order — matching the composer's inline `[N]` (which finalize leaves in the body verbatim) — and each entry carries the source URL (`[URL](URL)`) plus the `[[sources/<slug>]]` backlink. File: `skills/knowledge-finalize/SKILL.md`.

### Changed

- **#300 — `wiki-composer` emits clickable numbered citations.** Adopting the cogni-research `writer` convention: inline citations are now numbered `[N]` (default IEEE `<sup>[N](url)</sup>`, linking to the source page's `sources:` URL), numbered in first-appearance order and reused on re-cite; **never `[[N]]`** (Obsidian wikilink collision). `[[sources/<slug>]]` / `[[syntheses/<slug>]]` wikilinks move into the reference list **only**, so the cogni-wiki backlink graph survives without polluting prose. The agent gained `OUTPUT_LANGUAGE` (honoured for body, section headings, and the localized reference heading) and an optional `CITATION_FORMAT`; the hardcoded "Output language is English" / "Section headings in English" mandates are removed. `knowledge-compose` threads `OUTPUT_LANGUAGE=<plan.json::output_language>` into the `Task(wiki-composer, …)` dispatch. **Verify→revise loop kept whole (two-part follow-through):** (1) `wiki-verifier` is unaffected — it scores the manifest's verbatim `draft_sentence`, which now records the `[N]` markers as written. (2) `revisor` *was* affected and is updated: it edits the numbered `<sup>[N](url)</sup>` inline shape (not the retired inline `[[sources/<slug>]]`) in the draft's `OUTPUT_LANGUAGE`, and its citation-integrity guard counts inline numbered markers instead of inline wikilinks (the old guard would have failed `write_failed` on every numbered draft). It does **not** renumber on drop. (3) `knowledge-finalize` gains a ~6-line, URL-keyed renumber pass that rewrites the deposited body's inline `[N]` to match the re-derived, contiguous reference list — so finalize is authoritative for numbering and a revisor full-source-drop (which would otherwise leave a body/list gap) is normalized at deposit. Files: `agents/wiki-composer.md`, `skills/knowledge-compose/SKILL.md`, `agents/revisor.md`, `skills/knowledge-finalize/SKILL.md`.

### Tests

- `tests/test_knowledge_lib.sh` — new `slugify` + `ref_heading` unit assertions (`für insight-wave`→`fuer-insight-wave`, `Geschäftsidee`, `Über`/`Öl`/`Maß`, NFKD `Café`→`cafe`, empty/non-alnum→`""`, max-len truncation; `ref_heading("de")`/`("en")`/unknown→`References`).
- `tests/test_finalize_contract.sh` — asserts finalize reads `output_language`, derives the heading via `ref_heading`, and strips language-independently (`strip_words`, `LANGUAGE-INDEPENDENT`) rather than English-only.
- `tests/test_compose_contract.sh` — `OUTPUT_LANGUAGE` + `CITATION_FORMAT` flipped from forbidden to **required** parameter rows (`PROSE_DENSITY`/`EXPANSION_NOTES`/`STORY_ARC_ID` stay deferred); asserts the numbered-`[N]` first-appearance convention, the `[[N]]` prohibition, wikilinks-in-reference-list-only, and that `knowledge-compose` threads `OUTPUT_LANGUAGE`.
- `tests/test_verify_contract.sh` — asserts the revisor operates on the numbered `<sup>[N](url)</sup>` shape, edits in `OUTPUT_LANGUAGE`, and dropped the stale "keep the inline `[[sources/…]]` wikilink" instruction.
- Full suite green (20 files).

### Review fixes (multi-angle code review of the slice)

- **slugify robustness (#303 follow-ups).** (1) NFC-compose before transliterating, so NFD-form input (decomposed umlaut, common from macOS/web sources) slugifies identically to NFC — previously `NFD('für')`→`fur`, silently defeating the fix. (2) Lowercase **after** NFKD, so compatibility decompositions that emit uppercase ASCII (`№`→`No`, `™`→`TM`) are folded, not dropped by the keep-regex. (3) Added Polish `ł→l` to the manual map (`ł` has no NFKD decomposition and was being dropped — PL is a supported market). `ref_heading()` now `str()`-coerces its argument so a non-str `output_language` defaults to English instead of crashing on `.lower()`. New unit cases in `test_knowledge_lib.sh`.
- **`knowledge-finalize` strip/renumber hardening (#301/#300 follow-ups).** (1) The reference-section strip regex is anchored `(?:\A|\n)…(?:\n|\Z)`, so a reference heading that is the first/last line of the body is matched — the strip-miss otherwise re-introduced the duplicate-reference-section (#301) bug. (2) The safety-net (unrecognized-heading fallback) now strips a trailing H2 **only when every line is a genuine reference entry** (`[[sources/`/`[[syntheses/`/`**[N]**`), so a trailing Recommendations/Conclusions bullet list is no longer silently deleted. (3) The inline-marker renumber now remaps by the **marker number** (ascending = first-appearance = `cited_slugs` order) instead of by URL — robust to two slugs sharing a URL, to URL normalization drift, and to synthesis markers (no URL), which a URL-keyed pass mishandled.
- **Contract de-drift.** `wiki-composer`: synthesis citations are explicitly `<sup>[N]</sup>` (never a bare `[N]`, which the revisor's integrity guard would reject); the stale failure-mode line that still described an inline `[[sources/<slug>]]` is rewritten to the `[N]` shape; `CITATION_FORMAT` is documented as IEEE-only (the APA branch was unwired in `knowledge-compose` and structurally incompatible with finalize's numbered list).
- **Citation-link robustness (round 2).** Source URLs containing parentheses (e.g. a Wikipedia `..._(disambiguation)` URL) broke the markdown citation link — renderers (Obsidian included) truncate the destination at the first `)`. `knowledge-finalize` now angle-brackets such destinations (`[URL](<url>)` via `md_link_dest`) and `wiki-composer` is instructed to do the same inline and in the reference list. `first_url`'s regex-fallback no longer rstrips a whole `"']` charset (which could eat a URL ending in `]`) — it strips trailing quotes and at most one leaked list-closer. `wiki-verifier.md` prose de-drifted to the numbered-`[N]` shape (retired "adjacent wikilinks" wording + brittle `:96` line-refs); the composer's reference-format example drops the unsourced `Year` field (no source page carries one).
- **Executable coverage for the finalize subprocess (round 3, PR review item A).** The most regression-prone logic in the `knowledge-finalize` heredoc — `first_url`, `md_link_dest`, the language-independent reference-section strip, and the inline `[N]` renumber — was **extracted into `scripts/_knowledge_lib.py`** (`first_url` / `md_link_dest` / `strip_reference_section` / `renumber_inline_citations`), beside `slugify`/`ref_heading`, and is now **unit-tested** in `test_knowledge_lib.sh` rather than only grep-asserted. New cases cover the full-source-drop renumber (`[1][3]`→`[1][2]`), the safety-net preserving a trailing non-reference bullet section, #301 non-recurrence on a first-line heading, and paren-URL angle-bracketing. The SKILL now imports and calls these helpers; a dead `url_by_slug` (left over once the renumber stopped keying on URL) was removed. No behaviour change — the deposited-page output is byte-identical.

### Migration

- **Pre-v0.1.4 non-ASCII synthesis slugs.** Because `slugify` now transliterates (e.g. `Geschäftsidee`→`geschaeftsidee` instead of the old `gesch-ftsidee`), a project finalized **before** v0.1.4 from a non-ASCII (German/Polish/…) topic has its synthesis page at the **old** slug. Re-finalizing that project under v0.1.4 derives the new slug, so finalize's collision check at the new path misses the old page and would deposit a **second** synthesis instead of overwriting. If you have such pages: pass `--synthesis-slug <old-slug>` to keep the original, or delete/rename the stale page first. New in-repo bases are unaffected (no pre-v0.1.4 non-ASCII deposits exist). The same slug shift applies to `knowledge-ingest` source-page slugs derived from non-ASCII titles — a re-ingest creates a new page rather than updating the old one.

### Version

- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — `0.1.3` → `0.1.4` (mirrored). Maturity stays `preview`.

## 0.1.3 — 2026-05-25

Fixes the default knowledge-base location (**#296**). `knowledge-setup` defaulted `--knowledge-root` to `<cwd>/<knowledge-slug>/`, which in a multi-plugin workspace drops the base at the repo root instead of under the plugin namespace — breaking the monorepo's `cogni-{plugin}/{project-slug}/` convention and diverging from its only dependency, `cogni-wiki:wiki-setup`, which already defaults to `cogni-wiki/{slug}`. The default now resolves to `cogni-knowledge/<knowledge-slug>/` (relative to cwd). The `--knowledge-root` override is unchanged. Clean change, no legacy fallback — appropriate for a Preview plugin with no in-repo base relying on the old default. Migration: a knowledge base created before 0.1.3 at the old `<cwd>/<slug>/` default needs an explicit `--knowledge-root <path>` on subsequent `knowledge-*` calls, since the new default resolves to `cogni-knowledge/<slug>/`. Maturity stays **Preview**. Closes **#296**; epic **#264**.

### Fixed

- **Default knowledge-root now follows the cogni-plugin convention.** The default resolves to `cogni-knowledge/<knowledge-slug>/` instead of `<cwd>/<knowledge-slug>/`, mirroring `cogni-wiki:wiki-setup`'s `cogni-wiki/{slug}` default. The resolution lives entirely in skill prose (the LLM passes an already-resolved `--knowledge-root` to `knowledge-binding.py init`; the script never computes the default), so this is a prose-only change with no script or test edit. `knowledge-setup` Step 1 is the canonical resolver and now carries the convention note; the five sibling skills that restate the formula (`knowledge-plan` / `knowledge-resume` / `knowledge-query` / `knowledge-dashboard` / `knowledge-refresh`) were updated in lockstep, and the six pipeline skills that delegate via "same logic as <prev>" inherit it. The bound wiki nests correctly with no extra change — Step 3 passes `--wiki-root <knowledge_root>` and the binding's `--wiki-path` is `<knowledge_root>`. Files: `skills/{knowledge-setup,knowledge-plan,knowledge-resume,knowledge-query,knowledge-dashboard,knowledge-refresh}/SKILL.md`, `CLAUDE.md`.

### Version

- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — `0.1.2` → `0.1.3` (mirrored). Maturity stays `preview`.

## 0.1.2 — 2026-05-25

Follow-up from the PR #290 review (**#291**) — guards `knowledge-verify` against a citation-manifest written before v0.0.28. F22 (v0.0.28) made `id` + `draft_sentence` required per citation but kept the additive `schema_version: "0.1.0"`, so a manifest from a ≤0.0.27 composer still declares `0.1.0` while carrying neither field. Run against such a mid-upgrade draft, the verifier would mass-drop every citation as `sentence_not_in_draft` and merge could trip its duplicate-id check on the `None` ids. Now it fails loud and early with a "re-run knowledge-compose" message. Plus secondary housekeeping. Maturity stays **Preview**. Closes **#291**; epic **#264**.

### Fixed

- **Pre-0.0.28 citation-manifest guard (two layers).** (1) Deterministic backstop: `verify-store.py` `_load_manifest()` now rejects any `citations[]` entry missing `id`/`draft_sentence` with `…predates v0.0.28; re-run knowledge-compose` (exit 1, standard JSON envelope). `_load_manifest` is the single chokepoint `cmd_shard` calls before any verifier dispatch and before merge, so it covers both failure modes. (2) Friendly early abort: `knowledge-verify` Step 2's inline manifest check fails the same way before the shard runs, so the orchestrated flow surfaces the cause first. Files: `scripts/verify-store.py`, `skills/knowledge-verify/SKILL.md`.

### Housekeeping

- **verify-shards sweep.** `knowledge-finalize` gains a best-effort Step 9.5 that `rm -rf`s `<project>/.metadata/verify-shards/` after the synthesis is deposited — the canonical `verify-vN.json` is already merged and finalize never reads the shards. Never blocks finalize. File: `skills/knowledge-finalize/SKILL.md`.
- **`.gitignore`.** Added `**/.metadata/` so a knowledge/portfolio project created outside the in-repo `/.alpha/` base does not leave per-user, regenerable pipeline intermediates (verify-shards, manifests, scan-output) in `git status`. Does not untrack the already-tracked, separately-ignored `cogni-portfolio-evals/**/.metadata/` fixtures. File: `.gitignore`.

### Tests

- `tests/test_verify_store.sh` — new shard-reject case 5e: a schema-valid manifest whose citation omits `id`/`draft_sentence` is rejected with `v0.0.28` in `error`.
- `tests/test_verify_contract.sh` — asserts Step 2 of `knowledge-verify` carries the `predates v0.0.28` guard (regression anchor for the friendly-abort layer).

### Version

- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — `0.1.1` → `0.1.2` (mirrored). Maturity stays `preview`.

## 0.1.1 — 2026-05-24

M12 minor follow-ups (**#289**) — the three lowest-severity findings from the M12 alpha gate, all non-blocking polish — plus a companion fix to the same lexical-version bug class in cogni-workspace. No pipeline behaviour change beyond helper-script version resolution. Maturity stays **Preview**. Closes **#289**; epic **#264**.

### Fixed

- **F24 — citation-count drift.** One draft was reported with five different counts across surfaces (composer return / manifest / verify-v1 / verify-v2 / `pipeline-summary`). Pinned the authoritative count to `len(citation-manifest.json::citations)` for the latest draft version (already surfaced by `pipeline-summary.py project`): `wiki-composer` now returns the exact manifest-array length (never an estimate); `knowledge-compose` logs/summary use the script-derived count; `knowledge-verify` relabels its per-round verdict tally as verdicts-scored-for-draft-vN and surfaces the authoritative manifest count plus the pruned-stale count. Pin documented in `CLAUDE.md` §Conventions. No standalone-script (`.py`) change — `pipeline-summary.py` already exposes the canonical surface and `verify-store.py` already enforces conservation; the only code touched is `knowledge-verify`'s inline Step-4 validation snippet, which now reads the manifest length unconditionally and emits it alongside `counts`. Files: `agents/wiki-composer.md`, `skills/knowledge-compose/SKILL.md`, `skills/knowledge-verify/SKILL.md`, `CLAUDE.md`.
- **F25 — normative-text source preference.** `source-curator` (Phase 1 + Phase 3 Authority) and `knowledge-plan` (§2 `candidate_domains`) now prefer canonical article-page domains (e.g. `artificialintelligenceact.eu`) over legal-database landing/ELI URLs (e.g. `eur-lex.europa.eu/eli/...`) for the actual text of a law — ELI endpoints can resolve to the wrong document or return only a WebFetch summary. Guidance-only; no data-file or `candidate-store.py` change. Files: `agents/source-curator.md`, `skills/knowledge-plan/SKILL.md`.
- **F26 — version-aware helper-script resolution.** `resolve_wiki_ingest_scripts()` (in `knowledge-ingest` + `knowledge-finalize`) now picks the newest cached cogni-wiki version via `sort -V` instead of the lexically-first glob match (which selected `0.0.16` over the installed `0.0.45` on multi-version dev caches). `probe_plugin()` stays existence-only (unchanged). New regression test `tests/test_resolve_wiki_scripts.sh`. Files: `skills/knowledge-ingest/SKILL.md`, `skills/knowledge-finalize/SKILL.md`, `tests/test_resolve_wiki_scripts.sh`.

### Companion (cogni-workspace v0.6.31)

- `scripts/discover-plugins.sh` dedup-by-name now compares a parsed version tuple instead of a string (`'0.0.9' > '0.0.45'` in string order — the same bug class as F26). `'unknown'`/non-numeric segments sort lowest. Bumped cogni-workspace `0.6.30` → `0.6.31` (mirrored in `marketplace.json`).

### Version

- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — `0.1.0` → `0.1.1` (mirrored). Maturity stays `preview`.

## 0.1.0 — 2026-05-24

Phase 5 complete — the M12 alpha gate re-ran **GREEN** (C1–C5 all pass) on a fresh cold `.alpha/` base, so cogni-knowledge graduates **Incubating → Preview**. Full scorecard in `references/alpha-findings.md` §"M12 alpha re-run #2 (2026-05-24)". Closes **#287**, **#288**; ticks epic **#264** Phase 5.

### Changed

- Version `0.0.29` → `0.1.0` in `plugin.json` + root `marketplace.json` (mirrored); `binding.json` `SCHEMA_VERSION` → `0.1.0` (M12 re-alignment, no field change). README maturity callout flipped **Incubating → Preview**.

### Notes

- Backfilled entry: the v0.1.0 landing shipped without its own changelog stanza. Details of record live in `references/alpha-findings.md` §"M12 alpha re-run #2".

## 0.0.29 — 2026-05-24

Slice 11 of the absorption-roadmap Current sprint — Phase 5. Parallelizes the inverted-pipeline fetch so the M12 gate re-run isn't bottlenecked on a strictly-sequential Phase-3 batch loop. The partial M12 re-run was paused because `source-fetcher` ran one batch at a time (~4–12 min each; one read a 164-page PDF), making the fetch the dominant pipeline wall-clock. This release folds the body fetch into the already-parallel Phase-2 curators (Option B) and shrinks Phase 3 to an opt-in cobrowse fallback. It does **not** re-run the gate or flip maturity — that is the next landing. Maturity stays `incubating`. Closes **#292**; epic **#264**.

### Changed

- **Option B (#292) — fetch rides the parallel curators.** The WebFetch body-pull + PDF branch (former `source-fetcher` Steps 1/2/4: `_knowledge_lib.is_pdf_response`, the 20-page `Read`-loop, the 200-page cap, `fetch-cache.py store`, and the negative-cache write) moved into `source-curator`'s new **Phase 4**. The curators already fan out per sub-question (≤ 3 concurrent), so the fetch wall-clock collapses to the slowest curator wave instead of the sum of all sequential batches. `source-curator` gained `WebFetch` in its `tools:` (no cobrowse tools — it never cobrowses). Files: `agents/source-curator.md`, `skills/knowledge-curate/SKILL.md`.
- **`candidates.json` entries carry a `fetch` sub-object.** `{status, cache_key, content_hash, fetch_method, fetched_at, from_cache}` on `ok` (+ `pdf_pages_read`/`pdf_truncated` for PDFs); `{status: unavailable, reason, fallback_attempted, cobrowse_eligible}` on a WebFetch miss. `cobrowse_eligible` is `true` for the `webfetch_*` reasons (Phase 3 can retry them) and `false` for `pdf_extraction_failed` (terminal — cobrowse can't render PDF text). Schema stays `0.1.0` (additive). `candidate-store.py` `_validate_candidate` accepts it and `_merge_entry` prefers the `fetch.status == "ok"` side on a cross-SQ dedup so a good body is never discarded.
- **`source-fetcher` shrank to cobrowse-only.** `WebFetch` dropped from its `tools:` (the PDF `Read`-loop moved to the curator); keeps `Read` (for the candidates.json `publisher` lookup), `Bash`, and the `claude-in-chrome` MCP tools. Step 1 cache-lookup now short-circuits only on a positive `ok` hit (a prior cobrowse rescue) — a negative entry does not short-circuit, since cobrowse is the explicit retry. Files: `agents/source-fetcher.md`.
- **`knowledge-fetch` is now a cobrowse reconcile with an opt-in gate.** It builds `fetch-manifest.json` directly from the curators' `fetch` sub-objects (no agent dispatch for the WebFetch results). Cobrowse recovery of WebFetch misses is **opt-in**: a new `--cobrowse` flag, or an interactive `AskUserQuestion` when cobrowse-eligible misses exist; `--no-cobrowse` forces off; **default OFF** so the M12 gate re-run and `knowledge-refresh --mode push` stay deterministic and browser-free. When opted in, it mirrors cogni-claims to walk the user through enabling the Claude-in-Chrome **extension** (probe `mcp__claude-in-chrome__tabs_context_mcp`; `claude-in-chrome` is not an `install-mcp` server), then dispatches `source-fetcher` (cobrowse-only) sequentially and merges rescues. `--batch-size` is vestigial; `--tier` now scopes the cobrowse-retry set (the curator's `max_candidates_per_sq` bounds fetch cost). Files: `skills/knowledge-fetch/SKILL.md`.
- **C1 pass criterion reworded.** Because the fetch now runs inside the per-SQ curators (before the merge), two same-wave curators can each WebFetch a shared cross-SQ URL; the content-addressed cache collapses both writes to one entry. C1 is now "exactly one cache entry per distinct normalized URL (`fetch-cache.py stat` entries == distinct URLs)" — which still holds — rather than the literal "0 duplicate fetches". Same-wave double-fetch is an accepted, bounded cost. Files: `references/absorption-roadmap.md`.
- Docs: `references/inverted-pipeline.md` (Phase 2 + Phase 3 contracts rewritten; candidates.json gains `fetch{}`; phase table), `references/fetch-cache-design.md` (curator is now the primary cache writer), `references/absorption-roadmap.md` (Slice 11 SHIPPED, M12 row, C1 reword, Phase-5 header), `CLAUDE.md` (curate/fetch skill rows + source-curator/source-fetcher agent rows + Future-phases narrative), `README.md` (What it does / Components).
- Tests: `tests/test_skill_contracts.sh` (curator `tools:` now includes `WebFetch`; source-fetcher no longer asserts `WebFetch`; curator forwards `KNOWLEDGE_ROOT`/`MAX_AGE_DAYS` + calls `fetch-cache.py`; knowledge-fetch `--cobrowse` opt-in + `tabs_context_mcp` probe), `tests/test_ingest_contract.sh` (PDF assertions moved from `source-fetcher` to `source-curator`), `tests/test_candidate_store.sh` (an `ok` fetch wins a cross-SQ dedup collision).
- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — version `0.0.28` → `0.0.29` (mirrored). Maturity stays `incubating`.

### Notes

- **The M12 gate is NOT re-run by this release**, and the v0.1.0 + Preview maturity flip remains a separate, later landing — only after a fresh `.alpha/` gate re-run is clean.
- Cobrowse stays opt-in by design: autonomous runs (the gate re-run, push-mode refresh) never open a browser, so they remain reproducible.

## 0.0.28 — 2026-05-23

Slice 10 of the absorption-roadmap Current sprint — Phase 5 M12 gate blockers. The first full live M12 alpha gate (run 2026-05-23) was **HELD** on C3 (verify wall-clock ~16–18 min/pass at 169 citations ≫ 5 min) and C4 (verify→revise doesn't converge within the 2-round cap), both tracing to one root cause (F20): composer, verifier, and revisor each independently re-tokenize the draft into `section:sentence` positions and drift by one on EU-AI-Act prose. This release clears the three blockers. It does **not** re-run the gate or flip maturity — that is the next landing, gated on a green re-run. Maturity stays `incubating`. Closes **#286** (F21), **#287** (F22), **#288** (F23); epic **#264**.

### Added

- `scripts/verify-store.py` — Phase 6 fan-out plumbing. `shard` splits a citation manifest's `citations[]` into ⌈N/size⌉ per-shard manifests under `<project>/.metadata/verify-shards/` (each a valid citation-manifest scoped to a subset); `merge` concatenates the per-shard `wiki-verifier` fragments into the canonical `verify-vN.json`, recomputes `counts`, and enforces `counts.total == verified+deviations`. Stdlib-only, JSON envelope, `atomic_write`. **No `fcntl.flock`** (unlike `candidate-store.py`) — shards are partition-disjoint and `merge` is single-shot, so there is no shared-write contention to guard.
- `tests/test_verify_store.sh` — shard/merge smoke (split shape, subset validity + exact union, single-shard case, merge recount, idempotent re-shard, malformed-input rejection).

### Changed

- **F22 (#287) — stable carried citation positions.** Each `citation-manifest.json` entry gains a stable `id` (`cit-001`, …) and `draft_sentence` (the cited sentence copied verbatim). The verifier now scores `draft_sentence` **directly** against the cited claim and never re-tokenizes the draft to locate it — dissolving the off-by-one that drove C4. `draft_position` is demoted to a best-effort operator locator (no longer load-bearing). `id` is the universal join key: the verifier echoes it into every `verified[]`/`deviations[]` entry, the orchestrator's inline prune keys on it, and the revisor maps deviations back by it. The verifier's `draft_position_out_of_range` reason becomes `sentence_not_in_draft` (a substring staleness check). Schema stays `0.1.0` (additive). Files: `agents/wiki-composer.md`, `agents/wiki-verifier.md`, `agents/revisor.md`, `skills/knowledge-verify/SKILL.md`, `references/inverted-pipeline.md`. The F20 sentence-tokenizer rewrite is therefore **not** done — `draft_sentence` makes it non-load-bearing.
- **F21 (#286) — fan out the verifier.** `knowledge-verify` Step 3.1 is now shard → dispatch N `wiki-verifier` in parallel (one assistant message) → merge, via `verify-store.py`. `wiki-verifier` gains two optional, fully backward-compatible params — `CITATIONS_PATH` (read a shard subset) and `VERIFY_OUT_PATH` (write a per-shard fragment); omitting both is today's single-dispatch behaviour. New `--shard-size` skill param (default 40 → 169 citations ≈ 5 parallel shards). The orchestrator asserts `shards_merged == shard_count` so a crashed shard can't ship partial verification. C3 is re-baselined as per-shard wall-clock. Files: `scripts/verify-store.py`, `agents/wiki-verifier.md`, `skills/knowledge-verify/SKILL.md`, `references/inverted-pipeline.md`.
- **F23 (#288) — revisor re-points before dropping.** `agents/revisor.md` now exhausts on-page re-pointing first (scan all `pre_extracted_claims` on the cited page for a covering claim, rephrase + repoint `claim_id`); **drop is the last resort** (only `page_not_found` or no on-page cover). `fixes_summary` gains a `repoint` count (and `fixes_applied[].action` gains `"repoint"`) so the metric distinguishes re-alignment from evidence erosion. The revisor locates sentences by exact-string-search of `draft_sentence` (F22) and preserves each entry's `id`.
- `tests/test_verify_contract.sh` + `tests/test_compose_contract.sh` — updated for `id`/`draft_sentence`, the `sentence_not_in_draft` reason, the `verify-store.py` shard/merge + `CITATIONS_PATH`/`VERIFY_OUT_PATH` fan-out, prune-by-id, and the revisor `repoint`.
- Docs: `README.md` (DOES scripts list + Components rows + Architecture script count 5→6), `CLAUDE.md` (wiki-verifier / revisor / knowledge-verify rows + `verify-store.py` in the Scripts table + Future-phases narrative), `references/absorption-roadmap.md` (Slice 10 SHIPPED + Slice 9 lookahead), `references/alpha-findings.md` (F21/F22/F23 marked fixed-pending-gate-rerun).
- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — version `0.0.27` → `0.0.28` (mirrored). Maturity stays `incubating`.

### Notes

- **The M12 gate is NOT re-run by this release**, and the v0.1.0 + Preview maturity flip is deliberately a separate, later landing — only after a fresh `.alpha/` gate re-run shows C3 (per-shard verify < 5 min) and C4 (verify→revise converges; `drop` falls, `repoint` rises) green. We don't cross the 0.1.0 stability boundary speculatively.
- **#289 (F24–F26)** — citation-count drift, EUR-Lex curation, helper-script version resolution — stays out of this slice.
- The deterministic substring pre-filter named "complementary" in #286 stays a documented future option; fan-out alone is projected to clear C3.

## 0.0.27 — 2026-05-23

Slice 8 of the absorption-roadmap Current sprint — Phase 5 M11. Archives the legacy v0.0.x research+report chain so the v0.1.0 inverted pipeline is the only live path, and bakes a permanent audit-grep so the chain can't creep back. Establishes the monorepo `_archive/` convention. Maturity stays `incubating` (the v0.1.0 / Preview flip is M12).

### Changed

- **Archived to `_archive/`** (via `git mv`, history preserved): `skills/knowledge-research/` + `skills/knowledge-report/` (the last runtime reachers of cogni-research), their two private helper scripts `scripts/lineage-stamp.py` + `scripts/read-project-config.py`, and `tests/test_read_project_config_bare.sh`. The two SKILL.md files gain `archived: true` frontmatter. New `_archive/README.md` documents what was retired, what replaced it, and the convention. `_archive/` sits at the plugin root (not `skills/_archive/`) so skill discovery and the live `tests/test_*.sh` glob never pick it up.
- `skills/knowledge-setup/SKILL.md` — dropped the `probe_plugin cogni-research research-setup` line and the "requires both `cogni-wiki` and `cogni-research`" abort wording (it only ever dispatched `cogni-wiki:wiki-setup`); rerouted its description, next-action, and out-of-scope prose to the inverted pipeline. Now probes cogni-wiki only.
- Legacy-skill prose scrubbed from `knowledge-query`, `knowledge-dashboard`, `knowledge-resume` (incl. its routing description), `knowledge-plan`, and one `knowledge-finalize` line; `references/fetch-cache-design.md` updated. No runtime behaviour change — these were prose/discovery surfaces.
- `tests/test_knowledge_setup_probe.sh` — rewritten to the post-M11 invariant: every live gating skill (setup/query/dashboard/resume/refresh) probes cogni-wiki only; the both-probe block and synthetic cogni-research assertions are gone.
- `tests/test_skill_contracts.sh` — **new permanent audit-grep**: `skills/`, `scripts/`, and `agents/` must contain zero `knowledge-research` / `knowledge-report` references. Fails any future PR that re-introduces the legacy chain into the live surface.
- Docs rewritten so the inverted pipeline is the only live path: `README.md` (What it is / What it does / How it works / Components / Architecture / Dependencies), `CLAUDE.md` (header, skills + scripts tables, lineage-stamping section, delegation bullets, future phases), `references/delegation-contract.md` (intro, hard rule, "What about `agents/`?" rewritten to the seven local agents, report_source wiring, delegation-table note), `references/absorption-roadmap.md` (M11 row → shipped at v0.0.27; Slice 8 SHIPPED + Slice 9 lookahead; Phase-5 status header).
- `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` — version `0.0.26` → `0.0.27` (mirrored).
- `cogni-claims/CLAUDE.md` — one-line lost-caller note: cogni-knowledge's v0.1.0 pipeline runs its own zero-network `knowledge-verify` instead of submitting to cogni-claims (per absorption-roadmap cross-plugin coordination).
- **CHANGELOG backfill** — added the missing `0.0.25` (M10a) and `0.0.26` (M10b) entries below, which shipped together in PR #283 but were never recorded.

### Notes

- **No backwards-compat shim** for the archived `knowledge-research` / `knowledge-report` slugs — `/cogni-knowledge:knowledge-research` now returns "skill not found". Accepted cost while incubating (per `references/absorption-roadmap.md` "Out of scope for v0.1.0").
- **cogni-wiki untouched.** `cogni-wiki/CLAUDE.md` + `wiki-from-research/SKILL.md` still name `knowledge-report` to describe their `--allow-wiki-source` contract surface, which any caller can use; not in M11 scope.

## 0.0.26 — 2026-05-23

Slice 7 — Phase 5 M10b. `knowledge-refresh --mode push` rewritten onto the seven-phase inverted pipeline; paired with cogni-wiki v0.0.45's log-enum cleanup. (Recorded retroactively at M11 — shipped in PR #283 alongside M10a.)

### Changed

- `skills/knowledge-refresh/SKILL.md` — push-mode now runs the inverted pipeline (`knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`) per selected stale topic, with uniform `--knowledge-slug` / `--project-path` / `--knowledge-root` dispatch, fail-soft per topic (`{topic, failed_phase, error}` capture), idempotent resume (plan aborts-on-existing; downstream phases dedup/skip by construction), and cycle-guard delegated to finalize. Removed the legacy `knowledge-research` + `wiki-refresh`-pair dispatch and the cogni-research pre-flight probe (clean break); pull-mode unchanged.
- `references/delegation-contract.md` — §"Phase-3 push-refresh behaviour" rewritten; the legacy "What about agents/?" section banner-flagged as superseded.
- `tests/test_skill_contracts.sh` + `tests/test_knowledge_setup_probe.sh` — updated for the refresh probe split.

### Added

- `tests/test_refresh_push_chain.sh` — asserts the seven-phase dispatch order, fail-soft capture, and the clean-break invariant (no `knowledge-research` / `wiki-refresh` dispatch in push-mode).

### Notes

- **Paired with cogni-wiki v0.0.45**, which appended `compose` / `verify` / `finalize` to the `wiki/log.md` operation enum (additive, no `schema_version` bump). Live push-mode smoke deferred to M12 (budget too large for CI; the contract is grep-checkable).

## 0.0.25 — 2026-05-23

Slice 6 — Phase 5 M10a. The read-side trio now surfaces inverted-pipeline state and drops cogni-research from its pre-flight. (Recorded retroactively at M11 — shipped in PR #283.)

### Added

- `scripts/pipeline-summary.py` — read-only summaries for the read-side skills. `project --project-path` returns per-project counts from the six `.metadata/` manifests (sub-questions, candidates, fetched/unavailable, ingested/skipped, citations, latest-`verify-vN` verdict counts, `phase_reached`), degrading to zeros + `phase_reached: "none"` on a legacy v0.0.x deposit; `cache-health --knowledge-root` joins `fetch-cache.py stat` with `binding.curator_defaults.fetch_cache_max_age_days` to emit a knowledge-base-global `{entries, negative_ratio, oldest_age_days, max_age_days, verdict}`.
- `tests/test_pipeline_summary.sh` — 8 fixture-driven assertions.

### Changed

- `skills/knowledge-query/SKILL.md` — footer gains a fetch-cache health clause via `pipeline-summary.py cache-health`.
- `skills/knowledge-dashboard/SKILL.md` — overlay gains per-project inverted-pipeline columns + a knowledge-base-global `## Pipeline health` block.
- `skills/knowledge-resume/SKILL.md` — gains per-project pipeline depth + a Pipeline status line.
- **All three drop their cogni-research pre-flight probe to cogni-wiki-only** — the clean-break invariant now holds for the read surface, ahead of M11's archive.
- `tests/test_skill_contracts.sh` — extended with the read-side probe-drop + pipeline-summary-wiring block.

## 0.0.24 — 2026-05-22

Slice 5 of the absorption-roadmap Current sprint — Phase 5 M9. Lands the Phase-7 finalize step of the v0.1.0 inverted pipeline (`plan → curate → fetch → ingest → compose → verify → **finalize**`): the latest verified `draft-vN.md` + `verify-vN.json` + `citation-manifest.json` are now deposited as `<wiki>/syntheses/<synthesis-slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + an auto-generated `## References` list. The inverted-pipeline loop closes here — future `knowledge-compose` runs read the new synthesis pages as prior cross-source framing, which is the compounding property the differentiation thesis hinges on.

### Added

- `skills/knowledge-finalize/SKILL.md` — Phase-7 orchestrator. Reads `binding.json` for `WIKI_ROOT`, resolves the latest `draft-v*.md`, confirms a matching `verify-v*.json` exists with `schema_version: 0.1.0`, surfaces `counts.unsupported` as a non-blocking warning, derives the synthesis slug from `plan.json::topic` via `_knowledge_lib.slugify` (with `--synthesis-slug` override and `--overwrite` opt-in for re-deposit), runs `cycle-guard.py --report-source wiki` to refuse self-citing loops, composes the synthesis page (frontmatter + verified draft body verbatim + auto-generated `## References` section pulled from each cited source page's title + publisher), writes it atomically via `_knowledge_lib.atomic_write_text`, runs three cogni-wiki helpers at script level (`wiki_index_update.py --category "Syntheses"`, `config_bump.py --key entries_count --delta 1`, `rebuild_context_brief.py`), appends to `binding.json::research_projects[]` via `knowledge-binding.py append-project --report-source wiki`, and writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`. `allowed-tools: Read, Write, Bash` — no `Task` (no agent dispatch). M9 part 1/2.
- `tests/test_finalize_contract.sh` — grep-based contract assertions matching `tests/test_verify_contract.sh` (the M8 precedent). Covers the new SKILL's input/output paths, synthesis-frontmatter shape (`type: synthesis`, `derived_from_research`, `draft_revision_round`), three cogni-wiki helper calls at script level, binding-append dispatch, the `## [DATE] finalize | project=...` log-line shape, the clean-break invariants (no `Skill("cogni-research:` / `Skill("cogni-claims:` / `Skill("cogni-wiki:` dispatch), and that `allowed-tools` does NOT include `Task` (no agents in M9). **Plus** an inline `cycle-guard.py` fixture test: builds a synthetic v0.1.0 project with `.metadata/citation-manifest.json` + one wiki-slug entry; asserts exit 0 + `data.input_shape == "citation-manifest"` for the clear case, exit 1 + `status: cycle_detected` for the self-citing case. M9 part 2/2.

### Changed

- `scripts/cycle-guard.py` — strict additive fallback (~25 lines). When `<project>/02-sources/data/src-*.md` returns zero files, read `<project>/.metadata/citation-manifest.json` and treat each `citations[].wiki_slug` as a cited page id. New envelope field `data.input_shape ∈ {"legacy-source-entities", "citation-manifest", "none"}` signals which path ran. Direct-cycle detection works identically on both shapes (the `derived_from_research:` frontmatter lookup downstream is shape-agnostic); transitive recursion walks each hop's local shape independently so mixed-shape bindings (some v0.0.x projects, some v0.1.0 projects) coexist cleanly. Docstring updated to document the fallback. The five existing `tests/test_cycle_guard_*.sh` tests exercise the legacy path and still pass unchanged.
- `tests/fixtures/_cycle_guard_lib.sh` — two new helpers (`mk_v01_project`, `add_manifest_citation`) used by `test_finalize_contract.sh` to build v0.1.0 project fixtures. The existing legacy helpers are unchanged.
- `tests/test_skill_contracts.sh` — clean-break invariant loop extended to scan `knowledge-finalize/SKILL.md` for `Skill("cogni-{research,claims,wiki}:` dispatch (same shape as the M8 extension).
- `.claude-plugin/plugin.json` — version `0.0.23` → `0.0.24`. **Plus two paired doc-audit drift fixes the user pre-approved while the file was open:** Check 3 — `description` rewritten to drop "Thin orchestrator over cogni-research and cogni-wiki; no forked agents, no duplicated scripts" (the v0.1.0 clean break forks 4 agents — `source-curator`, `claim-extractor`, `wiki-composer`, `revisor` — adds 3 new agents — `source-fetcher`, `source-ingester`, `wiki-verifier` — and adds 3 scripts — `fetch-cache.py`, `candidate-store.py`, `_knowledge_lib.py`; the v0.0.x "thin orchestrator" framing was true at the start of Phase 5 but is false today) and replaced with a sentence naming the inverted pipeline. Check 5 — `"agents"` added to `keywords[]`.
- `.claude-plugin/marketplace.json` — `cogni-knowledge` version `0.0.23` → `0.0.24`; `description` + `keywords[]` mirrored byte-for-byte from `plugin.json` (the two must stay aligned per `feedback_marketplace_versions.md`).
- `CLAUDE.md` — Skills table gains a `knowledge-finalize` row. Scripts table's `cycle-guard.py` row rewritten to document both citation input shapes (`legacy-source-entities` / `citation-manifest`) and the `data.input_shape` envelope field. Architecture-section opening sentence updated to drop the "no forked agents, no duplicated scripts" language (parallel to the plugin.json description rewrite). "Inverted-pipeline progress" trailing paragraph records M9 shipped at v0.0.24; next slice is M10.
- `references/absorption-roadmap.md` — M-table row 9 status `pending — reuses existing cycle-guard.py` → `shipped at v0.0.24 — Slice 5 (cycle-guard adapted; legacy shape still supported)`. Phase-5 Status header bumped from `M1–M8 shipped … plugin at v0.0.23` to `M1–M9 shipped … plugin at v0.0.24`. Current-sprint block records Slice 5 SHIPPED with the full slice rationale (the scope deviation from the M-table's "as-is" framing, the contract widening to include `wiki_index_update.py`, the doc-audit drift fixes paired into the version bump) and advances the lookahead to Slice 6 (M10 — manifest-aware rebuild of query / dashboard / resume / refresh).
- `references/inverted-pipeline.md` — Phase 7 prose extended to name the three cogni-wiki helpers (`wiki_index_update.py` + `config_bump.py` + `rebuild_context_brief.py`) and to document the v0.0.24 `cycle-guard.py` citation-manifest fallback. "See also" line — `{config_bump,rebuild_context_brief}.py` → `{wiki_index_update,config_bump,rebuild_context_brief}.py` with one sentence noting why `wiki_index_update.py` joined the trio.
- `README.md` — Components table gains a `knowledge-finalize` row. "What it does" numbered list gains one new bullet between current items 7 (verify) and 8 (legacy research) for the finalize step.

### Notes

- **Cycle-guard adapter is a minor additive extension, not a redesign.** Legacy `02-sources/data/src-*.md` wins when the glob is non-empty (preserves existing semantics on mixed-shape projects); the manifest fallback fires only when the glob is empty. The five existing `test_cycle_guard_*.sh` tests assert the legacy path is intact (all five pass unchanged at v0.0.24).
- **Transitive cycle detection on the new manifest shape stays direct-only at v0.0.24.** The DFS at depth > 0 recurses into other `binding.research_projects[]` projects by calling `_walk_project_citations(other_project_path, wiki_slug)` — if that hop is itself v0.1.0, the fallback fires for that hop too. So mixed-shape bindings work. The new `input_shape` field is recorded only for the candidate (depth 0); per-hop shapes are not aggregated in this slice. Transitive-on-manifest specifically can land later if M12 alpha surfaces a real failure case.
- **`wiki_index_update.py` joined the Phase-7 helper trio vs the original `inverted-pipeline.md` Phase 7 line 170 contract.** Rationale: without it the new synthesis page never lands in `wiki/index.md` (the catalog), so it's not discoverable to future readers. `wiki-query --file-back` (`cogni-wiki/skills/wiki-query/SKILL.md:85-91`) and `knowledge-ingest` both call `wiki_index_update.py` for their new pages. The contract doc is updated in the same PR to match; the user pre-approved the widening via AskUserQuestion.
- **Doc-audit Check 3 / Check 5 drift fixes paired into the version bump** rather than split into a separate doc-only PR. The drift fixes are one-line edits adjacent to the version bump in the same JSON files, and the description rewrite reflects the same v0.1.0 reality M5–M8 + M9 collectively land. Check 8 (`docs/plugin-guide/cogni-knowledge.md` MISSING) stays open — `doc-hub` / cogni-docs territory, deferred to a separate doc-only sweep per user direction.
- **`finalize` log prefix is additive.** cogni-wiki's `wiki/log.md` operation enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") doesn't list `finalize` today (same posture as M7's `compose` and M8's `verify`), but pre-v0.0.35 readers count unknown prefixes in their catch-all bucket without crashing. Formalising all three additive prefixes into the cogni-wiki enum lands in M10 when query / dashboard rebuild on the new manifests anyway.
- **No `lineage-stamp.py` dispatch in M9.** That helper walks `raw/research-<slug>/` (the v0.0.x deposit shape) — v0.1.0 projects don't write to it. The `derived_from_research:` field on the synthesis page is set inline in Step 5's frontmatter compose. `lineage-stamp.py` stays in the plugin for the legacy `knowledge-research` / `knowledge-report` paths until M11 archives them.
- **No `topic_lineage.covered_themes[]` updates in M9.** That field is reserved for M10's manifest-aware dashboard rebuild — the read shape (which themes are covered) follows naturally from `plan.json::sub_questions[]` + the `wiki/syntheses/*.md` deposits, and the writer (where to record it) lands in M10's `knowledge-dashboard` rewrite.
- **End-to-end smoke is M12's job.** This release ships contract-test coverage of the new SKILL + the cycle-guard adapter. Semantic correctness of the full Phase 1→7 chain gets exercised on the alpha re-run at M12 against `eu-ai-act-v0.1`.

### Dependencies

No new minimum-version requirements. cogni-wiki ≥ 0.0.44 (the `type: source` allowlist) from v0.0.20 still holds. The Phase-7 synthesis page uses `type: synthesis` which has been allowlisted in cogni-wiki since v0.0.23.

### Post-review hardening (same v0.0.24, pre-merge)

A multi-angle code review surfaced 15 findings. All landed in the same v0.0.24 release before merge:

- **E1 / `wiki://` URL shape.** The synthesis page's `sources:` frontmatter now emits bare `wiki://<cited-slug>` per `cogni-wiki/skills/wiki-health/scripts/health.py:206`, not the composite `wiki://<wiki_slug>/<cited-slug>` that would have tripped `broken_wiki_source` on every cited entry on the next health run.
- **E3 / double `## References`.** `wiki-composer` already writes a `## References` H2 at the end of the draft (per its agent contract). Step 5 now matches a trailing `\n## References` regex and strips the composer's tail before composing its own richer References list (with publisher annotations).
- **E2 / synthesis-page citation handling.** Step 5 now tries `wiki/syntheses/<slug>.md` as a fallback when the cited page isn't under `wiki/sources/`, tracks `page_kind_by_slug`, and emits `[[syntheses/<slug>]]` vs `[[sources/<slug>]]` to match the cited page's actual directory.
- **Manifest swallow → hard error.** `scripts/cycle-guard.py` now defines `ManifestUnreadableError`, raises it on `json.JSONDecodeError` / `OSError` from the citation-manifest read, and `main()` catches and emits `status: manifest_unreadable` + exit 1. Previously a corrupt manifest silently returned `status: clear` — the exact failure mode the guard exists to prevent.
- **Step 7 → Step 8 gating + `--overwrite` skip.** Step 8 (`config_bump.py --delta 1`) now requires `INDEX_OK=yes` from Step 7 AND `SYNTHESIS_EXISTED_PRE=no`. Previous behavior bumped `entries_count` on every Step 7 failure (drift) and on every `--overwrite` re-deposit (permanent +1 per overwrite).
- **`--overwrite` binding update.** `scripts/knowledge-binding.py append-project` gained a `--allow-update` flag — on duplicate `research_slug`, the existing entry is updated in place (preserving array order, refreshing `report_path` / `deposited_at`). Step 9 passes the flag when `--overwrite` is in effect. Without the flag, duplicate-slug still aborts (existing semantics preserved).
- **Log-line CR/LF sanitization.** Step 10 now uses `printf '%s\n'` (not `echo`) and pre-strips `\r` / `\n` from TOPIC via `tr` so an operator-supplied multi-line topic cannot break `wiki/log.md`'s one-line-per-event invariant.
- **UTC date alignment.** Step 5 now stamps `created:` / `updated:` from `_dt.datetime.now(_dt.timezone.utc).date()` so the synthesis-page frontmatter agrees with Step 10's `date -u +%F` log stamp across midnight.
- **Frontmatter parser hardening.** Step 5's inline frontmatter parser now (a) skips indented lines so nested `pre_extracted_claims:` keys don't overwrite top-level `title:` / `publisher:`, (b) tolerates the no-trailing-newline case via `(?:\r?\n|\Z)`, (c) strips ASCII single-quote `'` alongside ASCII double + curly variants. Same regex tolerance landed in `cycle-guard.py::_FRONTMATTER_RE`.
- **Empty `sources:` shape.** When `citation-manifest.json::citations[]` is empty, frontmatter now emits inline `sources: []` (matching the `tags: []` shape) rather than the block-style `sources:\n  []` continuation that strict YAML parsers misread.
- **`input_shapes` per-hop tracking.** `cycle-guard.py`'s envelope now carries `input_shapes: [{slug, shape}, ...]` ordered by DFS depth, so mixed-shape transitive walks (some hops legacy, some hops citation-manifest) are observable rather than collapsed to the depth-0 shape. The singular `input_shape` field is retained for back-compat.
- **Test asserts replaced with `sys.exit`.** `tests/test_finalize_contract.sh`'s inline `python3 -c` verification blocks now use `if not X: sys.exit(...)` instead of `assert`; under `python3 -O` (where `assert` is stripped), the tests would have passed vacuously on broken output.
- **`CITATION_COUNT` computed in Step 3.** The dry-run printout block now has an explicit subprocess to read `len(manifest.citations)`; previously the SKILL named the field but no step computed it.
- New contract-test assertions cover each of the above fixes; new inline cycle-guard fixture in `test_finalize_contract.sh` exercises the corrupt-manifest case (exit 1 + `status: manifest_unreadable`).

## 0.0.23 — 2026-05-22

Slice 4 of the absorption-roadmap Current sprint — Phase 5 M8. Lands the Phase-6 verify step of the v0.1.0 inverted pipeline (`plan → curate → fetch → ingest → compose → **verify** → finalize`): the citation manifest M7 emits is now consumed by a zero-network claim-alignment pass against each cited page's `pre_extracted_claims:` frontmatter. The structural cost win versus cogni-claims (20–30 min verify → < 5 min) lands here — no WebFetch, no re-extraction, no claims.json store.

### Added

- `agents/wiki-verifier.md` — NEW agent (no upstream). Phase-6 zero-network claim verifier. Reads `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json` + each cited `wiki/sources/<slug>.md`'s `pre_extracted_claims:` frontmatter, scores every citation as `verbatim` / `paraphrase` / `unsupported` (plus the informational `synthesis` verdict for `claim_id: null` wikilinks to synthesis pages — never triggers the revisor), and writes `<project>/.metadata/verify-vN.json` schema `0.1.0`. Single-pass, tools: `["Read", "Write", "Glob", "Grep"]` — no `WebFetch`/`WebSearch`/`Task`. Excerpt matching uses `text` + `excerpt_quote`; `excerpt_position` offsets stay as the M9+ context-rendering primitive. M8 part 1/3.
- `agents/revisor.md` — point-in-time fork of `cogni-research/agents/revisor.md` (288 lines) at v0.0.23. Phase-6 corrective revisor. Reshapes inputs (a `verify-vN.json::deviations[]` list, not a cogni-claims verdict chain) and outputs (`draft-v{N+1}.md` + rewritten `citation-manifest.json` with `draft_version: N+1`, not a structural-review verdict). Strategy: rephrase the draft sentence to align with an existing claim on the cited page, OR drop the citation and rewrite the sentence as non-evidence-based. Tools: `["Read", "Write", "Glob", "Grep"]` — dropped `WebSearch`/`WebFetch`/`Bash` (zero-network corrective revision; corrections come from claims already on the wiki, never new fetches). Drops the upstream expansion-mode branch (`citation_density{}`, `cross_references_emitted`, placed-evidence ledger, density self-check), the Source-Mode Evidence Gathering helper (irrelevant on a wiki-only pipeline), the arc-preservation discipline, oscillation detection (no verdict chain), and the confidence-assessment table (no new evidence to confidence-rate) — all deferred per `references/absorption-roadmap.md` Slice 4 notes. Cross-page substitute-citation search is also deferred. M8 part 2/3.
- `skills/knowledge-verify/SKILL.md` — Phase-6 orchestrator. Reads `binding.json` for `WIKI_ROOT`, confirms `citation-manifest.json::draft_version` matches the latest `output/draft-v*.md`, dispatches `wiki-verifier` once per round via `Task`, inspects `verify-vN.json::deviations[]` for `verdict: "unsupported"`, dispatches `revisor` via `Task` if non-empty AND `revision_round < 2` (the Phase 6 contract's max-2-iterations cap), loops back through the verifier on the new draft version, and terminates when deviations are empty OR `revision_round == 2`. Verifies all artefacts on disk via one Python subprocess (env-var paths, matches M7's pattern; `counts.total == verified+deviations` is the audit hook). Appends one `## [YYYY-MM-DD] verify | …` line to `<wiki-root>/wiki/log.md`. `allowed-tools: Read, Write, Bash, Task`. M8 part 3/3.
- `tests/test_verify_contract.sh` — grep-based contract assertions matching `tests/test_compose_contract.sh`. Covers the verifier's input/output paths, the 3-verdict vocabulary (`verbatim`/`paraphrase`/`unsupported`) plus the informational `synthesis` verdict, the revisor fork's lineage declaration, the zero-network frontmatter-tools constraints (verifier and revisor MUST NOT include `WebFetch`/`WebSearch`/`Task`; revisor also drops `Bash`), the max-2-iterations cap in the skill, scope-discipline negatives in the revisor fork (no `OUTPUT_LANGUAGE` / `MARKET` / `STORY_ARC_ID` / `PROSE_DENSITY` / `VERDICT_PATH` parameter rows; the HTML-comment provenance is exempted via the `awk` body-only filter the compose test established).

### Changed

- `tests/test_skill_contracts.sh` — clean-break invariant loop extended to scan `wiki-verifier.md` + `revisor.md` + `knowledge-verify/SKILL.md` alongside the M5/M6/M7 surface for `Skill("cogni-{research,claims,wiki}:` dispatch.
- `CLAUDE.md` — Skills table gains `knowledge-verify`; Agents table gains `wiki-verifier` + `revisor`. "Inverted-pipeline progress" paragraph records M8 shipped at v0.0.23; next slice is M9.
- `references/absorption-roadmap.md` — M-table row 8 status `pending` → `shipped at v0.0.23 — Slice 4`. Phase-5 Status header bumped from `M1–M7 shipped … plugin at v0.0.22` to `M1–M8 shipped … plugin at v0.0.23`. Current-sprint block records Slice 4 SHIPPED and advances the lookahead to Slice 5 (M9 — `knowledge-finalize`).

### Notes

- **English-only in v0.0.23.** Multilingual verification (DE/FR/IT/PL/NL/ES) is deferred. The upstream revisor carries ~270 lines of language-aware revision rules; revisit when a user asks. Source-language quotes are quoted verbatim inside English narrative as M7 ships them.
- **Strict paraphrase scoring.** Adding a quantifier (`mostly`, `largely`) or shifting scope (`EU-wide` vs. `Germany`) is **not** a paraphrase — that's `unsupported`. The revisor needs the strict signal to do its job. Verbatim is acceptable but flagged so the dashboard can surface copy-paste vs. synthesis ratios.
- **Excerpt match by text, not by offset.** M5/M6 froze `excerpt_position` as the indexing primitive for M9+ context rendering; verdict scoring at M8 uses `text` + `excerpt_quote` only.
- **Revisor strategy: rephrase or drop.** Cross-page substitute-citation search ("find another page that supports this statement") is deferred — that needs a vector-similarity-ish pass the LLM doesn't get for free. Revisit if M12 alpha demands it.
- **Loop versioning.** Each verifier round writes `verify-v{N}.json` keyed to the current draft version. Each revisor pass produces `draft-v{N+1}.md` AND rewrites `citation-manifest.json` in place (with `draft_version: N+1` inside) — single manifest per project, latest-draft-keyed, matching M7's intent. Audit trail lives in the `verify-v*.json` series.
- **`verify` log prefix is additive.** cogni-wiki's `wiki/log.md` operation enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") doesn't list `verify` today (same posture as M7's `compose`), but pre-v0.0.35 readers count unknown prefixes in their catch-all bucket without crashing. Formalising both prefixes lands in Slice 5/M9 when the dashboard gets rebuilt on the new manifests.
- **End-to-end smoke is M12's job.** This release ships contract-test coverage of the three new files. Semantic correctness of the full verifier-revisor loop gets exercised on the alpha re-run at M12 against `eu-ai-act-v0.1`.

### Dependencies

No new minimum-version requirements. cogni-wiki ≥ 0.0.44 (the `type: source` allowlist) from v0.0.20 still holds.

## 0.0.22 — 2026-05-22

Slice 3 of the absorption-roadmap Current sprint — Phase 5 M7. Lands the Phase-5 compose step of the v0.1.0 inverted pipeline (`plan → curate → fetch → ingest → **compose** → verify → finalize`): with the wiki populated by M5/M6, the writer now reads `wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md` and emits `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json` with `[[sources/<slug>]]` wikilink citations. M8's verifier consumes the citation manifest's `(wiki_slug, claim_id)` pairs against each page's `pre_extracted_claims:` frontmatter for zero-network claim alignment.

### Added

- `agents/wiki-composer.md` — point-in-time fork of `cogni-research/agents/writer.md` (305 lines) at v0.0.22. Phase-5 composer for the inverted pipeline. Reshapes inputs (wiki pages, not aggregated-context.json + 01-contexts/ + 02-sources/) and outputs (single `[[sources/<slug>]]` citation shape + parallel citation manifest, not the upstream APA/MLA/IEEE matrix). Single-pass, no fan-out, no Task in tools list. Preserves the F11 outline-recovery contract: Phase 1 persists `writer-outline-vN.json` before Phase 2 attempts to write the draft; `RESUME_FROM_OUTLINE=true` skips Phase 1 on a recovery dispatch. Drops the upstream story-arc shape, executive density mode, multilingual output, expansion loops, and per-section sharding — all deferred per the Slice 3 notes in `references/absorption-roadmap.md`. M7 part 1/2.
- `skills/knowledge-compose/SKILL.md` — Phase-5 orchestrator. Reads `binding.json` for `WIKI_ROOT`, confirms `plan.json` + `ingest-manifest.json` exist, resolves the next draft version N from existing `output/draft-v*.md`, detects a leftover `writer-outline-vN.json` and passes `RESUME_FROM_OUTLINE=true` on recovery, dispatches `wiki-composer` once via `Task`, verifies both outputs land on disk (draft non-empty + contains `[[sources/`; citation-manifest parses with schema `0.1.0` + non-empty `citations[]` carrying `{draft_position, wiki_slug, claim_id}`), and appends one `## [YYYY-MM-DD] compose | …` line to `<wiki-root>/wiki/log.md`. M7 part 2/2.
- `tests/test_compose_contract.sh` — grep-based contract assertions matching `tests/test_ingest_contract.sh`. Covers the composer's input/output paths, the F11 surface (outline persistence + `RESUME_FROM_OUTLINE` honoured), the citation-manifest entry shape, the frontmatter-tools constraints (`Read`/`Write`/`Glob`/`Grep` only — no `Task`, no `WebFetch`), and the scope-discipline negatives (no `OUTPUT_LANGUAGE` / `PROSE_DENSITY` / `CITATION_FORMAT` / `EXPANSION_NOTES` / `STORY_ARC_ID` parameter rows; Phase 0 doesn't read `aggregated-context.json`).

### Changed

- `tests/test_skill_contracts.sh` — clean-break invariant loop extended to scan `wiki-composer.md` + `knowledge-compose/SKILL.md` alongside the M5/M6 surface for `Skill("cogni-{research,claims,wiki}:` dispatch.
- `CLAUDE.md` — Skills table gains `knowledge-compose`; Agents table gains `wiki-composer`. "Future phases" paragraph records M7 shipped at v0.0.22; next slice is M8.
- `references/absorption-roadmap.md` — M-table row 7 status `pending` → `shipped at v0.0.22 — Slice 3`. Current-sprint block records Slice 3 SHIPPED and advances the lookahead to Slice 4 (M8 — wiki-verifier + revisor fork + knowledge-verify).

### Notes

- **English-only in v0.0.22.** Multilingual output (DE/FR/IT/PL/NL/ES) is deferred. The upstream writer carries ~270 lines of language-aware output rules; revisit when a user asks. Source-language quotes are quoted verbatim inside English narrative.
- **Standard density only.** `PROSE_DENSITY` and the executive ceiling-mode inversion stay upstream-only. This is an orthogonal knob — it can land later without touching M7's contract.
- **No story arcs.** Implicit `standard-research`. The arc-driven outline shape and the `arc_element` field are not emitted.
- **Single writer pass.** No Phase 4.5 whole-draft expansion re-dispatch, no Phase 5 word-deficit iteration loop. `target_words` is read as a soft target; the orchestrator does not re-dispatch on shortfall. Composition over a bounded ingested-wiki corpus (~10–40 source pages typical) is inherently shorter than upstream's 45K-word aggregated-context inputs, so a single call usually clears the soft target. If M12 alpha surfaces a real shortfall pattern, port the expansion chain then.
- **Wikilink citations only.** The composer emits `[[sources/<slug>]]` inline. URL/APA/MLA/IEEE rendering is the renderer's job at finalize time (M9). Cleaner separation than upstream's six-format citation matrix.
- **`compose` log prefix is additive.** cogni-wiki's `wiki/log.md` operation enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") doesn't list `compose` today, but pre-v0.0.35 readers count unknown prefixes in their catch-all bucket without crashing. Formalising the prefix lands in Slice 4 / M10 when query/dashboard get rebuilt on the new manifests anyway.
- **End-to-end smoke is M12's job.** This release ships contract-test coverage of the new files. Semantic correctness of the full pipeline (including M7) gets exercised on the alpha re-run at M12 against `eu-ai-act-v0.1`.

### Dependencies

No new minimum-version requirements. cogni-wiki ≥ 0.0.44 (the `type: source` allowlist) from v0.0.20 still holds.

## 0.0.21 — 2026-05-21

`source-fetcher` Step 2 PDF branch now reads PDFs past page 20. Resolves F18 from the v0.0.20 M5+M6 smoke (issue #278). Single-file behaviour change in the agent contract plus a contract-test assertion; no script or schema changes.

### Changed

- `agents/source-fetcher.md` — Step 2 PDF branch loops `Read` over the saved PDF in 20-page windows (`"1-20"`, `"21-40"`, `"41-60"`, …) until either an empty page range is returned (end of PDF) or a 200-page hard cap fires (cost guard — Read transcribes PDFs via vision-rendered images, scaling linearly with pages). Concatenates per-window text into one body before `fetch-cache.py store`. The per-batch `fetched[]` entry now records `pdf_pages_read: <N>` so the orchestrator and a future operator can see exactly how much of the PDF landed; `pdf_truncated: true` is reserved for the 200-page hard-cap case. Phase 2 batch-output example extended to show the PDF row shape. Pre-v0.0.21 behaviour silently lost 60%+ of EUR-Lex consolidated annexes, EP think-tank ATAGs, and 30+ page arxiv papers; `claim-extractor` could not reach claims past page 20.
- `tests/test_ingest_contract.sh` — adds `assert_grep 'pdf_pages_read' "$FETCHER" ...` alongside the existing `pdf_truncated` assertion. Both tokens are now greppable: `pdf_pages_read` for the normal-loop case, `pdf_truncated` for the hard-cap case.

### Notes

- **Per-batch sink, not cache-entry schema.** Issue #278's acceptance criterion #2 originally proposed `pdf_pages_read` in the cache entry. This release surfaces the field in the agent-emitted per-batch `fetched[]` instead, keeping `fetch-cache.py`'s persisted schema frozen — strictly within the issue's "single agent file edit + test extension" scope.
- **No re-fetch of existing cache.** The EP ATAG PDF in `.alpha/eu-ai-act-gpai/`'s cache was captured at 1-2 pages pre-fix during the M5+M6 smoke. A re-fetch under the new loop is a manual smoke step (`fetch-cache.py evict` then re-run `source-fetcher`); not part of this release.

## 0.0.20 — 2026-05-21

Slice 2 of the absorption-roadmap Current sprint — Phase 5 M5 + M6. Lands the Phase-4 ingest step of the v0.1.0 inverted pipeline (`plan → curate → fetch → **ingest** → compose → verify → finalize`): claim extraction now happens at ingest time (per `references/claim-at-ingest.md`), populating each `wiki/sources/<slug>.md` page's `pre_extracted_claims:` frontmatter so future verification at draft time becomes a zero-network string match. Bundles two Slice-1 follow-up issues: #275 (PDF detection in source-fetcher, via shared `_knowledge_lib.is_pdf_response`) and #276 (`cobrowse_unavailable` reason promoted to documented vocabulary). Closes #275 Closes #276.

### Added

- `agents/claim-extractor.md` — point-in-time fork of `cogni-research/agents/claim-extractor.md` (blob `d76af91795` at fork time). Phase 4 extractor for the inverted pipeline. Reshapes input: reads a cached source body via `BODY_FILE` (not a draft); reshapes output: returns a JSON array of `{id, text, excerpt_quote, excerpt_position, sub_question_refs, extracted_at}` via the Task envelope (not via cogni-research entity creates). `excerpt_position` is a Python `str.find()` Unicode code-point offset, frozen at ingest per `references/claim-at-ingest.md:57`. Read-only tools (no Write, no WebFetch, no entity creates). M5 part 1/2.
- `agents/source-ingester.md` — NEW agent (no upstream). Phase 4 per-fetched-source emitter. Reads cached body via `fetch-cache.py fetch`, dispatches `claim-extractor` over it, writes `<wiki>/sources/<slug>.md` atomically via `_knowledge_lib.atomic_write_text` with `type: source` + populated `pre_extracted_claims:` frontmatter. Never re-fetches; never highlights the body (the `excerpt_position` offset is the indexing primitive). Emits a per-source JSON envelope the orchestrator merges into `ingest-manifest.json`. M5 part 2/2.
- `skills/knowledge-ingest/SKILL.md` — Phase 4 orchestrator. Reads `<project>/.metadata/fetch-manifest.json`, **resolves the final slug for every entry up-front** (single source of truth; the ingester only sanity-checks the regex), filters out URLs already in `ingest-manifest.json::ingested[]` (no-op re-run contract), and dispatches `source-ingester` per fetched source in batches of 8 — parallel within batch, sequential merge of per-source batch JSONs between batches. Merges per-source results into `<project>/.metadata/ingest-manifest.json` schema `0.1.0` (one atomic write per batch, not per source). After all ingesters return, calls cogni-wiki's `backlink_audit.py` (audit-only at v0.0.20 — `--apply-plan` deferred) and `wiki_index_update.py` (`--category Sources`) directly at script level per new slug — **NOT** via the upstream `cogni-wiki:wiki-ingest` skill (clean-break). Appends one `## [YYYY-MM-DD] ingest | …` line to `<wiki-root>/wiki/log.md`. M6.
- `scripts/_knowledge_lib.py` gains three helpers: `is_pdf_response(content_type, url)` (shared PDF detection — used by source-fetcher Step 2 PDF branch and as a sanity gate inside source-ingester); `atomic_write_text(path, text)` (markdown sibling of `atomic_write`; both wrap a shared `_atomic_write_via` core, preserving the three-way function-identity invariant verified by `tests/test_knowledge_lib.sh`); `slugify(text, max_len=80)` (canonical lower-kebab + dash-collapse + length-cap — single source of truth for wiki page slugs; lifted out of inline SKILL prose so `knowledge-ingest` calls a function instead of describing the algorithm). Stdlib only.
- `scripts/fetch-cache.py` gains `VALID_REASONS` (closed-vocabulary constant for the `webfetch_error_class` enum — eight tokens including `pdf_extraction_failed` and `cobrowse_unavailable`) and wires `--reason` to validate against it at parse time. Typos like `cobrowse_unavail` now fail with `"--reason 'cobrowse_unavail' is not in the closed vocabulary [...]; see references/fetch-cache-design.md §'Reason semantics'"` instead of silently writing a junk reason into the cache. `references/fetch-cache-design.md` §"Reason semantics" and `agents/source-fetcher.md` both now reflect the constant rather than define it independently.
- `tests/test_ingest_contract.sh` — grep-based contract assertions for the three new files plus the source-fetcher additions and the new `_knowledge_lib` helpers. Includes a behavioural Python pass over `is_pdf_response` (Content-Type + .pdf suffix detection) and `atomic_write_text` (round-trip + no `.tmp` debris).

### Changed

- `agents/source-fetcher.md` — Step 2 grows a PDF branch (#275): when `is_pdf_response(content_type, url)` is true, parse WebFetch's `[Binary content … also saved to <path>]` line, `Read pages: "1-20"` the saved file, transcribe per-page text into one body, and store through `fetch-cache.py store --fetch-method webfetch`. PDFs longer than 20 pages stamp `pdf_truncated: true` (Read tool's own cap). When the saved path is not surfaced (the EUR-Lex case observed in the M4 smoke), record `unavailable` with `reason: pdf_extraction_failed` and skip the cobrowse fallback (cobrowse downloads PDFs rather than rendering text). Step 3 (#276): when the `claude-in-chrome` MCP tools are absent from the runtime tool list, record `unavailable` with `reason: cobrowse_unavailable` + `fallback_attempted: false` (was a silent drop pre-v0.0.20). Step 4's closed `webfetch_error_class` vocabulary now documents `pdf_extraction_failed`, `cobrowse_unavailable`, and clarifies the existing entries — single source of truth lives in `references/fetch-cache-design.md` §"Reason semantics".
- `references/fetch-cache-design.md` — new `## Reason semantics` subsection enumerates every `webfetch_error_class` token with class (recoverable / terminal / environmental) and when each fires. Closes the F14 paper-trail gap where the vocabulary lived only inside `source-fetcher.md`.
- `references/inverted-pipeline.md` — Phase 4 contract clarified at line 118: the source page body is verbatim (not highlighted); `pre_extracted_claims:` carries the full claim shape per `references/claim-at-ingest.md`, and `excerpt_position` is the indexing primitive the future wiki-verifier reads.
- `tests/test_skill_contracts.sh` — clean-break invariant extended to scan the three new files (knowledge-ingest, source-ingester, claim-extractor). Adds a cogni-wiki extension that asserts these files do not dispatch any `cogni-wiki:` skill (the M6 contract: call helper scripts directly).
- `CLAUDE.md` — Skills table gains `knowledge-ingest`; Agents table gains `claim-extractor` + `source-ingester`. "Future phases" paragraph records M5 + M6 shipped at v0.0.20; M7 is the next slice.

### Notes

- **Backlink audit is audit-only at v0.0.20.** `backlink_audit.py --apply-plan` requires an LLM pass to curate which audit candidates to write back into existing pages; that pass is not in `knowledge-ingest`'s scope at v0.0.20. The audit candidate list is surfaced in the final summary so the operator can apply via `wiki-update`. F11 ("0 body-level wikilinks") from the v0.0.16 alpha stays open for the same reason.
- **`type: source` allowlist.** cogni-wiki v0.0.44 added `"source": "sources"` to `_wikilib.PAGE_TYPE_DIRS` (its `VALID_TYPES` derives from there); `wiki-health` and `wiki-lint` accept pages of this type. Older wikis on schema_version `< 0.0.6` need to be re-bootstrapped or hand-migrated — the skill surfaces the upstream hard-fail and directs the user to upgrade.
- **PDF transcription brittleness.** WebFetch's `[Binary content … also saved to <path>]` line is an undocumented tool-output convention. Parse defensively; on any parse miss fall through to `pdf_extraction_failed`. Documented in `references/fetch-cache-design.md` and `agents/source-fetcher.md` Step 2 so the next maintainer knows where to look.

### Dependencies

cogni-wiki ≥ 0.0.44 (the `type: source` allowlist) is the hard prerequisite for M6. Pre-v0.0.44 wikis hard-fail in `wiki-health` on the first ingested source page.

## 0.0.19 — 2026-05-21

Slice 1 of the absorption-roadmap Current sprint — Phase 5 M4 end-to-end smoke. Docs-only release: no skill/agent/script behaviour changes; the smoke ran clean against the v0.0.17 + v0.0.18 chain. Two new findings worth scheduling (F15 — PDF handling in `source-fetcher`; F13 — assertion-clarity in the M4 smoke recipe), three findings are positive/environmental (F14 cobrowse-MCP gating, F16 file-lock under contention, F17 environmental 502s). **Recommendation: GO** for Slice 2 (M5 + M6) per `references/alpha-findings.md` §"M4 smoke (2026-05-21)".

### Docs

- `references/alpha-findings.md` — new `## M4 smoke (2026-05-21)` section with the seven-step verification matrix, cost+timing measurements, F13–F17 findings, and the GO recommendation. Findings table extended with F13–F17 rows.

### Notes

- Smoke topic: "EU AI Act GPAI Code of Practice obligations" against a fresh `.alpha/eu-ai-act-gpai/` base (continues the v0.0.16 alpha narrative; comparable measurements).
- End-to-end: 6 sub-questions → 57 candidates curated → 41 fetched + 16 unavailable → 58 cache entries (positive + negative cache symmetric) → 100% hit rate on re-run → injected 404 handled cleanly. ~1h wall-clock, $0.155 total LLM cost.
- F15 (PDF handling) is the only real code finding. Recommended fix path: fold into Slice 2's `source-ingester` work since claim extraction needs to read fetched bodies and will face the same PDF-detection problem.

### Dependencies

No new minimum-version requirements. cogni-wiki ≥ 0.0.43 from v0.0.14 still holds.

## 0.0.18 — 2026-05-21

### Changed

- `scripts/_knowledge_lib.py` — NEW. Extracts the `normalize_url` +
  `_STRIP_QUERY_*` + `atomic_write` helpers previously duplicated across
  `candidate-store.py` and `fetch-cache.py`. Closes #272. The extraction was
  scheduled for M5 (`source-ingester` as the third caller); landed early
  because the two existing callers had already started style-drifting on
  `normalize_url`. Single source of truth for URL identity in the inverted
  pipeline — the dedup-key contract between curator-side merge and
  fetcher-side cache lookup is now structural rather than convention.
- `scripts/candidate-store.py`, `scripts/fetch-cache.py` — now import the
  shared helpers from `_knowledge_lib`; `_atomic_write` call sites renamed
  in-place to the public `atomic_write`. No behavioural change.
- `tests/test_knowledge_lib.sh` — NEW. Three-way `is`-identity assertion
  between `candidate-store`, `fetch-cache`, and `_knowledge_lib`
  `normalize_url` / `atomic_write`; behavioural canonicalization sanity
  check across a representative URL; `atomic_write` round-trip plus
  no-leftover-`.tmp` assertion.

### Notes

- `knowledge-binding.py:_write_binding` shares the same atomic-write pattern
  but a different signature (takes `knowledge_root`, resolves the binding
  path internally). Not extracted in this slice — possible follow-up.

## 0.0.17 — 2026-05-20

Phase 5 milestones M2-finish + M3 + M4 — the `plan → curate → fetch` chain of the v0.1.0 inverted pipeline. PR #269 (M1 + M2-script) shipped the foundation without a version bump; this release surfaces the first user-visible inverted-pipeline skills. Plugin stays at `0.0.x`/maturity `incubating` per the absorption-roadmap M-table — the maturity flip to Preview ships at M12 alongside the alpha re-run + 0.1.0 bump. The `0.0.16` slot is reserved for the alpha-re-run measurement record referenced in `references/alpha-findings.md` and the `knowledge-binding.py` comment block; no source code shipped under that version. The annotated git tag `cogni-knowledge-v0.0.16-alpha-measurement` at commit `f6c9d24e` marks the measurement record so the version timeline reads linearly. Closes #273.

### Added

- `agents/source-curator.md` — point-in-time fork of `cogni-research/agents/source-curator.md` (SHA `d2ee309` at fork time). Phase 2 curator for the inverted pipeline. Reshapes output: writes `<project>/.metadata/candidates.json` instead of `curated-sources.json`; renames `composite_score → score`; adds `tier`, `sub_question_refs[]`; drops emission of `dimensions{}`, `annotation`, `diversity{}` (computation stays internal; the M12 alpha gate is content-not-process). Composite scoring weights (0.30/0.25/0.15/0.15/0.15) unchanged at fork time. WebSearch only — no WebFetch (Phase 3's job). M3.
- `agents/source-fetcher.md` — NEW agent (no upstream). Phase 3 fetcher. Per-URL loop: `fetch-cache.py fetch` (cache lookup) → WebFetch → cobrowse fallback (via `claude-in-chrome` MCP when present) → `fetch-cache.py store` for both success and `unavailable` outcomes. Negative-cache symmetric with positive per `fetch-cache-design.md:53`. Never decides to drop a URL — only records availability. Closed `webfetch_error_class` vocabulary so downstream summarisation is stable. M2-finish.
- `skills/knowledge-plan/SKILL.md` — Phase 1 skill. Decomposes a topic into 3-7 sub-questions with per-sub-question `candidate_domains[]` (no web). Writes `<project>/.metadata/plan.json` schema `0.1.0` per `references/inverted-pipeline.md:41-57`. Creates the project directory at `<knowledge-root>/<topic-slug>-<YYYY-MM-DD>/`. Probes only `cogni-wiki` (clean-break — no cogni-research dispatch). Binding append deferred to M9 (`knowledge-finalize`). M4 part 1/3.
- `skills/knowledge-curate/SKILL.md` — Phase 2 orchestrator. Reads `plan.json` + `binding.curator_defaults`, fans out one `source-curator` dispatch per sub-question (parallel when ≤3, sequential otherwise), merges per-sub-question batches into `candidates.json` via `candidate-store.py append-batch`. Legacy-binding fallback: applies `DEFAULT_CURATOR_DEFAULTS` from `knowledge-binding.py` when pre-v0.0.3 bindings lack `curator_defaults`. M4 part 2/3.
- `skills/knowledge-fetch/SKILL.md` — Phase 3 orchestrator. Reads `candidates.json` + `binding.curator_defaults.fetch_cache_max_age_days`, builds batches (default 8 URLs each, sorted by `fetch_priority`), dispatches `source-fetcher` per batch (sequential at v0.0.17 for WebFetch rate-limit awareness), merges `fetched[]` + `unavailable[]` into `<project>/.metadata/fetch-manifest.json` schema `0.1.0` per `references/inverted-pipeline.md:91-109`. Optional `--tier` flag scopes fetches to a single tier. Non-blocking warning when unavailable rate exceeds 30%. M4 part 3/3.
- `scripts/candidate-store.py` — stdlib helper for file-locked (`fcntl.flock`) merge of parallel curator output batches into `<project>/.metadata/candidates.json`. Subcommands `init` / `append-batch` / `read`. Dedup key is URL-normalized (lowercase scheme+host, trailing-slash-stripped, `utm_*` / `ref` / `fbclid` / `gclid` params dropped, fragment dropped). Merge semantics on collision: higher score wins, earliest `discovered_at` wins, `sub_question_refs[]` unioned, `tier` + `fetch_priority` recomputed. Posix-only (consistent with `tests/README.md` Linux/macOS posture). M4 supporting infrastructure.
- `tests/test_candidate_store.sh` — 8 assertions: init idempotency + schema `0.1.0`, dedup+merge+ref-union+fetch_priority assignment, concurrent-append lock correctness (two parallel subshells racing on the same project), three malformed-input rejection cases (non-array, missing url, out-of-range score), URL normalization collapsing case + trailing slash + tracking params.
- `tests/test_skill_contracts.sh` — grep-based SKILL.md / agent-md contract assertions for the 6 new files. Catches silent contract drift (path, flag, or step disappearing). Includes a clean-break invariant check that asserts no new file dispatches a `cogni-research:` or `cogni-claims:` skill/agent.

### Changed

- `CLAUDE.md` — Skills table gains rows for `knowledge-plan` / `knowledge-curate` / `knowledge-fetch`. Scripts table gains `candidate-store.py`. "Future phases" paragraph rewritten to delegate the milestone narrative to `references/absorption-roadmap.md` (the source of truth) with a one-line progress pointer.
- `fetch-cache.py` `_url_key` now hashes the **normalized** URL form (`normalize_url` — same canonicalization `candidate-store.py` applies for dedup) rather than the raw URL. Any cache entries written between PR #269 and v0.0.17 are keyed against the un-normalized hash and will be invisible to post-v0.0.17 lookups. PR #269 only just shipped so production caches are unlikely, but if you have one, run `python3 cogni-knowledge/scripts/fetch-cache.py evict --older-than-days 0` to clear it.

### Dependencies

No new minimum-version requirements. cogni-wiki ≥ 0.0.43 from v0.0.14 still holds. (cogni-wiki 0.0.44's `type: source` allowlist is the next slice's dep — M6 `knowledge-ingest` — not this slice's.)

## 0.0.15 — 2026-05-20

Phase 4 alpha re-run on a fresh `eu-ai-act` knowledge base completed end-to-end without chain-breaker regression. Docs-only release recording the go decision for Phase 5 graduation.

### Docs

- `references/alpha-findings.md` — new `## v0.0.16 alpha re-run (2026-05-20)` section. Verifies F1–F5 fixed on the re-run (marketplace probe, `<slug>-<date>/` discovery, `.metadata/project-config.json` path, `[[wikilink]]` frontmatter parsing). Documents F11 (writer mid-Phase-2 socket crash — Phase 4.5 Step 0 recovery contract worked cleanly on re-dispatch) and F12 (`initialize-project.sh` CLI doesn't accept `--wiki-paths`; interactive `research-setup` menu handles it). Captures the four go/no-go measurements: time-to-second-research 44.9 min; cross-project compounding visible at the citation layer (synthesis cited all 21 prior-deposit wiki pages); claims duplication 17 shared URLs / ~150 distinct sources; subjective value positive. **Recommendation: GO** for Phase 5.

### Dependencies

No new minimum version — cogni-wiki ≥ 0.0.43 from v0.0.14 still holds, no upstream bug observed during the re-run.

## 0.0.14 — 2026-05-20

Phase 4 alpha findings F1–F5 + PR #267 reviewer-deferred items A1–A4. F1–F5 are the chain-breakers that prevented the `knowledge-research` + `knowledge-report` orchestrator chain from completing end-to-end without ad-hoc operator workarounds (symlinks, sed-patches, hand-written wiki pages). F5 is structurally subsumed by F4 — see `references/alpha-findings.md` for the full table.

### Added

- `references/alpha-findings.md` — captures F1–F10 from the Phase 4 internal alpha. F1–F4 are fixed in this release; F5 closes transitively via F4 (`_wiki_research.strip_wikilink` already strips path prefixes once it receives a string instead of a one-element list). F6–F10 are deferred and tracked there so they do not get lost.
- `tests/` — new stdlib-only test directory mirroring `cogni-wiki/tests/`. Ten smoke tests cover F1 + A4 (probe contract + behaviour against dev-repo and marketplace cache layouts), A1 (`read-project-config.py --bare`), A2 (binding `project_path` field + schema 0.0.2 with legacy compat), and A3 (six fixture-driven `cycle-guard.py` scenarios: direct/transitive cycles, depth-bound disablement, clear runs, dry-run report-don't-gate semantics, web/local not-applicable shortcut).
- `scripts/read-project-config.py` — `--bare`/`--raw` flag (A1) prints the resolved field value directly to stdout instead of the JSON envelope; errors go to stderr with exit 1. Collapses the two-process pipe at `knowledge-research` Step 3 and `knowledge-report` Step 5 to a single command. Default envelope mode is unchanged for any future structured-output consumer.
- `scripts/knowledge-binding.py` — `--project-path` argument on `append-project` (A2). Writes a new `project_path` field on each entry in `research_projects[]` with the absolute, resolved project root. Schema bump `0.0.1` → `0.0.2`. `cycle-guard.py` prefers `entry["project_path"]` over the legacy `.parent.parent` derivation; falls back to the old derivation when the field is absent (schema 0.0.1 or callers that don't pass `--project-path`). Backwards-compatible — existing bindings keep working.

### Changed

- `skills/knowledge-setup/SKILL.md` Step 0 — replaces the two-line dev-repo-only probe with a `probe_plugin()` helper that handles both layouts (`../<plugin>/skills/...` AND `../../<plugin>/<version>/skills/...`). Before F1, marketplace-cache installs always aborted with deps "missing" even when they were installed. Drops the v0.0.13 "future patch may roll the check into the other five skills" footnote since A4 lands the rollout.
- `skills/knowledge-research/SKILL.md`, `skills/knowledge-report/SKILL.md`, `skills/knowledge-query/SKILL.md`, `skills/knowledge-dashboard/SKILL.md`, `skills/knowledge-refresh/SKILL.md`, `skills/knowledge-resume/SKILL.md` — Step 0 pre-flight section gains the same `probe_plugin()` helper and abort wording (A4). Now every `knowledge-*` skill that dispatches into cogni-wiki or cogni-research aborts cleanly when either is missing, rather than failing mid-workflow with an opaque `Skill` tool error.
- `skills/knowledge-research/SKILL.md` Step 3, `skills/knowledge-report/SKILL.md` Step 5 — collapse the `python3 -c "...['data']['value']"` envelope-unwrap shellout via `read-project-config.py --bare` (A1). Both also pass the new `--project-path` arg on `knowledge-binding.py append-project` (A2). The hard-coded `cogni-research-<slug>/` path placeholder is replaced with `<abs path to project>` to align with cogni-wiki F2 (v0.7.x+ projects have no `cogni-research-` prefix).

### Dependencies

- `cogni-wiki` minimum version bumped to 0.0.43 (was 0.0.42) — F2 (`locate_research_project` supports v0.7.x+ naming), F3 (`batch_builder` reads `.metadata/project-config.json`), F4 (`parse_frontmatter` keeps `[[wikilink]]` as a string). F5 closes transitively via F4.

## 0.0.13 — 2026-05-19

Phase 2/3 debt cleanup, closing six items deferred from #265 and #266 before the Phase 4 alpha begins. No new user-facing surface — all changes harden existing primitives.

### Added

- `scripts/read-project-config.py` — factored stdlib reader for `cogni-research-<slug>/.metadata/project-config.json`. Replaces the `python3 -c "import json; …"` shellouts at `knowledge-research` Step 3 and `knowledge-report` Step 5. Same fallback semantics (missing file → default; default `web` for `report_source`); now isolated and unit-testable.
- `scripts/cycle-guard.py` — **transitive (multi-hop) cycle detection**. The MVP at v0.0.6 caught only direct self-cycles (candidate cites a page derived from itself). v0.0.13 extends the walk into a bounded DFS over `binding.research_projects[]`: when a cited page is derived from another deposited project `P`, the guard recurses into `P`'s own `02-sources/data/src-*.md` citations (project dir derived from the binding entry's `report_path.parent.parent`). Bounded by `--max-depth` (default 5; `0` disables transitive recursion matching the v0.0.6 behaviour) and a visited-slug set. New envelope fields: `transitive_self_cycles[]`, `cycle_path[]` (slug chain that closed the loop), `max_depth`.
- `scripts/cycle-guard.py` — **single up-front slug→path index**. Replaces the per-citation `<wiki>/wiki/**/<page-id>.md` glob in `_resolve_wiki_page` with a one-time walk that maps slug → (path, collisions). Collapses `O(citations × pages × hops)` to `O(pages)` once + `O(1)` per lookup; meaningful for large wikis under transitive recursion.
- `skills/knowledge-setup/SKILL.md` — new **Step 0 pre-flight dependency check** probing `cogni-wiki/skills/wiki-setup/SKILL.md` and `cogni-research/skills/research-setup/SKILL.md` via `${CLAUDE_PLUGIN_ROOT}/../<plugin>/...`. Aborts cleanly with the missing plugin name(s) instead of letting downstream steps fail mid-workflow with an opaque `Skill` tool error. Closes the open top-level "Pre-flight dependency check" checkbox on epic #264. Rollout to the other five knowledge-* skills tracked as a follow-up.

### Changed

- `skills/knowledge-research/SKILL.md` Step 3 + `skills/knowledge-report/SKILL.md` Step 5 — replaced the inlined `python3 -c "import json; …"` `report_source` reader with a call to the new `read-project-config.py` plus a one-line envelope unwrap.
- `scripts/cycle-guard.py` — docstring precision. The previous v0.0.6 docstring stated "MVP detects **direct** self-cycles only" with a "deferred to v0.0.7+" note; updated to describe the transitive walk + depth bound now that it ships. Rolls in the post-merge `5d273c2` patch that didn't land at v0.0.6.
- `scripts/cycle-guard.py` — abort message refresh: cycle reports now print the cycle chain (`A → B → A`) and distinguish direct vs. transitive; drops the obsolete "wait for transitive cycle handling (v0.0.7+)" line.

### Dependencies

- `cogni-wiki` minimum version bumped to 0.0.42 (was 0.0.41) — contract-level regression tests for `wiki-from-research --allow-wiki-source --cycle-guard-cleared` and `wiki-query --wiki-root`.

## 0.0.12 — 2026-05-19

### Changed

- `knowledge-query` now dispatches `cogni-wiki:wiki-query` with `--wiki-root <wiki_path>` directly (requires cogni-wiki ≥ 0.0.41, which added the flag). Drops the prompt-prefix shim from v0.0.8 — the shim relied on a `prompt=` Skill kwarg that does not exist, so wiki-query would silently fall back to cwd-walking and could resolve to the wrong wiki.
- `knowledge-refresh` push-mode §"Edge cases": new bullet documenting that each per-topic `knowledge-research` dispatch surfaces the upstream `cogni-research:research-setup` interactive menu, so the batch confirmation gates the *count* of runs (not their per-run scope decisions).

### Dependencies

- `cogni-wiki` minimum version bumped to 0.0.41 (was 0.0.40).

## 0.0.11 — 2026-05-19

Phase 3 of the wiki-first research epic (#264) is now shipped. Documentation closeout — no new code in this version.

### Docs

- `CLAUDE.md` §"Skills" table: add rows for `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh`. §"Future phases": flip Phase 3 to "shipped at v0.0.11" and add a Phase-3 follow-up debt bullet for the upstream `wiki-query --wiki-root` patch.
- `references/delegation-contract.md`: add §"Phase-3 push-refresh behaviour" capturing the single batch-confirmation UX and the composition-only contract.
- `references/absorption-roadmap.md`: Phase 3 block flipped to "Shipped at v0.0.11, 2026-05-19" with per-skill version + a follow-up debt bullet for the `wiki-query --wiki-root` upstream patch.
- `README.md`: §"What it does" table now lists all 7 skills; §"Quick start" includes `knowledge-dashboard` and `knowledge-query` examples; §"How it works" diagram covers all Phase-3 skills; §"Components" reflects 7 skills.

## 0.0.10 — 2026-05-19

### Added

- Skill `knowledge-refresh` — closes the self-healing loop on a bound knowledge base. Pull-mode delegates to `cogni-wiki:wiki-refresh`. Push-mode lints the bound wiki, asks the user (multi-select) which stale topics to re-research, single batch-confirmation gate, sequentially dispatches `knowledge-research` per selected topic, then dispatches `wiki-refresh` per new project so originally-stale pages refresh against the fresh evidence.

## 0.0.9 — 2026-05-19

### Added

- Skill `knowledge-dashboard` — composes `cogni-wiki:wiki-dashboard` with a binding overlay sidecar (`knowledge-overlay.md`) listing deposited research projects and the latest lint-audit `claim_drift` count. Co-located with `wiki-dashboard.html` so both files travel together when the user shares the base.

## 0.0.8 — 2026-05-19

Phase 3 of the wiki-first research epic (#264) begins — query the bound base by slug.

### Added

- Skill `knowledge-query` — binding-aware wrapper of `cogni-wiki:wiki-query`. Resolves the bound wiki path from `binding.json`, dispatches the upstream query (with a prompt-prefix shim that pins the wiki context until a `--wiki-root` flag lands upstream in `wiki-query`), and appends a one-line knowledge-base footer to the answer. Read-only — never writes to the binding.

## 0.0.7 — 2026-05-19

### Fixed

- `knowledge-research` Step 3 now records the live `report_source` from `<project>/.metadata/project-config.json` instead of the hard-coded `web` literal. Mirrors `knowledge-report` Step 5. Closes the third Phase-2 follow-up checkbox on #264.

## 0.0.6 — 2026-05-19

Phase 2 of the wiki-first research epic (#264) — the wiki-roundtrip primitive lands. Reports now get composed by reading the deposited wiki pages, not by re-fetching the same web sources.

### Added

- Skill `knowledge-report` — compose a research report by reading the bound wiki, refuse self-citing loops via `cycle-guard.py`, then re-deposit via `cogni-wiki:wiki-from-research` Mode B with the `--allow-wiki-source --cycle-guard-cleared` opt-in flags. Records the live `report_source` (`wiki` or `hybrid`) in the binding.
- Script `cycle-guard.py` — stdlib CLI that detects **direct** self-cycles. Walks the candidate project's `02-sources/data/src-*.md` entities for `wiki://<bound-slug>/<page-id>` citations and checks each resolved page's frontmatter for `derived_from_research: <candidate-slug>`. Output: insight-wave envelope; exit 1 on `cycle_detected`, exit 0 otherwise. Transitive (multi-hop) cycle detection is deferred to v0.0.7+ — MVP catches direct self-cycles only.

### Changed

- `cogni-wiki:wiki-from-research` (cogni-wiki v0.0.40) gains `--allow-wiki-source --cycle-guard-cleared` opt-in flags that lift its default abort on `report_source ∈ {wiki, hybrid}` projects. `knowledge-report` passes both. Direct users see no change.
- `references/delegation-contract.md` Phase-2 guardrail note moves from "prospective" to shipped (in `knowledge-report`; `knowledge-research` still hard-codes `web` — a one-line follow-up patch).

### Out of scope (deferred)

- Transitive cycle detection — land as a v0.0.7+ patch once alpha runs surface real cycle shapes.
- Lifting `knowledge-research`'s hard-coded `--report-source web` to read the live `report_source` — ships as a separate small PR.
- `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh` (Phase 3, v0.0.11+).

## 0.0.1 — 2026-05-19

Initial Incubating release. Phase 1 of the wiki-first research epic.

### Added

- Plugin scaffold (`.claude-plugin/plugin.json`, README, CLAUDE.md).
- `binding.json` data model (`.cogni-knowledge/binding.json`, schema v0.0.1).
- Skill `knowledge-setup` — bootstrap a knowledge base (wiki + binding).
- Skill `knowledge-research` — research a topic INTO the bound wiki via `cogni-wiki:wiki-from-research` (Mode A), then stamp lineage and record the project.
- Skill `knowledge-resume` — status + delegate to `cogni-wiki:wiki-resume`.
- Script `knowledge-binding.py` — stdlib CLI for `--init`, `--append-project`, `--read`.
- Script `lineage-stamp.py` — stdlib CLI that stamps `derived_from_research: <slug>` into deposited wiki page frontmatter.
- References: `differentiation-thesis.md`, `delegation-contract.md`, `absorption-roadmap.md`.

### Out of scope (deferred to later phases)

- `knowledge-report` (Phase 2) — wiki-roundtrip composition with cycle-guard.
- `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh` (Phase 3).
- Internal alpha (Phase 4), graduation to Preview (Phase 5), cogni-research absorption (Phase 6).
