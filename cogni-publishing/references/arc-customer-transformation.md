---
arc_id: customer-transformation
display_name: Customer Transformation
display_name_de: Kundentransformation
contract: 2
---

# Customer Transformation

## Intent

**Governing question:** What changed for the customer, what made it difficult, what intervention created the shift, and what verified outcome proves it mattered?

**Rhetorical job:** Prove value through a documented customer journey — the case study, the reference story. The arc moves from the customer's starting point through the struggle to the turning point and closes on the verified outcome and the transferable lesson. It proves; it does not sell.

**Not for:** prospective persuasion of a buyer who has not yet changed (`corporate-visions` — a case study written on that arc sells instead of proving), a portfolio introduction (`jtbd-portfolio`), or a company self-description (`company-credo`).

## Selection

**Best for:** case studies, reference stories, customer-success narratives, proof-of-value write-ups, before/after accounts with measured results.

**Signals:** content type `customer-story`, `case-study`, `customer-success`, `customer-transformation` or `reference-story`; the source follows one customer over time; it carries a before state, an intervention and measured results; keywords such as "case study", "customer", "before", "after", "results", "implementation", "outcome".

**Anti-signals:** no single customer; results projected rather than observed; a proposal or pitch addressed to the customer.

**Fallback priority:** never a fallback. When the decision purpose is "prove observed value", this arc outranks `corporate-visions` in the execution-fit step regardless of keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Before: The Starting Point | Ausgangslage: Wo der Kunde stand |
| 2 | Struggle: What Stood in the Way | Herausforderung: Was Fortschritt blockierte |
| 3 | Change: The Turning Point | Veränderung: Der Wendepunkt |
| 4 | Outcome: The Verified Transformation | Ergebnis: Die nachweisbare Transformation |

## Composition

Section lengths are proportions of `--target-length`. **Recommended length: 1,400 words** — a case study is read for its proof, not its prose — so callers pass `--target-length 1400`; the skill's own default stays 1,675 when the flag is omitted. Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Before | 20% |
| Struggle | 25% |
| Change | 30% |
| Outcome | 25% |

**Executive TL;DR emphasis:** before-state → struggle → intervention and turning point → verified outcome. The narrative opens with the TL;DR defined in `validation.md`; the verified outcome belongs in its first sentence as the conclusion.

**Transitions:**

1. Before → Struggle: "Getting from there to anywhere better was harder than it looked."
2. Struggle → Change: "The turning point came when…"
3. Change → Outcome: "What that produced can be measured."

**Closing pattern:** the verified outcome restated with its evidence, then the transferable lesson, framed explicitly as interpretation: "For organizations in a similar starting position, the pattern suggests…"

## Elements

### 1. Before

**Purpose:** establish where the customer stood — the starting point in the customer's own terms, with its measured baseline.

**Evidence sought:** the customer's situation, metrics and constraints in the source material, the market context that made the starting point ordinary rather than exceptional.

**Argument move:** describe the starting point factually — what the customer did, what it cost, what it produced — with the baseline numbers the outcome will later be measured against. Name the customer only when the supplied material authorizes it; otherwise describe the organization by type and scale.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure) (the baseline as the thing the story will overturn).

**Hard rules:** the baseline metrics that Outcome will use are stated here; named customer details appear only with authorization in the material; no judgment of the starting point.

**Failure modes:** a starting point with no numbers; a customer named without permission; the struggle told early.

### 2. Struggle

**Purpose:** show what stood in the way — the obstacles that made progress difficult and what earlier attempts produced.

**Evidence sought:** obstacles, failed or partial attempts, constraints and their costs in the source material, external pressures that raised the stakes.

**Argument move:** name the obstacles concretely, what each cost, and what the customer tried before; where external pressure made the struggle urgent, name it with its date. The struggle is the customer's, told with respect.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (the Problem leg), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** obstacles are concrete and costed; earlier attempts are acknowledged; the customer is not blamed.

**Failure modes:** "the customer faced many challenges"; a struggle invented to flatter the intervention; the customer cast as the problem.

### 3. Change

**Purpose:** describe the turning point — the intervention, what it was, what it did and why it worked where earlier attempts did not.

**Evidence sought:** the intervention's description, its implementation sequence and timeline, the mechanism by which it addressed the obstacles, in the source material and any supplied portfolio propositions.

**Argument move:** give the intervention IS-DOES-MEANS shape — what it is, what it did for the customer, why it held where earlier attempts failed — and tell the implementation as a sequence with dates. Causal claims are no stronger than the evidence permits: "contributed to", "coincided with", "the customer attributes" where the evidence stops short of "caused".

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (Solution leg), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the intervention is concrete and dated; causal language matches the evidence; the mechanism that overcame the obstacles is stated.

**Failure modes:** a product description in place of a turning point; "transformed" with no mechanism; causation asserted where only correlation is evidenced.

### 4. Outcome

**Purpose:** state the verified transformation — the measured results against the Before baseline — and the transferable lesson.

**Evidence sought:** the measured results, their measurement method and date, the customer's own attribution where quoted, in the source material.

**Argument move:** set each result against its baseline from Before, with the measurement and its date; distinguish what was measured from what the customer attributes; then draw the transferable lesson, framed as interpretation for the reader in a similar position.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (before/after), [You-Phrasing](techniques-overview.md#7-you-phrasing) (the lesson addressed to the reader), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** every result is set against its Before baseline and dated; measured results are distinguished from attributed ones; the transferable lesson is framed as interpretation, never as a promise.

**Failure modes:** results with no baseline; a projected result presented as observed; the lesson written as a sales claim.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Causal claims are no stronger than the evidence permits ("contributed to", "coincided with", "the customer attributes" where appropriate).
- Named customer details appear only when the supplied material authorizes them; otherwise the organization is described by type and scale.
- Every Outcome result is set against a Before baseline, with measurement method and date, and measured results are distinguished from attributed ones.
- The transferable lesson is framed as interpretation.
- The chain holds: the struggle is against the baseline described; the change addresses that struggle's obstacles; the outcome is measured against that baseline.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-corporate-visions.md` — when the job is prospective persuasion, not proof
- `arc-jtbd-portfolio.md` — when the job is to explain a portfolio, not one customer's journey
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
