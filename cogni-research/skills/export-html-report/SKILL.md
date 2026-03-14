---
name: export-html-report
description: |
  Export research project as a self-contained interactive HTML report with verification badges.
  Converts research-hub.md and entity files (findings, sources, claims) into an interactive HTML document
  with navigation, theme support, and resolved wikilinks. Use when user wants to export research as HTML,
  generate an HTML report, create a standalone research document, or share research results as a web page.
---

# Export HTML Report

Generate a single self-contained HTML file from synthesis output. Converts `research-hub.md` plus entity files into an interactive document with navigation, theme support, resolved wikilinks, and three-layer verification badges.

## Quick Start

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project /path/to/research-project \
  --theme digital-x \
  --output research-report.html
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | Yes | - | Path to research project root |
| `--theme` | No | `digital-x` | Theme ID from cogni-workspace themes |
| `--output` | No | `{project}/research-report.html` | Output HTML file path |

## Prerequisites

- synthesis skill completed: `research-hub.md` exists at project root
- Entity directories: 04-findings, 05-sources, 06-claims populated

## Verification Badges

Claims display three-layer confidence scoring:
- **Evidence confidence** badge (blue): 0.0-1.0
- **Claim quality** badge (purple): 0.0-1.0
- **Source verification** badge (green/yellow/red): verified/deviated/unavailable

## Entity Format Reference

Read `references/entity-formats.md` for how each entity type maps to HTML sections.
Read `references/theme-integration.md` for theme CSS variable mapping.

## Assets

- `assets/report-layout.css` — Base report styling
- `assets/report.js` — Interactive navigation and wikilink resolution
