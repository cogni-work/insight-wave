---
name: workspace-status
description: "Diagnose and report on the health of a insight-wave workspace. Use this skill whenever the user mentions workspace status, health, diagnostics, or troubleshooting — including check workspace, is my workspace ok, something broke, why isn't my plugin working, diagnose workspace, verify workspace, or any situation where understanding the workspace state would help resolve a problem. Even if the user doesn't explicitly say status, trigger this skill when they describe symptoms that suggest a misconfigured workspace (missing env vars, plugins not found, themes not loading). This is the first skill to reach for when debugging workspace issues."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Workspace Status

Diagnose the health of a insight-wave workspace by checking its foundation files, environment variables, plugin registry, themes, and dependencies. The goal is to give the user a clear picture of what's working and what needs attention, with actionable fixes for every issue found.

## Locating the Workspace

Find the workspace using this priority:
1. User-provided path
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

If no `.workspace-config.json` exists at the resolved path, stop and tell the user no workspace was found. Suggest they run `manage-workspace` to create one and explain briefly what a workspace provides (centralized config, plugin discovery, shared themes).

## Running the Checks

Run all five checks, then present a single consolidated report. The checks are ordered by dependency — foundation must exist before environment makes sense, environment must be correct before plugins can be verified.

### 1. Foundation

These files form the workspace skeleton. Without them, other checks can't run reliably.

| File | Required | What it does |
|------|----------|--------------|
| `.workspace-config.json` | Yes | Stores workspace metadata — version, language, registered plugins, timestamps. All other checks read from this file. |
| `.claude/settings.local.json` | Yes | Environment variables that Claude Code auto-injects. Plugins use these to find each other's paths. |
| `.workspace-env.sh` | No | Same variables exported for non-Claude contexts (Obsidian Terminal, VS Code tasks, CI/CD). Missing means shell-based tooling won't resolve plugin paths. |
| `.claude/output-styles/` | No | Behavioral anchors that shape Claude's communication style. Missing means default communication style. |

Read `.workspace-config.json` to extract: version, language, installed_plugins, created_at, updated_at.

**If a required file is missing**: report CRITICAL and suggest `manage-workspace`. Skip checks that depend on the missing file rather than producing misleading results.

### 2. Environment

Environment variables are the wiring that lets plugins find each other. A broken variable means a plugin can't locate its data directory or discover sibling plugins.

Verify these core variables exist and point to real directories:
- `PROJECT_AGENTS_OPS_ROOT` — workspace root
- `COGNI_WORKSPACE_ROOT` — shared workspace data directory

Then for each plugin listed in `.workspace-config.json`, verify its computed variables:
- `COGNI_{SUFFIX}_ROOT` or `PLUGIN_{SUFFIX}_ROOT` — the plugin's data directory
- `COGNI_{SUFFIX}_PLUGIN` or `PLUGIN_{SUFFIX}_PLUGIN` — the plugin's install path

Read the actual values from `.claude/settings.local.json` (the `env` object) and check that each path exists on disk. Report:
- **Set and valid**: the variable exists and the path resolves
- **Set but broken**: the variable exists but the path doesn't exist (likely a moved or deleted directory)
- **Missing**: expected variable not found in settings

### 3. Plugin Registry

Plugins can drift out of sync — a user might install a new plugin without running `manage-workspace`, or uninstall one without cleaning up the config. This check catches that drift.

Run plugin discovery:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

Compare the discovered plugins against `installed_plugins` in `.workspace-config.json`:

- **Registered and installed**: healthy, no action needed
- **Registered but not installed**: the plugin was removed or its cache was cleared. Suggest running `manage-workspace` to clean up the stale registration.
- **Installed but not registered**: a new plugin is available but the workspace doesn't know about it yet. Suggest running `manage-workspace` to wire it in.

If `discover-plugins.sh` returns `"success": false`, report the error from `data.error` and note that plugin discovery couldn't complete.

### 4. Themes

Themes let visual plugins (slides, big pictures, web narratives) share a consistent look. Missing themes don't break anything, but they limit visual output options.

Scan `${COGNI_WORKSPACE_ROOT}/themes/` (skip `_template`):
- Count available themes
- For each theme, check that `theme.md` contains "Color Palette" and "Typography" sections (these are the minimum viable sections visual plugins look for)
- Check that `_template/` exists (needed to create new themes)

### 5. Dependencies

External tools that scripts rely on. Required dependencies block core functionality; optional ones limit specific features.

Run:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

The script returns JSON with each tool's availability and version. Report:
- **Required** (jq, python3): must be installed for scripts to work. If missing, tell the user what to install and how (`brew install jq`, etc.).
- **Optional** (curl, git, bc): nice to have. Note what functionality is limited without them.

If `check-dependencies.sh` returns `"success": false`, report which required tools are missing.

## Status Report

Present results as a compact summary. Use OK / WARNING / CRITICAL status per category:

```
Workspace Status: /path/to/workspace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Foundation:   OK       | 4/4 files present
Environment:  OK       | 12 vars set, 0 missing
Plugins:      OK       | 5 registered, 5 installed
Themes:       OK       | 3 themes available
Dependencies: OK       | 2/2 required, 3/3 optional

Language: EN | Last updated: 2026-03-04
```

**Expand any category that isn't OK** with specifics and a fix:

```
Plugins:      WARNING  | 5 registered, 6 installed
  New: cogni-narrative (installed but not registered)
  -> Run manage-workspace to register it

Environment:  WARNING  | 12 vars set, 2 broken
  Broken: COGNI_NARRATIVE_ROOT -> /path/does/not/exist
  Broken: COGNI_NARRATIVE_PLUGIN -> /path/does/not/exist
  -> Run manage-workspace to refresh environment variables
```

Every issue should end with a concrete next step — either a skill to run (`manage-workspace`, `manage-themes`) or a command to execute.

## Quick vs Detailed Mode

- **Quick** (default): the compact summary above, expanding only categories with issues
- **Detailed**: expand all categories regardless of status — show every file path, every env var value, every theme name, every dependency version. Use this when the user explicitly asks for details, runs a diagnosis, or says something like "show me everything"
