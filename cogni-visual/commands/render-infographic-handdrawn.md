---
description: Render an infographic-brief.md as a hand-drawn Excalidraw scene — sketchnote (Mike Rohde / graphic recording tradition) or whiteboard (Dan Roam "Back of the Napkin" / RSA Animate tradition) style. Use for "hand-drawn infographic", "sketchnote infographic", "whiteboard infographic", "sketchnoting", "visual facilitation", "graphic recording", "whiteboard explainer", "RSA Animate infographic", "Mike Rohde style", "Back of the Napkin diagram", or when you already know the brief uses sketchnote/whiteboard style_preset. Direct dispatcher — reads the brief's style_preset and routes to render-infographic-sketchnote or render-infographic-whiteboard. For style-unknown briefs or auto-routing use /render-infographic instead.
allowed-tools: Read, Grep, Glob, AskUserQuestion, Agent, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__restore_snapshot, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__export_to_image, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__get_element, mcp__excalidraw__import_scene
---

# /render-infographic-handdrawn

Render an infographic-brief.md into a hand-drawn Excalidraw scene — **sketchnote** (Mike
Rohde / graphic recording) or **whiteboard** (Dan Roam "Back of the Napkin" / RSA Animate)
style. This command is the direct dispatcher for the hand-drawn family — it reads the
brief's `style_preset` and routes to the correct tradition-specific agent. The two traditions
have **opposite** discipline rules (warm/dashed/several-accents vs solid/transparent/hero+CTA
only), which is why each tradition has its own dedicated agent instead of a single
conditional one.

If you already know the style preset and want to save one file read, use `/render-infographic`
(the smart dispatcher) — it does the same routing. This command exists for callers who want
to be explicit that they are staying inside the hand-drawn family.

## Usage

```
/render-infographic-handdrawn [brief_path] [--output <path>]
```

## Behavior

### Step 1: Discover the brief

1. If a path argument was provided, use it directly.
2. Otherwise `Glob **/infographic-brief.md` (max 3 levels from the current working directory).
3. If multiple candidates are found, present them via `AskUserQuestion` (show filename,
   title, and style_preset for each). On empty response, auto-select the shallowest path.
4. If zero candidates are found, tell the user no brief was found and stop.

### Step 2: Read style_preset and route

Read the brief's frontmatter and confirm `type: infographic-brief`, `version: "1.0"` or
`"1.1"`, and `style_preset`. Then dispatch via the `Agent` tool:

- **`sketchnote`** → dispatch `render-infographic-sketchnote`
- **`whiteboard`** → dispatch `render-infographic-whiteboard`
- **`economist` / `editorial` / `data-viz` / `corporate`** → abort with an error telling the
  caller to use `/render-infographic-editorial` instead — this command is hand-drawn only.
- **Missing or unrecognized** → ask the user via `AskUserQuestion` whether the brief is
  sketchnote or whiteboard, then dispatch the matching agent.

Pass the absolute `BRIEF_PATH` and, if the user provided `--output`, the `OUTPUT_PATH`.
Prompt template:

```
Render the infographic brief at {brief_path} into a .excalidraw scene.
OUTPUT_PATH: {output_path or "default"}
```

### Step 3: Return the result

The agent returns single-line JSON. Forward it to the user verbatim, then add a one-line
recap naming the output path, share URL, element count, and the style_preset that was
rendered.

### Step 4: Offer an interactive edit checkpoint

The render is now live in the user's Excalidraw browser — every element is directly
editable by the user, not only by the agent. Before ending the command, explicitly tell the
user they can tweak anything on the canvas and that you can re-export their edited state
back to the original output path. Without this step, any manual touch-ups they make in the
browser would be lost the next time the pipeline runs.

Print a message in this exact shape, filling in the path from the agent's JSON:

> "The sketchnote/whiteboard is rendered at **`{output_path}`** and live in your
> Excalidraw browser. Feel free to tweak anything on the canvas — move a zone, fix a
> typo, swap an icon, adjust spacing. When you're happy with your edits, tell me
> **`save`** (or `export`, `persist`, `finalize`) and I'll re-export both the
> `.excalidraw` file and the PNG preview so your final version is what's stored on disk."

End the command here. Do NOT enter a polling loop. When the user comes back with a save
instruction, the outer conversation will handle it: call `mcp__excalidraw__export_scene`
with `filePath = {output_path}` to re-write the `.excalidraw` file from the current canvas
state, then `mcp__excalidraw__export_to_image` with `filePath = {same_dir}/infographic.png`
to regenerate the PNG. Report the new element count to the user as confirmation.

If the user moves on without saying save, that's fine — the agent's original export is
already on disk. The checkpoint exists so manual edits don't silently disappear, not to
force a second save.

## Concurrency note

Both hand-drawn agents share a single Excalidraw MCP canvas. **Never dispatch two
Excalidraw-based renders in parallel** — they will draw over each other regardless of which
tradition each is using. Serialize any mix of sketchnote and whiteboard renders.
