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
