# Visual QA for platform renders

Apply this rubric after every complete render and corrective pass. Deterministic checks decide what can be read from the artifact; review-record criteria hold presentation judgments. Record each observation with a criterion, severity, code, and description. Never record a bare quality verdict.

## Hand-off clauses and falsifiers

| Hand-off rule | Falsified by |
|---|---|
| Every visible string and note equals its frozen record | `copy-differs`, `notes-differs`, `evidence-differs`, or `order-differs` |
| Each copy key is one named native object, never split or rasterized | `flattened-substitution` or `witness-failed` |
| Slide and unit order equals composition order | `order-differs` |
| Speaker notes reproduce `talk_track` | `notes-differs` |
| Citation targets equal source URLs byte for byte | `sources-differs` |
| Dataset values, units, and labels are unchanged | `data-differs` plus review criterion `data integrity` |
| Palette and typefaces come only from the theme | artifact-painted `contrast-unresolved` / `contrast-low` plus review criterion `brand` |
| `key_figures` are hero figures | review criterion `hierarchy` |
| `dark_slides` and `climax` use the declared dark roles | artifact-painted contrast checks plus review criterion `brand` |
| `evidence_status` is present and visually quiet | `evidence-differs` plus review criterion `hierarchy` |
| No autofit, hidden/off-slide content, placeholder, prompt fragment, template residue, or picture of copy | `text-clipped`, `frames-overlap`, `generation-residue`, or review criterion `residue` |

The contrast checks read colors painted by the delivered artifact and grade them against the theme's declared roles. They do not prove typeface identity; the review's `brand` criterion carries that judgment.

## Review criteria

- **Layout:** keep an intentional grid, margins, whitespace, wrapping, and hierarchy. Do not solve density with tiny type.
- **Semantic visual:** show the relationship and focal point named by `visual_intent`; reject decorative icons, arbitrary metaphors, and visuals that restate the headline.
- **Anti-template:** vary composition with message and evidence; do not repeat a card grid, pills, or rounded rectangles as the dominant vocabulary.
- **Coherence:** keep terminology, citation style, footers, spacing rhythm, type, and color logic consistent across the deck.
- **Editability:** keep titles, copy, labels, tables, charts, and simple diagrams native. Limit pictures to declared non-copy fallbacks.
- **Residue:** leave no hidden object, unused placeholder, prompt fragment, debug label, stale template instruction, or temporary filename in notes or metadata.

Inspect every slide or page unit at full resolution and inspect one deck overview. Re-render affected artifacts and refresh their review entries after any repair. A spent repair budget is a bounded failure, never a handover.
