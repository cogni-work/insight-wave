---
arc_id: company-credo
display_name: Company Credo
display_name_de: Unternehmens-Credo
contract: 2
---

# Company Credo

## Intent

**Governing question:** Why does this company exist, what does it believe that others do not, why should the reader trust that, and what can the reader expect?

**Rhetorical job:** Build a belief-driven argument for an About page: the company states what it believes, backs it with receipts, and closes with a forward commitment. It is first-person where every other arc avoids it, and it argues by judgment rather than by capability.

**Not for:** describing how an engagement runs (`engagement-model`), presenting a solution portfolio (`jtbd-portfolio`), selling a change (`corporate-visions`), or proving a customer's outcome (`customer-transformation`).

## Selection

**Best for:** About-Us pages, company introductions, brand-identity narratives, the `about` scope of cogni-portfolio's customer narrative.

**Signals:** content type `company-credo` or `about-us`; the source is a company description, positioning statement, mission or the recurring MEANS themes of a portfolio; keywords such as "about us", "our mission", "why we exist", "what we believe", "who we are".

**Anti-signals:** the source is a delivery process (`engagement-model`); it lists solutions for buyer jobs (`jtbd-portfolio`); it is research about a market rather than about the company.

**Fallback priority:** never a fallback. Selected only on content type or company-identity signals.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Mission: Why We Exist | Mission: Warum es uns gibt |
| 2 | Conviction: What We Believe | Überzeugung: Woran wir glauben |
| 3 | Credibility: How You Can Trust Us | Glaubwürdigkeit: Warum Sie uns vertrauen können |
| 4 | Promise: What You Can Expect | Versprechen: Was Sie erwarten können |

## Composition

Section lengths are proportions of `--target-length`. **Recommended length: 1,400 words** — About pages are skimmed before a buyer digs into capabilities — so callers pass `--target-length 1400`; the skill's own default stays 1,675 when the flag is omitted. Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Mission | 27% |
| Conviction | 24% |
| Credibility | 29% |
| Promise | 20% |

**Executive TL;DR emphasis:** mission → conviction → credibility → promise. The narrative opens with the TL;DR defined in `validation.md`; the observation about the buyer's world that makes the company necessary belongs in its first sentence as the conclusion.

**Transitions:**

1. Mission → Conviction: "A mission like that only works if you hold a few things as non-negotiable."
2. Conviction → Credibility: "Convictions are cheap. Here is what we can show for them."
3. Credibility → Promise: "If any of this resonates, here is what working with us actually looks like."

**Closing pattern:** one invitation naming the next page by its buyer-facing function, never a URL and never "contact us" — "If you want to see what we actually do for your role, the capabilities page is where to go next."

## Elements

### 1. Mission

**Purpose:** answer the buyer's first unasked question — why this company exists — by naming the problem the company takes personally and refuses to accept as normal.

**Evidence sought:** the company description, positioning and mission in the portfolio manifest; the recurring verb across proposition MEANS statements (a theme in four or more propositions is part of the mission); the industry problem in the market context.

**Argument move:** find the recurring verb in the MEANS statements → name the problem the company refuses to accept → state the company's theory of why the problem persists and why it is placed to change that. First-person plural throughout: this is the one element in the suite where "we" is required.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) ("The industry treats X as fixed. We don't."), [Forcing Functions](techniques-overview.md#5-forcing-functions) (why the mission is urgent now).

**Hard rules:** first-person plural; no products, features or services — a belief, not a catalogue; the mission takes a position no competitor could sign unchanged.

**Failure modes:** a service list with "we"; a company history; a paragraph every company in the industry could publish.

### 2. Conviction

**Purpose:** translate the mission into three or four non-negotiable convictions that shape how the company designs, sells and delivers — the judgment the buyer is actually evaluating.

**Evidence sought:** recurring themes in proposition evidence arrays, differentiation claims against competitors (reverse-engineer the belief behind each), MEANS themes outside the mission, any named methodology or principle in the positioning.

**Argument move:** extract three or four convictions, each opening with a verb of belief ("We believe…", "We refuse…", "We insist…"; in German "Wir glauben…", "Wir weigern uns…") → apply the Disagreement Test to each → bind each to the consequence the buyer sees ("We believe X → which is why you will see Y when you work with us").

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [You-Phrasing](techniques-overview.md#7-you-phrasing) in the consequence half.

**Hard rules:** three or four convictions; each passes the Disagreement Test — a named competitor's CMO could put the opposite claim on their own About page; each pairs a belief sentence with a buyer-visible consequence; no generic corporate values ("we value integrity", "we put customers first").

**Failure modes:** a values wall of six; "we value customer success"; a belief with no consequence.

### 3. Credibility

**Purpose:** give the buyer permission to believe the mission and convictions by showing receipts.

**Evidence sought:** proposition evidence arrays (verified external claims), named accounts and testimonials in customer entities, verified claims in the claims store (`cogni-claims/claims.json`, status verified), certifications, partnerships and awards in the portfolio context.

**Argument move:** pick four to six items across the dimensions the buyer weighs — track record, external validation, recognizable logos (with permission), quantified outcomes, verifiable expertise — group them by dimension so they scan, and cite every number. Specific quantities beat round ones; third-party sources beat self-report.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques), [Contrast Structure](techniques-overview.md#6-contrast-structure) (claim versus proof).

**Hard rules:** at least four items across at least two dimensions; every quantitative claim cited; named accounts only with an explicit permission marker in the customer entity — otherwise describe, never name; nothing older than three years without a still-applies qualifier; no "trusted by industry leaders" without names or numbers.

**Failure modes:** logos only; uncited numbers; credibility inflation; a stale award presented as current.

### 4. Promise

**Purpose:** state in plain language what the buyer will experience if they work with the company — the handshake that makes the rest of the site a coherent offer.

**Evidence sought:** cross-cutting engagement patterns across solutions, product maturity distribution (commit only to `standard`, `launch` or `preview` products), buyer-facing DOES language in the propositions.

**Argument move:** identify three things the buyer experiences consistently whatever capability they hire → phrase each as a direct commitment ("You will…" / "Sie werden…") → end on one concrete invitation to the next page.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions) (the DOES layer as the promise).

**Hard rules:** exactly three promise items, every one second person; each holds across the current portfolio, not for one product; nothing depends on an `announce`-mode product; the final invitation is one link or call to action, never a menu.

**Failure modes:** a capability claim dressed as a promise; a roadmap item promised as current; "contact us"; hedged commitments.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Mission is first-person plural, lists no product or service, and takes a position competitors could not sign.
- Every Conviction passes the mandatory **Disagreement Test** — it is something at least one serious, named competitor plausibly does not believe — and pairs its belief with a buyer-visible consequence. A conviction every company would nod at is rewritten or cut.
- Credibility carries at least four items across at least two dimensions, every quantitative claim cited, named accounts only with permission, nothing older than three years unqualified.
- Promise carries exactly three You-phrased items true across the portfolio, none dependent on an `announce`-mode product, and one invitation to a specific next page.
- The chain holds: the convictions trace to the mission; the credibility backs those convictions specifically; the promise is consistent with the portfolio's actual maturity.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
