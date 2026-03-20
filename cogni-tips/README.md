# cogni-tips

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

## What it does

A two-stage pipeline for DACH-focused trend intelligence: scout trends across an industry using the Trendradar dimensions with multi-framework scoring, and generate a TIPS-structured narrative report with web-sourced quantitative evidence and inline citations. Bilingual research (EN/DE) with curated German institutional sources.

1. **Scout** trends across 4 Trendradar dimensions with bilingual web research (32 searches + academic, patent, and regulatory API queries), scored using multi-framework analysis (Ansoff signal intensity, Rogers diffusion stages, CRAAP source quality)
2. **Report** with 4 parallel agents enriching each dimension with quantitative evidence, producing a narrative report with inline citations and a verifiable claims registry

## What it means for you

If you need to stay ahead of industry trends for strategy, advisory, or portfolio decisions, this is your research accelerator.

- **Broad coverage, fast.** 32+ bilingual web searches plus academic and patent sources, executed in minutes.
- **Framework-scored, not gut-feel.** Every candidate scored on impact, probability, strategic fit, source quality, and signal strength.
- **Evidence-backed output.** Every quantitative claim in the report has an inline citation you can verify.
- **DACH-native.** German and English research queries, curated DACH institutional sources (industry associations, Fraunhofer, EUR-Lex), output in your chosen language.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

**Prerequisites:**
- Web access enabled (for trend research)
- Optional: `cogni-claims` plugin (recommended for claim verification of trend report citations)
- Optional: `cogni-narrative` plugin (for insight summary generation)

## Quick start

Describe what you want in natural language:

- "scout trends for the automotive industry"
- "select trend candidates for manufacturing"
- "generate a trend report"

Or invoke skills directly:

```
trend-scout    → interactive industry selection + trend scouting
trend-report   → narrative report from agreed candidates
```

## How it works

**trend-scout** initializes a research project, dispatches a **trend-web-researcher** agent for bilingual web research (32 queries + API sources), then a **trend-generator** agent to produce 60 scored candidates using extended thinking. All candidates are finalized automatically for downstream reporting.

**trend-report** reads agreed candidates and dispatches 4 parallel **trend-report-writer** agents (one per Trendradar dimension). Each agent enriches trends with web-sourced quantitative evidence, writes a TIPS-structured narrative section, and extracts verifiable claims. The skill assembles the final report with executive summary, portfolio analysis, and claims registry.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `trend-scout` | skill | End-to-end trend scouting with industry selection and bilingual research |
| `trend-report` | skill | Narrative report generation with evidence enrichment and claims extraction |
| `value-modeler` | skill | Transform trend candidates into investment themes, TIPS paths, and solution templates with portfolio mapping |
| `tips-catalog` | skill | Industry catalog management for cross-pursuit reuse of solution templates and investment themes |
| `tips-dashboard` | skill | Interactive HTML dashboard visualizing trend landscape, dimension coverage, and scoring distributions |
| `tips-resume` | skill | Resume a TIPS session — show project status, phase progress, and recommended next actions |
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
cogni-tips/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       6 trend intelligence skills
│   ├── trend-scout/
│   ├── trend-report/
│   ├── value-modeler/
│   ├── tips-catalog/
│   ├── tips-dashboard/
│   └── tips-resume/
├── agents/                       4 research agents
│   ├── trend-web-researcher.md
│   ├── trend-generator.md
│   ├── trend-report-writer.md
│   └── trend-report-investment-theme-writer.md
├── references/                   Framework documentation
│   ├── architecture-pattern.md
│   ├── data-model.md
│   └── research-types/
├── catalogs/                     Industry catalog (cross-pursuit reuse)
└── scripts/                      Utility scripts
    └── initialize-trend-project.sh
```

## Custom development

Need a custom trend framework, non-DACH market adaptation, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
