---
name: issues
description: File, list, or check status of GitHub issues against cogni-works plugins
argument-hint: "[create | list | status <number> | browse <number>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Manage GitHub issues for cogni-works plugins via the cogni-issues skill.

Accept a mode argument:
- `create` or no argument with a complaint/request — file a new issue
- `list` — show all filed issues grouped by plugin
- `status <number>` — check status of a specific issue
- `browse <number>` — open an issue in the browser

If no argument is provided and the user's message contains a bug report, feature request,
or complaint about a plugin, default to **create** mode. If the message is just `/issues`
with no context, default to **list** mode.

Steps:
1. Load the cogni-issues skill for full workflow and templates
2. Determine mode from argument or context
3. Follow the skill's workflow for the selected mode
