# cogni-workspace

Lean workspace orchestrator for cogni-works [Claude Cowork](https://claude.ai/cowork) marketplace plugins. Manages shared foundation (environment variables, settings), theme management, plugin discovery, and workspace health — so all cogni-x plugins operate from a consistent, well-configured base.

## Why this exists

Each cogni-works plugin needs environment variables, themes, and discovery of sibling plugins. Without a shared orchestrator, every plugin reinvents configuration:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No shared config | Each plugin manages its own env vars and paths | Inconsistent setup, manual duplication |
| Theme fragmentation | Visual plugins each scan for themes independently | Broken renders when theme paths don't match |
| Plugin drift | No way to detect version mismatches or missing dependencies | Skills fail at runtime with cryptic errors |
| Manual setup | Every new workspace requires manual scaffolding | 20+ minutes of boilerplate per project |

This plugin provides the infrastructure layer — workspace initialization, theme management, plugin discovery, and health diagnostics — so domain plugins can focus on their actual work.

## What it does

1. **Initialize** a workspace — dependency checks, plugin discovery, preference gathering (language, tool integrations), settings generation
2. **Manage themes** — extract from websites (via Chrome), PPTX files, or presets; audit for contrast and harmony; apply to downstream skills
3. **Pick themes** — centralized theme picker used by all visual plugins
4. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
5. **Diagnose** workspace health — five-tier report (foundation, env vars, plugin registry, themes, dependencies)
6. **Update** workspace — re-scan plugins, refresh env vars, regenerate settings with backup and rollback

## What it means for you

- **One command to set up.** `init-workspace` handles dependencies, discovery, env vars, settings, themes, and output styles.
- **Consistent theming.** All visual plugins use the same theme picker and theme format — no per-plugin configuration.
- **Health monitoring.** `workspace-status` catches drift, missing dependencies, and stale configurations before they cause failures.
- **Safe updates.** `update-workspace` backs up before modifying and supports rollback.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

**Prerequisites:**
- `jq` (required — JSON processing)
- `python3` (required — stdlib only, no pip)
- `bash 3.2+` (required)
- Optional: `curl`, `git`, `bc`

## Quick start

```
/init-workspace    # initialize a new workspace
/workspace-status  # check health
/update-workspace  # refresh after plugin changes
/pick-theme        # select a theme interactively
/manage-themes     # extract, create, audit, or apply themes
/cogni-issues      # file a GitHub issue against cogni-works
```

Or describe what you want:

- "Initialize a cogni-works workspace here"
- "What's the status of my workspace?"
- "Extract a theme from this website"
- "Update my workspace after installing new plugins"

## Try it

After installing, type one prompt:

> Initialize a cogni-works workspace

Claude checks dependencies, discovers installed plugins, asks for your language preference and tool integrations, then generates `.claude/settings.local.json`, `.workspace-env.sh`, `.workspace-config.json`, output style templates, and the default theme. Your workspace is ready for all cogni-x plugins.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `init-workspace` | skill | Full workspace initialization — dependencies, discovery, preferences, settings, themes |
| `manage-themes` | skill | 8 theme operations: recommend, list, grab from website, grab from PPTX, create from preset, audit, generate showcase, apply |
| `pick-theme` | skill | Centralized theme picker — discovers themes, presents interactive selection, returns path |
| `cogni-issues` | skill | GitHub issue lifecycle — create (with duplicate check and root cause hypothesis), list, status, browse |
| `update-workspace` | skill | Re-scan plugins, refresh env vars, update output styles, backup and rollback support |
| `workspace-status` | skill | Five-tier diagnostic: foundation, env vars, plugin registry, themes, dependencies |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; supports `--update` to preserve custom env vars |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       6 workspace management skills
│   ├── init-workspace/
│   ├── manage-themes/
│   ├── pick-theme/
│   ├── cogni-issues/
│   ├── update-workspace/
│   └── workspace-status/
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   └── on-session-start.sh
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── discover-plugins.sh
│   └── generate-settings.sh
├── themes/                       Brand theme storage
│   ├── _template/                Canonical theme template
│   └── cogni-work/               Bundled brand theme + showcase
└── assets/
    └── output-styles/            Language-specific behavioral anchors (EN/DE)
```

## Dependencies

cogni-workspace has no plugin dependencies — it is the foundation layer that other plugins depend on.

## Custom development

Need enterprise workspace configurations, custom theme infrastructure, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
