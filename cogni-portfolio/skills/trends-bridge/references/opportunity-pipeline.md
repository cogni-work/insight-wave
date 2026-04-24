# Blueprint-Aware Opportunity Pipeline

Step 5.4 of the `tips-to-portfolio` operation produces `portfolio-opportunities.json`
— a structured gap analysis of Solution Templates (STs) that lack strong portfolio
matches, plus a taxonomy-level aggregate showing which portfolio dimensions need
investment across the whole solution portfolio.

This reference covers the **procedural logic** (scoring, classification, taxonomy
aggregation). For the output file schema, see
`references/opportunity-schema.md`.

## Why two levels

Per-ST opportunities answer "which individual gaps should we evaluate?" That's
useful for tactical roadmap calls but misses the portfolio question: "which
dimensions of our offering are systematically underinvested?" Aggregating
building blocks across all STs — matched and unmatched — surfaces the taxonomy
priorities that a single-ST view would hide. The strategic insight from this
aggregation is typically the most valuable output of the bridge.

## Level 1: Per-ST opportunities

For each Solution Template with `match_confidence` of `"none"` or `"low"`,
generate a structured opportunity assessment.

### 1. Calculate opportunity score (0–10)

```
opportunity_score = (
    (ranking_value / 5) × 0.4 +
    tam_alignment × 0.3 +
    competitive_whitespace × 0.3
) × 10
```

- `ranking_value`: The ST's `ranking_value` from the TIPS value model (0–5).
- `tam_alignment`: Fraction of portfolio markets with `market_relevance = "direct"`
  or `"industry"` for this pursuit (0–1). Read from the market entries in
  `portfolio-context.json`.
- `competitive_whitespace`: If competitive analysis exists for related propositions,
  estimate whitespace from competitor coverage gaps. Otherwise default to `0.7`
  (moderate whitespace assumption — tune if the portfolio routinely has competitor
  data and this default distorts scoring).

### 2. Classify the opportunity

- **build** — The company has adjacent expertise (existing features in the same
  taxonomy dimension), the opportunity is core to differentiation, and no adequate
  turnkey solution exists. Requires development investment.
- **buy** — A commercial solution exists that covers 80%+ of the need. Faster
  time-to-market through acquisition or licensing.
- **partner** — Requires specialized domain expertise the company lacks. Best
  addressed through co-development, white-label, or referral partnership.

Use the ST's `category`, its blueprint building blocks (taxonomy dimensions), and
the portfolio's existing feature landscape to guide classification. A gap in a
consulting dimension (7.x) naturally suggests `partner`; a gap in a core
technical dimension (4.x, 6.x) may suggest `build` or `buy`.

### 3. Estimate revenue

- Read portfolio markets and filter to those with `market_relevance = "direct"`.
- Use TAM values with conservative penetration assumptions (0.05–0.2%).
- Set confidence:
  - `high` — validated TAM + comparable pricing.
  - `medium` — TAM with assumptions.
  - `low` — rough estimate.

### 4. Generate feature spec (roadmap-ready)

Each opportunity carries a `feature_spec` that can be promoted directly into a
`portfolio/features/{slug}.json` entry on user approval:

- `proposed_slug`: Derived from ST name (kebab-case).
- `name` and `description`: Adapted from ST for feature language.
- `category`: Derived from ST category.
- `readiness`: Always `"planned"`.
- `unmet_needs`: From blueprint building blocks with `coverage: "gap"` — each gap
  block's `gaps` array provides specific unmet capabilities. Falls back to
  `portfolio_anchor.theme_needs_undelivered` or ST description extraction.
- `taxonomy_refs`: Array of taxonomy categories from the ST's blueprint gap blocks
  (e.g., `["1.4", "7.2"]`) — shows which portfolio dimensions this opportunity
  spans.
- `source_themes` and `source_sts`: Traceability to the TIPS value model.

### 5. Assign priority

- `high` — `opportunity_score ≥ 7.0` AND `ranking_value ≥ 4.0`.
- `medium` — `opportunity_score ≥ 4.0` OR `ranking_value ≥ 3.0`.
- `low` — everything else.

## Level 2: Taxonomy gap analysis

After per-ST opportunities are generated, aggregate blueprint building blocks
across **all** Solution Templates (not just unmatched ones) to produce a
taxonomy-level gap report.

1. **Collect all building blocks** from every ST's
   `solution_blueprint.building_blocks`.
2. **Group by taxonomy dimension** (0–7) and then by category (e.g., `6.6`).
3. **Count coverage status** per category: how many STs need this category, and
   of those how many are covered / partial / gap.
4. **Generate the taxonomy gap report** — a table followed by a short strategic
   insight paragraph:

```
Taxonomy Gap Analysis — Portfolio Investment Priorities

| Dim | Taxonomy Category | STs Needing | Covered | Partial | Gap | Priority |
|-----|-------------------|-------------|---------|---------|-----|----------|
| 7   | Digital Transformation (7.2) | 5 | 0 | 1 | 4 | HIGH |
| 1   | 5G & IoT Connectivity (1.4) | 4 | 1 | 2 | 1 | MEDIUM |
| 2   | Cloud Security (2.4) | 3 | 0 | 0 | 3 | HIGH |
| 7   | Program Management (7.4) | 2 | 0 | 0 | 2 | MEDIUM |

Strategic Insight:
- Consulting (Dim 7) is the #1 portfolio gap: 7 building blocks across 5 STs need
  consulting capabilities that don't exist in the portfolio. Consider a consulting
  partnership or practice build.
- Security (Dim 2) gaps affect 3 high-ranked STs. Investing here would improve
  readiness scores across the solution portfolio.
```

### Taxonomy gap priority thresholds

- `HIGH` — ≥3 STs affected AND majority are `gap` (not `partial`).
- `MEDIUM` — 2+ STs affected.
- `LOW` — 1 ST affected.

## Output

Write `portfolio-opportunities.json` to the TIPS project directory (alongside
`tips-value-model.json`). Include both per-ST opportunities and the taxonomy gap
summary. The file schema is documented in `references/opportunity-schema.md`.

Present the opportunities table sorted by `opportunity_score`, followed by the
taxonomy gap report. The user can accept/defer/reject individual opportunities
inline — accepted opportunities promote to `portfolio/features/{slug}.json`
entries via the Step 3 new-feature-creation path, marked with
`tips_ref: "{pursuit-slug}#st-{id}"` for traceability.
