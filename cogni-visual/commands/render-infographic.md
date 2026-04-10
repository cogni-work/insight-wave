---
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, Skill, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__restore_snapshot, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__export_to_image, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__get_element
---

# /render-infographic

Render an infographic-brief.md into a hand-drawn Excalidraw sketchnote scene.

## Usage

```
/render-infographic [brief_path] [--theme <theme>] [--output <path>]
```

## Behavior

Invoke the `render-infographic` skill with any provided arguments. If no brief path is
given, the skill auto-discovers `**/infographic-brief.md` nearby.

```
Skill: render-infographic
Args: {user arguments}
```
