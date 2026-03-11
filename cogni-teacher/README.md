# cogni-teacher

Interactive 45-minute courses teaching Claude Cowork fundamentals and cogni-works marketplace plugins to consultants. Delivers structured learning with hands-on exercises, progress tracking, and optional slide deck generation for curriculum overviews.

> **Note**: Courses are designed for consultants learning to work with Claude Cowork and the cogni-works plugin ecosystem. Course content reflects the current plugin versions and may need updates as plugins evolve.

## Installation

```bash
claude plugins add cogni-work/cogni-teacher
```

## Commands

| Command | Description |
|---------|-------------|
| `/teach` | Start or resume an interactive course — guided lessons with exercises and progress tracking |
| `/courses` | List all available courses with completion status |
| `/course-deck` | Generate a PPTX slide deck for a course curriculum overview or course introduction |

## Skills

| Skill | Description |
|-------|-------------|
| `teach` | Interactive course delivery — structured lessons, hands-on exercises, progress tracking, and adaptive pacing based on learner responses |
| `course-deck` | Generate professional slide decks for course content — curriculum overview decks showing all available courses, or single-course introduction decks |

## Example Workflows

### Start a Course

1. Run `/courses` to see available courses and your completion status
2. Run `/teach` and select a course to begin
3. Follow the guided lessons with hands-on exercises — progress is saved automatically

### Resume a Course

1. Run `/teach` — the plugin detects your in-progress course
2. Continue from where you left off with full context restored

### Generate a Course Deck

1. Run `/course-deck` to create a curriculum overview presentation
2. Or specify a course name to generate an introduction deck for that specific course
3. The PPTX file is ready for use in training sessions or onboarding

## Architecture

```
cogni-teacher/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       2 teaching skills
│   ├── teach/
│   └── course-deck/
└── commands/                     3 slash commands
    ├── teach.md
    ├── courses.md
    └── course-deck.md
```

## License

[AGPL-3.0](LICENSE)
