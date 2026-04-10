# cogni-visual

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

A [Claude Cowork](https://claude.ai/cowork) plugin that transforms polished narratives and structured data into visual deliverables — presentation briefs, slide decks, big-picture journey maps, Big Block solution architecture diagrams, scrollable web narratives, poster storyboards, and visual assets. Supports Excalidraw, Pencil MCP, and PPTX rendering.

## Why this exists

The last mile of consulting delivery is visual production. Insights and narratives are ready — but turning them into presentations, diagrams, and branded collateral is where projects stall:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Manual visual production | Creating a branded slide deck from narrative content takes 1-2 days of formatting work | Delivery bottleneck — insights ready on Tuesday, client sees them on Thursday |
| Format fragmentation | Same core message needs slides for the boardroom, a journey map for the workshop, a web page for the follow-up | Each format is a separate production effort |
| Template fatigue | Generic templates produce generic-looking output; custom design is expensive | Deliverables look like every other consultancy's output |

## What it is

A brief-based visual production pipeline. Five skills generate structured briefs (YAML + Markdown) from narratives or data. Two renderers and downstream tools (document-skills:pptx, Excalidraw MCP, Pencil MCP) turn those briefs into final output files. All visuals inherit brand identity from cogni-workspace themes.

## What it does

1. **Brief** a presentation from any narrative → `presentation-brief.md` → pptx (PowerPoint deck)
2. **Brief** a journey map from any narrative → `big-picture-brief.md` → render-big-picture (Excalidraw scene)
3. **Brief** a poster series from any narrative → `storyboard-brief.md` → storyboard (print poster series)
4. **Brief** a scrollable web page from any narrative → `web-brief.md` → web (scrollable landing page)
5. **Brief** a solution architecture from TIPS data → `big-block-brief.md` → render-big-block (Excalidraw diagram)
6. **Enrich** a markdown report into themed HTML → `{report}-enriched.html` (branded interactive HTML)
7. **Render** a big-picture brief into an illustrated Excalidraw scene → `{name}.excalidraw` (illustrated journey map)
8. **Render** a big-block brief into a structured Excalidraw diagram → `{name}.excalidraw` (solution architecture diagram)
9. **Render** a presentation brief into a browser-ready HTML deck → `{name}.html` (self-contained slide deck with speaker notes)
10. **Review** a visual brief from three stakeholder perspectives — design quality, audience experience, usability

## What it means for you

- **Narrative to slides in under 10 minutes.** Assertion headlines, number plays, speaker notes, and 11 slide layout types — generated from your polished narrative, not typed from scratch. What used to take 1-2 days of formatting now takes one prompt.
- **Five visual formats from one narrative.** Slides for the boardroom, journey maps for workshops, solution architectures from TIPS data, web pages for digital follow-up, poster storyboards for print — all from the same source document, no re-authoring.
- **Brand-driven, not template-driven.** Visuals inherit colors, fonts, and identity from your cogni-workspace theme — reskinning 1,100+ elements means changing one theme file, not editing each object.
- **Review before you render.** Three-stakeholder brief review catches weak headlines, missing CTAs, and layout mismatches before committing to a 20-minute rendering pipeline — cheaper to fix a line of text than re-render an Excalidraw scene.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

> **Note:** Excalidraw MCP is required for big-picture and Big Block rendering. Pencil MCP is required for web narrative and storyboard rendering. Both are optional — the brief-generation skills work without them.

## Quick start

```
story-to-slides <narrative.md>             # presentation brief → document-skills:pptx
story-to-big-picture <narrative.md>        # journey map brief → render-big-picture → Excalidraw
story-to-big-block                         # solution architecture brief → render-big-block → Excalidraw
story-to-web <narrative.md>                # web narrative brief → Pencil MCP
story-to-storyboard <narrative.md>         # poster storyboard brief → Pencil MCP
/enrich-report <report.md>                 # markdown report → themed HTML with charts + diagrams
/render-big-picture <brief.md>             # big-picture brief → illustrated Excalidraw scene
/render-big-block <brief.md>               # big-block brief → solution architecture diagram
/render-html-slides <brief.md>             # presentation brief → self-contained HTML slide deck
/review-brief <brief.md>                   # visual brief → stakeholder review (3 perspectives)
```

Or just describe what you want in natural language:

- "Create a presentation from my narrative"
- "Turn this into a big-picture journey map"
- "Build a Big Block solution architecture from my TIPS value model"
- "Create a scrollable web version of my narrative"

## Try it

After installing, type one prompt:

> Create a presentation brief from my narrative and render it as slides

Claude reads your narrative, detects the story arc from frontmatter, models the audience, maps content to slide layouts with assertion headlines and number plays, and outputs a presentation brief ready for PPTX rendering.

## How it works

The pipeline follows a compose-polish-visualize flow: narratives from cogni-narrative are polished by cogni-copywriting, then visualized here. Each visual skill produces a structured brief (YAML frontmatter + Markdown body). Renderers consume the brief and produce the final file. For big-picture scenes, parallel station-structure and station-enrichment agents compose 1100-1500 element illustrated scenes. For Big Block diagrams, a sequential pipeline produces 150-250 element structured diagrams from TIPS value-modeler data.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `story-to-slides` | skill | Transform any narrative into an optimized multi-slide presentation brief that the PPTX skill can render |
| `story-to-big-picture` | skill | Transform any narrative into a single-canvas visual journey map brief — 6 metaphors, station decomposition, AI image prompts |
| `story-to-big-block` | skill | Transform TIPS value-modeler output into a visual Big Block solution architecture brief for Excalidraw rendering |
| `story-to-web` | skill | Transform any narrative into an optimized scrollable web narrative brief that the web agent can render |
| `story-to-storyboard` | skill | Transform any narrative into a multi-poster print storyboard brief for executive walkthroughs |
| `render-big-picture` | skill | Render a big-picture-brief.md into a richly illustrated Excalidraw scene (1100-1500 elements, dark/light mode) |
| `render-big-block` | skill | Render a big-block-brief.md into a structured solution architecture diagram using Excalidraw MCP |
| `render-html-slides` | skill | Render a presentation-brief.md into a self-contained HTML slide presentation with speaker notes and keyboard navigation |
| `enrich-report` | skill | Post-process any completed markdown report into a themed, self-contained HTML file with Chart.js visualizations |
| `review-brief` | skill | Review a visual brief from three stakeholder perspectives — design quality, audience experience, and usability |
| `story-to-slides` | agent | Orchestrates the story-to-slides skill |
| `pptx` | agent | Renders presentation briefs into .pptx via document-skills |
| `html-slides` | agent | Renders presentation briefs into self-contained HTML slide decks |
| `slides-enrichment-artist` | agent | Generates prep slides and per-slide speaker notes for a completed slide deck |
| `story-to-big-picture` | agent | Orchestrates the story-to-big-picture skill |
| `big-picture` | agent | Wrapper agent — delegates to render-big-picture skill |
| `station-structure-artist` | agent | Composes station structure (130-160 elements per station) |
| `station-enrichment-artist` | agent | Adds fine detail to stations (100-130 elements per station) |
| `zone-reviewer` | agent | Reviews one 1/4 zone of canvas for quality and contrast |
| `story-to-big-block` | agent | Orchestrates the story-to-big-block skill |
| `big-block` | agent | Wrapper agent — delegates to render-big-block skill |
| `story-to-web` | agent | Orchestrates the story-to-web skill |
| `web` | agent | Renders web briefs into .pen + self-contained HTML via Pencil MCP |
| `story-to-storyboard` | agent | Orchestrates the story-to-storyboard skill |
| `storyboard` | agent | Renders storyboard briefs into multi-poster .pen via Pencil MCP |
| `enrich-report` | agent | Orchestrates the enrich-report skill (markdown report → themed HTML) |
| `concept-diagram` | agent | Worker agent — generates one concept diagram (TIPS flow, relationship map, process flow, concept sketch) via Excalidraw MCP |
| `brief-review-assessor` | agent | Assesses visual brief quality from three stakeholder perspectives adapted to the brief type |
| `/render-big-picture` | command | Render a big-picture-brief.md into a richly illustrated Excalidraw scene using parallel artist agents |
| `/render-big-block` | command | Render a big-block-brief.md into an Excalidraw solution architecture diagram |
| `/render-html-slides` | command | Render a presentation-brief.md into a themed HTML slide presentation with speaker notes and keyboard navigation |
| `/enrich-report` | command | Enrich a markdown report with themed Chart.js visualizations and Excalidraw concept diagrams |
| `/review-brief` | command | Review a visual brief from stakeholder perspectives (design, audience, usability) |
| `ensure-excalidraw-canvas` | hook (PreToolUse) | Auto-starts Excalidraw canvas frontend before any Excalidraw MCP tool call |

## Architecture

```
cogni-visual/                              # 10 skills · 18 agents · 5 commands · 1 hook
├── .claude-plugin/                        # plugin manifest
├── skills/                               # 10 skills (5 brief generators · 3 renderers · 1 enricher · 1 reviewer)
│   ├── story-to-slides/
│   ├── story-to-slides-workspace/        # dev workspace (iteration artifacts, not a skill)
│   ├── story-to-big-picture/
│   ├── story-to-big-block/
│   ├── story-to-web/
│   ├── story-to-storyboard/
│   ├── render-big-picture/
│   ├── render-big-block/
│   ├── render-html-slides/
│   ├── enrich-report/
│   └── review-brief/
├── agents/                               # 18 agents (orchestration · rendering · workers)
├── commands/                             # 5 slash commands
├── hooks/                                # 1 PreToolUse hook (Excalidraw canvas auto-start)
└── libraries/                            # 13 shared reference files
    ├── arc-taxonomy.md                   # arc ID → visual arc type mapping
    ├── cta-taxonomy.md                   # CTA types and urgency levels
    ├── pptx-layouts.md                   # slide layout schemas
    ├── big-picture-layouts.md            # canvas dimensions and station positioning
    ├── big-block-layouts.md              # block sizing, tier bands, connection routing
    ├── web-layouts.md                    # section types and design tokens
    ├── storyboard-layouts.md             # poster dimensions and zone anatomy
    ├── brief-review-perspectives.md      # 5 perspective sets for stakeholder review
    ├── EXAMPLE_BRIEF.md                  # annotated presentation brief example
    ├── EXAMPLE_BIG_PICTURE_BRIEF.md      # annotated big-picture brief example
    ├── EXAMPLE_BIG_BLOCK_BRIEF.md        # annotated big-block brief example
    ├── EXAMPLE_STORYBOARD_BRIEF.md       # annotated storyboard brief example
    └── EXAMPLE_WEB_BRIEF.md              # annotated web narrative brief example
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | Yes | Produces narratives consumed by all story-to-X skills (upstream compose step) |
| cogni-copywriting | Yes | Polishes narratives before visual briefing (upstream polish step) |
| cogni-workspace | Yes | Provides brand themes for all visual output |
| cogni-trends | No | TIPS value-modeler data for Big Block solution architecture diagrams |
| cogni-research | No | enrich-report detects research project configs for report-type-specific enrichment |
| cogni-portfolio | No | enrich-report references portfolio-dashboard patterns for dashboard-style enrichment |
| cogni-sales | No | story-to-slides integrates with why-change Phase 5 for sales-presentation slide rendering |
| document-skills | No | PPTX rendering for slide briefs |
| Excalidraw MCP | No | Canvas rendering for big-picture and Big Block diagrams (github.com/yctimlin/mcp_excalidraw) |
| Pencil MCP | No | Canvas rendering for web narratives and poster storyboards (pencil.li) |

## Contributing

Contributions welcome — visual templates, layout types, rendering improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `zone-reviewer` (browser review) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [known-issues registry](https://github.com/anthropics/managed-service/blob/main/cogni-docs/references/known-issues.md) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `zone-reviewer` agent's browser-based visual review may fail silently — rendered visuals still work, but interactive browser review is unavailable until the conflict is resolved.

## Custom development

Need custom visual templates, branded rendering pipelines, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
