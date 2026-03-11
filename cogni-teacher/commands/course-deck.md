---
name: course-deck
description: Generate a PPTX slide deck for course curriculum or course introduction
argument-hint: "<curriculum | course number or name>"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Generate a professional PPTX slide deck using the course-deck skill.

Accept either:
- `curriculum` — generate a program overview deck covering all 7 courses
- A course number (1-7) or name (e.g., "basic tools", "tips scouting") — generate an intro deck for that course

Steps:
1. Load the course-deck skill to get deck structure, theme, and generation rules
2. Read the relevant course content from `references/courses/`
3. Read the cogni-work theme from `/Users/stephandehaas/GitHub/dev/cogni-workspace/themes/cogni-work/theme.md`
4. Generate the PPTX using PptxGenJS following the skill's slide templates
5. Save to the working directory with the correct filename

If no argument is provided, ask which deck type to generate.
