---
arc_id: theme-thesis
display_name: Theme Thesis
display_name_de: Themen-These
contract: 2
---

# Theme Thesis

## Intent

**Governing question:** Why must this theme change how the reader thinks, why is the window closing now, which portfolio capabilities answer it, and what does inaction cost?

**Rhetorical job:** The Corporate Visions persuasion arc adapted to a single investment theme inside a multi-theme TIPS report. One theme carries two to six value chains — a trend (T), implications (I), possibilities (P) and foundation requirements (S) — and zero to four solution templates from the value modeler; the arc converts that evidence into an investment case a CxO can approve.

**Not for:** a whole-report persuasion narrative (`corporate-visions`), the report's macro spine (`smarter-service`), or a theme-less trend landscape (`trend-panorama`).

## Selection

**Best for:** individual theme sections within TIPS trend reports, investment-thesis narratives for strategic themes, CxO-level theme justification backed by portfolio solution templates.

**Signals:** content type `theme` or `investment-theme`; input carrying `theme_id`, `strategic_question` and `value_chains[]` with `candidate_ref` fields; `solution_templates[]` present (possibly empty); keywords such as "theme", "investment thesis", "value chain", "solution template", "strategic question", "candidate_ref", "chain_score".

**Anti-signals:** a whole landscape of trends with no theme boundary (`trend-panorama`, `smarter-service`); persuasion with no TIPS value chains (`corporate-visions`).

**Fallback priority:** never a fallback. Selected only on theme-level structural or content-type signals.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Why Change: The Unconsidered Need | Warum Veränderung: Der unberücksichtigte Bedarf |
| 2 | Why Now: The Closing Window | Warum jetzt: Das sich schließende Zeitfenster |
| 3 | Why You: The Portfolio Response | Warum Sie: Die Portfolio-Antwort |
| 4 | Why Pay: The Business Case | Geschäftliche Auswirkungen: Der Business Case |

**Message-driven assertions.** The headings above are the fixed section headers a standalone theme narrative emits. The message-driven sentence a CxO should get from a table of contents — the core reframe, the convergence date, the capability claim, the cost-of-inaction ratio — is the **opening assertion of each element's body**, written last from the finished section (see each element's Argument move). A consumer composing a multi-theme report may render its own thesis headings around the element bodies; that is the consumer's composition, exactly as `smarter-service`'s synthesis section is.

## Composition

Section lengths are proportions of `--target-length`. **Recommended length: 800-1,200 words** by theme complexity — a two-chain theme toward the low end, a five-chain theme toward the high end — so callers pass `--target-length` explicitly; the skill's own default stays 1,675 when the flag is omitted. Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Why Change | 27% |
| Why Now | 22% |
| Why You | 33% |
| Why Pay | 18% |

Why You is the largest element because the portfolio showcase — solution templates as strategic capabilities — is the theme section's core value; Why Now is narrower than in `corporate-visions` because theme-level urgency typically rests on two forcing functions rather than three.

**Executive TL;DR emphasis:** core reframe → why now → why this actor → payoff and cost of inaction. The narrative opens with the TL;DR defined in `validation.md`; the theme's strategic question and its quantified surprise belong in its first sentence as the conclusion.

**TIPS candidate mapping.** Unlike the panorama arcs, every element draws from all dimensions by rhetorical purpose: Why Change from T (the unconsidered need) and I (concrete value-chain impact); Why Now from Act-horizon candidates of any dimension; Why You from P (opportunity) plus solution templates (capabilities) plus S (durability); Why Pay from I (disruption cost) and S (capability-gap cost). A candidate may serve more than one element when it serves different purposes.

**Transitions:**

1. Why Change → Why Now: "The window for acting on this reframe is closing."
2. Why Now → Why You: "Meeting the deadline is a matter of capabilities the portfolio already carries."
3. Why You → Why Pay: "The cost of delay compounds."

**Closing pattern:** the cost-of-inaction ratio as a declarative sentence — "Delaying costs 3x more than acting — €6.9M against €2.3M over three years."

## Elements

### 1. Why Change

**Purpose:** reframe the theme's external trends as an unconsidered need — a problem or opportunity conventional thinking misses.

**Evidence sought:** the theme's T-candidates (`chain.trend`) and I-candidates (`chain.implications[]`), with their enriched evidence and implications.

**Argument move:** open with the reframe as an assertion (the "Y" of "most think X, evidence shows Y"), then PSB — the status-quo assumption and why it is incomplete, the reality the T- and I-evidence reveals, the advantage for early recognizers — ending on a competitive implication that hands over to urgency.

**Techniques:** [PSB](techniques-overview.md#2-psb-problem-solution-benefit), [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** the opening assertion contains a verb or a contrast and a specific number or named entity; the reframe is grounded in cited T- and I-evidence; the element ends with a competitive implication.

**Failure modes:** a topic label as the opening ("Intelligent grid optimization"); a trend list; a reframe the reader already holds.

### 2. Why Now

**Purpose:** establish urgency through forcing functions — deadlines, tipping points and regulatory pressure that make action on this theme time-sensitive.

**Evidence sought:** Act-horizon candidates across the theme's value chains, T-candidates with regulatory deadlines, claims carrying dates or growth rates; Plan-horizon candidates with the most urgent timelines when fewer than two Act-horizon candidates exist.

**Argument move:** open with the convergence point as an assertion (a date or number), then stack two forcing functions from different categories, each with a date and a quantified consequence, and close on the window statement — who gains by acting by the date, who pays by delaying past it.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (timeline math), [Contrast Structure](techniques-overview.md#6-contrast-structure).

**Hard rules:** two forcing functions from different categories; every function dated and quantified; an explicit window statement.

**Failure modes:** "soon"; one forcing function; urgency without a consequence.

### 3. Why You

**Purpose:** convert the theme's solution templates and possibilities into strategic capabilities of lasting value for the customer — the value modeler's output made actionable.

**Evidence sought:** the theme's solution templates (name, category, enabler type), P-candidates (`chain.possibilities[]`) for quantified outcomes, S-candidates (`chain.foundation_requirements[]`) for durability, with their enriched evidence.

**Argument move:** open with the strongest capability claim as an assertion, then one to three capabilities in IS-DOES-MEANS — IS a concrete definition from the template, DOES quantified outcomes in You-Phrasing from the P-evidence, MEANS the durability argument from the S-evidence (foundations that take time, expertise or maturity to build). Without solution templates, build the capabilities from P-candidates directly. Include the solution-template table inline after the prose when templates exist.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** written for the customer, never for an internal sales team — the phrase "strategic capability" and "competitive moat" language are avoided; advantages are framed as durable strategic value; every DOES layer is second person and quantified.

**Failure modes:** a solution catalogue; third-person DOES; moat language aimed at rivals rather than value aimed at the reader.

### 4. Why Pay

**Purpose:** quantify the cost of inaction for this theme so the investment case closes.

**Evidence sought:** I-candidates for disruption cost, S-candidates for capability-gap cost, claims with cost, revenue, penalty or investment figures, Act-horizon evidence for compounding over three years.

**Argument move:** open with the ratio as an assertion, then a compound calculation stacking three or four cost dimensions (regulatory or market-position loss, capability premium, disruption cost, opportunity cost) on one three-year horizon, each quantified and cited, set against the investment the capabilities require.

**Techniques:** [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** at least three cost dimensions on one horizon; every component quantified and cited; the closing sentence is the ratio.

**Failure modes:** a single cost; mixed horizons; a percentage where a ratio belongs.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Each element opens with a message-driven assertion carrying a verb or contrast and a specific number, date or named entity; no opening is a topic label.
- Why Change grounds its reframe in T- and I-evidence; Why Now stacks two dated, quantified forcing functions from different categories; Why You carries one to three capabilities in IS-DOES-MEANS written for the customer; Why Pay stacks at least three cost dimensions on one horizon and ends on the ratio.
- A candidate reused across elements serves a different rhetorical purpose in each.
- The chain holds: the reframe makes the window matter; the window makes the capabilities urgent; the capabilities make the ratio credible.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `arc-smarter-service.md` — the report spine a theme section sits inside
- `arc-corporate-visions.md` — the whole-report persuasion arc this one adapts
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
