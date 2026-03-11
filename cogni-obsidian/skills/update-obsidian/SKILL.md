---
name: update-obsidian
description: >-
  Incrementally update an existing Obsidian vault's terminal configuration without overwriting user
  customizations. Use this skill when the user wants to update Obsidian settings, fix terminal
  profiles, refresh their Obsidian setup, sync new profiles from template, or troubleshoot WSL
  terminal issues. Also trigger when the user ran setup-obsidian before and now needs to bring
  their configuration up to date, or when they mention broken terminal profiles or path issues
  in Obsidian.
version: 1.1.0
---

## Purpose

Bring an existing Obsidian vault's terminal configuration up to date. The update script merges new profiles from the plugin template, fixes common WSL issues (doubled paths, stale args), removes deprecated profiles, and copies new launcher scripts — all without touching profiles or scripts the user has customized.

This is the counterpart to `setup-obsidian`: setup creates from scratch, update patches what's already there.

## Workflow

### Step 1: Resolve the Workplace Directory

**Resolution order:**
1. If the user gave a path, use it.
2. If the current working directory has `.obsidian/plugins/terminal/data.json`, use it.
3. Otherwise, ask which workplace to update.

If no `.obsidian/` directory exists at all, tell the user this workplace hasn't been set up yet and suggest `setup-obsidian` instead.

### Step 2: Run the Update Script

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-obsidian.sh" "<WORKPLACE_DIR>"
```

Add `--dry-run` to preview changes first. The script is idempotent — safe to run multiple times.

**If the script fails**, check the JSON error:
- Exit 1 (validation): directory not found or invalid JSON in data.json
- Exit 2 (args): missing workplace directory argument
- Exit 3 (operation failed): a write operation failed — check file permissions

### Step 3: Summarize Changes

The script returns JSON with arrays describing what changed:
- `profiles_added` — new terminal profiles merged from template
- `profiles_fixed` — WSL profiles that had stale args or missing settings corrected
- `scripts_copied` — new launcher scripts added

If all arrays are empty, nothing needed updating — tell the user their configuration is already current. If `--dry-run` was used, confirm whether to apply the changes for real.

## Script Contract

Full interface: `${CLAUDE_PLUGIN_ROOT}/contracts/update-obsidian.yml`
