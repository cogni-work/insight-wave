# cogni-works

Open-source Claude Code plugins for knowledge work — consulting, B2B sales, and marketing.

Built and battle-tested at [cogni-work](https://github.com/cogni-work), then extracted for the community.

## Plugins

| Plugin | What it does |
|--------|-------------|
| [cogni-claims](./cogni-claims) | Verify sourced claims against cited URLs. Catches citation errors, misquotations, and unsupported conclusions before content ships. |
| [cogni-obsidian](./cogni-obsidian) | Obsidian integration for Claude Code workplaces. Scaffolds vaults with Terminal plugin, manages vault configuration, and provides note management with frontmatter support. |
| [cogni-copywriting](./cogni-copywriting) | Professional copywriting toolkit with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB), stakeholder review, sales enhancement (Power Positions), and readability optimization. |
| [cogni-narrative](./cogni-narrative) | Story arc-driven narrative transformation. Transforms structured content into compelling executive narratives using 6 story arc frameworks. |
| [cogni-tips](./cogni-tips) | Strategic trend scouting and reporting pipeline. Combines the Smarter Service Trendradar with the TIPS framework for industry trend analysis. Bilingual (EN/DE). |
| [cogni-portfolio](./cogni-portfolio) | Portfolio messaging and proposition planning for SMEs using IS/DOES/MEANS framework. Features, advantages, and benefits with TAM/SAM/SOM targeting, competitor and customer analysis. |
| [cogni-visual](./cogni-visual) | Transform polished narratives into visual deliverables — presentation briefs, slide decks, big picture journey maps, scrollable web narratives, poster storyboards, and visual assets. Supports Excalidraw, Pencil MCP, and PPTX rendering. |
| [cogni-teacher](./cogni-teacher) | Interactive teaching and training plugin. Guides learners through structured modules with adaptive exercises, knowledge checks, and progress tracking. |
| [cogni-workspace](./cogni-workspace) | Lean workspace orchestrator. Manages shared foundation (env vars, settings), theme management, plugin discovery, and workspace health. |

## Quick start

### Add the marketplace

```shell
/plugin marketplace add cogni-work/cogni-works
```

### Install a plugin

```shell
/plugin install cogni-claims@cogni-works
/plugin install cogni-obsidian@cogni-works
/plugin install cogni-copywriting@cogni-works
/plugin install cogni-narrative@cogni-works
/plugin install cogni-tips@cogni-works
/plugin install cogni-portfolio@cogni-works
/plugin install cogni-visual@cogni-works
/plugin install cogni-teacher@cogni-works
/plugin install cogni-workspace@cogni-works
```

Or browse interactively with `/plugin` and go to the **Discover** tab.

## Who this is for

You work in consulting, B2B sales, or marketing — and you use Claude Code as your daily driver. These plugins handle the repetitive knowledge work so you can focus on the thinking:

- **Claim verification** — fact-check reports and proposals against their sources
- **Copywriting** — polish documents with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB), sales enhancement (Power Positions), and stakeholder review
- **Narrative transformation** — turn structured content into executive narratives using story arc frameworks
- **Obsidian workplaces** — set up and manage Obsidian vaults as collaborative Claude Code environments
- **Trend scouting** — strategic trend analysis with TIPS framework and Smarter Service Trendradar, bilingual (EN/DE)
- **Portfolio messaging** — proposition planning for SMEs with IS/DOES/MEANS framework, competitor research, and market targeting
- **Visual deliverables** — presentation briefs, slide decks, big picture journey maps, web narratives, and poster storyboards from polished narratives
- **Workspace orchestration** — shared foundation, themes, plugin discovery, and workspace health

## How it works

cogni-works is a [Claude Code plugin marketplace](https://code.claude.com/docs/en/discover-plugins). All plugins live inline in this monorepo. Claude loads skills, agents, and slash commands on demand.

```
cogni-works/
├── .claude-plugin/
│   └── marketplace.json    # Marketplace manifest
├── cogni-claims/           # Claim verification plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── commands/
├── cogni-obsidian/         # Obsidian integration plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   └── hooks/
├── cogni-copywriting/       # Copywriting toolkit plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── commands/
├── cogni-narrative/         # Narrative transformation plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── commands/
├── cogni-tips/             # Trend scouting & reporting plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── scripts/
├── cogni-portfolio/        # Portfolio messaging plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── scripts/
├── cogni-visual/           # Visual deliverables plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   ├── commands/
│   ├── hooks/
│   └── libraries/
├── cogni-teacher/          # Teaching & training plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── agents/
│   └── commands/
├── cogni-workspace/        # Workspace orchestrator plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   ├── hooks/
│   └── scripts/
└── README.md
```

Plugins follow the [Claude Code plugin standard](https://code.claude.com/docs/en/plugins-reference). No external dependencies — everything runs inside your Claude Code session.

## Contributing

We welcome contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, CLA requirements, and marketplace plugin guidelines. By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

All plugins are developed directly in this monorepo. To report issues or suggest improvements, open an issue on [cogni-works](https://github.com/cogni-work/cogni-works/issues).

## License

All plugins are licensed under AGPL-3.0-only. See [LICENSE](LICENSE) for details.
