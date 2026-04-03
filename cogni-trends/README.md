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

1. **Scout** trends across 4 Trendradar dimensions using persona-shaped bilingual web research with preliminary grounding (RAG-Fusion), adaptive query budgets (FLARE-inspired), and source quality tiering — scored using multi-framework analysis (Ansoff signal intensity, Rogers diffusion stages, CRAAP source quality) → `trend-candidates.md` → value-modeler, trend-report
2. **Model** investment themes (Handlungsfelder) by consolidating trends into T→I→P→S value chains, generating solution blueprints with portfolio composition and readiness scoring — optionally anchored to real products via cogni-portfolio → `tips-value-model.json` → trend-report, story-to-big-block
3. **Report** CxO-level narratives structured by investment theme using the Corporate Visions arc (Why Change → Why Now → Why You → Why Pay), optionally enriched with recursive deep research (STORM-inspired) for high-value trends, structural review with cross-theme quality gates, and a verifiable claims registry → `tips-trend-report.md` → themed HTML with interactive charts and diagrams via enrich-report
4. **Visualize** the full TIPS project lifecycle as an interactive HTML dashboard → `tips-dashboard.html`
5. **Catalog** curated solutions, SPIs, metrics, and collaterals into persistent industry catalogs for cross-pursuit reuse — each engagement improves the base catalog

## What it means for you

If you need to stay ahead of industry trends for strategy, advisory, or portfolio decisions, this is your research accelerator.

- **Broad coverage, fast.** Persona-shaped bilingual web searches with preliminary grounding, adaptive budgets, and source quality tiering — executed in minutes.
- **Framework-scored, not gut-feel.** Every candidate scored on impact, probability, strategic fit, source quality (CRAAP), and signal strength using Ansoff and Rogers frameworks.
- **From trends to solutions.** T→I→P→S value paths bridge scouted trends to investment themes and portfolio-grounded solution blueprints — not just trend narratives.
- **Evidence-backed output.** Optional deep research (STORM-inspired) for high-value trends, structural review with cross-theme quality gates, and every quantitative claim has an inline citation you can verify.
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
/trend-scout      → interactive industry selection + bilingual trend scouting
/value-modeler    → investment themes, solution blueprints, portfolio anchoring
/trend-report     → CxO-level narrative report from modeled themes
/trends-catalog   → curate and export solutions for cross-pursuit reuse
/trends-dashboard → interactive HTML visualization of the full pipeline
/trends-resume    → resume a project mid-stream with status and next actions
```

## How it works

**trend-scout** initializes a research project with interactive configuration disclosure, then runs 3 preliminary grounding searches (RAG-Fusion pattern) to calibrate query formulation. Dispatches a persona-shaped **trend-web-researcher** agent — each Smarter Service dimension gets queries shaped by a domain expert persona (Regulatory Analyst, CSO, CX Strategist, CTO) following the 4strat STEEP multi-agent approach. In thorough mode, the query budget adapts based on signal yield per dimension (FLARE-inspired). An optional **trend-signal-curator** agent ranks the ~85 raw signals into quality tiers (primary/secondary/supporting) using a 5-dimension composite score. Finally, a **trend-generator** agent produces 60 scored candidates using extended thinking with persona reasoning.

**value-modeler** reads scouted candidates and builds T→I→P→S relationship networks, consolidates them into 3-7 MECE investment themes (Handlungsfelder), and generates solution templates with portfolio blueprints. When cogni-portfolio is available, solutions are anchored to real products and features. Includes interactive Business Relevance scoring and multi-framework solution ranking.

**trend-report** reads modeled investment themes, optionally dispatches 3-5 parallel **trend-deep-researcher** agents for recursive TIPS-aligned deep research on high-value ACT-horizon trends (STORM-inspired tree exploration), then dispatches 4 parallel **trend-report-writer** agents (one per Trendradar dimension) for evidence enrichment. Assembles 3-7 **trend-report-investment-theme-writer** agents (one per theme) using the Corporate Visions arc (Why Change -> Why Now -> Why You -> Why Pay). A **trend-report-reviewer** agent applies a structural quality gate with cross-theme analysis before optional claims verification via cogni-claims.

**trends-catalog** curates solutions, SPIs, metrics, and collaterals from completed projects into persistent industry catalogs. Each engagement improves the base catalog for future pursuits in the same industry.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `trend-scout` | skill | Interactive trend scouting with industry selection, bilingual support (DE/EN), and downstream pipeline integration |
| `value-modeler` | skill | Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates |
| `trend-report` | skill | Generate a strategic TIPS trend report organized around investment themes (Handlungsfelder) with inline citations |
| `trends-catalog` | skill | Manage persistent industry catalogs that accumulate TIPS knowledge across pursuits |
| `trends-dashboard` | skill | Generate an interactive HTML dashboard showing the full TIPS project lifecycle |
| `trends-resume` | skill | Resume, continue, or check status of a TIPS trend scouting project |
| `trend-web-researcher` | agent | Execute bilingual web research (EN/DE) for trend scouting and return aggregated signals as compact JSON (haiku) |
| `trend-generator` | agent | Generate 60 scored trend candidates using multi-framework analysis (TIPS, Ansoff, Rogers, CRAAP) (opus) |
| `trend-candidate-reviewer` | agent | Assess 60 trend candidates from three stakeholder perspectives: strategic foresight analyst, industry domain expert (sonnet) |
| `trend-signal-curator` | agent | Evaluate and rank web research signals by quality, relevance, and diversity before candidate generation (haiku) |
| `trend-deep-researcher` | agent | Perform recursive deep research on a single high-value trend candidate to enrich evidence before report writing (sonnet) |
| `trend-report-writer` | agent | Generate a narrative TIPS dimension section with inline citations and verifiable claims from trend candidates (sonnet) |
| `trend-report-investment-theme-writer` | agent | Write a single investment theme (Handlungsfeld) section using the Corporate Visions arc (sonnet) |
| `trend-report-reviewer` | agent | Evaluate a trend report against structural quality criteria across investment themes (sonnet) |
| `trend-report-revisor` | agent | Revise a trend report after claims verification (sonnet) |

## Methodology & Attribution

cogni-trends combines established strategic foresight frameworks with state-of-the-art LLM research techniques. Each pipeline stage implements specific, referenceable methods.

### Strategic Foresight Frameworks

| Method | Origin | How cogni-trends uses it |
|--------|--------|--------------------------|
| **Smarter Service Trendradar** | Bernhard Steimel, [Smarter Service](https://www.smarter-service.com/) (2023) | 4-dimension model (Externe Effekte, Neue Horizonte, Digitale Wertetreiber, Digitales Fundament) organizes where trends are discovered. Source: *Trendbook Kompass fur die Multikrise* |
| **TIPS** | [Siemens Patent WO2018046399A1](https://patents.google.com/patent/WO2018046399A1/en) (filed 2017, ceased 2019) | Trend -> Implications -> Possibilities -> Solutions content expansion applied to every candidate. Freely usable (ceased patent) |
| **Ansoff Weak Signals** | H. Igor Ansoff, *Strategic Management* (1979) | 5-level signal intensity scale (Turbulence -> Foreseeable) maps to action horizons. ACT requires intensity 4-5; OBSERVE requires 1-2 |
| **Rogers Diffusion of Innovation** | Everett Rogers, *Diffusion of Innovations* (1962) | Adoption stage classification (Innovators -> Laggards) with chasm threshold at 16%. Validates horizon-diffusion alignment |
| **CRAAP Test** | Sarah Blakeslee, Meriam Library CSU Chico (2004) | Source quality assessment (Currency, Relevance, Authority, Accuracy, Purpose) applied in both signal extraction and curation |
| **Corporate Visions** | Tim Riesterer / Corporate Visions Inc. | Why Change -> Why Now -> Why You -> Why Pay narrative arc for investment theme sections in trend reports |

### LLM Research Techniques

| Method | Origin | How cogni-trends uses it |
|--------|--------|--------------------------|
| **RAG-Fusion** | Adrian Raudaschl (2023) | Preliminary grounding searches (Phase 0.5) reformulate downstream queries based on initial web results. RAG-Fusion shows +8-10% accuracy and +30-40% comprehensiveness with 3-5 grounding sub-queries |
| **FLARE** (Forward-Looking Active Retrieval) | Jiang et al., *Active Retrieval Augmented Generation* (2023) | Adaptive query budget allocates flexible search pool based on signal yield per dimension — researching further where gaps exist, stopping where coverage is sufficient. FLARE shows +62% vs baseline retrieval |
| **STORM** | Shao et al., Stanford (2024); [GPT-Researcher](https://github.com/assafelovic/gpt-researcher) | Recursive tree exploration in trend-deep-researcher agent: decompose trend into TIPS sub-aspects, extract learnings, generate follow-up questions, pursue recursively. Single-agent execution for cost control (vs GPT-Researcher's exponential spawning) |
| **GPT-Researcher CURATE_SOURCES** | Assaf Elovic, [GPT-Researcher](https://github.com/assafelovic/gpt-researcher) (25K+ stars) | Signal curation with 5-dimension composite scoring (relevance, authority, recency, specificity, uniqueness) and tier ranking (primary/secondary/supporting). Adapted from embedding-based to LLM-based assessment |
| **4strat STEEP Multi-Agent** | 4strat Platform; referenced in STEEP/PESTLE automation literature | One specialized expert persona per Trendradar dimension (Regulatory Analyst, CSO, CX Strategist, CTO) shapes search vocabulary, question patterns, and authority preferences. Cross-dimension synthesis in the trend-generator |
| **QAG** (Question-Answer-Generation) | Manakul et al. (2023) | Claims verification via cogni-claims: extract claims from report, formulate verification questions, check against cited sources. Detects misquotation, unsupported conclusions, selective omission |

### Scoring Model

The composite candidate score combines the frameworks above into a single 0.0-1.0 metric:

```
Composite = (0.25 x Impact) + (0.20 x Probability) + (0.20 x Strategic_Fit)
          + (0.15 x Source_Quality[CRAAP]) + (0.15 x Signal_Strength) - Uncertainty_Penalty

Training-sourced candidates (no web corroboration):
  Source_Quality capped at 0.4, Signal_Strength capped at 0.3
  -> theoretical max composite ~0.60 (vs 1.0 for fully web-grounded)
```

This scoring model ensures web-grounded candidates with institutional sources consistently outrank LLM training knowledge, reducing hallucination risk in downstream reports.

## Architecture

```
cogni-trends/
├── .claude-plugin/      Plugin manifest
├── skills/              6 trend intelligence skills
│   ├── trend-scout/     Grounding, persona research, signal curation, candidate generation
│   ├── trend-report/    Deep research, evidence enrichment, structural review, claims
│   ├── value-modeler/   T→I→P→S relationship networks, solution templates
│   ├── trends-catalog/  Persistent industry knowledge base
│   ├── trends-dashboard/  Interactive HTML visualization
│   └── trends-resume/   Multi-session state recovery
├── agents/              9 research agents
│   ├── trend-web-researcher.md          Persona-shaped bilingual research (haiku)
│   ├── trend-generator.md               60 scored candidates with persona reasoning (opus)
│   ├── trend-candidate-reviewer.md      3-perspective stakeholder review (sonnet)
│   ├── trend-signal-curator.md          5-dimension signal tiering (haiku)
│   ├── trend-deep-researcher.md         Recursive TIPS-aligned deep research (sonnet)
│   ├── trend-report-writer.md           Dimension sections, deep-research-aware (sonnet)
│   ├── trend-report-investment-theme-writer.md  Corporate Visions arc (sonnet)
│   ├── trend-report-reviewer.md         Cross-theme structural quality gate (sonnet)
│   └── trend-report-revisor.md          Post-verification revision (sonnet)
├── catalogs/            Industry catalog (cross-pursuit reuse)
│   └── b2b-ict/         B2B ICT catalog (general subsector)
├── references/          Framework documentation
│   ├── research-types/  Research type specifications
│   └── taxonomies/      Taxonomy definitions
└── scripts/             5 utility scripts
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-claims | No | Verify citations in trend reports against source URLs |
| cogni-copywriting | No | Executive polish on trend reports with tone scoping |
| cogni-narrative | No | Arc-driven transformation of trend report output; theme-thesis arc for investment theme writers |
| cogni-portfolio | No | Bidirectional integration via trends-bridge (portfolio context export, opportunity import) |
| cogni-visual | No | Themed HTML report via enrich-report; Big Block diagrams from value-modeler solution networks |
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
