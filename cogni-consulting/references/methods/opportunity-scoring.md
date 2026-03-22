---
name: Opportunity Scoring
phase: deliver
type: convergent
inputs: [option-synthesis, problem-statement, engagement-constraints]
outputs: [scored-option-matrix, ranked-options]
duration_estimate: "30-45 min with consultant"
requires_plugins: []
---

# Opportunity Scoring

Score and rank strategic options against weighted criteria to identify the strongest recommendations.

## When to Use

- When Develop has produced 3+ options that need evaluation
- Essential for: strategic-options, innovation-portfolio
- Useful for all vision classes during the Deliver phase

## Guided Prompt Sequence

### Step 1: Define Criteria
Propose 4-6 evaluation criteria based on the vision class:

| Vision Class | Suggested Criteria |
|---|---|
| strategic-options | Strategic fit, Market potential, Feasibility, Time to value, Risk, Investment |
| business-case | NPV/ROI, Risk, Time to breakeven, Strategic alignment, Implementation complexity |
| gtm-roadmap | Market size, Competitive advantage, Channel fit, Speed to market, Cost to serve |
| cost-optimization | Savings potential, Implementation effort, Risk of disruption, Speed, Sustainability |
| digital-transformation | Business impact, Technical feasibility, Change readiness, Cost, Strategic urgency |
| innovation-portfolio | Innovation potential, Market timing, Capability fit, Investment, Risk |
| market-entry | Market attractiveness, Competitive position, Entry barriers, Investment, Risk |

Ask: "These are the suggested criteria. Want to add, remove, or modify any?"

### Step 2: Weight Criteria
Assign percentage weights summing to 100%. The engagement constraints guide weighting:
- Timeline pressure? Weight "Speed" higher.
- Risk-averse client? Weight "Risk" higher.
- Innovation mandate? Weight "Innovation potential" higher.

### Step 3: Score Options
For each option × criterion, assign a score (1-5):
- 5 = Excellent fit / performance
- 4 = Good
- 3 = Moderate
- 2 = Weak
- 1 = Poor fit / high risk

Score collaboratively with the consultant — this is a judgment exercise, not a formula.

### Step 4: Calculate and Rank
Compute weighted scores and present the ranking matrix:

| Option | Criteria 1 (30%) | Criteria 2 (25%) | ... | Weighted Total |
|---|---|---|---|---|
| Option A | 4 (1.2) | 5 (1.25) | ... | 4.1 |
| Option B | 3 (0.9) | 4 (1.0) | ... | 3.6 |

### Step 5: Discuss and Decide
The scores inform but don't determine the recommendation. Ask:
- Does the ranking feel right? Any surprises?
- Are there qualitative factors the scoring doesn't capture?
- Which options should advance to business case development?

## Output Format

Save as `deliver/option-scoring.md`.
