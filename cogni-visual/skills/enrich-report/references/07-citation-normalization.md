# Citation Normalization (DOCX Export Path)

When exporting to DOCX format, normalize all inline citations to superscript numbered references regardless of input citation format. This produces consistent, professional rendering with clickable source links in Word documents.

The HTML path does NOT use this normalization — it preserves citations as-is from the source markdown, since clickable `<a>` tags work natively in browsers.

## Processing Order

1. `parse_references_section(md_text)` — extract reference map from trailing `## References`
2. `strip_references_section(md_text)` — remove the references section from markdown
3. `normalize_inline_citations(md_text, ref_map)` — replace all citation patterns with `<sup>[N](URL)</sup>` markers
4. Pass normalized markdown to `document-skills:docx` or pandoc
5. Append references as a numbered list at the end

## Step 1: Parse the References Section

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

        # Format B: N. Title. [URL](URL)
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

        # Format C: N. Title. https://URL
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

## Step 2: Normalize Inline Citations

Detect all citation patterns and replace with intermediate markers. Process from most specific to least specific to avoid double-matching:

```python
from collections import OrderedDict

def normalize_inline_citations(md_text: str, ref_map: dict) -> tuple:
    """Replace all citation formats with <sup>[N](URL)</sup> markers.
    Returns (modified_text, references_list)."""
    references = OrderedDict()
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
    def repl_wikilink_url(m):
        url = m.group(2)
        ref = ref_map.get(int(m.group(1)), {})
        title = ref.get('title', f'Reference {m.group(1)}')
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

    # Pattern 5: APA/MLA/Harvard — ([Author, Year](url))
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

## Strip Original References

```python
def strip_references_section(md_text: str) -> str:
    """Remove trailing ## References from markdown."""
    return re.sub(r'\n## References\s*\n[\s\S]*$', '', md_text)
```

## Supported Citation Formats

| Format | Example | Pattern |
|--------|---------|---------|
| Wikilink+anchor | `<sup>[[1]](#ref-1)</sup>` | Pattern 1 |
| Wikilink+URL | `[[1]](https://...)` | Pattern 2 |
| Chicago | `<sup>[1](https://...)</sup>` | Pattern 3 |
| IEEE | `[[1](https://...)]` | Pattern 4 |
| APA/MLA/Harvard | `([Author, 2025](https://...))` | Pattern 5 |
| Source ref | `[Source: Publisher](https://...)` | Pattern 6 |
| Bare wikilink | `[[1], [2], [3]]` | Pattern 7 |
