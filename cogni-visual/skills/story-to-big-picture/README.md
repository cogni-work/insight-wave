# Story-to-Big-Picture Skill

## Overview

Transform any narrative with a story arc into a visual journey map (big picture) brief. The skill analyzes a narrative's argument structure, brainstorms a Story World, decomposes the story into landscape objects along a scene, and specifies narrative connections for each station describing the visual intent. Rendering agents compose illustrations from these descriptions using shape-recipes-v3.md. Works with sales pitches, research reports, strategy documents, project updates, or thought leadership pieces.

**Core philosophy:** A big picture is NOT cards placed on a colored background. It is a **cohesive illustrated scene** where each station IS an object in the landscape — a broken CNC machine, a sensor-equipped robot arm, a control tower — guided by inline station numbers and bold headlines. The landscape isn't decoration; it's the story itself, made spatial.

## Key Capabilities

- **Two-Layer Intelligence** — Story arc analysis and scene architecture working together
- **Story World Brainstorming** — Three-phase creative process: content world analysis, concept generation (literal + lateral), and scoring. Replaces fixed metaphor selection with open-ended scene ideation.
- **Interactive Story World Proposal** — Presents top 2-3 Story World concepts with reasoning for user selection (or auto-selects in agent mode)
- **Station-as-Landscape-Object** — 4-8 stations decomposed from narrative sections, each becoming a physical object in the scene described via `object_name` + `narrative_connection`
- **Clean Brief Format (v3.0)** — Briefs describe WHAT to show (object names + narrative connections), not HOW to draw it. Rendering agents own visual interpretation via shape-recipes-v3.md.
- **Station-First Rendering** — Brief rendered by big-picture agent (master) orchestrating station-structure-artist, station-enrichment-artist, and zone-reviewer agents via Excalidraw MCP
- **Canvas Layout** — Precise station coordinates on DIN A0-A3 canvases at 150 DPI with zone-based spatial allocation
- **Four-Layer Validation** — Schema compliance, message quality, visual coherence, and content integrity

## When to Use

- Transforming any prose narrative into a visual journey map (big picture)
- Creating single-canvas visual summaries of strategy documents, project stories, or sales narratives
- When the audience needs to see the entire story at a glance
- When a spatial/landscape scene communicates better than sequential slides
- Downstream of cogni-narrative and cogni-copywriting in the compose-polish-visualize pipeline

**Not for:**
- Creating slide decks (use story-to-slides skill instead)
- Rendering briefs into .excalidraw files (use big-picture agent)
- Creating presentations from scratch without a source narrative
- Editing existing .excalidraw designs directly

## Quick Start

```bash
# Single narrative file with auto Story World
/story-to-big-picture source_path=/path/to/narrative.md language=en

# Project directory with Story World hint
/story-to-big-picture source_path=/path/to/project/ metaphor=cityscape language=de

# Custom canvas size and visual style
/story-to-big-picture source_path=/path/to/narrative.md canvas_size=A0 visual_style=sketch

# Non-interactive mode (agent delegation)
/story-to-big-picture source_path=/path/to/narrative.md interactive=false
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `source_path` | string | auto-discovered | Path to narrative file(s) or project directory. When omitted and `interactive=true`, auto-discovers nearby narratives. |
| `theme` | string | `smarter-service` | Theme ID from `/cogni-workplace/themes/{theme}/theme.md` |
| `language` | string | `en` | Language code (en/de) |
| `title` | string | auto-detected | Big picture title (extracted from narrative if not provided) |
| `subtitle` | string | auto-detected | Big picture subtitle |
| `customer_name` | string | from metadata | Customer/audience organization name |
| `provider_name` | string | from metadata | Presenter/author organization name |
| `output_path` | string | `{source_dir}/cogni-visual/big-picture-brief.md` | Where to write the brief |
| `max_stations` | int | `6` | Maximum station count (4-8, auto-determined from narrative) |
| `canvas_size` | string | `A1` | DIN format: `A0`, `A1`, `A2`, `A3` (always landscape) |
| `metaphor` | string | `auto` | Story World hint. Accepts classic names (`mountain`, `river`, `road`, `archipelago`, `garden`, `cityscape`) or free-text concept. Maps to a brainstorming starting point. When `auto`, brainstorms from narrative content. |
| `visual_style` | string | `auto` | Visual style: `auto` (detected from context), `flat-illustration`, `sketch`. Maps to Excalidraw roughness (0 or 1). |
| `arc_type` | string | `auto` | Story arc hint: `auto`, `why-change`, `problem-solution`, `journey`, `argument`, `report` |
| `arc_id` | string | from frontmatter | Narrative arc ID from cogni-narrative (e.g., `industry-transformation`, `corporate-visions`). Mapped to visual `arc_type` via `libraries/arc-taxonomy.md`. |
| `arc_definition_path` | string | none | Path to cogni-narrative arc definition file. When provided, arc element names are used as `station_label` values. |
| `interactive` | bool | `true` | When `true`, propose Story World options and wait for user selection. When `false`, auto-select top-ranked Story World. |
| `audience_context` | string | none | Structured audience/buyer data for station prioritization |
| `governing_thought` | string | auto-extracted | Pre-computed governing thought from caller |

### Theme Selection

The `theme` parameter accepts any theme ID from `/cogni-workplace/themes/`. Themes are created by `/grab-theme` from websites or PPTX templates. The skill stores the theme path in frontmatter — visual decisions are delegated to the Excalidraw MCP renderer.

### Canvas Sizes

All canvases are landscape at 150 DPI (print-quality):

| Format | Pixels (w x h) | Max Stations | Max Object Scale |
|--------|----------------|--------------|-----------------|
| A0 | 7016 x 4961 | 8 | 400 x 300 px |
| A1 | 4961 x 3508 | 7 | 300 x 220 px |
| A2 | 3508 x 2480 | 6 | 220 x 160 px |
| A3 | 2480 x 1754 | 5 | 160 x 120 px |

## Architecture

### Two-Layer Intelligence

```
Layer 1: STORY ARC ANALYSIS
  Read narrative -> Identify argument structure -> Map the arc
  (Reuses arc detection from story-to-slides references)

Layer 2: SCENE ARCHITECTURE
  Brainstorm Story World -> Decompose into stations -> Map stations to landscape objects
  Define object_name + narrative_connection per station (rendering agents own visual composition)
```

### 8-Step Workflow

1. **Parse parameters** — Discover source files, validate theme, resolve arc context, load libraries (big-picture-layouts.md, EXAMPLE_BIG_PICTURE_BRIEF.md)
2. **Read narrative & analyze arc** — Detect arc type, extract governing thought, map section roles. Arc type drives spatial flow direction (left-to-right, bottom-to-top, winding) rather than slide order.
3. **Brainstorm Story World** — Three-phase process: content world analysis (extract nouns, objects, spatial language), generate 2-3 concepts (at least one literal + one lateral), score and present to user (interactive) or auto-select (agent mode).
4. **Decompose into stations** — Break narrative into 4-8 stations mapped to arc sections. Each station becomes a landscape object from the selected Story World. Assign reading flow numbers and text placement.
5. **Write station copy & refine narrative connections** — Assertion headlines (max 50 chars), body text (100-120 words), hero numbers, and `object_name` + `narrative_connection` per station describing the visual intent for rendering agents.
5b. **Propose CTAs** — Extract and generate CTAs per station using shared CTA taxonomy. Interactive checkpoint for review.
6. **Define canvas layout** — Zone allocation (title banner, journey zone, footer), station x/y coordinates, reading flow via inline station numbers.
7. **Validate** — Four-layer validation (schema, messages, visual coherence, content integrity).
8. **Write brief** — Output big-picture-brief.md (v3.0) with YAML frontmatter and station specifications.

## Story World Brainstorming

Story World brainstorming replaces fixed metaphor selection with an open-ended creative process:

**Phase 1 — Content World Analysis:**
Read the narrative and extract concrete nouns, industry domain, physical objects, spatial language, and transformation verbs. Build a vocabulary of scene-relevant words.

**Phase 2 — Generate 2-3 Story World Concepts:**
Each concept includes:
- `world_name`: descriptive name (e.g., "Smart Factory Evolution")
- `world_type`: `literal` (directly from narrative domain) or `lateral` (creative metaphorical leap)
- `world_description`: 1-2 sentence scene description
- `station_objects`: for EACH station, what it BECOMES in this world (object_name + narrative_connection)
- `world_score`: narrative_fit (40%) + visual_composability (30%) + brand_fit (30%)

**RULE:** At least one literal AND one lateral concept must be generated.

**Phase 3 — Score and Present:**
When `interactive=true` (default), the skill presents the top 2-3 concepts for user selection. When `interactive=false`, it auto-selects the highest-scored world.

The `metaphor` parameter serves as a brainstorming hint — classic names (`mountain`, `cityscape`, etc.) seed the content world analysis; free-text hints guide the creative direction.

## Station Copy Rules

Station copy follows strict constraints for visual legibility at poster scale:

- **Assertion headlines:** Every headline must be an assertion (contains a verb), not a topic label. Max 50 characters.
- **Body text:** 4-6 sentences, target 100-120 words. Rich prose for poster reading distance.
- **Hero numbers:** One hero number per station (if applicable). Reframed with number plays (ratio framing, before/after contrast, specific quantification).
- **No hedging:** No "approximately", "around", "about". Use precise numbers.
- **Language consistency:** German umlauts (a, o, u, ss) preserved. Formatting rules follow language parameter.

```text
BAD (topic label):   "Digital Transformation"
GOOD (assertion):    "AI Cuts Response Time by 87%"

BAD (too long):      "Our comprehensive platform enables real-time monitoring"
GOOD (<=50 chars):   "Real-Time Monitoring Prevents 688 Deaths"
```

## Expected Output

A `big-picture-brief.md` (v3.0) with this structure:

```yaml
---
type: big-picture-brief
version: "3.0"
theme: smarter-service
theme_path: "/cogni-workplace/themes/smarter-service/theme.md"
customer: "Customer Name"
provider: "Provider Name"
language: "de"
generated: "2026-03-02"
arc_type: "why-change"
arc_id: "industry-transformation"
governing_thought: "Predictive Maintenance senkt ungeplante Stillstande um 73%."
confidence_score: 0.88
story_world:
  name: "Smart Factory Evolution"
  type: literal
  description: "Factory floor transforming from manual maintenance to smart automated production."
visual_style: "flat-illustration"
roughness: 0
canvas_size: "A1"
canvas_pixels: "4961 x 3508"
max_stations: 6
---

# Big Picture Brief: Predictive Maintenance im Maschinenbau

Predictive Maintenance senkt ungeplante Stillstande um 73%
und macht den Maschinenbau fit fur die nachste Dekade.

---

## Story World

  story_world: "Smart Factory Evolution"
  world_type: literal
  flow_pattern: ascending
  visual_style: flat-illustration
  roughness: 0

---

## Station 1: 23 Tage Stillstand pro Anlage

  reading_flow_number: 1
  position: { x: 200, y: 2200 }
  arc_role: problem
  station_label: "Krafte"
  text_placement: below

  headline: "23 Tage Stillstand pro Anlage"
  body: "Jede CNC-Anlage steht durchschnittlich 23 Tage pro Jahr still..."
  hero_number: "23"
  hero_label: "Tage Stillstand/Jahr"

  landscape_object:
    object_name: "Broken CNC Machine"
    narrative_connection: "A large CNC milling machine with cracked housing, red warning
      light on top, exposed internals visible through an open access panel, and hazard
      tape around the base. Represents the costly reality of unplanned downtime."
    scale: standard
    anchor_point: top-center

  cta:
    text: "Ihre Stillstandskosten berechnen"
    type: evaluate
    urgency: medium

[... additional stations with narrative connections ...]

---

## CTA Summary

  cta_proposals:
    - text: "Erstgesprach fur Pilotprojekt buchen"
      type: commit, urgency: high
  primary_cta: "Erstgesprach fur Pilotprojekt buchen"
  conversion_goal: "consultation"

---

## Generation Metadata

  Story Arc: why-change | Story World: Smart Factory Evolution (literal)
  Stations: 6 as landscape objects | Flow: ascending
  Visual style: flat-illustration | Roughness: 0 | Canvas: A1
  Brief format: v3.0 (clean — no shape_composition or landscape_composition)
  Number plays: 4 | Headlines optimized: 6
```

## Integration

### Pipeline Position

```
cogni-narrative -> cogni-copywriting -> cogni-visual:story-to-big-picture
                                         |-- Produces: big-picture-brief.md (v3.0)
                                         +-- Rendered by: big-picture agent (master)
                                              +-- Nx station-structure-artist (Pass 1, parallel)
                                              +-- Nx station-enrichment-artist (Pass 2, parallel)
                                              +-- 4x zone-reviewer (review, parallel)
                                              +-- via Excalidraw MCP
```

### Relationship to story-to-slides

Both skills share the same upstream pipeline and reuse the story arc analysis from `story-to-slides/references/03-story-arc-analysis.md`. Key differences:

| Aspect | story-to-slides | story-to-big-picture |
|--------|----------------|---------------------|
| Output | Multi-slide YAML brief | Single-canvas scene brief (v3.0) |
| Renderer | PPTX skill | Excalidraw MCP (master + N structure + N enrichment + 4 reviewer) |
| Layout unit | Slide with layout type | Station as landscape object with inline station number |
| Visual selector | N/A | Story World brainstorming (literal/lateral) + roughness |
| Headline limit | 60 chars | 50 chars |
| Body limit | 3-5 bullets | 4-6 sentences, 100-120 words |
| Validation | 5 layers | 4 layers + agent-side review checks |

## Troubleshooting

### Story World Mismatch

**Symptoms:** The selected Story World doesn't feel right for the narrative.

**Causes:**
- Auto-selection weighed visual composability over narrative fit
- World type (literal vs lateral) doesn't match audience expectations

**Solution:**
1. Use `interactive=true` (default) to review Story World proposals before committing
2. Override with explicit `metaphor=cityscape` (or other hint) parameter to seed brainstorming
3. Check `references/01-story-worlds.md` for brainstorming method and classic world patterns

### Station Count Too High/Low

**Symptoms:** Too many stations crammed together, or too few leaving empty space.

**Causes:**
- Narrative has many short sections (over-decomposition) or few long sections (under-decomposition)
- `max_stations` doesn't match canvas size capacity

**Solution:**
1. Adjust `max_stations` parameter (check canvas size limits in table above)
2. Ensure narrative sections are clearly delineated with headings
3. Minor sections are merged automatically — check decomposition log in metadata

### Narrative Connection Quality

**Symptoms:** Rendered station objects don't look recognizable or don't match the scene style.

**Causes:**
- `narrative_connection` too vague or abstract (rendering agents need concrete visual descriptions)
- Object name doesn't evoke a clear physical form

**Solution:**
1. Ensure `narrative_connection` describes concrete physical details (shapes, colors, distinctive features)
2. Use `visual_style` parameter explicitly instead of `auto`
3. Each station's narrative_connection should be 2-3 sentences with specific visual cues

### Low Confidence Score

**Symptoms:** `confidence_score < 0.8` in frontmatter.

**Causes:**
- Ambiguous narrative structure
- Missing statistics for hero numbers
- Sections that don't map cleanly to stations

**Solution:**
1. Check validation results in generation metadata
2. Review flagged stations
3. Add explicit structure markers to narrative (headings, statistics)
4. Manually adjust brief after generation

## References

### Bundled Reference Files

| File | Step | Purpose |
|------|------|---------|
| `references/01-story-worlds.md` | 3 | Story World brainstorming method, classic worlds, industry vocabularies, world scoring |
| `references/02-station-architecture.md` | 2, 4 | Arc analysis for spatial layouts, station decomposition, station-as-landscape-object |
| `references/04-text-station-copy.md` | 5 | Headline rules, body text constraints, number plays for stations |
| `references/05-validation.md` | 7 | Four-layer validation framework for big picture briefs |

### Libraries

| File | Purpose |
|------|---------|
| `$CLAUDE_PLUGIN_ROOT/libraries/big-picture-layouts.md` | Canvas dimensions, connection zones, station positioning patterns |
| `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_BIG_PICTURE_BRIEF.md` | Reference brief (v3.0) showing complete output format |

### Cross-References

- [SKILL.md](./SKILL.md) — Full implementation specification with detailed workflow steps
- [story-to-slides](../story-to-slides/) — Sibling skill for multi-slide presentation briefs
- [story-to-slides/references/03-story-arc-analysis.md](../story-to-slides/references/03-story-arc-analysis.md) — Shared arc detection rules
