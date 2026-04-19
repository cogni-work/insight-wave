# cogni-workspace

**Plugin guide** — for canonical positioning see the [cogni-workspace README](../../cogni-workspace/README.md).

---

## Overview

cogni-workspace is the foundation layer for the insight-wave ecosystem. Before any other cogni-x plugin can run reliably, it needs: a place to find the workspace root, environment variables pointing to shared resources, a theme directory, and knowledge of which other plugins are installed. cogni-workspace provides all of this through a single initialization command and a set of management skills.

In practice, most users interact with cogni-workspace twice: once when setting up a new workspace (`manage-workspace`), and occasionally when something drifts out of sync (`workspace-status`, `manage-workspace`). Theme management and Obsidian integration are optional — use them if you want visual consistency across plugin outputs or a terminal-integrated note-taking environment.

The plugin imposes no data model on the workspace. It writes four files during initialization — `.workspace-config.json`, `.workspace-env.sh`, `.claude/settings.local.json`, and output style templates — and then stays out of the way.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Workspace** | A project directory initialized with cogni-workspace — has `.workspace-config.json` and the shared env file |
| **Plugin discovery** | The process of scanning the marketplace cache for installed cogni-x plugins and registering them in the workspace config |
| **Theme** | A markdown file containing color palettes, typography, and design principles, stored in `cogni-workspace/themes/` |
| **Theme picker** | The `pick-theme` skill — the single entry point for theme selection used by all visual plugins |
| **Output style** | A language-specific behavioral anchor file (EN/DE) that shapes how plugin outputs are formatted |
| **Session hook** | `on-session-start.sh` — sources the workspace environment and validates plugin availability each time a session opens |
| **Five-tier diagnostic** | The structure of `workspace-status` output: foundation → env vars → plugin registry → themes → dependencies |
| **Obsidian vault** | A `.obsidian/` configuration directory scaffolded by `manage-workspace` during initialization |

### Prerequisites

Before running `manage-workspace`, ensure these tools are installed:

| Dependency | Required | Purpose |
|-----------|----------|---------|
| `jq` | Yes | JSON processing in scripts |
| `python3` | Yes | Standard library only — no pip required |
| `bash 3.2+` | Yes | Script runtime |
| `curl` | Optional | Source fetching in some skills |
| `git` | Optional | Version tracking |
| `bc` | Optional | Arithmetic in diagnostic scripts |

---

## Getting Started

Initialize a new workspace:

```
Initialize a insight-wave workspace here
```

or:

```
/manage-workspace
```

What the initialization does:

1. Runs `check-dependencies.sh` and reports any missing required tools
2. Asks for your language preference (English or German) and which tool integrations to enable
3. Discovers installed cogni-x plugins via `discover-plugins.sh`
4. Generates `.workspace-config.json` with plugin registry and metadata
5. Generates `.workspace-env.sh` with environment variables for each plugin
6. Generates `.claude/settings.local.json` with workspace-appropriate settings
7. Writes output style templates for EN and DE
8. Creates the `cogni-workspace/themes/` directory and installs the bundled `cogni-work` theme

After initialization, your workspace root contains:

```
.workspace-config.json     workspace metadata, plugin registry, language
.workspace-env.sh          environment variables sourced at session start
.claude/settings.local.json  Claude Code settings
cogni-workspace/themes/    shared theme storage
```

---

## Capabilities

### `manage-workspace` — Initialize or update a workspace

A single command that auto-detects whether to initialize or update. If no `.workspace-config.json` exists, it runs the full initialization flow (dependency checks, plugin discovery, preference gathering, settings generation). If one exists, it runs the update flow (backup, re-scan plugins, refresh env vars, update output styles) while preserving user customizations.

```
/manage-workspace
```

---

### `workspace-status` — Five-tier health diagnostic

Checks the workspace in five layers and reports findings with actionable fixes:

1. **Foundation** — are the required files present and well-formed?
2. **Environment variables** — does `.workspace-env.sh` define the variables plugins expect?
3. **Plugin registry** — are registered plugins still installed at their expected paths?
4. **Themes** — is at least one theme available for visual plugins?
5. **Dependencies** — are `jq`, `python3`, and bash at the required versions?

Run when something is not working and you are not sure whether it is a plugin issue or a workspace issue:

```
/workspace-status
```

```
What's the status of my workspace?
```

If the diagnostic finds issues, each finding comes with a specific fix. Infrastructure-level problems (env vars, settings) are workspace concerns; plugin-level problems (broken skills, missing references) are handled by cogni-help's `troubleshoot` skill.

---

### `manage-themes` — Theme extraction and management

Themes are markdown files that describe a visual identity — colors, typography, and design principles. All visual plugins (cogni-visual, document-skills) read from the same theme directory, so setting a theme here propagates to every plugin output.

Eight operations are available:

| Operation | What it does |
|-----------|-------------|
| `recommend` | Suggests themes based on your industry or audience description |
| `list` | Shows all available themes in the workspace |
| `grab from website` | Extracts colors and typography from a live URL using Chrome |
| `grab from PPTX` | Extracts a theme from an existing PowerPoint template |
| `create from preset` | Builds a theme from a named preset (e.g., corporate, minimal, vibrant) |
| `audit` | Checks a theme for contrast ratios, color harmony, and completeness |
| `generate showcase` | Renders a visual sample of how a theme looks applied to real content |
| `apply` | Registers a theme as the workspace default |

```
/manage-themes
```

```
Extract a theme from our company website and apply it to the workspace
```

The `grab from website` operation uses Chrome browser automation to read the live site — it captures computed styles, not just source HTML.

---

### `pick-theme` — Centralized theme picker

A thin coordination skill used internally by all visual plugins before generating output. When a skill needs a theme, it calls `pick-theme` rather than implementing its own discovery logic.

You can also call it directly when you want to choose a theme before starting a visual workflow:

```
/pick-theme
```

The skill scans both the plugin's bundled theme directory and your workspace themes directory, presents the available options, and returns the path to your selection.

---

### Obsidian Integration (via `manage-workspace`)

Obsidian vault setup and updates are handled as sub-steps of `manage-workspace`:

- **During initialization**: if you indicate Obsidian use, the skill scaffolds `.obsidian/` with a Terminal plugin, Tokyonight-themed terminal, and Claude Code launcher
- **During update**: if `.obsidian/` exists, the skill offers to refresh terminal profiles and launcher scripts without overwriting customizations, fixing common WSL issues

Prerequisites: Obsidian must be installed. The skill handles Terminal plugin installation automatically.

---

### `install-mcp` — MCP server installation

End-to-end MCP server installation for the ecosystem. Clones and builds git-based MCPs (Excalidraw, Pencil), detects native-app MCPs (browsermcp, claude-in-chrome), and patches Claude Desktop's `claude_desktop_config.json` so rendering plugins find their tools without hand-edited JSON.

```
/install-mcp
```

Backs up the desktop config before any write; rolls back in one command if an install breaks something. Usually invoked automatically by `manage-workspace` Step 5, but available standalone when you add a new plugin that declares an MCP dependency.

---

### `ask` — Query the bundled insight-wave wiki

Answers questions about the insight-wave ecosystem — plugins, skills, agents, architecture, cross-cutting conventions — by reading the vendor-curated wiki bundled at `${CLAUDE_PLUGIN_ROOT}/wiki/`, not from model memory. Wraps `cogni-wiki:wiki-query` so answers are grounded and cited with `[[wikilinks]]`; if the wiki has no page on the topic, the skill says so rather than guessing.

```
/ask how does claims propagation work across plugins?
/ask which plugin generates IS/DOES/MEANS messaging?
/ask what's the difference between cogni-narrative and cogni-copywriting?
```

First lookup before grepping source files — faster and doesn't pull plugin internals into your context.

---

## Integration Points

### Upstream — cogni-workspace depends on nothing

cogni-workspace is the foundation layer. It has no plugin dependencies. Every other plugin depends on it, not the other way around.

### Downstream — every visual and content plugin uses the workspace

| Plugin / skill | What it reads from the workspace |
|---------------|----------------------------------|
| All cogni-x plugins | `.workspace-env.sh` — sourced at session start via the hook |
| cogni-visual | Themes via `pick-theme` |
| document-skills | Themes via `pick-theme`; output style templates |
| cogni-consulting | `discover-plugins.sh` results — to know which plugins are available for dispatch |
| cogni-help | `workspace-status` results — used by the troubleshoot skill for infrastructure checks |

---

## Common Workflows

### Workflow 1: Set up a brand-new workspace

1. Install insight-wave plugins from the marketplace
2. Run `/manage-workspace` in your project directory — answer the language and integration questions
3. Run `/workspace-status` to confirm all five tiers are green
4. Run `/manage-themes` to extract your brand theme from your website or a PPTX template
5. Obsidian integration is offered during `/manage-workspace` if you indicate Obsidian use

Total time: 10–15 minutes. After this, all installed plugins can resolve themes, env vars, and plugin paths without additional configuration.

For an end-to-end onboarding example that wires workspace into a full project, see [../workflows/portfolio-to-website.md](../workflows/portfolio-to-website.md) or [../workflows/consulting-engagement.md](../workflows/consulting-engagement.md).

### Workflow 2: Diagnose why a plugin cannot find its theme

1. Run `/workspace-status` — check the themes tier specifically
2. If themes tier fails: run `/manage-themes list` to see what themes are registered
3. If the theme directory is empty: run `/manage-themes` and create or install a theme
4. If the theme directory exists but the plugin still cannot find it: check that the plugin is reading `$COGNI_WORKSPACE_ROOT/themes/` (the env var should be set by `.workspace-env.sh`)
5. If the env var is missing: run `/manage-workspace` to refresh environment variables

### Workflow 3: Update the workspace after moving the project directory

When you move a workspace to a different path, absolute paths stored in `.workspace-env.sh` and `.claude/settings.local.json` become stale:

1. Run `/manage-workspace` from the new path — it re-scans for installed plugins and regenerates env vars
2. Run `/workspace-status` to confirm the workspace resolves correctly at the new path
3. If you use Obsidian, `/manage-workspace` will offer to fix terminal launcher paths during the update (especially important on WSL)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| A plugin cannot find `.workspace-env.sh` | The session hook did not run, or the workspace was not initialized | Run `/workspace-status`; if the foundation tier fails, re-run `/manage-workspace` |
| `jq: command not found` in script output | `jq` is not installed | Install via your package manager: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu) |
| Themes directory exists but visual plugin uses wrong colors | Plugin is reading a stale theme path | Run `/pick-theme` to re-select the theme; the selection updates the workspace default |
| `workspace-status` passes but a plugin skill still fails | The failure is at plugin level, not workspace level | Run cogni-help's `/troubleshoot` for plugin-level diagnostics |
| Obsidian terminal profile shows a doubled path (WSL) | WSL path duplication in the profile arguments | Run `/manage-workspace` — the update flow fixes doubled paths and stale args |
| `/manage-workspace` succeeds but a newly installed plugin is not discovered | The plugin was installed after initialization | Run `/manage-workspace` to re-scan and register the new plugin |
| German umlaut characters break workspace initialization | Shell locale not set for UTF-8 | Set `LANG=de_DE.UTF-8` before running init; the script includes umlaut support from v0.2+ |

---

## Known Issues

**Chrome native messaging host conflict (KI-001):** When both Claude Desktop (Cowork) and Claude Code are installed, the `manage-themes` skill's live website theme extraction feature — which uses Chrome browser automation to capture computed styles from a URL — may not work. The Chrome extension connects to one native host and ignores the other, causing browser automation tools to silently vanish.

**Workaround:** Toggle native messaging host configs by renaming the `.json` file for the unused product in `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/` and restarting Chrome. Alternatively, extract themes from a PPTX template or create one from a preset — these paths do not require browser automation. See the [Known Issues Registry](../../cogni-docs/references/known-issues.md) for detailed steps.

---

## Extending This Plugin

cogni-workspace is a contribution-friendly surface for infrastructure improvements:

- **New theme templates** — the `themes/_template/` directory defines the canonical theme format; new presets or industry templates are additive and safe
- **Platform support** — `bash/portability-utils.sh` handles macOS, Linux, WSL, and Git Bash; if you have a platform that behaves differently, extending portability-utils is the right place
- **New diagnostic checks** — the five-tier structure in `workspace-status` can be extended with additional checks; a check should return a clear finding and a specific fix action
- **New output style languages** — the `assets/output-styles/` directory currently has EN and DE; other languages follow the same format

See [CONTRIBUTING.md](../../cogni-workspace/CONTRIBUTING.md) for guidelines.
