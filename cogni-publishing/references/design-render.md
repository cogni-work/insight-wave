# Design render

The normative description of `design-render` and its HTML target. `scripts/design-render.py` is the entry point, `scripts/render_core.py` the target-neutral core, `scripts/html_adapter.py` the HTML adapter and `scripts/render_checks.py` the independent checks; `scripts/validate-publishing.py check-plan` enforces the plan contract. Shared finding codes are defined in [`artifact-contracts.md`](artifact-contracts.md).

## Position in the chain

```text
normalized-brief@1 ─┐
semantic-composition@2 ─┼─render─> target-resolved-plan@2 ─> index.html
theme-artifact@1 (tokens) ─┘                  └──────────> render-provenance@1
```

The render validates the brief and composition through the publishing validator, resolves the theme and its fonts, lays every composition unit out, renders the page, runs the fidelity checks on it and only then writes. A rejection writes nothing.

## Operations

| Command | Needs | `data` on exit 0 |
|---|---|---|
| `render --target html` | brief, composition, theme, `--out` | the three output paths, unit count, content fingerprint, the font records, `layout_face`, `fidelity: passed` |
| `render --measure` | the same, plus the provisioned runtime | also `browser_report` and the measurement summary |
| `check-html` | brief, composition, page, optional theme | `valid`, the number of copy keys |
| `check-provenance` | provenance, optional composition, plan, output directory | `valid`, font count, `layout_face` |
| `compare` | two plans or two measurement reports | `equal`, the tolerance, the ignored fields |
| `check-runtime-lock` | optional runtime directory | `valid`, the pin |
| `measure` | a page and a report path, the provisioned runtime | the measurement summary |

Every command prints one `{"success", "data", "error"}` envelope and nothing on stderr: exit 0 success, 1 a contract or fidelity finding (`code`, `check`, `reference`, and `findings` for check commands), 2 a usage or runtime problem.

| Code | Meaning |
|---|---|
| `unsupported-target` | a target this renderer does not own; it renders `html` only |
| `invalid-theme` | the theme has no `theme.md`, its slug is not the composition's `design_system.name` (`theme-slug`), it has no `tokens/` or they do not compile (`theme-tokens`), a required token role is missing (`theme-token-missing`), or a length or ratio token is not one (`theme-token-unit`) |
| `font-unresolved` | no member of a font stack is bundled or a generic family; `reference` is the first requested family |
| `unresolved-citation` | a `[N]` marker in copy names no source record |
| `register-not-last` | a source register that is not the last unit |
| `runtime-missing` | a runtime-backed operation found no provisioned runtime; the error names `runtime/provision.sh` |
| `runtime-unpinned` | the provisioned runtime does not match the committed lockfile, pin or recorded interpreter |
| `measure-failed` | the runtime ran and failed |
| `render-incomplete` | an output is missing after the write |
| `plan-drift` | `compare` found a material difference; `differences` lists the paths |
| fidelity codes | `copy-omitted`, `copy-changed`, `copy-invented`, `invented-text`, `script`, `remote-asset`, `local-reference`, `truncating-css`, `hidden-copy`, `reordered-unit`, `description-missing`, `comparison-structure`, `chart-semantics`, `system-semantics`, `register-order`, `citation-missing`, `citation-unresolved`, `citation-substituted`, `token-block`, `css-literal`, `token-unused` |
| provenance codes | `font-unrecorded`, `silent-substitution`, `font-layout`, `runtime-unpinned`, `fingerprint-mismatch`, `design-system`, `output-digest` |
| lock codes | `range-pin`, `install-script`, `lock-missing`, `lock-mismatch`, `lock-unhashed`, `install-tracked` |

## Theme

The theme is a `theme-artifact@1` directory. Its name must equal the composition's pinned `design_system.name`; the pinned `version` is recorded in provenance and never compared with the plugin version, which changes on every release. Its `tokens/*.json` compile through `generate-tokens-css.py` and must carry these roles:

| File | Keys |
|---|---|
| `colors` | `text`, `bg`, `surface`, `accent`, `text-muted`, `border` |
| `typography` | `font-sans`; `size-display`, `size-h2`, `size-h3`, `size-body`, `size-small` in px; `line-height-display`, `line-height-h2`, `line-height-h3`, `line-height-body`, `line-height-small` as ratios |
| `spacing` | `3`, `4`, `5`, `6`, `7` in px |

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

1. a family in `bundled_faces` resolves to that face (none is bundled today);
2. a generic family — `system-ui`, `sans-serif`, `serif`, `monospace` — resolves to its documented `chain`;
3. any other family is skipped and recorded;
4. a stack with no resolvable member fails as `font-unresolved`.

Provenance records, per token, `requested_stack`, `requested_family`, `resolved_face`, `substituted` (true whenever the resolved face is not the first requested family), `skipped` and `fallback_chain`. The page sets copy in `--render-font-copy`, the resolved chain, never in a skipped family, so a face installed on one machine cannot substitute silently. Layout is computed with the resolved face's documented `advance_em`, every plan slot records it as `measured_with`, and provenance's `layout_face` must equal it.

## target-resolved-plan@2

A plan lays one composition out for one target on a `1280 × 720` px canvas. Units stack as frames in composition order; each frame is at least the canvas height and grows with its content. Within a frame, canvas slots follow the pattern's reading order top to bottom; notes are `placement: aside` with no box. Every slot records its `type_role`, `measured_with`, a deterministic line estimate and its `content` — the composition's own references: `{record_ref, field, digest}` for a binding, `{data_ref, digest}` for a chart point and `{source_ref, digest}` for a register entry, where a data or source digest is taken over the brief's record exactly as the composition's digests are. The plan carries no copy. `check-plan` enforces the full shape: see [`target-resolved-plan-v2.schema.json`](target-resolved-plan-v2.schema.json).

Line estimates never truncate: content that needs more lines gets a taller box. The page uses the plan's frame heights as minimum heights and its slot boxes to size the two SVG figures. Text outside a figure flows in the page and is never clipped.

SVG text does not wrap on its own, so each figure label is estimated and drawn at the width it actually has:

- An **entity label** wraps at the node text width: the slot width, less the 260 px connector gutter that stays free right of the nodes, less `spacing-4` on each side. Each node is `lines × line height + 2 × spacing-4` tall, with `spacing-5` between nodes.
- A **chart label** wraps at its label column, 40 % of the slot width, less an 8 px gap before the marks. It is estimated from the data item's `label` alone. Each point's row is `max(lines × line height, 28 px) + spacing-3`.

The entities or series slot's box height is the sum of those nodes or rows, and its `lines` is the sum of the label lines. The SVG draws exactly those lines. A target adapter takes these widths and the line split from the core and never derives them itself.

## render-provenance@1

`renderer` (name, plugin version, target), `runtime` (the committed manifest's exact dependency pins, the lockfile path and sha256, and whether this render used it), `design_system` (the composition's pin), `theme` (slug, sha256 of its resolved tokens), `inputs`, `content_fingerprint` (the brief's, which equals the composition's pinned fingerprint), `language`, `outputs` (path and sha256 of the plan and the page), `fonts`, `layout_face`, `measurement` (null unless `--measure`), `generated_at` and `run_id`. See [`render-provenance-v1.schema.json`](render-provenance-v1.schema.json).

## Fidelity rules

- **Text insertion.** Every original string enters the page through one escaping function, once, as text. Markdown characters stay visible; whitespace inside a string is kept (`white-space: pre-wrap`); nothing is trimmed, case-changed, normalized or reformatted. A number keeps the literal the brief wrote. A figure label is split into display lines before it is escaped: each paragraph is cut every n characters, where n is the number of characters per line the estimate uses, and a paragraph break stays at the end of its line. Each line is then escaped once, so the lines join to the string exactly. A break can fall inside a word.
- **Copy keys.** A copy-bearing element carries `data-copy`: `<record>#<field>`, `<record>#<field>#<item>` for a list item, `data:<id>#label`, `source:<id>#raw` for a narrative source or `source:<id>#<field>` for each field of a direct source, `trailer#<n>` and `document#title` / `document#subtitle`. A value label carries `data-value="<id>"` and reads the literal, one space, and the unit verbatim. A key may appear more than once — a chart label also labels its table row — and every occurrence must equal the brief.
- **Chrome vocabulary.** Visible text outside copy is limited to `[n]` register-number links for sources a direct section names without a marker, and the pattern library's relationship-kind tokens on system connectors. Everything else visible is copy.
- **Citations.** A `[N]` marker in narrative copy links the source whose `marker` is `[N]`, to its `url` byte for byte. A source a direct section or data item names is linked from its unit as `[n]`, `n` its position in the Sources list. A source without a URL links its register entry.
- **Register.** The source register lists every source once in original order — a narrative source as its verbatim `raw` line, a direct source as its fields — and is the last unit.
- **Figures.** A chart is one SVG generated from data only: one mark per bound point, each with its own label and value label, and a data table as its text alternative. Chart marks share one zero baseline: a positive value extends right of it, a negative value left of it, and a baseline line is drawn when a negative value is present. One chart plots one unit of measure; a mixed-unit series is rejected upstream as `mismatched-unit`. A conceptual system is the same bounded SVG path: one labelled node per declared entity, one connector per relationship labelled with its kind, and an entity list as its text alternative. Each figure label is one copy-bearing `<text>` element whose `<tspan>` lines join with nothing between them; a line carries no copy key of its own. Every figure has `role="img"`, is named by `aria-labelledby` pointing at its claim, and is described by `aria-describedby` pointing at its alternative. Series and sides are told apart by text, never by color alone.
- **Portability.** The page has no script, no event handler, no `<link>`, no `src`, no `@import`, no CSS `url()` and no absolute or file path; fragment references resolve inside the page. Navigational `<a href>` links are exempt. The path, workspace and runtime scan reads only where a page can name something to load — `<style>` text and attribute values other than navigational links and the identity attributes (`id`, `class`, `data-*`, `aria-*`) that carry the brief's own ids and copy keys. Copy text is never scanned, so prose that names a path or a tool stays copy; `file:` counts only as a URL scheme, and `cogni-workspace`, `node_modules` and `ms-playwright` only as path segments. Nothing hides, clamps or clips copy: no `display: none`, `visibility: hidden`, `overflow: hidden`, `max-height`, `text-overflow: ellipsis` or `line-clamp`.

## Comparator

`compare` ignores only the top-level volatile fields `generated_at` and `run_id`. Numbers under a `box` or `frame` may differ by at most the tolerance, 0.5 px by default; every other value — ids, digests, strings, line estimates, list lengths — must be equal. The same comparator reads two measurement reports, whose geometry also sits under `box`.

## Runtime boundary

Rendering is Python 3 stdlib only (3.9 or newer) and needs no Node, browser, network, model API or cogni-workspace. The measurement runtime is separate: `runtime/package.json` pins `playwright-core` to an exact version, `runtime/package-lock.json` locks it with its registry URL and sha512 integrity, and that version pins its own Chrome Headless Shell build. It is provisioned only by `runtime/provision.sh`, run once per machine by an operator or, in CI, by its own step of the Plugin test suites job ahead of the sweep; the wrapper, the skills and the test suites never install anything. `provision.sh` records the interpreter it used in the gitignored `runtime/.provisioned.json`. The Node interpreter itself is a per-machine host dependency — node 20 or newer, found on PATH or named by `NODE` — and not part of the pin: the lockfile makes `playwright-core` and its browser build reproducible across machines, while the recorded interpreter path and version bind only later measurements on the same machine. Every measurement re-verifies that interpreter's version, the installed package version and the lockfile digest, and runs `runtime/measure.mjs` with an explicit environment and `PLAYWRIGHT_BROWSERS_PATH` set to `runtime/browsers`, so neither PATH nor a global browser is ever consulted. `measure.mjs` aborts every request other than the page itself and reports it, reports clipped copy and DOM geometry, and records the platform fonts the browser used.
