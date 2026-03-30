# cogni-workspace

Lean workspace orchestrator for insight-wave [Claude Cowork](https://claude.ai/cowork) marketplace plugins. Manages shared foundation (environment variables, settings), theme management, plugin discovery, workspace health, and Obsidian vault integration — so all cogni-x plugins operate from a consistent, well-configured base.

## Why this exists

Each insight-wave plugin needs environment variables, themes, and discovery of sibling plugins. Without a shared orchestrator, every plugin reinvents configuration:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No shared config | Each plugin manages its own env vars and paths | Inconsistent setup, manual duplication |
| Theme fragmentation | Visual plugins each scan for themes independently | Broken renders when theme paths don't match |
| Plugin drift | No way to detect version mismatches or missing dependencies | Skills fail at runtime with cryptic errors |
| Manual setup | Every new workspace requires manual scaffolding | 20+ minutes of boilerplate per project |

This plugin provides the infrastructure layer — workspace initialization, theme management, plugin discovery, and health diagnostics — so domain plugins can focus on their actual work.

## What it is

The shared foundation layer for the insight-wave ecosystem. Every cogni-x plugin depends on workspace for environment variables, plugin discovery, and theme resolution. A single initialization sets up the entire workspace; health diagnostics catch drift before downstream skills break. Theme management ensures all visual plugins — slides, journey maps, web narratives — render with consistent brand identity.

## What it does

1. **Manage workspace** — initialize or update a workspace with auto-detection, dependency checks, plugin discovery, preference gathering, settings generation, backup and rollback
2. **Manage themes** — extract from websites (via Chrome), PPTX files, or presets; audit for contrast and harmony; apply to downstream skills
3. **Pick themes** — centralized theme picker used by all visual plugins
4. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
5. **Diagnose** workspace health — five-tier report (foundation, env vars, plugin registry, themes, dependencies)
6. **Set up Obsidian** — scaffold `.obsidian/` vault with Terminal plugin and Claude Code launcher
7. **Update Obsidian** — incrementally refresh terminal profiles without overwriting customizations

## What it means for you

- **One command to set up or update.** `manage-workspace` auto-detects whether to initialize or update, handles dependencies, discovery, env vars, settings, themes, and output styles.
- **Consistent theming.** All visual plugins use the same theme picker and theme format — no per-plugin configuration.
- **Health monitoring.** `workspace-status` catches drift, missing dependencies, and stale configurations before they cause failures.
- **Safe updates.** `manage-workspace` backs up before modifying and supports rollback.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- `jq` (required — JSON processing)
- `python3` (required — stdlib only, no pip)
- `bash 3.2+` (required)
- Optional: `curl`, `git`, `bc`

## Quick start

```
/manage-workspace  # initialize or update a workspace
/workspace-status  # check health
/pick-theme        # select a theme interactively
/manage-themes     # extract, create, audit, or apply themes
/setup-obsidian    # scaffold Obsidian vault with terminal integration
/update-obsidian   # refresh terminal profiles in existing vault
```

> **Note:** Issue filing (`/issues`) has moved to [cogni-help](../cogni-help).

Or describe what you want:

- "Initialize a insight-wave workspace here"
- "What's the status of my workspace?"
- "Extract a theme from this website"
- "Update my workspace after installing new plugins"

## Try it

After installing, type one prompt:

> Initialize a insight-wave workspace

Claude checks dependencies, discovers installed plugins, asks for your language preference and tool integrations, then generates `.claude/settings.local.json`, `.workspace-env.sh`, `.workspace-config.json`, output style templates, and the default theme. Your workspace is ready for all cogni-x plugins.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `manage-workspace` | skill | Initialize or update workspace — auto-detects mode, dependencies, discovery, preferences, settings, themes, backup and rollback |
| `manage-themes` | skill | 8 theme operations: recommend, list, grab from website, grab from PPTX, create from preset, audit, generate showcase, apply |
| `pick-theme` | skill | Centralized theme picker — discovers themes, presents interactive selection, returns path |
| `workspace-status` | skill | Five-tier diagnostic: foundation, env vars, plugin registry, themes, dependencies |
| `setup-obsidian` | skill | Scaffold Obsidian vault with Terminal plugin, Tokyonight theme, and Claude Code launcher |
| `update-obsidian` | skill | Incrementally update terminal profiles and launcher scripts without overwriting customizations |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `check-skill-names.sh` | script | Validates skill directory names against plugin.json manifest for consistency |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; supports `--update` to preserve custom env vars |
| `setup-obsidian.sh` | script | Copies vault templates, downloads Terminal plugin, substitutes path placeholders |
| `update-obsidian.sh` | script | Merges profiles, fixes WSL paths, removes deprecated profiles, copies scripts |
| `portability-utils.sh` | script | Cross-platform utilities (macOS, Linux, WSL, Git Bash) |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       6 workspace management skills
│   ├── manage-workspace/
│   ├── manage-themes/
│   ├── pick-theme/
│   ├── setup-obsidian/           Obsidian vault scaffolding
│   │   └── templates/obsidian/   Vault config templates
│   ├── update-obsidian/          Obsidian config updater
│   └── workspace-status/
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   └── on-session-start.sh
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── check-skill-names.sh
│   ├── discover-plugins.sh
│   ├── generate-settings.sh
│   ├── setup-obsidian.sh
│   └── update-obsidian.sh
├── bash/                         Cross-platform utilities
│   └── portability-utils.sh
├── contracts/                    Script interface definitions
│   ├── setup-obsidian.yml
│   └── update-obsidian.yml
├── themes/                       Brand theme storage
│   ├── _template/                Canonical theme template
│   └── cogni-work/               Bundled brand theme + showcase
├── schemas/                      JSON schemas
│   └── examples/                 Schema usage examples
├── references/                   Reference documentation
└── assets/
    ├── claude-templates/         Language-specific CLAUDE.md templates (EN/DE)
    └── output-styles/            Language-specific behavioral anchors (EN/DE)
```

## Dependencies

cogni-workspace has no plugin dependencies — it is the foundation layer that other plugins depend on.

## Contributing

Contributions welcome — theme templates, platform support, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need enterprise workspace configurations, custom theme infrastructure, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
