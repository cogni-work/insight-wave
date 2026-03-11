---
title: Professional Reports
type: deliverable
category: deliverable-type
tags: [report, analysis, documentation, research, findings]
formality: high
audience: [stakeholders, executives, teams, analysts]
typical-length: variable
recommended-frameworks: [pyramid, scqa, inverted-pyramid]
recommended-principles: [clarity, readability, all-core-principles]
related:
  - briefs
  - executive-summaries
version: 2.0
last_updated: 2026-02-25
---

# Professional Reports

## Quick Reference

| Attribute | Specification |
|-----------|--------------|
| **Purpose** | Comprehensive analysis, findings, and recommendations on a specific topic |
| **Length** | Variable (2-100+ pages) |
| **Formality** | High |
| **Audience** | Stakeholders, executives, teams, analysts |
| **Best frameworks** | Pyramid (default), SCQA (for narrative), Inverted Pyramid (for news-style) |
| **Reading time** | 10-60+ minutes (body); 2-5 minutes (executive summary alone) |
| **Core requirement** | Standalone executive summary with answer-first approach |

## Decision: Choose Report Type First

Before drafting, identify which report type matches the assignment. Each type has distinct structural expectations.

| Report Type | Primary Purpose | Framework | Key Differentiator |
|-------------|----------------|-----------|-------------------|
| **Research Report** | Present findings from investigation | Pyramid | Methodology section required |
| **Status/Progress Report** | Update stakeholders on project state | Inverted Pyramid | Timeline-oriented, metrics-heavy |
| **Analytical Report** | Evaluate options or diagnose problems | Pyramid or SCQA | Comparison tables, pro/con analysis |
| **Recommendation Report** | Propose a course of action | Pyramid | Decision matrix, clear recommendation |
| **Compliance/Audit Report** | Document adherence to standards | Pyramid | Checklist structure, pass/fail criteria |

If the type is ambiguous, default to **Recommendation Report** with Pyramid framework -- it covers the widest range of business scenarios.

## Standard Structures

### Structure A: Pyramid (Research / Recommendation Report)

Use when the audience wants the answer first. This is the default for most business reports.

```markdown
# [Descriptive Report Title That States the Finding]

## Executive Summary
[Answer-first: State the main conclusion in 2-3 sentences.]
[Key findings as numbered list (3-5 items with metrics).]
[Primary recommendation in 1-2 sentences.]

## Introduction
[Scope: What this report covers and why.]
[Context: What triggered this analysis.]
[Methodology overview: How analysis was conducted (1-2 paragraphs).]

## Key Findings

### Finding 1: [Descriptive Title With Metric]
[Evidence: Data, analysis, and supporting detail.]
[Implication: What this finding means for the organization.]

### Finding 2: [Descriptive Title With Metric]
[Evidence and implication, same pattern.]

### Finding 3: [Descriptive Title With Metric]
[Evidence and implication, same pattern.]

## Analysis
[Synthesis across findings. Connect the dots.]
[Comparison table if evaluating options.]

## Recommendations
[Numbered, actionable recommendations.]
[Each recommendation: What to do, who owns it, by when, expected impact.]

## Implementation Roadmap
[Timeline, phases, resource requirements.]

## Appendices
[Raw data, detailed methodology, supplementary charts.]
```

### Structure B: SCQA (Analytical / Problem-Solving Report)

Use when the audience needs to understand the problem before accepting the solution. Effective for skeptical stakeholders or complex problems.

```markdown
# [Report Title]

## Executive Summary
[Compressed SCQA: Situation (1 sentence) -> Problem (1 sentence) ->
Recommendation (2-3 sentences) -> Expected impact (1 sentence).]

## Situation (Background)
[Current state: What exists today. Establish shared context.]

## Complication (The Problem)
[What changed or went wrong. Quantify the impact.]
[Why the status quo is unacceptable.]

## Question (The Central Issue)
[Frame the question the report answers. Can be implicit in section flow.]

## Answer (Findings and Recommendations)
[Your solution with full supporting evidence.]
[Structured using Pyramid within this section: answer -> arguments -> evidence.]

## Implementation
[How to act on the recommendations.]

## Appendices
[Supporting detail.]
```

### Structure C: Status/Progress Report

Use for recurring project updates. Optimized for quick scanning.

```markdown
# [Project Name]: Status Report - [Date/Period]

## Summary
**Overall Status:** [On Track / At Risk / Off Track]
**Key Metric:** [Primary KPI and current value]
**Action Required:** [Yes/No - what decision is needed]

## Progress This Period
| Milestone | Status | Target Date | Notes |
|-----------|--------|-------------|-------|
| [Item 1]  | Done   | [Date]      | [Note] |
| [Item 2]  | On Track | [Date]   | [Note] |
| [Item 3]  | At Risk  | [Date]   | [Blocker] |

## Risks and Blockers
1. **[Risk]:** [Description, impact, mitigation plan]
2. **[Blocker]:** [Description, owner, resolution timeline]

## Next Period Plan
- [Action item 1 - Owner - Deadline]
- [Action item 2 - Owner - Deadline]
```

## The Executive Summary: Most Critical Section

The executive summary determines whether the rest of the report gets read. It must function as a standalone document.

### Requirements

- **Length:** 1-2 pages maximum, regardless of report length
- **Structure:** Always answer-first (Pyramid)
- **Standalone test:** An executive who reads only this section can make a decision
- **Completeness:** Must contain the conclusion, key findings (with metrics), and primary recommendation

### Chain of Thought: Writing the Executive Summary

Think through these steps in order:

1. **What is the single most important conclusion?** Write it as the opening sentence.
2. **What 3-5 findings support this conclusion?** List them with specific metrics.
3. **What should the reader do?** State the recommendation with owner, timeline, and expected impact.
4. **Can someone act on this alone?** If not, add what is missing.

### Before and After

**BEFORE (buried answer, vague, no metrics):**

```markdown
## Executive Summary

This report examines the current state of our customer support operations.
We analyzed data from multiple sources including ticket volumes, response
times, and customer satisfaction surveys. The analysis covered the period
from January through June. Several interesting patterns emerged from the
data. After careful consideration, we believe some changes may be beneficial
to improve overall performance.
```

Problems: Answer buried at the end. No specific findings. No metrics. No recommendation. Hedging language ("may be beneficial"). Reader learns nothing without reading the full report.

**AFTER (answer-first, specific, actionable):**

```markdown
## Executive Summary

Customer support response times must be reduced from 11 minutes to under
4 minutes to prevent further customer churn, which has increased 23% this
quarter.

**Key Findings:**
1. **Response time is the primary churn driver.** Customers who wait >8
   minutes are 3.2x more likely to cancel within 30 days.
2. **Tier-1 tickets consume 60% of agent time** but represent only 35%
   of revenue-impacting issues.
3. **Automated routing could eliminate 40% of Tier-1 volume,** freeing
   agents for high-value interactions.

**Recommendation:** Deploy automated ticket routing by Q3 ($150K
investment) to reduce average response time to 4 minutes and recover an
estimated $2.1M in at-risk annual revenue. VP of Support to lead
implementation.
```

## Writing Effective Report Sections

### Findings Sections

Each finding should follow this internal pattern:

1. **Headline the finding** in the section header (include the metric)
2. **State the finding** in the opening sentence (no buildup)
3. **Present the evidence** (data, analysis, sources)
4. **Explain the implication** (so what? why does this matter?)

**BEFORE (generic header, buried finding):**

```markdown
### Customer Analysis

We looked at customer data over the past six months. There were several
trends. One notable observation was that certain customer segments showed
different behavior patterns. Specifically, enterprise customers tended to
have longer support interactions but also higher satisfaction. Meanwhile,
SMB customers had shorter interactions but expressed more frustration with
resolution times.
```

**AFTER (specific header, answer-first, evidence-backed):**

```markdown
### Finding 2: Enterprise Customers Score 34% Higher in Satisfaction Despite 2x Longer Interactions

Enterprise customers report a 4.6/5.0 satisfaction rating compared to
3.4/5.0 for SMB customers, despite averaging 22-minute support interactions
versus 11 minutes for SMB.

| Segment | Avg. Interaction | CSAT Score | Resolution Rate |
|---------|-----------------|------------|-----------------|
| Enterprise | 22 min | 4.6 / 5.0 | 94% |
| SMB | 11 min | 3.4 / 5.0 | 71% |

The difference stems from first-contact resolution: enterprise tickets are
routed to specialized agents who resolve 94% of issues in a single
interaction. SMB tickets pass through an average of 2.3 agents before
resolution.

**Implication:** Investing in SMB-specialized routing could close the
satisfaction gap while reducing total handle time per ticket.
```

### Recommendations Section

Each recommendation must answer five questions:

1. **What** specifically should be done?
2. **Who** owns it?
3. **When** should it be completed?
4. **How much** will it cost (time, money, resources)?
5. **What impact** is expected?

**BEFORE (vague):**

```markdown
## Recommendations

- Improve customer support processes
- Consider investing in new technology
- Look into training programs for staff
```

**AFTER (specific, actionable, measurable):**

```markdown
## Recommendations

1. **Deploy automated ticket routing** (VP Support, Q3, $150K). Expected
   impact: reduce Tier-1 response time from 11 min to 4 min, recovering
   $2.1M in at-risk revenue.

2. **Create SMB-specialized support team** (Director of CS, Q4, 3 FTE
   reallocation). Expected impact: raise SMB CSAT from 3.4 to 4.2 within
   6 months.

3. **Implement quarterly support quality audits** (QA Lead, ongoing, no
   additional budget). Expected impact: maintain >90% first-contact
   resolution after process changes.
```

## Formatting Rules for Reports

### Heading Hierarchy

- **H1 (#):** Report title only. One per document.
- **H2 (##):** Major sections (Executive Summary, Findings, Recommendations).
- **H3 (###):** Subsections within major sections (individual findings, individual recommendations).
- **Never go deeper than H3.** If you need H4, restructure the content.

### Descriptive Headers

Headers must convey meaning when scanned without reading body text.

| Level | Bad | Good |
|-------|-----|------|
| H2 | Analysis | Customer Churn Analysis: Three Root Causes |
| H3 | Finding 1 | Finding 1: Response Time Drives 60% of Churn |
| H3 | Recommendation | Recommendation: Deploy Automated Routing by Q3 |

### Visual Elements

**Target density:** 1 visual element per 2 paragraphs of body text.

| Element | When to Use | Report Sections |
|---------|-------------|-----------------|
| **Tables** | Comparing options, showing metrics, structured data | Findings, Analysis, Recommendations |
| **Callouts** | Key insights, critical warnings | Findings, Executive Summary |
| **Bullet lists** | Action items, enumerations of 3+ items | Recommendations, Next Steps |
| **Numbered lists** | Sequential steps, prioritized items | Methodology, Implementation |

**Callout syntax for key insights:**

```markdown
> **Key Insight**: Customers who wait >8 minutes are 3.2x more likely
> to cancel within 30 days.
```

### Paragraph Length

- **Executive Summary:** 3-4 sentences per paragraph
- **Body sections:** 4-5 sentences per paragraph
- **Never exceed** 7 sentences or 6-8 lines on screen
- **One idea per paragraph.** Split if covering multiple points.

## Quality Checklist

Run through this checklist before finalizing any report:

### Executive Summary
- [ ] States main conclusion in the first sentence
- [ ] Contains 3-5 key findings with specific metrics
- [ ] Includes actionable recommendation with owner and timeline
- [ ] Standalone: an executive can decide based on this section alone
- [ ] Length: 1-2 pages maximum

### Structure and Navigation
- [ ] Heading hierarchy: H1 (title) -> H2 (sections) -> H3 (subsections), nothing deeper
- [ ] All headers are descriptive (no generic "Background" or "Analysis")
- [ ] Parallel grammatical structure across same-level headers
- [ ] Findings are numbered and titled with metrics

### Content Quality
- [ ] Every finding states evidence and implication
- [ ] Every recommendation answers: what, who, when, how much, what impact
- [ ] No finding without evidence; no recommendation without a finding to support it
- [ ] Active voice throughout (< 10% passive)
- [ ] Flesch Reading Ease: 50-60 for body, 55-65 for executive summary

### Visual and Formatting
- [ ] ~1 visual element per 2 paragraphs in body sections
- [ ] Tables used for all comparisons of 3+ items
- [ ] Callouts used for genuine key insights (not routine information)
- [ ] Paragraphs: 4-5 sentences average, never exceed 7

### Logical Integrity
- [ ] Conclusions follow from evidence (no unsupported claims)
- [ ] Arguments are MECE when using Pyramid framework
- [ ] Methodology is described clearly enough to be reproduced
- [ ] All data sources are cited

## Common Mistakes and Fixes

### Mistake 1: No Real Executive Summary

The most frequent report failure. What appears as an "executive summary" is actually an introduction or table of contents in disguise.

**Symptom:** Executive summary describes what the report covers instead of what it concludes.

**Bad:** "This report examines customer support operations and presents findings from our analysis of Q1-Q2 data."

**Fix:** "Customer support response times must be reduced from 11 to 4 minutes to prevent $2.1M in annual churn."

### Mistake 2: Generic Section Headers

Generic headers force readers to read every paragraph to understand structure.

**Bad:** Introduction, Background, Analysis, Discussion, Conclusion

**Fix:** Use headers that state findings: "Response Time Drives 60% of Customer Churn"

### Mistake 3: Vague Recommendations

Recommendations that cannot be acted upon waste the entire report's effort.

**Bad:** "The company should consider improving its customer support capabilities."

**Fix:** "Deploy automated ticket routing by Q3 ($150K). Owner: VP Support. Expected impact: reduce response time from 11 min to 4 min."

### Mistake 4: Evidence-Free Conclusions

Stating conclusions without linking them to specific data undermines credibility.

**Bad:** "Our analysis shows that customer satisfaction is declining."

**Fix:** "CSAT scores dropped from 4.2 to 3.4 between Q1 and Q2 (n=2,847 responses), with the sharpest decline in the SMB segment (-31%)."

### Mistake 5: Wall-of-Text Findings

Long unbroken paragraphs in findings sections destroy scannability.

**Fix:** Apply the finding pattern: headline (in header) -> statement (opening sentence) -> evidence (data/table) -> implication (so-what callout).

### Mistake 6: Appendix as Dumping Ground

Appendices should contain material a specific reader might need, not everything that did not fit elsewhere.

**Fix:** Only include in appendices: raw data tables, detailed methodology, supplementary charts referenced in the body, and glossaries. Each appendix item should be cross-referenced from the body text.

## Framework Selection Guide

Use this decision tree to choose the right framework:

```
Does the audience already trust your methodology and want the answer fast?
  YES -> Pyramid (answer-first)
  NO  -> Does the audience need to understand the problem before accepting the solution?
    YES -> SCQA (build the case, then present the answer)
    NO  -> Is this a recurring status update?
      YES -> Status Report structure (summary + metrics table + risks)
      NO  -> Default to Pyramid
```

**Hybrid approach:** Use SCQA for the executive summary to build context, then Pyramid for the body sections. This works well for recommendation reports where the audience is mixed (some skeptical, some just want the answer).

## See Also

- **Frameworks:** `../02-messaging-frameworks/pyramid-framework.md`, `../02-messaging-frameworks/scqa-framework.md`, `../02-messaging-frameworks/inverted-pyramid-framework.md`
- **Principles:** All core principles apply, especially `../01-core-principles/clarity-principles.md` and `../01-core-principles/readability-principles.md`
- **Formatting:** `../03-formatting-standards/visual-elements.md`
- **Related deliverables:** `executive-summaries.md`, `briefs.md`
