---
name: guide
description: Find the right cogni-works plugin or skill for your task
argument-hint: "[task description]"
allowed-tools:
  - Read
  - Glob
---

Help you find the right plugin(s) for your task using the guide skill.

Accept either:
- A task description — returns 1-3 plugin recommendations with commands and prerequisites
- No argument — shows the full ecosystem map

Steps:
1. Load the guide skill to get the plugin catalog and matching logic
2. If a task description is provided, match it to plugins and present recommendations
3. If no argument, present the ecosystem overview grouped by category
