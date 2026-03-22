---
name: Assumption Mapping
phase: define
type: convergent
inputs: [discovery-synthesis, research-findings]
outputs: [assumption-map, prioritized-assumptions]
duration_estimate: "20-30 min with consultant"
requires_plugins: [cogni-claims]
---

# Assumption Mapping

Identify, categorize, and prioritize the assumptions that underpin the engagement's problem framing.

## When to Use

- When Discovery surfaced claims that need verification
- Critical for: business-case (financial assumptions), market-entry (market assumptions)
- Pairs with cogni-claims for automated verification of sourced assumptions

## Guided Prompt Sequence

### Step 1: Extract Assumptions
From discovery outputs, identify assumptions — statements treated as true but not yet proven:
- Market size/growth claims
- Customer behavior assertions
- Technology trend projections
- Competitive positioning claims
- Financial projections or benchmarks

Categorize each:
- **Factual** — can be verified against a source (dispatch to cogni-claims)
- **Judgment** — requires expert opinion or analysis
- **Unknown** — data doesn't exist yet, needs primary research

### Step 2: Risk/Impact Matrix
Plot assumptions on a 2×2:
- **High impact, high uncertainty** → Must verify before proceeding
- **High impact, low uncertainty** → Important but likely safe
- **Low impact, high uncertainty** → Monitor but don't block on
- **Low impact, low uncertainty** → Accept and move on

### Step 3: Verification Plan
For high-priority assumptions:
- **Factual**: Submit to cogni-claims with source URLs
- **Judgment**: Identify which stakeholders can validate
- **Unknown**: Note as a gap — may need primary research or scenario planning

### Step 4: Document
Record all assumptions with their status and verification plan.

## Output Format

Save as `define/assumption-map.md`:

```markdown
# Assumption Map

## Must Verify (High Impact, High Uncertainty)
| # | Assumption | Type | Verification Method | Status |
|---|---|---|---|---|
| 1 | "Market will grow 18% YoY" | Factual | cogni-claims | pending |

## Important but Likely Safe
...

## Monitor
...
```
