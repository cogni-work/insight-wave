---
name: design-verify
description: This skill should be used when the user wants to prove a design-render output is faithful, editable, accessible and visually sound before handing it over — "verify the render", "design-verify", "verify the deck", "verify the page", "check the rendered output against the brief", "did the render change any copy", "is the deck editable", "check accessibility of the deck", "review the slides at full resolution", "render with verification", "repair the layout within budget", or "check the proof manifest". It compares copy, data, sources, evidence status, notes and unit order with the frozen brief; checks PPTX editability with edit witnesses; grades declared accessibility; fails on clipping, overlap, missing glyphs, unreadable text or misleading encodings; validates the review, specimen and proof records; and repairs layout within a bounded budget, never content. Prefer it over design-render's check-html or check-pptx before hand-over.
---

# Design Verify

Verify what `design-render` produced before anyone relies on it. The renderer already refuses a page or deck that fails its own fidelity checks; this skill checks the delivered file again, independently, against the frozen inputs, and adds what a render-time check cannot hold: per-family content preservation, object-level editability, declared accessibility, the critical visual classes, a persisted visual review, and a repair loop with a finite budget. The scripts decide what can be decided deterministically. A model or a person judges the rest, and only through a review record that names what was checked.

## Inputs

- **The frozen inputs** of the render: the normalized brief and the semantic composition it was rendered from, and the theme directory it was rendered with.
- **The delivered artifact**: `index.html` or `deck.pptx`, plus `pptx-manifest.json` for a deck.
- **Optionally**: a visual review record, a `design-render` measurement report (`browser-report.json`), and for a proof its manifest and specimen index.

## Workflow

1. Run `verify` on each delivered output. It re-runs the target's fidelity checks on the delivered file and adds preservation, editability (pptx), accessibility and geometry. Read `data.findings`; an empty list is the only passing state.
2. Capture every unit at full resolution for the review: a full-page capture of the page at 1280 CSS px cut on each unit's border rows (each unit section is drawn with a 1 px border, so find its top and bottom border rows in the capture and crop between them with a host image tool), and each slide of the deck at its 1280 × 720 px canvas. Record the capture tool, version, resolution and image digest with each entry. Capture with host tools, never a plugin script: a headless browser screenshot for a page and a LibreOffice PDF export rasterized per slide for a deck, with the commands in `${CLAUDE_PLUGIN_ROOT}/docs/design-verify-proof.md` §Reproduce it.
3. Review each capture and the deck as a whole under the rules below, recording each observation as a finding with a criterion, a severity (`critical`, `major`, `minor` or `note`), a code and a description. A critical finding names one of the critical classes. The entry shape `check-review` and `verify --review` expect is in `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md` §Review record. The committed `${CLAUDE_PLUGIN_ROOT}/docs/design-verify-proof/review-record.json` is a worked record that passes `check-review`; copy its entry shape, and never add a bare verdict key such as `overall`, `quality` or `score`, which the check rejects at any depth.
4. Run `verify --review <review-record.json>` so the review's critical and major findings join the report. For a proof, first run `check-review --record <review-record.json> --proof <proof-manifest.json>`: it checks the record's coverage and digests against the proof manifest, which a single render does not have.
5. When verification fails, run `render-verified` instead of hand-editing anything: it tries the other variants of the failing unit's pattern within the budget and returns either a passing render or a bounded failure with the repair history.
6. For a proof, run `check-specimens` and `check-proof`; `check-proof` recomputes every recorded hash and re-reads each report, the review and the specimen index.

## Review rules

Inspect every unit at full resolution, on every target and brand, before recording its review entry.

Review one deck overview per brand and target, in addition to the per-unit entries.

An open critical finding blocks success: no count, average or pass rate outweighs it.

Never record an unqualified quality verdict; every finding names its criterion, unit, target and brand.

A repair never alters frozen content: it changes only pattern, variant and slot names, and the content fingerprint stays identical.

A contact sheet alone misses a clipped line inside one unit, and full-resolution images alone miss the rhythm of the whole deck, which is why both views are required. The deterministic checks prove content and structure; the review judges appearance, and its record is what makes that judgement traceable to the artifact it looked at.

When reporting a result, name the verdict, each open finding with its unit, target and brand, the accessibility capabilities reported `unsupported` with their reasons, the geometry coverage, and whether a visual review record was folded in with `--review` — without one, say the verdict covers the deterministic checks only and appearance was not judged; say plainly when page geometry was checked statically because no measurement report was supplied.

For example: "The boardroom deck fails verification with one open critical finding, `frames-overlap` (overlap) on unit `u-answer`, target pptx, brand boardroom: the body frame sits on the title. Slide titles are reported `unsupported`, because the writer places every headline in a named text shape rather than a title placeholder. Deck geometry was checked from the package. The boardroom page passes, and its geometry was checked statically, because no measurement report was supplied. No visual review was folded in, so appearance was not judged."

## Commands

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" verify --target <html|pptx> --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --artifact <index.html|deck.pptx> [--manifest <pptx-manifest.json>] [--review <review-record.json>] [--browser-report <browser-report.json>] [--out <verification.json>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" preserve --target <html|pptx> --brief <normalized.json> --composition <composition.json> --artifact <file>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" editability --brief <normalized.json> --composition <composition.json> --pptx <deck.pptx>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" accessibility --target <html|pptx> --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --artifact <file> [--capabilities <declaration.json>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" geometry --target <html|pptx> --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --artifact <file> [--browser-report <browser-report.json>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" render-verified --target <html|pptx> --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --out <dir> --generated-at <YYYY-MM-DDTHH:MM:SSZ> --run-id <id> [--budget <0-10>] [--language <code>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" check-review --record <review-record.json> --proof <proof-manifest.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" check-specimens --index <specimens.json> --proof <proof-manifest.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-verify.py" check-proof --manifest <proof-manifest.json>
```

`render-verified` renders through `design-render` itself, verifies, and writes nothing on a bounded failure; on success it writes the render's outputs plus `composition.json` (the composition it rendered), `verification.json` and `repair-history.json`. Pass it the `generated_at` and `run_id` the first render recorded in its `provenance.json`, or another fixed pair, so every attempt is reproducible.

The repair budget defaults to 3 and is never more than 10; a repair past the budget is never attempted.

## Read the result

Every command prints one JSON envelope, `{"success", "data", "error"}`: exit 0 success, 1 a finding, 2 a usage or runtime problem. Act by class:

- **A preservation difference** (`copy-differs`, `data-differs`, `sources-differs`, `evidence-differs`, `notes-differs`, `order-differs`) — the delivered file no longer shows the frozen content. Re-render from the inputs; never edit the file, and never change the brief to match the file.
- **`flattened-substitution` or `witness-failed`** — copy or a chart reached the deck as something other than native text or a native chart, or an edit did not read back. Re-render; a picture is admitted only where the unit's variant declares a pptx fallback.
- **An accessibility failure** — a required capability of the target failed: reading order, a missing text alternative (`description-missing`), contrast below the required ratio, or a series told apart by colour alone. Contrast is computed from the brand's tokens, so fix the brand through `manage-themes`; fix anything else upstream and re-render. An `unsupported` capability is declared per target in `${CLAUDE_PLUGIN_ROOT}/references/verify-capabilities.json` and is never tuned to make a run pass.
- **A critical class** — `clipping`, `overlap`, `missing-glyph`, `unreadable-text` or `misleading-encoding`. Run `render-verified`; when it returns `repair-exhausted`, the content does not fit any eligible variant, and the fix belongs upstream in the brief or the composition, or in the other target.
- **A review, specimen or proof finding** (`review-incomplete`, `unqualified-verdict`, `specimen-unresolved`, `proof-hash-mismatch`, …) — the persisted record is incomplete or stale. Complete the review or re-record the proof from the documented commands; never hand-edit a recorded digest.

Every code is defined in `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md`.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md` | explaining a finding, the report shape, the critical classes, the review record, the specimen index, the proof manifest or the repair budget |
| `${CLAUDE_PLUGIN_ROOT}/references/verify-capabilities.json` | checking which accessibility capabilities a target declares required or unsupported, and which token pairs it paints |
| `${CLAUDE_PLUGIN_ROOT}/docs/design-verify-proof.md` | reproducing the two-brand proof, reading its evidence, or finding the host capture commands a review uses |

## Boundaries

- The scripts are stdlib only, and every input is a path the caller supplies: no environment, home directory, network, model credential or cogni-workspace, and nothing is installed. The review's captures use host tools, as step 2 says.
- Never edit a delivered page, deck, plan, manifest, provenance or report to make a check pass; re-render from the inputs.
- Never rewrite, shorten, split or reorder copy to make content fit, and never hand a finding to a copywriting skill: after the freeze the content is fixed, and only the presentation choices a repair names may change.
- A clean LibreOffice or browser capture is evidence about appearance, not about how Microsoft PowerPoint opens a deck; application results belong in `${CLAUDE_PLUGIN_ROOT}/docs/pptx-smoke-evidence.md`.
