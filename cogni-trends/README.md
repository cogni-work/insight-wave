# cogni-trends

> **Preview** (v0.6) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Markets covered.** 8 European and Anglo markets with per-region trend authorities — DACH (VDMA, BITKOM, Fraunhofer), FR (INRIA, ARCEP, Les Echos), IT (CNR, AGCOM, ASI), PL (UKE, POLSA, GUS), NL (TNO, ACM), ES (CNMC, INTA, CDTI), plus US and UK — DE/EN bilingual research against regional authorities — no generic US-centric datasets. See [Supported markets & languages](../cogni-workspace/README.md#supported-markets--languages) for the full registry.

> **Start here.** Run `/cogni-trends:trends-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

A [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai/cowork) plugin that scouts, scores, and reports industry trends via the Smarter Service Trendradar and TIPS value chain across European/Anglo markets.

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

Strategic trend analysis means scanning hundreds of sources across languages, scoring candidates against multiple frameworks, and synthesizing everything into a report a CxO will act on. Most trend reports collapse under that load — either shallow top-10 lists or months of consultant time.

| Problem | What happens | Impact |
|---------|-------------|--------|
| Source coverage gaps | English-only research misses DACH-specific signals | Blind spots in regulated EU markets |
| Scoring subjectivity | Trends selected by gut feel, not framework | Portfolio imbalance, hype bias |
| Evidence-free narratives | Trend reports cite no quantitative data | Low credibility with decision-makers |
| Manual effort | Weeks of desk research per trend cycle | Outdated by the time it ships |

The research-heavy scanning, scoring, and enrichment are exactly the parts that drain weeks and still leave gaps — while the strategic judgment they feed stays with you.

## What it is

A trend intelligence engine built on two strategic-foresight frameworks: the Smarter Service Trendradar, which structures where trends live across four dimensions, and the TIPS value chain (Trends → Implications → Possibilities → Solutions), which carries each signal through to a portfolio-grounded solution blueprint. It sits upstream of cogni-portfolio and cogni-narrative in the insight-wave ecosystem, and its industry catalogs persist so knowledge compounds across engagements rather than dying with each report.

## What it does

Connects industry trends to portfolio solutions for European markets. The pipeline scouts trends, bridges them to investment themes and solution blueprints via T→I→P→S value paths, enriches every candidate with web-sourced quantitative evidence, generates the canonical CxO-level TIPS report (and an optional companion catalog of all candidates), and curates reusable industry catalogs. Bilingual research (EN/DE) with curated regional institutional sources.

1. **Scout** trends across 4 Trendradar dimensions using persona-shaped bilingual web research with preliminary grounding (RAG-Fusion), adaptive query budgets (FLARE-inspired), and source quality tiering — scored using multi-framework analysis (Ansoff signal intensity, Rogers diffusion stages, CRAAP source quality) → `trend-candidates.md` → value-modeler, trend-research
2. **Model** investment themes (Handlungsfelder) by consolidating trends into T→I→P→S value chains, generating solution blueprints with portfolio composition and readiness scoring — optionally anchored to real products via cogni-portfolio → `tips-value-model.json` → trend-research
3. **Research** every candidate with 4 parallel writer agents — optionally augmented by recursive deep research (STORM-inspired) on 3–5 high-value Act-horizon trends — and emit per-dimension enriched evidence + claims plus a single research manifest → `.metadata/trend-research-output.json` → trend-synthesis, trend-booklet
4. **Synthesize** the canonical CxO-level TIPS report — 4 H2 dimensions (Forces / Impact / Horizons / Foundations) with investment themes nested as anchored H3 theme-cases (Stake / Move / Cost-of-Inaction), closing on a Foundations-anchored "Capability Imperative" — with a verifiable claims registry → `tips-trend-report.md` → verify-trend-report → themed HTML via enrich-report
5. **Catalog** every candidate as a comprehensive companion booklet organized by dimension → subcategory → horizon, with summary, citations, theme back-references, and keywords; orphans go in a per-dimension appendix → `tips-trend-booklet.md` → optional catalog companion to the curated report
6. **Visualize** the full TIPS project lifecycle as an interactive HTML dashboard → `tips-dashboard.html`
7. **Catalog** curated solutions, SPIs, metrics, and collaterals into persistent industry catalogs for cross-pursuit reuse — each engagement improves the base catalog

## What it means for you

- **Research your market natively.** Per-market bilingual queries run against the institutions your buyers trust — VDMA and BITKOM for DACH, INRIA for FR, CNR and AGCOM for IT — not generic US-centric datasets, with output in your chosen language.
- **Trust the shortlist.** Every candidate is scored on impact, probability, strategic fit, source quality, and signal strength using Ansoff and Rogers — so the trends that surface are framework-ranked, not gut-picked.
- **Reach solutions, not just narratives.** T→I→P→S value paths turn scouted signals into 3–7 portfolio-grounded investment themes per run, each carrying concrete solution blueprints.
- **Hand over a share-ready report.** The output finishes as themed, interactive HTML with Chart.js visualizations and concept diagrams — and industry catalogs compound, giving each new pursuit +20-40% richer context from prior work.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

Describe what you want in natural language:

- "scout trends for the automotive industry"
- "model investment themes from the scouted trends"
- "enrich the trend evidence" or "run the trend research stage"
- "generate a trend report" or "compose the TIPS report"
- "build a trend booklet" or "produce the full trend catalog"
- "verify the trend report"
- "export curated solutions to the industry catalog"
- "where was I?" or "resume my TIPS project"

Or invoke skills directly:

```
/cogni-trends:trends-resume   # ← entry point: status + next step
/trend-scout         → interactive industry selection + bilingual trend scouting
/value-modeler       → investment themes, solution blueprints, portfolio anchoring
/trend-research      → enrich every candidate with quantitative evidence; emit research manifest
/trend-synthesis     → canonical TIPS report (4 H2 dimensions × anchored H3 theme-cases)
/trend-booklet       → comprehensive TIPS catalog of all candidates by dimension → subcategory → horizon
/verify-trend-report → claim verification + structural review + revision pipeline
/trends-catalog      → curate and export solutions for cross-pursuit reuse
/trends-dashboard    → interactive HTML visualization of the full pipeline
/trends-resume       → resume a project mid-stream with status and next actions
```

## Try it

Start a project by scouting trends for an industry:

> Run `/cogni-trends:trend-scout`

You'll pick an industry interactively, then watch persona-shaped bilingual research run across the four Trendradar dimensions and produce 60 scored candidates:

```
project/trend-candidates.md   — 60 candidates, scored on impact / probability /
                                 strategic fit / source quality / signal strength
project/.metadata/            — scout output, grounding searches, run logs
```

Lost track of where a project stands? Run the entry point any time:

> Run `/cogni-trends:trends-resume`

It reports the current phase, the artifacts already produced, and the single next step — model investment themes, enrich the evidence, or compose the report — so you re-enter exactly where you left off with no context loss between sessions. Every candidate carries its scores and source citations, so you can trace why a trend ranked where it did before committing to it downstream.

## How it works

The pipeline runs in dependency order — scout → model → research → synthesize/catalog → verify — because each stage consumes the prior stage's artifact, and a report can only be evidence-backed once the evidence has been enriched.

**trend-scout** runs 3 preliminary grounding searches (RAG-Fusion) to calibrate queries, then dispatches a persona-shaped **trend-web-researcher** — each Smarter Service dimension gets queries from a domain-expert persona (Regulatory Analyst, CSO, CX Strategist, CTO) following the 4strat STEEP approach. In thorough mode the query budget adapts to signal yield per dimension (FLARE). An optional **trend-signal-curator** tiers the ~85 raw signals on a 5-dimension score before a **trend-generator** produces 60 scored candidates.

**value-modeler** builds T→I→P→S relationship networks from those candidates, consolidates them into 3-7 MECE investment themes, and generates solution templates with portfolio blueprints — anchored to real products when cogni-portfolio is present.

**trend-research** optionally dispatches 3–5 **trend-deep-researcher** agents for STORM-inspired recursive research on high-value ACT-horizon trends, then 4 parallel **trend-report-writer** agents (one per dimension) for evidence enrichment. A JSON-validity gate guards the per-dimension files before it writes `.metadata/trend-research-output.json` — the single manifest both synthesis skills gate on.

**trend-synthesis** anchors each theme to its dominant dimension and dispatches **trend-report-investment-theme-writer** agents (slim Stake / Move / Cost-of-Inaction cases), then 4 sequential **trend-report-composer** agents for the dimension narratives, closing on a "Capability Imperative" synthesis → `tips-trend-report.md` plus its claims registry.

**trend-booklet** walks the value model for candidate → theme back-references and dispatches 4 **trend-booklet-formatter** agents to render every candidate by subcategory → horizon; orphans land in per-dimension appendices.

**verify-trend-report** runs claim verification via cogni-claims, cross-theme structural review, optional revision, and a final menu offering executive polish or themed HTML. **trends-catalog** then curates solutions, SPIs, and metrics into persistent industry catalogs, so each engagement improves the base for the next.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `trends-resume` | skill | Resume, continue, or check status of a TIPS trend scouting project |
| `trend-scout` | skill | Interactive trend scouting workflow with industry selection, bilingual support (DE/EN), and downstream pipeline integration |
| `value-modeler` | skill | Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates |
| `trend-research` | skill | Research groundwork: deep research + 4 parallel writer agents enrich every candidate with web-sourced quantitative evidence; emits the research manifest |
| `trend-synthesis` | skill | Compose the canonical TIPS report — 4 H2 dimensions × anchored H3 theme-cases, closing on a Capability Imperative synthesis |
| `trend-booklet` | skill | Comprehensive TIPS catalog of all ~60 candidates organized by dimension → subcategory → horizon, with summary, citations, theme back-references |
| `verify-trend-report` | skill | Extended quality pipeline on the canonical report — claim verification via cogni-claims, structural review, revision, downstream menu |
| `trends-catalog` | skill | Manage persistent industry catalogs that accumulate TIPS knowledge across pursuits |
| `trends-dashboard` | skill | Generate an interactive HTML dashboard showing the full TIPS project lifecycle |
| `trend-web-researcher` | agent | Execute bilingual web research (EN/DE) for trend scouting and return aggregated signals as compact JSON (haiku) |
| `trend-generator` | agent | Generate 60 scored trend candidates using multi-framework analysis (TIPS, Ansoff, Rogers, CRAAP) (opus) |
| `trend-candidate-reviewer` | agent | Assess 60 trend candidates from three stakeholder perspectives (sonnet) |
| `trend-signal-curator` | agent | Evaluate and rank web research signals by quality, relevance, and diversity before candidate generation (haiku) |
| `trend-deep-researcher` | agent | Recursive deep research on a single high-value trend candidate to enrich evidence (sonnet) |
| `br-pre-scorer` | agent | Generate LLM-suggested Business Relevance scores (1-5) plus a one-line rationale per TIP candidate in a value-modeler project (haiku) |
| `trend-report-writer` | agent | Generate a narrative TIPS dimension section with inline citations and verifiable claims from trend candidates (sonnet) — invoked by trend-research |
| `trend-report-investment-theme-writer` | agent | Write a single investment theme as a slim 3-beat case (Stake / Move / Cost-of-Inaction) anchored to its dominant Smarter Service dimension (sonnet) — invoked by trend-synthesis |
| `trend-report-composer` | agent | Compose ONE Smarter Service macro section (Forces / Impact / Horizons / Foundations) — dimension narrative + nested theme-cases (sonnet) — invoked by trend-synthesis |
| `trend-booklet-formatter` | agent | Format ONE Smarter Service dimension's section of the TIPS trend booklet — pure formatter, no web research (sonnet) — invoked by trend-booklet |
| `trend-report-reviewer` | agent | Evaluate a trend report against structural quality criteria across investment themes (sonnet) |
| `trend-report-revisor` | agent | Revise a trend report after claims verification — apply corrections and find replacement evidence (sonnet) |

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
├── skills/              9 trend intelligence skills
│   ├── trends-resume/      Multi-session state recovery (entry point)
│   ├── trend-scout/        Grounding, persona research, signal curation, candidate generation
│   ├── value-modeler/      T→I→P→S relationship networks, solution templates
│   ├── trend-research/     Deep research, evidence enrichment, research manifest
│   ├── trend-synthesis/    Canonical TIPS report (4 H2 dimensions × H3 theme-cases)
│   ├── trend-booklet/      Comprehensive TIPS catalog of all candidates
│   ├── verify-trend-report/  Claim verification + structural review + revision pipeline
│   ├── trends-catalog/     Persistent industry knowledge base
│   └── trends-dashboard/   Interactive HTML visualization
├── agents/              12 research agents
│   ├── trend-web-researcher.md          Persona-shaped bilingual research (haiku)
│   ├── trend-generator.md               60 scored candidates with persona reasoning (opus)
│   ├── trend-candidate-reviewer.md      3-perspective stakeholder review (sonnet)
│   ├── trend-signal-curator.md          5-dimension signal tiering (haiku)
│   ├── trend-deep-researcher.md         Recursive TIPS-aligned deep research (sonnet)
│   ├── br-pre-scorer.md                 LLM-suggested Business Relevance scores (haiku)
│   ├── trend-report-writer.md           Dimension sections, deep-research-aware (sonnet)
│   ├── trend-report-investment-theme-writer.md  Slim 3-beat theme-case writer (sonnet)
│   ├── trend-report-composer.md         Smarter Service macro section composer (sonnet)
│   ├── trend-booklet-formatter.md       Booklet per-dimension formatter (sonnet)
│   ├── trend-report-reviewer.md         Cross-theme structural quality gate (sonnet)
│   └── trend-report-revisor.md          Post-verification revision (sonnet)
├── catalogs/            Industry catalog (cross-pursuit reuse)
│   └── b2b-ict/         B2B ICT catalog (general subsector)
├── references/          Framework documentation
│   ├── research-types/  Research type specifications
│   └── taxonomies/      Taxonomy definitions
├── scripts/             6 utility scripts
└── tests/               Project-status test + fixtures
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-claims | No | Verify citations in trend reports against source URLs |
| cogni-copywriting | No | Executive polish on trend reports with tone scoping |
| cogni-narrative | No | Arc-driven transformation of trend report output; the smarter-service arc drives the canonical report's theme-case writer and macro composer |
| cogni-portfolio | No | Bidirectional integration via trends-bridge (portfolio context export, opportunity import) |
| cogni-visual | No | Themed HTML report via enrich-report; Big Block diagrams from value-modeler solution networks |
| cogni-workspace | No | Theme selection for trends-dashboard via pick-theme skill |

cogni-trends is standalone for trend scouting and reporting. Cross-plugin integrations add verification, narrative polish, portfolio mapping, and visual output.

## Contributing

Contributions welcome — trend frameworks, industry taxonomies, research source integrations, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom trend framework, additional market coverage with new regional authority sources, or a plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation for consulting and strategy teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
