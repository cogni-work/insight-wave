# cogni-gpt-researcher Development Guide

## Identity

cogni-gpt-researcher is a multi-agent research report generator inspired by GPT-Researcher's STORM architecture. It translates GPT-Researcher's multi-agent editorial workflow into Claude Code plugin primitives, using WebSearch + WebFetch for web research and cogni-claims for evidence-based review loops.

## Architecture

```
research-report skill (orchestrator)
  → section-researcher agents (parallel web research, haiku)
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

Entities are ONLY created via `scripts/create-entity.py`. Never use Write or Edit tools to create entity files directly — hooks will block this. Entity files are `.md` with YAML frontmatter, Obsidian-browsable.

## Cross-Plugin Integration

- **cogni-claims** — review loop submits claims for source URL verification (primary integration)
- **cogni-narrative** — optional story arc polish on final report
- **cogni-copywriting** — optional executive polish
- **cogni-visual** — optional presentation generation

## Model Strategy (3-tier)

| Tier | Model | Used By |
|------|-------|---------|
| FAST | haiku | section-researcher (parallel web search) |
| SMART | sonnet | writer, reviewer, revisor, claim-extractor |
| STRATEGIC | sonnet (skill context) | Sub-question generation, orchestration |

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/execution-log.json`
- Web research uses WebSearch + WebFetch exclusively (no MCP search providers)
