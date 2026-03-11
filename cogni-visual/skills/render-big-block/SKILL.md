---
name: render-big-block
description: >-
  Render a big-block-brief.md (v1.0) into a structured solution architecture diagram
  using Excalidraw MCP — tier-banded grid with solution blocks, path connections,
  SPIs, foundations, and implementation roadmap.

  Use this skill whenever: the user asks to "render big block", "render the big block",
  "draw the solution architecture", "visualize the big block", "create excalidraw from
  big block brief", "Big Block rendern", "Lösungsarchitektur zeichnen", "render my
  big-block-brief", or when any upstream agent or skill produces a big-block-brief.md
  and needs it rendered into an Excalidraw diagram.

  Do NOT confuse with story-to-big-block (which creates the brief from value-modeler
  data) — this skill takes an existing brief and renders it into a visual diagram. If
  the user has a brief file ready, this is the right skill. If they have value-modeler
  output and want a brief first, use story-to-big-block instead.

  Pipeline: Parse brief → canvas setup → title banner → tier bands → solution blocks →
  path connections → SPI/Foundation cards → roadmap timeline → footer → export.
  Dark/light color mode auto-detected. ~150-250 Excalidraw elements.
version: 1.1.0
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
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
---

# Render Big Block — Solution Architecture Diagram (v1.0)

Render a big-block-brief.md (v1.0) into a structured Excalidraw diagram. The Big Block is a **data-driven grid** — tier bands with solution blocks, path connections, SPIs, foundations, and a roadmap timeline. This is fundamentally different from the Big Picture's illustrated landscape: here, precision and clarity matter more than artistic expression.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| brief_path | Yes | Path to big-block-brief.md |
| output_path | No | Path for .excalidraw output (default: `{brief_dir}/big-block.excalidraw`) |

## Output

Return a single-line JSON response:

**Success:**
```json
{"ok":true,"excalidraw_path":"{path}","share_url":"{url}","solutions":{N},"tiers":[{t1},{t2},{t3},{t4}],"connections":{N},"elements":{count},"color_mode":"{mode}"}
```

**Error:**
```json
{"ok":false,"e":"{error}","phase":"{phase_number}"}
```

---

## Pipeline Overview

The pipeline renders the Big Block in 9 sequential phases. Element count targets are specified per section to ensure consistent output.

```
Phase 1: Parse & Setup              → 1 element            Extract all data from brief
Phase 2: Title Banner               → 5 elements            Dark banner + title + subtitle + scoring + accent
Phase 3: Tier Bands                 → 2 per tier (8 total)  Background band + tier label
Phase 4: Solution Blocks            → 6 per block           Rect + name + score/stars + category + portfolio + wave
Phase 5: Path Connections           → 1-2 per connection    Line + optional label
Phase 6: SPI + Foundation Cards     → 3 per SPI, 4 per fdn  Card + name + link(s) [+ maturity for fdns]
Phase 7: Roadmap Timeline           → 3 + 3 + N badges      Wave bands + labels + solution pills
Phase 7.5: Visual Validation        → 0 elements            Screenshot review checkpoint
Phase 8: Footer + Export            → 4 elements            Background + customer + date + methodology
```

**Target element counts** (use these to self-check after each phase):
- 9-solution brief (A1): ~145 elements (1 + 5 + 8 + 54 + 12 + 27 + 15 + 0 + 4 = ~126 minimum)
- 3-solution brief (A2): ~70 elements

Save snapshots at every phase boundary for recovery. Use `snapshot_scene` after each phase — this enables `restore_snapshot` if a later phase fails.

---

## Phase 1: Parse & Setup

### Step 1.1: Read and Parse Brief

1. Read `brief_path` via Read tool
2. Parse YAML frontmatter — extract ALL of:
   - `title`, `subtitle`
   - `customer`, `provider`, `industry`, `language`
   - `canvas_size` (A0/A1/A2/A3), `canvas_pixels` (width x height)
   - `theme`, `theme_path`
   - `scoring` (formula, solutions_ranked, avg_ranking, portfolio_gaps)
   - `generated` date
3. Parse markdown body — extract into structured data:
   - **Tiers**: tier_id, tier_label, tier_label_de, solution_count
   - **Blocks**: block_id, name, name_short, br_score, br_stars, category, portfolio_ref, portfolio_status, foundation_factor, paths[], wave, spis[], foundations[]
   - **SPIs**: spi_id, name, name_de, linked_solutions[], description
   - **Foundations**: foundation_id, name, name_de, maturity_required, dependent_solutions[], description
   - **Connections**: path_id, path_name, blocks[], color
   - **Waves**: wave number, label, label_de, timeline, blocks[], description
4. Validate: every block_id in connections exists, every SPI/foundation link resolves

### Step 1.2: Load Layout Spec

Read `$CLAUDE_PLUGIN_ROOT/libraries/big-block-layouts.md`. Look up:
- Canvas dimensions for the brief's `canvas_size`
- Zone specifications (title banner, tier zone, SPI/foundation zone, roadmap zone, footer)
- Block dimensions (width, height, corner radius, margin)
- Text sizing table
- Color specifications for light/dark mode

### Step 1.3: Detect Color Mode

If `theme_path` exists, read it and extract background color. Apply luminance formula:

```
luminance = 0.299*R + 0.587*G + 0.114*B
if luminance < 128 → "dark" mode
else → "light" mode
```

If no theme found, default to light mode.

Build a color palette object from the layouts spec's color tables for the detected mode. This palette is used by all subsequent phases.

### Step 1.4: Compute Tier Band Heights

Distribute tier zone height proportionally to solution count per tier, respecting minimum heights from the layouts spec:
- Tier 1: min 30%
- Tier 2: min 25%
- Tier 3: min 22%
- Tier 4: min 15%

If a tier has 0 solutions, collapse to 30px label-only row.

Compute exact y-position and height for each tier band within the Tier Zone.

### Step 1.5: Compute Block Grid Positions

For each tier, lay out blocks in a grid:
- Blocks per row from layouts spec (e.g., A1 = 5 max)
- Center blocks horizontally within the tier band
- Vertical center within the band
- Apply margin between blocks

Record the (x, y, width, height) of every block — this is needed for connection routing in Phase 5.

### Step 1.6: Initialize Canvas

**IMPORTANT:** The canvas at localhost:3000 is shared. Always start with `clear_canvas` to ensure a clean slate — never assume the canvas is empty.

1. Run via Bash: `mkdir -p "{output_dir}"`
2. Call `clear_canvas` — this is the FIRST Excalidraw MCP call, always
3. Call `read_diagram_guide` — load Excalidraw best practices
4. Create canvas frame rectangle:
   ```
   type: rectangle
   x: 0, y: 0
   width: {canvas_width}, height: {canvas_height}
   backgroundColor: "#F7F7F7" (light) or "#0D0D0D" (dark)
   strokeColor: "transparent"
   strokeWidth: 0
   roughness: 0
   ```
5. Call `snapshot_scene` name="phase1-setup"

---

## Phase 2: Title Banner

The title banner is a dark bar across the top with white text, followed by an accent-colored separator.

### Elements to create:

1. **Banner background** — rectangle, full width, solid `#1A1A1A`
2. **Title text** — brief's `title` field, font size from layouts spec
3. **Subtitle text** — brief's `subtitle` field, smaller font
4. **Scoring line** — "{N} Lösungen | Ø BR {avg} | {gaps} Portfolio-Lücken" (or English equivalent)
5. **Accent border** — thin rectangle below banner, full width, theme accent color

Use `batch_create_elements` with all 5 elements. Group them as "title-banner".

Save snapshot: "phase2-banner"

---

## Phase 3: Tier Bands

Create the horizontal tier bands within the Tier Zone. Each band gets a tinted background and a tier label.

### For each tier (1-4):

1. **Band background** — rectangle at computed (x, y, width, height), tinted with tier color at opacity from layouts spec
2. **Tier label** — text at left margin, vertically centered in band. Include tier name + BR range.
   - German: "Stufe 1: Geschäftskritisch (BR >= 4.0)"
   - English: "Tier 1: Mission Critical (BR >= 4.0)"

Use `batch_create_elements` for all tier bands + labels (8-16 elements).

Group each tier's elements (band bg + label) as "tier-{N}".

Save snapshot: "phase3-tiers"

---

## Phase 4: Solution Blocks

This is the core visual content. Each solution block is a rounded rectangle with structured internal text.

### For each block:

Create these elements at the block's computed grid position:

1. **Block background** — rounded rectangle (cornerRadius from spec)
   - Stroke color: tier color at 60% (light) or 80% (dark)
   - If `portfolio_status: gap`: stroke color = red (#E53E3E / #FC8181)
   - Fill: #FFFFFF (light) or #1A1A1A (dark)

2. **Solution name** — bold text, `name_short` value, top of block

3. **BR score + stars** — "BR: {score} {stars}"
   - Stars: filled ★ in amber (#F6AD55), empty ☆ in gray
   - Use `br_stars` for filled count, pad to 5 total

4. **Category tag** — "Category: {category}" in muted text

5. **Portfolio reference** — either:
   - "→ {portfolio_ref}" in green (#38A169 / #68D391) if mapped
   - "PORTFOLIO GAP" in red (#E53E3E / #FC8181) if gap

6. **Wave + paths** — "Wave {N} | {count} paths" in smallest font, bottom of block

Use `batch_create_elements` in batches of up to 50 elements (roughly 7-8 blocks per batch at ~7 elements each).

Group each block's elements as "block-{block_id}".

Save snapshot: "phase4-blocks"

---

## Phase 5: Path Connections

Draw dashed bezier lines between blocks that share a TIPS path. Connections are rendered BEHIND blocks (lower z-order — they were created before blocks, but since we created blocks after tier bands, we need to ensure connections sit between tier bands and blocks visually).

### Connection routing strategy:

1. For each connection, identify the block positions of all linked blocks
2. For 2-block connections: single curved line between block centers
3. For 3+ block connections: hub-and-spoke from the highest-tier block to each other block
4. Route lines to exit from block edges (not centers) — prefer bottom/top edges for cross-tier connections, left/right for same-tier connections
5. Use Excalidraw arrow elements with `startArrowhead: null, endArrowhead: null` for bidirectional lines

### Connection styling:
- `strokeStyle: "dashed"`
- `strokeWidth: 2`
- `strokeColor`: tier color of highest-tier block in connection
- `opacity`: 40 (light) or 60 (dark)

### Connection priority (if > 8 connections):
1. All Tier 1 connections (always shown)
2. Cross-tier connections
3. Drop intra-tier lower-tier connections

### Optional: path label at midpoint
- Small text (8px A1) with path_name
- Only add labels if there's visual space (≤ 6 connections)

Use `batch_create_elements` for all connections.

Save snapshot: "phase5-connections"

---

## Phase 6: SPI + Foundation Cards

### SPIs (left half of SPI/Foundation Zone)

For each SPI, create a card:
1. **Card background** — rounded rectangle, red-tinted (#FFF5F5 / #2D1B1B)
2. **SPI name** — bold text, red tone (#C53030 / #FC8181)
3. **Linked solutions** — "→ {solution names}" in muted text

Layout: cards arranged in a 2-column grid within the left half of the zone.

### Foundations (right half of SPI/Foundation Zone)

For each Foundation, create a card:
1. **Card background** — rounded rectangle, blue-tinted (#EBF8FF / #1A2332)
2. **Foundation name** — bold text, blue tone (#2B6CB0 / #63B3ED)
3. **Maturity level** — "Maturity: {level}" in muted text
4. **Dependency count** — "→ {N} solutions depend" in muted text

Layout: cards arranged in a 2-column grid within the right half of the zone.

### Section labels

Add "Process Changes (SPIs)" / "Prozessanpassungen" label above SPI cards.
Add "Foundation Requirements" / "Voraussetzungen" label above Foundation cards.

Use `batch_create_elements` for all SPI + Foundation elements.

Group SPIs as "spi-section", Foundations as "foundation-section".

Save snapshot: "phase6-cards"

---

## Phase 7: Roadmap Timeline

The roadmap is a horizontal timeline at the bottom showing implementation waves.

### Elements:

1. **Timeline background** — full-width rectangle in the Roadmap Zone
2. **Wave bands** — 3 proportional segments (Wave 1: narrowest for 0-6mo, Wave 2: medium for 6-18mo, Wave 3: widest for 18-36mo)
   - Proportional widths: Wave 1 = 6/36, Wave 2 = 12/36, Wave 3 = 18/36
3. **Wave labels** — bold text: "Wave 1: Quick Wins" (or German equivalent)
4. **Timeline labels** — muted text: "0-6 Monate", "6-18 Monate", "18-36 Monate"
5. **Solution badges** — small pill/text for each solution in the wave, using `name_short`

Use `batch_create_elements` for all roadmap elements.

Group as "roadmap".

Save snapshot: "phase7-roadmap"

---

## Phase 7.5: Visual Validation

After rendering all content (Phases 2-7), take a screenshot to verify the diagram looks correct before exporting.

1. Call `get_canvas_screenshot` — this returns a visual snapshot of the current canvas
2. Review the screenshot for obvious issues:
   - Are all tier bands visible and properly stacked (Tier 1 top → Tier 4 bottom)?
   - Are solution blocks positioned within their tier bands (not overlapping band borders)?
   - Are connection lines visible between blocks?
   - Is the title banner at the top, footer area at the bottom?
   - Do SPI/Foundation cards appear below the tier zone?
3. If issues are detected, use `update_element` or `delete_element` to fix before exporting
4. Call `snapshot_scene` name="phase7.5-validated"

This phase adds no elements — it's a quality gate. Skip only if `get_canvas_screenshot` is unavailable.

---

## Phase 8: Footer + Export

### Step 8.1: Footer

Create footer elements:
1. **Footer background** — subtle rectangle
2. **Customer/Provider** — left-aligned: "{customer} | {provider}"
3. **Date** — center-aligned: "{generated}"
4. **Methodology** — right-aligned: "TIPS Business Relevance — WO2018046399A1"

Use `batch_create_elements`. Group as "footer".

Save snapshot: "phase8-footer"

### Step 8.2: Export .excalidraw File

**Primary method** — use `export_scene`:
```
export_scene:
  filePath: "{output_path}"
```

**Fallback** — if `export_scene` fails or is unavailable, use `describe_scene` to get the element data, then write the .excalidraw JSON file directly via Write tool. The .excalidraw format is:
```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "render-big-block",
  "elements": [... all elements from describe_scene ...],
  "appState": {"viewBackgroundColor": "{palette.canvas_frame_bg}"}
}
```

### Step 8.3: Element Count Verification

Call `describe_scene` and count elements. Compare against the target counts from the Pipeline Overview. Log the final count in the result JSON.

### Step 8.4: Generate Shareable URL

Call `export_to_excalidraw_url`. If unavailable, set share_url to "n/a" in the result.

### Step 8.5: Return Result JSON

```json
{"ok":true,"excalidraw_path":"{output_path}","share_url":"{url}","solutions":{N},"tiers":[{t1},{t2},{t3},{t4}],"connections":{conn_count},"elements":{total},"color_mode":"{mode}"}
```

---

## Constraints

- **Render via Excalidraw MCP tools** — always use `batch_create_elements`, `group_elements`, `snapshot_scene`, `export_scene` etc. Do NOT write .excalidraw JSON files manually unless MCP export fails (see Step 8.2 fallback).
- **Preserve brief content verbatim** (solution names, scores, path names) — the data IS the content, altering it breaks integrity.
- **Follow z-order** from big-block-layouts.md: canvas frame → banner → tier bands → tier labels → connections → blocks → SPI cards → foundation cards → roadmap → footer. Create elements in this order so earlier elements are behind later ones.
- **Use `roughness: 0`** for ALL elements — the Big Block is a precise diagram, not a hand-drawn illustration.
- **Use `fontFamily: 2`** (Helvetica/sans-serif) for all text — clean, professional typography.
- **Group elements** after each phase using `group_elements` — groups make the diagram editable (users can select and move entire blocks/sections). Group IDs: "title-banner", "tier-{N}", "block-{block_id}", "spi-section", "foundation-section", "roadmap", "footer".
- **Batch create** elements (up to 50 per call) for efficiency.
- **Save snapshots** at every phase boundary via `snapshot_scene` — enables `restore_snapshot` recovery without re-rendering completed phases.
- **Support both German and English** labels based on brief's `language` field.
- **Return JSON-only response** (no prose) — the calling agent parses output programmatically.
