---
description: Render an infographic-brief.md as a pixel-precise editorial .pen file via Pencil MCP — The Economist data page style (data journalism, Tufte data-ink discipline, Financial Times visual journalism tradition). Use for "editorial infographic", "Economist infographic", "Economist-style infographic", "The Economist data page", "magazine-style data page", "data journalism infographic", "FT-style infographic", "Tufte data-ink infographic", "data-viz infographic", "corporate infographic", "clean infographic", or when you already know the brief uses economist/editorial/data-viz/corporate style_preset. Direct dispatcher — for style-unknown briefs or auto-routing use /render-infographic instead.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__export_nodes, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_variables, mcp__pencil__open_document, mcp__pencil__set_variables, mcp__pencil__snapshot_layout
---

# /render-infographic-editorial

Render an infographic-brief.md into a pixel-precise editorial .pen file via Pencil MCP — **The
Economist data page** style, in the tradition of data journalism (Edward Tufte's data-ink
discipline, Financial Times visual journalism). Direct dispatcher to the
`render-infographic-pencil` agent — skips the style-preset routing in `/render-infographic`,
so only use this when you already know the brief's `style_preset` is `economist`, `editorial`,
`data-viz`, or `corporate`.

## Usage

```
/render-infographic-editorial [brief_path] [--output <path>]
```

## Behavior

### Step 1: Dispatch

Dispatch the `render-infographic-pencil` agent with any provided arguments. If no brief path
is given, the agent auto-discovers `**/infographic-brief.md` nearby.

```
Agent: render-infographic-pencil
Prompt: Render the infographic brief at {brief_path} into a .pen file. {additional args}
```

### Step 2: Return the result

Forward the agent's single-line JSON to the user verbatim, then add a one-line recap naming
the `.pen` path, operation count, and style_preset that was rendered.

### Step 3: Offer an interactive edit checkpoint

The render is now live in the user's Pencil browser — every frame is directly editable by
the user, not only by the agent. Before ending the command, explicitly tell the user they
can tweak anything on the canvas and that you can refresh the PNG preview from their
edited state. Without this step, any manual touch-ups they make in the browser would never
be reflected in the rendered preview file.

Note: Pencil auto-persists changes to the `.pen` file as the user edits, so the source
file is always current — unlike Excalidraw, there is no risk of losing edits. The save
action here only refreshes the PNG preview, not the source.

Print a message in this exact shape, filling in the path from the agent's JSON:

> "The editorial infographic is rendered at **`{pen_path}`** and live in your Pencil
> browser. Pencil auto-saves every change as you edit — move a stat, re-word a
> callout, adjust a rule line, swap a number. When you're happy with your edits,
> tell me **`save`** (or `refresh preview`, `export png`) and I'll re-export the
> PNG preview so your final version matches the `.pen` source."

End the command here. When the user comes back with a save instruction, re-run the agent's
PNG export routine (`mcp__pencil__export_nodes` or equivalent) against the current `.pen`
state and confirm the refreshed preview path to the user.
