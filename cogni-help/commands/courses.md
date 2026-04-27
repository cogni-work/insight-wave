---
name: courses
description: List all available cogni-help workflow tours with completion status
allowed-tools:
  - Read
  - Glob
---

Show the cogni-help workflow-tour curriculum with progress status for each tour.

Read the progress file at `.claude/cogni-help.local.md` in the current project directory.
If it does not exist, show all tours as not started.

Display the tour list using the format defined in the teach skill:
- Mark completed tours with [x]
- Mark in-progress tours with [>] and show current module
- Mark not-started tours with [ ]
- Show the seven canonical tours: tour-research-to-report, tour-trends-to-solutions, tour-portfolio-to-pitch, tour-portfolio-to-website, tour-consulting-engagement, tour-content-pipeline, tour-install-to-infographic
- Include the hint: Start a tour with `/teach <tour-id or short name>`
