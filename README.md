# insight-wave

Open-source plugin ecosystem for [Claude Cowork](https://claude.ai/cowork) that covers the full consulting and B2B sales pipeline — from research and trend scouting through portfolio positioning, narrative creation, and visual production to verified, brand-consistent deliverables.

12 plugins with 79 skills, 56 agents, and structured cross-plugin workflows. Each plugin handles one stage of the pipeline; together they form a continuous chain where the output of one becomes the input of the next.

<!-- Architecture diagram placeholder: create an ecosystem visual using
     cogni-visual:story-to-big-picture, save as architecture.excalidraw,
     export to assets/architecture.svg, then re-run /doc-bridge -->

## The Journey

insight-wave plugins work together across seven stages of the consulting workflow. Each stage builds on the previous one's output.

### Research & Discover

Start by gathering evidence. [cogni-research](cogni-research/README.md) runs parallel web research agents (5-25 concurrently depending on depth level) to produce multi-section reports with inline citations — from a basic 3,000-word scan to recursive deep-research trees of 15,000 words. [cogni-trends](cogni-trends/README.md) scouts industry trends across four TIPS dimensions with bilingual DE/EN web research, producing 60 scored trend candidates per run using multi-framework analysis (TIPS, Ansoff, Rogers, CRAAP).

> "Research the competitive landscape for cloud monitoring in the DACH mid-market — detailed report with IEEE citations"

### Analyze & Position

Structure evidence into a sellable portfolio. [cogni-portfolio](cogni-portfolio/README.md) defines products, features, and target markets, then generates IS/DOES/MEANS value propositions for each Feature x Market pair. 20 skills and 17 agents handle market sizing (TAM/SAM/SOM), competitive analysis, customer profiling, and solution planning — with three-layer quality assessment at each step. Eight industry taxonomies (ICT, SaaS, FinTech, HealthTech, MarTech, Industrial Tech, Professional Services, Open Source) classify your portfolio automatically.

> "Set up a portfolio for our cloud monitoring product targeting mid-market SaaS companies in DACH"

### Create & Articulate

Turn structured data into executive-readable stories. [cogni-narrative](cogni-narrative/README.md) applies one of 7 story arc frameworks (Corporate Visions, Technology Futures, Competitive Intelligence, Strategic Foresight, Industry Transformation, Trend Panorama, Theme-Thesis) to transform research output into narratives with quality scoring (0-100, A-F grades). [cogni-copywriting](cogni-copywriting/README.md) then polishes for readability using 7 messaging frameworks and 5 parallel stakeholder personas — detecting story arc frontmatter to apply arc-specific techniques.

> "Transform this research into a Corporate Visions narrative, then polish for executive readability"

### Sell & Deliver

Win the deal. [cogni-sales](cogni-sales/README.md) generates Corporate Visions Why Change pitches — four research phases (Why Change, Why Now, Why You, Why Pay) each backed by dedicated web research agents, producing a sales-presentation.md and sales-proposal.md per customer or market segment. [cogni-marketing](cogni-marketing/README.md) bridges portfolio propositions and trend themes into channel-ready content across 16 formats and 5 content types (thought leadership, demand gen, lead gen, sales enablement, ABM). [cogni-consulting](cogni-consulting/README.md) orchestrates full Double Diamond engagements — dispatching to research, trends, portfolio, and claims plugins at the right phase.

> "Create a Why Change pitch for Siemens AG based on our cloud monitoring portfolio"

### Visualize & Present

Make it visual. [cogni-visual](cogni-visual/README.md) transforms narratives into 5 visual formats: slide decks (11 layout types), big-picture journey maps (1,100-1,500 Excalidraw elements), Big Block solution architecture diagrams, scrollable web narratives, and printed poster storyboards. 7 skills generate structured briefs; 13 agents render them into final output files. All visuals inherit brand identity from your workspace theme.

> "Create a slide deck from the sales presentation, then render the strategy as a big picture journey map"

### Verify & Trust

Check before you ship. [cogni-claims](cogni-claims/README.md) verifies whether sourced claims match what their cited sources actually say. Other plugins register claims during generation; cogni-claims fetches each source URL, compares the claim against the actual content, and flags misquotations, unsupported conclusions, selective omissions, and stale data. Five operating modes: submit, verify, dashboard, inspect, resolve.

> "Verify all claims in the trend report against their cited sources"

### Learn & Operate

Set up and skill up. [cogni-help](cogni-help/README.md) provides an 11-course interactive curriculum covering every plugin, 5 cross-plugin workflow templates, plugin discovery, troubleshooting diagnostics, and quick-reference cheatsheets. [cogni-workspace](cogni-workspace/README.md) manages the shared foundation — environment variables, plugin discovery, theme management, workspace health, and Obsidian vault integration.

> "Teach me how to use insight-wave" or "Set up my workspace with Obsidian integration"

## Who this is for

### Consulting Boutiques

You compete with Big 5 firms on complexity — but not on headcount. insight-wave gives your team 10x delivery capacity through AI-native workflows that handle the research-heavy, repetitive knowledge work:

- **Trend scouting** — scan industries bilingually (EN/DE), score trends against strategic frameworks, and generate evidence-backed reports in hours, not weeks
- **Research reports** — parallel multi-agent web research with claims verification and three depth levels
- **Portfolio messaging** — build structured IS/DOES/MEANS value propositions, competitive analysis, and market sizing from a single project setup
- **Sales pitches** — Corporate Visions Why Change methodology, fully researched and narrated per customer or segment
- **Visual deliverables** — slide decks, journey maps, solution architectures, web narratives, and poster storyboards — generated from your content, not templates

For onboarding, customization, or managed delivery: [cogni-work.ai](https://cogni-work.ai)

### Consulting Partners

You see the AI consulting opportunity but need a platform and methodology to deliver it. insight-wave provides the production-ready plugin ecosystem:

- **Open-source core** — 12 plugins covering the full consulting pipeline from research through delivery
- **Extensible architecture** — build domain-specific plugins on the same framework
- **Training built in** — 11-course interactive curriculum to onboard your team and clients
- **Bilingual** — full DE/EN support across the stack, purpose-built for DACH markets

### AI-Ambitious SMEs

You want AI-native workflows for your sales and marketing teams — either self-service or with consulting support:

- **Marketing content engine** — bridge your portfolio and market trends into 16 channel-ready formats (blogs, whitepapers, battle cards, campaigns)
- **Portfolio planning** — structure your product messaging, market targeting, and competitive positioning
- **Proven templates** — battle-tested workflows, not blank-slate AI experimentation

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

| Plugin | Stage | Skills | Agents | What it does |
|--------|-------|--------|--------|--------------|
| [cogni-research](cogni-research/README.md) | Research | 4 | 8 | Multi-agent web research with parallel section researchers, five report types, and claims-verified review loops |
| [cogni-trends](cogni-trends/README.md) | Research | 6 | 4 | TIPS trend scouting with bilingual DE/EN research, investment theme modeling, and reusable industry catalogs |
| [cogni-portfolio](cogni-portfolio/README.md) | Analyze | 20 | 17 | IS/DOES/MEANS portfolio positioning with eight industry taxonomies, competitive analysis, and market sizing |
| [cogni-narrative](cogni-narrative/README.md) | Create | 3 | 3 | Story arc narrative transformation using 7 frameworks with quality scoring and derivative format adaptation |
| [cogni-copywriting](cogni-copywriting/README.md) | Create | 4 | 2 | Professional copywriting with 7 messaging frameworks, 5 stakeholder personas, and arc-aware polishing |
| [cogni-sales](cogni-sales/README.md) | Sell | 1 | 2 | Corporate Visions Why Change pitch generation for named customers or market segments |
| [cogni-marketing](cogni-marketing/README.md) | Sell | 11 | 3 | B2B marketing content engine — 16 formats across thought leadership, demand gen, lead gen, sales enablement, ABM |
| [cogni-consulting](cogni-consulting/README.md) | Sell | 7 | 1 | Double Diamond consulting orchestrator with 8 vision classes and Lean Canvas authoring |
| [cogni-visual](cogni-visual/README.md) | Visualize | 7 | 13 | Slide decks, journey maps, solution architectures, web narratives, and poster storyboards from narratives |
| [cogni-claims](cogni-claims/README.md) | Verify | 2 | 2 | Source verification — catches misquotations, unsupported conclusions, and stale data in sourced claims |
| [cogni-help](cogni-help/README.md) | Learn | 7 | 1 | 11-course curriculum, plugin discovery, workflow templates, troubleshooting, and cheatsheets |
| [cogni-workspace](cogni-workspace/README.md) | Operate | 7 | 0 | Shared foundation — env vars, theme management, plugin discovery, workspace health, Obsidian integration |

See [Cross-Plugin Data Flow](docs/er-diagram.md) for how data flows between plugins, or browse the [full documentation](docs/getting-started.md).

## Contributing

We welcome contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, CLA requirements, and marketplace plugin guidelines. By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

To build your own plugin, start from the [community plugin template](community-plugin-contributing-template.md) and the [plugin development guide](docs/contributing/plugin-development.md).

Contributions range from bug fixes and documentation improvements to new plugins and taxonomy templates. Open an issue to discuss your plugin idea before starting development — we'll help you find the right architecture and stage fit.

All plugins are developed directly in this monorepo. To report issues or suggest improvements, open an issue on [insight-wave](https://github.com/cogni-work/insight-wave/issues).

## Custom development

Need to customize existing plugins for your workflows, integrate with your internal systems, or build entirely new plugins for your domain? We offer plugin development, onboarding, and maintenance services.

Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai) to discuss your requirements.

## License

All plugins are licensed under AGPL-3.0-only. See [LICENSE](LICENSE) for details.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
