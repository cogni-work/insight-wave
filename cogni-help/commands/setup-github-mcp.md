---
name: setup-github-mcp
description: Set up the GitHub MCP server in Claude Desktop for GitHub integration
argument-hint: "[check | setup | repair]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

Configure the GitHub MCP server in Claude Desktop for full GitHub integration.

Accept a mode argument:
- `setup` or no argument — full guided walkthrough (prerequisites, PAT, config, restart)
- `check` — check if GitHub MCP is already configured and report status
- `repair` — diagnose and fix a broken GitHub MCP setup

If no argument is provided, default to **setup** mode.

Steps:
1. Load the setup-github-mcp skill for full workflow and templates
2. Determine mode from argument or context
3. Follow the skill's workflow for the selected mode
