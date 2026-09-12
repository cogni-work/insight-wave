---
id: plugin-cogni-workspace
title: "cogni-workspace (plugin)"
type: entity
tags: [cogni-workspace, plugin, foundation, themes, mcp, env-vars, workspace]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-workspace.md
status: stable
related: [concept-theme-inheritance, concept-mcp-server-map]
---

> **Preview** (v0.6.3) — core skills defined but may change.

The horizontal layer of the insight-wave marketplace — it owns the shared workspace state the vertical business plugins consume. Manages shared infrastructure (env vars, settings), MCP server installation and Desktop config patching, theme management, theme picker, plugin discovery, workspace health, and Obsidian vault integration.

## Layer

[[concept-four-layer-architecture|Horizontal layer]]. Every plugin that produces visual HTML output reads themes from cogni-workspace; every plugin needing an MCP server is installed via cogni-workspace.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-workspace:manage-workspace` | Initialize or update an insight-wave workspace; the entry point everyone runs first |
| `cogni-workspace:install-mcp` | End-to-end MCP server installation (clone, build, configure, patch Claude Desktop) |
| `cogni-workspace:manage-themes` | Create, audit, improve, select, and apply themes — sourced from Claude Design bundles or presets. Operation 11 (Select Theme) is the picker every visual plugin calls — see [[concept-theme-inheritance]] |
| `cogni-workspace:workspace-status` | Diagnose workspace health |

(Also bundled: the insight-wave wiki itself — read it directly, starting from this tree's own `index.md`.)

## What it owns

- **Themes** — imported from a Claude Design bundle or selected from a preset; consumed by all visual plugins through the design-variables CSS pattern
- **MCP servers** — excalidraw, claude-in-chrome, pencil; managed via the [[concept-mcp-server-map]]
- **Env vars and settings** — shared configuration across all insight-wave plugins
- **Obsidian vault integration** — projects can be browsed in Obsidian natively because all entity outputs are markdown with YAML frontmatter (see [[concept-data-model-patterns]])
- **insight-wave wiki** — bundled at `cogni-workspace/wiki/`, lands in the plugin cache on install, read directly from its own `index.md` (this is the wiki you're reading)

## Integration

The horizontal layer the vertical business plugins consume. cogni-workspace is the first install — `manage-workspace` initializes the directory structure that every other plugin's project directories live inside. `manage-themes` Operation 11 (Select Theme) is called by every visual surface (its own render agents, cogni-website, cogni-portfolio dashboards, cogni-trends dashboards).

**Source**: [cogni-workspace README](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-workspace.md)
