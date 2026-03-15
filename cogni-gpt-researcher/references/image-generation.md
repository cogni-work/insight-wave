# Image Generation Reference

## Overview

Optional inline image generation for research reports. When enabled, the writer agent can request AI-generated illustrations to be embedded in the report. Images are generated after the draft is written and inserted at marked positions.

## Activation

Image generation is activated when `generate_images` is set to `true` in project-config.json. Default: `false`.

When to suggest enabling:
- Detailed or deep reports (enough content to warrant illustrations)
- Topics that benefit from visual explanation (technology, architecture, processes)
- User explicitly requests images or "make it visual"

## Image Providers

Choose the right provider based on image style:
- **Technical diagrams** (flows, architectures, comparisons, process maps) → Excalidraw MCP
- **Illustrations and infographics** (conceptual visuals, data viz) → cogni-visual or external API

### Option 1: Excalidraw MCP (preferred for diagrams)

For technical diagrams — architecture overviews, process flows, comparison matrices, relationship maps — use the Excalidraw MCP tools (`mcp__excalidraw__*`). Excalidraw produces precise, editable hand-drawn-style diagrams that are far more accurate for technical content than AI-generated images.

1. Use `mcp__excalidraw__batch_create_elements` to build the diagram with boxes, arrows, and labels
2. Use `mcp__excalidraw__export_to_image` to export as PNG to `<project_path>/output/images/<filename>.png`
3. Ideal for: system architectures, data flows, timelines, org charts, comparison diagrams

### Option 2: cogni-visual delegation (preferred for illustrations)

If the cogni-visual plugin is installed and the image style is illustration or infographic:
```
Skill(cogni-visual:generate-image,
  prompt="<image description>",
  style="illustration|infographic",
  output_path="<project_path>/output/images/<filename>.png")
```

### Option 3: External API via Bash

If an image generation API key is available (e.g., DALL-E, Stability AI) and neither Excalidraw nor cogni-visual can handle the request:
```bash
curl -s "https://api.openai.com/v1/images/generations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"dall-e-3","prompt":"...","size":"1024x1024","n":1}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data'][0]['url'])"
```

### Option 4: Placeholder markers (fallback)

If no image provider is available, the writer inserts placeholder markers:
```markdown
<!-- IMAGE: Description of desired illustration. Topic: cloud architecture overview. Style: technical diagram -->
```
The user can later replace these with actual images.

## Style Selection Guide

Match the image style to the content being illustrated:

| Content Type | Style | Provider |
|-------------|-------|----------|
| System architecture, component relationships | diagram | Excalidraw MCP |
| Process flows, decision trees, workflows | diagram | Excalidraw MCP |
| Timelines, roadmaps | diagram | Excalidraw MCP |
| Comparison matrices, feature tables | diagram | Excalidraw MCP |
| Data visualization, charts, statistics | infographic | cogni-visual or external API |
| Conceptual overviews, abstract concepts | illustration | cogni-visual or external API |
| Market landscapes, ecosystem maps | infographic | cogni-visual or external API |

When in doubt: if the image needs precise labels, boxes, and arrows → Excalidraw. If it needs visual flair and artistic rendering → cogni-visual/API.

## Writer Integration

When `generate_images` is true, the writer agent:

1. After completing Phase 2 (draft writing), identify 2-5 positions where images would add value:
   - Section headers (overview diagrams)
   - Data-heavy sections (charts, infographics)
   - Process descriptions (flow diagrams)
   - Comparative sections (comparison tables as visuals)

2. For each image position, write a detailed prompt:
   - Subject description (what the image shows)
   - Style hint (diagram, infographic, illustration, chart)
   - Context (what section it supports)
   - Color scheme (match report theme)

3. Insert images using markdown syntax:
   ```markdown
   ![Description](output/images/section-overview.png)
   ```

## Configuration

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `generate_images` | bool | false | Enable image generation |
| `max_images` | int | 5 | Maximum images per report |
| `image_style` | string | "diagram" | Default style: diagram, illustration, infographic |

## Limitations

- Image generation adds latency and cost to the pipeline
- Generated images may not always be accurate for technical diagrams
- For best results, use placeholder markers and have the user supply real diagrams
- No image generation for outline or resource report types
