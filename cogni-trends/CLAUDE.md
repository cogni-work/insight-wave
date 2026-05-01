# cogni-trends

Strategic trend scouting and reporting pipeline — combines the Smarter Service Trendradar with the TIPS framework to bridge industry trends to portfolio solutions. Multilingual European markets (DE/FR/IT/PL/NL/ES) + US/UK + LATAM (MX/BR).

## Plugin Architecture

```
skills/                         9 trend intelligence skills
  trend-scout/                    End-to-end scouting: industry selection, bilingual web research, 60 candidates
    references/
      industry-subsectors.md      Industry and subsector classification
  value-modeler/                  T→I→P→S relationship networks → ranked solution templates
  trend-research/                 Research groundwork: deep research + 4 parallel writer agents enrich every candidate; emits .metadata/trend-research-output.json manifest
    references/
      research-manifest-schema.md  Manifest format and downstream drift-detection contract
      deep-research-selection.md   Phase 0.5 deep-research candidate selection criteria
      evidence-enrichment.md       Web search strategy passed to writer agents
      claims-format.md             Claims extraction schema
      region-authority-sources.json  Per-region authority sources (read by trend-report-writer agent)
  trend-synthesis/                Compose canonical TIPS report (4 H2 dimensions × anchored H3 theme-cases, closing on Capability Imperative); emits tips-trend-report.md + tips-trend-report-claims.json
    references/
      synthesis-skeleton.md        Phase 2 macro-skeleton flow (anchoring → primer → theme-cases → composers → exec → synthesis → assembly)
      capability-imperative.md     Phase 2.5 synthesis pattern
      claims-registry-format.md    Phase 2.4 claims registry table format
      report-length-tiers.md       Length tier definitions and budget formula
      report-structure.md          Dimension section template
  trend-booklet/                  Comprehensive TIPS catalog of all ~60 candidates by dimension → subcategory → horizon; emits tips-trend-booklet.md + tips-trend-booklet-index.json
    references/
      booklet-structure.md         Per-entry block template + nesting layout
      candidate-to-theme-backref.md  Walk value chains to map candidates to themes
      booklet-length-tiers.md      Compact / standard / exhaustive density definitions
    scripts/
      build-booklet-index.sh       Build .logs/booklet-index.json from value-model + scout + enriched-trends
  verify-trend-report/            Extended quality pipeline: claim verification + structural review + revisor + downstream menu
    references/
      claims-integration.md        cogni-claims submission and verification protocol
      structural-review.md         Reviewer/revisor loop, validation rules, version output
      downstream-options.md        Final menu (copywriter, enrich-report)
  trends-catalog/                 Persistent industry catalogs for cross-pursuit knowledge reuse
  trends-dashboard/               Interactive HTML dashboard of full TIPS project lifecycle
  trends-resume/                  Resume project mid-stream with full state recovery

agents/                         11 research agents
  trend-web-researcher.md         Persona-shaped bilingual web research (EN/DE), grounding-aware, adaptive budget (haiku)
  trend-generator.md              Generate 60 scored candidates with persona reasoning + TIPS + Ansoff + Rogers + CRAAP (opus)
  trend-candidate-reviewer.md     3-perspective stakeholder review of candidate pool (sonnet)
  trend-signal-curator.md         Evaluate and tier-rank web signals before generation (haiku)
  trend-report-writer.md          Write one Trendradar dimension section with citations, deep-research-aware (sonnet) — invoked by trend-research Phase 1
  trend-report-investment-theme-writer.md  Write one investment theme as a slim 3-beat case (Stake / Move / Cost-of-Inaction) anchored to its dominant Smarter Service dimension (sonnet) — invoked by trend-synthesis Phase 2.1
  trend-report-composer.md        Compose ONE Smarter Service macro section (dimension narrative + nested theme-cases). Invoked sequentially 4× per report by trend-synthesis Phase 2.2 (sonnet)
  trend-report-reviewer.md        Cross-theme structural review with 5-dimension quality rubric (sonnet)
  trend-report-revisor.md         Post-verification report revision — apply claim corrections/removals (sonnet)
  trend-deep-researcher.md        Recursive TIPS-aligned deep research for high-value ACT-horizon trends (sonnet) — invoked by trend-research Phase 0.5
  trend-booklet-formatter.md      Format ONE Smarter Service dimension's section of the TIPS trend booklet — pure formatter, no web research (sonnet) — invoked by trend-booklet Phase 2

catalogs/                       Industry knowledge base
  b2b-ict/                        B2B ICT catalog (general subsector)
    catalog.json                  Catalog manifest
    tips-entities.json            All TIPS entities
    solution-templates.json       Reusable solution templates
    spis.json                     Strategic Positioning Insights
    metrics.json                  Industry metrics
    collaterals.json              Marketing collaterals

scripts/                        5 utility scripts
  initialize-trend-project.sh     Initialize project directory structure
  project-status.sh               Show status with phase detection and candidate counts
  discover-projects.sh            Discover cogni-trends projects in workspace
  discover-portfolio-markets.sh   Find portfolio markets for TIPS-portfolio bridging
  repair-candidates.sh            Repair candidate integrity/structure issues

references/
  data-model.md                   Full entity schemas and project structure
  architecture-pattern.md         Bilingual search architecture (reusable for non-DACH markets)
  dimension-personas.md           Expert personas per Smarter Service dimension for targeted research
  language-resolution.md          Language configuration and resolution strategy
  research-types/                 Research type specifications
  taxonomies/                     Taxonomy definitions
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 9 | trend-scout, value-modeler, trend-research, trend-synthesis, trend-booklet, verify-trend-report, trends-catalog, trends-dashboard, trends-resume |
| Agents | 11 | trend-web-researcher (haiku), trend-generator (opus), trend-candidate-reviewer (sonnet), trend-signal-curator (haiku), trend-report-writer (sonnet), trend-report-investment-theme-writer (sonnet), trend-report-composer (sonnet), trend-report-reviewer (sonnet), trend-report-revisor (sonnet), trend-deep-researcher (sonnet), trend-booklet-formatter (sonnet) |

## Workflow Pipeline

```
trend-scout → value-modeler → trend-research → (trend-synthesis | trend-booklet) → verify-trend-report → trends-catalog
   (scout)      (model)         (enrich)         (compose)         (catalog)            (verify+revise)        (accumulate)
```

`trend-research` enriches every candidate with web-sourced quantitative evidence and emits a single manifest (`.metadata/trend-research-output.json`) that the two downstream synthesis skills gate on. `trend-synthesis` produces the curated TIPS investment-themes report (`tips-trend-report.md`); `trend-booklet` produces the comprehensive catalog of all candidates (`tips-trend-booklet.md`). The two are independent and can run in either order. `verify-trend-report` is the extended quality pipeline mirroring `cogni-research:verify-report`: claim verification via cogni-claims, cross-theme structural review, revisor loop, and a final menu surfacing executive polish (`cogni-copywriting:copywriter`) and visual enrichment (`cogni-visual:enrich-report`). `trends-resume` can re-enter at any stage. `trends-dashboard` visualizes the full lifecycle.

## Data Model

Each project lives in a directory with:
- `tips-project.json` — Project config and metadata
- `trend-candidates.md` — 60 scored candidates with TIPS expansion
- `tips-value-model.json` — Relationship networks and solution templates (value-modeler output)
- `tips-big-block.md` — Solution architecture summary
- `tips-solution-ranking.md` — Ranked solution templates with BR scores
- `tips-trend-report.md` — Canonical TIPS report (trend-synthesis output)
- `tips-trend-report-claims.json` — Merged claims registry
- `tips-trend-booklet.md` — Comprehensive TIPS catalog of all candidates (trend-booklet output)
- `tips-trend-booklet-index.json` — Structured sidecar index for the booklet
- `tips-insight-summary.md` — Condensed executive narrative (legacy artifact)
- `.metadata/` — Execution logs, trend-scout output, trend-research manifest, verification state
- `.logs/` — Agent outputs, per-dimension claims, per-dimension enriched-trends, theme-cases, macro-sections

## Frameworks & Methodology

### Strategic Foresight Frameworks

- **Smarter Service Trendradar** (Steimel, 2023) — 4-dimension model: Externe Effekte, Neue Horizonte, Digitale Wertetreiber, Digitales Fundament. Each trend on action horizon: Act (0-2y), Plan (2-5y), Observe (5+y)
- **TIPS** (Siemens WO2018046399A1, ceased 2019) — Trend -> Implications -> Possibilities -> Solutions content expansion
- **Ansoff Weak Signals** (1979) — 5-level signal intensity scale mapped to action horizons
- **Rogers Diffusion of Innovation** (1962) — Adoption stage classification with chasm threshold at 16%
- **CRAAP Test** (Blakeslee, 2004) — Source quality assessment in signal extraction and curation
- **Smarter Service** (theme-aware sibling of Trend Panorama) — Macro skeleton: Forces -> Impact -> Horizons -> Foundations as 4 H2 sections, with investment themes nested as anchored H3 cases. Closes on a Foundations-anchored "Capability Imperative" synthesis. The canonical TIPS report skeleton produced by `trend-synthesis`. The arc is registered upstream in `cogni-narrative/skills/narrative/references/story-arc/smarter-service/`.

### LLM Research Techniques

- **RAG-Fusion** (Raudaschl, 2023) — Preliminary grounding searches reformulate downstream queries (+8-10% accuracy)
- **FLARE** (Jiang et al., 2023) — Adaptive query budget based on signal yield per dimension (+62% vs baseline)
- **STORM** (Shao et al., Stanford 2024) / **GPT-Researcher** (Elovic) — Recursive tree exploration in deep-researcher agent
- **CURATE_SOURCES** (GPT-Researcher) — 5-dimension signal tiering adapted from embedding-based to LLM-based assessment
- **4strat STEEP Multi-Agent** — One expert persona per dimension shapes search vocabulary and authority preferences
- **QAG** (Manakul et al., 2023) — Claims verification via cogni-claims (extract claims, verify against cited sources)

### Multi-Framework Scoring

```
Composite = (0.25 x Impact) + (0.20 x Probability) + (0.20 x Strategic_Fit)
          + (0.15 x Source_Quality[CRAAP]) + (0.15 x Signal_Strength) - Uncertainty_Penalty
```

Training-sourced candidates capped: source_quality max 0.4, signal_strength max 0.3 (theoretical max ~0.60).

## Cross-Plugin Integration

| Plugin | Direction | Mechanism |
|--------|-----------|-----------|
| cogni-portfolio | bidirectional | trends-bridge exports solution templates → portfolio features; portfolio anchors enrich solution relevance scoring |
| cogni-narrative | downstream | smarter-service arc consumed by trend-synthesis theme-case writer + dimension composer (graceful fallback when absent) |
| cogni-claims | downstream | trend-research registers claims; `verify-trend-report` Phase 2 invokes cogni-claims:claims for source verification |
| cogni-copywriting | downstream | Executive polish on trend reports with tone scoping |
| cogni-workspace | upstream | pick-theme for dashboard theming; `region-authority-sources.json` is downstream of the canonical `references/supported-markets-registry.json` — per-market authority-domain drift detected via `cogni-workspace:audit-region-sources` (informational by default) |
| cogni-visual | downstream | enrich-report themed HTML from trend-report or trend-booklet; story-to-slides for presentations |

## Key Conventions

- Persona-shaped research: each Smarter Service dimension uses an expert persona (Regulatory Analyst, CSO, CX Strategist, CTO) for targeted search queries
- Preliminary grounding: 3 broad searches before the full research battery to calibrate queries
- Source quality tiering: signals ranked into primary/secondary/supporting tiers before candidate generation
- Adaptive query budget (thorough mode): 24 base + 12 flexible-pool searches allocated by signal yield
- Deep research: optional recursive TIPS-aligned exploration for high-value ACT-horizon trends (offered by trend-research)
- Candidate review: 3-perspective stakeholder assessment with accept/revise/reject verdict and surgical repair loop
- Structural review: cross-theme quality gate with 5-dimension rubric (verify-trend-report)
- Multilingual search: English tier (international) + local-language tier (regional institutional sources). Supports DE/FR/IT/PL/NL/ES/MX/BR markets via `SUBSECTOR_LOCAL` and `REGION_QUALIFIER_LOCAL` parameters
- Curated European sources per market in `region-authority-sources.json` (lives under `skills/trend-research/references/`). DACH: VDMA, BITKOM, Fraunhofer. FR: INRIA, ARCEP, Les Echos. IT: AGCOM, CNR, ASI. PL: UKE, POLSA. NL: TNO, ACM. ES: CNMC, INTA, CDTI.
- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- Scripts are stdlib-only (bash + python3, no pip dependencies)
- Catalogs accumulate knowledge across engagements — each pursuit enriches the next
- Design-variables pattern from cogni-workspace used for dashboard theming
- Claims auto-registered with source URLs during research enrichment
- Agent frontmatter — `tools:` is written in YAML array form (`tools: ["Read", "Write"]`); existing bare comma-separated entries are tolerated, but new agents follow the array form
- Scoring UI (`skills/value-modeler/templates/scoring-ui.html`) is intentionally DE-only — user-visible strings are German regardless of project `LANG`. Multilingual UI via `__LABEL_*__` placeholders is deferred until separately scoped
