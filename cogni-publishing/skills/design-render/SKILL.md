---
name: design-render
description: This skill should be used when the user wants to turn a validated, pattern-bound publishing composition into a finished branded deliverable — "render this composition", "design-render", "render the composition as HTML", "render branded HTML from the composition", "export the composition as a standalone HTML page", "render the composition as an editable PPTX", "render the composition as a deck", "check the rendered HTML", "check the rendered PPTX", "why did the render fail", or "measure the rendered page". It lays a semantic-composition@2 out as a target-resolved-plan@2 and renders one of two sibling targets: html, a self-contained themed page, or pptx, an editable deck of native text, shapes, charts with embedded data and speaker notes, with per-object editability recorded in a manifest. Frozen copy is never rewritten, truncated, shrunk or reordered. Rendering is standalone: no model API, network, Node or cogni-workspace; an optional pinned browser runtime only measures an HTML page.
---

# Design Render

Render a validated `semantic-composition@2` for one of two sibling targets and hand back its files. The renderer and its checks are the authority. Never edit a rendered page, deck, plan, manifest or the composition to make a check pass: frozen copy, unit order and source lineage are exactly what they protect, and a fix belongs upstream in the brief, the composition or the theme.

| Target | Writes |
|---|---|
| `html` | `target-plan.json` (the `target-resolved-plan@2`), `index.html`, `provenance.json` |
| `pptx` | `target-plan.json`, `deck.pptx`, `pptx-manifest.json` (the `pptx-manifest@1`), `provenance.json` |

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file.
- **A semantic composition** — the `data` of a successful `design-compose` `compose` run whose `targets` include the target to render.
- **A theme** — the `theme_path` from the `manage-themes` selection handoff, or a theme directory. Its directory name must equal the composition's `design_system.name`, and it must ship the authoritative `tokens/*.json` carrying the token roles listed in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md`; the pptx target also needs its colour tokens in hex. The bundled `cogni-work` theme qualifies.
- **The language** — taken from the brief's metadata; pass `--language` for a direct brief that does not state one (for example `--language de`).

## Workflow

1. Confirm the composition passes `check-composition`, the `design-compose` skill's command. `render` repeats that validation first, so a composition that fails there fails here with the same finding.
2. Run `render --target html` or `render --target pptx` with the brief, the composition, the theme and an output directory. The command validates everything first — composition, theme, fonts, and for pptx the slide fit and the copy itself — renders, runs the target's fidelity checks on its own output, and writes nothing unless every check passes.
3. Read the envelope. On success, report the output paths, the number of units and the font resolution: when `substituted` is true, name the requested face, the face used and — for html the fallback chain, for pptx the Office typeface the deck is written in — so the substitution is never silent. When a font's `source` is `theme`, say the page embeds that face, which the theme ships.

   A deck has one slide per unit, preceded by a cover slide when the brief has a document title or subtitle. For example: "Rendered 3 units to out/ as an editable deck: deck.pptx with 4 slides, 18 native objects and no fallback, plus target-plan.json, pptx-manifest.json and provenance.json. The theme asks for DM Sans, which it does not ship, so the deck is set in Arial, the documented typeface for system-ui, and the manifest records the substitution."

   For a page: "Rendered 3 units to out/ as a standalone page: index.html, target-plan.json and provenance.json. The theme asks for DM Sans, which it does not ship, so the page is set in the system-ui chain — system-ui, then sans-serif — and provenance records the substitution."
4. When handing over a deck, tell the user where its editable parts live: the native chart's data opens with the application's Edit Data command, speaker notes sit in the notes pane, and every citation whose source has a URL is a hyperlink to exactly that URL. Rendering a deck never needs the browser runtime.
5. When the user wants browser evidence for a page, run `measure` on it (or render the html target with `--measure`). It loads the page offline in the pinned runtime and reports blocked or failed requests, clipped copy, DOM geometry and the platform fonts actually used.
6. To prove a re-render reproduces a captured result, run `compare` on the two plans (or two measurement reports). Only `generated_at` and `run_id` are ignored; any other change, and any box moved or resized beyond the stated tolerance, is drift. A deck is also byte-identical across re-renders of the same inputs, so its digest reproduces.
7. To audit a delivered bundle, run `check-provenance` on its `provenance.json`; add the composition, the plan and the output directory to also check the content fingerprint, the output digests and, for a deck, that the manifest names the same writer and package. To grade a deck someone else produced or edited, run `check-pptx`; for a page, `check-html`. To confirm the runtime pin before provisioning or measuring, run `check-runtime-lock`.

## Commands

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" render --target html --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --out <dir> [--language <code>] [--measure]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" render --target pptx --brief <normalized.json> --composition <composition.json> --theme <theme-dir> --out <dir> [--language <code>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-html --brief <normalized.json> --composition <composition.json> --html <index.html> [--theme <theme-dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-pptx --brief <normalized.json> --composition <composition.json> --pptx <deck.pptx> [--manifest <pptx-manifest.json>] [--theme <theme-dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-provenance --provenance <provenance.json> [--composition <composition.json>] [--plan <target-plan.json>] [--out-dir <dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" compare --expected <plan-or-report.json> --actual <plan-or-report.json> [--tolerance <px>] [--expected-html <index.html> --actual-html <index.html>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" measure --html <index.html> --out <browser-report.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/design-render.py" check-runtime-lock [--runtime-dir <dir>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-plan --brief <normalized.json> --composition <composition.json> --plan <target-plan.json>
```

`render` runs the target's checks on its own output before writing it, so a page or deck that reaches disk has already passed them.

## Read the result

Every command prints one JSON envelope, `{"success", "data", "error"}`: exit 0 success, 1 a contract or fidelity finding (`data.code`, `data.check`, `data.artifact`, `data.reference`, and `data.findings` for the checks), 2 a usage or runtime problem. Quote the code and reference, then act by class. `copy-changed` and `fingerprint-mismatch` each belong to more than one class, so route by the command that emitted the finding and by `data.artifact` or `data.check`, never by the code alone:

- **A composition finding** — `data.artifact` is `semantic_composition`, raised by `check-composition`, by `check-plan`, or by the validation `render` runs first (`dangling-reference`, `target-geometry`, `copy-changed`, `fingerprint-mismatch`, …). Fix the composition through `design-compose`, never the rendered output.
- **A plan finding** — `data.artifact` is `target_resolved_plan`, from `check-plan`: for example `copy-changed` with check `slot-content`, or `fingerprint-mismatch` with check `content-fingerprint`. The plan no longer matches its brief and composition. Re-render; never edit the plan.
- **`fit-overflow`** (pptx) — a unit needs more than one 1280 × 720 slide, a chart row would wrap, or a system's nodes outgrow their box; `data.reference` names the unit. A deck never shrinks type, splits, merges, truncates or reorders a unit to fit. Shorten or split the content upstream, choose a pattern variant that carries less, or render the html target, whose frames may grow.
- **`unsupported-content`** (pptx) — a bound string holds a character a package cannot carry as text, such as a control character; `data.reference` names the key. Fix the brief; never drop the character.
- **`invalid-theme`** — the theme's slug does not match the pinned design system, it has no `tokens/`, a required token role is missing, (pptx) a colour token is not hex, or (check `theme-font`) a shipped-face declaration names a path outside the theme, a missing file, a file that is not its declared font format, or no positive `advance_em`; `data.reference` names it. Select a matching theme or fix the theme through `manage-themes`.
- **`font-unresolved`** — no member of the theme's font stack is shipped by the theme, bundled or a generic family. Add a generic family (`system-ui`, `sans-serif`, `serif`, `monospace`) to the end of the stack through `manage-themes`; never render with an unrecorded substitute.
- **`unresolved-citation`** — a `[N]` marker in the copy names no source. The fix belongs in the brief's Sources block.
- **`register-not-last`** — the source register must close the deliverable; reorder the composition in `design-compose`.
- **`unsupported-target`** — this renderer owns `html` and `pptx` only. Do not convert one target's output into another format.
- **`unsupported-capability`** under check `target` — the composition does not request the target you asked for. Recompose through `design-compose` with that target listed; never convert the other target's output.
- **A fidelity finding** from `check-html` or `check-pptx` — each `data.findings[]` entry carries a `code` under a `check`: for example `copy-changed` or `copy-omitted` under `frozen-copy` or `notes` (even when the code also appears as a composition code), `citation-missing`, `chart-semantics`, `description-missing` under `description`, `remote-asset`, `local-reference`, `css-literal`, `unshipped-font`, `font-not-embedded` for a page, or `package-content-type`, `package-relationship`, `chart-native`, `chart-values`, `system-semantics`, `unreported-flattening`, `manifest-object`, `autofit`, `readability` for a deck. Copy that merely names a path or a tool is never a `local-reference`; that code means the page itself loads from a local path. The output is not a faithful rendering. Re-render from the inputs; never patch the page or the package.
- **A provenance or lock finding** — from `check-provenance` (`silent-substitution`, `font-unrecorded`, `fingerprint-mismatch` under check `fingerprint`, `output-digest`, `writer-mismatch`, …) or from `check-runtime-lock` (`range-pin`, `lock-mismatch`, `install-tracked`, …). Re-render from the inputs, or re-provision from the committed lockfile; never hand-edit `provenance.json`, `pptx-manifest.json`, `package.json` or the lockfile.
- **`runtime-missing` / `runtime-unpinned`** — `--measure` and `measure` need the provisioned, lockfile-pinned runtime, because a measurement is reproducible only against that exact engine. Ask the user to provision it once with `bash "${CLAUDE_PLUGIN_ROOT}/runtime/provision.sh"`. An implicit install, or a browser found elsewhere, would break the render path's no-install contract and make the measurement unrepeatable. A plain render of either target does not need the runtime; `--measure` with the pptx target is a usage error.
- **`measure-failed` / `render-incomplete`** — the runtime ran and failed, or an output was missing after the write. Report the error verbatim and re-run; never hand-write the missing output.
- **`plan-drift`** — `data.differences` lists each changed path. A string or digest change means the content changed; a box change beyond the tolerance means the layout changed.

Every code is defined in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` and `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md`.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` | explaining a finding, the plan, manifest and provenance shapes, font resolution, the fidelity rules of either target or the runtime boundary |
| `${CLAUDE_PLUGIN_ROOT}/references/font-fallbacks-v1.json` | checking the order in which a theme-shipped face, a bundled face and a generic chain resolve, and which Office typeface a deck uses |
| `${CLAUDE_PLUGIN_ROOT}/references/target-resolved-plan-v2.schema.json` | checking the plan's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/pptx-manifest-v1.schema.json` | checking a deck manifest's exact shape: per-object editability, fallbacks, fonts, brand, assets, writer |
| `${CLAUDE_PLUGIN_ROOT}/references/render-provenance-v1.schema.json` | checking the provenance record's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` | the version compatibility matrix and the shared finding codes |

## Boundaries

- Two sibling targets behind one wrapper and one plan: the deck is written straight from the plan, and HTML is never an intermediate for it.
- A page has no script, remote asset, font download or file reference: it opens as a single file, offline. A deck links out only through citation hyperlinks and embeds only the chart workbooks its manifest lists by digest.
- A theme may ship a licensed face; the page embeds its bytes as a data URI and sets copy in it, so it renders offline without a download. A deck embeds no font. A face nothing ships — and, on a deck, any shipped face — resolves to the documented generic chain, the deck names that family's documented Office typeface, and provenance and the manifest record the substitution.
- Every deck object is native and editable. A picture is allowed only as a fallback its unit's pattern declares for the pptx target, recorded in the manifest with its capability and reason; a picture the manifest does not record as a fallback is an `unreported-flattening` finding, and one whose recorded fallback its pattern does not declare is `undeclared-fallback`.
- Rendering never installs, starts or contacts the measurement runtime unless `--measure` is passed with the html target, and the runtime is only ever the provisioned, lockfile-pinned one.
