# cogni-gpt-researcher Development Guide

## Identity

cogni-gpt-researcher is a multi-agent research report generator inspired by GPT-Researcher's STORM architecture. It translates GPT-Researcher's multi-agent editorial workflow into Claude Code plugin primitives, using WebSearch + WebFetch for web research and cogni-claims for evidence-based review loops.

## Architecture

```
research-report skill (orchestrator)
  → section-researcher agents (parallel web research, sonnet)
  → writer agent (report compilation, sonnet)
  → claim-extractor agent (draft → claims, sonnet)
  → cogni-claims integration (submit + verify)
  → reviewer agent (quality gate with verification data, sonnet)
  → revisor agent (feedback incorporation, sonnet)
```

Three report types: basic (3-5 sub-questions), detailed (5-10 sections), deep (recursive tree).

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

- **cogni-claims** — review loop submits claims for source URL verification (primary integration)
- **cogni-narrative** — story arc transformation via `research-story` pipeline (narrative-writer agent, narrative-review, narrative-adapt)
- **cogni-copywriting** — arc-aware executive polish via `research-story` pipeline (auto-activated by `arc_id` frontmatter)
- **cogni-visual** — optional presentation generation

### research-story Pipeline

The `research-story` skill chains three plugins: research-report → cogni-narrative → cogni-copywriting.
Citation bridge script (`scripts/bridge-citations.py`) converts `[Source: Publisher](URL)` citations
into per-source `.md` files that cogni-narrative can reference as `<sup>[N](file.md)</sup>`.
The `arc_id` field in narrative output frontmatter auto-activates cogni-copywriting's arc-aware mode.

## Model Strategy

| Tier | Model | Used By |
|------|-------|---------|
| RESEARCH | sonnet | section-researcher, deep-researcher (parallel web search) |
| SYNTHESIS | sonnet | writer, reviewer, revisor, claim-extractor |
| ORCHESTRATION | sonnet (skill context) | Sub-question generation, orchestration |

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/execution-log.json`
- Web research uses WebSearch + WebFetch exclusively (no MCP search providers)
