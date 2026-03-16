# English Labels for Trend Report

Language: `en`

## Report Title

```text
REPORT_TITLE: "TIPS Trend Report: {TOPIC}"
```

> **Title logic:** Use `{TOPIC}` only. Do NOT append `in {SUBSECTOR}` — the topic
> (e.g., "Digital Transformation of Large Energy Utilities in Germany") already
> contains the industry and geographic context. Appending the subsector creates
> redundant titles like "...in Utilities".

## Section Headers

```text
EXEC_SUMMARY: "Executive Summary"
PORTFOLIO_ANALYSIS: "Portfolio Analysis"
CLAIMS_REGISTRY: "Claims Registry"
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

## Executive Summary Labels

```text
CROSS_CUTTING_THEMES: "Cross-Cutting Themes"
KEY_FINDINGS: "Key Findings"
INDICATOR_BALANCE: "Indicator Balance"
STRATEGIC_POSTURE: "Strategic Posture"
```

## Portfolio Analysis Labels

```text
HORIZON_DISTRIBUTION: "Horizon Distribution"
CONFIDENCE_DISTRIBUTION: "Confidence Distribution"
SIGNAL_INTENSITY: "Signal Intensity"
LEADING_LAGGING: "Leading/Lagging Balance"
EVIDENCE_COVERAGE: "Evidence Coverage"
DIMENSION: "Dimension"
TOTAL: "Total"
HIGH: "High"
MEDIUM: "Medium"
LOW: "Low"
UNCERTAIN: "Uncertain"
AVG_INTENSITY: "Avg. Intensity"
STRONGEST_TREND: "Strongest Trend"
LEADING: "Leading"
LAGGING: "Lagging"
RATIO: "Ratio"
WITH_EVIDENCE: "With Evidence"
QUALITATIVE_ONLY: "Qualitative Only"
COVERAGE_PCT: "Coverage %"
```

## Claims Registry Labels

```text
CLAIMS_REGISTRY_INTRO: "All quantitative claims extracted from this report with their source URLs."
CLAIM: "Claim"
VALUE: "Value"
SOURCE: "Source"
CLAIMS: "claims"
```

## Strategic Theme Labels (Theme Mode)

```text
STRATEGIC_THEMES_OVERVIEW: "Strategic Themes"
THEME: "Theme"
STRATEGIC_QUESTION: "Strategic Question"
EXECUTIVE_SPONSOR: "Executive Sponsor"
INVESTMENT_THESIS: "Investment Thesis"
VALUE_CHAINS: "Value Chains"
TREND: "Trend"
IMPLICATION: "Implication"
POSSIBILITY: "Possibility"
FOUNDATION: "Foundation Requirements"
SOLUTION_TEMPLATES: "Solution Templates"
SOLUTION: "Solution"
CATEGORY: "Category"
ENABLER_TYPE: "Enabler Type"
STRATEGIC_ACTIONS: "Strategic Actions"
EMERGING_SIGNALS: "Emerging Signals"
EMERGING_SIGNALS_INTRO: "The following candidates were not assigned to any strategic theme. They represent early signals worth monitoring — their absence from current themes may itself be informative."
ALL_CANDIDATES_THEMED: "All 60 candidates are covered by the strategic themes above — no orphan signals."
HEADLINE_EVIDENCE: "Headline Evidence"
THEME_OVERVIEW: "Theme Overview"
CHAINS: "Chains"
CANDIDATES: "Candidates"
HORIZON_MIX: "Horizon Mix"
EVIDENCE: "Evidence"
ORPHANS: "Unthemed"
MECE_VALIDATION: "MECE Validation"
METRIC: "Metric"
STATUS: "Status"
THEME_COUNT: "Theme Count"
MUTUAL_EXCLUSIVITY: "Mutual Exclusivity"
COLLECTIVE_EXHAUSTIVENESS: "Collective Exhaustiveness"
BALANCE: "Balance"
```

## Story Arc Element Labels (Theme Thesis — Corporate Visions)

```text
WHY_CHANGE: "Why Change: The Unconsidered Need"
WHY_NOW: "Why Now: The Closing Window"
WHY_YOU: "Why You: The Portfolio Response"
WHY_PAY: "Why Pay: The Business Case"
```

## Phase Messages (Theme Mode)

```text
PHASE_0_THEMES_FOUND: "Value model detected: {COUNT} strategic themes available — using theme-organized report"
PHASE_2_THEME_AGENT_DISPATCH: "Dispatching {COUNT} theme agents..."
PHASE_2_THEME_AGENT_COMPLETE: "Theme agent {N}/{TOTAL}: {NAME} ({WORDS} words, {CITATIONS} citations)"
PHASE_2_THEME_AGENT_RETRY: "Retrying theme agent: {NAME}"
PHASE_2_THEME_AGENT_SKIP_RESUME: "Theme {NAME} already written — skipping agent dispatch"
PHASE_2_THEME_START: "Assembling strategic theme report..."
PHASE_2_THEME_WRITTEN: "Theme {N}/{TOTAL}: {NAME}"
PHASE_2_THEME_COMPLETE: "Strategic report written: {PATH}"
```

## No-Data Marker

```text
NO_QUANTITATIVE_DATA: "[No quantitative data available]"
```

## Phase Messages

```text
PHASE_0_START: "Loading trend-scout output..."
PHASE_0_LOADED: "Loaded {COUNT} agreed candidates across 4 dimensions"
PHASE_1_START: "Dispatching 4 agents for evidence enrichment..."
PHASE_1_AGENT: "Agent {N}/4: {DIMENSION} ({COUNT} trends)"
PHASE_1_COMPLETE: "All agents complete: {CLAIMS} claims extracted from {SEARCHES} searches"
PHASE_2_START: "Assembling trend report..."
PHASE_2_COMPLETE: "Report written: {PATH}"
PHASE_3_ASK: "{COUNT} quantitative claims were extracted. Would you like to verify them now?"
PHASE_3_VERIFY: "Verify now (Recommended)"
PHASE_3_SKIP: "Skip verification"
PHASE_3_RUNNING: "Running claim verification..."
PHASE_3_RESULT: "Verification complete: {VERDICT} ({PASSED} passed, {FAILED} failed, {REVIEW} review)"
PHASE_4_COMPLETE: "Trend Report Complete"
```
