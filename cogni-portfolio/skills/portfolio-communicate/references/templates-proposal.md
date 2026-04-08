# Templates: Proposal

Output templates for the `proposal` use case. Transforms a specific proposition (Feature × Market) into a sales-ready proposal document.

**Use case**: `proposal`
**Audience**: Sales teams, prospect-specific customization, buyer evaluation
**Voice**: Company speaks to buyer ("we"/"you"). Professional and direct — lead with value, not preamble. Avoid marketing superlatives in favor of specific, defensible claims.

---

## Handling messaging mode

A proposal is a *commercial commitment document*. It ends with a call to action for a specific engagement at a specific scope at a specific price. That only makes sense for offerings the company can actually deliver today. The messaging mode (see SKILL.md → Maturity-Aware Messaging) decides whether a proposal can be generated at all.

**announce mode → block generation.** If the proposition's parent product is in `maturity: concept` (or `development` with only `planned` features), the skill must **refuse to write a proposal** for that proposition and instead return a short explanation to the user:

> "The proposition `{feature-slug}--{market-slug}` belongs to product `{product-slug}`, which is currently in concept stage. A sales proposal would commit to delivering something that does not yet exist. Generate a `pitch` instead — it will surface this proposition as a future-outlook signal — or wait until the product reaches preview/launch. If you need to document intent for an internal stakeholder, consider a `market-brief` (which separates 'Available now' from 'Roadmap')."

For the `market` and `all` scopes, silently skip announce-mode propositions and list them in the batch summary as "skipped — concept stage" rather than blocking the entire run.

**preview mode → allowed with qualifiers.** Proposals may be generated for propositions whose product is in preview (beta) mode, but every such proposal must:
- Carry an **Early Access** banner at the top of the document body (below the frontmatter): *"This offering is currently in early access. Availability, scope and pricing are subject to change before general availability."*
- Label the Investment section pricing as "Introductory pricing — valid for early-access engagements only".
- Reframe the Evidence section items as "Early pilot results" rather than delivered outcomes.
- Soften the "Next Steps" CTA from a hard pilot booking to a design-partner or early-access application.

**launch mode → allowed, full voice.** Same treatment as standard, but the Executive Summary may lead with recency ("Recently released for…"). No other changes.

**standard mode** is the baseline the rest of this template describes.

**sunset mode → block generation.** Treat `decline` the same way as `announce`: refuse and explain, on the grounds that a proposal for a product the company is not accepting new engagements on is actively misleading.

---

## YAML Frontmatter

```yaml
---
title: "{MEANS statement as headline}"
type: portfolio-proposal
proposition: "{feature-slug}--{market-slug}"
feature: "{feature-slug}"
market: "{market-slug}"
product: "{product-slug}"
language: "{en|de}"
date_created: "{ISO 8601}"
relevance_tier: "{high|medium|low}"
---
```

---

## Proposal Structure

**Output**: `output/communicate/proposal/{feature-slug}--{market-slug}.md`

**Data sources**: The proposition, its feature, its product, the market, the customer profile, the competitor analysis, the solution (if available), and the package (if available at `packages/{product}--{market}.json`).

**Target length**: 1-2 pages. Enough to be useful, short enough to actually get read.

```markdown
# {Proposition headline — the MEANS statement}

## Executive Summary

{2-3 sentences: what we offer (IS), what it does for this buyer (DOES),
why it matters (MEANS). This is the entire proposal compressed into a paragraph.}

## The Challenge

{Customer pain points from the customer profile. Frame the buyer's world
before the solution exists — make them feel understood. Reference specific
pain points from customers/{market-slug}.json.

If no customer profile exists, derive challenges from the market description
and proposition DOES statement. Flag internally that customer profiles would
strengthen this section.}

## Our Approach

{IS and DOES statements expanded. Explain the capability and its
market-specific advantage. Be concrete — name the feature, describe
the mechanism, quantify the improvement where evidence supports it.}

## Why Us

{Differentiation from competitor analysis. Don't trash competitors —
position the proposition's unique angle. Reference specific competitor
weaknesses only where they contrast with genuine strengths.

Skip this section entirely if no competitor data exists — don't invent
differentiation.}

## Evidence

{From the proposition's evidence array. Present each evidence item as a
brief case study or data point, linked to its external source:

Format: "[Statement derived from evidence] — [source_title](source_url)"

Use `evidence[].source_url` and `evidence[].source_title` from the proposition.
If an evidence item has no source_url, present the statement without a link
and mark it "(unverified)".

If cogni-claims/claims.json exists, cross-reference evidence statements
and mark unverified or deviated claims with [unverified].

Never link to internal JSON entity file paths — always use external URLs.}

## Implementation Approach

{From the solution — adapt to solution type:
- Project solutions: implementation phases with durations
- Subscription solutions: onboarding summary (1-2 weeks)
- Partnership solutions: program stages with milestones

Only include if a solution exists for this proposition. Skip entirely
if no solution has been defined.}

## Investment

{**Prefer packages when available.** Check if a package exists for this
proposition's product × market (packages/{product}--{market}.json).
If a package exists, present the package tiers (which bundle this
feature with related capabilities) instead of individual solution pricing.
This shows the buyer the full product offering, not isolated feature pricing.

If no package exists, fall back to individual solution pricing:
- Project solutions: pricing tiers table (PoV, Small, Medium, Large)
  with price, currency, and scope. Framed as investment levels.
- Subscription solutions: subscription tiers table (Free, Pro, Enterprise)
  with monthly/annual pricing and scope.
- Partnership solutions: program stages with commitment levels and
  revenue-share terms.
- Hybrid: subscription tiers + optional project services.

**CRITICAL**: Never include cost_model data in customer-facing proposals.
Internal costs, margins, role rates, effort days, CAC/LTV, and unit
economics are confidential. Only external pricing (package tiers, project
tiers, subscription tiers, or partnership terms) and delivery approach
(implementation phases or onboarding) appear in proposals.

Only include if a solution or package exists. Skip entirely otherwise.}

## Next Steps

{Concrete call to action appropriate for B2B context:
demo scheduling, pilot program, technical evaluation.
Frame as exploration, not commitment.}
```

---

## Relevance Tier Ordering

When generating multiple proposals (scope `market` or `all`):

1. Generate high-tier propositions first (GA feature + beachhead market)
2. Then medium-tier
3. Skip low-tier and skip-tier unless the user explicitly requests them
4. Never generate for excluded Feature × Market pairs

Within a tier, order by market (beachhead first, then expansion).

---

## Content Guidelines

- Every section should pass the "so what?" test — if removing it loses nothing for the buyer, cut it
- Proposals without competitor data skip "Why Us" rather than inventing differentiation
- Proposals without solutions skip "Implementation Approach" and "Investment"
- A proposal with only IS/DOES/MEANS and customer challenges is still valuable — it frames the conversation
- Use buyer language from the customer profile, not internal proposition labels
