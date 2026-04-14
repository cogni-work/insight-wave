---
name: enrich-report
description: Enrich a markdown report with themed Chart.js visualizations and Excalidraw concept diagrams, producing a self-contained HTML file.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, Skill
arguments:
  - name: source
    description: Path to the markdown report file. If omitted, auto-discovers nearby reports.
    required: false
  - name: density
    description: "Enrichment density: minimal (5-8), balanced (10-15, default), rich (15-22)"
    required: false
  - name: layout
    description: "HTML layout mode: scroll (sidebar + continuous scroll, default), flipbook (two-page spread with 3D page-curl)"
    required: false
---

Invoke the `enrich-report` skill from cogni-visual.

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/enrich-report/SKILL.md`.

If `source` argument was provided, set `source_path` to that value.
If `density` argument was provided, set `density` to that value (must be minimal, balanced, or rich).
If `layout` argument was provided, set `layout` to that value (must be scroll or flipbook).
