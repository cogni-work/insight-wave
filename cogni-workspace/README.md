# cogni-workspace

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The horizontal layer of the [insight-wave](https://claude.ai/cowork) ecosystem — it owns the shared workspace state that the vertical business plugins consume (environment variables, the plugin registry, theme storage, MCP and tool configuration, the supported-markets registry), and it is the one you initialize first.

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

cogni-workspace is the ecosystem's infrastructure-as-plugin layer: a dedicated plugin whose sole job is to own the shared state every other plugin consumes — environment variables, the plugin registry, theme storage, and tool configuration. Its scope is horizontal: it owns the workspace state and tooling that no single business plugin should own, while each vertical plugin keeps its own project lifecycle and domain work. It is also the home of the canonical supported-markets registry that every market-aware plugin reads.

## What it does

1. **Manage workspace** — initialize or update a workspace with auto-detection, dependency checks, plugin discovery, preference gathering, settings generation, backup and rollback → `references/supported-markets-registry.json` → doc-generate, doc-power, doc-hub, doc-readme-root, doc-audit
2. **Manage themes** — select a theme (the single entry point every visual plugin calls); import a Claude Design bundle or create from presets; audit harmony and script-checked WCAG contrast; author tiered theme systems (tokens → assets → components → templates) per Theme System v2 (see [migration guide](docs/theme-system-v2-migration.md)); apply to downstream skills
3. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
4. **Diagnose** workspace health — eight checks reported as seven status rows (foundation, env vars, plugin registry, themes, dependencies, optional Python packages, MCP servers) plus a plugin-level tier
5. **Install MCP servers** — clone and build git-based MCP servers, detect native app MCPs, and write the server into your own MCP config (`~/.claude.json` for Claude Code, `claude_desktop_config.json` for Claude Desktop) so rendering plugins find their tools without manual JSON editing
6. **Obsidian integration** — scaffold `.obsidian/` vault or incrementally update terminal profiles, handled as sub-steps of manage-workspace
7. **Bundled reference wiki** — a vendor-curated insight-wave reference wiki ships at `wiki/`; read it directly, starting from its `wiki/index.md`, for grounded pages on plugins, skills, agents, architecture and conventions, plus the command cheatsheet (`ecosystem-command-reference`), the plugin-selection guide (`ecosystem-plugin-selection`) and the workflow walkthroughs (`workflow-*`)
8. **File and track issues** — `cogni-issues` uses the authenticated GitHub CLI to consult, deduplicate, create, list, and inspect plugin issues with atomic labels
9. **Troubleshoot plugin failures** — `workspace-status`'s plugin-level tier diagnoses plugin integrity, cross-plugin dependencies, stale state, and common setup errors; reachable through `/troubleshoot`
10. **Verify claims against their cited sources** — `claims` runs the six-mode claim-verification lifecycle (submit, verify, dashboard, inspect, resolve, cobrowse) that cogni-trends, cogni-portfolio, cogni-consult and cogni-knowledge submit sourced assertions to, and ships the cross-plugin data contract as reference material
11. **Polish documents for executive readability** — `copywriter` applies seven messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid) with arc-aware preservation and EN/DE-pivot translation across seven languages; `copy-reader` runs parallel stakeholder personas over a document
12. **Turn text into a narrative and a Claude Design brief in one run** — `text-to-narrative` runs the arc pipeline from its own bundled copy of the narrative assets, then cuts the narrative into one `design-brief.md` for slides, a document, an infographic or a web page: density-capped units, the Rendering Contract, the presentation-intent layer and the Sources block, with copy frozen from the narrative

## What it means for you

- **Set up a whole workspace in one command.** One `manage-workspace` run auto-detects mode, discovers plugins, and generates env vars, settings, and themes — replacing 20+ minutes of hand-scaffolding, and backing up first so a bad update rolls back in seconds.
- **Skip hand-editing MCP config entirely.** `install-mcp` clones, builds, and wires up git-based and native MCP servers and writes them into your own MCP config, for Claude Code or Claude Desktop — plugins find their tools without a single JSON edit.
- **Reskin everything from one file.** Slides, journey maps, web narratives, and dashboards across 5+ visual plugins inherit colors and fonts from one theme, so a rebrand is a single-file edit.
- **Catch drift before a skill breaks.** Layered health diagnostics surface missing deps, version mismatches and unloaded MCP servers as a clear report, not a cryptic mid-run failure.

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

**Managing markets.** The registry is the single source of truth, and `cogni-workspace:manage-market-registry` is the single entry point to it: `status` reports coverage across research, trends and portfolio plus any orphan overlay domain the registry does not carry, and `add` scaffolds a new market.

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
/manage-themes     # select, import, create, audit, or apply themes
/troubleshoot      # diagnose plugin and cross-plugin failures
/cogni-workspace:cogni-issues  # file or inspect GitHub issues
```

Or describe what you want:

- "Initialize a insight-wave workspace here"
- "What's the status of my workspace?"
- "Import the theme from this Claude Design bundle"
- "Update my workspace after installing new plugins"
- "Read the bundled wiki index at `wiki/index.md` and tell me which plugin generates IS/DOES/MEANS messaging"

## Try it

Initialize a workspace in the directory where your cogni-x plugins live:

> Run `/cogni-workspace:manage-workspace`

Claude checks dependencies, discovers your installed plugins, and asks for your output language and tool integrations. It then writes the workspace into the current directory:

```
.claude/settings.local.json   # env vars + plugin registry
.workspace-env.sh             # sourced by the session-start hook
.workspace-config.json        # discovered plugins, preferences
cogni-workspace/themes/_template/   # starting point for custom themes
```

Then confirm everything is wired up:

> Run `/cogni-workspace:workspace-status`

You'll get a seven-row report — foundation, env vars, plugin registry, themes, dependencies, optional Python packages, MCP servers — each marked OK or flagged, closing with the single next action to take. From here every cogni-x plugin reads its configuration from the workspace instead of asking you to set it up again. Re-run `manage-workspace` any time you install a new plugin and it updates the registry in place, so the rest of the ecosystem stays wired up without touching a single config file by hand.

## How it works

cogni-workspace runs as the first link in every ecosystem session. The session-start hook (`on-session-start.sh`) sources `.workspace-env.sh` and validates plugin availability before any other skill runs, so downstream plugins always open against a known-good environment rather than discovering a missing variable mid-task.

Setup itself is a single ordered pass. `manage-workspace` runs `check-dependencies.sh` first (you can't configure tools that aren't installed), then `discover-plugins.sh` scans the marketplace cache to learn which cogni-x plugins are present and what env var names they expect. With the inventory known, `generate-settings.sh` writes the settings files, `install-mcp` clones and wires any MCP servers the discovered plugins need, and the Obsidian and theme steps follow. Each step backs up before it writes, so an interrupted or bad run is recoverable.

State lives in two layers that other plugins consume. Configuration (env vars, the plugin registry, themes) is read at runtime — `manage-themes` Operation 11 is the single entry point visual plugins call for theme paths, and `get-market-config.py` merges the canonical supported-markets registry with each plugin's overlay so market data is never duplicated. Health is verified on demand: `workspace-status` re-runs its layered check (foundation, env vars, plugin registry, themes, dependencies, optional Python packages, MCP servers) so drift is located before a skill trips over it, not after. The ordering throughout is deliberate — discover before configure, configure before wire, back up before write.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `manage-workspace` | skill | Initialize or update workspace — auto-detects mode, dependencies, discovery, preferences, settings, themes, backup and rollback |
| `manage-themes` | skill | 9 theme operations: select (the centralized picker every visual plugin calls), recommend, list, create from preset, audit (script-checked WCAG contrast), author deep theme system, generate showcase, apply, import from Claude Design bundle |
| `workspace-status` | skill | Layered diagnostic: foundation, env vars, plugin registry, themes, dependencies, Python packages, MCP servers, plus plugin-level faults |
| `install-mcp` | skill | End-to-end MCP server installation — clone and build git-based MCPs, configure native app MCPs, and write the server into the user's own config (`~/.claude.json` or `claude_desktop_config.json`) |
| `manage-market-registry` | skill | Single entry point for the canonical supported-markets registry — coverage and orphan-domain status across research/trends/portfolio, and adding markets (codes, locales, authorities) |
| `workspace-dashboard` | skill | Interactive HTML dashboard of workspace foundation, env vars, plugin registry, themes, and dependencies |
| `cogni-issues` | skill | File, deduplicate, list, and inspect plugin issues through the authenticated GitHub CLI |
| `claims` | skill | Six-mode claim-verification lifecycle — submit, verify, dashboard, inspect, resolve, cobrowse |
| `claim-verifier` | agent | Fetches one source URL and verifies every claim against it, returning deviation analysis as strict JSON |
| `source-inspector` | agent | Opens a source URL via claude-in-chrome and walks the user to the relevant passage (cobrowse / inspect) |
| `text-to-narrative` | skill | Turn text into an arc-driven narrative from a bundled, flattened copy of the narrative assets, then into one Claude Design brief for slides, document, infographic or web — density-capped, contract-bearing, copy frozen; `scripts/check-design-brief.py` grades the brief |
| `copywriter` | skill | Polish, rewrite or create business documents with 7 messaging frameworks, arc-aware preservation, and EN/DE-pivot translation |
| `copy-reader` | skill | Review a document through parallel stakeholder persona Q&A, then synthesize the feedback |
| `copywriter` | agent | Delegation wrapper for the `copywriter` skill |
| `reader` | agent | Delegation wrapper for the `copy-reader` skill |
| `commands/claims.md` | command | Registers `/claims` as the entry point to the verification lifecycle |
| `commands/text-to-narrative.md` | command | Registers `/text-to-narrative`, text to narrative to Claude Design brief |
| `commands/copywrite.md` | command | Registers `/copywrite`, with `/review-doc` alongside it |
| `commands/troubleshoot.md` | command | Registers `/troubleshoot` as the diagnostic entry point |
| `claims-store.sh` | script | JSON state manager for the claim store, shipped with the `claims` skill (`skills/claims/scripts/`) |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `on-session-start-language.sh` | hook (SessionStart) | Injects the language rules the built-in "# Language" system-prompt section does not carry |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `check-skill-names.sh` | script | Validates skill directory names against plugin.json manifest for consistency |
| `check-workspace-python-deps.sh` | script | Fail-soft health check for optional Python packages in the workspace venv; reports per-package importability (`success` stays true) |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; `--update` preserves custom env vars and prunes the ones it generated for plugins no longer in the list |
| `install-mcp.sh` | script | Installs a git-based MCP server into `~/.claude/mcp-servers/` (clone, build, wrapper); outputs JSON with install and wrapper paths |
| `install-workspace-deps.sh` | script | Provisions optional Python packages from `python-deps-registry.json` into an isolated venv at `~/.claude/workspace-python-venv/`; idempotent, `--force` reinstalls, JSON envelope |
| `patch-desktop-config.py` | script | Merges git-installed MCP servers into the user's Claude Code (`~/.claude.json`) or Claude Desktop config from `mcp-git-registry.json`, preserving existing entries |
| `setup-obsidian.sh` | script | Copies vault templates, downloads Terminal plugin, substitutes path placeholders |
| `update-obsidian.sh` | script | Merges profiles, fixes WSL paths, removes deprecated profiles, copies scripts |
| `portability-utils.sh` | script | Cross-platform utilities (macOS, Linux, WSL, Git Bash) |
| `load-theme-component.py` | script | Load a tiered theme component for a downstream renderer (see `references/theme-component-loader.md`) |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       Workspace, claims, copywriting and narrative skills
│   ├── claims/                   Claim lifecycle + references/schema.md and workspace-conventions.md
│   ├── cogni-issues/             File and track plugin issues through the GitHub CLI
│   ├── install-mcp/              MCP server installation and user-config patching
│   ├── manage-market-registry/   Read and write path for the canonical supported-markets registry
│   ├── manage-themes/
│   ├── manage-workspace/         Init or update workspace (includes Obsidian integration)
│   ├── text-to-narrative/        Text -> arc narrative -> design-brief.md for Claude Design (bundled arcs, flat)
│   ├── workspace-dashboard/      Interactive HTML workspace status dashboard
│   └── workspace-status/
│                                  copywriter,
│                                  copy-reader is omitted here for brevity
├── agents/                       Subagents for claim verification and copywriting
│   ├── claim-verifier.md         Verify claims against one source URL (JSON out)
│   ├── source-inspector.md       Open a source via claude-in-chrome for cobrowse/inspect
│   ├── copywriter.md             Delegation wrapper for the copywriter skill
│   └── reader.md                 Delegation wrapper for the copy-reader skill
├── libraries/                    Six files read at run time by text-to-narrative and sibling plugins: arc taxonomy, presentation intent, web section and infographic copy rules
├── commands/                     Slash commands
│   ├── claims.md                 Registers /claims
│   ├── text-to-narrative.md      Registers /text-to-narrative
│   ├── copywrite.md              Registers /copywrite and /review-doc
│   └── troubleshoot.md           Registers /troubleshoot
├── wiki/                         Bundled vendor-curated insight-wave reference wiki (read directly; start at wiki/index.md)
│   ├── .cogni-wiki/              Wiki config + lockfile
│   ├── SCHEMA.md                 Wiki page schema
│   └── wiki/                     LLM-maintained pages, index, log, overview
├── templates/                    Shared templates
│   ├── obsidian/                 Obsidian vault config templates
│   └── mcp-wrappers/             Wrapper scripts for git-based MCP servers
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   ├── on-session-start.sh       One-line workspace status
│   └── on-session-start-language.sh  Language rules the built-in "# Language"
│                                 system-prompt section does not carry
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── check-skill-names.sh
│   ├── check-workspace-python-deps.sh  Health check for optional Python packages
│   ├── discover-plugins.sh
│   ├── generate-settings.sh
│   ├── check-market-orphans.py   Report overlay domains the canonical market registry does not carry
│   ├── get-market-config.py      Merge canonical market registry with plugin overlays
│   ├── install-mcp.sh            Clone, build, and wrap git-based MCP servers
│   ├── install-workspace-deps.sh Provision optional Python deps into an isolated venv
│   ├── patch-desktop-config.py   Merge MCP entries into the user's MCP config
│   ├── setup-obsidian.sh
│   ├── update-obsidian.sh
│   └── baselines/                Tier-0 output baselines for script contract checks
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
├── tests/                        Script unit tests (check-skill-names, sanitize-theme)
├── docs/                         Developer notes (e.g. theme-system v2 migration)
└── output-styles/                Workspace Advisor register, discovered in /config
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-website | No | Referenced in manage-workspace and workspace-status for website-related workspace configuration |
| cogni-portfolio | No | install-mcp references cogni-portfolio as a consumer of excalidraw MCP in the installation plan |
| claude-in-chrome | No | The `claims` skill's cobrowse mode and `workspace-status`' MCP health check use the Chrome extension; claim verification degrades to WebFetch without it |
| cogni-trends | No | manage-market-registry reads the trends region-authority overlay when reporting market coverage and orphan domains |
| cogni-knowledge | No | Named as the consumer of `pypdf` in cogni-workspace's own `references/python-deps-registry.json`, which manage-workspace provisions into the shared venv and workspace-status reports on |

## Contributing

Contributions welcome — theme templates, platform support, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/claims` (cobrowse), `/cogni-issues` (browser filing) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. `/claims` cobrowse verification falls back to web fetch, and `/cogni-issues` browser filing falls back to the `gh` CLI, until the conflict is resolved.

## Custom development

Need bespoke workspace configurations, custom theme infrastructure, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation for teams — or reach out directly at [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
