# cogni-visual

A [Claude Cowork](https://claude.ai/cowork) plugin that transforms polished narratives into visual deliverables — slide decks, big-picture journey maps, Big Block solution architectures, scrollable web narratives, and printed poster storyboards.

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

1. **Analyze** a narrative — detect story arc, model the audience, extract key assertions and data points
2. **Brief** the visual — select format (slides, journey map, solution architecture, web page, poster), map content to layout units, generate image prompts
3. **Render** the output — produce .pptx, .excalidraw, .pen, or .html via the appropriate downstream tool
4. **Review** the result — zone-based quality checks for big-picture scenes (4 parallel reviewers, 9 quality gates)

## What it means for you

- **Narrative to slides in minutes.** Assertion headlines, number plays, speaker notes, and 11 slide layout types — generated from your polished narrative, not typed from scratch.
- **Five visual formats from one pipeline.** Slides for the boardroom, journey maps for workshops, solution architectures from TIPS data, web pages for digital follow-up, poster storyboards for print.
- **Brand-driven, not template-driven.** Visuals inherit colors, fonts, and identity from your cogni-workspace theme — every output looks like yours.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

## Quick start

```
story-to-slides <narrative.md>             # presentation brief → document-skills:pptx
story-to-big-picture <narrative.md>        # journey map brief → render-big-picture → Excalidraw
story-to-big-block                         # solution architecture brief → render-big-block → Excalidraw
story-to-web <narrative.md>                # web narrative brief → Pencil MCP
story-to-storyboard <narrative.md>         # poster storyboard brief → Pencil MCP
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
| `story-to-slides` | skill | Multi-slide presentation brief — audience modeling, assertion headlines, 11 layout types |
| `story-to-big-picture` | skill | Single-canvas journey map brief — 6 metaphors, station decomposition, AI image prompts |
| `story-to-big-block` | skill | Solution architecture brief from TIPS value-modeler — tier classification, path connections |
| `story-to-web` | skill | Scrollable web brief — 200+ style guide tags, 10 section types, design tokens |
| `story-to-storyboard` | skill | Multi-poster print brief — 5-zone anatomy, A0-A3 sizes, CMYK-safe colors |
| `render-big-picture` | skill | Render journey map brief into Excalidraw scene (1100-1500 elements, dark/light mode) |
| `render-big-block` | skill | Render solution architecture brief into Excalidraw diagram (150-250 elements) |
| `story-to-slides` | agent | Orchestrates the story-to-slides skill |
| `pptx` | agent | Renders briefs into .pptx via document-skills |
| `story-to-big-picture` | agent | Orchestrates the story-to-big-picture skill |
| `big-picture` | agent | Wrapper agent — delegates to render-big-picture skill |
| `station-structure-artist` | agent | Composes station structure (130-160 elements per station) |
| `station-enrichment-artist` | agent | Adds fine detail to stations (100-130 elements per station) |
| `zone-reviewer` | agent | Reviews 1/4 zone of canvas for quality and contrast |
| `story-to-big-block` | agent | Orchestrates the story-to-big-block skill |
| `big-block` | agent | Wrapper agent — delegates to render-big-block skill |
| `story-to-web` | agent | Orchestrates the story-to-web skill |
| `web` | agent | Renders briefs into .pen via Pencil MCP |
| `story-to-storyboard` | agent | Orchestrates the story-to-storyboard skill |
| `storyboard` | agent | Renders briefs into multi-poster .pen via Pencil MCP |
| `/render-big-picture` | command | Invoke the big-picture rendering pipeline |
| `/render-big-block` | command | Invoke the Big Block rendering pipeline |

## Architecture

```
cogni-visual/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       7 skills (5 brief generators + 2 renderers)
│   ├── story-to-slides/
│   ├── story-to-big-picture/
│   ├── story-to-big-block/
│   ├── story-to-web/
│   ├── story-to-storyboard/
│   ├── render-big-picture/
│   └── render-big-block/
├── agents/                       13 agents (orchestration + rendering + workers)
├── commands/                     2 slash commands
└── libraries/                    12 shared reference files
    ├── arc-taxonomy.md           Arc ID → visual arc type mapping
    ├── cta-taxonomy.md           CTA types and urgency levels
    ├── pptx-layouts.md           Slide layout schemas
    ├── big-picture-layouts.md    Canvas dimensions and station positioning
    ├── big-block-layouts.md      Block sizing, tier bands, connection routing
    ├── web-layouts.md            Section types and design tokens
    └── storyboard-layouts.md     Poster dimensions and zone anatomy
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | Yes | Produces narratives (upstream — compose step) |
| cogni-copywriting | Yes | Polishes narratives (upstream — polish step) |
| cogni-workspace | Yes | Provides brand themes for all visual output |
| cogni-trends | No | TIPS value-modeler data for Big Block diagrams |
| document-skills | No | PPTX rendering for slide briefs |
| Excalidraw MCP | No | Canvas rendering for big-picture and Big Block (github.com/yctimlin/mcp_excalidraw) |
| Pencil MCP | No | Canvas rendering for web narratives and poster storyboards (pencil.li) |

## Contributing

Contributions welcome — visual templates, layout types, rendering improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need custom visual templates, branded rendering pipelines, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
