---
arc_id: strategic-foresight
display_name: Strategic Foresight
display_name_de: Strategische Vorausschau
contract: 2
---

# Strategic Foresight

## Intent

**Governing question:** What weak signals point to divergent futures, what plausible scenarios follow, which strategies hold across them, and what must be decided now?

**Rhetorical job:** Turn genuine uncertainty into strategic options. The arc moves from early indicators through alternative futures to robust strategies and closes on near-term decisions — it argues for preparedness across futures, not for a prediction.

**Not for:** a single-future capability roadmap (`technology-futures`), choosing among already-credible options against fixed criteria (`strategic-choice`), describing one industry's structural transition (`industry-transformation`), or persuading a reader to change now (`corporate-visions`).

## Selection

**Best for:** long-range planning, scenario analysis, foresight studies, strategy under regulatory or technological uncertainty.

**Signals:** the source carries weak signals and early indicators; it treats the future as uncertain or contradictory; it sketches or invites alternative scenarios; it distinguishes robust moves from bets.

**Anti-signals:** the evidence converges on one future (`technology-futures`); the options are already named and the job is to choose (`strategic-choice`); the pressure is to act now on a known need (`corporate-visions`).

**Fallback priority:** never a fallback. Selected on content type `foresight` or `scenarios`, or on keyword density.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Signals: Early Indicators | Signale: Frühindikatoren |
| 2 | Scenarios: Future States | Szenarien: Zukunftsbilder |
| 3 | Strategies: Adaptive Approaches | Strategien: Adaptive Ansätze |
| 4 | Decisions: Action Framework | Entscheidungen: Handlungsrahmen |

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Signals | 23% |
| Scenarios | 30% |
| Strategies | 27% |
| Decisions | 20% |

**Executive TL;DR emphasis:** signal → uncertainty and scenario logic → robust strategy → near-term decision. The narrative opens with the TL;DR defined in `validation.md`; the fact that the signals point in different directions belongs in its first sentence as the conclusion.

**Transitions:**

1. Signals → Scenarios: "These signals combine into [N] plausible scenarios."
2. Scenarios → Strategies: "Robust strategies create value regardless of which scenario unfolds."
3. Strategies → Decisions: "Executing robust strategies requires near-term decisions about [areas]."

**Closing pattern:** decision-making under uncertainty, not prediction — "The goal isn't predicting which future arrives — it's building the capability to thrive in any of them."

## Elements

### 1. Signals

**Purpose:** identify weak signals and early indicators of potential futures — developments that are emerging but not yet mainstream.

**Evidence sought:** Watch-horizon trends (`trend_entities`), emerging or counterintuitive patterns in the executive summary, non-obvious connections in cross-cutting patterns.

**Argument move:** identify each signal at the edge → interpret what it could indicate, with its confidence → group signals into patterns (convergent, contradictory, reinforcing) → make the uncertainty dimensions explicit (what is genuinely unknown). Quantify directional change with timeframes; name bifurcations as divergence signals.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Forcing Functions](techniques-overview.md#5-forcing-functions).

**Hard rules:** several weak signals, not one strong trend; contradictory signals are acknowledged; the uncertainty dimensions are named explicitly.

**Failure modes:** strong trends restated as signals; a single direction; uncertainty asserted but never located.

### 2. Scenarios

**Purpose:** construct two or three plausible, distinct futures from how the signals and uncertainties could play out.

**Evidence sought:** trends across horizons, macro drivers (`megatrend_entities`), scenario drivers in cross-cutting patterns, future implications in the executive summary.

**Argument move:** choose two or three macro drivers as axes → combine their extremes into distinct futures → ground each future's plausibility in the drivers' horizon and scope → explore what each future means for the organization by mapping the signals into it. Each scenario is internally consistent and incompatible with the others.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** two or three scenarios, no more; each is plausible, not extreme; scenarios are differentiated futures, not variations of one; implications are explored per scenario.

**Failure modes:** best/base/worst variations of one future; a fourth scenario for symmetry; a scenario with no implication.

### 3. Strategies

**Purpose:** identify strategies that create value across the scenarios — actions that work whichever future unfolds.

**Evidence sought:** strategic recommendations, common threads in cross-cutting patterns, scenario-independent insights in the executive summary.

**Argument move:** robustness analysis (what works in every scenario) → flexibility building (what creates options) → scenario-specific hedges (insurance for one future) → no-regret moves. Frame the strongest robust strategy as a position with IS-DOES-MEANS.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** each strategy is tested against every scenario; no-regret moves are named; hedges are labelled as hedges, not as strategies.

**Failure modes:** strategies that only work in one future; "stay flexible" with no option named; a bet presented as robust.

### 4. Decisions

**Purpose:** specify the near-term decisions that position the organization to respond as uncertainty resolves.

**Evidence sought:** action items in the recommendations, decision points in trends, timing considerations in the syntheses.

**Argument move:** catalogue the choices available now → name the information triggers (which signal would indicate which decision) → assess reversibility → optimize timing (decide now versus wait, and until when).

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation) (cost of a late irreversible decision).

**Hard rules:** near-term choices are specified; every decision has a trigger; reversibility is assessed for each.

**Failure modes:** recommendations with no decision point; triggers absent; irreversible and reversible decisions treated alike.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Signals carries several weak signals, acknowledges contradiction and names the uncertainty dimensions.
- Scenarios carries two or three plausible, differentiated futures, each with its implications.
- Strategies distinguishes robust moves, no-regret moves and hedges, tested across every scenario.
- Decisions specifies near-term choices with triggers and reversibility.
- The chain holds: the scenarios are built from the signals named; the strategies are robust across those scenarios; the decisions execute those strategies.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
