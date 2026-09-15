---
arc_id: competitive-intelligence
display_name: Competitive Intelligence
display_name_de: Wettbewerbsanalyse
contract: 2
---

# Competitive Intelligence

## Intent

**Governing question:** Where do the competitors stand, how is that changing, where are the gaps, and by when must we move?

**Rhetorical job:** Build an analytical case from the current landscape through the shifts reshaping it to a defensible position and a time-bound set of actions. It positions within a category that exists; it does not try to change the category.

**Not for:** reframing the buyer's category (`category-creation`), describing structural industry change beyond competition (`industry-transformation`), persuading a reader to change (`corporate-visions`), or exploring uncertainty with scenarios (`strategic-foresight`).

## Selection

**Best for:** competitive analysis, threat assessment, positioning studies, market-structure research.

**Signals:** the source names competitors, market shares, positions and moves; it tracks momentum (share trends, investment, M&A, partnerships); it identifies gaps or white spaces; it recommends time-bound moves.

**Anti-signals:** the source argues the category itself is wrong (`category-creation`); its forces are regulatory or structural rather than competitive (`industry-transformation`); it is a capability roadmap (`technology-futures`).

**Fallback priority:** never a fallback. Selected on content type `competitive` or on keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Landscape: Competitive Overview | Landschaft: Wettbewerbsübersicht |
| 2 | Shifts: Market Dynamics | Verschiebungen: Marktdynamik |
| 3 | Positioning: Strategic Options | Positionierung: Strategische Optionen |
| 4 | Implications: Action Priorities | Implikationen: Handlungsprioritäten |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Landscape | 27% |
| Shifts | 23% |
| Positioning | 30% |
| Implications | 20% |

**Executive TL;DR emphasis:** current landscape → competitive shift → defensible position → time-bound action. The narrative opens with the TL;DR defined in `validation.md`; the surprising competitive shift belongs in its first sentence as the conclusion.

**Transitions:**

1. Landscape → Shifts: "[N] momentum shifts are reshaping this landscape."
2. Shifts → Positioning: "These shifts create strategic gaps in [areas]."
3. Positioning → Implications: "Capturing these gaps requires time-bound action."

**Closing pattern:** a clear deadline for the competitive window — "Strategic gaps close by [quarter]. Organizations moving by [date] capture positions. Delay means competing for crowded spaces."

## Elements

### 1. Landscape

**Purpose:** map current competitive positions, market structure and established power dynamics.

**Evidence sought:** the competitive overview in the executive summary, market-structure analysis in the dimension syntheses, current-state indicators in trends, competitor entities when a `--content-map` supplies them.

**Argument move:** market structure (fragmented, concentrated, oligopoly) → current leaders and their share → the competitive bases each plays on (cost, differentiation, focus) → established moats. Move from aggregate share to segment-level detail; cluster competitors by the logic they compete on and tie each cluster to its business model.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure) (aggregate versus segment view).

**Hard rules:** the market structure is named; positions are quantified; competitive bases are mapped for the leaders.

**Failure modes:** a list of company names; share with no segment view; "highly competitive market".

### 2. Shifts

**Purpose:** identify the momentum changes, strategic moves and repositioning under way.

**Evidence sought:** Act-horizon trends carrying competitive moves, strategic-shift indicators in the executive summary, competitive dynamics in the syntheses.

**Argument move:** momentum indicators (share trends, investment patterns, growth-rate gaps) → strategic moves with timelines (M&A, partnerships, pivots) → capability races → emerging versus declining threats. Contrast a static top line with dynamic segment trajectories; name the shift in competitive logic.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** momentum is quantified; every strategic move carries a timeline; threats are assessed as emerging or declining.

**Failure modes:** "the market is consolidating" with no numbers; a move with no date; a threat list with no direction.

### 3. Positioning

**Purpose:** identify the strategic gaps, white spaces and positioning opportunities the landscape and the shifts open up.

**Evidence sought:** strategic recommendations, opportunity intersections in cross-cutting patterns, positioning insights in the executive summary.

**Argument move:** uncontested spaces (where competitors are not playing) → capability gaps (what they lack) → timing advantages (windows before they move) → differentiation axes (how to compete differently). Frame the strongest option as a position with IS-DOES-MEANS.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** at least one uncontested space is named; capability gaps are specific; every timing advantage is quantified as a window.

**Failure modes:** "differentiate through innovation"; gaps stated as competitors' adjectives; a window with no date.

### 4. Implications

**Purpose:** specify time-bound actions to exploit the gaps before they close or competitors fill them.

**Evidence sought:** action items in the recommendations, urgency indicators in trends, implementation timelines in the syntheses.

**Argument move:** immediate actions (0-6 months) → near-term moves (6-18 months) → capability building (18-36 months) → competitive response scenarios (what the competitors do when we move).

**Techniques:** [Compound Impact](techniques-overview.md#8-compound-impact-calculation) (cost of the window closing), [Forcing Functions](techniques-overview.md#5-forcing-functions).

**Hard rules:** every action sits in a time band; at least one competitive response scenario is considered; the element ends on the closing-window deadline.

**Failure modes:** actions with no horizon; no anticipation of competitor response; a generic "act now".

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Landscape names the market structure, quantifies positions and maps competitive bases.
- Shifts quantifies momentum, dates every strategic move and assesses threats as emerging or declining.
- Positioning names at least one uncontested space, specific capability gaps and quantified timing advantages.
- Implications places every action in a 0-6, 6-18 or 18-36 month band and considers at least one competitive response.
- The chain holds: the shifts are shifts in the landscape described; the gaps are the ones the shifts open; the actions capture those gaps before the stated deadline.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
