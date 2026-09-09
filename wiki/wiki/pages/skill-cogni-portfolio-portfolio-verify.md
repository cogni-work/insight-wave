---
id: skill-cogni-portfolio-portfolio-verify
title: "cogni-portfolio:portfolio-verify"
type: entity
tags: [cogni-portfolio, portfolio, fab, skill, portfolio-verify]
created: 2026-04-17
updated: 2026-04-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/portfolio-verify/SKILL.md
status: stable
related: [plugin-cogni-portfolio]
---

> One of the skills inside [[plugin-cogni-portfolio]].

Verify web-sourced claims in portfolio entities against their cited sources.

**Source**: `cogni-portfolio:portfolio-verify`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/portfolio-verify/SKILL.md))

Claims submitted by this skill conform to the reference contract shipped with `cogni-workspace:claims`, which preserves `entity_ref` so corrections cascade back to portfolio files.

Submission and verification of portfolio claims go through `cogni-workspace:claims`.
