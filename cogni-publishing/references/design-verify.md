# Design verify

The normative description of `design-verify`, the verification layer on top of `design-render`. `scripts/design-verify.py` is the entry point and `scripts/verify_checks.py` holds the checks. The render path imports nothing from either; `design-verify` extracts artifact facts through its own html.parser and zipfile/ElementTree readers in `verify_checks.py` and derives every expectation from the frozen normalized brief, the composition, the pattern library, the theme and `verify-capabilities.json`. Rendering codes are defined in [`design-render.md`](design-render.md) and the shared contract codes in [`artifact-contracts.md`](artifact-contracts.md). The records described here — the verification report, the review record, the specimen index, the proof manifest — are verifier output like render provenance, not chain artifacts, and carry no version of the artifact chain.

## Operations

| Command | Needs | `data` on exit 0 |
|---|---|---|
| `preserve` | target, brief, composition, artifact | the six families with status, expected count and differences |
| `editability` | brief, composition, deck | the object inventory and the text and chart edit witnesses |
| `accessibility` | target, brief, composition, theme, artifact, optional declaration | each declared requirement with its status |
| `geometry` | target, brief, composition, theme, artifact, optional measurement report | the coverage and an empty finding list |
| `verify` | the same, optional manifest, review record, measurement report and `--out` | the verdict and the checks; with `--out`, the full report on disk |
| `check-review` | review record, proof manifest | entry and overview counts |
| `check-specimens` | specimen index, proof manifest | the pattern count |
| `check-proof` | proof manifest | the output count and the brands |
| `render-verified` | target, brief, composition, theme, `--out`, fixed `--generated-at` and `--run-id`, optional `--budget` | the output paths, the repairs used and the changes |

Every command prints one `{"success", "data", "error"}` envelope and nothing on stderr: exit 0 success, 1 a finding (`data.findings` lists each), 2 a usage or runtime problem.

## Findings and the verdict

A finding is `{code, check, class, unit, message}`; the report adds `target` and `brand`, so every finding keeps its unit, target and brand until a re-verification clears it. `class` names one of the **critical classes** or is null:

| Class | Decided by |
|---|---|
| `clipping` | a deck frame whose text needs more height than the frame has, or a shape that leaves the slide; the page's static rule that no CSS hides, clamps or clips copy, and a measured `clipped` entry when a measurement report is supplied; a render refused as `fit-overflow` |
| `overlap` | two text-bearing deck frames that intersect by more than a pixel in both directions; two measured slot boxes of one page unit that intersect |
| `missing-glyph` | a replacement character (U+FFFD), a private-use, unassigned or surrogate code point, or a control character other than tab and line feed in the delivered text |
| `unreadable-text` | a text token pair below 4.5:1 contrast; a deck run below its slot's type role (the render-time readability floor) |
| `misleading-encoding` | a native chart whose value axis does not pin zero for one-signed values, a chart that is not a bar chart; page bars that do not share one zero baseline or are not proportional to their values |

The **verdict is `fail` whenever any finding is open**, of any class: a preservation difference, an editability failure, a failed accessibility requirement, a critical class, an independent structural fidelity finding on the delivered file, or a critical or major finding of a folded-in review. The report carries no pass rate, average, score or threshold, and nothing is weighed against anything else; a report with one critical finding among otherwise clean units fails.

## Preservation

Six families, each compared with the frozen normalized brief and reported with `status` (`passed`, `failed` or `not-carried`), `expected` (the count of rows the brief carries) and `differences` (`family`, `unit`, `reference`, `expected`, `found`):

| Family | Page | Deck |
|---|---|---|
| `copy` | every `data-copy` element of a text binding | the `copy:<key>` frame's paragraphs |
| `data` | each point's label and value label | the same, plus the native chart's series name, categories and numeric cache, and its embedded workbook |
| `sources` | an `<a>` in the unit linking the source's URL byte for byte | a hyperlink run on the unit's slide or its notes targeting the URL |
| `evidence` | the `evidence_status` binding | the same |
| `notes` | the unit's aside notes, and the trailer notes on the last unit | the unit's notes slide |
| `order` | the sections' unit order | the slides' unit order, the cover excepted |

A family the brief does not carry is `not-carried`, never `passed`: a direct brief carries no evidence status and a narrative brief no dataset.

## Editability (pptx)

Every copy key a unit binds must be one native `p:sp` with a `p:txBody`; every sourced chart must be one native `c:chart` graphic frame backed by an embedded workbook under `ppt/embeddings/`; and a picture is admitted only as the pptx fallback the unit's variant declares in the pattern library. Anything else is `flattened-substitution`. Two **edit witnesses** then edit the deck the way an application's editor reaches it — the first copy run's text, and the chart's first numeric-cache value together with workbook cell `B2` — re-zip the package with fixed entry dates and read both edits back. A witness records the object, the value before and after, and the edited package's digest; one that cannot find a native run or cell to edit fails as `witness-failed`. The witnesses prove the objects are editable data, not how an application draws the edit; application results belong to [`../docs/pptx-smoke-evidence.md`](../docs/pptx-smoke-evidence.md).

## Accessibility

[`verify-capabilities.json`](verify-capabilities.json) declares, per target, each accessibility requirement as `required` with its mechanism or `unsupported` with its reason, the token pairs the target paints, and the ratio each use of a pair requires (4.5:1 for text, 3:1 for graphics a reader needs). A required requirement is `passed` or `failed`; an unsupported one is reported `unsupported` with its reason and is never counted as passed. The declaration is fixed per target — it is never tuned per run or per brand to make a verification pass. Contrast is computed from the brand's resolved colour tokens with the WCAG 2.1 formula in `scripts/check-contrast.py`. A missing text alternative is `description-missing`: on a page, a figure not named by its claim or not described by its alternative; in a deck, a chart frame or picture without a `descr`, or a system entity that is not a native text node.

## Geometry coverage

A deck's geometry is read from the package itself, so its coverage is complete. A page's layout is decided by a browser, so its coverage is `static` — the no-hide, no-clamp, no-clip CSS rule and the figure encodings — unless a `design-render measure` report from the pinned runtime is supplied, when `measured` becomes `checked` and its `clipped` list and slot boxes are graded too. The report states which coverage applied; a page verified statically says so rather than claiming a measurement.

## Review record

A persisted visual review, `visual-review`, holds one **full-resolution entry per delivered unit or slide × target × brand**, including each generated PPTX cover (unit `document`, locator `slide 1 (document)`) and one **deck overview per (brand, target)**. Each entry names `brand`, `target`, `unit` (overviews have none), `view` (`full-resolution` or `deck-overview`), `artifact` (`path`, `sha256`, an optional `locator`), `capture` (`tool`, `version`, `width`, `height`, `sha256` of the image looked at; a full-resolution capture is at least 1280 × 720, and a deck overview's capture also names its committed image as `file`, relative to the record's directory), `checked` (the non-empty list of criteria the reviewer looked at) and `findings`. A finding carries `criterion`, `severity` (`critical`, `major`, `minor` or `note`), `code` and `description`; a critical finding's code is one of the critical classes. The record also names its `reviewer` (`kind`, `name`), its `method` and its `limitations`. `check-review` rejects a record missing any unit, target, brand or overview (`review-incomplete`), a duplicated entry (`review-duplicate`), an entry for another artifact than the proof records (`review-stale`), a deck overview whose `file` no longer matches its capture `sha256`, which `check-review` recomputes from the image (`review-stale`), a malformed entry, including a deck overview whose `file` is absent or outside the record's directory (`review-malformed`), and any key that states a bare verdict instead of findings — `verdict`, `quality`, `rating`, `score`, `overall`, `grade`, `pass_rate`, `average`, `threshold` or `approved`, at any depth (`unqualified-verdict`). `verify --review` folds the output's entries in: their critical and major findings become open findings of the report.

## Specimen index

A `specimen-index` names its `brands` and, per `pattern` and `variant` the proof uses, rendered `examples` for **both targets and every brand** (`brand`, `target`, `artifact` relative to the index, `locator`, `sha256`), `good` examples with the reason they are good, `unsuitable` uses (`case`, `reason`) and `limitations`; the index also records `fit_failures` and index-level `limitations`. An example's `locator` names the entry's `unit` inside that example's own file: on a page `#<id>` of the unit section carrying it, in a deck `slide <n> (<unit>)`, where slide n in presentation order, cover included, carries that unit. `check-specimens` fails on a pattern with no entry (`specimen-unresolved`), a missing target or brand (`specimen-target-missing`), an example whose file does not resolve or match its digest (`specimen-unresolved`, `specimen-stale`), an example whose locator names no such unit there, or a good example that names no example's brand, target and locator (`specimen-unresolved`), an entry without a good example (`specimen-good-missing`), a used pattern and variant with no unsuitable use of its own or an unsuitable use without a case or reason (`specimen-reason-missing`), and an index without fit failures or limitations (`specimen-malformed`). Examples are rendered per brand and target because token parity does not prove visual parity.

## Proof manifest

A `proof-manifest` declares a `root` relative to its own directory and names every file relative to it: the `brief` and the `normalized_brief`, and exactly **four outputs** — html and pptx for each of two distinct bundled brands. Each output records `brand`, `target`, its `composition` and `design_system`, its `theme` (`themes/<brand>` and the sha256 of `theme.md` and of every `tokens/*.json` — the brand files the renderer reads), the `renderer` name and exact `x.y.z` version, the producing `command`, and `plan`, `artifact`, `provenance`, `verification` and, for a deck, `manifest`, each as `{path, sha256}`. It also records the `review`, the `specimens`, the `repair` record and the `isolated_render` log. `check-proof` recomputes every digest (`proof-hash-mismatch`), resolves every path inside the root (`proof-unresolved`), requires the four outputs (`proof-outputs`), a bundled brand whose recorded files are exactly its authoritative ones (`proof-brand`), an exact renderer version (`proof-renderer`), a producing command naming its target and theme (`proof-command`), a passing verification report for exactly that artifact (`proof-unverified`) and a provenance that records it (`proof-provenance`), and then runs `check-review` and `check-specimens`. It never compares a recorded version with the plugin's current version, which the post-merge bump changes.

## Repair

`render-verified` renders through `design-render` itself, into a scratch directory beside `--out`, and verifies the result. On a failure it takes the first failing unit and tries the other variants of that unit's pattern in library order, one at a time: each candidate changes only that unit's `variant`, must pass the validator's `check-repair` against the frozen brief — the same content fingerprint, units, order, bindings, digests and references — and is then rendered and verified like the first attempt. A unit's own variant is never offered back. The **budget** is the number of candidates it may try after the first render: a whole number from 0 to 10, 3 unless `--budget` says otherwise; the one-line guard `budget_left` decides it. The loop stops at the first passing attempt, or with `repair-exhausted` when the budget is spent (`budget-exhausted`), no eligible variant is left (`no-eligible-repair`) or no failing unit can be named (`no-repairable-unit`). Every attempt runs with the caller's fixed `--generated-at` and `--run-id`, so it is reproducible.

The history lists each attempt's number, its changes (`unit`, `before`, `after` as `pattern/variant`), the digest of the composition it rendered, its verdict and its findings' codes, classes and units. A bounded failure writes nothing and returns the history, the last findings, the frozen content fingerprint beside the before and after fingerprints, and the unit ids before and after — the fingerprint comes from the frozen normalized brief, never from a repaired or rendered artifact, and the unit ids never change, because no repair splits, adds or drops a unit. A success writes the render's outputs, the composition it rendered, `verification.json` and `repair-history.json`. No step rewrites, shortens, reorders or re-routes copy, and nothing is handed to a copywriting skill.
