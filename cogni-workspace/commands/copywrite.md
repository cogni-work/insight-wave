---
name: copywrite
description: Polish markdown documents for executive readability using McKinsey Pyramid Principle
usage: /copywrite <file.md> [--scope=full|structure|tone|formatting|compress|review] [--personas=executive,legal,...] [--no-improve] [--flesch-target=50-60] [--translate=de|en|fr|it|pl|nl|es]
aliases: [polish, executive-polish, review-doc, stakeholder-review]
category: content-editing
allowed-tools: [Read, Task, Bash, Skill]
---

Invoke `cogni-publishing:copywriter` and pass `$ARGUMENTS` unchanged. Return its result unchanged.

If `cogni-publishing` is unavailable, stop with an actionable message telling the user to install that plugin. Do not launch a workspace copywriter agent or fall back to local implementation logic.
