---
name: portfolio-communicate
description: |
  Generate customer-facing portfolio documentation as markdown — general overview,
  market-tailored views, or customer-tailored views. Use whenever the user mentions
  "communicate portfolio", "portfolio for customers", "customer-facing documentation",
  "portfolio documentation", "present portfolio", "portfolio overview for customers",
  "what do we offer", "capability overview", "service catalog", "customer documentation",
  "external portfolio", "portfolio narrative", or wants to turn internal portfolio data
  into something a buyer or executive can read — even if they don't say "communicate"
  explicitly. Also trigger when the user has completed synthesize or export and asks
  "how do I present this to customers" or "make this customer-ready".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Portfolio Communicate

Generate customer-facing markdown documentation from portfolio entities. Where `synthesize` produces an internal messaging repository (tables, matrices, gap flags) and `portfolio-export` produces per-proposition proposals and per-market briefs, this skill produces **portfolio-level narratives** that present the company's offerings through the buyer's lens.

## Core Concept

Internal portfolio documentation serves internal teams — it exposes gaps, uses slugs, shows TAM/SAM/SOM numbers, and organizes by entity type. Customers never see that. What they need is a value-led story: what the company does for people like them, why it matters, and what engaging looks like.

This skill reads the same entity files as synthesize and export, but transforms them with a different lens:

| Internal (synthesize) | Customer-facing (communicate) |
|----------------------|------------------------------|
| Feature IS descriptions | Capabilities framed as customer value |
| TAM/SAM/SOM numbers | Market context from the buyer's perspective |
| Proposition matrices | Value stories organized by buyer need |
| Gap flags and coverage | Omitted — only present what exists |
| Competitor analysis tables | Differentiation woven into the narrative |

The output is self-contained markdown designed for two paths:
1. **Direct use** — readable in Obsidian, GitHub, email, or any markdown renderer
2. **Pipeline input** — feed into `cogni-narrative` for arc transformation, then to `story-to-web`, `story-to-slides`, or `story-to-big-picture` for visual formats

## Prerequisites

Verify the portfolio is sufficiently complete before generating customer-facing content:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/validate-entities.sh "<project-dir>"
bash $CLAUDE_PLUGIN_ROOT/scripts/project-status.sh "<project-dir>"
```

Minimum requirements:
- At least 1 product, 1 feature (with valid product_slug), 1 market, and 1 proposition
- `portfolio.json` has company context filled in

Running `synthesize` first is recommended as a quality gate — if the internal messaging repository reads well, customer-facing output will be strong. Not strictly required.

If `cogni-claims/claims.json` exists, check claim verification status. Warn about unverified claims and recommend running the `verify` skill first. Allow the user to proceed — omit unverified claims from customer-facing output rather than flagging them (unlike synthesize which marks them).

## Output Levels

Three levels of customer-facing documentation, each progressively more tailored:

### 1. Portfolio Overview

**Output**: `output/communicate/portfolio-overview.md`

The general entry point — presents the full company offering as a coherent story. Covers all products and key capabilities without market-specific tailoring. Suitable for website "What We Do" content, general capability decks, or first-contact materials.

### 2. Market-Tailored View

**Output**: `output/communicate/market/{market-slug}.md`

Filtered for a specific target market. Shows only propositions, solutions, and competitive positioning relevant to that market's buyers. Reframes capabilities through the buyer's needs and language. Suitable for segment-specific landing pages, targeted outreach, or market entry materials.

### 3. Customer-Tailored View

**Output**: `output/communicate/customer/{market-slug}--{persona}.md`

Personalized for a specific buyer persona within a market. Opens with the persona's pain points, filters propositions by their buying criteria, and frames investment for their budget authority level. Suitable for executive briefings, personalized pitch prep, or account-based outreach.

## Workflow

### 1. Determine Scope

Infer the scope from the user's request. Only ask for clarification if genuinely ambiguous.

If the request is vague ("communicate portfolio to customers"), present the options:
- **Overview** — general portfolio documentation for any audience
- **Market** — tailored for a specific market (which one?)
- **Customer** — tailored for a specific buyer persona (which market and persona?)
- **All** — overview + all markets + all customer personas

### 2. Load Entities

Read entity files from the project directory:
- `portfolio.json` for company context and language
- All `products/*.json`, `features/*.json`
- All `propositions/*.json` (filter by market for tailored views)
- All `solutions/*.json` and `packages/*.json` (if available)
- `markets/*.json` and `customers/*.json` (for tailored views)
- `competitors/*.json` (for differentiation, woven into narrative)

**Internal context (optional):** If `context/context-index.json` exists, read relevant entries. Strategic context enriches the company positioning. Competitive context sharpens differentiation claims. Incorporate high-confidence context naturally into the narrative.

### 3. Generate Markdown

Before generating any output, read `references/output-templates.md` for the complete template structure, section guidance, and tone transformation examples. Apply these writing principles throughout:

**Voice**: Write from the company's perspective speaking to the buyer. Use "we" for the company, "you" for the buyer. Professional but conversational — not a brochure, not a contract.

**Value-led structure**: Lead every section with what the buyer gains, not what the product is. DOES and MEANS statements before IS. The buyer's problem before the company's solution.

**No internal leakage**: Never expose slugs, entity types, sort_order, TAM/SAM/SOM figures, gap flags, coverage percentages, cost models, or internal margins. These are internal planning artifacts.

**Evidence over assertions**: Where propositions have evidence arrays, weave specific data points and outcomes into the narrative. Skip unverified claims entirely — only include verified or unchecked (no claims system) evidence.

**Differentiation, not comparison**: Draw on competitor analysis to sharpen positioning without naming competitors or making comparative claims. "We do X" is stronger than "Unlike others, we do X."

**Packages over features**: When packages exist for a product x market, present the bundled offering rather than listing individual features. Buyers think in solutions, not feature lists.

### 4. Present Results and Suggest Next Steps

List generated files with paths. Then suggest the downstream pipeline:

- **Polish prose**: "Run `/copywrite` on any generated file to polish for executive readability"
- **Arc narrative**: "Run `/narrative --source-path output/communicate/portfolio-overview.md` to transform into an arc-driven executive narrative"
- **Visual formats** (after narrative): `/story-to-web` for landing pages, `/story-to-slides` for presentations, `/story-to-big-picture` for visual journey maps

## Important Notes

- Output goes to `output/communicate/` — separate from synthesize (`output/README.md`) and export (`output/proposals/`, `output/briefs/`)
- Re-running overwrites previous output for that scope
- Each generated file includes YAML frontmatter compatible with `cogni-narrative` input requirements
- **Content Language**: Read `portfolio.json` `language` field. Generate content in that language if present, default to English
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language. Technical terms, skill names, and CLI commands remain in English

## Additional Resources

### Reference Files

For detailed output templates including heading structure, section guidance, data source mapping, and tone examples:
- **`references/output-templates.md`** — Complete markdown templates for all three output levels
