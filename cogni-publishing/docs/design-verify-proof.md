# design-verify proof: two brands, two targets

## Platform-route proof

Two distinct native creation runs now live in `design-verify-proof/codex-openai/boardroom/` and `design-verify-proof/document-skills/boardroom/`. Both ran on the current OpenAI Codex desktop host. The first loaded bundled `presentations:Presentations` (26.909.22227) and authored a new Artifact Tool presentation. The second loaded the installed Anthropic `document-skills:pptx` capability and authored a new PptxGenJS presentation. The latter proves that installed capability on this host; it does not claim an execution on an Anthropic host or standalone ChatGPT web.

Each run starts with recorded normalize and compose results from the Nordlicht fixture, includes immutable inputs, and keeps its own editable deck, attempt ledger, execution record, artifact digests, full-resolution slide captures, overview and visual review. Generator-side package completion supplies explicit semantic slide identities, citation relationships in notes, and required package declarations; neither run imports stdlib output to create its deck. The previous generic platform admission bundle has been replaced because importing an existing stdlib deck did not establish native creation.

HTML uses a separately authored DOM renderer over the same frozen records. That shared HTML leg is explicitly identified in both bundles and is not claimed as a presentation-skill output. It includes every unit and its complete notes, with full-unit browser captures. No content source URL was researched or changed: these are frozen test-fixture citations.

Every final artifact passes independent verification with its visual review folded in and has an empty preservation diff. The document-skills run extended its budget from three to five before its fourth repair to address key-figure emphasis. The OpenAI run extended its budget from three to six before the extra visual repairs, within the hard maximum of ten, and records all attempts including failures. Native chart creation is not demonstrated by this Nordlicht brief because its data array is empty; chart admission remains covered by the existing deterministic fixtures.

The theme supplies `colors.primary` and `colors.bg`, used as the recorded `bg-dark` and `text-on-dark` role aliases. Required units 1 and 6, including the climax, are dark; authored key figures are prominent; evidence tags preserve their exact strings while appearing uppercase. The frozen document title/subtitle requires a cover named `document`, followed by the eight composition units.

Replay each bundle from the plugin directory (set `BUNDLE` to either directory above):

```bash
python3 scripts/design-verify.py verify --target pptx --brief "$BUNDLE/inputs/brief.json" --composition "$BUNDLE/inputs/composition.json" --theme themes/boardroom --artifact "$BUNDLE/pptx/deck.pptx" --review "$BUNDLE/pptx/review-record.json"
python3 scripts/design-verify.py verify --target html --brief "$BUNDLE/inputs/brief.json" --composition "$BUNDLE/inputs/composition.json" --theme themes/boardroom --artifact "$BUNDLE/html/index.html" --review "$BUNDLE/html/review-record.json"
python3 scripts/design-render.py check-provenance --provenance "$BUNDLE/pptx/provenance.json" --composition "$BUNDLE/inputs/composition.json" --out-dir "$BUNDLE/pptx"
```

These non-reproducible execution records remain outside the legacy `proof-manifest.json`, whose exactly four stdlib outputs and byte-reproduction checks are unchanged. The offline platform suite validates both live provenance shapes and independently labels its fixed artifact stub as non-live.

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

The suite's plain result lines use `PASS:` or `FAIL:` as the status token. The stable `dver-*` case identifier is the following whitespace-delimited token; the historical “first token” wording is intentionally interpreted as the first token after that status token.

```bash
# 1. Build every intermediate under one concrete scratch root.
proof_work="$(mktemp -d)"
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/verify/direct-proof-v1.json > "$proof_work/proof-normalize.json"
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/verify/direct-unfit-v1.json > "$proof_work/unfit-normalize.json"
python3 - "$proof_work" <<'PY'
import json, os, sys
root = sys.argv[1]
for source, target in (("proof-normalize.json", "proof-brief.json"),
                       ("unfit-normalize.json", "unfit-brief.json")):
    envelope = json.load(open(os.path.join(root, source), encoding="utf-8"))
    assert envelope["success"] is True and envelope["error"] is None
    with open(os.path.join(root, target), "w", encoding="utf-8") as output:
        json.dump(envelope["data"], output, ensure_ascii=False)
for brand in ("boardroom", "editorial"):
    source = f"tests/fixtures/verify/composition-proof-{brand}-v2.json"
    composition = json.load(open(source, encoding="utf-8"))
    composition["normalized_brief_ref"].pop("content_fingerprint", None)
    composition["document_bindings"] = []
    for unit in composition["units"]:
        unit.pop("source_refs", None)
        unit.pop("register_refs", None)
        for binding in unit.get("bindings", []):
            binding.pop("digest", None)
    with open(os.path.join(root, f"{brand}-draft.json"), "w", encoding="utf-8") as output:
        json.dump(composition, output, ensure_ascii=False)
composition = json.load(open("tests/fixtures/verify/composition-unfit-v2.json", encoding="utf-8"))
composition["normalized_brief_ref"].pop("content_fingerprint", None)
composition["document_bindings"] = []
for unit in composition["units"]:
    unit.pop("source_refs", None)
    unit.pop("register_refs", None)
    for binding in unit.get("bindings", []):
        binding.pop("digest", None)
with open(os.path.join(root, "unfit-draft.json"), "w", encoding="utf-8") as output:
    json.dump(composition, output, ensure_ascii=False)
PY

# 2. Compose and validate both proof brands, plus the bounded-failure input.
python3 scripts/validate-publishing.py compose --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-draft.json" > "$proof_work/boardroom-compose.json"
python3 scripts/validate-publishing.py compose --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-draft.json" > "$proof_work/editorial-compose.json"
python3 scripts/validate-publishing.py compose --brief "$proof_work/unfit-brief.json" --composition "$proof_work/unfit-draft.json" > "$proof_work/unfit-compose.json"
python3 - "$proof_work" <<'PY'
import json, os, sys
root = sys.argv[1]
for name in ("boardroom", "editorial", "unfit"):
    envelope = json.load(open(os.path.join(root, f"{name}-compose.json"), encoding="utf-8"))
    assert envelope["success"] is True and envelope["error"] is None
    with open(os.path.join(root, f"{name}-composition.json"), "w", encoding="utf-8") as output:
        json.dump(envelope["data"], output, ensure_ascii=False)
PY
python3 scripts/validate-publishing.py check-composition --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-composition.json"
python3 scripts/validate-publishing.py check-composition --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-composition.json"

# 3. Render boardroom and editorial to both targets with fixed ids.
python3 scripts/design-render.py render --target html --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-composition.json" --theme themes/boardroom --out "$proof_work/boardroom/html" --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target pptx --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-composition.json" --theme themes/boardroom --out "$proof_work/boardroom/pptx" --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target html --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-composition.json" --theme themes/editorial --out "$proof_work/editorial/html" --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof
python3 scripts/design-render.py render --target pptx --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-composition.json" --theme themes/editorial --out "$proof_work/editorial/pptx" --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof

# 4. Verify all four outputs with the review record folded in.
python3 scripts/design-verify.py verify --target html --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-composition.json" --theme themes/boardroom --artifact "$proof_work/boardroom/html/index.html" --review docs/design-verify-proof/review-record.json --out "$proof_work/boardroom/html/verification.json"
python3 scripts/design-verify.py verify --target pptx --brief "$proof_work/proof-brief.json" --composition "$proof_work/boardroom-composition.json" --theme themes/boardroom --artifact "$proof_work/boardroom/pptx/deck.pptx" --manifest "$proof_work/boardroom/pptx/pptx-manifest.json" --review docs/design-verify-proof/review-record.json --out "$proof_work/boardroom/pptx/verification.json"
python3 scripts/design-verify.py verify --target html --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-composition.json" --theme themes/editorial --artifact "$proof_work/editorial/html/index.html" --review docs/design-verify-proof/review-record.json --out "$proof_work/editorial/html/verification.json"
python3 scripts/design-verify.py verify --target pptx --brief "$proof_work/proof-brief.json" --composition "$proof_work/editorial-composition.json" --theme themes/editorial --artifact "$proof_work/editorial/pptx/deck.pptx" --manifest "$proof_work/editorial/pptx/pptx-manifest.json" --review docs/design-verify-proof/review-record.json --out "$proof_work/editorial/pptx/verification.json"

# 5. Check the persisted records.
python3 scripts/design-verify.py check-review --record docs/design-verify-proof/review-record.json --proof docs/design-verify-proof/proof-manifest.json
python3 scripts/design-verify.py check-specimens --index docs/design-verify-proof/specimens.json --proof docs/design-verify-proof/proof-manifest.json
python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json

# 6. Exercise and assert the deliberately unfit PPTX contract without aborting on its expected rc=1.
set +e
python3 scripts/design-verify.py render-verified --target pptx --brief "$proof_work/unfit-brief.json" --composition "$proof_work/unfit-composition.json" --theme themes/boardroom --out "$proof_work/unfit/pptx" --generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof > "$proof_work/unfit-result.json"
proof_unfit_rc=$?
set -e
python3 - "$proof_unfit_rc" "$proof_work/unfit-result.json" <<'PY'
import json, sys
result = json.load(open(sys.argv[2], encoding="utf-8"))
assert int(sys.argv[1]) == 1
assert result["success"] is False
assert result["data"]["code"] == "repair-exhausted"
assert result["data"]["stopped"] == "no-eligible-repair"
PY
```

Replayed on 2026-09-17 with Python 3.14.2 and Bash 3.2.57: both normalizations, all three compositions, both explicit composition checks, all four renders, all four verifies, and all three persisted-record checks exited 0 with successful envelopes. The final unfit command exited 1 as expected with `code: repair-exhausted`, `repairs_used: 1`, and `stopped: no-eligible-repair`; its assertion step exited 0. The separate isolated record below captures the same render/verify path on the Python 3.9.6 floor. The four artifact digests are the values in the Results table below, and `check-proof` reports four valid outputs. This recording followed the small-unit type floor `compose` now writes, which raises the comparison and the conceptual system on every output by one type role, so all four artifacts, their plans, provenance and verification reports were re-recorded and re-reviewed together. It then followed a component-CSS addition that styles only the two metric patterns, which no unit of this proof carries: both pages were re-rendered and their diff is those two rules and nothing else, so each html artifact, its provenance and its verification report were re-recorded and every html record re-bound to the new page digest, while both decks, all four plans and both deck provenance files stayed byte-unchanged. The captures were not retaken, because the pages render identically.

The page, the deck and both plans are byte-reproducible. On Python 3.9.6 and 3.14.2 alike, a re-render gives the digests the manifest records. The deck's `pptx-manifest.json` records the interpreter that wrote it, so that file, and the provenance digest of it, change with the interpreter and nothing else; `isolated-render.json` shows exactly that. The `dver-43` case re-renders all four outputs on every suite run, byte-compares each page and deck, compares each plan and runs `check-provenance` on each committed bundle.

The visual review captures are made with host tools, never by a plugin script:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --force-device-scale-factor=1 --window-size=1280,4200 --screenshot=<full.png> file://<index.html>
soffice -env:UserInstallation=file://<scratch-profile> --headless --convert-to pdf --outdir <dir> <deck.pptx>
pdftoppm -r 96 -png <deck.pdf> <slide>
```

The full-page capture is cut into one image per unit on each unit's own border rows: each unit section carries a 1 px border, so its top and bottom border rows are found in the capture and the image is cropped between them with a host image tool. At 96 dpi each slide is its 1280 × 720 px canvas.

## Results

| Brand | Target | Artifact sha256 | Verdict | Preservation | Accessibility | Geometry |
|---|---|---|---|---|---|---|
| boardroom | html | `c30f50b5e02dfdc0705c94702b69eb409537aedf83a29b658ab64fd56e555d67` | pass | copy 13, data 4, sources 12, notes 4, order 5 passed; evidence not carried | 4 of 4 required passed | static |
| boardroom | pptx | `86739b881f39c60a951185be8d90fbb7dea2fdfbd57d0ee6a4f021505a2dbe69` | pass | the same | 4 of 4 required passed; slide titles unsupported | package |
| editorial | html | `fe65fd11838f121f21b58244462092cd0045639ad12f0c73de1844af4e874069` | pass | the same | 4 of 4 required passed | static |
| editorial | pptx | `a50d73a154456f5c22322edb6da9e07dbe7319bda50d89966794fd68791b9bce` | pass | the same | 4 of 4 required passed; slide titles unsupported | package |

Every report records `evidence` as `not-carried`, because a direct brief carries no evidence status. The evidence-status comparison is proved separately, on the narrative fixture, where it is carried; the `dver` suite turns it red on a mutated value.

**Contrast.** Contrast is computed from each brand's tokens with the WCAG 2.1 formula. boardroom's lowest text pair is `text-muted` on `surface` at 5.74:1, and its lowest graphic pair is `accent` on `surface` at 4.49:1. editorial's lowest text pair is `text-muted` on `surface` at 6.34:1, and its lowest graphic pair is `accent` on `surface` at 4.52:1. Every text pair clears 4.5:1 and every graphic pair clears 3:1. The same check fails the `cogni-work` test theme's lime accent at 1.26:1 on its surface. That brand is not in this proof, but the failure shows the check discriminates.

**The chart's text alternative.** Before this proof, the deck's chart frame carried no `descr`, so PowerPoint's accessibility checker would report the chart as missing alt text. The pptx alt-description requirement caught it. The writer now gives the frame its variant's purpose from the pattern library, the same convention the declared fallback picture follows. Charts whose values all share one sign also pin the value axis at zero, so bar lengths stay proportional in any application.

## Editability witnesses

Each proof deck's `verification.json` carries two witnesses. They are computed from the deck itself, and they reproduce because the edited package is re-zipped with fixed entry dates.

| Deck | Text witness (`copy:document#title`) | Chart witness (`chart:u-components`) |
|---|---|---|
| boardroom | edited and read back; package `sha256:1799c6f776835e01f583d94e0b70d52b29f0de9828b7a8ccff71fe9ed6f933e0` | cache and workbook `B2` from 13.0 to 42, both read back; package `sha256:b11e06af2c64d863de35ecd7179f93fa9a303e99bd02b76c8e14c3f37c3d4cc4` |
| editorial | edited and read back; package `sha256:860f6aae1757971753cc70ae5d228b74398c4accc41c5da0f130923cde6cc83d` | cache and workbook `B2` from 13.0 to 42, both read back; package `sha256:129b5c332fdfff1552ea7ee6ecadc58f506305a82213ebc019d65ec4199e5fed` |

Both decks list 14 objects in their editability inventory. Every copy key sits in a native `p:sp` text frame, the chart is a native `c:chart` frame with an embedded workbook, and there is no picture. A deck in which a copy frame or the chart has been swapped for a picture fails `editability` as `flattened-substitution`, and its witness fails; the `dver-19` and `dver-20` cases prove both. The witnesses show the objects are editable data. How an application draws the edit is recorded in [`pptx-smoke-evidence.md`](pptx-smoke-evidence.md), where the LibreOffice open of both proof decks is recorded and the Microsoft PowerPoint open and edit are pending.

## Visual review

[`design-verify-proof/review-record.json`](design-verify-proof/review-record.json) holds 22 full-resolution entries (5 HTML units and 6 PPTX slides, including the generated cover, per brand) and 4 deck overviews. Each entry names its artifact and digest, its capture tool, version, resolution and image digest, the criteria checked, and its findings. The reviewer is the resolving model. The record says so, and it names what a person should spot-check.

No entry carries a critical or a major finding. Every unit bound to `comparison` or `conceptual-system` also carries a note that `compose` raised its type floor to `type.lead`. The minor findings are these:

- **Tabular comparison.** In a tabular comparison, each option's title and body are identical peer rows, so the pairing is carried by order alone. This holds on all four outputs.
- **Headless units.** The comparison and the register are the only units without a headline, which each overview shows as a headless section.
- **Editorial entity labels.** Previously recorded on the page: in the editorial serif face, entity labels sat high in their nodes. At the raised lead role the nodes grew with the type and the labels now read as centred, so this no longer reproduces; the record keeps it as a note rather than dropping it.

The notes record the rest:

- the slide margin placement of register numbers
- the fixed value column of a deck chart
- sparse comparison and system slides
- the editorial system unit flowing 11 px past its 720 px plan frame, up from 3 px before the raised type floor (a page's frames are minimums, so nothing is clipped)
- a 96 dpi raster artifact that a 192 dpi re-raster showed to be a continuous border
- headings bold on the page but regular in the deck

Two overview files are committed per brand: `overview/<brand>-html.png` (the full page, downscaled) and `overview/<brand>-pptx.png` (all six slides from the LibreOffice export, stacked in order and downscaled to 640 px wide). The per-unit captures are identified by digest and regenerate from the commands above. `check-review` recomputes each overview's digest from its committed file.

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

[`isolated-render.json`](design-verify-proof/isolated-render.json) records the normalize, the four renders and the four verifies, with the digests of the brief, the normalized brief, both compositions and each brand's files it ran from, run from a scratch directory. The environment was `env -i`, with a scratch `HOME`, a decoy `cogni-workspace/` beside the working directory and `python3 -I -S` on Python 3.9.6. Every step exited 0 with nothing on stderr. The normalized brief, both pages, both decks, all four plans, the page provenance and all four verification reports are byte-identical to the committed ones. Only the two deck manifests and their provenance digests differ, by the recorded interpreter version.

## Claude Design handoff comparison

No actual Claude Design reference output exists for this brief, so no comparison with the Claude Design handoff is recorded here. Nothing in this proof fetched claude.ai or used Claude Design, and no script, suite or skill step needs it or fails without it. If a real reference output for this brief becomes available, record it here with its provenance — the export's origin, date and digest — beside the matching proof output, and review it under the same rules.

## Limitations

- **Page geometry is static.** The pinned measurement runtime was not provisioned on the recording host, so no page was measured. Page clipping is covered by the no-hide, no-clamp, no-clip CSS rule and by the visual review, and each page report says `measured: not-supplied`. `verify --browser-report` folds in a `design-render measure` report when one exists; recording one for both pages is tracked as a follow-up.
- **Microsoft PowerPoint results are pending.** The deck captures come from LibreOffice, which is a lenient reader. The PowerPoint open and edit of both proof decks stay pending in `pptx-smoke-evidence.md`, which is the only surface that may claim an application result.
- **Glyph coverage is judged by the review.** The deterministic glyph check rejects replacement, private-use, unassigned and control characters. Whether a platform face draws every glyph is judged by the visual review.
- **The reviewer is a model.** The review record is complete, but whether each finding is right is a judgement a person should spot-check against the committed overviews.
- **Recorded versions are history.** The renderer version and the brand pin recorded here are `0.0.16`, the plugin version the proof was rendered at; the post-merge bump moves the live version on. A re-render records the new version in provenance, and nothing compares the two.

## Verification revision evidence

The verification layer reads HTML and Office Open XML with its own stdlib readers. Its predicates independently check frozen copy and source-register prose, citation identity, native chart cardinality and data, connector attachment, package relationships and content types, component colour tokens, readability and the declared accessibility capabilities. The renderer is loaded only when the repair command explicitly renders an attempt.

The proof review includes both generated document covers, inspected by Codex from host-generated LibreOffice PDF exports rasterised with Poppler and committed as downscaled PNG overviews. Each cover records its actual image digest and observations. Existing unit observations retain their original reviewer. The regenerated isolated execution uses copied brief, compositions and themes, Python 3.9.6 with `-I -S -B`, an empty environment and scratch home. All nine normalization/render/verify steps succeed; the only output differences remain the recorded PPTX interpreter and its dependent provenance digest.

The verifier suite passes 59 cases, that count read off a run on Python 3.14.2 and Bash 5.3.9 rather than the Python 3.9.6 and Bash 3.2.57 of the isolated execution above. It exercises both missing-cover cases and poisons renderer-checker imports while verifying pristine and corrupted artifacts. Those negatives cover invented copy, altered publisher text, citation swaps, detached connectors, extra chart series, missing package content types and component colour overrides. All 19 publishing suites pass with the modern host Python; the three browser-measurement cases retain their existing local runtime skips. CI provisions that runtime and remains the authoritative full-suite check for the PR head.

The twelve repository checks for skill specification, breadcrumbs, command inventory, README inventory, case pairing, result formatting, mutation recipes, code spans, marketplace descriptions, attribution paths, versions and skill names pass. No version value changes in this branch.

All fifteen recorded mutation recipes were executed through the stable `mutation-check.sh` harness — the first fourteen on Python 3.9.6 and Bash 3.2.57, and recipe 15 on Python 3.14.2 and Bash 5.3.9, the interpreter available when the painted-pair recipe was added. Every selected case turned red under its mutation and green after restoration; all five mutated inputs were restored byte-for-byte. The two render-wiring recipes independently remove the full instruction and its required clause.

| Recipe | Selected case | Mutated / restored |
|---|---|---|
| 1 | `dver-11-frozen-copy` | red / green |
| 2 | `dver-12-source-link-loss` | red / green |
| 3 | `dver-13-clipping` | red / green |
| 4 | `dver-25-repair-budget-zero` | red / green |
| 5 | `dver-29-skill-full-resolution` | red / green |
| 6 | `dver-30-skill-deck-overview` | red / green |
| 7 | `dver-31-skill-critical-blocks` | red / green |
| 8 | `dver-32-skill-qualified-verdict` | red / green |
| 9 | `dver-33-skill-frozen-content` | red / green |
| 10 | `dver-42-skill-repair-budget` | red / green |
| 11 | `dver-34-render-wiring` | red / green |
| 12 | `dver-40-render-repair-report` | red / green |
| 13 | `dver-41-render-frozen-copy` | red / green |
| 14 | `dver-34-render-wiring` | red / green |
| 15 | `dver-46-painted-contrast-html` | red / green |
