# cogni-visual

A visual deliverables plugin for [Claude Code](https://claude.ai/code). Transforms polished narratives into presentation briefs, big-picture journey maps, scrollable web narratives, and printed poster storyboards. Works downstream of cogni-narrative and cogni-copywriting in a compose-polish-visualize pipeline.

> **Note**: This plugin generates intermediate briefs (YAML + Markdown) that are then rendered by downstream tools — `document-skills:pptx` for slide decks, [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) for big-picture journey maps, and [Pencil MCP](https://pencil.li) for web and storyboard canvases. A theme from cogni-workplace is required for branded output.

## Installation

```bash
claude plugins add cogni-visual
```

## Skills

| Skill | Description |
|-------|-------------|
| `story-to-slides` | Multi-slide presentation brief from any narrative — audience modeling, message architecture, assertion headlines, number plays, speaker notes, and 11 slide layout types |
| `story-to-big-picture` | Single-canvas visual journey map brief — metaphor selection (6 options), station decomposition, absolute positioning, AI image prompts, and theme-driven rendering |
| `story-to-web` | Scrollable landing-page-style web brief — style guide selection (200+ tags), 10 section types, design token variables, auto-layout, and responsive typography |
| `story-to-storyboard` | Multi-poster print storyboard brief — 5-zone poster anatomy, A0-A3 print sizes at 150 DPI, font scaling tables, and CMYK-safe color constraints |

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
- **Themes**: Brand themes from `cogni-workplace/themes/{id}/theme.md`
- **Renderers**: `document-skills:pptx` for slides; Excalidraw MCP for big-picture; Pencil MCP for web and storyboard

## Architecture

```
cogni-visual/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       4 transformation skills (narrative → brief)
│   ├── story-to-slides/
│   ├── story-to-big-picture/
│   ├── story-to-web/
│   └── story-to-storyboard/
├── agents/                       8 agents (orchestration + rendering)
│   ├── story-to-slides.md        Orchestrates story-to-slides skill
│   ├── pptx.md                   Renders briefs into .pptx
│   ├── story-to-big-picture.md   Orchestrates story-to-big-picture skill
│   ├── big-picture.md            Renders briefs into .excalidraw via Excalidraw MCP
│   ├── story-to-web.md           Orchestrates story-to-web skill
│   ├── web.md                    Renders briefs into .pen via Pencil MCP
│   ├── story-to-storyboard.md    Orchestrates story-to-storyboard skill
│   └── storyboard.md             Renders briefs into .pen via Pencil MCP
└── libraries/                    Shared reference material
    ├── arc-taxonomy.md           Arc ID → visual arc type mapping
    ├── pptx-layouts.md           Slide layout schemas
    ├── big-picture-layouts.md    Canvas dimensions and station positioning
    ├── web-layouts.md            Section types and design tokens
    └── storyboard-layouts.md     Poster dimensions and zone anatomy
```

### Skills vs Agents

**Skills** are the intelligence layer — they analyze narratives, select visual strategies, and produce structured briefs. **Agents** are the execution layer — they orchestrate skill invocations or render briefs into final output files. Skills are user-facing; agents are internal.

## Configuration

### Theme Integration

All visual outputs require a brand theme. Point to your theme file in the narrative frontmatter or provide the path when invoking a skill:

```yaml
theme_path: /path/to/cogni-workplace/themes/your-brand/theme.md
```

Themes define colors, fonts, and visual identity. Create themes using the `grab-theme` skill in cogni-workplace.

### Excalidraw MCP (Big Picture)

The big-picture renderer requires [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) for canvas rendering. It provides 26 tools for element-level CRUD, grouping, alignment, export (PNG/SVG/URL), and live preview via WebSocket. Ensure it is configured in your `.mcp.json`.

### Pencil MCP (Web & Storyboard)

Two renderers (web, storyboard) require [Pencil MCP](https://pencil.li) for canvas rendering. Ensure it is configured in your `.mcp.json`.

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- cogni-narrative (upstream — produces narratives)
- cogni-copywriting (upstream — polishes narratives)
- cogni-workplace (provides brand themes)
- document-skills plugin (provides `pptx` skill for slide rendering)
- Excalidraw MCP (for big-picture rendering — github.com/yctimlin/mcp_excalidraw)
- Pencil MCP (for web and storyboard rendering)

## License

[AGPL-3.0](LICENSE)
