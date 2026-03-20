# cogni-gpt-researcher Development Guide

## Identity

cogni-gpt-researcher is a multi-agent research report generator inspired by GPT-Researcher's STORM architecture. It translates GPT-Researcher's multi-agent editorial workflow into Claude Code plugin primitives, using WebSearch + WebFetch for web research and cogni-claims for evidence-based review loops.

## Architecture

```
research-report skill (orchestrator, phases 0-6)
  → section-researcher agents (parallel web research, sonnet)
  → local-researcher agents (parallel local document analysis, sonnet)
  → deep-researcher agents (recursive tree exploration, sonnet)
  → source-curator agent (auto for detailed/deep with 8+ sources, sonnet)
  → writer agent (report compilation, sonnet)
  → [optional image generation via cogni-visual or API]
  → reviewer agent (structural-only quality gate, sonnet)

verify-report skill (claims verification, separate context window)
  → claim-extractor agent (draft → verifiable claims, sonnet)
  → cogni-claims integration (submit + verify against source URLs)
  → reviewer agent (structural + claims-based quality gate, sonnet)
  → revisor agent (feedback incorporation, sonnet)
```

The two-skill split ensures claims verification runs in a fresh context window. The research pipeline (phases 0-4) saturates context with sub-questions, contexts, sources, and the draft — leaving insufficient capacity for thorough claims verification. verify-report loads only the draft and source entities, giving the claims pipeline full attention.

Five report types: basic, detailed, deep, outline, resource.
Three source modes: web (default), local (documents only), hybrid (web + documents).
Configurable: tone, citation format, researcher role (auto or manual), source URLs, domain filtering, sub-question count.

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
- **cogni-visual** — optional presentation generation

## Model Strategy

| Tier | Model | Used By |
|------|-------|---------|
| RESEARCH | sonnet | section-researcher, deep-researcher (web), local-researcher (documents) |
| SYNTHESIS | sonnet | writer, reviewer, revisor, claim-extractor |
| ORCHESTRATION | sonnet (skill context) | Sub-question generation, orchestration |

## Research Configuration

Project config (`project-config.json`) supports these optional fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tone` | string | "objective" | Writing tone — see `references/writing-tones.md` |
| `citation_format` | string | "apa" | Citation style (apa/mla/chicago/harvard/ieee/wikilink) — see `references/citation-formats.md` |
| `researcher_role` | string | auto-selected | Domain persona — see `references/agent-roles.md` |
| `report_source` | string | "web" | Research source: web, local, or hybrid |
| `document_paths` | string[] | [] | Local files/globs for local/hybrid mode |
| `source_urls` | string[] | [] | User-provided URLs to research first |
| `query_domains` | string[] | [] | Restrict web search to these domains |
| `max_subtopics` | int | per-type default | Override sub-question count |
| `curate_sources` | bool | auto | Source curation: auto-activates for detailed/deep with 8+ sources. Set `true` to force, `false` to disable |
| `generate_images` | bool | false | Enable AI image generation (placeholder markers if no provider) |

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/execution-log.json`
- Web research uses WebSearch + WebFetch (no MCP search providers), with optional source URL pre-fetch and domain filtering
- Local research uses Read + Glob + Grep tools for document analysis (PDF, MD, TXT, CSV, JSON)
- Hybrid mode runs both web and local researchers in parallel, merging results in context aggregation
- All agents report `cost_estimate` in output JSON (input/output words + estimated USD). Orchestrator accumulates in Phase 6
- Context entities support `follow_up_questions` array (deep research mode) for workspace visibility and writer transitions
