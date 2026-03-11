---
title: Executive Brief Template
type: template
category: deliverable-template
deliverable: brief
tags: [template, brief, executive-communication, decision-support]
instructions: >
  This is an LLM instruction template for generating executive briefs.
  Use this template as a structural blueprint when the copywriter skill
  produces a brief deliverable. Follow the section-by-section generation
  guidance. Adapt section count and depth to match the user's content scope.
version: 2.0
last_updated: 2026-02-25
---

# Executive Brief Template

<purpose>
Generate a concise, decision-oriented executive brief. A brief exists to help a busy decision-maker understand a situation, evaluate options, and act — all within a 2-5 minute read.
</purpose>

<generation-rules>
- Target length: 1-3 pages (400-1500 words depending on complexity)
- Readability: Flesch 50-60 (standard difficulty)
- Active voice: 80%+ of all sentences
- Paragraphs: 3-5 sentences maximum
- Heading depth: maximum 3 levels (# ## ###)
- Visual element every 2-3 paragraphs (table, bullet list, or callout)
- Framework: BLUF (default), Pyramid, or SCQA — select based on context below

FRAMEWORK SELECTION (think step by step):
1. Is there a clear, single recommendation the reader should approve? -> Use BLUF
2. Is this a complex analysis requiring structured argument with multiple supporting points? -> Use Pyramid
3. Do you need to build urgency by establishing a problem before proposing a solution? -> Use SCQA
If the user specified a framework, use that. Otherwise, default to BLUF.
</generation-rules>

---

## Template Structure

Generate the brief by working through each section below in order. Each section includes: what to write, how long it should be, and what makes it effective.

---

### Section 1: Title Block

```markdown
# [Descriptive Title: Action-Oriented, Under 10 Words]
**[Document Type — e.g., "Decision Brief" | "Strategic Brief" | "Investment Brief"] | [Date]**
```

<guidance>
- The title should tell the reader what this brief is about AND what it asks of them.
- Good: "Recommendation: Migrate CRM to Salesforce by Q3"
- Bad: "CRM Options" (too vague, no action signal)
- Include the document type label and date on the line below the title.
</guidance>

---

### Section 2: Executive Summary / Recommendation (REQUIRED)

This is the single most important section. Write it as if the reader will read ONLY this paragraph and nothing else.

```markdown
## Recommendation

[1-3 sentences. State: (1) what you recommend, (2) why it matters, and (3) the expected outcome. Include at least one specific number or timeframe. This section must be scannable in under 30 seconds.]

[Optional: 1-2 additional sentences ONLY if there is critical context — e.g., a hard deadline, a required decision, or an immediate risk. Do not add this paragraph for general background.]
```

<guidance>
THINK BEFORE WRITING: What is the one sentence a busy executive would highlight? Lead with that.

Quality checklist for this section:
- Does it state a clear recommendation (not just describe a situation)?
- Does it include at least one concrete number, dollar amount, or date?
- Could the reader make a decision from this section alone?
- Is it under 75 words?

BLUF pattern: "We recommend [action] by [date] to [achieve outcome], which will [quantified benefit]."
SCQA pattern: Lead with the complication/urgency, then state the recommendation.
Pyramid pattern: State the governing thought (main conclusion), then preview supporting arguments.
</guidance>

---

### Section 3: Supporting Arguments (2-4 sections)

Generate 2-4 supporting sections depending on complexity. Each section presents one distinct argument, finding, or evidence cluster that supports the recommendation.

```markdown
## [Argument Heading: Specific and Descriptive]

[Opening sentence: State this section's main point in 1 sentence.]

[Evidence paragraph: 3-5 sentences providing data, examples, or analysis that prove the opening claim. Use concrete numbers and cite sources where available.]
```

<guidance>
STRUCTURAL PRINCIPLE — MECE (Mutually Exclusive, Collectively Exhaustive):
- Each section covers one distinct topic with no overlap between sections
- Together, the sections cover all the reasoning needed to support the recommendation
- If two sections start to overlap, merge them or redraw boundaries

CONTENT RULES per section:
- Lead each section with its conclusion (not with background)
- Support claims with data: percentages, dollar amounts, timeframes, comparisons
- Use ONE of these sub-formats when the content calls for it:

  Sub-format A — Bullet evidence:
  - [Supporting fact with number]
  - [Supporting fact with number]
  - [Supporting fact with number]

  Sub-format B — Comparison table:
  | Criterion | Option A | Option B |
  |-----------|----------|----------|
  | [Metric]  | [Value]  | [Value]  |

  Sub-format C — Risk/challenge pairs:
  **[Risk name]:** [1-2 sentence description of the risk and its mitigation]

SECTION COUNT GUIDANCE:
- 1-page brief (400-600 words): 2 supporting sections
- 2-page brief (700-1000 words): 3 supporting sections
- 3-page brief (1000-1500 words): 3-4 supporting sections
</guidance>

---

### Section 4: Financial Impact (CONDITIONAL)

Include this section when the recommendation involves costs, savings, investment, or resource allocation. Omit it entirely when no financial dimension exists.

```markdown
## Financial Impact

[1-2 sentence summary of the financial case.]

| Metric | Current | Proposed | Impact |
|--------|---------|----------|--------|
| [Key metric 1] | [Value] | [Value] | [Change with direction] |
| [Key metric 2] | [Value] | [Value] | [Change with direction] |
| [Key metric 3] | [Value] | [Value] | [Change with direction] |

**ROI / Payback:** [1 sentence: expected return and timeline. Example: "Projected 3.2x ROI within 18 months based on $240K annual cost savings against $75K implementation cost."]
```

<guidance>
- Always show current vs. proposed states — executives need the delta, not just the endpoint
- Express impact as both absolute numbers AND relative change (e.g., "$120K savings, 34% reduction")
- If exact numbers are unavailable, provide ranges with stated assumptions
- The ROI/Payback line converts the table into a single decision-ready statement
</guidance>

---

### Section 5: Next Steps / Decision Required (REQUIRED)

```markdown
## Next Steps

[1-2 sentences: What decision is needed, who makes it, and by when.]

1. **[Action item]** — [Owner] by [deadline]
2. **[Action item]** — [Owner] by [deadline]
3. **[Action item]** — [Owner] by [deadline]

**Decision deadline:** [Date] — [Brief reason for the deadline, e.g., "to align with Q3 budget cycle" or "before contract renewal on April 15"]
```

<guidance>
Every action item MUST have three components: what, who, when.
- Bad: "Finalize the plan" (no owner, no deadline)
- Good: "Finalize migration plan — J. Torres, Engineering — by March 15"

The decision deadline must include the WHY behind the date. Arbitrary deadlines erode trust. Tie the date to a business event, dependency, or consequence.

Limit to 3-5 action items. If there are more, the brief is probably scoped too broadly.
</guidance>

---

### Section 6: Appendix (OPTIONAL)

```markdown
## Appendix

- [Supporting document, data source, or detailed analysis link]
- [Contact for follow-up questions]
```

<guidance>
Include ONLY when there are specific supporting materials the reader might want to reference. Do not add an appendix just to have one. Common reasons to include:
- A detailed analysis deck or spreadsheet backs the summary numbers
- Regulatory or legal references are relevant
- Technical specifications exist that a subset of readers may need
</guidance>

---

## Quality Validation Checklist

Before finalizing, verify each item. If any item fails, revise the brief before output.

**Structure:**
- [ ] Recommendation section is the first substantive content after the title
- [ ] Supporting sections follow MECE principle (no overlap, no gaps)
- [ ] Every section heading is specific and descriptive (not generic like "Background")
- [ ] Parallel grammatical structure across same-level headings

**Content:**
- [ ] Recommendation section is self-contained and decision-ready on its own
- [ ] Every claim is supported by a number, data point, or cited source
- [ ] Financial impact included when costs/savings are part of the recommendation
- [ ] Next steps have owner + deadline for every action item
- [ ] Decision deadline includes a business reason

**Writing Quality:**
- [ ] Active voice in 80%+ of sentences
- [ ] Sentences average 15-20 words
- [ ] Paragraphs are 3-5 sentences
- [ ] No hedging language ("seems to suggest," "might possibly") — use confident assertions ("shows," "will," "delivers")
- [ ] Key numbers and terms are bolded for scannability

**Formatting:**
- [ ] Maximum 3 heading levels used
- [ ] Visual element (table, bullets, or callout) every 2-3 paragraphs
- [ ] Horizontal rules separate major sections
- [ ] Total length within target range for brief complexity

**Preservation (when applicable):**
- [ ] German characters preserved (never ae/oe/ue/ss substitutions)
- [ ] All citation markers and URLs intact
- [ ] Diagram placeholders and figure references unchanged

---

## Common Failure Patterns

Avoid these specific patterns that weaken executive briefs:

| Failure | Why It Fails | Fix |
|---------|-------------|-----|
| Recommendation buried after context | Executives stop reading after first paragraph | Move recommendation to Section 2, before any background |
| No clear decision request | Reader finishes unsure what to do | End with explicit "approve X by Y date" |
| Overlapping arguments | Redundancy signals weak analysis | Apply MECE — each section one distinct point |
| Data without interpretation | Numbers alone do not persuade | Follow every metric with "which means [business impact]" |
| Missing financial impact | Executives think in dollars and ROI | Add Financial Impact section whenever money is involved |
| Vague next steps | No accountability, no follow-through | Every action item: what + who + when |
| Hedging language throughout | Undermines confidence in recommendation | Replace "might" with "will," "could" with "delivers" |
