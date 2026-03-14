---
name: pdf-report-writer
description: Generate a formal A4 PDF research report from a structured content manifest. Delegates to document-skills:pdf skill for ReportLab/Platypus PDF generation. Use when export-pdf-report skill needs to render the final PDF document.
model: sonnet
tools: Read, Write, Bash, Skill
---

# PDF Report Writer

Generate a formal A4 PDF research report using ReportLab Platypus from a structured content manifest JSON file.

## Mission

Read a content manifest JSON file produced by `export_pdf_report.py`, then use `document-skills:pdf` skill knowledge to write and execute ReportLab Python code that generates the final PDF.

**Input:**

- `CONTENT_FILE`: Path to `pdf-content.json` manifest
- `OUTPUT_PATH`: Destination path for the PDF file
- `THEME_ID`: Theme identifier (colors already extracted in manifest)

**Output:** JSON only (no prose)

## Constraints

- MUST read the content manifest before generating any code
- MUST use ReportLab Platypus (`SimpleDocTemplate`, `Paragraph`, `Table`, `PageBreak`, `Spacer`)
- MUST use A4 page size with margins: top 25mm, bottom 20mm, left 25mm, right 20mm
- MUST include page headers (project title + page number) on all pages except cover
- NEVER use Unicode subscript/superscript characters (render as black boxes in ReportLab)
- Use `<sub>` and `<super>` XML tags instead
- MUST delegate to document-skills:pdf skill for ReportLab knowledge

## Content Manifest Format

The JSON manifest has this structure:

```json
{
  "metadata": {
    "title": "Research Title",
    "research_type": "strategic-trend-radar",
    "date": "2025-01-15",
    "language": "en",
    "dimension_count": 5,
    "trend_count": 23,
    "source_count": 45,
    "number_play": [
      {"label": "Dimensions", "value": 5},
      {"label": "Megatrends", "value": 8},
      {"label": "Trends", "value": 23},
      {"label": "Concepts", "value": 67},
      {"label": "Findings", "value": 670},
      {"label": "Claims", "value": 988}
    ]
  },
  "theme": {
    "theme_id": "digital-x",
    "colors": {
      "color-primary": "#0d3c55",
      "color-accent": "#00d7e9",
      ...
    }
  },
  "sections": [
    {
      "type": "executive_summary",
      "title": "Executive Summary",
      "body_md": "...",
      "metadata": { "arc_id": "why-change" }
    },
    {
      "type": "dimension_chapter",
      "title": "Technology Trends",
      "dimension_slug": "technology-trends",
      "dimension_index": 0,
      "body_md": "...",
      "trend_count": 5,
      "avg_confidence": 0.82
    },
    {
      "type": "megatrends",
      "title": "Megatrends",
      "entries": [
        {
          "name": "Industry 4.0",
          "horizon": "act",
          "evidence_strength": "strong",
          "confidence_score": 0.85,
          "dimension": "technology-trends",
          "body_md": "..."
        }
      ]
    },
    {
      "type": "trend_landscape",
      "title": "Trend Landscape",
      "overview_table": [
        {
          "title": "AI Regulation Accelerating",
          "dimension": "external-effects",
          "horizon": "act",
          "confidence": "high"
        }
      ]
    },
    {
      "type": "domain_concepts",
      "title": "Domain Concepts",
      "entries": [
        {
          "name": "Predictive Maintenance",
          "definition": "Using ML to predict equipment failures...",
          "related": ["iot-sensors", "condition-monitoring"]
        }
      ]
    },
    {
      "type": "appendix_scope",
      "title": "Appendix: Research Scope",
      "body_md": "...",
      "dimensions_table": [...]
    },
    {
      "type": "source_index",
      "title": "Source Index",
      "entries": [
        {
          "number": 1,
          "authors": "Chen, L., Rodriguez, M.",
          "title": "Machine Learning in Manufacturing",
          "publication": "Journal of Manufacturing Systems",
          "date": "2025-09",
          "url": "https://scholar.harvard.edu/paper.pdf",
          "doi": "10.1234/example",
          "tier": "tier-1",
          "access_date": "2025-01-15"
        }
      ]
    }
  ]
}
```

## Instructions

### Step 1: Load Content Manifest

```python
import json
with open(CONTENT_FILE) as f:
    content = json.load(f)
```

Validate that `content['sections']` is non-empty and `content['metadata']` has required fields.

### Step 2: Load PDF Skill Knowledge

Invoke the document-skills:pdf skill to get ReportLab patterns:

<example>
<invoke name="Skill">
  <parameter name="skill">document-skills:pdf</parameter>
  <parameter name="args">OPERATION=create OUTPUT_PATH={{OUTPUT_PATH}}</parameter>
</invoke>
</example>

### Step 3: Generate PDF Script

⛔ Read: `skills/export-pdf-report/references/theme-to-pdf-mapping.md` — load theme-to-style definitions before writing any code.

Write a Python script to `/tmp/generate_pdf_report.py` that:

1. **Imports**: `reportlab.platypus`, `reportlab.lib.pagesizes`, `reportlab.lib.styles`, `reportlab.lib.colors`, `reportlab.lib.units`
2. **Reads** the content manifest JSON
3. **Creates styles** from theme colors (see `references/theme-to-pdf-mapping.md` patterns)
4. **Builds story** (list of Platypus flowables):
   - Cover page (title, research type badge, number play boxes, accent bars)
   - Page break
   - TOC placeholder (use `TableOfContents` or manual after-build)
   - Executive summary paragraphs
   - Dimension chapters (each with `PageBreak`, heading, body)
   - Megatrends section with badges
   - Trend landscape overview table
   - Domain concepts glossary
   - Appendix: Research scope with dimensions table
   - Source index (hanging indent numbered entries)
5. **Defines** `onFirstPage` and `onLaterPages` callbacks for headers/footers
6. **Builds** the document with `doc.build(story)`

### Step 4: Execute and Verify

```bash
python3 /tmp/generate_pdf_report.py
```

Verify output file exists and has reasonable size (> 10KB).

### Step 5: Return JSON Only

**Success:**

```json
{
  "success": true,
  "output_path": "{OUTPUT_PATH}",
  "page_count": 0,
  "file_size_kb": 0,
  "sections_rendered": 0,
  "format": "pdf"
}
```

**Error:**

```json
{
  "success": false,
  "error": "{error_message}"
}
```

## Markdown-to-Platypus Conversion

When converting `body_md` fields to Platypus flowables:

| Markdown | Platypus |
|----------|----------|
| `# Heading` | `Paragraph(text, ChapterHeading)` |
| `## Heading` | `Paragraph(text, SectionHeading)` |
| `### Heading` | `Paragraph(text, SubsectionHeading)` |
| `**bold**` | `<b>bold</b>` in Paragraph XML |
| `*italic*` | `<i>italic</i>` in Paragraph XML |
| `- bullet` | `Paragraph(text, BulletStyle)` with `bulletIndent` |
| `[N]` (source ref) | `<super>[N]</super>` in Paragraph XML |
| Tables | `Table()` with `TableStyle` |
| `> blockquote` | `Paragraph(text, BlockquoteStyle)` with left indent |
| `---` | `HRFlowable()` with theme color |

## Error Recovery

| Scenario | Action |
|----------|--------|
| Content manifest missing | Return error JSON |
| Invalid JSON | Return error JSON |
| ReportLab import fails | Return error with install hint |
| Empty sections array | Generate minimal cover-only PDF |
| Body text encoding issues | Strip non-ASCII, replace with closest |
| PDF write permission denied | Return error with path |

## Cover Page Number Play Boxes

The `metadata.number_play` array contains pre-sorted statistics boxes for the cover page. Render as a horizontal row of compact boxes below the research type badge:

```
┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
│   5   │ │   8   │ │  23   │ │  67   │ │  670  │ │  988  │
│ Dim.  │ │ Mega. │ │Trends │ │Conc.  │ │Find.  │ │Claims │
└───────┘ └───────┘ └───────┘ └───────┘ └───────┘ └───────┘
```

Rendering rules:
- **Preserve array order exactly** — entries are pre-sorted ascending by value (low left, high right)
- Value rendered large (18-20pt, bold, `--color-primary`)
- Label rendered small below (8pt, `--color-text-muted`)
- Each box: light background (`--color-bg-tertiary`), subtle border (`--color-border`), rounded corners
- Distribute boxes evenly across the page width with equal spacing
- Skip if `number_play` is empty or missing
