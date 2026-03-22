---
name: Data Audit
phase: discover
type: divergent
inputs: [engagement-vision, client-context]
outputs: [data-inventory, gap-analysis]
duration_estimate: "30-45 min with consultant"
requires_plugins: []
---

# Data Audit

Inventory available data sources, assess quality, and identify critical gaps that could undermine the engagement.

## When to Use

- When the engagement depends on quantitative evidence
- Critical for: cost-optimization (need cost baselines), business-case (need financial data)
- Valuable for: digital-transformation (need current-state metrics)

## Guided Prompt Sequence

### Step 1: Inventory Data Sources
Walk through with the consultant:
- What internal data systems exist? (CRM, ERP, BI tools, spreadsheets)
- What reports are regularly produced? (financial reports, dashboards, reviews)
- What external data sources are used? (market research, analyst reports, benchmarks)
- What customer data is available? (feedback, usage analytics, support tickets)

### Step 2: Assess Quality
For each data source:
- **Recency**: When was it last updated?
- **Completeness**: Does it cover the full scope of the engagement?
- **Accuracy**: How reliable is it? Known issues?
- **Accessibility**: Can we get it? Who owns it? Privacy/compliance constraints?

### Step 3: Map to Engagement Needs
What data does each diamond phase need?
- **Discovery**: Market data, competitive intelligence, internal performance
- **Define**: Assumption verification data, baseline metrics
- **Develop**: Financial models, operational benchmarks
- **Deliver**: Validation data, implementation metrics

### Step 4: Identify Gaps
Where are the critical gaps?
- What data is needed but doesn't exist?
- What data exists but can't be accessed?
- What data exists but is too outdated to be useful?

For each gap: can it be filled during the engagement? By whom? At what cost?

## Output Format

Save as `discover/data-audit.md`:

```markdown
# Data Audit

## Available Data Sources
| Source | Type | Recency | Quality | Accessible |
|---|---|---|---|---|

## Gap Analysis
| Need | Phase | Gap | Resolution |
|---|---|---|---|
```
