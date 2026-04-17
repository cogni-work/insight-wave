# cogni-portfolio

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A [Claude Cowork](https://claude.ai/cowork) plugin for portfolio messaging and proposition planning. Helps SMEs build structured, market-specific value propositions using the IS/DOES/MEANS (FAB) framework — from product definition through competitive analysis and customer profiling to export-ready deliverables, across eight pluggable industry taxonomies (B2B SaaS, FinTech, HealthTech, MarTech, Industrial Tech, ICT, Professional Services, Commercial Open Source).

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

1. **Setup** — initialize a portfolio project with company context, taxonomy selection, and directory structure → `portfolio.json` → features, markets, products, portfolio-scan
2. **Scan** — discover what a company offers by scraping their website and classifying findings against the taxonomy → `features/*.json` + `products/*.json` → propositions, solutions
3. **Define features** — add market-independent capabilities (IS layer) per product → `features/*.json` → propositions, solutions, packages
4. **Define markets** — discover, evaluate, and size target markets with TAM/SAM/SOM → `markets/*.json` → propositions, solutions, customers
5. **Generate propositions** — create IS/DOES/MEANS messaging for each Feature x Market pair → `propositions/{feature}--{market}.json` → solutions, packages, compete
6. **Plan solutions** — define implementation phases and tiered pricing (PoV/S/M/L) → `solutions/{feature}--{market}.json` → packages, why-change. Products can define delivery blueprints capturing standard phases, pricing multipliers, and role ratios; the solution-planner uses these as structural templates and adapts per Feature x Market
7. **Define products** — manage top-level product offerings and link to features → `products/*.json` → features, propositions. Optional delivery blueprints standardize the delivery pattern across markets with drift detection when updated
8. **Build packages** — bundle solutions into sellable offerings per Product x Market → `packages/*.json` → portfolio-communicate
9. **Analyze competitors** — produce competitive landscape, battle cards, and differentiation per proposition → `competitors/*.json` → propositions
10. **Profile customers** — create ideal customer profiles and buyer personas per market → `customers/*.json` → portfolio-communicate
11. **Communicate** — generate pitches, proposals, briefs, workbooks, and documentation for any audience → `output/communicate/{use-case}/*.md` → copywriter, story-to-web, doc-readme-root
12. **Dashboard** — generate an interactive HTML status view of the full portfolio → `output/dashboard.html`
13. **Architecture diagram** — generate an Excalidraw product-feature hierarchy diagram → `output/architecture.excalidraw` → doc-readme-root
14. **Track source lineage** — register ingested documents and evidence URLs, detect changes, cascade refresh through dependent entities → `source-registry.json` → features, propositions, solutions

## What it means for you

- **Portfolio positioning in days, not weeks.** What used to take 2 weeks of analyst time per product line — market sizing, competitive mapping, proposition writing — runs in structured parallel with research agents.
- **Market-specific by design.** Every proposition is scoped to a Feature × Market pair, so one feature generates a distinct DOES/MEANS pitch per segment — no more single generic message stretched across 3–5 target markets.
- **Eight industry taxonomies built in.** B2B ICT (57 categories), SaaS, FinTech, HealthTech, MarTech, Industrial Tech, Professional Services, Commercial Open Source — auto-selected by company context.
- **Export-ready across four formats.** Proposals, market briefs, portfolio workbooks (markdown + XLSX), and an interactive HTML dashboard — one `portfolio-communicate` run produces all four from the same entity data.
- **Canvas to portfolio in one step.** Bootstrap a full portfolio directly from a Lean Canvas — extract products, features, and markets from a founding-stage hypothesis without a single field of manual re-entry.
- **Deep-dive without leaving the plugin.** Two dedicated research agents (`feature-deep-diver`, `proposition-deep-diver`) validate buyer language against live web evidence and propose refinements grounded in verifiable sources.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/portfolio-setup                           # create project, capture company context
/products                                  # define named offerings
/features                                  # add capabilities per product (IS layer)
/markets                                   # discover and size target markets
/propositions                              # generate IS/DOES/MEANS messaging
/customers                                 # create buyer personas per market
/solutions                                 # define implementation plans and pricing
/compete                                   # analyze competitors per proposition
/portfolio-verify                          # verify claims against sources
/portfolio-communicate                     # produce pitches, proposals, briefs, workbooks
/portfolio-dashboard                       # interactive HTML status dashboard
/portfolio-architecture                    # product-feature architecture diagram
/portfolio-lineage                         # track sources, detect drift, cascade refresh
```

Or just describe what you want in natural language:

- "Set up a portfolio project for our cloud services"
- "Generate propositions for all features in the enterprise segment"
- "Who are our top 3 competitors for managed security in mid-market?"
- "Export a market brief for the DACH healthcare vertical"
- "Bootstrap my portfolio from this lean canvas"
- "Deep dive into the managed-security feature"
- "Sharpen messaging for managed-security in mid-market"
- "Show me the architecture diagram for our portfolio"

## Try it

After installing, type one prompt:

> Set up a portfolio project for a cloud infrastructure company targeting mid-market SaaS

Claude captures your company context, auto-selects the B2B ICT taxonomy, initializes the project, and walks you through defining products, features, and target markets. From there, generate propositions, competitive analysis, and export-ready deliverables.

## Data model

All entities are stored as JSON files in the project directory:

| Entity | Storage | Key Fields |
|--------|---------|------------|
| Project | `portfolio.json` | company name, description, industry, taxonomy, delivery defaults |
| Product | `products/{slug}.json` | name, positioning, pricing tier, maturity, delivery_blueprint (optional) |
| Feature | `features/{slug}.json` | product_slug, name, description, category |
| Market | `markets/{slug}.json` | name, segmentation, TAM/SAM/SOM |
| Proposition | `propositions/{feature}--{market}.json` | IS/DOES/MEANS statements, evidence, quality score |
| Solution | `solutions/{feature}--{market}.json` | implementation phases, pricing tiers (PoV/S/M/L), blueprint_ref + blueprint_version (when generated from blueprint) |
| Competitor | `competitors/{feature}--{market}.json` | name, positioning, strengths, weaknesses |
| Customer | `customers/{market}.json` | role, pain points, buying criteria |
| Package | `packages/{product}--{market}.json` | bundled solution tiers |
| Source Registry | `source-registry.json` | document/URL fingerprints, entity links, staleness |

See [references/data-model.md](references/data-model.md) for the full schema with JSON examples and entity relationships.

## How it works

Each portfolio project lives in `cogni-portfolio/{slug}/` with typed JSON files organized by entity. The workflow follows a logical progression: setup → products → features → markets → propositions → customers → solutions → compete → verify → communicate. Research-intensive steps (market sizing, competitive analysis, customer profiling) dispatch parallel web-research agents. Propositions are scored by quality assessors against DOES/MEANS criteria, with a quality gate for downstream consumption.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `portfolio-setup` | skill | Initialize a new portfolio project with company context and directory structure |
| `portfolio-canvas` | skill | Bootstrap a portfolio project from a Lean Canvas or Business Model Canvas |
| `portfolio-scan` | skill | Discover offerings via website scanning and classify against taxonomy |
| `portfolio-ingest` | skill | Extract portfolio entities from uploaded documents (md, docx, pptx, xlsx, pdf) |
| `products` | skill | Define and manage the top-level product offerings in the portfolio |
| `features` | skill | Define and manage market-independent product features (IS layer of FAB) |
| `markets` | skill | Discover, evaluate, and size target markets for the portfolio |
| `propositions` | skill | Generate and manage IS/DOES/MEANS (FAB) value propositions per Feature x Market pair |
| `solutions` | skill | Define implementation plans and pricing tiers for propositions |
| `packages` | skill | Bundle solutions into sellable packages per Product x Market combination |
| `compete` | skill | Analyze competitors — competitive landscape, battle cards, positioning, differentiation |
| `customers` | skill | Create ideal customer profiles and buyer personas per target market |
| `portfolio-verify` | skill | Verify web-sourced claims in portfolio entities against their cited sources |
| `portfolio-communicate` | skill | Generate portfolio deliverables for any audience (pitches, proposals, briefs, workbooks, docs) |
| `portfolio-dashboard` | skill | Generate an interactive HTML dashboard showing the full portfolio status |
| `portfolio-architecture` | skill | Generate an interactive Excalidraw architecture diagram of products and features |
| `portfolio-lineage` | skill | Track source documents and URLs, detect changes, cascade refresh through features → propositions → solutions |
| `trends-bridge` | skill | Bidirectional integration between cogni-trends TIPS analysis and the portfolio |
| `portfolio-resume` | skill | Resume, continue, or check status of a portfolio project |
| `market-researcher` | agent | Web research for TAM/SAM/SOM with claim submission |
| `competitor-researcher` | agent | Web research for competitive intelligence per proposition |
| `customer-researcher` | agent | Web research for named company profiling per target market |
| `customer-narrative-writer` | agent | Generate a single customer-narrative markdown file (one scope) from portfolio entities — enables parallel fan-out |
| `customer-review-assessor` | agent | Assess customer profile quality from three stakeholder perspectives |
| `proposition-generator` | agent | Generate IS/DOES/MEANS messaging for a single Feature x Market combination |
| `proposition-quality-assessor` | agent | Assess DOES/MEANS messaging quality in propositions (any language) |
| `proposition-review-assessor` | agent | Assess proposition set from buyer, sales, and product manager perspectives |
| `proposition-deep-diver` | agent | Deep research — buyer language validation, competitive messaging, evidence enrichment |
| `solution-architect` | agent | Propose delivery blueprints and shared solution eligibility per product |
| `solution-planner` | agent | Plan implementation phases and pricing tiers for a single proposition |
| `solution-review-assessor` | agent | Assess solution quality from procurement, provider SA, and client SA perspectives |
| `feature-quality-assessor` | agent | Assess feature description quality using LLM intelligence (any language) |
| `feature-review-assessor` | agent | Assess feature set quality from PM, proposition strategist, and pre-sales perspectives |
| `feature-deduplication-detector` | agent | Detect set-wide duplicate features within a single product using lexical and semantic similarity — works in any language |
| `feature-deep-diver` | agent | Deep research — competitive landscape, technical differentiation, market positioning |
| `quality-enricher` | agent | Research company-specific information to improve features or propositions with quality gaps |
| `communicate-review-assessor` | agent | Assess portfolio communication quality from stakeholder perspectives |
| `dashboard-refresher` | agent | Regenerate the portfolio dashboard HTML from current entity data |
| `portfolio-web-researcher` | agent | Domain-scoped web research for taxonomy-driven portfolio scanning |
| `ensure-excalidraw-canvas` | hook (PreToolUse) | Auto-start the Excalidraw canvas frontend before any `mcp__excalidraw__*` tool call |

## Architecture

```
cogni-portfolio/
├── .claude-plugin/               Plugin manifest
├── templates/                    8 pluggable industry taxonomy templates
│   ├── b2b-ict/                  Enterprise ICT (8 dims, 57 cats)
│   ├── b2b-saas/                 B2B SaaS (8 dims, 47 cats)
│   ├── b2b-fintech/              FinTech (8 dims, 48 cats)
│   ├── b2b-healthtech/           HealthTech (8 dims, 46 cats)
│   ├── b2b-martech/              MarTech (8 dims, 45 cats)
│   ├── b2b-industrial-tech/      Industrial Tech (8 dims, 48 cats)
│   ├── b2b-professional-services/ Professional Services (8 dims, 44 cats)
│   └── b2b-opensource/           Commercial Open Source (8 dims, 50 cats)
├── skills/                       19 portfolio skills
│   └── portfolio-canvas-workspace/ Dev workspace (evals, iterations — not a skill)
├── agents/                       20 delegation agents
├── hooks/                        1 guardrail hook (Excalidraw canvas auto-start)
├── references/
│   └── data-model.md             Full entity schema and project structure reference
└── scripts/                      10 utility scripts
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | No | Pitch use case reads arc definitions for narrative structure; output is directly consumable by story-to-slides and story-to-web |
| cogni-visual | No | Pitch output consumable by story-to-slides, story-to-web, and story-to-storyboard |
| cogni-marketing | No | Customer narratives from portfolio-communicate are auto-discovered by marketing-setup for voice/messaging enrichment |
| cogni-claims | No | Claim verification for research-backed assertions via portfolio-verify |
| cogni-trends | No | Bidirectional TIPS integration via trends-bridge |
| cogni-workspace | No | Theme selection for portfolio-dashboard via pick-theme |
| cogni-consulting | No | Lean Canvas extraction via portfolio-canvas (canvases from business-model-hypothesis vision class) |
| cogni-sales | No | Downstream consumer — why-change pitch builds on portfolio features and propositions |
| document-skills | No | Document ingestion (docx, pptx, xlsx, pdf) via portfolio-ingest; XLSX export via portfolio-communicate |

cogni-portfolio is standalone for core messaging workflows. All integrations are optional and activate when the respective plugin is installed.

## Contributing

Contributions welcome — taxonomy templates, quality assessment dimensions, export formats, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom taxonomy template, industry-specific frameworks, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
