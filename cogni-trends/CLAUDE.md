# cogni-trends

Strategic trend scouting and reporting pipeline — combines the Smarter Service Trendradar with the TIPS framework to bridge industry trends to portfolio solutions. DACH-focused, bilingual EN/DE.

## Plugin Architecture

```
skills/                         6 trend intelligence skills
  trend-scout/                    End-to-end scouting: industry selection, bilingual web research, web-grounded candidates
    references/
      industry-subsectors.md      Industry and subsector classification
  trend-report/                   CxO-level narrative report organized by investment themes
    references/
      report-structure.md         Theme-first report structure and evidence requirements
  value-modeler/                  T→I→P→S relationship networks → ranked solution templates
  trends-catalog/                 Persistent industry catalogs for cross-pursuit knowledge reuse
  trends-dashboard/               Interactive HTML dashboard of full TIPS project lifecycle
  trends-resume/                  Resume project mid-stream with full state recovery

agents/                         5 research agents
  trend-web-researcher.md         Bilingual web research (EN/DE), returns aggregated signals (haiku)
  trend-generator.md              Generate web-grounded scored candidates using TIPS + Ansoff + Rogers + CRAAP (opus)
  trend-report-writer.md          Write one Trendradar dimension section with citations (sonnet)
  trend-report-investment-theme-writer.md  Write one investment theme using Corporate Visions arc (sonnet)
  trend-report-revisor.md         Post-verification report revision — apply claim corrections/removals (sonnet)

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
  language-resolution.md          Language configuration and resolution strategy
  research-types/                 Research type specifications
  taxonomies/                     Taxonomy definitions
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 6 | trend-scout, value-modeler, trend-report, trends-catalog, trends-dashboard, trends-resume |
| Agents | 5 | trend-web-researcher (haiku), trend-generator (opus), trend-report-writer (sonnet), trend-report-investment-theme-writer (sonnet), trend-report-revisor (sonnet) |

## Workflow Pipeline

```
trend-scout → value-modeler → trend-report → trends-catalog
   (scout)      (model)         (report)      (accumulate)
```

Each stage depends on the previous. `trends-resume` can re-enter at any stage. `trends-dashboard` visualizes the full lifecycle.

## Data Model

Each project lives in a directory with:
- `tips-project.json` — Project config and metadata
- `trend-candidates.md` — Web-grounded scored candidates with TIPS expansion (variable count)
- `tips-value-model.json` — Relationship networks and solution templates (value-modeler output)
- `tips-big-block.md` — Solution architecture summary
- `tips-solution-ranking.md` — Ranked solution templates with BR scores
- `tips-trend-report.md` — Full CxO narrative report
- `tips-insight-summary.md` — Condensed executive narrative
- `.metadata/` — Execution logs, trend-scout output, verification state
- `.logs/` — Agent outputs, per-dimension claims, report sections

## Frameworks

**Smarter Service Trendradar** — 4-dimension model for organizing where trends are discovered:
- Externe Effekte (external forces)
- Neue Horizonte (future revenue sources)
- Digitale Wertetreiber (digital value creation)
- Digitales Fundament (foundational capabilities)

Each trend placed on action horizon: Act (0-2y), Plan (2-5y), Observe (5+y).

**TIPS** — Content expansion applied to every trend:
- **T**rend → **I**mplications → **P**ossibilities → **S**olutions

**Multi-Framework Scoring** (trend-generator): TIPS + Ansoff signal intensity + Rogers diffusion stage + CRAAP source quality.

## Cross-Plugin Integration

| Plugin | Direction | Mechanism |
|--------|-----------|-----------|
| cogni-portfolio | bidirectional | trends-bridge exports solution templates → portfolio features; portfolio anchors enrich solution relevance scoring |
| cogni-narrative | downstream | trend-panorama and theme-thesis arcs consume TIPS output |
| cogni-claims | downstream | trend-report registers claims; verify via cogni-claims:claims |
| cogni-copywriting | downstream | Executive polish on trend reports with tone scoping |
| cogni-workspace | upstream | pick-theme for dashboard theming |
| cogni-visual | downstream | Big Block diagrams from value-modeler solution networks; enrich-report themed HTML from trend-report |

## Key Conventions

- Bilingual search: English tier (international) + German tier (DACH institutional sources)
- Curated German sources: VDMA, BITKOM, Fraunhofer, Zukunftsinstitut, EUR-Lex
- Scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`
- Scripts are stdlib-only (bash + python3, no pip dependencies)
- Catalogs accumulate knowledge across engagements — each pursuit enriches the next
- Design-variables pattern from cogni-workspace used for dashboard theming
- Claims auto-registered with source URLs during report generation
