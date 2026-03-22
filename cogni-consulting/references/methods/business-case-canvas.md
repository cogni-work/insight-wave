---
name: Business Case Canvas
phase: deliver
type: convergent
inputs: [ranked-options, verified-claims, engagement-constraints]
outputs: [business-case-document]
duration_estimate: "45-90 min with consultant"
requires_plugins: []
---

# Business Case Canvas

Structure the financial and strategic justification for the recommended option(s).

## When to Use

- When the engagement needs to justify an investment decision
- Essential for: business-case, cost-optimization
- Valuable for: strategic-options, digital-transformation, market-entry

## Guided Prompt Sequence

### Step 1: Investment Summary
Capture the headline numbers:
- **Total investment required**: Capex + opex over the planning horizon
- **Planning horizon**: Typically 3-5 years
- **Implementation timeline**: Phases with estimated durations

### Step 2: Revenue/Savings Model
Depending on vision class:
- **Revenue-generating**: Market size × capture rate × pricing = revenue forecast
- **Cost-saving**: Current cost baseline − projected cost after optimization = savings
- **Strategic value**: Qualitative value (competitive positioning, capability building, risk reduction)

Build the model collaboratively. Flag assumptions explicitly — cross-reference with verified claims from cogni-claims.

### Step 3: Key Assumptions
List every assumption the business case depends on:
- Market assumptions (growth, pricing, competition)
- Operational assumptions (timeline, resource availability, productivity)
- Financial assumptions (discount rate, cost of capital, inflation)

For each, note: verified by cogni-claims? Supported by discovery research? Expert judgment?

### Step 4: Risk Assessment
Identify 5-10 risks:
- **Probability**: Low / Medium / High
- **Impact**: Low / Medium / High
- **Mitigation**: What can be done to reduce likelihood or impact?
- **Owner**: Who is responsible for managing this risk?

### Step 5: Sensitivity Analysis
Test 3 scenarios:
- **Optimistic**: Best-case assumptions (+20% on revenue/savings, -20% on costs)
- **Base**: Current model as-is
- **Conservative**: Worst-case assumptions (-20% on revenue/savings, +20% on costs)

Does the investment still make sense in the conservative scenario?

### Step 6: Recommendation
Structure the recommendation:
- **Go**: Investment justified under base and conservative scenarios
- **Conditional go**: Investment justified under base scenario, needs monitoring under conservative
- **No-go**: Investment does not justify under base scenario

## Output Format

Save as `deliver/business-case.md`:

```markdown
# Business Case: [Option Name]

## Investment Summary
| Metric | Value |
|---|---|
| Total investment | €X.XM |
| Planning horizon | N years |
| Expected return | €X.XM (NPV) / XX% (IRR) |
| Payback period | N months |

## Revenue/Savings Model
...

## Key Assumptions
| # | Assumption | Source | Verified |
|---|---|---|---|

## Risk Register
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|

## Sensitivity Analysis
| Scenario | Revenue | Cost | NPV | IRR |
|---|---|---|---|---|

## Recommendation
[Go / Conditional go / No-go] — [rationale]
```
