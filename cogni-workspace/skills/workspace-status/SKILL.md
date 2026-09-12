---
name: workspace-status
description: >-
  Diagnose the health of an insight-wave workspace and its installed plugins — one surface for
  both workspace infrastructure and plugin-level faults. Use this skill whenever the user
  mentions workspace status, health, or diagnostics — including "check workspace", "is my
  workspace ok", "diagnose workspace", "verify workspace" — or reports something broken at the
  plugin level: "something is wrong", "plugin error", "skill not responding", "fix my setup",
  or "why isn't X working". It covers workspace infrastructure (env vars, themes, settings, the
  plugin registry, MCP servers) and plugin-level and cross-plugin faults (plugin availability,
  skill-file integrity, cross-plugin dependencies, stale state left by retirements). It is also
  the cross-session re-entry point for the workspace itself: "workspace resume", "resume
  workspace", "where was I in the workspace". Trigger it even without an explicit request when
  the user describes symptoms of a misconfigured workspace or hits an unclear error during
  plugin use.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch
---

# Workspace Status

Diagnose the health of an insight-wave workspace and of the plugins installed in it — its foundation files, environment variables, plugin registry, themes, dependencies, MCP servers, and the plugin-level and cross-plugin faults that stop a skill working. This is the single diagnostic surface for both: there is no separate skill to route to. The goal is to give the user a clear picture of what's working and what needs attention, with actionable fixes for every issue found.

## Locating the Workspace

Find the workspace using this priority:
1. User-provided path
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

If no `.workspace-config.json` exists at the resolved path, stop and tell the user no workspace was found. Suggest they run `manage-workspace` to create one and explain briefly what a workspace provides (centralized config, plugin discovery, shared themes).

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Present findings, explanations, and fix
instructions in that language.

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names, command names, file paths
- Status values (`OK`, `WARN`, `FAIL`)
- Error messages, stack traces, code snippets
- Column headers in diagnostic tables
- The `Symptom` / `Cause` / `Fix` field labels themselves — the label stays fixed so
  the report shape is recognisable across languages; only its content is translated

## Reporting Findings

State what is wrong, why, and how to fix it, in the format Symptom → Cause → Fix,
one finding per block, using the same field labels
`${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/known-issues.md` uses so a catalogued fix and a fresh diagnosis read
identically:

**Symptom**: a cogni-marketing skill reports that portfolio data cannot be found.

**Cause**: cogni-marketing depends on cogni-portfolio, which has no entry in
`.claude-plugin/marketplace.json` for this workspace.

**Fix**: install cogni-portfolio from the marketplace, then re-run.

Keep the three labels even when a field is short — a finding with no known cause
says so under **Cause** rather than dropping the label, so every report has the
same three anchors to scan for.

The consolidated `## Status Report` below is the per-run summary; this shape is for
the individual findings that expand under it.

## Running the Checks

Run all eight checks, then present a single consolidated report. The checks are ordered by dependency — foundation must exist before environment makes sense, environment must be correct before plugins can be verified.

### 1. Foundation

These files form the workspace skeleton. Without them, other checks can't run reliably.

| File | Required | What it does |
|------|----------|--------------|
| `.workspace-config.json` | Yes | Stores workspace metadata — version, language, registered plugins, timestamps. All other checks read from this file. |
| `.claude/settings.local.json` | Yes | Environment variables that Claude Code auto-injects. Plugins use these to find each other's paths. |
| `.workspace-env.sh` | No | Same variables exported for non-Claude contexts (Obsidian Terminal, VS Code tasks, CI/CD). Missing means shell-based tooling won't resolve plugin paths. |

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

Run:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/inspect-themes.py --pretty
```

The script walks the merged theme set (`${CLAUDE_PLUGIN_ROOT}/themes/` and `${COGNI_WORKSPACE_ROOT}/themes/`, workspace shadowing standard) and returns one row per user-visible theme — `_template` and dot-prefixed entries are filtered. For each row, render:

- `tier` — `tier-0` or `tiered (<schema_version>)`
- `tiers_populated` — comma-joined dotted keys (`tokens, assets, components.web, components.deck`) or `(none)`
- `origin` — `claude-design @ <imported_at> (sha256 <prefix>…)` or `local-authored`
- The legacy `Color Palette ✓ / Typography ✓` line (the tier-0 floor — preserve verbatim, including when both signals are absent)

Then check that `${COGNI_WORKSPACE_ROOT}/themes/_template/` exists (needed to create new themes — render `_template/ ✓ present` on a single line under the per-theme rows).

**Strict mode.** When the user request mentions "strict", "deep", "before-PR", or "validate", append `--strict` to the `inspect-themes.py` call. Each tiered theme row then carries `validator: pass` or `validator: FAIL — <first error>` from `validate-theme-manifest.py`. Default invocation must not pass `--strict` (no subprocess fan-out across N themes).

Canonical tier vocabulary: `${CLAUDE_PLUGIN_ROOT}/references/theme-manifest.md`.

#### Theme drift (shadowed slugs)

The picker merges `${CLAUDE_PLUGIN_ROOT}/themes/` (standard, ships with the plugin) with `${COGNI_WORKSPACE_ROOT}/themes/` (user-owned), and workspace copies shadow standard copies when slugs collide. This shadowing is **intentional** — it enables user customisation. The drift advisories below are **informational, not errors**: the picker still resolves a valid theme either way.

The motivating example is `cogni-work`: the standard copy ships a tiered layout (manifest.json, tokens/, components/, `.claude-design-source` sidecar), while an older workspace copy predating tiered themes carries none of it. That older copy silently downgrades the experience, because the picker resolves the workspace copy first.

Run:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/check-theme-drift.py
```

The script compares the two locations and emits one row per shadowed slug. Slugs that exist on only one side are not reported (that's the normal case, not drift). Statuses:

| Standard | Workspace | Status | Surface text |
|---|---|---|---|
| tier-0 | tier-0, theme.md equal | `identical` | `identical` |
| tier-0 | tier-0, theme.md differs | `workspace_customised` | `workspace customised` |
| tiered | tier-0 | `upgrade_available` | `upgrade available — workspace copy is tier-0, standard is tiered` |
| tiered | tiered, manifest or tokens.css differs | `tier_drift` | `tier drift — standard manifest sha X, workspace sha Y` |
| tier-0 | tiered | `workspace_ahead` | `workspace ahead` |

When `.claude-design-source` sidecars differ in URL or sha256, the advisory appends `standard imported from bundle X; workspace imported from bundle Y`. A sidecar mismatch on otherwise-identical files promotes the row to `workspace_customised` so the divergence surfaces.

`identical` rows are not surfaced in the default report (they're not a problem). Detailed mode shows them.

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

### 5.5. Optional Python Packages

Some plugins ship pip-backed optional fallbacks provisioned by `manage-workspace`
into an isolated venv at `~/.claude/workspace-python-venv/` (e.g. cogni-knowledge's
`pypdf` text-layer PDF fallback). These are always optional — their absence limits
a specific feature, it never blocks core functionality.

Run:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-workspace-python-deps.sh
```

The script returns JSON with `data.venv_present`, a per-package `available` /
`version` / `required_by` list, and `missing_optional`. Report:
- **venv present + all packages importable** → OK.
- **packages missing (or venv absent)** → WARNING, never CRITICAL. Tell the user
  to run `/cogni-workspace:manage-workspace` (or `install-workspace-deps.sh`
  directly) to provision them, and name which feature is limited (from
  `required_by`).

`check-workspace-python-deps.sh` always returns `"success": true` (every package
is optional), so treat a non-empty `missing_optional` as an advisory, not a failure.

### 6. MCP Servers

MCP servers power visual rendering (Excalidraw, Pencil), browser automation (claude-in-chrome),
and other capabilities. No plugin declares an MCP server itself — `install-mcp` installs
each one on demand and writes it into the user's own config, so what is configured always
reflects what is actually installed. This check verifies that required MCPs are available
in the current session.

Read `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/mcp-registry.md` for the full
list of ecosystem MCPs and which plugins need them. Read
`${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json` for any server's `desktop_config_key`
and install metadata — look a server's key up there rather than assuming it.

**Detection approach**: Probe each known server's one representative tool with `ToolSearch`
using the `select:` prefix — a returned tool definition means the MCP is loaded, no match
means it is not available. The **Install** column decides how a missing server is reported:

| MCP Server | Probe tool | Needed by | Install |
|------------|-----------|-----------|---------|
| `excalidraw` | `mcp__excalidraw__describe_scene` | cogni-portfolio, cogni-workspace | install-mcp |
| `claude-in-chrome` | `mcp__claude-in-chrome__tabs_context_mcp` | cogni-website, cogni-workspace | manual (Chrome extension) |
| `pencil` | `mcp__pencil__get_editor_state` | cogni-website, cogni-workspace | manual (Pencil desktop app) — config entry still written by install-mcp; see the Manual bullet |

**Report format**:

- **Loaded**: The MCP tools are available in this session
- **Not loaded**: An `install-mcp` server that is needed but not available. `ToolSearch`
  alone cannot say why — it returns the same no-match in every case — and the install is
  two independent steps, so read two pieces of state before advising:
  - the **config entry** — the server's entry in the config of the host
    **this session runs in**
  - the **install directory** — the `start.sh` under the MCP server install base

  Which key names which artifact, the four-row install-state matrix that turns those two
  readings into advice, and why a restart on its own is rarely the whole answer are all in
  `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/mcp-registry.md` under
  "## Diagnosing a not-loaded install-mcp server" — the file this check already loads above
- **Manual**: The MCP is a manual install — the Claude-in-Chrome browser extension or the
  Pencil desktop app. Name what to fetch and inform the user, but don't flag as an error;
  a missing manual server is not the "Not loaded" case above. The two differ in one way that
  matters: `claude-in-chrome` has no registry entry and so no config entry at all, whereas
  `pencil` is a registry `native` server whose `pencil` config entry `install-mcp` still
  writes. So if Pencil is installed and running and its tools are still missing, check for the
  `pencil` key in the config of the host this session runs in — `~/.claude.json` under
  Claude Code, `claude_desktop_config.json` under Claude Desktop — and run
  `/cogni-workspace:install-mcp` for that target if it is absent, before telling the user to
  open the app

Only check MCPs for plugins that are actually installed (cross-reference with the plugin
registry from Check 3).

### 7. Plugin-Level Diagnostics

The plugin-level tier. Checks 1-6 establish that the workspace itself is sound;
this one establishes that the plugins installed in it are. Six probes, each
detailed in
`${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/plugin-diagnostics.md`:

| Probe | Establishes |
|-------|-------------|
| 7a Plugin availability | every marketplace entry has a source directory with a valid `plugin.json` |
| 7b Skill-file integrity | every `skills/*/SKILL.md` exists and its frontmatter parses |
| 7c Progress/state file health | `.claude/*.local.md` frontmatter is well-formed and not stale |
| 7d Cross-plugin dependencies | every plugin a plugin requires is present in the marketplace |
| 7e Stale state from retirements | no orphaned engagement or course-progress file lingers |
| 7f Common misconfigurations | recognition patterns routed to the known-issues catalogue |

Run the probes the user's symptom points at rather than all six every time — start
with the most likely cause and expand if needed. When no symptom narrows it — a bare
"check my workspace" — run 7a, 7b and 7d: they are the cheap roster-level probes whose
failures explain the widest range of later faults. When the request is a bare full
scan, run everything; see `## Full Scan Mode` below.

## Status Report

Present results as a compact summary. Use OK / WARNING / CRITICAL status per category:

```
Workspace Status: /path/to/workspace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Foundation:   OK       | 3/3 files present
Environment:  OK       | 12 vars set, 0 missing
Plugins:      OK       | 5 registered, 5 installed
Themes:       OK       | 3 themes available, 1 tiered, 0 drift advisories
Dependencies: OK       | 2/2 required, 3/3 optional
Python pkgs:  OK       | venv present, 1/1 optional importable
MCP Servers:  OK       | 3/3 loaded (2 manual)

Language: EN | Last updated: 2026-03-04
```

**Expand any category that isn't OK** with specifics and a fix:

```
Plugins:      WARNING  | 5 registered, 6 installed
  New: cogni-consult (installed but not registered)
  -> Run manage-workspace to register it

Environment:  WARNING  | 12 vars set, 2 broken
  Broken: COGNI_NARRATIVE_ROOT -> /path/does/not/exist
  Broken: COGNI_NARRATIVE_PLUGIN -> /path/does/not/exist
  -> Run manage-workspace to refresh environment variables (an update also
     removes generated vars for plugins no longer installed)

Themes:       WARNING  | 2 themes available, 1 tiered, 1 drift advisory
  cogni-work   workspace  tiered (1.0) | tokens, assets, components.web, components.deck
                          origin: claude-design @ 2026-05-18T09:35:13Z (sha256 b23aec46…)
                          Color Palette ✓ | Typography ✓
  _template/ ✓ present

  Drift: cogni-work — upgrade available — workspace copy is tier-0, standard is tiered
    standard imported from bundle https://api.anthropic.com/v1/design/h/X9LG…
  -> Run `manage-themes` to refresh the workspace copy (overwrites local edits)

MCP Servers:  WARNING  | 1/3 loaded (2 manual)
  excalidraw   built but not configured — start.sh present, no `excalidraw` key in this host's config (`~/.claude.json`, Claude Code)
    -> Run /cogni-workspace:install-mcp to write the config entry, then start a new session
  pencil       manual install — Pencil desktop app not running
    -> Open Pencil (https://pencil.dev); informational, not an error
```

Every issue should end with a concrete next step — either a skill to run (`manage-workspace`, `manage-themes`) or a command to execute.

### Close with one recommended action

The report orients; the recommendation commits. After the summary block, name **exactly one** next action and why it comes first — a single next step with its reason beats a list of options the user has to rank. Walk this ladder and stop at the first match:

| Condition | Recommend | Because |
|---|---|---|
| A required foundation file is missing | `manage-workspace` | Nothing else can be trusted until the workspace exists |
| A required dependency is missing (check 5) | Install it with the command that check named | Scripts cannot run at all, so every other finding below is unreliable |
| Registry and installed plugins disagree | `manage-workspace` | Env vars are generated from the registry, so every downstream path is suspect |
| An env var is missing, or set but pointing at a missing path | `manage-workspace` | Regenerating settings is the only supported repair |
| No themes are available | `manage-themes` | Visual output across every plugin falls back to defaults until one exists |
| A theme reports `upgrade_available` or `tier_drift` | `manage-themes` | Advisory, not an error — but it is the next thing worth doing |
| An optional Python package is missing (check 5.5) | `manage-workspace` | It provisions the shared venv; the dependent skill degrades until it does |
| An MCP server is built but not configured | `install-mcp` | One config write plus a new session clears it |
| A plugin-level fault was found in check 7 | The fix named in that finding | The finding already carries its own remedy |
| Everything is OK | Offer `workspace-dashboard` | Nothing needs fixing, so the useful next move is seeing the configuration |

The last row is reachable only when **every** check reported OK. If a check reports
CRITICAL or WARNING and no row above matches it, the ladder is out of date with the
checks — say so and recommend the remedy that check printed, rather than falling through
to `workspace-dashboard` while the summary block above shows a fault.

If the user arrived by asking to resume — "workspace resume", "where was I in the workspace" — lead with this recommendation and keep the summary block underneath it. If they asked for a diagnosis, keep the summary first and close with the recommendation.

## Full Scan Mode

When the user asks for a full diagnostic with no narrower target — including via the
`/troubleshoot` command, which enters here — run every check and present this summary
table alongside the status report above:

| Check | Status | Details |
|-------|--------|---------|
| Marketplace | OK/WARN/FAIL | N plugins registered |
| Plugin integrity | OK/WARN/FAIL | Any missing SKILL.md files |
| State files | OK/WARN/FAIL | Any corrupted or stale files |
| Cross-plugin dependencies | OK/WARN/FAIL | Any missing cross-plugin deps |
| Environment | OK/WARN/FAIL | N vars set, N broken, N missing |

Every row is a check this skill performs. Marketplace, plugin integrity, state files
and cross-plugin dependencies come from check 7's probes; the Environment row reports
check 2's result directly. The external-tool dependencies of check 5 are reported in
the status report above, not in this table — the two use the word "dependencies" for
different things.

## Quick vs Detailed Mode

- **Quick** (default): the compact summary above, expanding only categories with issues
- **Detailed**: expand all categories regardless of status — show every file path, every env var value, every theme name, every dependency version. Use this when the user explicitly asks for details, runs a diagnosis, or says something like "show me everything"

## Reference

- `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/plugin-diagnostics.md` — the procedures behind check 7's six probes
- `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/known-issues.md` — a maintained catalogue of known symptoms and their fixes
- `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/mcp-registry.md` — the ecosystem MCP list read by check 6

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
