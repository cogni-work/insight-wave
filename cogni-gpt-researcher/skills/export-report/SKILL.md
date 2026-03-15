---
name: export-report
description: |
  Export a completed research report to different formats: Markdown (default), HTML, PDF, or DOCX.
  Use when the user asks to "export report", "save as HTML", "export to PDF", "export to Word",
  "export to DOCX", "publish report", "convert report", "download report", "share the report",
  "make it pretty", or wants the research output in a specific format for sharing or presentation.
---

# Export Report Skill

## Quick Example

**User**: "Export the report as HTML"

**Result**: Self-contained HTML file at `output/report.html` with:
- Professional typography (Georgia serif, max-width 800px)
- Auto-generated table of contents
- Clickable source links
- Print-optimized CSS

## Prerequisites

- Completed research project with `output/report.md`
- For PDF: `weasyprint` Python package (optional, falls back to browser print-to-PDF)

## Workflow

### Phase 0: Locate Report

The export skill needs to find the right project and verify the report exists. Without a completed report, there is nothing to export — and exporting a draft mid-review would publish unverified content.

1. Find the project directory (ask user if ambiguous)
2. Verify `output/report.md` exists (NOT `draft-v*.md` — only the finalized report)
3. Determine requested format(s) from user request

### Phase 1: Export

Each format builds on the previous — HTML is generated from markdown, PDF from HTML. This cascade means the markdown source is always the single source of truth.

**Markdown** (always available):
- `output/report.md` is already the markdown output
- Optionally copy to a user-specified location

**HTML**:
1. Read `references/export-formats.md` for the HTML template
2. Read `output/report.md`
3. Generate self-contained HTML with inline CSS (no external dependencies)
4. Include: table of contents from headings, clickable source links, clean typography
5. Write to `output/report.html`

**PDF**:
1. First generate HTML (as above)
2. **Preferred**: Invoke `Skill(document-skills:pdf)` to create the PDF from HTML with full formatting control (reportlab-based, no external dependency)
3. **Fallback**: If the pdf skill is unavailable and `weasyprint` is installed: `python3 -c "import weasyprint; weasyprint.HTML('output/report.html').write_pdf('output/report.pdf')"`
4. **Last resort**: Inform user HTML is available, suggest browser print-to-PDF
5. Write to `output/report.pdf`

**DOCX** (Word):
1. **Preferred**: Invoke `Skill(document-skills:docx)` to create the DOCX from the markdown report with professional formatting (headings, ToC, hyperlinked citations). The docx skill produces production-grade Word documents with no external dependency
2. **Fallback**: If the docx skill is unavailable, check if `pandoc` is available: `which pandoc`. If so: `pandoc output/report.md -o output/report.docx --from markdown --to docx`
3. **Last resort**: Inform user and suggest `brew install pandoc` or `apt install pandoc`
4. Write to `output/report.docx`

**Presentation** (optional):
- If cogni-visual is available, delegate: `Skill(cogni-visual:presentation-brief)`
- Generates a presentation brief from the report

### Phase 2: Report to User

- List exported files with paths and file sizes
- Preview: show first 5 lines of the HTML or confirm PDF page count
- Suggest next steps (share, present, further research)

## Supported Formats

| Format | Output Path | Requirements | Quality |
|--------|-------------|-------------|---------|
| Markdown | `output/report.md` | None (always available) | Source format |
| HTML | `output/report.html` | None (generated inline) | Best for sharing |
| PDF | `output/report.pdf` | `document-skills:pdf` (preferred) or weasyprint | Best for printing |
| DOCX | `output/report.docx` | `document-skills:docx` (preferred) or pandoc | Best for editing/collaboration |

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| `output/report.md` not found | Check if drafts exist — suggest completing review loop first |
| `output/report.md` is empty | Report error, suggest re-running Phase 4 (writer) |
| pdf skill unavailable + weasyprint not installed | Generate HTML, suggest `pip install weasyprint` or browser print-to-PDF |
| docx skill unavailable + pandoc not installed | Inform user, suggest `brew install pandoc` or `apt install pandoc` |
| HTML generation fails | Fall back to markdown copy with formatting note |
| cogni-visual not available | Skip presentation option, note in output |
