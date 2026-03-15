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
