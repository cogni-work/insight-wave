---
arc_id: category-creation
display_name: Category Creation
display_name_de: Kategoriegestaltung
contract: 2
---

# Category Creation

## Intent

**Governing question:** Why does the old category no longer fit, what shift makes a new frame necessary, what is the new category, and what does leadership in it require?

**Rhetorical job:** Change the buyer's frame of reference. The arc represents the existing category fairly, evidences the shift that breaks it, proposes the new frame and closes on what defines leadership in it. It argues for a new way of seeing the market, not for a position inside the old one.

**Not for:** positioning within a category that stays stable (`competitive-intelligence`), describing structural industry change without proposing a new frame (`industry-transformation`), or persuading one buyer to change inside the existing frame (`corporate-visions`).

## Selection

**Best for:** market-reframe narratives, category-design papers, thought leadership that names a new category, positioning for a company that does not fit the existing frame.

**Signals:** content type `category-creation`, `category-design`, `market-reframe` or `new-category`; the source argues the existing category mis-describes the buyer's problem; it names a shift with evidence; it proposes or implies a new frame or name; keywords such as "category", "reframe", "the old model", "a new class of", "redefine".

**Anti-signals:** competitors and shares within an accepted category; structural forces on a sector with no new frame proposed; a diagnostic memo.

**Fallback priority:** never a fallback. Selected on content type or the reframe signals.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Status Quo: The Existing Category | Status Quo: Die bestehende Kategorie |
| 2 | Shift: What Breaks the Old Frame | Verschiebung: Was den alten Bezugsrahmen bricht |
| 3 | New Frame: The Category That Fits the New Reality | Neuer Bezugsrahmen: Die Kategorie für die neue Realität |
| 4 | Leadership: What Defines the Category Leader | Führungsanspruch: Was Kategorie-Führung ausmacht |

## Composition

Section lengths are proportions of `--target-length`. **Recommended length: 1,500 words** — a reframe argument loses force when it sprawls — so callers pass `--target-length 1500`; the skill's own default stays 1,675 when the flag is omitted. Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Status Quo | 20% |
| Shift | 25% |
| New Frame | 35% |
| Leadership | 20% |

**Executive TL;DR emphasis:** existing category → frame-breaking shift → new category logic → leadership criteria. The narrative opens with the TL;DR defined in `validation.md`; the new frame belongs in its first sentence as the conclusion.

**Transitions:**

1. Status Quo → Shift: "That category described the market well — until [shift]."
2. Shift → New Frame: "A market that behaves this way needs a different name for what it buys."
3. New Frame → Leadership: "If that is the category, leading it means something specific."

**Closing pattern:** the leadership criteria as a test the reader can apply — "The category leader is whoever [criterion] first" — with the proof-versus-aspiration line drawn.

## Elements

### 1. Status Quo

**Purpose:** represent the existing category fairly — how the market currently names, buys and evaluates, and why that made sense.

**Evidence sought:** the market description and competitive landscape in the sources, buyer language and evaluation criteria, the history that produced the existing category.

**Argument move:** describe the existing category as its adherents would: what it groups, what it optimizes for, why it served. The reader must recognize their own frame before it is questioned; a straw-man status quo forfeits the argument.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) (set up, not yet sprung), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the existing category is represented fairly, in the market's own terms; its strengths are acknowledged; no reframe yet.

**Failure modes:** a caricature of the old frame; the new frame smuggled in early; a status quo the reader would not recognize.

### 2. Shift

**Purpose:** evidence the shift that breaks the old frame — the changes that make the existing category mis-describe what buyers now need.

**Evidence sought:** trends and forcing dates, buyer-behaviour changes, technology or regulatory shifts in the syntheses, at least two independent signals.

**Argument move:** name the shift, then evidence it with at least two independent, cited signals; show precisely where the old category's assumptions fail under the shift; where the shift carries a deadline or a tipping point, name it.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (the Problem leg), [Forcing Functions](techniques-overview.md#5-forcing-functions), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** at least two evidence-backed signals, independent of each other; each signal is tied to the specific assumption of the old frame it breaks.

**Failure modes:** one signal stretched; signals that do not touch the old frame's assumptions; a shift asserted with no evidence.

### 3. New Frame

**Purpose:** propose the category that fits the new reality — its logic, its boundaries, what it groups and what it excludes.

**Evidence sought:** the strategic recommendations, positioning insights, the buyer needs the shift exposed, portfolio propositions when a `--content-map` supplies them.

**Argument move:** name the new category and its governing logic, define what belongs inside and outside it, show how it resolves the failures Shift exposed, and give the category's core offer IS-DOES-MEANS shape. Label the category name as interpretation unless it is externally established.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit) (Solution and Benefit legs), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [Contrast Structure](techniques-overview.md#6-contrast-structure) (old frame versus new).

**Hard rules:** the category name is labelled interpretation unless externally established; boundaries are stated; every failure named in Shift is resolved or explicitly left open; the largest element.

**Failure modes:** a product renamed as a category; a category with no boundary; a name presented as established fact.

### 4. Leadership

**Purpose:** state what defines the category leader — the criteria, separating what is proven from what is aspired to.

**Evidence sought:** evidence of who already meets the criteria, capability and track-record data in the sources, the reader's own position where the material supplies it.

**Argument move:** derive the leadership criteria from the new frame's logic, show for each whether it is already proven (by whom, with what evidence) or aspirational, and address the reader with what leading would require of them.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** proof and aspiration are separated for every criterion; the criteria derive from the new frame; the close is a test the reader can apply.

**Failure modes:** the writer's company declared leader by assertion; criteria unrelated to the frame; aspiration presented as proof.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Status Quo represents the existing category fairly, in the market's own terms.
- Shift carries at least two independent, evidence-backed signals, each tied to an assumption of the old frame.
- The category name is labelled interpretation unless externally established, and the new frame's boundaries are stated.
- Leadership separates proof from aspiration for every criterion.
- The chain holds: the shift breaks the frame described; the new frame resolves the failures the shift exposed; the leadership criteria derive from the new frame.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-competitive-intelligence.md` — when the category is stable and the job is to position within it
- `arc-industry-transformation.md` — when the job is to describe structural change, not to propose a frame
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
