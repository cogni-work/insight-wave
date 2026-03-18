# Output Specifications

Both deliverables have two variants — **customer mode** (named customer) and **segment mode** (reusable market segment pitch). The arc structure and quality criteria are identical; only the framing differs.

---

## sales-presentation.md

A "Why Change" sales narrative structured using the Corporate Visions arc. Written in the configured language (`en` or `de`). All claims include numbered citations.

### Customer Mode Template

```markdown
---
type: sales-presentation
pitch_mode: customer
customer: "{customer_name}"
provider: "{company_name}"
industry: "{customer_industry}"
methodology: corporate-visions-why-change
language: "{language}"
generated: "{date}"
portfolio_path: "{portfolio_path}"
---

# {customer_name} — Why Change

## Executive Hook

[The unconsidered need that reframes the buyer's thinking — the most surprising finding from research. 10% of total length.]

---

## Why Change: The Hidden Cost of the Status Quo

### The Current Reality

[What {customer_name} assumes is "good enough" — the status quo belief that feels reasonable. Use PSB Problem section from why-change-patterns.md.]

### Unconsidered Needs

[Problems they haven't considered, revealed by research + portfolio capabilities. Use PSB Solution section. Evidence-based reframing with citations.]

### Why This Matters

[Competitive advantage for early recognizers. Use PSB Benefit section. End with competitive implication.]

---

## Why Now: The Cost of Waiting

### Timing Triggers

[2-3 forcing functions: regulatory deadlines, competitive pressure, market timing. Specific dates, not "soon". From why-now-patterns.md.]

### Cost of Inaction

[Quantified 3-year compound impact: regulatory penalties + talent premium + market position loss + opportunity cost. Before/after contrast.]

---

## Why You: Our Unique Position

### Key Differentiators

[2-3 Key Differentiators using IS-DOES-MEANS structure from why-you-patterns.md. You-Phrasing throughout DOES layer. Mapped to buyer needs from Phase 1.]

| Position | IS (your solution/capability) | DOES (for {customer_name}) | MEANS (competitive moat) |
|----------|-------------------------------|---------------------------|--------------------------|
| [Name] | [What the solution IS — positioning statement, NOT the problem] | [Quantified outcome with You-Phrasing] | [Why competitors can't replicate — time/experience/certification barrier] |

**IS semantics:** IS must describe YOUR SOLUTION or capability, never the customer's problem. The customer's problem informs which capability to highlight, but IS always positions the solution.

**MEANS downstream note:** When this narrative is rendered as slides (cogni-visual), MEANS is transformed from competitive moat to technology/methodology proof — the technical architecture, certifications, or methodology that makes the DOES claims credible. This is by design: slide audiences need proof of HOW, not why competitors can't copy.

### Competitive Differentiation

[Why alternatives fall short — from portfolio competitor data. Trap questions that expose competitor weaknesses.]

---

## Why Pay: The Business Case

### Investment Overview

[Solution tiers from portfolio — PoV / Small / Medium / Large. Duration, effort, price per tier.]

### ROI Analysis

[TCO vs Total Value of Ownership. Cost of inaction (from Phase 2) vs investment (from solutions). Simple ratio: "Action costs less than inaction by Nx."]

---

## Next Steps

[Proposed engagement path — typically start with PoV tier. Clear call-to-action.]

---

## Sources & Claims

[Numbered citations with URLs. Format: [N] Title — URL]
```

### Segment Mode Template

```markdown
---
type: sales-presentation
pitch_mode: segment
segment: "{segment_name}"
provider: "{company_name}"
industry: "{customer_industry}"
market: "{market_slug}"
methodology: corporate-visions-why-change
language: "{language}"
generated: "{date}"
portfolio_path: "{portfolio_path}"
---

# {segment_name} — Why Change

## Executive Hook

[The unconsidered need that reframes thinking for organizations in this segment — the most surprising industry-level finding. 10% of total length.]

---

## Why Change: The Hidden Cost of the Status Quo

### The Current Reality

[What organizations in {segment_name} typically assume is "good enough" — the prevailing industry belief. Use PSB Problem section from why-change-patterns.md.]

### Unconsidered Needs

[Problems the segment hasn't considered, revealed by market research + portfolio capabilities. Use PSB Solution section. Industry evidence with citations.]

### Why This Matters

[Competitive advantage for early movers in this segment. Use PSB Benefit section. End with market-level implication.]

---

## Why Now: The Cost of Waiting

### Timing Triggers

[2-3 forcing functions affecting the segment: regulatory deadlines, competitive dynamics, technology shifts. Specific timelines, not "soon". From why-now-patterns.md.]

### Cost of Inaction

[Quantified 3-year compound impact for a typical organization in this segment. Before/after contrast using industry benchmarks.]

---

## Why You: Our Unique Position

### Key Differentiators

[2-3 Key Differentiators using IS-DOES-MEANS structure from why-you-patterns.md. You-Phrasing throughout DOES layer. Mapped to typical buyer needs in this segment.]

| Position | IS (your solution/capability) | DOES (for {segment_name}) | MEANS (competitive moat) |
|----------|-------------------------------|---------------------------|--------------------------|
| [Name] | [What the solution IS — positioning statement, NOT the problem] | [Quantified outcome with You-Phrasing] | [Why competitors can't replicate] |

### Competitive Differentiation

[Why alternatives fall short for this segment — from portfolio competitor data. Trap questions that expose competitor weaknesses.]

---

## Why Pay: The Business Case

### Investment Overview

[Solution tiers from portfolio — PoV / Small / Medium / Large. Duration, effort, price per tier.]

### ROI Analysis

[TCO vs Total Value of Ownership for a typical organization. Cost of inaction (from Phase 2) vs investment (from solutions). Simple ratio.]

---

## Next Steps

[Recommended engagement path for organizations in this segment. Suggest starting with PoV tier.]

---

## Sources & Claims

[Numbered citations with URLs. Format: [N] Title — URL]
```

### Quality Criteria (both modes)

Apply the quality gates from `cogni-narrative/skills/narrative/references/story-arc/corporate-visions/arc-definition.md`:
- All 4 elements present (Why Change, Why Now, Why You, Why Pay)
- PSB structure in Why Change
- 2-3 forcing functions in Why Now with specific timelines
- 2-3 Key Differentiators with IS-DOES-MEANS in Why You
- 3-4 cost dimensions stacked in Why Pay
- 15-25 total citations
- Buyer role awareness reflected in tone (no inline tags)

---

## sales-proposal.md

A formal proposal document. More structured and action-oriented than the presentation. Includes implementation details and pricing from portfolio solutions.

### Customer Mode Template

```markdown
---
type: sales-proposal
pitch_mode: customer
customer: "{customer_name}"
provider: "{company_name}"
industry: "{customer_industry}"
language: "{language}"
generated: "{date}"
portfolio_path: "{portfolio_path}"
---

# Proposal: {solution_name} for {customer_name}

## Executive Summary

[2-3 paragraphs: the unconsidered need (from Why Change), the urgency (from Why Now), and our unique position (from Why You). End with investment range and expected ROI.]

## Understanding Your Situation

[Customer context from web research + buying center mapping. Industry challenges specific to {customer_name}. Pain points aligned with buyer personas. Show we understand their world before proposing solutions.]

## Proposed Solution

[For each focused feature/product:]

### {Product/Feature Name}

**What it is:** [IS statement from proposition]
**What it does for you:** [DOES statement, adapted for {customer_name} context]
**Business outcome:** [MEANS statement with quantified impact]

[If TIPS data available: link to trend-driven urgency and value chain narrative]

## Implementation Approach

[From portfolio solutions — phases, deliverables, timeline]

### Recommended Tier: {tier_name}

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| [Phase name] | [weeks] | [key deliverables] |

### Alternative Tiers

[Brief overview of other available tiers (PoV/S/M/L) with duration and price range]

## Investment & ROI

### Pricing

| Tier | Duration | Investment | Expected ROI |
|------|----------|-----------|--------------|
| Proof of Value | [weeks] | [price] | [ROI metric] |
| [Other tiers] | ... | ... | ... |

### Value Justification

[Cost of inaction (from Why Pay) vs investment. 3-year horizon. Simple ratio.]

## Why {company_name}

[Competitive differentiation from portfolio compete data. Proof points. Team expertise. Relevant experience.]

## Next Steps

1. [Specific next action with timeline]
2. [Follow-up meeting or workshop]
3. [Decision timeline]

## Appendix

### Detailed Pricing Breakdown

[Per-phase effort, role rates, deliverables from solution entity]

### Team & Credentials

[Relevant team members and experience]

### Sources

[All citations from research phases]
```

### Segment Mode Template

```markdown
---
type: sales-proposal
pitch_mode: segment
segment: "{segment_name}"
provider: "{company_name}"
industry: "{customer_industry}"
market: "{market_slug}"
language: "{language}"
generated: "{date}"
portfolio_path: "{portfolio_path}"
---

# Proposal: {solution_name} for {segment_name}

## Executive Summary

[2-3 paragraphs: the unconsidered need for this segment (from Why Change), the urgency (from Why Now), and our unique position (from Why You). End with investment range and expected ROI.]

## Understanding the Segment

[Segment context from market research. Industry challenges common to {segment_name} organizations. Pain points aligned with typical buyer personas in this segment. Demonstrate deep market understanding.]

## Proposed Solution

[For each focused feature/product:]

### {Product/Feature Name}

**What it is:** [IS statement from proposition]
**What it does for organizations in this segment:** [DOES statement, adapted for segment context]
**Business outcome:** [MEANS statement with quantified impact using industry benchmarks]

[If TIPS data available: link to trend-driven urgency and value chain narrative]

## Implementation Approach

[From portfolio solutions — phases, deliverables, timeline]

### Recommended Tier: {tier_name}

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| [Phase name] | [weeks] | [key deliverables] |

### Alternative Tiers

[Brief overview of other available tiers (PoV/S/M/L) with duration and price range]

## Investment & ROI

### Pricing

| Tier | Duration | Investment | Expected ROI |
|------|----------|-----------|--------------|
| Proof of Value | [weeks] | [price] | [ROI metric] |
| [Other tiers] | ... | ... | ... |

### Value Justification

[Cost of inaction for a typical organization in this segment vs investment. 3-year horizon. Simple ratio using industry benchmarks.]

## Why {company_name}

[Competitive differentiation from portfolio compete data. Proof points. Segment-specific expertise and track record.]

## Next Steps

1. [Recommended engagement path for organizations in this segment]
2. [Assessment or discovery workshop proposal]
3. [Typical decision timeline for this segment]

## Appendix

### Detailed Pricing Breakdown

[Per-phase effort, role rates, deliverables from solution entity]

### Team & Credentials

[Relevant team members and segment experience]

### Sources

[All citations from research phases]
```

### Quality Criteria (both modes)

- Executive summary captures the arc in 2-3 paragraphs
- Situation section shows research depth (not generic)
- Solution section uses IS/DOES/MEANS from portfolio propositions
- Implementation from actual portfolio solution entities
- Pricing from actual solution tier data
- ROI links back to Why Pay analysis
- All claims have citations
