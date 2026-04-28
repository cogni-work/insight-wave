---
name: course-deck
description: Generate a PPTX slide deck for the workflow-tour curriculum or a single tour introduction
argument-hint: "<curriculum | tour ID or short name>"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Generate a professional PPTX slide deck using the course-deck skill.

Accept either:
- `curriculum` — generate a program overview deck covering the 7 workflow tours
- A tour ID (e.g., `tour-research-to-report`) or short name (e.g., "research", "trends", "pitch", "website", "consulting", "content", "install") — generate an intro deck for that tour

Steps:
1. Load the course-deck skill to get deck structure, theme, and generation rules
2. Read the relevant tour content from `references/courses/tours/`
3. Read the cogni-work theme from `$COGNI_WORKSPACE_ROOT/themes/cogni-work/theme.md`
4. Generate the PPTX using PptxGenJS following the skill's slide templates
5. Save to the working directory with the correct filename

If no argument is provided, ask which deck type to generate.
