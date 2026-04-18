---
id: skill-cogni-research-research-setup
title: "cogni-research:research-setup"
type: entity
tags: [cogni-research, research, multi-agent, skill, research-setup]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-research/skills/research-setup/SKILL.md
status: stable
related: [plugin-cogni-research]
---

> One of the skills inside [[plugin-cogni-research]].

Configure and initialize a cogni-research project — interactive menu for report type, tone, citation style, target market (10 supported: DACH, DE, FR, IT, PL, NL, ES, US, UK, EU — each with per-market authority sources and intent-based bilingual search), output language, and source mode (web / local / wiki / hybrid). Creates the project directory and project-config.json. Mandatory first step before research-report can run; research-report routes here automatically when no project is initialized.

**Source**: `cogni-research:research-setup`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-research/skills/research-setup/SKILL.md))
