# cogni-knowledge changelog

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
