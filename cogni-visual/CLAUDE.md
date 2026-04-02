# cogni-visual

Transform polished narratives and structured data into visual deliverables — presentation briefs, slide decks, big picture journey maps, Big Block solution architecture diagrams, scrollable web narratives, poster storyboards, and visual assets.

## Plugin Architecture

```
skills/              Intelligent transformation & rendering skills
  story-to-slides/     Multi-slide presentation brief from any narrative
  story-to-big-picture/ Single-canvas visual journey map brief from any narrative
  story-to-web/        Scrollable landing-page-style web brief from any narrative
  story-to-storyboard/ Multi-poster print storyboard brief from any narrative
  story-to-big-block/  Big Block solution architecture brief from TIPS value-modeler output
  render-big-picture/  Orchestrator skill — station-first pipeline (v4.2, 1100-1500 elements, dark/light mode)
  render-big-block/    Orchestrator skill — sequential pipeline (v1.0, 150-250 elements, dark/light mode)
  review-brief/        Standalone stakeholder review of any visual brief (3 perspectives, accept/revise verdict)
  enrich-report/       Post-processing: markdown report → themed HTML (+ optional PDF/DOCX) with Chart.js + Excalidraw SVG
    scripts/
      generate-enriched-report.py  Python HTML generator (markdown→HTML, theme injection, chart mounting)
    schemas/
      design-variables.schema.json  Shared design-variables contract
      enrichment-plan.schema.json   Enrichment plan validation
    references/
      01-report-detection.md       Report type detection heuristics
      02-section-analysis.md       Section mapping and data extraction rules
      03-enrichment-catalog.md     Enrichment types, triggers, scoring, density thresholds
      04-chart-patterns.md         Chart.js config templates (themed)
      05-excalidraw-patterns.md    Excalidraw element recipes for concept diagrams
      06-html-structure.md         HTML layout, CSS architecture, responsive breakpoints
    references/
      color-palette.md             Single source of truth for all color/dark mode decisions
      element-templates.md         Banner, footer, prompt templates + pipeline data tables
      illustration-techniques.md   How to compose high-density illustrations from primitives (250+ per object)
      shape-recipes-v3.md          High-density recipe library (250+ elements per object, structure + enrichment)
      scene-composition-guide.md   DEPRECATED (v4.1) — inter-station connection guide (retained for reference)
      review-checklist.md          9-gate quality checklist (contrast visibility + dark mode compliance)

commands/            User-facing slash commands
  render-big-picture.md  /render-big-picture — invoke the rendering pipeline
  render-big-block.md    /render-big-block — invoke the Big Block rendering pipeline
  enrich-report.md       /enrich-report — enrich a report with themed visualizations
  review-brief.md        /review-brief — stakeholder review of any visual brief

agents/              Autonomous rendering agents (brief -> output)
  story-to-slides.md   Orchestrates the story-to-slides skill
  pptx.md              Renders presentation briefs into .pptx via document-skills:pptx
  story-to-big-picture.md  Orchestrates the story-to-big-picture skill
  big-picture.md       Wrapper agent — delegates to render-big-picture skill
  station-structure-artist.md  Worker agent — composes station structure (130-160 elements, Pass 1)
  station-enrichment-artist.md Worker agent — adds fine detail to station (100-130 elements, Pass 2)
  slides-enrichment-artist.md  Worker agent — generates prep slides + speaker notes (Step 8.2)
  station-connector-artist.md  DEPRECATED (v4.1) — retained for reference
  zone-reviewer.md     Worker agent — reviews and corrects one 1/4 zone of canvas
  story-to-web.md      Orchestrates the story-to-web skill
  web.md               Renders web briefs into .pen + HTML via Pencil MCP
  story-to-big-block.md   Orchestrates the story-to-big-block skill
  big-block.md         Wrapper agent — delegates to render-big-block skill
  story-to-storyboard.md  Orchestrates the story-to-storyboard skill
  storyboard.md        Renders storyboard briefs into multi-poster .pen via Pencil MCP
  enrich-report.md     Orchestrates the enrich-report skill (report → themed HTML)
  brief-review-assessor.md  Stakeholder review of visual briefs (3 perspectives per brief type, haiku)

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
  big-block-layouts.md     Block sizing, tier bands, connection routing, SPI/foundation sections
  EXAMPLE_BIG_BLOCK_BRIEF.md   Reference Big Block brief (9 solutions, 4 tiers, manufacturing)
  cta-taxonomy.md          CTA types, urgency levels, arc-to-CTA heuristics (all skills)
  brief-review-perspectives.md  5 perspective sets for stakeholder review (slides, big-picture, web, storyboard, big-block)
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 9 | story-to-slides, story-to-big-picture, story-to-big-block, story-to-web, story-to-storyboard, render-big-picture, render-big-block, enrich-report, review-brief |
| Agents | 16 | story-to-slides, pptx, story-to-big-picture, big-picture (wrapper), story-to-big-block, big-block (wrapper), station-structure-artist (worker ×N), station-enrichment-artist (worker ×N), slides-enrichment-artist (worker), zone-reviewer (worker ×4), story-to-web, web, story-to-storyboard, storyboard, enrich-report, brief-review-assessor |
| Commands | 4 | render-big-picture, render-big-block, enrich-report, review-brief |
| Libraries | 13 | arc-taxonomy, cta-taxonomy, pptx-layouts, EXAMPLE_BRIEF, big-picture-layouts, EXAMPLE_BIG_PICTURE_BRIEF, big-block-layouts, EXAMPLE_BIG_BLOCK_BRIEF, web-layouts, EXAMPLE_WEB_BRIEF, storyboard-layouts, EXAMPLE_STORYBOARD_BRIEF, brief-review-perspectives |

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

## Big Block Pipeline (v1.0 — Solution Architecture Diagrams)

The Big Block transforms TIPS value-modeler Phase 4 output into a structured solution architecture diagram:

```
tips-value-model.json + tips-big-block.md (Phase 4 output)
         ↓
┌──────────────────────────────────────────────────────┐
│ story-to-big-block SKILL (v1.0)                      │
│  Step 0: Auto-discover value-modeler output          │
│  Step 1: Parse JSON — solutions, paths, SPIs         │
│  Step 2: Classify into BR tiers (1-4)                │
│  Step 3: Map path connections between blocks         │
│  Step 4: Assign implementation waves (1-3)           │
│  Step 5: Extract SPIs and foundations                │
│  Step 6: Preview and confirm                         │
│  Step 7: Validate and write brief                    │
└──────────────────────────────────────────────────────┘
         ↓
big-block-brief.md (v1.0)
         ↓
┌──────────────────────────────────────────────────────┐
│ render-big-block SKILL (orchestrator v1.0)           │
│  Phase 1: Parse brief, setup canvas (color mode)     │
│  Phase 2: Title banner (dark bar + accent border)    │
│  Phase 3: Tier bands (horizontal, Tier 1→4)          │
│  Phase 4: Solution blocks (grid, BR-scored)          │
│  Phase 5: Path connections (dashed bezier lines)     │
│  Phase 6: SPI + Foundation cards                     │
│  Phase 7: Roadmap timeline (Wave 1→3)                │
│  Phase 8: Footer + export .excalidraw + URL          │
└──────────────────────────────────────────────────────┘
         ↓
big-block.excalidraw (structured diagram, 150-250 elements)
```

Key differences from Big Picture:
- **Input:** Structured data (JSON) not narratives (prose)
- **Layout:** Tier-based grid with solution blocks, not landscape journey map
- **Content:** Solution names, BR scores, portfolio mappings — not assertion headlines and body copy
- **Connections:** TIPS path links between blocks, not spatial reading flow
- **Sections:** SPIs, Foundations, Implementation Roadmap below the tier grid
- **Rendering:** Sequential phases, no parallel worker agents (~150-250 elements vs 1100-1500)

## Pipeline Position

```
cogni-narrative -> cogni-copywriting -> cogni-visual
(compose)         (polish)            (visualize)

cogni-trends/cogni-research → enrich-report → browser / PDF / DOCX
(text report)                 (post-process)   (themed HTML + optional format export)
```

- **Upstream (narrative skills):** Narratives from cogni-narrative, polished by cogni-copywriting
- **Upstream (big-block):** TIPS value-modeler Phase 4 output from cogni-trends
- **External:** Themes from cogni-workspace (`/cogni-workspace/themes/{id}/theme.md`)
- **Downstream:** `document-skills:pptx` renders slide briefs; Excalidraw MCP renders big-picture briefs; Pencil MCP renders web and storyboard briefs; `document-skills:pdf` and `document-skills:docx` handle format export from enrich-report
- **Web HTML export:** Web agent reads rendered .pen design tree to generate self-contained HTML + integration manifest for `export-html-report` landing page overlay
- **Report output consolidation:** enrich-report is the single output skill for all report formats (HTML, PDF, DOCX). It supersedes the deprecated cogni-research:export-report. The `formats` parameter controls output: `["html"]` (default), `["html", "pdf"]`, `["html", "docx"]`, or all three. The `density` parameter controls enrichment volume: `none` for themed prose only, `minimal`/`balanced`/`rich` for data visualizations.

## Key Conventions

- **Briefs are YAML frontmatter + Markdown.** Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification.
- **Big Block = data-driven grid, not narrative landscape.** story-to-big-block reads structured JSON from the TIPS value-modeler (not narratives). Solution blocks are organized by BR tier in horizontal bands. TIPS path connections link blocks that share trend-implication-possibility paths. SPIs and Foundations appear below the tier grid. No arc taxonomy, no story worlds, no copywriting — the data IS the content.
- **Unified arc taxonomy.** All four narrative skills read `arc_id` from narrative frontmatter, map to visual `arc_type` via `libraries/arc-taxonomy.md` (6 narrative arcs → 5 visual arc types), and optionally load arc element names for labeling (station labels, section labels, arc labels, methodology phases).
- **Agent responses are JSON-only.** Agents return structured JSON; no prose.
- **Assertion headlines.** Every slide title, station headline, section headline, and poster headline must be an assertion (contains a verb), not a topic label.
- **Number plays.** Statistics are reframed for visual impact (ratio framing, hero number isolation, before/after contrast).
- **Progressive disclosure.** Reference files are read only at the step that needs them, not all at once.
- **Theme-driven visuals.** Briefs contain no color/font fields; the renderer reads theme.md directly (or maps to design tokens for web and storyboard briefs). Big-picture briefs v3.0 are fully clean — no drawing data.
- **CTA proposals.** All four skills extract and generate CTAs via shared `libraries/cta-taxonomy.md`. Each content unit gets a per-section `cta:` field (text, type, urgency). A `CTA Summary` block aggregates 3-5 prioritized proposals with a `primary_cta`. Interactive CTA checkpoint lets users review/edit before finalization.
- **Big picture = station-first, no connectors, no arrows, no circles.** Station-structure-artists compose 130-160 element structures. Station-enrichment-artists add 100-130 fine details. Inline accent-colored number text (not circles) positioned LEFT of headline indicates reading flow. Dark mode min fill #888888, opacity-aware contrast checks. Title spans ~50% banner width (A1: 110px). Station body text 100-120 words. 4 zone-reviewers evaluate station density + contrast visibility + dark mode compliance in parallel. Batch size 50 with fallback to 25/10.
- **Stakeholder review for briefs.** All story-to-X skills support a `stakeholder_review` parameter (defaults to `interactive`). When enabled, the `brief-review-assessor` agent evaluates the brief from 3 type-adapted perspectives (design, audience, usability) with 5 weighted criteria each. Verdict is accept/revise/reject with max 2 revision rounds. Perspectives are defined in `libraries/brief-review-perspectives.md`. The standalone `review-brief` skill and `/review-brief` command enable reviewing existing briefs outside the generation flow.

## Skill Differences

| Aspect | story-to-slides | story-to-big-picture | story-to-big-block | render-big-picture | render-big-block | story-to-web | story-to-storyboard | enrich-report |
|--------|----------------|---------------------|-------------------|-------------------|-----------------|-------------|---------------------|---------------|
| Input | Narrative (prose) | Narrative (prose) | Value-modeler (JSON) | Brief (v3.0) | Brief (v1.0) | Narrative (prose) | Narrative (prose) | Markdown report (any) |
| Output | Multi-slide YAML brief | Single-canvas scene brief (v3.0) | Solution architecture brief (v1.0) | .excalidraw illustrated scene | .excalidraw structured diagram | Scrollable section brief | Multi-poster print brief | Self-contained themed HTML + optional PDF/DOCX |
| Renderer | PPTX skill | N/A (produces brief) | render-big-block | Excalidraw MCP (station-first, N+N+4 agents) | Excalidraw MCP (sequential, 8 phases) | Pencil MCP (web agent) | Pencil MCP (storyboard agent) | Python script + Chart.js CDN + Excalidraw MCP (SVG export) |
| Layout unit | Slide with layout type | Station as landscape object | Solution block in tier band | Station as 250+ element two-pass illustration | Solution block in tier grid | Section with auto-layout | Poster with 1-3 stacked sections | Report section with injected chart/SVG |
| Element count | N/A | N/A | N/A | 1100-1500 total (stations only) | 150-250 total | N/A | N/A | 10-22 enrichments (Chart.js + SVG) |
| Quality review | N/A | 4-layer validation | 8-point schema validation | 9-gate zone-based (4 parallel reviewers, 2 passes) | Snapshot checkpoints | 4-layer validation | N/A | 5-gate validation (citations, charts, SVG, theme, content) |
| Stakeholder review | Designer + Audience + Presenter | Storyteller + Audience + Facilitator | Architect + Decision Maker + Sales Engineer | N/A (rendering) | N/A (rendering) | UX Designer + Audience + Strategist | Print Designer + Audience + Presenter | N/A (post-processing) |
