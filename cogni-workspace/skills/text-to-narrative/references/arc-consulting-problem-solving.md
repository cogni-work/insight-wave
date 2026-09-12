---
arc_id: consulting-problem-solving
display_name: Consulting Problem-Solving
display_name_de: Consulting-Problemlösung
contract: 2
---

# Consulting Problem-Solving

## Intent

**Governing question:** What is happening, why is the status quo no longer sufficient, what is the best-supported answer, and what follows from it?

**Rhetorical job:** Diagnose an open problem and derive the answer — the consulting Situation, Complication, Resolution, Implications job. The arc establishes a shared baseline, names what breaks it, argues the evidence-led answer and closes on decisions and next moves. The complete argument can be stated in one sentence: *Given S, but C, therefore R, which means I.*

**Not for:** persuading a reader to buy or change (`corporate-visions` — a diagnostic memo that ends in "Why Pay" is selling, not diagnosing), choosing among options that are already credible (`strategic-choice`), or reframing a market category (`category-creation`).

## Selection

**Best for:** diagnostic memos, problem-solving reports, consulting deliverables that must derive an answer from evidence, executive briefings on an open question.

**Signals:** content type `consulting`, `problem-solving`, `diagnostic` or `recommendation-case`; the source states a baseline and something that disturbs it; it works toward one best-supported answer; it separates evidence from interpretation; keywords such as "situation", "complication", "root cause", "hypothesis", "recommendation", "so what".

**Anti-signals:** named alternatives already on the table awaiting a choice; a case for investment addressed to a buyer; a documented customer outcome.

**Fallback priority:** never a fallback. When the decision purpose is "understand the problem and derive the answer", this arc outranks `corporate-visions` in the execution-fit step regardless of keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Situation: Relevant Baseline | Situation: Relevante Ausgangslage |
| 2 | Complication: What Breaks the Baseline | Komplikation: Was die Ausgangslage verändert |
| 3 | Resolution: The Evidence-Led Answer | Lösung: Die evidenzbasierte Antwort |
| 4 | Implications: Decisions and Next Moves | Implikationen: Entscheidungen und nächste Schritte |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Situation | 20% |
| Complication | 27% |
| Resolution | 33% |
| Implications | 20% |

**Executive TL;DR emphasis:** situation → complication → evidence-led resolution → executive implications. The narrative opens with the TL;DR defined in `validation.md`; the resolution — the answer — belongs in its first sentence as the conclusion.

**Transitions:**

1. Situation → Complication: "That baseline no longer holds."
2. Complication → Resolution: "The evidence points to one answer."
3. Resolution → Implications: "If that is the answer, three things follow."

**Closing pattern:** the one-sentence form of the whole argument — "Given [S], but [C], therefore [R], which means [I]." — followed by the first next move.

## Elements

### 1. Situation

**Purpose:** establish the relevant baseline the reader and writer share — what is true, agreed and material to the problem, and nothing else.

**Evidence sought:** the executive summary's framing, baseline facts and figures in the dimension syntheses, the research question, context the sources treat as settled.

**Argument move:** state the baseline as facts the reader will not dispute, sized with the numbers that matter, and stop where agreement stops. Everything that is contested belongs in Complication.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure) (what is settled versus what is about to be questioned).

**Hard rules:** only material, agreed facts; no recommendation, no tension; the shortest element.

**Failure modes:** history for its own sake; a situation the reader would dispute; the complication smuggled in early.

### 2. Complication

**Purpose:** name what breaks the baseline — the change, tension or new fact that makes the status quo insufficient.

**Evidence sought:** counterintuitive findings and tensions in the syntheses, trend entities with a shift or a deadline, cost and risk figures, anything the executive summary flags as new.

**Argument move:** state the complication as one clear break, then evidence it: what changed, by how much, since when, with what consequence if unaddressed. Where the evidence carries a deadline or a tipping point, name it; where the complication has several strands, order them by consequence.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (the Problem leg, fully developed), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** one governing complication, evidenced with numbers and dates; every strand traces to the baseline it breaks; no answer yet.

**Failure modes:** a list of unrelated problems; a complication the situation never set up; the resolution leaking in.

### 3. Resolution

**Purpose:** argue the evidence-led answer to the complication — the best-supported resolution, with evidence and interpretation kept apart.

**Evidence sought:** strategic recommendations, the syntheses' strongest supported claims, portfolio propositions when a `--content-map` supplies them.

**Argument move:** state the answer, then show why the evidence supports it over the alternatives it displaces; separate what the evidence establishes from what the writer infers, and say which is which; where the answer is a capability or an approach, give it IS-DOES-MEANS shape so it is concrete.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (Solution and Benefit legs), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the resolution directly addresses the named complication — no orphan recommendations; evidence and interpretation are visibly distinguished; the largest element.

**Failure modes:** recommendations the complication never asked for; interpretation dressed as evidence; a menu of answers with no argument for one.

### 4. Implications

**Purpose:** state what follows from the resolution — the decisions to take, in what order, and the next moves.

**Evidence sought:** action items in the recommendations, timelines and dependencies in the syntheses, the cost of inaction where the sources quantify it.

**Argument move:** derive each implication from the resolution ("if R, then…"), name the decision it requires and who owns it, order the moves, and state what the reader should do first. Address the reader directly where the decision is theirs.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing), [Compound Impact](techniques-overview.md#8-compound-impact-calculation) (the cost of not acting on the resolution), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** every implication traces to the resolution; each names a decision and an owner or a next move; the element ends on the one-sentence argument and the first move.

**Failure modes:** implications that introduce new analysis; a generic "next steps" list; a close with no first move.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- The complete argument can be stated as *Given S, but C, therefore R, which means I* — and the closing states it.
- Situation carries only material, agreed facts and no recommendation.
- Complication names one governing break, evidenced with numbers and dates, that traces to the baseline.
- Resolution directly addresses the named complication with no orphan recommendations, and distinguishes evidence from interpretation.
- Every implication traces to the resolution and names a decision, an owner or a next move.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-strategic-choice.md` — when the alternatives are already credible and the job is to choose
- `arc-corporate-visions.md` — when the job is to persuade, not to diagnose
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
