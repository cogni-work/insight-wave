# cogni-knowledge changelog

## 0.0.17 — 2026-05-20

Phase 5 milestones M2-finish + M3 + M4 — the `plan → curate → fetch` chain of the v0.1.0 inverted pipeline. PR #269 (M1 + M2-script) shipped the foundation without a version bump; this release surfaces the first user-visible inverted-pipeline skills. Plugin stays at `0.0.x`/maturity `incubating` per the absorption-roadmap M-table — the maturity flip to Preview ships at M12 alongside the alpha re-run + 0.1.0 bump. The `0.0.16` slot is reserved for the alpha-re-run measurement record referenced in `references/alpha-findings.md` and the `knowledge-binding.py` comment block; no released artefact ships under that tag.

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
