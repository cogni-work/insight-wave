---
arc_id: industry-transformation
display_name: Industry Transformation
display_name_de: Branchen-Transformation
contract: 2
---

# Industry Transformation

## Intent

**Governing question:** Which macro forces are restructuring the industry, what resists them, what does the industry become, and how does one lead in that new structure?

**Rhetorical job:** Explain a structural change and position the reader to lead in it. The arc moves from forces through friction to the new equilibrium and closes on leadership positioning — a tension-and-release pattern about an industry, not about one buyer's need.

**Not for:** competitive positioning within a stable category (`competitive-intelligence`), reframing the buyer's category (`category-creation`), persuading one reader to change (`corporate-visions`), or multi-scenario uncertainty (`strategic-foresight`).

## Selection

**Best for:** industry analysis, regulatory-impact studies, sector-transformation research, thought leadership on structural change.

**Signals:** the source names regulatory, technological, social or economic forces acting on a whole sector; it identifies barriers, incumbents or infrastructure slowing the change; it describes a future industry structure or business-model shift; it asks who leads.

**Anti-signals:** the forces are competitors' moves rather than macro forces (`competitive-intelligence`); the source argues for a new category rather than describing a transition (`category-creation`); it is one company's investment case (`corporate-visions`).

**Fallback priority:** never a fallback. Selected on content type `industry` or on keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Forces: Transformation Drivers | Kräfte: Makro-Treiber |
| 2 | Friction: Barriers to Change | Reibung: Widerstandspunkte |
| 3 | Evolution: Pathway Forward | Evolution: Strukturelle Veränderungen |
| 4 | Leadership: Strategic Imperatives | Führung: Positionierungsstrategien |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Forces | 27% |
| Friction | 23% |
| Evolution | 30% |
| Leadership | 20% |

**Executive TL;DR emphasis:** forces → friction → evolution → leadership move. The narrative opens with the TL;DR defined in `validation.md`; the quantified transformation indicator belongs in its first sentence as the conclusion.

**Transitions:**

1. Forces → Friction: "These forces encounter friction at [points]."
2. Friction → Evolution: "Despite friction, the industry evolves toward [new structure]."
3. Evolution → Leadership: "Leading in the transformed industry requires [positioning]."

**Closing pattern:** positioning for the new structure, not defending the old — "Industry transformation is inevitable. Leadership positioning is a strategic choice." or "The question isn't whether the industry transforms — it's who leads the transformed industry."

## Elements

### 1. Forces

**Purpose:** identify the macro forces — regulatory, technological, social, economic — driving the transformation.

**Evidence sought:** macro drivers (`megatrends_summary`, `megatrend_entities`), industry-level developments in trends, macro context in the executive summary.

**Argument move:** identify forces by category → size each by scope and horizon → show how forces reinforce or counteract each other → time their peak. Frame the forces as irreversible and unavoidable where the evidence supports it; quantify market coverage; show capital thresholds and timing mismatches as structural forces, not preferences.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** forces come from more than one category; each is quantified and timed; interactions between forces are explained.

**Failure modes:** "important trends"; one force; forces listed without magnitude or date.

### 2. Friction

**Purpose:** identify the barriers, resistance and distortions slowing the transformation.

**Evidence sought:** tensions and contradictions in cross-cutting patterns, adoption barriers in trends, implementation challenges in the syntheses, resistance factors in the executive summary.

**Argument move:** name each friction's source (incumbents, regulation, infrastructure, culture) → its magnitude → whether it is temporary or structural → the workaround. Show friction as timing mismatches, capital traps and geographic incompatibilities, and use forces language: friction forces specific responses.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Compound Impact](techniques-overview.md#8-compound-impact-calculation).

**Hard rules:** friction sources are identified; magnitude is assessed; a workaround or response is described for each.

**Failure modes:** friction as a complaint list; no magnitude; no way through.

### 3. Evolution

**Purpose:** describe the industry's future structure — the new equilibrium, business models and competitive dynamics.

**Evidence sought:** future-state vision in the recommendations, transformation direction in the executive summary, structural implications in the syntheses, emergent structures in cross-cutting patterns.

**Argument move:** describe how the industry organizes → who gains and loses power → how value creation changes → the timeline to the new equilibrium. Describe the new structure, not the current one plus a delta.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) (old structure versus new), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the new structure is described as a structure; power shifts are identified; a timeline to equilibrium is stated.

**Failure modes:** "the industry will continue to evolve"; a trend extrapolation with no structure; no winners and losers.

### 4. Leadership

**Purpose:** specify how to position for leadership in the transformed industry — thriving in the new structure, not surviving the change.

**Evidence sought:** strategic recommendations, leadership opportunities in the syntheses, positioning insights in the executive summary.

**Argument move:** where to play in the new structure → the sources of differentiation in the new equilibrium → when to commit resources → how to manage the transition from current to future. Frame the strongest position with IS-DOES-MEANS.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Compound Impact](techniques-overview.md#8-compound-impact-calculation).

**Hard rules:** positioning is for the new structure, never a defence of the old; differentiation sources are named in new-equilibrium terms; a transition strategy is specified.

**Failure modes:** "protect market share"; differentiation borrowed from the old structure; no transition path.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Forces spans more than one category, with each force quantified, timed and related to the others.
- Friction identifies sources, assesses magnitude and describes a response for each.
- Evolution describes a new structure with power shifts and a timeline to equilibrium.
- Leadership positions for the new structure with named differentiation and a transition strategy.
- The chain holds: the friction resists the forces named; the evolution is the outcome of forces against friction; the leadership move is positioned for that evolution.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
