---
name: tips-selection
description: |
  Interactive TIPS (Trend-Implications-Possibilities-Solutions) candidate generation workflow for smarter-service research projects. Generates 60 trend candidates across 4 dimensions and 3 horizons using web research and training knowledge, presents them for user review, and auto-selects all 60 for downstream dimension-planner integration. This skill is a mandatory prerequisite for dimension-planner when research_type is smarter-service. Use when: (1) starting smarter-service research that needs TIPS candidates, (2) user mentions "TIPS selection", "trend candidates", or wants to generate research candidates, (3) dimension-planner halts due to missing agreed-trend-candidates.json, (4) user wants to customize or regenerate trend candidates before research planning.
---

# TIPS Selection

Generate and finalize 60 TIPS trend candidates for smarter-service research projects.

## Why This Skill Exists

The dimension-planner skill needs a curated set of trend candidates to generate refined research questions. This skill produces those candidates by combining live web research with training knowledge, organized across 4 dimensions and 3 horizons. All 60 candidates are auto-selected — the user reviews them but doesn't need to down-select.

## Prerequisites

- Research project with `research_type: smarter-service` in question frontmatter
- `industry_sector` field in question frontmatter (or extractable from `research_context`)

## References

Read references only when entering the corresponding phase:

| Reference | When to read |
|-----------|-------------|
| [phase-0-initialize.md](references/workflow-phases/phase-0-initialize.md) | Starting the skill — load project context |
| [phase-0.5-web-research.md](references/workflow-phases/phase-0.5-web-research.md) | Running web searches for trend signals |
| [phase-1-generate.md](references/workflow-phases/phase-1-generate.md) | Generating 60 candidates |
| [phase-2-present.md](references/workflow-phases/phase-2-present.md) | Writing trend-candidates.md |
| [phase-3-finalize.md](references/workflow-phases/phase-3-finalize.md) | Building agreed-trend-candidates.json |

## Workflow

```
Phase 0 → Phase 0.5 → Phase 1 → Phase 2 → Phase 3
  │           │          │          │          │
  │           │          │          │          └─ Write agreed JSON, done
  │           │          │          └─ Write trend-candidates.md for user review
  │           │          └─ Generate 60 candidates (web + training mix)
  │           └─ Web search for trend signals (8 searches)
  └─ Load project context, validate prerequisites
```

Track progress using TodoWrite:

1. Phase 0: Initialize & Load Context
2. Phase 0.5: Web Research (if enabled)
3. Phase 1: Generate 60 Candidates
4. Phase 2: Present Candidates
5. Phase 3: Finalize Agreed Candidates

### Phase 0: Initialize

Read [phase-0-initialize.md](references/workflow-phases/phase-0-initialize.md).

Extract PROJECT_PATH, INDUSTRY_SECTOR, and WEB_RESEARCH_ENABLED from the question file. Validate the project is smarter-service type. If trend-candidates.md already exists with status `agreed`, nothing to do.

### Phase 0.5: Web Research

Read [phase-0.5-web-research.md](references/workflow-phases/phase-0.5-web-research.md).

Run 8 web searches (4 dimensions x 2 regions: global + DACH) to gather current trend signals. These signals enrich candidate generation in Phase 1. If all searches fail, proceed with training knowledge only.

Web research is enabled by default. Disable via `web_research: false` in question frontmatter.

### Phase 1: Generate Candidates

Read [phase-1-generate.md](references/workflow-phases/phase-1-generate.md).

Generate 60 trend candidates: 5 per cell across a 4x3 matrix (4 dimensions x 3 horizons). Mix web-sourced and training-sourced candidates. Each candidate includes trend name, 3 keywords, rationale, source type, and freshness indicator.

### Phase 2: Present Candidates

Read [phase-2-present.md](references/workflow-phases/phase-2-present.md).

Write `trend-candidates.md` to `{PROJECT_PATH}/02-refined-questions/data/`. This file is a human-readable record of all 60 candidates organized by dimension and horizon. Inform the user the file is ready for review.

### Phase 3: Finalize

Read [phase-3-finalize.md](references/workflow-phases/phase-3-finalize.md).

Auto-select all 60 candidates and write `agreed-trend-candidates.json` to `.metadata/`. Update trend-candidates.md status to `agreed`. The dimension-planner skill will pick up this JSON file automatically.

---

## Dimension Matrix

| Dimension | German | TIPS Focus | Description |
|-----------|--------|------------|-------------|
| externe-effekte | Externe Effekte | Trend (T) | External forces, regulations, market shifts |
| neue-horizonte | Neue Horizonte | Possibilities (P) | Strategic options, business model evolution |
| digitale-wertetreiber | Digitale Wertetreiber | Implications (I) | Value creation, digital impact |
| digitales-fundament | Digitales Fundament | Solutions (S) | Capabilities, infrastructure, enablers |

### Horizons

| Horizon | Timeframe | Character |
|---------|-----------|-----------|
| act | 0-2 years | Immediate, validated, ready for implementation |
| plan | 2-5 years | Emerging, requires preparation |
| observe | 5+ years | Future, speculative, monitoring stage |

## Output Files

### trend-candidates.md

Location: `{PROJECT_PATH}/02-refined-questions/data/trend-candidates.md`

Human-readable record with all 60 candidates in tables, organized by dimension and horizon. Includes source provenance and freshness indicators.

### agreed-trend-candidates.json

Location: `{PROJECT_PATH}/.metadata/agreed-trend-candidates.json`

```json
{
  "metadata": {
    "industry_sector": "manufacturing",
    "agreed_at": "2026-03-04T10:30:00Z",
    "total_candidates": 60,
    "source_skill": "tips-selection",
    "web_research_status": "success",
    "web_sourced_count": 28,
    "training_sourced_count": 32
  },
  "candidates": [
    {
      "dimension": "externe-effekte",
      "horizon": "act",
      "sequence": 1,
      "trend_name": "EU AI Act Compliance",
      "keywords": ["ai-act", "regulation", "2026"],
      "rationale": "Immediate deadline pressure",
      "source": "web-signal",
      "source_url": "https://...",
      "freshness_date": "2026-01"
    }
  ]
}
```

## Integration

After this skill completes, the user runs `dimension-planner`. That skill checks for `.metadata/agreed-trend-candidates.json` — if present and valid (60 candidates), it uses them; if missing, it halts with an instruction to run `tips-selection` first.

## Error Handling

| Scenario | Response |
|----------|----------|
| Missing question file | Exit — cannot proceed without project context |
| research_type not smarter-service | Exit — this skill only handles smarter-service |
| industry_sector not found | Ask the user to provide it |
| All web searches fail | Proceed with training-only generation (warning logged) |
| trend-candidates.md already agreed | Nothing to do — inform user |
