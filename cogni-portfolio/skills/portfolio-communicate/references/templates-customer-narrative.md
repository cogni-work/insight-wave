# Templates: Customer Narrative

Output templates for the `customer-narrative` use case. These templates produce the **main components of a portfolio-driven website** from the buyer's perspective — each file is arc-structured and carries an `arc_id` in its YAML frontmatter so that `text-to-narrative` can build a Claude Design brief (web, slides, document or infographic) from it under the same arc — pass the frontmatter's `arc_id` as `--arc-id`.

**Use case**: `customer-narrative`
**Audience**: Buyers, executives, decision-makers navigating a portfolio-driven website
**Voice**: Company speaks to buyer ("we"/"you"). Professional but conversational — pages feel authored, not generated.

## The website component model

A portfolio-driven website — from the buyer's perspective — has these main components. Each corresponds to a scope in this use case and is driven by a specific `text-to-narrative` arc contract:

| Scope | Output file | Component | Arc | Why this arc |
|---|---|---|---|---|
| `home` | `home.md` | Home page (what we do, for whom, why it matters) | `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation mirrors how buyers enter a website: "what problem does this solve, does it solve mine, how do I start?" |
| `about` | `about.md` | About Us page (who we are, why we exist, what we believe) | `company-credo` | Mission → Conviction → Credibility → Promise answers the unasked first question: "why should I trust this company before I evaluate any specific offering?" |
| `capability` | `capabilities/{feature-slug}.md` | One page per customer-facing feature | `corporate-visions` | Why Change → Why Now → Why You → Why Pay is the canonical capability-page arc: it scopes each capability as a small sales story rather than a feature list. |
| `persona` | `for/{market-slug}--{persona}.md` | Persona landing page ("For CROs", "For Plant Managers") | `jtbd-portfolio` | Same arc as `home`, but scoped to a single persona's jobs and friction — the same rhetorical shape, narrowed. |
| `approach` | `approach.md` | How We Work / Our Approach | `engagement-model` | Principles → Process → Partnership → Outcomes answers the follow-up question every capability page raises: "OK but how does this actually land in my organization?" |
| `all` | all of the above | All components in one invocation | — | Use this to regenerate the entire website from the current portfolio state. |

**Dropped in v2:** The `market/*.md` scope from the previous version has been removed. Market-level content was substantially redundant with persona pages (same roadmap block, same differentiation block, same "what we offer" block) and had no role in a typical website information architecture. Market-relevant content now lives where it is actually needed: either summarized in `home.md` ("who we serve"), deepened in specific persona pages, or rolled up into `about.md`.

**Deduplication principles baked into these templates**:
- **Roadmap ("On the roadmap" / "Auf dem Fahrplan") appears in exactly one file — `home.md`**. All other pages link to it.
- **Cross-cutting differentiators ("why us") appear in exactly one file — `about.md`**. Capability and persona pages refer to them; they do not restate them.
- **Persona pages show only the capabilities relevant to that persona's buying criteria**. They never re-enumerate the full portfolio.
- **Capability pages are the single source of truth for a feature's Why Change → Why Pay**. Persona pages link out to the relevant capability pages rather than inlining the capability story.

---

## Handling messaging mode

The skill attaches a `messaging_mode` to every product and feature in Step 2 — derived from product `maturity` and feature `readiness`. See SKILL.md → Maturity-Aware Messaging for the mapping table. Website content is buyer-facing, so getting tense and framing right is the whole point — a present-tense sentence about a `concept` product is a broken promise and reads as sales noise.

Apply these rules wherever a product or feature is rendered:

- **standard** (growth / mature / fallback): confident present tense. Full proof points. No inline label.
- **launch**: present tense, tag the product name with *(Newly launched)*.
- **preview** (beta): present tense qualified by "in beta" or "early access". Tag with *(Beta)*. Pricing qualified as "introductory" or "early-access".
- **announce** (concept / planned): future tense. "We are building…", "Expected to support…". No Engagement/Pricing prose, no proof points. These offerings **only** appear in the "On the roadmap" subsection of `home.md`. Tag with *(Coming soon)*.
- **sunset** (decline): "We continue to support existing customers for [product]." No CTA, no pricing. Omitted from `home.md` and `capabilities/*.md` unless the scope explicitly names the product.

**Roadmap subsection (home.md only).** `home.md` carries a subsection titled **"On the roadmap"** (EN) / **"Auf dem Fahrplan"** (DE) listing the `announce` and `preview` offerings in future-tense or beta-qualified voice. This subsection carries a one-line framing ("What we're building next, with expected availability where known.") and then the products. **No other file in this use case carries a Roadmap subsection** — the deduplication discipline depends on it.

**Feature-level override inside a standard product.** When a `standard` product contains a `beta` or `planned` feature, describe that specific feature in the stricter voice inline ("…including {feature name} *(in beta)*, which will…") rather than moving the whole product to the Roadmap. The product stays in the main narrative; the feature prose qualifies itself.

**Promise discipline.** `home.md` and `about.md` both close with a forward commitment (the Invitation in jtbd-portfolio, the Promise in company-credo). **Neither commitment may depend on an `announce`-mode product.** If a promise would only be true once a concept ships, it belongs on the Roadmap subsection, not the commitment.

---

## YAML Frontmatter (all scopes)

Every generated file includes frontmatter that `text-to-narrative`, `/copywrite` and friends all understand:

```yaml
---
title: "{Compelling title — value-led, not internal}"
subtitle: "{Company name} — {component descriptor}"
type: portfolio-communicate
use_case: customer-narrative
scope: home | about | capability | persona | approach
arc_id: jtbd-portfolio | company-credo | corporate-visions | engagement-model
arc_display_name: "JTBD Portfolio" | "Company Credo" | "Corporate Visions" | "Engagement Model"
language: "{en|de}"
date_created: "{ISO 8601}"

# Scope-specific fields:
feature: "{feature-slug}"          # capability scope only
market: "{market-slug}"            # persona scope only
persona: "{persona identifier}"    # persona scope only

source_entities:
  products: {count}
  features: {count}
  propositions: {count}
  solutions: {count}
  packages: {count}
---
```

**Why `arc_id` in frontmatter matters.** `cogni-workspace`'s `copywriter` reads it to polish within the arc's elements without touching the skeleton, and it is the value to pass as `--arc-id` when `text-to-narrative` builds the brief — that skill does not read a source file's frontmatter arc, so without it the page is re-narrated under an auto-detected arc, which discards the scope's chosen structure. Always populate it.

---

## Scope 1: `home` — Home Page

**Output**: `output/communicate/customer-narrative/home.md`
**Arc**: `jtbd-portfolio` (Job Landscape → Friction Map → Portfolio Map → Invitation)
**Target length**: ~1,675 words (the arc's default)

**Data sources**: portfolio.json, all products/*.json, all features/*.json, all propositions/*.json (grouped by market but not filtered), markets/*.json (used to summarize "who we serve"), cross-cutting customer pain points from customers/*.json, cross-cutting solution entry tiers from solutions/*.json.

**What the home page is for.** This is the entry point. A buyer lands here from a Google search or a LinkedIn post and needs to answer three questions in 60 seconds: *"does this company understand my world"*, *"what do they build that might matter to me"*, *"where do I go next"*. The `jtbd-portfolio` arc is the cleanest way to answer all three.

```markdown
---
{YAML frontmatter with arc_id: jtbd-portfolio}
---

# {Compelling value-led title — not "Home"}

*(Hook — ~10% / ~170 words — one sharp observation that creates inevitability. Frame the
buyer's world as changing in a way that makes the company's portfolio urgent. Ground with
at least 1 citation.)*

## Job Landscape: Functional Jobs

*(~24% / ~400 words)*

{Open with the Contrast Structure move — "Our portfolio has N products. Your buyers have 3–4 jobs." This is the JTBD reframe that governs everything below.}

{Extract 3–4 functional jobs from the union of customer pain points across ALL markets. Each job is a verb phrase in buyer language (e.g. "Reduce unplanned downtime below 2%"), NEVER a product category name. At the home-page level these jobs must be genuinely cross-market — jobs that specific to one market go on persona pages, not here.}

**Job 1: {Verb phrase}**
{1–2 sentences of context: why this job matters to the kinds of buyers the company serves.}

**Job 2: {Verb phrase}**
{Context.}

**Job 3: {Verb phrase}**
{Context.}

## Friction Map: Obstacles and Cost of Inaction

*(~21% / ~350 words)*

{Per-job friction entries. For each job above, name the obstacle and quantify the cost of inaction using evidence from proposition.evidence arrays. Every cost claim needs a citation. Use Forcing Functions where external pressures exist (regulation, market tipping points). Use Compound Impact to stack friction across the job landscape.}

## Portfolio Map: Solutions by Job

*(~27% / ~450 words)*

{1:1 mapping from jobs to the company's top-level solution families. At the home-page level, map to products (not individual propositions) — the capability-page template goes feature-deep. For each job, present the matching product as an IS/DOES/MEANS triple:

- **IS:** One sentence on what the product concretely is
- **DOES:** You-Phrased outcome the buyer experiences (quantified where possible)
- **MEANS:** One sentence on why competitors struggle to deliver the same outcome

Link each product to its capability page at `capabilities/{feature-slug}.md` using buyer-facing anchor text.}

### On the roadmap

*(REQUIRED: This is the ONLY file that carries a Roadmap subsection. Its presence here is what allows persona pages, capability pages, and the About page to skip the roadmap entirely and still communicate the full story of the company.)*

{One-line framing: "What we're building next, with expected availability where known."}

{List `announce`-mode and `preview`-mode offerings in future-tense or beta-qualified voice. No pricing, no proof points, no engagement language — these are announcements.}

- **{Product name}** *(Coming soon)* — {future-tense 1-sentence description + expected availability if known}
- **{Product name}** *(Beta)* — {present-qualified description, "currently in early access with N design partners"}

## Invitation: Next Step

*(~18% / ~300 words)*

{Close with one clear, low-commitment entry point across the whole portfolio — not a menu of options. Reference the lowest-commitment tier across solutions (proof-of-value, free tier, pilot).}

{At the home-page level, the Invitation should fork once by buyer type, pointing to persona pages. Example:
- "If you're a CRO specifically, the For CROs page is where this story becomes concrete."
- "If you're heading operations, the For Plant Managers page goes deeper."

That fork is NOT a menu — it is a single gesture that routes by role. Do not list more than two forks.}

{Final sentence: acknowledge that deal-specific conversations happen elsewhere — `/why-change` in the sales flow — without naming the internal skill. For example: "When you have a named account in mind, we build a tailored Why Change narrative for that specific conversation."}

## Who we serve

*(Optional short section — 150 words MAX. Absorbed the old market-scope content.)*

{Very brief list of the markets the company serves, framed as buyer identities, not segment definitions. This section exists only to reassure the reader that their industry is served. If a reader wants depth, they navigate to the persona page.}
```

**Content guidelines for home**:
- Target length: ~1,675 words (the jtbd-portfolio default)
- The Job Landscape must be cross-market — market-specific jobs belong on persona pages
- The Portfolio Map uses IS/DOES/MEANS per product family, not feature-level detail
- The Roadmap subsection is mandatory and exclusive to this file
- Every quantitative claim is cited to an external source URL

---

## Scope 2: `about` — About Us Page

**Output**: `output/communicate/customer-narrative/about.md`
**Arc**: `company-credo` (Mission → Conviction → Credibility → Promise)
**Target length**: ~1,400 words (the arc's default)

**Data sources**: portfolio.json (company_description, positioning, founded_year, mission/vision, certifications), cross-cutting MEANS themes from propositions/*.json, differentiation claims from competitors/*.json, named accounts from customers/*.json (ONLY if `disclosure_permission: true`), cogni-claims/claims.json verified facts, cross-cutting engagement patterns from solutions/*.json (for Promise).

**What the about page is for.** A buyer clicks "About" when they are about to evaluate a capability seriously and want to know whether the company is the kind of company they want to work with — *before* they dig into the capability. The `company-credo` arc is designed specifically for this moment: it answers "who is this and why should I believe them" without pitching a solution.

```markdown
---
{YAML frontmatter with arc_id: company-credo}
---

# {Positioning statement as title — not "About Us"}

*(Hook — ~10% / ~140 words — "Founding lens" framing. One observation about the industry
or the buyer's world that makes the company's existence feel necessary.)*

## Mission: Why We Exist

*(~24% / ~335 words — FIRST-PERSON PLURAL REQUIRED ("we" / "wir"). This is the one place in the
customer-narrative suite where company first-person voice is mandatory.)*

{Two paragraphs:
1. The belief: the named problem the company refuses to accept as normal + why it persists + 1 citation
2. The verb: what the company does about it, in one specific verb phrase}

{Apply Contrast Structure (industry default vs. company stance) and Forcing Functions (why now, not five years ago). Mission MUST NOT be a service list. If every competitor could sign the paragraph, it is too generic.}

## Conviction: What We Believe

*(~22% / ~310 words)*

{3–4 non-negotiable convictions. Each:
- Named headline
- Belief sentence starting with a verb of position ("We believe…", "We refuse…", "We insist…")
- Buyer-visible consequence ("which is why you will see Y when you work with us")

Every conviction must pass the disagreement test — a named competitor must plausibly disagree with it. Generic corporate values ("we value integrity", "we put customers first") fail the test and are forbidden.}

## Credibility: How You Can Trust Us

*(~26% / ~365 words — the longest element; this is where belief hardens into willingness to proceed.)*

{Open with: "Convictions are cheap. Here is what we can show."}

{Present 4–6 credibility items grouped by dimension using bold labels so buyers can scan:

**Track record**
{Years operating, deployment counts, longest engagement — with citations.}

**External validation**
{Certifications (ISO 27001, SOC 2, etc.), partner badges, analyst mentions, awards — with citations.}

**Named outcomes**
{Specific customer outcomes WITH quantified improvements. Named customers ONLY if `customers/{market}.json` has `disclosure_permission: true`. Otherwise describe anonymously ("a top-3 German automotive OEM").}

**Expertise**
{Published case studies, standards contributions, conference talks.}

Cover at least 2 of the 4 dimensions. Cite every quantitative claim. Flag anything older than 3 years.}

## Promise: What You Can Expect

*(~18% / ~250 words — the handshake.)*

{3 You-Phrased commitments. Each:
- Short headline ("You will own your data contracts")
- One paragraph of what this means in practice
- No dependency on `announce`-mode products (maturity discipline)

Close with a SINGLE invitation pointing to a specific next page by buyer-facing function — usually the Capabilities index or a specific persona page. NOT a menu of options.}

Example close:
> If you want to see what we actually build for your role, the Capabilities page is the next stop. If you're a CRO specifically, the For CROs page is a better starting point.

(That is one invitation with a fork, not two separate CTAs.)
```

**Content guidelines for about**:
- Target length: ~1,400 words
- Mission in first-person plural throughout
- Every conviction passes the disagreement test and names a buyer-visible consequence
- Credibility covers ≥2 dimensions with every quantitative claim cited
- Named customers ONLY with explicit disclosure permission
- Promise items must be true across the current live portfolio (no `announce`-mode dependencies)
- Single closing invitation, not a menu

---

## Scope 3: `capability` — Capability / Feature Page

**Output**: `output/communicate/customer-narrative/capabilities/{feature-slug}.md`
**Arc**: `corporate-visions` (Why Change → Why Now → Why You → Why Pay)
**Target length**: ~1,675 words per capability

**Data sources**: one feature from features/*.json, its parent product from products/*.json, all propositions/*.json targeting that feature (across markets — the capability page is market-agnostic; market-tailored versions happen on persona pages), solutions/*.json for the feature, competitors/*.json for the feature, cross-cutting evidence.

**What the capability page is for.** The capability page is where a buyer lands from the home page or the persona page when they want to understand one specific thing the company builds deeply enough to decide whether to start a conversation about it. Corporate Visions is the canonical arc for this moment — it scopes a single capability as a small sales story with its own Why Change → Why Pay sequence.

**Cardinality.** Generate one file per customer-facing feature. Skip features that are pure internal infrastructure (no propositions, or `purpose` field empty). For a portfolio of 20 features, 10–15 capability pages is typical.

**Source-of-truth discipline.** This is the only file in the use case where the feature's "Why Change → Why Pay" is told in full. Persona pages reference it; the home page summarizes it in one IS/DOES/MEANS triple. The capability page is the authoritative story.

```markdown
---
{YAML frontmatter with arc_id: corporate-visions, feature: {feature-slug}}
---

# {Value-led title for this capability — not "Capability X"}

*(Hook — ~10% — one sharp observation that makes the buyer's current situation feel newly urgent
for this specific capability. Ground with at least 1 citation.)*

## Why Change: Unconsidered Needs

*(~27%)*

{Frame the buyer's current-state obstacle that this capability addresses. Draw from customer pain points across markets that target this feature + the feature's propositions' DOES statements reverse-engineered into buyer problems. Quantify with citations from proposition evidence arrays.}

## Why Now: Forcing Functions

*(~21%)*

{External pressures that make THIS capability urgent right now — not five years ago, not five years from now. Regulatory shifts, technology availability, market tipping points. Cite.}

## Why You: Unique Positioning

*(~27%)*

{Present this capability through its propositions' IS/DOES/MEANS — but at the capability level, aggregate across markets rather than repeating per-proposition detail:

- **IS:** What the capability concretely is (from feature.description + feature.purpose).
- **DOES:** What you experience (aggregated DOES across propositions, You-Phrased, quantified).
- **MEANS:** Why competitors struggle to match it (aggregated from competitors/*.json).

Do NOT list features sub-capabilities. If you find yourself writing a bullet list of sub-features, stop and reframe as one IS paragraph + one DOES paragraph + one MEANS paragraph.}

## Why Pay: ROI Justification

*(~15%)*

{Investment framing for this specific capability. Solution tiers (PoV, S, M, L) with scope descriptions and pricing bands where available. NO cost_model data, NO internal margins, NO effort days — only external-facing pricing from solutions and packages. Single low-commitment entry point as the CTA.}
```

**Content guidelines for capability**:
- Target length: ~1,675 words per file
- One file per customer-facing feature (skip features with no propositions or empty purpose)
- The capability page is market-agnostic — market-specific framing happens on persona pages
- Use IS/DOES/MEANS at the feature level, aggregated across markets
- NO sub-feature bullet lists
- External pricing only (no cost_model, margins, effort days)
- Every quantitative claim cited to external source URLs

---

## Scope 4: `persona` — Persona Landing Page

**Output**: `output/communicate/customer-narrative/for/{market-slug}--{persona}.md`
**Arc**: `jtbd-portfolio` (Job Landscape → Friction Map → Portfolio Map → Invitation), persona-scoped
**Target length**: ~1,500 words per persona

**Data sources**: one market from markets/*.json, the specific persona from customers/{market}.json (role, seniority, pain_points, buying_criteria, budget_authority), propositions in that market FILTERED by persona buying criteria, the parent features and products for those propositions, the solutions for those propositions.

**What the persona page is for.** A buyer who recognised themselves in the home page's Invitation fork ("If you're a CRO specifically…") lands here. This page is narrower than home and narrower than a capability page — it is *one persona's version of the Job Landscape*, pointing them at the subset of capabilities that actually matter to their role.

**Cardinality.** One file per persona across all markets. If the portfolio has 3 markets × 2 personas each = 6 persona files.

**Deduplication discipline.** Persona pages are the file type most at risk of duplicating content from home, capability, and about pages. The template below enforces three rules:

1. **No Roadmap subsection** — point to home.md if the persona would care about roadmap items.
2. **No full capability stories** — link to the relevant capability pages; do not inline their Why Change → Why Pay.
3. **No cross-cutting differentiation** — point to about.md's Conviction element; do not restate it.

```markdown
---
{YAML frontmatter with arc_id: jtbd-portfolio, market: {market-slug}, persona: {persona id}}
---

# For {Persona}: {Their governing goal in one sentence}

*(Hook — ~10% / ~150 words — write directly to this persona's role. Reference their specific world
using language from the customer profile pain points. This should feel like it was written for them
specifically, not adapted from a generic template.)*

## Job Landscape: Functional Jobs

*(~24% / ~360 words)*

{3–4 functional jobs filtered and reframed for THIS persona. Draw from persona.pain_points and buying_criteria. Phrase as verb phrases in the persona's actual language (e.g. "Close the quarter without losing pipeline visibility for three weeks" — a CRO would say this; "achieve sales enablement maturity" is consultant-speak and is forbidden).}

**Job 1: {Persona-specific verb phrase}**
{1–2 sentences anchored in what this persona's Monday morning actually looks like.}

**Job 2: {Verb phrase}**
{Context.}

**Job 3: {Verb phrase}**
{Context.}

## Friction Map: Obstacles and Cost of Inaction

*(~21% / ~315 words)*

{Per-job friction entries specific to this persona. Draw from persona pain_points — these are the persona's own words in customers/{market}.json. Cost of inaction should be framed in metrics this persona's role is measured on (CROs: pipeline, quota attainment; Plant Managers: downtime hours, OEE; CFOs: cost per unit, margin).}

## Portfolio Map: Solutions by Job

*(~27% / ~405 words)*

{1:1 map from this persona's jobs to the subset of propositions that actually match their buying criteria. FILTER RUTHLESSLY — not every proposition in the market matches every persona. A CRO cares about different propositions than a VP Customer Success.

For each relevant proposition, present ONE SENTENCE of IS/DOES/MEANS and then link out to the full capability page:

**Job 1 → [Capability name](../capabilities/{feature-slug}.md)**
{One sentence: the capability's DOES in this persona's language, pointing to the full capability story.}

**Job 2 → [Capability name](../capabilities/{feature-slug}.md)**
{One sentence.}

Do NOT inline the capability story. The capability page is the source of truth. This page is the router.}

## Invitation: Next Step

*(~18% / ~270 words)*

{Entry point calibrated to this persona's budget authority and decision style:
- High budget authority (C-level): lead with strategic outcomes, reference package tiers
- Medium authority (Director): balance outcomes with scope clarity
- Operational authority (Manager): emphasize quick wins and proof-of-value

Close with a SINGLE entry point — not a menu. Frame explicitly as low-commitment ("a 4-week engagement focused on {persona's top priority}", not "contact sales").}

{Optional final sentence pointing at the about page for trust-building: "If you want to understand how we think before you commit to a conversation, our About page is where we lay that out."}
```

**Content guidelines for persona**:
- Target length: ~1,500 words per persona file
- Persona pages ROUTE to capability pages; they do not reinvent them
- NO roadmap subsection (point to home.md)
- NO cross-cutting differentiation (point to about.md)
- Filter propositions ruthlessly by persona buying criteria — fewer targeted propositions > comprehensive coverage
- Persona jobs must be in the persona's own vocabulary
- Single entry point in the Invitation, calibrated to budget authority

---

## Scope 5: `approach` — How We Work Page

**Output**: `output/communicate/customer-narrative/approach.md`
**Arc**: `engagement-model` (Principles → Process → Partnership → Outcomes)
**Target length**: ~1,400 words (the arc's default)

**Data sources**: portfolio.json (engagement framing, methodology references), all solutions/*.json (primary — aggregate phases across solutions for Process), cross-cutting patterns from customers/*.json buying_criteria (for Partnership), cross-cutting MEANS themes from propositions/*.json (for Outcomes).

**What the approach page is for.** Every capability page raises the same follow-up question in the buyer's head: *"OK, but how does this actually land in my organization?"* The approach page is the answer. It is navigation-oriented — buyers scan it looking for reassurance that the company has a grown-up way of working, not a read-through.

**No pricing, no ROI numbers.** This is the strictest discipline in the arc. Pricing belongs on capability pages (where it can be scoped) or proposals (where it is customer-specific). Pricing on the approach page makes the page read as a sales pitch, which is exactly the tone the buyer is avoiding when they click "How We Work".

```markdown
---
{YAML frontmatter with arc_id: engagement-model}
---

# {Distinctive working-style title — not "Our Approach"}

*(Hook — ~8% / ~110 words — the shortest Hook across the customer-narrative suite. One observation
about what buyers typically fear about services engagements, + a preview that the company works
differently in exactly that way.)*

## Principles: Principles We Work By

*(~22% / ~310 words)*

{3–4 operating principles. Each:
- Headline in operational language (NOT a value)
- Paragraph describing what the principle looks like in practice + what it replaces in the industry default
- Traceable to the Process element below

Example: "Weekly working demos, no status reports" is operational. "Customer-centric delivery" is a value. Write operationally.}

## Process: How an Engagement Unfolds

*(~28% / ~390 words — the longest element; this is the meat of the page.)*

{Aggregate phases across the portfolio's solutions. Identify the canonical 4–6 phases that recur. Present each as a skimmable card:

**Phase {N}: {Name} ({time band})**
- **What happens:** {1–2 sentences of the work}
- **What you see:** {the artifact(s) the buyer will interact with}
- **What you sign:** {the approval(s) the phase requires, or "nothing" for observational phases}
- **Traceable principle:** {which Principle from above is most visible in this phase, optional but valuable}

Every phase has an artifact. Every phase has a time band (range, not false precision — "2–4 weeks" not "a few weeks"). No phase is solution-specific — those belong on capability pages.}

## Partnership: What We Expect From You

*(~20% / ~280 words — reciprocal of the About page's Promise.)*

{Opening reciprocity framing: "None of this works unless you bring a few things to the table."}

{3–4 You-Phrased expectations. Each:
- Names a concrete thing (a person, a data source, an approval authority, a timebox)
- States the consequence if missing ("we pause the engagement rather than work around it")
- Offers reciprocity where possible ("we provide a one-page technical scope to accelerate your security review")

Constructive tone — this is a list of inputs the engagement needs, NOT a list of reasons the engagement could fail.}

## Outcomes: What Success Looks Like

*(~22% / ~310 words)*

{Opening engagement-level framing: "These outcomes are true regardless of which capability you hire us for. Capability-specific outcomes live on the capability pages."}

{3 cross-cutting outcome themes aggregated from MEANS across the portfolio. Each:
- Buyer-visible change (not company activity)
- How the change is observed (a meeting gets shorter, a report takes less time, a dashboard shows a specific number compressing)
- NO pricing, NO ROI numbers, NO per-capability metrics}

{Soft close: "The process adapts to your size and scope. The principles do not." + one invitation to the Capabilities index page.}
```

**Content guidelines for approach**:
- Target length: ~1,400 words
- Every Principle is operational, not aspirational
- Every Process phase has an artifact AND a time band
- NO solution-specific phases (those belong on capability pages)
- Every Partnership expectation names a concrete thing + consequence
- Every Outcome is cross-cutting and describes buyer-visible change
- **NO pricing, NO ROI numbers anywhere** (strictest discipline in the arc)

---

## Citations

Customer-facing documents must cite **external source URLs** so readers can verify evidence claims. Never link to internal JSON entity file paths (`propositions/x.json`, `markets/y.json`) — these are meaningless to buyers.

**Inline format**: `<sup>[N]</sup>` in the body text — the number references the Sources footer.

**Source priority** (use the first available for each cited claim):
1. `evidence[].source_url` from the proposition — the original external source
2. `evidence[].source_url` from competitor or customer entities
3. `cogni-claims/claims.json` entries with `status: "verified"` — use their `source_url`
4. No citation — use descriptive inline text instead (e.g., "(internal estimate)")

**Claims without external sources**: Market sizing, internal calculations, or LLM-derived estimates get no superscript citation. State the figure with a parenthetical qualifier.

**References footer**: End each document with a numbered sources section:

```markdown
---
## Sources

[1] [Source Title](https://source-url) — brief context
[2] [Source Title](https://source-url) — brief context
```

Customer narratives are self-paced reading — keep citations unobtrusive. A Sources footer at the end is cleaner than heavy inline linking.

---

## Tone Transformation Examples

These examples illustrate how to transform internal language into customer-facing prose. They apply to every scope.

### Feature Description (IS)

**Internal**: "Cloud-native monitoring platform with real-time anomaly detection using ML-based baseline analysis and automated incident correlation across distributed microservice architectures."

**Customer-facing**: "Monitor your entire cloud environment from a single pane of glass. Our platform learns what 'normal' looks like for your systems and alerts you to anomalies before they become incidents — even across hundreds of interconnected services."

### Proposition (DOES/MEANS)

**Internal DOES**: "Reduces mean-time-to-detection (MTTD) by 60% through automated baseline learning and cross-service correlation, eliminating manual threshold configuration."

**Customer-facing**: "When something goes wrong in your infrastructure, you know within minutes — not hours. Teams that previously spent days configuring alert thresholds now get accurate, context-aware notifications automatically. The result: problems caught and resolved before your customers notice."

### Market Description

**Internal**: "Grosse Energieversorger DE — Large German energy utilities (>500 employees, >500M EUR revenue). TAM: 2.4B EUR. Key dynamics: regulatory pressure from EnWG amendments, legacy SCADA modernization, grid digitalization mandates."

**Customer-facing**: "Large energy utilities navigating one of the most complex technology transitions in the industry — modernizing decades-old operational systems while meeting increasingly demanding regulatory requirements and grid digitalization targets."

### Differentiation

**Internal competitor analysis**: "Competitor X lacks real-time correlation. Competitor Y has no ML-based baselines. Our automated incident correlation is unique in this segment."

**Customer-facing**: "Where traditional monitoring tools require manual configuration for every new service, our platform adapts automatically — learning your system's behavior patterns and correlating events across your entire infrastructure without human intervention."
