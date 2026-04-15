# cogni-visual

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

A [Claude Cowork](https://claude.ai/cowork) plugin for brief-based visual production — skills distill polished narratives into structured YAML+Markdown briefs (slides, infographics, storyboards, web narratives, enriched reports), then rendering agents hand those briefs to PPTX, Excalidraw, Pencil MCP, and HTML backends. Every output inherits brand identity from your cogni-workspace theme instead of generic templates.

## Why this exists

The last mile of consulting delivery is visual production. Insights and narratives are ready — but turning them into presentations, diagrams, and branded collateral is where projects stall:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Manual visual production | Creating a branded slide deck from narrative content takes 1-2 days of formatting work | Delivery bottleneck — insights ready on Tuesday, client sees them on Thursday |
| Format fragmentation | Same core message needs slides for the boardroom, a journey map for the workshop, a web page for the follow-up | Each format is a separate production effort |
| Template fatigue | Generic templates produce generic-looking output; custom design is expensive | Deliverables look like every other consultancy's output |

## What it is

A brief-based visual production pipeline. Skills generate structured briefs (YAML + Markdown) from narratives or data. Renderers and downstream tools (document-skills:pptx, Excalidraw MCP, Pencil MCP) turn those briefs into final output files. All visuals inherit brand identity from cogni-workspace themes.

## What it does

1. **Brief** a presentation from any narrative → `presentation-brief.md` → pptx (PowerPoint deck)
2. **Brief** a poster series from any narrative → `storyboard-brief.md` → storyboard (print poster series)
3. **Brief** a scrollable web page from any narrative → `web-brief.md` → web (scrollable landing page)
4. **Brief** an infographic from any narrative → `infographic-brief.md` → `/render-infographic` (auto-routes to Excalidraw for sketchnote/whiteboard or Pencil MCP for economist/editorial/data-viz/corporate)
5. **Enrich** a markdown report into themed HTML → `{report}-enriched.html` (branded interactive HTML)
6. **Render** a presentation brief into a browser-ready HTML deck → `{name}.html` (self-contained slide deck with speaker notes)
7. **Review** a visual brief from three stakeholder perspectives — design quality, audience experience, usability

## What it means for you

- **Narrative to slides in under 10 minutes.** Assertion headlines, number plays, speaker notes, and 11 slide layout types — generated from your polished narrative, not typed from scratch. What used to take 1-2 days of formatting now takes one prompt.
- **Multiple visual formats from one narrative.** Slides for the boardroom, web pages for digital follow-up, poster storyboards for print, infographics in three traditions (Mike Rohde sketchnote, Dan Roam whiteboard, Economist editorial), and markdown reports enriched into themed HTML with interactive Chart.js charts and inline SVG concept diagrams — all from the same source document, no re-authoring.
- **Brand-driven, not template-driven.** Visuals inherit colors, fonts, and identity from your cogni-workspace theme — changing one theme file reskins all output, not editing each object.
- **Review before you render.** Three-stakeholder brief review catches weak headlines, missing CTAs, and layout mismatches before committing to a rendering pipeline — cheaper to fix a line of text than re-render.

## Known Limitations

> **Chrome native messaging host conflict between Cowork and Claude Code** (S2-major) — Browser-based zone review for rendered visuals may fail silently when tools are missing. Workaround: Toggle native messaging host configs by renaming the .json file for the unused product and restarting Chrome. See [Known Issues Registry](../../cogni-docs/references/known-issues.md#ki-001) for details.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

> **Note:** Excalidraw MCP is required for hand-drawn infographic rendering (sketchnote, whiteboard traditions). Pencil MCP is required for editorial infographic rendering (economist, editorial, data-viz, corporate), web narratives, and storyboards. Both MCPs are optional — the brief-generation skills work without them.

## Quick start

```
story-to-slides <narrative.md>             # presentation brief → document-skills:pptx
story-to-web <narrative.md>                # web narrative brief → Pencil MCP
story-to-storyboard <narrative.md>         # poster storyboard brief → Pencil MCP
story-to-infographic <narrative.md>        # infographic brief (7 layouts × 6 style presets)
/render-infographic <brief.md>             # auto-routes to Excalidraw or Pencil based on style
/render-infographic-handdrawn <brief.md>   # direct: sketchnote or whiteboard → Excalidraw
/render-infographic-editorial <brief.md>   # direct: economist/editorial/data-viz → Pencil MCP
/enrich-report <report.md>                 # markdown report → themed HTML with charts + diagrams
/render-html-slides <brief.md>             # presentation brief → self-contained HTML slide deck
/review-brief <brief.md>                   # visual brief → stakeholder review (3 perspectives)
```

Or just describe what you want in natural language:

- "Create a presentation from my narrative"
- "Create a scrollable web version of my narrative"
- "Create an infographic from my narrative"

## Try it

After installing, type one prompt:

> Create a presentation brief from my narrative and render it as slides

Claude reads your narrative, detects the story arc from frontmatter, models the audience, maps content to slide layouts with assertion headlines and number plays, and outputs a presentation brief ready for PPTX rendering.

## How it works

The pipeline follows a compose-polish-visualize flow: narratives from cogni-narrative are polished by cogni-copywriting, then visualized here. Each visual skill produces a structured brief (YAML frontmatter + Markdown body). Renderers consume the brief and produce the final file.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `story-to-slides` | skill | Transform any narrative into an optimized multi-slide presentation brief that the PPTX skill can render |
| `story-to-web` | skill | Transform any narrative into an optimized scrollable web narrative brief that the web agent can render |
| `story-to-storyboard` | skill | Transform any narrative into a multi-poster print storyboard brief for executive walkthroughs |
| `story-to-infographic` | skill | Transform any narrative into a single-page infographic brief (7 layout types, 6 style presets) |
| `render-html-slides` | skill | Render a presentation-brief.md into a self-contained HTML slide presentation with speaker notes and keyboard navigation |
| `enrich-report` | skill | Post-process any completed markdown report into a themed, self-contained HTML file with Chart.js visualizations |
| `review-brief` | skill | Review a visual brief from three stakeholder perspectives — design quality, audience experience, and usability |
| `story-to-slides` | agent | Orchestrates the story-to-slides skill |
| `pptx` | agent | Renders presentation briefs into .pptx via document-skills |
| `html-slides` | agent | Renders presentation briefs into self-contained HTML slide decks |
| `slides-enrichment-artist` | agent | Generates prep slides and per-slide speaker notes for a completed slide deck |
| `story-to-web` | agent | Orchestrates the story-to-web skill |
| `web` | agent | Renders web briefs into .pen + self-contained HTML via Pencil MCP |
| `story-to-storyboard` | agent | Orchestrates the story-to-storyboard skill |
| `storyboard` | agent | Renders storyboard briefs into multi-poster .pen via Pencil MCP |
| `story-to-infographic` | agent | Orchestrates the story-to-infographic skill |
| `render-infographic-pencil` | agent | Renders infographic briefs into editorial .pen via Pencil MCP (economist, editorial, data-viz, corporate) |
| `render-infographic-sketchnote` | agent | Renders infographic briefs into hand-drawn Excalidraw scenes — sketchnote tradition (Mike Rohde) |
| `render-infographic-whiteboard` | agent | Renders infographic briefs into hand-drawn Excalidraw scenes — whiteboard tradition (Dan Roam) |
| `editorial-sketch` | agent | Worker — generates one editorial-discipline line-art sketch as inline SVG |
| `enrich-report` | agent | Orchestrates the enrich-report skill (markdown report → themed HTML) |
| `report-html-writer` | agent | Worker (opus) — writes the scroll-layout HTML from source markdown, enrichment-plan, and design-variables for enrich-report Phase 4a |
| `enriched-report-reviewer` | agent | Worker — visual quality review of enriched HTML via Browser MCP screenshots (10-gate rubric) for enrich-report Phase 5b |
| `concept-diagram` | agent | Worker — generates one concept diagram via Excalidraw MCP (fallback for interactive .excalidraw) |
| `concept-diagram-svg` | agent | Worker — generates one concept diagram as clean inline SVG using geometric primitives (default) |
| `brief-review-assessor` | agent | Assesses visual brief quality from three stakeholder perspectives adapted to the brief type |
| `/enrich-report` | command | Enrich a markdown report with themed Chart.js visualizations and concept diagrams |
| `/render-html-slides` | command | Render a presentation-brief.md into a themed HTML slide presentation with speaker notes |
| `/render-infographic` | command | Render an infographic brief — auto-routes to the right rendering agent based on style preset |
| `/render-infographic-handdrawn` | command | Render an infographic brief as a hand-drawn Excalidraw scene (sketchnote or whiteboard) |
| `/render-infographic-editorial` | command | Render an infographic brief as an editorial .pen file via Pencil MCP |
| `/review-brief` | command | Review a visual brief from stakeholder perspectives (design, audience, usability) |
| `ensure-excalidraw-canvas` | hook (PreToolUse) | Auto-starts Excalidraw canvas frontend before any Excalidraw MCP tool call |

## Architecture

```
cogni-visual/                              # 7 skills · 19 agents · 6 commands · 1 hook
├── .claude-plugin/                        Plugin manifest (v0.16.19)
├── skills/                               7 visual skills (4 brief generators · 1 renderer · 1 enricher · 1 reviewer)
│   ├── story-to-slides/
│   ├── story-to-web/
│   ├── story-to-storyboard/
│   ├── story-to-infographic/
│   ├── render-html-slides/
│   ├── enrich-report/
│   └── review-brief/
├── agents/                               19 agents (orchestration · rendering · workers)
├── commands/                             6 slash commands (including /render-infographic dispatcher + 2 direct variants)
├── hooks/                                1 PreToolUse hook (Excalidraw canvas auto-start)
├── scripts/                              Utility scripts (rasterize-sketch.py, cartographic-outline.py)
├── references/                           Reference data (cartographic-data/)
├── evals/                                Evaluation harnesses (render-infographic)
└── libraries/                            17 shared reference files
    ├── arc-taxonomy.md                   arc ID → visual arc type mapping
    ├── cta-taxonomy.md                   CTA types and urgency levels
    ├── pptx-layouts.md                   slide layout schemas
    ├── web-layouts.md                    section types and design tokens
    ├── storyboard-layouts.md             poster dimensions and zone anatomy
    ├── infographic-layouts.md            layout type schemas for infographics
    ├── infographic-pencil-layouts.md     Pencil MCP: Economist tokens, Lucide icons, batch_design syntax
    ├── brief-review-perspectives.md      perspective sets for stakeholder review
    ├── svg-patterns.md                   SVG element recipes for concept diagrams
    ├── excalidraw-patterns.md            Excalidraw MCP element recipes
    ├── render-excalidraw-common.md       shared hand-drawn discipline (canvas lifecycle, review gates)
    ├── EXAMPLE_BRIEF.md                  annotated presentation brief example
    ├── EXAMPLE_WEB_BRIEF.md              annotated web narrative brief example
    ├── EXAMPLE_STORYBOARD_BRIEF.md       annotated storyboard brief example
    ├── EXAMPLE_INFOGRAPHIC_BRIEF.md      annotated infographic brief (stat-heavy, data-viz)
    ├── EXAMPLE_SKETCHNOTE_BRIEF.md       annotated infographic brief (timeline-flow, sketchnote)
    └── EXAMPLE_ECONOMIST_BRIEF.md        annotated infographic brief (stat-heavy portrait, economist)
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | Yes | Produces narratives consumed by all story-to-X skills (upstream compose step) |
| cogni-copywriting | Yes | Polishes narratives before visual briefing (upstream polish step) |
| cogni-workspace | Yes | Provides brand themes for all visual output |
| cogni-trends | No | Trend reports for enrich-report |
| cogni-research | No | enrich-report detects research project configs for report-type-specific enrichment |
| cogni-portfolio | No | enrich-report references portfolio-dashboard patterns for dashboard-style enrichment |
| cogni-sales | No | story-to-slides integrates with why-change Phase 5 for sales-presentation slide rendering |
| document-skills | No | PPTX rendering for slide briefs |
| Excalidraw MCP | No | Canvas rendering for infographic diagrams (github.com/yctimlin/mcp_excalidraw) |
| Pencil MCP | No | Canvas rendering for web narratives and poster storyboards (pencil.li) |

## Contributing

Contributions welcome — visual templates, layout types, rendering improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need custom visual templates, branded rendering pipelines, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
