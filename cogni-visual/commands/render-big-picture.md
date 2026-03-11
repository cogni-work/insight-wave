---
name: render-big-picture
description: Render a big-picture-brief.md into a richly illustrated Excalidraw scene using parallel artist agents
argument-hint: "brief_path=/path/to/big-picture-brief.md"
allowed-tools:
  - Skill
  - Read
  - Bash
---

# Render Big Picture

Render a big-picture-brief.md (v3.0 or v2.0) into a richly illustrated Excalidraw scene.

## Usage

```
/render-big-picture brief_path=/path/to/big-picture-brief.md
/render-big-picture brief_path=/path/to/brief.md output_path=/path/to/output.excalidraw
/render-big-picture brief_path=/path/to/brief.md sketch_path=/path/to/sketch.excalidraw
/render-big-picture brief_path=/path/to/brief.md skip_sketch=true
```

## What This Does

Invokes the `render-big-picture` skill which uses a station-first pipeline:
1. Canvas setup and title banner rendering (color-mode-aware: dark/light)
2. Station structure illustration (N station-structure-artist agents in parallel, 130-160 elements each)
3. Station enrichment detail (N station-enrichment-artist agents in parallel, 100-130 elements each)
4. Footer
5. Zone-based quality review with corrections (4x zone-reviewer agents in parallel, 9-gate review)
6. Optional Phase 0: generates a 20-50 element composition sketch via official Excalidraw MCP as spatial backbone (skip with `skip_sketch=true`, or provide a pre-made sketch via `sketch_path`)
7. Export to .excalidraw file + shareable URL

## Instructions

Invoke the render-big-picture skill with the user's parameters:

```
/cogni-visual:render-big-picture {arguments}
```

If no brief_path is provided, search for `**/big-picture-brief.md` in the current directory and subdirectories. If exactly one is found, use it. If multiple are found, ask the user which one to render.

## Tips

- The rendered .excalidraw file is saved next to the brief by default
- Total rendering time depends on station count (5-8 stations = 2-4 minutes)
- 4 zone-reviewers evaluate 1/4 of the canvas each (9-gate checklist) and may iterate up to 2 times
- For best results, ensure the Excalidraw browser frontend is running on port 3000
