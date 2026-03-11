---
library_id: big-picture-layouts
version: 2.1.0
created: 2026-02-26
updated: 2026-03-04
---

# Big Picture Layout Library

Canvas dimensions, zone templates, station object positioning, station number specifications, text readability glow, and typography for visual journey maps rendered via Excalidraw MCP (github.com/yctimlin/mcp_excalidraw).

**v2.0:** Stations are landscape objects (not cards). Numbered circles guide reading flow. Text uses glow backgrounds for readability.

**v4.2:** Inline accent-colored station numbers (no circles/ellipses). Dark mode min fill #888. Larger title fonts (~50% banner width). Taller banners. Increased text area heights for 100-120 word bodies.

---

## Canvas Dimensions

All canvases are landscape orientation at 150 DPI (print-quality).

| Format | Pixels (w x h) | mm (w x h) | Max Stations | Object Bounding Box | Text Area |
|--------|----------------|------------|--------------|---------------------|-----------|
| A0 | 7016 x 4961 | 1189 x 841 | 8 | 450 x 300 px | 500 x 300 px |
| A1 | 4961 x 3508 | 841 x 594 | 7 | 350 x 250 px | 380 x 240 px |
| A2 | 3508 x 2480 | 594 x 420 | 6 | 250 x 180 px | 280 x 195 px |
| A3 | 2480 x 1754 | 420 x 297 | 5 | 180 x 130 px | 200 x 150 px |

---

## Canvas Zones

Every big picture canvas is divided into these zones:

```
+==================================================================+
|  TITLE BANNER (12% height)                                       |
|  Solid dark background (#1A1A1A or theme dark)                   |
|  Title (110px bold) + Subtitle (42px) + Governing thought (28px) |
|  24px accent-color bottom border as visual separator             |
+==================================================================+
|                                                                  |
|  JOURNEY ZONE (74% height)                                       |
|                                                                  |
|  Background: Landscape composition shapes (low opacity)          |
|  Scene: Station objects AS landscape elements                    |
|  Flow: Station numbers 1 2 3 (accent color) indicate reading order|
|                                                                  |
|  [Machine] ①   [Station] ②   [Gauge] ③                         |
|                                                                  |
|        [CNC] ④         [Line] ⑤                                |
|                                                                  |
|                         [Tower] ⑥                               |
|                                                                  |
+------------------------------------------------------------------+
|  FOOTER (6% height)                                              |
|  Logos, branding, credits, date                                  |
+------------------------------------------------------------------+
```

**IMPORTANT:** The title banner must be prominent and readable from 2+ meters on a printed poster. Use a **solid opaque background** (not semi-transparent rgba). The accent-color bottom border (24px) creates clear visual separation.

### Zone Specifications per Canvas Size

#### A1 (default)

| Zone | x | y | width | height | Purpose |
|------|---|---|-------|--------|---------|
| Title Banner | 0 | 0 | 4961 | 520 | Title, subtitle, governing thought |
| Accent Border | 0 | 520 | 4961 | 24 | Theme accent color separator |
| Journey Zone | 0 | 544 | 4961 | 2474 | Landscape scene + station objects |
| Footer | 0 | 3018 | 4961 | 490 | Logos, branding |

#### A0

| Zone | x | y | width | height |
|------|---|---|-------|--------|
| Title Banner | 0 | 0 | 7016 | 740 |
| Accent Border | 0 | 740 | 7016 | 32 |
| Journey Zone | 0 | 772 | 7016 | 3495 |
| Footer | 0 | 4267 | 7016 | 694 |

#### A2

| Zone | x | y | width | height |
|------|---|---|-------|--------|
| Title Banner | 0 | 0 | 3508 | 368 |
| Accent Border | 0 | 368 | 3508 | 16 |
| Journey Zone | 0 | 384 | 3508 | 1749 |
| Footer | 0 | 2133 | 3508 | 347 |

#### A3

| Zone | x | y | width | height |
|------|---|---|-------|--------|
| Title Banner | 0 | 0 | 2480 | 260 |
| Accent Border | 0 | 260 | 2480 | 12 |
| Journey Zone | 0 | 272 | 2480 | 1237 |
| Footer | 0 | 1509 | 2480 | 245 |

---

## Station Positioning Patterns

### Coordinate System

All station positions in briefs use **journey-zone-relative** coordinates. The origin `(0, 0)` is the **top-left corner of the journey zone**, not the canvas.

```
absolute_x = journey_zone.x + station.x
absolute_y = journey_zone.y + station.y

Example (A1 canvas):
  journey_zone = { x: 0, y: 444 }
  station = { x: 200, y: 2200 }
  absolute = { x: 200, y: 2644 }
```

### Ascending (6 stations on A1)

Stations rise from lower-left to upper-right, matching transformation/climb arcs.

```
Positions (x, y) relative to Journey Zone origin:
  S1: (200, 2200)    -- valley floor
  S2: (900, 1800)    -- lower slope
  S3: (1700, 1400)   -- mid slope
  S4: (2600, 1000)   -- upper slope
  S5: (3500, 600)    -- near summit
  S6: (4400, 300)    -- summit/vista
```

### Linear (6 stations on A1)

Stations spread left-to-right with gentle vertical offset.

```
Positions (x, y) relative to Journey Zone origin:
  S1: (200, 1800)
  S2: (1100, 1200)
  S3: (2000, 600)
  S4: (2900, 1400)
  S5: (3700, 800)
  S6: (4500, 1600)
```

### Winding S-curve (6 stations on A1)

```
Positions (x, y) relative to Journey Zone origin:
  S1: (200, 600)
  S2: (1200, 400)
  S3: (2300, 800)
  S4: (2300, 1800)
  S5: (3400, 2000)
  S6: (4400, 1400)
```

### Hub-and-spoke (5 stations on A1)

```
Positions (x, y) relative to Journey Zone origin:
  Center: (2480, 1369)
  S1: (500, 500)
  S2: (4000, 400)
  S3: (300, 2200)
  S4: (4200, 2100)
  S5: (2480, 2400)
```

### Minimum Spacing Constraints

| Constraint | Minimum | Notes |
|-----------|---------|-------|
| Station top to journey zone top | 100px | Prevents collision with title banner accent border |
| Station bottom to journey zone bottom | 80px | Prevents collision with footer |
| Horizontal gap between station bounding boxes | 50px | Edge-to-edge |
| Vertical gap between station bounding boxes | 50px | Edge-to-edge |

---

## Station Object Layout

In v2.0, each station is composed of a **landscape object** (shapes) + **station number text** + **text glow** + **text elements**, NOT a white card with an image.

### Station Visual Structure

```
            ┌───────────┐
            │ Base Shape │              ← landscape_object (composed from recipe)
            │ + Accents  │              ← 2-4 accent shapes (details)
            └───────────┘
   ┌──────────────────────────────┐
   │  [glow background]           │    ← Semi-transparent rect (palette.text_glow_bg)
   │  KRÄFTE                      │    ← Station label (uppercase, accent color)
   │ 1 23 Tage Stillstand...     │    ← Number text (accent) inline LEFT of headline
   │  Body text here...           │    ← Body (regular, palette.body_text_color)
   │  23  Tage/Jahr               │    ← Hero number + label
   └──────────────────────────────┘
```

### Object Scale Factors

| Scale | Factor | When to Use | Max per Big Picture |
|-------|--------|-------------|---------------------|
| `hero` | 1.5x all dimensions | Most important station (solution/proof) | 1 |
| `standard` | 1.0x | Most stations | Unlimited |
| `supporting` | 0.8x | Secondary/contextual stations | Unlimited |

### Text Placement Algorithm

The `text_placement` field determines where text goes relative to the landscape object:

| Placement | Text Position | When to Use |
|-----------|--------------|-------------|
| `below` | Below the object, full width | Default. Most stations. |
| `above` | Above the object | Stations near canvas bottom edge |
| `right` | To the right of the object | Stations with space right, next station is far |
| `left` | To the left of the object | Rightmost stations near canvas edge |
| `auto` | Renderer decides | Fallback |

Text area dimensions scale with canvas size (see Canvas Dimensions table).

---

## Station Number Specification

Each station has a number text element that identifies its reading order (1, 2, 3...). The number is rendered as accent-colored text inline with the headline — no circle or ellipse.

| Canvas | Font Size | Color | Gap (number to headline) |
|--------|-----------|-------|--------------------------|
| A0 | 32px | theme_accent | 12px |
| A1 | 24px | theme_accent | 12px |
| A2 | 18px | theme_accent | 10px |
| A3 | 14px | theme_accent | 8px |

**Positioning:** Number text is placed to the LEFT of the headline text, on the same y-baseline.

```
number_text_width = font_size * 0.7
number_x = headline_x - number_text_width - gap
number_y = headline_y   # same baseline
```

**Z-order:** Number text renders ON TOP of the text glow background but BELOW the title banner.

---

## Text Readability Glow

A semi-transparent white rectangle placed behind the text area ensures readability against the landscape scene.

| Property | Value | Notes |
|----------|-------|-------|
| Fill | `#FFFFFFD9` | White at 85% opacity |
| Corner radius | 0px | Sharp corners (Excalidraw default) |
| Padding | 10px | Extends 10px beyond text block on all sides |
| Stroke | transparent | No border |
| Roughness | 0 | Always smooth (readable text needs clean bg) |

**IMPORTANT:** The glow is NOT a station card. It's a subtle background that fades into the scene. It only covers the text area, not the landscape object.

### Dark Mode Glow

| Property | Light Mode | Dark Mode |
|----------|-----------|-----------|
| Fill | `#FFFFFFD9` (white at 85%) | `{theme.background}D9` (canvas bg at 85%) |
| Example | `#FFFFFFD9` on white canvas | `#0A0A0AD9` on `#0A0A0A` canvas |

---

## Dark/Light Color Mode

The pipeline auto-detects color mode from the theme's `background` color luminance. All agents receive `color_mode` and an adapted `palette` via `CANVAS_CONTEXT`.

### Color Mode Detection

```
luminance = 0.299*R + 0.587*G + 0.114*B
if luminance < 128 → "dark"
else → "light"
```

### Palette Reference

| Key | Light Mode | Dark Mode |
|-----|-----------|-----------|
| canvas_frame_bg | `#FFFFFF` | theme.background |
| footer_bg | `#F5F5F5` | theme.background lightened 10% |
| footer_text | `#666666` | `#AAAAAA` |
| text_glow_bg | `#FFFFFFD9` | `{theme.background}D9` |
| structure_colors | `#888-#D0D0D0` | `#888-#FFFFFF` (inverted grey scale, min #888) |
| stroke_default | `#333333` | `#FFFFFF` |
| headline_color | theme.primary | `#FFFFFF` |
| body_text_color | theme.body_text | `#CCCCCC` |

---

## Text Styling (Excalidraw MCP)

### Station Text

| Element | A0 | A1 | A2 | A3 | Weight | Color |
|---------|-----|-----|-----|-----|--------|-------|
| Station label | 18px | 14px | 10px | 7px | Regular | Theme accent |
| Station headline | 36px | 28px | 20px | 14px | Bold | Theme primary |
| Station body | 22px | 18px | 13px | 9px | Regular | Theme body |
| Hero number | 64px | 48px | 34px | 24px | Bold | Theme accent |
| Hero label | 20px | 16px | 11px | 8px | Regular | Theme muted |
| Station number | 32px | 24px | 18px | 14px | Bold | Theme accent |

### Title Banner

| Element | A0 | A1 | A2 | A3 | Color |
|---------|-----|-----|-----|-----|-------|
| Title | 144px | 110px | 76px | 54px | #FFFFFF |
| Subtitle | 56px | 42px | 30px | 22px | #FFFFFFCC |
| Governing thought | 36px | 28px | 20px | 14px | #FFFFFF99 |
| Banner background | -- | -- | -- | -- | Solid #1A1A1A |
| Accent border height | 32px | 24px | 16px | 12px | Theme accent |

**CRITICAL:** Banner background MUST be solid (not semi-transparent). Never `rgba()` with alpha below 1.0.

### Footer

| Element | A0 | A1 | A2 | A3 | Weight | Alignment |
|---------|-----|-----|-----|-----|--------|-----------|
| Customer/provider | 24px | 20px | 16px | 12px | Regular | Left |
| Date | 24px | 20px | 16px | 12px | Regular | Right |
| Logo area | 160x80px | 120x60px | 90x45px | 60x30px | -- | Right |

---

## Reading Flow

Reading order is indicated by inline station number text only. No circles, no arrows, no connecting paths.

| Property | Value |
|----------|-------|
| Indicator | Station number text elements (1 2 3...) in accent color, inline LEFT of each station's headline |
| Reading direction | Left-to-right, following station numbers |
| No arrows, no circles | Number text alone is sufficient to guide reading flow |

**v4.2 change:** Numbered circles replaced with inline accent-colored number text. No ellipses, no separate circle elements.

---

## Rendering Order (Z-Order)

> **Sketch imports:** When Phase 0 imports a composition sketch, those elements sit at z-order Layer 0 (behind the canvas frame). The table below applies to pipeline-generated elements only.

Elements MUST be rendered in this exact order (station-first pipeline v4.1):

| Layer | Z-Order | Element | Created By |
|-------|---------|---------|------------|
| 1 (back) | 0 | Canvas frame (palette.canvas_frame_bg) | Skill Phase 1 |
| 2 | 1 | Title banner (dark bg + text) | Skill Phase 2 |
| 3 | 2 | Journey zone background (tinted) | Skill Phase 3 |
| 4 | 3 | Station structures (120-150 each) | N× station-structure-artist |
| 5 | 4 | Text glow backgrounds (palette.text_glow_bg) | N× station-structure-artist |
| 6 | 5 | Station number text elements (accent color) | N× station-structure-artist |
| 7 | 6 | Station text (labels, headlines, body, hero) | N× station-structure-artist |
| 8 | 7 | Station enrichment details (100-130 each) | N× station-enrichment-artist |
| 9 (front) | 8 | Footer (palette.footer_bg) | Skill Phase 4 |

---

## Story-World-to-Layout Mapping

| Story World Type | Typical Flow Pattern | Station Count |
|-----------------|---------------------|---------------|
| Factory / Industrial | Ascending or Linear | 5-7 |
| Cityscape / Urban | Linear | 5-7 |
| Road / Highway | Linear or Winding | 5-8 |
| Mountain / Ascent | Ascending | 5-7 |
| River / Flow | Linear | 5-7 |
| Garden / Growth | Winding | 5-7 |
| Archipelago / Islands | Hub-and-spoke | 4-6 |

---

## Review Zone Definitions (4 Quarters)

The canvas is divided into 4 horizontal quarters for parallel zone-based review.

| Review Zone | Range | A0 x-range | A1 x-range | A2 x-range | A3 x-range |
|-------------|-------|-----------|-----------|-----------|-----------|
| A (left) | 0–25% | 0–1754 | 0–1240 | 0–877 | 0–620 |
| B (center-left) | 25–50% | 1754–3508 | 1240–2481 | 877–1754 | 620–1240 |
| C (center-right) | 50–75% | 3508–5262 | 2481–3721 | 1754–2631 | 1240–1860 |
| D (right) | 75–100% | 5262–7016 | 3721–4961 | 2631–3508 | 1860–2480 |

---

## Excalidraw Style Mapping

| Brief Property | Excalidraw Property |
|---------------|---------------------|
| Font family (sans-serif) | `fontFamily: 2` (Helvetica) |
| Font family (monospace) | `fontFamily: 3` (Cascadia) |
| Font family (creative) | `fontFamily: 1` (Virgil hand-drawn) |
| `roughness: 0` | Clean, corporate |
| `roughness: 1` | Slightly hand-drawn |
| `roughness: 2` | Sketch-like |
| Text glow opacity 85% | `opacity: 85` |
| Accent at 60% opacity | `opacity: 60` |
| Dashed stroke | `strokeStyle: "dashed"` |

## Excalidraw Grouping Strategy

Use `group_elements` to keep composite elements together:
- **Title banner group**: background rect + title + subtitle + governing thought + accent line
- **Station groups** (one per station): object shapes + number text + glow + all text
- **Footer group**: background rect + customer text + date text
