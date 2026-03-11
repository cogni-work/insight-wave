---
name: render-big-picture
description: >-
  Render a big-picture-brief.md (v3.0) into a richly illustrated Excalidraw scene — 1100-1500
  elements across 5-6 stations, each a detailed landscape object built from Excalidraw primitives.

  Use this skill whenever: the user asks to "render big picture", "render the big picture",
  "draw the big picture", "illustrate the brief", "create excalidraw from brief", "render the
  journey map", "Big Picture rendern", "Excalidraw erstellen", "Journey Map zeichnen",
  "visualize the brief", "turn this brief into a visual", "make the big picture scene",
  "render my big-picture-brief", or when any upstream agent or skill produces a
  big-picture-brief.md and needs it rendered into an illustrated Excalidraw canvas.

  Do NOT confuse with story-to-big-picture (which creates the brief from a narrative) — this
  skill takes an existing brief and renders it into a visual scene. If the user has a brief
  file ready, this is the right skill. If they have a narrative and want a brief first, use
  story-to-big-picture instead.

  Pipeline: N station-structure-artists (Pass 1) + N station-enrichment-artists (Pass 2) +
  4 zone-reviewers. Dark/light color mode auto-detected. Optional composition sketch via
  Excalidraw MCP.
version: 4.2.0
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Agent
  - TodoWrite
  - mcp__excalidraw__clear_canvas
  - mcp__excalidraw__create_element
  - mcp__excalidraw__batch_create_elements
  - mcp__excalidraw__group_elements
  - mcp__excalidraw__describe_scene
  - mcp__excalidraw__get_canvas_screenshot
  - mcp__excalidraw__snapshot_scene
  - mcp__excalidraw__restore_snapshot
  - mcp__excalidraw__export_scene
  - mcp__excalidraw__export_to_excalidraw_url
  - mcp__excalidraw__read_diagram_guide
  - mcp__excalidraw__query_elements
  - mcp__excalidraw__update_element
  - mcp__excalidraw__delete_element
  - mcp__excalidraw__get_element
  - mcp__excalidraw__import_scene
  - mcp__excalidraw_sketch__read_me
  - mcp__excalidraw_sketch__create_view
---

# Render Big Picture — Orchestrator Skill (v4.2)

Render a big-picture-brief.md (v3.0) into a richly illustrated Excalidraw scene. You orchestrate parallel artist agents that build stations as dense landscape objects, then zone-based reviewers that check quality. The result is a single-canvas visual journey map with 1100-1500 elements.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| brief_path | Yes | Path to big-picture-brief.md |
| output_path | No | Path for .excalidraw output (default: `{brief_dir}/big-picture.excalidraw`) |
| sketch_path | No | Path to pre-made .excalidraw sketch (skips Phase 0, imports directly) |
| skip_sketch | No | Set true to skip Phase 0 sketch generation (default: false) |

## Output

Return a single-line JSON response:

**Success:**
```json
{"ok":true,"excalidraw_path":"{path}","share_url":"{url}","stations":{N},"total_elements":{count},"color_mode":"{mode}","review_score":{S},"iterations":{I}}
```

**Error:**
```json
{"ok":false,"e":"{error}","phase":"{phase_number}"}
```

---

## Pipeline Overview

The pipeline builds a big picture in 6 phases. Each phase has a clear purpose — understand why each matters so you can recover intelligently if something goes wrong.

```
Phase 0: (optional) Sketch             → 20-50 elements    Establishes spatial composition
Phase 1: Parse & Setup                 → 1 frame element   Extracts all data needed by agents
Phase 2: Title Banner                  → ~6 elements        First thing viewers see — sets tone
Phase 3: Stations P1 (N parallel)      → 130-160 per stn   Object silhouettes + structure
Phase 3.5: Stations P2 (N parallel)    → 100-130 per stn   Surface texture + micro-detail
Phase 4: Integration (footer)          → ~5 elements        Metadata closure
Phase 5: Review (4 parallel)           → up to 120 fixes    Quality enforcement
Phase 6: Export                                              Deliverable generation

For 5 stations: 5+5+4 = 14 agents, ~1200 elements
For 6 stations: 6+6+4 = 16 agents, ~1450 elements
```

Create 6 TodoWrite entries at startup (Phases 1-6). Mark each in_progress before starting, completed after finishing.

---

## Phase 0: Composition Sketch (Optional)

> **Why:** A 20-50 element sketch establishes spatial relationships between stations before investing in detail. It's cheap insurance against layout problems that would be expensive to fix after 1000+ elements exist.

**Decision tree:**
- `sketch_path` provided → skip to Phase 1 Step 1.3b (import it there)
- `skip_sketch=true` → skip to Phase 1 Step 1.1
- Otherwise → read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/element-templates.md`, section "Phase 0: Composition Sketch Workflow". Follow Steps 0.1-0.3.

Capture the elements JSON as `SKETCH_ELEMENTS` for Phase 1 import.

---

## Phase 1: Parse & Setup

> **Why:** This phase converts the brief's text into structured data that all downstream agents need. Every agent receives the same palette, font sizes, and zone boundaries — consistency depends on getting this right.

### Step 1.1: Read and Parse Brief

1. Read `brief_path` via Read tool
2. Parse YAML frontmatter — extract ALL of:
   - `title`, `subtitle`, `governing_thought`
   - `story_world` (name, type, description)
   - `visual_style` and `roughness`
   - `canvas_size` and `canvas_pixels` (width x height)
   - `theme_path`, `customer`, `provider`, `language`
   - `generated` date
3. Extract `canvas_layout` (title_banner, journey_zone, footer, journey_path)
4. Extract ALL station specifications into a list
5. Read `theme_path` via Read tool. Extract colors:
   - `primary`, `accent`, `background`, `body_text`, `muted`
   - Fall back to defaults if theme not found: primary=#003366, accent=#00D084, body_text=#333333, muted=#999999
6. **Detect color mode and build palette:** Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/color-palette.md`. Apply the color mode detection algorithm and build the full palette from the Master Palette table.

### Step 1.2: Compute Rendering Parameters

Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/element-templates.md`, section "Font Size & Family Tables". Look up font sizes for the brief's `canvas_size` (A0/A1/A2/A3) and resolve font family mapping.

### Step 1.3: Compute Zone Boundaries

Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/element-templates.md`, section "Review Zone Computation". Apply the formulas to compute review zone boundaries and cross-zone alignment coordinates.

Map each station to its containing review zone based on x-position.

### Step 1.3b: Import Composition Sketch

> Skip this step if Phase 0 was skipped AND no `sketch_path` was provided.

1. Run via Bash: `mkdir -p "{output_dir}"` where output_dir = dirname(output_path or brief_dir)
2. Call `clear_canvas` (clean slate)
3. Call `read_diagram_guide` — load Excalidraw best practices
4. **IF** `sketch_path` provided:
   - Call `import_scene(filePath=sketch_path, mode="replace")`
5. **ELSE IF** Phase 0 produced `SKETCH_ELEMENTS` JSON:
   - Call `import_scene(data=SKETCH_ELEMENTS, mode="replace")`
6. Call `describe_scene()` — extract all imported element IDs, types, and bounding boxes
7. Build mapping:
   - `SKETCH_ELEMENT_MAP`: [{id, type, x, y, width, height}] — all imported elements
   - `SKETCH_OBSTACLES`: elements NOT near any station position (scene background elements)
   - `SKETCH_STATION_ANCHORS`: elements near station positions (within 300px of station center)
   - For each station, find the NEAREST sketch anchor element → becomes singular `SKETCH_STATION_ANCHOR` in Phase 3 prompt
8. Call `snapshot_scene` name="sketch-imported"
9. Create canvas frame rectangle ON TOP of imported sketch
10. Call `snapshot_scene` name="frame-done"

> After Step 1.3b, skip Steps 1.4 and 1.5 (canvas already initialized and framed).

### Step 1.4: Initialize Canvas

> Skip this step if Step 1.3b was executed.

1. Run via Bash: `mkdir -p "{output_dir}"` where output_dir = dirname(output_path or brief_dir)
2. Call `clear_canvas`
3. Call `read_diagram_guide` — load Excalidraw best practices
4. Call `snapshot_scene` name="canvas-init"

### Step 1.5: Create Canvas Frame

> Skip this step if Step 1.3b was executed (frame already created).

```
create_element:
  type: rectangle
  x: 0, y: 0
  width: {canvas_width}, height: {canvas_height}
  backgroundColor: "{palette.canvas_frame_bg}"
  strokeColor: "transparent"
  strokeWidth: 0
  roughness: 0
```

Save snapshot: "frame-done"

---

## Phase 2: Title Banner

> **Why:** The title banner is the first thing a viewer reads. It establishes the narrative scope and sets visual tone. A strong banner with clear title, subtitle, and governing thought gives the viewer a mental frame for interpreting the stations below.

Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/element-templates.md`, section "Phase 2: Title Banner Template". Apply the template with parsed brief values and computed font sizes.

Group all banner elements. Save snapshot: "banner-done"

---

## Phase 3: Station Rendering Pass 1 (N Parallel Structure Artists)

> **Why:** Stations are the entire visual payload. Each station is a landscape object (factory, tower, dashboard, etc.) built from 130-160 Excalidraw primitives that create a recognizable silhouette with internal structure. This pass establishes what each object IS — the enrichment pass adds what it FEELS like.

**Load references:**
1. Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/illustration-techniques.md`
2. Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/shape-recipes-v3.md` — find the closest recipe Structure section per station

### Step 3.1: Create Journey Zone Background

```
create_element:
  type: rectangle
  x: {journey_zone.x}
  y: {journey_zone.y}
  width: {journey_zone.width}
  height: {journey_zone.height}
  backgroundColor: "{theme_background_tint}"
  strokeColor: "transparent"
  strokeWidth: 0
  roughness: 0
  opacity: 30
```

### Step 3.2: Prepare Station Prompts

For each station, find the CLOSEST matching recipe from shape-recipes-v3.md based on `object_name`. Include that recipe's **Structure section** in the prompt as `RECIPE_HINT`.

Recipe matching priority:
1. Exact name match (e.g., "Control Tower" → Control Tower recipe)
2. Category match (e.g., "Smart Warehouse" → Warehouse / Logistics Hall recipe)
3. Domain match (e.g., industrial → Generic Industrial Object)
4. Fallback: Generic Tech Object

For EACH station, prepare a prompt following the contract in `element-templates.md`, section "Phase 3: Station Prompt Contract".

### Step 3.3: Launch All Station-Structure-Artists in Parallel

Launch ALL station-structure-artist agents in a **SINGLE message** with multiple Agent tool calls — launching them one at a time would multiply wall-clock time by N, turning a 2-minute parallel run into a 12-minute sequential crawl.

```
For each station (1..N):
  Agent tool:
    subagent_type: "cogni-visual:station-structure-artist"
    prompt: {station prompt from Step 3.2}
```

Wait for ALL agents to complete. Collect from each:
- `number_id` — station number text element for review
- `group_id` — needed for review
- `bbox` — bounding box for overlap checking
- `station_number` — to match responses to stations
- `elements_created` — for tracking
- `structure_map` — needed for Phase 3.5 enrichment pass

**Error handling:** If any station agent fails, log the error and continue with successful stations. Missing stations won't get enrichment but the scene is still usable.

Save snapshot: "stations-structure-done"

---

## Phase 3.5: Station Rendering Pass 2 (N Parallel Enrichment Artists)

> **Why:** Structure creates the silhouette; enrichment creates the texture. Rivets, seam lines, weathering marks, cable runs — these 100-130 elements per station are what make the difference between "diagram" and "illustration." The enrichment artists use the `structure_map` from Pass 1 to place details precisely within known regions.

### Step 3.5.1: Prepare Enrichment Prompts

For each station that completed Pass 1 successfully, prepare a prompt following the contract in `element-templates.md`, section "Phase 3.5: Enrichment Prompt Contract".

### Step 3.5.2: Launch All Station-Enrichment-Artists in Parallel

Launch ALL enrichment agents in a **SINGLE message** — same reasoning as Phase 3.

```
For each station (1..N) that has a structure_map:
  Agent tool:
    subagent_type: "cogni-visual:station-enrichment-artist"
    prompt: {enrichment prompt from Step 3.5.1}
```

Wait for ALL agents. Collect from each:
- `elements_added` count
- `total_elements` (structure + enrichment)

Track total station elements: sum of all total_elements across stations.

**Error handling:** If enrichment fails for a station, the structure is still intact — a well-structured station without enrichment looks better than no station at all.

Save snapshot: "stations-enriched-done"

---

## Phase 4: Integration

> **Why:** The footer closes the canvas with metadata (customer, provider, date). It's a small phase but important for professional completeness — a big picture without attribution looks unfinished.

### Step 4.1: Footer

Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/element-templates.md`, section "Phase 4: Footer Template". Apply the template with brief metadata and computed font sizes.

Group footer elements. Save snapshot: "integration-done"

---

## Phase 5: Zone-Based Review (4 Parallel Zone Reviewers)

> **Why:** After 14+ agents have worked independently, quality varies across the canvas. Zone reviewers catch contrast problems, sparse stations, missing elements, and dark mode violations. Dividing the canvas into 4 zones lets reviewers focus deeply on their section while running in parallel.

**Load reference:** Read `$CLAUDE_PLUGIN_ROOT/skills/render-big-picture/references/review-checklist.md`

### Step 5.1: Compute Review Zone Data

For each review zone (A, B, C, D):
- List stations in this zone (based on station x-position vs review zone boundaries)
- Collect station element counts, bboxes, group_ids

### Step 5.2: First Review Pass (4 Parallel Zone Reviewers)

Launch 4 zone-reviewer agents in a **SINGLE message** — the 4 zones are spatially independent.

```
For each review_zone (A, B, C, D):
  Agent tool:
    subagent_type: "cogni-visual:zone-reviewer"
    prompt:
      REVIEW_ZONE: {zone letter, x_start, x_end, y_start: 0, y_end: canvas_height}
      BRIEF_SUMMARY: {title, station count, station names, story world, canvas size}
      STATIONS_IN_ZONE: {station data for this zone}
      COLOR_MODE: {color_mode}
      CANVAS_FRAME_BG: {palette.canvas_frame_bg}
      PALETTE: {palette}
      REVIEW_PASS: 1
      MAX_PASSES: 2
      DENSIFY_STATIONS: (optional — list of station numbers that used DENSIFY mode)
```

Wait for ALL 4 reviewers. Collect from each:
- `score` (0-9)
- `gate` scores
- `corrections_made` count

### Step 5.3: Second Review Pass (if needed)

Compute overall score = min(zone_scores). If any zone scores below 6:

Launch zone-reviewer agents ONLY for failing zones (score < 6) with `REVIEW_PASS: 2`.

If all zones >= 6, skip second pass.

### Step 5.4: Record Review Results

Compute final aggregated score and store for export JSON.

Save snapshot: "review-done"

---

## Phase 6: Export

> **Why:** The export phase produces the deliverable. The .excalidraw file is the primary artifact; the shareable URL is a convenience for stakeholders who don't have Excalidraw installed.

### Step 6.1: Final Validation

Call `describe_scene` to verify:
- Total element count (target: 1100+ for 5 stations, 1400+ for 6 stations)
- Station groups exist (N groups for N stations)
- Station number text elements exist (N elements)
- Title banner group exists
- Footer group exists

### Step 6.2: Export .excalidraw File

```
export_scene:
  filePath: "{output_path}"
```

### Step 6.3: Generate Shareable URL

```
export_to_excalidraw_url
```

**Note:** If the Excalidraw browser frontend is not available, the .excalidraw file is still exported. Skip URL generation.

### Step 6.4: Return Result JSON

```json
{"ok":true,"excalidraw_path":"{output_path}","share_url":"{url}","stations":{N},"total_elements":{count},"station_elements":{station_total},"color_mode":"{color_mode}","review_score":{score},"iterations":{review_passes}}
```

---

## Reference Index

These files contain the data tables and contracts that the phases above reference. Read each only at the phase that needs it — not all at once.

| Reference | Read at | Contains |
|-----------|---------|----------|
| `references/color-palette.md` | Phase 1 | Color mode detection, master palette, grey-scale inversion, dark mode floor |
| `references/element-templates.md` | Phase 1-4 | Font size tables, banner/footer templates, station prompt contracts, z-order, batch strategy, snapshots, error recovery |
| `references/illustration-techniques.md` | Phase 3 | Shape stacking, detail catalog, composition workflow, high-density planning |
| `references/shape-recipes-v3.md` | Phase 3/3.5 | Per-object-type element-by-element recipes (structure + enrichment) |
| `references/review-checklist.md` | Phase 5 | 9-gate quality checklist, zone methodology, scoring, correction priority |

---

## Constraints

- Preserve brief content verbatim (headlines, body text, numbers) — altering source content breaks the narrative's data integrity.
- Create ALL stations at their specified positions — missing stations leave visible gaps in the reading flow.
- Maintain consistent roughness across ALL elements — mixed roughness produces jarring style clash between stations.
- Save snapshots at each phase checkpoint — the pipeline runs 14-16 parallel agents; any failure must be recoverable without re-running successful agents.
- Launch all agents in ONE message per phase — sequential launches multiply wall-clock time by the agent count.
- Collect structure_maps from station-structure-artists — the enrichment pass needs precise bounding boxes to place details within known regions.
- Pass color_mode and palette to ALL artist and reviewer agents — agents without palette data will use default colors that clash with the chosen color mode.
- Do not invent stations or reorder them — the reading flow numbers encode a deliberate narrative sequence.
- Do not pass shape_composition or landscape_composition to agents — v3.0 briefs are clean; agents use object_name + narrative_connection + recipe hints.
- Return JSON-only response (no prose) — the calling agent parses the output programmatically.
