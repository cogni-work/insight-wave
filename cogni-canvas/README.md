# cogni-canvas

Lean Canvas authoring and refinement for Claude Code. Guides users through creating business model hypotheses from scratch or iteratively improving existing canvases with section-by-section critique, coherence checking, and version tracking.

## Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `canvas-create` | `/cogni-canvas:canvas-create` | Guided Q&A to build a new Lean Canvas from scratch |
| `canvas-refine` | `/cogni-canvas:canvas-refine <path>` | Critique and improve an existing canvas |

## Canvas Format

Canvases are markdown files with YAML frontmatter tracking version, dates, and per-section status (`filled` / `draft` / `unfilled`). The 9 standard Lean Canvas sections are followed by an evolution log that records what changed and why across versions.

## Shared References

Both skills share reference material at the plugin root:

- `references/canvas-format.md` — file format spec, frontmatter schema, versioning rules
- `references/lean-canvas-sections.md` — quality criteria, common pitfalls, and guiding questions for all 9 sections

## Integration

After defining a canvas, use `cogni-portfolio:portfolio-canvas` to extract portfolio entities (products, features, markets) from the canvas for downstream messaging and sales workflows.

## License

AGPL-3.0-only
