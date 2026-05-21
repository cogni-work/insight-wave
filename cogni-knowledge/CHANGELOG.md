# cogni-knowledge changelog

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
