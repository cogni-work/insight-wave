---
name: init-workspace
description: >-
  Initialize a insight-wave workspace with shared foundation for marketplace
  plugins. Use this skill whenever someone asks to create, set up, scaffold, or
  initialize a workspace — including phrases like "set up my workplace",
  "get started with cogni", "create a new project workspace", or any mention of
  workspace initialization. Also trigger when someone runs a fresh plugin
  install and needs the shared foundation that plugins depend on.
version: 0.2.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Init Workspace

A insight-wave workspace is the shared foundation that all marketplace plugins depend on. It centralizes environment configuration, theme storage, and plugin registration so that plugins can find each other and share resources. Without a workspace, plugins operate in isolation and can't resolve paths or discover themes.

## Before You Start

Run the dependency checker — it returns JSON so you can parse the result and tell the user exactly what's missing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

Required: `jq`, `python3`, `bash` 3.2+. If required dependencies are missing, show the user what to install before continuing. Optional dependencies (`curl`, `git`, `bc`) are fine to skip.

## Initialization Flow

### 1. Where and Whether

Ask the user where to create the workspace. Default to the current working directory.

If `.workspace-config.json` already exists at the target, this workspace was already initialized. Suggest `update-workspace` instead — re-initializing would overwrite their configuration.

### 2. Discover Plugins

Scan the marketplace cache for installed cogni-* plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

The script returns JSON with each plugin's name, version, path, and computed environment variable names. Present the list to the user so they can confirm, add, or remove plugins before proceeding. This matters because the plugin list determines which environment variables get generated — missing a plugin here means it won't be wired up.

### 3. Gather Preferences

Use AskUserQuestion to collect:

1. **Language** — EN or DE. This controls which behavioral output-style anchors get installed, affecting how Claude communicates in this workspace.
2. **Plugin confirmation** — Show discovered plugins, let the user adjust.
3. **Tool integrations** — Obsidian, VS Code, other. This gets stored in the config so tool-specific plugins know what to set up later.

### 4. Generate the Workspace

This is the core step. Run the settings generator with the confirmed inputs:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh \
  --target "${TARGET_DIR}" \
  --language "${LANGUAGE}" \
  --plugins "${PLUGIN_LIST_JSON}"
```

The script creates three files:
- **`.claude/settings.local.json`** — Environment variables that Claude Code auto-injects. This is the single source of truth for plugin paths.
- **`.workspace-env.sh`** — Same variables exported for non-Claude contexts (Obsidian Terminal, VS Code tasks, CI/CD).
- **`.workspace-config.json`** — Workspace metadata (version, language, plugin list, timestamps).

It also creates data directories for each registered plugin under the workspace root.

Pass the plugins argument as either a JSON string or a path to a JSON file containing the plugin array from the discovery step.

### 5. Install Output Styles, CLAUDE.md Templates, and Theme Template

Copy the language-appropriate output-style file. These files contain behavioral anchors that shape Claude's communication patterns in this workspace:

```bash
cp "${CLAUDE_PLUGIN_ROOT}/assets/output-styles/workspace-${LANGUAGE}.md" \
   "${TARGET_DIR}/.claude/output-styles/"
```

Copy the language-specific CLAUDE.md template to the workspace root and to the templates directory (used by the Obsidian Terminal launcher for per-session language switching):

```bash
cp "${CLAUDE_PLUGIN_ROOT}/assets/claude-templates/CLAUDE.${LANGUAGE}.md" \
   "${TARGET_DIR}/CLAUDE.md"

mkdir -p "${TARGET_DIR}/.claude/templates"
cp "${CLAUDE_PLUGIN_ROOT}/assets/claude-templates/CLAUDE.en.md" \
   "${CLAUDE_PLUGIN_ROOT}/assets/claude-templates/CLAUDE.de.md" \
   "${TARGET_DIR}/.claude/templates/"
```

The CLAUDE.md at workspace root ensures Claude uses the correct language and orthography (including umlauts for German). The templates directory enables the Obsidian launcher to switch languages per session.

Create the `output-styles` and `templates` directories first if needed. Then copy the theme template:

```bash
cp -r "${CLAUDE_PLUGIN_ROOT}/themes/_template/" \
      "${TARGET_DIR}/cogni-workspace/themes/_template/"
```

The template gives users a starting point for creating custom themes that visual plugins consume.

### 6. Obsidian Integration (Optional)

If the user indicated they use Obsidian in step 3, offer to set up Obsidian integration now:

> "You mentioned you use Obsidian. Would you like me to set up the vault integration now? This adds a Terminal plugin with a Claude Code launcher so you can work in Obsidian and launch Claude Code from the built-in terminal."

If yes, run the setup script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-obsidian.sh" "${TARGET_DIR}"
```

If `.obsidian/` already exists, skip and mention that `update-obsidian` can refresh the terminal config.

If the user declines, let them know they can run `/setup-obsidian` later.

### 7. Summarize

Show what was created in a compact format:
- Workspace path
- Registered plugins with their environment variable names
- Language setting
- Next steps: install themes, configure tool integrations, explore plugin capabilities

## Error Handling

If any script returns `"success": false` in its JSON output, read the `data.error` field and relay it to the user. Don't continue past a failed step — the workspace would be in an incomplete state.

If `generate-settings.sh` fails partway through, clean up by removing any partially created files before reporting the error.
