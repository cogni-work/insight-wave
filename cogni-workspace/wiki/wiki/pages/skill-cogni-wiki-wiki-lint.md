---
id: skill-cogni-wiki-wiki-lint
title: "cogni-wiki:wiki-lint"
type: entity
tags: [cogni-wiki, wiki, knowledge, skill, wiki-lint]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-wiki/skills/wiki-lint/SKILL.md
status: stable
related: [plugin-cogni-wiki]
---

> One of the skills inside [[plugin-cogni-wiki]].

Audit a Karpathy-style wiki for health problems — broken "wikilinks" double-bracket references, orphan pages with no inbound links, stale dates, missing frontmatter fields, contradictions between pages, tag typos, and sources that no longer exist in raw/. Writes a severity-tiered report to wiki/pages/lint-YYYY-MM-DD.md and always appends to wiki/log.md.

**Source**: `cogni-wiki:wiki-lint`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-wiki/skills/wiki-lint/SKILL.md))
