# Format Export Procedures

The PDF and DOCX procedures enrich-report Phase 6 follows when `formats` includes `pdf` or `docx` — Mermaid and Chart.js pre-rendering, the preferred / fallback / last-resort chain for each format, and the output naming.

## Contents
- PDF export
- DOCX export

## PDF export

1. Read `references/07-citation-normalization.md` — not for HTML citations (which are already correct), but for understanding the citation landscape in case pre-processing is needed.
2. **Mermaid pre-rendering**: If the HTML contains `<pre class="mermaid">` blocks, these render client-side via JavaScript and will appear blank in static PDF conversion. Pre-render them before PDF generation:
   - Try `mmdc` (mermaid-cli): extract Mermaid source → render to SVG → replace in HTML
   - Fallback: use Excalidraw MCP (`mcp__excalidraw__create_from_mermaid` → `export_to_image`)
   - Last resort: leave as code blocks and note the limitation to the user
3. **Chart.js pre-rendering**: Chart.js `<canvas>` elements also require JavaScript. For PDF with charts, `document-skills:pdf` can execute JS during rendering. If using weasyprint (no JS), charts will be blank — inform the user and suggest `density=none` for chart-free PDF.
4. **Generate PDF**:
   - Preferred: `Skill(document-skills:pdf)` from the enriched HTML. Pass `design-variables.json` for theme token access.
   - Fallback: If weasyprint is available: `python3 -c "import weasyprint; weasyprint.HTML(filename='{html_path}').write_pdf('{pdf_path}')"`
   - Last resort: Inform user the HTML is available and suggest browser print-to-PDF
5. Output: `{output_dir}/{stem}-enriched.pdf` (scroll) or `{output_dir}/{stem}-enriched-flipbook.pdf` (flipbook). Mirror the layout suffix from the HTML filename.

## DOCX export

DOCX cannot represent interactive charts or inline SVG. Convert from the original markdown source (not the HTML) to preserve clean document structure.

1. Read `references/07-citation-normalization.md` for citation normalization patterns.
2. Normalize citations in the markdown: parse the `## References` section, replace inline citation patterns with numbered superscript markers, strip the original references section.
3. **Generate DOCX**:
   - Preferred: `Skill(document-skills:docx)` from the normalized markdown. Pass theme tokens: `heading_font` (fonts.headers), `body_font` (fonts.body), `accent_color` (colors.accent).
   - Fallback: If pandoc is available: `pandoc {md_path} -o {docx_path} --from markdown --to docx`
   - Last resort: Inform user and suggest `brew install pandoc` or `pip install pandoc`
4. Output: `{output_dir}/{stem}.docx`
