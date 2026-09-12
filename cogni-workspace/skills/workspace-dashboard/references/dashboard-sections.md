# Dashboard Sections Reference

Per-section reference for `workspace-dashboard`: data source, helper(s) reused, and expected output shape. The generator script (`scripts/generate-dashboard.py`) implements all seven sections; this file documents the contracts so the SKILL.md stays lean and so future maintenance has a single place to look.

## 1. Workspace Overview

**Data source**:
- `<workspace-root>/.workspace-config.json` (if present): `version`, `language`, `installed_plugins[]`, `created_at`, `updated_at`, `tool_integrations[]`
- Foundation file existence (boolean per file): `.workspace-config.json`, `.claude/settings.local.json`, `.workspace-env.sh`
- Mode detection: workspace mode (has `.workspace-config.json`) vs monorepo dev mode (has `.claude-plugin/marketplace.json` but no workspace config)

**Output**: header card with metadata key/value list and a small foundation-file checklist row.

## 2. Installed Plugins

**Data source** (in priority order):
1. Output of `${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh` — JSON envelope with `data.plugins[]` (name, version, description, path, root_var, plugin_var)
2. Fallback (monorepo dev mode): glob `<workspace-root>/cogni-*/.claude-plugin/plugin.json` directly and synthesize the same shape
3. Per-plugin enrichment: read each plugin's `plugin.json` for `keywords[]` and `archived` flag

**Maturity derivation** (mirrors root `CLAUDE.md` table and `cogni-docs/references/maturity-model.md`):

| Version pattern | Stage |
|---|---|
| `archived: true` (any version) | Archived |
| `0.0.x` | Incubating |
| `0.x.x` (x ≥ 1) | Preview |
| `1.x.x` | Released |
| `2.x.x` or higher | Established |

**Output**: card grid with name, version pill, maturity badge (color-coded by stage), and a description preview. Each card expands to show env var names (mono font) and the install path.

## 3. Themes Gallery

**Data source**:
- Bundled themes: `<workspace-root>/cogni-workspace/themes/*/theme.md` (monorepo dev mode) **or** `$CLAUDE_PLUGIN_ROOT/themes/*/theme.md` (workspace mode)
- Workspace themes: `<workspace-root>/themes/*/theme.md` (when running outside the monorepo)
- Skip `_template/` directory always
- Per theme: parse `# H1` for name, `**Primary**: \`#HEX\``, `**Accent**: \`#HEX\``, etc. for swatches, `**Headers**: ...` for font, presence of `manifest.json` for tier-0 vs tiered

**Output**: card per theme. Each card shows the theme's actual colors as 5 swatches (primary, secondary, accent, surface, background — read from that theme's own theme.md, *not* from the dashboard's design-variables). Source badge (standard / workspace), tier badge (tier-0 / tiered).

## 4. MCP Servers

**Data source**:
- `<workspace-root>/cogni-workspace/references/mcp-git-registry.json` — declares each server (`type`, `repo`, `desktop_config_key`, `provides_tools[]`, `required_by[]`, platform-specific paths for native servers)
- Install status check: for git-based servers, existence of `~/.claude/mcp-servers/<name>/start.sh` (base overridable via `$CLAUDE_MCP_DIR`); for native servers, existence of the platform-specific binary path. What `<name>` is, and why it rather than `desktop_config_key`, is stated once in `skills/workspace-status/references/mcp-registry.md`
- Required shape: a top-level `servers` object whose values are themselves objects. A registry that parses but does not match it — root not an object, `servers` absent or not an object, or any entry not an object — is **unreadable**. This section then falls back to the same placeholder a missing registry gets, because either way there are no cards to draw; the Health Snapshot row is where the two are told apart.

**Output**: card per server. Status pill (Installed / Missing / Manual). Type pill (git / native). Required-by chips (one per consuming plugin). For git-based: repo URL truncated. For native: platform path.

## 5. Market Coverage Matrix

**Data source**:
- Canonical: `<workspace-root>/cogni-workspace/references/supported-markets-registry.json` (rows = `markets` keys)
- Plugin overlays (columns):
  - `cogni-research/references/market-sources.json`
  - `cogni-trends/skills/trend-research/references/region-authority-sources.json`

cogni-portfolio is intentionally not a column: under the centralized markets model it reads the registry directly via `${CLAUDE_PLUGIN_ROOT}/scripts/get-market-config.py`, so its market set is structurally identical to the registry by construction.

**Output**: heatmap grid. Rows = markets (sorted by `tier` then alphabetically). Columns = the two consuming plugins. Cell = green when the market is present in that plugin's overlay, neutral when absent. Below the matrix: per-market summary chips (authority-domain counts, primary authorities).

This section is **read-only**. `manage-market-registry` owns both directions over the registry: its `status` sub-action is the dedicated coverage reporter (overlay-vs-registry coverage and orphan-domain detection, computed by `scripts/check-market-orphans.py`), and its `add` sub-action is the write path. Drift on the shared market set is structurally impossible under the centralized model — the matrix shows the static current state.

## 6. Cross-Plugin Hooks

**Data source**:
- Glob `<workspace-root>/cogni-*/hooks/hooks.json` and parse each
- Standard Claude Code hook shape: `{ "hooks": { "<EventName>": [ { "matcher": "...", "hooks": [ { "type": "command", "command": "...", "timeout": N } ] } ] } }`

**Output**: table grouped by event (SessionStart, PostToolUse, PreToolUse, Stop, etc.). Each row: plugin name, matcher, command (truncated, full path on hover), timeout (s).

## 7. Health Snapshot

**Data source**:
- Foundation files: existence check (same set as Section 1)
- Environment vars: read `.claude/settings.local.json` `env` object, count how many resolve to existing paths
- Plugins: count from Section 2
- Themes: count from Section 3
- Dependencies: invoke `<workspace-root>/cogni-workspace/scripts/check-dependencies.sh` and partition `data.dependencies[]` (one entry per tool: `{name, available, required, version}`) on each entry's own `required` flag; `data.missing_required` / `data.missing_optional` carry the same misses as integers
- MCPs: read the `servers` object from `<workspace-root>/cogni-workspace/references/mcp-git-registry.json` and partition its entries on each entry's own resolved install status. The row renders exactly one of four summaries: `registry not found` (file absent, unparseable, or a literal JSON null), `registry unreadable` (parses, but not the required shape above), `no servers configured` (`servers` present and empty), or `<installed>/<total> installed[, <n> manual]`. All three zero-server states are non-`ok`, so the row can never report a green `0/0` — a count comparison both sides satisfy at zero is not evidence of health.

**Output**: one row per check. Each row: green/yellow/red dot, check name, one-line summary (e.g., "12 vars set, 0 missing"), and a "Run `/cogni-workspace:workspace-status` for details" pointer at the section foot.

The dashboard intentionally does **not** re-implement the diagnostic depth of `workspace-status`. The snapshot is a *teaser* — it tells the user whether anything is off, then defers to the dedicated status skill for the why and the fix.

## Failure Modes

- **No workspace found**: write a minimal HTML with just the overview section saying "no workspace at this path", suggest `manage-workspace`.
- **`discover-plugins.sh` fails**: fall back to glob mode and add a yellow note in Section 7's Plugins line.
- **Theme parsing fails**: render the card with a "unparseable theme" badge and skip swatches.
- **MCP registry missing**: skip Section 4 entirely with a placeholder note.
- **MCP registry shape drift**: a registry that parses but does not match the required shape renders Section 4's placeholder and a non-`ok` Health Snapshot row naming which state it is. The run still exits 0 and still writes the HTML, per the rule below — a malformed registry must degrade, never abort before the page exists.
- **Missing market catalogs**: render the matrix with empty columns for the missing plugins.

In every failure mode the script must still produce *some* HTML — never error out without writing the file. The user's first question after a failure should be answerable by opening the dashboard.
