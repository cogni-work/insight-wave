---
id: skill-cogni-workspace-manage-themes
title: "cogni-workspace:manage-themes"
type: entity
tags: [cogni-workspace, workspace, foundation, skill, manage-themes]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/skills/manage-themes/SKILL.md
status: stable
related: [plugin-cogni-workspace]
---

> One of the skills inside [[plugin-cogni-workspace]].

Create, audit, improve, select, and apply visual design themes for the workspace — sourced from Claude Design bundles or presets, then stored and applied to all visual outputs (slides, documents, diagrams, reports). Also audits and improves existing themes: contrast/accessibility checks, palette harmony, typography pairing, and completeness review.

Operation 11 (Select Theme) is the single entry point every visual plugin calls to resolve a theme. It discovers themes across the bundled and workspace directories, presents an interactive picker, and returns `theme_path`, `theme_name` and `theme_slug` — see [[concept-theme-inheritance]].

**Source**: `cogni-workspace:manage-themes`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/skills/manage-themes/SKILL.md))
