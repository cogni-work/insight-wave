---
name: export-report
description: |
  Export a completed research report to different formats: Markdown (default), HTML, or PDF.
  Use when the user asks to "export report", "save as HTML", "export to PDF", "publish report",
  "convert report", or wants the research output in a specific format.
---

# Export Report Skill

## Quick Example

**User**: "Export the report as HTML"

**Result**: HTML file generated at `output/report.html` from `output/report.md`.

## Prerequisites

- Completed research project with `output/report.md`
- For PDF: `weasyprint` Python package (optional, falls back to HTML)

## Workflow

### Phase 0: Locate Report

1. Find the project directory (ask user if ambiguous)
2. Verify `output/report.md` exists
3. Determine requested format(s)

### Phase 1: Export

**Markdown** (always available):
- `output/report.md` is already the markdown output
- Optionally copy to a user-specified location

**HTML**:
1. Read `output/report.md`
2. Generate HTML with inline CSS for professional formatting
3. Include: table of contents, source links, clean typography
4. Write to `output/report.html`

**PDF**:
1. First generate HTML (as above)
2. If `weasyprint` is available: convert HTML to PDF
3. If not: inform user HTML is available, suggest browser print-to-PDF
4. Write to `output/report.pdf`

**Presentation** (optional):
- If cogni-visual is available, delegate: `Skill(cogni-visual:presentation-brief)`
- Generates a presentation brief from the report

### Phase 2: Report to User

- List exported files with paths
- File sizes
- Suggest next steps (share, present, further research)

## Supported Formats

| Format | Output Path | Requirements |
|--------|-------------|-------------|
| Markdown | `output/report.md` | None (always available) |
| HTML | `output/report.html` | None (generated via Python) |
| PDF | `output/report.pdf` | weasyprint (optional) |
