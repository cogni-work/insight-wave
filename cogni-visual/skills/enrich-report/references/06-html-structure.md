# HTML Structure

Two-zone layout architecture, CSS patterns, and script structure for the enriched report HTML output.

## Two-Zone Architecture

The output has two distinct zones with different purposes:

1. **Infographic header zone** — Full-width editorial visual executive summary. Scannable in 60 seconds. Contains KPI cards, 1-2 charts, pull-quote, comparison pair. This is where all data visualization storytelling lives.
2. **Report body zone** — Full prose with sidebar navigation. Designed for continuous reading. Contains very sparse illustrations (3-5 max) only where they aid comprehension.

```
┌─────────────────────────────────────────────────────┐
│            INFOGRAPHIC HEADER ZONE                  │
│  (full-width, editorial grid, .infographic-header)  │
│                                                     │
│  Title: Governing Assertion                         │
│  ┌──────────┬──────────┬──────────┐                 │
│  │ KPI Card │ KPI Card │ KPI Card │                 │
│  └──────────┴──────────┴──────────┘                 │
│  ┌───────────────┬─────────────────┐                │
│  │  Chart.js     │  "Pull-quote"   │                │
│  │   ████ ██     │   — Source       │                │
│  └───────────────┴─────────────────┘                │
│  Sources footer                                     │
├─────────────── divider ─────────────────────────────┤
│  ┌──────────┐  ┌─────────────────────────────────┐  │
│  │ Sidebar  │  │  REPORT BODY ZONE               │  │
│  │ (260px)  │  │  (max-width 860px)              │  │
│  │          │  │                                 │  │
│  │ Contents │  │  ## Section heading              │  │
│  │ ● Sec 1  │  │  Paragraph text...              │  │
│  │ ● Sec 2  │  │  Paragraph text...              │  │
│  │   ○ 2.1  │  │  > Blockquote...                │  │
│  │   ○ 2.2  │  │  Paragraph text continues...    │  │
│  │ ● Sec 3  │  │                                 │  │
│  │          │  │  ┌─[Process Flow SVG]────────┐   │  │
│  │          │  │  │  (sparse illustration)    │   │  │
│  │          │  │  └──────────────────────────┘   │  │
│  │          │  │                                 │  │
│  │          │  │  Paragraph text continues...    │  │
│  │          │  │  [Citations preserved]           │  │
│  │          │  │                                 │  │
│  │          │  │  Footer                        │  │
│  └──────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Content-First Layout Rules

The layout supports a reading experience. These rules are enforced by the Python generator script:

1. **Content backbone:** `main.content` is `max-width: 860px` with `padding: 48px 40px`. This is a reading-width column, not a dashboard grid.

2. **Enrichment insets:** All report-body enrichment containers (`.chart-container`, `.concept-diagram`, `.summary-card`) are `max-width: 720px` with `margin: 32px auto`. The 140px width difference creates visual subordination — enrichments are clearly insets within the text flow.

3. **Chart height limits in report body:** Charts are moderate height to avoid dominating the page:
   - Doughnut/distribution: 300px max
   - Bar/line/radar: 300px max (hard cap 400px for bar charts with 6+ items)
   - Timeline: 200px max
   - Summary cards: auto height

4. **Prohibited in report body:** The following patterns signal "dashboard" and are only allowed in the infographic header:
   - KPI card grids (`.kpi-row`, `.ig-kpi-card`)
   - Hero banners or splash sections
   - Key-findings grids
   - Sticky horizontal table-of-contents bars
   - Section-lead cards that replace prose with 1-sentence summaries
   - More than 2 consecutive enrichments without intervening prose

5. **Typography primacy.** Body text uses `line-height: 1.7` and `var(--font-body)` at browser default size. Headings use `var(--font-headers)` with clear hierarchy (h1: 2.2rem, h2: 1.6rem, h3: 1.2rem, h4: 1.05rem).

6. **Section structure.** Each section follows: heading → prose → (optional enrichment) → more prose. Enrichments appear BETWEEN paragraphs at natural reading breaks, never before the first paragraph.

## CSS Architecture

All styles use CSS custom properties from `:root {}` — no hardcoded values in component styles.

**Design token categories:**
- Colors: `--primary`, `--secondary`, `--accent`, `--accent-muted`, `--accent-dark`, `--bg`, `--surface`, `--surface2`, `--surface-dark`, `--border`, `--text`, `--text-light`, `--text-muted`
- Status: `--status-success`, `--status-warning`, `--status-danger`, `--status-info`
- Typography: `--font-headers`, `--font-body`, `--font-mono`
- Spacing: `--radius`, `--shadow-sm`, `--shadow-md`, `--shadow-lg`, `--shadow-xl`

## Enrichment Container Classes

| Class | Purpose | Max-Width |
|-------|---------|-----------|
| `.chart-container` | Chart.js canvas wrapper | 720px |
| `.concept-diagram` | Concept diagram SVG wrapper | 720px |
| `.summary-card` | Key takeaway callout | 720px |
| `.kpi-row` | Flex container for KPI cards | 720px |
| `.kpi-card` | Individual metric card | 220px |

All enrichment containers are centered with `margin: 32px auto` to create visual breathing room between prose and visualizations.

## Chart.js Integration

Chart.js is loaded once from CDN in `<head>`:
```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
```

Each chart gets:
1. A `<canvas id="enr-XXX">` element in the content flow
2. An initialization function in the bottom `<script>` block

**Color resolution:** CSS variable tokens in chart configs (`var(--accent)`) are resolved to hex values at build time by the Python generator. Chart.js does not support CSS variables natively.

## SVG Embedding

Concept diagrams are embedded inline as `<svg>` elements (not `<img src>`). This ensures:
- No external file dependencies (self-contained HTML)
- SVG inherits page context (though colors are baked in from export)
- Responsive scaling via `max-width: 100%; height: auto`

## Navigation Sidebar

- **Sticky:** `position: sticky; top: 0; height: 100vh`
- **Scroll spy:** JavaScript tracks scroll position and highlights the current section's nav link
- **Depth indentation:** H2 links flush left, H3 indented 16px, H4 indented 32px
- **Active state:** `.active` class applies accent background color
- **Hidden on mobile:** `display: none` below 1024px viewport width

## Script Block Structure

```html
<script>
document.addEventListener('DOMContentLoaded', function() {
  // 1. Chart.js initializations (one IIFE per chart)
  (function() { new Chart('enr-001', {...}); })();
  (function() { new Chart('enr-002', {...}); })();

  // 2. Scroll spy for navigation
  // Updates .active class on nav links based on scroll position

  // 3. Smooth scroll for nav link clicks (optional)
});
</script>
```

## Responsive Breakpoints

| Breakpoint | Changes |
|-----------|---------|
| > 1024px | Sidebar visible, content max-width 860px |
| 768-1024px | Sidebar hidden, content full width with 20px padding |
| < 768px | KPI cards stack vertically, charts full width, smaller headings |

## File Size Considerations

- Chart.js CDN: ~60KB gzipped (cached across loads)
- Inline SVGs: 5-30KB each depending on complexity
- Total HTML: typically 200-500KB for a fully enriched trend-report
- All self-contained except Chart.js CDN reference
