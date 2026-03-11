---
library_id: big-block-layouts
version: 1.0.0
created: 2026-03-11
---

# Big Block Layout Library

Canvas dimensions, tier row positioning, solution block sizing, connection line routing, and typography for Big Block solution architecture diagrams rendered via Excalidraw MCP.

The Big Block is a **structured grid diagram** — fundamentally different from the Big Picture's illustrated landscape scene. Where a Big Picture has landscape objects telling a story, the Big Block has solution blocks organized by BR tier with path connections showing relationships.

---

## Canvas Dimensions

Reuses the same DIN formats at 150 DPI. Landscape orientation.

| Format | Pixels (w x h) | Max Solutions | Block Size (w x h) | Max Blocks/Row |
|--------|----------------|---------------|---------------------|----------------|
| A0 | 7016 x 4961 | 16 | 400 x 160 px | 6 |
| A1 | 4961 x 3508 | 12 | 320 x 140 px | 5 |
| A2 | 3508 x 2480 | 10 | 240 x 110 px | 4 |
| A3 | 2480 x 1754 | 8 | 180 x 90 px | 3 |

---

## Canvas Zones

The Big Block canvas is divided into 5 zones:

```
+==================================================================+
|  TITLE BANNER (10%)                                               |
|  "Big Block: {Title}" + Subtitle + Scoring summary               |
+==================================================================+
|                                                                   |
|  TIER ZONE (55%)                                                  |
|  Horizontal bands: Tier 1 (top) → Tier 4 (bottom)               |
|  Each band contains solution blocks in a grid                     |
|                                                                   |
|  ┌─ Tier 1: Mission Critical ──────────────────────────────┐     |
|  │  [Block] [Block] [Block]                                 │     |
|  └──────────────────────────────────────────────────────────┘     |
|  ┌─ Tier 2: High Impact ───────────────────────────────────┐     |
|  │  [Block] [Block] [Block]                                 │     |
|  └──────────────────────────────────────────────────────────┘     |
|  ┌─ Tier 3/4 ──────────────────────────────────────────────┐     |
|  │  [Block] [Block] [Block]                                 │     |
|  └──────────────────────────────────────────────────────────┘     |
|                                                                   |
+-------------------------------------------------------------------+
|  SPI + FOUNDATION ZONE (20%)                                      |
|  Process changes (left) | Foundation requirements (right)         |
+-------------------------------------------------------------------+
|  ROADMAP ZONE (10%)                                               |
|  Wave 1 → Wave 2 → Wave 3 timeline                               |
+-------------------------------------------------------------------+
|  FOOTER (5%)                                                      |
|  Customer | Provider | Date | Methodology                        |
+-------------------------------------------------------------------+
```

### Zone Specifications (A1 — default)

| Zone | x | y | width | height | Purpose |
|------|---|---|-------|--------|---------|
| Title Banner | 0 | 0 | 4961 | 350 | Title, subtitle, scoring summary |
| Accent Border | 0 | 350 | 4961 | 16 | Theme accent color separator |
| Tier Zone | 80 | 416 | 4801 | 1930 | Tier bands with solution blocks |
| SPI/Foundation Zone | 80 | 2396 | 4801 | 700 | SPIs (left half) + Foundations (right half) |
| Roadmap Zone | 80 | 3146 | 4801 | 180 | Implementation wave timeline |
| Footer | 0 | 3326 | 4961 | 182 | Branding, date, methodology |

### Zone Specifications (A0)

| Zone | x | y | width | height |
|------|---|---|-------|--------|
| Title Banner | 0 | 0 | 7016 | 500 |
| Accent Border | 0 | 500 | 7016 | 24 |
| Tier Zone | 100 | 574 | 6816 | 2730 |
| SPI/Foundation Zone | 100 | 3354 | 6816 | 990 |
| Roadmap Zone | 100 | 4394 | 6816 | 250 |
| Footer | 0 | 4644 | 7016 | 317 |

### Zone Specifications (A2)

| Zone | x | y | width | height |
|------|---|---|-------|--------|
| Title Banner | 0 | 0 | 3508 | 250 |
| Accent Border | 0 | 250 | 3508 | 12 |
| Tier Zone | 60 | 302 | 3388 | 1365 |
| SPI/Foundation Zone | 60 | 1707 | 3388 | 490 |
| Roadmap Zone | 60 | 2237 | 3388 | 125 |
| Footer | 0 | 2362 | 3508 | 118 |

---

## Tier Band Layout

Each tier is a horizontal band within the Tier Zone. Bands stack vertically, Tier 1 at top.

### Band Height Distribution

Height is distributed proportionally to solution count, with Tier 1 getting a minimum 30% of the Tier Zone.

| Tier | Min Height % | Visual Weight | Band Color (light mode) | Band Color (dark mode) |
|------|-------------|---------------|------------------------|----------------------|
| Tier 1 | 30% | Heaviest — accent tint | `theme_accent` at 8% opacity | `theme_accent` at 12% opacity |
| Tier 2 | 25% | Medium — secondary tint | `theme_secondary` at 6% opacity | `theme_secondary` at 10% opacity |
| Tier 3 | 22% | Light — neutral tint | `#888888` at 4% opacity | `#888888` at 8% opacity |
| Tier 4 | 15% | Lightest — minimal tint | `#888888` at 2% opacity | `#888888` at 5% opacity |

**If a tier has 0 solutions:** Collapse it to a thin label row (30px) showing "Keine Lösungen in dieser Stufe" / "No solutions in this tier".

### Band Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ TIER LABEL (left edge, rotated 90° or horizontal small text)    │
│                                                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│   │ Block    │  │ Block    │  │ Block    │   ← Solution blocks  │
│   │ BR: 4.67 │  │ BR: 4.33 │  │ BR: 4.00 │   ← in a row        │
│   │ ★★★★★   │  │ ★★★★    │  │ ★★★★    │                     │
│   └──────────┘  └──────────┘  └──────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Tier Label

| Canvas | Font Size | Weight | Position | Color |
|--------|-----------|--------|----------|-------|
| A0 | 28px | Bold | Left margin, vertically centered | Tier color at 80% |
| A1 | 22px | Bold | Left margin, vertically centered | Tier color at 80% |
| A2 | 16px | Bold | Left margin, vertically centered | Tier color at 80% |
| A3 | 12px | Bold | Left margin, vertically centered | Tier color at 80% |

The tier label includes both the tier name and BR range:
- "Tier 1: Mission Critical (BR >= 4.0)"
- "Stufe 1: Geschäftskritisch (BR >= 4.0)" (German)

---

## Solution Block Layout

Each solution block is a rounded rectangle containing structured information.

### Block Dimensions

| Canvas | Width | Height | Corner Radius | Margin Between Blocks |
|--------|-------|--------|---------------|----------------------|
| A0 | 400 px | 160 px | 12 px | 40 px |
| A1 | 320 px | 140 px | 10 px | 30 px |
| A2 | 240 px | 110 px | 8 px | 20 px |
| A3 | 180 px | 90 px | 6 px | 15 px |

### Block Internal Layout

```
┌──────────────────────────────┐
│ Solution Name (bold)          │  ← name_short, truncate at width
│ BR: 4.67 ★★★★★              │  ← score + star visualization
│ Category: software            │  ← category tag
│ → predictive-analytics        │  ← portfolio ref (green) or "PORTFOLIO GAP" (red)
│ Wave 1 | 3 paths              │  ← implementation wave + path count
└──────────────────────────────┘
```

### Block Colors

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Block background | `#FFFFFF` | `#1A1A1A` |
| Block stroke | Tier color at 60% | Tier color at 80% |
| Block stroke (gap) | `#E53E3E` (red) | `#FC8181` (light red) |
| Name text | `#1A1A1A` | `#FFFFFF` |
| Score text | Tier color | Tier color |
| Stars (filled) | `#F6AD55` (amber) | `#F6AD55` |
| Stars (empty) | `#E2E8F0` (gray) | `#4A5568` |
| Portfolio ref | `#38A169` (green) | `#68D391` |
| Portfolio gap | `#E53E3E` (red) | `#FC8181` |
| Wave badge | `theme_accent` at 20% bg | `theme_accent` at 30% bg |

### Block Text Sizing

| Element | A0 | A1 | A2 | A3 | Weight |
|---------|-----|-----|-----|-----|--------|
| Solution name | 20px | 16px | 13px | 10px | Bold |
| BR score | 16px | 13px | 10px | 8px | Regular |
| Stars | 14px | 11px | 9px | 7px | Regular |
| Category | 12px | 10px | 8px | 6px | Regular |
| Portfolio ref | 12px | 10px | 8px | 6px | Regular |
| Wave/paths | 10px | 8px | 7px | 5px | Regular |

---

## SPI Section Layout

SPIs occupy the left half of the SPI/Foundation Zone.

### SPI Card

```
┌──────────────────────────────────┐
│ SPI-001: Data Governance Policy   │  ← SPI name
│ → Predictive Quality Analytics    │  ← linked solution(s)
└──────────────────────────────────┘
```

| Property | A0 | A1 | A2 |
|----------|-----|-----|-----|
| Card width | 48% of zone | 48% of zone | 48% of zone |
| Card height | 60 px | 50 px | 40 px |
| Cards per column | 2 | 2 | 2 |
| Max cards | 6 | 6 | 4 |
| SPI name font | 14px | 12px | 9px |
| Link font | 12px | 10px | 7px |

### SPI Card Colors

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Background | `#FFF5F5` (red-50 tint) | `#2D1B1B` |
| Stroke | `#FC8181` at 40% | `#FC8181` at 60% |
| Name text | `#C53030` | `#FC8181` |
| Link text | `#718096` | `#A0AEC0` |

---

## Foundation Section Layout

Foundations occupy the right half of the SPI/Foundation Zone.

### Foundation Card

```
┌──────────────────────────────────┐
│ Data Infrastructure               │  ← Foundation name
│ Maturity: Advanced                │  ← Required maturity level
│ → 3 solutions depend              │  ← dependency count
└──────────────────────────────────┘
```

### Foundation Card Colors

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Background | `#EBF8FF` (blue-50 tint) | `#1A2332` |
| Stroke | `#63B3ED` at 40% | `#63B3ED` at 60% |
| Name text | `#2B6CB0` | `#63B3ED` |
| Maturity text | `#718096` | `#A0AEC0` |

---

## Path Connection Lines

TIPS paths that link multiple solution blocks are visualized as connection lines.

### Connection Routing

Lines route between blocks that share a TIPS path. Use curved bezier connections (not straight lines) to avoid crossing block boundaries.

| Property | Value |
|----------|-------|
| Line style | Dashed (strokeStyle: "dashed") |
| Line width | 2px |
| Color | Tier color of highest-tier block in the connection |
| Opacity | 40% (light mode), 60% (dark mode) |
| Arrow heads | None (bidirectional relationship) |
| Routing | Vertical preferred — connections between tiers route along the left/right margins |
| Label | Path name at midpoint, small font (8px A1), rotated if vertical |

### Connection Priority

When a canvas has many connections (> 8), only render:
1. All Tier 1 connections (always shown)
2. Cross-tier connections (Tier 1 block → Tier 2+ block)
3. Drop intra-tier connections in lower tiers if space is tight

---

## Roadmap Zone Layout

The Implementation Roadmap appears as a horizontal timeline at the bottom.

```
┌─────────────────────────────────────────────────────────────────┐
│  Wave 1: Quick Wins     │  Wave 2: Strategic Build  │  Wave 3  │
│  0-6 months             │  6-18 months              │  18-36m  │
│  [st-001] [st-002]      │  [st-003][st-004][st-005] │  [...]   │
└─────────────────────────────────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Wave band width | Proportional to timeline (6/18/36 months) |
| Wave label | Bold, tier 1 accent color |
| Timeline label | Regular, muted text |
| Block references | Small pills/badges with solution name_short |

---

## Title Banner

| Element | A0 | A1 | A2 | A3 | Color |
|---------|-----|-----|-----|-----|-------|
| Title | 96px | 72px | 52px | 38px | `#FFFFFF` |
| Subtitle | 40px | 32px | 24px | 18px | `#FFFFFFCC` |
| Scoring line | 24px | 20px | 16px | 12px | `#FFFFFF99` |
| Banner background | — | — | — | — | Solid `#1A1A1A` |
| Accent border height | 24px | 16px | 12px | 8px | `theme_accent` |

The scoring line shows: "{N} Lösungen | Ø BR {avg} | {gaps} Portfolio-Lücken"

---

## Footer

| Element | A0 | A1 | A2 | A3 | Alignment |
|---------|-----|-----|-----|-----|-----------|
| Customer/Provider | 20px | 16px | 13px | 10px | Left |
| Date | 20px | 16px | 13px | 10px | Center |
| Methodology | 16px | 13px | 10px | 8px | Right |

Methodology line: "TIPS Business Relevance — WO2018046399A1"

---

## Excalidraw Grouping Strategy

| Group | Contains |
|-------|----------|
| Title banner | Background rect + title + subtitle + scoring + accent border |
| Tier band (×N) | Band background + tier label + all blocks in tier |
| Solution block (×N) | Block rect + name + score + stars + category + portfolio + wave |
| SPI section | Section label + all SPI cards |
| Foundation section | Section label + all foundation cards |
| Connection (×N) | Line + optional label |
| Roadmap | Timeline background + wave labels + block badges |
| Footer | Background + customer + date + methodology |

---

## Dark/Light Color Mode

Inherits the same detection logic as big-picture-layouts.md:

```
luminance = 0.299*R + 0.587*G + 0.114*B
if luminance < 128 → "dark"
else → "light"
```

All color specifications above include both light and dark mode values.

---

## Rendering Order (Z-Order)

| Layer | Z-Order | Element |
|-------|---------|---------|
| 1 (back) | 0 | Canvas frame |
| 2 | 1 | Title banner |
| 3 | 2 | Tier band backgrounds |
| 4 | 3 | Tier labels |
| 5 | 4 | Connection lines (behind blocks) |
| 6 | 5 | Solution blocks |
| 7 | 6 | SPI cards |
| 8 | 7 | Foundation cards |
| 9 | 8 | Roadmap timeline |
| 10 (front) | 9 | Footer |
