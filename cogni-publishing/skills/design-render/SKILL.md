---
name: design-render
description: This skill should be used to create a branded HTML page or editable PPTX deck from a validated publishing composition — "render this composition", "render the composition as HTML", "render branded HTML from the composition", "render the composition as an editable PPTX", or "design-render". For PPTX it hands the frozen brief, composition and theme to the presentation skill the host provides, then admits the result only through design-verify; HTML follows the DOM contract design-verify reads. It also handles explicitly qualified renderer diagnostics — "run the renderer fidelity check", "diagnose a render failure", and "measure the rendered page". Creation preserves frozen copy, data and order and runs design-verify before reporting success. Independent checks of an existing deliverable against frozen inputs or before handover belong to design-verify. Optional browser measurement uses the provisioned pinned runtime.
---

# Design Render

Turn a validated `semantic-composition@2` into a client-grade deliverable and hand back its files. The platform route delegates PPTX creation to the host presentation skill; HTML follows this plugin's DOM contract. On every route, design-verify independently gates handover. Never edit a rendered page, deck or composition to make a check pass: frozen copy, unit order and source lineage are exactly what they protect.

Every delivery contains the native artifact, platform provenance, independent verification and visual review.

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file.
- **A semantic composition** — the `data` of a successful `design-compose` `compose` run whose `targets` include the target to render.
- **A theme** — the `theme_path` from the `manage-themes` selection handoff, or a theme directory. Its directory name must equal the composition's `design_system.name`, and it must ship the authoritative `tokens/*.json` carrying the token roles listed in `${CLAUDE_PLUGIN_ROOT}/references/design-render.md`; the pptx target also needs its colour tokens in hex. Every bundled theme qualifies; a tier-0 theme (`theme.md` only) derives its tokens through `manage-themes` Operation 7. A theme may also ship licensed faces, one per weight of a family, declared in its `assets/fonts/faces.json` beside each face's licence; the html target embeds every face of the copy family, each under its declared weight (declaration fields: `design-render.md` §Fonts). The bundled `cogni-work` theme ships DM Sans Regular and Bold.
- **The language** — taken from the brief's metadata; pass `--language` for a direct brief that does not state one (for example `--language de`).
- **The narrative** — optional context only. Never use it as a source of deliverable copy.

## Platform route — PPTX

### Resolve the host presentation skill

Resolve by host, in this order. On Codex, select the bundled `presentations:Presentations` skill even when `document-skills:pptx` is installed. On an Anthropic host, select its installed `anthropic-skills:pptx` or `document-skills:pptx` capability. On another host, select an installed skill whose description explicitly claims `.pptx` creation. Rely on the host's normal description-based skill triggering; do not create or consult a renderer registry. Load the selected theme as the design system. Its token files under `tokens/`, their compiled `tokens.resolved.json` when present, `assets/fonts/faces.json` when shipped, and `theme.md` are authoritative when another brand skill disagrees. Resolve semantic dark-surface roles to existing theme colors: use explicit `bg-dark` / `text-on-dark` tokens when present; otherwise map them to the theme's existing `primary` / `bg` colors and record that mapping in provenance and visual review. Invent no color.

When no presentation skill is available, return exactly `{"success": false, "error": "platform_renderer_unavailable"}`. Write no artifacts and install nothing.

### Build the slide plan

- Preserve composition order: one slide per composition unit, with `sources` last. When the normalized brief has a document title or subtitle, prepend exactly one slide named `document` carrying those frozen fields as `copy:document#title` and `copy:document#subtitle`; this is the cover the verifier expects. Otherwise the first composition unit is slide 1. Add no invented cover copy.
- Keep each frozen headline as an assertion and map one communication objective to the slide. Translate `visual_intent` into the relationship and focal point it names; avoid decorative icons, stock imagery, arbitrary metaphors, repeated card grids, pills, and template monoculture.
- Render every `key_figures` item as a hero figure. Render `design.dark_slides` and the `climax` unit on `bg-dark` with `text-on-dark`. Render `evidence_status` as a quiet uppercase tag and put `talk_track` in speaker notes.
- Solve fit through layout, composition, and accessible type. Never edit frozen copy or silently correct it.

### Hand-off contract

Pass these clauses, the normalized brief, the composition, and the theme directory to the resolved skill:

1. Reproduce every frozen record exactly by id: wording, character order, punctuation, capitalization, numbers, qualifiers, evidence labels, citation identities, and notes. Invent no text and take no copy from the narrative.
2. Represent each copy key as exactly one native text object named `copy:<record-id>#<field>` through the presentation skill's object-name option. Keep a multi-item text binding in that one object as separate paragraphs. For system entities that require distinct native shapes, expand the list binding to one object per frozen item named `copy:<record-id>#<field>#<zero-based-index>`, preserving item order; do not also emit the whole-list object. Never split an individual copy key across shapes or render copy as a picture.
3. Name the slide's unit object with its composition unit id so order can be read back.
4. Write `talk_track` through the presentation skill's notes API, complete and verbatim.
5. Make each citation a hyperlink whose target equals its source URL byte for byte. Keep a source without a URL as text.
6. Use only palette and typefaces from the resolved theme tokens. Honor the hero-figure, dark-surface, and quiet-tag instructions above.
7. Use the brief's values, units, and labels for native charts. Invent no value, decorative percentage, or unsupported precision.
8. Use no autofit or shrink-to-fit; leave nothing hidden or off-slide; include no placeholder, prompt fragment, debug label, template remnant, or picture of copy.

### Gate and bounded repair loop

Run `design-verify.py verify --target pptx` against the normalized brief, composition, theme, and delivered deck. Do not pass a `pptx-manifest.json`: platform decks are inventoried from the package. Review every slide at full resolution under `references/visual-qa.md` and fold the record into verification.

If verification fails, re-invoke that same selected presentation skill, not a different renderer, with every finding returned verbatim and an instruction to change nothing else. Count each re-invocation as one repair attempt. The repair budget defaults to 3 and is never more than 10. Never make more re-invocations than the budget. When the budget is spent, report a bounded failure carrying the last attempt's findings verbatim; never report success or hand over those files.

Run `design-verify.py preserve` before handover and require an empty frozen-copy diff. Check the brief content fingerprint before the first attempt and after the last; any change is a defect, not a repair.

Write `provenance.json` beside the deck with `renderer: {"kind": "platform", "name": <resolved skill>, "version": <skill version or marketplace commit>}` and `reproducible: false`. Record the host and run identity, frozen brief/composition/theme inputs, every attempt and its findings, per-attempt preserve result, before/after content fingerprint and ordered unit ids, applicable theme/font/runtime evidence, review record digest, and every output digest. Report the deck path, slide count, theme, renderer identity, substitutions, verify verdict, and review coverage. Never present an outline, PDF, or image sequence as the deck.

## Platform route — HTML

Author one `section[data-unit][data-pattern]` per composition unit in order. Put slot content in `data-slot` elements in reading order, every frozen field in one `data-copy` element, dataset values in `data-value`, and citations and source-register entries in `data-source` elements whose links equal the source URL. Use only theme custom properties for color and type. Include no hidden, clamped, clipped, scripted, remote, or file-referenced content. Gate the page with `design-verify.py verify --target html` and the same bounded loop and fingerprint rules.

## Verify before reporting

Never rewrite, shorten, add, drop or reorder copy or units to make a unit fit, and never hand a finding to a copywriting skill.

After every render, run design-verify on the output and report success only when its verdict passes.
When verification fails, repair within the budget and report the findings and repair history of a bounded failure, never a success.

For an automated host integration, pass an explicit JSON argv array as `--platform-command` to `design-verify.py render-verified`. The command forwards the frozen inputs and previous findings to the same host bridge on every attempt. It does not discover skills, install dependencies or select a fallback. Without a bridge it returns `platform_renderer_unavailable` and writes nothing. The skill-driven route above invokes the selected host capability directly.

Report the native artifact path, renderer identity, theme, font substitutions, preservation result, verification verdict and review coverage. Describe any non-editable fallback and its reason. Browser evidence is collected separately with `design-render.py measure`; its pinned runtime must already be provisioned.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/skills/design-render/references/visual-qa.md` | reviewing a platform render and mapping each hand-off clause to its falsifier |
| `${CLAUDE_PLUGIN_ROOT}/skills/design-render/agents/openai.yaml` | checking the Codex discovery prompt for `$design-render` |
| `${CLAUDE_PLUGIN_ROOT}/references/layout-contract.md` | implementing or checking the HTML DOM contract |
| `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` | the host bridge contract, provenance admission and measurement runtime |
| `${CLAUDE_PLUGIN_ROOT}/references/font-fallbacks-v1.json` | checking the order in which a theme-shipped face, a bundled face and a generic chain resolve, and which Office typeface a deck uses |
| `${CLAUDE_PLUGIN_ROOT}/references/render-provenance-v1.schema.json` | checking the provenance record's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` | the version compatibility matrix and the shared finding codes |
| `${CLAUDE_PLUGIN_ROOT}/references/design-verify.md` | verifying a rendered output after the render, the repair budget, and the findings `verify` and `render-verified` report |

## Boundaries

- The platform route invokes a host skill but copies none of its prose, scripts, or license material into this plugin. Provenance records the resolved host skill and marks its output non-reproducible.
- Host resolution is a model decision; the design-verify gate, not the resolution choice or the host skill's own verdict, admits a deliverable.
- A page has no script, remote asset, font download or file reference: it opens as a single file, offline. A deck links out only through citation hyperlinks and embeds only the chart workbooks and declared fallback pictures its provenance lists by digest.
- A theme may ship a licensed face; the page embeds its bytes as a data URI and sets copy in it, so it renders offline without a download. A deck embeds no font. A face nothing ships — and, on a deck, any shipped face — resolves to the documented generic chain, the deck names that family's documented Office typeface, and provenance records the substitution.
- Only the explicit `measure` command starts the provisioned, lockfile-pinned browser runtime. Rendering never installs it.
