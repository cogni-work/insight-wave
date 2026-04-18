---
id: skill-cogni-workspace-ask
title: "cogni-workspace:ask"
type: entity
tags: [cogni-workspace, workspace, foundation, skill, ask]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/skills/ask/SKILL.md
status: stable
related: [plugin-cogni-workspace]
---

> One of the skills inside [[plugin-cogni-workspace]].

Answer a question about the insight-wave plugin ecosystem by reading the bundled insight-wave wiki — never from memory. The wiki ships with cogni-workspace and lives at ${CLAUDE_PLUGIN_ROOT}/wiki/. Reads wiki/wiki/index.md first to find relevant pages, then reads only those pages, then synthesizes a grounded answer with "wikilink" double-bracket references citations.

**Source**: `cogni-workspace:ask`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/skills/ask/SKILL.md))
