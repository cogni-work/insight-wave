# Element Templates & Pipeline Data

Extracted templates, data tables, and contracts used by the render-big-picture orchestrator skill. Referenced inline by phase number.

---

## Phase 0: Composition Sketch Workflow

> If `sketch_path` is provided (path to .excalidraw file), skip to Phase 1 Step 1.3b.
> If `skip_sketch=true`, skip this phase entirely and proceed to Phase 1 Step 1.1.

### Step 0.1: Load Composition Guide

Call `mcp__excalidraw_sketch__read_me()` — load element format reference and color palettes.

### Step 0.2: Compose Scene Sketch

Using the brief's `story_world` and station positions, construct a 20-50 element Excalidraw JSON array that establishes:
- Background zones (sky, horizon, ground) as large rectangles
- Station silhouettes as labeled shapes at approximate positions
- Key landmarks from the story world description
- Journey path as a simple line/arrow

Target: compositionally correct layout, NOT detail density.

### Step 0.3: Preview Sketch

Call `mcp__excalidraw_sketch__create_view(elements=JSON)`.
If MCP Apps are supported, user sees animated preview and can edit interactively.
If not, the model proceeds with the composed JSON.

Capture the elements JSON as `SKETCH_ELEMENTS` for Phase 1 import.

---

## Font Size & Family Tables

### Font Sizes per Canvas Size

| Element | A0 | A1 | A2 | A3 |
|---------|-----|-----|-----|-----|
| title | 144 | 110 | 76 | 54 |
| subtitle | 56 | 42 | 30 | 22 |
| governing_thought | 36 | 28 | 20 | 14 |
| station_headline | 36 | 28 | 20 | 14 |
| station_body | 22 | 18 | 13 | 9 |
| hero_number | 64 | 48 | 34 | 24 |
| hero_label | 20 | 16 | 11 | 8 |
| station_label | 18 | 14 | 10 | 7 |
| station_number | 32 | 24 | 18 | 14 |
| footer_text | 24 | 20 | 16 | 12 |

### Font Family Mapping

| Font Type | fontFamily Value |
|-----------|-----------------|
| Sans-serif (Inter, Helvetica, Arial) | 2 |
| Monospace | 3 |
| Creative/sketch | 1 (Virgil) |

---

## Phase 2: Title Banner Template

Render the title banner as a solid dark block at the top of the canvas.

```
batch_create_elements:
  - type: rectangle                    # banner background
    x: 0, y: 0
    width: {canvas_width}
    height: {title_banner.height}
    backgroundColor: "#1A1A1A"
    strokeColor: "transparent"
    strokeWidth: 0
    roughness: 0

  - type: text                         # title
    x: {padding_left}
    y: {title_y}
    text: "{title}"
    fontSize: {font_sizes.title}
    fontFamily: {font_family}
    strokeColor: "#FFFFFF"

  - type: text                         # subtitle
    x: {padding_left}
    y: {subtitle_y}
    text: "{subtitle}"
    fontSize: {font_sizes.subtitle}
    fontFamily: {font_family}
    strokeColor: "#FFFFFFCC"

  - type: text                         # governing thought
    x: {padding_left}
    y: {thought_y}
    text: "{governing_thought}"
    fontSize: {font_sizes.governing_thought}
    fontFamily: {font_family}
    strokeColor: "#FFFFFF99"

  - type: line                         # accent border at bottom
    x: 0
    y: {title_banner.height}
    width: {canvas_width}
    height: 0
    strokeColor: "{theme_accent}"
    strokeWidth: {accent_border_height}
```

**Layout rules:**
- Title at y=40
- Subtitle at y = title_y + font_sizes.title + 12
- Governing thought at y = subtitle_y + font_sizes.subtitle + 8
- Left padding: 60px (A0/A1), 40px (A2/A3)
- Accent border height: 24px (A0), 18px (A1), 12px (A2), 8px (A3)

Group all banner elements: `group_elements`.
Save snapshot: "banner-done"

---

## Phase 3: Station Prompt Contract

For EACH station, the orchestrator prepares a prompt containing these fields:

```
STATION_SPEC:
  reading_flow_number: {N}
  object_name: "{landscape_object.object_name}"
  narrative_connection: "{landscape_object.narrative_connection}"
  scale: {landscape_object.scale}
  arc_role: {arc_role}
  position: {x, y} (journey-zone-relative)
  text_placement: {text_placement}
  headline: "{headline}"
  body: "{body}"
  hero_number: "{hero_number}" (if present)
  hero_label: "{hero_label}" (if present)
  station_label: "{station_label}" (if present)

CANVAS_CONTEXT:
  journey_zone: {x, y, width, height}
  roughness: {roughness}
  font_family: {font_family}
  theme_colors: {primary, accent, body_text, muted}
  font_sizes: {headline, body, hero_number, hero_label, station_label, station_number}
  color_mode: {light|dark}
  palette: {canvas_frame_bg, footer_bg, footer_text, text_glow_bg, structure_colors, stroke_default, headline_color, body_text_color}

COLOR_MOOD:
  {arc_role color guidance from brief or defaults}

RECIPE_HINT:
  {Structure section from closest matching recipe in shape-recipes-v3.md}

SKETCH_STATION_ANCHOR: (optional — only if Step 1.3b found an anchor)
  {id, x, y, width, height of the imported sketch element nearest this station}
```

Do NOT pass `shape_composition` to agents — agents use `object_name` + `narrative_connection` + `RECIPE_HINT` to compose illustrations.

---

## Phase 3.5: Enrichment Prompt Contract

For each station that completed Pass 1 successfully:

```
STATION_SPEC:
  reading_flow_number: {N}
  object_name: "{object_name}"
  narrative_connection: "{narrative_connection}"
  scale: {scale}
  arc_role: {arc_role}

STRUCTURE_MAP: {structure_map from Pass 1 response}

STRUCTURE_ELEMENT_COUNT: {elements_created from Pass 1}

CANVAS_CONTEXT:
  roughness: {roughness}
  theme_colors: {primary, accent, body_text, muted}
  color_mode: {light|dark}
  palette: {structure_colors, stroke_default}

RECIPE_ENRICHMENT_HINT:
  {Enrichment section from closest matching recipe in shape-recipes-v3.md}

SKETCH_MODE: (optional — "DENSIFY" if this station used DENSIFY mode, omit otherwise)
```

---

## Phase 4: Footer Template

```
batch_create_elements:
  - type: rectangle                    # footer background
    x: 0, y: {footer.y}
    width: {canvas_width}
    height: {footer.height}
    backgroundColor: "{palette.footer_bg}"
    strokeColor: "transparent"
    roughness: 0

  - type: text                         # left: customer | provider metadata
    x: {padding_left}
    y: {footer.y + 20}
    text: "{footer_left_text}"
    fontSize: {font_sizes.footer_text}
    fontFamily: {font_family}
    strokeColor: "{palette.footer_text}"

  - type: text                         # right: date
    x: {canvas_width - 200}
    y: {footer.y + 20}
    text: "{footer_right_text}"
    fontSize: {font_sizes.footer_text}
    fontFamily: {font_family}
    strokeColor: "{palette.footer_text}"
```

Group footer elements: `group_elements`.
Save snapshot: "integration-done"

---

## Review Zone Computation

Divide canvas width into 4 equal zones:

```
review_width = canvas_width / 4
For review_zone A..D (index 0..3):
  x_start = index * review_width
  x_end = (index + 1) * review_width
```

**Cross-zone alignment coordinates:**
```
horizon_y = journey_zone.y + (journey_zone.height * 0.30)
ground_y = journey_zone.y + (journey_zone.height * 0.85)
```

Map each station to its containing review zone based on x-position.

---

## Rendering Z-Order

Elements are created in this order (Excalidraw renders later = on top):

| Layer | Phase | Element | Created By |
|-------|-------|---------|------------|
| 1 (back) | 1 | Canvas frame (palette.canvas_frame_bg) | Skill Phase 1 |
| 2 | 2 | Title banner (dark bg + text) | Skill Phase 2 |
| 3 | 3 | Journey zone background (tinted) | Skill Phase 3 |
| 4 | 3 | Station structures (120-150 each) | N x station-structure-artist |
| 5 | 3 | Text glow backgrounds (palette.text_glow_bg) | N x station-structure-artist |
| 6 | 3 | Station number text (accent color) | N x station-structure-artist |
| 7 | 3 | Station text (headlines, body, hero) | N x station-structure-artist |
| 8 | 3.5 | Station enrichment details (100-130 each) | N x station-enrichment-artist |
| 9 (front) | 4 | Footer (palette.footer_bg) | Skill Phase 4 |

Stations are the entire visual focus. Inline accent-colored number text indicates reading flow.

---

## Batch Size Strategy

| Default | Fallback 1 | Fallback 2 |
|---------|-----------|-----------|
| 50 elements per batch | 25 elements | 10 elements |

Agents use 50-element batches. If a batch fails, retry at 25, then 10.

---

## Snapshot Checkpoints

| Snapshot Name | After Phase | Purpose |
|--------------|-------------|---------|
| sketch-imported | 1.3b | Imported composition sketch (if applicable) |
| canvas-init | 1.4 | Empty canvas |
| frame-done | 1.3b or 1.5 | Canvas frame (color-mode-aware) |
| banner-done | 2 | Title banner rendered |
| stations-structure-done | 3 | Station structures complete |
| stations-enriched-done | 3.5 | Station enrichment complete |
| integration-done | 4 | Footer |
| review-done | 5 | Review corrections applied |

---

## Error Recovery

| Phase | Scenario | Action |
|-------|----------|--------|
| 1 | Brief not found | Return error JSON |
| 2 | Banner creation fails | Retry once, then create title text only |
| 3 | Station-structure-artist fails | Log error, no enrichment for that station |
| 3 | All structure artists fail | Return error JSON |
| 3.5 | Enrichment artist fails | Station still has structure — continue |
| 5 | Zone reviewer fails | Skip that zone's review, proceed to export |
| 6 | Export fails | Retry once, return error with snapshot name |

---

## Example: Station Prompt (German B2B, Smart Factory, A1)

A concrete example of the station prompt the orchestrator sends to a station-structure-artist:

```
STATION_SPEC:
  reading_flow_number: 3
  object_name: "Smart Factory"
  narrative_connection: "Digitale Fertigungsplattform verbindet Shopfloor-Daten mit Echtzeit-Analytik"
  scale: standard
  arc_role: solution
  position: {x: 2200, y: 800}
  text_placement: below
  headline: "Vernetzte Produktion steigert OEE um 23%"
  body: "Die Integration von IoT-Sensoren in bestehende Maschinenparks ermoeglicht praediktive Wartung und reduziert ungeplante Stillstaende um 34%. Durch Echtzeit-Dashboards auf Shopfloor-Ebene erkennen Schichtleiter Engpaesse, bevor sie die Lieferkette beeintraechtigen. Pilotprojekte bei drei mittelstaendischen Herstellern zeigen: Der ROI liegt unter 14 Monaten, waehrend die Ausschussrate um 18% sinkt."
  hero_number: "23%"
  hero_label: "OEE-Steigerung"
  station_label: "LOESUNGSANSATZ"

CANVAS_CONTEXT:
  journey_zone: {x: 0, y: 544, width: 4961, height: 2474}
  roughness: 1
  font_family: 2
  theme_colors: {primary: "#003366", accent: "#00D084", body_text: "#333333", muted: "#999999"}
  font_sizes: {headline: 28, body: 18, hero_number: 48, hero_label: 16, station_label: 14, station_number: 24}
  color_mode: "light"
  palette: {canvas_frame_bg: "#FFFFFF", footer_bg: "#F5F5F5", footer_text: "#666666", text_glow_bg: "#FFFFFFD9", structure_colors: "#888888, #999999, #BBBBBB, #D0D0D0", stroke_default: "#333333", headline_color: "#003366", body_text_color: "#333333"}

COLOR_MOOD:
  solution — theme primary, bright accents, optimistic palette

RECIPE_HINT:
  {Smart Factory recipe Structure section from shape-recipes-v3.md}
```

Expected response (single-line JSON):
```json
{"ok":true,"station_number":3,"group_id":"grp_abc123","number_id":"number-3","bbox":{"x":2200,"y":1344,"w":450,"h":560},"elements_created":148,"structure_map":{"base":{"x":2190,"y":1830,"w":470,"h":60},"body":{"x":2220,"y":1560,"w":410,"h":270},"top":{"x":2240,"y":1400,"w":380,"h":160},"detail_zone":{"x":2200,"y":1600,"w":120,"h":200},"ground_contact":{"x":2180,"y":1880,"w":490,"h":25}}}
```
