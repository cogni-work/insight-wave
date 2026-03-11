# Shape Recipes v3 — High-Density Illustration Library

## Purpose

Each recipe provides element-by-element specifications for station-structure-artist (Pass 1, 120-150 elements) and station-enrichment-artist (Pass 2, 100-130 elements). Together they produce **250+ element** stations.

## Dark Mode Grey-Scale Inversion

Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/color-palette.md`, section "Grey-Scale Inversion" for the full light→dark mapping table. Key points:

- Replace grey fills in recipe specs using that mapping when `color_mode = "dark"`
- Accent, glass, warning, and status colors remain unchanged in both modes
- **Dark mode floor: #888888** — no fill below this value (elements disappear against dark backgrounds)
- For elements at <50% opacity, use `#999999` minimum base color

---

**How to use:**
1. Find the recipe closest to the station's `object_name`
2. Scale all dimensions by scale factor (hero=1.5x, standard=1.0x, supporting=0.8x)
3. **Apply color mode** — if dark mode, invert greys using the mapping above
4. Apply theme colors (replace generic colors where appropriate)
5. Apply arc_role color mood
6. Apply the brief's roughness value
7. Use the Structure section for Pass 1 (station-structure-artist)
8. Use the Enrichment section for Pass 2 (station-enrichment-artist)
9. Adapt freely — these are inspiration, not rigid specs

---

## Recipe 1: Control Tower (260+ elements)

### Structure Section (Pass 1: 140 elements)

**Layer A: Ground Contact (10 elements)**
```
1.  rectangle: primary shadow, w:350 h:15, fill:#000000, opacity:10, y:base_bottom+5
2.  ellipse: soft shadow spread, w:400 h:25, fill:#000000, opacity:6
3.  rectangle: ground plane, w:300 h:8, fill:#888888, opacity:30
4.  rectangle: concrete apron left, w:100 h:6, fill:#AAAAAA, opacity:25
5.  rectangle: concrete apron right, w:100 h:6, fill:#AAAAAA, opacity:25
6.  line: ground crack 1, w:60, strokeColor:#999999, opacity:15
7.  line: ground crack 2, w:40, strokeColor:#999999, opacity:12
8.  rectangle: curb edge, w:320 h:4, fill:#777777, opacity:20
9.  ellipse: puddle reflection, w:50 h:10, fill:#87CEEB, opacity:8
10. rectangle: drain grate, w:20 h:15, fill:#555555, opacity:25
```

**Layer B: Main Structure (25 elements)**
```
11. rectangle: base building front, w:250 h:100, fill:#C0C0C0, strokeColor:#999999
12. rectangle: base building shadow side, w:30 h:100, fill:#A0A0A0
13. rectangle: base building top ledge, w:260 h:8, fill:#999999
14. rectangle: tower shaft body, w:80 h:280, fill:#D0D0D0, strokeColor:#AAAAAA
15. rectangle: shaft shadow side, w:15 h:280, fill:#999999
16. rectangle: shaft front panel, w:65 h:280, fill:#D5D5D5, opacity:50
17. rectangle: observation deck floor, w:200 h:20, fill:#B0B0B0, strokeColor:#888888
18. rectangle: observation deck glass, w:200 h:80, fill:#87CEEB, opacity:50, strokeColor:#666666
19. rectangle: observation deck roof, w:220 h:15, fill:#888888
20. rectangle: deck overhang left, w:15 h:12, fill:#888888
21. rectangle: deck overhang right, w:15 h:12, fill:#888888
22. rectangle: roof edge fascia, w:220 h:4, fill:#666666
23. ellipse: radar dome, w:60 h:50, fill:#CCCCCC, strokeColor:#999999
24. rectangle: radar base mount, w:30 h:10, fill:#AAAAAA
25. rectangle: antenna mast, w:6 h:50, fill:#888888
26. rectangle: base entrance alcove, w:60 h:65, fill:#AAAAAA
27. rectangle: entrance door, w:50 h:60, fill:#555555
28. rectangle: door frame top, w:54 h:4, fill:#444444
29. rectangle: foundation plinth, w:270 h:15, fill:#888888
30. rectangle: foundation step, w:280 h:8, fill:#777777
31. rectangle: shaft base transition, w:100 h:12, fill:#B0B0B0
32. rectangle: utility room door, w:30 h:45, fill:#666666, x:base_right-40
33. line: roof line, w:250, strokeColor:#888888, strokeWidth:2
34. rectangle: ventilation unit on roof, w:40 h:25, fill:#999999
35. rectangle: elevator housing on roof, w:25 h:35, fill:#AAAAAA
```

**Layer C: Internal Structure (30 elements)**
```
36-39. rectangle: shaft window row 1-4, w:40 h:15, fill:#87CEEB, opacity:60 (4 windows)
40-43. rectangle: shaft window frames 1-4, w:42 h:17, fill:none, strokeColor:#888888 (4 frames)
44-47. line: shaft horizontal band 1-4, w:80, strokeColor:#BBBBBB (4 floor dividers)
48-55. line: deck window mullion 1-8, vertical, strokeColor:#AAAAAA (8 mullions)
56-57. rectangle: deck interior console left/right, w:30 h:15, fill:#333333, opacity:30
58-59. rectangle: base window left/right, w:30 h:25, fill:#87CEEB, opacity:50
60-61. rectangle: base window frame left/right, w:32 h:27, strokeColor:#888888
62-63. line: base wall panel seam 1-2, vertical, strokeColor:#CCCCCC
64. rectangle: stairwell window (narrow vertical), w:12 h:80, fill:#87CEEB, opacity:35
65. rectangle: electrical panel area, w:40 h:30, fill:#E0E0E0
```

**Layer D: Detail Elements (40 elements)**
```
66. ellipse: beacon light, w:12 h:12, fill:#FF0000
67. ellipse: beacon glow inner, w:25 h:25, fill:#FF0000, opacity:25
68. ellipse: beacon glow outer, w:45 h:45, fill:#FF0000, opacity:10
69. line: beacon mount, w:0 h:8, strokeColor:#666666
70. line: radar arm, w:40 h:0, strokeColor:#666666, strokeWidth:2
71. ellipse: radar tip, w:8 h:8, fill:#AAAAAA
72-74. ellipse: approach light 1-3, w:8 h:8, fill:#00FF00
75-77. ellipse: approach light glow 1-3, w:16 h:16, fill:#00FF00, opacity:15
78-79. ellipse: runway indicator light 1-2, w:8 h:8, fill:#FFAA00
80. line: railing on deck roof, w:200, strokeColor:#999999, strokeWidth:1
81-84. line: railing posts 1-4, w:0 h:10, strokeColor:#999999
85. rectangle: signage plate, w:40 h:12, fill:#FFFFFF, opacity:40
86. rectangle: signage text, w:30 h:6, fill:#333333, opacity:30
87-88. line: lightning rod + cable, w:0 h:25, strokeColor:#AAAAAA
89-91. ellipse: antenna panel 1-3 on mast, w:12 h:8, fill:#CCCCCC
92-93. line: guy wire 1-2 (thin lines from mast), strokeColor:#CCCCCC, opacity:20
94. rectangle: base signage (tower ID), w:60 h:15, fill:#1A1A1A
95. rectangle: security camera mount, w:12 h:8, fill:#333333
96. ellipse: camera lens, w:6 h:6, fill:#222222
97. rectangle: fire extinguisher box, w:12 h:18, fill:#FF4444, opacity:50
98-99. ellipse: ceiling lights in deck 1-2, w:10 h:10, fill:#FFFFCC, opacity:30
100. rectangle: access keypad, w:8 h:12, fill:#333333
101. ellipse: keypad LED, w:4 h:4, fill:#00CC66
102-103. line: cable conduit 1-2, vertical lines along shaft, strokeColor:#888888
104-105. rectangle: equipment cabinet 1-2 at base, w:25 h:20, fill:#555555
```

**Layer E: Accent & Emphasis (15 elements)**
```
106-107. rectangle: accent stripe on shaft 1-2, w:80 h:4, fill:theme_accent
108. rectangle: deck floor edge light strip, w:200 h:3, fill:theme_accent, opacity:30
109-110. ellipse: deck interior screen glow 1-2, w:25 h:15, fill:#00AAFF, opacity:20
111-112. ellipse: status light green 1-2 on base, w:6 h:6, fill:#00CC66
113. ellipse: status light amber on base, w:6 h:6, fill:#FFAA00
114-116. rectangle: window glow reflection 1-3, w:20 h:8, fill:#FFFFCC, opacity:10
117-118. ellipse: approach path indicator 1-2, w:10 h:10, fill:theme_accent, opacity:40
119-120. line: accent line on entrance frame top/bottom, w:50, strokeColor:theme_accent, opacity:50
```

**Layer F: Environmental Touches (15 elements)**
```
121-123. ellipse: signal wave 1-3 from antenna, concentric, fill:transparent, stroke:#4488CC, opacity:30/20/10
124-126. ellipse: wind indicator elements (pole + vane + sock), various
127-128. line: power cable to building 1-2, strokeColor:#333333, strokeStyle:dashed
129-130. ellipse: birds near tower 1-2, w:8 h:4, fill:#333333, opacity:15
131-133. ellipse: cloud wisps near top 1-3, w:60-100 h:15-25, fill:#FFFFFF, opacity:8
134. rectangle: shadow cast on ground from tower, w:60 h:200, fill:#000000, opacity:5
135. line: fence line near base, w:120, strokeColor:#CCCCCC, opacity:20
```

**Number Text + Headline: 8-12 elements** (inline accent-colored number text LEFT of headline, as per station-structure-artist workflow Steps 3-6)

### Enrichment Section (Pass 2: 120 elements)

**Surface Textures (30 elements)**
```
1-8.   line: shaft panel seam lines (vertical), w:0 h:40-80, strokeColor:#CCCCCC, opacity:25
9-16.  line: base wall horizontal joint lines, w:30-60, strokeColor:#CCCCCC, opacity:20
17-22. line: deck roof edge details, w:10-30, strokeColor:#AAAAAA, opacity:30
23-26. line: foundation mortar lines, w:20-40, strokeColor:#BBBBBB, opacity:15
27-30. line: concrete slab joints on ground, w:40-80, strokeColor:#BBBBBB, opacity:12
```

**Micro-Details (35 elements)**
```
31-42. ellipse: rivet rows along structural bands, 4px diameter, fill:#888888, opacity:60 (12 rivets)
43-48. ellipse: bolt heads on deck floor, 5px diameter, fill:#777777, opacity:50 (6 bolts)
49-52. rectangle: small vent grilles on shaft, w:12 h:8, fill:#555555, opacity:40
53-56. line: cable clips along conduit, w:6, strokeColor:#888888, opacity:40 (4 clips)
57-60. rectangle: pipe fittings at base, w:8 h:6, fill:#AAAAAA, opacity:50
61-63. ellipse: drainage holes, w:5 h:5, fill:#444444, opacity:30
64-65. rectangle: small warning labels, w:10 h:6, fill:#FFAA00, opacity:40
```

**Equipment & Accessories (30 elements)**
```
66-67. rectangle: exterior light fixtures on base, w:8 h:12, fill:#DDDDDD
68-69. ellipse: light fixture glow, w:15 h:15, fill:#FFFFCC, opacity:15
70-71. rectangle: cable junction boxes, w:10 h:8, fill:#555555
72. rectangle: rain gauge, w:6 h:15, fill:#CCCCCC
73. rectangle: barometer housing, w:12 h:12, fill:#DDDDDD
74. ellipse: barometer face, w:10 h:10, fill:#FFFFFF, opacity:60
75-76. rectangle: solar panel 1-2 on base roof, w:25 h:15, fill:#334466
77-78. line: solar panel grid lines, strokeColor:#445577
79-80. rectangle: HVAC ductwork 1-2 on base, w:15 h:10, fill:#BBBBBB
81-83. line: pipe runs along base wall 1-3, w:40-80, strokeColor:#999999, strokeWidth:2
84-85. rectangle: meter panels 1-2, w:8 h:12, fill:#EEEEEE
86-87. ellipse: meter dial 1-2, w:6 h:6, fill:#FFFFFF
88-90. rectangle: step lights 1-3 near entrance, w:10 h:4, fill:#FFFFCC, opacity:30
91-93. line: handrail on entrance stairs 1-3, strokeColor:#888888
94-95. rectangle: security bollard 1-2, w:8 h:15, fill:#888888
```

**Environmental Integration (25 elements)**
```
96-100. rectangle: shadow projections from details, varied, fill:#000000, opacity:3-6
101-104. ellipse: reflection highlights on glass, w:5-15, fill:#FFFFFF, opacity:8-15
105-108. ellipse: dust/particle motes near base, w:3-5, fill:#CCCCCC, opacity:5
109-112. line: rain streak marks on shaft, w:0 h:15-30, strokeColor:#AABBCC, opacity:5
113-116. ellipse: moss spots at base, w:5-8, fill:#6B8E6B, opacity:5-8
117-120. rectangle: shadow detail under ledges, w:20-50 h:3, fill:#000000, opacity:8
```

---

## Recipe 2: Biometric Terminal Gate (250+ elements)

### Structure Section (Pass 1: 135 elements)

**Layer A: Ground Contact (10 elements)**
```
1. rectangle: ground shadow, w:320 h:12, fill:#000000, opacity:10
2. ellipse: soft shadow, w:360 h:20, fill:#000000, opacity:6
3. rectangle: floor surface, w:300 h:6, fill:#CCCCCC, opacity:40
4. rectangle: approach walkway, w:400 h:4, fill:#DDDDDD, opacity:30
5-6. line: floor guide lines left/right, w:60, strokeColor:#FFAA00, strokeStyle:dashed
7-8. rectangle: floor tile markings left/right, w:40 h:3, fill:#EEEEEE, opacity:20
9. rectangle: floor drain, w:80 h:3, fill:#888888, opacity:20
10. line: floor joint line, w:300, strokeColor:#CCCCCC, opacity:15
```

**Layer B: Main Structure (25 elements)**
```
11. rectangle: left pillar body, w:40 h:200, fill:#E0E0E0, strokeColor:#BBBBBB
12. rectangle: left pillar shadow side, w:8 h:200, fill:#C0C0C0
13. rectangle: right pillar body, w:40 h:200, fill:#E0E0E0, strokeColor:#BBBBBB
14. rectangle: right pillar shadow side, w:8 h:200, fill:#C0C0C0
15. rectangle: top crossbar, w:280 h:25, fill:#D0D0D0, strokeColor:#AAAAAA
16. rectangle: crossbar fascia, w:280 h:4, fill:#999999
17. rectangle: crossbar internal beam, w:260 h:8, fill:#BBBBBB, opacity:50
18-19. rectangle: barrier arm left/right, w:100 h:8, fill:#888888
20-21. rectangle: barrier arm tip left/right, w:15 h:6, fill:#FF4444
22. rectangle: scanner body, w:60 h:120, fill:#333333, strokeColor:#222222
23. rectangle: scanner screen frame, w:54 h:75, fill:#1A1A1A
24. rectangle: scanner screen glass, w:50 h:70, fill:#0A192F
25. rectangle: scanner base, w:65 h:15, fill:#444444
26. rectangle: scanner top cap, w:58 h:8, fill:#444444
27. rectangle: left pillar base plate, w:50 h:8, fill:#CCCCCC
28. rectangle: right pillar base plate, w:50 h:8, fill:#CCCCCC
29-30. rectangle: pillar top cap left/right, w:44 h:6, fill:#CCCCCC
31. rectangle: overhead sign frame, w:130 h:35, fill:#1A1A1A
32. rectangle: sign content area, w:110 h:20, fill:#FFFFFF, opacity:30
33-34. line: sign mounting bracket left/right, w:0 h:15, strokeColor:#888888
35. rectangle: sign LED strip, w:120 h:3, fill:#00CC66, opacity:30
```

**Layer C: Internal Structure (25 elements)**
```
36-37. line: left pillar panel seam (vertical), strokeColor:#CCCCCC
38-39. line: right pillar panel seam (vertical), strokeColor:#CCCCCC
40-41. rectangle: pillar accent stripe left/right, w:40 h:4, fill:theme_accent
42-43. rectangle: pillar mid-stripe left/right, w:40 h:4, fill:theme_accent, y:mid
44. rectangle: screen content glow, w:46 h:66, fill:#00D084, opacity:20
45. ellipse: fingerprint outer ring, w:30 h:35, strokeColor:#00D084, strokeWidth:2
46. ellipse: fingerprint inner ring, w:16 h:20, strokeColor:#00D084, strokeWidth:1
47-48. line: fingerprint whorl lines 1-2, strokeColor:#00D084, opacity:30
49. rectangle: card reader slot, w:25 h:5, fill:#555555
50. rectangle: card reader indicator, w:20 h:3, fill:#222222
51-52. rectangle: barrier arm hinge left/right, w:12 h:12, fill:#777777
53. rectangle: scanner speaker grille, w:30 h:8, fill:#222222
54-56. line: speaker grille lines 1-3, w:25, strokeColor:#333333
57-58. rectangle: pillar cable channel left/right, w:4 h:100, fill:#D0D0D0
59-60. rectangle: crossbar internal detail left/right, w:30 h:4, fill:#AAAAAA
```

**Layer D: Detail Elements (35 elements)**
```
61. ellipse: green status light, w:14 h:14, fill:#00CC66
62. ellipse: green glow, w:28 h:28, fill:#00CC66, opacity:20
63. ellipse: amber light, w:14 h:14, fill:#FFAA00, opacity:40
64. ellipse: red light, w:14 h:14, fill:#FF4444, opacity:30
65-66. ellipse: proximity sensor left/right, w:10 h:10, fill:#4488CC
67-68. ellipse: proximity sensor glow left/right, w:18 h:18, fill:#4488CC, opacity:12
69-70. ellipse: infrared sensor left/right on crossbar, w:8 h:8, fill:#880000, opacity:30
71-72. rectangle: emergency button housing left/right, w:15 h:15, fill:#FF4444, opacity:60
73. rectangle: intercom grille, w:20 h:12, fill:#333333
74-75. ellipse: intercom mic/speaker, w:8 h:8, fill:#444444
76. rectangle: barcode scanner window, w:30 h:6, fill:#87CEEB, opacity:40
77-78. rectangle: ticket slot left/right, w:5 h:25, fill:#444444
79. rectangle: information panel, w:35 h:25, fill:#1A1A1A
80-81. rectangle: info panel content lines 1-2, w:25 h:3, fill:#FFFFFF, opacity:20
82-85. ellipse: ceiling lights above 1-4, w:10 h:10, fill:#FFFFCC, opacity:20
86-88. line: floor directional arrows 1-3, strokeColor:#FFAA00, opacity:30
89-90. rectangle: accessibility marker left/right, w:12 h:12, fill:#4488CC, opacity:30
91-93. ellipse: gate sensor array 1-3 (top crossbar), w:6 h:6, fill:#555555
94-95. rectangle: pillar number plate left/right, w:15 h:10, fill:#FFFFFF, opacity:40
```

**Layer E: Accent & Emphasis (15 elements)**
```
96-97. rectangle: accent glow strip left/right pillar, w:3 h:80, fill:theme_accent, opacity:25
98. rectangle: screen border glow, w:56 h:77, fill:theme_accent, opacity:10
99-100. line: floor accent line left/right, w:80, strokeColor:theme_accent, opacity:30
101-102. ellipse: approval indicator glow 1-2, w:40 h:40, fill:#00CC66, opacity:8
103-104. rectangle: barrier tip glow left/right, w:20 h:10, fill:#FF4444, opacity:15
105-107. rectangle: sign letter highlight 1-3, w:8 h:10, fill:#FFFFFF, opacity:15
108-110. ellipse: ambient glow dots 1-3, w:20 h:20, fill:theme_accent, opacity:5
```

**Layer F: Environmental (15 elements)**
```
111-113. line: data flow lines from scanner 1-3, strokeColor:#4488CC, strokeStyle:dashed, opacity:15
114-115. ellipse: reflected light on floor 1-2, w:30 h:8, fill:#FFFFCC, opacity:5
116-118. line: queue rope post lines 1-3 (behind gate), strokeColor:#CCCCCC, opacity:15
119-120. rectangle: queue rope post base 1-2, w:8 h:20, fill:#CCCCCC, opacity:15
121-122. ellipse: person silhouette hint 1-2 (very subtle), w:15 h:40, fill:#999999, opacity:5
123-125. line: power/data cables under floor grate 1-3, strokeColor:#444444, opacity:10
```

### Enrichment Section (Pass 2: 115 elements)

Follow same 4-category pattern as Control Tower enrichment but adapted for gate/security context. Key additions: badge reader textures, glass panel scratches, floor wear patterns, barrier mechanism details, sensor calibration marks, cable management clips, anti-tamper seals, accessibility braille dots, maintenance access panels, hinge mechanisms.

---

## Recipe 3: Smart Factory / Production Hall (260+ elements)

### Structure Section (Pass 1: 145 elements)

**Layer A (12):** Wide shadow, concrete apron, loading dock platform, drain channels, parking bumpers, floor markings.

**Layer B (28):** Main hall rectangle (w:450 h:250), side wing, annex building, sawtooth roof peaks (4 lines), roof valleys (4 lines), skylights (4 rectangles), bay doors (3 tall rectangles), roll-up door tracks, entrance vestibule, loading dock, dock levelers.

**Layer C (30):** Window strip (long rectangle), window dividers (8 lines), bay door panels (6 horizontal lines per door), interior hints through windows (conveyor, robot arm, product line), office section windows (4 rectangles), stairwell external, fire escape, cable trays on exterior, downspouts (3 vertical lines).

**Layer D (40):** Company signage, safety signs (4 diamonds), security cameras (3), lights (6), exhaust vents (4), HVAC units on roof (3), electrical panels (2), fire hydrant, fire alarm boxes (2), access control panels (2), loading bay lights (4), dock bumpers (4), bollards (4), delivery truck outline, emergency exit signs (2), hazmat labels (2), meter boxes (2).

**Layer E (15):** Accent stripes on bay doors, status lights on production line (4), smokestack emission glow, safety barrier stripes, illuminated company logo, operational status board glow.

**Layer F (15):** Forklift tracks on ground, conveyor path hints extending from bay doors, steam/heat shimmer above roof, incoming truck approach lines, pipe run from utility to building, ground-level vegetation, shadow cast on surrounding ground.

### Enrichment Section (Pass 2: 120 elements)

Surface textures (30): wall panel seams, corrugated cladding lines, concrete block patterns, roof sheet overlaps. Micro-details (35): rivets on structural beams, bolt patterns on bay door frames, weld seams, cable clips, pipe flanges. Equipment (30): fire suppression sprinkler heads, conveyor rollers visible through windows, tool racks, compressed air manifolds, emergency shower, eye wash station. Environmental (25): oil stains on loading dock, tire marks, rain gutters, puddles under downspouts, grease marks.

---

## Recipe 4: Digital Infrastructure Hub (250+ elements)

### Structure Section (Pass 1: 140 elements)

**Layer A (10):** Ground shadow, concrete pad, perimeter fence line, security gate, access road.

**Layer B (25):** Main building body (w:300 h:180), shadow side panel, flat roof, raised floor indication, server hall wing, cooling wing, entrance lobby, emergency exit, roof parapet, building corner reveals.

**Layer C (30):** Glass wall section, server racks visible through glass (4 racks), rack LEDs (12 small ellipses), networking cabinets (3), cable overhead trays, raised floor tiles visible, UPS room door, battery room door, fire suppression room, generator room door, loading dock for equipment.

**Layer D (40):** Shield element on facade, 5G antenna on roof, signal waves (6 ellipses), cooling units (4 with fans), entrance card reader, security bollards (3), CCTV cameras (4), perimeter sensors (4), cable conduits (3), power transformer, backup generator outline, satellite dishes (2), fiber optic entry point, weather station, roof access ladder.

**Layer E (15):** Server LED glow effects, antenna signal emanation, shield check glow, entrance security glow, status panel illumination, accent lighting strips.

**Layer F (15):** Power cables from transformer, fiber optic route markers, heat exhaust from cooling, emergency lighting, vehicle charging stations, shadow from antenna array.

### Enrichment Section (Pass 2: 115 elements)

Surface (25): building panel joints, server rack screw patterns, cable tray mesh, floor tile edges. Micro (30): network port indicators, PDU outlets, cable labels, equipment serial plates, fire suppression nozzles. Equipment (35): temperature sensors, humidity gauges, air pressure indicators, cable management rings, hot/cold aisle containment, blanking panels. Environmental (25): heat shimmer over cooling, condensation on cooling pipes, LED status reflections on glass, grounding cable runs.

---

## Recipe 5: Dashboard / Command Center (250+ elements)

### Structure Section (Pass 1: 135 elements)

**Layer A (10):** Ground shadow, raised floor indication, cable floor panels, anti-static mat edges, operator chair bases.

**Layer B (22):** Main room enclosure (wide rectangle), control desk arc (curved arrangement of rectangles), main display wall frame (large rectangle), side display frames (2), ceiling structure, operator stations (3 desk shapes), desk surfaces, equipment rack column (2).

**Layer C (30):** Main screen content (dark rectangle with data viz hints), secondary screens (4 with content), operator monitors (6 small rectangles), keyboard shapes (3), input devices, desk dividers, cable channels under desks, console panels, rack equipment faces, ceiling tile grid.

**Layer D (40):** Screen data visualizations (chart shapes, gauge arcs, status bars — 15 elements), LED status strips, control buttons (8 small rectangles), intercom units (2), emergency phone, wall clocks (2), white boards, documentation holders, coffee machine, cable management arms on desks, KVM switches, power strips, ambient lighting, emergency exit signs.

**Layer E (18):** Screen glow effects (4 large low-opacity rectangles), LED reflections on desk surfaces, status light halos, accent lighting under desks, alert indicators, active alarm glow.

**Layer F (15):** Reflected screen light on floor, operator shadows, air conditioning vents, ceiling light panels, ambient particles in projected light.

### Enrichment Section (Pass 2: 120 elements)

Surface (25): desk edge trim, screen bezel details, rack face panel seams, ceiling tile joints, floor tile edges. Micro (35): USB port indicators, power button LEDs, fan grille patterns, cable tie points, label maker tags. Equipment (35): sticky notes on monitors, phone handset, water bottles, security badges, personal items. Environmental (25): screen reflections on glass walls, dust motes in projector beam, temperature display readings, clock hand positions.

---

## Recipe 6: Warehouse / Logistics Hall (260+ elements)

### Structure Section (Pass 1: 145 elements)

**Layer A (12):** Wide shadow, concrete floor, loading bay aprons (3), forklift lanes (marked lines), pedestrian walkway markings.

**Layer B (28):** Main hall (very wide rectangle), high-bay shelving visible through doors (4 tall thin rectangles per bay × 2 bays), mezzanine level, office section, receiving dock, shipping dock, roof structure (truss lines), roller doors (3).

**Layer C (30):** Shelf unit details (horizontal lines for shelf levels × 8 units), pallet outlines on shelves (12 small rectangles), conveyor belt sections (2 long rectangles), sorting station, packing station tables, label printers, barcode scanners on posts, pick trolleys, staging area markers.

**Layer D (38):** Forklift outline, pallet jack, safety mirrors (3), emergency lighting (4), fire extinguishers (3), rack protection posts (6 small rectangles), floor markings (arrows, zones — 8 elements), dock bumpers (4), leveler plates (2), overhead crane outline, pick-to-light indicators.

**Layer E (15):** Safety zone lighting, active rack LED indicators, conveyor belt active glow, dock light indicators, emergency exit illumination.

**Layer F (15):** Forklift tire marks, dust particles in high-bay, shadow from overhead crane, condensation near cold storage door, truck approach lights.

### Enrichment Section (Pass 2: 120 elements)

Warehouse-specific micro-details: barcode labels on racks, bin location numbers, weight limit markings, pallet wrap textures, cable trunking runs, sprinkler heads, smoke detectors, emergency shower, aisle markers, rack beam clips, shelf pin holes, anti-collapse mesh, temperature zone indicators.

---

## Recipe 7: Generic Industrial Object (250+ elements — fallback)

Use when no specific recipe matches the object_name but the object is industrial/manufacturing in nature.

### Structure Section (Pass 1: 130 elements)

**Layer A (10):** Standard ground contact (shadow, ground plane, concrete pad, edge curb, drain).

**Layer B (25):** Rectangular main body with shadow side, roof/top structure, entrance/access point, base/foundation, side wing or attached structure, structural columns/supports.

**Layer C (25):** Panel divisions on main body (6 lines), window/viewport elements (6), door details (3), structural member intersections (4), interior hints through openings (6).

**Layer D (35):** Safety signage (4 diamonds), lights (4 ellipses with glow), cameras (2), vents (4), control panel (3 elements), utility connections (4), access hardware (3), information plates (3), emergency equipment (4), bollards (4).

**Layer E (15):** Status indicators, accent stripes, glow effects, operational lighting.

**Layer F (15):** Shadow cast, utility runs, environmental particles, contextual vegetation, ground marks.

### Enrichment Section (Pass 2: 120 elements)

Generic industrial enrichment: panel seams (15), rivet patterns (15), pipe fittings (10), cable routes (10), weathering marks (10), equipment accessories (20), surface texture lines (20), shadow details (10), environmental integration (10).

---

## Recipe 8: Generic Tech Object (250+ elements — fallback)

Use when the object is technology/digital in nature but no specific recipe matches.

### Structure Section (Pass 1: 130 elements)

**Layer A (10):** Clean ground contact (shadow, polished floor, cable floor indication, anti-static zones).

**Layer B (22):** Sleek rectangular body with rounded-feel edges (multiple overlapping rectangles), display/screen area (dark rectangle), status panel, top ventilation, side access panel, base unit.

**Layer C (25):** Screen content elements (data viz shapes, progress bars, status text areas), port arrays (rows of small rectangles), ventilation grille lines, cable entry points, internal board hints, mounting brackets.

**Layer D (35):** LED indicators (8 small ellipses), port lights (6), button arrays (4 groups), connectivity indicators, antenna elements, sensor arrays, certification labels, serial number plate, power input indicator, network status display.

**Layer E (18):** Screen glow, LED halo effects, power indicator glow, status beacon, connectivity signal glow, ambient light emanation.

**Layer F (15):** Data flow path lines (dashed), heat exhaust indication, cable connections to other systems, reflected light on floor, electromagnetic field suggestion (very subtle concentric shapes).

### Enrichment Section (Pass 2: 120 elements)

Tech-specific enrichment: circuit board trace patterns (15), heat sink fin details (10), connector pin arrays (15), diagnostic port details (10), firmware version labels (5), warranty seal dots (5), ventilation mesh patterns (15), LED diffuser textures (10), cable management clips (10), thermal paste marks (5), ground strap connections (5), EMI shielding mesh lines (15).

---

## Composition Adaptation Rules

When adapting any recipe for a specific station:

1. **Scale all dimensions** by the station's scale factor (hero=1.5, standard=1.0, supporting=0.8)
2. **Apply theme colors** — replace generic blues/greens with theme accent/primary where appropriate
3. **Apply arc_role color mood:**
   - problem → grey base, red/orange accent elements
   - urgency → warm grey, amber accents
   - evidence → cool tones, blue accents
   - solution → theme primary, bright accents
   - proof → theme primary lighter, green success accents
   - call-to-action → theme accent as primary, high contrast
4. **Adjust detail level** — hero stations get MORE detail elements, supporting stations can reduce micro-details
5. **Always include:** ground shadow + main body + recognition cues + ground contact minimum
6. **Improvise freely** — these recipes are detailed starting points, adapt to the specific object
7. **Structure returns `structure_map`** — named regions with bounding boxes for enrichment pass
8. **Enrichment uses `structure_map`** — places details within known regions, not blind coordinate guessing
