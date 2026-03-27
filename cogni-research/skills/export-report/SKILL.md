---
name: export-report
description: |
  Export a completed research report to different formats: Markdown (default), HTML, PDF, or DOCX.
  Supports branded theming via cogni-workspace:pick-theme — applies theme colors and fonts to all visual exports.
  Use when the user asks to "export report", "save as HTML", "export to PDF", "export to Word",
  "export to DOCX", "publish report", "convert report", "download report", "share the report",
  "make it pretty", or wants the research output in a specific format for sharing or presentation.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill
---

# Export Report Skill

## Quick Example

**User**: "Export the report as HTML"

**Result**: Self-contained HTML file alongside `report.md` (e.g., `output/report.html`) with:
- Theme-branded typography and colors (or professional defaults if no theme selected)
- Auto-generated table of contents
- Clickable source links (visually distinct in both screen and print)
- Print-optimized CSS that preserves link visibility

## Prerequisites

- Completed research project with a finalized `report.md`
- For PDF: `weasyprint` Python package (optional, falls back to browser print-to-PDF)

## Workflow

### Phase 0: Locate Report

The export skill needs to find the right project and verify the report exists. Without a completed report, there is nothing to export — and exporting a draft mid-review would publish unverified content.

1. Find the project directory (ask user if ambiguous)
2. Locate `report.md` within the project (typically `output/report.md`, but may reside elsewhere). Verify it exists (NOT `draft-v*.md` — only the finalized report)
3. Derive `REPORT_DIR` — the parent directory of the located `report.md`. All exported files will be written to `REPORT_DIR` alongside the source report
4. Determine requested format(s) from user request

### Phase 1: Pick Theme and Derive Design Variables

**This phase is NOT optional.** Every HTML, PDF, or DOCX export must go through theme selection before generating output. Without a theme, exports use generic Georgia fonts and plain blue links — defeating the purpose of branded reports. Do NOT skip to Phase 2 without completing theme derivation or confirming fallback.

**Step 1 — Select theme:**
- If caller already provided a `theme_path`, use it directly
- Otherwise, call `cogni-workspace:pick-theme` — it discovers all available themes (both standard and workspace), handles auto-selection when only one theme exists, and returns `theme_path`, `theme_name`, and `theme_slug`
- Do NOT search the filesystem for themes manually — pick-theme is the single source of truth for theme discovery

**Step 2 — Derive design-variables.json:**
1. Read the selected `theme.md` at the returned `theme_path`
2. Read `cogni-workspace/references/design-variables-pattern.md` for the derivation convention
3. Read `cogni-workspace/schemas/examples/design-variables-cogni-work.json` as a structural reference
4. Extract the token groups below into a JSON structure
5. Compute the report-specific derived tokens (link colors, toc background, etc.)
6. Write the result to `{REPORT_DIR}/design-variables.json`

**Required core tokens** (from `design-variables-pattern.md`):

| Group | Tokens | Notes |
|-------|--------|-------|
| `colors` | `background`, `surface`, `text`, `accent`, `border` | Foundation palette from theme |
| `colors` | `text_muted`, `text_light`, `surface_dark` | Derived variants |
| `fonts` | `headers`, `body`, `mono` | Font stacks with system fallbacks |
| `google_fonts_import` | Full `@import url(...)` string | Empty string if using system fonts |
| `radius` | Corner radius value | From theme or default `4px` |

**Report-specific derived tokens** (extend the standard design-variables):

| Token | Derived From | Purpose |
|-------|-------------|---------|
| `colors.link` | `accent` | Citation hyperlinks — must meet WCAG AA contrast against `background` |
| `colors.link_visited` | darken `link` by 15% | Visited citation links |
| `colors.toc_background` | `surface` | Table of contents background |
| `colors.blockquote_border` | `border` | Blockquote left border |
| `colors.source_ref` | `text_muted` | Source reference annotations |

**Step 3 — Verify** before proceeding: confirm `{REPORT_DIR}/design-variables.json` exists and contains `colors`, `fonts`, and `google_fonts_import` keys.

**Fallback**: If no themes are found at all (empty themes directory), proceed with hardcoded defaults and inform the user: "No themes found — using default styling. Add a theme via cogni-workspace for branded exports." The export must never fail because of missing themes — but the fallback path should be the exception, not the norm.

### Phase 2: Export

Each format builds on the previous — HTML is generated from markdown, PDF from HTML. This cascade means the markdown source is always the single source of truth.

**Citation clickability**: All citation links (`[Source: Publisher](URL)` or configured citation style) must remain clickable in every export format. Links must be visually distinct (colored + underlined) in both screen and print views. Never strip `href` attributes or flatten links to plain text.

**Citation normalization for HTML**: The markdown report may use various citation formats (APA inline `([Author](url))`, wikilink `[[N]]`, IEEE `[[N](url)]`, bare `[Source: X](url)`). During HTML conversion, normalize ALL inline citations to superscript numbered references:
- Body: `<sup class="citation-ref"><a href="URL" title="Source title">[N]</a></sup>`
- Bottom: `<div class="references-section">` with numbered `<ol>` of clickable source links
- See `references/export-formats.md` § "Citation Normalization" for the conversion patterns

For wikilink `[[N]]` citations without embedded URLs: resolve reference numbers against the `## References` section at the bottom of the markdown, extract the URL from each reference entry, and link the superscript directly to that source URL.

**Markdown** (always available):
- `{REPORT_DIR}/report.md` is already the markdown output
- Optionally copy to a user-specified location

**HTML**:
1. Read `references/export-formats.md` for the HTML template (includes Mermaid CDN script and diagram CSS)
2. Read `{REPORT_DIR}/report.md`
3. If `{REPORT_DIR}/design-variables.json` exists, inject theme tokens into the HTML template's CSS custom properties. If no design variables, use the hardcoded fallback values in the template.
4. If `google_fonts_import` is non-empty, insert it as a `<style>` tag in `<head>`
5. **Mermaid diagrams**: Convert fenced ` ```mermaid ` code blocks to `<pre class="mermaid">` elements. Wrap each diagram + its caption in `<figure>/<figcaption>`. See `references/export-formats.md` § "Mermaid Diagram Handling" for conversion details. The Mermaid CDN script in the template handles client-side rendering.
6. Generate self-contained HTML with: table of contents from headings, clickable source links (underlined, colored), clean typography
7. Write to `{REPORT_DIR}/report.html`

**PDF**:
1. First generate HTML (as above) — the HTML already carries theme styling
2. **Pre-render Mermaid diagrams**: If the report contains Mermaid code blocks, they must be pre-rendered before PDF conversion (PDF cannot execute JavaScript). Follow the pre-rendering fallback chain in `references/export-formats.md` § "PDF / DOCX Export": try `mmdc` first, then Excalidraw MCP, then fall back to code blocks with a user note.
3. **Preferred**: Invoke `Skill(document-skills:pdf)` to create the PDF from HTML with full formatting control (reportlab-based, no external dependency). Pass `{REPORT_DIR}/design-variables.json` if it exists so the skill can apply theme tokens to PDF-native elements.
4. **Fallback**: If the pdf skill is unavailable and `weasyprint` is installed: `python3 -c "import weasyprint; weasyprint.HTML('{REPORT_DIR}/report.html').write_pdf('{REPORT_DIR}/report.pdf')"` — weasyprint preserves `<a href>` hyperlinks automatically.
5. **Last resort**: Inform user HTML is available, suggest browser print-to-PDF
6. Write to `{REPORT_DIR}/report.pdf`

**DOCX** (Word):
1. **Pre-render Mermaid diagrams**: Same as PDF — Mermaid code blocks must be pre-rendered to PNG before DOCX conversion. Follow the same fallback chain (mmdc → Excalidraw MCP → code blocks). Save rendered images to `{REPORT_DIR}/images/` and replace Mermaid blocks with `![Figure N](images/diagram-N.png)` in the markdown before conversion.
2. **Preferred**: Invoke `Skill(document-skills:docx)` to create the DOCX from the markdown report with professional formatting (headings, ToC, hyperlinked citations). Pass theme tokens if available: `heading_font` (fonts.headers), `body_font` (fonts.body), `accent_color` (colors.accent), `link_color` (colors.link). The docx skill preserves markdown links as Word hyperlinks.
3. **Fallback**: If the docx skill is unavailable, check if `pandoc` is available: `which pandoc`. If so: `pandoc {REPORT_DIR}/report.md -o {REPORT_DIR}/report.docx --from markdown --to docx`. Pandoc preserves `[text](url)` as clickable Word hyperlinks.
4. **Last resort**: Inform user and suggest `brew install pandoc` or `apt install pandoc`
5. Write to `{REPORT_DIR}/report.docx`

**Presentation** (optional):
- If cogni-visual is available, delegate: `Skill(cogni-visual:presentation-brief)`
- Generates a presentation brief from the report

### Phase 3: Report to User

- List exported files with paths and file sizes
- Mention which theme was applied (or "default styling" if no theme)
- Preview: show first 5 lines of the HTML or confirm PDF page count
- Suggest next steps (share, present, further research)

## Supported Formats

| Format | Output Path | Requirements | Quality |
|--------|-------------|-------------|---------|
| Markdown | `{REPORT_DIR}/report.md` | None (always available) | Source format |
| HTML | `{REPORT_DIR}/report.html` | None (generated inline) | Best for sharing |
| PDF | `{REPORT_DIR}/report.pdf` | `document-skills:pdf` (preferred) or weasyprint | Best for printing |
| DOCX | `{REPORT_DIR}/report.docx` | `document-skills:docx` (preferred) or pandoc | Best for editing/collaboration |

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| `report.md` not found | Check if drafts exist — suggest completing review loop first |
| `report.md` is empty | Report error, suggest re-running Phase 4 (writer) |
| No themes found | Proceed with hardcoded defaults, inform user |
| pdf skill unavailable + weasyprint not installed | Generate HTML, suggest `pip install weasyprint` or browser print-to-PDF |
| docx skill unavailable + pandoc not installed | Inform user, suggest `brew install pandoc` or `apt install pandoc` |
| HTML generation fails | Fall back to markdown copy with formatting note |
| cogni-visual not available | Skip presentation option, note in output |
