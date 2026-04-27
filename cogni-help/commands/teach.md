---
name: teach
description: Start or resume an interactive cogni-help workflow tour
argument-hint: "<tour ID or short name>"
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

Start or resume an interactive workflow-tour course from the cogni-help curriculum.

Accept the tour by canonical ID or by short name/keyword (e.g., "research", "trends", "pitch", "website", "consulting", "content", "install").

Map input to tour IDs:
- research, research-to-report, report → tour-research-to-report
- trends, trend, scouting, trends-to-solutions, solutions → tour-trends-to-solutions
- pitch, portfolio-to-pitch, sales-deck → tour-portfolio-to-pitch
- website, portfolio-to-website, site → tour-portfolio-to-website
- consulting, diamond, double-diamond, engagement → tour-consulting-engagement
- content, content-pipeline, marketing → tour-content-pipeline
- install, infographic, install-to-infographic, first-run → tour-install-to-infographic

Steps:
1. Load the teach skill to get curriculum context and delivery rules
2. Read progress from `.claude/cogni-help.local.md`
3. If the tour is in-progress, ask: "Continue from Module X, or start over?"
4. Load the tour content from the matching reference file in `references/courses/tours/`
5. Deliver modules one at a time following the teach skill format
6. Update progress after each completed module
7. On tour completion, mark the tour as completed and congratulate the user

If no argument is provided, show the tour list (same as /courses) and ask which tour to start.
