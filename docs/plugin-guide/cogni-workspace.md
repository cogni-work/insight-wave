# cogni-workspace

**Plugin guide** — for canonical positioning see the [cogni-workspace README](../../cogni-workspace/README.md).

---

## Overview

cogni-workspace is the horizontal layer of the insight-wave ecosystem — it owns the shared workspace state that the vertical business plugins consume. Before any other cogni-x plugin can run reliably, it needs: a place to find the workspace root, environment variables pointing to shared resources, a readable location for saved themes, and knowledge of which other plugins are installed. cogni-workspace provides all of this through a single initialization command and a set of management skills. The theme lifecycle itself — authoring, import, validation, selection and token compilation — is owned by cogni-publishing; this plugin keeps a same-name route to it and reads saved user themes in place.

In practice, most users interact with cogni-workspace twice: once when setting up a new workspace (`manage-workspace`), and occasionally when something drifts out of sync (`workspace-status`, `manage-workspace`). The theme route and Obsidian integration are optional — use them if you want visual consistency across plugin outputs or a terminal-integrated note-taking environment.

The plugin imposes no data model on the workspace. It writes three files during initialization — `.workspace-config.json`, `.workspace-env.sh`, and `.claude/settings.local.json` — and then stays out of the way.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Workspace** | A project directory initialized with cogni-workspace — has `.workspace-config.json` and the shared env file |
| **Plugin discovery** | The process of scanning the marketplace cache for installed cogni-x plugins and registering them in the workspace config |
| **Theme** | A markdown file containing color palettes, typography, and design principles. Bundled themes ship with cogni-publishing; saved user themes stay readable in place under `cogni-workspace/themes/` |
| **Theme picker** | Operation 11 (Select Theme) of `cogni-publishing:manage-themes` — the single entry point for theme selection used by all visual plugins. This plugin's `manage-themes` is a same-name route to it |
| **Output style** | A language-neutral stance register shipped at the plugin root, discovered by Claude Code and selected in `/config` |
| **Session hook** | `on-session-start.sh` — sources the workspace environment and validates plugin availability each time a session opens |
| **Layered diagnostic** | The structure of `workspace-status` output: foundation → env vars → plugin registry → themes → dependencies → Python packages → MCP servers, then plugin-level faults |
| **Obsidian vault** | A `.obsidian/` configuration directory scaffolded by `manage-workspace` during initialization |
| **Claim** | A sourced assertion tracked for verification — carries the asserted text, its `source_url`, and `entity_ref` provenance pointing back to the plugin entity it came from |
| **Deviation** | A detected mismatch between a claim and what its cited source actually says, held for the user to review and resolve |

### Prerequisites

Before running `manage-workspace`, ensure these tools are installed:

| Dependency | Required | Purpose |
|-----------|----------|---------|
| `jq` | Yes | JSON processing in scripts |
| `python3` | Yes | Standard library only — no pip required |
| `bash 3.2+` | Yes | Script runtime |
| `curl` | Optional | Source fetching in some skills |
| `git` | Optional | Version tracking |
| `bc` | Optional | Arithmetic in diagnostic scripts |

---

## Getting Started

Initialize a new workspace:

```
Initialize a insight-wave workspace here
```

or:

```
/manage-workspace
```

What the initialization does:

1. Runs `check-dependencies.sh` and reports any missing required tools
2. Asks for your output language preference (English and German are common defaults; 16+ languages are supported — see [Supported markets & languages](../../cogni-workspace/README.md#supported-markets--languages)) and which tool integrations to enable
3. Discovers installed cogni-x plugins via `discover-plugins.sh`
4. Generates `.workspace-config.json` with plugin registry and metadata
5. Generates `.workspace-env.sh` with environment variables for each plugin
6. Generates `.claude/settings.local.json` with workspace-appropriate settings
7. Creates the `cogni-workspace/themes/` directory and seeds a theme template from cogni-publishing, fail-soft when that plugin is absent

After initialization, your workspace root contains:

```
.workspace-config.json     workspace metadata, plugin registry, language
.workspace-env.sh          environment variables sourced at session start
.claude/settings.local.json  Claude Code settings
cogni-workspace/themes/    saved user themes, read in place by cogni-publishing
```

---

## Capabilities

### `manage-workspace` — Initialize or update a workspace

A single command that auto-detects whether to initialize or update. If no `.workspace-config.json` exists, it runs the full initialization flow (dependency checks, plugin discovery, preference gathering, settings generation). If one exists, it runs the update flow (backup, re-scan plugins, refresh env vars) while preserving user customizations.

```
/manage-workspace
```

---

### `workspace-status` — Layered health diagnostic

Checks the workspace in layers and reports findings with actionable fixes:

1. **Foundation** — are the required files present and well-formed?
2. **Environment variables** — does `.workspace-env.sh` define the variables plugins expect?
3. **Plugin registry** — are registered plugins still installed at their expected paths?
4. **Themes** — is at least one theme available for visual plugins?
5. **Dependencies** — are `jq`, `python3`, and bash at the required versions?
6. **Optional Python packages** — is the shared venv provisioned with what dependent skills need?
7. **MCP servers** — are the servers plugins expect built, configured, and loaded in this session?
8. **Plugin-level faults** — plugin availability, skill-file integrity, cross-plugin dependencies, stale state

Run when something is not working and you are not sure whether it is a plugin issue or a workspace issue:

```
/workspace-status
```

```
What's the status of my workspace?
```

If the diagnostic finds issues, each finding comes with a specific fix. Infrastructure-level problems (env vars, settings) and plugin-level problems (broken skills, missing references) are both `workspace-status`'s — checks 1-6 cover the workspace, check 7 covers the plugins installed in it.

---

### `workspace-dashboard` — The workspace in a browser

Generates a self-contained HTML dashboard of the whole workspace configuration — installed plugins with their versions, resolved environment variables, registered themes, Obsidian integration state, and MCP server status — in one scrollable page. `workspace-status` answers "is anything broken?" on the terminal; this answers "what does my workspace actually look like?" in a form you can scan or hand to someone else.

```
/workspace-dashboard
```

### `manage-themes` — Compatibility route to the publishing theme lifecycle

**cogni-publishing owns the theme lifecycle.** It holds the only implementation: the bundled themes, and the discovery, selection, validation, token-compilation and import scripts behind them. This plugin's `manage-themes` is a same-name route — it passes the request and its arguments through to `cogni-publishing:manage-themes` unchanged and hands the `theme_path` / `theme_name` / `theme_slug` result straight back. It adds no theme behaviour of its own, and none may be added here.

```
/manage-themes
```

The route exists so callers written against the old name keep working through the declared migration window, which closes **2026-12-15**. Point new work at `cogni-publishing:manage-themes` directly — see the [migration guide](../publishing-migration.md). When cogni-publishing is not installed, the route fails with installation guidance rather than running a reduced workflow.

Your saved themes are unaffected by the ownership change: cogni-publishing reads them in place from your workspace themes directory, and nothing moves, rewrites or overwrites them. For what the operations do and how to author, import or audit a theme, read the capability where it lives — `cogni-publishing`'s own guide is the authority, and duplicating its operation table here is how the two drift apart.

---

### Obsidian Integration (via `manage-workspace`)

Obsidian vault setup and updates are handled as sub-steps of `manage-workspace`:

- **During initialization**: if you indicate Obsidian use, the skill scaffolds `.obsidian/` with a Terminal plugin, Tokyonight-themed terminal, and Claude Code launcher
- **During update**: if `.obsidian/` exists, the skill offers to refresh terminal profiles and launcher scripts without overwriting customizations, fixing common WSL issues

Prerequisites: Obsidian must be installed. The skill handles Terminal plugin installation automatically.

---

### `install-mcp` — MCP server installation

End-to-end MCP server installation for the ecosystem. Clones and builds git-based MCPs (Excalidraw, Pencil), detects native-app MCPs (browsermcp, claude-in-chrome), and writes the server into your own MCP config — `~/.claude.json` for Claude Code, `claude_desktop_config.json` for Claude Desktop — so rendering plugins find their tools without hand-edited JSON.

```
/install-mcp
```

Backs up the config before any write; rolls back in one command if an install breaks something. Usually invoked automatically by `manage-workspace` Step 5, but available standalone when you add a plugin that needs an MCP server.

---

### `cogni-issues` — File and track plugin issues on GitHub

Files bugs, feature requests, change requests and questions against any marketplace plugin through the authenticated GitHub CLI, and lists or inspects the issues already open. It deduplicates before filing — an incoming report is checked against open issues so the same defect does not get filed twice — and routes each issue to the repository that actually owns the named plugin.

```
/cogni-issues file a bug against cogni-portfolio: portfolio-scan drops the taxonomy
/cogni-issues list open issues for cogni-trends
```

Requires an authenticated `gh` CLI. Without it the skill reports the gap rather than failing silently.

---

### `manage-market-registry` — Canonical market registry

cogni-workspace owns the canonical market registry (`references/supported-markets-registry.json`) that every market-aware plugin reads through `scripts/get-market-config.py`. The full list of built-out markets, registered markets, and supported output languages lives in the [Supported markets & languages](../../cogni-workspace/README.md#supported-markets--languages) section of the cogni-workspace README — that is the single source of truth other plugin READMEs link to.

`manage-market-registry` owns both directions over that one registry. Its `status` sub-action is read-only: it reports coverage across research, trends and portfolio and audits per-plugin region-source overlays against the registry to catch orphan domains. Its `add` sub-action is the write path for scaffolding a new market.

```
/cogni-workspace:manage-market-registry status
/cogni-workspace:manage-market-registry add
```

---

### `claims` — Verify sourced claims against their cited sources

Claim verification is a cogni-workspace capability, not a separate plugin. The `claims` skill takes assertions that other plugins produced with a citation, fetches each cited source, and reports where the claim and the source disagree. It never generates claims itself — cogni-trends, cogni-portfolio, and cogni-knowledge submit them; this skill checks them.

Determine the operating mode from intent rather than asking the user to name one:

| Mode | What triggers it | What it does |
|------|-----------------|--------------|
| `submit` | A user or plugin provides new claims with sources | Adds claims to the registry for tracking |
| `verify` | "verify", "check", "re-check", or first run after submission | Fetches sources and compares each claim against them |
| `dashboard` | "show", "status", "what claims need attention" | Displays all claims grouped by status |
| `inspect` | "inspect", "what's wrong with", "explain this deviation" + a claim ID | Deep-dives one claim's evidence |
| `resolve` | "resolve", "fix", "correct" + a claim ID | Walks the user through resolving a deviation |
| `cobrowse` | "cobrowse", "recover sources", "let's look together" | Interactive cobrowsing to recover `source_unavailable` claims |

`dashboard` is the safe default when intent is ambiguous.

```
/claims
```

Two agents do the work. `claim-verifier` runs one dispatch per unique source URL, fetching the source and detecting five deviation types — `misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, and `source_contradiction` — with a severity per claim. `source-inspector` handles the cobrowse path, recovering claims whose source could not be fetched automatically.

Deviation detection is LLM-based, so findings are assessments for the user to review, not definitive judgments. The user always has the final say on how a deviation is handled. The same `claims` skill ships the data model in `references/schema.md` and the storage contract in `references/workspace-conventions.md`.

#### Data model and store

Claims move through a three-state lifecycle:

```
unverified ──> verified            (no deviations found)
unverified ──> deviated            (deviations detected)
unverified ──> source_unavailable  (source unreachable)
deviated   ──> resolved            (user resolves all deviations)
```

An unfetchable source yields `source_unavailable`, never `verified` — if a source cannot be read, the claim's accuracy is unknown, and recording it as verified would overstate what was checked.

The store lives under the working directory:

```
{working_dir}/cogni-claims/
├── claims.json          # Registry of all ClaimRecords
├── sources/{hash}.json  # Cached source content per URL
└── history/{id}.json    # Audit trail per claim
```

The directory keeps the name `cogni-claims/` because it holds accumulated per-project user state: renaming it would orphan every claim store already on disk. Read and write it under that name regardless of which plugin ships the skill.

### `text-to-narrative` — Compatibility route to the publishing editorial capability

**cogni-publishing owns narrative composition.** It holds the full implementation — the fifteen arc contracts, the arc registry, the language and validation references, the scripts, fixtures and evals. This plugin's `text-to-narrative` is a same-name route that passes the request and its arguments through unchanged; when cogni-publishing is absent it fails with installation guidance rather than running a reduced workflow.

What the capability does, in one paragraph so the route is legible: it takes structured input — research syntheses, portfolio entities, plain markdown — and writes an arc-driven executive narrative whose frontmatter carries `arc_id` and element metadata, opening answer-first and running four arc-element sections; a later phase freezes that narrative into a normalized brief, which the publishing chain then composes, renders to branded HTML or editable PPTX, and verifies. Claude Design remains an optional handoff rather than the render path. For the arc catalogue, the density ceilings and the brief grammar, read cogni-publishing's own guide — duplicating its tables here is how the two drift apart.

The route exists for the declared migration window, which closes **2026-12-15**; point new work at `cogni-publishing:text-to-narrative` and see the [migration guide](../publishing-migration.md).

Commands: `/text-to-narrative`.

### `copywriter` — Compatibility route to the publishing editorial capability

**cogni-publishing owns copywriting.** It holds the seven messaging frameworks, the arc-aware preservation mode, the seven-language translate-then-polish flow, the stakeholder personas and the readability scripts. This plugin's `copywriter` skill and `/copywrite` command pass the request and arguments through unchanged, and fail with installation guidance when cogni-publishing is absent.

The route exists for the declared migration window, which closes **2026-12-15**; point new work at `cogni-publishing:copywriter` and see the [migration guide](../publishing-migration.md).

Commands: `/copywrite`.

### Rendering

Rendering is owned by cogni-publishing and runs in Python 3 standard library only: `design-compose` binds a frozen normalized brief to the pattern library, `design-render` lays the result out and writes portable branded HTML or an editable PPTX deck, and `design-verify` independently grades the output against the frozen brief — copy, order and provenance preserved by digest. Claude Design remains an optional handoff for the brief, not the render path.

This plugin renders nothing. The local render chain it once carried — the HTML slide and report-enrichment skills, the infographic commands and the per-format renderer agents — retired by maintainer ruling once its `story-to-*` brief producers had gone and no in-repo producer remained. Six `libraries/` files survive because sibling plugins read them at run time: the arc taxonomy, the presentation-intent layer, and the web-section and infographic copy rules.


---

## Integration Points

### Upstream — cogni-workspace requires no other plugin

cogni-workspace has no required plugin dependencies. Its scope is horizontal: the vertical business plugins consume the shared state it owns, while each keeps its own project lifecycle.

### Downstream — every visual and content plugin uses the workspace

| Plugin / skill | What it reads from the workspace |
|---------------|----------------------------------|
| All cogni-x plugins | `.workspace-env.sh` — sourced at session start via the hook |
| cogni-website | Themes via `cogni-publishing:manage-themes` Operation 11; `design-variables.json` derived from the picked theme |
| document-skills | Themes via `cogni-publishing:manage-themes` Operation 11 |
| cogni-consult | `discover-plugins.sh` results — to know which plugins are available for dispatch |
| Market-aware plugins | `references/supported-markets-registry.json`, joined with per-plugin overlays by `scripts/get-market-config.py` |

---

## Common Workflows

### Workflow 1: Set up a brand-new workspace

1. Install insight-wave plugins from the marketplace
2. Run `/manage-workspace` in your project directory — answer the language and integration questions
3. Run `/workspace-status` to confirm every layer is green
4. Run `/manage-themes` — it routes to `cogni-publishing:manage-themes` — to import your Claude Design bundle or start from a preset
5. Obsidian integration is offered during `/manage-workspace` if you indicate Obsidian use

Total time: 10–15 minutes. After this, all installed plugins can resolve themes, env vars, and plugin paths without additional configuration.

For an end-to-end onboarding example that wires workspace into a full project, see [../workflows/portfolio-to-website.md](../workflows/portfolio-to-website.md) or [../workflows/consulting-engagement.md](../workflows/consulting-engagement.md).

### Workflow 2: Diagnose why a plugin cannot find its theme

1. Run `/workspace-status` — check the themes tier specifically
2. If themes tier fails: run `/manage-themes list` to see what themes are registered
3. If the theme directory is empty: run `/manage-themes` and create or install a theme
4. If the theme directory exists but the plugin still cannot find it: check that the plugin is reading `$COGNI_WORKSPACE_ROOT/themes/` (the env var should be set by `.workspace-env.sh`)
5. If the env var is missing: run `/manage-workspace` to refresh environment variables

### Workflow 3: Update the workspace after moving the project directory

When you move a workspace to a different path, absolute paths stored in `.workspace-env.sh` and `.claude/settings.local.json` become stale:

1. Run `/manage-workspace` from the new path — it re-scans for installed plugins and regenerates env vars
2. Run `/workspace-status` to confirm the workspace resolves correctly at the new path
3. If you use Obsidian, `/manage-workspace` will offer to fix terminal launcher paths during the update (especially important on WSL)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| A plugin cannot find `.workspace-env.sh` | The session hook did not run, or the workspace was not initialized | Run `/workspace-status`; if the foundation tier fails, re-run `/manage-workspace` |
| `jq: command not found` in script output | `jq` is not installed | Install via your package manager: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu) |
| Themes directory exists but visual plugin uses wrong colors | Plugin is reading a stale theme path | Run `/manage-themes` and use Operation 11 to re-select the theme; hand the returned path to the plugin |
| A workspace-infrastructure check passes but a plugin skill still fails | The failure is at plugin level, not workspace level | Run cogni-workspace's `/troubleshoot` for the plugin-level tier (check 7) |
| Obsidian terminal profile shows a doubled path (WSL) | WSL path duplication in the profile arguments | Run `/manage-workspace` — the update flow fixes doubled paths and stale args |
| `/manage-workspace` succeeds but a newly installed plugin is not discovered | The plugin was installed after initialization | Run `/manage-workspace` to re-scan and register the new plugin |
| German umlaut characters break workspace initialization | Shell locale not set for UTF-8 | Set `LANG=de_DE.UTF-8` before running init; the script includes umlaut support from v0.2+ |

---

## Known Issues

**Chrome native messaging host conflict (KI-001):** When both Claude Desktop (Cowork) and Claude Code are installed, the Chrome extension connects to one native host and ignores the other, causing browser automation tools to silently vanish. In this plugin that affects the `claims` skill's source cobrowsing (which falls back to web fetch only) and `cogni-issues` browser-based issue filing (which must use the `gh` CLI instead).

**Workaround:** Toggle native messaging host configs by renaming the `.json` file for the unused product in `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/` and restarting Chrome. See the [Known Issues Registry](../known-issues.md) for detailed steps.

---

## Extending This Plugin

cogni-workspace is a contribution-friendly surface for infrastructure improvements:

- **New theme templates** — the `themes/_template/` directory defines the canonical theme format; new presets or industry templates are additive and safe
- **Platform support** — `bash/portability-utils.sh` handles macOS, Linux, WSL, and Git Bash; if you have a platform that behaves differently, extending portability-utils is the right place
- **New diagnostic checks** — the layered structure in `workspace-status` can be extended with additional checks; a check should return a clear finding and a specific fix action
- **The output register** — `output-styles/` at the plugin root carries one register, discovered by Claude Code and selected in `/config`. It is never copied into a workspace; a copied style only appears in the picker and is never activated

See [CONTRIBUTING.md](../../cogni-workspace/CONTRIBUTING.md) for guidelines.
