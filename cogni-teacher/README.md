# cogni-teacher

Interactive 45-minute courses for [Claude Cowork](https://claude.ai/cowork) teaching fundamentals and cogni-works marketplace plugins to consultants. 7-course curriculum with hands-on exercises, quizzes, and progress tracking.

## Why this exists

The cogni-works ecosystem has 12 plugins with 50+ skills, dozens of agents, and interconnected workflows. Learning by trial and error wastes hours and builds bad habits:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No structured onboarding | New users discover plugins randomly, miss key capabilities | Underutilization of the ecosystem |
| Skill dependencies unclear | Users run advanced skills before mastering prerequisites | Errors and frustration from skipped foundations |
| No hands-on practice | Reading docs doesn't build muscle memory | Knowledge doesn't stick without exercises |
| Progress invisible | No way to track what's been learned or what's next | Learners repeat topics or skip important ones |

This plugin provides a structured learning path from workspace setup through advanced visual deliverables, with exercises that create real artifacts in your working directory.

## What it does

1. **Teach** interactive courses with a theory → demo → exercise → quiz → recap cycle per module
2. **Track** progress across sessions — resume where you left off, skip ahead if confident
3. **Exercise** by creating real artifacts (workspaces, narratives, portfolio entries) in a dedicated `_teacher-exercises/` directory
4. **Generate** slide decks for group onboarding sessions or course introductions

## What it means for you

- **Structured path.** 7 courses in logical order — each builds on the previous, with prerequisites handled automatically.
- **Adaptive pacing.** Skip exercises if you're confident, get extra practice if you're struggling. The course adapts to you.
- **Real artifacts.** Exercises create actual files using the plugins being taught — not toy examples.
- **Persistent progress.** Course completion, current module, and timestamps tracked across sessions.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

**Prerequisites:**
- The plugins being taught should be installed (cogni-workspace, cogni-obsidian, cogni-copywriting, cogni-narrative, cogni-claims, cogni-tips, cogni-portfolio, cogni-visual)

## Quick start

```
/teach 1          # start Course 1: Cowork Fundamentals
/teach portfolio  # start Course 6 by keyword
/courses          # see all 7 courses with completion status
/course-deck      # generate a PPTX overview for group onboarding
```

Or describe what you want:

- "Teach me how to use cogni-works"
- "I want to learn about trend scouting"
- "Show me my course progress"
- "Generate a training deck for the team"

## Curriculum

| # | Course | What you learn | Plugins covered |
|---|--------|---------------|-----------------|
| 1 | Cowork Fundamentals | Claude Cowork basics, plugin ecosystem, workplace setup | cogni-teacher (meta) |
| 2 | Workspace & Obsidian | Workspace initialization, Obsidian vault setup, theme management | cogni-workspace, cogni-obsidian |
| 3 | Basic Tools | Document polishing, stakeholder review, claim verification, narrative transformation | cogni-copywriting, cogni-narrative, cogni-claims |
| 4 | Trend Scouting | TIPS framework, Trendradar dimensions, trend candidate selection | cogni-tips (Part 1) |
| 5 | Trend Reporting | Trend reports, value modeling, portfolio integration | cogni-tips (Part 2) |
| 6 | Portfolio Messaging | IS/DOES/MEANS framework, propositions, markets, competitors, solutions | cogni-portfolio |
| 7 | Visual Deliverables | Slides, big-picture maps, web narratives, storyboards | cogni-visual |

Each course is ~45 minutes with ~5 modules following the cycle: Theory → Demo → Exercise → Quiz → Recap.

## Try it

After installing, type one prompt:

> Teach me Course 1

Claude starts an interactive lesson on Cowork Fundamentals — explaining concepts, demonstrating features, giving you exercises to try, and quizzing you along the way. Your progress is saved automatically so you can resume later.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `teach` | skill | Interactive course delivery engine — adaptive pacing, progress tracking, exercise creation |
| `course-deck` | skill | PPTX slide generation — curriculum overview or single-course introduction decks |
| `/teach` | command | Start or resume a course by number (1-7) or keyword |
| `/courses` | command | Show all 7 courses with completion status |
| `/course-deck` | command | Generate a PPTX deck for group onboarding |

## Architecture

```
cogni-teacher/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       2 teaching skills
│   ├── teach/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── courses/          7 course content files
│   └── course-deck/
│       └── SKILL.md
└── commands/                     3 slash commands
    ├── teach.md
    ├── courses.md
    └── course-deck.md
```

Progress is tracked in `.claude/cogni-teacher.local.md` (YAML frontmatter with per-course status, current module, and timestamps). Exercise files are created in `_teacher-exercises/` in the user's working directory.

## Custom development

Need custom training courses for your team, onboarding for proprietary plugins, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
