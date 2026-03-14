# Theme-to-PDF Style Mapping

How CSS variables from `cogni-workplace/themes/{theme-id}/theme.md` map to ReportLab PDF styles.

## Overview

The HTML export uses CSS variables directly in `report-layout.css`. The PDF export extracts the same variables from theme.md but maps them to ReportLab style objects (colors, fonts, paragraph styles).

## Color Extraction

Extract CSS variables from `## CSS Variable Reference` block in theme.md:

```python
import re

def extract_theme_colors(theme_md_path):
    """Extract CSS variables from theme.md into a dict."""
    content = open(theme_md_path).read()
    pattern = r'## CSS Variable Reference.*?```css\n(.*?)```'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return get_fallback_colors()

    colors = {}
    for line in match.group(1).split('\n'):
        m = re.match(r'\s*--([\w-]+):\s*(.+?);', line)
        if m:
            colors[m.group(1)] = m.group(2).strip()
    return colors
```

## Color Variable Mapping

| CSS Variable | PDF Usage | ReportLab Type |
|-------------|-----------|----------------|
| `--color-primary` | Chapter headings, cover title, HR lines | `colors.HexColor()` |
| `--color-primary-dark` | Cover accent bar | `colors.HexColor()` |
| `--color-primary-light` | Section number prefixes | `colors.HexColor()` |
| `--color-accent` | Highlight boxes, trend badges | `colors.HexColor()` |
| `--color-accent-light` | Badge backgrounds | `colors.HexColor()` with alpha |
| `--color-bg-primary` | Page background (usually white) | Not needed (white default) |
| `--color-bg-secondary` | Callout boxes, sidebar backgrounds | `colors.HexColor()` |
| `--color-bg-tertiary` | Table header backgrounds | `colors.HexColor()` |
| `--color-text-primary` | Body text | `colors.HexColor()` |
| `--color-text-secondary` | Subheadings, metadata | `colors.HexColor()` |
| `--color-text-muted` | Captions, page headers, footnotes | `colors.HexColor()` |
| `--color-border` | Table borders, separator lines | `colors.HexColor()` |
| `--color-dim-1` to `--color-dim-8` | Dimension chapter accent colors | `colors.HexColor()` |

## Font Mapping

CSS font stacks map to the closest available ReportLab font:

| CSS Variable | Example Value | ReportLab Font |
|-------------|---------------|----------------|
| `--font-primary` | `'TeleNeoWeb', sans-serif` | `Helvetica` (default sans) |
| `--font-heading` | `'TeleNeo ExtraBold', Georgia, serif` | `Helvetica-Bold` or `Times-Bold` |
| `--font-mono` | `'SF Mono', monospace` | `Courier` |

ReportLab has 14 built-in PDF fonts (no installation needed):
- `Helvetica`, `Helvetica-Bold`, `Helvetica-Oblique`, `Helvetica-BoldOblique`
- `Times-Roman`, `Times-Bold`, `Times-Italic`, `Times-BoldItalic`
- `Courier`, `Courier-Bold`, `Courier-Oblique`, `Courier-BoldOblique`
- `Symbol`, `ZapfDingbats`

For custom fonts (TTF/OTF), use `pdfmetrics.registerFont()` — but the built-in fonts cover most needs.

**Font selection logic:**
1. If theme font stack contains `serif` keyword: use `Times-Roman` family
2. If theme font stack contains `mono` keyword: use `Courier` family
3. Default: use `Helvetica` family

## Paragraph Style Definitions

```python
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY

def create_styles(theme_colors):
    """Create ReportLab paragraph styles from theme colors."""
    primary = HexColor(theme_colors.get('color-primary', '#0d3c55'))
    accent = HexColor(theme_colors.get('color-accent', '#00d7e9'))
    text = HexColor(theme_colors.get('color-text-primary', '#0d3c55'))
    muted = HexColor(theme_colors.get('color-text-muted', '#5a7a8a'))

    return {
        'CoverTitle': ParagraphStyle(
            'CoverTitle', fontSize=28, leading=34,
            fontName='Helvetica-Bold', textColor=primary,
            alignment=TA_CENTER, spaceAfter=12
        ),
        'ChapterHeading': ParagraphStyle(
            'ChapterHeading', fontSize=22, leading=26,
            fontName='Helvetica-Bold', textColor=primary,
            spaceBefore=0, spaceAfter=12
        ),
        'SectionHeading': ParagraphStyle(
            'SectionHeading', fontSize=16, leading=20,
            fontName='Helvetica-Bold', textColor=primary,
            spaceBefore=18, spaceAfter=8
        ),
        'SubsectionHeading': ParagraphStyle(
            'SubsectionHeading', fontSize=13, leading=16,
            fontName='Helvetica-Bold', textColor=primary,
            spaceBefore=12, spaceAfter=6
        ),
        'BodyText': ParagraphStyle(
            'BodyText', fontSize=10, leading=14,
            fontName='Helvetica', textColor=text,
            alignment=TA_JUSTIFY, spaceAfter=6
        ),
        'Caption': ParagraphStyle(
            'Caption', fontSize=8, leading=10,
            fontName='Helvetica', textColor=muted,
            spaceAfter=4
        ),
        'SourceEntry': ParagraphStyle(
            'SourceEntry', fontSize=9, leading=12,
            fontName='Helvetica', textColor=text,
            leftIndent=24, firstLineIndent=-24, spaceAfter=6
        ),
        'BadgeText': ParagraphStyle(
            'BadgeText', fontSize=7, leading=9,
            fontName='Helvetica-Bold'
        ),
        'GlossaryTerm': ParagraphStyle(
            'GlossaryTerm', fontSize=10, leading=14,
            fontName='Helvetica-Bold', textColor=text
        ),
        'GlossaryDef': ParagraphStyle(
            'GlossaryDef', fontSize=9, leading=13,
            fontName='Helvetica', textColor=text,
            leftIndent=12, spaceAfter=8
        ),
    }
```

## Badge Rendering

Badges are rendered as inline `Table` cells with colored backgrounds:

```python
from reportlab.platypus import Table, TableStyle

def render_badge(text, bg_color, text_color):
    """Create a badge as a small styled table cell."""
    style = TableStyle([
        ('BACKGROUND', (0, 0), (0, 0), bg_color),
        ('TEXTCOLOR', (0, 0), (0, 0), text_color),
        ('FONTNAME', (0, 0), (0, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (0, 0), 7),
        ('TOPPADDING', (0, 0), (0, 0), 2),
        ('BOTTOMPADDING', (0, 0), (0, 0), 2),
        ('LEFTPADDING', (0, 0), (0, 0), 6),
        ('RIGHTPADDING', (0, 0), (0, 0), 6),
        ('ROUNDEDCORNERS', [3, 3, 3, 3]),
    ])
    t = Table([[text]], colWidths=[None])
    t.setStyle(style)
    return t
```

## Badge Color Mapping

| Badge Type | Background CSS Variable | Text Color |
|-----------|------------------------|------------|
| Horizon ACT | `--color-badge-horizon-act` | Dark green |
| Horizon PLAN | `--color-badge-horizon-plan` | Dark amber |
| Horizon OBSERVE | `--color-badge-horizon-observe` | Dark gray |
| Evidence Strong | `--color-badge-evidence-strong` | Dark green |
| Evidence Moderate | `--color-badge-evidence-moderate` | Dark amber |
| Evidence Weak | `--color-badge-evidence-weak` | Dark red |
| Confidence | `--color-badge-confidence` | Dark accent |
| Dimension | `--color-badge-dimension` | Primary |

## Fallback Colors

When theme is not found, use the same defaults as the HTML export:

```python
FALLBACK_COLORS = {
    'color-primary': '#0d3c55',
    'color-primary-dark': '#091f2c',
    'color-primary-light': '#1a5276',
    'color-accent': '#00d7e9',
    'color-accent-light': '#4de8f4',
    'color-bg-primary': '#ffffff',
    'color-bg-secondary': '#f8fafb',
    'color-bg-tertiary': '#e8f4f8',
    'color-text-primary': '#0d3c55',
    'color-text-secondary': '#2c5364',
    'color-text-muted': '#5a7a8a',
    'color-border': '#d4dfe5',
    'color-dim-1': '#00b8d4',
    'color-dim-2': '#5b2c6f',
    'color-dim-3': '#1e8449',
    'color-dim-4': '#ff6b4a',
    'color-dim-5': '#3b82f6',
    'color-dim-6': '#8b5cf6',
    'color-dim-7': '#ec4899',
    'color-dim-8': '#f59e0b',
}
```
