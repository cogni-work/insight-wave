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

### Option 1: cogni-visual delegation (preferred)

If the cogni-visual plugin is installed, delegate image generation:
```
Skill(cogni-visual:generate-image,
  prompt="<image description>",
  style="diagram|illustration|infographic",
  output_path="<project_path>/output/images/<filename>.png")
```

### Option 2: External API via Bash

If an image generation API key is available (e.g., DALL-E, Stability AI):
```bash
curl -s "https://api.openai.com/v1/images/generations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"dall-e-3","prompt":"...","size":"1024x1024","n":1}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data'][0]['url'])"
```

### Option 3: Placeholder markers (fallback)

If no image provider is available, the writer inserts placeholder markers:
```markdown
<!-- IMAGE: Description of desired illustration. Topic: cloud architecture overview. Style: technical diagram -->
```
The user can later replace these with actual images.

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
