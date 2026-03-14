---
name: export-pdf-report
description: |
  Export research project as a formal A4 PDF report with verification badges.
  Converts research-hub.md and entity files into a print-ready PDF with cover page,
  table of contents, and three-layer claim verification badges. Use when user wants a PDF report,
  printable research document, formal deliverable, or wants to share research as PDF.
---

# Export PDF Report

Generate a formal A4 PDF from synthesis output with cover page, table of contents, and verification badges.

## Quick Start

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-pdf-report/scripts/export_pdf_report.py" \
  --project /path/to/research-project \
  --output research-report.pdf
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | Yes | - | Path to research project root |
| `--output` | No | `{project}/research-report.pdf` | Output PDF file path |

## Prerequisites

- synthesis skill completed: `research-hub.md` exists at project root

## Reference Files

- `references/entity-formats.md` — Entity type to PDF section mapping
- `references/report-structure.md` — PDF layout and section order
