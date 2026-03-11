---
name: courses
description: List all available cogni-teacher courses with completion status
allowed-tools:
  - Read
  - Glob
---

Show the cogni-teacher curriculum with progress status for each course.

Read the progress file at `.claude/cogni-teacher.local.md` in the current project directory.
If it does not exist, show all courses as not started.

Display the course list using the format defined in the teach skill:
- Mark completed courses with [x]
- Mark in-progress courses with [>] and show current module
- Mark not-started courses with [ ]
- Show recommended sequence (1-7)
- Include the hint: Start a course with `/teach <number or name>`
