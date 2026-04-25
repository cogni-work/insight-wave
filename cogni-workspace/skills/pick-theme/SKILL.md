---
name: pick-theme
description: >-
  Standard theme picker for all insight-wave ecosystem plugins. Discovers themes
  from the standard cogni-workspace themes directory and the user's workspace
  themes directory, then presents an interactive picker via AskUserQuestion.
  Returns the absolute path to the selected theme.md file. Use this skill
  whenever a downstream skill needs a theme — before generating slides, dashboards,
  web narratives, big pictures, storyboards, HTML reports, or any other themed
  output. Triggers on phrases like "pick a theme", "choose theme", "which theme",
  "select a theme", or when any visual output skill needs theme resolution. Also
  triggers when skills internally need theme selection as a prerequisite step.
  Also triggers on "apply a theme", "use this theme", or "theme my output".
  This is the single standard entry point for theme selection across both
  insight-wave and insight-wave-pro marketplaces.
version: 0.2.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Pick Theme

Standard theme picker for the insight-wave ecosystem. Provides a single, consistent theme selection experience used by all plugins that produce visual output — slides, dashboards, web narratives, big pictures, storyboards, and HTML reports.

## Why This Exists

Without a centralized picker, every visual skill implements its own theme discovery and selection logic. This leads to inconsistent UX (different skills show different theme lists), missed themes (some skills only scan one directory), and duplicated code. This skill is the one place where theme discovery and selection happens.

## Theme Sources

The picker scans two directories and merges the results:

| Source | Location | Purpose |
|--------|----------|---------|
| **Standard** | `$CLAUDE_PLUGIN_ROOT/themes/` | Ships with cogni-workspace. Always available. Contains `cogni-work` and any other bundled themes. |
| **Workspace** | `$COGNI_WORKSPACE_ROOT/themes/` | User-created themes via `manage-themes`. Project-specific brand themes. |

If both directories contain a theme with the same slug, the workspace version takes priority (the user's customization wins). The `_template/` directory is always skipped.

## How to Use

### Step 1: Discover Available Themes

Run the discovery script to get a JSON array of all available themes:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/pick-theme/scripts/discover-themes.py"
```

The script outputs a JSON array sorted by relevance: workspace themes first (newest first), then standard themes. Each entry contains:

```json
{
  "slug": "cogni-work",
  "name": "Cogni Work",
  "description": "A bold, modern theme pairing electric chartreuse with deep black foundations.",
  "primary": "#111111",
  "accent": "#C8E62E",
  "background": "#FAFAF8",
  "font": "DM Sans Bold",
  "path": "/absolute/path/to/themes/cogni-work/theme.md",
  "source": "standard",
  "mtime": 1741564800.0,
  "tiers": {
    "tokens": "/absolute/path/to/themes/cogni-work/tokens",
    "components": {"web": "/absolute/path/to/themes/cogni-work/components/web"}
  }
}
```

The `mtime` field is the file modification timestamp (Unix epoch). The script pre-sorts results so the first entry is always the best default candidate — no additional sorting needed.

#### Optional fields (Theme System v2)

Two fields are optional and only appear when a theme ships a `manifest.json` (see `references/theme-manifest.md`):

| Field | When present | Shape |
|-------|--------------|-------|
| `tiers` | manifest.json exists and validates | object with absolute resolved paths for each declared tier (`tokens`, `assets`, `components.{web,deck,dashboard}`, `templates.{deck,report,landing,dashboard}`, `showcase`) — keys mirror what the manifest declared, no more |
| `manifest_error` | manifest.json exists but failed validation | string with the validator's error message; the theme still appears in the output as a tier-0 fallback so a broken manifest never makes a theme disappear |

Tier-0 themes (no `manifest.json`) emit byte-identical output to the legacy script — neither field is present. Pass `--no-include-tiers` to suppress both fields globally regardless of manifest state.

### Step 2: Present the Picker

Present discovered themes via AskUserQuestion. Build the options from the discovery output. Each option should show the theme name plus a compact summary (primary color, accent color, font).

**Rules for building the picker:**

- Show up to 4 themes as AskUserQuestion options (the tool's maximum)
- If more than 4 themes exist, take the first 4 from the discovery output — the script already sorts by relevance (workspace first, newest first), so the top 4 are the best candidates
- The first option is the recommended default — add "(Recommended)" to its label
- The "Other" escape hatch (built into AskUserQuestion) lets users type a custom theme path
- If only 1 theme exists, skip the picker entirely and use it directly — tell the user which theme is being applied

**AskUserQuestion structure** (must match the tool's exact schema):

```json
{
  "questions": [{
    "question": "Which theme would you like to use?",
    "header": "Theme",
    "multiSelect": false,
    "options": [
      {
        "label": "Cogni Work (Recommended)",
        "description": "#111111 + #C8E62E · DM Sans Bold · standard"
      },
      {
        "label": "Digital X",
        "description": "#0D3B4F + #00BCD4 · Inter Bold · workspace"
      }
    ]
  }]
}
```

**Option format:** `label` = theme name, `description` = `{primary} + {accent} · {font} · {source}`. Keep a mental map of label → path from the discovery output so you can resolve the user's selection back to the absolute theme path.

### Step 3: Resolve Selection

- If the user picked a listed theme → use the `path` from the discovery output
- If the user typed a custom path via "Other" → validate the path exists and contains a theme.md
- Read the selected theme.md to confirm it's valid (has at minimum a Color Palette section)

### Step 4: Return the Theme Path

The output of this skill is the **absolute path** to the selected `theme.md` file. The calling skill uses this path to read theme tokens and apply them to its output.

Store and communicate these three values — they form the **return contract** that downstream skills depend on:

| Field | Value | Example |
|-------|-------|---------|
| **theme_path** | Absolute path to `theme.md` | `/Users/.../themes/cogni-work/theme.md` |
| **theme_name** | Human-readable name from the H1 | `Cogni Work` |
| **theme_slug** | Directory name (kebab-case) | `cogni-work` |

Downstream skills receive `theme_path` and read design tokens directly from the file. For Python-based scripts, pass it as `--theme <theme_path>`. For skill-to-skill handoffs, include it in the calling context.

## Integration Guide for Downstream Skills

Any skill that produces themed output should use pick-theme instead of implementing its own theme resolution. Replace inline theme scanning with a reference to this skill.

**Before** (each skill doing its own thing):
```
Scan themes/*/theme.md, present via AskUserQuestion. Otherwise use default.
```

**After** (delegating to pick-theme):
```
Use cogni-workspace:pick-theme to let the user select a theme.
The skill returns the absolute path to the chosen theme.md.
Read the theme.md and extract design tokens for your output.
```

### Skip Conditions

The picker can be skipped when:
- The caller already has a `theme_path` parameter (explicit theme from upstream)
- The caller is running in non-interactive/auto mode
- There's only one theme available (auto-select it)

In these cases, just validate the provided path and proceed.

## Auto-Discovery and Stale Path Handling

The discovery script automatically detects when `COGNI_WORKSPACE_ROOT` is empty, missing, or stale (e.g. pointing to a previous Cowork session path like `/sessions/...`). When this happens, it searches for `.workspace-config.json` in common locations:

1. `$PROJECT_AGENTS_OPS_ROOT` (if set and valid)
2. `~/Library/CloudStorage/*/*/` (macOS cloud storage — OneDrive, iCloud, Dropbox)
3. `~/*/` (direct home subdirectories)

It picks the most recently modified workspace and scans its `cogni-workspace/themes/` directory. The auto-discovery output appears on stderr:
```
WARNING: workspace root not found: /sessions/gallant-vibrant-cori/mnt/TSC/cogni-workspace
HINT: path looks like a stale Cowork session. Auto-discovering...
AUTO-DISCOVERED workspace themes: /Users/.../TSC/cogni-workspace/themes
```

To disable auto-discovery (e.g. in CI/CD), pass `--no-discover`. To override the workspace root explicitly:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/pick-theme/scripts/discover-themes.py" --workspace-root "/path/to/workspace"
```

## Fallback Behavior

If no themes are found at all (neither standard nor workspace):
1. Warn the user: "No themes found. Would you like to create one with /manage-themes, or continue with default styling?"
2. If continuing without a theme, return an empty path — the downstream skill should use its own hardcoded fallback

If the discovery script fails (missing python3, permission issues):
1. Fall back to manual Glob scanning with the `path` parameter set to the base directory:
   - Standard themes: pattern `*/theme.md`, path `$CLAUDE_PLUGIN_ROOT/themes`
   - Workspace themes: pattern `*/theme.md`, path `$COGNI_WORKSPACE_ROOT/themes`
2. Parse theme names from H1 lines
3. Present via AskUserQuestion as usual
