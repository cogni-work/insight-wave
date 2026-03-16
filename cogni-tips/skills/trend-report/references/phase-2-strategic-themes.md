# Phase 2: Strategic Theme Assembly

Phase 2 assembles the report around strategic themes from `tips-value-model.json`. The dimensional evidence gets enriched in Phase 1 — this phase restructures it into strategic narratives.

The core idea: themes are the skeleton, individual trends are the evidence woven into each theme's story. A CxO reads themes and investment decisions, not a catalog of 60 trends sorted by dimension.

---

## Inputs

| Source | Content | Read from |
|--------|---------|-----------|
| Strategic Themes | Theme definitions with value chains | `{PROJECT_PATH}/.logs/phase2-value-model.json` → `themes[]` |
| Value Chains | T→I→P causal paths | `{PROJECT_PATH}/.logs/phase2-value-model.json` → `value_chains[]` |
| Solution Templates | What to build per theme | `{PROJECT_PATH}/.logs/phase2-value-model.json` → `solution_templates[]` (may be empty if value-modeler Phase 2 hasn't run) |
| Per-trend evidence | Evidence blocks keyed by candidate_ref | `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` (4 files) |
| Claims | Quantitative claims keyed by ID | `{PROJECT_PATH}/.logs/claims-{dimension}.json` (4 files) |
| i18n labels | Section headings in target language | Loaded in Phase 0 |

---

## Step 2.1: Build Lookups

Read all 4 `enriched-trends-{dimension}.json` files and build a single lookup map:

```
candidate_ref → { name, horizon, evidence_md, implications_md, opportunities_md, actions_md, claims_refs, has_quantitative_evidence }
```

The `actions_md` field contains semicolon-separated action keywords (3-5 words each), e.g. `"pilot predictive maintenance; integrate OT/IT data layer; establish vendor shortlist"`. These are compressed intent markers, not full prose — Phase 2 synthesizes complete strategic actions at theme level using these as input.

Read all 4 `claims-{dimension}.json` files and build a claims lookup:

```
claim_id → { text, value, unit, type, context, citations }
```

Read `.logs/phase2-value-model.json` (pruned subset created in Phase 0 Step 0.2b) and extract:
- `themes[]` — ordered list of strategic themes
- `value_chains[]` — all value chains with candidate_refs
- `solution_templates[]` — solution templates linked to themes (may be empty; only `st_id`, `name`, `category`, `enabler_type`, `theme_ref` fields)
- `coverage` — linked/orphaned/total counts
- `mece_validation` — theme count, ME/CE status
- `orphan_candidates[]` — candidates not in any theme

---

## Step 2.2: Generate Strategic Executive Summary

The executive summary leads with the strategic themes table — this is the first thing the reader sees after the title. It answers "what are our strategic bets?" before anything else.

Write `{PROJECT_PATH}/.logs/report-header.md` containing:

### Frontmatter

```yaml
---
title: "{REPORT_TITLE}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
generated_by: trend-report
source_skills:
  - trend-scout
  - value-modeler
report_mode: strategic-themes
total_trends: 60
total_themes: {N}
total_claims: {N}
generated_at: "{ISO-8601}"
---
```

Note `report_mode: strategic-themes` and `source_skills` includes `value-modeler`.

### Executive Summary Content

```markdown
# {REPORT_TITLE}

## {EXEC_SUMMARY_LABEL}

{Opening paragraph: 2-3 sentences framing the strategic landscape for this industry/subsector.
What macro forces are reshaping the competitive environment? Set the stage for the themes.}

### {STRATEGIC_THEMES_OVERVIEW_LABEL}

| # | {THEME_LABEL} | {STRATEGIC_QUESTION_LABEL} | {EXECUTIVE_SPONSOR_LABEL} |
|---|---------------|---------------------------|---------------------------|
| 1 | {theme.name} | {theme.strategic_question} | {theme.executive_sponsor_type} |
| 2 | ... | ... | ... |

{Bridging paragraph: How these themes relate to each other. Are there dependencies?
Which themes are act-now vs. watch-and-prepare? What's the overall strategic posture?}

### {HEADLINE_EVIDENCE_LABEL}

{Pick 3-5 of the most impactful quantitative claims across all themes. Each should
support a different theme. Format as a tight bulleted list with inline citations.}

### {STRATEGIC_POSTURE_LABEL}

{Assessment based on horizon distribution of theme-linked trends:
- Heavy ACT concentration → "immediate action required across multiple fronts"
- Mixed ACT/PLAN → "selective near-term action with medium-term strategic bets"
- Heavy PLAN/OBSERVE → "monitoring posture with time to prepare"
Tie this back to the specific themes and their urgency.}
```

Must end with two trailing newlines.

---

## Step 2.3: Generate Theme Sections

For each theme (ordered by `theme_id`), write a section to `{PROJECT_PATH}/.logs/report-theme-{theme_id}.md`.

Each theme section tells a complete strategic story: why this investment domain matters, what evidence supports it, what to build, and what to do first.

### Theme Section Template

```markdown
## {N}. {theme.name}

> {theme.strategic_question}

**{EXECUTIVE_SPONSOR_LABEL}:** {theme.executive_sponsor_type}

### {INVESTMENT_THESIS_LABEL}

{Extended narrative: expand the theme's 2-3 sentence narrative into a rich paragraph
(300-500 words) by weaving in quantitative evidence from the theme's trends. This is
NOT a summary of trends — it's a strategic argument for why this investment domain
demands attention. Reference specific numbers and cite sources inline.

The narrative should flow naturally: external force → business implication → strategic
response. Mirror the T→I→P causal logic of the value chains but in prose form, not
as a list.}

### {VALUE_CHAINS_LABEL}

{For each value chain in this theme:}

#### {chain.name}

**{TREND_LABEL}:** {chain.trend.name}
{Pull evidence_md from enriched-trends lookup for this candidate_ref. Include the
full evidence paragraph with citations. If the trend has no quantitative evidence,
use its qualitative analysis.}

**{IMPLICATION_LABEL}:** {For each implication in chain.implications:}
- **{implication.name}** — {Pull evidence_md + implications_md from lookup. Condense
  to 2-3 sentences focusing on what this means for the specific industry.}

**{POSSIBILITY_LABEL}:** {For each possibility in chain.possibilities:}
- **{possibility.name}** — {Pull evidence_md + opportunities_md from lookup. Focus on
  the strategic opportunity, not generic description.}

{If chain has foundation_requirements:}
**{FOUNDATION_LABEL}:** {List foundation requirements with brief context from their
enriched evidence. These are prerequisites, not opportunities.}

---

{End of value chain. Separator between chains within a theme.}

{If solution_templates exist for this theme:}
### {SOLUTION_TEMPLATES_LABEL}

| # | {SOLUTION_LABEL} | {CATEGORY_LABEL} | {ENABLER_TYPE_LABEL} |
|---|-------------------|-------------------|----------------------|
| 1 | {st.name} | {st.category} | {st.enabler_type} |

{Brief description of each solution template and how it addresses the theme's
strategic question. 1-2 sentences per ST.}

### {STRATEGIC_ACTIONS_LABEL}

{Synthesize 3-5 concrete actions from the individual trend actions across all value
chains in this theme. These should be theme-level decisions, not trend-level tasks.
Prioritize by horizon: ACT items first, then PLAN, then OBSERVE.}

1. **{Action}** — {1-sentence rationale linking to specific evidence}
2. ...
```

Must end with two trailing newlines.

### Writing Guidelines

**Investment thesis quality gate:** After writing each theme's investment thesis, verify:
- Word count is at least 250 words (target 300-500). If under 250, expand by pulling additional evidence from the enriched-trends lookup for candidates in that theme's value chains.
- At least 3 inline citations with URLs. If under 3, check the enriched-trends data for quantitative claims that weren't yet incorporated.
- The narrative follows the T→I→P flow: external force → business implication → strategic response. If it reads as a list of facts, rewrite it as a strategic argument.

**Narrative voice:** Authoritative but not academic. Write for a CxO who has 10 minutes to understand why this theme matters and what to do about it. Avoid hedge words ("might," "could potentially") when the evidence is strong — let the data speak.

**Evidence weaving:** Don't dump all claims in a list. Integrate them into the narrative flow. "The predictive maintenance market reached $6.9B in 2024 [Gartner], and manufacturers deploying these capabilities report 30% fewer unplanned outages [McKinsey]" reads better than bullet points.

**Cross-referencing:** When a trend appears in multiple themes (shared candidates), write about it from THIS theme's angle. The same AI trend means different things for "Smart Manufacturing" vs. "Customer Intelligence."

**Foundation requirements:** Keep these brief. They're context ("you need this infrastructure"), not the main argument. 1-2 sentences per requirement.

**Solution templates:** Only present if value-modeler Phase 2 has run (check if `solution_templates[]` is non-empty for this theme). If empty, omit the section entirely — don't mention solutions that don't exist yet.

---

## Step 2.4: Generate Emerging Signals Section

Orphan candidates (trends not in any theme's value chains) still have enriched evidence. Present them as emerging signals worth monitoring — they didn't fit a current theme, which itself is interesting context.

Write `{PROJECT_PATH}/.logs/report-emerging-signals.md`:

```markdown
## {EMERGING_SIGNALS_LABEL}

{EMERGING_SIGNALS_INTRO}

{For each orphan candidate, grouped by dimension:}

### {candidate.name} ({TIPS_ROLE})

{Pull evidence_md from enriched-trends lookup. Write a condensed 2-3 sentence summary.
Note the horizon — observe-horizon orphans are expected; act-horizon orphans may
signal gaps in the theme model.}

---
```

If there are no orphans (100% coverage), write:

```markdown
## {EMERGING_SIGNALS_LABEL}

{ALL_CANDIDATES_THEMED}
```

Must end with two trailing newlines.

---

## Step 2.5: Generate Strategic Portfolio View

Replace the flat dimensional portfolio analysis with theme-level metrics.

Write `{PROJECT_PATH}/.logs/report-portfolio.md`:

```markdown
## {PORTFOLIO_ANALYSIS_LABEL}

### {THEME_OVERVIEW_LABEL}

| # | {THEME_LABEL} | {CHAINS_LABEL} | {CANDIDATES_LABEL} | {HORIZON_MIX_LABEL} | {EVIDENCE_LABEL} |
|---|---------------|----------------|--------------------|--------------------|-------------------|
| 1 | {theme.name} | {chain_count} | {candidate_count} | {act/plan/observe} | {claims_count} claims |
| 2 | ... | ... | ... | ... | ... |
| | **{TOTAL_LABEL}** | **{N}** | **{N}/{total}** | | **{N}** claims |

### {HORIZON_DISTRIBUTION_LABEL}

| {THEME_LABEL} | ACT | PLAN | OBSERVE |
|---------------|-----|------|---------|
| {theme.name} | {count} | {count} | {count} |
| ... | ... | ... | ... |
| {ORPHANS_LABEL} | {count} | {count} | {count} |

### {MECE_VALIDATION_LABEL}

| {METRIC_LABEL} | {VALUE_LABEL} | {STATUS_LABEL} |
|-----------------|---------------|----------------|
| {THEME_COUNT_LABEL} | {N} | {pass/warn} |
| {MUTUAL_EXCLUSIVITY_LABEL} | {pass/fail} | {from mece_validation} |
| {COLLECTIVE_EXHAUSTIVENESS_LABEL} | {pct}% | {pass if >=80%} |
| {BALANCE_LABEL} | {pass/fail} | {from mece_validation} |

### {EVIDENCE_COVERAGE_LABEL}

| {THEME_LABEL} | {WITH_EVIDENCE_LABEL} | {QUALITATIVE_ONLY_LABEL} | {COVERAGE_PCT_LABEL} |
|---------------|-----------------------|--------------------------|----------------------|
| {theme.name} | {count} | {count} | {pct}% |
| ... | ... | ... | ... |
```

Must end with two trailing newlines.

### Counting Logic

- **Candidates per theme:** Count unique `candidate_ref` values across all value chains in the theme (trend + implications + possibilities). Don't double-count shared candidates.
- **Horizon mix:** Count candidates by their `horizon` field from the enriched-trends data.
- **Claims per theme:** Sum `claims_refs` lengths for all candidates in the theme.
- **Evidence coverage per theme:** Count candidates where `has_quantitative_evidence == true` vs total candidates in theme.

---

## Step 2.6: Generate Claims Registry

Claims registry includes a `theme` column:

```markdown
## {CLAIMS_REGISTRY_LABEL}

{CLAIMS_REGISTRY_INTRO}

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {THEME_LABEL} |
|---|---------------|---------------|-----------------|---------------|
| 1 | {claim text} | {value + unit} | [{title}](url) | {theme name or "—"} |
```

To determine which theme a claim belongs to: look up the claim's parent trend via `claims_refs` in the enriched-trends data, then find which theme's value chains reference that candidate_ref. Claims from orphan candidates get "—" in the theme column.

Must end with two trailing newlines.

---

## Step 2.7: Assemble Final Report

Verify all files exist, then concatenate in this order:

```bash
# Build file list for theme mode
FILES="{PROJECT_PATH}/.logs/report-header.md"

# Theme sections in order
for theme_id in theme-001 theme-002 ... theme-N; do
  FILES="$FILES {PROJECT_PATH}/.logs/report-theme-${theme_id}.md"
done

# Remaining sections
FILES="$FILES {PROJECT_PATH}/.logs/report-emerging-signals.md"
FILES="$FILES {PROJECT_PATH}/.logs/report-portfolio.md"
FILES="$FILES {PROJECT_PATH}/.logs/report-claims-registry.md"

cat $FILES > "{PROJECT_PATH}/tips-trend-report.md"
```

### Verification

Read first 3 + last 3 lines of the assembled report:
- First lines should start with `---` (YAML frontmatter)
- Last lines should contain the claims total
- Report should contain exactly N theme H2 headers matching `## {N}. {theme.name}`

---

## Step 2.8: Merge Claims

Merge all 4 dimension claims into `tips-trend-report-claims.json`. The claims themselves don't change; only the report structure around them does.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `tips-value-model.json` has themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| enriched-trends JSON missing for a dimension | HALT: Phase 1 agent failed to produce enriched output |
| Theme references candidate_ref not found in enriched data | Log warning, skip that candidate in the theme narrative |
| Solution templates empty | Omit "Solution Templates" subsection (value-modeler Phase 2 hasn't run yet) |
| MECE validation failed in value model | Include as-is with warning in portfolio view |
