# Templates: Market Brief

Output templates for the `market-brief` use case. Produces marketing content packages for a specific target market, covering all propositions that address it.

**Use case**: `market-brief`
**Audience**: Marketing teams, campaign planning, sales enablement
**Voice**: Internal-facing but polished. Data-rich, structured for marketing team consumption. Include market sizing, buyer profiles, and messaging angles that marketers can directly use in campaigns.

---

## YAML Frontmatter

```yaml
---
title: "{Market Name} — Marketing Brief"
type: portfolio-market-brief
market: "{market-slug}"
language: "{en|de}"
date_created: "{ISO 8601}"
proposition_count: {N}
product_count: {N}
---
```

---

## Market Brief Structure

**Output**: `output/communicate/market-brief/{market-slug}.md`

**Data sources**: The market definition, all propositions targeting this market, their parent features and products, customer profiles, and competitor analyses for those propositions.

**Target length**: 2-3 pages.

```markdown
# {Market Name} — Marketing Brief

## Market Overview

{From market definition: segmentation criteria (company size, revenue range,
vertical), TAM/SAM/SOM with sources, key market dynamics.

Unlike customer-facing content, include the full sizing data — marketing
teams need this for campaign planning and budget justification.}

## Target Buyer

{From customer profile (customers/{market-slug}.json): role, seniority,
pain points, buying criteria, decision role, information sources.

Write as a portrait of the person, not a data dump. Marketing teams
need to visualize who they're targeting to write effective copy.

If no customer profile exists, approximate from the market definition
and flag: "Buyer profile based on market definition — run /customers
for deeper persona research."}

## Value Propositions

{All propositions targeting this market, grouped by product.

For each proposition:
- One-line elevator pitch derived from the MEANS statement
- IS/DOES/MEANS breakdown
- Key evidence points (from evidence array)
- Relevance tier (high/medium/low)

Order: high-tier propositions first within each product group.
Include low-tier and skip-tier with appropriate flags — marketing
teams need visibility into the full portfolio, not just priorities.}

## Competitive Positioning

{Aggregated differentiation across all propositions in this market.
Identify 2-3 themes where the portfolio consistently wins.

Unlike proposals (which avoid naming competitors), briefs CAN name
competitors since this is internal marketing material. Include:
- Key competitor names and their positioning
- Where the portfolio differentiates
- Where competitors are strong (honest assessment helps messaging)}

## Recommended Messaging Themes

{3-5 messaging angles that cut across propositions. These are the
themes a marketing team would use in campaigns, not individual
proposition messages.

For each theme:
- Theme name (2-5 words)
- Core message (1 sentence)
- Supporting propositions (which portfolio capabilities back this theme)
- Suggested channels (based on buyer information sources from customer profile)}
```

---

## Content Guidelines

- TAM/SAM/SOM numbers belong in briefs (internal) but NOT in customer-facing content
- Competitor names belong in briefs (internal) but NOT in proposals or pitches
- Briefs are reference documents — completeness matters more than narrative flow
- Include relevance tiers so marketing can prioritize campaigns
- If the market has packages, mention them in the value propositions section to show commercial maturity
