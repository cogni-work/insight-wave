# Obsidian Integration Plugin

An Obsidian integration plugin for Claude Code that bridges Obsidian vaults with Claude Code workplaces. Scaffolds vault configurations with Terminal plugin integration, manages terminal profiles across platforms, and provides standardized note creation with YAML frontmatter — enabling cogni-x plugins to work on projects collaboratively through an Obsidian-based environment.

> **Note**: This plugin configures Obsidian as a workplace frontend for Claude Code. It downloads the [Obsidian Terminal](https://github.com/polyipseity/obsidian-terminal) community plugin from GitHub during setup. Review the Terminal plugin's license and permissions before use.

## Installation

```bash
claude plugins add cogni-obsidian
```

### Prerequisites

- [Obsidian](https://obsidian.md/) installed
- `jq` — JSON processing (`brew install jq` / `apt install jq`)
- `curl` — Terminal plugin download (`brew install curl` / `apt install curl`)

## Skills

| Skill | Description |
|-------|-------------|
| `setup-obsidian` | Scaffold a complete `.obsidian/` vault with Terminal plugin profiles, workspace layout, Tokyonight theme, and Claude Code launcher script |
| `update-obsidian` | Incrementally update terminal profiles, fix WSL issues, merge new configurations, and sync scripts — without overwriting user customizations |
| `note-manager` | Create markdown notes with consistent YAML frontmatter (title, date, tags, source) for standardized cogni-x plugin output |

## Example Workflows

### Set Up a New Workplace

1. Create a project directory and ask Claude: *"Set up Obsidian for my workplace at /path/to/my-project"*
2. Open the directory as an Obsidian vault (File > Open Vault)
3. Click the Terminal ribbon icon — the **Workplace** profile launches Claude Code with language selection and permission mode options
4. All cogni-x plugin environment variables are sourced automatically via `.workplace-env.sh`

### Update an Existing Workplace

1. Ask Claude: *"Update the Obsidian configuration for my workplace"*
2. New terminal profiles are merged, deprecated profiles are removed, and WSL path issues are auto-healed
3. Existing customizations (fonts, colors, scripts) are preserved

### Create Structured Notes

1. Ask Claude: *"Create a note for the Q1 market analysis findings"*
2. A markdown file is created with YAML frontmatter (title, date, tags, source plugin)
3. Obsidian handles indexing, linking, search, and graph visualization

## What Gets Created

The `setup-obsidian` skill scaffolds this structure in your workplace:

```
.obsidian/
├── app.json                 # Vault settings (live preview, line numbers, link updates)
├── appearance.json          # Theme (moonstone), base font size
├── core-plugins.json        # 15 enabled core plugins (explorer, search, graph, backlinks...)
├── community-plugins.json   # Terminal plugin enabled
├── workspace.json           # Multi-pane layout (editor, file explorer, search, bookmarks)
└── plugins/
    └── terminal/
        ├── main.js          # Terminal plugin (downloaded from GitHub)
        ├── manifest.json    # Plugin manifest
        ├── styles.css       # Plugin styles
        ├── data.json        # Terminal profiles with Tokyonight color scheme
        └── workplace-orchestrator.sh  # Claude Code launcher with language + permission selection
```

### Terminal Profiles

| Profile | Platform | Description |
|---------|----------|-------------|
| Workplace (Unix) | macOS, Linux | Launches Claude Code via `/bin/bash` with SF Mono font |
| Workplace (WSL) | Windows | Launches Claude Code via `wsl.exe` with Cascadia Code font |

## Platform Support

| Platform | Terminal Profile | Path Format |
|----------|-----------------|-------------|
| macOS (Darwin) | `workplace` | Native (`/Users/...`) |
| Linux | `workplace` | Native (`/home/...`) |
| Windows (WSL) | `workplace-wsl` | WSL (`/mnt/c/...`) |
| Windows (Git Bash) | `workplace-wsl` | Converted (`/mnt/c/...`) |

Path placeholders (`{{WORKPLACE_ROOT}}` and `{{WORKPLACE_ROOT_WSL}}`) are substituted at setup time to support all platforms from a single template.

## Architecture

This plugin follows the cogni-x **convention-based zero-coupling** architecture:

- Each cogni-x plugin owns its output scaffolding from a workspace root provided via environment variables (e.g., `COGNI_RESEARCH_ROOT`, `COGNI_NARRATIVE_ROOT`)
- cogni-obsidian provides the vault and terminal integration layer — it does not manage plugin-specific folder structures
- The `.workplace-env.sh` file is sourced automatically by the Terminal plugin, making all plugin roots available to Claude Code sessions
- All scripts use `bash 3.2` compatibility and cross-platform portability utilities

## License

[AGPL-3.0](LICENSE)
