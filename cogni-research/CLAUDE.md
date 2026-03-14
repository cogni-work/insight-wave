# cogni-research Development Guide

## Identity

cogni-research is a general-purpose deep research engine with three-layer claim assurance and narrative-driven synthesis. It transforms research questions into traceable, source-backed insights through a 4-stage pipeline.

## Architecture

```
research-plan → findings-sources → claims → synthesis
```

- **7 skills** (4 pipeline + 3 export)
- **7 agents** (dimension-planner, batch-creator, findings-creator ×3, source-creator, claim-extractor)
- **7 entity types** (00-06)
- **8 hooks** (anti-hallucination guardrails)
- **3 research types** (generic, lean-canvas, b2b-ict-portfolio)

## Entity Creation Rules

Entities are ONLY created via `scripts/create-entity.py`. Never use Write or Edit tools to create entity files directly — hooks will block this. Entity files are `.md` with YAML frontmatter, designed to be Obsidian-browsable.

## Cross-Plugin Integration

- **cogni-narrative** — synthesis skill delegates storytelling (6 arc frameworks)
- **cogni-claims** — claims skill submits for source URL verification (optional)
- **cogni-workspace** — theme support for export skills

## Research Types

| Type | DOK | Dimensions | Use Case |
|------|-----|------------|----------|
| generic | 1-4 | Dynamic | Flexible research on any topic |
| lean-canvas | 2 | 9-block | Business model analysis |
| b2b-ict-portfolio | 3 | 8-dimension | B2B ICT provider analysis |

## Key Conventions

- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- All scripts are stdlib-only (bash + python3, no pip dependencies)
- Wikilinks use workspace-relative paths: `[[dir/data/entity-slug]]`
- Phase state tracked via `.metadata/` in project directory
- Bilingual support via ISO 639-1 codes (en, de)
