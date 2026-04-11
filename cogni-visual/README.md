# cogni-visual

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

A [Claude Cowork](https://claude.ai/cowork) plugin that transforms polished narratives and structured data into visual deliverables — presentation briefs, slide decks, scrollable web narratives, poster storyboards, single-page infographics, and visual assets. Supports Excalidraw, Pencil MCP, PPTX, and HTML rendering.

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
- **Multiple visual formats from one narrative.** Slides for the boardroom, web pages for digital follow-up, poster storyboards for print, infographics for quick summaries — all from the same source document, no re-authoring.
- **Brand-driven, not template-driven.** Visuals inherit colors, fonts, and identity from your cogni-workspace theme — changing one theme file reskins all output, not editing each object.
- **Review before you render.** Three-stakeholder brief review catches weak headlines, missing CTAs, and layout mismatches before committing to a rendering pipeline — cheaper to fix a line of text than re-render.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

> **Note:** Excalidraw MCP is required for infographic rendering. Pencil MCP is required for web narrative and storyboard rendering. Both are optional — the brief-generation skills work without them.

## Quick start

```
story-to-slides <narrative.md>             # presentation brief → document-skills:pptx
story-to-web <narrative.md>                # web narrative brief → Pencil MCP
story-to-storyboard <narrative.md>         # poster storyboard brief → Pencil MCP
story-to-infographic <narrative.md>        # infographic brief → Excalidraw sketchnote
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
| `enrich-report` | agent | Orchestrates the enrich-report skill (markdown report → themed HTML) |
| `concept-diagram` | agent | Worker agent — generates one concept diagram (TIPS flow, relationship map, process flow, concept sketch) via Excalidraw MCP |
| `brief-review-assessor` | agent | Assesses visual brief quality from three stakeholder perspectives adapted to the brief type |
| `/render-html-slides` | command | Render a presentation-brief.md into a themed HTML slide presentation with speaker notes and keyboard navigation |
| `/enrich-report` | command | Enrich a markdown report with themed Chart.js visualizations and Excalidraw concept diagrams |
| `/review-brief` | command | Review a visual brief from stakeholder perspectives (design, audience, usability) |
| `ensure-excalidraw-canvas` | hook (PreToolUse) | Auto-starts Excalidraw canvas frontend before any Excalidraw MCP tool call |

## Architecture

```
cogni-visual/                              # 8 skills · 11 agents · 4 commands · 1 hook
├── .claude-plugin/                        # plugin manifest
├── skills/                               # 7 skills (4 brief generators · 1 renderer · 1 enricher · 1 reviewer)
│   ├── story-to-slides/
│   ├── story-to-slides-workspace/        # dev workspace (iteration artifacts, not a skill)
│   ├── story-to-web/
│   ├── story-to-storyboard/
│   ├── story-to-infographic/
│   ├── render-html-slides/
│   ├── enrich-report/
│   └── review-brief/
├── agents/                               # 11 agents (orchestration · rendering · workers)
├── commands/                             # 6 slash commands (including /render-infographic smart dispatcher and its two direct variants)
├── hooks/                                # 1 PreToolUse hook (Excalidraw canvas auto-start)
└── libraries/                            # 12 shared reference files
    ├── arc-taxonomy.md                   # arc ID → visual arc type mapping
    ├── cta-taxonomy.md                   # CTA types and urgency levels
    ├── pptx-layouts.md                   # slide layout schemas
    ├── web-layouts.md                    # section types and design tokens
    ├── storyboard-layouts.md             # poster dimensions and zone anatomy
    ├── infographic-layouts.md            # layout type schemas for infographics
    ├── brief-review-perspectives.md      # perspective sets for stakeholder review
    ├── EXAMPLE_BRIEF.md                  # annotated presentation brief example
    ├── EXAMPLE_STORYBOARD_BRIEF.md       # annotated storyboard brief example
    ├── EXAMPLE_WEB_BRIEF.md              # annotated web narrative brief example
    ├── EXAMPLE_INFOGRAPHIC_BRIEF.md      # annotated infographic brief example
    └── svg-patterns.md                   # SVG element recipes for concept diagrams
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
