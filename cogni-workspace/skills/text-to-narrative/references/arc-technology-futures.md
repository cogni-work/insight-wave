---
arc_id: technology-futures
display_name: Technology Futures
display_name_de: Technologie-Zukunft
contract: 2
---

# Technology Futures

## Intent

**Governing question:** Which capabilities are reaching practical maturity, how do they combine, what do the combinations make possible, and what must be in place to capture it?

**Rhetorical job:** Move a reader from a catalogue of technologies to a decision about capability building. The arc moves from emergence through convergence to opportunity and closes on prerequisites and sequencing — a progression in time, from what exists now to what must be built.

**Not for:** persuading a reader to change a status quo (`corporate-visions`), describing an industry's structural change (`industry-transformation`), weighing named strategic options against criteria (`strategic-choice`), or exploring divergent futures under uncertainty (`strategic-foresight`).

## Selection

**Best for:** innovation and R&D syntheses, technology-trend research, capability roadmapping, technology-scouting reports.

**Signals:** the source names emerging technologies and their maturity; it shows technologies combining; it derives applications or use cases from those combinations; it names capability gaps, infrastructure, partnerships or investments.

**Anti-signals:** the source is about competitive positions rather than capabilities (`competitive-intelligence`); it argues for a purchase or investment case (`corporate-visions`); it is a multi-scenario foresight exercise (`strategic-foresight`).

**Fallback priority:** never a fallback. Selected on content type `technology` or on keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | What's Emerging: Technology Horizon | Was Entsteht: Technologie-Horizont |
| 2 | What's Converging: Integration Points | Was Konvergiert: Integrationspunkte |
| 3 | What's Possible: Application Scenarios | Was Möglich Ist: Anwendungsszenarien |
| 4 | What's Required: Capability Development | Was Erforderlich Ist: Kompetenzentwicklung |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| What's Emerging | 27% |
| What's Converging | 27% |
| What's Possible | 27% |
| What's Required | 19% |

**Executive TL;DR emphasis:** emerging capability → convergence → unlocked opportunity → prerequisite. The narrative opens with the TL;DR defined in `validation.md`; the surprising convergence or capability leap belongs in its first sentence as the conclusion.

**Transitions:**

1. What's Emerging → What's Converging: "These capabilities combine in [N] convergence patterns."
2. What's Converging → What's Possible: "Convergence unlocks opportunities across [domains]."
3. What's Possible → What's Required: "Capturing these opportunities requires [category] capabilities."

**Closing pattern:** a call to action on capability building or the opportunity window — "Organizations building [prerequisite] now capture [window]. Late starters compete for commoditized applications." or "The convergence window is [timeframe]. Required capabilities take [build time]. Start by [date]."

## Elements

### 1. What's Emerging

**Purpose:** identify emerging capabilities that are reaching practical maturity — moving from lab to market, prototype to product, theoretical to deployable.

**Evidence sought:** trend entities on the Watch and Act horizons (`trend_entities`), capability definitions (`domain_concepts`, maturity markers), emerging-technology mentions in the executive summary.

**Argument move:** for each capability — a maturity indicator (the evidence that it is deployable, not hype), what it can actually do, a readiness timeline, and early-adopter evidence with results. Quantify the improvement each capability delivers.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) (mature versus hyped), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** every capability carries a maturity signal and a timeline from the evidence; capability improvements are quantified; theoretical or purely speculative technologies are excluded.

**Failure modes:** a technology tour with no maturity discrimination; "revolutionary" without a deployment; timelines of "soon".

### 2. What's Converging

**Purpose:** identify where emerging technologies combine into capabilities greater than the sum of their parts.

**Evidence sought:** cross-cutting patterns and technology intersections in the dimension syntheses, trends showing co-evolving technologies, interdisciplinary developments.

**Argument move:** for each convergence point — which technologies combine, the synergy mechanism (why the combination is worth more than the parts), the unlock effect (what becomes possible only through the combination) and the adoption catalyst (why now, not earlier or later).

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** effects are shown as multiplicative, not additive; each convergence names its unique unlock; timing is explained with evidence of acceleration.

**Failure modes:** listing technologies side by side and calling it convergence; a synergy asserted without a mechanism; no answer to "why now".

### 3. What's Possible

**Purpose:** articulate the specific opportunities, applications and value-creation scenarios the emerged and converged technologies make feasible.

**Evidence sought:** strategic recommendations, opportunity statements in the executive summary, application scenarios in the dimension syntheses, opportunity implications in trends.

**Argument move:** for each opportunity — the concrete application or use case, the business value it unlocks, the advantage window and what capturing it requires; state the competitive positioning implication.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions) for the strongest opportunity, [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** scenarios are concrete, not abstract; value potential is quantified; every opportunity window carries a timeline.

**Failure modes:** "significant opportunities across industries"; value with no number; an opportunity with no window.

### 4. What's Required

**Purpose:** specify the concrete prerequisites — capabilities, infrastructure, partnerships, investments — needed to capture the opportunities.

**Evidence sought:** implementation requirements in the recommendations, capability gaps in the syntheses, readiness factors in the executive summary, adoption barriers and enablers in trends.

**Argument move:** for each requirement — its type (infrastructure, capability, partnership, investment), the readiness gap between current and required state, the build timeline, and its place in the sequence (what enables what); state make, buy or partner where the evidence allows.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation).

**Hard rules:** requirements are specific and actionable, never "build capabilities"; every requirement has a build timeline; sequencing logic is explicit.

**Failure modes:** a wish list; requirements with no timeline; no dependency order.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Every emerging capability carries a maturity signal and a timeline; none is speculative.
- Every convergence names its multiplicative unlock and its adoption catalyst.
- Every opportunity is a concrete scenario with a quantified value and a window.
- Every requirement is typed, timed and sequenced.
- The chain holds: the capabilities are the ones that converge; the convergences are the ones that unlock the opportunities; the requirements are the ones those opportunities need.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
