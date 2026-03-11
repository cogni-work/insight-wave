---
name: setup-obsidian
description: >-
  Scaffold a complete Obsidian vault with Claude Code terminal integration for a workplace
  directory. Use this skill whenever the user wants to set up Obsidian, create or configure an
  Obsidian vault, connect Obsidian to Claude Code, scaffold a workplace environment, or mentions
  wanting to use Obsidian as their writing/research/project workspace. Also trigger when the user
  asks about integrating a terminal into Obsidian or launching Claude Code from within Obsidian,
  even if they don't explicitly say "setup".
version: 1.1.0
---

## Purpose

Create a ready-to-use `.obsidian/` configuration inside a workplace directory so the user can open it in Obsidian and immediately launch Claude Code from the built-in Terminal plugin. The configuration includes a Tokyonight-themed terminal, a launcher script that handles language selection and permission modes, and sensible vault defaults (live preview, line numbers, file explorer, search, backlinks).

## Workflow

### Step 1: Resolve the Target Directory

The user may provide a path explicitly, or you may need to figure it out from context.

**Resolution order:**
1. If the user gave a path, use it.
2. If the current working directory contains `.workplace-env.sh` or `.workplace-config.json`, suggest it — these are markers of an existing workplace.
3. Otherwise, ask: "Which directory should I set up as an Obsidian vault?"

### Step 2: Check for Existing Configuration

Check whether `<TARGET_DIR>/.obsidian/` already exists. If it does, **stop** — the setup script refuses to overwrite existing configurations. Tell the user their vault is already configured and suggest using `update-obsidian` instead, which handles incremental updates while preserving their customizations.

### Step 3: Run the Setup Script

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-obsidian.sh" "<TARGET_DIR>"
```

The script copies template configs, downloads the Terminal plugin from GitHub, substitutes path placeholders, and sets the platform-appropriate default profile. It outputs JSON — check `success` in the response.

Add `--dry-run` if the user wants to preview what would happen first.

**If the script fails**, check the JSON error:
- Exit 1 (validation): the directory doesn't exist or copying failed — confirm the path
- Exit 2 (args): missing target directory — ensure the path argument is passed
- Exit 3 (dependency): `jq` or `curl` is missing — tell the user to install them

### Step 4: Guide the User

After a successful run, tell the user how to get started:

1. **Open in Obsidian** — File > Open Vault > navigate to the workplace directory
2. **Launch the terminal** — Click the terminal icon in the left ribbon, or use Command Palette > "Terminal: Open terminal"
3. **The "Workplace" profile starts Claude Code** — it will ask for language and permission mode, then launch Claude Code in the workplace context
4. **Tip**: if the user has `.workplace-env.sh`, environment variables are sourced automatically when the terminal opens

### What Gets Created

```
.obsidian/
├── app.json                 # Live preview, line numbers, link auto-update
├── appearance.json          # Moonstone theme, 16px base font
├── core-plugins.json        # 15 core plugins (explorer, search, graph, backlinks, etc.)
├── community-plugins.json   # Terminal plugin
├── workspace.json           # Default layout: editor + file explorer + search sidebar
└── plugins/terminal/
    ├── main.js              # Terminal plugin (downloaded from GitHub)
    ├── manifest.json
    ├── styles.css
    ├── data.json             # Workplace profiles with Tokyonight terminal theme
    └── workplace-orchestrator.sh  # Claude Code launcher script
```

## Script Contract

Full interface: `${CLAUDE_PLUGIN_ROOT}/contracts/setup-obsidian.yml`
