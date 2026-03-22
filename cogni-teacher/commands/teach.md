---
name: teach
description: Start or resume an interactive cogni-teacher course
argument-hint: "<course number or name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Bash
  - Grep
  - WebSearch
  - WebFetch
---

Start or resume an interactive 45-minute course from the cogni-teacher curriculum.

Accept course by number (1-11) or by name/keyword (e.g., "cowork", "basic tools", "tips", "diamond").

Map input to course IDs:
- 1, cowork, fundamentals → cowork-fundamentals
- 2, workspace, obsidian → workspace-obsidian
- 3, basic, tools, copywriting, narrative, claims → basic-tools
- 4, scouting, tips-scouting, selection → tips-scouting
- 5, reporting, tips-reporting → tips-reporting
- 6, portfolio, canvas → portfolio
- 7, visual → visual
- 8, research, researcher, gpt-researcher → research
- 9, marketing, content, campaign → marketing
- 10, sales, pitch, why-change → sales
- 11, diamond, consulting, orchestrator, double-diamond → consulting

Steps:
1. Load the teach skill to get curriculum context and delivery rules
2. Read progress from `.claude/cogni-teacher.local.md`
3. If course is in-progress, ask: "Continue from Module X, or start over?"
4. Load the course content from the matching reference file in `references/courses/`
5. Deliver modules one at a time following the teach skill format
6. Update progress after each completed module
7. On course completion, mark course as completed and congratulate the user

If no argument is provided, show the course list (same as /courses) and ask which course to start.
