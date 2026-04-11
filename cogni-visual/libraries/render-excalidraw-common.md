# render-excalidraw-common

Shared discipline for the hand-drawn infographic renderers — `render-infographic-sketchnote` and `render-infographic-whiteboard`. Both agents load this file at Step 1 so their tradition-specific prompts stay focused on composition voice instead of repeating lifecycle plumbing and brand-palette rules.

Scope boundary:

- **This file owns:** canvas lifecycle, brand-accent discipline, the eight cross-tradition self-review gates, the Excalidraw element JSON quick-reference, and the error-recovery table.
- **Each tradition agent owns:** its own roughness / border / fill parameters, its own accent budget (how many elements earn accent color), its own forbidden-elements list, and its own "named-reference" gate (would Mike Rohde recognize this? would an RSA Animate illustrator?).
- **`libraries/excalidraw-patterns.md` owns:** low-level element recipes — if you need more than the quick-reference below, that is where to go.

---

## 1. Canvas lifecycle

The Excalidraw MCP canvas may contain leftover elements from a previous session. If you skip this and start drawing, you will draw on top of someone else's work and the final scene will be corrupted in ways the self-review gates cannot detect cleanly.

`clear_canvas()` alone is unreliable when a previous `.excalidraw` file is loaded — the reliable path is to replace the scene with an explicitly empty one:

1. Write a minimal empty scene to a temp file:
   ```json
   {"type":"excalidraw","version":2,"elements":[],"appState":{"viewBackgroundColor":"#ffffff"}}
   ```
2. `import_scene` with that file and `mode: "replace"`.
3. Verify with `describe_scene()` — element count must be `0`. If it is not, retry once with a fresh temp file; if still non-empty, return `{"ok": false, "e": "canvas_clear_failed"}`.
4. `snapshot_scene()` — this is your clean recovery point. Any later zone that fails validation can `restore_snapshot()` back to here.

Do not proceed to planning or rendering until the canvas is confirmed empty.

**Zone checkpoints.** Before each zone's first `batch_create_elements` call, take another `snapshot_scene()`. Excalidraw batches accept at most 25 elements per call — split larger zones across multiple calls, and snapshot between zones, not between batches inside the same zone. If a zone fails the self-review, you want to restore to the state *before* that zone started, not partway through.

**Concurrency.** The Excalidraw MCP canvas is a single shared surface. Never dispatch two Excalidraw-based renders in parallel — they will draw over each other. Any caller that needs to render multiple hand-drawn briefs must serialize them. The `/render-infographic` and `/render-infographic-handdrawn` commands both enforce this, but if you are dispatched from somewhere else, remind the caller in your returned JSON `warnings` field if you detect pre-existing content after the clear step.

---

## 2. Brand-accent discipline (no traffic-light coding)

An infographic lives inside a brand. The theme palette is the whole color vocabulary — do not add colors outside it to signal semantics. In particular: **never introduce a second accent (red, amber, yellow) to mean "bad" or "problem" while using the theme accent to mean "good".** That is traffic-light coding, and it dilutes the brand. The 0.13.1 iteration exposed exactly this drift — the hand-drawn renderer was coloring "problem" zones red and "solution" zones green on briefs that carried no color fields — and this section is the fix.

The discipline is asymmetric:

- **Theme accent = positive only.** Use it for hero numbers that represent progress, the proposed / solution side of a comparison, the CTA band, and the emphasis marks your tradition allows. Because the accent is rare, it earns attention when it appears.
- **Ink and muted gray = everything else.** Problem numbers, cost-of-inaction stats, status-quo columns, supporting labels — all render in near-black ink, optionally with a slightly muted weight. Weight, size, and position carry the emphasis, not hue.
- **No red unless red IS the brand accent.** If `theme.primary` is red (rare — the Economist editorial preset is the main case, and that runs on `render-infographic-pencil`, not here), red is the positive color. Otherwise red must never appear.

Why this matters: a strong hand-drawn infographic can deliver the full problem → solution contrast using only ink, gray, and one accent color. Rely on size, placement, and iconography — not on a second palette — to carry the emotional load. This is also what lets the same scene feel native under any brand theme: swap the accent hue and nothing else has to change.

**Comparison-pair rule.** For `comparison-pair` blocks specifically: the left side (status quo, problem) uses ink and muted gray only — heavier weight, tighter spacing, no accent color. The right side (proposed, solution) uses the brand accent for at most two highlight elements — lighter weight, airier spacing. The contrast is built from weight and tone, not from red-vs-green.

---

## 3. Self-review gates (shared)

After the final zone is drawn, capture the scene and walk it against each gate below before touching anything. Name specific zones and element ids when you identify a failure — vague observations do not drive good fixes.

1. `export_to_image(format: "png")` — capture visual state.
2. `describe_scene()` — confirm element counts per zone match the plan from your Step 3 reasoning.

| Gate | What to look for |
|------|------------------|
| **Text Readability** | No overlapping or clipping text; hero numbers legible at a glance. |
| **Zone Composition** | Each zone has clear internal hierarchy: headline → content → source. |
| **Visual Balance** | Weight distributed across the canvas — no quadrant empty while another is overcrowded. |
| **Number Prominence** | Hero numbers are the first thing noticed (the 10-second test). |
| **Flow & Connections** | Arrows guide natural reading order, not confuse it. |
| **Style Character** | Roughness, font choice, and border style clearly match your tradition's parameters. |
| **Accent Discipline** | Accent color appears only on the elements you committed to in Step 3, and only on positive-semantic elements (see §2). No red unless red is the brand accent. |
| **Brand Palette Fidelity** | Walk every stroke and fill. Every non-ink color must be the theme accent or a direct tint of it, and must mark a **positive** element. If you see red / amber / yellow signalling "bad" while the theme accent signals "good", you have traffic-light coded the scene and this gate fails — replace all negative-semantic reds with ink / gray before passing. |

Your tradition agent also enforces a **ninth gate** (the named-reference check) and a preset-specific **forbidden-elements list**. Those are intentionally not in this file — they are where the two traditions actually diverge.

**Fix loop.** For each failing gate, identify the specific element id and the targeted `update_element` or `delete_element` call that would fix it. If the fix would cascade (resizing one element pushes another off-canvas), call that out and plan the chain before executing. **Maximum 3 fix iterations** — if gates are still failing after the third pass, `restore_snapshot()` to the last good state and report the remaining issues in the output JSON's `warnings` field.

---

## 4. Excalidraw element quick-reference

Things the Excalidraw MCP requires that you cannot derive from design knowledge. If you need more (curved arrows, binding rules, group semantics), see `libraries/excalidraw-patterns.md`.

**Rectangle / ellipse:**
```json
{
  "type": "rectangle",
  "x": 100, "y": 200, "width": 400, "height": 180,
  "strokeColor": "#111111", "backgroundColor": "#F2F2EE",
  "fillStyle": "solid", "strokeWidth": 2, "roughness": 1,
  "roundness": {"type": 3, "value": 12}
}
```

**Text:** `"type": "text"`, `fontSize`, `fontFamily` (`1` = Virgil, `2` = Helvetica, `3` = Cascadia — always use `1` for hand-drawn), `textAlign`, `text`. `strokeColor` controls text color.

**Arrows:** `"type": "arrow"` with `startBinding` / `endBinding` pointing at element ids so arrows move with the elements they connect.

**Checkpoints:** `snapshot_scene()` before risky batches, `restore_snapshot()` to recover.

**Batch limit:** `batch_create_elements` rejects more than 25 elements per call — split automatically.

---

## 5. Error recovery

| Scenario | Action |
|----------|--------|
| Brief not found | Return `{"ok": false, "e": "brief_not_found"}` |
| Invalid brief version (accept `1.0` and `1.1` only) | Return `{"ok": false, "e": "unsupported_brief_version"}` |
| Excalidraw MCP unavailable | Return `{"ok": false, "e": "excalidraw_mcp_unavailable"}` |
| Canvas not empty after `import_scene` replace | Retry once with a fresh temp file; if still non-empty, return `{"ok": false, "e": "canvas_clear_failed"}` |
| Invalid `layout_type` | Default to the brief's first valid block ordering and note in `warnings` |
| Icon cannot be drawn in 2–4 primitives | Substitute a simpler icon (circle, square, or labeled dot) and continue |
| Zone overlap unresolved after 3 fix passes | `restore_snapshot()` to last good state and return with `warnings: ["overlap_unresolved"]` |
| Brief has more than 12 content blocks | Render the first 12, set `warnings: ["blocks_truncated"]` |
| `batch_create_elements` rejects more than 25 elements | Split into multiple calls automatically |
