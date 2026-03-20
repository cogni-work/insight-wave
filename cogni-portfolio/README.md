# Portfolio Messaging Plugin

A portfolio messaging and proposition planning plugin for [Claude Cowork](https://claude.ai/cowork). Helps SMEs build structured, market-specific value propositions using the IS/DOES/MEANS (FAB) framework — from product definition through competitive analysis to export-ready deliverables.

> **Note**: This plugin assists with B2B messaging strategy and portfolio planning. All outputs — especially market sizing, competitive intelligence, and claim verification — should be reviewed by domain experts before use in sales materials, proposals, or strategic decisions.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

## Skills

| Skill | Description |
|-------|-------------|
| `portfolio-setup` | Create a new portfolio project — capture company context, initialize directory structure, and generate portfolio.json |
| `products` | Define and manage named product offerings with positioning, pricing tier, maturity, and versioning |
| `features` | Add market-independent capabilities (IS layer) per product, with bulk import from documentation |
| `portfolio-ingest` | Extract portfolio entities from uploaded documents (md, docx, pptx, xlsx, pdf) in the uploads folder |
| `markets` | Discover and size target markets with TAM/SAM/SOM — via LLM estimation or delegated web research |
| `propositions` | Generate IS/DOES/MEANS messaging for each Feature x Market pair, individually or in batch |
| `solutions` | Define implementation plans and pricing tiers (PoV/S/M/L) per proposition for customer business cases |
| `packages` | Bundle solutions into sellable packages per Product x Market combination with tiered pricing |
| `compete` | Analyze 3-5 competitors per proposition with positioning, strengths, weaknesses, and differentiation |
| `customers` | Create ideal customer profiles and buyer personas per target market |
| `portfolio-verify` | Orchestrate claim verification for research-backed assertions (delegates to cogni-claims plugin) |
| `synthesize` | Generate structured messaging repository with per-market summaries and integrated claim status |
| `portfolio-export` | Produce deliverables — proposition proposals, market briefs, portfolio workbooks (markdown and XLSX) |
| `portfolio-dashboard` | Generate an interactive HTML dashboard showing the full portfolio status |
| `portfolio-scan` | Discover a company's service offerings via web research, classify against a portfolio taxonomy template (e.g., B2B ICT: 8 dimensions / 57 categories), and import as portfolio entities |
| `tips-bridge` | Bidirectional integration between cogni-tips TIPS analysis and cogni-portfolio product portfolio |
| `portfolio-resume` | Detect current workflow phase and recommend next actions for an existing project |

## Agents

| Agent | Description |
|-------|-------------|
| `market-researcher` | Web research agent for TAM/SAM/SOM sizing data with claim submission for verification |
| `competitor-researcher` | Web research agent for competitive intelligence per proposition with claim tracking |
| `customer-researcher` | Web research agent for named customer profiling and industry context |
| `customer-review-assessor` | Reviews customer profiles for completeness, accuracy, and sales actionability |
| `proposition-generator` | Generates IS/DOES/MEANS messaging for a single Feature x Market pair with optional web research |
| `proposition-quality-assessor` | Reviews propositions for messaging quality, evidence strength, and market fit |
| `solution-planner` | Plans implementation phases and pricing tiers for a single proposition |
| `solution-review-assessor` | Reviews solutions for pricing viability, implementation feasibility, and tier differentiation |
| `feature-quality-assessor` | Assesses feature description quality using LLM intelligence — works in any language |
| `quality-enricher` | General-purpose quality enrichment agent for iterative improvement cycles |
| `portfolio-web-researcher` | Template-parameterized parallel web research agent for portfolio scanning across taxonomy dimensions |

## Example Workflows

### Full Portfolio Build

1. Run `/portfolio-setup` to create a new project and define your company context
2. (Optional) Drop existing documents into `uploads/` and run `/portfolio-ingest` to import data
3. Run `/products` to define your named offerings
4. Run `/features` to add capabilities per product
5. Run `/markets` to discover and size 3-7 target markets
6. Run `/propositions` to generate IS/DOES/MEANS messaging for all Feature x Market pairs
7. Run `/solutions` to define implementation plans and pricing tiers
8. Run `/compete` to analyze competitors per proposition
8. Run `/customers` to create buyer personas per market
9. Run `/portfolio-verify` to check research-backed claims against sources
10. Run `/synthesize` to generate the messaging repository
11. Run `/portfolio-export` to produce proposals, briefs, and workbooks

### Resume Existing Work

1. Run `/portfolio-resume` to detect your current phase and see progress (also detects unprocessed uploads)
2. Follow the recommended next action

### Quick Market Entry Analysis

1. Run `/portfolio-setup` with a focused product scope
2. Run `/features` to define key capabilities
3. Run `/markets` with web research for validated sizing
4. Run `/propositions` to generate messaging for priority markets
5. Run `/portfolio-export market-brief` to produce market-specific content

## Data Model

All entities are stored as JSON files in the project directory:

| Entity | Storage | Key Fields |
|--------|---------|------------|
| Project | `portfolio.json` | company name, description, industry |
| Product | `products/{slug}.json` | name, positioning, pricing tier, maturity |
| Feature | `features/{slug}.json` | product_slug, name, description, category |
| Market | `markets/{slug}.json` | name, segmentation, TAM/SAM/SOM |
| Proposition | `propositions/{feature}--{market}.json` | IS/DOES/MEANS statements, evidence |
| Solution | `solutions/{feature}--{market}.json` | implementation phases, pricing tiers (PoV/S/M/L) |
| Competitor | `competitors/{feature}--{market}.json` | name, positioning, strengths, weaknesses |
| Customer | `customers/{market}.json` | role, pain points, buying criteria |

## Dependencies

This plugin works standalone for core messaging workflows. Optional integrations enhance specific capabilities:

- **cogni-claims plugin** — Required for `/portfolio-verify` (claim verification against cited sources)
- **document-skills plugin** — Required for `/portfolio-ingest` (docx, pptx, xlsx, pdf extraction) and XLSX export in `/portfolio-export`

> **Note:** Without these plugins, you can still build the full portfolio through synthesis. Verification and XLSX export will be unavailable.

## Architecture

```
cogni-portfolio/
├── .claude-plugin/plugin.json    Plugin manifest
├── templates/                    Pluggable taxonomy templates
│   └── b2b-ict/                 B2B ICT taxonomy (8 dims, 57 cats)
├── skills/                       17 portfolio skills
│   ├── portfolio-setup/
│   ├── products/
│   ├── features/
│   ├── portfolio-ingest/
│   ├── markets/
│   ├── propositions/
│   ├── solutions/
│   ├── packages/
│   ├── compete/
│   ├── customers/
│   ├── portfolio-verify/
│   ├── synthesize/
│   ├── portfolio-export/
│   ├── portfolio-dashboard/
│   ├── portfolio-scan/
│   ├── tips-bridge/
│   └── portfolio-resume/
├── agents/                       11 delegation agents
│   ├── market-researcher.md
│   ├── competitor-researcher.md
│   ├── customer-researcher.md
│   ├── customer-review-assessor.md
│   ├── proposition-generator.md
│   ├── proposition-quality-assessor.md
│   ├── solution-planner.md
│   ├── solution-review-assessor.md
│   ├── feature-quality-assessor.md
│   ├── quality-enricher.md
│   └── portfolio-web-researcher.md
└── scripts/                      7 utility scripts
    ├── append-claim.sh
    ├── cascade-rename.sh
    ├── project-init.sh
    ├── project-status.sh
    ├── sync-portfolio.sh
    ├── validate-entities.sh
    └── generate-scan-mapping.sh
```

## Custom development

Need a custom taxonomy template, industry-specific frameworks, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
