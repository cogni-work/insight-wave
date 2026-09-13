---
name: design-render
description: This skill should be used when the user wants to turn a validated, pattern-bound publishing composition into a finished branded deliverable — "render this composition", "design-render", "render the composition as HTML", "render branded HTML from the composition", "lay out the semantic composition for the browser", "check the rendered HTML", "why did the render fail", or "measure the rendered page". It lays a semantic-composition@2 out as a target-resolved-plan@2 and renders its HTML target as one self-contained page with the theme's tokens, sourced charts, labelled system figures, linked citations and a closing source register, plus a provenance record of fonts, pins and fingerprints. Frozen copy is inserted as text and never rewritten, truncated or reordered. Rendering is standalone — no model API, no network, no Node and no cogni-workspace installation; an optional, separately pinned browser runtime only measures the result. It renders the html target only.
---

# Design Render

Render a validated `semantic-composition@2` for the HTML target and hand back three files: `target-plan.json` (the `target-resolved-plan@2`), `index.html` and `provenance.json`. The renderer and its checks are the authority. Never edit the rendered page, the plan or the composition to make a check pass: frozen copy, unit order and source lineage are exactly what they protect, and a fix belongs upstream in the brief, the composition or the theme.

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file.
- **A semantic composition** — the `data` of a successful `design-compose` `compose` run whose `targets` include `html`.
- **A theme** — the `theme_path` from the `manage-themes` selection handoff, or a theme directory. Its directory name must equal the composition's `design_system.name`, and it must ship the authoritative `tokens/*.json` carrying the token roles listed in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md`. The bundled `cogni-work` theme qualifies.
- **The language** — taken from the brief's metadata; pass `--language` for a direct brief that does not state one (for example `--language de`).

## Workflow

1. Confirm the composition passes `check-composition` (see `design-compose`). A composition that fails there fails here with the same finding.
2. Run `render --target html` with the brief, the composition, the theme and an output directory. The command validates everything first — composition, theme, fonts and, with `--measure`, the runtime — and writes nothing unless every check passes.
3. Read the envelope. On success, report the three output paths, the number of units and the font resolution: when `substituted` is true, name the requested face, the face used and the fallback chain, so the substitution is never silent.
4. When the user wants browser evidence, run `measure` on the page (or render with `--measure`). It loads the page offline in the pinned runtime and reports blocked or failed requests, clipped copy, DOM geometry and the platform fonts actually used.
5. To prove a re-render reproduces a captured result, run `compare` on the two plans (or two measurement reports). Only `generated_at` and `run_id` are ignored; any other change, and any box moved or resized beyond the stated tolerance, is drift.

## Commands

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" render --target html --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --out <dir> [--language <code>] [--measure]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-html --brief <normalized.json> --composition <composition.json> --html <index.html> [--theme <theme-dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-provenance --provenance <provenance.json> [--composition <composition.json>] [--plan <target-plan.json>] [--out-dir <dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" compare --expected <plan-or-report.json> --actual <plan-or-report.json> [--tolerance <px>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" measure --html <index.html> --out <browser-report.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-runtime-lock
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-plan --brief <normalized.json> --composition <composition.json> --plan <target-plan.json>
```

`render` runs the `check-html` fidelity checks on its own output before writing it, so a page that reaches disk has already passed them. Run `check-html` directly on a page someone else produced or edited.

## Read the result

Every command prints one JSON envelope, `{"success", "data", "error"}`: exit 0 success, 1 a contract or fidelity finding (`data.code`, `data.check`, `data.reference`, and `data.findings` for the checks), 2 a usage or runtime problem. Quote the code and reference, then act by class:

- **A composition finding** (`dangling-reference`, `target-geometry`, `copy-changed`, `fingerprint-mismatch`, …) — fix the composition through `design-compose`, never the rendered output.
- **`invalid-theme`** — the theme's slug does not match the pinned design system, it has no `tokens/`, or a required token role is missing (`data.reference` names it). Select a matching theme or add the token through `manage-themes`.
- **`font-unresolved`** — no member of the theme's font stack is bundled or a generic family. Add a generic family (`system-ui`, `sans-serif`, `serif`, `monospace`) to the end of the stack through `manage-themes`; never render with an unrecorded substitute.
- **`unresolved-citation`** — a `[N]` marker in the copy names no source. The fix belongs in the brief's Sources block.
- **`register-not-last`** — the source register must close the deliverable; reorder the composition in `design-compose`.
- **`unsupported-target`** — this renderer owns `html` only. Do not convert the HTML into another format.
- **A fidelity finding** from `check-html` (`copy-changed`, `copy-omitted`, `citation-missing`, `chart-semantics`, `description-missing`, `remote-asset`, `css-literal`, …) — the page is not a faithful rendering. Re-render from the inputs; never patch the page.
- **`runtime-missing` / `runtime-unpinned`** — `--measure` or `measure` needs the pinned runtime. Tell the user to provision it once with `bash ${CLAUDE_PLUGIN_ROOT}/runtime/provision.sh`; never install anything yourself, and never substitute a browser found elsewhere. A plain `render` does not need it.
- **`plan-drift`** — `data.differences` lists each changed path. A string or digest change means the content changed; a box change beyond the tolerance means the layout changed.

Every code is defined in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` and `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md`.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` | explaining a finding, the plan and provenance shapes, font resolution, the fidelity rules or the runtime boundary |
| `${CLAUDE_PLUGIN_ROOT}/references/font-fallbacks-v1.json` | checking which faces are bundled and which generic chain a font resolves to |
| `${CLAUDE_PLUGIN_ROOT}/references/target-resolved-plan-v2.schema.json` | checking the plan's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/render-provenance-v1.schema.json` | checking the provenance record's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` | the version compatibility matrix and the shared finding codes |

## Boundaries

- The HTML target only; the editable presentation target is a separate renderer, and HTML is never an intermediate for it.
- No script, remote asset, font download or file reference in the page: it opens as a single file, offline.
- No font file is bundled. A brand face the theme names but nothing ships resolves to the documented generic chain, and provenance records the substitution.
- Rendering never installs, starts or contacts the measurement runtime unless `--measure` is passed, and the runtime is only ever the provisioned, lockfile-pinned one.
