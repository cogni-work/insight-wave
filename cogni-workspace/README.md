# cogni-workspace

Lean workspace orchestrator for cogni-works marketplace plugins. Manages shared foundation (environment variables, settings), theme management, plugin discovery, and workspace health — so all cogni-x plugins operate from a consistent, well-configured base.

> **Note**: This plugin provides the shared infrastructure layer for cogni-works plugins. It does not perform domain tasks itself — it ensures all other plugins have the environment, themes, and configuration they need.

## Installation

```bash
claude plugins add cogni-work/cogni-workspace
```

## Skills

| Skill | Description |
|-------|-------------|
| `init-workspace` | Initialize a cogni-works workspace with shared foundation — environment variables, directory structure, plugin discovery, and settings generation |
| `manage-themes` | Extract visual design themes from live websites (via Chrome), PowerPoint templates, or manual definition — stored as reusable theme files for cogni-visual |
| `update-workspace` | Refresh workspace configuration — sync plugin versions, update environment variables, regenerate settings, and re-run discovery |
| `workspace-status` | Diagnose and report on workspace health — plugin versions, missing dependencies, environment variable status, and configuration issues |

## Hooks

| Hook | Trigger | Description |
|------|---------|-------------|
| `on-session-start.sh` | Session start | Automatically sources workspace environment and validates plugin availability at the beginning of each Claude Code session |

## Example Workflows

### Initialize a New Workspace

1. Create a project directory for your work
2. Ask Claude: *"Initialize a cogni-works workspace here"*
3. The plugin scaffolds environment files, discovers installed plugins, and generates settings

### Extract a Brand Theme

1. Open a website or PowerPoint with your brand styling
2. Ask Claude: *"Extract a theme from this website"* or provide a `.pptx` file
3. The theme is saved to `themes/` and available for cogni-visual rendering

### Check Workspace Health

1. Ask Claude: *"What's the status of my workspace?"*
2. Review the diagnostic report — plugin versions, missing dependencies, environment issues
3. Run *"Update my workspace"* to fix any detected issues

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       4 workspace management skills
│   ├── init-workspace/
│   ├── manage-themes/
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
│   ├── _template/
│   └── cogni-work/
└── assets/                       Shared assets
    └── output-styles/
```

## License

[AGPL-3.0](LICENSE)
