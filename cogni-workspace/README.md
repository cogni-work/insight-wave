# cogni-workspace

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The foundation-layer plugin for the [insight-wave](https://claude.ai/cowork) ecosystem — the only plugin that other cogni-x plugins depend on, and the one that must be initialized first. cogni-workspace owns environment configuration, MCP server installation, theme storage, plugin discovery, workspace health diagnostics, Obsidian vault integration, and a bundled vendor-curated insight-wave reference wiki queryable via the `ask` skill — so every cogni-x plugin starts running, not configuring.

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

cogni-workspace implements the **infrastructure-as-plugin pattern**: a dedicated plugin whose sole job is to own the shared state that all other plugins consume — environment variables, plugin registry, theme storage, and tool configuration. It is the only plugin in the ecosystem with no upward dependencies; every other cogni-x plugin depends on it, and none of them duplicate what it provides.

In the Claude Cowork plugin model, workspace-level state (paths, env vars, installed MCPs) cannot be assumed — it must be actively initialized and maintained. cogni-workspace does this in one command and keeps it consistent across plugin updates. Health diagnostics run a five-tier check (foundation, env vars, plugin registry, themes, dependencies) so drift is caught before downstream skills break, not after.

## What it does

1. **Manage workspace** — initialize or update a workspace with auto-detection, dependency checks, plugin discovery, preference gathering, settings generation, backup and rollback → `references/supported-markets-registry.json` → doc-generate, doc-power, doc-hub, doc-readme-root, doc-audit
2. **Manage themes** — extract from websites (via Chrome), PPTX files, or presets; audit for contrast and harmony; author tiered theme systems (tokens → assets → components → templates) per Theme System v2 (see [migration guide](docs/theme-system-v2-migration.md)); apply to downstream skills
3. **Pick themes** — centralized theme picker used by all visual plugins
4. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
5. **Diagnose** workspace health — five-tier report (foundation, env vars, plugin registry, themes, dependencies)
6. **Install MCP servers** — clone and build git-based MCP servers, detect native app MCPs, and patch Claude Desktop config so rendering plugins find their tools without manual JSON editing
7. **Obsidian integration** — scaffold `.obsidian/` vault or incrementally update terminal profiles, handled as sub-steps of manage-workspace
8. **Ask the bundled wiki** — `ask` wraps `cogni-wiki:wiki-query` against a vendor-curated insight-wave reference wiki bundled at `wiki/` so users can ask grounded questions about plugins, skills, agents, architecture, and conventions without grepping source files

## What it means for you

- **One command to set up or update.** `manage-workspace` auto-detects mode, discovers installed plugins, generates env vars, settings, themes, and output styles — replacing 20+ minutes of manual scaffolding per project.
- **Zero hand-edited MCP config.** `install-mcp` clones and builds git-based MCP servers (Excalidraw, Pencil), detects native app MCPs (browsermcp, claude-in-chrome), and patches Claude Desktop config with automatic backup — rendering plugins like cogni-visual and cogni-portfolio find their tools without a single JSON edit.
- **Consistent theming across all visual output.** Slides, journey maps, web narratives, and dashboards across 5+ visual plugins inherit colors and fonts from one theme file — reskinning the entire ecosystem is a single-file edit, not 5+ separate ones.
- **Catch workspace drift before skills break.** Five-tier health diagnostics (foundation, env vars, plugin registry, themes, dependencies) surface mismatches and missing deps before they cause cryptic runtime failures.
- **Safe updates with rollback in seconds.** `manage-workspace` backs up before modifying — if an update breaks something, restore the previous state in one command, no manual file recovery.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/manage-workspace  # initialize or update a workspace
/workspace-status  # check health
/pick-theme        # select a theme interactively
/manage-themes     # extract, create, audit, or apply themes
```

> **Note:** Issue filing (`/issues`) has moved to [cogni-help](../cogni-help).

Or describe what you want:

- "Initialize a insight-wave workspace here"
- "What's the status of my workspace?"
- "Extract a theme from this website"
- "Update my workspace after installing new plugins"
- "Ask the wiki: how does claims propagation work?"
- "Ask the wiki: which plugin generates IS/DOES/MEANS messaging?"

## Try it

After installing, type one prompt:

> Initialize a insight-wave workspace

Claude checks dependencies, discovers installed plugins, asks for your language preference and tool integrations, then generates `.claude/settings.local.json`, `.workspace-env.sh`, `.workspace-config.json`, output style templates, and the default theme. Your workspace is ready for all cogni-x plugins.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `manage-workspace` | skill | Initialize or update workspace — auto-detects mode, dependencies, discovery, preferences, settings, themes, backup and rollback |
| `manage-themes` | skill | 9 theme operations: recommend, list, grab from website, grab from PPTX, create from preset, audit, author deep theme system, generate showcase, apply |
| `pick-theme` | skill | Centralized theme picker — discovers themes, presents interactive selection, returns path |
| `workspace-status` | skill | Five-tier diagnostic: foundation, env vars, plugin registry, themes, dependencies |
| `install-mcp` | skill | End-to-end MCP server installation — clone and build git-based MCPs, configure native app MCPs, and patch Claude Desktop config |
| `ask` | skill | Answer questions about the insight-wave ecosystem by reading the bundled wiki — grounded, cited, never from memory |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `check-skill-names.sh` | script | Validates skill directory names against plugin.json manifest for consistency |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; supports `--update` to preserve custom env vars |
| `install-mcp.sh` | script | Installs a git-based MCP server into `~/.claude/mcp-servers/` (clone, build, wrapper); outputs JSON with install and wrapper paths |
| `patch-desktop-config.py` | script | Merges git-installed MCP servers into Claude Desktop's config from `mcp-git-registry.json`, preserving existing entries |
| `setup-obsidian.sh` | script | Copies vault templates, downloads Terminal plugin, substitutes path placeholders |
| `update-obsidian.sh` | script | Merges profiles, fixes WSL paths, removes deprecated profiles, copies scripts |
| `portability-utils.sh` | script | Cross-platform utilities (macOS, Linux, WSL, Git Bash) |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       6 workspace management skills
│   ├── ask/                      Query the bundled insight-wave wiki for grounded answers
│   ├── install-mcp/              MCP server installation and Desktop config patching
│   ├── manage-workspace/         Init or update workspace (includes Obsidian integration)
│   ├── manage-themes/
│   ├── pick-theme/
│   └── workspace-status/
├── wiki/                         Bundled vendor-curated insight-wave reference wiki (read by ask)
│   ├── .cogni-wiki/              Wiki config + lockfile
│   ├── raw/                      Immutable source snapshots (plugin READMEs, curation notes)
│   ├── assets/                   Attachments (SVG, images) referenced by wiki pages
│   └── wiki/                     LLM-maintained pages, index, log, overview
├── templates/                    Shared templates
│   ├── obsidian/                 Obsidian vault config templates
│   └── mcp-wrappers/             Wrapper scripts for git-based MCP servers
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   └── on-session-start.sh
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── check-region-catalogs.sh  Cross-plugin drift checker for portfolio, trends, research region catalogs
│   ├── check-skill-names.sh
│   ├── discover-plugins.sh
│   ├── generate-settings.sh
│   ├── install-mcp.sh            Clone, build, and wrap git-based MCP servers
│   ├── patch-desktop-config.py   Merge MCP entries into Claude Desktop config
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

cogni-workspace has no required plugin dependencies — it is the foundation layer that other plugins depend on.

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-visual | No | manage-themes passes color variables to cogni-visual renderers (render-big-picture, render-big-block) |
| cogni-website | No | Referenced in manage-workspace and workspace-status for website-related workspace configuration |
| cogni-help | No | Referenced inline in workspace skills for issue filing and guided help |
| cogni-portfolio | No | install-mcp references cogni-portfolio as a consumer of excalidraw MCP in the installation plan |
| cogni-claims | No | workspace-status references cogni-claims as a provider plugin for the claude-in-chrome MCP server check |
| cogni-wiki | No | `ask` wraps `cogni-wiki:wiki-query` to read the bundled insight-wave reference wiki |

## Contributing

Contributions welcome — theme templates, platform support, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/manage-themes` (website extraction) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/manage-themes` skill's live website extraction mode falls back to manual theme specification until the conflict is resolved.

## Custom development

Need enterprise workspace configurations, custom theme infrastructure, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
