# cogni-help

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The onboarding and navigation layer for the [insight-wave](https://github.com/cogni-work/insight-wave) ecosystem — the single entry point that makes 12 plugins with 70+ skills behave like one coherent system.

## Why this exists

| Problem | What happens | Impact |
|---------|-------------|--------|
| 12 plugins, no map | New users don't know which plugin handles their task | Trial-and-error onboarding — first productive use takes hours |
| Disconnected workflows | Research, narrative, visual, and sales plugins work together but no guide shows how | Users run one plugin well, miss the multi-plugin pipelines that deliver 10x value |
| Silent failures | A missing dependency or stale workspace breaks skills at runtime | Cryptic errors with no diagnostic path — users blame the plugin, not the config |
| No structured learning | Users learn by stumbling into slash commands | Shallow usage — power features go undiscovered |

A capable ecosystem nobody can navigate is a capability nobody uses — the cost of insight-wave's breadth is paid in every onboarding hour and every undiscovered pipeline.

## What it is

A meta-plugin for the insight-wave ecosystem, built on a workflow-tour curriculum keyed 1:1 to the canonical cross-plugin pipelines. While the other plugins produce content — research, narratives, portfolios, visuals — cogni-help is the layer that teaches you how to use them together and routes you to the right one. It owns no domain data; it indexes the ecosystem so the other twelve plugins read as a single system.

## What it does

1. **Teach** through 7 interactive workflow tours — adaptive pacing, hands-on exercises, quizzes, and progress tracking across the canonical end-to-end pipelines
2. **Guide** users to the right plugin — match natural-language task descriptions to capabilities across 12 plugins and 70+ skills
3. **Chain** plugins into pipelines — 7 cross-plugin workflow templates from install-to-infographic through full consulting engagements
4. **Diagnose** plugin problems — check integrity, dependencies, workspace health, and known issues before they surface as runtime failures
5. **Summarize** any plugin — generate one-screen quick-reference cheatsheets with commands, capabilities, and tips
6. **Generate** training decks — PPTX slide decks for curriculum overview or per-tour introductions
7. **File** GitHub issues — guided consultation to capture bugs, feature requests, and change requests against any ecosystem plugin

## What it means for you

- **Skip the memorization.** Describe your task in plain language and the guide skill routes it to the exact plugin and skill across 12 plugins and 70+ skills — first productive result in under 5 minutes.
- **Build real skills in 5–6 hours.** Complete all 7 workflow tours (~45–60 minutes each) with hands-on exercises that produce real output. Resume any tour mid-module — progress is tracked to the lesson.
- **Collapse multi-plugin work into 3–4 steps.** Run any of 7 workflow templates to chain plugins into repeatable pipelines — research-to-report in 3 steps, portfolio-to-pitch in 4.
- **Catch failures before they surface.** Run the 5-tier health check to surface missing dependencies, stale configs, and integrity issues before they become cryptic runtime errors.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/guide "I need to create a sales pitch"   # find the right plugin
/teach tour-install-to-infographic         # start the first-run capstone tour
/workflow research-to-report               # see a cross-plugin pipeline
/cheatsheet cogni-trends                   # quick reference for a plugin
/troubleshoot                              # run diagnostics
cogni-issues                               # file a bug or feature request (skill, no slash command)
/courses                                   # see course progress
```

Or describe what you want:

- "Which plugin should I use to verify claims?"
- "Teach me how to use insight-wave"
- "How do I go from research to a slide deck?"
- "Something is broken with cogni-portfolio"

## Try it

Don't know which plugin handles your task? Describe it in plain language:

> Run `/guide "I need to turn research into a slide deck"`

The guide skill matches your description against all 12 plugins and 70+ skills and routes you to the pipeline, e.g.:

```
research-to-report pipeline:
  cogni-knowledge  → research a topic into a wiki
  cogni-narrative  → compose the findings into a story
  cogni-visual     → render slides from the narrative
```

Then walk the matching tour hands-on:

> Run `/teach tour-research-to-report`

The tour runs ~45–60 minutes across five modules — Theory, Demo, Exercise, Quiz, Recap — and tracks your progress to the lesson, so you can stop and resume `/courses` later without losing your place. The exercise module has you run real commands against your own workspace, so you finish with a working artifact rather than just notes. If something breaks along the way, `/troubleshoot` checks plugin integrity and dependencies and points you at the fix.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `teach` | skill | Interactive workflow-tour delivery — 7 tours, adaptive pacing, progress tracking |
| `course-deck` | skill | Generate PPTX slide decks for curriculum overview or per-tour introductions |
| `guide` | skill | Help users find the right insight-wave plugin or skill for their task |
| `troubleshoot` | skill | Diagnose and fix common issues with insight-wave plugins |
| `workflow` | skill | Cross-plugin workflow templates for common multi-plugin pipelines |
| `cheatsheet` | skill | Generate quick-reference cards for any insight-wave plugin |
| `cogni-issues` | skill | File and track GitHub issues against insight-wave ecosystem plugins |
| `course-deck-generator` | agent (sonnet) | PPTX generation as delegated subprocess |
| `/teach` | command | Start or resume an interactive cogni-help workflow tour |
| `/courses` | command | List all cogni-help workflow tours with completion status |
| `/course-deck` | command | Generate a PPTX slide deck for the tour curriculum or a tour introduction |
| `/guide` | command | Find the right insight-wave plugin or skill for your task |
| `/troubleshoot` | command | Diagnose and fix issues with insight-wave plugins |
| `/workflow` | command | Show cross-plugin workflow templates for common multi-plugin pipelines |
| `/cheatsheet` | command | Generate a quick-reference card for any insight-wave plugin |
| `course-status.sh` | script | JSON tour progress check |
| `reset-progress.sh` | script | Reset tour progress |
| `health-check.sh` | script | JSON diagnostic output |

## Curriculum (teach skill)

| Tour ID | Title | Pipeline |
|---------|-------|----------|
| `tour-install-to-infographic` | Install-to-Infographic | cogni-workspace → themes → cogni-visual |
| `tour-research-to-report` | Research-to-Report | cogni-knowledge → cogni-narrative → cogni-visual |
| `tour-trends-to-solutions` | Trends-to-Solutions | cogni-trends → cogni-portfolio → cogni-marketing |
| `tour-content-pipeline` | Content-Pipeline | cogni-marketing → cogni-narrative → cogni-copywriting → cogni-visual |
| `tour-portfolio-to-pitch` | Portfolio-to-Pitch | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `tour-portfolio-to-website` | Portfolio-to-Website | cogni-portfolio → cogni-workspace → cogni-website |
| `tour-consulting-engagement` | Consulting-Engagement | cogni-consult (setup → scope → action fields → design-thinking → personas) |

Each tour is ~45–60 minutes with ~5 modules: Theory → Demo → Exercise → Quiz → Recap.

## Workflow Templates

| Workflow | Pipeline |
|----------|----------|
| `install-to-infographic` | cogni-workspace → cogni-workspace (themes) → cogni-visual |
| `research-to-report` | cogni-knowledge → cogni-narrative → cogni-visual |
| `trends-to-solutions` | cogni-trends → cogni-portfolio → cogni-marketing |
| `portfolio-to-pitch` | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `portfolio-to-website` | cogni-portfolio → cogni-workspace → cogni-website |
| `content-pipeline` | cogni-marketing → cogni-narrative → cogni-copywriting → cogni-visual |
| `consulting-engagement` | cogni-consult (setup → scope → action fields → design-thinking → personas) |
| `docs-pipeline` | cogni-docs: doc-start → audit → generate → sync → power → claude → hub → bridge |
| `full-onboarding` | cogni-workspace → cogni-help workflow tours |

## Data model

Tour progress is stored in `.claude/cogni-help.local.md` (YAML frontmatter).
Issue state is stored in `cogni-issues/issues.json` in the working directory.
Exercise artifacts are written to `_teacher-exercises/`.

## How it works

cogni-help is a thin index over the ecosystem rather than a content producer, so each skill resolves a different navigation question against the same shared map. `guide` reads a plugin-capability catalog and matches a natural-language task description to the plugin and skill that owns it — discovery comes first, because a user who picks the wrong plugin never reaches the pipeline that would have worked.

Once the right entry point is known, `workflow` and `teach` take over. `workflow` returns one of the cross-plugin templates — ordered plugin chains like research-to-report or portfolio-to-pitch — so the multi-plugin handoffs are explicit instead of rediscovered each time. `teach` walks the same chains interactively: each of the seven tours maps 1:1 to a workflow template and steps through Theory → Demo → Exercise → Quiz → Recap, persisting progress to `.claude/cogni-help.local.md` so a tour can be paused and resumed at the module it left off.

The remaining skills support that core loop. `troubleshoot` runs ahead of failure — it checks plugin integrity, dependencies, and workspace health (delegating infrastructure checks to cogni-workspace) so a missing dependency surfaces as a diagnostic rather than a cryptic runtime error. `cheatsheet` reads any plugin's metadata to render a one-screen reference, and `cogni-issues` files bugs and requests against the right ecosystem repo without leaving the session. Every dependency is soft: cogni-help runs without any specific plugin installed, and only the tours and workflows that walk a given plugin require it to be present.

## Architecture

```
cogni-help/
├── .claude-plugin/plugin.json    Plugin manifest (v0.0.10)
├── agents/                       1 delegation agent
│   └── course-deck-generator.md
├── skills/                       7 skills
│   ├── teach/                    Interactive workflow-tour delivery
│   ├── course-deck/              PPTX generation
│   ├── guide/                    Plugin discovery
│   ├── troubleshoot/             Diagnostics
│   ├── workflow/                 Pipeline templates
│   ├── cheatsheet/               Quick reference cards
│   └── cogni-issues/             GitHub issue management
├── commands/                     7 slash commands
│   ├── teach.md
│   ├── courses.md
│   ├── course-deck.md
│   ├── guide.md
│   ├── troubleshoot.md
│   ├── workflow.md
│   └── cheatsheet.md
└── scripts/                      3 utility scripts
    ├── course-status.sh
    ├── reset-progress.sh
    └── health-check.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-workspace | No | troubleshoot delegates to workspace-status for infrastructure health checks |
| All ecosystem plugins | No | Required for their respective tours but not for guide, troubleshoot, workflow, cheatsheet, or issues |

## Contributing

Contributions welcome — tour content, workflow templates, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/cogni-issues` (browser filing) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/cogni-issues` skill falls back to `gh` CLI — issue filing still works, but interactive browser-based filing is unavailable until the conflict is resolved.

## Custom development

Need a bespoke training curriculum for your team, a new workflow tour, or a plugin built for your stack? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation and onboarding for organizations adopting the insight-wave ecosystem.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
