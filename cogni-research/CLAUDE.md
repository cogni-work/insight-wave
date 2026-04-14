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
| `citation_format` | string | "apa" | Citation style (apa/mla/chicago/harvard/ieee/wikilink) — see `references/citation-formats.md` |
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

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/execution-log.json`
- Web research uses WebSearch + WebFetch (no MCP search providers), with market-localized search (intent-based language routing via `references/market-sources.json`), optional source URL pre-fetch, and domain filtering
- Local research uses Read + Glob + Grep tools for document analysis (PDF, MD, TXT, CSV, JSON)
- Wiki research queries cogni-wiki instances via index-first page discovery (Read + Glob + Grep on wiki directories)
- Hybrid mode runs available researcher types in parallel (web + local + wiki), merging results in context aggregation
- All agents report `cost_estimate` in output JSON (input/output words + estimated USD). Orchestrator accumulates in Phase 6
- Context entities support `follow_up_questions` array (deep research mode) for workspace visibility and writer transitions
- **Word-count enforcement chain (v0.7.0, deep mode)**: writer runs in three modes — `outline` (Phase 4a commits `.metadata/writer-outline-v{N}.json` with per-section budgets and zero-padded indices, no prose), `section` (Phase 4b fans out one dispatch per outline entry, each writing `.metadata/draft-sections/section-{NN}.md` with its own fresh output budget, reading only a pre-sliced context at `.metadata/section-contexts/section-{NN}.json` produced by `scripts/merge-context.py --slice-sections`), and `full` (unchanged legacy monolithic dispatch, used by basic/detailed/outline/resource). Phase 4c runs `scripts/assemble-draft.sh` to concatenate sections into `output/draft-v{N}.md`, backfill `drafted_words` into the outline, and emit per-section deficits. Phase 4.5 in deep mode re-dispatches **only underrunning sections** (not the whole draft) with `WRITER_MODE=section` + `EXPANSION_NOTES`, re-runs `assemble-draft.sh`, and caps at one expansion pass. The deep `gate_floor` is `1.0 × floor` (no tolerance) because section dispatch is expected to hit budget reliably — the historical `0.9 × floor` tolerance exists only for basic/detailed/outline/resource. Phase 5 iteration-2 is gated on an explicit `.metadata/review-verdicts/v2.json` file-existence check after the reviewer re-dispatch and halts hard if the reviewer failed to persist. Phase 6 promotion is gated: in deep mode, if the final draft is below 8,000 words and `allow_short: true` is not set, the orchestrator asks the user to accept-short / retry-sections / abort rather than silently promoting. The `allow_short: true` flag short-circuits both per-section expansion and iteration-2 review. Non-deep modes retain the legacy chain verbatim: write-failure recovery in Phase 4.5 Step 0, whole-draft expansion re-dispatch at `floor × 0.9`, reviewer Word Count Gate stepped cap (0.30 / 0.45 / 0.60), iteration-2 on `Word deficit` verdicts, and advisory Phase 6 warnings.
- Context aggregation caps scale by report type in `scripts/merge-context.py` — deep mode gets 45K words of input (up from the legacy flat 25K) so the writer has enough raw material to retain evidence density at the 8K output floor. In deep mode, `merge-context.py --slice-sections` emits per-section context slices to `.metadata/section-contexts/section-{NN}.json` so each section-writer dispatch reads only the contexts matching its `covers_sub_questions`, keeping each call's input budget small and predictable
