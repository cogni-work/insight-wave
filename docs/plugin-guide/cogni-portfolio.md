# cogni-portfolio

Portfolio messaging and proposition planning — from product definition through competitive analysis to export-ready deliverables.

For the canonical IS/DOES/MEANS positioning of this plugin, see the [cogni-portfolio README](../../cogni-portfolio/README.md).

---

## Overview

cogni-portfolio gives B2B companies a structured way to build market-specific messaging. The core problem it addresses: companies know what they sell but produce inside-out messaging — feature lists disconnected from buyer pain. The plugin enforces an outside-in discipline through the IS/DOES/MEANS (FAB) framework applied at the Feature x Market level.

Every proposition answers three questions:

- **IS**: What is this capability? (market-independent definition)
- **DOES**: What does it do for this buyer in this market? (benefit, market-specific)
- **MEANS**: What does that mean for their business? (outcome, in buyer language)

The same feature gets different DOES/MEANS statements for enterprise vs. mid-market buyers — because the stakes, vocabulary, and priorities differ. cogni-portfolio enforces this discipline structurally: propositions are always scoped to a Feature x Market pair, never to a feature alone.

Projects follow a logical progression through typed JSON entities. Research-intensive steps (market sizing, competitive analysis, customer profiling) dispatch parallel web-research agents. Quality assessors score every entity before it unblocks downstream generation. The pipeline ends in export-ready deliverables: proposals, market briefs, XLSX workbooks, an interactive HTML dashboard, and architecture diagrams.

---

## Key Concepts

### IS/DOES/MEANS (FAB) Framework

| Layer | Question | Scope | Example |
|-------|----------|-------|---------|
| IS | What is this capability? | Market-independent | "Real-time cloud infrastructure monitoring" |
| DOES | What does it do for the buyer? | Market-specific | "Detects incidents before they reach end users" |
| MEANS | What does that mean for their business? | Outcome in buyer language | "SLAs stay green without a dedicated NOC team" |

Features define the IS layer. Propositions add DOES and MEANS for each target market.

### Feature x Market Join

The Feature x Market combination is the core entity. Propositions, solutions, and competitive analysis all live at this intersection. A company with 5 features and 4 markets can produce up to 20 distinct propositions — each with tailored messaging, pricing, and competitive context.

### Industry Taxonomies

Eight pluggable templates classify features and markets into industry-standard dimensions and categories. The taxonomy is selected automatically during setup based on company context.

| Template | Dimensions | Categories | Vertical |
|----------|-----------|------------|---------|
| b2b-ict | 8 | 57 | Enterprise ICT |
| b2b-saas | 8 | 47 | B2B SaaS |
| b2b-fintech | 8 | 48 | FinTech |
| b2b-healthtech | 8 | 46 | HealthTech |
| b2b-martech | 8 | 45 | MarTech |
| b2b-industrial-tech | 8 | 48 | Industrial Tech |
| b2b-professional-services | 8 | 44 | Professional Services |
| b2b-opensource | 8 | 50 | Commercial OSS |

### Three-Layer Quality Assessment

Most entity types pass through:

1. **Structural validation** — shell scripts check JSON schema compliance
2. **Quality assessment** — LLM assessors evaluate content dimensions (mechanism clarity, differentiation, market-specificity)
3. **Stakeholder review** — assessors simulate 3 reader perspectives and produce accept/warn/fail verdicts

Quality gates block downstream generation. Features must pass quality assessment before propositions can be generated.

### Entity Storage

All entities are JSON files in the project directory:

```
cogni-portfolio/{project-slug}/
├── portfolio.json                # Root manifest
├── products/{slug}.json          # Top-level offerings
├── features/{slug}.json          # IS-layer capabilities
├── markets/{segment}-{region}.json
├── propositions/{feature}--{market}.json
├── solutions/{feature}--{market}.json
├── competitors/{feature}--{market}.json
├── customers/{market}.json
└── packages/{product}--{market}.json
```

---

## Getting Started

**First prompt:**

> Set up a portfolio project for a cloud infrastructure company targeting mid-market SaaS in DACH

What happens:

1. `portfolio-setup` asks clarifying questions about company context and current product lines
2. Auto-selects the `b2b-saas` or `b2b-ict` taxonomy based on your answer
3. Runs `scripts/project-init.sh` to scaffold the directory structure
4. Creates `portfolio.json` with company context, taxonomy selection, and delivery defaults
5. Recommends the next step: `/products`

**Expected output (portfolio.json fragment):**

```json
{
  "slug": "acme-cloud-services",
  "company": {
    "name": "Acme Cloud Services",
    "description": "Cloud infrastructure management for mid-market SaaS",
    "industry": "Cloud Infrastructure"
  },
  "taxonomy": {
    "type": "b2b-ict",
    "dimensions": 8,
    "categories": 57
  },
  "language": "en"
}
```

From there, the recommended path is: `/products` → `/features` → `/markets` → `/propositions`.

---

## Capabilities

### portfolio-setup

Initialize a project by capturing company context and scaffolding the directory structure. Setup creates `portfolio.json`, selects the appropriate taxonomy, and establishes the baseline that every downstream skill reads.

**Example prompt:** "Create a portfolio project for a HealthTech company providing clinical decision support"

---

### products

Define and manage top-level product offerings. Products are the containers that features belong to. The skill takes a consulting stance — it challenges vague product definitions and helps scope offerings for commercial clarity.

**Example prompt:** "I have three products: a data platform, an analytics suite, and a professional services arm. Let's define them."

---

### features

Define market-independent capabilities — the IS layer of each proposition. Features belong to exactly one product. Deep-dive mode runs web research on competitive landscape and buyer language for a single feature.

**Example prompt:** "Add the predictive alerting capability to our monitoring product, then deep dive on how competitors position it"

---

### markets

Discover, evaluate, and size target markets with TAM/SAM/SOM. The skill challenges lazy segmentation (e.g., "all European enterprises") and guides toward focused, sizable segments where the portfolio can realistically win.

**Example prompt:** "What are the right markets for our cloud monitoring feature? We're thinking enterprise and mid-market, Germany first."

---

### propositions

Generate IS/DOES/MEANS messaging per Feature x Market pair — individually or in batch. Deep-dive mode validates buyer language, researches competitive messaging, and co-creates sharper DOES/MEANS through dialogue.

**Example prompt:** "Generate propositions for all features in the mid-market-saas-dach market"

**Representative proposition output:**

```json
{
  "feature_slug": "cloud-monitoring",
  "market_slug": "mid-market-saas-dach",
  "is": "Real-time cloud infrastructure monitoring with automated incident detection",
  "does": "Surfaces incidents in under 60 seconds before end-user impact, without requiring dedicated NOC headcount",
  "means": "SaaS teams maintain 99.9% uptime SLAs with a lean operations team — the ops burden stays flat as the infrastructure scales",
  "quality_score": 0.84,
  "evidence": ["2024 DACH SaaS Operations Survey: median MTTD 8 min without monitoring"]
}
```

---

### customers

Create ideal customer profiles (ICPs) and buyer personas per target market. Profiles describe who buys, why they buy, and how they make purchasing decisions. Customer profiling is market-scoped — all propositions in a market share the same buyer profile.

**Example prompt:** "Profile the buyer for mid-market SaaS in DACH — who is the economic buyer, and what triggers a purchase?"

---

### solutions

Define implementation plans and tiered pricing (PoV/Small/Medium/Large) to build buyer business cases. The skill challenges cookie-cutter phases and pricing that doesn't reflect the proposition's DOES statement.

**Example prompt:** "Build a solution plan for cloud-monitoring in mid-market, with a proof-of-value tier that gives the buyer a clear success signal"

---

### packages

Bundle feature-level solutions into sellable product packages per Product x Market. Nobody buys individual features — they buy a product configured for their segment. Packages set commercial pricing for the combination.

**Example prompt:** "Package all cloud platform solutions for mid-market SaaS into three tiers"

---

### compete

Analyze 3–5 competitors per proposition. Competitive analysis is proposition-scoped: the same feature competes against different vendors in enterprise vs. mid-market.

**Example prompt:** "Who are our top competitors for cloud monitoring in mid-market SaaS, and how do we differentiate?"

---

### portfolio-verify

Verify web-sourced claims in portfolio entities against their cited source URLs via cogni-claims. Research agents auto-log every web-sourced fact to `cogni-claims/claims.json`. This skill checks each claim before generating deliverables.

**Example prompt:** "Verify all claims before I generate the portfolio deliverables"

**Example prompt:** "Export a market brief for the healthcare vertical in DACH, and a proposal for Acme Corp"

---

### portfolio-communicate

Generate portfolio documentation for any audience — customer-facing narratives, repository documentation, developer guides, or custom formats.

**Example prompt:** "Write a customer-facing capability overview for our cloud platform targeting healthcare CTOs"

---

### portfolio-dashboard

Generate a self-contained HTML dashboard showing entity counts, the Feature x Market matrix, market sizing, pricing, competitor coverage, and claims status. Supports drill-down navigation.

**Example prompt:** "Open the portfolio dashboard"

---

### portfolio-architecture

Generate an Excalidraw diagram of the product-feature hierarchy — products as containers, features nested inside. Updates in-place as the portfolio evolves.

**Example prompt:** "Show me the portfolio architecture diagram"

---

### portfolio-canvas

Bootstrap a portfolio from a Lean Canvas or Business Model Canvas — extract products, features, and markets from a founding-stage hypothesis document in one step.

**Example prompt:** "Bootstrap my portfolio from this lean canvas" (upload your canvas as a markdown file)

---

### portfolio-ingest

Extract portfolio entities from uploaded documents: `.md`, `.docx`, `.pptx`, `.xlsx`, `.pdf`. Use when you have existing product decks, strategy documents, or competitive briefs.

**Example prompt:** "Ingest these product sheets and extract features and markets"

---

### portfolio-taxonomy

Own and customize the project-local taxonomy that classifies offerings. Clone a bundled template (B2B SaaS, FinTech, HealthTech, MarTech, Industrial Tech, ICT, Professional Services, Commercial Open Source), author from scratch, or import from an existing portfolio. This is the prerequisite setup step before `portfolio-scan` can classify discovered offerings against a consistent category set.

**Example prompt:** "Clone the b2b-ict taxonomy into this project so I can customize its categories"

---

### portfolio-scan

Discover a company's service offerings by scanning public websites, classify against the taxonomy template, and import as portfolio entities. Before deep research, scan asks you to confirm the list of **provider units** — subsidiaries, practice areas, or brands that will be scanned independently.

**Example prompt:** "Scan Acme Corp's website and map their services to our ICT taxonomy"

---

### portfolio-lineage

Track the relationship between input sources (uploaded documents, web research URLs, TIPS enrichment) and the portfolio entities derived from them. When a document is re-uploaded with updated content or a web source changes, this skill detects the drift, maps which entities are affected, and guides you through a layered refresh — features first, then propositions, then solutions — so nothing regenerates from stale inputs.

Five operating modes: **status** (show source registry health), **check** (detect changed documents and URLs), **trace** (follow one entity back to its sources and forward to its dependents), **impact** (blast radius if a source changes), and **refresh** (guided cascade through the dependency chain).

**Example prompt:** "What sources feed the cloud-monitoring feature, and what would be affected if I re-upload the pricing doc?"

---

### trends-bridge

Bidirectional integration with cogni-trends: import solution templates from a TIPS value model as portfolio features, or export portfolio context to enrich TIPS solution relevance scoring.

**Example prompt:** "Bridge the automotive TIPS project into my portfolio"

---

### portfolio-consolidate

Roll up N research-only `portfolio-scan` outputs across providers into a taxonomy-shaped coverage matrix. Use for cross-provider market-landscape analysis — which competitors cover which taxonomy categories, where coverage clusters, and where gaps exist — without committing any of the scans as features in your own portfolio.

**Example prompt:** "Consolidate last week's five provider scans into a coverage matrix against the b2b-ict taxonomy"

---

### portfolio-resume

Detect the current workflow phase, show entity counts and coverage gaps, and recommend the next action. Use to re-enter a project after a break.

**Example prompt:** "Where was I in the portfolio project?"

---

## Integration Points

### Upstream (what cogni-portfolio consumes)

| Plugin | Skill | What is consumed |
|--------|-------|-----------------|
| cogni-trends | trends-bridge | Solution templates and investment themes from TIPS value-modeler |
| cogni-consulting | portfolio-canvas | Lean Canvas from business-model-hypothesis vision class |
| document-skills | portfolio-ingest | DOCX/PPTX/XLSX document readers for entity extraction |
| cogni-workspace | portfolio-dashboard | Theme selection via pick-theme |

### Downstream (what cogni-portfolio produces for others)

| Plugin | Skill | What is provided |
|--------|-------|-----------------|
| cogni-claims | portfolio-verify | Claims submitted for source URL verification |
| cogni-trends | trends-bridge | Portfolio anchors that enrich TIPS solution relevance scoring |
| document-skills | portfolio-communicate | XLSX workbook generation for deliverables |
| cogni-narrative | portfolio-communicate | Pitch narratives with arc_id for story-to-slides |

---

## Common Workflows

### Workflow 1: New Product Line Positioning

Use this when launching a new product or entering a new market segment.

1. `/portfolio-setup` — capture company context, select taxonomy
2. `/products` — define the new product offering
3. `/features` — add capabilities (IS layer)
4. `/markets` — size the target segments
5. `/propositions` — generate IS/DOES/MEANS per Feature x Market
6. `/customers` — profile the buyers per market
7. `/compete` — map competitors per proposition
8. `/portfolio-verify` — verify web-sourced claims
9. `/portfolio-communicate` — produce pitches, proposals, briefs, and workbooks

For multi-plugin flows that extend this into trend-informed positioning, see [../workflows/portfolio-trends-positioning.md](../workflows/portfolio-trends-positioning.md).

---

### Workflow 2: Bootstrap from Existing Documents

Use this when you have product decks, strategy briefs, or competitive intelligence already written.

1. `/portfolio-setup` — initialize project
2. `/portfolio-ingest` — extract entities from uploaded documents
3. `/features` — review and enrich extracted features (quality assessment)
4. `/markets` — validate and size extracted markets
5. `/propositions` — generate messaging for Feature x Market pairs not covered by ingested content
6. `/portfolio-communicate` — generate deliverables

---

### Workflow 3: Sharpen Messaging for a Single Proposition

Use this when a specific proposition feels generic or loses to a competitor.

1. `/propositions` (deep-dive mode) — "deep dive on cloud-monitoring in mid-market-saas-dach"
   - Runs buyer language validation, competitive messaging research, and evidence gathering
   - Co-creates sharper DOES/MEANS through interactive dialogue
2. `/compete` — refresh competitor analysis for that proposition
3. `/portfolio-verify` — re-verify updated claims
4. `/portfolio-communicate` — regenerate deliverables with updated content

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "No portfolio project found" | Running a skill before setup | Run `/portfolio-setup` first |
| Propositions blocked by quality gate | Features failed quality assessment | Run `/features` again and address the feedback from the quality assessor |
| Market sizing feels wrong | Research agent used low-quality sources | Run `/portfolio-verify` to check TAM/SAM/SOM claims against their source URLs |
| Deliverables have thin competitor sections | `/compete` not run for those propositions | Run `/compete` for missing Feature x Market pairs, then re-run `/portfolio-communicate` |
| Dashboard not updating | Entity files changed outside the workflow | Refresh via the dashboard-refresher agent, or re-run `/portfolio-dashboard` |
| Canvas bootstrap misses features | Canvas document uses non-standard section headings | Describe your canvas structure when running `/portfolio-canvas` |
| Claims verification times out | Large number of claims + slow source URLs | Run `/portfolio-verify` in batches, filtering by entity type |

---

## Extending This Plugin

cogni-portfolio accepts contributions in several areas:

- **Taxonomy templates** — new industry verticals (e.g., EdTech, GovTech, AgriTech) following the 8-dimension structure
- **Quality assessment dimensions** — additional criteria for feature and proposition quality assessors
- **Export formats** — new deliverable types (e.g., PowerPoint briefs, investor one-pagers)
- **Scripts** — additional utility scripts for batch operations or data validation

See [CONTRIBUTING.md](../../cogni-portfolio/CONTRIBUTING.md) for guidelines. For custom taxonomy templates or domain-specific frameworks, open an issue or reach out directly.
