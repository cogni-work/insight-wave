# Style Presets

Five style presets that control the CSS aesthetic layer of infographics. Each preset defines
visual personality independent of theme colors — the theme provides the palette, the preset
provides the character.

The preset is stored in the brief frontmatter as `style_preset`. The Python renderer applies
it via `data-style="{preset}"` on the root container, scoping all CSS rules.

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
- Status colors for positive/negative indicators (success green, danger red)
- Small labels in text-muted, uppercase, letter-spacing: 0.05em

**Best for:** Trend reports, market data, KPI dashboards, research findings, data-heavy
narratives. Content where numbers tell the story.

---

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

1. **data-viz** — dashboard-style, numbers-forward. Best for your trend data.
2. **editorial** — clean magazine aesthetic. Best for executive credibility.
3. **sketchnote** — informal workshop feel. Best for collaborative settings."
```

The user's context awareness (who will see this, where, for what purpose) always overrides
the algorithmic recommendation.
