---
name: Customer Journey Analysis
phase: discover
type: divergent
inputs: [engagement-vision, client-context, customer-data]
outputs: [journey-map, pain-points, opportunity-areas]
duration_estimate: "45-60 min with consultant"
requires_plugins: []
---

# Customer Journey Analysis

Map the as-is customer experience to identify pain points, drop-offs, and opportunity areas.

## When to Use

- When the engagement outcome depends on customer experience improvement
- Critical for: gtm-roadmap (understand buyer journey), digital-transformation (digitize touchpoints)
- Valuable for: market-entry (understand local customer expectations)

## Guided Prompt Sequence

### Step 1: Define the Journey Scope
With the consultant:
- Which customer segment? (match engagement scope)
- Which journey? (acquisition, onboarding, usage, renewal, support)
- What level of detail? (high-level stages vs. detailed touchpoints)

### Step 2: Map Journey Stages
Walk through the journey stage by stage:
- **Awareness**: How do customers first learn about the offering?
- **Consideration**: What do they evaluate? Against what alternatives?
- **Purchase/Sign-up**: What's the buying process? Friction points?
- **Onboarding**: First experience? Time to value?
- **Usage**: Core usage patterns? Feature adoption?
- **Support**: How do they get help? Resolution experience?
- **Renewal/Expansion**: What drives retention? What causes churn?

For each stage capture:
- Customer actions and goals
- Touchpoints (channels, systems, people)
- Emotions (satisfaction, frustration, confusion)
- Pain points and friction
- Current metrics (if available from data audit)

### Step 3: Identify Pain Points
Rank pain points by:
- **Severity**: How much does it hurt the customer?
- **Frequency**: How many customers are affected?
- **Business impact**: What does it cost the client? (churn, support cost, lost revenue)

### Step 4: Spot Opportunities
Where could the journey be improved?
- Quick wins (low effort, high impact)
- Strategic improvements (high effort, high impact)
- Innovation opportunities (new capabilities that transform the experience)

## Output Format

Save as `discover/customer-journey.md`:

```markdown
# Customer Journey Analysis

## Journey: [segment] × [journey type]

### Stage: [name]
- **Customer goal**: ...
- **Touchpoints**: ...
- **Pain points**: ...
- **Opportunity**: ...

## Pain Point Priority
| Pain Point | Stage | Severity | Frequency | Business Impact |
|---|---|---|---|---|

## Opportunities
| Opportunity | Type | Effort | Impact |
|---|---|---|---|
```
