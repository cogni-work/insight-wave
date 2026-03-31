# cogni-trends

A [Claude Cowork](https://claude.ai/cowork) plugin for scouting, selecting, and reporting on strategic industry trends — **specialized for the German Mittelstand and DACH markets**. Combines the [Smarter Service Trendradar](https://www.smarter-service.com/2023/01/31/trendradar-fuer-die-multikrise-und-neue-geooekonomie/) (4-dimension structure by Bernhard Steimel) with the TIPS content framework (Trends, Implications, Possibilities, Solutions — a B2B consulting methodology widely used since the early 2000s; see [WO2018046399A1](https://patents.google.com/patent/WO2018046399A1/en) for a detailed treatment, filed by Siemens 2017, ceased 2019).

> **Market scope:** This plugin is purpose-built for DACH (Germany, Austria, Switzerland). It searches bilingually in English and German, targets curated German institutional sources (VDMA, BITKOM, Fraunhofer, Zukunftsinstitut, EUR-Lex), and uses German-language dimension names from the Smarter Service Trendradar. The underlying bilingual search architecture is generalizable to other markets — see [`references/architecture-pattern.md`](references/architecture-pattern.md) for the reusable pattern.

## Frameworks

This plugin builds on two complementary frameworks:

**Smarter Service Trendradar** — A concentric 4-layer model for organizing where trends are discovered, developed by [Bernhard Steimel](https://www.smarter-service.com/) for digital transformation research in the German Mittelstand:

| Layer | Dimension | Core Question |
|-------|-----------|---------------|
| Outer | Externe Effekte | What external forces are impacting the organization? |
| Strategic | Neue Horizonte | What will the company be paid for in the future? |
| Value | Digitale Wertetreiber | Where do we create value through digital means? |
| Foundation | Digitales Fundament | What capabilities must exist for the next decade? |

Each trend is placed on an action horizon: **Act** (0-2y), **Plan** (2-5y), or **Observe** (5+y).

**TIPS** — A content expansion applied to every discovered trend, regardless of dimension. Originally documented in Siemens patent [WO2018046399A1](https://patents.google.com/patent/WO2018046399A1/en) (filed 2017, ceased 2019 through non-entry into national phase — freely usable). Each trend is analyzed through:

- **T**rend — What is happening?
- **I**mplications — What does this mean for the industry?
- **P**ossibilities — How can the organization capitalize?
- **S**olutions — What concrete steps deliver value?

The dimensions define *where* trends live. TIPS defines *how* each trend is analyzed.

## Why this exists

Strategic trend analysis requires scanning hundreds of sources across languages, scoring candidates against multiple frameworks, and synthesizing everything into a report with verifiable evidence. Most trend reports are either shallow (top-10 lists without evidence) or expensive (months of consultant time).

| Problem | What happens | Impact |
|---------|-------------|--------|
| Source coverage gaps | English-only research misses DACH-specific signals | Blind spots in regulated EU markets |
| Scoring subjectivity | Trends selected by gut feel, not framework | Portfolio imbalance, hype bias |
| Evidence-free narratives | Trend reports cite no quantitative data | Low credibility with decision-makers |
| Manual effort | Weeks of desk research per trend cycle | Outdated by the time it ships |

This plugin automates the research-heavy parts while keeping strategic judgment where it belongs — with you.

## What it is

A four-stage trend intelligence pipeline for the insight-wave ecosystem. The Smarter Service Trendradar provides the 4-dimension scoring structure; the TIPS framework (Trends → Implications → Possibilities → Solutions) drives the value chain from scouted signals to portfolio-grounded solution blueprints. Upstream of cogni-portfolio (which consumes solution templates via trends-bridge) and cogni-narrative (which transforms trend output into arc-driven reports). Reusable industry catalogs accumulate knowledge across engagements.

## What it does

Connects industry trends to portfolio solutions for DACH markets. A four-stage pipeline that scouts trends, bridges them to investment themes and solution blueprints via T→I→P→S value paths, generates CxO-level reports, and curates reusable industry catalogs. Bilingual research (EN/DE) with curated German institutional sources.

1. **Scout** trends across 4 Trendradar dimensions with bilingual web research (32 searches + academic, patent, and regulatory API queries), scored using multi-framework analysis (Ansoff signal intensity, Rogers diffusion stages, CRAAP source quality) → `trend-candidates.md` → value-modeler, trend-report
2. **Model** investment themes (Handlungsfelder) by consolidating trends into T→I→P→S value chains, generating solution blueprints with portfolio composition and readiness scoring — optionally anchored to real products via cogni-portfolio → `tips-value-model.json` → trend-report, story-to-big-block
3. **Report** CxO-level narratives structured by investment theme using the Corporate Visions arc (Why Change → Why Now → Why You → Why Pay), enriched with web-sourced quantitative evidence, inline citations, and a verifiable claims registry → `tips-trend-report.md` → themed HTML with interactive charts and diagrams via enrich-report
4. **Catalog** curated solutions, SPIs, metrics, and collaterals into persistent industry catalogs for cross-pursuit reuse — each engagement improves the base catalog

## What it means for you

If you need to stay ahead of industry trends for strategy, advisory, or portfolio decisions, this is your research accelerator.

- **Broad coverage, fast.** 32+ bilingual web searches plus academic and patent sources, executed in minutes.
- **Framework-scored, not gut-feel.** Every candidate scored on impact, probability, strategic fit, source quality, and signal strength.
- **From trends to solutions.** T→I→P→S value paths bridge scouted trends to investment themes and portfolio-grounded solution blueprints — not just trend narratives.
- **Evidence-backed output.** Every quantitative claim in the report has an inline citation you can verify.
- **Polished visual output.** Reports finish as themed, interactive HTML with Chart.js dashboards and concept diagrams — ready to share, not just a markdown file.
- **Cross-pursuit learning.** Industry catalogs accumulate curated solutions, SPIs, and metrics — each engagement improves the next.
- **Multi-session workflow.** Resume any project mid-stream with full state recovery via `/trends-resume`.
- **DACH-native.** German and English research queries, curated DACH institutional sources (industry associations, Fraunhofer, EUR-Lex), output in your chosen language.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- Web access enabled (for trend research)
- Optional: `cogni-claims` plugin (recommended for claim verification of trend report citations)
- Optional: `cogni-narrative` plugin (for insight summary generation)

## Quick start

Describe what you want in natural language:

- "scout trends for the automotive industry"
- "model investment themes from the scouted trends"
- "generate solution blueprints"
- "generate a trend report"
- "export curated solutions to the industry catalog"
- "where was I?" or "resume my TIPS project"

Or invoke skills directly:

```
trend-scout    → interactive industry selection + trend scouting
value-modeler  → investment themes, solution blueprints, portfolio anchoring
trend-report   → CxO-level narrative report from modeled themes
trends-catalog   → curate and export solutions for cross-pursuit reuse
trends-dashboard → interactive HTML visualization of the full pipeline
trends-resume    → resume a project mid-stream with status and next actions
```

## How it works

**trend-scout** initializes a research project, dispatches a **trend-web-researcher** agent for bilingual web research (32 queries + API sources), then a **trend-generator** agent to produce 60 scored candidates using extended thinking. All candidates are finalized automatically for downstream modeling.

**value-modeler** reads scouted candidates and builds T→I→P→S relationship networks, consolidates them into 3-7 MECE investment themes (Handlungsfelder), and generates solution templates with portfolio blueprints. When cogni-portfolio is available, solutions are anchored to real products and features. Includes interactive Business Relevance scoring and multi-framework solution ranking.

**trend-report** reads modeled investment themes and dispatches 3-7 parallel **trend-report-investment-theme-writer** agents (one per theme). Each agent writes a narrative section using the Corporate Visions arc (Why Change → Why Now → Why You → Why Pay), enriched with web-sourced quantitative evidence and verifiable claims. The skill assembles the final report with executive summary, portfolio analysis, and claims registry.

**trends-catalog** curates solutions, SPIs, metrics, and collaterals from completed projects into persistent industry catalogs. Each engagement improves the base catalog for future pursuits in the same industry.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `trend-scout` | skill | End-to-end trend scouting with industry selection and bilingual research |
| `trend-report` | skill | Narrative report generation with evidence enrichment and claims extraction |
| `value-modeler` | skill | Transform trend candidates into investment themes, TIPS paths, and solution templates with portfolio mapping |
| `trends-catalog` | skill | Industry catalog management for cross-pursuit reuse of solution templates and investment themes |
| `trends-dashboard` | skill | Interactive HTML dashboard visualizing trend landscape, dimension coverage, and scoring distributions |
| `trends-resume` | skill | Resume a TIPS session — show project status, phase progress, and recommended next actions |
| `trend-web-researcher` | agent | Executes 32 bilingual web searches + API queries, returns aggregated signals |
| `trend-generator` | agent | Generates scored trend candidates using multi-framework analysis (Opus) |
| `trend-report-writer` | agent | Writes one Trendradar dimension section with TIPS analysis and claims |
| `trend-report-investment-theme-writer` | agent | Writes investment theme (Handlungsfeld) narrative sections for the trend report |

## Attribution

- **Smarter Service Trendradar** by [Bernhard Steimel / Smarter Service](https://www.smarter-service.com/) — 4-dimension trend analysis structure. Source: *Trendbook Kompass fur die Multikrise* (2023).
- **TIPS framework** originated at [Siemens Industry Software](https://patents.google.com/patent/WO2018046399A1/en) — Trends, Implications, Possibilities, Solutions content structure. Patent WO2018046399A1 (filed 2017, ceased 2019).
- **Scoring frameworks** — Ansoff Matrix (signal intensity), Rogers Diffusion of Innovations (adoption stage), CRAAP Test (source quality).

## Architecture

```
cogni-trends/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       6 trend intelligence skills
│   ├── trend-scout/
│   ├── trend-report/
│   ├── value-modeler/
│   ├── trends-catalog/
│   ├── trends-dashboard/
│   └── trends-resume/
├── agents/                       4 research agents
│   ├── trend-web-researcher.md
│   ├── trend-generator.md
│   ├── trend-report-writer.md
│   └── trend-report-investment-theme-writer.md
├── references/                   Framework documentation
│   ├── architecture-pattern.md
│   ├── data-model.md
│   ├── language-resolution.md
│   ├── tips-patent.pdf
│   ├── research-types/
│   └── taxonomies/
├── catalogs/                     Industry catalog (cross-pursuit reuse)
└── scripts/                      Utility scripts
    ├── initialize-trend-project.sh
    ├── project-status.sh
    ├── discover-projects.sh
    ├── discover-portfolio-markets.sh
    └── repair-candidates.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-claims | No | Verify citations in trend reports against source URLs |
| cogni-narrative | No | Arc-driven transformation of trend report output |
| cogni-portfolio | No | Bidirectional integration via trends-bridge (portfolio context export, opportunity import) |
| cogni-copywriting | No | Executive polish on trend reports with tone scoping |
| cogni-visual | No | Big Block diagrams from value-modeler solution networks |
| cogni-workspace | No | Theme selection for trends-dashboard via pick-theme skill |

cogni-trends is standalone for trend scouting and reporting. Cross-plugin integrations add verification, narrative polish, portfolio mapping, and visual output.

## Contributing

Contributions welcome — trend frameworks, industry taxonomies, research source integrations, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom trend framework, non-DACH market adaptation, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
