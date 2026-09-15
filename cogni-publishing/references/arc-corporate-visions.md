---
arc_id: corporate-visions
display_name: Corporate Visions
display_name_de: Corporate Visions
contract: 2
---

# Corporate Visions

## Intent

**Governing question:** Why should the reader change, why now, why with this capability, and why does it pay?

**Rhetorical job:** Persuade a decision-maker to leave a status quo that feels good enough. The arc moves from an unconsidered need through external urgency to a defensible position and closes on an undeniable business case. It is a sales-persuasion arc: it argues for a change and an investment.

**Not for:** diagnosing an open problem and deriving the answer (use `consulting-problem-solving`), choosing among already-credible alternatives (`strategic-choice`), proving observed customer value (`customer-transformation`), or an investment-theme thesis inside a TIPS report (`theme-thesis`). When the reader has not yet accepted that a change is needed, this is the arc; when they have, a diagnostic or choice arc serves them better.

## Selection

**Best for:** market research syntheses, competitive positioning, sales enablement content, B2B value-proposition development, executive decision support.

**Signals:** the source frames a problem executives underestimate; it carries deadlines, regulatory dates or tipping points; it recommends capabilities or positions; it quantifies costs, risks or penalties.

**Anti-signals:** the source is a documented customer journey with verified outcomes; it weighs named alternatives against criteria; it describes a solution portfolio for buyers who already want it (`jtbd-portfolio`); it is a company self-description (`company-credo`, `engagement-model`).

**Fallback priority:** the default *candidate* when no specialized content type is detected — a candidate for the shortlist, never an automatic winner. The registry's `distinguish_from` block names the arcs it must be weighed against.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE | FR | IT | PL | NL | ES |
|---|----|----|----|----|----|----|----|
| 1 | Why Change: Unconsidered Needs | Warum Wandel: Unerkannte Handlungsbedarfe | Pourquoi changer : besoins insoupçonnés | Perché cambiare: bisogni latenti | Dlaczego zmiana: nieuświadomione potrzeby | Waarom veranderen: onopgemerkte behoeften | Por qué cambiar: necesidades no consideradas |
| 2 | Why Now: Forcing Functions | Warum Jetzt: Handlungsdruck | Pourquoi maintenant : facteurs déclencheurs | Perché ora: fattori scatenanti | Dlaczego teraz: czynniki wymuszające | Waarom nu: dwingende factoren | Por qué ahora: factores determinantes |
| 3 | Why You: Unique Positioning | Warum Sie: Einzigartige Positionierung | Pourquoi vous : positionnement unique | Perché Lei: posizionamento unico | Dlaczego Państwo: wyjątkowe pozycjonowanie | Waarom u: unieke positionering | Por qué usted: posicionamiento único |
| 4 | Why Pay: ROI Justification | Warum Investieren: ROI-Begründung | Pourquoi investir : justification du ROI | Perché investire: giustificazione del ROI | Dlaczego inwestować: uzasadnienie ROI | Waarom investeren: ROI-onderbouwing | Por qué invertir: justificación del ROI |

The narrative skill generates EN and DE. The five further columns are the substitution set the copywriter uses in arc-mode translation; they are carried here because this contract is the one authority for the arc's headings.

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Why Change | 30% |
| Why Now | 23% |
| Why You | 30% |
| Why Pay | 17% |

**Executive TL;DR emphasis:** unconsidered need → urgency → fit → business case. The narrative opens with the TL;DR defined in `validation.md`; the most surprising quantified finding belongs in its first sentence as the conclusion, not as a teaser.

**Transitions:**

1. Why Change → Why Now: "Three converging forces make action urgent."
2. Why Now → Why You: "Organizations that thrive don't just react — they build capabilities."
3. Why You → Why Pay: "The cost of delay compounds."

**Closing pattern:** one simple, undeniable comparison — "Action costs less than inaction by 2-3x", "The choice: invest €1.2M strategically, or lose €3.1M reactively." Never a percentage, never a paragraph.

## Elements

### 1. Why Change

**Purpose:** reframe the findings as an unconsidered need — a problem the reader did not know they had, or did not realize was solvable.

**Evidence sought:** the executive summary and cross-cutting patterns (`executive_summary`, `dimension_syntheses`), paradigm shifts (`megatrends_summary`), counterintuitive findings and tensions. Use whatever source material was loaded in Phase 1; no fixed directory layout is assumed.

**Argument move:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) — Problem (~33% of the element: the status quo assumption and why it is incomplete), Solution (~33%: the unconsidered reality the evidence reveals — a reframing of the problem space, not a product pitch), Benefit (the remainder: the advantage for early recognizers, ending on a forward implication that hands over to urgency). Choose one reframe shape and commit to it: inverse correlation, hidden variable, category error, optimization paradox or temporal reframe.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the Problem half opens with a contrast ("Most organizations think X. But the evidence shows Y."); two or three citations ground the reframe; the element ends with a competitive implication, not a summary.

**Failure modes:** stating an obvious problem ("organizations need to adopt AI"); academic framing ("our analysis reveals"); a reframe the reader already believes — if the section does not make the reader uncomfortable about a current assumption, the need is not unconsidered enough; PSB with a missing leg.

### 2. Why Now

**Purpose:** establish urgency through forcing functions — external pressures, deadlines and tipping points that make action time-sensitive.

**Evidence sought:** trend entities with an Act horizon (`trend_entities`, `trends_summary`), regulatory dates and timelines in the sources, urgency indicators in the executive summary. Megatrends are macro context here, not forcing functions.

**Argument move:** stack two or three forcing functions, each an external pressure with a specific deadline and a quantified consequence, then a window-of-opportunity contrast between early movers and late starters. Draw the functions from distinct categories — regulatory, talent, market expectation, technology tipping point, competitive momentum — so the urgency reads as structural rather than incidental.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (timeline math, before/after), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** every forcing function carries a specific date or quarter and a quantified consequence; at least two functions are stacked; the element closes with a window-closing statement. This element carries the densest citation load in the narrative.

**Failure modes:** vague urgency ("the market is changing rapidly", "soon"); a single forcing function; consequences without numbers ("there will be penalties"); no closing window.

### 3. Why You

**Purpose:** convert strategic recommendations into Power Positions — capabilities that create advantage and are hard to replicate.

**Evidence sought:** strategic recommendations, strategic implications in the dimension syntheses, positioning opportunities in the executive summary, portfolio propositions when a `--content-map` supplies them.

**Argument move:** two or three Power Positions, each in IS-DOES-MEANS order: IS names the capability concretely in one or two sentences; DOES states what it does for the reader in You-Phrasing with quantified outcomes; MEANS explains why competitors struggle to copy it — time, tacit knowledge, integration complexity. Positions may be process, governance, capability-building, partnership or culture positions; pick the mix the evidence supports.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** each position is named; every DOES layer is second person and carries at least one quantified outcome; every MEANS layer names the moat. Feature lists are forbidden — if a position starts listing features, collapse it into one IS sentence.

**Failure modes:** generic advice ("invest in training"); third-person DOES ("organizations reduce…"); an IS that is a buzzword ("a comprehensive approach to AI adoption"); weak differentiation ("be good at this").

### 4. Why Pay

**Purpose:** quantify the cost of inaction so the business case becomes undeniable.

**Evidence sought:** risk and cost figures in the cross-cutting patterns, cost implications in trend entities, investment requirements in the recommendations, financial impacts in the executive summary.

**Argument move:** a compound impact calculation — stack three or four cost dimensions (regulatory penalties, talent premium, market-position loss, opportunity cost, or whichever the evidence supplies) on one three-year horizon, each with a number and a citation, then reduce the whole case to one ratio: "Action costs less than inaction by N-Mx."

**Techniques:** [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (ratio framing, before/after).

**Hard rules:** at least three cost dimensions; one time horizon throughout; every component quantified and cited; the final sentence is a simple ratio, not a percentage.

**Failure modes:** a single cost factor; mixed horizons ("two years here, five years there"); "significant savings"; a closing comparison that needs explanation.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Why Change carries all three PSB legs and opens with a contrast.
- Why Now stacks at least two forcing functions, each with a date and a quantified consequence, and closes on a window-closing statement.
- Why You carries two or three named Power Positions in IS-DOES-MEANS order with second-person DOES layers.
- Why Pay stacks at least three cost dimensions on one horizon and ends on a simple ratio.
- The rhetorical chain holds: the TL;DR's conclusion is the one the four elements earn; the need makes the forcing functions feel inevitable; the urgency makes the reader want the positions; the positions make the cost comparison feel like a conclusion.
- The closing sentence of the fourth element is the ratio; nothing follows it inside the element — the `**Sources**` block that comes after is a register, not prose.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
