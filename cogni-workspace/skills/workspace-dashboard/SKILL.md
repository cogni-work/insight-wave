---
name: workspace-dashboard
description: |
  Generate a self-contained HTML dashboard showing the full insight-wave workspace
  configuration — installed plugins (with maturity stages and env vars), themes
  gallery with color swatches, MCP server status, market coverage matrix,
  cross-plugin hooks, and a health snapshot. Use whenever the user mentions
  workspace dashboard, workspace overview, "show me what's installed",
  "show me the themes", "MCP overview", plugin registry, market coverage,
  ecosystem map, or wants a *visual* view of the cogni-workspace configuration —
  even if they don't say "dashboard". This is the visual sibling of
  `workspace-status` (which is a text-based health diagnostic): pick this skill
  when the user wants to *see* the configuration, not diagnose it.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
---

# Workspace Dashboard

Generate a self-contained HTML dashboard that visualizes the entire insight-wave workspace configuration — installed plugins, themes, MCP servers, markets, hooks, and health — into a single browsable page. The dashboard opens in the user's browser and supports drill-down into every section.

## Core Concept

cogni-workspace is the foundation that every other plugin reads from. Plugins arrive via the marketplace, themes shape every visual output, MCP servers power rendering and browser automation, market catalogs drive bilingual research, and hooks run quietly in the background on every session. This information is scattered across `.workspace-config.json`, `references/*.json`, and per-plugin `plugin.json` files — useful but invisible.

The dashboard turns that scattered state into a single visual overview. It is **complementary to `workspace-status`**:

- `workspace-status` answers *"is anything broken?"* — text-based, OK/WARNING/CRITICAL flags, designed for diagnosis.
- `workspace-dashboard` answers *"what is configured?"* — visual, rich, designed for exploration.

Both are read-only. Neither modifies workspace state.

## Workflow

### 1. Locate the Workspace

Find the workspace using this priority:

1. User-provided path (positional arg to the skill or script)
2. `$COGNI_WORKSPACE_ROOT`
3. `$PROJECT_AGENTS_OPS_ROOT`
4. Current working directory (only if it has `.workspace-config.json` or `.claude-plugin/marketplace.json`)

If no workspace can be located, tell the user and suggest `manage-workspace` to create one. The dashboard can also run in **monorepo dev mode** — when the resolved path looks like the `insight-wave` repo (has `.claude-plugin/marketplace.json` but no `.workspace-config.json`), the generator reads plugin metadata directly from sibling `cogni-*` directories. This makes the dashboard usable for plugin development before a workspace exists.

### 2. Pick Theme

Check whether `<workspace-root>/.dashboard-design-variables.json` already exists from a previous run. If it does, ask the user: "A dashboard theme is already configured. Reuse it, or pick a new one?" Default to reuse — most re-runs just want fresh data with the same look.

- **If reusing**: skip directly to step 4.
- **If picking new** (or no design-variables exist): use the `cogni-workspace:manage-themes` skill (Operation 11, Select Theme). It returns `theme_path`, `theme_name`, and `theme_slug`.

**Skip conditions** (auto-select without prompting): caller already provided a `theme_path`, only one theme exists in the workspace, or running in non-interactive mode.

### 3. Generate Design Variables

Read the selected `theme.md` and produce a design-variables JSON file at `<workspace-root>/.dashboard-design-variables.json`. The JSON must follow the schema at `$CLAUDE_PLUGIN_ROOT/skills/workspace-dashboard/schemas/design-variables.schema.json`. See `examples/design-variables-cogni-work.json` for the exact format.

**What the LLM adds** beyond a raw token extraction (same conventions as `portfolio-dashboard`):

- Derives `surface2` (~4% darker than `surface`) if not explicit in the theme
- Computes `accent_muted` and `accent_dark` variants if the theme only defines `accent`
- Builds a Google Fonts `@import` URL from the font families
- Adjusts shadow opacity for dark themes
- Ensures WCAG AA contrast between `text`/`background` and `text_light`/`surface_dark`
- Sets `radius` and `shadows` appropriate to the theme's visual style

### 4. Generate the Dashboard

Run the generator with the design-variables JSON:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py" \
  "<workspace-root>" \
  --design-variables "<workspace-root>/.dashboard-design-variables.json"
```

The script:

- Reads `.workspace-config.json` and the workspace foundation files
- Discovers plugins (via `discover-plugins.sh` when available, or by globbing `cogni-*/.claude-plugin/plugin.json` in monorepo dev mode)
- Reads `${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json` for MCP servers, cross-checked against `~/.claude/mcp-servers/<name>/`
- Reads `${CLAUDE_PLUGIN_ROOT}/references/supported-markets-registry.json` plus the three plugin catalogs to build the market coverage matrix
- Reads every plugin's `hooks/hooks.json` (when present) for the hooks summary
- Walks `themes/` directories for the gallery
- Loads the design-variables JSON for theming
- Writes `<workspace-root>/workspace-dashboard.html` (self-contained, inline CSS + JS)
- Returns JSON: `{"status": "ok", "path": "<output-path>", "theme": "<name>", "design_variables": "<path-or-null>"}`

**Legacy fallback**: the script still accepts `--theme <path-to-theme.md>` for CI/automated runs. Precedence: `--design-variables` > `--theme` > built-in defaults.

### 5. Open in Browser

```bash
open "<workspace-root>/workspace-dashboard.html"
```

Tell the user the dashboard is open. Re-running the script regenerates the HTML against current state.

## Dashboard Sections

The generated HTML includes seven sections, all in a single-page layout with a sticky pill-style navigation bar:

1. **Workspace Overview** — Header card. Workspace path, language, version, created/updated timestamps, foundation file checklist (`.workspace-config.json`, `.claude/settings.local.json`, `.workspace-env.sh`). Mode badge (workspace vs monorepo dev mode).
2. **Installed Plugins** — Card grid + sortable table. For each plugin: name, version, **maturity stage** (Incubating / Preview / Released / Established / Archived — derived from version per `cogni-docs/references/maturity-model.md`), description, env var names (`COGNI_*_ROOT`, `COGNI_*_PLUGIN`), install path. Click a card to expand into skills/agents/scripts counts.
3. **Themes Gallery** — Visual cards, one per theme. Each card shows the theme's own primary, secondary, accent, surface, and background colors as actual swatches (not the dashboard theme). Font preview, source badge (standard / workspace), tier badge (tier-0 / tiered), file path.
4. **MCP Servers** — Cards per server from `mcp-git-registry.json`. Status pill (installed / missing / manual), type pill (git / native), required-by chips (which plugins depend on it), platform-specific install path (when native). For git-based servers: repo URL and build command shown on hover.
5. **Market Coverage Matrix** — Heatmap-style grid. Rows = markets from `supported-markets-registry.json`. Columns = the plugins carrying their own market overlay (`cogni-trends`). cogni-portfolio is deliberately not a column — it reads the registry directly via `get-market-config.py`, so its market set matches the registry by construction. Cells are color-coded: green = market present in plugin's catalog, neutral = absent. Below the matrix: per-market authority-domain count and a small chip list of primary authorities.
6. **Cross-Plugin Hooks** — Table grouped by event (SessionStart, PostToolUse, etc.). Each row: plugin, matcher, command path, timeout. Useful for understanding what runs invisibly.
7. **Health Snapshot** — Compact one-line-per-check summary that mirrors the workspace-status categories (Foundation / Environment / Plugins / Themes / Dependencies / MCP) with green/yellow/red dots. Each line ends with a "run /workspace-status for details" pointer rather than re-implementing the diagnostic depth.

The footer shows the generation timestamp and a "generated by cogni-workspace" credit line.

## Important Notes

- The dashboard is **read-only** — it shows configuration state, it does not modify anything.
- The HTML file is fully self-contained (inline CSS + vanilla JS, no external dependencies beyond the optional Google Fonts import declared by the theme).
- Re-running the script overwrites the previous dashboard — diff with `git` if you want to see what changed in the workspace.
- The dashboard lives at `<workspace-root>/workspace-dashboard.html` (workspace root, not a subdirectory — the workspace is flat).
- **Communication Language**: read the `language` field in `.workspace-config.json`. If present, communicate with the user in that language (status messages, instructions, recommendations). Technical terms, skill names, and CLI commands remain in English. Default to English when the field is absent.

## Shared Pattern

This dashboard is the fourth instance of the design-variables pattern documented at `${CLAUDE_PLUGIN_ROOT}/references/design-variables-pattern.md`, alongside `portfolio-dashboard`, `trends-dashboard`, and `marketing-dashboard`. The 3-stage flow is identical: select a theme through manage-themes → LLM derives design-variables.json → Python generator consumes JSON.

For a per-section reference (data sources, helpers, expected output shape), see `references/dashboard-sections.md`.

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
