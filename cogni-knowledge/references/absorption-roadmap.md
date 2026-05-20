# Absorption roadmap

cogni-knowledge is structured around a committed endgame: if the alpha proves positive, `cogni-research` is absorbed into this plugin. The Phase 4 alpha closed positive (GO recommendation in v0.0.16) and the absorption is now in flight, restructured as **a single v0.1.0 inverted-pipeline clean break** rather than the original two-step Phase 5 → Phase 6 sequence. The phases below trace the path from "Phase 1 MVP scaffold" to "cogni-research deprecated, cogni-knowledge v1.0".

Reading order: this file, then `inverted-pipeline.md` (the v0.1.0 technical contract), then `differentiation-thesis.md`, then `delegation-contract.md`.

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

### Phase 4 — Internal alpha (v0.0.14 → v0.0.20)

**Status.** Findings F1–F5 (chain-breakers) shipped fixed at v0.0.14 alongside PR-#267 reviewer-deferred items A1–A4. Findings document at `references/alpha-findings.md`. F6–F10 are deferred. Next step is the v0.0.16 alpha re-run on a fresh knowledge base, which is now unblocked.

**Goal.** Test on one real knowledge area for ≥ 3 research projects. Decide go/no-go on absorption.

**Activities.**
- Reset a fresh knowledge base (EU AI Act suggested).
- Run ≥ 3 `knowledge-research` invocations on a real topic end-to-end (no sed-patches, no symlinks, no manual page writes — v0.0.14 unblocks this).
- Run ≥ 1 `knowledge-report` against the populated base (Phase 2 round-trip).
- Compare against equivalent standalone `cogni-research` runs on:
  - Time-to-second-research.
  - Cross-project information density (`[[wikilinks]]` between projects).
  - Claims duplication.
  - User-perceived value (subjective).
- Update `references/alpha-findings.md` with re-run outcomes; close any F6–F10 items that resolved by side effect.

**Go/no-go gate.**
- Positive → commit to Phase 5 + Phase 6.
- Negative → freeze cogni-knowledge as an experimental path; do not migrate cogni-research consumers.

### Phase 5 — Inverted-pipeline clean break (v0.1.0) — **THIS PHASE**

**Status.** Foundation work landing in PR #269 (milestones 1 + 2 of 12). Maturity callout stays at Incubating until milestone 12 (alpha re-run) is clean.

**Context for the restructure.** The original Phase 5 plan was a hardening pass (README rewrite, doc-audit clean, maturity callout flip) sequenced before a separate Phase 6 absorption. The Phase 4 alpha closed positive but exposed three structural problems the user wanted fixed before the maturity boundary crossing:

- The wiki is empty for ~80% of wall-clock while research runs (alpha finding F6).
- Sources are fetched twice (once by `cogni-research`'s section-researcher, again by `cogni-claims`' verifier — see `cogni-claims/skills/claims/SKILL.md:108`).
- Unreachable sources reach the report because verification happens after composition.

User decisions baked into the v0.1.0 plan (recorded via AskUserQuestion in the planning session, full plan was at `~/.claude/plans/here-is-a-draft-tranquil-anchor.md`):

1. **Clean break.** `cogni-research` is 0% in the cogni-knowledge runtime path at v0.1.0. `knowledge-refresh --pull-mode` is rewritten on the inverted pipeline. `cogni-research` stays installed only as the source of the forked agents and as the dep for non-cogni-knowledge callers.
2. **cogni-claims absorbed too.** `knowledge-verify` replaces `cogni-claims` for cogni-knowledge consumers. `cogni-claims` stays alive for `cogni-trends` / `cogni-portfolio` submitters.
3. **One big v0.1.0 cut.** All twelve milestones land before the v0.1.0 tag.

This squashes the original Phase 5 (hardening) and Phase 6 (absorption migration) into one release.

**Goal.** Replace the v0.0.x `research → wiki-ingest → claims-verify` chain with the inverted pipeline (`plan → curate → fetch → ingest → compose → verify → finalize`). The wiki becomes the writer's substrate; sources are fetched once before composition; unreachable sources are dropped before they can be cited.

**Pipeline contract.** Full phase-by-phase contract lives at `references/inverted-pipeline.md`. Supporting design notes at `references/fetch-cache-design.md` and `references/claim-at-ingest.md`.

**Implementation order (12 milestones; status as of this commit).**

| # | Milestone | Status |
|---|---|---|
| 1 | Plumbing — binding schema 0.1.0, fetch-cache bootstrap, contract docs | **shipped** (PR #269) |
| 2 | `source-fetcher` agent + `fetch-cache.py` script | **partial** — script + tests shipped (PR #269); agent pending |
| 3 | `source-curator` fork from cogni-research | pending |
| 4 | `knowledge-curate` + `knowledge-fetch` skills | pending |
| 5 | `claim-extractor` fork + `source-ingester` agent | pending |
| 6 | `knowledge-ingest` skill | pending — **blocked on cogni-wiki v0.0.44** (`type: source` allowlist in `wiki-lint` + `wiki-health`) |
| 7 | `wiki-composer` agent (fork of cogni-research `writer`) + `knowledge-compose` skill | pending — must preserve F11 outline-recovery contract |
| 8 | `wiki-verifier` agent (replaces cogni-claims verifier) + `revisor` agent (forked from cogni-research, kept local to honour the clean break) + `knowledge-verify` skill | pending |
| 9 | `knowledge-finalize` skill | pending — reuses existing `cycle-guard.py` |
| 10 | Rebuild `knowledge-query`, `knowledge-dashboard`, `knowledge-resume`, `knowledge-refresh` on new manifests | pending — `--pull-mode` rewritten on inverted pipeline (clean-break commitment) |
| 11 | Archive `knowledge-research` + `knowledge-report` → `skills/_archive/`; rewrite README, CLAUDE.md, references | pending |
| 12 | Alpha re-run on `eu-ai-act-v0.1`; bump `plugin.json` + `marketplace.json` to 0.1.0; flip maturity callout to Preview | pending — gates the version bump |

**Cross-plugin coordination.**

| Plugin | Required change | Owner |
|---|---|---|
| cogni-wiki | Accept `type: source` in `wiki-lint` + `wiki-health` allowlists. One-line addition + fixture. | Lands as cogni-wiki v0.0.44 before milestone 6. |
| cogni-claims | No code change. v0.1.0 stops dispatching to it. One-line note in `cogni-claims/CLAUDE.md` recording the lost caller. | Trivial doc edit, lands with milestone 11. |
| cogni-research | No code change. v0.1.0 stops dispatching to it. Forked agents in cogni-knowledge are point-in-time copies; drift from upstream is acceptable and documented in `inverted-pipeline.md`. | No edit. |

**Pass criteria for the milestone 12 alpha re-run (all must hold).**

- 0 duplicate URL fetches across the run (verified via fetch-cache content hashes).
- 0 unreachable URLs in the final report's citation set (because unreachable were dropped at fetch time).
- Claim-verify wall-clock < 5 min (vs 20–30 min baseline in v0.0.15).
- Every cited statement in `draft-v1.md` resolves to a `[[wiki-slug]]` that exists and has at least one pre-extracted claim aligned with it.
- F11 recovery contract still works: kill `wiki-composer` mid-Phase-2 after outline persistence; re-dispatch recovers without re-doing Phase 1.

**Out of scope for v0.1.0** (deferred to v0.2 or later, not blocking).

- Local + wiki + hybrid source modes. v0.1.0 is web-only.
- Multi-market fan-out. v0.1.0 is single-market.
- Federated wikis (`wiki_paths[]`).
- Knowledge-graph visualization in dashboard.
- Persistent fetch queue (analogous to cogni-wiki's ingest queue Mode D).
- Backwards-compat alias for the archived `knowledge-research` / `knowledge-report` slugs.

### Phase 6 — v1.0 deprecation cleanup (cogni-knowledge v1.0.0; cogni-research → archived)

**Goal.** After v0.1.0 ships and bakes for ≥ 2 minor versions of real usage, formalize cogni-research's deprecation and cross the Preview → Released maturity boundary.

**Deliverables.**

1. **Deprecate cogni-research.** 2-version sunset; final state has `"archived": true` in `cogni-research/.claude-plugin/plugin.json` and mirror in `marketplace.json`. The agent source files stay in the repo for archival reference; the plugin is no longer installable.
2. **Migrate downstream callers** that still dispatch to cogni-research:
   - `cogni-trends`: cut over `trend-research` to cogni-knowledge (with a default knowledge base per trend domain).
   - `cogni-narrative`: arc-driven research integration cut over.
   - `cogni-portfolio`: verify (mostly uses `WebSearch` directly per existing audit).
   - `cogni-wiki:wiki-from-research`: rotate from `cogni-research:research-setup` to a cogni-knowledge dispatch (or deprecate the skill entirely if all callers have migrated).
3. **Top-level docs.** Update `/insight-wave/CLAUDE.md` data-flow diagram to remove cogni-research from the runtime graph.
4. **Maturity flip.** Bump cogni-knowledge to 1.0.0, flip README callout from Preview to Released.

**Out of scope for the entire epic.** Absorbing cogni-wiki itself — it is a general-purpose Karpathy-pattern knowledge engine usable standalone (interview notes, PDFs, raw drops). Keep separate.

## Open questions (revisit at Phase 6)

- **Rename at v1.0?** Does `cogni-knowledge` keep its name once it owns the full research surface, or does it rename to something cleaner? Defer until v0.1.x usage signal lands.
- **Backwards-compat alias.** Should we ship a `cogni-research:` alias inside cogni-knowledge during the sunset window, or just rely on downstream consumers cutting over? Defer to Phase 6 planning.
- **Multi-wiki knowledge bases.** Today's binding records exactly one `wiki_path`. A future extension could allow `wiki_paths[]` for federated bases. Defer until a user explicitly asks for it — premature now.
