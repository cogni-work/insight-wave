---
library_id: pptx-render-recipe
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# PPTX Render Recipe

How a **pptxgenjs** renderer turns a presentation brief into a `.pptx`. The brief's field schema is `pptx-layouts.md`; this file is the rendering half — canvas and starting positions, theme-to-palette and font mapping, notes, citations, the `Source` footer, Mermaid-to-shape rules, charts, the references slide, and the QA loop that proves the deck still says what the brief says.

**This is guidance, not an API.** Every position below is a starting point a renderer may adjust to fit its text; every rule names a pptxgenjs call (`slide.addText`, `slide.addNotes`, `slide.addShape`, `slide.addChart`) and never a helper library — there is no component file to import, and a renderer that finds itself wanting one should write the call inline. The brief's `# Rendering Contract` binds throughout: copy is frozen, notes travel complete, citations become hyperlinks, styling comes only from the theme, and `Layout` is a content shape to map onto the nearest native arrangement.

The in-Claude-Code path is `agents/pptx.md`, which hands this file and the brief to the installed Anthropic pptx skill (`anthropic-skills:pptx`, or `document-skills:pptx` from the marketplace) and then runs the QA below. The claude.ai path attaches the brief and a theme and states the same contract in its prompt.

## Canvas

- 16:9, **10 × 5.625 in**; all coordinates below are inches from the top-left origin.
- Content area starts at `x = 0.7` and spans `8.6` in; the slide title sits at `y = 0.35`, `h = 0.6`; the optional bottom banner at `y = 4.7`, `h = 0.5`.
- Heights inside a layout may flex within these bounds; a renderer shrinks a box before it shrinks a font, and moves overflow to the notes rather than clipping it — the producer already budgeted words per field (`density-*` checks), so overflow signals a font too large for the box, not copy to cut.

## Starting positions per layout

Element tables and internal box layouts per layout, moved here from the schema. Point sizes are the values the original geometry was tuned for on this canvas.

### title-slide

#### Elements

| Element | X | Y | W | H | Alignment |
|---------|---|---|---|---|-----------|
| title | 1.0 | 1.8 | 8.0 | 1.2 | center |
| subtitle | 1.0 | 3.2 | 8.0 | 0.6 | center |
| metadata | 1.0 | 4.2 | 8.0 | 0.4 | center |
| logo | 4.5 | 0.4 | 1.0 | 0.6 | center |

### stat-card-with-context

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| leftBorder | 0.62 | 1.2 | 0.08 | 3.0 | Accent strip (optional) |
| heroStatBox | 0.7 | 1.2 | 4.0 | 3.0 | Large stat card |
| statNumber | 0.85 | 1.4 | 3.7 | 0.55 | Number (36pt, bold) |
| statLabel | 0.85 | 1.95 | 3.7 | 0.3 | Label (13pt, bold) |
| statSublabel | 0.85 | 2.25 | 3.7 | 0.25 | Sublabel (10pt, optional) |
| impactBox | 0.85 | 3.7 | 3.7 | 0.35 | Impact callout (optional) |
| contextBox | 5.1 | 1.2 | 4.6 | 3.0 | Context area |
| contextHeadline | 5.25 | 1.35 | 4.3 | 0.4 | Context headline (16pt, bold) |
| contextBullets | 5.25 | 1.85 | 4.3 | 2.0 | Bullet points (14pt) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer bar (optional) |

### four-quadrants

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| quadrant1 | 0.7 | 1.2 | 4.2 | 1.5 | Top-left card |
| quadrant2 | 5.1 | 1.2 | 4.2 | 1.5 | Top-right card |
| quadrant3 | 0.7 | 2.8 | 4.2 | 1.5 | Bottom-left card |
| quadrant4 | 5.1 | 2.8 | 4.2 | 1.5 | Bottom-right card |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

#### Quadrant Internal Layout — Stat-Card Mode (default)

When `Number` is present, each quadrant renders as a stat card:
- **Number**: 24pt, bold, top-aligned
- **Label**: 12pt, bold, below number
- **Sublabel**: 10pt, optional, below label
- **Icon**: 32×32px, optional, top-right corner

#### Quadrant Internal Layout — Text-Card Mode

When `Number` is absent and `Bullets` is present, each quadrant renders as a text card with a thin accent bar at top:
- **Accent bar**: 4px height, full card width, primary or accent color (Champion card uses theme accent)
- **Label**: 14pt, bold, muted color — role or category name
- **Sublabel**: 14pt, normal, body color — person title or description
- **Bullets**: 9pt, normal, body color — 3-4 key messages, max 10 words each. Think McKinsey slide bullet — a phrase the audience scans in one glance, not a sentence they read. Longer bullets wrap to illegibility at 9pt in 4.2" width. First bullet often formatted as "Lead with: {approach}"

### two-columns-equal

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| leftColumn | 0.7 | 1.2 | 4.0 | 3.3 | Left content area |
| rightColumn | 5.2 | 1.2 | 4.0 | 3.3 | Right content area |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

#### Column Internal Layout

Each column can contain:
- **Headline**: 18pt, bold
- **Body Text**: 14pt, 3-6 bullet points
- **Image/Chart**: Variable height
- **Callout Box**: Highlighted info

### is-does-means

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| isBox | 0.7 | 1.2 | 8.6 | 0.9 | IS layer (What) |
| doesBox | 0.7 | 2.2 | 8.6 | 0.9 | DOES layer (How) |
| meansBox | 0.7 | 3.2 | 8.6 | 0.9 | MEANS layer (Evidence) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

#### Box Internal Layout

Each box contains:
- **Layer Label**: "IS" / "DOES" / "MEANS" (12pt, badge)
- **Content**: 14pt text. Each box fits ONE line (~15-20 words) at 12pt in 0.9" height. Write like a billboard line or conference badge tagline — phrase notation, NOT full sentences. Full sentences force font shrinking to illegibility.
- **Separator**: Subtle divider line

### three-options

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| option1 | 0.7 | 1.2 | 2.7 | 3.0 | Left option |
| option2 | 3.6 | 1.2 | 2.7 | 3.0 | Center option |
| option3 | 6.5 | 1.2 | 2.7 | 3.0 | Right option |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

#### Option Internal Layout

Each option contains:
- **Header**: 14pt, bold, option name
- **Price/Value**: 18pt, bold (if pricing)
- **Features**: 12pt bullets, 3-5 items
- **Badge**: "Recommended" or similar (optional)

### timeline-steps

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| step1 | 0.7 | 1.5 | 1.5 | 1.8 | Step 1 box |
| arrow1 | 2.3 | 2.3 | 0.3 | 0.2 | Arrow 1→2 |
| step2 | 2.7 | 1.5 | 1.5 | 1.8 | Step 2 box |
| arrow2 | 4.3 | 2.3 | 0.3 | 0.2 | Arrow 2→3 |
| step3 | 4.7 | 1.5 | 1.5 | 1.8 | Step 3 box |
| arrow3 | 6.3 | 2.3 | 0.3 | 0.2 | Arrow 3→4 |
| step4 | 6.7 | 1.5 | 1.5 | 1.8 | Step 4 box |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

#### Step Internal Layout

Each step contains:
- **Number**: 18pt, bold, top
- **Label**: 13pt, bold, step name
- **Description**: 11pt, 2-3 lines
- **Duration**: 10pt, optional

### layered-architecture

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| lane1Zone | 0.7 | 1.2 | dynamic | 3.3 | Lane 1 background zone |
| lane2Zone | dynamic | 1.2 | dynamic | 3.3 | Lane 2 background zone |
| lane3Zone | dynamic | 1.2 | dynamic | 3.3 | Lane 3 background zone (optional) |
| laneHeaders | per lane | 1.2 | per lane | 0.3 | Lane labels (muted, uppercase) |
| nodeBoxes | per node | per node | per node | 0.55 | Rounded rectangles with text |
| arrows | computed | computed | computed | - | Connectors with optional labels |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Lane widths are computed dynamically: `laneWidth = (8.6 - (laneCount - 1) × 0.3) / laneCount`. Nodes are centered vertically within their lane.

### process-flow

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| node1-N | computed | 1.8 | computed | 1.2 | Node boxes (3-6) |
| arrow1-N | computed | 2.3 | 0.3 | - | Arrow connectors between nodes |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Node widths are computed dynamically: `nodeWidth = min(2.0, (8.6 - (nodeCount - 1) × 0.3) / nodeCount)`.

#### Node Internal Layout

Each node contains:
- **Label**: 13pt, bold, centered
- **Description**: 10pt, normal, below label (from Mermaid node text after `\n`)

### gantt-chart

#### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| timeAxis | 3.4 | 1.2 | 6.2 | 0.35 | Month/quarter labels |
| phaseHeaders | 0.7 | per phase | 2.6 | 0.25 | Phase group labels |
| taskLabels | 0.7 | per task | 2.6 | 0.30 | Task name labels (left) |
| taskBars | computed | per task | computed | 0.30 | Colored bars (right) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Bar X and width are computed from task start dates and durations relative to the total date range.

#### Status Styling

| Mermaid Status | Visual Style |
|----------------|-------------|
| `:done` | Primary color, 40% transparency, checkmark |
| `:active` | Primary color, full opacity, accent border |
| `:crit` | Danger/warning color, full opacity |
| (unmarked) | Tertiary background, dashed border |

### closing-slide

#### Elements

| Element | X | Y | W | H | Alignment |
|---------|---|---|---|---|-----------|
| title | 1.0 | 1.8 | 8.0 | 1.2 | center |
| subtitle | 1.0 | 3.2 | 8.0 | 0.6 | center |
| metadata | 1.0 | 4.2 | 8.0 | 0.4 | center |
| logo | 4.5 | 0.4 | 1.0 | 0.6 | center |

## Palette

Colors come from the theme, never from the brief.

1. When the theme directory carries `manifest.json` with `tiers.tokens`, read the token tier (the `tokens/` directory: `tokens.css` or its JSON sibling) and map: primary → headline and accent bars, secondary → sublabels and muted text, background and surface → slide and card fills, danger/warning → gantt `:crit` bars.
2. Otherwise read `theme.md` → `## Color Palette` and take each named color's hex value. pptxgenjs wants hex **without** the `#` — strip it once at load time and pass six-digit strings everywhere.
3. Hyperlink runs use `0563C1` unless the theme names a link color.
4. `design.dark_slides` in the brief frontmatter lists slides rendered dark as rhythm anchors: swap background and text colors on exactly those slides.

## Fonts

`theme.md` → `## Typography` names a heading and a body face, each with a fallback chain. PowerPoint renders the user's fonts, not the renderer's: pick the **first entry of the fallback chain that is on the safe list** (Arial, Calibri, Georgia, Times New Roman, Verdana, Trebuchet MS, Segoe UI) and write that name into the deck. Report the substitution in the render result (`fonts_substituted: [{wanted, used}]`) so the consultant knows what to expect on a machine that lacks the brand face.

## Speaker notes

`Speaker-Notes` travels **verbatim** into `slide.addNotes(text)` — both `>>` sections, every tag, every `[N](url)` link as plain text. Do not summarise, do not drop the second section, do not convert markdown. A slide without `Speaker-Notes` gets no notes call.

## Citations

An inline `<sup>[N](url)</sup>` marker becomes a hyperlink **run on the number**, superscripted, inside the text-run array of the field it sits in:

```javascript
slide.addText([
  { text: 'Security staff cannot cover all areas 24/7 ', options: { bullet: true } },
  { text: '1', options: { superscript: true, hyperlink: { url: 'https://eba.bund.de/report' }, color: '0563C1' } }
], { x: 5.25, y: 1.85, w: 4.3, h: 2.0, fontSize: 14 });
```

Set `bullet: true` on the first run only. A field with no marker is a single run. Markers never appear in headlines, banners, hero-stat fields or step labels, so those are always plain single runs.

## Source footer

`Source: "[Label](URL)"` renders as one small text run (10pt, muted) positioned above the bottom banner (`x = 0.7`, `y = 4.45`, `w = 8.6`, `h = 0.25`), the label carrying `hyperlink: { url }`. Two pipe-separated sources become two runs separated by ` | `.

## Mermaid to native shapes

`Diagram` is data. Parse the Mermaid text and draw editable shapes — never an image.

- **layered-architecture** (`graph LR` with subgraphs): one lane per subgraph, `laneWidth = (8.6 - (laneCount - 1) × 0.3) / laneCount`; a muted uppercase lane header at `y = 1.2`, `h = 0.3`; nodes as rounded rectangles `h = 0.55` centered vertically in their lane; edges as connectors with optional labels; `-.->` renders dashed.
- **process-flow** (`graph LR`, no subgraphs): nodes evenly spaced at `y = 1.8`, `h = 1.2`, `nodeWidth = min(2.0, (8.6 - (nodeCount - 1) × 0.3) / nodeCount)`; arrows `w = 0.3` between them; node text after `\n` becomes a smaller description line. When the slide carries `Detail-Grid`, list each node's items under its box.
- **gantt-chart** (`gantt`): task labels left (`x = 0.7`, `w = 2.6`), a time axis at `y = 1.2` from `x = 3.4`, `w = 6.2`, one bar per task with `x` and `w` computed from start date and duration over the total range, row height from the task count. Status styling: `:done` primary at 40% transparency, `:active` primary with accent border, `:crit` danger color, unmarked tertiary fill with dashed border.

## Charts

`visual.chart` is native series data: `slide.addChart(pptx.ChartType[type], data, options)` with `categories[]` as labels and each `series[{name, values[]}]` as one data series, `unit` in the axis title. Never render a chart as an image, and never invent a chart for a slide whose `visual.kind` is not `chart`.

## References slide

The slide carrying `Slide-Kind: references` is rendered with the `two-columns-equal` positions and stays the **last** slide in the deck. Each bullet is `[N] Label — URL`; make the URL a hyperlink run and keep the plain URL text visible so it survives printing.

## QA

Render, then prove the deck against the brief before reporting success:

1. **Round trip** — `python3 "$CLAUDE_PLUGIN_ROOT/scripts/brief-render-qa.py" --brief <brief> --pptx <deck>` reads the deck's slide and notes XML and reports `text_missing[]`, `notes_missing[]`, `links_expected`, `links_found`, `links_missing[]` and `slide_count`. Anything in `text_missing` or `notes_missing` is a Rendering Contract breach: fix the generator and re-render, once.
2. **File validation** — the pptx skill's own `scripts/office/validate.py <deck>` checks schema, relationships, content types and chart parts and names the fix for each fault.
3. **Visual review** — when LibreOffice (`soffice`) is present, render thumbnails and look at every slide for overflow, clipped text and mis-scaled fonts; when it is absent, report the step as skipped rather than silently passing it.

The agent returns all three results in its JSON `qa` block.
