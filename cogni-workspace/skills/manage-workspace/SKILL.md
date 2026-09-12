---
name: manage-workspace
description: >-
  Initialize or update an insight-wave workspace — the shared foundation that all
  marketplace plugins depend on. Use this skill whenever someone asks to create,
  set up, scaffold, initialize, update, refresh, or sync a workspace — including
  phrases like "set up my workplace", "get started with cogni", "create a new
  project workspace", "update workspace", "refresh workspace", "sync plugins",
  "re-scan plugins", or any mention of workspace initialization or updates. Also
  trigger when someone runs a fresh plugin install and needs the shared foundation
  that plugins depend on, or when plugins were added/removed and the workspace
  needs to catch up. Even if the user just says "new project", "start fresh",
  "add a plugin", "wire up my workspace", or "my plugins can't find each other",
  this skill applies.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Workspace

## Why This Exists

An insight-wave workspace is the shared foundation that all marketplace plugins depend on. It centralizes environment configuration, theme storage, and plugin registration so that plugins can find each other and share resources. Without a workspace, plugins operate in isolation and can't resolve paths or discover themes.

This skill handles both initial creation and ongoing updates. It auto-detects which mode to use based on whether a workspace already exists.

## Before Starting

Run the dependency checker — it returns JSON, so parse the result and tell the user exactly what's missing:

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

1. **Language** — EN or DE. This is written as the `language` key by step 3, which Claude Code turns into a `# Language` system-prompt section, so a fresh session responds in the workspace language. Bilingual plugins read the same value as their default.
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

The script generates `_ROOT` and `_PLUGIN` environment variables for each plugin. It does not create plugin data directories — each plugin creates its own working directory when it first needs one (via its own setup/init skill). It also emits `COGNI_WORKSPACE_PYTHON_VENV` (pointing at `~/.claude/workspace-python-venv`), which the next step uses to provision optional Python dependencies.

Pass the plugins argument as either a JSON string or a path to a JSON file containing the plugin array from the discovery step.

### 3.5. Provision Optional Python Dependencies

Some plugins ship pip-backed optional fallbacks (e.g. cogni-knowledge's
text-layer PDF extraction via `pypdf`). cogni-workspace provisions these into an
isolated venv at `~/.claude/workspace-python-venv/` — mirroring how MCP servers
install into `~/.claude/` — so the stdlib-only convention for plugin scripts
stays intact while the fallbacks "light up" automatically. Step 3 already emitted
`COGNI_WORKSPACE_PYTHON_VENV` into the settings, so the venv path is in place
before this step runs.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/install-workspace-deps.sh
```

**Fail-soft — never block setup.** Every package is optional. If `python3`, the
`venv` module, or the network is unavailable, the script returns a clean
`{"success":false,...}` envelope; warn and continue (do not abort init). On
success it returns `data.action` of `installed` / `updated` / `skipped` and the
provisioned package list. Packages are declared in
`${CLAUDE_PLUGIN_ROOT}/references/python-deps-registry.json`.

### 4. Install Theme Template

Do **not** copy an output style into the workspace. The register ships with the plugin at `output-styles/`, where Claude Code discovers it — a copied style only appears in the picker and is never activated, so copying it creates a file that looks like configuration and governs nothing. Users select it in `/config`.

Do **not** write a workspace-root `CLAUDE.md`. The language rules reach a fresh session without it: step 3's `generate-settings.sh` writes the `language` key into `.claude/settings.local.json`, which Claude Code turns into a `# Language` system-prompt section, and the plugin's `SessionStart` hook adds the orthography rules that section does not carry. The root `CLAUDE.md` is the user's file — the place for project-specific instructions — and this skill never creates or overwrites it.

Copy the theme template:

```bash
cp -r "${CLAUDE_PLUGIN_ROOT}/themes/_template/" \
      "${TARGET_DIR}/cogni-workspace/themes/_template/"
```

The template gives users a starting point for creating custom themes that visual plugins consume.

### 5. MCP Server Installation

Delegate to the `install-mcp` skill, which handles the full lifecycle: git-based server
installation, native app detection, writing the server into the user config for the
detected client (Claude Code `~/.claude.json` and/or Claude Desktop), and verification.

Since manage-workspace already has the plugin list confirmed in step 2, pass it to
install-mcp so it skips redundant plugin discovery. The skill runs non-interactively
when called from here (no extra user confirmations needed).

After install-mcp completes, read
`${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json` — anchored because at this point
in the flow the working directory is the user's workspace target, not the plugin root —
for the installable server set, and present a combined summary. The registry is what says
which servers install-mcp can write, so read the set from it rather than assuming a fixed
pair — a server added there is installable without touching this skill. claude-in-chrome
is the one ecosystem MCP with no registry entry: a Chrome extension the user installs
themselves. Show a row only
for a registry server whose `required_by` intersects the plugin list confirmed in step 2 —
install-mcp installs nothing for an absent plugin — and take each row's action and status
verbatim from install-mcp's returned summary rather than from the registry. The Action
cell is the per-server verb exactly as that summary carries it (install-mcp reads it from
the config writer's per-server `actions[]`), never a label composed here — composing one
reports a write for a server the writer may have skipped; the verb set and where to read
it from live in
`${CLAUDE_PLUGIN_ROOT}/skills/install-mcp/references/result-envelope.md`. Label each row
with the entry's `desktop_config_key` as the registry gives it (the server
`mcp_excalidraw` labels as `excalidraw`, for example), because that key is what lands in
the user's config and what the `mcp__<key>__*` tool names derive from; do not label the
row with the registry server name. The block below is illustrative:

```
MCP Servers (installed on demand, written to your config):
  excalidraw       added      loaded       <- cogni-portfolio, cogni-workspace
  pencil           skipped    not loaded   <- cogni-website, cogni-workspace

Manual install needed:
  claude-in-chrome Chrome extension                  <- cogni-website, cogni-workspace
```

The row-selection rule above covers registry servers only. Show the `Manual install needed:`
row when the plugin list confirmed in step 2 includes `cogni-website` or `cogni-workspace`;
that pairing is fixed here rather than read from the registry, since `claude-in-chrome` has
no registry entry to supply it.

install-mcp does not always return per-server rows, and there is nothing to render when it
does not — the shapes that produce that are enumerated in
`${CLAUDE_PLUGIN_ROOT}/skills/install-mcp/references/result-envelope.md`. In every such case,
render no rows rather than inventing them: report the affected servers as not configured,
surface the raw error and the target it names when there is one, and send the user to
`/cogni-workspace:install-mcp` to finish the write before treating workspace setup as
complete.

Newly written servers load only after a session restart — relay install-mcp's restart
reminder in the summary rather than presenting "config written" as a finished state.

### 6. Obsidian Integration (Optional)

If the user indicated they use Obsidian in step 2, offer to set up Obsidian integration now:

> "You mentioned you use Obsidian. Would you like me to set up the vault integration now? This adds a Terminal plugin with a Claude Code launcher so you can work in Obsidian and launch Claude Code from the built-in terminal."

If yes, run the setup script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-obsidian.sh" "${TARGET_DIR}"
```

If `.obsidian/` already exists, skip and mention that the update step (Update Mode step 6) can refresh the terminal config.

If the user declines, let them know they can run a workspace update later to add it.

### 7. Summarize

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

The `--update` flag preserves any custom env vars the user added manually. It
also removes the per-plugin vars it generated for plugins that are no longer in
the confirmed list: `COGNI_<NAME>_ROOT` and `COGNI_<NAME>_PLUGIN`, or
`PLUGIN_<NAME>_ROOT` and `PLUGIN_<NAME>_PLUGIN` for a plugin outside the
`cogni-` namespace. So deselecting a plugin at step 2 retires its wiring instead
of leaving a var pointing at a directory that no longer exists.

`PROJECT_AGENTS_OPS_ROOT`, `COGNI_WORKSPACE_ROOT` and
`COGNI_WORKSPACE_PYTHON_VENV` are kept regardless of that list, since the
workspace needs its own pointers even when `cogni-workspace` is deselected.

### 3.5. Refresh Optional Python Dependencies

Re-provision the optional-dep venv so any newly declared packages (or version
bumps) in `${CLAUDE_PLUGIN_ROOT}/references/python-deps-registry.json` are picked up. `--force`
reinstalls/upgrades into the existing `~/.claude/workspace-python-venv/`:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/install-workspace-deps.sh --force
```

Same fail-soft contract as Init Mode Step 3.5: warn and continue if `python3` /
the `venv` module / the network is unavailable — never block the update.

### 4. Update Theme Template

**Migrate a workspace created before the language settings key.** Step 3's `generate-settings.sh --update` writes the `language` key into `.claude/settings.local.json`, which is now where the workspace language lives. Three retired artifacts may still be on disk:

- `.claude/templates/` — the cache that fed the Obsidian launcher's per-session `CLAUDE.md` copy. Nothing reads it any more. Delete it.
- `.claude/output-styles/workspace-en.md` / `workspace-de.md` — copies this skill used to install. A copied style only ever appeared in the picker; the register now ships with the plugin. Say so and offer to delete them, defaulting to keeping the files in case the user edited one.
- The workspace-root `CLAUDE.md`, if it was written by a retired template. Compare it against the language block the plugin used to ship (a `# Workspace Instructions` / `# Workspace-Anweisungen` heading followed only by language bullets). If that is all it contains, say the rules now arrive via the settings key and the `SessionStart` hook and offer to delete it — defaulting to keeping the file. If it contains anything else, leave it untouched and say why.

Do **not** overwrite the workspace-root `CLAUDE.md` under any branch. It is the user's file.

Refresh `_template/theme.md` from `${CLAUDE_PLUGIN_ROOT}/themes/_template/`. Preserve all user-created themes.

### 5. MCP Server Installation

Same as Init Mode step 5 — delegate to the `install-mcp` skill. In update mode, also
tell install-mcp to use `--force` for git-based MCPs (pulls latest and rebuilds).
Removing a plugin does **not** remove its MCP server — the entry now lives in the user's
own config and `install-mcp` has no removal path, so only the user can delete it.
Name each server whose `required_by` no longer intersects the confirmed plugin list and
tell the user which key to remove. The key is the registry entry's
`desktop_config_key` (for `mcp_excalidraw` that is `excalidraw`), not the registry server
name — naming the server name instead tells the user to delete a key that is not there, and
the orphan server keeps spawning at every session start. Remove it from `~/.claude.json`
(top-level `mcpServers`) and/or `claude_desktop_config.json`.

### 6. Update Obsidian Integration (Optional)

If `.obsidian/` exists in the workspace, offer to refresh the terminal configuration:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-obsidian.sh" "${WORKSPACE_DIR}"
```

This merges new terminal profiles and fixes common issues without touching user customizations. Skip this step if no `.obsidian/` directory is found.

### 7. Verify and Report

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

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
