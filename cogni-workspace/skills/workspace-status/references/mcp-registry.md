# MCP Server Registry

Known MCP servers in the insight-wave ecosystem. Each entry documents which plugins
need the MCP, how it's installed, and which skills depend on it.

## Installed On Demand (written to user config by install-mcp)

No plugin ships an MCP declaration. Running the `install-mcp` skill installs the server
and writes it into the user's own config — `~/.claude.json` for Claude Code,
`claude_desktop_config.json` for Claude Desktop. A server therefore appears in the config
only once it is actually installed.

### excalidraw (yctimlin/mcp_excalidraw)

- **Needed by:** cogni-portfolio, cogni-workspace
- **Type:** git-installed (cloned and built by `${CLAUDE_PLUGIN_ROOT}/scripts/install-mcp.sh`)
- **Install path:** `~/.claude/mcp-servers/mcp_excalidraw/`
- **Entry point:** `~/.claude/mcp-servers/mcp_excalidraw/start.sh` (wrapper that starts canvas + MCP)
- **Source repo:** https://github.com/yctimlin/mcp_excalidraw.git
- **Canvas frontend:** React + Excalidraw on localhost:3000 (auto-started by wrapper)
- **Probe tool:** `mcp__excalidraw__describe_scene`
- **Skills:** enrich-report, portfolio-architecture, and the concept-diagram / infographic render agents
- **Features:** WebSocket canvas sync, snapshots, mermaid-to-excalidraw, image export
- **Troubleshooting:**
  - If tools not available: run `manage-workspace` init/update to install, or run the two
    steps by hand. Both are needed — `install-mcp.sh` only clones and builds; since no
    plugin declaration supplies the entry any more, nothing is configured until the writer
    runs. Anchor every path with `${CLAUDE_PLUGIN_ROOT}`: `install-mcp.sh` runs under
    `set -euo pipefail`, so a repo-relative wrapper path that misses aborts it with no JSON
    output at all.

    ```bash
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-mcp.sh" \
      --name mcp_excalidraw \
      --repo https://github.com/yctimlin/mcp_excalidraw.git \
      --wrapper "${CLAUDE_PLUGIN_ROOT}/templates/mcp-wrappers/excalidraw-canvas.sh"

    python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-desktop-config.py" \
      --registry "${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json" \
      --target cli --server mcp_excalidraw
    ```
  - If tools available but canvas not visible: check `http://localhost:3000`
  - To update: run `install-mcp.sh` with `--force` to pull latest and rebuild
  - **Pick the write target:** `--target cli` writes `~/.claude.json` (Claude Code),
    `--target desktop` writes `claude_desktop_config.json`, `--target both` does each in
    turn. Whichever is written, the server loads only after a restart — a new Claude Code
    session, or a Claude Desktop restart.
- **Retired sibling:** a url-type `excalidraw_sketch` server (`https://mcp.excalidraw.com`)
  was once offered as a no-install alternative. It was removed after its only documented
  consumer skill ceased to exist, leaving it with no caller; being url-type it never
  spawned a local process, so it was not part of the failing-server problem that moved
  declarations out of plugins.

## Manual Install

These MCPs require user action to install — install-mcp does not fetch the app or extension itself.

### claude-in-chrome

- **Used by:** cogni-website, cogni-workspace
- **Type:** Chrome extension (manual install)
- **Requires:** Claude-in-Chrome extension installed in Chrome and active
- **Probe tool:** `mcp__claude-in-chrome__tabs_context_mcp`
- **Skills:** claims (cobrowse verification), cogni-issues (GitHub automation), website-preview (browser review)
- **Troubleshooting:**
  - If not available: install the Claude-in-Chrome extension in Chrome
  - The extension controls the user's visible Chrome browser — not headless
  - The user must be logged into relevant services (GitHub, etc.) in Chrome

### pencil

- **Needed by:** cogni-website, cogni-workspace
- **Type:** Desktop app with bundled MCP server
- **Install:** Download from https://pencil.dev, open the app — MCP auto-starts
- **Config entry:** `install-mcp` does write pencil's config entry — it is a registry `native` server with `desktop_config_key: pencil`. Only the desktop-app install is manual.
- **Probe tool:** `mcp__pencil__get_editor_state`
- **Skills and agents:** the `web` and `storyboard` agents (web narrative and printed-poster rendering), `render-infographic-pencil` (editorial infographics), website-build (homepage hero rendering)
- **Note:** Skills that use Pencil tell the user "open Pencil" if the MCP is unavailable.
  This is handled at the skill level, not by cogni-workspace.
- **Troubleshooting:**
  - If not available: open the Pencil desktop app
  - Pencil registers its MCP automatically when running

## Diagnosing a not-loaded install-mcp server

This section is the canonical home of the key-to-directory rule and the install-state
matrix. `workspace-status` check 6, the `workspace-dashboard` install probe, `install-mcp`
and `patch-desktop-config.py` all point here rather than restating it.

### Which key names which artifact

An install is two independent artifacts, and they are keyed differently:

- **The config entry** is keyed by the registry entry's `desktop_config_key` — `excalidraw`
  for the registry server `mcp_excalidraw` — in the config of the host **this session runs
  in**: the top-level `mcpServers` in `~/.claude.json` under Claude Code, or the same key in
  `claude_desktop_config.json` under Claude Desktop. Only that host's config feeds the table
  below. An entry present solely in the *other* host's config leaves this one unconfigured,
  and counting it lands on the restart row for a write that never happened here.
- **The install directory** is `$HOME/.claude/mcp-servers/<registry server name>/start.sh` —
  named for the registry **server name** (`mcp_excalidraw`), not the config key, because
  `install-mcp.sh` is what creates it: it builds the directory as `$MCP_BASE_DIR/$NAME`
  from the `--name` it is handed, and `install-mcp` hands it the registry server name. The
  config key is never passed to the installer at all, so a probe that resolves the
  directory from `desktop_config_key` looks in a path nothing creates.
- `$CLAUDE_MCP_DIR`, when set to a non-empty value, replaces the
  `$HOME/.claude/mcp-servers` base.

### Install-state matrix

Read both pieces of state, then take the matching row:

| Config entry (this host) | `start.sh` | State | Advise |
|---|---|---|---|
| absent | absent | never installed | route to `/cogni-workspace:install-mcp` |
| absent | present | built but not configured | re-run the config write — `/cogni-workspace:install-mcp` |
| present | absent | configured but not built, or the install directory was deleted | re-run `/cogni-workspace:install-mcp` to clone and build — this is the state that surfaces a *failed* server under `/mcp`, because the config entry points at a `start.sh` that is not there |
| present | present | configured, but not loaded in this session | advise a session restart |

### Why a restart is rarely the whole answer

A restart *on its own* only fixes the configured-but-not-loaded row. `install-mcp.sh` clones
and builds, and nothing is configured until `patch-desktop-config.py` runs — so wherever a
step is missing, the write or the build comes first and the new session follows it, never
instead of it.

If a restart does not clear it, first re-check that the entry is in *this* host's config — a
server written only with `--target desktop` is absent from `~/.claude.json` and needs a
`--target cli` write, not a restart — and only then treat it as a failed spawn (a broken
build or a port conflict).
