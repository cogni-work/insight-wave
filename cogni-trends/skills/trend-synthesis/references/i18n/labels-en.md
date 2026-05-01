# English Labels for Trend Synthesis

Language: `en`

> **Note:** Pruned to synthesis-stage labels. Research-stage and booklet-stage labels live in their respective sibling skills.

## Report Title

```text
REPORT_TITLE: "{TITLE}"
REPORT_SUBTITLE: "{SUBTITLE}"
```

> **Title:** A punchy, max-8-word title synthesized from the topic, industry, and
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
CLAIMS_REGISTRY: "Claims Registry"
```

## Smarter Service Macro Section Labels

```text
MACRO_FORCES: "Forces — External Effects"
MACRO_IMPACT: "Impact — Digital Value Drivers"
MACRO_HORIZONS: "Horizons — New Horizons"
MACRO_FOUNDATIONS: "Foundations — Digital Foundation"
```

## Smarter Service Synthesis Section

```text
SYNTHESIS_HEADING_SMARTER_SERVICE: "The Capability Imperative"
UNIFIED_CAPABILITY_ROADMAP_LABEL: "Unified Capability Roadmap"
```

## Phase 2 Status Messages

```text
PHASE_2_PRIMER_START: "Writing shared dimension primer (Smarter Service)..."
PHASE_2_PRIMER_WRITTEN: "Shared dimension primer written."
PHASE_2_THEME_CASE_AGENT_DISPATCH: "Dispatched theme-case writers for {N} investment themes (slim 3-beat mode)."
PHASE_2_THEME_CASE_AGENT_COMPLETE: "Theme-case complete: {theme_name}"
PHASE_2_THEME_CASE_AGENT_SKIP_RESUME: "Skipping theme-case (resume): {theme_name}"
PHASE_2_COMPOSER_DISPATCH: "Dispatching dimension composer: {dimension}..."
PHASE_2_COMPOSER_COMPLETE: "Dimension composer complete: {dimension}"
PHASE_2_COMPOSER_SKIP_RESUME: "Skipping dimension composer (resume): {dimension}"
PHASE_2_SYNTHESIS_START: "Writing synthesis section..."
PHASE_2_SYNTHESIS_WRITTEN: "Synthesis section written"
PHASE_2_COMPLETE: "Report written: {PATH}"
PHASE_3_FINALIZE_COMPLETE: "Trend synthesis complete — ready for /verify-trend-report"
```

## Theme-Case Heading Helpers

```text
STRATEGIC_QUESTION_LABEL: "Strategic question"
EXECUTIVE_SPONSOR: "Executive Sponsor"
SECONDARY_CALLOUT_PATTERN: "→ See also Theme {N} in {macro_section} for the {topic} dependency."
THEME_CASE_REFERENCE_PATTERN: "→ See also Theme {N} in {Macro Section}"
```

## Investment Theme Common Labels (passed to writer agents)

```text
INVESTMENT_THEME: "Investment Theme"
STRATEGIC_QUESTION: "Strategic Question"
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
REFERENCES_BLOCK_LABEL: "Industry reference cases"
```

## Claims Registry Labels

```text
CLAIMS_REGISTRY_INTRO: "All quantitative claims extracted from this report with their source URLs."
CLAIM: "Claim"
VALUE: "Value"
SOURCE: "Source"
DIMENSION_LABEL: "Dimension"
INVESTMENT_THEME_LABEL: "Investment Theme"
CLAIMS: "claims"
```

## Report Length Tier Selection

```text
PHASE_0_LENGTH_QUESTION: "How long should the report be? Length controls prose only — the claims registry is always rendered in full and never counted."
PHASE_0_LENGTH_HEADER: "Report length"
LENGTH_TIER_STANDARD: "Standard (≈4,000 words)"
LENGTH_TIER_STANDARD_DESC: "Detailed research report — analog to cogni-research's 'detailed' mode. Recommended default."
LENGTH_TIER_EXTENDED: "Extended (≈5,500 words)"
LENGTH_TIER_EXTENDED_DESC: "Strategic deep dive with more evidence per theme."
LENGTH_TIER_COMPREHENSIVE: "Comprehensive (≈7,000 words)"
LENGTH_TIER_COMPREHENSIVE_DESC: "Full-depth analysis for stakeholders who want everything."
LENGTH_TIER_MAXIMUM: "Maximum (≈8,000 words)"
LENGTH_TIER_MAXIMUM_DESC: "Exhaustive prose, full evidence weave per theme-case."
LENGTH_TIER_CUSTOM_DESC: "Pre-seeded by automation via tips-project.json. Bounds: 2,500 ≤ target_words ≤ 12,000 prose."
LENGTH_BUDGET_REBALANCED_NOTE: "Note: dimension-narrative budget reduced from its initial 12% allocation to give per-theme-case targets headroom above the structural floor (Stake 80 + Move 130 + Cost 80 = 290). Composer agents still meet the 250-word dimension floor."
LENGTH_BUDGET_FLOOR_WARNING: "Warning: per-theme-case target is binding at the structural floor (290 words = Stake 80 + Move 130 + Cost 80) even after rebalancing dimension narratives. Theme cases will likely land 30–60% above target and the full report may exceed the tier word target. Recommendation: switch to Extended tier or consolidate to ≤5 investment themes."
```

> Tier labels reference *prose* word counts — executive summary + macro sections + synthesis. The claims registry / sources appendix adds another ~1,500–3,500 words depending on claim volume and is always present regardless of tier.
