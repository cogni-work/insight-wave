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
| Dataset values, units, and labels are unchanged | `data-differs` |
| Charts and text remain native and editable | package-derived editability inventory plus a read-back witness for each chart series and named text object; `flattened-substitution` or `witness-failed` falsifies the rule |
| Palette and typefaces come only from the theme | review-rule judgment `appearance`; the deterministic contrast report is theme-token-derived and does not prove what the deck painted |
| `key_figures` are hero figures | `misleading-encoding` or review-rule judgment `appearance` |
| `dark_slides` and `climax` use the declared dark roles | review-rule judgment `appearance`; the deterministic contrast report is theme-token-derived and does not prove the delivered surface role |
| `evidence_status` is present and visually quiet | `evidence-differs`, `unreadable-text`, or review-rule judgment `appearance` |
| No autofit, hidden/off-slide content, placeholder, prompt fragment, template residue, or picture of copy | `clipping`, `overlap`, `unreadable-text`, `flattened-substitution`, or review-rule judgment `appearance` |

The deterministic contrast report is computed from the theme's tokens, not from colors read back from the delivered deck. It therefore cannot prove palette or typeface identity. Those are part of the `appearance` judgment that `design-verify` Review rules assign to the visual review record.

## Review criteria

- **Layout:** keep an intentional grid, margins, whitespace, wrapping, and hierarchy. Do not solve density with tiny type.
- **Semantic visual:** show the relationship and focal point named by `visual_intent`; reject decorative icons, arbitrary metaphors, and visuals that restate the headline.
- **Anti-template:** vary composition with message and evidence; do not repeat a card grid, pills, or rounded rectangles as the dominant vocabulary.
- **Coherence:** keep terminology, citation style, footers, spacing rhythm, type, and color logic consistent across the deck.
- **Editability:** keep titles, copy, labels, tables, charts, and simple diagrams native. Limit pictures to declared non-copy fallbacks.
- **Residue:** leave no hidden object, unused placeholder, prompt fragment, debug label, stale template instruction, or temporary filename in notes or metadata.

Inspect every HTML unit and every slide at full resolution and inspect one whole-deck overview. Give every observation an artifact path plus a unit, slide, or overview locator. For every declared dark surface, climax, hero figure, and evidence-status tag, record the exact artifact and locator where it is visible. Re-render affected artifacts and refresh their review entries after any repair. A spent repair budget is a bounded failure, never a handover.
