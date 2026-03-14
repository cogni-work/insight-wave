# Report Structure Reference

Formal A4 PDF report layout specification for deeper-research output.

## Page Setup

- **Format**: A4 (210mm x 297mm / 595.28 x 841.89 points)
- **Margins**: Top 25mm, Bottom 20mm, Left 25mm, Right 20mm
- **Header**: 10mm zone — project title (left), page number (right)
- **Footer**: 5mm zone — theme branding line or copyright

## Section Sequence

### 1. Cover Page (1 page, no header/footer)

```
┌──────────────────────────────────────┐
│                                      │
│     [Theme accent bar]               │
│                                      │
│                                      │
│     RESEARCH TITLE                   │
│     (from research-hub.md            │
│      frontmatter title)              │
│                                      │
│     Research Type Badge              │
│     (e.g., "Strategic Trend Radar")  │
│                                      │
│     Date: YYYY-MM-DD                 │
│                                      │
│   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│   │  5  │ │  8  │ │ 52  │ │ 67  │  │
│   │Dim. │ │Mega.│ │Trend│ │Conc.│  │
│   └─────┘ └─────┘ └─────┘ └─────┘  │
│   ┌─────┐ ┌─────┐                   │
│   │ 670 │ │ 988 │                   │
│   │Find.│ │Claim│                   │
│   └─────┘ └─────┘                   │
│                                      │
│     [Theme primary bar]              │
└──────────────────────────────────────┘
```

Number play boxes show 6 research statistics (Dimensions, Megatrends, Trends, Concepts, Findings, Claims). Pre-sorted ascending by value. Labels localized (en/de).

**Data sources:**
- Title: `research-hub.md` frontmatter `title`
- Research type: `sprint-log.json` → `research_type`
- Date: `sprint-log.json` → `created_at` or current date
- Number play: `insight-summary.md` frontmatter `stats_*` fields (preferred), or entity file counts as fallback

### 2. Table of Contents (1-2 pages)

Auto-generated from section headings with dot-leader page numbers.

```
Table of Contents

Executive Summary .......................... 3
1  Dimension: Technology Trends ........... 5
2  Dimension: Market Dynamics ............. 12
3  Dimension: External Effects ............ 19
Megatrends ................................ 26
Trend Landscape ........................... 31
Domain Concepts ........................... 33
Appendix: Research Scope .................. 36
Source Index ............................... 38
```

### 3. Executive Summary (1-2 pages)

**Source:** `insight-summary.md` (if present), otherwise `executive-summary.md`

- Full narrative text rendered as body paragraphs
- Story arc badge rendered as subtitle if `arc_id` is in frontmatter
- If neither file exists: skip section entirely

### 4. Dimension Chapters (variable length)

**Source:** `12-synthesis/synthesis-*.md` — one chapter per dimension

Each chapter:
- Chapter number + dimension title as heading (colored with dimension palette)
- Full synthesis body text
- Wikilinks resolved to source references
- Inline badges for trend count, confidence, evidence freshness
- Page break before each new chapter

**Ordering:** By dimension order in `01-research-dimensions/data/`

### 5. Megatrends (variable length)

**Source:** `06-megatrends/data/megatrend-*.md`

Each megatrend entry:
- Megatrend name as H2
- Planning horizon badge (ACT/PLAN/OBSERVE)
- Evidence strength badge
- Dimension affinity
- Body text (TIPS or generic structure)
- Finding count as metadata line

**Ordering:** By `confidence_score` descending, then `planning_horizon` (act > plan > observe)

### 6. Trend Landscape (1-2 pages)

**Source:** `11-trends/data/trend-*.md` and `portfolio-*.md`

Overview table of all trends:

| # | Trend | Dimension | Horizon | Confidence |
|---|-------|-----------|---------|------------|
| 1 | AI Regulation | External Effects | ACT | High |
| 2 | Edge Computing | Technology | PLAN | Medium |

**Ordering:** Grouped by dimension, then by `planning_horizon` (act first)

### 7. Domain Concepts (compact)

**Source:** `05-domain-concepts/data/concept-*.md`

Glossary-style layout:
- Concept name in bold
- Definition as inline text
- Related concepts as comma-separated list
- 2-column layout if space permits

**Ordering:** Alphabetical by `dc:title`

### 8. Appendix: Research Scope (1 page)

**Source:** `00-research-scope.md` (if present)

- Methodology description
- Dimension overview table (dimension name, question count, finding count)
- Evidence scale explanation
- If file missing: skip section

### 9. Source Index (variable length)

**Source:** `07-sources/data/source-*.md` + `08-publishers/` + `09-citations/data/citation-*.md`

Formal numbered bibliography:

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
- Authors (from source entity or publisher)
- Title
- Publication / journal / domain
- DOI if available
- Access date
- Reliability tier

**Ordering:** By reliability tier (tier-1 first), then alphabetical by title

## Typography Hierarchy

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Cover title | 28pt | Bold | `--color-primary` |
| Chapter heading (H1) | 22pt | Bold | Dimension color |
| Section heading (H2) | 16pt | Bold | `--color-primary` |
| Subsection (H3) | 13pt | SemiBold | `--color-primary` |
| Body text | 10pt | Regular | `--color-text-primary` |
| Caption / metadata | 8pt | Regular | `--color-text-muted` |
| Badge text | 7pt | Medium | Varies by badge type |
| Source index | 9pt | Regular | `--color-text-primary` |
| Page header | 8pt | Regular | `--color-text-muted` |
| Page number | 8pt | Regular | `--color-text-muted` |

## Badge Rendering

Badges in the PDF are rendered as inline colored rectangles with text:

```
┌──────────┐  ┌─────┐  ┌──────────────┐
│ ACT      │  │ 85% │  │ Strong       │
│ (green)  │  │     │  │ (green tint) │
└──────────┘  └─────┘  └──────────────┘
```

Badge color mapping:
- **Horizon ACT**: green background, dark text
- **Horizon PLAN**: amber background, dark text
- **Horizon OBSERVE**: gray background, dark text
- **Evidence Strong**: green tint
- **Evidence Moderate**: amber tint
- **Evidence Weak**: red tint
- **Confidence %**: accent tint
- **Dimension**: dimension palette color

## Page Break Rules

- Always before: Cover, TOC, each Dimension Chapter, Megatrends section, Trend Landscape section, Source Index
- Never: within a paragraph, within a table row
