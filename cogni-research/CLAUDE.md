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
| `market` | string | "global" | Region code for search localization (global/dach/de/fr/it/pl/nl/es/us/uk/eu). Controls local-language query generation, authority source boosts, and geographic modifiers. `eu` is a composite market that fans out per-country researchers. See `references/market-sources.json` |
| `output_language` | string | auto from market | ISO 639-1 code for report output language. Defaults to market's `default_output_language`. Can diverge from market (e.g., market=fr, output_language=en) |
| `language` | string | "en" | **Legacy** — backward compat alias. When set without `market`, "de" maps to market=dach, "en" maps to market=global |
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
