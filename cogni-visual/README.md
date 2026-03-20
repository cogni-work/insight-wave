# cogni-visual

A visual deliverables plugin for [Claude Cowork](https://claude.ai/cowork). Transforms polished narratives into presentation briefs, big-picture journey maps, Big Block solution architecture diagrams, scrollable web narratives, and printed poster storyboards. Works downstream of cogni-narrative and cogni-copywriting in a compose-polish-visualize pipeline.

> **Note**: This plugin generates intermediate briefs (YAML + Markdown) that are then rendered by downstream tools — `document-skills:pptx` for slide decks, [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) for big-picture journey maps, and [Pencil MCP](https://pencil.li) for web and storyboard canvases. A theme from cogni-workspace is required for branded output.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

## Skills

| Skill | Description |
|-------|-------------|
| `story-to-slides` | Multi-slide presentation brief from any narrative — audience modeling, message architecture, assertion headlines, number plays, speaker notes, and 11 slide layout types |
| `story-to-big-picture` | Single-canvas visual journey map brief — metaphor selection (6 options), station decomposition, absolute positioning, AI image prompts, and theme-driven rendering |
| `story-to-big-block` | Big Block solution architecture brief from TIPS value-modeler output — tier classification, path connections, implementation waves, SPI and foundation mapping |
| `story-to-web` | Scrollable landing-page-style web brief — style guide selection (200+ tags), 10 section types, design token variables, auto-layout, and responsive typography |
| `story-to-storyboard` | Multi-poster print storyboard brief — 5-zone poster anatomy, A0-A3 print sizes at 150 DPI, font scaling tables, and CMYK-safe color constraints |
| `render-big-picture` | Render a big-picture-brief into a richly illustrated Excalidraw scene — station-first pipeline with parallel agents, 1100-1500 elements, dark/light color modes |
| `render-big-block` | Render a big-block-brief into a structured Excalidraw diagram — sequential pipeline, tier bands, solution blocks, path connections, 150-250 elements |

## Example Workflows

### Create a Slide Deck

```
You: Create a presentation brief from my-narrative.md

Claude: [Reads narrative, detects arc_id from frontmatter]
        [Models audience, builds message architecture]
        [Maps narrative elements to 11 slide layout types]
        [Writes assertion headlines, number plays, speaker notes]
        [Outputs presentation-brief.md — ready for document-skills:pptx]
```

### Create a Big-Picture Journey Map

```
You: Create a big picture from my-narrative.md

Claude: [Reads narrative, maps arc_id to visual arc_type]
        [Presents 6 journey metaphors — user selects one]
        [Decomposes narrative into stations with x,y coordinates]
        [Generates AI image prompts for landscape and stations]
        [Outputs big-picture-brief.md — ready for Excalidraw MCP rendering]
```

### Create a Big Block Solution Architecture

```
You: Create a Big Block from my TIPS value model

Claude: [Reads TIPS value-modeler Phase 4 output (JSON)]
        [Classifies solutions into BR tiers (1-4)]
        [Maps TIPS path connections between blocks]
        [Assigns implementation waves (1-3)]
        [Outputs big-block-brief.md — ready for Excalidraw MCP rendering]
```

### Create a Scrollable Web Narrative

```
You: Create a web narrative from my-narrative.md

Claude: [Reads narrative, queries Pencil MCP for style guide tags]
        [User selects visual style from matching guides]
        [Maps narrative to 10 section types with design tokens]
        [Generates AI image prompts, sets typography variables]
        [Outputs web-narrative-brief.md — ready for Pencil MCP rendering]
```

### Create a Printed Poster Storyboard

```
You: Create a storyboard from my-narrative.md

Claude: [Reads narrative, selects print size (A0-A3)]
        [Decomposes into poster sequence (title, content, data, summary)]
        [Applies 5-zone anatomy per poster with font scaling]
        [Generates image prompts, validates print constraints]
        [Outputs storyboard-brief.md — ready for Pencil MCP rendering]
```

## Pipeline Position

```
cogni-narrative  →  cogni-copywriting  →  cogni-visual
(compose)           (polish)              (visualize)
```

- **Upstream**: Narratives from cogni-narrative, polished by cogni-copywriting
- **Themes**: Brand themes from `cogni-workspace/themes/{id}/theme.md`
- **Renderers**: `document-skills:pptx` for slides; Excalidraw MCP for big-picture; Pencil MCP for web and storyboard

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
│   ├── story-to-slides.md        Orchestrates story-to-slides skill
│   ├── pptx.md                   Renders briefs into .pptx
│   ├── story-to-big-picture.md   Orchestrates story-to-big-picture skill
│   ├── big-picture.md            Delegates to render-big-picture skill
│   ├── station-structure-artist.md  Worker — composes station structure (130-160 elements)
│   ├── station-enrichment-artist.md Worker — adds fine detail (100-130 elements)
│   ├── zone-reviewer.md          Worker — reviews 1/4 zone of canvas
│   ├── story-to-big-block.md     Orchestrates story-to-big-block skill
│   ├── big-block.md              Delegates to render-big-block skill
│   ├── story-to-web.md           Orchestrates story-to-web skill
│   ├── web.md                    Renders briefs into .pen via Pencil MCP
│   ├── story-to-storyboard.md    Orchestrates story-to-storyboard skill
│   └── storyboard.md             Renders briefs into .pen via Pencil MCP
├── commands/                     2 slash commands
│   ├── render-big-picture.md
│   └── render-big-block.md
└── libraries/                    12 shared reference files
    ├── arc-taxonomy.md           Arc ID → visual arc type mapping
    ├── cta-taxonomy.md           CTA types and urgency levels
    ├── pptx-layouts.md           Slide layout schemas
    ├── big-picture-layouts.md    Canvas dimensions and station positioning
    ├── big-block-layouts.md      Block sizing, tier bands, connection routing
    ├── web-layouts.md            Section types and design tokens
    └── storyboard-layouts.md     Poster dimensions and zone anatomy
```

### Skills vs Agents

**Skills** are the intelligence layer — they analyze narratives, select visual strategies, and produce structured briefs. **Agents** are the execution layer — they orchestrate skill invocations or render briefs into final output files. Skills are user-facing; agents are internal.

## Configuration

### Theme Integration

All visual outputs require a brand theme. Point to your theme file in the narrative frontmatter or provide the path when invoking a skill:

```yaml
theme_path: /path/to/cogni-workspace/themes/your-brand/theme.md
```

Themes define colors, fonts, and visual identity. Create themes using the `grab-theme` skill in cogni-workspace.

### Excalidraw MCP (Big Picture)

The big-picture renderer requires [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) for canvas rendering. It provides 26 tools for element-level CRUD, grouping, alignment, export (PNG/SVG/URL), and live preview via WebSocket. Ensure it is configured in your `.mcp.json`.

### Pencil MCP (Web & Storyboard)

Two renderers (web, storyboard) require [Pencil MCP](https://pencil.li) for canvas rendering. Ensure it is configured in your `.mcp.json`.

## Prerequisites

- [Claude Cowork](https://claude.ai/cowork) installed
- cogni-narrative (upstream — produces narratives)
- cogni-copywriting (upstream — polishes narratives)
- cogni-workspace (provides brand themes)
- document-skills plugin (provides `pptx` skill for slide rendering)
- Excalidraw MCP (for big-picture rendering — github.com/yctimlin/mcp_excalidraw)
- Pencil MCP (for web and storyboard rendering)

## Custom development

Need custom visual templates, branded rendering pipelines, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
