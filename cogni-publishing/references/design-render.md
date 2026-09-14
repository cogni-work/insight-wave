# Design render

The normative description of `design-render` and its two sibling targets, `html` and `pptx`. `scripts/design-render.py` is the entry point, `scripts/render_core.py` the target-neutral core, `scripts/html_adapter.py` and `scripts/pptx_adapter.py` the target adapters, and `scripts/render_checks.py` and `scripts/pptx_checks.py` their independent checks; `scripts/validate-publishing.py check-plan` enforces the plan contract. Shared finding codes are defined in [`artifact-contracts.md`](artifact-contracts.md).

## Position in the chain

```text
normalized-brief@1 ─┐                                   ┌─ html ─> index.html
semantic-composition@2 ─┼─render─> target-resolved-plan@2 ─┤
theme-artifact@1 (tokens) ─┘                              └─ pptx ─> deck.pptx + pptx-manifest@1
                                                  └──────────> render-provenance@1
```

The render validates the brief and composition through the publishing validator, resolves the theme and its fonts, lays every composition unit out for the requested target, renders the page or deck, runs that target's fidelity checks on it and only then writes. A rejection writes nothing. The two adapters are siblings: each reads the same plan, and neither ever produces the other's output.

## Operations

| Command | Needs | `data` on exit 0 |
|---|---|---|
| `render --target html` | brief, composition, theme, `--out` | the three output paths, unit count, content fingerprint, the font records, `layout_face`, `fidelity: passed` |
| `render --measure` | the same, plus the provisioned runtime; html target only | also `browser_report` and the measurement summary |
| `render --target pptx` | brief, composition, theme, `--out` | the four output paths, unit and slide counts, content fingerprint, the font records with their typeface, `layout_face`, object, editable-object and fallback counts, `package_sha256`, `fidelity: passed` |
| `check-html` | brief, composition, page, optional theme — required to admit a face the theme ships, since without it every `url()` stays a finding | `valid`, the number of copy keys |
| `check-pptx` | brief, composition, deck, optional manifest and theme | `valid`, the slide count, whether a manifest and theme were checked |
| `check-provenance` | provenance, optional composition, plan, output directory | `valid`, font count, `layout_face` |
| `compare` | two plans or two measurement reports | `equal`, the tolerance, the ignored fields |
| `check-runtime-lock` | optional runtime directory | `valid`, the pin |
| `measure` | a page and a report path, the provisioned runtime | the measurement summary |

Every command prints one `{"success", "data", "error"}` envelope and nothing on stderr: exit 0 success, 1 a contract or fidelity finding (`code`, `check`, `reference`, and `findings` for check commands), 2 a usage or runtime problem.

| Code | Meaning |
|---|---|
| `unsupported-target` | a target this renderer does not own; it renders `html` and `pptx` |
| `usage-error` | a usage problem, among them `--measure` with the pptx target (exit 2) |
| `fit-overflow` | pptx: a unit's plan frame is taller than the slide, a chart row's value would wrap, a chart's rows or a system's nodes outgrow their box, the cover does not fit, or (check `bounds`) a shape leaves the slide |
| `unsupported-content` | pptx: a bound string holds a character a package cannot carry as text — a control character other than tab and line feed, a carriage return, a lone surrogate, U+FFFE or U+FFFF |
| `invalid-theme` | the theme has no `theme.md`, its slug is not the composition's `design_system.name` (`theme-slug`), it has no `tokens/` or they do not compile (`theme-tokens`), a required token role is missing (`theme-token-missing`), or a length or ratio token is not one, or (pptx) a colour token is not `#RRGGBB` or `#RGB` hex (`theme-token-unit`), or a shipped-face declaration is malformed, names a path outside the theme or a missing file, a file without its format's signature, or no positive `advance_em` (`theme-font`) |
| `font-unresolved` | no member of a font stack is shipped by the theme (for the html target), bundled or a generic family; `reference` is the first requested family |
| `unresolved-citation` | a `[N]` marker in copy names no source record |
| `register-not-last` | a source register that is not the last unit |
| `runtime-missing` | a runtime-backed operation found no provisioned runtime; the error names `runtime/provision.sh` |
| `runtime-unpinned` | the provisioned runtime does not match the committed lockfile, pin or recorded interpreter |
| `measure-failed` | the runtime ran and failed |
| `render-incomplete` | an output is missing after the write |
| `plan-drift` | `compare` found a material difference; `differences` lists the paths |
| fidelity codes | `copy-omitted`, `copy-changed`, `copy-invented`, `invented-text`, `script`, `remote-asset`, `local-reference`, `truncating-css`, `hidden-copy`, `reordered-unit`, `description-missing`, `comparison-structure`, `chart-semantics`, `system-semantics`, `register-order`, `citation-missing`, `citation-unresolved`, `citation-substituted`, `token-block`, `css-literal`, `token-unused`, `unshipped-font`, `font-not-embedded` |
| pptx fidelity codes | `package-unreadable`, `package-duplicate`, `package-content-type`, `package-relationship`, `package-target`, `package-schema`, `remote-asset`, `local-reference`, `reordered-unit`, `register-not-last`, `copy-omitted`, `copy-changed`, `copy-invented` (checks `frozen-copy` and `notes`), `invented-text`, `text-outside-frame`, `chart-native`, `chart-values`, `system-semantics`, `citation-missing`, `citation-unresolved`, `citation-substituted`, `unreported-flattening`, `undeclared-fallback`, `description-missing` (check `fallback`), `manifest-invalid`, `manifest-object`, `manifest-editability`, `manifest-identity`, `autofit`, `readability`, `fit-overflow` (check `bounds`) |
| provenance codes | `font-unrecorded`, `silent-substitution`, `font-layout`, `runtime-unpinned`, `fingerprint-mismatch`, `design-system`, `output-digest`, `writer-mismatch` |
| lock codes | `range-pin`, `install-script`, `lock-missing`, `lock-mismatch`, `lock-unhashed`, `install-tracked` |

## Theme

The theme is a `theme-artifact@1` directory. Its name must equal the composition's pinned `design_system.name`; the pinned `version` is recorded in provenance and never compared with the plugin version, which changes on every release. Its `tokens/*.json` compile through `generate-tokens-css.py` and must carry these roles:

| File | Keys |
|---|---|
| `colors` | `text`, `bg`, `surface`, `accent`, `text-muted`, `border` |
| `typography` | `font-sans`; `size-display`, `size-h2`, `size-h3`, `size-body`, `size-small` in px; `line-height-display`, `line-height-h2`, `line-height-h3`, `line-height-body`, `line-height-small` as ratios |
| `spacing` | `3`, `4`, `5`, `6`, `7` in px |

A theme may also ship licensed font faces, declared in an optional `assets/fonts/faces.json`; §Fonts states how they resolve and what a declaration carries.

The page carries the compiler's `:root` token block verbatim, so every custom property equals the theme's token value. Component rules follow a `/* design-render: components */` marker and use `var()` only — no color, font-family or other brand literal.

## Type roles

| Role | Tokens |
|---|---|
| `type.display` | `size-display`, `line-height-display` |
| `type.heading` | `size-h2`, `line-height-h2` |
| `type.lead` | `size-h3`, `line-height-h3` |
| `type.body` | `size-body`, `line-height-body` |
| `type.caption` | `size-small`, `line-height-small` |

A slot starts at a default role — `answer` display; `claim` and `heading` heading; `support` lead; `context`, `items`, `entities`, `series` and `notes` body; `evidence` caption — and a canvas slot is raised to the pattern's `min_type_role`, or the unit's `type_floor`, when that is higher. Notes sit aside and are not raised.

## Fonts

[`font-fallbacks-v1.json`](font-fallbacks-v1.json) is the machine-readable resolution data. Every `typography.font-*` token is resolved by walking its stack in order:

1. for the html target, a family the theme ships resolves to that face, and the page embeds it;
2. a family in `bundled_faces` resolves to that face (the plugin bundles none; a face ships with the theme that uses it);
3. a generic family — `system-ui`, `sans-serif`, `serif`, `monospace` — resolves to its documented `chain`;
4. any other family is skipped and recorded;
5. a stack with no resolvable member fails as `font-unresolved`.

**Faces a theme ships.** A theme declares them in `assets/fonts/faces.json` as `{"faces": [...]}`. Each face carries `family` (a plain name of letters, digits, spaces, `_` and `-` that is not a generic keyword), `file` (a path relative to the theme directory), `format` (`truetype` or `opentype`), `advance_em` (a positive number) and `licence` (the path of the face's licence text, also inside the theme), and may carry `advance_em_derivation` saying how the metric was read. `resolve_theme` validates every declaration before anything is written: a path that is absolute, contains `..`, or resolves through a symlink to anything outside the theme, a file that does not exist, bytes that do not start with the format's signature (`00 01 00 00` or `true` for truetype, `OTTO` for opentype), or a missing or non-positive `advance_em` fails as `invalid-theme` with check `theme-font`. A theme is untrusted input and its face's bytes are copied into the artifact, so containment is part of the contract rather than a convenience. `advance_em` is declared data, because rendering is stdlib only and never parses a font. Derive it from the shipped file as the mean advance width of the glyphs U+0020 to U+007E map to, divided by `unitsPerEm` and rounded to three decimals; the suite re-derives the fixture face's value that way from the TrueType tables. A shipped face resolves only for a target that embeds it. The html target embeds the copy face, and only that face, as one `@font-face` whose `src` is a single `url(data:<type>;base64,…)` of the file's bytes with the matching `format()` hint (`font/ttf` with `truetype`, `font/otf` with `opentype`), placed before the token block and outside the component rules. The pptx target embeds no font, so there a shipped family is skipped like any unshipped one and the stack falls through to its generic family, recorded as a substitution. The theme's tokens digest does not cover font bytes, so a shipped face's record also carries `file_sha256`.

Provenance records, per token, `requested_stack`, `requested_family`, `resolved_face`, `substituted` (true whenever the resolved face is not the first requested family), `skipped`, `fallback_chain` and `source` — `theme` for a face the theme ships, `bundled` or `generic` — plus `file_sha256` for a `theme` source. A deck names a typeface rather than a family keyword, so the pptx target writes a resolved generic family as that family's documented `pptx_typeface` — a typeface Office ships — in the theme's font scheme and on every run, embeds no font, and records the typeface beside the resolution in its manifest. The page sets copy in `--render-font-copy`, the resolved chain, never in a skipped family, so a face installed on one machine cannot substitute silently; a shipped face leads that chain only because the page carries its bytes. Layout is computed with the resolved face's documented `advance_em`, every plan slot records it as `measured_with`, and provenance's `layout_face` must equal it.

## target-resolved-plan@2

A plan lays one composition out for one target on a `1280 × 720` px canvas. Units stack as frames in composition order; each frame is at least the canvas height and grows with its content. Within a frame, canvas slots follow the pattern's reading order top to bottom; notes are `placement: aside` with no box. Every slot records its `type_role`, `measured_with`, a deterministic line estimate and its `content` — the composition's own references: `{record_ref, field, digest}` for a binding, `{data_ref, digest}` for a chart point and `{source_ref, digest}` for a register entry, where a data or source digest is taken over the brief's record exactly as the composition's digests are. The plan carries no copy. `check-plan` enforces the full shape: see [`target-resolved-plan-v2.schema.json`](target-resolved-plan-v2.schema.json).

Line estimates never truncate: content that needs more lines gets a taller box. The page uses the plan's frame heights as minimum heights and its slot boxes to size the two SVG figures. Text outside a figure flows in the page and is never clipped. Its estimate is by character count: each paragraph takes `ceil(characters / n)` lines, where n is the number of characters of the resolved face's advance that fit the width. The browser wraps that text itself, and its boxes are only minimums.

SVG text does not wrap on its own, so each figure label is split by the word-aware rule under Text insertion below, and its estimate is the number of lines that split gives. Figure labels and flowing text are therefore estimated differently. Each label is estimated and drawn at the width it actually has:

- An **entity label** wraps at the node text width: the slot width, less the 260 px connector gutter that stays free right of the nodes, less `spacing-4` on each side. Each node is `lines × line height + 2 × spacing-4` tall, with `spacing-5` between nodes.
- A **chart label** wraps at its label column, 40 % of the slot width, less an 8 px gap before the marks. It is estimated from the data item's `label` alone. Each point's row is `max(lines × line height, 28 px) + spacing-3`.

The entities or series slot's box height is the sum of those nodes or rows, and its `lines` is the sum of the label lines. The SVG draws exactly those lines. A target adapter takes these widths and the line split from the core and never derives them itself. It draws them at the size they were measured at: entity labels, chart labels and value labels take the size token of their slot's own `type_role`, raised by `type_floor` when that is higher, and never a fixed size. Connector kind labels are chrome, not slot copy, and are drawn at `size-small`.

## render-provenance@1

`renderer` (name, plugin version, target), `runtime` (the committed manifest's exact dependency pins, the lockfile path and sha256, and whether this render used it — never for a deck), `design_system` (the composition's pin), `theme` (slug, sha256 of its resolved tokens), `inputs`, `content_fingerprint` (the brief's, which equals the composition's pinned fingerprint), `language`, `outputs` (path and sha256 of the plan and the artifact — `index.html` or `deck.pptx` — and, for a deck, of `pptx-manifest.json` as `manifest`), `fonts` (a shipped face's record also carries its file's `file_sha256`, which `check-provenance` requires as `font-unrecorded`), `layout_face`, `measurement` (null unless `--measure`), `generated_at` and `run_id`. See [`render-provenance-v1.schema.json`](render-provenance-v1.schema.json). `check-provenance` with `--out-dir` also rejects a deck bundle whose manifest names another writer or package than the provenance records (`writer-mismatch`).

## Fidelity rules

- **Text insertion.** Every original string enters the page through one escaping function, once, as text. Markdown characters stay visible; whitespace inside a string is kept (`white-space: pre-wrap`); nothing is trimmed, case-changed, normalized or reformatted. A number keeps the literal the brief wrote. A figure label is split into display lines before it is escaped, by the same rule its estimate counts. n is the number of characters per line the estimate uses. Each paragraph is filled word by word and breaks at a break space, meaning any whitespace character except the no-break spaces U+00A0, U+2007 and U+202F, before the first word that would not fit in n characters. At a break, the break spaces stay at the end of the line they follow and do not count toward that line's fit, so no continuation line starts indented. Spaces inside a line count. Only a word longer than n characters is cut: it starts a fresh line and is cut after every n characters, and its last piece may be followed by the next words. A paragraph break stays at the end of its line, and every paragraph, even an empty one, takes at least one line. Each line is then escaped once, so the lines join to the string exactly.
- **Copy keys.** A copy-bearing element carries `data-copy`: `<record>#<field>`, `<record>#<field>#<item>` for a list item, `data:<id>#label`, `source:<id>#raw` for a narrative source or `source:<id>#<field>` for each field of a direct source, `trailer#<n>` and `document#title` / `document#subtitle`. A value label carries `data-value="<id>"` and reads the literal, one space, and the unit verbatim. A key may appear more than once — a chart label also labels its table row — and every occurrence must equal the brief.
- **Chrome vocabulary.** Visible text outside copy is limited to `[n]` register-number links for sources a direct section names without a marker, and the pattern library's relationship-kind tokens on system connectors. Everything else visible is copy.
- **Citations.** A `[N]` marker in narrative copy links the source whose `marker` is `[N]`, to its `url` byte for byte. A source a direct section or data item names is linked from its unit as `[n]`, `n` its position in the Sources list. A source without a URL links its register entry.
- **Register.** The source register lists every source once in original order — a narrative source as its verbatim `raw` line, a direct source as its fields — and is the last unit.
- **Figures.** A chart is one SVG generated from data only: one mark per bound point, each with its own label and value label, and a data table as its text alternative. Chart marks share one zero baseline: a positive value extends right of it, a negative value left of it, and a baseline line is drawn when a negative value is present. One chart plots one unit of measure; a mixed-unit series is rejected upstream as `mismatched-unit`. A conceptual system is the same bounded SVG path: one labelled node per declared entity, one connector per relationship labelled with its kind, and an entity list as its text alternative. Each figure label is one copy-bearing `<text>` element whose `<tspan>` lines join with nothing between them; a line carries no copy key of its own. Every figure has `role="img"`, is named by `aria-labelledby` pointing at its claim, and is described by `aria-describedby` pointing at its alternative. Series and sides are told apart by text, never by color alone.
- **Portability.** The page has no script, no event handler, no `<link>`, no `src`, no `@import`, no CSS `url()` and no absolute or file path; fragment references resolve inside the page. The single exception to "no CSS `url()`" is a `data:` URI that is the whole `src` of an `@font-face`, carries the `format()` hint its type names, and decodes to the bytes of a face the rendering theme ships — judged against the theme's own files, so `check-html` admits it only with `--theme` and without one fails closed. A remote, protocol-relative or file `src`, a `url()` anywhere else (a `data:` one included), and `@import` stay `remote-asset`; a CSS `local()` asks the host for an installed face and is `local-reference`; an embedded payload that is not a shipped face is `unshipped-font`; and a copy face the theme ships that the page does not embed is `font-not-embedded`. Navigational `<a href>` links are exempt. The path, workspace and runtime scan reads only where a page can name something to load — `<style>` text and attribute values other than navigational links and the identity attributes (`id`, `class`, `data-*`, `aria-*`) that carry the brief's own ids and copy keys. Copy text is never scanned, so prose that names a path or a tool stays copy; `file:` counts only as a URL scheme, and `cogni-workspace`, `node_modules` and `ms-playwright` only as path segments. Nothing hides, clamps or clips copy: no `display: none`, `visibility: hidden`, `overflow: hidden`, `max-height`, `text-overflow: ellipsis` or `line-clamp`.

## The PPTX target

`render --target pptx` writes an editable deck straight from the same `target-resolved-plan@2`, with `target: pptx`; `check-plan` grades that plan exactly as it grades an HTML plan. The writer, `scripts/pptx_adapter.py`, is Python 3 stdlib: it writes the Office Open XML package directly and never calls the HTML adapter, a presentation library or a runtime. `scripts/pptx_checks.py` grades the package independently — it reads it with `zipfile` and `xml.etree`, derives every expectation from the brief and composition, and does not import the writer.

**Writer and capability test.** The issue that introduced this target named PptxGenJS as its pinned presentation library, unless a documented capability test supports an alternative. The stdlib OOXML writer replaces PptxGenJS, and `tests/test-design-render-pptx.sh` is its capability test: every run proves, from the package itself, each of the six pptx capabilities pattern-library@1 declares.

| Capability | Case | What the case proves from the package |
|---|---|---|
| `text-frame` | `drpx-06-frozen-copy` | every bound string is native text, `a:t` runs in the one `p:sp/p:txBody` its copy key names, and no text sits outside a shape's text frame |
| `hyperlink` | `drpx-13-citations-and-order` | every `[N]` marker and register URL is a hyperlink run whose External relationship targets its source URL byte for byte |
| `editable-shapes` | `drpx-11-editable-shapes` | one preset-geometry node shape per entity, and one `p:cxnSp` connector per relationship glued by `stCxn` and `endCxn` to exactly its two nodes |
| `native-chart` | `drpx-09-native-chart` | a native bar chart whose numeric cache and embedded workbook carry the brief's literal values and unit |
| `speaker-notes` | `drpx-12-notes-evidence` | each unit's notes on its notes slide, with the trailer notes closing the last |
| `picture-fallback` | `drpx-27-fallback-picture` | the one picture a variant declares as its pptx fallback: a `p:pic` whose primary blip is a PNG part and whose blip extension carries the SVG part, with a text alternative, on that variant's slide only |

Because nothing is installed, every PPTX guard runs wherever the suite runs, CI included. The writer's identity is design-render itself: the manifest records its name and the plugin version read at render time, and the running interpreter as `runtime`; the external `renderer` pin of `resolve-config` still describes an external `target-resolved-plan@1` renderer and is untouched.

**Slides and geometry.** A slide is the plan's 1280 × 720 px canvas — 12192000 × 6858000 EMU at 9525 EMU per px — and a px is ¾ pt, so sizes are written in hundredths of a point. The deck has one slide per composition unit in composition order, named by its unit id, preceded by a `document` cover slide when the brief has a document title or subtitle; the source register, when present, is the last slide. Every canvas slot becomes shapes at its plan box, in reading order.

**Colours.** The theme's `colors` tokens are written once, as the literal colours of the deck theme's colour scheme. Every slide, layout, master, notes and chart part reaches colour only through a scheme reference, so every colour a deck carries is a theme token. `drpx-23-theme-colours` holds the package to that. A declared fallback picture cannot reference the colour scheme, so its PNG and SVG parts carry the theme's `accent` token as a literal colour: still a theme token, but one that does not follow a later change of the deck's theme.

**Addressing copy.** Every copy-bearing object is a native text frame (`a:t` runs in `p:sp/p:txBody`) whose shape name addresses its content:

| Shape name | Carries |
|---|---|
| `copy:<record>#<field>` | one binding; a list field keeps one paragraph per item, except in a comparison's `items` or a system's `entities` slot, where each item is its own shape `copy:<record>#<field>#<item>` |
| `copy:document#title`, `copy:document#subtitle` | the cover slide's copy |
| `copy:data:<id>#label`, `value:<id>` | a chart point's label, and its literal value, one space and its unit, on the point's row |
| `register:<unit>` | the register, one paragraph per source in original order: a narrative source's verbatim `raw` line, or a direct source's `[n]` register number and its fields |
| `cites:<unit>` | chrome: `[n]` links for the sources a unit's records and data name without a marker, in the slide's bottom margin |
| `kind:<from>:<to>` | chrome: a relationship's kind token |
| `edge:<from>:<to>`, `rule:<key>`, `chart:<unit>` | a connector, a decorative accent rule and the chart frame; none carries text |
| `figure:<unit>` | a declared fallback picture (§Fallbacks); it carries no text, only its `descr` text alternative |

A paragraph's text is its runs' text with each `a:br` read as a line feed — the writer turns a line feed in copy into a line break and changes nothing else. Speaker notes go in the unit's notes slide, one paragraph per notes value; the composition's trailer notes follow on the last slide's notes. Evidence status is text on the slide, in its own frame. `docProps/core.xml` repeats the document title as file metadata.

**Citations.** A `[N]` marker in copy or notes becomes a hyperlink run on the marker itself; its relationship is `TargetMode="External"` and its `Target` is the source's `url` byte for byte, or an internal jump to the register slide for a source without one. The register links each URL the same way.

**The chart.** A sourced chart is one native bar chart in its own chart part, backed by an embedded workbook. Its categories are the brief's labels, its numeric cache the brief's literal numbers in order, and its series name the unit; the workbook carries the unit in `B1`, the labels in column A and the literals in column B, one row per point. The point's label and value are also native text on its row, so the frozen strings stay text on the slide. Each point's row is the one the plan measured for its label (§target-resolved-plan@2), and the rows stack from the top of the series box to its bottom. The label is one text frame at the box's left edge, exactly the chart label width wide with no inset, so the frame wraps the label where the plan did; the planned split is never written as line breaks or extra paragraphs. The value shares the row on one line, and the chart frame starts at the label column's right edge.

**Systems.** A conceptual system is one editable node shape per declared entity carrying its label, one `p:cxnSp` connector per relationship glued by `stCxn` and `endCxn` to exactly the two nodes it joins, in composition order, and one kind label per relationship. Each node is as tall as the plan measured its label, and its side insets leave exactly the node text width for the label to wrap in. A variant that declares a pptx fallback keeps every one of those native parts and adds its picture beside them: the `feedback-loop` variant adds its return track, from the last node back to the first, in the gutter left of the nodes, so the system check grades that slide exactly as it grades any other.

**Fit and readability.** A deck has fixed slides, so a unit the plan had to grow past 720 px fails as `fit-overflow`, as does a series value that would wrap out of its row, a chart whose rows or a system whose nodes outgrow their box, or a cover that does not fit. A series label that needs more lines is not a fit failure: it takes the taller row the plan gave it. The writer never shrinks type, splits, merges, truncates or reorders a unit, and never hands shrinking to the opening application: every text body carries `a:noAutofit`, no `a:normAutofit` or `fontScale` is written, and no run is set below the size of the type role its slot resolves to (§Type roles: the slot default raised to the pattern's `min_type_role` or the unit's `type_floor`; the cover title display and subtitle lead; a unit's `cites:` frame and a connector's `kind:` token, chrome, caption; notes body). `check-pptx` derives that floor per shape from the composition, the pattern library and the theme, never from the writer, and keeps the theme's caption size (`typography.size-small`) — the minimum the manifest records as `readability.min_sz` — as the backstop no run in any part may go below.

**Fallbacks.** Every object is native and editable, except a picture its unit's **variant** declares as its pptx fallback in the pattern library: a `fallback` of `target`, `capability` and `reason` on the variant (see [`design-composition.md`](design-composition.md)). Pattern-library@1 declares one, on `conceptual-system/feedback-loop`, with the capability `picture-fallback`; every other variant draws natively, so a deck without such a unit carries no picture, no picture media type and no media part — its bytes are those of a deck written before fallbacks existed. The writer reads the declaration from the loaded library and never restates it. It writes the picture as one `p:pic` named `figure:<unit>` whose primary `a:blip` embeds a PNG part and whose blip extension (`{96DAC541-7B7A-43D3-8B79-37D633B846F1}`) holds an `asvg:svgBlip` embedding the SVG part, both under `ppt/media/` with the `png` and `svg` media types. The SVG is the authoritative drawing; the PNG, which an application without SVG support shows instead, is a stdlib-drawn approximation of it — pixel-snapped, without antialiasing, at two pixels per canvas px. The picture carries no copy; its `descr` text alternative is the variant's `purpose` from the library. The manifest records it on its slide as an object of kind `image`, `editable: false`, the declared capability and a `fallback` equal to the library declaration, repeats it in `fallbacks`, and lists both media parts in `assets` by digest. `check-pptx` needs that manifest to accept such a deck, and grades the picture per variant: a picture no manifest entry names, an entry claiming native editability, or a fallback entry without capability or reason is `unreported-flattening`; a recorded fallback that is not exactly the declaration of the slide unit's variant is `undeclared-fallback` — a sibling variant of the same pattern admits no picture; a picture missing from `fallbacks` is `unreported-flattening`; and a picture without a `descr` is `description-missing`. No application result for a deck carrying a fallback is recorded until [`../docs/pptx-smoke-evidence.md`](../docs/pptx-smoke-evidence.md) records one.

**Determinism and integrity.** The package is written with fixed zip timestamps and attributes in a fixed part order and carries no volatile dates, so equal inputs give byte-identical decks and the digest in the manifest and provenance reproduces. Every XML part has its own content-type override, every internal relationship resolves to a part, every relationship id a part uses is declared, every element the writer uses carries the children the OOXML schema requires of it (`package-schema` — a structural subset of the schema, not a full validation), and the only external relationships are hyperlinks. The required-children rule exists because a lenient reader opens such a package while Microsoft PowerPoint offers to repair it: an empty `p:normalViewPr` in `viewProps.xml` did exactly that.

## pptx-manifest@1

The deck's manifest is renderer output like render-provenance@1, not a chain artifact. It records `package` (path and sha256), `slide_size`, `writer` (name, version, adapter), `runtime` (interpreter name and version), `design_system` (the composition's pin), `theme` (slug, tokens digest), `language`, `fonts` (the resolution records plus `typeface`), `readability` (the minimum size and its token), `assets` (part, sha256, kind and unit of every embedded part: `chart-workbook` under `ppt/embeddings/`, and `fallback-raster` and `fallback-vector` under `ppt/media/`), `slides` (part, name, unit, pattern, notes part and every object's shape id, name, kind, editable, capability, copy keys and fallback) and `fallbacks` (every image object, in slide order). `check-pptx` holds it to the package in both directions: every object on a slide is listed with its true kind and editability, every listed object exists, and every asset digest matches its part. See [`pptx-manifest-v1.schema.json`](pptx-manifest-v1.schema.json).

## Comparator

`compare` ignores only the top-level volatile fields `generated_at` and `run_id`. Numbers under a `box` or `frame` may differ by at most the tolerance, 0.5 px by default; every other value — ids, digests, strings, line estimates, list lengths — must be equal. The same comparator reads two measurement reports, whose geometry also sits under `box`.

## Runtime boundary

Rendering either target is Python 3 stdlib only (3.9 or newer) and needs no Node, browser, network, model API or cogni-workspace. The measurement runtime is separate: `runtime/package.json` pins `playwright-core` to an exact version, `runtime/package-lock.json` locks it with its registry URL and sha512 integrity, and that version pins its own Chrome Headless Shell build. It is provisioned only by `runtime/provision.sh`, run once per machine by an operator or, in CI, by its own step of the Plugin test suites job ahead of the sweep; the wrapper, the skills and the test suites never install anything. `provision.sh` records the interpreter it used in the gitignored `runtime/.provisioned.json`. The Node interpreter itself is a per-machine host dependency — node 20 or newer, found on PATH or named by `NODE` — and not part of the pin: the lockfile makes `playwright-core` and its browser build reproducible across machines, while the recorded interpreter path and version bind only later measurements on the same machine. Every measurement re-verifies that interpreter's version, the installed package version and the lockfile digest, and runs `runtime/measure.mjs` with an explicit environment and `PLAYWRIGHT_BROWSERS_PATH` set to `runtime/browsers`, so neither PATH nor a global browser is ever consulted. `measure.mjs` aborts every request other than the page itself and reports it, reports clipped copy and DOM geometry, and records the platform fonts the browser used.
