# cogni-teacher

Interactive 45-minute courses for [Claude Cowork](https://claude.ai/cowork) teaching fundamentals and cogni-works marketplace plugins to consultants. 11-course curriculum with hands-on exercises, quizzes, and progress tracking.

## Why this exists

The cogni-works ecosystem has 14 plugins with 60+ skills, dozens of agents, and interconnected workflows. Learning by trial and error wastes hours and builds bad habits:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No structured onboarding | New users discover plugins randomly, miss key capabilities | Underutilization of the ecosystem |
| Skill dependencies unclear | Users run advanced skills before mastering prerequisites | Errors and frustration from skipped foundations |
| No hands-on practice | Reading docs doesn't build muscle memory | Knowledge doesn't stick without exercises |
| Progress invisible | No way to track what's been learned or what's next | Learners repeat topics or skip important ones |

This plugin provides a structured learning path from workspace setup through advanced sales pitches, with exercises that create real artifacts in your working directory.

## What it does

1. **Teach** interactive courses with a theory → demo → exercise → quiz → recap cycle per module
2. **Track** progress across sessions — resume where you left off, skip ahead if confident
3. **Exercise** by creating real artifacts (workspaces, narratives, portfolio entries, research reports) in a dedicated `_teacher-exercises/` directory
4. **Generate** slide decks for group onboarding sessions or course introductions

## What it means for you

- **Structured path.** 11 courses in logical order — each builds on the previous, with prerequisites handled automatically.
- **Adaptive pacing.** Skip exercises if you're confident, get extra practice if you're struggling. The course adapts to you.
- **Real artifacts.** Exercises create actual files using the plugins being taught — not toy examples.
- **Persistent progress.** Course completion, current module, and timestamps tracked across sessions.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

## Quick start

```
/teach 1          # start Course 1: Cowork Fundamentals
/teach portfolio  # start Course 6 by keyword
/teach research   # start Course 8: Research Reports
/courses          # see all 11 courses with completion status
/course-deck      # generate a PPTX overview for group onboarding
```

Or describe what you want:

- "Teach me how to use cogni-works"
- "I want to learn about trend scouting"
- "Show me my course progress"
- "Generate a training deck for the team"

## Example workflows

**Self-paced learning**: Start with `/teach 1`, complete the course, check progress with `/courses`, resume the next day with `/teach 2`.

**Skip-ahead for experienced users**: Already know Cowork basics? Jump straight to `/teach portfolio` or `/teach sales` — prerequisites are checked but not enforced.

**Group onboarding**: Generate a curriculum overview deck with `/course-deck curriculum`, then create course-specific intro decks with `/course-deck 3` for workshop sessions.

## Curriculum

| # | Course | What you learn | Plugins covered |
|---|--------|---------------|-----------------|
| 1 | Cowork Fundamentals | Claude Cowork basics, plugin ecosystem, workplace setup | cogni-teacher (meta) |
| 2 | Workspace & Obsidian | Workspace initialization, Obsidian vault setup, theme management | cogni-workspace, cogni-obsidian |
| 3 | Basic Tools | Document polishing, stakeholder review, claim verification, narrative transformation | cogni-copywriting, cogni-narrative, cogni-claims |
| 4 | Trend Scouting | TIPS framework, Trendradar dimensions, trend candidate selection | cogni-tips (Part 1) |
| 5 | Trend Reporting | Trend reports, value modeling, portfolio integration | cogni-tips (Part 2) |
| 6 | Portfolio Messaging | Lean Canvas, IS/DOES/MEANS framework, propositions, markets, competitors, solutions | cogni-canvas, cogni-portfolio |
| 7 | Visual Deliverables | Slides, big-picture maps, web narratives, storyboards | cogni-visual |
| 8 | Research Reports | Multi-agent research, parallel web search, claims verification, export | cogni-gpt-researcher |
| 9 | B2B Marketing Content | GTM paths, 3D content matrix, campaigns, editorial calendar, dashboard | cogni-marketing |
| 10 | Sales Pitches | Why Change methodology, unconsidered needs, business case, proposals | cogni-sales |
| 11 | Consulting Orchestration | Double Diamond framework, vision framing, phase-gated delivery, cross-plugin dispatch | cogni-diamond |

Each course is ~45 minutes with ~5 modules following the cycle: Theory → Demo → Exercise → Quiz → Recap. Course 11 (Diamond) is the capstone — it orchestrates most other plugins.

## Try it

After installing, type one prompt:

> Teach me Course 1

Claude starts an interactive lesson on Cowork Fundamentals — explaining concepts, demonstrating features, giving you exercises to try, and quizzing you along the way. Your progress is saved automatically so you can resume later.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `teach` | skill | Interactive course delivery engine — adaptive pacing, progress tracking, exercise creation (11 courses) |
| `course-deck` | skill | PPTX slide generation — curriculum overview or single-course introduction decks |
| `course-deck-generator` | agent (sonnet) | PPTX generation as delegated subprocess for cross-plugin use |
| `/teach` | command | Start or resume a course by number (1-11) or keyword |
| `/courses` | command | Show all 11 courses with completion status |
| `/course-deck` | command | Generate a PPTX deck for group onboarding |
| `course-status.sh` | script | Quick JSON progress check without loading the skill |
| `reset-progress.sh` | script | Reset progress for a course or all courses |

## Data model

Progress is stored in `.claude/cogni-teacher.local.md` using YAML frontmatter:

| Field | Type | Description |
|-------|------|-------------|
| `student` | string | Learner name (optional) |
| `started` | ISO date | Date of first course activity |
| `last_session` | ISO date | Date of most recent activity |
| `courses.<id>.status` | enum | `completed`, `in-progress`, `not-started` |
| `courses.<id>.current_module` | int | Module number being studied |
| `courses.<id>.completed_modules` | int[] | List of completed module numbers |
| `courses.<id>.started_at` | ISO date | When this course was started |
| `courses.<id>.completed_at` | ISO date | When this course was completed |

Exercise artifacts are written to `_teacher-exercises/` in the working directory.

## Architecture

```
cogni-teacher/
├── .claude-plugin/plugin.json    Plugin manifest (v0.1.6)
├── agents/                       1 delegation agent
│   └── course-deck-generator.md
├── skills/                       2 teaching skills
│   ├── teach/
│   │   ├── SKILL.md
│   │   ├── evals/evals.json
│   │   └── references/
│   │       ├── courses/          11 course content files
│   │       └── exercises/        8 exercise templates
│   └── course-deck/
│       ├── SKILL.md
│       └── evals/evals.json
├── commands/                     3 slash commands
│   ├── teach.md
│   ├── courses.md
│   └── course-deck.md
└── scripts/                      2 utility scripts
    ├── course-status.sh
    └── reset-progress.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-workspace | Yes | Course 2: workspace initialization and theme management |
| cogni-obsidian | Yes | Course 2: Obsidian vault setup and note management |
| cogni-copywriting | Yes | Course 3: document polishing and stakeholder review |
| cogni-narrative | Yes | Course 3: executive narrative transformation |
| cogni-claims | Yes | Course 3: citation verification |
| cogni-tips | Yes | Courses 4-5: trend scouting and reporting pipeline |
| cogni-portfolio | Yes | Course 6: portfolio messaging and propositions |
| cogni-canvas | Yes | Course 6: Lean Canvas authoring as portfolio precursor |
| cogni-visual | Yes | Course 7: slide decks and visual deliverables |
| cogni-gpt-researcher | Yes | Course 8: multi-agent research reports |
| cogni-marketing | Yes | Course 9: B2B marketing content engine |
| cogni-sales | Yes | Course 10: sales pitch generation |
| cogni-diamond | Yes | Course 11: Double Diamond consulting orchestration |

Each course teaches the corresponding plugin — all are required for the full curriculum but courses can be taken independently.

## Custom development

Need custom training courses for your team, onboarding for proprietary plugins, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
