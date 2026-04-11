# cogni-visual

Transform polished narratives and structured data into visual deliverables — presentation briefs, slide decks, scrollable web narratives, poster storyboards, single-page infographics, and visual assets.

## Plugin Architecture

```
skills/              Intelligent transformation & rendering skills
  story-to-slides/     Multi-slide presentation brief from any narrative
  story-to-web/        Scrollable landing-page-style web brief from any narrative
  story-to-storyboard/ Multi-poster print storyboard brief from any narrative
  story-to-infographic/ Single-page infographic brief from any narrative (7 layout types, 6 style presets in 2 rendering families)
    references/
      01-content-distillation.md  "Less is more" rules, 10-second test, number selection
      02-infographic-mapping.md   Layout type selection heuristics, content pattern → layout, family-grouped compatibility
      03-style-presets.md         6 style presets grouped into two families — editorial (economist, editorial, data-viz, corporate) and hand-drawn (sketchnote, whiteboard)
      04-block-copywriting.md     Per-block-type copy rules, assertion headlines, number plays, icon prompts
      05-validation-checklist.md  4-layer validation (schema, density, data integrity, distillation quality)
  review-brief/        Standalone stakeholder review of any visual brief (3 perspectives, accept/revise verdict)
  render-html-slides/  Render presentation-brief.md → self-contained HTML slide deck with speaker notes, navigation, transitions
    scripts/
      generate-html-slides.py  Python HTML generator (brief→HTML, theme injection, layout rendering, Mermaid)
    references/
      01-layout-renderers.md   Brief YAML → HTML mapping for all 11 layout types
      02-slide-navigation.md   Keyboard, mouse, touch navigation + transitions
      03-speaker-notes.md      Speaker notes panel, toggle, print mode
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
      (05-excalidraw-patterns.md moved to libraries/excalidraw-patterns.md)
      06-html-structure.md         HTML layout, CSS architecture, responsive breakpoints
    references/
      color-palette.md             Single source of truth for all color/dark mode decisions
      element-templates.md         Banner, footer, prompt templates + pipeline data tables
      illustration-techniques.md   How to compose high-density illustrations from primitives (250+ per object)
      shape-recipes-v3.md          High-density recipe library (250+ elements per object, structure + enrichment)
      scene-composition-guide.md   DEPRECATED (v4.1) — inter-station connection guide (retained for reference)
      review-checklist.md          9-gate quality checklist (contrast visibility + dark mode compliance)

commands/            User-facing slash commands
  render-html-slides.md  /render-html-slides — render presentation brief as HTML slide deck
  enrich-report.md       /enrich-report — enrich a report with themed visualizations
  render-infographic.md  /render-infographic — smart dispatcher: reads brief style_preset, routes to the right render agent (Excalidraw or Pencil)
  render-infographic-excalidraw.md  /render-infographic-excalidraw — direct dispatch to the Excalidraw hand-drawn render agent (sketchnote, whiteboard)
  render-infographic-pencil.md  /render-infographic-pencil — direct dispatch to the Pencil editorial render agent (economist, editorial, data-viz, corporate)
  review-brief.md        /review-brief — stakeholder review of any visual brief

agents/              Autonomous rendering agents (brief -> output)
  story-to-slides.md   Orchestrates the story-to-slides skill
  pptx.md              Renders presentation briefs into .pptx via document-skills:pptx
  html-slides.md       Renders presentation briefs into self-contained HTML slide decks
  slides-enrichment-artist.md  Worker agent — generates prep slides + speaker notes (Step 8.2)
  story-to-web.md      Orchestrates the story-to-web skill
  web.md               Renders web briefs into .pen + HTML via Pencil MCP
  story-to-storyboard.md  Orchestrates the story-to-storyboard skill
  storyboard.md        Renders storyboard briefs into multi-poster .pen via Pencil MCP
  story-to-infographic.md  Orchestrates the story-to-infographic skill
  render-infographic-excalidraw.md  Renders infographic briefs into hand-drawn Excalidraw scenes (sketchnote, whiteboard presets, opus)
  render-infographic-pencil.md  Renders infographic briefs into editorial .pen via Pencil MCP (economist, editorial, data-viz, corporate presets, opus)
  enrich-report.md     Orchestrates the enrich-report skill (report → themed HTML)
  concept-diagram.md   Worker agent — generates one concept diagram via Excalidraw MCP, returns SVG. Retained as fallback for Excalidraw-native output scenarios (interactive .excalidraw files). Superseded by concept-diagram-svg for enrich-report
  concept-diagram-svg.md  Worker agent — generates one concept diagram as clean inline SVG using LLM-crafted geometric primitives. No Excalidraw dependency. Produces gradient fills, drop shadows, zone backgrounds. Visual review via browser screenshot. Default for enrich-report concept track. Cross-plugin: any skill dispatching to enrich-report benefits (cogni-portfolio, cogni-consulting, cogni-trends, cogni-research)
  brief-review-assessor.md  Stakeholder review of visual briefs (3 perspectives per brief type, haiku)

libraries/           Shared reference material loaded at Step 1
  arc-taxonomy.md          Shared arc_id → arc_type mapping + element names (all skills)
  pptx-layouts.md          Slide layout schemas for PPTX skill
  EXAMPLE_BRIEF.md         Reference presentation brief (story-to-slides)
  web-layouts.md           Section type schemas, typography, spacing, design tokens
  EXAMPLE_WEB_BRIEF.md     Reference web narrative brief
  storyboard-layouts.md    Poster composition model, section stacking, portrait adaptations, print constraints
  EXAMPLE_STORYBOARD_BRIEF.md  Reference storyboard brief (4-poster, stacked web sections)
  infographic-layouts.md   Layout type schemas (7 layouts) + block type catalog (11 block types) for infographics
  infographic-pencil-layouts.md  Pencil MCP reference: Economist token overrides, Lucide icon mapping, batch_design syntax
  EXAMPLE_INFOGRAPHIC_BRIEF.md  Reference infographic brief (stat-heavy, data-viz)
  svg-patterns.md          SVG element recipes for concept diagrams (inline SVG generation, concept-diagram-svg agent)
  excalidraw-patterns.md   Excalidraw MCP element recipes (Excalidraw-native output only)
  cta-taxonomy.md          CTA types, urgency levels, arc-to-CTA heuristics (all skills)
  brief-review-perspectives.md  Perspective sets for stakeholder review (slides, web, storyboard, infographic)
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 7 | story-to-slides, story-to-web, story-to-storyboard, story-to-infographic, render-html-slides, enrich-report, review-brief |
| Agents | 15 | story-to-slides, pptx, html-slides, slides-enrichment-artist (worker), story-to-web, web, story-to-storyboard, storyboard, story-to-infographic, render-infographic-excalidraw (opus), render-infographic-pencil (opus), enrich-report, concept-diagram (worker, Excalidraw fallback), concept-diagram-svg (worker, default inline SVG), brief-review-assessor |
| Commands | 6 | render-html-slides, render-infographic, render-infographic-excalidraw, render-infographic-pencil, enrich-report, review-brief |
| Libraries | 13 | arc-taxonomy, cta-taxonomy, pptx-layouts, EXAMPLE_BRIEF, web-layouts, EXAMPLE_WEB_BRIEF, storyboard-layouts, EXAMPLE_STORYBOARD_BRIEF, infographic-layouts, infographic-pencil-layouts, EXAMPLE_INFOGRAPHIC_BRIEF, brief-review-perspectives, svg-patterns |

## Pipeline Position

```
cogni-narrative -> cogni-copywriting -> cogni-visual
(compose)         (polish)            (visualize)

cogni-trends/cogni-research → enrich-report → browser / PDF / DOCX
(text report)                 (post-process)   (themed HTML + optional format export)
```

- **Upstream (narrative skills):** Narratives from cogni-narrative, polished by cogni-copywriting
- **External:** Themes from cogni-workspace (`/cogni-workspace/themes/{id}/theme.md`)
- **Downstream:** `document-skills:pptx` renders slide briefs into PowerPoint; `render-html-slides` renders slide briefs into self-contained HTML; Excalidraw MCP renders infographic briefs; Pencil MCP renders web and storyboard briefs; `document-skills:pdf` and `document-skills:docx` handle format export from enrich-report
- **Web HTML export:** Web agent reads rendered .pen design tree to generate self-contained HTML + integration manifest for `export-html-report` landing page overlay
- **Report output consolidation:** enrich-report is the single output skill for all report formats (HTML, PDF, DOCX). It supersedes the deprecated cogni-research:export-report. The `formats` parameter controls output: `["html"]` (default), `["html", "pdf"]`, `["html", "docx"]`, or all three. The `density` parameter controls enrichment volume: `none` for themed prose only, `minimal`/`balanced`/`rich` for data visualizations.

## Key Conventions

- **Briefs are YAML frontmatter + Markdown.** Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification.
- **Unified arc taxonomy.** All narrative skills read `arc_id` from narrative frontmatter, map to visual `arc_type` via `libraries/arc-taxonomy.md` (10 narrative arcs → 5 visual arc types), and optionally load arc element names for labeling (section labels, arc labels, methodology phases).
- **Agent responses are JSON-only.** Agents return structured JSON; no prose.
- **Assertion headlines.** Every slide title, section headline, and poster headline must be an assertion (contains a verb), not a topic label.
- **Number plays.** Statistics are reframed for visual impact (ratio framing, hero number isolation, before/after contrast).
- **Progressive disclosure.** Reference files are read only at the step that needs them, not all at once.
- **Theme-driven visuals.** Briefs contain no color/font fields; the renderer reads theme.md directly (or maps to design tokens for web and storyboard briefs).
- **CTA proposals.** All narrative skills extract and generate CTAs via shared `libraries/cta-taxonomy.md`. Each content unit gets a per-section `cta:` field (text, type, urgency). A `CTA Summary` block aggregates 3-5 prioritized proposals with a `primary_cta`. Interactive CTA checkpoint lets users review/edit before finalization.
- **Infographic = content distillation + dual rendering.** story-to-infographic distills narratives into 3-8 content blocks with strict word limits. 7 layout types × 6 style presets organized into two families. 11 block types as content primitives. The `/render-infographic` command is a smart dispatcher that reads the brief's `style_preset` and routes to one of two Opus-powered agents: `render-infographic-excalidraw` (Mike Rohde sketchnote / RSA Animate whiteboard style) for the hand-drawn family (sketchnote, whiteboard); `render-infographic-pencil` (The Economist data page style) for the editorial family (economist, editorial, data-viz, corporate). Power users can skip dispatch via the direct commands `/render-infographic-excalidraw` and `/render-infographic-pencil`. Both agents trust frontier LLM knowledge of these well-known visual styles — instructions focus on WHY and WHAT, not prescriptive pixel coordinates.
- **Stakeholder review for briefs.** All story-to-X skills support a `stakeholder_review` parameter (defaults to `interactive`). When enabled, the `brief-review-assessor` agent evaluates the brief from 3 type-adapted perspectives (design, audience, usability) with 5 weighted criteria each. Verdict is accept/revise/reject with max 2 revision rounds. Perspectives are defined in `libraries/brief-review-perspectives.md`. The standalone `review-brief` skill and `/review-brief` command enable reviewing existing briefs outside the generation flow.

## Skill Differences

| Aspect | story-to-slides | render-html-slides | story-to-web | story-to-storyboard | story-to-infographic | /render-infographic (command) | enrich-report |
|--------|----------------|-------------------|-------------|---------------------|---------------------|-------------------------------|---------------|
| Input | Narrative (prose) | Presentation brief (v4.0) | Narrative (prose) | Narrative (prose) | Narrative (prose) | Infographic brief (v1.0) | Markdown report (any) |
| Output | Multi-slide YAML brief | Self-contained HTML slide deck | Scrollable section brief | Multi-poster print brief | Single-page infographic brief (v1.0) | .excalidraw scene (hand-drawn family) or .pen file (editorial family) | Self-contained themed HTML + optional PDF/DOCX |
| Renderer | PPTX skill | Python script + Mermaid CDN | Pencil MCP (web agent) | Pencil MCP (storyboard agent) | N/A (produces brief) | Command-level router: reads `style_preset` in brief, dispatches to `render-infographic-excalidraw` (opus) or `render-infographic-pencil` (opus). Direct commands `/render-infographic-excalidraw` and `/render-infographic-pencil` skip the routing step | Python script + Chart.js CDN + inline SVG (concept-diagram-svg agent) |
| Layout unit | Slide with layout type | Slide with HTML/CSS layout | Section with auto-layout | Poster with 1-3 stacked sections | Block with block type (11 types) | Zone with Excalidraw elements (150-250) or Pencil frames (80-160 ops) | Report section with injected chart/SVG |
| Element count | N/A | N/A | N/A | N/A | 3-8 content blocks | N/A | 10-22 enrichments (Chart.js + SVG) |
| Quality review | N/A | 5-point validation (count, notes, citations, mermaid, theme) | 4-layer validation | N/A | 4-layer validation (schema, density, integrity, distillation) | 6-gate screenshot validation (excalidraw) or 5-gate screenshot validation (pencil) — both at agent layer | 5-gate validation (citations, charts, SVG, theme, content) |
| Stakeholder review | Designer + Audience + Presenter | N/A (rendering) | UX Designer + Audience + Strategist | Print Designer + Audience + Presenter | Info Designer + Target Audience + Digital Producer | N/A (rendering) | N/A (post-processing) |
