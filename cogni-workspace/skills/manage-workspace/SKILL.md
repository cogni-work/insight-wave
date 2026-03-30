---
name: manage-workspace
description: >-
  Initialize or update a insight-wave workspace — the shared foundation that all
  marketplace plugins depend on. Use this skill whenever someone asks to create,
  set up, scaffold, initialize, update, refresh, or sync a workspace — including
  phrases like "set up my workplace", "get started with cogni", "create a new
  project workspace", "update workspace", "refresh workspace", "sync plugins",
  "re-scan plugins", or any mention of workspace initialization or updates. Also
  trigger when someone runs a fresh plugin install and needs the shared foundation
  that plugins depend on, or when plugins were added/removed and the workspace
  needs to catch up.
version: 0.3.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Workspace

A insight-wave workspace is the shared foundation that all marketplace plugins depend on. It centralizes environment configuration, theme storage, and plugin registration so that plugins can find each other and share resources. Without a workspace, plugins operate in isolation and can't resolve paths or discover themes.

This skill handles both initial creation and ongoing updates. It auto-detects which mode to use based on whether a workspace already exists.

## Before You Start

Run the dependency checker — it returns JSON so you can parse the result and tell the user exactly what's missing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

Required: `jq`, `python3`, `bash` 3.2+. If required dependencies are missing, show the user what to install before continuing. Optional dependencies (`curl`, `git`, `bc`) are fine to skip.

## Detect Mode

Determine the workspace target path:
1. User-provided path (if they specified one)
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

Check for `.workspace-config.json` at the target path:
- **Not found** → Init mode (section below)
- **Found** → Update mode (section further below)

---

## Init Mode

Use this flow when no workspace exists yet at the target path.

### 1. Discover Plugins

Scan the marketplace cache for installed cogni-* plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

The script returns JSON with each plugin's name, version, path, and computed environment variable names. Present the list to the user so they can confirm, add, or remove plugins before proceeding. This matters because the plugin list determines which environment variables get generated — missing a plugin here means it won't be wired up.

### 2. Gather Preferences

Use AskUserQuestion to collect:

1. **Language** — EN or DE. This controls which behavioral output-style anchors get installed, affecting how Claude communicates in this workspace.
2. **Plugin confirmation** — Show discovered plugins, let the user adjust.
3. **Tool integrations** — Obsidian, VS Code, other. This gets stored in the config so tool-specific plugins know what to set up later.

### 3. Generate the Workspace

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

The script generates `_ROOT` and `_PLUGIN` environment variables for each plugin. It does not create plugin data directories — each plugin creates its own working directory when it first needs one (via its own setup/init skill).

Pass the plugins argument as either a JSON string or a path to a JSON file containing the plugin array from the discovery step.

### 4. Install Output Styles, CLAUDE.md Templates, and Theme Template

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

### 5. Obsidian Integration (Optional)

If the user indicated they use Obsidian in step 2, offer to set up Obsidian integration now:

> "You mentioned you use Obsidian. Would you like me to set up the vault integration now? This adds a Terminal plugin with a Claude Code launcher so you can work in Obsidian and launch Claude Code from the built-in terminal."

If yes, run the setup script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-obsidian.sh" "${TARGET_DIR}"
```

If `.obsidian/` already exists, skip and mention that the update step (Update Mode step 5) can refresh the terminal config.

If the user declines, let them know they can run a workspace update later to add it.

### 6. Summarize

Show what was created in a compact format:
- Workspace path
- Registered plugins with their environment variable names
- Language setting
- Next steps: install themes, configure tool integrations, explore plugin capabilities

---

## Update Mode

Use this flow when `.workspace-config.json` already exists at the target path. Read it to understand current state (language, installed plugins, tool integrations).

### 1. Create Backup

Before modifying anything, create a timestamped backup:

```bash
BACKUP_DIR=".backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"
cp .workspace-config.json "${BACKUP_DIR}/"
cp -r .claude/ "${BACKUP_DIR}/"
cp .workspace-env.sh "${BACKUP_DIR}/" 2>/dev/null
```

### 2. Re-Discover Plugins

Run plugin discovery to detect new, removed, or updated plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

Compare against the `installed_plugins` list in `.workspace-config.json`. Present changes to the user:
- **New plugins**: Not in config but found installed
- **Removed plugins**: In config but no longer installed
- **Unchanged plugins**: Still present

Ask user to confirm the updated plugin list.

### 3. Refresh Environment Variables

Regenerate `settings.local.json` and `.workspace-env.sh` with the confirmed plugin list:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh \
  --target "${WORKSPACE_DIR}" \
  --language "${LANGUAGE}" \
  --plugins "${UPDATED_PLUGIN_LIST_JSON}" \
  --update
```

The `--update` flag preserves any custom env vars the user added manually.

### 4. Update Output Styles and Theme Template

Copy latest output-style files from `${CLAUDE_PLUGIN_ROOT}/assets/output-styles/` to `.claude/output-styles/`, overwriting existing ones (these are plugin-managed, not user-customized).

Refresh `_template/theme.md` from `${CLAUDE_PLUGIN_ROOT}/themes/_template/`. Preserve all user-created themes.

### 5. Update Obsidian Integration (Optional)

If `.obsidian/` exists in the workspace, offer to refresh the terminal configuration:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-obsidian.sh" "${WORKSPACE_DIR}"
```

This merges new terminal profiles and fixes common issues without touching user customizations. Skip this step if no `.obsidian/` directory is found.

### 6. Verify and Report

Update `.workspace-config.json`:
- Refresh `installed_plugins` list
- Update `updated_at` timestamp
- Bump version if schema changed

Check all expected files exist. Present a summary:
- Plugins added/removed
- Environment variables changed
- Files updated
- Backup location (for rollback if needed)

## Rollback

If something goes wrong during an update, restore from backup:

```bash
cp -r .backups/{timestamp}/.claude/ .claude/
cp .backups/{timestamp}/.workspace-config.json .
cp .backups/{timestamp}/.workspace-env.sh . 2>/dev/null
```

## Error Handling

If any script returns `"success": false` in its JSON output, read the `data.error` field and relay it to the user. Don't continue past a failed step — the workspace would be in an incomplete state.

If `generate-settings.sh` fails partway through, clean up by removing any partially created files before reporting the error.
