# cogni-help

Onboarding and navigation layer for the insight-wave ecosystem — teaches users through courses, routes tasks to plugins, chains multi-plugin workflows, and diagnoses problems.

## Plugin Architecture

```
skills/                         7 help skills
  teach/                          Interactive course delivery — 12 courses, adaptive pacing, progress tracking
    references/
      courses/                    12 course definitions (01-cowork-fundamentals through 12-documentation)
      exercises/                  Hands-on exercise templates per course
  course-deck/                    Generate PPTX slide decks for curriculum or course intros
  guide/                          Plugin discovery — match tasks to plugins, ecosystem map
    references/
      plugin-catalog.md           Plugin capability index for matching
  troubleshoot/                   Diagnostics — plugin integrity, dependencies, stale state
    references/
      known-issues.md             Known issues and resolution patterns
  workflow/                       Pipeline templates — 9 cross-plugin workflow playbooks (7 user-facing + 2 internal/operational)
    references/
      workflows/                  7 user-facing workflow definitions (research-to-report, trends-to-solutions, portfolio-to-pitch, portfolio-to-website, content-pipeline, install-to-infographic, consulting-engagement)
      internal-workflows/         2 internal/operational definitions (docs-pipeline, full-onboarding)
  cheatsheet/                     Quick reference — one-screen cards for any plugin
  cogni-issues/                   Issue lifecycle — create, list, status via GitHub browser automation

agents/
  course-deck-generator.md        PPTX generation as delegated subprocess (sonnet)

commands/                       7 slash commands
  teach.md, courses.md, course-deck.md, guide.md,
  troubleshoot.md, workflow.md, cheatsheet.md

scripts/                        3 utility scripts
  course-status.sh                Show course progress for a project directory
  health-check.sh                 Quick health check for plugin ecosystem
  reset-progress.sh               Reset course progress (per-course or all)
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 7 | teach, course-deck, guide, troubleshoot, workflow, cheatsheet, cogni-issues |
| Agents | 1 | course-deck-generator (sonnet) |
| Commands | 7 | teach, courses, course-deck, guide, troubleshoot, workflow, cheatsheet |

## 12-Course Curriculum

| # | Course | Plugins Covered |
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

Each course ~45 minutes with ~5 modules: Theory → Demo → Exercise → Quiz → Recap.

## Workflow Templates

User-facing (canonical, 1:1 with `docs/workflows/`):

| Workflow | Pipeline |
|----------|----------|
| install-to-infographic | cogni-workspace → cogni-workspace (themes) → cogni-visual |
| research-to-report | cogni-research → cogni-narrative → cogni-visual |
| trends-to-solutions | cogni-trends → cogni-portfolio → cogni-marketing |
| portfolio-to-pitch | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| portfolio-to-website | cogni-portfolio → cogni-workspace → cogni-website |
| content-pipeline | cogni-marketing → cogni-narrative → cogni-copywriting → cogni-visual |
| consulting-engagement | cogni-consulting phases (Discover → Define → Develop → Deliver) |

Internal / operational (maintainer pipelines, no canonical docs companion):

| Workflow | Pipeline |
|----------|----------|
| docs-pipeline | cogni-docs: doc-start → audit → generate → sync → power → claude → hub → bridge |
| full-onboarding | cogni-workspace → cogni-help courses 1-12 |

## Data Model

- Course progress stored in `.claude/cogni-help.local.md` (YAML frontmatter)
- Issue state stored in `cogni-issues/issues.json` in the working directory
- Exercise artifacts written to `_teacher-exercises/`

## Cross-Plugin Integration

cogni-help references all ecosystem plugins — it is the meta-layer:
- **teach** skill maps each course to 1-3 plugins
- **workflow** skill chains 3-5 plugins per pipeline template
- **guide** skill indexes all plugin capabilities for task matching
- **troubleshoot** skill checks plugin dependencies and workspace health
- **cheatsheet** skill reads any plugin's metadata to generate quick reference

All dependencies are soft — cogni-help functions without any specific plugin installed, but courses and workflows require the relevant plugins.

## Relationship to docs/ Directory

The workspace root contains a `docs/` directory generated by cogni-docs with user-facing
documentation (plugin guides, workflow tutorials, architecture docs, getting-started).
cogni-help references this documentation in several places:

- **teach skill**: Course completion sections point to `docs/plugin-guide/<plugin>.md`
- **guide skill**: Plugin catalog includes a docs/ resource table for learning queries
- **cheatsheet skill**: Generated cards include a "Learn More" footer linking to plugin guides
- **workflow skill**: Workflow templates cross-reference `docs/workflows/` tutorials

When docs/ content is updated via cogni-docs, cogni-help's references remain valid because
they point to stable paths (`docs/plugin-guide/<plugin>.md`), not specific content.

## Key Conventions

- Course progress is per-user (stored in user's `.claude/` directory)
- Exercises create temporary artifacts in `_teacher-exercises/` (gitignored)
- Plugin catalog in guide/references/plugin-catalog.md must be updated when plugins are added
- Workflow definitions are standalone markdown files in workflow/references/workflows/ (user-facing) and workflow/references/internal-workflows/ (operational/maintainer pipelines)
- Skill-level `version` fields in `SKILL.md` frontmatter track sibling-skill convention (often staying at `0.1.0` while the plugin version moves) — `cogni-help/.claude-plugin/plugin.json` and the matching `.claude-plugin/marketplace.json` entry are the single source of truth for the plugin version
