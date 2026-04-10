# Zone Layout Formulas

Coordinate formulas for placing content zones on the Excalidraw canvas. Each layout type
defines a zone grid that maps content blocks to rectangular areas.

## Canvas Dimensions

| Orientation | Width | Height | Margin | Usable Area |
|-------------|-------|--------|--------|-------------|
| landscape | 1600 | 1000 | 40 | 1520 × 920 |
| portrait | 1000 | 1600 | 40 | 920 × 1520 |

**Reserved areas:**
- Title banner: top 120px of usable area
- Footer: bottom 60px of usable area
- CTA: 70px above footer (if present)
- Content area: everything between title and CTA/footer

**Content origin (landscape):** x=60, y=170. Content size: 1480 × 660.
**Content origin (portrait):** x=60, y=170. Content size: 880 × 1200.

## Zone Spacing

Gap between zones: 24px. Zone padding (internal): 16px.

---

## stat-heavy (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER (full width, 120px)            │
├────────┬────────┬────────────────────────────┤
│ KPI 1  │ KPI 2  │ KPI 3        (row 1: 180px)│
├────────┴────────┼────────────────────────────┤
│ Chart           │ Stat Row     (row 2: 260px)│
│ (60% width)     │ (40% width)                │
├─────────────────┴────────────────────────────┤
│ Process / Text / Extra KPI     (row 3: 180px)│
├──────────────────────────────────────────────┤
│ CTA (70px) + FOOTER (60px)                   │
└──────────────────────────────────────────────┘
```

**KPI row zones (3 across):**
- Zone 1: x=60, y=170, w=480, h=180
- Zone 2: x=564, y=170, w=480, h=180
- Zone 3: x=1068, y=170, w=472, h=180

**Middle row (2 zones):**
- Chart zone: x=60, y=374, w=880, h=260
- Stat zone: x=964, y=374, w=576, h=260

**Bottom row (full width or split):**
- Full: x=60, y=658, w=1480, h=180
- Split 2: x=60/784, y=658, w=700/700, h=180

---

## comparison (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER (full width)                   │
├───────────┬───────────────────────┬──────────┤
│ Hero KPI  │                       │ Hero KPI │
│ (left)    │ COMPARISON PAIR       │ (right)  │
│           │ (center, 60% width)   │          │
├───────────┴───────────────────────┴──────────┤
│ Evidence Strip (stat-row, full width)        │
├──────────────────────────────────────────────┤
│ Chart or Extra Zone (full width)             │
├──────────────────────────────────────────────┤
│ CTA + FOOTER                                 │
└──────────────────────────────────────────────┘
```

**KPI left:** x=60, y=170, w=220, h=300
**Comparison center:** x=304, y=170, w=880, h=300
**KPI right:** x=1208, y=170, w=332, h=300
**Evidence:** x=60, y=494, w=1480, h=140
**Extra:** x=60, y=658, w=1480, h=170

---

## timeline-flow (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER                                │
├──────────────────────────────────────────────┤
│                                              │
│  PROCESS STRIP (full width, 280px)           │
│  Steps flow left → right with arrows         │
│                                              │
├──────────────────────────────────────────────┤
│ Supporting zones below (stat-row, text, KPI) │
├──────────────────────────────────────────────┤
│ CTA + FOOTER                                 │
└──────────────────────────────────────────────┘
```

**Process strip:** x=60, y=170, w=1480, h=280
**Support row:** x=60, y=474, w=1480, h=200 (split as needed)

---

## hub-spoke (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER                                │
├──────────────────────────────────────────────┤
│         ┌───┐                                │
│    ┌──┐ │HUB│ ┌──┐                           │
│    │N1│←┤   ├→│N2│   Central hub + spokes    │
│    └──┘ │   │ └──┘   (460px height)          │
│         └─┬─┘                                │
│      ┌──┐ │ ┌──┐                             │
│      │N3│←┘→│N4│                             │
│      └──┘   └──┘                             │
├──────────────────────────────────────────────┤
│ Supporting zones (stat-row, text)            │
├──────────────────────────────────────────────┤
│ CTA + FOOTER                                 │
└──────────────────────────────────────────────┘
```

**Hub center:** cx=800, cy=400 (relative to canvas), radius 60
**Spoke nodes:** arranged in circle at radius 200 from hub center
**Each spoke:** x=cx±200, y=cy±200, w=140, h=80

---

## funnel-pyramid (Portrait preferred)

```
┌───────────────────────┐
│  TITLE BANNER         │
├───────────────────────┤
│ ╔═══════════════════╗ │
│ ║   TIER 1 (widest) ║ │
│ ╠═══════════════╗   ║ │
│ ║   TIER 2      ║   ║ │
│ ╠═══════════╗   ║   ║ │
│ ║   TIER 3  ║   ║   ║ │
│ ╠═══════╗   ║   ║   ║ │
│ ║ T4    ║   ║   ║   ║ │
│ ╚═══════╩═══╩═══╩═══╝ │
├───────────────────────┤
│ CTA + FOOTER          │
└───────────────────────┘
```

**Tiers:** centered horizontally, each tier narrower than the one above/below.
Width formula: `tier_width = usable_width × (1 - tier_index × 0.15)`

---

## list-grid (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER                                │
├──────────┬──────────┬────────────────────────┤
│  Card 1  │  Card 2  │  Card 3               │
│  icon    │  icon    │  icon    (row 1)       │
│  label   │  label   │  label                 │
├──────────┼──────────┼────────────────────────┤
│  Card 4  │  Card 5  │  Card 6               │
│  icon    │  icon    │  icon    (row 2)       │
│  label   │  label   │  label                 │
├──────────┴──────────┴────────────────────────┤
│ CTA + FOOTER                                 │
└──────────────────────────────────────────────┘
```

**Grid:** 2 or 3 columns, 2-3 rows. Zone size = content_width/cols × row_height.
Column width: `(1480 - (cols-1)*24) / cols`
Row height: `(content_height - (rows-1)*24) / rows`

---

## flow-diagram (Landscape)

```
┌──────────────────────────────────────────────┐
│  TITLE BANNER                                │
├──────────────────────────────────────────────┤
│                                              │
│  DIAGRAM ZONE (full width, 400px)            │
│  Process flow or hub-spoke SVG equivalent    │
│                                              │
├──────────┬──────────┬────────────────────────┤
│ Annot 1  │ Annot 2  │ Annot 3   (150px)     │
├──────────┴──────────┴────────────────────────┤
│ CTA + FOOTER                                 │
└──────────────────────────────────────────────┘
```

**Diagram zone:** x=60, y=170, w=1480, h=400
**Annotation row:** x=60, y=594, w=480 each, h=150 (up to 3 columns)
