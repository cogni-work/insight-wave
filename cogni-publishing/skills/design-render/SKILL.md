---
name: design-render
description: This skill should be used to create a branded HTML page or editable PPTX deck from a validated publishing composition — "render this composition", "render the composition as HTML", "render branded HTML from the composition", "render the composition as an editable PPTX", or "design-render". For PPTX it hands the frozen brief, composition and theme to the presentation skill the host provides, then admits the result only through design-verify; HTML follows the DOM contract design-verify reads. It also handles explicitly qualified renderer diagnostics — "run the renderer fidelity check", "diagnose a render failure", and "measure the rendered page". Creation preserves frozen copy, data and order and runs design-verify before reporting success. Independent checks of an existing deliverable against frozen inputs or before handover belong to design-verify. The temporary stdlib route renders offline without network or workspace setup; optional browser measurement uses the provisioned pinned runtime.
---

# Design Render

Turn a validated `semantic-composition@2` into a client-grade deliverable and hand back its files. The platform route delegates PPTX creation to the host presentation skill; HTML follows this plugin's DOM contract. The stdlib route remains as a temporary offline fallback until its retirement issue lands. On every route, design-verify independently gates handover. Never edit a rendered page, deck, plan, manifest or composition to make a check pass: frozen copy, unit order and source lineage are exactly what they protect.

| Target | Writes |
|---|---|
| `html` | `target-plan.json` (the `target-resolved-plan@2`), `index.html`, `provenance.json` |
| `pptx` | `target-plan.json`, `deck.pptx`, `pptx-manifest.json` (the `pptx-manifest@1`), `provenance.json` |

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file.
- **A semantic composition** — the `data` of a successful `design-compose` `compose` run whose `targets` include the target to render.
- **A theme** — the `theme_path` from the `manage-themes` selection handoff, or a theme directory. Its directory name must equal the composition's `design_system.name`, and it must ship the authoritative `tokens/*.json` carrying the token roles listed in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md`; the pptx target also needs its colour tokens in hex. Every bundled theme qualifies; a tier-0 theme (`theme.md` only) derives its tokens through `manage-themes` Operation 7. A theme may also ship licensed faces, one per weight of a family, declared in its `assets/fonts/faces.json` beside each face's licence; the html target embeds every face of the copy family, each under its declared weight (declaration fields: `design-render.md` §Fonts). The bundled `cogni-work` theme ships DM Sans Regular and Bold.
- **The language** — taken from the brief's metadata; pass `--language` for a direct brief that does not state one (for example `--language de`).
- **The narrative** — optional context only. Never use it as a source of deliverable copy.

## Platform route — PPTX

### Resolve the host presentation skill

Prefer the first installed presentation skill in this order: `anthropic-skills:pptx` or `document-skills:pptx` on Claude Code, the bundled `Presentations` skill on Codex, then any installed skill whose description claims `.pptx` creation. Rely on the host's normal description-based skill triggering; do not create or consult a renderer registry. Load the selected theme as the design system. Its `tokens.resolved.json`, `assets/fonts/faces.json`, and `theme.md` are authoritative when another brand skill disagrees.

When no presentation skill is available, return exactly `{"success": false, "error": "platform_renderer_unavailable"}`. While the stdlib route remains installed, name it as the available fallback; never report the platform route as successful.

### Build the slide plan

- Preserve composition order: one slide per composition unit, with the first unit on slide 1 and `sources` last. Add no standalone cover.
- Keep each frozen headline as an assertion and map one communication objective to the slide. Translate `visual_intent` into the relationship and focal point it names; avoid decorative icons, stock imagery, arbitrary metaphors, repeated card grids, pills, and template monoculture.
- Render every `key_figures` item as a hero figure. Render `design.dark_slides` and the `climax` unit on `bg-dark` with `text-on-dark`. Render `evidence_status` as a quiet uppercase tag and put `talk_track` in speaker notes.
- Solve fit through layout, composition, and accessible type. Never edit frozen copy or silently correct it.

### Hand-off contract

Pass these clauses, the normalized brief, the composition, and the theme directory to the resolved skill:

1. Reproduce every frozen record exactly by id: wording, character order, punctuation, capitalization, numbers, qualifiers, evidence labels, citation identities, and notes. Invent no text and take no copy from the narrative.
2. Represent each copy key as exactly one native text object named `copy:<record-id>#<field>` through the presentation skill's object-name option. Keep multi-item fields in that one object as separate paragraphs; never split a key across shapes or render copy as a picture.
3. Name the slide's unit object with its composition unit id so order can be read back.
4. Write `talk_track` through the presentation skill's notes API, complete and verbatim.
5. Make each citation a hyperlink whose target equals its source URL byte for byte. Keep a source without a URL as text.
6. Use only palette and typefaces from the resolved theme tokens. Honor the hero-figure, dark-surface, and quiet-tag instructions above.
7. Use the brief's values, units, and labels for native charts. Invent no value, decorative percentage, or unsupported precision.
8. Use no autofit or shrink-to-fit; leave nothing hidden or off-slide; include no placeholder, prompt fragment, debug label, template remnant, or picture of copy.

### Gate and bounded repair loop

Run `design-verify.py verify --target pptx` against the normalized brief, composition, theme, and delivered deck. Do not pass a `pptx-manifest.json`: platform decks are inventoried from the package. Review every slide at full resolution under `references/visual-qa.md` and fold the record into verification.

If verification fails, re-invoke the same presentation skill with the findings listed verbatim and an instruction to change nothing else. The repair budget defaults to 3 and is never more than 10. When the budget is spent, report a bounded failure carrying the last attempt's findings; never report success or hand over those files.

Run `design-verify.py preserve` before handover and require an empty frozen-copy diff. Check the brief content fingerprint before the first attempt and after the last; any change is a defect, not a repair.

Write `provenance.json` beside the deck with `renderer: {"kind": "platform", "name": <resolved skill>, "version": <skill version or marketplace commit>}` and `reproducible: false`, plus the input fingerprint and output digest. Report the deck path, slide count, theme, renderer identity, substitutions, verify verdict, and review coverage. Never present an outline, PDF, or image sequence as the deck.

## Platform route — HTML

Author one `section[data-unit][data-pattern]` per composition unit in order. Put slot content in `data-slot` elements in reading order, every frozen field in one `data-copy` element, dataset values in `data-value`, and citations and source-register entries in `data-source` elements whose links equal the source URL. Use only theme custom properties for color and type. Include no hidden, clamped, clipped, scripted, remote, or file-referenced content. Gate the page with `design-verify.py verify --target html` and the same bounded loop and fingerprint rules.

## Temporary stdlib route

1. Confirm the composition passes `check-composition`, the `design-compose` skill's command. `render` repeats that validation first, so a composition that fails there fails here with the same finding.
2. Run `render --target html` or `render --target pptx` with the brief, the composition, the theme and an output directory. The command validates everything first — composition, theme, fonts, and for pptx the slide fit and the copy itself — renders, runs the target's fidelity checks on its own output, and writes nothing unless every check passes.
3. Read the envelope. When the render succeeds, verify it as §Verify before reporting says, and once verification passes, report the output paths, the number of units and the font resolution: when `substituted` is true, name the requested face, the face used and — for html the fallback chain, for pptx the Office typeface the deck is written in — so the substitution is never silent. When the copy font (`typography.font-sans`) has `source` `theme`, say the page embeds that family's faces, which the theme ships.

   A deck includes a cover when the brief supplies a document title or subtitle. Report, for example: "Rendered 3 units and a cover to deck.pptx, with native text, chart data and notes. The deck uses Arial as the recorded substitute. design-verify passes with no open finding." See `references/design-render.md` §Handover report examples for page and font variants.

4. When handing over a deck, tell the user where its editable parts live: the native chart's data opens with the application's Edit Data command, speaker notes sit in the notes pane, and every citation whose source has a URL is a hyperlink to exactly that URL. Rendering a deck never needs the browser runtime.
5. When the user wants browser evidence for a page, run `measure` on it (or render the html target with `--measure`). It loads the page offline in the pinned runtime and reports blocked or failed requests, clipped copy, DOM geometry and the platform fonts actually used.
6. To prove a re-render reproduces a captured result, run `compare` on the two plans (or two measurement reports). Only `generated_at` and `run_id` are ignored; any other change, and any box moved or resized beyond the stated tolerance, is drift. A deck is also byte-identical across re-renders of the same inputs, so its digest reproduces.
7. To audit a delivered bundle, run `check-provenance` on its `provenance.json`; add the composition, the plan and the output directory to also check the content fingerprint, the output digests and, for a deck, that the manifest names the same writer and package. To grade a deck someone else produced or edited, run `check-pptx`; for a page, run `check-html` with the `--theme` it was rendered with. Without it an embedded theme face cannot be told from any other `url()`, so the check fails closed. Before handing a page or deck over, grade it with design-verify instead: check-html and check-pptx re-run the render's own gate, while `verify` checks the file independently against the frozen brief and composition. To confirm the runtime pin before provisioning or measuring, run `check-runtime-lock`.

## Verify before reporting

After every render, run design-verify on the output and report success only when its verdict passes: its `verify` command checks the delivered file against the frozen brief and composition (for a deck, pass its `pptx-manifest.json` with `--manifest` so the manifest cross-checks run again), and the `design-verify` skill states the visual review it needs.

When verification fails, repair within the budget and report the findings and repair history of a bounded failure, never a success: `design-verify.py render-verified` tries the other variants of the failing unit's pattern and returns either a passing render or that bounded failure.

Never rewrite, shorten, add, drop or reorder copy or units to make a unit fit, and never hand a finding to a copywriting skill: after the freeze only presentation choices may change.

When `render-verified` returns a passing render, report its `data.changes` (each changed unit's pattern/variant before and after) and `repairs_used`, and name the `composition.json` it wrote beside the output as the composition the delivered file was rendered from. On a bounded failure, tell the user that the files the first render wrote failed verification and must not be handed over.

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

`render` runs the target's checks on its own output before writing it, so a page or deck that reaches disk has already passed them. The `verify` and `render-verified` commands and their flags are in the `design-verify` skill and `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md`.

## Read the result

Every command prints one JSON envelope, `{"success", "data", "error"}`: exit 0 success, 1 a contract or fidelity finding (`data.code`, `data.check`, `data.artifact`, `data.reference`, and `data.findings` for the checks), 2 a usage or runtime problem. Quote the code and reference, then act by class. `copy-changed` and `fingerprint-mismatch` each belong to more than one class, so route by the command that emitted the finding and by `data.artifact` or `data.check`, never by the code alone:

Route a composition problem to `design-compose`, a theme problem to `manage-themes`, and an artifact or plan fidelity problem to a re-render from the frozen inputs. Use `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` §Finding response guide for the per-code actions and exceptions. Do not shorten or split frozen copy to resolve fit failures; select a compatible presentation variant or report the bounded failure. Measurement needs the provisioned pinned runtime; a plain render does not.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/skills/design-render/references/visual-qa.md` | reviewing a platform render and mapping each hand-off clause to its falsifier |
| `${CLAUDE_PLUGIN_ROOT}/skills/design-render/agents/openai.yaml` | checking the Codex discovery prompt for `$design-render` |
| `${CLAUDE_PLUGIN_ROOT}/references/layout-contract.md` | implementing or checking the HTML DOM contract |
| `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` | explaining a finding, the plan, manifest and provenance shapes, font resolution, the fidelity rules of either target or the runtime boundary |
| `${CLAUDE_PLUGIN_ROOT}/references/font-fallbacks-v1.json` | checking the order in which a theme-shipped face, a bundled face and a generic chain resolve, and which Office typeface a deck uses |
| `${CLAUDE_PLUGIN_ROOT}/references/target-resolved-plan-v2.schema.json` | checking the plan's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/pptx-manifest-v1.schema.json` | checking a deck manifest's exact shape: per-object editability, fallbacks, fonts, brand, assets, writer |
| `${CLAUDE_PLUGIN_ROOT}/references/render-provenance-v1.schema.json` | checking the provenance record's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` | the version compatibility matrix and the shared finding codes |
| `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md` | verifying a rendered output after the render, the repair budget, and the findings `verify` and `render-verified` report |

## Boundaries

- The platform route invokes a host skill but copies none of its prose, scripts, or license material into this plugin. Provenance records the resolved host skill and marks its output non-reproducible.
- Host resolution is a model decision; the design-verify gate, not the resolution choice or the host skill's own verdict, admits a deliverable.
- Two sibling targets behind one wrapper and one plan: the deck is written straight from the plan, and HTML is never an intermediate for it.
- A page has no script, remote asset, font download or file reference: it opens as a single file, offline. A deck links out only through citation hyperlinks and embeds only the chart workbooks and declared fallback pictures its manifest lists by digest.
- A theme may ship a licensed face; the page embeds its bytes as a data URI and sets copy in it, so it renders offline without a download. A deck embeds no font. A face nothing ships — and, on a deck, any shipped face — resolves to the documented generic chain, the deck names that family's documented Office typeface, and provenance and the manifest record the substitution.
- Every deck object is native and editable, except a picture its unit's variant declares as its pptx fallback in the pattern library — today only the `feedback-loop` return track — which carries no copy and is recorded in the manifest with the declared capability and reason. When reporting such a deck, name the fallback and its reason rather than calling every object editable. A picture the manifest does not record as a fallback is an `unreported-flattening` finding, one whose recorded fallback the unit's variant does not declare is `undeclared-fallback`, and one without a text alternative is `description-missing`.
- Rendering never installs, starts or contacts the measurement runtime unless `--measure` is passed with the html target, and the runtime is only ever the provisioned, lockfile-pinned one.
