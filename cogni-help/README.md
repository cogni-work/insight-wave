# cogni-help

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

cogni-help unifies the [insight-wave](https://github.com/cogni-work/insight-wave) ecosystem into a single entry point — teaching users through a 12-course curriculum, routing tasks to the right plugin, chaining multi-plugin workflows, diagnosing problems, generating one-screen cheatsheets, and filing GitHub issues straight from the session — so 12 plugins with 70+ skills behave like one coherent system.

## Why this exists

| Problem | What happens | Impact |
|---------|-------------|--------|
| 12 plugins, no map | New users don't know which plugin handles their task | Trial-and-error onboarding — first productive use takes hours |
| Disconnected workflows | Research, narrative, visual, and sales plugins work together but no guide shows how | Users run one plugin well, miss the multi-plugin pipelines that deliver 10x value |
| Silent failures | A missing dependency or stale workspace breaks skills at runtime | Cryptic errors with no diagnostic path — users blame the plugin, not the config |
| No structured learning | Users learn by stumbling into slash commands | Shallow usage — power features go undiscovered |

## What it is

A meta-plugin for the insight-wave ecosystem. While other plugins produce content — research, narratives, portfolios, visuals — cogni-help teaches you how to use them together. A 12-course curriculum covers every plugin from fundamentals through advanced workflows. Six cross-plugin workflow templates chain plugins into end-to-end pipelines. Diagnostics catch configuration issues before they surface as skill failures.

## What it does

1. **Teach** through 12 interactive courses — adaptive pacing, hands-on exercises, quizzes, and progress tracking across the full plugin ecosystem
2. **Guide** users to the right plugin — match natural-language task descriptions to capabilities across 12 plugins and 70+ skills
3. **Chain** plugins into pipelines — 6 cross-plugin workflow templates from research-to-slides through full consulting engagements
4. **Diagnose** plugin problems — check integrity, dependencies, workspace health, and known issues before they surface as runtime failures
5. **Summarize** any plugin — generate one-screen quick-reference cheatsheets with commands, capabilities, and tips
6. **Generate** training decks — PPTX slide decks for curriculum overview or per-course introductions
7. **File** GitHub issues — guided consultation to capture bugs, feature requests, and change requests against any ecosystem plugin

## What it means for you

- **Skip the memorization.** Describe your task in plain language and the guide skill routes it to the exact plugin and skill across 12 plugins and 70+ skills — first productive result in under 5 minutes.
- **Build real skills in 9 hours.** Complete all 12 courses (~45 minutes each) with hands-on exercises that produce real output. Resume any course mid-module — progress is tracked to the lesson.
- **Collapse multi-plugin work into 3–4 steps.** Run any of 6 workflow templates to chain plugins into repeatable pipelines — research-to-slides in 3 steps, portfolio-to-pitch in 4.
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
/teach 1                                   # start Course 1: Cowork Fundamentals
/workflow research-to-slides               # see a cross-plugin pipeline
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

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `teach` | skill | Interactive course delivery — 12 courses, adaptive pacing, progress tracking |
| `course-deck` | skill | Generate PPTX slide decks for curriculum overview or per-course introductions |
| `guide` | skill | Help users find the right insight-wave plugin or skill for their task |
| `troubleshoot` | skill | Diagnose and fix common issues with insight-wave plugins |
| `workflow` | skill | Cross-plugin workflow templates for common multi-plugin pipelines |
| `cheatsheet` | skill | Generate quick-reference cards for any insight-wave plugin |
| `cogni-issues` | skill | File and track GitHub issues against insight-wave ecosystem plugins |
| `course-deck-generator` | agent (sonnet) | PPTX generation as delegated subprocess |
| `/teach` | command | Start or resume an interactive cogni-help course |
| `/courses` | command | List all available cogni-help courses with completion status |
| `/course-deck` | command | Generate a PPTX slide deck for course curriculum or course introduction |
| `/guide` | command | Find the right insight-wave plugin or skill for your task |
| `/troubleshoot` | command | Diagnose and fix issues with insight-wave plugins |
| `/workflow` | command | Show cross-plugin workflow templates for common multi-plugin pipelines |
| `/cheatsheet` | command | Generate a quick-reference card for any insight-wave plugin |
| `course-status.sh` | script | JSON progress check |
| `reset-progress.sh` | script | Reset course progress |
| `health-check.sh` | script | JSON diagnostic output |

## Curriculum (teach skill)

| # | Course | Plugins covered |
|---|--------|-----------------|
| 1 | Cowork Fundamentals | cogni-help (meta) |
| 2 | Workspace & Obsidian | cogni-workspace, cogni-help:cogni-issues |
| 3 | Basic Tools | cogni-copywriting, cogni-narrative, cogni-claims |
| 4 | Trend Scouting | cogni-trends (Part 1) |
| 5 | Trend Reporting | cogni-trends (Part 2) |
| 6 | Portfolio Messaging | cogni-consulting, cogni-portfolio |
| 7 | Visual Deliverables | cogni-visual |
| 8 | Research Reports | cogni-research |
| 9 | B2B Marketing | cogni-marketing |
| 10 | Sales Pitches | cogni-sales |
| 11 | Consulting Orchestration | cogni-consulting |
| 12 | Documentation Pipeline | cogni-docs |

Each course is ~45 minutes with ~5 modules: Theory → Demo → Exercise → Quiz → Recap.

## Workflow Templates

| Workflow | Pipeline |
|----------|----------|
| `research-to-slides` | cogni-research → cogni-narrative → cogni-visual |
| `trend-to-marketing` | cogni-trends → cogni-portfolio → cogni-marketing |
| `portfolio-to-pitch` | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `new-engagement` | cogni-consulting phases (Discover → Define → Develop → Deliver) |
| `docs-pipeline` | cogni-docs: doc-start → audit → generate → sync → power → claude → hub → bridge |
| `full-onboarding` | cogni-workspace → cogni-help courses 1-12 |

## Data model

Course progress is stored in `.claude/cogni-help.local.md` (YAML frontmatter).
Issue state is stored in `cogni-issues/issues.json` in the working directory.
Exercise artifacts are written to `_teacher-exercises/`.

## Architecture

```
cogni-help/
├── .claude-plugin/plugin.json    Plugin manifest (v0.0.5)
├── agents/                       1 delegation agent
│   └── course-deck-generator.md
├── skills/                       7 skills
│   ├── teach/                    Interactive course delivery
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
| All ecosystem plugins | No | Required for their respective courses but not for guide, troubleshoot, workflow, cheatsheet, or issues |

## Contributing

Contributions welcome — course content, workflow templates, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/cogni-issues` (browser filing) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/cogni-issues` skill falls back to `gh` CLI — issue filing still works, but interactive browser-based filing is unavailable until the conflict is resolved.

## Custom development

Need custom training courses or a new plugin? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
