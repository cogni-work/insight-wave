# MCP Server Registry

Known MCP servers in the insight-wave ecosystem. Each entry documents which plugin
provides the MCP, how it's installed, and which skills depend on it.

## Auto-Installed (via plugin .mcp.json)

These MCPs are declared in plugin `.mcp.json` files. When a user installs the plugin
from the marketplace, Desktop/Cowork auto-discovers and starts the MCP server on the
host machine. No manual configuration needed.

### excalidraw

- **Provided by:** cogni-visual, cogni-portfolio
- **Type:** npx (auto-downloads at runtime)
- **npx package:** `excalidraw-mcp`
- **Requires:** Canvas frontend on localhost:3000 (auto-started by cogni-visual's PreToolUse hook)
- **Probe tool:** `mcp__excalidraw__describe_scene`
- **Skills:** render-big-picture, render-big-block, enrich-report, portfolio-architecture
- **Troubleshooting:**
  - If tools not available: check that cogni-visual or cogni-portfolio is installed
  - If tools available but operations fail: verify canvas frontend is running (`http://localhost:3000`)
  - Canvas auto-start hook: `cogni-visual/hooks/ensure-excalidraw-canvas.sh`

### excalidraw_sketch

- **Provided by:** cogni-visual
- **Type:** URL (remote MCP server, no local install)
- **URL:** `https://mcp.excalidraw.com`
- **Probe tool:** `mcp__excalidraw_sketch__read_me`
- **Skills:** render-big-picture (optional Phase 0 sketch)
- **Troubleshooting:**
  - If not available: check internet connectivity
  - This is optional — render-big-picture works without it

### browsermcp

- **Provided by:** cogni-claims, cogni-help, cogni-workspace
- **Type:** npx (auto-downloads at runtime)
- **npx package:** `@anthropic-ai/browsermcp@latest`
- **Probe tool:** `mcp__browsermcp__browser_navigate`
- **Skills:** claims (verification fallback), cogni-issues (GitHub automation), manage-themes (website extraction)
- **Troubleshooting:**
  - If not available: check that at least one provider plugin is installed
  - Runs headless (Playwright) — no visible browser window
  - Works in Cowork VMs (no display needed)

## Manual Install

These MCPs cannot be auto-installed via `.mcp.json` and require user action.

### pencil

- **Type:** Desktop app with bundled MCP server
- **Install:** Download from https://pencil.dev, open the app — MCP auto-starts
- **Probe tool:** `mcp__pencil__get_editor_state`
- **Skills:** story-to-web (web narrative rendering), story-to-storyboard (poster rendering)
- **Note:** Skills that use Pencil tell the user "open Pencil" if the MCP is unavailable.
  This is handled at the skill level, not by cogni-workspace.
- **Troubleshooting:**
  - If not available: open the Pencil desktop app
  - Pencil registers its MCP automatically when running
