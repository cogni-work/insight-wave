# cogni-research Development Guide

## Identity

cogni-research is a multi-agent research report generator inspired by GPT-Researcher's STORM architecture. It translates GPT-Researcher's multi-agent editorial workflow into Claude Code plugin primitives, using WebSearch + WebFetch for web research and cogni-claims for evidence-based review loops.

## Architecture

```
research-setup skill (configuration, project init, AskUserQuestion)
  → interactive Configuration Menu (report type, tone, citations, market, source mode)
  → project directory creation via initialize-project.sh

research-report skill (orchestrator, phases 0.5-6)
  → prerequisite gate: invokes research-setup if no project-config.json
  → section-researcher agents (parallel web research, sonnet)
  → local-researcher agents (parallel local document analysis, sonnet)
  → wiki-researcher agents (parallel cogni-wiki querying, sonnet)
  → deep-researcher agents (recursive tree exploration, sonnet)
  → source-curator agent (auto for detailed/deep with 8+ sources, sonnet)
  → writer agent (report compilation, sonnet)
  → reviewer agent (structural quality gate, sonnet)

verify-report skill (claims verification, separate context window)
  → claim-extractor agent (draft → verifiable claims, sonnet)
  → cogni-claims integration (submit + verify against source URLs)
  → reviewer agent (structural + claims-based quality gate, sonnet)
  → revisor agent (feedback incorporation, sonnet)
```

The three-skill split serves two purposes: (1) research-setup isolates user interaction from the research pipeline — the model cannot race past configuration to start research because setup has no research phases; (2) verify-report runs claims verification in a fresh context window, since the research pipeline saturates context with sub-questions, contexts, sources, and the draft.

Five report types: basic, detailed, deep, outline, resource.
Four source modes: web (default), local (documents only), wiki (cogni-wiki instances), hybrid (web + documents + wikis).
Configurable: market (search localization), output language, tone, citation format, researcher role (auto or manual), source URLs, domain filtering, sub-question count.

## Entity Model (4 types)

| # | Type | Directory | Purpose |
|---|------|-----------|---------|
| 00 | sub-question | `00-sub-questions/` | Decomposed research sub-questions |
| 01 | context | `01-contexts/` | Per-sub-question research results |
| 02 | source | `02-sources/` | Deduplicated source registry |
| 03 | report-claim | `03-report-claims/` | Claims extracted from report draft |

## Entity Creation Rules

Entities are ONLY created via `scripts/create-entity.sh` (bash wrapper that delegates to `create-entity.py`). Never use Write or Edit tools to create entity files directly — hooks will block this. Entity files are `.md` with YAML frontmatter, Obsidian-browsable.

## Cross-Plugin Integration

- **cogni-claims** — verify-report skill submits claims for source URL verification (primary integration)
- **cogni-narrative** — story arc transformation of research output. User invokes `/narrative --source-path <report-output-dir>` after research completes. cogni-narrative auto-bridges `[Source: Publisher](URL)` citations into per-source files via its built-in citation bridge (Phase 0.5).
- **cogni-copywriting** — arc-aware executive polish. User invokes copywriter on narrative output. Auto-activated by `arc_id` frontmatter in narrative output.
- **cogni-visual** — enrich-report is the single output skill for all report formats: themed HTML with interactive charts and concept diagrams, plus optional PDF and DOCX export via the `formats` parameter. The deprecated export-report skill remains as a fallback but is superseded by enrich-report. Optional presentation generation via story-to-slides.
- **cogni-wiki** — wiki-researcher agent queries user's cogni-wiki instances for sub-question answers. The wiki's compiled, cross-referenced knowledge serves as a local RAG source. Source provenance: `wiki://<slug>/<page>`, publisher: `cogni-wiki:<slug>`. Activated when `report_source` is `wiki` or `hybrid` with `wiki_paths` configured.

## Model Strategy

| Tier | Model | Used By |
|------|-------|---------|
| RESEARCH | sonnet | section-researcher, deep-researcher (web), local-researcher (documents), wiki-researcher (cogni-wiki) |
| SYNTHESIS | sonnet | writer, reviewer, revisor, claim-extractor |
| ORCHESTRATION | sonnet (skill context) | Sub-question generation, orchestration |

## Research Configuration

Project config (`project-config.json`) supports these optional fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | *required* | Region code for search localization. Must be one of the keys in `references/market-sources.json`: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. `eu` is a composite market that fans out per-country researchers. No `global` option — research-setup resolves ambiguity by asking the user. The script refuses to run without a valid code (the only compat exception is legacy `--language de` → `dach`). |
| `output_language` | string | auto from market | ISO 639-1 code for report output language. Defaults to market's `default_output_language`. Can diverge from market (e.g., market=fr, output_language=en) |
| `language` | string | "en" | **Legacy** — backward compat alias. When set without `market`, "de" maps to `market=dach` as a compat bridge; any other language without an explicit market causes `initialize-project.sh` to exit with an error (research-setup resolves ambiguity by asking the user). |
| `tone` | string | "objective" | Writing tone — see `references/writing-tones.md` |
| `citation_format` | string | "apa" | Citation style (apa/mla/chicago/harvard/ieee/wikilink/local-wikilink) — see `references/citation-formats.md` |
| `researcher_role` | string | auto-selected | Domain persona — see `references/agent-roles.md` |
| `report_source` | string | "web" | Research source: web, local, wiki, or hybrid |
| `document_paths` | string[] | [] | Local files/globs for local/hybrid mode |
| `wiki_paths` | string[] | [] | cogni-wiki root paths for wiki/hybrid mode. Each path must contain `.cogni-wiki/config.json` |
| `source_urls` | string[] | [] | User-provided URLs to research first |
| `query_domains` | string[] | [] | Restrict web search to these domains |
| `max_subtopics` | int | per-type default | Override sub-question count |
| `curate_sources` | bool | auto | Source curation: auto-activates for detailed/deep with 8+ sources. Set `true` to force, `false` to disable |
| `confirm_plan` | bool | `true` | Phase 1.5 execution plan preview: when `true`, research-report prints the plan (sub-Q count × channels × agent type × recursion × batches × cost) and asks the user to confirm or adjust before spawning researchers. Set `false` for silent runs — plan is still logged to `.logs/phase-1.5-plan.json` |
| `recursive_depth` | int | `2` when `report_type == "deep"`, else `0` | Controls deep-mode web researcher type. `0` forces `section-researcher` even in deep mode (flat single-pass); `2` uses `deep-researcher` with 2-level internal recursion. Ignored in basic/detailed/outline/resource modes. **Deep mode defaults to 2** — a missing or null field resolves to 2 in Phase 1.5a, closing the prior silent-downgrade loophole. The user can still explicitly set 0 to opt down, or use "Disable recursion" in the Phase 1.5c plan-confirmation menu |
| `batch_size` | int | `4` | Parallel researcher batch size in Phase 2. `2` is gentler on WebFetch rate limits; `6` is faster on quiet markets. Applies to all source modes |
| `allow_short` | bool | `false` | When `true`, the Phase 4.5 word-count gate logs any shortfall but skips the writer expansion re-dispatch, and the Phase 5 expansion-review loop is skipped. The reviewer's stepped completeness cap still applies (the verdict is still honest), and the Phase 6 summary still surfaces the deficit warning — this flag only disables the automatic expansion attempts. Use when a power user wants deep-mode tree structure but intends to hand-edit prose downstream |
| `target_words` | int | default-by-depth (basic 3000, detailed 5000, **deep 5000** (was 8000 before v0.7.7), outline 1000, resource 1500) | Writer word-count floor, independent of `report_type`. Set explicitly to override the default-by-depth. Resolved at project creation by `initialize-project.sh` and pinned into `project-config.json` for the project's lifetime. Phase 4 writer dispatch, Phase 4.5 writer gate, Phase 5 expansion loop, and Phase 6 promotion gate all resolve their floor from this field. `initialize-project.sh --target-words <N>` takes a positive integer. In v0.7.7 (issue #35) the deep default was reduced from 8000 to 5000 to align with professional deep-research norms and the single-voice writer's ~5.6–6.1K single-call ceiling; set `target_words: 8000` for the old 8K-deep long-form behaviour. The Phase 6 promotion gate hard-stops only when `report_type == "deep"` AND `target_words >= 8000` AND `allow_short != true` — at `target_words < 8000` (including the new 5K default) the gate is advisory, matching detailed/basic behaviour |

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/execution-log.json`
- Web research uses WebSearch + WebFetch (no MCP search providers), with market-localized search (intent-based language routing via `references/market-sources.json`), optional source URL pre-fetch, and domain filtering
- Local research uses Read + Glob + Grep tools for document analysis (PDF, MD, TXT, CSV, JSON)
- Wiki research queries cogni-wiki instances via index-first page discovery (Read + Glob + Grep on wiki directories)
- Hybrid mode runs available researcher types in parallel. Web stays 1:1 per sub-question; wiki/local agents batch sub-questions against a shared corpus sweep (asymmetric allocation heuristic in `skills/research-report/SKILL.md` Phase 1.5a, capped at 4 agents per bounded channel, `N < 4` sub-questions falls back to legacy 1:1). Results merge in context aggregation
- All agents report `cost_estimate` in output JSON (input/output words + estimated USD). Orchestrator accumulates in Phase 6
- Context entities support `follow_up_questions` array (deep research mode) for workspace visibility and writer transitions
- **Word-count enforcement chain (v0.7.1 single-voice expansion, v0.7.7 length decoupling)**: writer runs only in `full` mode for every report type. Phase 4 dispatches one writer call with `TARGET_MIN_WORDS` resolved from `project-config.json target_words` (default-by-depth fallback: basic 3000, detailed 5000, deep 5000, outline 1000, resource 1500 — deep was 8000 before v0.7.7). The writer commits `.metadata/writer-outline-v{N}.json` (per-section budgets, zero-padded indices) and produces the full draft in one response. Phase 4.5 Step 0 checks the draft exists on disk and re-dispatches once if the writer silently failed to persist. Phase 4.5 Step 4 re-dispatches the whole draft once at `gate_floor = target_words × 0.9` (10% tolerance, uniform across report types) with `TARGET_MIN_WORDS` + `EXPANSION_NOTES`. Phase 5 structural review has a word-deficit expansion loop keyed off the reviewer's `Word deficit` issue prefix: basic/detailed/outline/resource cap at **2 iterations**, deep caps at **3 iterations**. The iteration caps are a structural property of single-call output ceilings, not of the floor — deep still caps at 3 even when `target_words: 5000` because deep mode's tree structure and coherence properties are depth-driven, not length-driven. For `target_words >= 8000`, deep mode must compound (writer → revisor → revisor) across three calls to reach the floor while preserving single-voice coherence — empirical reference point is the KI-Adoption corpus run that produced 8,423 words / accept 0.872 on exactly this chain. For the new v0.7.7 `target_words: 5000` deep default, a single writer pass usually clears the floor without needing the expansion chain, so the 3-iteration cap becomes a rarely-exercised safety net. Phase 5 iteration persistence is still gated on a `[ -s .metadata/review-verdicts/v{N}.json ]` existence check after each follow-up reviewer dispatch. Phase 6 promotion gate: hard stop only when `report_type == "deep"` AND `target_words >= 8000` AND `allow_short: true` is not set — the gate prompts accept-short / retry-expansion / abort. For `target_words < 8000` (including the new 5K deep default) and all non-deep modes, the gate is advisory: short drafts promote automatically with a `⚠ Below target` line in the Phase 6 summary. `allow_short: true` short-circuits both Phase 4.5 expansion and the Phase 5 word-deficit loop regardless of `target_words`. The reviewer's Word Count Gate adds a `[0.98, 1.00) = 0.75` rounding-noise band (low-severity `Word deficit (rounding-noise)`, no expansion trigger) so drafts within 2% of the floor don't bounce pointlessly, plus the existing `[0.75, 0.98) = 0.60`, `[0.50, 0.75) = 0.45`, `< 0.50 = 0.30` caps for real shortfalls.
- Context aggregation caps scale by `report_type` (research depth) in `scripts/merge-context.py`, NOT by `target_words` — evidence density is a depth property, not a length property. Deep mode gets 45K words of input (up from the legacy flat 25K) so the writer has enough raw material to retain evidence density even when `target_words: 8000+` requires compounding expansion. A deep project with `target_words: 5000` still gets the 45K input cap because the tree shape (10–20 leaves) is unchanged — length was decoupled, depth was not. The legacy `--slice-sections` mode is gone — per-section context slicing only existed to feed the v0.7.0 sharded section dispatch, which is reverted.
