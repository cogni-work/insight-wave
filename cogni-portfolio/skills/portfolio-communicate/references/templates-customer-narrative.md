# Templates: Customer Narrative

Output templates for the `customer-narrative` use case. Transforms portfolio entities into customer-facing narratives — value-led stories presenting the company's offerings through the buyer's lens.

**Use case**: `customer-narrative`
**Audience**: Buyers, executives, decision-makers evaluating the company's offerings
**Voice**: Company speaks to buyer ("we"/"you"). Professional but conversational.

Each template shows the heading structure, section-by-section content guidance, and data source mapping.

---

## Handling messaging mode

The skill attaches a `messaging_mode` to every product and feature in Step 2 — derived from product `maturity` and feature `readiness`. See SKILL.md → Maturity-Aware Messaging for the mapping table. Customer narratives are buyer-facing, so getting tense and framing right is the whole point of the exercise — a present-tense sentence about a `concept` product is a broken promise.

Apply these rules wherever a product or feature section is rendered:

- **standard** (growth / mature / fallback): the existing voice. Confident present tense. Full proof points. Full engagement framing. No inline label.
- **launch**: present tense, but tag the product name in its section heading with *(Newly launched)*. Opening sentence may reference recency ("Recently launched for…"). Proof points and pricing are allowed.
- **preview** (beta): present tense qualified by "in beta" or "early access" on first mention. Evidence items allowed but reframe as "early pilots" rather than delivered outcomes. Any pricing must be labelled "introductory" or "early-access". Tag the product name with *(Beta)*.
- **announce** (concept / planned development): future tense. "We are building…", "Expected to support…". **No Engagement/Pricing prose.** **No proof points.** These offerings move into a dedicated "Roadmap" subsection (see below) rather than appearing alongside live capabilities. Tag with *(Coming soon)*.
- **sunset** (decline): neutral voice. "We continue to support existing customers for [product]; we are no longer accepting new engagements." No CTA, no pricing, no proof points. Omit from `overview` scope by default; include only if the scope explicitly names the product. Tag with *(Legacy — existing customers only)*.

**Roadmap subsection.** In the `overview` and `market` scopes, after the main "What We Do" / "How We Help" section, insert a subsection titled **"On the roadmap"** (EN) / **"Auf dem Fahrplan"** (DE) containing the announce-mode and preview-mode offerings. This section carries a one-line framing — e.g. "What we're building next, with expected availability where known." — and then the products in future-tense or beta-qualified voice. This keeps early-stage material visible to the buyer without contaminating the "what you can buy today" narrative.

**Feature-level override inside a standard product.** When a `standard` product contains a `beta` or `planned` feature, describe that specific feature in the stricter voice inline ("…including {feature name} *(in beta)*, which will…") rather than moving the whole product to the Roadmap section. The product stays in the main listing; the feature prose qualifies itself.

---

## YAML Frontmatter (all levels)

Every generated file includes frontmatter compatible with `cogni-narrative` input:

```yaml
---
title: "{Compelling title — value-led, not internal}"
subtitle: "{Company name} — {scope descriptor}"
type: portfolio-communicate
scope: overview | market | customer
market: "{market-slug}"          # market and customer levels only
persona: "{persona identifier}"  # customer level only
language: "{en|de}"
date_created: "{ISO 8601}"
source_entities:
  products: {count}
  features: {count}
  propositions: {count}
  solutions: {count}
  packages: {count}
---
```

---

## Level 1: Portfolio Overview

**Output**: `output/communicate/customer-narrative/portfolio-overview.md`

**Data sources**: portfolio.json, products/*.json, features/*.json, propositions/*.json (all), packages/*.json (if available)

```markdown
# {Company Name}: {Value-Led Tagline}

{Opening paragraph — 2-3 sentences that answer "What does this company do and why should
I care?" Frame from the buyer's perspective. Use the company_description and positioning
from portfolio.json but rewrite for external consumption. No internal language.}

## What We Do

{For each product, one subsection. Order by relevance — flagship/GA products first,
then by the number of propositions each product powers. Within each product, present
capabilities (features) as value statements, not technical specs.}

### {Product Name}

{Product positioning rewritten as a customer value statement. 2-3 sentences.
Draw from product description and positioning fields.}

**Key capabilities:**

{For each feature belonging to this product (ordered by sort_order), transform into a
customer-facing capability statement. When the feature has a `purpose` field, use it as
the lead — it is already customer-readable. Supplement with the IS description for depth.
When purpose is absent, transform the IS description into customer-facing language.
Focus on what the capability enables for the buyer, not what it technically is.

Format as a brief list — each capability gets 1-2 sentences maximum.
If packages exist for this product, group capabilities by package tier
to show natural bundling.}

## Who We Serve

{Brief section listing target markets as audience descriptions, not segment definitions.
Reframe market names and descriptions as buyer identities.

Example: Instead of "Grosse Energieversorger DE (TAM: 2.4B EUR)" write
"Large energy utilities transforming their digital infrastructure."

For each market, one sentence describing what the company offers there,
linking to the market-tailored view if generated.}

## Why Us

{Cross-cutting differentiation themes extracted from propositions and competitor analysis.
Identify 3-5 themes that recur across multiple propositions — these are the company's
genuine differentiators, not proposition-specific claims.

Present as narrative paragraphs, not a comparison table. Weave in evidence
from proposition evidence arrays where available, citing external sources
(see [Citations](#citations) below). No competitor names.}

## Working Together

{If solutions and/or packages exist, present engagement models at a high level.
Group by solution type:
- Project-based: "We deliver through structured implementation phases..."
- Subscription: "Our platform is available in tiers designed to grow with you..."
- Partnership: "We build long-term partnerships with shared outcomes..."

Do NOT include specific pricing — this is an overview. Mention that tailored
proposals are available for specific needs.}

## Next Steps

{Concrete, low-pressure call to action. Frame as exploration, not commitment.
"Let's explore how [company] can support your [relevant goal]."
Include contact mechanism if available from portfolio.json.}
```

**Content guidelines for overview**:
- Target length: 800-1,500 words (enough to tell the story, short enough to read)
- Every section should pass the "so what?" test — if removing it loses nothing for the buyer, cut it
- Products with no propositions: mention briefly but don't feature prominently
- Features with no propositions: omit from customer-facing content

---

## Level 2: Market-Tailored View

**Output**: `output/communicate/customer-narrative/market/{market-slug}.md`

**Data sources**: portfolio.json, the specific market JSON, all propositions targeting this market, their parent features and products, solutions for those propositions, packages for relevant product x market pairs, customers/{market}.json, competitors for those propositions

```markdown
# {Value-Led Title for This Market}

{Opening paragraph — speak directly to the buyer in this market. Reference their
world, their challenges, their priorities. Draw from the market description and
customer profile pain points. Do NOT mention market sizing or segmentation.

Example: Instead of "The German enterprise energy market faces regulatory pressure..."
write "As an energy executive, you're balancing grid modernization with tightening
regulatory requirements — while your IT landscape grows more complex every quarter."}

## Your Challenges

{Extract the top 3-5 pain points from the customer profile (customers/{market}.json).
Frame each as a brief narrative paragraph that demonstrates understanding of the
buyer's world. This is the "feel understood" section — specificity matters more
than completeness.

If no customer profile exists for this market, derive challenges from the market
description and proposition DOES statements. Flag internally that customer profiles
would strengthen this section.}

## How We Help

{For each product that has propositions in this market, one subsection.
Order products by the number of propositions they have in this market (most first).}

### {Product Name}: {Market-Specific Value Headline}

{For each proposition (feature x this market), present as a value story:

1. The buyer's need (derived from DOES statement, reframed as buyer language)
2. What the capability delivers (DOES statement)
3. Why it matters (MEANS statement)
4. Evidence (from proposition evidence array — specific outcomes, metrics, case references, linked to external sources via `evidence[].source_url`)

If a package exists for this product x market, present capabilities as a bundled
offering with tier differentiation rather than individual feature listings.

Order propositions by relevance tier from project-status.sh (high first).
Skip low-tier and skip-tier propositions unless the portfolio is small (<5 total).}

## What Sets Us Apart

{Market-specific differentiation. Read competitor analysis for all propositions
in this market. Identify differentiation themes that are specific to this market's
competitive landscape — not the same generic differentiators from the overview.

Present as 2-3 focused paragraphs. Reference competitor positioning analysis
without naming competitors.}

## Engagement Options

{If solutions exist for propositions in this market:

Present solution types available, with enough detail for the buyer to understand
the engagement model and investment range.

**Project-based solutions**: Name the implementation phases and their purpose.
Include pricing tiers (PoV/S/M/L or equivalent) with scope descriptions.
Frame as investment levels, not cost items.

**Subscription solutions**: Present tier structure (Free/Pro/Enterprise or equivalent)
with what each tier includes. Monthly/annual pricing if available.

**Partnership solutions**: Describe the program structure and commitment model.

**Packages**: If packages exist for this product x market, present the package tiers
as the primary offering — show what's bundled and the value of the bundle.

External pricing (package tiers, project tiers, subscription tiers, partnership terms) is
appropriate for customer-facing content. NEVER include cost_model data, internal margins,
effort days, role rate breakdowns, CAC/LTV, or unit economics — these are confidential
internal planning data.}

## Let's Talk

{Market-specific call to action. Reference the buyer's situation:
"If [market-specific challenge] resonates, we'd welcome the opportunity to explore
how [company] can support your [market-specific goal]."}
```

**Content guidelines for market view**:
- Target length: 1,000-2,000 words (deeper than overview, focused on one market)
- Use buyer language from the customer profile, not internal proposition labels
- Every proposition should appear as a value story, not a feature listing
- Include pricing/investment only when solutions exist — don't fabricate

---

## Level 3: Customer-Tailored View

**Output**: `output/communicate/customer-narrative/customer/{market-slug}--{persona}.md`

**Data sources**: All market-level sources + specific persona from customers/{market}.json (role, seniority, pain_points, buying_criteria, budget_authority)

```markdown
# {Personalized Title Addressing the Persona's Goal}

{Opening paragraph — write directly to this persona's role and situation.
Reference their specific pain points and priorities from the customer profile.
This should feel like it was written for them specifically, not adapted from
a generic template.

Example for a CTO persona: "As the technology leader responsible for your
organization's digital backbone, the decisions you make about cloud infrastructure
directly impact both operational efficiency and competitive positioning."}

## What We See in Your World

{Persona-specific framing of 2-3 key challenges. Draw from the persona's
pain_points array in the customer profile. For each challenge, validate it with
a brief external reference — a market trend, a regulatory development, or a
common industry pattern. This builds credibility through shared understanding.}

## What We Bring to the Table

{Filter propositions to those most relevant to this persona's buying criteria.
Not every proposition in the market is relevant to every persona — a CTO cares
about different propositions than a CFO.

For each relevant proposition:
1. Frame the capability in terms of this persona's priorities
2. Connect DOES to their specific pain points
3. Present MEANS in terms of outcomes this persona measures
4. Include evidence that resonates with this persona's seniority level
   (C-level: strategic outcomes, Director: operational metrics, Manager: tactical gains)

Fewer, more targeted propositions are better than comprehensive coverage.}

## How We'd Work Together

{Present the engagement approach filtered for this persona's decision-making style
and budget authority:

- High budget authority (C-level): Lead with strategic outcomes, present investment
  as a portfolio decision, reference package tiers if available
- Medium authority (Director): Balance outcomes with implementation detail,
  present pricing tiers with clear scope
- Operational authority (Manager): Emphasize quick wins and proof of value,
  lead with PoV or free tier options

Adapt solution presentation to persona's buying_criteria — if they value speed,
emphasize rapid deployment. If they value risk mitigation, emphasize phased approach.}

## Recommended Starting Point

{Persona-specific call to action. Based on their budget authority and buying criteria,
suggest the most appropriate entry point:
- PoV/pilot for risk-averse or lower budget authority
- Full engagement for strategic buyers with clear mandate
- Subscription free tier for self-service evaluation

Make it concrete: "Based on your priorities, we'd recommend starting with [specific
entry point] — a [duration] engagement focused on [persona's top priority]."}
```

**Content guidelines for customer view**:
- Target length: 800-1,500 words (focused and personal, not exhaustive)
- Reference the persona by role, not by name (the persona is a type, not a person)
- Filter ruthlessly — only propositions that match this persona's buying criteria
- Investment framing should match the persona's budget authority level
- If the customer profile has specific named companies or accounts, do NOT include them — this is persona-level, not account-level (ABM is handled by cogni-marketing)

---

## Citations

Customer-facing documents must cite **external source URLs** so readers can verify evidence claims. Never link to internal JSON entity file paths (`propositions/x.json`, `markets/y.json`) — these are meaningless to buyers.

**Inline format**: `<sup>[N]</sup>` in the body text — the number references the Sources footer.

**Source priority** (use the first available for each cited claim):
1. `evidence[].source_url` from the proposition — the original external source
2. `evidence[].source_url` from competitor or customer entities
3. No citation — use descriptive inline text instead (e.g., "(internal estimate)")

**Claims without external sources**: Market sizing, internal calculations, or LLM-derived estimates get no superscript citation. State the figure with a parenthetical qualifier.

**References footer**: End the document with a numbered sources section:

```markdown
---
## Sources

[1] [Source Title](https://source-url) — brief context
[2] [Source Title](https://source-url) — brief context
```

Customer narratives are self-paced reading — keep citations unobtrusive. A Sources footer at the end is cleaner than heavy inline linking.

---

## Tone Transformation Examples

These examples illustrate how to transform internal language into customer-facing prose.

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
