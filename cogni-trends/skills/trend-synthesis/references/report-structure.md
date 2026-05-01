# Report Structure Template

Reference for dimension section templates written by trend-research Phase 1 agents. The overall report assembly is handled by [synthesis-skeleton.md](synthesis-skeleton.md).

---

## Dimension Section Template (written by agents)

Each agent writes its dimension section following this structure:

```markdown
## {TIPS_LETTER} — {DIMENSION_LABEL}: {DIMENSION_DISPLAY_NAME}

### {HORIZON_ACT_LABEL} (0-2 {YEARS_LABEL})

#### 1. {Trend Name}

**{OVERVIEW_LABEL}** — {Description with quantitative evidence and inline citations.
The market for X reached $Y billion in 2025 [Source Title](url), representing
a Z% increase year-over-year [Another Source](url).}

**{IMPLICATIONS_LABEL}** — {Impact analysis on the specific industry/subsector.}

**{OPPORTUNITIES_LABEL}** — {Possibilities enabled by this trend.}

**{ACTIONS_LABEL}** — {Concrete recommended steps for organizations.}

---

#### 2. {Next Trend Name}
[...repeat for all trends in this horizon...]

### {HORIZON_PLAN_LABEL} (2-5 {YEARS_LABEL})
[...same structure...]

### {HORIZON_OBSERVE_LABEL} (5+ {YEARS_LABEL})
[...same structure...]
```

---

## Trailing Newline Requirement

Every `.logs/` file MUST end with exactly two trailing newlines (`\n\n`). This ensures clean section boundaries after concatenation — no missing blank lines between sections and no extra whitespace accumulation.

- Agent-written files: enforced by `trend-report-writer` agent (Step 4)
- Orchestrator-written files: enforced by trend-synthesis Phase 2 steps

---

## Citation Format

All citations in the report body use generic markdown links:

```markdown
The market reached $6.9 billion in 2024 [Gartner Report](https://gartner.com/...).
```

This format is:
- Human-readable in prose
- Parseable by claim-extractor (0.9 proximity confidence)
- Compatible with cogni-visual:enrich-report and export-pdf-report rendering
