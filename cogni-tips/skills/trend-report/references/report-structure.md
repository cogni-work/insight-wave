# Report Structure Template

Reference for assembling the final TIPS trend report in Phase 2.

This reference covers the **catalog mode** (dimensional report). For **theme mode** (strategic themes report), see [phase-2-strategic-themes.md](phase-2-strategic-themes.md) — that reference has its own frontmatter, section order, and assembly strategy.

---

## Report Modes

| Mode | Condition | Organizing Principle | Reference |
|------|-----------|---------------------|-----------|
| **Theme** | `tips-value-model.json` exists with themes | Strategic themes → value chains → evidence | `phase-2-strategic-themes.md` |
| **Catalog** | No value model available | TIPS dimensions → horizons → individual trends | This file |

Phase 0 sets `THEME_MODE` based on value-model detection. Phase 2 reads the appropriate reference.

---

## Catalog Mode

### Frontmatter

```yaml
---
title: "TIPS Trend Report: {TOPIC} in {SUBSECTOR}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
generated_by: trend-report
source_skill: trend-scout
total_trends: 60
total_claims: {N}
generated_at: "{ISO-8601}"
dimensions:
  - externe-effekte
  - digitale-wertetreiber
  - neue-horizonte
  - digitales-fundament
horizons:
  - act
  - plan
  - observe
---
```

---

## Section Order

The report follows this exact section order:

```text
1. Title (H1)
2. Executive Summary (H2)
3. T — Trends: External Effects (H2)
   3a. ACT Horizon (H3) → individual trends (H4)
   3b. PLAN Horizon (H3) → individual trends (H4)
   3c. OBSERVE Horizon (H3) → individual trends (H4)
4. I — Implications: Digital Value Drivers (H2)
   [same horizon structure]
5. P — Possibilities: New Horizons (H2)
   [same horizon structure]
6. S — Solutions: Digital Foundation (H2)
   [same horizon structure]
7. Portfolio Analysis (H2)
   7a. Horizon Distribution (H3)
   7b. Confidence Distribution (H3)
   7c. Signal Intensity (H3)
   7d. Leading/Lagging Balance (H3)
   7e. Evidence Coverage (H3)
8. Claims Registry (H2)
```

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

## Executive Summary Template

```markdown
## {EXEC_SUMMARY_LABEL}

{500-word cross-cutting summary covering:}

1. **{CROSS_CUTTING_THEMES_LABEL}** — 3-5 themes that span multiple dimensions
2. **{KEY_FINDINGS_LABEL}** — Most impactful trends with supporting quantitative evidence
3. **{INDICATOR_BALANCE_LABEL}** — Balance between leading and lagging indicators
4. **{STRATEGIC_POSTURE_LABEL}** — Overall assessment (proactive vs reactive positioning)
```

---

## Portfolio Analysis Template

```markdown
## {PORTFOLIO_ANALYSIS_LABEL}

### {HORIZON_DISTRIBUTION_LABEL}

| {DIMENSION_LABEL} | ACT | PLAN | OBSERVE | {TOTAL_LABEL} |
|-----------|-----|------|---------|-------|
| {dim1} | N | N | N | N |
| {dim2} | N | N | N | N |
| {dim3} | N | N | N | N |
| {dim4} | N | N | N | N |
| **{TOTAL_LABEL}** | **N** | **N** | **N** | **60** |

### {CONFIDENCE_DISTRIBUTION_LABEL}

| {DIMENSION_LABEL} | {HIGH_LABEL} | {MEDIUM_LABEL} | {LOW_LABEL} | {UNCERTAIN_LABEL} |
|-----------|------|--------|-----|-----------|
| ... | ... | ... | ... | ... |

### {SIGNAL_INTENSITY_LABEL}

| {DIMENSION_LABEL} | {AVG_INTENSITY_LABEL} (1-5) | {STRONGEST_TREND_LABEL} |
|-----------|-------------------|-----------------|
| ... | ... | ... |

### {LEADING_LAGGING_LABEL}

| {DIMENSION_LABEL} | {LEADING_LABEL} | {LAGGING_LABEL} | {RATIO_LABEL} |
|-----------|---------|---------|-------|
| ... | ... | ... | ... |

### {EVIDENCE_COVERAGE_LABEL}

| {DIMENSION_LABEL} | {WITH_EVIDENCE_LABEL} | {QUALITATIVE_ONLY_LABEL} | {COVERAGE_PCT_LABEL} |
|-----------|---------------|-----------------|-------------|
| ... | ... | ... | ... |
```

---

## Claims Registry Template

```markdown
## {CLAIMS_REGISTRY_LABEL}

{CLAIMS_REGISTRY_INTRO}

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {DIMENSION_LABEL} |
|---|-------|-------|--------|-----------|
| 1 | {claim text} | {value + unit} | [{title}](url) | {dimension} |
| 2 | ... | ... | ... | ... |

{TOTAL_LABEL}: {N} {CLAIMS_LABEL}
```

---

## Assembly Strategy

The final report is assembled incrementally to avoid token overflow. The orchestrator writes 3 small files; the 4 dimension sections are already on disk from Phase 1 agents. A single `cat` concatenates all 7 files.

### File-to-Section Mapping

| # | Log File | Section | Written By |
|---|----------|---------|------------|
| 1 | `.logs/report-header.md` | Frontmatter + Title + Executive Summary | Orchestrator (Step 2.4) |
| 2 | `.logs/report-section-externe-effekte.md` | T — Trends: External Effects | Agent (Phase 1) |
| 3 | `.logs/report-section-digitale-wertetreiber.md` | I — Implications: Digital Value Drivers | Agent (Phase 1) |
| 4 | `.logs/report-section-neue-horizonte.md` | P — Possibilities: New Horizons | Agent (Phase 1) |
| 5 | `.logs/report-section-digitales-fundament.md` | S — Solutions: Digital Foundation | Agent (Phase 1) |
| 6 | `.logs/report-portfolio.md` | Portfolio Analysis | Orchestrator (Step 2.4a) |
| 7 | `.logs/report-claims-registry.md` | Claims Registry | Orchestrator (Step 2.4b) |

### Concatenation Command

```bash
cat \
  "{PROJECT_PATH}/.logs/report-header.md" \
  "{PROJECT_PATH}/.logs/report-section-externe-effekte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitale-wertetreiber.md" \
  "{PROJECT_PATH}/.logs/report-section-neue-horizonte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitales-fundament.md" \
  "{PROJECT_PATH}/.logs/report-portfolio.md" \
  "{PROJECT_PATH}/.logs/report-claims-registry.md" \
  > "{PROJECT_PATH}/tips-trend-report.md"
```

### Trailing Newline Requirement

Every `.logs/` file MUST end with exactly two trailing newlines (`\n\n`). This ensures clean section boundaries after concatenation — no missing blank lines between sections and no extra whitespace accumulation.

- Agent-written files: enforced by `trend-report-writer` agent (Step 4)
- Orchestrator-written files: enforced by Steps 2.4, 2.4a, 2.4b

---

## Citation Format

All citations in the report body use generic markdown links:

```markdown
The market reached $6.9 billion in 2024 [Gartner Report](https://gartner.com/...).
```

This format is:
- Human-readable in prose
- Parseable by claim-extractor (0.9 proximity confidence)
- Compatible with export-html-report and export-pdf-report rendering
