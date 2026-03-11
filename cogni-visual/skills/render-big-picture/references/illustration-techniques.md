# Excalidraw Illustration Techniques

## Purpose

Guide artist agents in composing rich, recognizable illustrations from Excalidraw primitives. Station objects require 250+ elements each (structure + enrichment combined). The goal: photographic density where every surface has texture, every structure has detail, every space has atmosphere.

**v4.1 targets:** 250+ elements per station object (structure 130-160 + enrichment 100-130), 1100-1500 elements total across all stations.

---

## Core Principle: Shape Stacking

Excalidraw has 6 primitives: `rectangle`, `ellipse`, `diamond`, `line`, `arrow`, `text`. Everything — airports, machines, towers, landscapes — is built by **stacking, overlapping, and nesting** these shapes.

Think of each primitive as a **building block**, not a finished component:
- A **window** = small rectangle with light fill + smaller rectangle inside
- A **antenna** = thin tall rectangle + small ellipse on top + short lines radiating out
- A **door** = rectangle with rounded perception (two rectangles, inner darker)
- A **light/beacon** = small ellipse with bright fill + larger ellipse at low opacity (glow)

---

## Technique Catalog

### 1. Layered Depth (Back-to-Front)

Build objects in layers. Earlier elements sit behind later ones (Excalidraw renders in creation order).

```
Layer 1 (back):  Shadow/ground plane — dark rectangle, low opacity, offset 8-12px down-right
Layer 2:         Main body — primary rectangle/shape with fill
Layer 3:         Surface details — panels, doors, windows (smaller shapes on top)
Layer 4:         Accent features — lights, antennas, distinctive elements
Layer 5 (front): Highlights — small bright shapes that catch the eye
```

**Example — Building:**
1. Shadow rectangle (offset +10, +10, opacity 15, fill #000000)
2. Main wall rectangle (fill #D0D0D0)
3. Darker base/foundation rectangle (bottom 20%, fill #999999)
4. Window grid (4-8 small rectangles, fill #87CEEB or #FFFFFF60)
5. Door rectangle (center bottom, darker fill)
6. Roof line or ledge (line across top, strokeWidth 2)
7. Antenna/detail on roof (thin rectangle + ellipse)

### 2. Structural Composition

Build complex shapes from overlapping simple ones:

**Towers:** Stack 2-3 rectangles of decreasing width
- Base: wide, short rectangle
- Shaft: narrower, tall rectangle
- Top: wider observation deck rectangle
- Crown: ellipse or diamond for dome/radar

**Machines:** Combine rectangles at different angles
- Body: main rectangle
- Control panel: small rectangle on side (darker)
- Moving parts: ellipses (wheels, gears)
- Connections: lines (pipes, cables, conveyors)

**Vehicles:** Overlap rectangles + ellipses
- Body: main rectangle
- Cabin/cockpit: offset rectangle (different color)
- Wheels/landing gear: ellipses at bottom
- Windows: small rectangles or ellipses (light fill)

### 3. Detail Elements (Recognition Cues)

Small elements (5-20px) that make an object recognizable:

| Detail Type | Implementation | Effect |
|-------------|----------------|--------|
| Lights/LEDs | Small ellipse (8-12px), bright fill (#FF0000, #00FF00, #FFAA00) | Shows status, draws eye |
| Buttons/controls | Tiny rectangles (6-10px) in a row | Suggests interface/panel |
| Rivets/bolts | Tiny ellipses (4-6px), dark fill | Adds industrial feel |
| Lines/seams | Short lines (strokeWidth 1-2) | Suggests panels, sections |
| Text labels | Tiny rectangles (representing label plates) | Suggests signage |
| Vents/grilles | Multiple thin horizontal lines | Suggests ventilation/airflow |
| Wires/cables | Lines with slight curves | Suggests connectivity |
| Handles/rails | Short thick lines (strokeWidth 3-4) | Suggests accessibility |

### 4. Glow and Emphasis

Make important elements pop:

**Beacon/light glow:**
1. Large ellipse (40-60px), bright fill, opacity 15-25% → glow aura
2. Medium ellipse (20-30px), bright fill, opacity 40-60% → inner glow
3. Small ellipse (8-12px), bright fill, opacity 100% → light source

**Screen glow:**
1. Rectangle slightly larger than screen, fill matching screen color, opacity 10-20%
2. Screen rectangle with dark fill (#1A1A1A or #0A192F)
3. Content elements on screen (status bars, charts as small rectangles)

**Selection/highlight:**
1. Rectangle or ellipse slightly larger than target, dashed stroke, accent color
2. Target element on top

### 5. Environmental Elements

Create atmosphere around objects:

| Element | Composition | When to Use |
|---------|-------------|-------------|
| Ground plane | Wide rectangle, very low height (8-15px), dark fill, low opacity | Under every station object |
| Ground shadow | Ellipse below object, dark fill, opacity 8-15%, wider than object | Under tall objects |
| Signal waves | 2-3 concentric arc-like ellipses, increasing size, decreasing opacity | Near antennas, sensors, radios |
| Steam/exhaust | 2-3 ellipses ascending, decreasing size, very low opacity (5-15%) | Near engines, vents |
| Connection lines | Dashed lines between related elements | Showing data flow, connections |
| Measurement marks | Short vertical lines with horizontal line between | Showing scale, dimensions |

### 6. Color Depth

Use multiple shades to create volume. Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/color-palette.md` for the full grey-scale inversion table, dark mode floor (#888888), and accent/glass/status colors.

**Key principle:** Select grey palette based on `CANVAS_CONTEXT.color_mode`. Dark mode inverts the grey scale so station elements contrast against dark backgrounds. No fill below #888888 in dark mode.

**Glass/Screen palette** (both modes):
- Frame: #333333 or #444444
- Glass surface: #87CEEB at 40-60% opacity, or #4488CC
- Reflection: small white rectangle at 20-30% opacity, angled
- Content: colored rectangles/lines inside at reduced opacity

### 7. Scale and Proportion

For A1 canvas (4961 x 3508), station objects should be:

| Scale | Object Bounding Box | Element Count (Combined) | Visual Weight |
|-------|-------------------|--------------------------|---------------|
| hero (1.5x) | 400-600px wide, 300-500px tall | 280-340 elements | Dominant, highly detailed |
| standard (1.0x) | 250-400px wide, 200-350px tall | 230-290 elements | Clear, richly detailed |
| supporting (0.8x) | 200-320px wide, 160-280px tall | 180-240 elements | Present, well-detailed |

**Proportions within an object:**
- Main body: 60-70% of bounding box
- Details and accents: 20-30%
- Environmental (shadow, ground): 10-15%

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Single shape = object | Unrecognizable from distance | Stack 5+ shapes minimum |
| All same size elements | Flat, no hierarchy | Vary sizes: 1 large + several medium + many small |
| No overlapping | Looks like a diagram, not illustration | Overlap shapes to create depth |
| Uniform opacity | Everything blends together | Use 100% for foreground, 40-80% for mid, 10-30% for back |
| Only rectangles | Mechanical, rigid | Mix all 4 shape types (rect, ellipse, diamond, line) |
| No ground contact | Objects float in space | Add ground plane or shadow below |
| Symmetric layout | Boring, unnatural | Offset elements slightly, vary spacing |
| Bright colors everywhere | Overwhelming, no focus | Muted base (greys) + 1-2 accent colors |

---

## Composition Workflow for Station Artists

1. **Identify the object** — What is it? What makes it recognizable?
2. **Sketch the silhouette** — What's the overall shape? (Usually 2-3 large overlapping primitives)
3. **Add structure** — Divide into sections (base, middle, top; or left panel, main body, right wing)
4. **Insert details** — Windows, doors, lights, panels, controls (10-15 small elements)
5. **Apply depth** — Shadow behind, ground plane below, highlights on top
6. **Add recognition cues** — The 2-3 elements that make THIS object distinct from any other
7. **Environmental touches** — Signal waves, steam, glow effects where appropriate
8. **Color and opacity pass** — Ensure depth through color gradation and opacity variation

---

## High-Density Composition (250+ Elements per Object)

### Planning for 250+ Elements

At 250+ elements, composition must be deliberate. Break the object into **named regions** and assign element budgets:

```
Region planning example — Control Tower (260 elements):

Region: Base Building (45 elements)
  - Main wall: 3 rectangles (front, side, shadow)
  - Windows: 12 small rectangles (4 cols × 3 rows)
  - Window frames: 12 lines (horizontal dividers)
  - Door area: 4 elements (frame, door, handle, glass)
  - Foundation: 3 elements (base, plinth, step)
  - Wall details: 11 elements (panels, vents, signage, drain pipes, lighting)

Region: Tower Shaft (50 elements)
  - Main shaft: 3 rectangles (body, shadow side, front face)
  - Windows: 16 small rectangles (4 per floor × 4 floors)
  - Window details: 8 lines (horizontal bands between floors)
  - Panel seams: 8 vertical lines
  - Structural bands: 6 horizontal rectangles (floor divisions)
  - Rivets/bolts: 9 tiny ellipses along seams

Region: Observation Deck (55 elements)
  - Deck structure: 5 rectangles (floor, walls, roof, overhang, fascia)
  - Glass panels: 12 rectangles (windows around perimeter)
  - Window mullions: 10 vertical lines
  - Interior hints: 8 elements (console shapes, chair outlines, screen glow)
  - Exterior walkway: 6 elements (railing, posts, floor markings)
  - Equipment: 5 elements (binoculars, panels, comms)
  - Lighting: 9 elements (strip lights, spot lights with glow)

Region: Radar & Antenna (35 elements)
  - Radar dome: 4 elements (dome, mount, hatch, seam line)
  - Antenna array: 6 elements (mast, panels, cross-members)
  - Signal waves: 6 ellipses (3 per antenna, concentric)
  - Beacon: 6 elements (light, inner glow, outer glow, housing, mount, cable)
  - Lightning rod: 3 elements (rod, base, ground wire)
  - Weather instruments: 6 elements (anemometer arms, cups, vane)
  - Status LEDs: 4 tiny ellipses

Region: Ground & Environment (40 elements)
  - Ground plane: 4 elements (shadow, surface, texture patches)
  - Equipment at base: 10 elements (cabinets, generators, fences)
  - Approach lights: 8 elements (light posts + lights)
  - Cables/pipes: 6 lines (power, data, drainage)
  - Warning signs: 4 elements (sign shapes + hazard diamonds)
  - Landscaping: 8 elements (path edges, bollards, planters)

Region: Surface Textures & Micro-Details (35 elements)
  - Panel seam lines on walls: 10 thin lines
  - Rivet rows along structural bands: 8 tiny ellipses
  - Paint weathering marks: 5 low-opacity rectangles
  - Cable bundles along shaft: 4 thin lines
  - Pipe fittings/joints: 4 small rectangles
  - Rust spots: 4 tiny ellipses (orange-brown, very low opacity)
```

### Multi-Batch Execution

With 250+ elements per object, plan sub-regions to complete per batch:

```
Batch 1 (50): Ground contact + Main structure (Layers A-B)
Batch 2 (50): Internal structure + wall details (Layer C)
Batch 3 (50): Detail elements part 1 — windows, panels, doors (Layer D)
Batch 4 (50): Detail elements part 2 — equipment, sensors, lights (Layer D)
Batch 5 (50): Accents + environmental + surface textures (Layers E-F)
```

### Structure vs. Enrichment Split

250+ element objects are built in TWO PASSES:

**Pass 1 — Structure (station-structure-artist): 130-160 elements**
- Silhouette (main shapes that define the object form)
- Internal divisions (floors, panels, major sections)
- Primary details (windows, doors, major equipment)
- Circle + text elements
- Returns `structure_map` with named regions and bounding boxes

**Pass 2 — Enrichment (station-enrichment-artist): 100-130 elements**
- Surface textures (seam lines, panel edges, material patterns)
- Micro-details (rivets, screws, vents, wire clips, LED dots)
- Equipment accessories (cameras, signs, gauges, meters)
- Environmental integration (cast shadows, reflections, particles)

---

## Micro-Detail Catalog

Elements at 5-20px scale that create visual texture and industrial realism:

### Hardware & Fasteners (3-8px)
| Detail | Shape | Size | Fill | Opacity |
|--------|-------|------|------|---------|
| Rivet | ellipse | 4-6px | #888888 | 60-80% |
| Screw head | ellipse | 5-7px | #777777 | 70% |
| Bolt head (hex) | diamond | 6-8px | #999999 | 60% |
| Washer | ellipse | 8px, stroke only | #AAAAAA | 50% |
| Nail head | ellipse | 3-4px | #666666 | 70% |

### Structural Lines (1-2px stroke)
| Detail | Shape | Length | Stroke | Opacity |
|--------|-------|--------|--------|---------|
| Panel seam | line | 20-100px | #CCCCCC | 30-50% |
| Weld line | line | 10-40px | #AAAAAA | 25% |
| Joint line | line | 5-20px | #BBBBBB | 40% |
| Crack | line | 8-30px | #999999 | 15-25% |
| Edge trim | line | 20-80px | #DDDDDD | 35% |

### Surface Patterns (5-15px)
| Detail | Shape | Size | Fill | Opacity |
|--------|-------|------|------|---------|
| Vent slat | rectangle | 15×2px | #555555 | 50% |
| Brick (single) | rectangle | 12×6px | #CC9966 | 20% |
| Tile | rectangle | 10×10px | #DDDDDD | 15% |
| Gravel dot | ellipse | 3-5px | #999999 | 20% |
| Metal grain | line | 5-10px | #CCCCCC | 10% |

### Equipment & Indicators (6-15px)
| Detail | Shape | Size | Fill | Opacity |
|--------|-------|------|------|---------|
| LED indicator | ellipse | 6-8px | varies | 80-100% |
| Small button | rectangle | 8×6px | #444444 | 70% |
| Gauge face | ellipse | 12-15px | #FFFFFF | 60% |
| Wire clip | rectangle | 4×6px | #888888 | 50% |
| Pipe fitting | rectangle | 8×10px | #AAAAAA | 60% |
| Small vent | rectangle | 10×8px | #333333 | 40% |
| Cable bundle | line | 15-30px | #444444, strokeWidth:3 | 40% |

### Weathering & Age (very low opacity)
| Detail | Shape | Size | Fill | Opacity |
|--------|-------|------|------|---------|
| Rust spot | ellipse | 5-12px | #CC6633 | 8-15% |
| Water stain | rectangle | 10-25px tall | #AABBAA | 5-10% |
| Dirt mark | ellipse | 8-15px | #998877 | 5-8% |
| Faded paint | rectangle | 15-30px | lighter variant | 8-12% |
| Moss/lichen | ellipse | 5-10px | #6B8E6B | 5-8% |

---

## Texture Patterns from Repeated Elements

Create visual texture by repeating small elements in patterns:

### Rivet Row Pattern
```
8-12 ellipses, 4px diameter, spaced 10-15px apart along a structural seam
Fill: #888888, opacity: 60%
Creates: Industrial/structural feel along panel edges
```

### Window Grid Pattern
```
3×4 grid of rectangles (12 total), 15×20px each, spaced 5px
Fill: #87CEEB or #4488CC at 40-60% opacity
Optional: thin lines between windows (mullions)
Creates: Building facade texture
```

### Brick/Panel Pattern
```
2-3 rows of offset rectangles, 12×6px each, 2px gaps
Fill: slightly varied shades (#CC9966, #BB8855, #DDAA77) at 15-25% opacity
Creates: Masonry or panel cladding texture
```

### Ventilation Slat Pattern
```
5-8 horizontal lines, 2px tall, spaced 4px apart inside a rectangle
Stroke: #555555, opacity: 30-50%
Creates: Air intake / exhaust grille texture
```

### Cable Run Pattern
```
3-5 parallel lines, 1px stroke, following a path along a wall
Stroke: #444444, strokeWidth: 1, opacity: 30%
Creates: Cable tray / conduit texture
```

---

## Batch Strategy for 250+ Elements

### Sub-Region Planning

Before creating ANY elements, divide the object into 5-6 named sub-regions. Each sub-region should have:
- Clear bounding box (x, y, width, height)
- Target element count (40-60 elements)
- Element types to include

### Batch Sizing Rules

| Batch Size | When to Use |
|-----------|-------------|
| 50 | Default — optimal throughput |
| 25 | Fallback if 50-element batch fails |
| 10 | Emergency fallback for persistent failures |

### Element Counting

Track elements created after each batch. If falling behind target:
- Increase detail density in remaining batches
- Add micro-detail elements (rivets, seams, texture lines)
- Add environmental elements (shadows, reflections, particles)

### Avoiding Coordinate Overlap

When placing many small elements in one region:
- Use a grid pattern with 8-15px spacing
- Offset alternate rows by half the spacing (brick pattern)
- Vary sizes slightly (±2px) to avoid mechanical look
- Vary opacity slightly (±5%) for natural feel
