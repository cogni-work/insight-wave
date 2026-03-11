# Color Palette — Single Source of Truth

All color decisions for the big-picture rendering pipeline are defined here. Artist agents, the orchestrator skill, and reference docs point to this file instead of maintaining inline copies.

---

## Color Mode Detection

Parse the theme `background` hex color to RGB, then compute luminance:

```
luminance = 0.299 * R + 0.587 * G + 0.114 * B
```

- luminance < 128 → `color_mode = "dark"`
- luminance >= 128 → `color_mode = "light"`

---

## Master Palette

| Key | Light Mode | Dark Mode | Purpose |
|-----|-----------|-----------|---------|
| `canvas_frame_bg` | `#FFFFFF` | theme.background (e.g. `#0A0A0A`) | Canvas rectangle fill |
| `footer_bg` | `#F5F5F5` | Lighten theme.background +10% (e.g. `#1A1A1A`) | Footer band |
| `footer_text` | `#666666` | `#AAAAAA` | Footer metadata text |
| `text_glow_bg` | `#FFFFFFD9` | `{theme.background}D9` (e.g. `#0A0A0AD9`) | Readability glow behind station text |
| `structure_colors` | `#888888, #999999, #BBBBBB, #D0D0D0` | `#888888, #AAAAAA, #CCCCCC, #FFFFFF` | Station object fills (lightest→darkest) |
| `stroke_default` | `#333333` | `#FFFFFF` | Default stroke for all structural elements |
| `headline_color` | theme.primary | `#FFFFFF` | Station headline text |
| `body_text_color` | theme.body_text | `#CCCCCC` | Station body text |

---

## Grey-Scale Inversion (Light → Dark)

When `color_mode = "dark"`, invert grey fills in all recipes:

| Light Mode | Dark Mode | Role |
|-----------|-----------|------|
| `#D0D0D0` | `#FFFFFF` | Highlights, top surfaces |
| `#BBBBBB` | `#DDDDDD` | Light surfaces |
| `#999999` | `#CCCCCC` | Main body, medium surfaces |
| `#888888` | `#BBBBBB` | Secondary surfaces |
| `#777777` | `#999999` | Shadow sides, recesses |
| `#666666` | `#999999` | Deeper shadows |
| `#555555` | `#888888` | Details, depth |
| `#444444` | `#777777` | Deep shadows, interiors |
| `#333333` | `#666666` | Darkest shadows |

Accent, glass, warning, and status colors remain unchanged in both modes.

---

## Dark Mode Floor — #888888

No visible fill or stroke below **#888888** in dark mode — because elements below this threshold disappear against dark backgrounds, wasting element budget on invisible shapes.

For elements at <50% opacity, use **#999999** minimum base color — because low opacity further reduces effective contrast; a higher starting luminance compensates.

**Opacity-aware contrast check (used by zone-reviewer Gate 4):**
```
effective_contrast = abs(element_luminance - canvas_luminance) * (opacity / 100)
```
Must be >= 25. Below 15 = near-invisible (FAIL).

---

## Structure Artist Colors

### Light Mode (default)
- Main structure fills: `#888888`, `#999999`, `#BBBBBB`, `#D0D0D0`
- Shadow sides: `#666666`, `#777777`
- Detail depth: `#444444`, `#555555`
- Headlines: theme.primary
- Body text: theme.body_text
- All strokeColor: palette.stroke_default (`#333333`)

### Dark Mode
- Main structure fills: `#CCCCCC`, `#DDDDDD`, `#EEEEEE`, `#FFFFFF`
- Shadow sides: `#999999`, `#AAAAAA`
- Detail depth: `#888888`, `#999999`
- Headlines: `#FFFFFF`
- Body text: `#CCCCCC`
- All strokeColor: palette.stroke_default (`#FFFFFF`)

---

## Enrichment Artist Colors

### Light Mode
- Seam lines: strokeColor `#CCCCCC`, opacity 25-35%
- Rivets/bolts: fill `#888888`, opacity 50-70%
- Reflections: fill `#FFFFFF`, opacity 8-15%
- Shadows: fill `#000000`, opacity 3-8%
- Weathering: muted earth tones, opacity 5-12%

### Dark Mode
- Seam lines: strokeColor `#888888`, opacity 30-45%
- Rivets/bolts: fill `#BBBBBB`, opacity 50-70%
- Reflections: fill `#555555`, opacity 12-20%
- Shadows: fill `#000000`, opacity 3-6%
- Weathering: `#666666`, `#777777`, opacity 8-15%
- Light fixtures: fill `#EEEEEE` (brighter to stand out)

---

## Shared Accent / Glass / Status Colors

These remain constant in both color modes:

| Category | Colors | Usage |
|----------|--------|-------|
| Glass/screens | `#87CEEB` at 40-60% opacity, or dark `#0A192F` with bright content | Windows, displays |
| Theme accent | theme.accent | 2-3 key elements per station (sparingly) |
| Status green | `#00CC66` or `#44CC44` | Operational indicators |
| Warning red | `#FF4444` or `#CC0000` | Alerts, emergency elements |
| Alert amber | `#FFAA00` or `#FF8800` | Caution indicators |
| Info blue | `#4488CC` or `#0066CC` | Data flow, connectivity |
