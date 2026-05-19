# cogni-knowledge changelog

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
