# Phase 4: Rank & Visualize

## Objective

Apply the F1 formula to calculate solution rankings, produce a prioritized solution roadmap,
and generate the Big Block solution diagram.

## Step 1: Apply Enhanced F1 Formula

The ranking uses a three-step formula that improves on the patent's simple averaging.
Simple averaging flattens scores — a path with T=5,I=4,P=2 gives 3.67, washing out
the high-relevance signal. The enhanced formula preserves peak signals and rewards
cross-cutting solutions.

### Step 1a: Calculate per-path scores

For each path linked to the ST, calculate the F1 base:

```
PathScore(p) = (SUM(BR_T) + SUM(BR_I) + SUM(BR_P)) / (count_T + count_I + count_P)
```

Only include TIPs with assigned BR values. If a path has zero scored TIPs, skip it.
Store the array of per-path scores on the ST as `path_scores`.

### Step 1b: Peak-weighted aggregation

For STs linked to multiple paths:

```
BR(ST_i) = 0.6 × max(PathScores) + 0.4 × avg(PathScores)
```

For single-path STs, this equals the plain F1 (max = avg).

Why peak-weighting: a cross-cutting solution that addresses one mission-critical path
and two moderate paths should rank higher than a single-path moderate solution. Simple
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
- `path_scores`: array of per-path F1 scores (for transparency)
- `business_relevance_calculated`: result of Step 1b (before foundation adjustment)
- `foundation_factor`: the readiness multiplier
- `ranking_value`: FinalScore (or user override if `business_relevance` is set)
- `business_relevance`: User override (integer or null, bypasses calculation)

**Edge cases:**
- ST with zero scored TIPs across all paths → `ranking_value` = null, "insufficient data"
- User override set → use override as `ranking_value`, still calculate and show F1 for comparison
- Calculated values are floats (1.0-5.0), not rounded

## Step 2: Generate Ranked Solution List

Sort all STs by `ranking_value` descending and produce `tips-solution-ranking.md`:

```markdown
# Solution Ranking: {Project Name}

Customer-specific solution prioritization based on Business Relevance scoring.

## Priority Tier 1: Mission Critical (BR >= 4.0)

| Rank | Solution Template | BR Score | Category | Paths | Portfolio |
|------|------------------|----------|----------|-------|-----------|
| 1 | Predictive Quality Analytics | 4.67 | software | 3 | predictive-analytics |
| 2 | Real-time OEE Dashboard | 4.33 | software | 2 | PORTFOLIO GAP |
| 3 | Compliance Automation Suite | 4.00 | software | 1 | compliance-engine |

## Priority Tier 2: High Impact (BR 3.0 - 3.99)

| Rank | Solution Template | BR Score | Category | Paths | Portfolio |
|------|------------------|----------|----------|-------|-----------|
| 4 | Digital Twin Simulation | 3.80 | hybrid | 2 | digital-twin |
| ... |

## Priority Tier 3: Moderate Impact (BR 2.0 - 2.99)
...

## Priority Tier 4: Low Priority (BR < 2.0)
...

## Unranked (Insufficient Scoring Data)
...

---

## Scoring Summary

- Solutions ranked: {n}
- Average BR: {avg}
- Tier 1 (mission critical): {n} solutions
- Tier 2 (high impact): {n} solutions
- Portfolio gaps identified: {n}
- Foundation prerequisites: {list}

## Methodology

Rankings calculated using TIPS Value Modeler formula F1:
BR(ST) = average Business Relevance of all scored TIP entities in linked paths.
Based on Siemens TIPS methodology (WO2018046399A1).
```

Use the project language (DE/EN) for all labels and descriptions.

## Step 3: Generate Big Block Diagram

The Big Block is the patent's signature output — a solution architecture diagram showing
which solutions map to which areas of the customer's business.

Generate `tips-big-block.md` as a structured markdown representation:

```markdown
# Big Block: Solution Architecture for {Customer/Project}

## {Industry} — Digital Solution Landscape

### Tier 1: Mission Critical Solutions
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐           │
│  │ Predictive Quality  │  │ Real-time OEE       │           │
│  │ Analytics Platform  │  │ Dashboard           │           │
│  │ BR: 4.67 ★★★★★     │  │ BR: 4.33 ★★★★      │           │
│  │ → predictive-       │  │ → PORTFOLIO GAP     │           │
│  │   analytics         │  │                     │           │
│  └─────────────────────┘  └─────────────────────┘           │
│                                                              │
└──────────────────────────────────────────────────────────────┘

### Process Changes Required (SPIs)
┌──────────────────────────────────────────────────────────────┐
│ SPI-001: Establish    │ SPI-002: Train quality │             │
│ data governance       │ engineers on ML        │             │
│ policy                │ interpretation         │             │
│ → Predictive Quality  │ → Predictive Quality   │             │
└──────────────────────────────────────────────────────────────┘

### Foundation Requirements
┌──────────────────────────────────────────────────────────────┐
│ Data Infrastructure │ ML Engineering │ Cloud Platform       │
│ Maturity            │ Talent          │ Readiness            │
└──────────────────────────────────────────────────────────────┘
```

**If cogni-visual is available:** Suggest generating a proper visual Big Block using
the big-picture or slides workflow. The markdown version serves as the content brief.

## Step 4: Implementation Roadmap

Based on the ranking and horizon alignment, suggest an implementation sequence:

```markdown
## Implementation Roadmap

### Wave 1: Quick Wins (0-6 months)
Solutions from Tier 1 where all path candidates are "act" horizon.
Foundation prerequisites that are already partially in place.

### Wave 2: Strategic Build (6-18 months)
Tier 1-2 solutions on "plan" horizon.
Foundation building for Wave 3.

### Wave 3: Future Positioning (18-36 months)
Tier 2-3 solutions on "observe" horizon.
Strategic bets on emerging possibilities.
```

## Step 5: Present Final Output

Summarize the complete value model to the user:

"Here's your customer-specific solution roadmap:

- **{n} TIPS paths** connecting trends through implications to possibilities
- **{n} Solution Templates** generated, ranked by business relevance
- **{n} SPIs** — process changes to realize solution value
- **{n} Metrics** — KPIs to measure success
- **Top 3 priorities:** {ST-1}, {ST-2}, {ST-3}
- **Portfolio gaps found:** {n} solutions not covered by existing products
- **Implementation:** {n} quick wins, {n} strategic builds, {n} future bets

Files created:
- `tips-value-model.json` — Complete model data
- `tips-solution-ranking.md` — Ranked solution list
- `tips-big-block.md` — Solution architecture diagram

Next steps:
- Connect portfolio gaps to cogni-portfolio for feature/proposition development
- Generate a visual Big Block using cogni-visual
- Use the ranking to drive customer proposal creation"

## Output

Update `tips-value-model.json`:
- Set `ranking_value` and `business_relevance_calculated` on all STs
- Add `implementation_roadmap` section

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"complete"`
- Add `"phase-4"` to `phases_completed`
- Record `ranked_solutions`, `avg_ranking`, `tier_distribution`, `portfolio_gaps`
