# insight-wave

Open-source plugins for consulting, sales, and marketing on [Claude Code](https://claude.ai/code). 12 AGPL-3.0 plugins that automate the research-heavy, methodology-driven work behind B2B deliverables — trend scouting, portfolio positioning, sales pitches, content creation, visual production, and source verification.

Each plugin implements an established framework (Corporate Visions, Double Diamond, TIPS, IS/DOES/MEANS) rather than general-purpose text generation. Outputs include inline citations, structured data models, and quality gates. Every deliverable follows a reproducible methodology you can inspect and override.

<!-- Architecture diagram placeholder: create an ecosystem visual using
     cogni-visual:story-to-big-picture, save as architecture.excalidraw,
     export to assets/architecture.svg, then re-run /doc-bridge -->

## What the plugins do

12 plugins organized around eight capability areas. Each area handles a distinct part of the workflow; plugins within an area share data formats and can be used independently or together.

### Sales Pitches

[cogni-sales](cogni-sales/README.md) generates account-specific pitches using the Corporate Visions Why Change methodology — four research phases (Why Change, Why Now, Why You, Why Pay) each backed by a dedicated web research agent. Outputs a `sales-presentation.md` and `sales-proposal.md` with sequential citations. Works in two modes: customer mode for named accounts with company-specific research, or segment mode for reusable market-vertical pitches.

> "Create a Why Change pitch for Siemens Manufacturing based on our managed services portfolio"

→ [Plugin guide](docs/plugin-guide/cogni-sales.md) · [Portfolio to Pitch workflow](docs/workflows/portfolio-to-pitch.md)

### Portfolio Messaging

[cogni-portfolio](cogni-portfolio/README.md) structures products, features, and target markets into market-specific value propositions using IS/DOES/MEANS messaging. 20 skills handle the full positioning lifecycle — from TAM/SAM/SOM market sizing and competitive analysis through three-layer quality assessment to export-ready proposals and workbooks. Eight industry taxonomies (ICT, SaaS, FinTech, HealthTech, MarTech, Industrial Tech, Professional Services, Open Source) classify your portfolio automatically.

> "Set up a portfolio for our cloud monitoring product targeting mid-market SaaS companies in DACH"

→ [Plugin guide](docs/plugin-guide/cogni-portfolio.md)

### Content Production

[cogni-marketing](cogni-marketing/README.md) bridges portfolio propositions and trend themes into channel-ready content across 16 formats — blogs, LinkedIn articles, whitepapers, battle cards, email nurtures, video scripts, and more. A 3D content matrix (market x GTM path x content type) tracks coverage gaps. [cogni-copywriting](cogni-copywriting/README.md) polishes any document for executive readability using 7 messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Power Positions) and runs 5 parallel stakeholder personas to catch blind spots. [cogni-narrative](cogni-narrative/README.md) transforms structured content into executive narratives using 7 story arc frameworks with quality scoring (0-100, A-F grades).

> "Generate thought leadership content for the AI automation theme across LinkedIn and blog formats"

→ [Plugin guide: cogni-marketing](docs/plugin-guide/cogni-marketing.md) · [Content Pipeline workflow](docs/workflows/content-pipeline.md)

### Consulting Orchestration

[cogni-consulting](cogni-consulting/README.md) manages Double Diamond engagements — dispatching to research, trends, portfolio, and claims plugins at the right phase. Eight vision classes (strategic options, business case, GTM roadmap, cost optimization, digital transformation, innovation portfolio, market entry, business model hypothesis) scope the engagement. Phase gates are advisory — your consulting judgment drives the process.

> "I need to evaluate strategic options for expanding our cloud services portfolio in the DACH mid-market"

→ [Plugin guide](docs/plugin-guide/cogni-consulting.md) · [Consulting Engagement workflow](docs/workflows/consulting-engagement.md)

### Research

[cogni-research](cogni-research/README.md) runs 5-25 parallel web research agents to produce multi-section reports with inline citations — from a basic 3,000-word scan to recursive deep-research trees of 15,000 words. Three depth levels (basic, detailed, deep), three source modes (web, local documents, hybrid), and a structural review loop before finalization.

> "Write a detailed research report on AI regulation in the EU with IEEE citations"

→ [Plugin guide](docs/plugin-guide/cogni-research.md) · [Research to Report workflow](docs/workflows/research-to-report.md)

### Trend Intelligence

[cogni-trends](cogni-trends/README.md) scouts industry trends across four TIPS dimensions with bilingual DE/EN web research, producing 60 scored trend candidates per run using multi-framework analysis (TIPS, Ansoff, Rogers, CRAAP). The value-modeler consolidates candidates into 3-7 investment themes with solution blueprints. Reusable industry catalogs accumulate knowledge across engagements. Purpose-built for DACH markets with curated German institutional sources (VDMA, BITKOM, Fraunhofer).

> "Scout trends for the automotive industry, then model investment themes from the results"

→ [Plugin guide](docs/plugin-guide/cogni-trends.md) · [Trends to Solutions workflow](docs/workflows/trends-to-solutions.md)

### Visual Production

[cogni-visual](cogni-visual/README.md) transforms narratives into five visual formats: slide decks (11 layout types), big-picture journey maps (1,100-1,500 Excalidraw elements), Big Block solution architecture diagrams, scrollable web narratives, and printed poster storyboards. Five skills generate structured briefs; 13 agents render them into .pptx, .excalidraw, .pen, or .html files. All visuals inherit brand identity from your workspace theme.

> "Create a slide deck from the sales presentation, then render the strategy as a big picture journey map"

→ [Plugin guide](docs/plugin-guide/cogni-visual.md)

### Platform & Quality

[cogni-claims](cogni-claims/README.md) verifies whether sourced claims match what their cited sources actually say — catching misquotations, unsupported conclusions, selective omissions, and stale data. Other plugins register claims during generation; cogni-claims fetches each source and flags deviations for your review. [cogni-workspace](cogni-workspace/README.md) manages the shared foundation — environment variables, theme management, plugin discovery, and workspace health. [cogni-help](cogni-help/README.md) provides a 12-course interactive curriculum, 6 cross-plugin workflow templates, and troubleshooting diagnostics.

> "Verify all claims in the trend report against their cited sources"

→ [Plugin guide: cogni-claims](docs/plugin-guide/cogni-claims.md) · [Plugin guide: cogni-help](docs/plugin-guide/cogni-help.md)

Beyond the open-source plugins, cogni-works offers consulting services — plugin engineering for domain-specific workflows, managed deployment, and a partner certification program — through [cogni-work.ai](https://cogni-work.ai). Whether you run a consulting practice, a sales organization, or a marketing team, the site shows how these capabilities translate into managed workflows and onboarding for your team.

## Who this is for

### Consulting Firms

You compete on methodology depth, not headcount — but quality assurance depends on individual partners, and every pitch costs days of senior capacity.

- **Account-specific pitches in 90 minutes** — [cogni-sales](cogni-sales/README.md) generates Corporate Visions Why Change pitches with web-researched evidence per customer → [Portfolio to Pitch](docs/workflows/portfolio-to-pitch.md)
- **Verified research in 20 minutes** — [cogni-research](cogni-research/README.md) runs 5-25 parallel agents to produce DACH-sourced reports with inline citations → [Research to Report](docs/workflows/research-to-report.md)
- **60 scored trend candidates per scouting run** — [cogni-trends](cogni-trends/README.md) identifies industry trends across four TIPS dimensions with bilingual DE/EN research → [Trends to Solutions](docs/workflows/trends-to-solutions.md)
- **Double Diamond with quality gates** — [cogni-consulting](cogni-consulting/README.md) orchestrates engagements with automated phase readiness assessment → [Consulting Engagement](docs/workflows/consulting-engagement.md)
- **Consistent portfolio messaging** — [cogni-portfolio](cogni-portfolio/README.md) structures IS/DOES/MEANS propositions across Feature x Market pairs with three-layer quality assessment

**Start here:** [cogni-sales](cogni-sales/README.md), [cogni-research](cogni-research/README.md), [cogni-portfolio](cogni-portfolio/README.md)

For consulting on applying these workflows in client engagements, or to certify your team as practitioners: [cogni-work.ai](https://cogni-work.ai)

### Sales Organizations

Your reps spend 2-3 days per opportunity on research and deck creation. The standard presentation stops working after the third customer — but account-specific pitches require senior capacity tied up in large deals.

- **Methodology-disciplined pitches** — [cogni-sales](cogni-sales/README.md) follows the full Corporate Visions arc (Why Change → Why Now → Why You → Why Pay) with web-researched evidence per phase
- **Verified account briefings** — [cogni-research](cogni-research/README.md) delivers DACH market data you can stand behind in front of a customer
- **Consistent messaging from one foundation** — [cogni-portfolio](cogni-portfolio/README.md) produces buyer-role-specific value propositions for each opportunity
- **Proposals and one-pagers without the marketing queue** — [cogni-marketing](cogni-marketing/README.md) generates sales enablement content (battle cards, demo scripts, objection handlers) from portfolio data

**Start here:** [cogni-sales](cogni-sales/README.md), [cogni-portfolio](cogni-portfolio/README.md), [cogni-research](cogni-research/README.md)

For CRM integration and managed deployment of sales workflows: [cogni-work.ai](https://cogni-work.ai)

### Marketing Teams

Your pipeline needs more content, but the budget doesn't cover additional headcount. Meanwhile, every format is written from scratch and brand voice varies by channel.

- **16 content formats from one narrative** — [cogni-marketing](cogni-marketing/README.md) generates blog, LinkedIn, newsletter, and whitepaper from a single source in consistent brand voice → [Content Pipeline](docs/workflows/content-pipeline.md)
- **Source-verified thought leadership** — [cogni-research](cogni-research/README.md) produces DACH market data with inline citations — no invented statistics
- **Consistent messaging foundation** — [cogni-portfolio](cogni-portfolio/README.md) translates your positioning into market-specific value propositions across all channels
- **Trend-driven content relevance** — [cogni-trends](cogni-trends/README.md) identifies industry trends for thought leadership content, structured by TIPS dimensions

**Start here:** [cogni-marketing](cogni-marketing/README.md), [cogni-portfolio](cogni-portfolio/README.md), [cogni-research](cogni-research/README.md)

For CMS integration and managed content operations: [cogni-work.ai](https://cogni-work.ai)

## Prerequisites

- [Claude Code](https://claude.ai/code) (CLI, desktop app, or IDE extension)
- Terminal access (macOS, Linux, or WSL)
- `bash` 3.2+, `python3` (stdlib only), `jq`
- Optional: [Obsidian](https://obsidian.md/) for browsable knowledge management

## Quick start

### 1. Add the marketplace

```shell
/plugin marketplace add cogni-work/insight-wave
```

### 2. Install plugins

```shell
/plugin install cogni-workspace@insight-wave    # install first — foundation layer
/plugin install cogni-research@insight-wave
/plugin install cogni-trends@insight-wave
/plugin install cogni-portfolio@insight-wave
/plugin install cogni-narrative@insight-wave
/plugin install cogni-copywriting@insight-wave
/plugin install cogni-sales@insight-wave
/plugin install cogni-marketing@insight-wave
/plugin install cogni-visual@insight-wave
/plugin install cogni-claims@insight-wave
/plugin install cogni-consulting@insight-wave
/plugin install cogni-help@insight-wave
```

Or browse interactively with `/plugin` and go to the **Discover** tab.

### 3. Initialize your workspace

```
/init-workspace
```

This runs dependency checks, discovers installed plugins, gathers your preferences, and generates shared settings. See the [getting started guide](docs/getting-started.md) for the full walkthrough.

## How it works

insight-wave runs on [Claude Cowork](https://claude.ai/cowork), Anthropic's agentic desktop application. Plugins are installed from this marketplace and loaded on demand — skills, agents, and slash commands activate when relevant to your task.

The workplace combines Claude Cowork with [Obsidian](https://obsidian.md/) for persistent, browsable knowledge management. Everything runs on your laptop — no cloud infrastructure required, GDPR-compliant by design.

```
insight-wave/
├── .claude-plugin/
│   └── marketplace.json                    # Marketplace manifest (12 plugins)
├── docs/                                   # User documentation
│   ├── getting-started.md                  # Installation and first steps
│   ├── ecosystem-overview.md               # Plugin landscape and data flow
│   ├── plugin-guide/                       # Per-plugin deep dives (12 guides)
│   ├── workflows/                          # Cross-plugin pipeline guides (5 workflows)
│   ├── architecture/                       # Design philosophy, plugin anatomy, ER diagram
│   └── contributing/                       # Plugin development guide
├── cogni-claims/                           # Claim verification
├── cogni-copywriting/                      # Copywriting toolkit
├── cogni-consulting/                       # Double Diamond orchestrator
├── cogni-research/                         # Multi-agent research reports
├── cogni-marketing/                        # B2B marketing content engine
├── cogni-narrative/                        # Story arc narrative transformation
├── cogni-portfolio/                        # Portfolio messaging & planning
├── cogni-sales/                            # B2B sales pitch generation
├── cogni-help/                             # Help hub: courses, guide, workflows, troubleshoot
├── cogni-trends/                           # Trend scouting & reporting
├── cogni-visual/                           # Visual deliverables
├── cogni-workspace/                        # Workspace orchestrator
├── cogni-portfolio-evals/                  # Eval harness (not a marketplace plugin)
├── CLA.md                                  # Contributor License Agreement
├── CODE_OF_CONDUCT.md                      # Contributor Covenant v2.1
├── CONTRIBUTING.md                         # Contribution guide & CLA info
├── LICENSE                                 # AGPL-3.0-only
├── MARKETPLACE_TERMS.md                    # Third-party plugin terms
├── ROADMAP.md                              # Patent-based ecosystem roadmap
├── SECURITY.md                             # Vulnerability disclosure policy
├── community-plugin-contributing-template.md
└── README.md
```

Plugins follow the [Claude Code plugin standard](https://code.claude.com/docs/en/plugins-reference). No external dependencies — everything runs inside your Claude Cowork session.

## Plugins at a glance

| Plugin | Capability | What it does |
|--------|-----------|--------------|
| [cogni-sales](cogni-sales/README.md) | Sales | Corporate Visions Why Change pitch generation for named customers or market segments |
| [cogni-portfolio](cogni-portfolio/README.md) | Portfolio | IS/DOES/MEANS portfolio positioning with eight industry taxonomies, competitive analysis, and market sizing |
| [cogni-marketing](cogni-marketing/README.md) | Content | B2B marketing content engine — 16 formats across thought leadership, demand gen, lead gen, sales enablement, ABM |
| [cogni-copywriting](cogni-copywriting/README.md) | Content | Professional copywriting with 7 messaging frameworks, 5 stakeholder personas, and arc-aware polishing |
| [cogni-narrative](cogni-narrative/README.md) | Content | Story arc narrative transformation using 7 frameworks with quality scoring and derivative format adaptation |
| [cogni-consulting](cogni-consulting/README.md) | Consulting | Double Diamond consulting orchestrator with 8 vision classes and Lean Canvas authoring |
| [cogni-research](cogni-research/README.md) | Research | Multi-agent web research with parallel section researchers, five report types, and claims-verified review loops |
| [cogni-trends](cogni-trends/README.md) | Trend Intelligence | TIPS trend scouting with bilingual DE/EN research, investment theme modeling, and reusable industry catalogs |
| [cogni-visual](cogni-visual/README.md) | Visual | Slide decks, journey maps, solution architectures, web narratives, and poster storyboards from narratives |
| [cogni-claims](cogni-claims/README.md) | Quality | Source verification — catches misquotations, unsupported conclusions, and stale data in sourced claims |
| [cogni-help](cogni-help/README.md) | Platform | 12-course curriculum, plugin discovery, workflow templates, troubleshooting, and cheatsheets |
| [cogni-workspace](cogni-workspace/README.md) | Platform | Shared foundation — env vars, theme management, plugin discovery, workspace health, Obsidian integration |

See [Cross-Plugin Data Flow](docs/er-diagram.md) for how data flows between plugins, or browse the [full documentation](docs/getting-started.md).

Workflow guides: [Research to Report](docs/workflows/research-to-report.md) | [Portfolio to Pitch](docs/workflows/portfolio-to-pitch.md) | [Trends to Solutions](docs/workflows/trends-to-solutions.md) | [Consulting Engagement](docs/workflows/consulting-engagement.md) | [Content Pipeline](docs/workflows/content-pipeline.md)

## Contributing

We welcome contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, CLA requirements, and marketplace plugin guidelines. By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

To build your own plugin, start from the [community plugin template](community-plugin-contributing-template.md) and the [plugin development guide](docs/contributing/plugin-development.md).

Contributions range from bug fixes and documentation improvements to new plugins and taxonomy templates. Open an issue to discuss your plugin idea before starting development — we'll help you find the right architecture fit.

All plugins are developed directly in this monorepo. To report issues or suggest improvements, open an issue on [insight-wave](https://github.com/cogni-work/insight-wave/issues).

## Professional services

Build your own plugins using the [community template](community-plugin-contributing-template.md) and the [Claude Code plugin standard](https://code.claude.com/docs/en/plugins-reference).

cogni-works offers plugin engineering for domain-specific workflows, managed deployment with team onboarding, and a partner certification program for firms building practices on the platform. These services complement the open-source plugins with implementation expertise, ongoing maintenance, and formal qualification paths.

[cogni-work.ai](https://cogni-work.ai)

## License

All plugins are licensed under AGPL-3.0-only. See [LICENSE](LICENSE) for details.

---

Built by [cogni-work](https://cogni-work.ai) — open-source plugins for Claude Code.
