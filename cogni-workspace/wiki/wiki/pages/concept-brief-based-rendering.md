---
id: concept-brief-based-rendering
title: Brief-based rendering (separate content spec from rendering)
type: concept
tags: [cogni-workspace, briefs, rendering, separation-of-concerns]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

cogni-workspace separates content specification from rendering. Between the compose/polish phase and the render phase, cogni-workspace inserts a **brief**: a structured Markdown file with YAML frontmatter that describes *what* to render without describing *how*.

## The pipeline

```
cogni-workspace `text-to-narrative` → cogni-workspace `copywriter` → brief → cogni-workspace render agents
(compose)                             (polish)                       (specify) (visualize)
```

A brief sits between the `copywriter` skill's output and cogni-workspace's rendering agents. Nothing in cogni-workspace writes that brief today: it is hand-authored against the templates and worked examples in the plugin's `libraries/`, or supplied by a caller. (`text-to-narrative` Phase 7 writes a different artifact, `design-brief.md`, which goes to Claude Design rather than to these renderers.)

## What a brief specifies vs hides

A presentation brief lists slides with headlines, body copy, and CTA proposals. It does **not** specify colors, fonts, layout coordinates, or element types.

An infographic brief lists content blocks with block types, headlines, and data points. It does **not** specify element composition or spatial relationships — those decisions belong to the rendering agents.

Briefs are YAML frontmatter + Markdown. Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification.

## Two practical benefits

1. **Briefs are reviewable and editable independently of rendering.** A user can author a presentation brief, adjust the headline on slide 3, and then render without touching anything upstream.

2. **Rendering agents can evolve independently.** When rendering pipelines upgrade (new chart types, new sketchnote conventions, new export formats), existing briefs remain valid because brief formats make no assumptions about rendering technique.

## Brief types in cogni-workspace

- `presentation-brief.md` — slides
- `infographic-brief.md` — single-page visual summary
- `storyboard-brief.md` — multi-poster sequence
- `web-brief.md` — scrollable web narrative
- `enrichment-plan.md` — annotation of an existing markdown report

Each brief is consumed by a different render agent (`render-html-slides`, `render-infographic-pencil`/`-sketchnote`/`-whiteboard`, `storyboard`, `web`, `enrich-report`).

## Why this matters across the ecosystem

Brief-based rendering is the cleanest example of [[concept-data-isolation]] inside a single plugin. The brief is the contract; everything before it is content; everything after it is presentation. The same principle could be applied to other rendering domains.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
