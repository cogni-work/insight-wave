# Report Structure Reference

Formal A4 PDF report layout specification for cogni-research output.

## Page Setup

- **Format**: A4 (210mm x 297mm / 595.28 x 841.89 points)
- **Margins**: Top 25mm, Bottom 20mm, Left 25mm, Right 20mm
- **Header**: 10mm zone -- project title (left), page number (right)
- **Footer**: 5mm zone -- theme branding line or copyright

## Section Sequence

### 1. Cover Page (1 page, no header/footer)

```
+-----------------------------------------+
|                                         |
|     [Theme accent bar]                  |
|                                         |
|                                         |
|     RESEARCH TITLE                      |
|     (from research-hub.md              |
|      frontmatter title)                 |
|                                         |
|     Research Type Badge                 |
|     (e.g., "Strategic Research")        |
|                                         |
|     Date: YYYY-MM-DD                    |
|                                         |
|   +-----+ +-----+ +-----+ +-----+      |
|   |  5  | | 670 | | 120 | | 988 |      |
|   |Dim. | |Find.| |Src. | |Claim|      |
|   +-----+ +-----+ +-----+ +-----+      |
|                                         |
|     [Theme primary bar]                 |
+-----------------------------------------+
```

Number play boxes show 4 research statistics (Dimensions, Findings, Sources, Claims). Pre-sorted ascending by value. Labels localized (en/de).

**Data sources:**
- Title: `research-hub.md` frontmatter `title`
- Research type: `sprint-log.json` -> `research_type`
- Date: `sprint-log.json` -> `created_at` or current date
- Number play: entity file counts

### 2. Table of Contents (1-2 pages)

Auto-generated from section headings with dot-leader page numbers.

```
Table of Contents

Executive Summary .......................... 3
Appendix: Research Scope .................. 5
Source Index ............................... 7
```

### 3. Executive Summary (1-2 pages)

**Source:** `insight-summary.md` (if present), otherwise `executive-summary.md`

- Full narrative text rendered as body paragraphs
- Story arc badge rendered as subtitle if `arc_id` is in frontmatter
- If neither file exists: skip section entirely

### 4. Appendix: Research Scope (1 page)

**Source:** `00-research-scope.md` (if present)

- Methodology description
- Dimension overview table (dimension name, question count, finding count)
- Evidence scale explanation
- If file missing: skip section

### 5. Source Index (variable length)

**Source:** `05-sources/data/source-*.md`

Sources now include publisher and citation data inline. Formal numbered bibliography:

```
Sources

[1]  Chen, L., Rodriguez, M. (2025). "Machine Learning in Manufacturing."
     Journal of Manufacturing Systems. DOI: 10.1234/example.
     Accessed: 2025-01-15. Tier: 1 (Academic).

[2]  McKinsey & Company (2024). "Digital Transformation Report."
     mckinsey.com. Accessed: 2025-01-10. Tier: 2 (Industry).
```

Each entry includes:
- Sequential number (referenced from body text)
- Authors (from source entity)
- Title
- Publication / journal / domain
- DOI if available
- Access date
- Reliability tier

**Ordering:** By reliability tier (tier-1 first), then alphabetical by title

## Entity Types (7 total)

| # | Directory | Entity | Description |
|---|-----------|--------|-------------|
| 00 | `00-initial-question` | Initial Question | Original research question |
| 01 | `01-research-dimensions` | Dimension | Research dimension definitions |
| 02 | `02-refined-questions` | Question | Refined research questions |
| 03 | `03-query-batches` | Query Batch | Search query batches |
| 04 | `04-findings` | Finding | Web research findings |
| 05 | `05-sources` | Source | Source metadata with publisher + citation |
| 06 | `06-claims` | Claim | Verified claims |

## Typography Hierarchy

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Cover title | 28pt | Bold | `--color-primary` |
| Section heading (H2) | 16pt | Bold | `--color-primary` |
| Subsection (H3) | 13pt | SemiBold | `--color-primary` |
| Body text | 10pt | Regular | `--color-text-primary` |
| Caption / metadata | 8pt | Regular | `--color-text-muted` |
| Badge text | 7pt | Medium | Varies by badge type |
| Source index | 9pt | Regular | `--color-text-primary` |
| Page header | 8pt | Regular | `--color-text-muted` |
| Page number | 8pt | Regular | `--color-text-muted` |

## Page Break Rules

- Always before: Cover, TOC, Source Index
- Never: within a paragraph, within a table row
