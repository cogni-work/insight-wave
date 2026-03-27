# Export Formats Reference

## HTML Template

The HTML export uses a self-contained template with CSS custom properties. When `output/design-variables.json` exists, substitute theme tokens into the `:root` block. When no design variables are available, the fallback values (after the `|` pipe) produce the same clean default styling as before.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{report_title}</title>
  {google_fonts_import}
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({startOnLoad: true, theme: 'neutral'});</script>
  <style>
    :root {
      --color-bg: {colors.background|#ffffff};
      --color-surface: {colors.surface|#f8f8f8};
      --color-text: {colors.text|#333333};
      --color-text-muted: {colors.text_muted|#888888};
      --color-accent: {colors.accent|#0066cc};
      --color-link: {colors.link|#0066cc};
      --color-link-visited: {colors.link_visited|#004499};
      --color-border: {colors.border|#cccccc};
      --color-toc-bg: {colors.toc_background|#f8f8f8};
      --color-blockquote-border: {colors.blockquote_border|#cccccc};
      --color-source-ref: {colors.source_ref|#888888};
      --font-headers: {fonts.headers|Georgia, serif};
      --font-body: {fonts.body|Georgia, serif};
      --font-mono: {fonts.mono|monospace};
      --radius: {radius|4px};
    }
    body {
      font-family: var(--font-body);
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.6;
      color: var(--color-text);
      background: var(--color-bg);
    }
    h1 {
      font-family: var(--font-headers);
      border-bottom: 2px solid var(--color-text);
      padding-bottom: 0.5rem;
    }
    h2 {
      font-family: var(--font-headers);
      color: var(--color-text);
      margin-top: 2rem;
    }
    h3 {
      font-family: var(--font-headers);
    }
    a {
      color: var(--color-link);
      text-decoration: underline;
    }
    a:visited {
      color: var(--color-link-visited);
    }
    blockquote {
      border-left: 3px solid var(--color-blockquote-border);
      padding-left: 1rem;
      color: var(--color-text-muted);
    }
    .source-ref {
      font-size: 0.85em;
      color: var(--color-source-ref);
    }
    .source-ref a {
      color: var(--color-link);
      text-decoration: underline;
    }
    /* Superscript citation references */
    .citation-ref {
      vertical-align: super;
      font-size: 0.75em;
      line-height: 0;
    }
    .citation-ref a {
      color: var(--color-link);
      text-decoration: none;
      font-weight: 600;
    }
    .citation-ref a:hover {
      text-decoration: underline;
    }
    /* References section at bottom */
    .references-section {
      margin-top: 3rem;
      border-top: 2px solid var(--color-border);
      padding-top: 1rem;
    }
    .references-section ol {
      padding-left: 1.5rem;
      font-size: 0.9em;
    }
    .references-section li {
      margin-bottom: 0.5rem;
    }
    .references-section a {
      color: var(--color-link);
      word-break: break-all;
    }
    .toc {
      background: var(--color-toc-bg);
      padding: 1rem;
      border-radius: var(--radius);
      margin: 1rem 0;
    }
    .toc ul {
      list-style: none;
      padding-left: 1rem;
    }
    .toc a {
      color: var(--color-link);
      text-decoration: underline;
    }
    .meta {
      color: var(--color-text-muted);
      font-size: 0.9em;
      margin-bottom: 2rem;
    }
    code {
      font-family: var(--font-mono);
      background: var(--color-surface);
      padding: 0.15em 0.3em;
      border-radius: 3px;
      font-size: 0.9em;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1rem 0;
    }
    th, td {
      border: 1px solid var(--color-border);
      padding: 0.5rem 0.75rem;
      text-align: left;
    }
    th {
      background: var(--color-surface);
      font-family: var(--font-headers);
    }

    /* Mermaid diagram blocks */
    pre.mermaid {
      text-align: center;
      max-width: 800px;
      margin: 1.5rem auto;
      background: transparent;
      border: none;
      padding: 0;
    }
    /* Figure captions (italicized line after diagrams) */
    figure {
      margin: 1.5rem auto;
      text-align: center;
      max-width: 800px;
    }
    figcaption {
      font-style: italic;
      font-size: 0.9em;
      color: var(--color-text-muted);
      margin-top: 0.5rem;
    }

    @media print {
      body { max-width: 100%; padding: 1rem; font-size: 11pt; }
      .toc { page-break-after: always; }
      h2 { page-break-before: always; }
      a { color: var(--color-link); text-decoration: underline; }
      a[href]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: var(--color-text-muted); }
      .source-ref { font-size: 0.75em; }
      .citation-ref a[href]::after { content: ""; }  /* suppress URL expansion for superscript refs */
      .references-section { page-break-before: always; }
    }
  </style>
</head>
<body>
  {content}
</body>
</html>
```

The `{google_fonts_import}` placeholder is either a `<style>@import url(...);</style>` tag from the design-variables `google_fonts_import` field, or empty if no theme is selected or the theme uses system fonts.

Each `{token|fallback}` notation means: use the design variable value if present, otherwise use the hardcoded fallback. Values are baked in at generation time — this is not a runtime mechanism.

## Design Variables Integration

When `<project-dir>/output/design-variables.json` exists, load it and inject tokens into the HTML template:

1. Read the JSON file
2. Extract `colors`, `fonts`, `google_fonts_import`, `radius`
3. Compute report-specific derived tokens if not already present:
   - `link` = `accent` (darken if contrast ratio < 4.5:1 against `background`)
   - `link_visited` = darken `link` by 15%
   - `toc_background` = `surface`
   - `blockquote_border` = `border`
   - `source_ref` = `text_muted`
4. Substitute values into the HTML template's `:root` custom properties
5. If `google_fonts_import` is non-empty, wrap in `<style>` tag and place in `<head>`

When no `design-variables.json` exists, use the fallback values directly (identical to the previous hardcoded template).

## Markdown to HTML Conversion

Use Python stdlib `html` module for escaping, plus simple regex-based markdown conversion:
- `# heading` → `<h1>heading</h1>`
- `**bold**` → `<strong>bold</strong>`
- `[text](url)` → `<a href="url">text</a>` — preserves clickable links
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

## Mermaid Diagram Handling

### HTML Export

Mermaid code blocks in the markdown report are rendered client-side by the Mermaid CDN script already included in the HTML template. During MD→HTML conversion:

1. Detect fenced ` ```mermaid ` code blocks
2. Convert them to `<pre class="mermaid">` elements (NOT `<code>` — Mermaid.js expects `<pre class="mermaid">` or `<div class="mermaid">`)
3. Wrap each diagram and its caption in a `<figure>` element:

```html
<figure>
  <pre class="mermaid">
    flowchart LR
      A[Start] --> B[End]
  </pre>
  <figcaption>Figure 1: Description of the diagram.</figcaption>
</figure>
```

The italicized caption line (`*Figure N: ...*`) immediately following a Mermaid block should be extracted and placed inside `<figcaption>`.

### PDF / DOCX Export (Pre-rendering)

Mermaid code blocks must be pre-rendered to images before PDF or DOCX conversion, since these formats cannot execute JavaScript.

**Pre-rendering fallback chain:**

1. **mermaid-cli** (`mmdc`): Check `which mmdc`. If available:
   ```bash
   mmdc -i diagram.mmd -o output/images/diagram-N.svg -t neutral --width 800
   ```
   Replace the `<pre class="mermaid">` block with `<img src="output/images/diagram-N.svg" alt="Figure N description">`.

2. **Excalidraw MCP**: If `mmdc` is not available but Excalidraw MCP tools are accessible, use `mcp__excalidraw__create_from_mermaid` to convert each Mermaid block, then `mcp__excalidraw__export_to_image` to export as PNG.

3. **Fallback**: If neither pre-renderer is available, leave Mermaid blocks as styled `<pre><code>` blocks in the output. Add a note in the Phase 3 report:
   > "Diagrams appear as code blocks in PDF/DOCX. For rendered diagrams, install mermaid-cli: `npm install -g @mermaid-js/mermaid-cli`"

## Citation Normalization

When generating HTML, normalize all inline citations to superscript numbered references regardless of the input citation format. This produces consistent, professional rendering with clickable source links.

### Processing Order

1. `parse_references_section(md_text)` — extract reference map
2. `strip_references_section(md_text)` — remove trailing `## References` from markdown
3. `normalize_inline_citations(md_text, ref_map)` — replace all citation patterns with `<sup>[N](URL)</sup>` markers
4. Standard MD→HTML conversion (headings, bold, links, etc.)
5. `convert_sup_markers_to_html(html_text)` — style the superscript markers
6. Append `build_references_html(references)` before `</body>`

### Step 1: Parse the References Section

Build a map from reference number to `{title, url}` by parsing the trailing `## References` block:

```python
import re

def parse_references_section(md_text: str) -> dict:
    """Parse ## References entries into {number: {title, url}} map."""
    ref_map = {}
    ref_match = re.search(r'\n## References\s*\n([\s\S]*?)$', md_text)
    if not ref_match:
        return ref_map

    for line in ref_match.group(1).strip().split('\n'):
        line = line.strip()
        if not line:
            continue

        # Format A: [N] Title. Retrieved from|Available at: URL
        # or:       [N] Title. URL
        m = re.match(
            r'\[(\d+)\]\s+(.+?)\.?\s+(?:(?:Retrieved from|Available at:?)\s+)?(https?://\S+)',
            line
        )
        if m:
            ref_map[int(m.group(1))] = {
                'title': m.group(2).strip(),
                'url': m.group(3).strip()
            }
            continue

        # Format B: N. Title. [URL](URL)  — numbered list with markdown link
        m = re.match(
            r'(\d+)\.\s+(.+?)\s+\[https?://[^\]]*\]\((https?://[^\)]+)\)',
            line
        )
        if m:
            ref_map[int(m.group(1))] = {
                'title': m.group(2).strip().rstrip('.'),
                'url': m.group(3).strip()
            }
            continue

        # Format C: N. Title. https://URL  — numbered list with bare URL
        m = re.match(
            r'(\d+)\.\s+(.+?)\s+(https?://\S+)\s*$',
            line
        )
        if m:
            ref_map[int(m.group(1))] = {
                'title': m.group(2).strip().rstrip('.'),
                'url': m.group(3).strip()
            }
            continue

    return ref_map
```

### Step 2: Normalize Inline Citations

Detect all citation patterns and replace with intermediate `<sup>[N](URL)</sup>` markers. Process patterns from most specific to least specific to avoid double-matching:

```python
from collections import OrderedDict

def normalize_inline_citations(md_text: str, ref_map: dict) -> tuple:
    """Replace all citation formats with <sup>[N](URL)</sup> markers.
    Returns (modified_text, references_list)."""
    references = OrderedDict()  # url -> {number, title, url}
    counter = [0]

    def get_or_assign(url: str, title: str) -> int:
        if url not in references:
            counter[0] += 1
            references[url] = {'number': counter[0], 'title': title, 'url': url}
        return references[url]['number']

    # Pattern 1: Wikilink with anchor — <sup>[[N]](#ref-N)</sup>
    def repl_wikilink_anchor(m):
        num = int(m.group(1))
        ref = ref_map.get(num, {})
        url = ref.get('url', f'#ref-{num}')
        title = ref.get('title', f'Reference {num}')
        n = get_or_assign(url, title)
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'<sup>\[\[(\d+)\]\]\(#ref-\d+\)</sup>', repl_wikilink_anchor, md_text
    )

    # Pattern 2: Wikilink with URL — [[N]](url)
    # Common hybrid format: double-bracket number with standard markdown URL
    def repl_wikilink_url(m):
        num = int(m.group(1))
        url = m.group(2)
        ref = ref_map.get(num, {})
        title = ref.get('title', f'Reference {num}')
        n = get_or_assign(url, title)
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'\[\[(\d+)\]\]\((https?://[^\)]+)\)', repl_wikilink_url, md_text
    )

    # Pattern 3: Chicago — <sup>[N](url)</sup>
    def repl_chicago(m):
        url = m.group(2)
        n = get_or_assign(url, f'Reference {m.group(1)}')
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'<sup>\[(\d+)\]\((https?://[^\)]+)\)</sup>', repl_chicago, md_text
    )

    # Pattern 4: IEEE — [[N](url)]
    def repl_ieee(m):
        url = m.group(2)
        n = get_or_assign(url, f'Reference {m.group(1)}')
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'\[\[(\d+)\]\((https?://[^\)]+)\)\]', repl_ieee, md_text
    )

    # Pattern 5: APA/MLA/Harvard — ([Author, Year](url)) or ([Author](url))
    def repl_apa(m):
        title = m.group(1)
        url = m.group(2)
        n = get_or_assign(url, title)
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'\(\[([^\]]+)\]\((https?://[^\)]+)\)\)', repl_apa, md_text
    )

    # Pattern 6: Bare source ref — [Source: Publisher](url)
    def repl_source(m):
        title = m.group(1)
        url = m.group(2)
        n = get_or_assign(url, title)
        return f'<sup>[{n}]({url})</sup>'
    md_text = re.sub(
        r'\[Source:\s*([^\]]+)\]\((https?://[^\)]+)\)', repl_source, md_text
    )

    # Pattern 7: Bare wikilink group — [[1], [2], [3]] or [[4]]
    # This is the most common malformed pattern — numbers without URLs
    def repl_bare_wikilink(m):
        full = m.group(0)
        nums = re.findall(r'\[(\d+)\]', full)
        parts = []
        for num_str in nums:
            num = int(num_str)
            ref = ref_map.get(num, {})
            url = ref.get('url', f'#ref-{num}')
            title = ref.get('title', f'Reference {num}')
            n = get_or_assign(url, title)
            parts.append(f'<sup>[{n}]({url})</sup>')
        return ''.join(parts)
    md_text = re.sub(
        r'\[\[(\d+)\](?:,\s*\[(\d+)\])*\]', repl_bare_wikilink, md_text
    )

    return md_text, list(references.values())
```

### Step 3: Convert Markers to HTML

After MD→HTML conversion, convert the intermediate `<sup>[N](url)</sup>` markers to styled superscript links:

```python
def convert_sup_markers_to_html(html_text: str) -> str:
    """Convert <sup>[N](url)</sup> markers to citation-ref spans."""
    def repl(m):
        num = m.group(1)
        url = m.group(2)
        return (
            f'<sup class="citation-ref">'
            f'<a href="{url}" title="Reference {num}">[{num}]</a>'
            f'</sup>'
        )
    return re.sub(
        r'<sup>\[(\d+)\]\((https?://[^\)]+)\)</sup>', repl, html_text
    )
```

### Step 4: Build References Section HTML

Generate the numbered references list and insert before `</body>`:

```python
def build_references_html(references: list) -> str:
    """Build <div class="references-section"> with numbered <ol>."""
    if not references:
        return ""
    items = []
    for ref in references:
        n = ref['number']
        title = ref['title']
        url = ref['url']
        items.append(
            f'  <li id="ref-{n}" value="{n}">'
            f'{title} &mdash; <a href="{url}">{url}</a>'
            f'</li>'
        )
    return (
        '<div class="references-section">\n'
        '<h2>References</h2>\n'
        '<ol>\n' + '\n'.join(items) + '\n</ol>\n'
        '</div>'
    )
```

Insert the output just before `</body>` in the final HTML template.

### Strip Original References

Remove the trailing `## References` section from markdown before conversion — the HTML references section replaces it:

```python
def strip_references_section(md_text: str) -> str:
    """Remove trailing ## References from markdown."""
    return re.sub(r'\n## References\s*\n[\s\S]*$', '', md_text)
```

## PDF Generation

If `weasyprint` is available:
```python
from weasyprint import HTML
HTML(filename='output/report.html').write_pdf('output/report.pdf')
```

Weasyprint preserves `<a href>` elements as clickable PDF hyperlinks automatically.

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

## DOCX Generation

If `pandoc` is available, convert markdown to Word format:

```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --highlight-style=tango
```

Pandoc preserves `[text](url)` markdown links as clickable Word hyperlinks.

Optional: use a reference docx for custom styling:
```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --reference-doc=template.docx
```

### Themed DOCX

When `design-variables.json` exists and `document-skills:docx` is available, pass theme tokens as parameters:
- `heading_font`: fonts.headers
- `body_font`: fonts.body
- `accent_color`: colors.accent (used for heading color)
- `link_color`: colors.link (used for hyperlink color)

For pandoc fallback, generate a minimal `reference.docx` with:
- Custom heading styles using the theme's header font and accent color
- Body text using the theme's body font
- Hyperlink character style preserving the link color

If neither `document-skills:docx` nor reference doc generation is available, plain pandoc output without theming is acceptable — the user still gets a working Word document with clickable links.

Check availability:
```bash
which pandoc && echo "pandoc available" || echo "pandoc not found"
```

Fallback: inform user to install pandoc (`brew install pandoc` on macOS, `apt install pandoc` on Linux).

## Conversion Fallback Chain

Use this decision logic to select the best available converter:

```
1. weasyprint available?
   → Yes: HTML → PDF via weasyprint (best quality, supports print CSS, preserves hyperlinks)
   → No: continue

2. pandoc available?
   → Yes: MD → DOCX via pandoc (for Word format, preserves clickable links)
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
