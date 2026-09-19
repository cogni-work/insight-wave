# Platform render proof

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

The platform manifest binds these four outputs by digest. Run `python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json` to recompute the digests, validate actual-host provenance, read the frozen inputs and review records, and independently verify every artifact. The manifest declares each brief's brands and capabilities, so coverage is explicit and missing or duplicate combinations fail.

## Regression fixtures

Historical outputs in `tests/fixtures/verify/reference-artifacts/` and `artifact-samples/` are immutable verifier inputs, not live platform proof or an available renderer. The test bridge selects exact frozen-input matches and copies bytes; it contains no layout or artifact-generation implementation. Tests mutate those inputs to prove preservation, geometry, contrast, editability, source identity and bounded-repair rejection. Their provenance is explicitly non-live.

## Claude Design handoff comparison

No actual Claude Design reference output exists for this brief. No visual superiority or cross-host execution is claimed. Human application testing remains a maintainer task; committed checks establish artifact structure, preservation and the recorded visual review only.
