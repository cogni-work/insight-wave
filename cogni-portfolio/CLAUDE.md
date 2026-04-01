# cogni-portfolio

Portfolio messaging and proposition planning — from product definition through competitive analysis to export-ready deliverables using the IS/DOES/MEANS (FAB) framework.

## Plugin Architecture

```
skills/                         19 portfolio skills
  portfolio-setup/                Initialize project with company context and taxonomy
  portfolio-canvas/               Bootstrap from Lean Canvas or Business Model Canvas
  portfolio-scan/                 Discover offerings via web scanning + taxonomy classification
  portfolio-ingest/               Extract entities from uploaded documents (md, docx, pptx, xlsx, pdf)
  products/                       Define and manage top-level product offerings
  features/                       Define market-independent capabilities (IS layer)
    references/
      quality-dimensions.md       Feature description quality criteria
  markets/                        Discover, evaluate, and size target markets (TAM/SAM/SOM)
  propositions/                   Generate IS/DOES/MEANS messaging per Feature x Market
    references/
      quality-dimensions.md       DOES/MEANS messaging quality criteria
  solutions/                      Implementation plans and pricing tiers per proposition
  packages/                       Bundle solutions into sellable packages per Product x Market
  compete/                        Competitive landscape analysis per proposition
  customers/                      Ideal customer profiles and buyer personas per market
  portfolio-verify/               Orchestrate claim verification via cogni-claims
  synthesize/                     Aggregate all entities into structured messaging repository
  portfolio-communicate/          All portfolio output: pitches, proposals, briefs, workbooks, docs
    references/
      templates-customer-narrative.md   Customer-facing documentation
      templates-pitch.md                Arc-structured presentation narratives (cogni-narrative compatible)
      templates-proposal.md             Per-proposition sales proposals
      templates-market-brief.md         Per-market marketing briefs
      templates-repo-documentation.md   Developer-facing documentation
      use-case-registry.md              Use case routing and configuration
  portfolio-dashboard/            Interactive HTML dashboard of full portfolio status
  portfolio-architecture/         Excalidraw product-feature hierarchy diagram
  trends-bridge/                  Bidirectional integration with cogni-trends TIPS analysis
  portfolio-resume/               Detect workflow phase and recommend next actions

agents/                         17 delegation agents
  market-researcher.md            Web research for TAM/SAM/SOM with claim submission
  competitor-researcher.md        Web research for competitive intelligence
  customer-researcher.md          Web research for named customer profiling
  customer-review-assessor.md     Review customer profiles from 3 stakeholder perspectives
  proposition-generator.md        Generate IS/DOES/MEANS messaging for Feature x Market
  proposition-quality-assessor.md Assess DOES/MEANS messaging quality (any language)
  proposition-review-assessor.md  Review proposition set from buyer, sales, marketer perspectives
  proposition-deep-diver.md       Deep research — buyer language, competitive messaging, evidence
  solution-planner.md             Plan implementation phases and pricing tiers
  solution-review-assessor.md     Review solutions from procurement, provider SA, client SA
  feature-quality-assessor.md     Assess feature description quality (any language)
  feature-review-assessor.md      Review feature set from PM, strategist, pre-sales perspectives
  feature-deep-diver.md           Deep research — competitive landscape, differentiation, positioning
  quality-enricher.md             Research to improve feature/proposition quality gaps
  communicate-review-assessor.md  Review communication quality from stakeholder perspectives
  dashboard-refresher.md          Regenerate dashboard HTML from current entity data
  portfolio-web-researcher.md     Domain-scoped web research for taxonomy-driven scanning

templates/                      8 pluggable industry taxonomies
  b2b-ict/                        Enterprise ICT (8 dims, 57 categories)
  b2b-saas/                       B2B SaaS (8 dims, 47 categories)
  b2b-fintech/                    FinTech (8 dims, 48 categories)
  b2b-healthtech/                 HealthTech (8 dims, 46 categories)
  b2b-martech/                    MarTech (8 dims, 45 categories)
  b2b-industrial-tech/            Industrial Tech (8 dims, 48 categories)
  b2b-professional-services/      Professional Services (8 dims, 44 categories)
  b2b-opensource/                  Commercial Open Source (8 dims, 50 categories)

scripts/                        8 utility scripts
  project-init.sh                 Initialize project directory structure
  project-status.sh               Show status with entity counts and gap analysis
  quality-audit.sh                Structural quality checks on portfolio entities
  validate-entities.sh            Validate data model integrity
  sync-portfolio.sh               Sync portfolio.json with products/ directory state
  cascade-rename.sh               Cascade slug rename across dependent entity files
  append-claim.sh                 Atomically append claim to cogni-claims/claims.json
  generate-scan-mapping.sh        Generate scan-to-taxonomy mapping

references/
  data-model.md                   Full entity schema and project structure reference
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 19 | portfolio-setup, portfolio-canvas, portfolio-scan, portfolio-ingest, products, features, markets, propositions, solutions, packages, compete, customers, portfolio-verify, synthesize, portfolio-communicate, portfolio-dashboard, portfolio-architecture, trends-bridge, portfolio-resume |
| Agents | 17 | market-researcher, competitor-researcher, customer-researcher, customer-review-assessor, proposition-generator, proposition-quality-assessor, proposition-review-assessor, proposition-deep-diver, solution-planner, solution-review-assessor, feature-quality-assessor, feature-review-assessor, feature-deep-diver, quality-enricher, communicate-review-assessor, dashboard-refresher, portfolio-web-researcher |

## Typical Workflow

```
portfolio-setup → products → features → markets → customers → propositions → solutions → packages
                                                                    ↓
                                                               compete
                                                                    ↓
                                                          portfolio-verify (claims)
                                                                    ↓
                                                     synthesize → portfolio-communicate
                                                                     ├── pitch → story-to-slides
                                                                     ├── proposal
                                                                     ├── market-brief
                                                                     ├── workbook (XLSX)
                                                                     ├── customer-narrative
                                                                     └── repo-documentation
                                                                → portfolio-dashboard
```

Optional entry points: `portfolio-canvas` (from Lean Canvas), `portfolio-scan` (from website), `portfolio-ingest` (from documents).

## Data Model

Each project lives in `cogni-portfolio/{project-slug}/` with:
- `portfolio.json` — Root manifest (company context, taxonomy selection, config)
- `products/` — Product definitions (JSON)
- `features/` — Market-independent feature definitions (IS layer, JSON)
- `markets/` — Target markets with TAM/SAM/SOM (JSON)
- `propositions/` — IS/DOES/MEANS per Feature x Market (JSON)
- `solutions/` — Implementation plans + pricing per proposition (JSON)
- `competitors/` — Competitive landscape per proposition (JSON)
- `customers/` — ICPs and named accounts per market (JSON)
- `context/` — Extracted intelligence from uploaded documents
- `output/` — Generated output (pitches, proposals, briefs, workbooks, narratives, dashboard)
- `cogni-claims/` — Web-sourced claim verification registry (optional)

Feature x Market combinations are the core join — they drive propositions, solutions, and competitor analysis.

## Three-Layer Quality Assessment

Most entity types go through a three-layer quality pipeline:

1. **Structural validation** — scripts check JSON schema compliance
2. **Quality assessment** — LLM-based assessor agents evaluate content dimensions (mechanism clarity, differentiation, market-specificity)
3. **Stakeholder review** — assessor agents simulate 3 reader perspectives and produce accept/warn/fail verdicts

Quality gates block downstream generation when upstream entities fail. Features must pass quality assessment before propositions can be generated.

## Agent Model Strategy

| Tier | Model | Agents |
|------|-------|--------|
| Research | inherit (caller's model) | market-researcher, competitor-researcher, customer-researcher, proposition-generator, solution-planner |
| Deep Research | sonnet | feature-deep-diver, proposition-deep-diver, quality-enricher |
| Quality Assessment | haiku | feature-quality-assessor, proposition-quality-assessor, feature-review-assessor, proposition-review-assessor, solution-review-assessor, customer-review-assessor, communicate-review-assessor, dashboard-refresher |
| Web Research | haiku | portfolio-web-researcher |

Research agents auto-log claims with source URLs to `cogni-claims/claims.json` via `scripts/append-claim.sh`.

## Cross-Plugin Integration

| Plugin | Direction | Mechanism |
|--------|-----------|-----------|
| cogni-claims | downstream | portfolio-verify orchestrates claim verification; research agents auto-log claims |
| cogni-trends | bidirectional | trends-bridge imports solution templates, exports portfolio anchors |
| cogni-workspace | upstream | portfolio-dashboard uses pick-theme for theme selection |
| cogni-consulting | upstream | portfolio-canvas consumes Lean Canvas from business-model-hypothesis vision class |
| document-skills | downstream | portfolio-ingest uses docx/pptx/xlsx readers; portfolio-communicate workbook uses XLSX writer |
| cogni-narrative | downstream | portfolio-communicate pitch use case reads arc definitions for narrative structure |
| cogni-visual | downstream | portfolio-communicate pitch output is directly consumable by story-to-slides, story-to-web, story-to-big-picture |

## Key Conventions

- Entity slugs in kebab-case, derived from entity names
- All research agents return structured JSON with `cost_estimate` fields
- Portfolio.json is a lightweight manifest — entity data lives in subdirectories
- Templates provide taxonomy dimensions + search patterns; selected at project-setup
- Design-variables pattern from cogni-workspace used for dashboard theming
- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- Scripts are stdlib-only (bash + python3, no pip dependencies)
