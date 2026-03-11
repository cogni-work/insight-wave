---
title: Readability and Scannability Principles
type: writing-principle
category: core-principles
tags: [readability, scannability, visual-hierarchy, formatting]
audience: [all]
related:
  - clarity-principles
  - plain-language-principles
  - visual-elements
  - heading-hierarchy
version: 2.0
last_updated: 2026-02-25
---

# Readability and Scannability Principles

## Quick Reference
**Use when:** All deliverable types
**Core principle:** Enable fast comprehension through visual structure
**Key techniques:** Headers, white space, bullets, emphasis, short paragraphs
**Standard:** A reader can grasp the main points in 30 seconds of scanning

## Purpose

This reference teaches you how to structure and format business documents so readers absorb information quickly and accurately. Business readers scan before they read. If they cannot determine relevance within seconds, they move on.

Your job is to make every document pass two tests:
1. **The scan test:** Can a reader extract the main message and structure in 30 seconds without reading full sentences?
2. **The read test:** When the reader commits to reading, does each section deliver its point immediately and clearly?

Apply every principle below during document creation and during polish/revision passes.

## Decision Logic

When formatting any document, follow this sequence:

```
Step 1: Identify the single main message
Step 2: Place it at the very top (BLUF)
Step 3: Break remaining content into logical sections
Step 4: Write descriptive headers for each section
Step 5: Within each section, front-load the key point
Step 6: Convert any sequence of 3+ related items into a list
Step 7: Convert any comparison or structured data into a table
Step 8: Apply emphasis sparingly to critical terms only
Step 9: Verify white space separates every distinct idea
Step 10: Run the 30-second scan test
```

## Principles

### 1. Front-Load Important Information

Put the most important content at the beginning of every level: document, section, paragraph, and sentence.

**The reasoning:** Readers who stop early (and most do) should still walk away with the core message. This applies recursively at every structural level.

**At the document level** -- state the conclusion or recommendation first, then provide supporting analysis:

<example>
<input>
Our team analyzed three approaches to reducing customer churn. We examined historical data from the past 18 months, interviewed 45 account managers, and benchmarked against industry standards. After weighing cost, timeline, and expected impact, we recommend investing in proactive outreach.
</input>
<output>
We recommend investing in proactive outreach to reduce customer churn.

This recommendation is based on 18 months of historical data, interviews with 45 account managers, and industry benchmarking. Proactive outreach scores highest on cost efficiency, implementation speed, and projected impact.
</output>
<reasoning>The original buries the recommendation at the end. The revision leads with it, so a reader who only sees the first line still gets the key message.</reasoning>
</example>

**At the sentence level** -- place the subject and verb early, before qualifiers:

<example>
<input>After careful consideration of all available options and extensive stakeholder consultation over the past quarter, we decided to proceed with Option B.</input>
<output>We chose Option B after evaluating all options and consulting stakeholders last quarter.</output>
<reasoning>The subject ("we") and action ("chose") now appear in the first three words instead of at position 18.</reasoning>
</example>

**At the header level** -- lead with the keyword or finding, not filler:

| Weak header | Strong header |
|---|---|
| Analysis of Customer Satisfaction Decline | Customer Satisfaction Declined 15% |
| Considerations Regarding Policy Changes | Policy Changes: Three Key Considerations |
| An Overview of Our Marketing Strategy | Marketing Strategy: Content-Led Growth |

### 2. Create Clear Visual Hierarchy

Use a consistent heading structure so readers can navigate by headers alone.

**Rules:**
- **H1 (#):** Document title only. One per document.
- **H2 (##):** Major sections. These are the primary navigation landmarks.
- **H3 (###):** Subsections within a major section.
- **Never go deeper than H3.** If you need H4, restructure instead. Deep nesting signals disorganized thinking.

**Make headers informative, not generic.** A reader who only reads your headers should understand the document's argument.

<example>
<input>
## Introduction
## Background
## Analysis
## Recommendations
## Conclusion
</input>
<output>
## Recommendation: Migrate to Cloud Infrastructure by Q3
## Current On-Premise Costs Are Unsustainable
## Cloud Migration Saves 40% and Improves Uptime
## Three-Phase Migration Plan
## Next Steps: Approve Budget by March 15
</output>
<reasoning>The generic headers tell the reader nothing. The descriptive headers communicate the full argument even if the reader never opens a single section.</reasoning>
</example>

**Parallel structure for sibling headers.** Headers at the same level should use the same grammatical form:

All questions:
- How Did Costs Increase?
- Why Are Customers Leaving?
- What Should We Do Next?

All noun phrases:
- Cost Driver Analysis
- Customer Churn Patterns
- Recommended Actions

All imperative/action:
- Reduce Infrastructure Costs
- Improve Customer Retention
- Expand Into New Markets

### 3. Keep Paragraphs Short and Focused

Each paragraph should make exactly one point. If you find yourself making two points, split into two paragraphs.

**Targets:**
- 3-5 sentences per paragraph (optimal)
- 40-70 words per paragraph (optimal)
- Never exceed 7 sentences or 6-8 lines on screen

<example>
<input>
The quarterly review revealed several concerning trends. Customer satisfaction dropped by 15% compared to Q2, largely driven by longer response times in the support department. Additionally, we noticed a 23% increase in ticket volume, which our current staffing levels cannot sustain. Meanwhile, our competitor launched a self-service portal that has drawn positive reviews, and our own product team has been unable to prioritize a similar feature due to the ongoing platform migration. The finance team also flagged that support costs per ticket have risen from $8 to $15, which puts us over budget for Q4. The board has asked for a remediation plan by end of month.
</input>
<output>
Customer satisfaction dropped 15% in Q3, driven by longer support response times and a 23% increase in ticket volume that our current staffing cannot handle.

The competitive landscape has shifted. Our main competitor launched a self-service portal to strong reviews. Our product team cannot prioritize a similar feature until the platform migration completes.

Support costs have risen from $8 to $15 per ticket, putting us over budget for Q4. The board has asked for a remediation plan by end of month.
</output>
<reasoning>The original packs six distinct points into one dense paragraph. The revision separates them into three focused paragraphs: (1) the core problem, (2) the competitive context, (3) the financial urgency and deadline. Each paragraph has one job.</reasoning>
</example>

### 4. Use Lists for Scannable Groups

Convert any group of 3 or more parallel items from prose into a list. Lists are faster to scan, easier to reference, and harder to misread.

**Use bullet lists** for items of equal importance with no inherent order.
**Use numbered lists** for sequential steps, ranked items, or anything where order matters.

**Formatting rules:**
- Keep 3-7 items per list. Fewer than 3 does not justify a list. More than 7 should be grouped into sub-categories.
- Use parallel grammatical structure across all items.
- Introduce every list with a complete sentence ending in a colon.

<example>
<input>
The project achieved several outcomes. We reduced costs by 30%, and we also improved response time so it's now under 2 hours. Customer satisfaction increased to 4.5 stars as well.
</input>
<output>
The project achieved three measurable outcomes:

- Reduced costs by 30%
- Improved response time to under 2 hours
- Increased customer satisfaction to 4.5 stars
</output>
<reasoning>Parallel items buried in prose become instantly scannable as a list. All items use the same verb-first structure.</reasoning>
</example>

**Parallel structure matters.** Every item in a list must use the same grammatical form:

| Not parallel | Parallel |
|---|---|
| Reduce costs by 30% | Reduce costs by 30% |
| Response times should improve | Improve response time to 2 hours |
| Our goal is higher customer satisfaction | Increase customer satisfaction to 4.5 stars |

### 5. Use Tables for Comparisons and Structured Data

When content involves comparison, metrics, or multi-attribute data, always use a table instead of prose or nested lists.

**Use a table when:**
- Comparing 2+ options across shared criteria
- Presenting metrics over time periods
- Showing before/after states
- Displaying any data with rows and columns of related values

**Table formatting rules:**
- Left-align text columns, right-align number columns
- Use clear, concise column headers
- Limit to 5-7 columns; split wider data into multiple tables
- Add a caption or introductory sentence above the table

<example>
<input>
Currently our response time is 11 minutes and we want to get it down to 4 minutes, which would be a 64% improvement. Our CSAT score is 3.8 and our target is 4.5, an 18% improvement. Cost per ticket is $15 now and we want to bring it to $8, which is a 47% reduction.
</input>
<output>
The improvement plan targets three metrics:

| Metric | Current | Target | Change |
|---|---:|---:|---:|
| Response time | 11 min | 4 min | -64% |
| CSAT score | 3.8 | 4.5 | +18% |
| Cost per ticket | $15 | $8 | -47% |
</output>
<reasoning>Three parallel data points with shared attributes (current, target, change) are far easier to compare and reference in a table than buried in a paragraph.</reasoning>
</example>

### 6. Apply Emphasis Sparingly and Consistently

Bold text guides the reader's eye. When everything is bold, nothing is.

**Use bold for:**
- Key terms on first mention
- Critical numbers, dates, or deadlines
- The single most important phrase in a section

**Use italics for:**
- Publication titles
- Foreign phrases
- Subtle emphasis where bold would be too strong

**Never use:**
- Underline (readers confuse it with hyperlinks)
- ALL CAPS for emphasis (reserve for acronyms like API, ROI, and standard memo headers like TO:, FROM:)
- Bold on more than 10-15% of text in any section

<example>
<input>The **critical** **deadline** is **Friday** and we **must** **complete** all **tasks** before the **end of business**.</input>
<output>The critical deadline is **Friday, November 15**. All tasks must be complete by end of business.</output>
<reasoning>The original bolds seven words, diluting all emphasis. The revision bolds only the specific date -- the one piece of information the reader must not miss.</reasoning>
</example>

### 7. Use White Space to Separate Ideas

White space (blank lines, margins, spacing) reduces cognitive load and signals structure. Dense pages discourage reading.

**Apply white space by:**
- Inserting a blank line between every paragraph
- Adding space above and below headers
- Using horizontal rules (---) to separate major topic shifts
- Breaking up long sections with sub-headers even when the hierarchy does not strictly require them

**The density test:** If any section looks like a wall of text when you squint at it, it needs more white space or shorter paragraphs or both.

### 8. Structure Documents with Progressive Disclosure

Present information in layers so different readers can stop at their appropriate depth.

**Standard pattern:**

1. **Summary** (1 paragraph): The main message and recommendation. Executives can stop here.
2. **Key findings** (bulleted list): The 3-5 main supporting points. Managers can stop here.
3. **Detailed analysis** (full sections): Evidence, methodology, and explanation. Analysts read this.
4. **Appendix** (optional): Raw data, technical details, references. Specialists consult this.

This pattern ensures that the document serves every audience without forcing anyone to read more than they need.

## Readability Metrics

Use these metrics as quality checks during revision. They are targets, not rigid rules. Adjust for audience and document type.

### Sentence and Paragraph Targets

| Metric | Target | Acceptable range |
|---|---|---|
| Average sentence length | 15-20 words | 12-25 words |
| Average paragraph length | 3-5 sentences | 2-7 sentences |
| Passive voice usage | Below 10% | Below 20% |

### Flesch Reading Ease (English)

**Formula:** 206.835 - 1.015 x (words / sentences) - 84.6 x (syllables / words)

| Score | Level | Use for |
|---|---|---|
| 70-80 | Easy (7th grade) | General public communications |
| 60-70 | Standard (8th-9th grade) | Most external business writing |
| 50-60 | Fairly difficult (10th-12th grade) | Internal business writing, technical audiences |
| 30-50 | Difficult (college) | Specialized professional audiences only |

**Target for business writing:** 50-70 depending on audience. When in doubt, aim simpler.

### Flesch Reading Ease -- German (Amstad, 1978)

German words average more syllables than English (compound nouns like Qualitaetssicherungssysteme), so the standard English formula produces inaccurate scores. Use the Amstad adaptation.

**Formula:** 180 - (words / sentences) - 58.5 x (syllables / words)

Key differences from the English formula:
- Lower constant (180 vs 206.835)
- No coefficient on average sentence length (1.0 vs 1.015)
- Lower syllable penalty (58.5 vs 84.6) to compensate for German compound words

| Score | Level |
|---|---|
| 70-80 | Medium easy |
| 60-70 | Medium |
| 50-60 | Medium weight |
| 30-50 | Heavy |
| 0-30 | Very difficult (academic) |

**Target for German business writing:** 30-50 (using Amstad formula). German compound words (e.g., Qualitaetssicherungssysteme) inherently produce lower Amstad scores than equivalent English text on the standard Flesch scale. A German Amstad score of 30-50 corresponds roughly to the readability level of an English text scoring 50-60 on the standard Flesch formula.

The readability script auto-detects language and applies the correct formula. Use `--lang de` or `--lang en` to override detection.

## Document Type Quick Reference

Apply the general principles above, then adjust intensity based on document type:

| Document type | Paragraph length | Header depth | Lists | Special notes |
|---|---|---|---|---|
| Email | 2-3 sentences | Minimal (keep emails short) | Use freely | Front-load the ask or key info in first 2 sentences |
| Memo | 3-4 sentences | 2 levels (## and ###) | For details and next steps | Generous white space throughout |
| Brief | 3-5 sentences | 2-3 levels, descriptive | For findings and options | Use progressive disclosure structure |
| Report | 4-5 sentences | 3 levels max, highly descriptive | Every 2-3 paragraphs | Include table of contents for 5+ pages |
| Proposal | 3-5 sentences | 2-3 levels, client-focused | For benefits and deliverables | Tables for pricing and ROI comparisons |

## Revision Checklist

Run this checklist as a final pass on any document. Fix every item that fails.

- [ ] The main message appears in the first 1-2 sentences of the document
- [ ] Every header is descriptive (not generic like "Introduction" or "Background")
- [ ] Sibling headers use parallel grammatical structure
- [ ] No paragraph exceeds 7 sentences or 6-8 lines on screen
- [ ] Each paragraph makes exactly one point
- [ ] Every group of 3+ parallel items is formatted as a list
- [ ] Every comparison or multi-attribute data set uses a table
- [ ] Bold is used on fewer than 15% of words and only on critical terms
- [ ] No section appears as a dense wall of text (the squint test)
- [ ] The document follows progressive disclosure: summary then details then appendix
- [ ] A reader scanning only headers and first sentences of sections gets the full argument
