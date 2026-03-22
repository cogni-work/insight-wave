---
name: guide
description: >-
  Help users find the right cogni-works plugin or skill for their task.
  Use this skill whenever the user asks "which plugin should I use", "what can I do
  with cogni-works", "find me a skill for X", "recommend a plugin", "where do I start",
  "help me find the right tool", "what plugins are available", "I need to do X — which
  plugin handles that?", or any question about plugin capabilities, ecosystem navigation,
  or tool selection. Also trigger when a user seems lost or unsure which plugin to use
  for a specific task — even if they don't explicitly ask for guidance.
version: 0.1.0
allowed-tools:
  - Read
  - Glob
---

# guide: Plugin & Skill Discovery

Help users navigate the cogni-works ecosystem by matching their task to the right
plugin(s). Users often know what they want to accomplish but not which of the 15+
plugins handles it. Your job is to bridge that gap quickly and accurately.

## How to Guide

1. **Read the catalog** at `references/plugin-catalog.md` — it contains every plugin,
   its skills, key commands, and typical use cases.

2. **Match the user's intent** to 1-3 plugins. Think about what they're actually trying
   to accomplish, not just keyword matches. "I need to make slides" could mean cogni-visual
   (presentation from narrative), course-deck (training slides), or cogni-marketing
   (campaign materials).

3. **Present recommendations** with:
   - Plugin name and what it does (one sentence)
   - The specific command or skill to invoke
   - Prerequisites (other plugins, data, or setup needed)
   - Why this is the right fit for their task

4. **For multi-plugin tasks**, suggest a sequence: "Start with cogni-research for the
   report, then cogni-narrative to shape the story, then cogni-visual for slides."
   Mention the `/workflow` command if a matching workflow template exists.

## When No Plugin Fits

If the user's task doesn't match any plugin, say so clearly. Don't force-fit a plugin
to a task it wasn't designed for. Suggest the user check if a community plugin exists
or consider building one.

## Plugin Map (Quick Reference)

When the user asks for an overview (no specific task), present the ecosystem map:

**Research & Intelligence**: cogni-research, cogni-tips, cogni-claims, cogni-portfolio
**Content & Transformation**: cogni-narrative, cogni-copywriting, cogni-visual
**Go-to-Market**: cogni-marketing, cogni-sales
**Orchestration**: cogni-consulting, cogni-workspace
**Support & Learning**: cogni-help (this plugin), cogni-canvas, cogni-obsidian

For detailed information on any plugin, read the full catalog reference.
