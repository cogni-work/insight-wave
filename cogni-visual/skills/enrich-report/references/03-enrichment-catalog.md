# Enrichment Catalog

Complete catalog of enrichment types available for report visualization. Each type specifies its trigger conditions, scoring weights, and how to extract data from the source section.

## Contents

- [Enrichment Types](#enrichment-types) — Full catalog organized by track
  - [Data Track (Chart.js)](#data-track-chartjs) — kpi-dashboard, horizon-chart, theme-radar, coverage-heatmap, distribution-doughnut, timeline-chart, comparison-bar, stat-chart
  - [Concept Track (Excalidraw → SVG)](#concept-track-excalidraw--svg) — tips-flow, relationship-map, process-flow, concept-sketch
  - [HTML Track](#html-track) — summary-card
- [Theme Consistency Rule (trend-report)](#theme-consistency-rule-trend-report) — Cross-section theme coherence
- [Content-Pattern Structural Rules (research-report)](#content-pattern-structural-rules-research-report) — Data tag extraction from research sections
- [Section Consistency Rule (research-report)](#section-consistency-rule-research-report) — Minimum enrichment per section
- [Scoring Reference](#scoring-reference) — How enrichment scores are calculated
- [Type Diversity Scoring](#type-diversity-scoring) — Rewarding variety across enrichment types
- [Spacing Rules](#spacing-rules) — Minimum distance between enrichments

## Enrichment Types

### Data Track (Chart.js)

---

#### `kpi-dashboard`

**What it shows:** A row of large hero numbers with sublabels and source attribution. The executive summary's "at a glance" numbers.

**Chart.js type:** Custom HTML (no canvas) — styled metric cards with optional sparkline via Chart.js line chart (hidden axes, 40px height).

**Trigger conditions:**
- Section tagged `headline-evidence` or `executive-summary` (structural)
- OR section contains 3+ numeric claims within 200 words (content-detected)

**Data extraction:**
1. Find numeric claims: regex for currency amounts (€/$), percentages (N%), large numbers (N million/billion/Mrd.), year-over-year changes (+N%/-N%).
2. For each: extract `value` (the number), `label` (surrounding context, max 8 words), `source_url` (from nearest inline citation).
3. Cap at 6 KPI cards (more becomes noise).

**Contrast pairs:** When the executive summary presents a cost-of-action vs. cost-of-inaction contrast (e.g., "€6–9 Mio. proaktive Investition" vs. "€18–25 Mio. Kosten des Nichthandelns"), ALWAYS include BOTH values as adjacent KPI cards. This contrast is typically the report's central argument — showing only one side strips the persuasive impact. Look for patterns like "Handeln kostet X. Nichthandeln kostet Y.", "proaktive Investition: X ... Kosten des Wartens: Y", or "1:3 Verhältnis" framing in the summary.

**Scoring:**
- Base: 40 (structural) or 25 (content-detected)
- +10 per numeric claim above 3 (max +30)
- +15 if section is first H2 (executive summary position)

**Density threshold:** Always included at `minimal`.

---

#### `horizon-chart`

**What it shows:** Stacked horizontal bar chart showing the distribution of trend candidates across action horizons (ACT / PLAN / OBSERVE) per investment theme.

**Chart.js type:** `bar` (horizontal, stacked)

**Trigger conditions:**
- Section tagged `horizon-distribution` (structural)
- OR table with columns matching horizon terms (Act/Plan/Observe or Handeln/Planen/Beobachten)

**Data extraction:**
1. Parse the horizon distribution table.
2. Extract: theme names (row labels), horizon values per theme (ACT count, PLAN count, OBSERVE count).
3. Colors: ACT → `var(--status-danger)`, PLAN → `var(--status-warning)`, OBSERVE → `var(--status-info)`.

**Scoring:** Base: 35 (structural). +10 if 4+ themes in table.

**Density threshold:** Included at `balanced` and above.

---

#### `theme-radar`

**What it shows:** Radar chart comparing investment themes across multiple dimensions (candidate count, evidence density, claims count, solution templates, ACT ratio).

**Chart.js type:** `radar`

**Trigger conditions:**
- Section tagged `strategic-themes-table` or theme overview table (structural)
- OR table with 4+ columns of numeric data about named entities

**Data extraction:**
1. Parse the theme overview table.
2. Extract per-theme: candidate count, chains, ACT/PLAN/OBSERVE ratios, claims count.
3. Normalize each axis to 0-100 scale for radar display.
4. Each theme becomes a dataset with its own color (cycle through `--accent`, `--primary`, `--secondary`, `--status-info`, `--status-success`).

**Scoring:** Base: 30 (structural). +15 if 5+ themes.

**Density threshold:** Included at `balanced` and above.

---

#### `coverage-heatmap`

**What it shows:** Grouped bar chart (or matrix) showing evidence coverage percentages per theme or per dimension.

**Chart.js type:** `bar` (grouped)

**Trigger conditions:**
- Section tagged `evidence-coverage` (structural)
- OR table with percentage values in cells

**Data extraction:**
1. Parse the evidence coverage table.
2. Extract: category labels (rows), metric names (columns), percentage values.
3. Color-code bars: >80% → `var(--status-success)`, 50-80% → `var(--status-warning)`, <50% → `var(--status-danger)`.

**Scoring:** Base: 25 (structural).

**Density threshold:** Included at `rich` only.

---

#### `distribution-doughnut`

**What it shows:** Doughnut chart showing proportional distribution (e.g., MECE validation theme balance, market share, resource allocation).

**Chart.js type:** `doughnut`

**Trigger conditions:**
- Section tagged `mece-validation` (structural)
- OR section contains proportional data that sums to ~100% or a whole
- OR table with a "share" or "%" column

**Placement rule:** If the data source is a claims registry or appendix table, place the chart in the **synthesis section** (the last narrative H2 before the appendix) — NOT in the appendix/registry itself. Reference tables are data sources, not visualization hosts.

**Data extraction:**
1. Parse proportional data from table or inline text.
2. Extract: segment labels, values, optional percentages.
3. Colors: cycle through palette derived from design-variables.

**Scoring:** Base: 25 (structural) or 20 (content-detected). +10 if clear proportional split.

**Density threshold:** Included at `balanced` and above.

---

#### `timeline-chart`

**What it shows:** Scatter/line chart with date axis showing regulatory deadlines, milestones, or horizon events annotated on a timeline.

**Chart.js type:** `line` with point annotations (via chartjs-plugin-annotation or styled data points)

**Trigger conditions:**
- Section contains 3+ date references (year, quarter, "by 2027", "Q3 2026")
- OR section tagged with temporal content (strategic actions with time-bound deliverables)

**Data extraction:**
1. Extract date references with context: regex for `Q[1-4] 20\d{2}`, `by 20\d{2}`, `20\d{2}-20\d{2}`, month-year patterns.
2. For each: `date` (normalized to YYYY-MM or YYYY-QN), `label` (action/event, max 10 words), `category` (regulatory/strategic/market).
3. Sort chronologically.

**Scoring:** Base: 20 (content-detected). +15 if 5+ date references. +10 if section is in strategic actions.

**Density threshold:** Included at `balanced` and above.

---

#### `comparison-bar`

**What it shows:** Horizontal bar chart comparing items side-by-side (solution templates, vendor capabilities, market sizes).

**Chart.js type:** `bar` (horizontal)

**Trigger conditions:**
- Table with 4+ rows and 2+ numeric columns
- OR solution templates table (structural for trend-report)
- OR section with explicit comparison language ("vs", "compared to", "outperforms")

**Data extraction:**
1. Parse comparison table or extract from text.
2. Extract: item labels (rows), metric values, metric labels (columns).
3. Sort by primary metric (descending).

**Scoring:** Base: 20 (content-detected) or 25 (structural — solution templates). +10 if clear ranking.

**Density threshold:** Included at `balanced` and above.

---

#### `stat-chart`

**What it shows:** Simple bar or line chart for a cluster of related statistics in a text section (not from a table).

**Chart.js type:** `bar` (vertical) or `line` depending on data pattern

**Trigger conditions:**
- 3+ numeric claims within 300 words, sharing a common unit or topic
- NOT already covered by a structural enrichment

**Data extraction:**
1. Cluster numeric claims by topic similarity (shared keywords).
2. Extract: labels (claim context), values (normalized to same unit where possible).
3. Choose bar vs line: temporal sequence → line; discrete items → bar.

**Scoring:** Base: 15 (content-detected). +10 per additional claim above 3. +5 if claims share a unit.

**Density threshold:** Included at `rich` only.

---

### Concept Track (Excalidraw → SVG)

---

#### `tips-flow`

**What it shows:** Horizontal flow diagram showing one T→I→P→S value chain: one Trend box on the left, connected by arrows to Implication boxes, which connect to Possibility boxes, which connect to Solution boxes.

**Excalidraw pattern:** 4-column flow with color-coded boxes per TIPS dimension. See `excalidraw-patterns.md` (in libraries/) for element recipes.

**Trigger conditions:**
- Section tagged `value-chain` (structural — trend-report)
- OR section with T→I→P→S content pattern (bold labels "Trend:", "Implication:", "Possibility:", "Foundation Requirements:")

**Data extraction:**
1. Extract chain components: trend name, implication names (1-3), possibility names (1-3), solution/foundation names.
2. Parse from the structured value chain format (bold labels followed by text blocks).

**Scoring:** Base: 40 (structural). Max 5 tips-flow enrichments per report (one per primary value chain).

**Density threshold:** Always included at `minimal`.

---

#### `relationship-map`

**What it shows:** Network diagram showing how investment themes connect to each other — shared trends, cascading implications, or cross-theme dependencies.

**Excalidraw pattern:** Central-radiating layout with theme nodes and labeled connections. See `excalidraw-patterns.md` (in libraries/).

**Trigger conditions:**
- Bridge paragraphs that reference theme interconnections
- OR synthesis section that aggregates across themes
- OR any section that explicitly names 3+ other theme names

**Data extraction:**
1. Identify theme names mentioned across sections.
2. Map cross-references: which themes mention which other themes.
3. Extract connection labels from bridge paragraph text (e.g., "The capability gap from Theme 1 compounds when Theme 2's deadline hits").

**Scoring:** Base: 30. +10 if 4+ themes interconnected. Max 1 per report.

**Density threshold:** Included at `balanced` and above.

---

#### `process-flow`

**What it shows:** Horizontal or vertical flow diagram showing a process, workflow, or causal chain described in the research text. Generic process visualization — not TIPS-specific.

**Excalidraw pattern:** Linear flow with color-coded step boxes connected by arrows. See `excalidraw-patterns.md` (in libraries/) "process-flow" pattern.

**Trigger conditions:**
- Section tagged `has-process` (content-pattern tag from section analysis)
- OR section with 3+ sequential steps in an ordered list or causal chain language
- AND section word count > 300

**Data extraction:**
1. Extract step labels from ordered list items, numbered sub-headings, or noun phrases after causal connectors.
2. Extract connections between steps (sequential or branching).
3. Max 8 steps — simplify if more (merge minor steps, keep key transitions).

**Scoring:**
- Base: 25 (content-pattern detected)
- +5 if section is tagged `methodology` (process diagrams are especially useful here)
- +10 if 5+ steps
- Max 3 `process-flow` enrichments per report

**Density threshold:** Included at `balanced` and above.

---

#### `concept-sketch`

**What it shows:** Simple conceptual diagram for an abstract idea — convergence, transformation phases, strategic positioning, capability layers.

**Excalidraw pattern:** Varies by concept type. See `excalidraw-patterns.md` (in libraries/) for common concept patterns (layered stack, convergence arrows, phase progression, 2x2 matrix).

**Trigger conditions:**
- Section describes an abstract concept with spatial/structural metaphor (layers, stages, convergence, matrix)
- AND section word count > 400
- AND no other enrichment planned for this section

**Data extraction:**
1. Identify the conceptual structure from text (e.g., "three layers of...", "convergence of X and Y", "progression from A to B to C").
2. Extract labels for diagram elements.

**Scoring:** Base: 15 (content-detected, low because subjective). +10 if clear spatial metaphor. +5 if strategic importance (H2 level).

**Density threshold:** Included at `rich` only.

---

### HTML Track

---

#### `summary-card`

**What it shows:** Styled HTML card with a key takeaway, positioned before a long section to give readers the "bottom line up front".

**Implementation:** Themed `<div>` with accent left border, summary text, section word count badge.

**Trigger conditions:**
- Section word count > 800
- AND section has an identifiable thesis (first or second sentence contains a strong assertion)
- AND section is at H2 level

**Data extraction:**
1. Extract the thesis sentence (first sentence with a verb + quantitative claim, or first sentence after "the key finding is" / "critically" / "most importantly").
2. Truncate to max 2 sentences.

**Scoring:** Base: 10. +10 if section > 1200 words. +5 if thesis contains a number.

**Density threshold:** Included at `balanced` and above.

---

## Theme Consistency Rule (trend-report)

In a trend-report, each investment theme (Handlungsfeld) has the same internal structure: investment thesis, evidence paragraphs with numeric claims, solution descriptions, and a cost-of-action-vs-inaction comparison. Because the structure repeats, the visual treatment must also repeat. Inconsistent enrichment — one theme gets 3 visuals, another gets 0 — signals arbitrary placement and undermines the report's visual rhythm.

**Baseline per theme (mandatory at `balanced` and above):**

Each theme H2 section MUST receive at minimum:
1. **`summary-card`** — key takeaway at the theme opening (BLUF)
2. **One data chart** — the best-fit chart for the theme's evidence. Selection priority:
   - If theme has a cost comparison (Handeln vs. Nichthandeln) → `comparison-bar`
   - If theme has regulatory deadlines / temporal milestones → `timeline-chart`
   - If theme has 3+ numeric claims clustered by topic → `stat-chart`
   - Fallback: `comparison-bar` from the theme's solution descriptions

**Optional per theme (at `balanced`, if score > 40):**
3. **`tips-flow`** or **`concept-sketch`** — if the theme contains a value chain or clear conceptual structure

**How to apply:** After the content-detection scoring pass (Layer 2), check each theme H2 section. If a theme has fewer than 2 enrichments, force-add from the baseline list above. Score the force-added items at 50 (strong — structural consistency) so they survive the density cap.

At `minimal` density: each theme gets only 1 enrichment (the best-scoring one). At `rich`: baseline + all qualifying optional enrichments.

---

## Content-Pattern Structural Rules (research-report)

Research reports use content-pattern tags (detected by analyzing section body text) rather than heading keywords to drive structural enrichment. These rules fire based on what the content **contains**, not what the heading **says** — making them work for any research topic.

| Content pattern | Enrichment | Track | Base Score |
|----------------|------------|-------|------------|
| `executive-summary` + 3+ numeric claims | `kpi-dashboard` | data | 40 |
| `has-data-table` (numeric table with 4+ rows) | `comparison-bar` | data | 30 |
| `has-comparison` (table or prose comparing entities) | `comparison-bar` | data | 30 |
| `has-timeline` (3+ chronological dates) | `timeline-chart` | data | 28 |
| `has-distribution` (proportional data ~100%) | `distribution-doughnut` | data | 25 |
| `stat-dense` (5+ numeric claims clustered) | `stat-chart` | data | 25 |
| `has-process` (sequential steps / causal chain) | `process-flow` | concept | 25 |
| `has-synthesis` (cross-section aggregation) | `relationship-map` | concept | 30 |
| `has-thesis` + section >800 words | `summary-card` | html | 20 |
| `methodology` + `has-process` | `process-flow` | concept | 30 |
| Pre-planned (`diagram-plan.json`) | per-plan type | concept | 40 |

**Deduplication:** When a section has multiple content-pattern tags that map to the same enrichment type (e.g., `has-data-table` and `has-comparison` both → `comparison-bar`), create only one enrichment for that type. Use the higher score.

**Overlap with Layer 2 (content detection):** Content-pattern structural rules and Layer 2 content detection may identify the same visualization opportunity. When they overlap, the structural rule score takes precedence (it's typically higher). Do not create duplicate enrichments for the same data.

---

## Section Consistency Rule (research-report)

In a research report, body sections vary in data richness — some contain dense numeric tables and statistics, others are purely analytical prose. The consistency rule ensures data-rich sections receive proportional visual treatment without forcing charts on prose-only sections.

**Baseline per H2 section (at `balanced` density, for sections with 600+ words):**

1. **`summary-card`** — if `has-thesis` is detected (section >800 words with identifiable thesis sentence in first 2 sentences)
2. **One data chart** — if ANY content-pattern data tag is present (`has-data-table`, `stat-dense`, `has-comparison`, `has-timeline`, `has-distribution`). Pick the highest-scoring match from the content-pattern structural rules table above.
3. **Fallback: skip** — if no content-pattern data tags are detected, the section is pure analytical prose. Do NOT force a chart where no data exists. This is the critical difference from trend-reports, where every investment theme has a predictable internal structure with chartable cost comparisons. Research body sections may legitimately contain only qualitative analysis.

**How to apply:** After the content-detection scoring pass (Layer 2), check each H2 section. For data-rich sections (those with at least one content-pattern data tag) with fewer enrichments than the baseline, force-add the missing baseline enrichment. Score force-added `summary-card` items at 40, force-added data charts at 35.

At `minimal` density: only `executive-summary` KPI dashboard + pre-planned diagrams (from `diagram-plan.json`). No per-section baseline.
At `rich`: baseline + all qualifying content-pattern enrichments + `process-flow` diagrams for procedural sections.

---

## Scoring Reference

| Score Range | Meaning | Density Required |
|-------------|---------|-----------------|
| 80-100 | Essential — structural, always high value | `minimal` |
| 50-79 | Strong — clear data, good fit | `balanced` |
| 25-49 | Moderate — useful but not critical | `balanced` (near cap) |
| 10-24 | Optional — adds variety, lower confidence | `rich` |
| 0-9 | Skip — insufficient data or poor fit | never |

## Type Diversity Scoring

Applied after base scoring to prevent any single enrichment type from dominating the plan:

| Condition | Score Modifier |
|-----------|---------------|
| First use of this type in the plan | +15 |
| Type not used in last 3 enrichments | +10 |
| Same type as immediately preceding enrichment | -15 |
| This type already accounts for 40%+ of all planned enrichments | -10 |

These modifiers stack. A `stat-chart` that is the first stat-chart in the plan AND hasn't been used in the last 3 enrichments gets +25. A `comparison-bar` that is the 6th comparison-bar in a 13-enrichment plan (46%) AND follows another comparison-bar gets -25.

The purpose is to ensure visual variety — a report with 6 comparison-bars and no stat-charts, distribution-doughnuts, or timeline-charts is visually monotonous even if each individual comparison-bar is data-justified. When multiple chart types could fit the same data (e.g., a numeric table could be comparison-bar OR stat-chart), diversity scoring tips the balance toward the underrepresented type.

## Spacing Rules

- **Minimum distance:** 300 words between any two enrichments (measured in source text between injection points).
- **Variety rule:** No more than 2 consecutive enrichments of the same type. If a third would occur, skip the lowest-scoring one.
- **Section boundary:** Enrichments inject AFTER the relevant content block, BEFORE the next heading. Never inject before a section's first paragraph.
- **Appendix exclusion:** Never place enrichments inside reference/appendix sections: `claims-registry`, `quellenregister`, `references`, `bibliography`, `literaturverzeichnis`. These are data SOURCES for charts, not visualization hosts. If an enrichment's data comes from an appendix table, place it in the last narrative section before the appendix (typically `synthesis` or `die-investitionsentscheidung`).
- **Synthesis placement:** When a chart summarizes cross-theme data (claims distribution, investment comparison across all Handlungsfelder), place it in the synthesis/closing section — after the paragraph containing the aggregate numbers, not at the section start.
