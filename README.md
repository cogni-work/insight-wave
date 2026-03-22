# cogni-works

Open-source plugin ecosystem for [Claude Cowork](https://claude.ai/cowork) — the Integrated Workplace Agent Environment for consulting, B2B sales, and marketing.

Scale your delivery capacity with virtual co-workers that handle research, analysis, messaging, and visual production while you focus on strategic judgment and client relationships.

Built and battle-tested at [cogni-work](https://github.com/cogni-work), then extracted for the community.

## Who this is for

### Consulting Boutiques

You compete with Big 5 firms on complexity — but not on headcount. cogni-works gives your team 10x delivery capacity through AI-native workflows that handle the research-heavy, repetitive knowledge work:

- **Trend scouting** — scan industries bilingually (EN/DE), score trends against strategic frameworks, and generate evidence-backed reports in hours, not weeks
- **Research reports** — parallel multi-agent web research with claims verification and three depth levels
- **Portfolio messaging** — build structured IS/DOES/MEANS value propositions, competitive analysis, and market sizing from a single project setup
- **Sales pitches** — Corporate Visions Why Change methodology, fully researched and narrated per customer or segment
- **Visual deliverables** — slide decks, journey maps, solution architectures, web narratives, and poster storyboards — generated from your content, not templates

### Consulting Partners

You see the AI consulting opportunity but need a platform and methodology to deliver it. cogni-works provides the production-ready plugin ecosystem:

- **Open-source core** — 14 plugins covering the full consulting pipeline from research through delivery
- **Extensible architecture** — build domain-specific plugins on the same framework
- **Training built in** — 11-course interactive curriculum to onboard your team and clients
- **Bilingual** — full DE/EN support across the stack, purpose-built for DACH markets

### AI-Ambitious SMEs

You want AI-native workflows for your sales and marketing teams — either self-service or with consulting support:

- **Marketing content engine** — bridge your portfolio and market trends into 16 channel-ready formats (blogs, whitepapers, battle cards, campaigns)
- **Portfolio planning** — structure your product messaging, market targeting, and competitive positioning
- **Proven templates** — battle-tested workflows, not blank-slate AI experimentation

## Plugins

| Plugin | What it does |
|--------|-------------|
| [cogni-canvas](./cogni-canvas) | Lean Canvas authoring and refinement — guided Q&A, section-by-section critique, multi-persona stress testing, and version tracking. |
| [cogni-claims](./cogni-claims) | Verify sourced claims against cited URLs. Catches citation errors, misquotations, and unsupported conclusions before content ships. |
| [cogni-copywriting](./cogni-copywriting) | Professional copywriting toolkit with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB), multi-stakeholder review, and readability optimization. Bilingual EN/DE. |
| [cogni-diamond](./cogni-diamond) | Double Diamond consulting orchestrator. Guides engagements through Discover, Define, Develop, Deliver by dispatching to cogni-works plugins at the right phase. Vision-first, method-aware, phase-gated. |
| [cogni-gpt-researcher](./cogni-gpt-researcher) | Multi-agent research report generator. STORM-inspired editorial workflow with parallel web research, claims-verified review loops, and three depth levels (basic, detailed, deep). |
| [cogni-marketing](./cogni-marketing) | B2B marketing content engine. Bridges TIPS themes and portfolio propositions into channel-ready content across 16 formats — thought leadership, demand gen, lead gen, sales enablement, ABM. Bilingual DE/EN. |
| [cogni-narrative](./cogni-narrative) | Story arc-driven narrative transformation. Transforms structured content into executive narratives using 6 story arc frameworks and 8 narrative techniques. Bilingual EN/DE. |
| [cogni-obsidian](./cogni-obsidian) | Obsidian integration for Claude Cowork workplaces. Scaffolds vaults with Terminal plugin, manages terminal profiles across platforms, and provides note management with frontmatter support. |
| [cogni-portfolio](./cogni-portfolio) | Portfolio messaging and proposition planning using IS/DOES/MEANS framework. Eight industry taxonomies, TAM/SAM/SOM market sizing, competitive analysis, and export-ready deliverables. |
| [cogni-sales](./cogni-sales) | B2B sales pitch generation using Corporate Visions Why Change methodology. Research-backed presentations and proposals for named customers or market segments. Bilingual DE/EN. |
| [cogni-teacher](./cogni-teacher) | Interactive 45-minute courses teaching Claude Cowork fundamentals and cogni-works plugins. 11-course curriculum with hands-on exercises and progress tracking. |
| [cogni-tips](./cogni-tips) | Strategic trend scouting and reporting pipeline. Combines the Smarter Service Trendradar with the TIPS framework for DACH-focused industry trend analysis. Bilingual EN/DE. |
| [cogni-visual](./cogni-visual) | Transform polished narratives into visual deliverables — slide decks, big-picture journey maps, Big Block solution architectures, scrollable web narratives, and poster storyboards. |
| [cogni-workspace](./cogni-workspace) | Lean workspace orchestrator. Manages shared foundation (env vars, settings), theme management, plugin discovery, and workspace health diagnostics. |

See [Cross-Plugin Data Flow](docs/er-diagram.md) for how data flows between plugins.

## Quick start

### Add the marketplace

```shell
/plugin marketplace add cogni-work/cogni-works
```

### Install a plugin

```shell
/plugin install cogni-canvas@cogni-works
/plugin install cogni-claims@cogni-works
/plugin install cogni-copywriting@cogni-works
/plugin install cogni-diamond@cogni-works
/plugin install cogni-gpt-researcher@cogni-works
/plugin install cogni-marketing@cogni-works
/plugin install cogni-narrative@cogni-works
/plugin install cogni-obsidian@cogni-works
/plugin install cogni-portfolio@cogni-works
/plugin install cogni-sales@cogni-works
/plugin install cogni-teacher@cogni-works
/plugin install cogni-tips@cogni-works
/plugin install cogni-visual@cogni-works
/plugin install cogni-workspace@cogni-works
```

Or browse interactively with `/plugin` and go to the **Discover** tab.

## How it works

cogni-works runs on [Claude Cowork](https://claude.ai/cowork), Anthropic's agentic desktop application. Plugins are installed from this marketplace and loaded on demand — skills, agents, and slash commands activate when relevant to your task.

The workplace combines Claude Cowork with [Obsidian](https://obsidian.md/) for persistent, browsable knowledge management. Everything runs on your laptop — no cloud infrastructure required, GDPR-compliant by design.

```
cogni-works/
├── .claude-plugin/
│   └── marketplace.json                    # Marketplace manifest (14 plugins)
├── docs/
│   └── er-diagram.md                       # Cross-plugin data flow diagram
├── cogni-canvas/                            # Lean Canvas authoring
├── cogni-claims/                           # Claim verification
├── cogni-copywriting/                      # Copywriting toolkit
├── cogni-diamond/                           # Double Diamond orchestrator
├── cogni-gpt-researcher/                   # Multi-agent research reports
├── cogni-marketing/                        # B2B marketing content engine
├── cogni-narrative/                        # Story arc narrative transformation
├── cogni-obsidian/                         # Obsidian integration
├── cogni-portfolio/                        # Portfolio messaging & planning
├── cogni-sales/                            # B2B sales pitch generation
├── cogni-teacher/                          # Interactive training courses
├── cogni-tips/                             # Trend scouting & reporting
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

## Custom development

Need to customize existing plugins for your workflows, integrate with your internal systems, or build entirely new plugins for your domain? We offer plugin development, onboarding, and maintenance services.

Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai) to discuss your requirements.

## Contributing

We welcome contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, CLA requirements, and marketplace plugin guidelines. By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

All plugins are developed directly in this monorepo. To report issues or suggest improvements, open an issue on [cogni-works](https://github.com/cogni-work/cogni-works/issues).

## License

All plugins are licensed under AGPL-3.0-only. See [LICENSE](LICENSE) for details.
