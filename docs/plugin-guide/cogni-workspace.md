# cogni-workspace

**Plugin guide** — for canonical positioning see the [cogni-workspace README](../../cogni-workspace/README.md).

---

## Overview

cogni-workspace is the horizontal layer of the insight-wave ecosystem — it owns the shared workspace state that the vertical business plugins consume. Before any other cogni-x plugin can run reliably, it needs: a place to find the workspace root, environment variables pointing to shared resources, a theme directory, and knowledge of which other plugins are installed. cogni-workspace provides all of this through a single initialization command and a set of management skills.

In practice, most users interact with cogni-workspace twice: once when setting up a new workspace (`manage-workspace`), and occasionally when something drifts out of sync (`workspace-status`, `manage-workspace`). Theme management and Obsidian integration are optional — use them if you want visual consistency across plugin outputs or a terminal-integrated note-taking environment.

The plugin imposes no data model on the workspace. It writes three files during initialization — `.workspace-config.json`, `.workspace-env.sh`, and `.claude/settings.local.json` — and then stays out of the way.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Workspace** | A project directory initialized with cogni-workspace — has `.workspace-config.json` and the shared env file |
| **Plugin discovery** | The process of scanning the marketplace cache for installed cogni-x plugins and registering them in the workspace config |
| **Theme** | A markdown file containing color palettes, typography, and design principles, stored in `cogni-workspace/themes/` |
| **Theme picker** | Operation 11 (Select Theme) of the `manage-themes` skill — the single entry point for theme selection used by all visual plugins |
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
7. Creates the `cogni-workspace/themes/` directory and installs the bundled `cogni-work` theme

After initialization, your workspace root contains:

```
.workspace-config.json     workspace metadata, plugin registry, language
.workspace-env.sh          environment variables sourced at session start
.claude/settings.local.json  Claude Code settings
cogni-workspace/themes/    shared theme storage
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

### `manage-themes` — Theme creation and management

Themes are markdown files that describe a visual identity — colors, typography, and design principles. Every rendering surface — this plugin's own render chain (`render-html-slides`, `/render-infographic`, `enrich-report`), cogni-website, and `document-skills` — reads from the same theme directory, so setting a theme here propagates to every plugin output.

Nine operations are available:

| Operation | What it does |
|-----------|-------------|
| `select theme` | Discovers themes across the bundled and workspace directories, presents an interactive picker, and returns the chosen theme's absolute path. This is the entry point every visual plugin calls |
| `recommend` | Suggests themes based on your industry or audience description |
| `list` | Shows all available themes in the workspace |
| `create from preset` | Starts from a preset the plugin ships — `cogni-work`, `boardroom`, `clean-slate`, `signal` or `editorial` — used as-is or forked into your workspace, or generates a new theme from colors, fonts and a description you supply |
| `audit` | Checks a theme for contrast ratios, color harmony, and completeness |
| `author deep theme system` | Deepens a theme into a tiered Theme System v2 directory (tokens, primitives, assets) |
| `generate showcase` | Renders a visual sample of how a theme looks applied to real content |
| `apply` | Reads a resolved theme and hands its contents to the downstream skill that produces the output |
| `import from Claude Design bundle` | Materialises a Claude Design handoff bundle into a complete tiered theme |

```
/manage-themes
```

```
Import the theme from this Claude Design bundle and apply it to the workspace
```

The `import from Claude Design bundle` operation is the recommended authoring path: the bundle is the upstream truth and the local theme directory is its materialised mirror. Re-running the importer against the *same* bundle URL is a no-op; a re-export produces a new URL and re-materialises the theme, which needs `--allow-overwrite`. The `audit` operation reads its contrast verdicts out of `check-contrast.py` rather than estimating them, so an accessibility finding is always a measured ratio.

The `select theme` operation is the one every other plugin reaches for. It scans both the plugin's bundled theme directory and your workspace themes directory, presents the available options, and returns the path to your selection — so no visual skill implements its own discovery logic. You can also call it directly when you want to choose a theme before starting a visual workflow.

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

### The bundled insight-wave wiki

A vendor-curated wiki ships bundled at `${CLAUDE_PLUGIN_ROOT}/wiki/`, covering plugins, skills, agents, architecture and cross-cutting conventions, plus the command cheatsheet, the plugin-selection guide and the workflow walkthroughs. Read it directly, starting from its index at `${CLAUDE_PLUGIN_ROOT}/wiki/wiki/index.md`; pages cite each other with `[[wikilinks]]` and each carries a `**Source**` line back to the canonical file on GitHub.

First lookup before grepping source files — faster and doesn't pull plugin internals into your context.

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

Deviation detection is LLM-based, so findings are assessments for the user to review, not definitive judgments. The user always has the final say on how a deviation is handled.

---

### `claim-entity` — The claim data model

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

### `text-to-narrative` — From text to an executive narrative and a Claude Design brief

The successor to the retired `narrative` skill (itself absorbed from the retired cogni-narrative plugin), to the retired `narrative-publish` pipeline, and to the retired `story-to-*` brief producers. Takes structured input — research syntheses, portfolio entities, plain markdown — and writes `insight-summary.md`: an arc-driven executive narrative with YAML frontmatter carrying `arc_id`, `arc_display_name` and element metadata, opening with an answer-first Executive TL;DR and running exactly four arc-element sections. It then adds a seventh phase that cuts the finished narrative into one `design-brief.md` for Claude Design.

Each arc is one contract file (`references/arc-{arc}.md`, bundled flat with the skill) that fixes its headings per language, its composition, its four elements and its own validation rules; the arc registry chooses between arcs and confirms the choice as a two-to-three arc shortlist; the universal gates live once in `references/validation.md`, with the deterministic half run by a script; and the language rules — English executive prose, German sentence craft — are loaded late, at the language pass. A Phase 0 execution brief (`--audience`, `--purpose`, `--perspective`, `--geography`) steers the drafting passes, and a banded release review reports `qa_verdict` in the result.

Fifteen arc frameworks are available, each a fixed sequence of four named elements with defined rhetorical intent:

| Arc | Element flow | Best for |
|-----|--------------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Sales, B2B market research |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation, R&D, technology trends |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry and regulatory analysis |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | TIPS trend-scout output (theme-less) |
| `smarter-service` | Forces → Impact → Horizons → Foundations | TIPS reports with investment themes |
| `theme-thesis` | Why Change → Why Now → Why You → Why Pay | Investment theme narratives |
| `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation | Portfolio introductions, pre-sales |
| `company-credo` | Mission → Conviction → Credibility → Promise | About-Us pages |
| `engagement-model` | Principles → Process → Partnership → Outcomes | How-We-Work pages |
| `consulting-problem-solving` | Situation → Complication → Resolution → Implications | Diagnostic memos, problem-solving reports |
| `strategic-choice` | Context → Tension → Options → Choice | Make/buy/partner, market entry, sequencing |
| `customer-transformation` | Before → Struggle → Change → Outcome | Case studies, reference stories |
| `category-creation` | Status Quo → Shift → New Frame → Leadership | Market reframes, category design |

The skill analyses the input's structure and proposes a best-fit arc; `--arc-id {arc-id}` overrides it. Target length defaults to ~1,675 words, with section proportions preserved rather than sections cut. A single source file whose frontmatter already carries `arc_id` and `word_count` is a finished narrative: the drafting phases are skipped and only the brief is built from it.

The `--format` derivative mode the `narrative` skill carried — executive brief, talking points, one-pager — retired with it and has no successor; its trigger phrases are ledgered in `references/retired-trigger-phrases.tsv`. The `narrative-writer` and `narrative-adapter` agents and the `/narrative`, `/narrative-adapt` and `/narrative-publish` commands retired at the same time.

The pipeline — execution brief, citation bridge, arc selection from the registry, the arc contract, four drafting passes, deterministic and judged validation — runs from the skill's own bundled, flattened copy of every narrative asset, so it needs no other plugin installed (its one cross-skill call is the copywriter's readability script). Phase 7 then cuts the finished narrative into one `design-brief.md` for a Claude Design generator named by `--target` — `slides` (default), `document`, `infographic` or `web`.

The brief is self-contained. It carries the units cut to the target's density ceilings (every ceiling is stated once in `references/density-ceilings.md` and written into the brief's own frontmatter), the five-clause Rendering Contract in the brief's language, the presentation-intent layer (`design`, `key_figures`, `climax`, four `note:` lines) and the narrative's Sources block verbatim, so citations resolve to URLs without a second file. Copy is frozen: every line is a verbatim selection from the narrative, never a rewrite, and `scripts/check-design-brief.py` grades the brief before the handoff — contract placement, unit numbering, every ceiling, every number against the narrative, every citation against Sources. A finished narrative can be passed as the source to build only the brief. The skill prints one attachment box for claude.ai/design; the organization design system applies, so a theme is attached only when none is configured.

Commands: `/text-to-narrative`.

### `copywriter` — Polish documents for executive readability

Absorbed from the retired cogni-copywriting plugin. Applies seven messaging frameworks — BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid — plus persuasion techniques (number plays, power words, rhetorical devices) to memos, briefs, reports, proposals, one-pagers and blog posts.

Two modes matter beyond ordinary polish:

- **Arc-aware preservation.** When the document carries an `arc_id` in frontmatter, the polish strengthens writing *within* each arc element without altering the skeleton — the title, subtitle, four elements in sequence, and bridge section stay intact. The arc contract it polishes against is read at runtime from `skills/text-to-narrative/references/arc-{arc}.md` — headings, per-element techniques and validation — so every registered arc activates arc mode; `tests/test-arc-reference-sync.sh` pins that every upstream path the copywriter cites resolves.
- **Translate-then-polish.** A two-pass flow across seven languages (de/en/fr/it/pl/nl/es), every direction pivoting on English or German. Arc-element and bridge headings are *substituted* from the arc contract's `## Headings` rather than freely translated, for every language that contract carries — all seven for `corporate-visions` and `jtbd-portfolio`, EN and DE for the rest — and an arc with no column for the target language fails closed.

`copy-reader` reviews a document through five parallel stakeholder personas and synthesises their feedback.

Commands: `/copywrite`, `/review-doc`.

### The retired `story-to-*` brief producers

`story-to-slides`, `story-to-web` (with its `mode=storyboard` printed-poster mode) and `story-to-infographic` — absorbed from the retired cogni-visual plugin — turned an arc narrative into a `presentation-brief.md`, `web-brief.md`, `storyboard-brief.md` or `infographic-brief.md` for the renderers below, each graded in-pipeline by the `brief-review-assessor` agent. They and their four driver agents retired in favour of `text-to-narrative`, which hands one `design-brief.md` to Claude Design instead of producing a per-target brief for local rendering. The render chain survived that retirement unchanged and still consumes those brief shapes (`libraries/brief-pipeline.md` states them), but nothing in this plugin produces them from a narrative any more: an existing brief is hand-authored against the `libraries/` templates (`presentation-brief-template.md`, `web-section-architecture.md`, `infographic-brief-validation.md`) or supplied by a caller. Briefs carry no color fields — the theme is a render-time choice, read directly by the renderer.

### `render-html-slides` — Render a presentation brief as HTML slides

The no-PowerPoint rendering path for an existing `presentation-brief.md`. Turns the brief into a **self-contained HTML deck** — one file, themed from the workspace theme, with keyboard navigation, a speaker-notes toggle, and Mermaid diagram support. After the first render it opens an interactive refinement loop: a text-only correction is edited straight into the HTML, while a structural change re-renders just the affected slide instead of the whole deck.

Reach for this instead of the PPTX path when the deck will be presented from a browser, shared as a single file, or iterated on quickly. The `html-slides` agent wraps the same skill for autonomous callers. The PPTX path for the same brief is the `pptx` *agent*, which dispatches `anthropic-skills:pptx` (or `document-skills:pptx` from the marketplace) and then round-trips the deck against the brief with `brief-render-qa.py` so dropped text or speaker notes are reported rather than silently shipped; there is no `pptx` skill in this plugin.

### `/render-infographic` — Render an infographic brief

An existing `infographic-brief.md` — content blocks under strict word limits plus icon prompts — routes to one of two rendering families, picked by its `style_preset`:

- **Hand-drawn** — the `sketchnote` and `whiteboard` presets, rendered through `/render-infographic-handdrawn` into an `.excalidraw` scene.
- **Editorial** — the `economist`, `editorial`, `data-viz` and `corporate` presets, rendered through `/render-infographic-editorial` into a `.pen` file.

`/render-infographic` is the universal entry point: it reads the brief's `style_preset` and routes to the right family. One constraint to respect: both hand-drawn render agents share a single Excalidraw MCP canvas, so hand-drawn renders must be serialized and never dispatched in parallel. Pencil-rendered editorial briefs are file-backed and can run alongside one Excalidraw render safely.

The two remaining brief shapes render through agents rather than commands: the `web` agent renders an existing `web-brief.md` via Pencil MCP into a `.pen` file and exports a self-contained HTML page from it, and the `storyboard` agent renders an existing `storyboard-brief.md` into a multi-poster `.pen` file for print.

### `enrich-report` — Turn a finished report into a visual deliverable

Absorbed from the retired cogni-visual plugin. Post-processes an *already-written* markdown report into a self-contained themed HTML rendition — it never authors a new report from scratch, never creates slides, and never rewrites prose (that is `copywriter`). The layout follows the consulting-deliverable pattern: the report's executive summary, then a full-width editorial infographic distilled from the whole report, then the report body with sidebar navigation and sparse inline Chart.js charts and SVG concept diagrams. The infographic is where the data visualization concentrates; the body stays prose unless a visual genuinely aids a specific passage.

One run always produces both HTML layouts: a scroll version at `{source_dir}/output/{stem}-enriched.html` and a paginated flipbook alongside it as `{stem}-enriched-flipbook.html`. On request via `formats`, PDF is derived from that HTML while DOCX is converted from the original markdown to keep the document structure clean. The source markdown is never touched, and a validation gate enforces preservation — the HTML must retain at least 80% of the source word count, with H2 and citation counts matching.

Commands: `/enrich-report`.

---

## Integration Points

### Upstream — cogni-workspace requires no other plugin

cogni-workspace has no required plugin dependencies. Its scope is horizontal: the vertical business plugins consume the shared state it owns, while each keeps its own project lifecycle.

### Downstream — every visual and content plugin uses the workspace

| Plugin / skill | What it reads from the workspace |
|---------------|----------------------------------|
| All cogni-x plugins | `.workspace-env.sh` — sourced at session start via the hook |
| cogni-website | Themes via `manage-themes` Operation 11; `design-variables.json` derived from the picked theme |
| document-skills | Themes via `manage-themes` Operation 11 |
| cogni-consult | `discover-plugins.sh` results — to know which plugins are available for dispatch |

---

## Common Workflows

### Workflow 1: Set up a brand-new workspace

1. Install insight-wave plugins from the marketplace
2. Run `/manage-workspace` in your project directory — answer the language and integration questions
3. Run `/workspace-status` to confirm every layer is green
4. Run `/manage-themes` to import your Claude Design bundle or start from a preset
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
