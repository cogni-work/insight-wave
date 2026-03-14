# Synthesis Template: Technology Futures Arc

**Arc ID:** `technology-futures`
**Arc Display Name:** Technology Futures
**Arc Elements:** What's Emerging / What's Converging / What's Possible / What's Required

## Applicability

Used when `arc_id="technology-futures"` is set in `.metadata/sprint-log.json`. Mapped from `research_type="technology"`.

**Best for:** Technology scouting, innovation roadmaps, R&D strategy research.

---

## Arc Element Definitions

### Element 1: What's Emerging

**Purpose:** Identify nascent technologies, early signals, and frontier developments. Present evidence of emerging capabilities before mainstream awareness.

**Content guidance:**
- Early-stage technology developments and breakthroughs
- Research lab findings and pre-commercial innovations
- Weak signals from patent filings, academic papers, or startup activity
- First implementations and proof-of-concept results

**Signal words for classification:** emerging, nascent, breakthrough, novel, prototype, early-stage, frontier, experimental, pioneering, research, discovery, innovation, first, pre-commercial, beta

**Planning horizon affinity:**
- Primary: Observe (18+ months) — frontier technologies
- Secondary: Plan (6-18 months) — maturing innovations

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 2: What's Converging

**Purpose:** Show technology convergence patterns. Present evidence of synergies between technologies, platforms merging, or capability stacking.

**Content guidance:**
- Technologies combining to create new capabilities
- Platform convergence and ecosystem formation
- Cross-domain technology transfer patterns
- Standards alignment and interoperability developments

**Signal words for classification:** convergence, integration, platform, ecosystem, synergy, interoperability, standard, stack, combination, cross-domain, fusion, hybrid, unified, bridging, middleware

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — convergence patterns becoming actionable
- Secondary: Act (0-6 months) — mature convergences ready for adoption

**Word target:** 200-350 words
**Citation density:** 2-4 citations

### Element 3: What's Possible

**Purpose:** Articulate the opportunity space. Show evidence of transformative potential when emerging technologies are applied strategically.

**Content guidance:**
- Use cases enabled by technology convergence
- Transformation scenarios supported by evidence
- Capability unlocks and competitive advantage potential
- Industry-specific application opportunities

**Signal words for classification:** potential, opportunity, enable, transform, unlock, possible, capability, vision, application, use case, scenario, impact, disruption, advantage, strategic

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — strategic opportunity windows
- Secondary: Observe (18+ months) — long-term transformation potential

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 4: What's Required

**Purpose:** Define prerequisites and investment needs. Present evidence of what is needed to capture the opportunity — skills, infrastructure, partnerships, governance.

**Content guidance:**
- Technical prerequisites and infrastructure requirements
- Skill gaps and talent requirements
- Investment thresholds and resource needs
- Governance and compliance considerations
- Risk factors and mitigation requirements

**Signal words for classification:** requirement, prerequisite, investment, skill, infrastructure, governance, compliance, risk, talent, capacity, readiness, maturity, gap, dependency, foundation

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate readiness actions
- Secondary: Plan (6-18 months) — capability building roadmap

**Word target:** 150-250 words
**Citation density:** 2-3 citations

---

## Section Header Translations

| Element | English (en) | German (de) |
|---------|-------------|-------------|
| Element 1 | What's Emerging | Was Entsteht |
| Element 2 | What's Converging | Was Konvergiert |
| Element 3 | What's Possible | Was Wird Möglich |
| Element 4 | What's Required | Was Wird Benötigt |

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
arc_id: "technology-futures"
arc_display_name: "Technology Futures"
arc_elements: ["What's Emerging", "What's Converging", "What's Possible", "What's Required"]
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing dimension scope and technology landscape}

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
