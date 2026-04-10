# Element Recipes for Infographic Rendering

Excalidraw element compositions for each infographic component. Every element uses the
hand-drawn aesthetic — roughness >= 1 for sketchnote/whiteboard presets, 0 for clean presets.

## Common Element Properties

All elements share these baseline properties:

```json
{
  "roughness": 1,
  "strokeWidth": 2,
  "strokeColor": "{PALETTE.primary}",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeStyle": "solid",
  "opacity": 100
}
```

**Roughness by preset:** sketchnote=2, whiteboard=1, editorial=0, data-viz=0, corporate=0.

**Font families:**
- `1` = Virgil (hand-drawn) — sketchnote, whiteboard
- `2` = Helvetica (clean) — editorial, corporate
- `3` = Cascadia (monospace) — data-viz numbers

---

## Title Banner

Position: centered at top, within page border.

### Elements

**1. Headline text:**
```json
{
  "type": "text", "x": 800, "y": 50, "text": "{headline}",
  "fontSize": 36, "fontFamily": 1, "textAlign": "center",
  "strokeColor": "{PALETTE.primary}", "fontWeight": "bold"
}
```

**2. Underline accent:**
```json
{
  "type": "line", "x": 300, "y": 90, "width": 1000, "height": 0,
  "strokeColor": "{PALETTE.accent}", "strokeWidth": 3, "roughness": 2
}
```

**3. Subline text:**
```json
{
  "type": "text", "x": 800, "y": 100, "text": "{subline}",
  "fontSize": 16, "fontFamily": 1, "textAlign": "center",
  "strokeColor": "{PALETTE.text_muted}"
}
```

**4. Metadata text:**
```json
{
  "type": "text", "x": 800, "y": 125, "text": "{metadata}",
  "fontSize": 12, "fontFamily": 1, "textAlign": "center",
  "strokeColor": "{PALETTE.text_muted}"
}
```

---

## Zone Border Recipes

### Standard Zone (solid)
```json
{
  "type": "rectangle", "x": "{zone.x}", "y": "{zone.y}",
  "width": "{zone.w}", "height": "{zone.h}",
  "strokeColor": "{PALETTE.border}", "strokeWidth": 2,
  "roughness": 1, "roundness": {"type": 3, "value": 12},
  "backgroundColor": "{PALETTE.surface}", "fillStyle": "solid"
}
```

### Dashed Zone (sketchnote preset)
Same as above but: `"strokeStyle": "dashed"`, `"roughness": 2`

### Accent Zone (for hero KPIs)
Same as standard but: `"strokeColor": "{PALETTE.accent}"`, `"strokeWidth": 3`

### No-fill Zone (whiteboard preset)
Same as standard but: `"backgroundColor": "transparent"`

---

## Block Type Compositions

### kpi-card → Hero Number Zone

```
┌─────────────────┐
│     [icon]       │  ← small shape illustration (40px)
│      73%         │  ← Hero-Number (fontSize 48, accent_dark, bold)
│  weniger Vorfälle│  ← Hero-Label (fontSize 16, primary)
│  nach 6 Mo Pilot │  ← Sublabel (fontSize 12, text_muted)
│    Quelle: ...   │  ← Source (fontSize 10, text_muted)
└─────────────────┘
```

Elements: zone border + 4-6 text elements + optional icon (2-3 shapes).

**Hero number text:**
```json
{
  "type": "text", "text": "{Hero-Number}",
  "fontSize": 48, "fontFamily": 3, "textAlign": "center",
  "strokeColor": "{PALETTE.accent_dark}"
}
```

### stat-row → Evidence Strip

Horizontal arrangement of 2-4 stat blocks within the zone.

```
┌──────────┬──────────┬──────────┐
│   28%    │   94%    │   80%    │  ← numbers (fontSize 28, accent_dark)
│ Selling  │ Favorit  │ ohne VB  │  ← labels (fontSize 11, text_muted)
│   Zeit   │ gesetzt  │ entschied│
└──────────┴──────────┴──────────┘
```

Each stat: number text + label text + optional small circle icon.
Stat width: `zone.w / stats.length`. Centered within each segment.

### comparison-pair → Contrast Zone

```
┌────────────────┬─┬────────────────┐
│   Status quo   │ │ Mit Methodik   │  ← column labels (bold)
│ ────────────── │ │ ────────────── │
│ − Gen. Pitches │ │ + Spez. Argum. │  ← bullets with −/+ markers
│ − 87% ohne Ana │ │ + 38% Win Rate │     (danger/success colors)
│ − 3.120 Std    │ │ + 50% Abschl.  │
└────────────────┘ └────────────────┘
```

Elements:
- Left zone rectangle (surface fill)
- Right zone rectangle (light accent fill)
- Vertical divider line
- Column label texts (bold, 16px)
- Bullet texts (14px) with "−"/"+" prefix elements
- "−" markers in danger color, "+" in success color

### process-strip → Flow Strip

Horizontal chain of step containers connected by arrows:

```
  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │[icon]   │ →  │[icon]   │ →  │[icon]   │ →  │[icon]   │
  │ Step 1  │    │ Step 2  │    │ Step 3  │    │ Step 4  │
  └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

Each step: rounded rectangle + label text + icon shapes.
Step width: `(zone.w - (steps-1)*48) / steps`. Arrow gap: 48px.
Arrow elements connect each pair: `type: "arrow"`, roughness 1, accent color.

### chart → Data Sketch

**Bar chart approximation:**
```
  │ ██
  │ ██ ██
  │ ██ ██ ██
  │ ██ ██ ██ ██
  └──────────────
    Q1 Q2 Q3 Q4
```

For each data point: rectangle with height proportional to value. Max bar height: zone.h - 60.
Bar width: `(zone.w - 60) / datapoints / 2`. Fill: accent color. Labels below each bar.

**Doughnut approximation:**
- Large circle (stroke only, accent color, strokeWidth 12)
- Small filled arc segment (using a second circle with clip)
- Actually: use two concentric circles + text overlay with percentage
- Center text: "{primary_value}%" in large font

### text-block → Annotation

Simple: headline text (bold, 14px) + body text (12px, muted) + optional icon.

### icon-grid → Card Grid

Grid of small rectangles with icon shapes and labels. Each card:
- Rounded rectangle (surface fill)
- Icon composition (2-3 shapes, 32px)
- Label text (bold, 13px)
- Sublabel text (11px, muted)

---

## Icon Compositions

Simple pictograms from 2-5 Excalidraw primitives. Each fits a 40×40px bounding box.

| Concept | Shapes | Description |
|---------|--------|-------------|
| shield | rectangle(20×28) + diamond(20×12) at bottom | Security, protection |
| chart-up | rectangle(30×2, bottom line) + line(ascending, 3 points) | Growth, trend |
| clock | circle(r=16) + line(0,-12) + line(8,0) from center | Time, duration |
| person | circle(r=6, top) + rectangle(16×16, below) | People, team |
| warning | triangle(base 30, height 26) | Alert, risk |
| target | circle(r=16) + circle(r=8) + circle(r=2, filled) | Goal, precision |
| brain | ellipse(28×24) + 3 curved lines inside | AI, intelligence |
| lightbulb | ellipse(16×20, top) + rectangle(10×8, bottom) | Idea, insight |
| medal | circle(r=12) + rectangle(8×14, below) | Award, achievement |
| rocket | rectangle(12×28, rotated) + triangle(base, bottom) | Launch, speed |
| handshake | two mirrored "L" shapes overlapping | Partnership, deal |
| money | rectangle(28×16) + text("€" or "$", centered) | Cost, investment |

Position: within the zone, typically:
- KPI card: centered above the hero number
- Process step: centered above the label
- Comparison side: top-left of the column

---

## Style Preset Mapping

| Property | sketchnote | whiteboard | editorial | data-viz | corporate |
|----------|-----------|------------|-----------|----------|-----------|
| roughness | 2 | 1 | 0 | 0 | 0 |
| strokeWidth | 2 | 2 | 1 | 1 | 2 |
| fontFamily | 1 (Virgil) | 1 (Virgil) | 2 (Helvetica) | 2 (Helvetica) | 2 (Helvetica) |
| numberFont | 1 (Virgil) | 1 (Virgil) | 2 (Helvetica) | 3 (Cascadia) | 2 (Helvetica) |
| zone border | dashed | solid | solid | solid | solid |
| zone fill | surface | transparent | transparent | surface (light) | surface |
| zone roundness | 20 | 0 | 0 | 8 | 4 |
| page border | roughness 2 | roughness 1 | roughness 0 | roughness 0 | roughness 0 |
| accent usage | icons + arrows | numbers + CTA only | numbers only | numbers + charts | headers + CTA |

### Font Size Scale

| Element | sketchnote | whiteboard | editorial | data-viz | corporate |
|---------|-----------|------------|-----------|----------|-----------|
| Title headline | 32 | 36 | 36 | 32 | 34 |
| Hero number | 44 | 48 | 48 | 52 | 44 |
| Zone headline | 18 | 16 | 16 | 14 | 16 |
| Body text | 13 | 14 | 14 | 13 | 14 |
| Label | 11 | 12 | 12 | 11 | 12 |
| Source/metadata | 10 | 10 | 10 | 10 | 10 |

---

## CTA Composition

```
┌──────────────────────────────────┐
│  CTA Headline (bold, 18px)       │
│                                  │
│  ╔══════════════════════════╗    │  ← Button: rounded rect, accent fill
│  ║   CTA Button Text       ║    │     text: primary color, bold
│  ╚══════════════════════════╝    │
└──────────────────────────────────┘
```

Elements: headline text + rounded rectangle (accent fill) + button text.
Position: centered, below last content zone.

## Footer Composition

```
─────────────────────────────────────────  ← divider line (border color)
Customer Name        April 2026        Provider
Quellen: Source 1, Source 2, Source 3      ← source line (italic, 10px, muted)
```

Elements: divider line + 3-4 text elements.
