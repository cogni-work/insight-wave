# Synthesis Template: Corporate Visions Arc

**Arc ID:** `corporate-visions`
**Arc Display Name:** Corporate Visions
**Arc Elements:** Why Change / Why Now / Why You / Why Pay

## Applicability

Used when `arc_id="corporate-visions"` is set in `.metadata/sprint-log.json`. This is the default arc for `market`, `generic`, and unrecognized research types.

**Best for:** B2B acquisition pitches, market opportunity framing, value proposition research.

---

## Arc Element Definitions

### Element 1: Why Change

**Purpose:** Establish that the status quo is untenable. Present evidence that contradicts current assumptions, reveals overlooked problems, or shows emerging threats.

**Content guidance:**
- Evidence that challenges existing approaches or assumptions
- Data showing market shifts, regulatory changes, or competitive pressure
- Trends indicating growing risks of inaction
- Overlooked problems surfacing from research

**Signal words for classification:** disruption, risk, gap, failing, obsolete, challenge, threat, shift, pressure, decline, contradiction, problem, inadequate, unsustainable, vulnerable

**Planning horizon affinity:**
- Primary: Observe (18+ months) — emerging threats not yet felt
- Secondary: Plan (6-18 months) — building pressures requiring preparation

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 2: Why Now

**Purpose:** Create urgency. Show time-bound factors, acceleration signals, and closing windows of opportunity.

**Content guidance:**
- Time-sensitive market developments or regulatory deadlines
- Acceleration patterns in adoption, technology, or competition
- Convergence of factors creating a unique moment
- Cost-of-delay evidence and competitive timing

**Signal words for classification:** accelerating, deadline, window, momentum, convergence, timing, urgent, immediate, now, catalyst, tipping point, adoption curve, first-mover, competitive timing

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate urgency
- Secondary: Plan (6-18 months) — approaching deadlines

**Word target:** 200-350 words
**Citation density:** 2-4 citations

### Element 3: Why You

**Purpose:** Demonstrate capability and differentiation. Show evidence of unique strengths, positioning advantages, or capability fit.

**Content guidance:**
- Capabilities that align with opportunity requirements
- Competitive advantages or unique positioning
- Existing assets, partnerships, or expertise that create leverage
- Evidence of successful approaches in analogous situations

**Signal words for classification:** capability, advantage, differentiation, strength, expertise, unique, positioning, competence, asset, platform, partnership, ecosystem, track record, qualification

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — capability building and positioning
- Secondary: Act (0-6 months) — leveraging existing strengths

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 4: Why Pay

**Purpose:** Justify investment. Present financial evidence, ROI projections, cost implications, and value quantification.

**Content guidance:**
- Financial data supporting investment decisions
- ROI evidence, cost-benefit analysis patterns
- Total cost of ownership considerations
- Value quantification from comparable implementations
- Risk-adjusted return evidence

**Signal words for classification:** ROI, cost, investment, value, financial, budget, savings, revenue, payback, TCO, efficiency, economic, monetize, business case, pricing

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate business case
- Secondary: Plan (6-18 months) — long-term value realization

**Word target:** 150-250 words
**Citation density:** 2-3 citations

---

## Section Header Translations

| Element | English (en) | German (de) |
|---------|-------------|-------------|
| Element 1 | Why Change | Warum Verändern |
| Element 2 | Why Now | Warum Jetzt |
| Element 3 | Why You | Warum Sie |
| Element 4 | Why Pay | Warum Investieren |

---

## Evidence Classification Algorithm

For each trend and claim, calculate element affinity score:

1. **Signal word match** (weight: 0.4): Count signal word matches in trend title, description, and key claims
2. **Planning horizon affinity** (weight: 0.35): Apply bonus for horizon-element alignment per table above
3. **Content semantic match** (weight: 0.25): Assess conceptual alignment with element purpose

**Assign to highest-scoring element.** Ties broken by: element with fewer assigned trends (balance preference).

**Balance check:** If any element has zero trends after classification, log WARNING and redistribute from the element with the most trends (move lowest-scoring trend).

---

## Document Structure (Arc Path)

```markdown
---
{standard frontmatter}
arc_id: "corporate-visions"
arc_display_name: "Corporate Visions"
arc_elements: ["Why Change", "Why Now", "Why You", "Why Pay"]
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing dimension scope and key findings}

## {ARC_HEADER_ELEMENT_1}

{250-400 words with 3-5 citations}

## {ARC_HEADER_ELEMENT_2}

{200-350 words with 2-4 citations}

## {ARC_HEADER_ELEMENT_3}

{250-400 words with 3-5 citations}

## {ARC_HEADER_ELEMENT_4}

{150-250 words with 2-3 citations}

## {HEADER_RELATED_DIMENSIONS}
{50-100 words, optional}

## {HEADER_RELATED_MEGATRENDS}
{100-250 words, optional}

## {HEADER_APPENDIX}
{Unchanged appendix: Evidence Assessment, Evidence Quality Analysis, Domain Concepts, References}
```
