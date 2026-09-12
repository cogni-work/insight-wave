---
arc_id: trend-panorama
display_name: Trend Panorama
display_name_de: Trend-Panorama
contract: 2
---

# Trend Panorama

## Intent

**Governing question:** Which external forces are reshaping the landscape, how do they disrupt value creation, what strategic possibilities open, and what capabilities are required?

**Rhetorical job:** Summarize a trend landscape into one flowing narrative along the four Smarter Service dimensions — Trends (T), Implications (I), Possibilities (P), Solutions (S) — with an Act → Plan → Observe urgency cascade inside each element. It is the theme-less TIPS arc: a panorama of the whole landscape, not a set of investment bets.

**Not for:** a TIPS report built on an investment-theme value model (`smarter-service`), a single theme's investment thesis (`theme-thesis`), or a non-TIPS technology roadmap (`technology-futures`).

## Selection

**Best for:** trend-scout output summaries, TIPS trend-report narratives without themes, multi-horizon trend landscape overviews, industry trend panoramas.

**Signals:** structural — `trend-scout-output.json` in the source or its `.metadata/`, or trend entities carrying `planning_horizon` and `dimension` frontmatter, with **no** `tips-value-model.json`; content type `trend`, `trends` or `tips`; keywords such as "trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension".

**Anti-signals:** `tips-value-model.json` present (`smarter-service`); a single theme with value chains (`theme-thesis`); no horizon or dimension structure in the source.

**Fallback priority:** never a fallback. The structural signal decides between this arc and `smarter-service` before any keyword analysis runs.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Forces: External Pressures & Market Signals | Kräfte: Externe Einflüsse & Marktsignale |
| 2 | Impact: Value Chain Disruption | Wirkung: Wertschöpfungsdynamik |
| 3 | Horizons: Strategic Possibilities | Horizonte: Strategische Möglichkeiten |
| 4 | Foundations: Capability Requirements | Fundamente: Kompetenzanforderungen |

Each element maps to one TIPS dimension: Forces = T (`externe-effekte`, Externe Effekte), Impact = I (`digitale-wertetreiber`, Digitale Wertetreiber), Horizons = P (`neue-horizonte`, Neue Horizonte), Foundations = S (`digitales-fundament`, Digitales Fundament).

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Forces | 27% |
| Impact | 27% |
| Horizons | 27% |
| Foundations | 19% |

**Executive TL;DR emphasis:** forces → impact → horizons → foundations. The narrative opens with the TL;DR defined in `validation.md`; the strategic question and the quantified cross-dimensional surprise — how many converging trends, how many demand action within 24 months — belong in its first sentence as the conclusion.

**Horizon cascade inside every element:** lead with Act-horizon evidence (0-2 years, signal levels 4-5 — what demands immediate response, roughly half the element), bridge with Plan-horizon evidence (2-5 years, levels 2-4 — what to build capability for, roughly a third), close with Observe-horizon evidence (5+ years, levels 1-2 — weak signals to monitor, the remainder). Synthesize clusters; never list individual trends.

**Transitions:**

1. Forces → Impact: "These external forces translate into measurable disruption across the value chain."
2. Impact → Horizons: "Disruption creates openings. The strategic question shifts from 'how to defend' to 'where to position.'"
3. Horizons → Foundations: "Capturing these opportunities requires specific capabilities across culture, workforce, and technology."

**Closing pattern:** the capability imperative, inside Foundations — "The trend panorama shows what's changing; the foundations show what to build first. Trends without foundations are strategic theatre."

## Elements

### 1. Forces

**Purpose:** synthesize the T-dimension into a narrative of external forces reshaping the landscape — economy, regulation and society, cascaded by horizon.

**Evidence sought:** trend entities with `dimension: externe-effekte` (`trend_entities`, `trends_summary`), the T-section of an existing trend report, cross-dimensional context from the executive summary.

**Argument move:** group the T-trends into economy, regulation and society → within each, cascade Act → Plan → Observe → show how the forces reinforce or counteract each other → size each force by trend score and confidence tier.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (the dominant force as an unconsidered need), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** all three subcategories appear; the Act → Plan → Observe cascade is visible; force interactions are stated; magnitudes carry scores or confidence tiers.

**Failure modes:** a trend list; horizons mixed or missing; forces named with no interaction.

### 2. Impact

**Purpose:** synthesize the I-dimension into a narrative of how the forces reshape value creation — customer experience, products and services, business processes.

**Evidence sought:** trend entities with `dimension: digitale-wertetreiber`, the I-section of an existing report, value-chain transformation patterns in the executive summary.

**Argument move:** make the Forces → Impact causal chain explicit → cascade Act (disruption under way), Plan (emerging value shifts), Observe (potential disruptions) → show how customer-experience change drives product evolution which forces process transformation → quantify disruption in revenue, cost structure and share.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) (before/after value chain), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Forcing Functions](techniques-overview.md#5-forcing-functions).

**Hard rules:** the force-to-impact chain is explicit for every impact; the cascade across the three subcategories is shown; disruption is quantified.

**Failure modes:** impacts asserted without the force that causes them; "significant disruption"; one subcategory only.

### 3. Horizons

**Purpose:** synthesize the P-dimension into a narrative of strategic possibilities — strategy, leadership and governance openings the disruption creates.

**Evidence sought:** trend entities with `dimension: neue-horizonte`, the P-section of an existing report, strategic-opportunity statements in the executive summary.

**Argument move:** connect impact to opportunity → cascade Act (seize now), Plan (build toward), Observe (position for) → differentiate strategy openings from leadership-model shifts from governance innovations → size each window by horizon timeline and confidence.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** every opportunity traces to an impact; windows are sized and timed; the three subcategories are distinguished.

**Failure modes:** opportunities with no window; "position for the future"; strategy and governance conflated.

### 4. Foundations

**Purpose:** synthesize the S-dimension into a narrative of required capabilities — culture, workforce and technology — in build order.

**Evidence sought:** trend entities with `dimension: digitales-fundament`, the S-section of an existing report, capability-building recommendations in the executive summary.

**Argument move:** connect the opportunities to the capabilities that enable them → cascade Act (build now), Plan (start developing), Observe (begin experimenting) → sequence dependencies (culture enables workforce, workforce enables technology) → quantify the readiness gap; close on the capability imperative.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Forcing Functions](techniques-overview.md#5-forcing-functions), [You-Phrasing](techniques-overview.md#7-you-phrasing).

**Hard rules:** capabilities are sequenced, never a flat menu; each names the horizon it must be built for; the readiness gap is quantified.

**Failure modes:** a capability menu; no build order; the close restates the panorama instead of the imperative.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Each element carries the Act → Plan → Observe cascade and covers its dimension's three subcategories.
- Horizon classifications match the source data.
- Forces states force interactions; Impact makes every force-to-impact chain explicit; Horizons times every window; Foundations sequences the capabilities.
- The chain holds across dimensions: the impacts follow from the forces, the horizons open from the impacts, the foundations enable the horizons.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-smarter-service.md` — the theme-aware sibling with the same four elements
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
