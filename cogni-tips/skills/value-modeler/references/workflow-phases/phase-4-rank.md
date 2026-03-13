# Phase 4: Rank & Visualize

## Objective

Apply the F1 formula to calculate solution rankings, produce a prioritized solution roadmap,
and generate the Big Block solution diagram.

## Step 1: Apply Enhanced F1 Formula

The ranking uses a three-step formula that improves on the patent's simple averaging.
Simple averaging flattens scores — a path with T=5,I=4,P=2 gives 3.67, washing out
the high-relevance signal. The enhanced formula preserves peak signals and rewards
cross-cutting solutions.

### Step 1a: Calculate per-chain scores

For each value chain linked to the ST, calculate the F1 base:

```
ChainScore(p) = (SUM(BR_T) + SUM(BR_I) + SUM(BR_P)) / (count_T + count_I + count_P)
```

Only include TIPs with assigned BR values. If a chain has zero scored TIPs, skip it.
Store the array of per-chain scores on the ST as `chain_scores`.

### Step 1b: Peak-weighted aggregation

For STs linked to multiple chains:

```
BR(ST_i) = 0.6 × max(ChainScores) + 0.4 × avg(ChainScores)
```

For single-chain STs, this equals the plain F1 (max = avg).

Why peak-weighting: a cross-cutting solution that addresses one mission-critical chain
and two moderate chains should rank higher than a single-chain moderate solution. Simple
averaging would pull it down; peak-weighting anchors on the strongest justification.

### Step 1c: Foundation readiness adjustment

Count the ST's `foundation_dependencies`:

```
FoundationFactor:
  0-1 dependencies → 1.00
  2-3 dependencies → 0.95
  4+  dependencies → 0.90
```

```
FinalScore(ST_i) = BR(ST_i) × FoundationFactor
```

This surfaces implementation risk as a mild penalty without dominating the ranking.

### Step 1d: Store results

On each ST, store:
- `chain_scores`: array of per-chain F1 scores (for transparency)
- `business_relevance_calculated`: result of Step 1b (before foundation adjustment)
- `foundation_factor`: the readiness multiplier
- `ranking_value`: FinalScore (or user override if `business_relevance` is set)
- `business_relevance`: User override (integer or null, bypasses calculation)

**Edge cases:**
- ST with zero scored TIPs across all chains → `ranking_value` = null, "insufficient data"
- User override set → use override as `ranking_value`, still calculate and show F1 for comparison
- Calculated values are floats (1.0-5.0), not rounded

### Step 1e: Surface quality flags

If any ST has `quality_flag: "quality_investment_needed"` (set by Phase 2 when the matched
portfolio proposition has quality failures), preserve the flag through ranking. The flag does
not affect the ranking score — it is informational. In the ranked output (Step 2), annotate
flagged STs with a warning marker so the user knows which solutions depend on propositions
that need quality improvement before customer-facing use.

## Step 2: Generate Ranked Solution List

Produce `tips-solution-ranking.md` organized by Strategic Theme, with STs ranked within
each theme. This dual structure gives both the thematic view (for strategic planning)
and the global ranking (for budget prioritization).

```markdown
# Solution Ranking: {Project Name}

Customer-specific solution prioritization based on Business Relevance scoring.
{n} Strategic Themes | {n} Solution Templates | Average BR: {avg}

## Strategic Theme Rankings

| # | Theme | Avg BR | Top Solution | STs |
|---|-------|--------|-------------|-----|
| 1 | Smart Manufacturing & Supply Chain | 4.35 | Digital Twin Production Optimization | 4 |
| 2 | Regulatory Compliance & Sustainability | 4.15 | Packaging Compliance Manager | 3 |
| 3 | Health & Nutrition Transformation | 3.48 | AI Personalization Platform | 3 |
| ... |

## Theme 1: {Top Theme Name}
Strategic Question: {question}
Executive Sponsor: {sponsor type}
Theme Average BR: {avg}

| Rank | Solution Template | BR Score | Category | Chains | Foundation |
|------|------------------|----------|----------|--------|------------|
| 1 | ... | 4.67 | software | VC-5, VC-6 | 0.95 |
| 2 | ... | 4.33 | hardware | VC-5 | 0.95 |

### ST Details
[detailed ST descriptions with SPIs, metrics, foundation deps]

## Theme 2: {Next Theme}
...

---

## Global Priority View

For cross-theme budget allocation, all STs ranked globally:

### Tier 1: Mission Critical (BR >= 4.0)
| Rank | Solution Template | Theme | BR Score |
|------|------------------|-------|----------|
| 1 | ... | Smart Manufacturing | 4.67 |

### Tier 2: High Impact (BR 3.0 - 3.99)
...

### Tier 3: Moderate Impact (BR < 3.0)
...

---

## Scoring Summary

- Strategic Themes: {n}
- Solutions ranked: {n}
- Average BR: {avg}
- Tier 1 (mission critical): {n} solutions across {n} themes
- Portfolio gaps identified: {n}

## Methodology

Rankings calculated using TIPS Value Modeler formula F1 (Enhanced):
BR(ST) = 0.6 × max(ChainScore) + 0.4 × avg(ChainScore) × FoundationFactor
Based on Siemens TIPS methodology (WO2018046399A1).
```

Use the project language (DE/EN) for all labels and descriptions.

## Step 3: Generate Big Block Diagram

The Big Block is the patent's signature output — a solution architecture diagram showing
which solutions map to which areas of the customer's business. With Strategic Themes, the
Big Block gains a natural column/section structure where each theme is a distinct zone.

Generate `tips-big-block.md` as a structured markdown representation:

```markdown
# Big Block: Solution Architecture for {Customer/Project}

## {Industry} — Strategic Solution Landscape

### Theme Overview
┌────────────────┬────────────────┬────────────────┬────────────────┬────────────────┐
│   Theme 1      │   Theme 2      │   Theme 3      │   Theme 4      │   Theme 5      │
│   Health &     │   Regulatory   │   Smart Mfg    │   Commercial   │   Digital      │
│   Nutrition    │   Compliance   │   & Supply     │   Excellence   │   Retail       │
│   BR: 3.48     │   BR: 4.15     │   BR: 4.35     │   BR: 3.49     │   BR: 2.84     │
│   CPO          │   CSO          │   COO          │   CCO          │   CDO          │
└────────────────┴────────────────┴────────────────┴────────────────┴────────────────┘

### Theme 1: Health & Nutrition Transformation (CPO)
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐           │
│  │ AI Personalization  │  │ Reformulation       │           │
│  │ Platform            │  │ Framework           │           │
│  │ BR: 3.61 ★★★☆      │  │ BR: 3.33 ★★★☆      │           │
│  └─────────────────────┘  └─────────────────────┘           │
│                                                              │
└──────────────────────────────────────────────────────────────┘

### Theme 2: Regulatory Compliance & Sustainability (CSO)
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐           │
│  │ Compliance Manager  │  │ Modular Packaging   │           │
│  │ BR: 4.28 ★★★★      │  │ BR: 4.23 ★★★★      │           │
│  └─────────────────────┘  └─────────────────────┘           │
│                                                              │
└──────────────────────────────────────────────────────────────┘

[... remaining themes ...]

### Solution Process Improvements (by theme)
┌──────────────────────────────────────────────────────────────┐
│ Theme 1: Datenschutzkonforme Profil-Verwaltung (governance)  │
│ Theme 2: Lieferanten-Compliance-Zertifizierung (governance)  │
│ Theme 3: Prädiktive-Wartung in Schichtübergabe (workflow)    │
│ ...                                                          │
└──────────────────────────────────────────────────────────────┘

### Foundation Requirements
┌──────────────────────────────────────────────────────────────┐
│ AI/ML Engineers    │ Cloud ERP Migration │ IoT Monitoring    │
│ Industry 4.0      │ Digital Traceability │ Legacy Systems    │
└──────────────────────────────────────────────────────────────┘
```

The theme-organized Big Block communicates at a glance: "Here are 5 investment areas,
each with an executive owner and a clear set of solutions. Fund themes 2 and 3 first."

**If cogni-visual is available:** Suggest generating a proper visual Big Block using
the big-picture or slides workflow. The markdown version serves as the content brief.

## Step 4: Implementation Roadmap

Based on the ranking and horizon alignment, suggest an implementation sequence.
The roadmap is organized by wave but annotated with themes so the customer can see
which strategic areas activate in which phase:

```markdown
## Implementation Roadmap

### Wave 1: Quick Wins (0-6 months)
Solutions from Tier 1 where value chain candidates are "act" horizon.
Foundation prerequisites that are already partially in place.

| Solution | Theme | BR | Horizon |
|----------|-------|----|---------|
| Compliance Manager | Regulatory & Sustainability | 4.28 | act |
| Modular Packaging | Regulatory & Sustainability | 4.23 | act |
| ... |

### Wave 2: Strategic Build (6-18 months)
Tier 1-2 solutions on "plan" horizon.
Foundation building for Wave 3.

| Solution | Theme | BR | Horizon |
|----------|-------|----|---------|
| Digital Twin | Smart Manufacturing | 4.43 | plan |
| ... |

### Wave 3: Future Positioning (18-36 months)
Tier 2-3 solutions on "observe" horizon.
Strategic bets on emerging possibilities.

### Theme Activation Timeline
Shows when each theme "turns on" based on its solutions' wave distribution:

| Theme | Wave 1 | Wave 2 | Wave 3 |
|-------|--------|--------|--------|
| Regulatory & Sustainability | ██████ | ████ | |
| Smart Manufacturing | | ██████ | ████ |
| Health & Nutrition | ████ | ████ | ██ |
| ... |
```

## Step 5: Present Final Output

Summarize the complete value model to the user:

"Here's your customer-specific solution roadmap:

- **{n} Strategic Themes** — distinct investment areas for executive decision-making
- **{n} value chains** connecting trends through implications to possibilities
- **{n} Solution Templates** generated, ranked by business relevance
- **{n} SPIs** — process changes to realize solution value
- **{n} Metrics** — KPIs to measure success
- **Top theme:** {Theme-1} (avg BR: {x}) — {strategic question}
- **Top 3 solutions:** {ST-1}, {ST-2}, {ST-3}
- **Portfolio gaps found:** {n} solutions not covered by existing products
- **Implementation:** {n} quick wins, {n} strategic builds, {n} future bets

Files created:
- `tips-value-model.json` — Complete model data (themes + chains + solutions)
- `tips-solution-ranking.md` — Ranked solution list by theme and global
- `tips-big-block.md` — Solution architecture diagram organized by theme

Next steps:
- Connect portfolio gaps to cogni-portfolio for feature/proposition development
- Generate a visual Big Block using cogni-visual
- Use the theme structure to drive customer proposal creation — one theme per proposal section"

## Output

Update `tips-value-model.json`:
- Set `ranking_value` and `business_relevance_calculated` on all STs
- Add `implementation_roadmap` section

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"complete"`
- Add `"phase-4"` to `phases_completed`
- Record `ranked_solutions`, `avg_ranking`, `tier_distribution`, `portfolio_gaps`
