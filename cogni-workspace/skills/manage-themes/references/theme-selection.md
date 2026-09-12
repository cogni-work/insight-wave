# Theme Selection Mechanics

Supporting detail for **Operation 11 (Select Theme)**. Operation 11 in `SKILL.md` carries the contract — the discovery invocation, the picker rules, and the three-field return contract. This file carries the mechanics a caller reaches for only when something is unusual: which roots are scanned, the two optional discovery fields, what happens when the workspace root is stale, and what to do when discovery produces nothing.

## Theme Sources

The discovery script scans two directories and merges the results:

| Source | Location | Purpose |
|--------|----------|---------|
| **Standard** | `$CLAUDE_PLUGIN_ROOT/themes/` | Ships with cogni-workspace. Always available. Contains `cogni-work` and the bundled presets. |
| **Workspace** | `$COGNI_WORKSPACE_ROOT/themes/` | User themes created or forked through this skill. Project-specific brand themes. |

If both directories contain a theme with the same slug, the workspace version takes priority — the user's customisation wins. The `_template/` directory is always skipped.

## Optional discovery fields (Theme System v2)

Two fields appear only when a theme ships a `manifest.json` (see `${CLAUDE_PLUGIN_ROOT}/references/theme-manifest.md`):

| Field | When present | Shape |
|-------|--------------|-------|
| `tiers` | manifest.json exists and validates | object with absolute resolved paths for each declared tier — `tokens`, `assets`, `components.{web,deck,dashboard}`, `templates.{deck,report,landing,dashboard}`, `showcase`. Keys mirror what the manifest declared, no more. |
| `manifest_error` | manifest.json exists but failed validation | string with the validator's error message. The theme still appears in the output as a tier-0 fallback, so a broken manifest never makes a theme disappear. |

Tier-0 themes with no `manifest.json` emit neither field. Pass `--no-include-tiers` to suppress both globally regardless of manifest state.

The three-field return contract is deliberately narrower than this: Operation 11 returns `theme_path`, `theme_name` and `theme_slug` and never a `tiers` map. A consumer that needs tiers probes the theme directory itself.

## Auto-discovery and stale path handling

The discovery script detects when `COGNI_WORKSPACE_ROOT` is empty, missing, or stale — for example pointing at a previous Cowork session path under `/sessions/`. When that happens it searches for `.workspace-config.json` in three locations, in order:

1. `$PROJECT_AGENTS_OPS_ROOT`, if set and valid
2. `~/Library/CloudStorage/*/*/` — macOS cloud storage (OneDrive, iCloud, Dropbox)
3. `~/*/` — direct home subdirectories

It picks the most recently modified workspace and scans that workspace's `cogni-workspace/themes/` directory. Auto-discovery reports on stderr, never on stdout, so the JSON on stdout stays parseable:

```
WARNING: workspace root not found: /sessions/gallant-vibrant-cori/mnt/TSC/cogni-workspace
HINT: path looks like a stale Cowork session. Auto-discovering...
AUTO-DISCOVERED workspace themes: /Users/.../TSC/cogni-workspace/themes
```

To disable auto-discovery — in CI, or any hermetic run — pass `--no-discover`. To override the workspace root explicitly:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/discover-themes.py" --workspace-root "/path/to/workspace"
```

## Fallback behaviour

**No themes found at all**, in neither root:

1. Tell the user: "No themes found. Would you like to create one, or continue with default styling?" Creating one is Operation 5.
2. If they continue without a theme, return an empty `theme_path` — the downstream skill uses its own hardcoded fallback.

**The discovery script itself fails** — python3 missing, permission denied:

1. Fall back to manual Glob scanning with the `path` parameter set to each base directory:
   - Standard themes: pattern `*/theme.md`, path `$CLAUDE_PLUGIN_ROOT/themes`
   - Workspace themes: pattern `*/theme.md`, path `$COGNI_WORKSPACE_ROOT/themes`
2. Parse theme names from the H1 line of each file.
3. Present them through AskUserQuestion as usual.

The manual fallback loses the relevance sort and both optional fields. Say so rather than presenting a degraded list as if it were the normal one.

**AskUserQuestion is unavailable** — a headless or non-interactive run: take the first entry of the discovery output. The script pre-sorts by relevance, so the first entry is the best default candidate. Name the theme that was auto-selected in the reply.
