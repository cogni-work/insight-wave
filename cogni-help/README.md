# cogni-help

Central help hub for the [insight-wave](https://github.com/cogni-work/insight-wave) ecosystem. Interactive courses, plugin discovery, cross-plugin workflow guides, troubleshooting, quick-reference cheatsheets, and GitHub issue filing.

## Why this exists

The insight-wave ecosystem has 15 plugins with 60+ skills, dozens of agents, and interconnected workflows. Users need a single place to learn, navigate, diagnose, and get help:

| Need | Solution |
|------|----------|
| Structured onboarding | 11-course curriculum with hands-on exercises |
| "Which plugin do I use?" | Plugin discovery guide with recommendations |
| Multi-plugin pipelines | Workflow templates with step-by-step playbooks |
| Something broken? | Diagnostic tool with known-issues reference |
| Quick refresher | One-screen cheatsheets for any plugin |
| Bug or feature request | Guided issue filing against insight-wave |

## Quick start

```
/guide "I need to create a sales pitch"   # find the right plugin
/teach 1                                   # start Course 1: Cowork Fundamentals
/workflow research-to-slides               # see a cross-plugin pipeline
/cheatsheet cogni-trends                     # quick reference for a plugin
/troubleshoot                              # run diagnostics
/issues                                    # file a bug or feature request
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
| `teach` | skill | Interactive course delivery — 11 courses, adaptive pacing, progress tracking |
| `course-deck` | skill | PPTX generation — curriculum overview or course introduction decks |
| `guide` | skill | Plugin discovery — match tasks to plugins, ecosystem map |
| `troubleshoot` | skill | Diagnostics — plugin integrity, dependencies, stale state, known issues |
| `workflow` | skill | Pipeline templates — 5 cross-plugin workflow playbooks |
| `cheatsheet` | skill | Quick reference — one-screen cards for any plugin |
| `cogni-issues` | skill | Issue lifecycle — create, list, status, browse GitHub issues |
| `course-deck-generator` | agent (sonnet) | PPTX generation as delegated subprocess |
| `/teach` | command | Start or resume a course |
| `/courses` | command | Show course progress |
| `/course-deck` | command | Generate training PPTX |
| `/guide` | command | Find the right plugin |
| `/troubleshoot` | command | Run diagnostics |
| `/workflow` | command | View pipeline templates |
| `/cheatsheet` | command | Generate quick reference |
| `/issues` | command | File or track GitHub issues |
| `course-status.sh` | script | JSON progress check |
| `reset-progress.sh` | script | Reset course progress |
| `health-check.sh` | script | JSON diagnostic output |

## Curriculum (teach skill)

| # | Course | Plugins covered |
|---|--------|-----------------|
| 1 | Cowork Fundamentals | cogni-help (meta) |
| 2 | Workspace & Obsidian | cogni-workspace, cogni-obsidian, cogni-help:cogni-issues |
| 3 | Basic Tools | cogni-copywriting, cogni-narrative, cogni-claims |
| 4 | Trend Scouting | cogni-trends (Part 1) |
| 5 | Trend Reporting | cogni-trends (Part 2) |
| 6 | Portfolio Messaging | cogni-canvas, cogni-portfolio |
| 7 | Visual Deliverables | cogni-visual |
| 8 | Research Reports | cogni-research |
| 9 | B2B Marketing | cogni-marketing |
| 10 | Sales Pitches | cogni-sales |
| 11 | Consulting Orchestration | cogni-consulting |

Each course is ~45 minutes with ~5 modules: Theory → Demo → Exercise → Quiz → Recap.

## Workflow Templates

| Workflow | Pipeline |
|----------|----------|
| `research-to-slides` | cogni-research → cogni-narrative → cogni-visual |
| `trend-to-marketing` | cogni-trends → cogni-portfolio → cogni-marketing |
| `portfolio-to-pitch` | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `new-engagement` | cogni-consulting phases (Discover → Define → Develop → Deliver) |
| `full-onboarding` | cogni-workspace → cogni-help courses 1-11 |

## Data model

Course progress is stored in `.claude/cogni-help.local.md` (YAML frontmatter).
Issue state is stored in `cogni-issues/issues.json` in the working directory.
Exercise artifacts are written to `_teacher-exercises/`.

## Architecture

```
cogni-help/
├── .claude-plugin/plugin.json    Plugin manifest (v0.2.0)
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
├── commands/                     8 slash commands
│   ├── teach.md
│   ├── courses.md
│   ├── course-deck.md
│   ├── guide.md
│   ├── troubleshoot.md
│   ├── workflow.md
│   ├── cheatsheet.md
│   └── issues.md
└── scripts/                      3 utility scripts
    ├── course-status.sh
    ├── reset-progress.sh
    └── health-check.sh
```

## Dependencies

All ecosystem plugins are soft dependencies — required for their respective courses
but not for using guide, troubleshoot, workflow, cheatsheet, or issues.

## Custom development

Need custom training courses or a new plugin? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
