# Templates: Proposal

Output templates for the `proposal` use case. Transforms a specific proposition (Feature × Market) into a sales-ready proposal document.

**Use case**: `proposal`
**Audience**: Sales teams, prospect-specific customization, buyer evaluation
**Voice**: Company speaks to buyer ("we"/"you"). Professional and direct — lead with value, not preamble. Avoid marketing superlatives in favor of specific, defensible claims.

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

{From the proposition's evidence array. Present as brief case studies
or data points. Mark any [unverified] claims clearly.

If cogni-claims/claims.json exists, cross-reference evidence statements
and mark unverified or deviated claims with [unverified].}

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
