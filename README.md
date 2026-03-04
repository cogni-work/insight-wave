# cogni-works

Open-source Claude Code plugins for knowledge work — consulting, B2B sales, and marketing.

Built and battle-tested at [cogni-work](https://github.com/cogni-work), then extracted for the community.

## Plugins

| Plugin | What it does |
|--------|-------------|
| [cogni-claims](./cogni-claims) | Verify sourced claims against cited URLs. Catches citation errors, misquotations, and unsupported conclusions before content ships. |
| [cogni-obsidian](./cogni-obsidian) | Obsidian integration for Claude Code workplaces. Scaffolds vaults with Terminal plugin and manages cross-platform terminal profiles. |

## Quick start

### Add the marketplace

```shell
/plugin marketplace add cogni-work/cogni-works
```

### Install a plugin

```shell
/plugin install cogni-claims@cogni-works
/plugin install cogni-obsidian@cogni-works
```

Or browse interactively with `/plugin` and go to the **Discover** tab.

## Who this is for

You work in consulting, B2B sales, or marketing — and you use Claude Code as your daily driver. These plugins handle the repetitive knowledge work so you can focus on the thinking:

- **Claim verification** — fact-check reports and proposals against their sources
- **Obsidian workplaces** — set up and manage Obsidian vaults as collaborative Claude Code environments

## How it works

cogni-works is a [Claude Code plugin marketplace](https://code.claude.com/docs/en/discover-plugins). Each plugin is a self-contained submodule with skills, agents, and slash commands that Claude loads on demand.

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
│   └── commands/
└── README.md
```

Plugins follow the [Claude Code plugin standard](https://code.claude.com/docs/en/plugins-reference). No external dependencies — everything runs inside your Claude Code session.

## Contributing

We welcome contributions. Each plugin lives in its own repository and is included here as a Git submodule.

To report issues or suggest improvements, open an issue on the relevant plugin repo or on [cogni-works](https://github.com/cogni-work/cogni-works/issues).

## License

Individual plugins carry their own licenses. See each plugin's repository for details.
