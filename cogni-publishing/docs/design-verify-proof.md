# design-verify proof: two brands, two targets

This page is the evidence that the publishing render path works end to end. One brief goes through it under two existing bundled brands, `boardroom` and `editorial`, to both targets, html and pptx. Every output is then verified by `design-verify`, and every unit of every output is inspected at full resolution. The records live in [`design-verify-proof/`](design-verify-proof/), and `proof-manifest.json` there binds them together by digest. `python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json` recomputes every recorded hash, re-reads every report, and validates the review record and the specimen index. The `dver` suite runs that check, and the others, on every CI run.

## The proof brief

`tests/fixtures/verify/direct-proof-v1.json` is a `direct-brief@1` under an existing contract, with no new contract version. It carries five units:

- an answer with notes
- a two-option comparison (today and tomorrow), with notes
- a sourced chart: four data items with value, unit and a source that has a URL
- a conceptual system: three entities, two `depends-on` relationships, notes
- the source register

Its frozen normalization is `direct-proof-v1.normalized.json`. The two compositions, `composition-proof-boardroom-v2.json` and `composition-proof-editorial-v2.json`, are frozen `compose` output and differ only in `design_system.name`. The patterns they bind are `answer-emphasis/statement`, `comparison/tabular`, `sourced-chart/bar`, `conceptual-system/cluster` and `sources/register`. `design_system.version` is `0.0.16`, the plugin version the proof was rendered at, which is the pin for a bundled brand. The brands' own revisions are the digests of `theme.md` and every `tokens/*.json`, recorded per output in the proof manifest.

## Reproduce it

Run everything from the plugin directory. Nothing needs cogni-workspace initialisation, a model-provider credential, the network, Node or a browser. The runtime dependency is the Python 3 standard library (3.9 or newer). The pinned measurement runtime — `playwright-core` 1.63.0, pinned by `runtime/package.json` and `runtime/package-lock.json` — is **not** used by any command below. It is named here because it is the only other pinned dependency the render path has, and a measured page report needs it.

```bash
# 1. Normalize the brief; its data equals tests/fixtures/verify/direct-proof-v1.normalized.json
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/verify/direct-proof-v1.json

# 2. Compose each brand from a stripped draft: drop every binding digest, the content fingerprint, units[].source_refs,
#    units[].register_refs and document_bindings from the committed composition, then let compose fill them again
python3 scripts/validate-publishing.py compose --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition <stripped-boardroom-draft.json>
python3 scripts/validate-publishing.py compose --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition <stripped-editorial-draft.json>

# 3. Render the four outputs with fixed ids
python3 scripts/design-render.py render --target html --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition tests/fixtures/verify/composition-proof-boardroom-v2.json --theme themes/boardroom --out docs/design-verify-proof/boardroom/html --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target pptx --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition tests/fixtures/verify/composition-proof-boardroom-v2.json --theme themes/boardroom --out docs/design-verify-proof/boardroom/pptx --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target html --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition tests/fixtures/verify/composition-proof-editorial-v2.json --theme themes/editorial --out docs/design-verify-proof/editorial/html --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target pptx --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition tests/fixtures/verify/composition-proof-editorial-v2.json --theme themes/editorial --out docs/design-verify-proof/editorial/pptx --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof

# 4. Verify each output with the review record folded in (the proof manifest records all four commands)
python3 scripts/design-verify.py verify --target pptx --brief tests/fixtures/verify/direct-proof-v1.normalized.json --composition tests/fixtures/verify/composition-proof-boardroom-v2.json --theme themes/boardroom --artifact docs/design-verify-proof/boardroom/pptx/deck.pptx --manifest docs/design-verify-proof/boardroom/pptx/pptx-manifest.json --review docs/design-verify-proof/review-record.json --out docs/design-verify-proof/boardroom/pptx/verification.json

# 5. Check the persisted records
python3 scripts/design-verify.py check-review --record docs/design-verify-proof/review-record.json --proof docs/design-verify-proof/proof-manifest.json
python3 scripts/design-verify.py check-specimens --index docs/design-verify-proof/specimens.json --proof docs/design-verify-proof/proof-manifest.json
python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json

# 6. The deliberately unfit fixture: a bounded failure, recorded in repair-unfit.json
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/verify/direct-unfit-v1.json
python3 scripts/design-verify.py render-verified --target pptx --brief <normalized direct-unfit-v1> --composition tests/fixtures/verify/composition-unfit-v2.json --theme themes/boardroom --out <dir> --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
```

The page, the deck and both plans are byte-reproducible. On Python 3.9.6 and 3.14.2 alike, a re-render gives the digests the manifest records. The deck's `pptx-manifest.json` records the interpreter that wrote it, so that file, and the provenance digest of it, change with the interpreter and nothing else; `isolated-render.json` shows exactly that.

The visual review captures are made with host tools, never by a plugin script:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --force-device-scale-factor=1 --window-size=1280,4200 --screenshot=<full.png> file://<index.html>
soffice -env:UserInstallation=file://<scratch-profile> --headless --convert-to pdf --outdir <dir> <deck.pptx>
pdftoppm -r 96 -png <deck.pdf> <slide>
```

The full-page capture is cut into one image per unit on each unit's own border rows. At 96 dpi each slide is its 1280 × 720 px canvas.

## Results

| Brand | Target | Artifact sha256 | Verdict | Preservation | Accessibility | Geometry |
|---|---|---|---|---|---|---|
| boardroom | html | `dc2d55ad03a25837705b5d5801be8ca22a87a8372ce76d5d7506e033c3a81d88` | pass | copy 13, data 4, sources 12, notes 4, order 5 passed; evidence not carried | 4 of 4 required passed | static |
| boardroom | pptx | `0dddf52dbb4bdc0d87419febebcc2119835ee2bb2b486c1a6291e7873dacd44b` | pass | the same | 4 of 4 required passed; slide titles unsupported | package |
| editorial | html | `235eb7585cf1c19d7af99c9112aefc9de45ab3057254a0749976314d2cebc1b1` | pass | the same | 4 of 4 required passed | static |
| editorial | pptx | `a5a2aa950fc6dfddd7e3a585dbf5a2848447edac6f06ba4d6fefed46c184f043` | pass | the same | 4 of 4 required passed; slide titles unsupported | package |

Every report records `evidence` as `not-carried`, because a direct brief carries no evidence status. The evidence-status comparison is proved separately, on the narrative fixture, where it is carried; the `dver` suite turns it red on a mutated value.

**Contrast.** Contrast is computed from each brand's tokens with the WCAG 2.1 formula. boardroom's lowest text pair is `text-muted` on `surface` at 5.74:1, and its lowest graphic pair is `accent` on `surface` at 4.49:1. editorial's lowest text pair is `text-muted` on `surface` at 6.34:1, and its lowest graphic pair is `accent` on `surface` at 4.52:1. Every text pair clears 4.5:1 and every graphic pair clears 3:1. The same check fails the `cogni-work` test theme's lime accent at 1.26:1 on its surface. That brand is not in this proof, but the failure shows the check discriminates.

**The chart's text alternative.** Before this proof, the deck's chart frame carried no `descr`, so PowerPoint's accessibility checker would report the chart as missing alt text. The pptx alt-description requirement caught it. The writer now gives the frame its variant's purpose from the pattern library, the same convention the declared fallback picture follows. Charts whose values all share one sign also pin the value axis at zero, so bar lengths stay proportional in any application.

## Editability witnesses

Each proof deck's `verification.json` carries two witnesses. They are computed from the deck itself, and they reproduce because the edited package is re-zipped with fixed entry dates.

| Deck | Text witness (`copy:document#title`) | Chart witness (`chart:u-components`) |
|---|---|---|
| boardroom | edited and read back; package `sha256:ace0e5f4c296b8c3f58fe2841520d5a220e5bf58c0f7627399e38cea9576ba2f` | cache and workbook `B2` from 13.0 to 42, both read back; package `sha256:6f5590695e16addb6f8fefe620bd5679d5783794f50c19bee1fbd693f705091e` |
| editorial | edited and read back; package `sha256:385eb69b9585d034357bb795707ec1f92ccba6213e264492dd7ec4c873cdd825` | cache and workbook `B2` from 13.0 to 42, both read back; package `sha256:d054142f8e783cc4da50221043fec99e18a5847b7dfa6e5425db2a485e365b62` |

Both decks list 14 objects in their editability inventory. Every copy key sits in a native `p:sp` text frame, the chart is a native `c:chart` frame with an embedded workbook, and there is no picture. A deck in which a copy frame or the chart has been swapped for a picture fails `editability` as `flattened-substitution`, and its witness fails; the `dver-19` and `dver-20` cases prove both. The witnesses show the objects are editable data. How an application draws the edit is recorded in [`pptx-smoke-evidence.md`](pptx-smoke-evidence.md), where the LibreOffice open of both proof decks is recorded and the Microsoft PowerPoint open and edit are pending.

## Visual review

[`design-verify-proof/review-record.json`](design-verify-proof/review-record.json) holds 20 full-resolution entries (5 units × 2 targets × 2 brands) and 4 deck overviews. Each entry names its artifact and digest, its capture tool, version, resolution and image digest, the criteria checked, and its findings. The reviewer is the resolving model. The record says so, and it names what a person should spot-check.

No entry carries a critical or a major finding. The minor findings are these:

- **Tabular comparison.** In a tabular comparison, each option's title and body are identical peer rows, so the pairing is carried by order alone. This holds on all four outputs.
- **Headless units.** The comparison and the register are the only units without a headline, which each overview shows as a headless section.
- **Editorial entity labels.** In the editorial serif face, entity labels sit high in their nodes on the page.

The notes record the rest:

- the slide margin placement of register numbers
- the fixed value column of a deck chart
- sparse comparison and system slides
- the editorial system unit flowing 3 px past its 720 px plan frame (a page's frames are minimums, so nothing is clipped)
- a 96 dpi raster artifact that a 192 dpi re-raster showed to be a continuous border
- headings bold on the page but regular in the deck

Two overview files are committed per brand: `overview/<brand>-html.png` (the full page, downscaled) and `overview/<brand>-pptx.pdf` (the LibreOffice export). The per-unit captures are identified by digest and regenerate from the commands above.

## Specimens

[`design-verify-proof/specimens.json`](design-verify-proof/specimens.json) maps every pattern the proof uses to its rendered examples on both targets for both brands, with good examples, unsuitable uses and limitations:

| Pattern / variant | Examples | Unsuitable use recorded |
|---|---|---|
| `answer-emphasis/statement` | page `#unit-u-answer`, slide 2 | more than three support lines (statement-with-support carries five) |
| `comparison/tabular` | page `#unit-u-compare`, slide 3 | `parallel` for title-plus-body options: it sets one column per field, so one option is split across two columns. Display size on a slide: it overflows under both variants. |
| `sourced-chart/bar` | page `#unit-u-components`, slide 4 | a mixed-unit series; twelve multi-line labels on a slide |
| `conceptual-system/cluster` | page `#unit-u-capability`, slide 5 | `feedback-loop` when every part must stay editable in PowerPoint |
| `sources/register` | page `#unit-u-sources`, slide 6 | a register placed anywhere but last |

The index records its fit failures (the unfit fixture) and its limitations. First among them: token parity is not visual parity. The two brands share every token check, yet the page sets headings in bold and the deck does not, and the editorial serif face runs on metrics the documented advance does not describe. That is why every brand and target was rendered and inspected rather than inferred.

## Repair within a budget

`tests/fixtures/verify/direct-unfit-v1.json` holds a two-option comparison at display size, which is deliberately unfit for a fixed slide. [`repair-unfit.json`](design-verify-proof/repair-unfit.json) records `render-verified` on it, with the default budget of 3, as a bounded failure:

- **Attempt 0.** `comparison/parallel` fails as `fit-overflow`, class `clipping`, on `u-options`.
- **Attempt 1.** The one repair, to `comparison/tabular`, fails the same way.
- **The loop stops at `no-eligible-repair`** after one repair. The content fingerprint is identical before and after and equals the frozen brief's. The unit ids are unchanged, and nothing is written.

The same composition renders and verifies on html, whose frames grow.

## Isolated run

[`isolated-render.json`](design-verify-proof/isolated-render.json) records the normalize, the four renders and the four verifies, run from a scratch directory. The environment was `env -i`, with a scratch `HOME`, a decoy `cogni-workspace/` beside the working directory and `python3 -I -S` on Python 3.9.6. Every step exited 0 with nothing on stderr. The normalized brief, both pages, both decks, all four plans, the page provenance and all four verification reports are byte-identical to the committed ones. Only the two deck manifests and their provenance digests differ, by the recorded interpreter version.

## Claude Design handoff comparison

No actual Claude Design reference output exists for this brief, so no comparison with the Claude Design handoff is recorded here. Nothing in this proof fetched claude.ai or used Claude Design, and no script, suite or skill step needs it or fails without it. If a real reference output for this brief becomes available, record it here with its provenance — the export's origin, date and digest — beside the matching proof output, and review it under the same rules.

## Limitations

- **Page geometry is static.** The pinned measurement runtime was not provisioned on the recording host, so no page was measured. Page clipping is covered by the no-hide, no-clamp, no-clip CSS rule and by the visual review, and each page report says `measured: not-supplied`. `verify --browser-report` folds in a `design-render measure` report when one exists; recording one for both pages is tracked as a follow-up.
- **Microsoft PowerPoint results are pending.** The deck captures come from LibreOffice, which is a lenient reader. The PowerPoint open and edit of both proof decks stay pending in `pptx-smoke-evidence.md`, which is the only surface that may claim an application result.
- **Glyph coverage is judged by the review.** The deterministic glyph check rejects replacement, private-use, unassigned and control characters. Whether a platform face draws every glyph is judged by the visual review.
- **The reviewer is a model.** The review record is complete, but whether each finding is right is a judgement a person should spot-check against the committed overviews.
- **Recorded versions are history.** The renderer version and the brand pin recorded here are `0.0.16`, the plugin version the proof was rendered at; the post-merge bump moves the live version on. A re-render records the new version in provenance, and nothing compares the two.
