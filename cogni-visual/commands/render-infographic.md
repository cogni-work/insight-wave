---
description: Render an infographic-brief.md into a visual output — auto-routes to the right rendering agent based on the brief's style_preset. Use whenever the user says "render infographic", "Infografik rendern", "make the infographic visual", "draw the infographic", "turn the brief into an infographic", or has an infographic-brief.md they want to render and does not know (or care) which renderer to use. Handles both the hand-drawn family (sketchnote, whiteboard — Mike Rohde / RSA Animate tradition) and the editorial family (economist, editorial, data-viz, corporate — The Economist data page / data journalism tradition). For style-known direct dispatch use /render-infographic-handdrawn or /render-infographic-editorial.
allowed-tools: Read, Grep, Glob, AskUserQuestion, Agent, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__restore_snapshot, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__export_to_image, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__get_element, mcp__excalidraw__import_scene, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__export_nodes, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_variables, mcp__pencil__open_document, mcp__pencil__set_variables, mcp__pencil__snapshot_layout
---

# /render-infographic

Render an infographic-brief.md into a visual output. This command is the **smart dispatcher** —
it reads the brief's `style_preset` and routes to the right rendering agent. Two families exist:

| Style Preset | Family | Direct Command | Rendering Agent | Output |
|---------------|--------|---------------|-----------------|--------|
| `sketchnote` | Hand-drawn sketchnote (Mike Rohde / graphic recording) | `/render-infographic-handdrawn` | `render-infographic-sketchnote` | `.excalidraw` scene |
| `whiteboard` | Hand-drawn whiteboard (Dan Roam / RSA Animate) | `/render-infographic-handdrawn` | `render-infographic-whiteboard` | `.excalidraw` scene |
| `economist`, `editorial`, `data-viz`, `corporate` | Editorial (The Economist data page) | `/render-infographic-editorial` | `render-infographic-pencil` | `.pen` file |

## Usage

```
/render-infographic [brief_path] [--output <path>]
```

## Behavior

Follow these steps. Do not invent alternative workflows.

### Step 1: Discover the brief

1. If a path argument was provided, use it directly.
2. Otherwise `Glob **/infographic-brief.md` (max 3 levels from the current working directory).
3. If multiple candidates are found, present them via `AskUserQuestion` (max 4 options, show
   filename, title, and style_preset from each candidate's frontmatter). On empty response,
   auto-select the shallowest path.
4. If zero candidates are found, tell the user no brief was found and stop.

### Step 2: Validate and read style_preset

Read the brief and confirm:

- Frontmatter contains `type: infographic-brief`
- Frontmatter contains `version: "1.0"`
- Frontmatter contains `style_preset: <value>`

If any of these are missing or `type`/`version` do not match, abort with a clear error.

### Step 3: Route to the right agent

Match the `style_preset` value and dispatch via the `Agent` tool:

- **`sketchnote`** → dispatch `render-infographic-sketchnote` (Mike Rohde tradition — dashed, warm, several accents)
- **`whiteboard`** → dispatch `render-infographic-whiteboard` (Dan Roam tradition — solid, transparent, accent only on hero + CTA)
- **`economist`**, **`editorial`**, **`data-viz`**, or **`corporate`** → dispatch `render-infographic-pencil`
- **Missing or unrecognized** → ask the user via `AskUserQuestion` which family they want
  (hand-drawn sketchnote, hand-drawn whiteboard, or editorial), then dispatch the matching
  agent. If the user picks hand-drawn without specifying, ask a second `AskUserQuestion` to
  disambiguate between sketchnote and whiteboard — the two traditions have opposite
  discipline rules and the agents refuse to render the wrong preset.

Pass the absolute `BRIEF_PATH` and, if the user provided `--output`, the `OUTPUT_PATH`.
Prompt template:

```
Render the infographic brief at {brief_path} into a {.excalidraw|.pen} file.
OUTPUT_PATH: {output_path or "default"}
```

### Step 4: Return the result

The agent returns single-line JSON. Forward that JSON to the user verbatim, then add a one-line
recap naming:

- The output file path (`.excalidraw` or `.pen`)
- The share URL (Excalidraw only)
- The element or operation count
- The style_preset that was rendered
- Any warnings in the JSON

## Concurrency note

Both hand-drawn agents (`render-infographic-sketchnote` and `render-infographic-whiteboard`)
share a single Excalidraw MCP canvas. **Never dispatch two Excalidraw-based renders in
parallel** — they will draw over each other regardless of which tradition each one is using.
If rendering multiple hand-drawn briefs (any mix of sketchnote and whiteboard), serialize
them. Pencil agents use file-backed documents and can run alongside Excalidraw renders
safely.

## When to use a direct command instead

If you already know the style family and want to skip the dispatch step, use the direct
commands:

- `/render-infographic-handdrawn` — dispatches straight to the hand-drawn agent (Excalidraw backend; sketchnote, whiteboard)
- `/render-infographic-editorial` — dispatches straight to the editorial agent (Pencil backend; economist, editorial, data-viz, corporate)

These do not read the brief's `style_preset` — they trust the caller. Use them when you are
certain about the family and want to save one file read.
