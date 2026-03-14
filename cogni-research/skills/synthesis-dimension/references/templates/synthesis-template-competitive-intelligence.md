# Synthesis Template: Competitive Intelligence Arc

**Arc ID:** `competitive-intelligence`
**Arc Display Name:** Competitive Intelligence
**Arc Elements:** Landscape / Shifts / Positioning / Implications

## Applicability

Used when `arc_id="competitive-intelligence"` is set in `.metadata/sprint-log.json`. Mapped from `research_type="competitive"`.

**Best for:** Market analysis, competitive positioning, strategic response planning.

---

## Arc Element Definitions

### Element 1: Landscape

**Purpose:** Map the current competitive terrain. Present evidence of market structure, key players, established positions, and prevailing dynamics.

**Content guidance:**
- Market structure and segmentation evidence
- Competitor capabilities and market share data
- Customer expectations and value chain positions
- Industry benchmarks and performance standards

**Signal words for classification:** market, landscape, competitor, player, share, segment, benchmark, position, structure, industry, incumbent, leader, follower, ecosystem, customer

**Planning horizon affinity:**
- Primary: Act (0-6 months) — current state assessment
- Secondary: Plan (6-18 months) — structural patterns

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 2: Shifts

**Purpose:** Identify competitive dynamics in motion. Present evidence of changes in market power, technology adoption, customer behavior, or regulatory environment.

**Content guidance:**
- Competitive moves and strategic pivots observed
- Technology adoption curves disrupting positions
- Customer behavior changes and preference shifts
- Regulatory or policy changes affecting competition
- New entrant activity and market boundary erosion

**Signal words for classification:** shift, change, disruption, pivot, adoption, transition, migration, new entrant, emerging, decline, growth, regulatory, behavior, preference, erosion

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — shifts requiring strategic response
- Secondary: Observe (18+ months) — early shifts to monitor

**Word target:** 200-350 words
**Citation density:** 2-4 citations

### Element 3: Positioning

**Purpose:** Define strategic positioning opportunities. Present evidence of defensible positions, capability advantages, and differentiation paths.

**Content guidance:**
- Positioning gaps in the competitive landscape
- Capability advantages relevant to identified shifts
- Differentiation opportunities supported by evidence
- Partnership and ecosystem positioning strategies

**Signal words for classification:** positioning, differentiation, advantage, niche, strategy, gap, opportunity, defense, strength, unique, value proposition, brand, capability, partner, alliance

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — strategic positioning actions
- Secondary: Act (0-6 months) — quick positioning wins

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 4: Implications

**Purpose:** Translate competitive analysis into strategic decisions. Present evidence-based recommendations for competitive response.

**Content guidance:**
- Strategic options ranked by evidence strength
- Resource allocation implications
- Risk-reward assessment for positioning choices
- Timing considerations for competitive moves

**Signal words for classification:** implication, recommendation, decision, priority, investment, resource, risk, opportunity, action, response, timeline, trade-off, scenario, outcome, strategic

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate competitive responses
- Secondary: Plan (6-18 months) — strategic positioning investments

**Word target:** 150-250 words
**Citation density:** 2-3 citations

---

## Section Header Translations

| Element | English (en) | German (de) |
|---------|-------------|-------------|
| Element 1 | Landscape | Wettbewerbslandschaft |
| Element 2 | Shifts | Marktverschiebungen |
| Element 3 | Positioning | Positionierung |
| Element 4 | Implications | Implikationen |

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
arc_id: "competitive-intelligence"
arc_display_name: "Competitive Intelligence"
arc_elements: ["Landscape", "Shifts", "Positioning", "Implications"]
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing competitive context and key findings}

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
