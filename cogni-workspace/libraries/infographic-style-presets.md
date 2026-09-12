---
library_id: infographic-style-presets
version: 1.0.0
created: 2026-09-07
---

# Style Presets

Six style presets that control the visual character of infographics. Each preset defines
personality independent of theme colors — the theme provides the palette, the preset provides
the character. Presets are organized into **two rendering families** that determine *which
agent* will render the brief. Choosing a preset is therefore also choosing a renderer.

**Hand-drawn family** (rendered via Excalidraw MCP — two tradition-specific agents, each unconditional so neither drifts toward the other's discipline):
- **sketchnote** — Mike Rohde / graphic recording tradition → `render-infographic-sketchnote`
- **whiteboard** — Dan Roam "Back of the Napkin" / RSA Animate tradition → `render-infographic-whiteboard`

**Editorial family** (rendered by `render-infographic-pencil` via Pencil MCP):
- **economist** (flagship) — The Economist magazine data page
- **editorial** — Harvard Business Review / McKinsey Quarterly
- **data-viz** — Bloomberg Terminal / dashboard-forward
- **corporate** — annual report / compliance document

The preset is stored in the brief frontmatter as `style_preset`. The rendering dispatcher
(`/render-infographic`) reads this value and routes the brief to the right family's agent.

---

# Content Density by Style Preset

Every content-density gate in the skill — the Step 5 self-check, the Step 8 validation layer,
the Step 9 final checks — and the Block Density criterion of the Step 8b review rubric resolves
its ceiling **here**, from the brief's active `style_preset`. This table is the only place those
numbers are stated; the gates cite it rather than restating a figure, so adding a preset cannot
desynchronize them.

| Style Preset | Max Content Blocks | Max Word Count | Philosophy |
|-------------|-------------------|----------------|------------|
| sketchnote, whiteboard, editorial, data-viz, corporate | 8 | 150 | Minimal to focused — scan in 10 seconds |
| **economist** | **14** | **250** | **Dense editorial — read in 60 seconds** |

Resolve on the preset itself, not on its rendering family: `editorial`, `data-viz` and
`corporate` are editorial-family presets but carry the *standard* budget. Only `economist` is
dense. When `style_preset` is absent or unrecognized, fall back to the standard row (8 / 150) —
never to the economist ceiling.

The maxima above are hard ceilings. A universal floor applies to every preset: fewer than
3 content blocks (excluding title, CTA and footer) is too sparse and fails.

The **economist** preset produces magazine-density content: prose text blocks sit alongside
stat callouts in a multi-column grid. Extract more data points from the narrative, include
short explanatory paragraphs (2-3 sentences), and fill a 2-3 column editorial layout.
Aim for 10-14 content blocks including 3-5 text-blocks with prose alongside the stats.

---

# Editorial family

Rendered by `render-infographic-pencil` via Pencil MCP. The editorial family composes dense,
disciplined newspaper-quality pages where blocks share rows in a 2–3 column grid, red (or
theme-primary) rule lines separate sections, and hero numbers earn trust through scale.
Restraint is the signature — no rounded corners, no drop shadows, no decorative elements.

## economist

**Character:** The Economist magazine editorial — the flagship of the editorial family. Bold
stat callouts, clean grid, minimal ornamentation. Numbers dominate the page, color is
disciplined (red accent only), and information density is high but spacious. Think weekly
newsmagazine data page — authoritative, precise, visually striking without being decorative.

**Visual DNA:**
- Cream/off-white background (`#FBF9F3`) — warm, not sterile
- Deep red (`#C00000`) for bar charts, accent borders, rule lines, and icon highlights
- Near-black (`#1A1A1A`) for body text and headlines
- Amber (`#D4A017`) for secondary callout icons and tertiary accents
- Sharp edges — `border-radius: 0` for all blocks, no exceptions
- Percentage signs and units rendered at same visual weight as digits (not superscript)
- Thin 2px red rule lines under section headers
- Monospace or tabular figures for all numbers — numbers are the star
- No shadows, no gradients, no rounded corners, no decorative elements
- High white-space discipline — generous padding (40-60px), clean gutters
- Simple bar charts with solid red fills — no 3D, no patterns, no chartjunk

**Best for:** C-suite insight summaries, trend reports for senior leadership, investor-facing
data stories, board presentations, research findings. Content where "The Economist credibility"
is the design goal — data-forward, editorially confident, zero visual noise.

---

## editorial

**Character:** Clean magazine aesthetic with strong type hierarchy, generous whitespace, and
understated elegance. Think Harvard Business Review or McKinsey Quarterly — authoritative
content that lets the data speak through impeccable typography.

**Visual DNA:**
- Sans-serif headers at large weights (600-700), body at regular (400)
- Generous whitespace — 40-60px between blocks, 24px internal padding
- Thin borders (1px solid) in muted tones
- Sharp edges — `border-radius: 0` for all blocks
- Accent color used sparingly — only for hero numbers and CTA
- Background: clean white or very light surface
- No shadows, no gradients, no decorative elements

**Best for:** Executive reports, financial analysis, investment theses, board presentations,
thought leadership. Content that needs to feel authoritative and trustworthy.

---

## data-viz

**Character:** Dashboard-like, chart-forward, minimal decoration. Numbers and charts dominate.
Think Bloomberg Terminal meets annual report — the data is the design.

**Visual DNA:**
- Monospace font for all numbers (hero numbers, stat rows, chart labels)
- Compact spacing — 24-32px between blocks, 16px internal padding
- Accent-colored backgrounds for KPI cards (light tint of accent)
- Chart blocks get maximum space allocation (50%+ of content area)
- Subtle grid lines in background (light border color, 1px)
- Brand accent = positive only; ink/muted gray carries negative. Do NOT add a second
  accent (red for "bad", green for "good") — traffic-light coding dilutes the brand and
  makes every dashboard look the same regardless of theme.
- Small labels in text-muted, uppercase, letter-spacing: 0.05em

**Best for:** Trend reports, market data, KPI dashboards, research findings, data-heavy
narratives. Content where numbers tell the story.

---

## corporate

**Character:** Conservative, trust-building, brand-safe. Think annual report or compliance
document — structured, reliable, no surprises. The visual equivalent of a firm handshake.

**Visual DNA:**
- Primary color headers on dark backgrounds (surface_dark)
- Structured grid with solid borders (2px solid)
- Serif-friendly typography where theme supports it
- Badge-style labels (small caps, bordered, pill-shaped)
- Moderate spacing — 32px between blocks, 20px internal padding
- Consistent block sizing — all blocks same height within rows
- Footer prominent with full attribution and source line
- No playfulness — no rotations, no dashed borders, no rounded corners beyond 4px

**Best for:** Board presentations, compliance reports, governance overviews, regulatory
content, investor materials. Content that needs to inspire confidence and trust.

---

# Hand-drawn family

Rendered via Excalidraw MCP by two tradition-specific agents: `render-infographic-sketchnote`
(sketchnote preset) and `render-infographic-whiteboard` (whiteboard preset). The hand-drawn
family composes live-facilitator scenes where imperfection signals humanity: dashed or solid
marker borders, rough strokes, Virgil font, primitive-shape icons, and curved arrows that
guide reading order. Trust comes from the visible hand, not from grid discipline. Each
tradition has its own dedicated agent because sketchnote (warm, dashed, several accents) and
whiteboard (spare, solid, accent only on hero + CTA) have **opposite** discipline rules — a
single conditional agent drifted toward the looser tradition, so 0.14.0 gives each one an
unconditional voice and extracts the truly shared concerns (canvas lifecycle, brand-accent
doctrine, shared review gates) into `libraries/render-excalidraw-common.md`.

## sketchnote

**Character:** Hand-drawn feel, informal, workshop-ready. Think visual note-taking at a
conference — energetic, accessible, human. Not sloppy — intentionally crafted to feel
approachable while remaining professional.

**Visual DNA:**
- Rounded corners — `border-radius: 24px` for all blocks
- Dashed borders (2px dashed) in primary color
- Playful icon sizing — icons 48-64px, larger than other presets
- Relaxed spacing — 32-48px between blocks, generous padding
- Slight rotation on some blocks (1-2deg CSS transform) for dynamism
- Background: warm off-white or light cream surface
- Optional: SVG "hand-drawn" border paths instead of CSS borders
- Headers use slightly heavier weight with a casual feel

**Best for:** Workshop materials, ideation summaries, brainstorm outputs, learning materials,
team retrospectives. Content that needs to feel collaborative and accessible.

---

## whiteboard

**Character:** Minimal, black-and-white with accent highlights, marker-pen feel. Think
strategy session whiteboard captured and cleaned up — focused, no distractions, pure content.

**Visual DNA:**
- White background, black text — that's the base
- Single accent color for highlights, CTA, and hero numbers only
- Bold borders (2px solid black) on key blocks
- No background fills on blocks — content floats on white
- Maximum whitespace — 48-64px between blocks
- Large, bold headers — the whiteboard has big handwriting
- Minimal decoration — no shadows, no gradients, no rounded corners
- Icons rendered in black/accent two-tone only

**Best for:** Strategy sessions, internal alignment, team planning, quick visual summaries.
Content that needs to communicate clearly without aesthetic distraction.

---

## Preset Selection Guidance

When presenting style options to the user, lead with the context match:

```
"Based on [source type / audience / context], I recommend:

1. **economist** — The Economist magazine style. Bold stats, red accent, cream background. Best for C-suite data stories.
2. **data-viz** — dashboard-style, numbers-forward. Best for your trend data.
3. **editorial** — clean magazine aesthetic. Best for executive credibility.
4. **sketchnote** — informal workshop feel. Best for collaborative settings."
```

The user's context awareness (who will see this, where, for what purpose) always overrides
the algorithmic recommendation.

## Two-Step Disclosure (choosing the preset interactively)

People think about infographic style in two steps, not six. The first cognitive split is
**hand-drawn feel vs editorial feel** — that single choice determines the rendering family
and eliminates four of the six presets. The second step narrows to a preset inside the
chosen family. Presenting all six at once asks the user to hold too much in their head.

**Step 4a — Family choice.** Infer the likely family from source cues (workshop recap or
learning content → hand-drawn; trend report, investor brief, or board deck → editorial)
and present via AskUserQuestion:

- **Hand-drawn (sketchnote / whiteboard)** — Mike Rohde sketchnote and RSA Animate
  whiteboard traditions. Warm, human, feels like a facilitator drew it at a conference.
  Best for workshops, team alignment, learning material, internal brainstorms.
- **Editorial (economist / editorial / data-viz / corporate)** — The Economist data page
  and data journalism tradition. Dense, disciplined, data-ink honest. Best for trend
  reports, investor briefs, board decks, flagship insights.

On empty response, auto-select the inferred family.

**Step 4b — Preset narrowing inside the chosen family.** Only present the 2–3 presets that
belong to the chosen family, with recommendations grounded in source cues:

- **Hand-drawn family** → pick between `sketchnote` (warm, organic, dashed borders, accent
  color on several marks) and `whiteboard` (disciplined minimalism, solid borders, accent
  color only on hero numbers and CTA).
- **Editorial family** → pick among `economist` (flagship, magazine-dense), `editorial`
  (HBR/McKinsey, generous whitespace), `data-viz` (Bloomberg Terminal dashboard feel,
  monospace numbers), `corporate` (annual report / governance, structured grid,
  serif-friendly). Each preset's density budget is in the Content Density table of
  `infographic-style-presets.md`, loaded at this step.

Present via AskUserQuestion with 2–3 options. On empty response, auto-select top
recommendation.
