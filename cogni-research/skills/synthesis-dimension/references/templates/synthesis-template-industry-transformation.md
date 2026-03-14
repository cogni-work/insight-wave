# Synthesis Template: Industry Transformation Arc

**Arc ID:** `industry-transformation`
**Arc Display Name:** Industry Transformation
**Arc Elements:** Forces / Friction / Evolution / Leadership

## Applicability

Used when `arc_id="industry-transformation"` is set in `.metadata/sprint-log.json`. Mapped from `research_type="industry"` or `research_type="transformation"`.

**Best for:** Industry disruption analysis, transformation strategy, change management research.

---

## Arc Element Definitions

### Element 1: Forces

**Purpose:** Identify the forces driving industry transformation. Present evidence of technological, economic, regulatory, and social pressures reshaping the industry.

**Content guidance:**
- Technology forces (automation, digitalization, AI adoption)
- Economic forces (cost pressure, new business models, value chain shifts)
- Regulatory forces (compliance requirements, policy changes)
- Social forces (workforce expectations, customer behavior, sustainability)

**Signal words for classification:** force, driver, pressure, catalyst, disruption, technology, regulation, economic, social, demand, automation, digitalization, mandate, requirement, acceleration

**Planning horizon affinity:**
- Primary: Observe (18+ months) — structural forces reshaping industry
- Secondary: Plan (6-18 months) — forces becoming actionable

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 2: Friction

**Purpose:** Identify barriers and resistance to transformation. Present evidence of organizational, technical, and market friction slowing change.

**Content guidance:**
- Organizational resistance and cultural barriers
- Technical debt and legacy system constraints
- Skill gaps and talent market limitations
- Regulatory uncertainty and compliance complexity
- Market inertia and switching costs

**Signal words for classification:** barrier, resistance, friction, legacy, debt, gap, constraint, inertia, challenge, obstacle, complexity, cost, risk, uncertainty, slow

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate friction to address
- Secondary: Plan (6-18 months) — structural barriers requiring sustained effort

**Word target:** 200-350 words
**Citation density:** 2-4 citations

### Element 3: Evolution

**Purpose:** Map the transformation pathway. Present evidence of evolutionary stages, success patterns, and transition models.

**Content guidance:**
- Stage models and maturity frameworks from evidence
- Successful transformation patterns and case evidence
- Technology adoption curves and migration paths
- Industry evolution benchmarks and timelines

**Signal words for classification:** evolution, stage, maturity, pathway, transition, migration, adoption, phase, progression, benchmark, model, roadmap, milestone, transformation, journey

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — transformation roadmap
- Secondary: Observe (18+ months) — long-term evolution trajectory

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 4: Leadership

**Purpose:** Define leadership requirements for successful transformation. Present evidence of governance models, capability needs, and strategic priorities.

**Content guidance:**
- Leadership capabilities required for transformation success
- Governance models and decision-making structures
- Strategic priorities and resource allocation evidence
- Change management approaches validated by evidence

**Signal words for classification:** leadership, governance, capability, strategy, priority, decision, management, talent, culture, vision, alignment, commitment, sponsor, champion, accountability

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate leadership actions
- Secondary: Plan (6-18 months) — leadership capability building

**Word target:** 150-250 words
**Citation density:** 2-3 citations

---

## Section Header Translations

| Element | English (en) | German (de) |
|---------|-------------|-------------|
| Element 1 | Forces | Treibende Kräfte |
| Element 2 | Friction | Widerstände |
| Element 3 | Evolution | Evolutionspfad |
| Element 4 | Leadership | Führungsanforderungen |

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
arc_id: "industry-transformation"
arc_display_name: "Industry Transformation"
arc_elements: ["Forces", "Friction", "Evolution", "Leadership"]
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing transformation context and key forces}

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
