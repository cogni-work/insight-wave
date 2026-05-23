# Absorption roadmap

cogni-knowledge is structured around a committed endgame: if the alpha proves positive, `cogni-research` is absorbed into this plugin. The Phase 4 alpha closed positive (GO recommendation in v0.0.16) and the absorption is now in flight, restructured as **a single v0.1.0 inverted-pipeline clean break** rather than the original two-step Phase 5 → Phase 6 sequence. The phases below trace the path from "Phase 1 MVP scaffold" to "cogni-research deprecated, cogni-knowledge v1.0".

Reading order: this file, then `inverted-pipeline.md` (the v0.1.0 technical contract), then `differentiation-thesis.md`, then `delegation-contract.md`.

**Resuming work?** Jump to §"Phase 5" → **Current sprint** (after the M-table) — that block names the next concrete slice (target version, file set, exit criterion) instead of forcing you to re-derive it from the M-table + PR history. The M-table is the long view; **Current sprint** is the short view that refreshes on each landing.

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

**Status.** M1–M9 shipped (PR #269, #271, #274, plus v0.0.19 docs-only + v0.0.20 Slice 2 + v0.0.21 PDF Read-loop + v0.0.22 Slice 3 + v0.0.23 Slice 4 + v0.0.24 Slice 5); **M10 shipped — M10a at v0.0.25 (read-side adapters), M10b at v0.0.26 (refresh push-mode rewrite) + cogni-wiki v0.0.45 (log-enum cleanup)**; **M11 shipped at v0.0.27 (legacy `knowledge-research` / `knowledge-report` chain archived to `_archive/`)**. Plugin at v0.0.27 / Incubating. M12 pending — see the M-table for status and **Current sprint** below for the next concrete slice. Maturity callout stays at Incubating until milestone 12 (alpha re-run) is clean.

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
| 2 | `source-fetcher` agent + `fetch-cache.py` script | **shipped** — script + tests (PR #269), agent (PR #271) |
| 3 | `source-curator` fork from cogni-research | **shipped** (PR #271) |
| 4 | `knowledge-curate` + `knowledge-fetch` skills | **shipped** (PR #271) — also `knowledge-plan` (Phase 1 skill) + `candidate-store.py`; manual end-to-end smoke deferred to v0.0.19 (see **Current sprint** below) |
| 5 | `claim-extractor` fork + `source-ingester` agent | **shipped at v0.0.20** — Slice 2 |
| 6 | `knowledge-ingest` skill | **shipped at v0.0.20** — Slice 2 (audit-only backlink path; `--apply-plan` deferred to a follow-up) |
| 7 | `wiki-composer` agent (fork of cogni-research `writer`) + `knowledge-compose` skill | **shipped at v0.0.22 — Slice 3** (F11 outline-recovery contract preserved through the fork) |
| 8 | `wiki-verifier` agent (replaces cogni-claims verifier) + `revisor` agent (forked from cogni-research, kept local to honour the clean break) + `knowledge-verify` skill | **shipped at v0.0.23 — Slice 4** (zero-network claim alignment; max-2-iteration revisor loop on `unsupported` deviations) |
| 9 | `knowledge-finalize` skill | **shipped at v0.0.24 — Slice 5** (`cycle-guard.py` adapted to read `citation-manifest.json` on v0.1.0 projects via additive fallback; legacy `02-sources/data/` shape still supported. Synthesis page deposit + index update + binding append + context-brief rebuild) |
| 10 | Rebuild `knowledge-query`, `knowledge-dashboard`, `knowledge-resume`, `knowledge-refresh` on new manifests | **shipped** — M10a at v0.0.25 (read-side: query/dashboard/resume read inverted-pipeline state via `pipeline-summary.py`; cogni-research probe dropped); M10b at v0.0.26 (`knowledge-refresh --mode push` rewritten on the seven-phase chain, cogni-research dispatch removed) + cogni-wiki v0.0.45 log-enum cleanup |
| 11 | Archive `knowledge-research` + `knowledge-report` → `_archive/`; rewrite README, CLAUDE.md, references | **shipped at v0.0.27 — Slice 8** |
| 12 | Alpha re-run on `eu-ai-act-v0.1`; bump `plugin.json` + `marketplace.json` to 0.1.0; flip maturity callout to Preview | pending — gates the version bump |

**Current sprint.** Refresh this block on every landing — either replace with the next slice, or mark `complete (next: M<NN>)` until the next planning pass.

*Slice 1 — v0.0.19: M4 end-to-end smoke* — **SHIPPED 2026-05-21** (commit `3b181fe9`). All seven verification steps passed against a fresh `.alpha/eu-ai-act-gpai/` base on topic "EU AI Act GPAI Code of Practice obligations" (6 sub-questions → 57 candidates → 41 fetched + 16 unavailable → 100% cache-hit on re-run → 404 injection clean). Five new findings logged (F13–F17 in `references/alpha-findings.md` §"M4 smoke (2026-05-21)"); two filed as follow-up issues for Slice 2 to close: **#275 (F15 — PDF handling)** and **#276 (F14 — cobrowse_unavailable reason)**. Net code change: zero — docs-only release. **Recommendation: GO** for Slice 2.

*Slice 2 — v0.0.20: M5 + M6 (claim-extractor + source-ingester + knowledge-ingest)* — **SHIPPED 2026-05-21**. Phase-4 ingest step of the inverted pipeline landed: `wiki/sources/<slug>.md` pages get one-per-fetched-URL with `type: source` frontmatter populated by `pre_extracted_claims:` (per `references/claim-at-ingest.md` — verification at draft time becomes a zero-network string match). Bundles closed: **#275** (PDF detection in source-fetcher Step 2 via shared `_knowledge_lib.is_pdf_response`; WebFetch's saved-binary path is read via `Read pages: "1-20"`; EUR-Lex no-saved-path cases record `pdf_extraction_failed` instead of silently dropping) and **#276** (cobrowse_unavailable promoted to documented vocabulary in `references/fetch-cache-design.md` §"Reason semantics"). One deferral: `backlink_audit.py --apply-plan` stays audit-only at v0.0.20; auto-curating which audit candidates to write back requires an LLM pass not in this skill's scope. F11 (0 body-level wikilinks) stays open for the same reason. Net cost: +2 agents, +1 skill, +2 helpers in `_knowledge_lib.py`, +1 contract test file.

*Slice 3 — v0.0.22: M7 (wiki-composer agent + knowledge-compose skill)* — **SHIPPED 2026-05-22**. Phase-5 compose step of the inverted pipeline landed: the populated wiki (M5/M6) gets read by `wiki-composer` (forked from `cogni-research/agents/writer.md`), which emits `<project>/output/draft-vN.md` with `[[sources/<slug>]]` wikilink citations plus `<project>/.metadata/citation-manifest.json` carrying `{draft_position, wiki_slug, claim_id}` per citation — exactly the shape M8's `wiki-verifier` will consume for zero-network claim alignment. F11 contract preserved end-to-end: Phase 1 of the composer persists `writer-outline-vN.json` before any draft `Write`; `knowledge-compose`'s pre-flight detects a leftover outline and passes `RESUME_FROM_OUTLINE=true` so Phase 2 re-runs without re-doing Phase 1. Deferrals (matching Slice 2's "in notes, not issues" pattern): English-only output, standard density only, no story arcs, single-pass (no expansion loops), wikilink-only citation shape, no per-sub-question section sharding. Live end-to-end smoke is M12's job — this release ships contract-test coverage. Net cost: +1 agent, +1 skill, +1 contract test file (`test_compose_contract.sh`); existing tests unaffected.

*Slice 4 — v0.0.23: M8 (wiki-verifier agent + revisor fork + knowledge-verify skill)* — **SHIPPED 2026-05-22**. Phase-6 verify step of the inverted pipeline landed: the citation manifest M7 emits is now consumed by a zero-network claim-alignment pass against each cited page's `pre_extracted_claims:` frontmatter. Verifier scores every citation as `verbatim` / `paraphrase` / `unsupported` (+ informational `synthesis` for `claim_id: null` wikilinks); `revisor` (forked from cogni-research, drift acceptable) closes the loop on `unsupported` deviations with a rephrase-or-drop strategy, capped at 2 iterations per `references/inverted-pipeline.md` Phase 6. The structural cost win versus cogni-claims lands here (target < 5 min vs 20–30 min baseline — exercised at M12). Deferrals (matching Slice 3's "in notes, not issues" pattern): English-only verification, excerpt match by `text`+`excerpt_quote` not by offset, rephrase-or-drop only (cross-page substitute-citation search deferred), revisor drops upstream's expansion-mode + Source-Mode Evidence Gathering + arc-preservation + oscillation detection + confidence-assessment surfaces (all upstream-only). Live end-to-end smoke is M12's job — this release ships contract-test coverage. Net cost: +2 agents (`wiki-verifier` new, `revisor` forked), +1 skill (`knowledge-verify`), +1 contract test file (`test_verify_contract.sh`); `test_skill_contracts.sh` clean-break loop extended to the new files.

*Slice 5 — v0.0.24: M9 (`knowledge-finalize` skill + `cycle-guard.py` v0.1.0 adapter)* — **SHIPPED 2026-05-22**. Phase-7 finalize step of the inverted pipeline landed: the latest verified `draft-vN.md` + `verify-vN.json` + `citation-manifest.json` are read, `cycle-guard.py` (now with a citation-manifest fallback) refuses self-citing loops, and the verified draft is deposited as `<wiki>/syntheses/<slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + an auto-generated `## References` list. Three cogni-wiki helpers run at script level — `wiki_index_update.py --category "Syntheses"`, `config_bump.py --key entries_count --delta 1`, `rebuild_context_brief.py` — so the synthesis is discoverable + the wiki health stays consistent. `binding.research_projects[]` gets a new entry with `report_source: wiki` via `knowledge-binding.py append-project`. The inverted-pipeline loop closes here — future `knowledge-compose` runs read `wiki/syntheses/*.md` as prior cross-source framing, which is the compounding property the differentiation thesis hinges on. **Scope deviation from the M-table:** the M-table line said "M9 reuses `cycle-guard.py` as-is" — exploration showed that the existing guard walks `<project>/02-sources/data/src-*.md`, the legacy cogni-research layout, NOT the v0.1.0 layout where citations live in `<project>/.metadata/citation-manifest.json`. Shipping with the unmodified guard would have made it a silent no-op on v0.1.0 projects. The fix is a strict additive extension (~25 lines): when the legacy glob is empty, read the citation manifest instead. Direct-cycle detection works on both shapes; the new envelope field `data.input_shape ∈ {"legacy-source-entities", "citation-manifest", "none"}` signals which path ran. Existing five `test_cycle_guard_*.sh` tests pass unchanged. **Doc-audit drift fixes** paired into the version bump: Check 3 (`plugin.json::description` rewritten — the v0.1.0 clean break forks 4 agents + adds 3 scripts, so "no forked agents, no duplicated scripts" is false) and Check 5 (`"agents"` added to `keywords[]`). **One contract widening vs the original `inverted-pipeline.md` Phase 7 line 170:** `wiki_index_update.py` joined the helper trio. Without it the new synthesis page never lands in `wiki/index.md` and is not discoverable — both `wiki-query --file-back` and `knowledge-ingest` already adopt this posture. The reference doc is updated in the same PR to match. Live end-to-end smoke is M12's job. Net cost: +1 skill, +1 contract test file, ~25 lines added to `cycle-guard.py`, doc + version bookkeeping.

*Slice 6 — v0.0.25: M10a (read-side adapters)* — **SHIPPED**. The three read-side skills (`knowledge-query` / `knowledge-dashboard` / `knowledge-resume`) now surface inverted-pipeline state via a new standalone CLI `scripts/pipeline-summary.py`: `project --project-path` returns per-project counts from the six `.metadata/` manifests (sub-questions, candidates, fetched/unavailable, ingested/skipped, citations, latest-`verify-vN` verdict `counts`, `phase_reached`), degrading to zeros + `phase_reached: "none"` on legacy v0.0.x deposits; `cache-health --knowledge-root` joins `fetch-cache.py stat` with `binding.curator_defaults.fetch_cache_max_age_days` to emit a knowledge-base-global `{entries, negative_ratio, oldest_age_days, max_age_days, verdict}`. query gains a fetch-cache footer clause; dashboard gains per-project pipeline columns + a `## Pipeline health` block; resume gains per-project depth + a Pipeline status line. **All three drop their cogni-research pre-flight probe to cogni-wiki-only** — the clean-break invariant (decision-1) now holds for the read surface, ahead of M11's archive. `knowledge-binding.py` untouched. New `tests/test_pipeline_summary.sh` (8 fixture-driven assertions); `tests/test_skill_contracts.sh` extended with the read-side probe-drop + pipeline-summary-wiring block. **Recommendation: GO** for M10b.

*Slice 7 — v0.0.26 + cogni-wiki v0.0.45: M10b (refresh push-mode clean break + log-enum cleanup)* — **SHIPPED**. (1) cogni-wiki v0.0.45 appended `compose`/`verify`/`finalize` to the `wiki/log.md` operation enum in `SCHEMA.md.template` + `CLAUDE.md` (additive, no `schema_version` bump — `queue` precedent; these three prefixes had shipped since v0.0.22–24 but were never enumerated; `plan`/`curate`/`fetch` excluded because they never write `wiki/log.md`), with a new `tests/test_log_format_enum.sh`. (2) cogni-knowledge v0.0.26 rewrote `knowledge-refresh --mode push` to run the seven-phase chain (`knowledge-plan` → … → `knowledge-finalize`) per stale topic — uniform `--knowledge-slug`/`--project-path`/`--knowledge-root` dispatch, fail-soft per topic with `{topic, failed_phase, error}` capture, idempotent resume (plan aborts-on-existing so refresh reuses the project dir; downstream phases dedup/skip by construction), cycle-guard delegated to finalize. Dropped the cogni-research pre-flight probe (clean break) and removed every `knowledge-research`/`wiki-refresh`-pair dispatch from push-mode; pull-mode unchanged. `delegation-contract.md` §"Phase-3 push-refresh behaviour" rewritten + the legacy "What about agents/?" section banner-flagged as superseded. New `tests/test_refresh_push_chain.sh`; `test_skill_contracts.sh` + `test_knowledge_setup_probe.sh` updated for the refresh probe split. Live push-mode smoke deferred to M12 (budget too large for CI; the contract is grep-checkable). **Recommendation: GO** for M11.

*Slice 8 — v0.0.27: M11 (archive `knowledge-research` + `knowledge-report` → `_archive/`)* — **SHIPPED**. The two legacy skills + their two private helper scripts (`lineage-stamp.py`, `read-project-config.py`) + the read-project-config test were `git mv`'d to a plugin-root `_archive/` (outside `skills/` so skill discovery and the live `tests/test_*.sh` glob never pick them up — chosen over `skills/_archive/` for that reason; establishes the monorepo `_archive/` convention). `knowledge-setup` dropped its cogni-research probe + "requires both" abort wording (it only ever dispatched `cogni-wiki:wiki-setup`); the surviving legacy-skill references in `knowledge-query` / `knowledge-dashboard` / `knowledge-resume` / `knowledge-plan` / `knowledge-finalize` + `fetch-cache-design.md` were scrubbed. Docs rewritten: README (What it does / Components / How it works), CLAUDE.md (skills + scripts tables, lineage section), `delegation-contract.md` (agents section + report_source wiring). A permanent **audit-grep** in `test_skill_contracts.sh` now fails any PR that re-introduces the legacy chain into `skills/ scripts/ agents/`. Also paired in: backfilled the missing `CHANGELOG.md` 0.0.25 + 0.0.26 entries, and a one-line lost-caller note in `cogni-claims/CLAUDE.md`. **Recommendation: GO** for M12.

*Slice 9 — M12 (alpha re-run gate)* — **RUN 2026-05-23 → HELD (no flip).** First full live end-to-end run of Phases 1–7 on a fresh `.alpha/eu-ai-act-v01/` base (topic "EU AI Act GPAI Code of Practice obligations", 6 sub-questions → 53 candidates → 51 fetched/2 unavailable → 51 ingested / 317 claims → draft-v1 6 570 words / ~169 citations → verify 28 unsupported → revisor → draft-v2 / 10 unsupported). **Pass criteria: C1 ✅ (0 dup fetches), C2 ✅ (0 unreachable cited), C3 ❌ (verify ~16–18 min/pass at 169 citations ≫ 5 min target), C4 ❌ (verify→revise loop does not converge to 0 unsupported within the 2-round cap), C5 ⊘ (F11 live crash-recovery not exercised).** Phases 1–4 are solid at scale. The flip to 0.1.0 / Preview is **blocked on C3 + C4**, which share a root cause: composer and verifier independently re-tokenize the draft into `section:sentence` positions and drift by one (F20 confirmed at M12). Full write-up + fix surfaces in `references/alpha-findings.md` §"M12 alpha re-run (2026-05-23)" (findings **F21–F26**). **Next: rework `draft_position` into a stable composer-emitted / verifier-consumed id (F22), add a deterministic substring pre-filter or per-section sharding for verify wall-clock (F21), bias the revisor to re-point over drop (F23) — then re-run this gate before the v0.1.0 bump.** M11's audit-grep remains the canary that fails the M12 PR if the legacy chain creeps back.

*Slice 10 — v0.0.28: #287 / F22 (cited-text anchor — stable `draft_sentence`)* — **SHIPPED.** Made `draft_position` non-load-bearing. `wiki-composer` now emits `draft_sentence` (the verbatim cited sentence, carrying its `[[…/<slug>]]` wikilink) into each `citation-manifest.json` entry; `wiki-verifier` and `revisor` consume it directly and **never re-tokenize the draft** — so the composer is now the pipeline's *only* tokenizer, and the cross-agent `section:sentence` off-by-one drift that produced the M12 round-0 `unsupported` cluster (F22, the C4 root) is structurally impossible. The verifier locates a citation by substring-presence of `draft_sentence` + confirms the cited slug's wikilink sits inside it; a miss is `unsupported` with the new `reason: cited_text_not_in_draft`, which **replaces `draft_position_out_of_range` 1:1** (emitted by the verifier, pruned inline by `knowledge-verify` Step 3.2, dropped by the revisor as defence-in-depth). The revisor drops its global `draft_position` re-index pass and updates `draft_sentence` in place on rephrase. `draft_sentence` is **required** — no legacy fallback; a pre-#287 manifest aborts the verifier with `manifest_missing_draft_sentence` (→ re-run `knowledge-compose`). Schema stays `0.1.0` (additive field; nothing depends on shipped 0.1.0 manifests, and composer/verifier/revisor ship together). **F20's tokenizer-rewrite urgency drops to near-zero** — positions are now decorative and only the composer tokenizes, so there is no shared rule left to drift; the #289 F20-adjacent concern can be deferred or closed. This is the keystone fix that de-risks #286 (each citation is self-contained → verifier sharding becomes trivial) and #288 (the revisor no longer needs a re-index pass). Net cost: body edits to 3 agents + 2 skills + 3 references + 2 contract tests + CLAUDE.md; +1 drift reason. **Next: #286 (F21, fan out the verifier for the C3 wall-clock) → #288 (F23, bias the revisor to re-point over drop) → re-run the M12 gate before the v0.1.0 / Preview flip.**

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
