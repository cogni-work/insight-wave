# PPTX smoke evidence

Recorded application evidence for decks rendered by `design-render --target pptx`. The package, relationship, frozen-copy, chart and editability checks run on every suite run (`tests/test-design-render-pptx.sh`); what no suite can run is a real presentation application opening and editing a deck, so that evidence is recorded here. Grade it by reading it.

## Fixture decks

Rendered from the plugin directory with the fixture theme `tests/fixtures/render/themes/cogni-work`. A deck is byte-deterministic — `generated_at` and `run_id` live only in the manifest and provenance — so these digests reproduce from the same inputs, on Python 3.9.6 and 3.14.2 alike.

| Fixture | Brief / composition | Slides | Objects (all editable) | Fallbacks | `deck.pptx` sha256 |
|---|---|---|---|---|---|
| narrative | `tests/fixtures/narrative-slides-v1.expected.json` / `tests/fixtures/composition-narrative-v2.json` | 9 | 52 | 0 | `21ac934faa070bf2e63309877c6929da1409342cc3335a351071c7b5fe7a5650` |
| costs | normalized `tests/fixtures/direct-costs-v1.json` / `tests/fixtures/composition-direct-costs-v2.json` | 4 | 18 | 0 | `5812a8134d9ca0436f612a5e4ed3976b3a91fbda87c7b7a974bcc7c7f818ca55` |
| German edge | normalized `tests/fixtures/render/direct-de-edge-v1.json` / `tests/fixtures/render/composition-direct-de-edge-v2.json`, `--language de` | 6 | 36 | 0 | `8bf2030565b0c2e92545ad888855264407ca1e689eeac0cdb343acc86d2b0902` |

The digests change whenever the writer's output changes on purpose; re-record this table in the same change.

## LibreOffice Impress — recorded

- **Application:** LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2.
- **Open:** `soffice --headless --convert-to pdf` on each of the three decks exited 0, and each PDF has exactly one page per slide (9, 4 and 6). A visual read of the PDFs showed every text frame, the native bar chart with its bars on one zero line and its labels and literal values on their rows, the system nodes joined by labelled elbow connectors, the notes-free cover, and the register with its linked URLs.
- **Edit:** not recorded. An unattended edit round trip through LibreOffice's bundled scripting interpreter was attempted; macOS terminated that interpreter at launch (SIGKILL, code-signing launch-constraint violation — the embedded helper may only be launched by LibreOffice itself), so no edit result exists from this host.

LibreOffice is a lenient reader: it opens packages that Microsoft PowerPoint would offer to repair. A clean LibreOffice open is therefore necessary evidence, not sufficient evidence, for the no-repair-prompt criterion.

## Microsoft PowerPoint — recorded

- **Application:** Microsoft PowerPoint 16.112.4 on macOS 26.6.2, opened by a human, 2026-09-14.
- **Open:** all three decks in the table above opened with **no repair prompt**.
- **What that caught first.** The writer's first output — the same decks with an empty `p:normalViewPr` in `ppt/viewProps.xml` — made PowerPoint offer to repair all three, while LibreOffice had opened them without complaint. Patching only that part made PowerPoint open them cleanly, which isolated the defect; the writer now emits `restoredLeft` and `restoredTop`, and its output is byte-identical to those patched decks (the digests above). `check-pptx` now rejects a missing required child as `package-schema`, and `drpx-22` holds that guard to a deck written the old way.
- **Edit:** pending. Still to record, on the same decks:
  1. Edit a text box — for example append a word to the answer headline — and confirm it is live text.
  2. On the costs and German decks, select the chart, choose **Edit Data**, change one value in the embedded workbook, and confirm the bar moves.
  3. Confirm the notes pane shows each slide's speaker notes and a citation such as `[1]` opens its source URL.

Record the results here, replacing this list.
