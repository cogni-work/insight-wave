---
name: render-big-block
description: Render a big-block-brief.md into an Excalidraw solution architecture diagram
allowed-tools:
  - Agent
  - Glob
---

# /render-big-block

Render a big-block-brief.md (v1.0) into a structured Excalidraw solution architecture diagram.

## Usage

```
/render-big-block [brief_path] [output_path]
```

## Arguments

- `brief_path` — Path to big-block-brief.md. If omitted, auto-discovers by searching for `**/big-block-brief.md`.
- `output_path` — Path for .excalidraw output. Defaults to `{brief_dir}/big-block.excalidraw`.

## Behavior

Launch the `cogni-visual:big-block` agent with the provided (or discovered) brief path. The agent delegates to the `render-big-block` skill which orchestrates sequential Excalidraw rendering:

1. Parse brief + detect color mode
2. Title banner + accent border
3. Tier bands (Tier 1 → Tier 4)
4. Solution blocks in grid layout
5. TIPS path connections (dashed lines)
6. SPI + Foundation cards
7. Implementation roadmap timeline
8. Footer + export .excalidraw

Report the result to the user: file path, shareable URL, solution count, element count.
