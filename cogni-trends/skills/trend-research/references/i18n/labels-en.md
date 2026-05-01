# English Labels for Trend Research

Language: `en`

> **Note:** This is a full copy of the legacy `trend-report` labels file. Many
> entries are consumed only by `trend-synthesis` (theme-cases, dimension
> composer, exec summary, claims registry) or `trend-booklet`. Pruning per-skill
> is a follow-up cleanup; for now keeping a full copy avoids accidental misses
> when a research-stage status message is moved.

## Phase Messages (Research)

```text
PHASE_0_START: "Loading trend-scout output..."
PHASE_0_LOADED: "Loaded {COUNT} agreed candidates across 4 dimensions"
PHASE_0_INVESTMENT_THEMES_FOUND: "Value model detected: {COUNT} investment themes available"
PHASE_1_START: "Dispatching 4 agents for evidence enrichment..."
PHASE_1_AGENT: "Agent {N}/4: {DIMENSION} ({COUNT} trends)"
PHASE_1_COMPLETE: "All agents complete: {CLAIMS} claims extracted from {SEARCHES} searches"
PHASE_2_RESEARCH_MANIFEST_WRITTEN: "Research manifest written: {PATH}"
PHASE_2_RESEARCH_COMPLETE: "Trend research complete — ready for /trend-synthesis or /trend-booklet"
```

## TIPS Dimension Headers

```text
DIMENSION_T: "T — Trends: External Effects"
DIMENSION_I: "I — Implications: Digital Value Drivers"
DIMENSION_P: "P — Possibilities: New Horizons"
DIMENSION_S: "S — Solutions: Digital Foundation"
```

## Horizon Labels

```text
HORIZON_ACT: "ACT Horizon (0-2 Years)"
HORIZON_PLAN: "PLAN Horizon (2-5 Years)"
HORIZON_OBSERVE: "OBSERVE Horizon (5+ Years)"
YEARS: "Years"
```

## Trend Subsection Labels

```text
OVERVIEW: "Trend Overview"
IMPLICATIONS: "Implications"
OPPORTUNITIES: "Opportunities"
ACTIONS: "Recommended Actions"
```

## No-Data Marker

```text
NO_QUANTITATIVE_DATA: "[No quantitative data available]"
```

## Deep Research Phase

```text
PHASE_DEEP_RESEARCH_OFFER: "I can perform deep research on 3-5 high-value trends before writing the report. This adds ~5-10 minutes but produces richer evidence with quantitative data."
PHASE_DEEP_RESEARCH_AUTO: "Deep research top ACT-horizon trends (recommended for executive audiences)"
PHASE_DEEP_RESEARCH_SKIP: "Skip deep research and proceed with standard evidence enrichment"
PHASE_DEEP_RESEARCH_PICK: "Select specific trends for deep research"
PHASE_DEEP_RESEARCH_DISPATCH: "Dispatching {COUNT} deep researchers in parallel..."
PHASE_DEEP_RESEARCH_COMPLETE: "Deep research complete: {OK}/{TOTAL} trends researched"
```

## JSON Validity Gate

```text
PHASE_VALIDATE_TRENDS_PASS: "All 4 enriched-trends JSON files valid (repaired: {N})"
PHASE_VALIDATE_TRENDS_FAIL: "Enriched-trends JSON unrepairable: {FILE} (line {LINE}, col {COL}). Re-dispatch the affected dimension's writer agent."
```
