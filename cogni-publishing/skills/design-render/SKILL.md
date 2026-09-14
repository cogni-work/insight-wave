---
name: design-render
description: This skill should be used when the user wants to turn a validated, pattern-bound publishing composition into a finished branded deliverable — "render this composition", "design-render", "render the composition as HTML", "render branded HTML from the composition", "lay out the semantic composition for the browser", "check the rendered HTML", "why did the render fail", or "measure the rendered page". It lays a semantic-composition@2 out as a target-resolved-plan@2 and renders its HTML target as one self-contained page with the theme's tokens, sourced charts, labelled system figures, linked citations and a closing source register. It applies whenever a semantic-composition@2 with an html target needs to become a page. Frozen copy is inserted as text and never rewritten, truncated or reordered. Rendering is standalone — no model API, no network, no Node and no cogni-workspace installation; an optional, separately pinned browser runtime only measures the result. It renders the html target only.
---

# Design Render

Render a validated `semantic-composition@2` for the HTML target and hand back three files: `target-plan.json` (the `target-resolved-plan@2`), `index.html` and `provenance.json`. The renderer and its checks are the authority. Never edit the rendered page, the plan or the composition to make a check pass: frozen copy, unit order and source lineage are exactly what they protect, and a fix belongs upstream in the brief, the composition or the theme.

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file.
- **A semantic composition** — the `data` of a successful `design-compose` `compose` run whose `targets` include `html`.
- **A theme** — the `theme_path` from the `manage-themes` selection handoff, or a theme directory. Its directory name must equal the composition's `design_system.name`, and it must ship the authoritative `tokens/*.json` carrying the token roles listed in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md`. The bundled `cogni-work` theme qualifies.
- **The language** — taken from the brief's metadata; pass `--language` for a direct brief that does not state one (for example `--language de`).

## Workflow

1. Confirm the composition passes `check-composition`, the `design-compose` skill's command. `render` repeats that validation first, so a composition that fails there fails here with the same finding.
2. Run `render --target html` with the brief, the composition, the theme and an output directory. The command validates everything first — composition, theme, fonts and, with `--measure`, the runtime — and writes nothing unless every check passes.
3. Read the envelope. On success, report the three output paths, the number of units and the font resolution: when `substituted` is true, name the requested face, the face used and the fallback chain, so the substitution is never silent.

   For example: "Rendered 7 units to out/: target-plan.json, index.html and provenance.json. The theme asks for DM Sans, which is not bundled, so the copy is set in system-ui through the documented chain system-ui, sans-serif, and provenance records the substitution."
4. When the user wants browser evidence, run `measure` on the page (or render with `--measure`). It loads the page offline in the pinned runtime and reports blocked or failed requests, clipped copy, DOM geometry and the platform fonts actually used.
5. To prove a re-render reproduces a captured result, run `compare` on the two plans (or two measurement reports). Only `generated_at` and `run_id` are ignored; any other change, and any box moved or resized beyond the stated tolerance, is drift.
6. To audit a delivered bundle, run `check-provenance` on its `provenance.json`; add the composition, the plan and the output directory to also check the content fingerprint and the output digests. To confirm the runtime pin before provisioning or measuring, run `check-runtime-lock`.

## Commands

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" render --target html --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --out <dir> [--language <code>] [--measure]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-html --brief <normalized.json> --composition <composition.json> --html <index.html> [--theme <theme-dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-provenance --provenance <provenance.json> [--composition <composition.json>] [--plan <target-plan.json>] [--out-dir <dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" compare --expected <plan-or-report.json> --actual <plan-or-report.json> [--tolerance <px>] [--expected-html <index.html> --actual-html <index.html>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" measure --html <index.html> --out <browser-report.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-runtime-lock [--runtime-dir <dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-plan --brief <normalized.json> --composition <composition.json> --plan <target-plan.json>
```

`render` runs the `check-html` fidelity checks on its own output before writing it, so a page that reaches disk has already passed them. Run `check-html` directly on a page someone else produced or edited.

## Read the result

Every command prints one JSON envelope, `{"success", "data", "error"}`: exit 0 success, 1 a contract or fidelity finding (`data.code`, `data.check`, `data.artifact`, `data.reference`, and `data.findings` for the checks), 2 a usage or runtime problem. Quote the code and reference, then act by class. `copy-changed` and `fingerprint-mismatch` each belong to more than one class, so route by the command that emitted the finding and by `data.artifact` or `data.check`, never by the code alone:

- **A composition finding** — `data.artifact` is `semantic_composition`, raised by `check-composition`, by `check-plan`, or by the validation `render` runs first (`dangling-reference`, `target-geometry`, `copy-changed`, `fingerprint-mismatch`, …). Fix the composition through `design-compose`, never the rendered output.
- **A plan finding** — `data.artifact` is `target_resolved_plan`, from `check-plan`: for example `copy-changed` with check `slot-content`, or `fingerprint-mismatch` with check `content-fingerprint`. The plan no longer matches its brief and composition. Re-render; never edit the plan.
- **`invalid-theme`** — the theme's slug does not match the pinned design system, it has no `tokens/`, or a required token role is missing (`data.reference` names it). Select a matching theme or add the token through `manage-themes`.
- **`font-unresolved`** — no member of the theme's font stack is bundled or a generic family. Add a generic family (`system-ui`, `sans-serif`, `serif`, `monospace`) to the end of the stack through `manage-themes`; never render with an unrecorded substitute.
- **`unresolved-citation`** — a `[N]` marker in the copy names no source. The fix belongs in the brief's Sources block.
- **`register-not-last`** — the source register must close the deliverable; reorder the composition in `design-compose`.
- **`unsupported-target`** — this renderer owns `html` only. Do not convert the HTML into another format.
- **A fidelity finding** from `check-html` — `data.findings[].check` names the rule: `copy-changed` under `frozen-copy`, `copy-omitted`, `citation-missing`, `chart-semantics`, `description-missing`, `remote-asset`, `css-literal`, …. The page is not a faithful rendering, even when the code also appears as a composition code. Re-render from the inputs; never patch the page.
- **A provenance or lock finding** — from `check-provenance` (`silent-substitution`, `font-unrecorded`, `fingerprint-mismatch` under check `fingerprint`, `output-digest`, …) or from `check-runtime-lock` (`range-pin`, `lock-mismatch`, `install-tracked`, …). Re-render from the inputs, or re-provision from the committed lockfile; never hand-edit `provenance.json`, `package.json` or the lockfile.
- **`runtime-missing` / `runtime-unpinned`** — `--measure` and `measure` need the provisioned, lockfile-pinned runtime, because a measurement is reproducible only against that exact engine. Ask the user to provision it once with `bash "${CLAUDE_PLUGIN_ROOT}/runtime/provision.sh"`. An implicit install, or a browser found elsewhere, would break the render path's no-install contract and make the measurement unrepeatable. A plain `render` does not need the runtime.
- **`measure-failed` / `render-incomplete`** — the runtime ran and failed, or an output was missing after the write. Report the error verbatim and re-run; never hand-write the missing output.
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
