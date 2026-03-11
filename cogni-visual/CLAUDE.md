# cogni-visual

Transform polished narratives into visual deliverables — presentation briefs, slide decks, big picture journey maps, scrollable web narratives, poster storyboards, and visual assets.

## Plugin Architecture

```
skills/              Intelligent transformation & rendering skills
  story-to-slides/     Multi-slide presentation brief from any narrative
  story-to-big-picture/ Single-canvas visual journey map brief from any narrative
  story-to-web/        Scrollable landing-page-style web brief from any narrative
  story-to-storyboard/ Multi-poster print storyboard brief from any narrative
  render-big-picture/  Orchestrator skill — station-first pipeline (v4.2, 1100-1500 elements, dark/light mode)
    references/
      color-palette.md             Single source of truth for all color/dark mode decisions
      element-templates.md         Banner, footer, prompt templates + pipeline data tables
      illustration-techniques.md   How to compose high-density illustrations from primitives (250+ per object)
      shape-recipes-v3.md          High-density recipe library (250+ elements per object, structure + enrichment)
      scene-composition-guide.md   DEPRECATED (v4.1) — inter-station connection guide (retained for reference)
      review-checklist.md          9-gate quality checklist (contrast visibility + dark mode compliance)

commands/            User-facing slash commands
  render-big-picture.md  /render-big-picture — invoke the rendering pipeline

agents/              Autonomous rendering agents (brief -> output)
  story-to-slides.md   Orchestrates the story-to-slides skill
  pptx.md              Renders presentation briefs into .pptx via document-skills:pptx
  story-to-big-picture.md  Orchestrates the story-to-big-picture skill
  big-picture.md       Wrapper agent — delegates to render-big-picture skill
  station-structure-artist.md  Worker agent — composes station structure (130-160 elements, Pass 1)
  station-enrichment-artist.md Worker agent — adds fine detail to station (100-130 elements, Pass 2)
  station-connector-artist.md  DEPRECATED (v4.1) — retained for reference
  zone-reviewer.md     Worker agent — reviews and corrects one 1/4 zone of canvas
  story-to-web.md      Orchestrates the story-to-web skill
  web.md               Renders web briefs into .pen + HTML via Pencil MCP
  story-to-storyboard.md  Orchestrates the story-to-storyboard skill
  storyboard.md        Renders storyboard briefs into multi-poster .pen via Pencil MCP

libraries/           Shared reference material loaded at Step 1
  arc-taxonomy.md          Shared arc_id → arc_type mapping + element names (all skills)
  pptx-layouts.md          Slide layout schemas for PPTX skill
  EXAMPLE_BRIEF.md         Reference presentation brief (story-to-slides)
  big-picture-layouts.md   Canvas dimensions, zones, station positioning (A0-A3 at 150 DPI)
  EXAMPLE_BIG_PICTURE_BRIEF.md  Reference big-picture brief
  web-layouts.md           Section type schemas, typography, spacing, design tokens
  EXAMPLE_WEB_BRIEF.md     Reference web narrative brief
  storyboard-layouts.md    Poster composition model, section stacking, portrait adaptations, print constraints
  EXAMPLE_STORYBOARD_BRIEF.md  Reference storyboard brief (4-poster, stacked web sections)
  cta-taxonomy.md          CTA types, urgency levels, arc-to-CTA heuristics (all skills)
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 5 | story-to-slides, story-to-big-picture, story-to-web, story-to-storyboard, render-big-picture |
| Agents | 11 | story-to-slides, pptx, story-to-big-picture, big-picture (wrapper), station-structure-artist (worker ×N), station-enrichment-artist (worker ×N), zone-reviewer (worker ×4), story-to-web, web, story-to-storyboard, storyboard |
| Commands | 1 | render-big-picture |
| Libraries | 10 | arc-taxonomy, cta-taxonomy, pptx-layouts, EXAMPLE_BRIEF, big-picture-layouts, EXAMPLE_BIG_PICTURE_BRIEF, web-layouts, EXAMPLE_WEB_BRIEF, storyboard-layouts, EXAMPLE_STORYBOARD_BRIEF |

## Big Picture Rendering Pipeline (v4.2 — Contrast, Inline Numbers, Bigger Title)

The big picture rendering uses a station-first pipeline with parallel agents:

```
big-picture-brief.md (v3.0)
         ↓
┌──────────────────────────────────────────────────────┐
│ render-big-picture SKILL (orchestrator v4.2)         │
│  Phase 0: (optional) Sketch via official Excalidraw  │  ← excalidraw_sketch MCP, 20-50 elements
│           MCP → import into canvas                   │
│  Phase 1: Parse brief, setup canvas (color mode)     │
│  Phase 2: Title banner                               │
│  Phase 3: Stations P1 → N× station-structure-artist  │  ← N agents PARALLEL, 130-160 each
│  Phase 3.5: Stations P2 → N× station-enrichment-artist│ ← N agents PARALLEL, 100-130 each
│  Phase 4: Integration (footer)                       │
│  Phase 5: Review → 4× zone-reviewer                 │  ← 4 agents PARALLEL, 30 corrections each
│  Phase 6: Export .excalidraw + URL                   │
└──────────────────────────────────────────────────────┘
         ↓
big-picture.excalidraw (illustrated scene, 1100-1500 elements)
```

Key features:
- **Dark/light color mode**: auto-detected from theme background luminance. Palette passed to all agents.
- **Station-first pipeline**: stations are the entire visual focus. No connector phase, no journey path arrows.
- **Clean brief format (v3.0)**: briefs describe WHAT (object_name + narrative_connection), not HOW (no shape_composition, no landscape_composition). Agents own visual interpretation via shape-recipes-v3.md.
- **Hybrid sketch architecture**: optional Phase 0 uses official Excalidraw MCP (`excalidraw_sketch`) to generate 20-50 element composition sketch. Parameters: `sketch_path`, `skip_sketch`
- **Two-pass stations**: structure (silhouette + details) then enrichment (textures + micro-details). DENSIFY mode when sketch anchor exists.
- **Reading flow via inline numbers**: accent-colored number text inline LEFT of headline. No circles, no arrows.
- **Zone-based review**: 4 parallel reviewers, each covering 25% of canvas. Gates 4/5 evaluate contrast visibility (opacity-aware, min #888) and dark mode compliance.
- **Batch size 50**: optimized for Excalidraw MCP throughput with fallback to 25/10
- **8 snapshot checkpoints**: full recovery at every iteration boundary
- **Backward compatible**: renders v2.0 briefs by ignoring landscape_composition and shape_composition fields

## Pipeline Position

```
cogni-narrative -> cogni-copywriting -> cogni-visual
(compose)         (polish)            (visualize)
```

- **Upstream:** Narratives from cogni-narrative, polished by cogni-copywriting
- **External:** Themes from cogni-workplace (`/cogni-workplace/themes/{id}/theme.md`)
- **Downstream:** `document-skills:pptx` renders slide briefs; Excalidraw MCP renders big-picture briefs; Pencil MCP renders web and storyboard briefs
- **Web HTML export:** Web agent reads rendered .pen design tree to generate self-contained HTML + integration manifest for `export-html-report` landing page overlay

## Key Conventions

- **Briefs are YAML frontmatter + Markdown.** Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification.
- **Unified arc taxonomy.** All four skills read `arc_id` from narrative frontmatter, map to visual `arc_type` via `libraries/arc-taxonomy.md` (6 narrative arcs → 5 visual arc types), and optionally load arc element names for labeling (station labels, section labels, arc labels, methodology phases).
- **Agent responses are JSON-only.** Agents return structured JSON; no prose.
- **Assertion headlines.** Every slide title, station headline, section headline, and poster headline must be an assertion (contains a verb), not a topic label.
- **Number plays.** Statistics are reframed for visual impact (ratio framing, hero number isolation, before/after contrast).
- **Progressive disclosure.** Reference files are read only at the step that needs them, not all at once.
- **Theme-driven visuals.** Briefs contain no color/font fields; the renderer reads theme.md directly (or maps to design tokens for web and storyboard briefs). Big-picture briefs v3.0 are fully clean — no drawing data.
- **CTA proposals.** All four skills extract and generate CTAs via shared `libraries/cta-taxonomy.md`. Each content unit gets a per-section `cta:` field (text, type, urgency). A `CTA Summary` block aggregates 3-5 prioritized proposals with a `primary_cta`. Interactive CTA checkpoint lets users review/edit before finalization.
- **Big picture = station-first, no connectors, no arrows, no circles.** Station-structure-artists compose 130-160 element structures. Station-enrichment-artists add 100-130 fine details. Inline accent-colored number text (not circles) positioned LEFT of headline indicates reading flow. Dark mode min fill #888888, opacity-aware contrast checks. Title spans ~50% banner width (A1: 110px). Station body text 100-120 words. 4 zone-reviewers evaluate station density + contrast visibility + dark mode compliance in parallel. Batch size 50 with fallback to 25/10.

## Skill Differences

| Aspect | story-to-slides | story-to-big-picture | render-big-picture | story-to-web | story-to-storyboard |
|--------|----------------|---------------------|-------------------|-------------|---------------------|
| Output | Multi-slide YAML brief | Single-canvas scene brief (v3.0) | .excalidraw illustrated scene | Scrollable section brief | Multi-poster print brief |
| Renderer | PPTX skill | N/A (produces brief) | Excalidraw MCP (station-first pipeline, N+N+4 agents) | Pencil MCP (web agent) | Pencil MCP (storyboard agent) |
| Layout unit | Slide with layout type | Station as landscape object | Station as 250+ element two-pass illustration | Section with auto-layout | Poster with 1-3 stacked sections |
| Element count | N/A | N/A | 1100-1500 total (stations only) | N/A | N/A |
| Quality review | N/A | 4-layer validation | 9-gate zone-based review (4 parallel reviewers, up to 2 passes) | N/A | N/A |
