---
description: Render an infographic-brief.md as a hand-drawn Excalidraw scene (sketchnote or whiteboard style, Mike Rohde / RSA Animate tradition). Use for "sketchnote infographic", "whiteboard infographic", "hand-drawn infographic", "Mike Rohde style infographic", "graphic recording", or when you already know the brief uses sketchnote/whiteboard style_preset. Direct dispatcher — for style-unknown briefs or auto-routing use /render-infographic instead.
allowed-tools: Read, Grep, Glob, AskUserQuestion, Agent, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__restore_snapshot, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__export_to_image, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__get_element, mcp__excalidraw__import_scene
---

# /render-infographic-excalidraw

Render an infographic-brief.md into a hand-drawn Excalidraw scene — sketchnote (Mike Rohde
/ graphic recording) or whiteboard (RSA Animate / Dan Roam) style. Direct dispatcher to the
`render-infographic-excalidraw` agent — skips the style-preset routing in `/render-infographic`,
so only use this when you already know the brief's `style_preset` is `sketchnote` or `whiteboard`.

## Usage

```
/render-infographic-excalidraw [brief_path] [--output <path>]
```

## Behavior

Dispatch the `render-infographic-excalidraw` agent with any provided arguments. If no brief
path is given, the agent auto-discovers `**/infographic-brief.md` nearby.

Note: Excalidraw agents share a single MCP canvas. Never dispatch two Excalidraw-based renders
in parallel — they will draw over each other. Serialize if you need multiple runs.

```
Agent: render-infographic-excalidraw
Prompt: Render the infographic brief at {brief_path} into a .excalidraw scene. {additional args}
```
