# Customer Value Mapping Research Report Template

This template provides structure for research reports when `research_type = "customer-value-mapping"`. Uses Corporate Visions Value Story methodology to synthesize customer needs with TIPS trends and portfolio solutions for sales enablement.

---

## Template Metadata

**Research Type:** `customer-value-mapping`
**Target Length:** 2,000-3,000 words
**Minimum Citations:** 28+ (distributed across 4 dimensions)
**Structure:** 8 sections following Value Story methodology
**Output Consumer:** value-story-creator skill (13-17 slide PPTX)

---

## YAML Frontmatter Structure

```yaml
---
title: "{Customer Name} Value Story Research"
research_type: customer-value-mapping
customer_name: "{Customer Name}"
customer_industry: "{Industry}"
source_smarter_service: "{path to TIPS source project}"
source_portfolio: "{path to portfolio source project}"
date_created: "{ISO 8601 timestamp}"
dimensions:
  - why-change
  - why-now
  - why-you
  - why-pay
entity_count: {number, minimum 10}
confidence_avg: {0.0-1.0}
slide_coverage: "13-17 slides"
tags:
  - answer
  - synthesis-level/executive
  - customer-value-mapping
  - value-story
  - sales-enablement
  - {customer-slug}
---
```

---

## Section 1: Executive Summary

**Length:** 200-300 words
**Citations:** 3-5 inline citations minimum
**Purpose:** Customer-focused overview of the value proposition and key findings

### Content Requirements

- Open with the customer's strategic context (1-2 sentences)
- Summarize the unconsidered needs discovered (Why Change)
- Highlight timing urgency factors (Why Now)
- Preview differentiation and economic justification
- Set expectations for the Value Story presentation

### Writing Style

- Customer-centric language (use {CUSTOMER_NAME} throughout)
- Executive-friendly, avoid technical jargon
- Data-driven with supporting citations
- Forward-looking and opportunity-focused

### Example Structure

```markdown
## Executive Summary

{CUSTOMER_NAME} operates in a rapidly evolving {CUSTOMER_INDUSTRY} landscape where [strategic context]<sup>[1](11-trends/data/need-mapping-001.md)</sup>.

Our research identified [N] unconsidered needs that create compelling reasons for {CUSTOMER_NAME} to act now<sup>[2](11-trends/data/need-mapping-002.md)</sup>. Key timing pressures include [urgency factors]<sup>[3](11-trends/data/need-mapping-003.md)</sup>.

[Solution provider]'s portfolio offers differentiated capabilities that directly address these needs<sup>[4](11-trends/data/need-mapping-004.md)</sup>, with projected [ROI/value metrics]<sup>[5](11-trends/data/need-mapping-005.md)</sup>.

This research provides the foundation for a {X}-slide Value Story presentation targeting {CUSTOMER_NAME}'s decision-makers.
```

---

## Section 2: Why Change - Disrupt Status Quo

**Length:** 400-600 words
**Citations:** 8-12 inline citations
**Slide Coverage:** Slides 2-5
**Minimum Entities:** 3

### Purpose

Expose unconsidered needs, hidden risks, and industry forces that should compel {CUSTOMER_NAME} to change from their current state.

### Content Requirements

- Present 3+ unconsidered needs with evidence
- Connect each need to industry TIPS trends
- Include quantified impact where available
- Reference customer-specific context

### Subsection Structure

```markdown
## Why Change: Disrupt Status Quo

### Strategic Overview

[2-3 paragraphs introducing the change imperative for {CUSTOMER_NAME}, grounded in industry context and customer-specific factors]<sup>[citations]</sup>

### Unconsidered Needs

#### Need 1: {Need Title}

{CUSTOMER_NAME} faces [need description] due to [industry force]<sup>[T1]({tips-path})</sup>.

**Impact:** [Quantified business impact]<sup>[1](11-trends/data/need-mapping-xxx.md)</sup>

**Evidence:** [Supporting data point]

#### Need 2: {Need Title}

[Same structure]<sup>[T2]({tips-path}), [2](11-trends/data/need-mapping-xxx.md)</sup>

#### Need 3: {Need Title}

[Same structure]<sup>[T3]({tips-path}), [3](11-trends/data/need-mapping-xxx.md)</sup>

### Need Mappings Summary

| Need | TIPS Source | Impact | Slide |
|------|-------------|--------|-------|
| {Need 1} | [[{tips-path}]] | {metric} | 2 |
| {Need 2} | [[{tips-path}]] | {metric} | 3 |
| {Need 3} | [[{tips-path}]] | {metric} | 4 |
```

---

## Section 3: Why Now - Create Timing Urgency

**Length:** 300-500 words
**Citations:** 6-10 inline citations
**Slide Coverage:** Slides 6-9
**Minimum Entities:** 2

### Purpose

Quantify the cost of delay and identify forcing functions that make immediate action critical for {CUSTOMER_NAME}.

### Content Requirements

- Present 2+ urgency factors with deadlines/windows
- Quantify cost of inaction
- Identify competitive or regulatory triggers
- Include customer-specific timing context

### Subsection Structure

```markdown
## Why Now: Create Timing Urgency

### Strategic Overview

[1-2 paragraphs establishing the urgency context for {CUSTOMER_NAME}]<sup>[citations]</sup>

### Urgency Factors

#### Factor 1: {Urgency Title}

{CUSTOMER_NAME} faces a critical window for [action] due to [timing pressure]<sup>[T1]({tips-path})</sup>.

**Deadline/Window:** [Specific date or timeframe]
**Cost of Delay:** [Quantified impact per month/quarter]<sup>[1](11-trends/data/need-mapping-xxx.md)</sup>

#### Factor 2: {Urgency Title}

[Same structure]<sup>[T2]({tips-path}), [2](11-trends/data/need-mapping-xxx.md)</sup>

### Timing Summary

| Factor | Deadline | Cost of Delay | Slide |
|--------|----------|---------------|-------|
| {Factor 1} | {date} | {cost/month} | 6 |
| {Factor 2} | {date} | {cost/month} | 7 |
```

---

## Section 4: Why You - Differentiate Solution

**Length:** 400-600 words
**Citations:** 8-12 inline citations
**Slide Coverage:** Slides 10-13
**Minimum Entities:** 3

### Purpose

Connect {CUSTOMER_NAME}'s unconsidered needs to unique portfolio capabilities that differentiate from alternatives.

### Content Requirements

- Present 3+ capability mappings with portfolio linkage
- Show explicit need-to-solution connections
- Differentiate from alternatives or competitors
- Include proof points where available

### Subsection Structure

```markdown
## Why You: Differentiate Solution

### Strategic Overview

[2-3 paragraphs connecting {CUSTOMER_NAME}'s needs to [Solution Provider]'s unique approach]<sup>[citations]</sup>

### Capability Mappings

#### Mapping 1: {Capability Title}

{CUSTOMER_NAME}'s need for [capability] is uniquely addressed by [{Portfolio Solution}]<sup>[P1]({portfolio-path})</sup>.

**Differentiation:** [How this differs from alternatives]<sup>[T1]({tips-path})</sup>
**Proof Point:** [Evidence of success]<sup>[1](11-trends/data/need-mapping-xxx.md)</sup>

#### Mapping 2: {Capability Title}

[Same structure]<sup>[P2]({portfolio-path}), [T2]({tips-path}), [2](11-trends/data/need-mapping-xxx.md)</sup>

#### Mapping 3: {Capability Title}

[Same structure]<sup>[P3]({portfolio-path}), [T3]({tips-path}), [3](11-trends/data/need-mapping-xxx.md)</sup>

### Capability Summary

| Need | Portfolio Solution | Differentiation | Slide |
|------|-------------------|-----------------|-------|
| {Need 1} | [[{portfolio-path}]] | {differentiator} | 10 |
| {Need 2} | [[{portfolio-path}]] | {differentiator} | 11 |
| {Need 3} | [[{portfolio-path}]] | {differentiator} | 12 |
```

---

## Section 5: Why Pay - Justify Economics

**Length:** 300-500 words
**Citations:** 6-10 inline citations
**Slide Coverage:** Slides 14-16
**Minimum Entities:** 2

### Purpose

Prove ROI, quantify value exchange, and justify the investment for {CUSTOMER_NAME}'s budget holders.

### Content Requirements

- Present 2+ economic justifications with quantified ROI
- Include TCO comparison where applicable
- Show payback timeline
- Reference portfolio pricing models

### Subsection Structure

```markdown
## Why Pay: Justify Economics

### Strategic Overview

[1-2 paragraphs framing the investment proposition for {CUSTOMER_NAME}]<sup>[citations]</sup>

### Economic Justifications

#### Justification 1: {ROI Title}

Investment in [{Portfolio Solution}]<sup>[P1]({portfolio-path})</sup> delivers [ROI metric] for {CUSTOMER_NAME}.

**ROI Calculation:** [X% return over Y period]<sup>[T1]({tips-path})</sup>
**Payback Timeline:** [X months]<sup>[1](11-trends/data/need-mapping-xxx.md)</sup>

#### Justification 2: {ROI Title}

[Same structure]<sup>[P2]({portfolio-path}), [T2]({tips-path}), [2](11-trends/data/need-mapping-xxx.md)</sup>

### Value Summary

| Investment | ROI | Payback | Slide |
|------------|-----|---------|-------|
| {Solution 1} | {X%} | {X months} | 14 |
| {Solution 2} | {X%} | {X months} | 15 |
```

---

## Section 6: Research Mapping (for value-story-creator)

**Purpose:** Structured finding references organized by Value Story stage for value-story-creator consumption

### Format

```markdown
## Research Mapping

### Why Change Findings
| ID | Finding | Trend Reference | TIPS Source |
|----|---------|-------------------|-------------|
| WC-1 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{tips-path}]] |
| WC-2 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{tips-path}]] |
| WC-3 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{tips-path}]] |

### Why Now Findings
| ID | Finding | Trend Reference | TIPS Source |
|----|---------|-------------------|-------------|
| WN-1 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{tips-path}]] |
| WN-2 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{tips-path}]] |

### Why You Findings
| ID | Finding | Trend Reference | Portfolio Source |
|----|---------|-------------------|------------------|
| WY-1 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{portfolio-path}]] |
| WY-2 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{portfolio-path}]] |
| WY-3 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{portfolio-path}]] |

### Why Pay Findings
| ID | Finding | Trend Reference | Portfolio Source |
|----|---------|-------------------|------------------|
| WP-1 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{portfolio-path}]] |
| WP-2 | {finding summary} | [[11-trends/data/need-mapping-xxx.md]] | [[{portfolio-path}]] |
```

---

## Section 7: Strategic Recommendations

**Length:** 150-250 words
**Purpose:** Actionable next steps for the Value Story presentation

### Content Requirements

- 3-5 prioritized recommendations
- Clear call-to-action for each
- Stakeholder mapping for presentation delivery

### Format

```markdown
## Strategic Recommendations

Based on this research, we recommend the following approach for engaging {CUSTOMER_NAME}:

1. **Primary Recommendation**
   - Action: [specific action]
   - Target stakeholder: [role/name]
   - Timeline: [when]

2. **Secondary Recommendation**
   - Action: [specific action]
   - Target stakeholder: [role/name]
   - Timeline: [when]

3. **Supporting Recommendation**
   - Action: [specific action]
   - Target stakeholder: [role/name]
   - Timeline: [when]

### Presentation Delivery

| Stakeholder | Value Story Focus | Key Message |
|-------------|-------------------|-------------|
| {CIO/CTO} | Why Change + Why You | {message} |
| {CFO} | Why Now + Why Pay | {message} |
| {Business Lead} | Why You | {message} |
```

---

## Section 8: References

**Purpose:** Complete citation list for traceability

### Format

```markdown
## References

### Customer Need Mappings
1. [Need Mapping: {Title}](11-trends/data/need-mapping-xxx.md) - {dimension}
2. [Need Mapping: {Title}](11-trends/data/need-mapping-xxx.md) - {dimension}
[... continue for all entities]

### TIPS Sources (from {source-project})
T1. [{TIPS Title}]({source-smarter-service-path}/11-trends/data/trend-xxx.md) - {dimension}, {horizon}
T2. [{TIPS Title}]({source-smarter-service-path}/11-trends/data/trend-xxx.md) - {dimension}, {horizon}
[... continue for all TIPS]

### Portfolio Sources (from {portfolio-project})
P1. [{Portfolio Name}]({source-portfolio-path}/11-trends/data/portfolio-xxx.md) - {portfolio_type}
P2. [{Portfolio Name}]({source-portfolio-path}/11-trends/data/portfolio-xxx.md) - {portfolio_type}
[... continue for all portfolio]

### Customer Findings
1. [{Finding Title}](04-findings/data/finding-xxx.md)
2. [{Finding Title}](04-findings/data/finding-xxx.md)
[... continue for all findings]
```

---

## Quality Checklist

Before finalizing the report, verify:

### Content Coverage

- [ ] Executive Summary: 200-300 words with 3-5 citations
- [ ] Why Change: 400-600 words with 8-12 citations, 3+ need mappings
- [ ] Why Now: 300-500 words with 6-10 citations, 2+ urgency factors
- [ ] Why You: 400-600 words with 8-12 citations, 3+ capability mappings
- [ ] Why Pay: 300-500 words with 6-10 citations, 2+ economic justifications
- [ ] Research Mapping: All findings organized by stage
- [ ] Recommendations: 3-5 actionable items

### Citation Requirements

- [ ] Total citations: 28+ minimum
- [ ] All need-mapping entities cited
- [ ] All TIPS sources cited with cross-project paths
- [ ] All portfolio sources cited for Why You/Why Pay
- [ ] References section complete and accurate

### Customer Context

- [ ] {CUSTOMER_NAME} appears in all sections
- [ ] Customer-specific facts integrated
- [ ] Industry context maintained

### Slide Coverage

- [ ] Each section maps to slide ranges
- [ ] Summary tables indicate slide assignments
- [ ] Total coverage: 13-17 slides

---

## Version History

- **v1.0 (Sprint 440):** Initial template for customer-value-mapping research type
