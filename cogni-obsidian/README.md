# cogni-obsidian

Obsidian integration for [Claude Cowork](https://claude.ai/cowork) workplaces. Scaffolds vault configurations with Terminal plugin integration, manages terminal profiles across platforms, and provides standardized note creation with YAML frontmatter.

## Why this exists

Claude Cowork sessions are ephemeral — when the session ends, context disappears. Teams need persistent, browsable workspaces where research, narratives, and portfolio data can be explored, linked, and visualized:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Ephemeral sessions | Claude Code work products exist as files but lack a browsing interface | Users can't explore relationships between outputs |
| No graph navigation | Markdown files with wikilinks exist but no tool renders the connections | Cross-reference value is invisible |
| Platform fragmentation | macOS, Linux, and Windows/WSL each need different terminal configurations | Manual setup per platform, broken profiles on team shares |
| Manual vault setup | Obsidian requires 6+ config files and a community plugin download | 15+ minutes of boilerplate per workplace |

This plugin scaffolds a complete Obsidian vault — including the Terminal plugin for launching Claude Code directly from Obsidian — so cogni-x plugin outputs become a browsable, linked knowledge workspace.

## What it does

1. **Scaffold** a complete `.obsidian/` configuration: vault settings, Moonstone theme, 15 core plugins, Terminal community plugin (auto-downloaded), Tokyonight-themed terminal profiles, and a workplace launcher script
2. **Update** existing vaults incrementally — merge new terminal profiles, fix WSL issues, remove deprecated profiles, copy new scripts — without overwriting user customizations
3. **Create notes** with consistent YAML frontmatter (title, date, tags, source, status) in kebab-case filenames

## What it means for you

- **One command to set up.** `setup-obsidian` handles config files, plugin download, terminal profiles, and launcher script.
- **Cross-platform.** macOS, Linux, Windows WSL, and Git Bash — all from a single template with automatic path substitution.
- **Safe updates.** `update-obsidian` merges new configurations without destroying your customizations.
- **Browse everything.** All cogni-x plugin outputs become Obsidian notes with frontmatter — searchable, linkable, and graph-navigable.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- [Obsidian](https://obsidian.md/) installed
- `jq` — JSON processing (`brew install jq` / `apt install jq`)
- `curl` — Terminal plugin download (`brew install curl` / `apt install curl`)

## Quick start

- "Set up Obsidian for my workplace at /path/to/my-project"
- "Update the Obsidian configuration for my workplace"
- "Create a note for the Q1 market analysis findings"

## Try it

After installing, type one prompt:

> Set up Obsidian for my workplace

Claude scaffolds the `.obsidian/` directory with all config files, downloads the Terminal community plugin, configures platform-appropriate terminal profiles with Tokyonight colors, and creates a workplace launcher script. Open the directory as an Obsidian vault and click the Terminal ribbon icon to launch Claude Code.

## What gets created

```
.obsidian/
├── app.json                 Vault settings (live preview, line numbers, link updates)
├── appearance.json          Theme (moonstone), base font size
├── core-plugins.json        15 enabled core plugins (explorer, search, graph, backlinks...)
├── community-plugins.json   Terminal plugin enabled
├── workspace.json           Multi-pane layout (editor, file explorer, search, bookmarks)
└── plugins/
    └── terminal/
        ├── main.js          Terminal plugin (downloaded from GitHub)
        ├── manifest.json    Plugin manifest
        ├── styles.css       Plugin styles
        ├── data.json        Terminal profiles with Tokyonight color scheme
        └── workplace-orchestrator.sh  Claude Code launcher with language + permission selection
```

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `obsidian-setup` | skill | Scaffold complete `.obsidian/` vault with Terminal plugin, profiles, and launcher. Supports `--dry-run`. Refuses to overwrite existing vaults |
| `update-obsidian` | skill | Incremental update — merge profiles, fix WSL issues, remove deprecated configs. Idempotent, supports `--dry-run` |
| `note-manager` | skill | Create markdown notes with YAML frontmatter (title, date required; tags, source, status optional). Kebab-case filenames |

## Platform support

| Platform | Terminal Profile | Path Format |
|----------|-----------------|-------------|
| macOS (Darwin) | `workplace` | Native (`/Users/...`) |
| Linux | `workplace` | Native (`/home/...`) |
| Windows (WSL) | `workplace-wsl` | WSL (`/mnt/c/...`) |
| Windows (Git Bash) | `workplace-wsl` | Converted (`/mnt/c/...`) |

Path placeholders (`{{WORKPLACE_ROOT}}` and `{{WORKPLACE_ROOT_WSL}}`) are substituted at setup time.

## Architecture

```
cogni-obsidian/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       3 integration skills
│   ├── obsidian-setup/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── update-obsidian/
│   │   └── SKILL.md
│   └── note-manager/
│       └── SKILL.md
└── hooks/
    └── hooks.json
```

This plugin follows the cogni-x **convention-based zero-coupling** architecture: each plugin owns its output scaffolding from a workspace root provided via environment variables. cogni-obsidian provides the vault and terminal integration layer — it does not manage plugin-specific folder structures.

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-workspace | No | Provides workspace root path and environment variables |

cogni-obsidian is standalone. All cogni-x plugin outputs become browsable vault content automatically through their wikilink conventions.

## Custom development

Need custom workspace integrations, enterprise vault configurations, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
