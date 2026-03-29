---
name: portfolio-architecture
description: |
  Generate an interactive Excalidraw architecture diagram showing products and features
  in a clean hierarchy. Use whenever the user mentions architecture diagram,
  portfolio diagram, product-feature diagram, "show me the structure",
  "visualize the portfolio", portfolio architecture, feature map, product tree,
  "how do the products relate", or wants a visual overview of how products and
  features fit together — even if they don't say "architecture" explicitly.
allowed-tools: Read, Write, Glob, Grep, Bash, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__import_scene, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element
---

# Portfolio Architecture Diagram

Generate an interactive Excalidraw diagram that visualizes the product-feature hierarchy of a cogni-portfolio project. Products appear as large container rectangles with features nested directly inside — no category groupings, no cross-product bridges. The diagram is editable on the live canvas, and user changes are preserved across runs.

## When This Skill Adds Value

- After defining or restructuring products — see the full hierarchy at a glance
- After shaping features — verify grouping, coverage, and readiness distribution
- During portfolio review — spot gaps (empty products), orphaned features, or imbalanced distribution
- When other skills offer "view the architecture diagram" at review checkpoints

## Workflow

### 1. Find the Portfolio Project

Read `portfolio.json` in the current working directory or a user-specified path. If no portfolio project is found, tell the user to run the `portfolio-setup` skill first.

Read `portfolio.json` for the `language` field — if present, communicate with the user in that language. Technical terms, skill names, and CLI commands remain in English.

### 2. Check for Existing Diagram

Check whether `{project-dir}/output/architecture.excalidraw` exists.

**If it exists** — import it onto the canvas via `import_scene(filePath="...", mode="replace")` so the user's previous edits are visible. Then offer options:

- **(a) Full regeneration** — wipe and rebuild from current product/feature data (proceed to Step 3)
- **(b) Add missing** — read data, identify products/features not yet on canvas, add only new elements
- **(c) Update colors** — re-read features, update readiness colors on existing feature rectangles
- **(d) Just open** — the diagram is on canvas, user can edit interactively; skip to Step 6

For option (b): read products/features JSON, call `query_elements` to find existing elements by their IDs (`product-{slug}`, `feature-{slug}`), compute the diff, add only missing elements using the layout from Step 4 (appending to the right of existing products).

For option (c): iterate feature elements on canvas, call `update_element` to change `backgroundColor` and `strokeColor` where readiness has changed.

**If it does not exist** — proceed to Step 3 (fresh generation).

### 3. Read Portfolio Data

Read all `products/*.json` and `features/*.json` from the project directory.

Build two data structures:
- **products**: array of `{slug, name, maturity, revenue_model}` sorted by name
- **features_by_product**: map of `product_slug` → array of `{slug, name, readiness, sort_order}` sorted by `sort_order` then by slug

**Important**: Ignore the `category` field on features. Features appear directly inside their product — no category sub-groupings.

Compute summary stats: product count, feature count, readiness breakdown (GA/Beta/Planned).

### 4. Create Excalidraw Elements

For fresh generation, call `clear_canvas` first.

#### Layout Constants

| Parameter | Value |
|-----------|-------|
| Canvas padding | 60px |
| Product width | 300px |
| Product gap | 40px horizontal |
| Product header height | 60px (name + metadata) |
| Feature width | 260px (20px inset each side) |
| Feature height | 40px |
| Feature gap | 12px vertical |
| Feature top margin | 20px below header |

#### Product Position

Product at index `i`:
- `x = 60 + i × (300 + 40)`
- `y = 60`
- `width = 300`
- `height = 60 + 20 + (feature_count × (40 + 12)) + 20` (bottom padding)
- Minimum height 120px for empty products

#### Feature Position

Feature at index `j` inside product at index `i`:
- `x = product_x + 20`
- `y = product_y + 60 + 20 + j × (40 + 12)`
- `width = 260`
- `height = 40`

#### Color Scheme

| Readiness | backgroundColor | strokeColor | strokeStyle |
|-----------|----------------|-------------|-------------|
| ga | `#bbf7d0` | `#166534` | solid |
| beta | `#fef08a` | `#92400e` | solid |
| planned | `#e5e7eb` | `#6b7280` | dashed |

Product rectangles: `backgroundColor: "#f8fafc"`, `strokeColor: "#334155"`, `strokeWidth: 2`

#### Element Creation

Use `roughness: 0` and `fontFamily: 2` (sans-serif) for a clean, professional look.

For each product, create these elements via `batch_create_elements`:

1. **Product rectangle** — `type: "rectangle"`, `id: "product-{slug}"`
2. **Product name** — `type: "text"`, bold, `fontSize: 20`, centered in header, `id: "product-label-{slug}"`
3. **Product metadata** — `type: "text"`, `fontSize: 14`, maturity + revenue_model below name, color `#64748b`, `id: "product-meta-{slug}"`
4. For each feature:
   - **Feature rectangle** — `type: "rectangle"`, colored by readiness, `id: "feature-{slug}"`
   - **Feature label** — `type: "text"`, `fontSize: 16`, centered in rectangle, `id: "feature-label-{slug}"`

After creating all elements for one product, call `group_elements(elementIds=[...])`.

**Unassigned features** (product_slug not matching any product): place in a final column with a red-bordered rectangle titled "Unassigned Features".

After all products are rendered, call `snapshot_scene(name="architecture-complete")`.

### 5. Present Results

1. Call `get_canvas_screenshot` and display it
2. Present summary: product count, feature count, readiness breakdown
3. Flag observations:
   - Products with zero features
   - Unassigned features
   - Imbalanced distribution (e.g., one product with 15 features, another with 2)
4. Tell the user the diagram is live on the Excalidraw canvas and they can rearrange, annotate, or edit freely

### 6. Interactive Editing Checkpoint

Ask the user: "Would you like to make any changes, or shall I save the diagram?"

- If the user wants changes: apply them via `update_element`/`delete_element`/`create_element`, or let them edit directly on the canvas
- If satisfied: proceed to Step 7

### 7. Export and Save

1. Call `export_scene(filePath="{project-dir}/output/architecture.excalidraw")`
2. Fallback if export_scene fails: call `describe_scene`, write the `.excalidraw` JSON via Write tool:
   ```json
   {
     "type": "excalidraw",
     "version": 2,
     "source": "portfolio-architecture",
     "elements": [...],
     "appState": {"viewBackgroundColor": "#ffffff"}
   }
   ```
3. Optionally call `export_to_excalidraw_url` for a shareable link
4. Confirm save path to the user

### 8. Offer Next Steps

- **(a) Refine products** — delegate to the `products` skill
- **(b) Refine features** — delegate to the `features` skill
- **(c) Open the dashboard** — delegate to the `dashboard-refresher` agent
- **(d) Done** — diagram saved at `output/architecture.excalidraw`

## Important Notes

- The diagram preserves user edits: re-running this skill imports the existing file and offers incremental update options instead of overwriting
- Products must exist before the diagram shows anything meaningful; features are optional but make it useful
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md` for complete entity schemas
