# Export Formats Reference

## HTML Template

The HTML export uses a self-contained template with inline CSS:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{report_title}</title>
  <style>
    body { font-family: Georgia, serif; max-width: 800px; margin: 0 auto; padding: 2rem; line-height: 1.6; color: #333; }
    h1 { border-bottom: 2px solid #333; padding-bottom: 0.5rem; }
    h2 { color: #555; margin-top: 2rem; }
    a { color: #0066cc; }
    blockquote { border-left: 3px solid #ccc; padding-left: 1rem; color: #666; }
    .source-ref { font-size: 0.85em; color: #888; }
    .toc { background: #f8f8f8; padding: 1rem; border-radius: 4px; margin: 1rem 0; }
    .toc ul { list-style: none; padding-left: 1rem; }
    .meta { color: #888; font-size: 0.9em; margin-bottom: 2rem; }
  </style>
</head>
<body>
  {content}
</body>
</html>
```

## Markdown to HTML Conversion

Use Python stdlib `html` module for escaping, plus simple regex-based markdown conversion:
- `# heading` → `<h1>heading</h1>`
- `**bold**` → `<strong>bold</strong>`
- `[text](url)` → `<a href="url">text</a>`
- `- item` → `<li>item</li>`
- Blank line → `<p>` paragraph break

For richer conversion, check if `markdown` package is available:
```python
try:
    import markdown
    html = markdown.markdown(md_text, extensions=['toc', 'tables'])
except ImportError:
    html = simple_md_to_html(md_text)
```

## PDF Generation

If `weasyprint` is available:
```python
from weasyprint import HTML
HTML(filename='output/report.html').write_pdf('output/report.pdf')
```

Fallback: inform user to open HTML in browser and use "Print to PDF".

## Table of Contents Generation

The HTML template includes a `.toc` CSS class. Generate the ToC from heading tags:

```python
import re

def generate_toc(html_content: str) -> str:
    """Scan for <h2> tags and build a linked table of contents."""
    headings = re.findall(r'<h2[^>]*>(.*?)</h2>', html_content)
    if not headings:
        return ""

    toc_items = []
    for i, heading in enumerate(headings):
        anchor = f"section-{i}"
        toc_items.append(f'<li><a href="#{anchor}">{heading}</a></li>')

    toc_html = f'<div class="toc"><h3>Contents</h3><ul>{"".join(toc_items)}</ul></div>'

    # Inject anchors into headings
    counter = 0
    def add_anchor(match):
        nonlocal counter
        result = f'<h2 id="section-{counter}">{match.group(1)}</h2>'
        counter += 1
        return result

    html_content = re.sub(r'<h2[^>]*>(.*?)</h2>', add_anchor, html_content)
    return toc_html, html_content
```

Insert the ToC after the `.meta` div and before the first `<h2>`.

## Print CSS

Add this `@media print` block to the `<style>` section for clean PDF output:

```css
@media print {
  body { max-width: 100%; padding: 1rem; font-size: 11pt; }
  .toc { page-break-after: always; }
  h2 { page-break-before: always; }
  a { color: #333; text-decoration: none; }
  a[href]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: #666; }
  .source-ref { font-size: 0.75em; }
}
```

## DOCX Generation

If `pandoc` is available, convert markdown to Word format:

```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --highlight-style=tango
```

Optional: use a reference docx for custom styling:
```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --reference-doc=template.docx
```

Check availability:
```bash
which pandoc && echo "pandoc available" || echo "pandoc not found"
```

Fallback: inform user to install pandoc (`brew install pandoc` on macOS, `apt install pandoc` on Linux).

## Conversion Fallback Chain

Use this decision logic to select the best available converter:

```
1. weasyprint available?
   → Yes: HTML → PDF via weasyprint (best quality, supports print CSS)
   → No: continue

2. pandoc available?
   → Yes: MD → DOCX via pandoc (for Word format)
   → Also: MD → HTML via pandoc (alternative to markdown package)
   → No: continue

3. markdown package available?
   → Yes: MD → HTML via markdown(extensions=['toc', 'tables']) → serve as HTML
   → No: continue

4. Fallback: MD → HTML via simple regex converter (built-in)
   → Serve as HTML file
   → Inform user: "Open in browser and use Print to PDF for PDF output"
```

Check availability at runtime:
```python
import shutil

def get_converters():
    available = []
    try:
        import weasyprint
        available.append("weasyprint")
    except ImportError:
        pass
    if shutil.which("pandoc"):
        available.append("pandoc")
    try:
        import markdown
        available.append("markdown")
    except ImportError:
        pass
    if not available:
        available.append("simple")
    return available
```
