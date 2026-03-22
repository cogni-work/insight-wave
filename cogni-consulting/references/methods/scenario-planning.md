---
name: Scenario Planning
phase: develop
type: divergent
inputs: [problem-statement, hmw-questions, discovery-themes]
outputs: [scenario-matrix, scenario-narratives]
duration_estimate: "45-60 min with consultant"
requires_plugins: []
---

# Scenario Planning

Explore 4 plausible futures using a 2×2 uncertainty matrix to stress-test options and surface robust strategies.

## When to Use

- When the engagement faces significant external uncertainty
- Critical for: market-entry, digital-transformation, innovation-portfolio
- Valuable for: strategic-options when the competitive landscape is volatile

## Guided Prompt Sequence

### Step 1: Identify Critical Uncertainties
From the discovery findings and problem statement, surface external uncertainties:
- Market dynamics (growth, consolidation, disruption)
- Technology shifts (adoption curves, standards evolution)
- Regulatory changes (compliance requirements, market access)
- Competitive moves (new entrants, M&A, pricing changes)
- Customer behavior (preferences, switching costs, expectations)

Ask the consultant: "Which 2 uncertainties would most impact the engagement outcome if they resolved differently than expected?"

### Step 2: Build the 2×2 Matrix
Use the two selected uncertainties as axes. Each axis has two poles (e.g., "Market consolidates" vs. "Market fragments"). This creates 4 quadrants, each a distinct scenario.

### Step 3: Name and Describe Scenarios
For each quadrant:
- **Name**: A memorable, evocative label (2-4 words)
- **Narrative**: What does this world look like in 3-5 years? (3-5 sentences)
- **Signals**: What early indicators would tell us this scenario is emerging?
- **Implications for client**: How would this scenario affect the engagement outcome?

### Step 4: Stress-Test Options
Map the options from Develop against the scenarios:
- Which options work well in multiple scenarios? (robust)
- Which only work in one scenario? (risky bets)
- Are there options that work in no scenario? (eliminate)
- Are there scenarios with no good options? (gap to fill)

### Step 5: Identify Robust Strategies
Strategies that perform reasonably well across multiple scenarios are the safest recommendations. Pure bets on a single scenario should be flagged as high-risk.

## Output Format

Save as `develop/scenarios/scenario-matrix.md`:

```markdown
# Scenario Matrix

## Uncertainties
- **Axis 1**: [uncertainty] — [pole A] vs. [pole B]
- **Axis 2**: [uncertainty] — [pole A] vs. [pole B]

## Scenarios

### Scenario 1: [Name] (A1 × A2)
**Narrative**: ...
**Signals**: ...
**Client impact**: ...

### Scenario 2: [Name] (A1 × B2)
...

## Option × Scenario Fit
| Option | Scenario 1 | Scenario 2 | Scenario 3 | Scenario 4 | Robustness |
|---|---|---|---|---|---|
| [option] | strong | weak | moderate | strong | 3/4 |
```
