# English Labels for Trend Report

Language: `en`

## Report Title

```text
REPORT_TITLE: "{TITLE}"
REPORT_SUBTITLE: "{SUBTITLE}"
```

> **Title:** A punchy, max-8-word title synthesized from the topic, arc, and
> investment themes. NOT the research question — that becomes the subtitle.
> **Subtitle:** The research question (`{TOPIC}`), optionally shortened for
> readability. Do NOT append `in {SUBSECTOR}` — the topic already contains
> the industry and geographic context.

## Title Proposal

```text
PHASE_0_TITLE_QUESTION: "Proposed report title — accept or edit:"
PHASE_0_TITLE_HEADER: "Report Title"
PHASE_0_TITLE_ACCEPT: "Accept"
PHASE_0_TITLE_EDIT: "Edit"
```

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

## Investment Theme Labels (Theme Mode)

```text
STRATEGIC_INVESTMENT_THEMES_OVERVIEW: "Investment Themes"
INVESTMENT_THEME: "Investment Theme"
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
EMERGING_SIGNALS_INTRO: "The following candidates were not assigned to any investment theme. They represent early signals worth monitoring — their absence from current investment themes may itself be informative."
ALL_CANDIDATES_THEMED: "All candidates are covered by the investment themes above — no orphan signals."
HEADLINE_EVIDENCE: "Headline Evidence"
INVESTMENT_THEME_OVERVIEW: "Investment Theme Overview"
CHAINS: "Chains"
CANDIDATES: "Candidates"
HORIZON_MIX: "Horizon Mix"
EVIDENCE: "Evidence"
ORPHANS: "Unthemed"
MECE_VALIDATION: "MECE Validation"
METRIC: "Metric"
STATUS: "Status"
INVESTMENT_THEME_COUNT: "Investment Theme Count"
MUTUAL_EXCLUSIVITY: "Mutual Exclusivity"
COLLECTIVE_EXHAUSTIVENESS: "Collective Exhaustiveness"
BALANCE: "Balance"
```

## Story Arc Element Labels (Fallback / Structural Markers)

> These labels are structural identifiers, NOT output headings. The theme-writer
> agent generates message-driven headings from evidence (see arc-definition.md
> Heading Generation Rules). These labels serve as: (a) fallback when evidence
> is insufficient, (b) structural markers in agent prompts for element
> identification, (c) quality gate reference labels in validation output.

```text
WHY_CHANGE: "Why Change: The Unconsidered Need"
WHY_NOW: "Why Now: The Closing Window"
WHY_YOU: "Why You: The Portfolio Response"
WHY_PAY: "Why Pay: The Business Case"
COST_OF_INACTION: "Cost of Action vs. Cost of Inaction"
```

## Report Arc Selection

```text
PHASE_0_ARC_QUESTION: "Which narrative arc should frame the report? This determines how themes connect — not how individual themes are written."
PHASE_0_ARC_HEADER: "Report Arc"
ARC_CORPORATE_VISIONS: "Corporate Visions (Recommended)"
ARC_CORPORATE_VISIONS_DESC: "Challenge assumptions, create urgency, quantify inaction — the B2B persuasion frame"
ARC_TECHNOLOGY_FUTURES: "Technology Futures"
ARC_TECHNOLOGY_FUTURES_DESC: "Map emerging capabilities, show convergence, quantify required investment"
ARC_COMPETITIVE_INTELLIGENCE: "Competitive Intelligence"
ARC_COMPETITIVE_INTELLIGENCE_DESC: "Map landscape shifts, identify positioning opportunities, assess threats"
ARC_STRATEGIC_FORESIGHT: "Strategic Foresight"
ARC_STRATEGIC_FORESIGHT_DESC: "Read signals, build scenarios, frame decisions under uncertainty"
ARC_INDUSTRY_TRANSFORMATION: "Industry Transformation"
ARC_INDUSTRY_TRANSFORMATION_DESC: "Identify structural forces, acknowledge friction, chart evolution path"
ARC_TREND_PANORAMA: "Trend Panorama (TIPS-native)"
ARC_TREND_PANORAMA_DESC: "Map forces → impact → horizons → foundations across the Trendradar"
ARC_THEME_THESIS: "Theme Thesis"
ARC_THEME_THESIS_DESC: "Each theme as an investment thesis with its own quantified business case"
```

## Synthesis Section Headings (per arc)

```text
SYNTHESIS_CORPORATE_VISIONS: "The Investment Decision"
SYNTHESIS_TECHNOLOGY_FUTURES: "What's Required"
SYNTHESIS_COMPETITIVE_INTELLIGENCE: "Strategic Implications"
SYNTHESIS_STRATEGIC_FORESIGHT: "The Decisions Ahead"
SYNTHESIS_INDUSTRY_TRANSFORMATION: "Leadership Positioning"
SYNTHESIS_TREND_PANORAMA: "Strategic Foundations"
SYNTHESIS_THEME_THESIS: "Aggregate Investment Case"
```

## Bridge Paragraph Labels

```text
BRIDGE_LABEL: "Strategic Link"
PHASE_2_BRIDGES_START: "Generating bridge paragraphs between investment themes..."
PHASE_2_SYNTHESIS_START: "Writing synthesis section..."
PHASE_2_BRIDGE_WRITTEN: "Bridge {N}→{N+1}: {FROM_NAME} → {TO_NAME}"
PHASE_2_SYNTHESIS_WRITTEN: "Synthesis section written"
```

## Phase Messages (Investment Theme Mode)

```text
PHASE_0_INVESTMENT_THEMES_FOUND: "Value model detected: {COUNT} investment themes available — using investment-theme-organized report"
PHASE_2_INVESTMENT_THEME_AGENT_DISPATCH: "Dispatching {COUNT} investment theme agents..."
PHASE_2_INVESTMENT_THEME_AGENT_COMPLETE: "Investment theme agent {N}/{TOTAL}: {NAME} ({WORDS} words, {CITATIONS} citations)"
PHASE_2_INVESTMENT_THEME_AGENT_RETRY: "Retrying investment theme agent: {NAME}"
PHASE_2_INVESTMENT_THEME_AGENT_SKIP_RESUME: "Investment theme {NAME} already written — skipping agent dispatch"
PHASE_2_INVESTMENT_THEME_START: "Assembling investment theme report..."
PHASE_2_INVESTMENT_THEME_WRITTEN: "Investment theme {N}/{TOTAL}: {NAME}"
PHASE_2_INVESTMENT_THEME_COMPLETE: "Investment theme report written: {PATH}"
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
