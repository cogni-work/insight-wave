---
name: marketing-setup
description: "Initialize a cogni-marketing project by discovering cogni-trends and cogni-portfolio sources, configuring brand voice, and selecting markets with GTM paths. Use this skill when the user asks to 'set up marketing', 'create a marketing project', 'initialize marketing', 'start marketing content', 'configure brand', 'marketing setup', or wants to begin creating marketing content for a portfolio — even if they don't say 'setup' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Marketing Setup

## Purpose

Initialize a cogni-marketing project by:
1. Discovering available cogni-trends and cogni-portfolio projects
2. Configuring brand identity and voice
3. Selecting target markets from portfolio
4. Mapping TIPS strategic themes to GTM paths per market
5. Scaffolding the project directory

## Prerequisites

- At least one cogni-portfolio project with products, features, and markets defined
- At least one cogni-trends project with value-modeler completed (strategic themes + ranked solution templates)

## Workflow

### Step 0: Project Discovery

Scan the working directory for existing sources:

1. **Find cogni-portfolio projects**: Glob for `**/portfolio.json` files. For each, read to confirm it has `products` and `markets` populated.
2. **Find cogni-trends projects**: Glob for `**/tips-project.json` files. For each, check that `tips-value-model.json` exists alongside it (value-modeler completed).
3. **Find existing marketing projects**: Glob for `**/marketing-project.json` to avoid duplicates.
4. **Find portfolio-communicate output** (optional enrichment): For each discovered portfolio project, check if `output/communicate/customer-narrative/` exists. If it does, list the files found (overview, market-level, customer-level narratives). These are pre-written audience-tailored narratives that content generation skills can reference for richer voice and messaging consistency. Store discovered paths in `marketing-project.json` under `sources.enriched_portfolio_narratives`.

Present discovered sources to user:
```
Portfolio projects found:
  1. acme-cloud (4 products, 3 markets, 12 propositions)
     └─ Customer narratives: 1 overview, 3 market, 5 persona (enrichment available)
  2. beta-services (2 products, 1 market, 4 propositions)

TIPS projects found:
  1. b2b-ict-ai-trends (5 themes, 18 solution templates)
  2. manufacturing-digital (4 themes, 12 solution templates)
```

If customer narratives were found, note this briefly — they will be available as optional enrichment for content generation skills (voice consistency, messaging alignment).

Ask user to select one portfolio and one TIPS project. If only one of each exists, confirm automatically.

### Step 1: Brand Configuration

Ask user for brand details. Provide smart defaults from portfolio company data:

```
Brand name: [from portfolio.json company.name]
Brand voice: [suggest based on industry]
CTA style: soft-ask | direct | value-exchange
Visual direction: [optional, for creative briefs]
```

**Industry-based voice defaults:**
- B2B ICT / Technology: "authoritative, data-driven, forward-looking"
- Consulting / Professional Services: "trusted advisor, insight-led, pragmatic"
- Manufacturing / Industrial: "reliable, precision-focused, results-oriented"

For tone modifiers, use the defaults from `${CLAUDE_PLUGIN_ROOT}/references/content-formats.md` — user can override later.

### Step 2: Market Selection

Read all markets from the portfolio project (`markets/*.json`). Present with key metrics:

```
Available markets:
  1. [primary] mid-market-saas-dach — TAM €2.4B, 3 propositions, 2 competitors
  2. [expansion] enterprise-manufacturing-dach — TAM €5.1B, 4 propositions, 3 competitors
  3. [aspirational] startup-fintech-eu — TAM €800M, 1 proposition, 0 competitors
```

Ask user to select markets and set priority (primary/secondary). Recommend starting with primary/expansion markets that have the most propositions.

### Step 3: GTM Path Mapping

For each selected market, read the TIPS value model (`tips-value-model.json`). Present strategic themes ranked by solution ranking value:

```
GTM paths for mid-market-saas-dach:
  Theme                          | Ranking | Top ST readiness | Recommendation
  AI-Driven Predictive Maint.    | 4.2     | 0.82             | ★ Primary GTM path
  Cloud-Native Transformation    | 3.8     | 0.64             | ★ Secondary
  Sustainability Reporting       | 3.1     | 0.45             | Consider later
  Legacy Modernization           | 2.4     | 0.31             | Low priority
```

For each theme, show which portfolio propositions map to it (via solution template → portfolio anchor → proposition). Ask user to select 2-4 GTM paths per market.

For each selected GTM path, determine funnel focus (must use schema enum: `awareness|consideration|decision|full-funnel`):
- High readiness (≥0.7) + strong propositions → **full-funnel** (all stages, awareness through decision)
- Medium readiness (0.4-0.7) → **consideration** (awareness + consideration content, not yet ready for hard sell)
- Low readiness (<0.4) → **awareness** (thought leadership positioning only)

### Step 4: Content Defaults

Present default content settings from `${CLAUDE_PLUGIN_ROOT}/references/content-formats.md`. Ask:

> "These are the default content specifications. Would you like to adjust any word counts, formats, or cadence? Or proceed with defaults?"

### Step 5: Scaffold Project

Determine project slug: `{brand-name}-marketing` (kebab-case).

Create directory structure:
```bash
mkdir -p cogni-marketing/{slug}/content/{thought-leadership,demand-generation,lead-generation,sales-enablement,abm}
mkdir -p cogni-marketing/{slug}/{campaigns,calendar,output/exports,.logs}
```

Write `marketing-project.json` with all configured data following the schema in `${CLAUDE_PLUGIN_ROOT}/references/data-model.md`.

### Step 6: Summary & Next Steps

Display project summary:
```
Marketing project initialized: {slug}
  Brand: {name} ({voice})
  Language: {language}
  Markets: {count} ({list})
  GTM paths: {count} across {market_count} markets
  Source portfolio: {path}
  Source TIPS: {path}

Next steps:
  1. Run /content-strategy to build the content matrix
  2. Or jump directly to /thought-leadership for your first content piece
```

## Validation Gates

- **Hard gate**: Portfolio project must have at least 1 product + 1 feature + 1 market
- **Hard gate**: TIPS project must have value-modeler output (tips-value-model.json with themes)
- **Soft warning**: Markets with 0 propositions — flag as "messaging not yet developed"
- **Soft warning**: GTM paths with readiness < 0.3 — flag as "solution blueprint incomplete"

## Language Handling

Read language from portfolio project's `portfolio.json` → `language` field. Default to the same for marketing. If TIPS project has a different language, ask user which to use for marketing output. Marketing projects can be bilingual — content is generated in the project language, with the option to generate parallel versions in the other language.
