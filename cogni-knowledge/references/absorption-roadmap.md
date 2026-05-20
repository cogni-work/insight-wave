# Absorption roadmap

cogni-knowledge is structured around a committed endgame: if the alpha proves positive, `cogni-research` is absorbed into this plugin. The phases below trace the path from "Phase 1 MVP scaffold" to "cogni-research archived, cogni-knowledge v1.0".

Reading order: this file, then `differentiation-thesis.md`, then `delegation-contract.md`.

## Phases

### Phase 1 — MVP: binding + accumulating research (v0.0.1 → v0.0.5)

**Status.** Shipped at v0.0.1.

**Deliverables.**
- Plugin scaffold (`.claude-plugin/plugin.json`, `README.md`, `CLAUDE.md`, `CHANGELOG.md`).
- `binding.json` data model.
- Skills: `knowledge-setup`, `knowledge-research`, `knowledge-resume`.
- Scripts: `knowledge-binding.py`, `lineage-stamp.py`.
- Marketplace registration in `/insight-wave/.claude-plugin/marketplace.json`.

**Out of scope.** Wiki-roundtrip composition, cycle-guard, push-refresh, dashboard, query convenience.

### Phase 2 — Wiki-roundtrip reports (v0.0.6 → v0.0.10) — **THIS PHASE**

**Status.** Shipped at v0.0.6.

**Goal.** Reports get composed by reading the deposited wiki pages, not transient research contexts.

**Deliverables.**
- `scripts/cycle-guard.py` — detects self-cycle wiki↔research evidence chains by walking the candidate project's `02-sources/data/src-*.md` source entities for `wiki://<bound-slug>/<page-id>` citations and checking each resolved page's frontmatter for `derived_from_research:` lineage stamps. v0.0.6 shipped direct self-cycles only; **v0.0.13 added transitive (multi-hop) detection** with a bounded DFS over `binding.research_projects[]` (default `--max-depth 5`, visited-slug set), plus a single up-front slug→path index for O(1) page lookups.
- Modification to `cogni-wiki/skills/wiki-from-research/SKILL.md` (cogni-wiki v0.0.40): lift the hard abort on `report_source ∈ {wiki, hybrid}`, gated behind `--allow-wiki-source --cycle-guard-cleared` opt-in flags. Default behavior unchanged for direct users.
- `skills/knowledge-report/SKILL.md` — dispatches `cogni-research:research-setup` with a wiki-mode pre-fill prompt against the bound wiki, runs `research-report` (auto-chained), runs `cycle-guard.py` to refuse self-citing loops, then re-deposits via `wiki-from-research` Mode B with the opt-in flag pair. Records the live `report_source` from `<project>/.metadata/project-config.json` in the binding — first satisfaction of the delegation-contract Phase-2 guardrail.

**Follow-up debt — closed at v0.0.13:**
- Transitive (multi-hop) cycle detection → shipped in v0.0.13 (moved into Deliverables above).
- Lift `knowledge-research`'s hard-coded `--report-source web` to read the live `report_source` → shipped in v0.0.7.
- Single up-front slug→path index in `cycle-guard.py` → shipped in v0.0.13.
- Factored project-config reader (`scripts/read-project-config.py`) replacing the `python3 -c` shellouts at `knowledge-research` Step 3 and `knowledge-report` Step 5 → shipped in v0.0.13.
- `cogni-wiki/tests/` contract regression tests for the `wiki-from-research --allow-wiki-source --cycle-guard-cleared` flag pair and `wiki-query --wiki-root` → shipped as cogni-wiki v0.0.42 alongside this slice.
- Cycle-guard docstring precision (the `5d273c2` post-merge tweak that didn't land at v0.0.6) → shipped in v0.0.13.

### Phase 3 — Query, dashboard, push-refresh (v0.0.11 → v0.0.15)

**Status.** Shipped at v0.0.11, 2026-05-19. Phase 2/3 follow-up debt closed at v0.0.13 (see Phase 2's "Follow-up debt — closed at v0.0.13" subsection above).

**Goal.** Make the accumulated knowledge legible and self-healing.

**Deliverables.**
- `knowledge-query` (v0.0.8) — binding-aware wrapper of `cogni-wiki:wiki-query`. Resolves the bound wiki path from `binding.json`, dispatches the upstream query, appends a one-line knowledge-base footer.
- `knowledge-dashboard` (v0.0.9) — composes `cogni-wiki:wiki-dashboard` with a `knowledge-overlay.md` sidecar (deposited projects table, latest lint-audit `claim_drift` count).
- `knowledge-refresh` (v0.0.10) — pull-mode delegates to `cogni-wiki:wiki-refresh`; push-mode lints the wiki, asks the user which stale topics to re-research, batch-confirms cost, sequentially dispatches `knowledge-research` per selected topic then `wiki-refresh` per new project.
- `cogni-wiki:wiki-query` upstream patch (v0.0.41) — adds `--wiki-root` flag mirroring `wiki-resume` / `wiki-lint` / `wiki-dashboard`. Allows `knowledge-query` to pin the bound wiki without a prompt-prefix shim.

### Phase 4 — Internal alpha (v0.0.16 → v0.0.20)

**Goal.** Test on one real knowledge area for ≥ 3 research projects. Decide go/no-go on absorption.

**Activities.**
- Run ≥ 3 `knowledge-research` invocations on a real topic (EU AI Act suggested).
- Run ≥ 1 `knowledge-report` against the populated base (Phase 2 round-trip).
- Compare against equivalent standalone `cogni-research` runs on:
  - Time-to-second-research.
  - Cross-project information density (`[[wikilinks]]` between projects).
  - Claims duplication.
  - User-perceived value (subjective).
- Document findings in `references/alpha-findings.md`.

**Go/no-go gate.**
- Positive → commit to Phase 5 + Phase 6.
- Negative → freeze cogni-knowledge as an experimental path; do not migrate cogni-research consumers.

### Phase 5 — Hardening + 0.1.x graduation (v0.1.0)

**Goal.** Cross the Incubating → Preview maturity boundary.

**Deliverables.**
- Comprehensive `README.md` and `CLAUDE.md`.
- `cogni-docs:doc-audit` clean.
- Update `/insight-wave/CLAUDE.md` data-flow diagram.
- New entry in `/insight-wave/docs/workflows/` for the wiki-first research cycle.
- Flip README maturity callout to Preview.
- Validate skill names with `cogni-workspace/scripts/check-skill-names.sh`.

### Phase 6 — Absorption migration (cogni-knowledge v1.0.0; cogni-research → archived)

**Goal.** Execute the committed endgame.

**Deliverables.**
1. **Move cogni-research internals into cogni-knowledge.**
   - Agents: `cogni-research/agents/{section-researcher, deep-researcher, local-researcher, wiki-researcher, writer, reviewer, revisor, claim-extractor, source-curator}.md` → `cogni-knowledge/agents/`.
   - Skills: `cogni-research/skills/{research-setup, research-report, research-resume, verify-report, audit-arcs}` core logic absorbed into cogni-knowledge equivalents.
   - Scripts: `cogni-research/scripts/*` → `cogni-knowledge/scripts/`.
   - Schemas: `cogni-research/schemas/*` → `cogni-knowledge/schemas/`.
2. **Migrate downstream callers.**
   - `cogni-trends`: cut over `trend-research` from cogni-research to cogni-knowledge (with a default knowledge base per trend domain).
   - `cogni-narrative`: arc-driven research integration cut over.
   - `cogni-portfolio`: verify (mostly uses `WebSearch` directly per existing audit).
   - `cogni-wiki:wiki-from-research`: leave it dispatching `cogni-research:research-setup` for back-compat during the deprecation window; rotate to cogni-knowledge in a follow-up.
3. **Deprecate cogni-research.** 2-version sunset; final state has `"archived": true` in `cogni-research/.claude-plugin/plugin.json` and mirror in marketplace.json.
4. **Top-level docs.** Update `/insight-wave/CLAUDE.md` data-flow diagram.

**Out of scope for the entire epic.** Absorbing cogni-wiki itself — it is a general-purpose Karpathy-pattern knowledge engine usable standalone (interview notes, PDFs, raw drops). Keep separate.

## Open questions for the absorption phase

These are recorded so they do not block Phase 1 → Phase 5 work; revisit when Phase 6 is approved.

- **Rename at v1.0?** Does `cogni-knowledge` keep its name once it owns the full research surface, or does it rename to something cleaner? Defer the decision to Phase 5 — the marketing answer depends on what positioning the alpha findings support.
- **Backwards-compat alias.** Should we ship a `cogni-research:` alias inside cogni-knowledge during the sunset window, or just rely on downstream consumers cutting over? Defer to Phase 6 planning.
- **Multi-wiki knowledge bases.** Today's binding records exactly one `wiki_path`. A future extension could allow `wiki_paths[]` for federated bases. Defer until a user explicitly asks for it — premature now.
