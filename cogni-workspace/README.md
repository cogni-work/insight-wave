# cogni-workspace

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The foundation layer of the [insight-wave](https://claude.ai/cowork) ecosystem — the one plugin every other cogni-x plugin depends on, and the one you initialize first.

## Why this exists

Every insight-wave plugin needs the same workspace state — environment variables, themes, MCP tools, knowledge of its sibling plugins. With no shared owner for that state, each plugin reinvents it, and the seams show up at the worst time:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No shared config | Each plugin manages its own env vars and paths | The same path is defined three ways; one drifts and a skill reads the stale value |
| Theme fragmentation | Visual plugins each scan for themes independently | A slide deck and a dashboard render in different colors from the same project |
| Plugin drift | Nothing detects version mismatches or missing dependencies | A skill fails mid-run with a cryptic error instead of a clear "dependency missing" |
| Manual setup | Every new workspace is scaffolded by hand | 20+ minutes of boilerplate before the first real plugin runs |

The cost compounds with every plugin added and every workspace created: configuration work that should happen once is paid again and again, and the failures it causes surface as runtime errors no user can diagnose.

## What it is

cogni-workspace is the ecosystem's infrastructure-as-plugin layer: a dedicated plugin whose sole job is to own the shared state every other plugin consumes — environment variables, the plugin registry, theme storage, and tool configuration. It is the only plugin with no upward dependencies; every other cogni-x plugin depends on it, and none of them duplicate what it owns. It is also the home of the canonical supported-markets registry that every market-aware plugin reads.

## What it does

1. **Manage workspace** — initialize or update a workspace with auto-detection, dependency checks, plugin discovery, preference gathering, settings generation, backup and rollback → `references/supported-markets-registry.json` → doc-generate, doc-power, doc-hub, doc-readme-root, doc-audit
2. **Manage themes** — extract from websites (via Chrome), PPTX files, or presets; audit for contrast and harmony; author tiered theme systems (tokens → assets → components → templates) per Theme System v2 (see [migration guide](docs/theme-system-v2-migration.md)); apply to downstream skills
3. **Pick themes** — centralized theme picker used by all visual plugins
4. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
5. **Diagnose** workspace health — five-tier report (foundation, env vars, plugin registry, themes, dependencies)
6. **Install MCP servers** — clone and build git-based MCP servers, detect native app MCPs, and patch Claude Desktop config so rendering plugins find their tools without manual JSON editing
7. **Obsidian integration** — scaffold `.obsidian/` vault or incrementally update terminal profiles, handled as sub-steps of manage-workspace
8. **Ask the bundled wiki** — `ask` reads a vendor-curated insight-wave reference wiki bundled at `wiki/` (self-contained index-first grounded read) so users can ask grounded questions about plugins, skills, agents, architecture, and conventions without grepping source files

## What it means for you

- **Set up a whole workspace in one command.** One `manage-workspace` run auto-detects mode, discovers plugins, and generates env vars, settings, themes, and output styles — replacing 20+ minutes of hand-scaffolding, and backing up first so a bad update rolls back in seconds.
- **Skip hand-editing MCP config entirely.** `install-mcp` clones, builds, and wires up git-based and native MCP servers and patches Claude Desktop config — plugins find their tools without a single JSON edit.
- **Reskin everything from one file.** Slides, journey maps, web narratives, and dashboards across 5+ visual plugins inherit colors and fonts from one theme, so a rebrand is a single-file edit.
- **Catch drift before a skill breaks.** Five-tier health diagnostics surface missing deps and version mismatches as a clear report, not a cryptic mid-run failure.

## Supported markets & languages

cogni-workspace owns the **canonical market registry** (`references/supported-markets-registry.json`) that every market-aware plugin reads through `scripts/get-market-config.py`. The platform is **European-first and multilingual — not DACH-only.** This is the canonical statement other plugin READMEs link to.

**Built-out markets — bilingual research + curated authority sources.** Nine markets are wired end-to-end into the bilingual (local language + English) research and trend-discovery pipelines, each with curated institutional authority sources:

| Market | Language | Example authority sources |
|---|---|---|
| DACH / DE | German | Fraunhofer, Bitkom, VDMA, Destatis, Handelsblatt |
| FR | French | INRIA, CNRS, INSEE, Arcep, Les Echos |
| IT | Italian | CNR, ISTAT, AGCOM, Il Sole 24 Ore |
| ES | Spanish | CSIC, INE, CNMC, Expansión |
| NL | Dutch | TNO, CBS, ACM, FD |
| PL | Polish | PAN, GUS, UKE, Rzeczpospolita |
| UK · US | English | ONS, Ofcom · BLS, Census, NIST |

**Registered & pluggable markets — breadth.** Beyond the built-out set, **28 markets in total** are registered in the taxonomy and selectable per project: extended single-country (AT, CZ, SK, HU, RO, HR, GR, MK, MX, BR, CN, JP), composite regions (EU, Nordics, LATAM, NA, APAC, MEA), and Global. Many extended markets already carry registry authority domains; the composites and several extended markets are **registered and ready but not yet wired into the bilingual research/trends overlays** — they are the expansion frontier, not a built-out claim.

**Languages.** 16+ output languages with native UTF-8 encoding — German (ä/ö/ü/ß), French (é/è/ç), Italian (à/ò/ù), Polish (ą/ć/ę/ł/ż), Spanish (á/é/ñ), Dutch, Portuguese, Czech, Slovak, Hungarian, Romanian, Croatian, Greek, Macedonian, Chinese, Japanese, English — never ASCII substitutes — plus **bilingual (local + English) search** so research draws on local-language and international sources alike.

**Managing markets.** The registry is the single source of truth: add or update markets with `cogni-workspace:manage-markets`, and audit per-plugin source overlays for drift with `cogni-workspace:audit-region-sources`.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/manage-workspace  # initialize or update a workspace
/workspace-status  # check health
/pick-theme        # select a theme interactively
/manage-themes     # extract, create, audit, or apply themes
```

> **Note:** Issue filing (`/issues`) has moved to [cogni-help](../cogni-help).

Or describe what you want:

- "Initialize a insight-wave workspace here"
- "What's the status of my workspace?"
- "Extract a theme from this website"
- "Update my workspace after installing new plugins"
- "Ask the wiki: how does claims propagation work?"
- "Ask the wiki: which plugin generates IS/DOES/MEANS messaging?"

## Try it

Initialize a workspace in the directory where your cogni-x plugins live:

> Run `/cogni-workspace:manage-workspace`

Claude checks dependencies, discovers your installed plugins, and asks for your output language and tool integrations. It then writes the workspace into the current directory:

```
.claude/settings.local.json   # env vars + plugin registry
.workspace-env.sh             # sourced by the session-start hook
.workspace-config.json        # discovered plugins, preferences
.claude/output-styles/        # language-specific behavioral anchors
themes/                       # default cogni-work theme
```

Then confirm everything is wired up:

> Run `/cogni-workspace:workspace-status`

You'll get a five-tier report — foundation, env vars, plugin registry, themes, dependencies — each marked OK or flagged, with a clear pointer to the fix when something is off. From here every cogni-x plugin reads its configuration from the workspace instead of asking you to set it up again. Re-run `manage-workspace` any time you install a new plugin and it updates the registry in place, so the rest of the ecosystem stays wired up without touching a single config file by hand.

## How it works

cogni-workspace runs as the first link in every ecosystem session. The session-start hook (`on-session-start.sh`) sources `.workspace-env.sh` and validates plugin availability before any other skill runs, so downstream plugins always open against a known-good environment rather than discovering a missing variable mid-task.

Setup itself is a single ordered pass. `manage-workspace` runs `check-dependencies.sh` first (you can't configure tools that aren't installed), then `discover-plugins.sh` scans the marketplace cache to learn which cogni-x plugins are present and what env var names they expect. With the inventory known, `generate-settings.sh` writes the settings files, `install-mcp` clones and wires any MCP servers the discovered plugins need, and the Obsidian and theme steps follow. Each step backs up before it writes, so an interrupted or bad run is recoverable.

State lives in two layers that other plugins consume. Configuration (env vars, the plugin registry, themes) is read at runtime — `pick-theme` is the single entry point visual plugins call for theme paths, and `get-market-config.py` merges the canonical supported-markets registry with each plugin's overlay so market data is never duplicated. Health is verified on demand: `workspace-status` re-runs the five-tier check (foundation, env vars, plugin registry, themes, dependencies) so drift is located before a skill trips over it, not after. The ordering throughout is deliberate — discover before configure, configure before wire, back up before write.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `manage-workspace` | skill | Initialize or update workspace — auto-detects mode, dependencies, discovery, preferences, settings, themes, backup and rollback |
| `manage-themes` | skill | 9 theme operations: recommend, list, grab from website, grab from PPTX, create from preset, audit, author deep theme system, generate showcase, apply |
| `pick-theme` | skill | Centralized theme picker — discovers themes, presents interactive selection, returns path |
| `workspace-status` | skill | Five-tier diagnostic: foundation, env vars, plugin registry, themes, dependencies |
| `install-mcp` | skill | End-to-end MCP server installation — clone and build git-based MCPs, configure native app MCPs, and patch Claude Desktop config |
| `ask` | skill | Answer questions about the insight-wave ecosystem by reading the bundled wiki — grounded, cited, never from memory |
| `manage-markets` | skill | Write path for the canonical supported-markets registry — show status and add markets (codes, locales, authorities) |
| `audit-region-sources` | skill | Read-only sibling of manage-markets — audit per-plugin region-source overlays against the canonical registry for orphans and drift |
| `workspace-dashboard` | skill | Interactive HTML dashboard of workspace foundation, env vars, plugin registry, themes, and dependencies |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `check-skill-names.sh` | script | Validates skill directory names against plugin.json manifest for consistency |
| `check-workspace-python-deps.sh` | script | Fail-soft health check for optional Python packages in the workspace venv; reports per-package importability (`success` stays true) |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; supports `--update` to preserve custom env vars |
| `install-mcp.sh` | script | Installs a git-based MCP server into `~/.claude/mcp-servers/` (clone, build, wrapper); outputs JSON with install and wrapper paths |
| `install-workspace-deps.sh` | script | Provisions optional Python packages from `python-deps-registry.json` into an isolated venv at `~/.claude/workspace-python-venv/`; idempotent, `--force` reinstalls, JSON envelope |
| `patch-desktop-config.py` | script | Merges git-installed MCP servers into Claude Desktop's config from `mcp-git-registry.json`, preserving existing entries |
| `setup-obsidian.sh` | script | Copies vault templates, downloads Terminal plugin, substitutes path placeholders |
| `update-obsidian.sh` | script | Merges profiles, fixes WSL paths, removes deprecated profiles, copies scripts |
| `portability-utils.sh` | script | Cross-platform utilities (macOS, Linux, WSL, Git Bash) |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       9 workspace management skills
│   ├── ask/                      Query the bundled insight-wave wiki for grounded answers
│   ├── audit-region-sources/     Audit per-plugin region-source overlays against the registry
│   ├── install-mcp/              MCP server installation and Desktop config patching
│   ├── manage-markets/           Write path for the canonical supported-markets registry
│   ├── manage-workspace/         Init or update workspace (includes Obsidian integration)
│   ├── manage-themes/
│   ├── pick-theme/
│   ├── workspace-dashboard/      Interactive HTML workspace status dashboard
│   └── workspace-status/
├── wiki/                         Bundled vendor-curated insight-wave reference wiki (read by ask)
│   ├── .cogni-wiki/              Wiki config + lockfile
│   ├── raw/                      Immutable source snapshots (plugin READMEs, curation notes)
│   ├── assets/                   Attachments (SVG, images) referenced by wiki pages
│   └── wiki/                     LLM-maintained pages, index, log, overview
├── templates/                    Shared templates
│   ├── obsidian/                 Obsidian vault config templates
│   └── mcp-wrappers/             Wrapper scripts for git-based MCP servers
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   └── on-session-start.sh
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── check-skill-names.sh
│   ├── check-workspace-python-deps.sh  Health check for optional Python packages
│   ├── discover-plugins.sh
│   ├── generate-settings.sh
│   ├── get-market-config.py      Merge canonical market registry with plugin overlays
│   ├── install-mcp.sh            Clone, build, and wrap git-based MCP servers
│   ├── install-workspace-deps.sh Provision optional Python deps into an isolated venv
│   ├── patch-desktop-config.py   Merge MCP entries into Claude Desktop config
│   ├── setup-obsidian.sh
│   └── update-obsidian.sh
├── bash/                         Cross-platform utilities
│   └── portability-utils.sh
├── contracts/                    Script interface definitions
│   ├── setup-obsidian.yml
│   └── update-obsidian.yml
├── themes/                       Brand theme storage
│   ├── _template/                Canonical theme template
│   └── cogni-work/               Bundled brand theme + showcase
├── schemas/                      JSON schemas
│   └── examples/                 Schema usage examples
├── references/                   Reference documentation
├── docs/                         Developer notes (e.g. theme-system v2 migration)
└── assets/
    ├── claude-templates/         Language-specific CLAUDE.md templates (EN/DE)
    └── output-styles/            Language-specific behavioral anchors (EN/DE)
```

## Dependencies

cogni-workspace has no required plugin dependencies — it is the foundation layer that other plugins depend on.

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-visual | No | manage-themes passes color variables to cogni-visual renderers (render-big-picture, render-big-block) |
| cogni-website | No | Referenced in manage-workspace and workspace-status for website-related workspace configuration |
| cogni-help | No | Referenced inline in workspace skills for issue filing and guided help |
| cogni-portfolio | No | install-mcp references cogni-portfolio as a consumer of excalidraw MCP in the installation plan |
| cogni-claims | No | workspace-status references cogni-claims as a provider plugin for the claude-in-chrome MCP server check |

## Contributing

Contributions welcome — theme templates, platform support, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/manage-themes` (website extraction) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/manage-themes` skill's live website extraction mode falls back to manual theme specification until the conflict is resolved.

## Custom development

Need bespoke workspace configurations, custom theme infrastructure, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation for teams — or reach out directly at [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
