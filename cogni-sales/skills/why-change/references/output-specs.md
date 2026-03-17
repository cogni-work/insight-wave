# Output Specifications

## sales-presentation.md

A "Why Change" sales narrative structured using the Corporate Visions arc. Written in the configured language (`en` or `de`). All claims include numbered citations.

### Template

```markdown
---
type: sales-presentation
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

### Power Positions

[2-3 Power Positions using IS-DOES-MEANS structure from why-you-patterns.md. You-Phrasing throughout DOES layer. Mapped to buyer needs from Phase 1.]

| Position | IS | DOES (for {customer_name}) | MEANS |
|----------|-----|---------------------------|-------|
| [Name] | [Capability] | [Quantified outcome with You-Phrasing] | [Competitive moat] |

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

### Quality Criteria

Apply the quality gates from `cogni-narrative/skills/narrative/references/story-arc/corporate-visions/arc-definition.md`:
- All 4 elements present (Why Change, Why Now, Why You, Why Pay)
- PSB structure in Why Change
- 2-3 forcing functions in Why Now with specific timelines
- 2-3 Power Positions with IS-DOES-MEANS in Why You
- 3-4 cost dimensions stacked in Why Pay
- 15-25 total citations
- Buyer role tags throughout

---

## sales-proposal.md

A formal customer proposal document. More structured and action-oriented than the presentation. Includes implementation details and pricing from portfolio solutions.

### Template

```markdown
---
type: sales-proposal
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

### Quality Criteria

- Executive summary captures the arc in 2-3 paragraphs
- Customer situation shows research depth (not generic)
- Solution section uses IS/DOES/MEANS from portfolio propositions
- Implementation from actual portfolio solution entities
- Pricing from actual solution tier data
- ROI links back to Why Pay analysis
- All claims have citations
