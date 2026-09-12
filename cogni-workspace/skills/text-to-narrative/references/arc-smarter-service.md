---
arc_id: smarter-service
display_name: Smarter Service
display_name_de: Smarter Service
contract: 2
---

# Smarter Service

## Intent

**Governing question:** Which external forces reshape the landscape, how do they disrupt value creation, where do the investment themes position, and what shared foundations must be built first?

**Rhetorical job:** The theme-aware sibling of `trend-panorama`. Same four Smarter Service dimensions, same Act → Plan → Observe cascade, but each element is written as the macro spine under which investment themes from a `tips-value-model.json` anchor. Named after the Smarter Service Trendradar (Steimel, 2023), the four-dimension framework that structures the cogni-trends plugin; the arc makes that framework load-bearing in the narrative.

**Not for:** a trend landscape with no value model (`trend-panorama`), a single theme's investment thesis (`theme-thesis`), or a non-TIPS technology roadmap (`technology-futures`).

## Selection

**Best for:** CxO-level TIPS trend reports with investment themes, board-level foresight briefings where bets cluster across dimensions, multi-theme transformation roadmaps anchored in dimension forces.

**Signals:** structural, highest confidence — `tips-value-model.json` in the source or its `.metadata/`, or `tips-trend-report.md` with investment-theme sections; content type `smarter-service` or `investment-theme-report`; `research_type: smarter-service-themed`; keywords such as "investment theme", "Handlungsfeld", "value chain", "solution template", "Smarter Service", "Trendradar", "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament".

**Anti-signals:** only `trend-scout-output.json` and no value model (`trend-panorama`); a single theme's value chains (`theme-thesis`).

**Fallback priority:** never a fallback. When the value model is absent, fall back to `trend-panorama`.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them. Exactly four rows: the standalone narrative is four `##` sections.

| # | EN | DE |
|---|----|----|
| 1 | Forces: External Pressures & Market Signals | Kräfte: Externe Einflüsse & Marktsignale |
| 2 | Impact: Value Chain Disruption | Wirkung: Wertschöpfungsdynamik |
| 3 | Horizons: Strategic Possibilities | Horizonte: Strategische Möglichkeiten |
| 4 | Foundations: Capability Requirements | Fundamente: Kompetenzanforderungen |

Each element maps to one TIPS dimension: Forces = T (`externe-effekte`), Impact = I (`digitale-wertetreiber`), Horizons = P (`neue-horizonte`), Foundations = S (`digitales-fundament`).

**Synthesis-section boundary.** A multi-theme trend report may close on a separate cross-theme synthesis section ("The Capability Imperative" / "Der Fähigkeitsimperativ"). That section is a **consumer composition** owned by cogni-trends' `trend-report-composer`, not a fifth element of this arc: the narrative this contract governs is exactly four `##` sections, and its close synthesizes the capability path inside Foundations.

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Forces | 27% |
| Impact | 27% |
| Horizons | 27% |
| Foundations | 19% |

**Executive TL;DR emphasis:** the forces → impact → horizons → foundations cascade, anchored on the named investment themes. The narrative opens with the TL;DR defined in `validation.md`; the strategic question, the quantified cross-dimensional surprise and the number of themes that anchor in the dimensions belong in its first sentence as the conclusion.

**Trend-report scale.** cogni-trends consumes this arc at report scale — typically 4,000-8,000 prose words across its length tiers (`cogni-trends/skills/trend-synthesis/references/report-length-tiers.md`), with per-dimension narratives and nested theme cases composed by its own agents. The proportions above are the standalone-narrative shape; the composer applies its own per-dimension targets.

**Theme anchoring (the theme-aware twist).** Each investment theme from `tips-value-model.json` is anchored to **one** macro element — the dimension where its evidence is strongest — never duplicated across elements. The rule is deterministic and is enforced by the consuming skill:

1. **Anchor pole** = the TIPS dimension with the highest count of `candidate_ref` entries for that theme in the value model.
2. **Tiebreaker** = highest single-candidate composite score.
3. **Secondary poles** = one-line callouts in the relevant other macro sections ("→ See also Theme 2 in Foundations for the talent dependency"), never duplicate sub-sections.

Each theme therefore appears exactly once in the report's main flow, and the macro arc carries through cleanly. Theme cases nested inside a section receive no bridge paragraphs; the bridges between the four macro sections carry the arc.

**Horizon cascade inside every element:** lead with Act-horizon evidence, bridge with Plan, close with Observe — as in `trend-panorama`.

**Transitions:**

1. Forces → Impact: "These external forces translate into measurable disruption across the value chain."
2. Impact → Horizons: "Disruption creates openings. The strategic question shifts from 'how to defend' to 'where to position.'"
3. Horizons → Foundations: "Capturing these opportunities requires specific capabilities across culture, workforce, and technology."

**Closing pattern:** the capability imperative, inside Foundations — "Identifying trends is necessary but insufficient. These [N] investment themes share [M] foundation requirements. Without them, opportunities remain theoretical."

## Elements

### 1. Forces

**Purpose:** synthesize the T-dimension into the macro narrative of external forces reshaping the operating landscape across themes; anchored themes localize that story to specific bets.

**Evidence sought:** trend entities with `dimension: externe-effekte` (`trend_entities`), the T-section of an existing trend report, the cross-dimensional executive summary, the value chains of themes anchored to Forces.

**Argument move:** establish the macro force narrative first — the three or four forces that dominate, grouped by subcategory, led by the highest-confidence Act-horizon force → introduce each anchored theme as a localized response to those forces, deferring its persuasion to the theme case → show where economic pressure amplifies regulatory urgency and where societal expectation outruns regulation.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the macro narrative precedes any theme mention; each anchored theme is introduced once, as a response; the Act → Plan → Observe cascade is visible; force interactions are stated.

**Failure modes:** themes before forces; a theme's Why-Change argument restated in the dimension narrative; a trend list.

### 2. Impact

**Purpose:** synthesize the I-dimension into the narrative of how the forces translate into measurable disruption inside the value chain; anchored themes show which bets ride or defend against it.

**Evidence sought:** trend entities with `dimension: digitale-wertetreiber`, the I-section of an existing report, value chains of themes anchored to Impact.

**Argument move:** make the Forces → Impact chain explicit → cascade Act, Plan, Observe → present each anchored theme as a value-chain investment story ("this theme captures the impact we just established").

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Forcing Functions](techniques-overview.md#5-forcing-functions).

**Hard rules:** every impact names the force that causes it; disruption is quantified; anchored themes are tied to the impact, not to a generic opportunity.

**Failure modes:** implied causality; unquantified disruption; a theme anchored here that argues a Horizons story.

### 3. Horizons

**Purpose:** synthesize the P-dimension into the narrative of strategic possibilities the disruption creates; anchored themes name specific bets within those windows.

**Evidence sought:** trend entities with `dimension: neue-horizonte`, the P-section of an existing report, value chains of themes anchored to Horizons.

**Argument move:** reframe disruption as opening — first-mover windows, defensive moats, business-model pivots → cascade Act, Plan, Observe → present each anchored theme as a strategic-bet story inside its window.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** every opportunity traces to an impact and carries a timed window; anchored themes sit inside a named window.

**Failure modes:** opportunities floating free of the disruption; untimed windows; a theme that repeats macro context.

### 4. Foundations

**Purpose:** synthesize the S-dimension into the narrative of required capabilities — the foundations without which the horizons stay theoretical — and close on the capability imperative.

**Evidence sought:** trend entities with `dimension: digitales-fundament`, the S-section of an existing report, solution templates from `tips-value-model.json`, value chains of themes anchored to Foundations.

**Argument move:** connect opportunities to the capabilities that enable them, separating shared foundations from theme-specific ones → sequence dependencies (culture enables workforce, workforce enables technology) → present each anchored theme as a capability investment story → close by aggregating the foundation requirements the themes share.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Forcing Functions](techniques-overview.md#5-forcing-functions), [You-Phrasing](techniques-overview.md#7-you-phrasing).

**Hard rules:** capabilities are sequenced, never a flat menu; shared and theme-specific foundations are distinguished; the close aggregates across themes.

**Failure modes:** a capability menu; every foundation attributed to one theme; a close that restates the panorama.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Each investment theme appears exactly once in the main flow; anchoring follows the deterministic rule (dominant `candidate_ref` pole, composite-score tiebreaker); secondary poles are one-line callouts.
- Theme cases never restate macro Forces, Impact, Horizons or Foundations context — that lives in the dimension narratives once.
- Each element carries the Act → Plan → Observe cascade.
- The narrative is exactly four `##` sections; any cross-theme synthesis section is the consumer's composition, not this narrative's.
- The chain holds across dimensions and the close aggregates the foundations the themes share.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-trend-panorama.md` — the theme-less sibling with the same four elements
- `arc-theme-thesis.md` — the arc for a single theme's investment thesis inside a report built on this one
- `cogni-trends/skills/trend-synthesis/references/report-length-tiers.md` — the length tiers cogni-trends applies when it consumes this arc at report scale
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
