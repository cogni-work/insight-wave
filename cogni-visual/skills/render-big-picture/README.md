# render-big-picture

Orchestrate the rendering of a big-picture-brief.md (v3.0 or v2.0) into a richly illustrated Excalidraw scene.

## Quick Start

```bash
/render-big-picture brief_path=/path/to/big-picture-brief.md
```

## Architecture

Uses a station-first parallel pipeline with dark/light color mode:

1. **Skill** orchestrates 7 phases (0-6) with progressive reference loading
2. **Nx station-structure-artist** agents compose station silhouettes in parallel (130-160 elements each, Pass 1)
3. **Nx station-enrichment-artist** agents add fine detail in parallel (100-130 elements each, Pass 2)
4. **4x zone-reviewer** agents evaluate and correct 1/4 canvas each (9-gate review per zone)

## Phases

| Phase | Action | Agent |
|-------|--------|-------|
| 0 | (optional) Sketch via Excalidraw MCP | Skill (direct) |
| 1 | Parse brief, init canvas, create frame | Skill (direct) |
| 2 | Render title banner + accent border | Skill (direct) |
| 3 | Draw station structures (Pass 1) | Nx station-structure-artist (parallel, 130-160 each) |
| 3.5 | Add station enrichment (Pass 2) | Nx station-enrichment-artist (parallel, 100-130 each) |
| 4 | Integration (footer) | Skill (direct) |
| 5 | Zone-based review + corrections | 4x zone-reviewer (parallel, up to 2 passes) |
| 6 | Export .excalidraw + shareable URL | Skill (direct) |

## References

- `references/illustration-techniques.md` — Techniques for composing high-density illustrations from Excalidraw primitives (250+ per object)
- `references/shape-recipes-v3.md` — High-density recipe library with 250+ elements per object (structure + enrichment sections)
- `references/scene-composition-guide.md` — DEPRECATED (v4.1) — retained for reference
- `references/review-checklist.md` — 9-gate quality checklist (contrast visibility + dark mode compliance)

## Output

- `.excalidraw` file (richly illustrated scene, 1100-1500 elements)
- Shareable Excalidraw URL (if browser frontend available)
