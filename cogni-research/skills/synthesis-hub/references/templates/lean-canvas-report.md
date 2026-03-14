# Lean Canvas Research Report Template

This template provides structure for research reports when `research_type = "lean-canvas"`. Uses Lean Canvas framework for strategic business model analysis and validation.

---

## Template Metadata

**Research Type:** `lean-canvas`
**Target Length:** 2,500-3,500 words
**Minimum Citations:** 50+
**Structure:** 14 sections following Lean Canvas methodology

---

## YAML Frontmatter Structure

```yaml
---
title: "[Business/Product Name] - Lean Canvas Analysis"
research_type: lean-canvas
date_created: "[ISO 8601 timestamp]"
entity_count: [number]
confidence_avg: [0.0-1.0]
tags:
  - answer
  - synthesis-level/executive
  - lean-canvas
  - business-model
  - strategy
  - [domain-tag]
---
```

---

## Section 1: Executive Summary

**Length:** 200-300 words
**Citations:** 3-5 inline citations minimum
**Purpose:** High-level overview of the business model opportunity synthesized from research trends

### Content Requirements

- Summarize the core business opportunity in 2-3 sentences
- Highlight the key value proposition and target market
- Identify 2-3 primary competitive differentiators
- Preview critical success factors or key trends
- Set strategic context for the detailed canvas analysis

### Writing Style

- Executive-friendly language (avoid jargon)
- Forward-looking and opportunity-focused
- Data-driven with supporting citations
- Clear connection between problem and solution

### Example Structure

```markdown
## Executive Summary

[Opening sentence establishing market context]<sup>[1](11-trends/data/trend-001.md)</sup>

[2-3 sentences describing the business opportunity and target customer]<sup>[2](11-trends/data/trend-002.md), [3](05-domain-concepts/data/concept-001.md)</sup>

[Value proposition and key differentiators]<sup>[4](11-trends/data/trend-003.md)</sup>

[Critical success factors or strategic implications]<sup>[5](11-trends/data/trend-004.md)</sup>
```

---

## Section 2: Problem

**Length:** 100-150 words
**Citations:** 3+ citations minimum
**Purpose:** Define the top 3 customer problems this business addresses

### Content Requirements

- List and describe the top 3 problems in priority order
- Provide evidence from research for each problem
- Describe existing alternatives customers currently use
- Quantify problem severity when possible (market size, pain intensity)

### Format

```markdown
## Problem

### Top Customer Problems

1. **[Problem Name/Description]**<sup>[1](11-trends/data/trend-id.md)</sup>
   [2-3 sentences describing the problem, its impact, and evidence from research. Include quantitative data if available.]

2. **[Problem Name/Description]**<sup>[2](11-trends/data/trend-id-2.md)</sup>
   [2-3 sentences describing the problem, its impact, and evidence from research.]

3. **[Problem Name/Description]**<sup>[3](11-trends/data/trend-id-3.md)</sup>
   [2-3 sentences describing the problem, its impact, and evidence from research.]

### Existing Alternatives

[Describe how customers currently solve these problems - competitors, workarounds, or doing nothing. Include limitations of existing solutions.]<sup>[4](11-trends/data/trend-id-4.md)</sup>
```

---

## Section 3: Customer Segments

**Length:** 100-150 words
**Citations:** 2+ citations minimum
**Purpose:** Identify and characterize target customer groups

### Content Requirements

- Define 2-4 distinct customer segments
- Describe key characteristics, behaviors, and needs for each segment
- Identify early adopters vs. mainstream customers
- Prioritize segments by strategic importance

### Format

```markdown
## Customer Segments

### Primary Target Segments

**1. [Segment Name]** (Early Adopters)<sup>[1](11-trends/data/trend-id.md)</sup>
[Description of segment characteristics, size, behaviors, and why they're early adopters]

**2. [Segment Name]** (Mainstream)<sup>[2](11-trends/data/trend-id-2.md)</sup>
[Description of segment characteristics, size, behaviors, and strategic importance]

### Segment Prioritization

[Explain which segment to target first and why, based on accessibility, pain intensity, and strategic fit]

```

---

## Section 4: Unique Value Proposition

**Length:** 100-150 words
**Citations:** 3+ citations minimum
**Purpose:** Articulate the single, clear, compelling message that explains why the solution is different and worth buying

### Content Requirements

- State the core value proposition in one clear sentence
- Explain what makes it unique compared to alternatives
- Connect the UVP directly to customer problems
- Provide evidence from research supporting the differentiation claims

### Format

```markdown
## Unique Value Proposition

### Core Value Statement

[Single sentence capturing the unique value proposition]<sup>[1](11-trends/data/trend-id.md)</sup>

[1-2 sentences elaborating on what makes this proposition compelling and different]<sup>[2](11-trends/data/trend-id-2.md)</sup>

### Key Differentiators

- **[Differentiator 1]:** [Brief explanation with evidence]<sup>[3](11-trends/data/trend-id-3.md)</sup>
- **[Differentiator 2]:** [Brief explanation with evidence]<sup>[4](05-domain-concepts/data/concept-id.md)</sup>
- **[Differentiator 3]:** [Brief explanation with evidence]<sup>[5](11-trends/data/trend-id-4.md)</sup>

### Value vs. Alternatives

[Comparison table or narrative showing how this value proposition compares to existing alternatives]
```

---

## Section 5: Solution

**Length:** 100-150 words
**Citations:** 3+ citations minimum
**Purpose:** Outline the top 3 features that directly address the identified problems

### Content Requirements

- List 3 core features mapped to the top 3 problems
- Explain how each feature solves its corresponding problem
- Focus on features, not technology implementation details
- Include evidence that these features resonate with customers

### Format

```markdown
## Solution

### Core Features

**1. [Feature Name]** (Addresses Problem 1)<sup>[1](11-trends/data/trend-id.md)</sup>
[Description of feature and how it solves Problem 1]

**2. [Feature Name]** (Addresses Problem 2)<sup>[2](11-trends/data/trend-id-2.md)</sup>
[Description of feature and how it solves Problem 2]

**3. [Feature Name]** (Addresses Problem 3)<sup>[3](11-trends/data/trend-id-3.md)</sup>
[Description of feature and how it solves Problem 3]

### Solution Validation

[Evidence from research that these features address customer needs effectively]<sup>[4](11-trends/data/trend-id-4.md)</sup>
```

---

## Section 6: Channels

**Length:** 75-100 words
**Citations:** 2+ citations minimum
**Purpose:** Define the path to customers across acquisition, delivery, and support

### Content Requirements

- Identify customer acquisition channels (how to reach them)
- Describe delivery channels (how customers receive value)
- Outline support and retention channels
- Prioritize channels by cost-effectiveness and reach

### Format

```markdown
## Channels

### Customer Acquisition

[Primary channels for reaching and acquiring customers]<sup>[1](11-trends/data/trend-id.md)</sup>

**Priority Channels:**
- [Channel 1]: [Why effective for target segment]
- [Channel 2]: [Why effective for target segment]

### Delivery & Support

[How value is delivered to customers and how support is provided]<sup>[2](11-trends/data/trend-id-2.md)</sup>

### Channel Strategy

[Explanation of channel mix and prioritization based on customer behavior and economics]
```

---

## Section 7: Revenue Streams

**Length:** 75-100 words
**Citations:** 2+ citations minimum
**Purpose:** Define revenue model and pricing strategy

### Content Requirements

- Identify primary revenue streams (subscription, transaction, licensing, etc.)
- Describe pricing strategy and justification
- Include revenue potential estimates if available
- Compare to competitor pricing models

### Format

```markdown
## Revenue Streams

### Primary Revenue Model

[Description of core revenue model]<sup>[1](11-trends/data/trend-id.md)</sup>

**Revenue Structure:**
- [Revenue stream 1]: [Pricing and volume assumptions]
- [Revenue stream 2]: [Pricing and volume assumptions]

### Pricing Strategy

[Pricing approach, positioning, and rationale]<sup>[2](11-trends/data/trend-id-2.md)</sup>

### Revenue Validation

[Evidence from research supporting pricing assumptions and willingness to pay]
```

---

## Section 8: Cost Structure

**Length:** 75-100 words
**Citations:** 2+ citations minimum
**Purpose:** Outline fixed and variable costs required to operate the business

### Content Requirements

- Identify major fixed costs (infrastructure, salaries, facilities)
- Identify major variable costs (per-customer costs, COGS)
- Highlight cost drivers and optimization opportunities
- Compare cost structure to competitors if available

### Format

```markdown
## Cost Structure

### Fixed Costs

[Major fixed cost categories and estimates]<sup>[1](11-trends/data/trend-id.md)</sup>

- [Cost category 1]: [Description and magnitude]
- [Cost category 2]: [Description and magnitude]

### Variable Costs

[Major variable cost categories and per-unit economics]<sup>[2](11-trends/data/trend-id-2.md)</sup>

- [Cost category 1]: [Description and per-unit cost]
- [Cost category 2]: [Description and per-unit cost]

### Cost Optimization

[Opportunities to reduce costs or improve unit economics]
```

---

## Section 9: Key Metrics

**Length:** 75-100 words
**Citations:** 2+ citations minimum
**Purpose:** Define success indicators and KPIs that measure business progress

### Content Requirements

- Identify 3-5 key metrics that indicate business health
- Focus on actionable metrics (not vanity metrics)
- Include both leading and lagging indicators
- Provide benchmark targets when possible

### Format

```markdown
## Key Metrics

### Critical Success Metrics

**1. [Metric Name]**<sup>[1](11-trends/data/trend-id.md)</sup>
[Description, measurement method, and target/benchmark]

**2. [Metric Name]**<sup>[2](11-trends/data/trend-id-2.md)</sup>
[Description, measurement method, and target/benchmark]

**3. [Metric Name]**
[Description, measurement method, and target/benchmark]

### Measurement Strategy

[How these metrics will be tracked and reported, cadence for review]

### Metric Validation

[Evidence from research or industry benchmarks supporting metric selection]
```

---

## Section 10: Unfair Advantage

**Length:** 75-100 words
**Citations:** 2+ citations minimum
**Purpose:** Identify competitive moats that cannot be easily copied or bought

### Content Requirements

- Define sustainable competitive advantages
- Focus on genuine barriers to entry (not just features)
- Include network effects, proprietary technology, exclusive access, or unique trends
- Be honest if no clear unfair advantage exists yet

### Format

```markdown
## Unfair Advantage

### Sustainable Competitive Moat

[Description of the primary unfair advantage]<sup>[1](11-trends/data/trend-id.md)</sup>

**Advantage Categories:**
- **[Category 1]:** [Specific advantage that's hard to replicate]<sup>[2](11-trends/data/trend-id-2.md)</sup>
- **[Category 2]:** [Specific advantage that's hard to replicate]

### Defensibility Analysis

[Assessment of how sustainable this advantage is over time and what could erode it]

### Building the Moat

[If no strong unfair advantage exists yet, outline strategy to develop one]
```

---

## Section 11: Strategic Recommendations

**Length:** 150-200 words
**Citations:** 5+ citations
**Purpose:** Provide actionable next steps based on canvas analysis

### Content Requirements

- 5-8 prioritized recommendations
- Each recommendation should be specific and actionable
- Connect recommendations to canvas trends
- Include validation experiments or tests to reduce risk
- Prioritize by impact and feasibility

### Format

```markdown
## Strategic Recommendations

### Priority Actions

**1. [Recommendation Title]** (High Priority)<sup>[1](11-trends/data/trend-id.md)</sup>
[Specific action, rationale, and expected outcome]

**2. [Recommendation Title]** (High Priority)<sup>[2](11-trends/data/trend-id-2.md)</sup>
[Specific action, rationale, and expected outcome]

**3. [Recommendation Title]** (Medium Priority)<sup>[3](11-trends/data/trend-id-3.md)</sup>
[Specific action, rationale, and expected outcome]

**4. [Recommendation Title]** (Medium Priority)
[Specific action, rationale, and expected outcome]

**5. [Recommendation Title]** (Low Priority)
[Specific action, rationale, and expected outcome]

### Validation Experiments

[Propose 2-3 low-cost experiments to test critical assumptions in the canvas]<sup>[4](11-trends/data/trend-id-4.md)</sup>

### Risk Mitigation

[Identify 2-3 key risks and mitigation strategies]<sup>[5](11-trends/data/trend-id-5.md)</sup>
```

---

## Section 12: Confidence Assessment

**Length:** 100-150 words
**Citations:** 2+ citations for methodology
**Purpose:** Transparently communicate research quality and limitations

### Content Requirements

- Overall confidence score (0.0-1.0) with explanation
- Breakdown by canvas section if confidence varies
- Identify gaps in research or missing data
- Suggest areas requiring additional validation
- Acknowledge limitations and biases

### Format

```markdown
## Confidence Assessment

### Overall Research Confidence

**Aggregate Confidence Score:** [0.0-1.0]

[Explanation of overall confidence level and factors affecting it]<sup>[1](11-trends/data/trend-id.md)</sup>

### Confidence by Section

| Canvas Section | Confidence | Notes |
|---------------|-----------|-------|
| Problem | [0.0-1.0] | [Brief explanation] |
| Customer Segments | [0.0-1.0] | [Brief explanation] |
| UVP | [0.0-1.0] | [Brief explanation] |
| Solution | [0.0-1.0] | [Brief explanation] |
| Channels | [0.0-1.0] | [Brief explanation] |
| Revenue | [0.0-1.0] | [Brief explanation] |
| Costs | [0.0-1.0] | [Brief explanation] |
| Metrics | [0.0-1.0] | [Brief explanation] |
| Unfair Advantage | [0.0-1.0] | [Brief explanation] |

### Research Gaps

[Identify 3-5 areas where additional research would improve confidence]

### Limitations

[Acknowledge methodology limitations, potential biases, or data quality issues]<sup>[2](11-trends/data/trend-id-2.md)</sup>
```

---

## Section 13: Domain Concepts Glossary

**Length:** 50-100 words
**Purpose:** Define key terminology and concepts referenced in the report

### Format

```markdown
## Domain Concepts Glossary

**[Term 1]:** [Clear definition in 1-2 sentences]<sup>[1](05-domain-concepts/data/concept-id.md)</sup>

**[Term 2]:** [Clear definition in 1-2 sentences]<sup>[2](05-domain-concepts/data/concept-id-2.md)</sup>

**[Term 3]:** [Clear definition in 1-2 sentences]<sup>[3](05-domain-concepts/data/concept-id-3.md)</sup>

[Continue for 8-12 key domain concepts]
```

---

## Section 14: Appendix - Research Scope

**Length:** 100-150 words
**Purpose:** Document methodology and data sources for transparency

### Format

```markdown
## Appendix: Research Scope

### Research Methodology

[Brief description of research approach and methods used]

**Research Parameters:**
- **Entities Analyzed:** [number]
- **Trends Generated:** [number]
- **Domain Concepts Identified:** [number]
- **Research Duration:** [timeframe]

### Data Sources

[List primary categories of data sources used]

- [Source type 1]: [Description]
- [Source type 2]: [Description]
- [Source type 3]: [Description]

### Analytical Framework

[Description of how the Lean Canvas framework was applied to synthesize trends]

### Report Generation

**Template Version:** lean-canvas-report v1.0
**Generated:** [ISO 8601 timestamp]
**Last Updated:** [ISO 8601 timestamp]
```

---

## Citation Density Requirements

### Minimum Citations by Section

| Section | Minimum Citations | Recommended |
|---------|------------------|-------------|
| Executive Summary | 3-5 | 4-6 |
| Problem | 3+ | 4-5 |
| Customer Segments | 2+ | 3-4 |
| Unique Value Proposition | 3+ | 4-5 |
| Solution | 3+ | 4-5 |
| Channels | 2+ | 3-4 |
| Revenue Streams | 2+ | 3-4 |
| Cost Structure | 2+ | 3-4 |
| Key Metrics | 2+ | 3-4 |
| Unfair Advantage | 2+ | 3-4 |
| Strategic Recommendations | 5+ | 6-8 |
| Confidence Assessment | 2+ | 2-3 |
| Domain Concepts | 8-12 | 10-15 |
| **TOTAL** | **50+** | **60-75** |

### Citation Best Practices

- **Trend citations** (`11-trends/data/*.md`): Use for evidence, data points, and specific findings
- **Concept citations** (`05-domain-concepts/data/*.md`): Use for definitions and technical explanations
- **Inline format:** `<sup>[1](11-trends/data/trend-id.md)</sup>`
- **Multiple citations:** `<sup>[1](11-trends/data/trend-001.md), [2](11-trends/data/trend-002.md)</sup>`
- **Citation clustering:** Place citations at the end of sentences or key phrases
- **Link validation:** Ensure all citations link to existing files in the workspace

---

## Quality Checklist

Before finalizing the report, verify:

- [ ] YAML frontmatter includes all required fields
- [ ] All 14 sections are present and complete
- [ ] Word count is 2,500-3,500 words
- [ ] Minimum 50 citations distributed across sections
- [ ] All citations link to valid trend or concept files
- [ ] Customer segments are clearly defined and prioritized
- [ ] UVP is articulated in one clear sentence
- [ ] Solution features map directly to problems
- [ ] Revenue and cost structures are realistic
- [ ] Strategic recommendations are actionable and prioritized
- [ ] Confidence assessment is transparent about limitations
- [ ] Domain concepts glossary defines 8-12 key terms
- [ ] Professional tone throughout (executive-friendly)
- [ ] Canvas sections are internally consistent and connected

---

## Template Version History

**Version:** 1.0
**Created:** 2025-12-03
**Last Updated:** 2025-12-03
**Status:** Active

### Changelog

- **v1.0 (2025-12-03):** Initial template creation
  - Established 14-section structure following Lean Canvas framework
  - Defined citation density requirements (50+ minimum)
  - Created comprehensive section-by-section guidance
  - Added quality checklist and validation criteria

---

## Template Usage Notes

This template is designed for the `synthesis-hub` skill within the `deeper-research` plugin. When `research_type = "lean-canvas"`, the skill should:

1. Load this template as the structural foundation
2. Map research trends to appropriate canvas sections
3. Generate section content with required citation density
4. Ensure cross-section consistency and flow
5. Validate against quality checklist before output

The Lean Canvas framework is optimized for:
- Early-stage startups and new product ideas
- Business model validation and iteration
- Strategic planning for new market entry
- Product-market fit analysis
- Communicating business models to stakeholders

For other research types, use appropriate templates:
- Market analysis → `market-analysis-report.md`
- Technology assessment → `technology-assessment-report.md`
- Competitive intelligence → `competitive-analysis-report.md`
