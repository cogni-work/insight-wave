# Synthesis Template: Strategic Foresight Arc

**Arc ID:** `strategic-foresight`
**Arc Display Name:** Strategic Foresight
**Arc Elements:** Signals / Scenarios / Strategies / Decisions

## Applicability

Used when `arc_id="strategic-foresight"` is set in `.metadata/sprint-log.json`. Mapped from `research_type="foresight"` or `research_type="scenarios"`.

**Best for:** Future planning, scenario development, strategic decision-making under uncertainty.

---

## Arc Element Definitions

### Element 1: Signals

**Purpose:** Identify weak and strong signals of change. Present evidence of emerging patterns, early indicators, and discontinuities that may shape the future.

**Content guidance:**
- Weak signals from technology, society, regulation, or economy
- Leading indicators and early-warning patterns
- Discontinuities and surprising developments
- Trend acceleration or deceleration signals

**Signal words for classification:** signal, indicator, early, emerging, pattern, discontinuity, weak signal, leading, precursor, harbinger, foresight, scan, horizon, megatrend, driver

**Planning horizon affinity:**
- Primary: Observe (18+ months) — weak signals and emerging patterns
- Secondary: Plan (6-18 months) — strengthening signals

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 2: Scenarios

**Purpose:** Construct plausible futures from signal clusters. Present evidence-backed scenarios showing alternative development paths.

**Content guidance:**
- Scenario narratives built from converging signals
- Key uncertainties and branching points
- Probability assessments based on evidence strength
- Cross-impact relationships between signals

**Signal words for classification:** scenario, future, uncertainty, pathway, alternative, probability, projection, forecast, if-then, branching, wildcard, plausible, trajectory, development, outlook

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — scenarios informing medium-term strategy
- Secondary: Observe (18+ months) — long-range scenario horizons

**Word target:** 200-350 words
**Citation density:** 2-4 citations

### Element 3: Strategies

**Purpose:** Define strategic options for each scenario. Present evidence of effective approaches, capability requirements, and option value.

**Content guidance:**
- Strategic options mapped to scenarios
- Robust strategies that work across multiple scenarios
- Hedging approaches and option-creating moves
- Capability investments that preserve flexibility

**Signal words for classification:** strategy, option, approach, capability, resilience, flexibility, hedge, invest, position, prepare, adapt, robust, portfolio, contingency, roadmap

**Planning horizon affinity:**
- Primary: Plan (6-18 months) — strategic positioning
- Secondary: Act (0-6 months) — no-regret moves

**Word target:** 250-400 words
**Citation density:** 3-5 citations

### Element 4: Decisions

**Purpose:** Crystallize actionable decisions. Present evidence-backed decision frameworks, triggers, and priorities.

**Content guidance:**
- Decision points with clear trigger conditions
- Priority ranking based on evidence and urgency
- Resource allocation recommendations
- Monitoring indicators for scenario realization

**Signal words for classification:** decision, priority, trigger, action, resource, allocate, commit, deadline, milestone, threshold, governance, monitor, review, execute, launch

**Planning horizon affinity:**
- Primary: Act (0-6 months) — immediate decision requirements
- Secondary: Plan (6-18 months) — decision preparation

**Word target:** 150-250 words
**Citation density:** 2-3 citations

---

## Section Header Translations

| Element | English (en) | German (de) |
|---------|-------------|-------------|
| Element 1 | Signals | Signale |
| Element 2 | Scenarios | Szenarien |
| Element 3 | Strategies | Strategien |
| Element 4 | Decisions | Entscheidungen |

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
arc_id: "strategic-foresight"
arc_display_name: "Strategic Foresight"
arc_elements: ["Signals", "Scenarios", "Strategies", "Decisions"]
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing foresight context and key signals}

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
