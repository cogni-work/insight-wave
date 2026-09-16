---
arc_id: strategic-choice
display_name: Strategic Choice
display_name_de: Strategische Entscheidung
contract: 2
---

# Strategic Choice

## Intent

**Governing question:** Which option should we choose, and why is that choice superior given the evidence and the trade-offs?

**Rhetorical job:** Decide among already-credible alternatives — make, buy or partner; market entry; sequencing. The arc frames the decision, names the criteria that discriminate, evaluates genuinely distinct options against the same criteria, and recommends one with its principal trade-off stated.

**Not for:** diagnosing an open problem where the options are not yet known (`consulting-problem-solving`), persuading a reader who has not accepted that a decision is due (`corporate-visions`), or exploring divergent futures rather than a present choice (`strategic-foresight`).

## Selection

**Best for:** make/buy/partner decisions, market-entry choices, sequencing and prioritization decisions, option papers for a board or steering committee.

**Signals:** content type `strategic-choice`, `options`, `decision` or `trade-off`; the source names two or more alternatives; it states or implies criteria; it weighs trade-offs; keywords such as "options", "alternatives", "criteria", "trade-off", "make or buy", "recommend", "versus".

**Anti-signals:** no alternative is named; the source argues for a single course as the only one; the futures are uncertain rather than the options.

**Fallback priority:** never a fallback. When the decision purpose is "choose between named alternatives", this arc outranks `corporate-visions` in the execution-fit step regardless of keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Context: The Decision Frame | Kontext: Der Entscheidungsrahmen |
| 2 | Tension: The Trade-offs That Matter | Spannungsfeld: Die entscheidenden Zielkonflikte |
| 3 | Options: The Strategic Alternatives | Optionen: Die strategischen Alternativen |
| 4 | Choice: The Recommended Path | Entscheidung: Der empfohlene Weg |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Context | 18% |
| Tension | 22% |
| Options | 35% |
| Choice | 25% |

**Executive TL;DR emphasis:** decision context → governing trade-offs → alternatives → recommended choice. The narrative opens with the TL;DR defined in `validation.md`; the recommendation belongs in its first sentence as the conclusion.

**Transitions:**

1. Context → Tension: "Within that frame, [N] trade-offs decide the outcome."
2. Tension → Options: "Against those criteria, [N] alternatives are credible."
3. Options → Choice: "One of them holds up better than the others."

**Closing pattern:** the recommendation, its principal trade-off, and — when uncertainty is material — the trigger that would reopen it: "Choose [X]; accept [trade-off]; revisit if [trigger]."

## Elements

### 1. Context

**Purpose:** frame the decision — what is being decided, by whom, by when, within which constraints, and why now.

**Evidence sought:** the research question, the decision owner and deadline where the sources carry them, constraints (budget, regulation, capacity) in the syntheses, forcing dates.

**Argument move:** state the decision in one sentence, then the constraints and the timing that bound it. Frame without prejudging: the context makes the tension legible, it does not tilt the options.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions) (why the decision is due now), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the decision is stated as a decision, not a topic; constraints are concrete; no option is favoured yet.

**Failure modes:** background with no decision; a frame that already names the winner; constraints left implicit.

### 2. Tension

**Purpose:** name the trade-offs that matter — the two to five criteria on which the options genuinely differ.

**Evidence sought:** tensions and contradictions in the syntheses, cost and speed figures, risk and reversibility considerations, stakeholder priorities in the executive summary.

**Argument move:** name each discriminating criterion, why it matters to this decision, and how the evidence lets it be assessed; order the criteria by weight and say why. Criteria on which every option scores alike are not tensions and are left out.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation) (the cost of the wrong choice).

**Hard rules:** two to five criteria; each discriminates between the options; the ordering is stated and justified.

**Failure modes:** a criteria list copied from a template; six or more criteria; a criterion on which every option scores the same.

### 3. Options

**Purpose:** present the genuinely distinct alternatives and evaluate each against the same criteria, fairly.

**Evidence sought:** the alternatives the sources name or imply, cost, timeline and risk evidence per alternative, comparable cases where the syntheses carry them.

**Argument move:** two to four options, each given its strongest form; for each, an IS-DOES-MEANS statement (what it is, what it delivers, why it holds or fails), then its assessment on every criterion from Tension with the evidence behind each rating. No option is weakened to make the preferred one obvious.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** two to four genuinely distinct options; every option evaluated on every criterion; each option presented at its strongest; the largest element.

**Failure modes:** a straw-man option; options evaluated on different criteria; five options where two are variants.

### 4. Choice

**Purpose:** recommend one option, state its principal trade-off, and name the trigger that would reopen the decision when uncertainty is material.

**Evidence sought:** the evaluations from Options, the weights from Tension, the reversibility and timing evidence in the syntheses.

**Argument move:** name the recommendation, show why it dominates on the weighted criteria, state the trade-off the reader accepts by choosing it, and — when the evidence is uncertain on a deciding criterion — name the observable trigger that would reverse the choice. Address the decision-maker directly.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Forcing Functions](techniques-overview.md#5-forcing-functions) (the decision deadline).

**Hard rules:** exactly one recommendation; its principal trade-off is stated; a reconsideration trigger is named when uncertainty is material; the close follows the closing pattern.

**Failure modes:** "it depends"; two recommendations; a trade-off hidden; a trigger that cannot be observed.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Context states the decision as a decision, with concrete constraints, and favours no option.
- Tension carries two to five discriminating criteria, ordered and justified.
- Options carries two to four genuinely distinct alternatives, each evaluated against the same criteria, none weakened to make the preferred answer obvious.
- Choice names one recommendation, its principal trade-off, and a reconsideration trigger when uncertainty is material.
- The chain holds: the criteria come from the context; the options are assessed on those criteria; the choice follows from the assessments.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-consulting-problem-solving.md` — when the answer must first be derived from an open problem
- `arc-strategic-foresight.md` — when the uncertainty is about the future, not the option
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
