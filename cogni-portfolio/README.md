# cogni-portfolio

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Markets covered.** 25 pluggable regions — single-country (DE, FR, IT, ES, NL, PL, AT, CZ, SK, HU, RO, HR, GR, MK), composite (DACH, EU, Nordics, US/NA, APAC, LATAM, MEA), extended (CN, JP), and global (UK, Global) — market-segmented propositions, competitors, and customer personas — not one-size-fits-all.

> **Start here.** Run `/cogni-portfolio:portfolio-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

A [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai/cowork) plugin that builds market-specific value propositions on the IS/DOES/MEANS (FAB) framework, the proposition-planning anchor of the insight-wave ecosystem.

## Why this exists

B2B companies know what they sell — but struggle to articulate why each market segment should care. The gap between product knowledge and market-specific messaging is where most positioning stalls: the same pitch goes to every segment, the analysis lives in scattered decks, and the work has to be redone by hand the moment a market or competitor shifts.

| Problem | What happens | Impact |
|---------|-------------|--------|
| Inside-out messaging | Product descriptions list features without connecting to buyer pain | Prospects don't see themselves in the pitch |
| No market differentiation | Same positioning for every segment — enterprise, mid-market, and SME hear identical value props | Messaging resonates with nobody specifically |
| Manual portfolio analysis | Sizing markets, mapping competitors, and writing propositions per Feature x Market takes weeks of analyst time | Portfolio positioning takes 2 weeks of work per product line |
| Scattered deliverables | Propositions, competitive intel, and pricing live in disconnected spreadsheets and slide decks | Sales teams can't find or trust the latest messaging |

## What it is

A structured portfolio-messaging engine built on the IS/DOES/MEANS (FAB) framework and a Feature × Market data model. It treats positioning as a verifiable artifact: each proposition answers what the capability IS, what it DOES for the buyer, and what it MEANS for their business, scoped to one market segment at a time. Where other insight-wave plugins generate content, this one is the source of truth for what a company offers and to whom.

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

- **Position your portfolio in days, not weeks.** Market sizing, competitive mapping, and proposition writing that took two weeks of analyst time per product line now run in structured parallel with research agents.
- **Pitch each segment in its own language.** Every proposition is scoped to one Feature × Market pair, so a single feature yields a distinct DOES/MEANS message per segment instead of one generic pitch stretched across every market.
- **Export once, reuse everywhere.** One `portfolio-communicate` run produces proposals, market briefs, workbooks (markdown + XLSX), and an interactive dashboard from the same entity data — sales always reads the latest messaging.
- **Trust the claims.** Web-sourced assertions are verified against their cited sources, so the positioning you ship rests on evidence, not assumption.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/cogni-portfolio:portfolio-resume          # ← entry point: status + next step
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

Start a project and let it capture your company context:

> Run `/cogni-portfolio:portfolio-setup`

Describe the company — say, a cloud infrastructure provider targeting mid-market SaaS. Claude auto-selects the B2B ICT taxonomy, scaffolds the project, and writes the manifest:

```
cogni-portfolio/acme-cloud/
├── portfolio.json          # company context, taxonomy, config
├── products/               # top-level offerings
├── features/               # market-independent capabilities (IS layer)
├── markets/                # target segments with TAM/SAM/SOM
└── propositions/           # IS/DOES/MEANS per Feature × Market
```

From there, define products and features, size your markets, then generate propositions:

> Run `/cogni-portfolio:propositions`

Each Feature × Market pair gets a distinct IS/DOES/MEANS message written to `propositions/{feature}--{market}.json`. Quality gates score each one and flag thin messaging before it flows downstream, so weak propositions never reach a pitch or a website unchecked. From there you can size markets, analyze competitors, and export pitches and proposals — every deliverable traces back to the same Feature × Market join. Returning later? Run `/cogni-portfolio:portfolio-resume` for status and the recommended next step.

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

Each portfolio project lives in `cogni-portfolio/{slug}/` as typed JSON files organized by entity. The workflow runs in dependency order — `setup → products → features → markets → propositions → solutions → compete → customers → verify → communicate` — because each step consumes what the previous one produced. Features (the IS layer) must exist before a proposition can say what a capability DOES; markets must be sized before a proposition can be scoped to a segment. The ordering is not cosmetic: it is what makes Feature × Market the core join that propositions, solutions, and competitor analysis all key off.

Research-intensive steps — market sizing, competitive analysis, customer profiling — dispatch parallel web-research agents that auto-log every web-sourced claim with its source URL and entity provenance, so assertions stay traceable back to evidence.

Most entity types then pass through a three-layer quality gate: scripts validate JSON schema compliance, LLM assessor agents score content dimensions (mechanism clarity, differentiation, market-specificity), and stakeholder-perspective agents simulate three reader viewpoints to return accept / warn / fail verdicts. The gate is load-bearing — it blocks downstream generation when upstream entities fail, so a weak feature can never quietly seed a weak proposition. `portfolio-verify` closes the loop: once cited claims are resolved, corrections propagate back into entity files and cascade staleness through every dependent entity.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `portfolio-resume` | skill | Resume, continue, or check status of a portfolio project |
| `portfolio-setup` | skill | Initialize a new portfolio project with company context and directory structure |
| `portfolio-canvas` | skill | Bootstrap a portfolio project from a Lean Canvas or Business Model Canvas |
| `portfolio-scan` | skill | Discover offerings via website scanning and classify against taxonomy |
| `portfolio-taxonomy` | skill | Clone, author, or import a project-local taxonomy so categories, search patterns, and product skeleton can be customized without touching bundled templates |
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
| `portfolio-consolidate` | skill | Roll up N research-only scan outputs into a taxonomy-shaped coverage matrix across providers |
| `trends-bridge` | skill | Bidirectional integration between cogni-trends TIPS analysis and the portfolio |
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
├── skills/                       21 portfolio skills
│   └── portfolio-canvas-workspace/ Dev workspace (evals, iterations — not a skill)
├── agents/                       20 delegation agents
├── hooks/                        1 guardrail hook (Excalidraw canvas auto-start)
├── references/
│   └── data-model.md             Full entity schema and project structure reference
├── scripts/                      18 utility scripts
└── tests/                        Entity-validation test harness
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | No | Pitch use case reads arc definitions for narrative structure; output is directly consumable by story-to-slides and story-to-web |
| cogni-visual | No | Pitch output consumable by story-to-slides, story-to-web, and story-to-storyboard |
| cogni-marketing | No | Customer narratives from portfolio-communicate are auto-discovered by marketing-setup for voice/messaging enrichment |
| cogni-claims | No | Claim verification for research-backed assertions via portfolio-verify |
| cogni-trends | No | Bidirectional TIPS integration via trends-bridge |
| cogni-knowledge | No | Pitch arcs (technology-futures, strategic-foresight, trend-panorama, theme-thesis) in portfolio-communicate draw on cogni-knowledge research syntheses for evidence |
| cogni-workspace | No | Theme selection for portfolio-dashboard via pick-theme |
| cogni-sales | No | Downstream consumer — why-change pitch builds on portfolio features and propositions |
| document-skills | No | Document ingestion (docx, pptx, xlsx, pdf) via portfolio-ingest; XLSX export via portfolio-communicate |

cogni-portfolio is standalone for core messaging workflows. All integrations are optional and activate when the respective plugin is installed.

## Contributing

Contributions welcome — taxonomy templates, quality assessment dimensions, export formats, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom taxonomy template, an industry-specific proposition framework, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for teams — or reach out directly at [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
