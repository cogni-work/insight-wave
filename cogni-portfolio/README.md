# cogni-portfolio

A [Claude Cowork](https://claude.ai/cowork) plugin for portfolio messaging and proposition planning. Helps SMEs build structured, market-specific value propositions using the IS/DOES/MEANS (FAB) framework — from product definition through competitive analysis to export-ready deliverables.

## Why this exists

B2B companies know what they sell — but struggle to articulate why each market segment should care. The gap between product knowledge and market-specific messaging is where most positioning stalls:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Inside-out messaging | Product descriptions list features without connecting to buyer pain | Prospects don't see themselves in the pitch |
| No market differentiation | Same positioning for every segment — enterprise, mid-market, and SME hear identical value props | Messaging resonates with nobody specifically |
| Manual portfolio analysis | Sizing markets, mapping competitors, and writing propositions per Feature x Market takes weeks of analyst time | Portfolio positioning takes 2 weeks of work per product line |
| Scattered deliverables | Propositions, competitive intel, and pricing live in disconnected spreadsheets and slide decks | Sales teams can't find or trust the latest messaging |

## What it is

A structured portfolio messaging workflow for Claude Cowork. Eight pluggable taxonomy templates (B2B ICT, SaaS, FinTech, HealthTech, etc.) provide industry-standard classification. The IS/DOES/MEANS framework ensures every proposition answers: what IS the capability, what DOES it do for the buyer, and what does it MEAN for their business.

## What it does

1. **Setup** a portfolio project — capture company context, select industry taxonomy, initialize directory structure
2. **Define** products, features (IS layer), and target markets with TAM/SAM/SOM sizing
3. **Generate** IS/DOES/MEANS propositions for each Feature x Market pair — individually or in batch
4. **Plan** solutions with implementation phases and tiered pricing (PoV/S/M/L)
5. **Analyze** 3-5 competitors per proposition with positioning, strengths, weaknesses, and differentiation
6. **Profile** ideal customers and buyer personas per target market
7. **Verify** research-backed claims against cited sources via cogni-claims
8. **Synthesize** a structured messaging repository and export proposals, briefs, and workbooks

## What it means for you

- **Portfolio positioning in days, not weeks.** What used to take 2 weeks of analyst time per product line — market sizing, competitive mapping, proposition writing — runs in structured parallel with research agents.
- **Market-specific by design.** Every proposition is scoped to a Feature x Market pair. The same feature gets different DOES/MEANS messaging for enterprise vs. mid-market.
- **Eight industry taxonomies built in.** B2B ICT (57 categories), SaaS, FinTech, HealthTech, MarTech, Industrial Tech, Professional Services, Commercial Open Source — auto-selected by company context.
- **Export-ready.** Proposals, market briefs, portfolio workbooks (markdown and XLSX), and an interactive HTML dashboard — ready for sales, investors, or internal strategy.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

> **Note**: All outputs — especially market sizing, competitive intelligence, and claim verification — should be reviewed by domain experts before use in sales materials, proposals, or strategic decisions.

## Quick start

```
/portfolio-setup                           # create project, capture company context
/products                                  # define named offerings
/features                                  # add capabilities per product (IS layer)
/markets                                   # discover and size target markets
/propositions                              # generate IS/DOES/MEANS messaging
/solutions                                 # define implementation plans and pricing
/compete                                   # analyze competitors per proposition
/customers                                 # create buyer personas per market
/portfolio-verify                          # verify claims against sources
/synthesize                                # generate messaging repository
/portfolio-export                          # produce proposals, briefs, workbooks
/portfolio-dashboard                       # interactive HTML status dashboard
```

Or just describe what you want in natural language:

- "Set up a portfolio project for our cloud services"
- "Generate propositions for all features in the enterprise segment"
- "Who are our top 3 competitors for managed security in mid-market?"
- "Export a market brief for the DACH healthcare vertical"

## Try it

After installing, type one prompt:

> Set up a portfolio project for a cloud infrastructure company targeting mid-market SaaS

Claude captures your company context, auto-selects the B2B ICT taxonomy, initializes the project, and walks you through defining products, features, and target markets. From there, generate propositions, competitive analysis, and export-ready deliverables.

## Data model

All entities are stored as JSON files in the project directory:

| Entity | Storage | Key Fields |
|--------|---------|------------|
| Project | `portfolio.json` | company name, description, industry, taxonomy, delivery defaults |
| Product | `products/{slug}.json` | name, positioning, pricing tier, maturity |
| Feature | `features/{slug}.json` | product_slug, name, description, category |
| Market | `markets/{slug}.json` | name, segmentation, TAM/SAM/SOM |
| Proposition | `propositions/{feature}--{market}.json` | IS/DOES/MEANS statements, evidence, quality score |
| Solution | `solutions/{feature}--{market}.json` | implementation phases, pricing tiers (PoV/S/M/L) |
| Competitor | `competitors/{feature}--{market}.json` | name, positioning, strengths, weaknesses |
| Customer | `customers/{market}.json` | role, pain points, buying criteria |
| Package | `packages/{product}--{market}.json` | bundled solution tiers |

See [references/data-model.md](references/data-model.md) for the full schema with JSON examples and entity relationships.

## How it works

Each portfolio project lives in `cogni-portfolio/{slug}/` with typed JSON files organized by entity. The workflow follows a logical progression: setup → products → features → markets → propositions → solutions → compete → customers → verify → synthesize → export. Research-intensive steps (market sizing, competitive analysis, customer profiling) dispatch parallel web-research agents. Propositions are scored by quality assessors against DOES/MEANS criteria, with a quality gate for downstream consumption.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `portfolio-setup` | skill | Create project, capture company context, select taxonomy |
| `products` | skill | Define and manage named product offerings |
| `features` | skill | Add market-independent capabilities (IS layer) per product |
| `portfolio-ingest` | skill | Extract entities from uploaded documents (md, docx, pptx, xlsx, pdf) |
| `markets` | skill | Discover and size target markets with TAM/SAM/SOM |
| `propositions` | skill | Generate IS/DOES/MEANS messaging per Feature x Market |
| `solutions` | skill | Define implementation plans and tiered pricing |
| `packages` | skill | Bundle solutions into sellable packages per Product x Market |
| `compete` | skill | Analyze 3-5 competitors per proposition |
| `customers` | skill | Create ideal customer profiles and buyer personas |
| `portfolio-verify` | skill | Orchestrate claim verification via cogni-claims |
| `synthesize` | skill | Generate structured messaging repository |
| `portfolio-export` | skill | Produce proposals, briefs, and workbooks |
| `portfolio-dashboard` | skill | Interactive HTML dashboard |
| `portfolio-scan` | skill | Discover offerings via web research and classify against taxonomy |
| `trends-bridge` | skill | Bidirectional integration with cogni-trends TIPS analysis |
| `portfolio-resume` | skill | Detect workflow phase and recommend next actions |
| `market-researcher` | agent | Web research for TAM/SAM/SOM with claim submission |
| `competitor-researcher` | agent | Web research for competitive intelligence |
| `customer-researcher` | agent | Web research for named customer profiling |
| `customer-review-assessor` | agent | Reviews customer profiles for completeness |
| `proposition-generator` | agent | Generates IS/DOES/MEANS messaging with optional research |
| `proposition-quality-assessor` | agent | Reviews propositions for quality and evidence strength |
| `solution-planner` | agent | Plans implementation phases and pricing tiers |
| `solution-review-assessor` | agent | Reviews solutions for pricing viability |
| `feature-quality-assessor` | agent | Assesses feature description quality |
| `quality-enricher` | agent | General-purpose iterative improvement |
| `portfolio-web-researcher` | agent | Parallel web research across taxonomy dimensions |

## Architecture

```
cogni-portfolio/
├── .claude-plugin/plugin.json    Plugin manifest
├── templates/                    8 pluggable taxonomy templates
│   ├── b2b-ict/                  Enterprise ICT (8 dims, 57 cats)
│   ├── b2b-saas/                 B2B SaaS (8 dims, 47 cats)
│   ├── b2b-fintech/              FinTech (8 dims, 48 cats)
│   ├── b2b-healthtech/           HealthTech (8 dims, 46 cats)
│   ├── b2b-martech/              MarTech (8 dims, 45 cats)
│   ├── b2b-industrial-tech/      Industrial Tech (8 dims, 48 cats)
│   ├── b2b-professional-services/ Prof. Services (8 dims, 44 cats)
│   └── b2b-opensource/           Commercial OSS (8 dims, 50 cats)
├── skills/                       17 portfolio skills
├── agents/                       11 delegation agents
├── references/
│   └── data-model.md             Full entity schema
└── scripts/                      7 utility scripts
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-claims | No | Claim verification for research-backed assertions via portfolio-verify |
| document-skills | No | Document ingestion (docx, pptx, xlsx, pdf) and XLSX export |
| cogni-trends | No | Bidirectional TIPS integration via trends-bridge |
| cogni-consulting | No | Lean Canvas extraction via portfolio-canvas (canvases produced by business-model-hypothesis vision class) |

cogni-portfolio is standalone for core messaging workflows. Verification and XLSX export require their respective plugins.

## Custom development

Need a custom taxonomy template, industry-specific frameworks, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
