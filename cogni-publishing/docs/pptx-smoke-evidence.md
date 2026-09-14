# PPTX smoke evidence

Recorded application evidence for decks rendered by `design-render --target pptx`. The package, relationship, frozen-copy, chart and editability checks run on every suite run (`tests/test-design-render-pptx.sh`); what no suite can run is a real presentation application opening and editing a deck, so that evidence is recorded here. Grade it by reading it.

## Fixture decks

Rendered from the plugin directory with the fixture theme `tests/fixtures/render/themes/cogni-work`. A deck is byte-deterministic — `generated_at` and `run_id` live only in the manifest and provenance — so these digests reproduce from the same inputs, on Python 3.9.6 and 3.14.2 alike.

| Fixture | Brief / composition | Slides | Objects (all editable) | Fallbacks | `deck.pptx` sha256 |
|---|---|---|---|---|---|
| narrative | `tests/fixtures/narrative-slides-v1.expected.json` / `tests/fixtures/composition-narrative-v2.json` | 9 | 52 | 0 | `21ac934faa070bf2e63309877c6929da1409342cc3335a351071c7b5fe7a5650` |
| costs | normalized `tests/fixtures/direct-costs-v1.json` / `tests/fixtures/composition-direct-costs-v2.json` | 4 | 18 | 0 | `5812a8134d9ca0436f612a5e4ed3976b3a91fbda87c7b7a974bcc7c7f818ca55` |
| German edge | normalized `tests/fixtures/render/direct-de-edge-v1.json` / `tests/fixtures/render/composition-direct-de-edge-v2.json`, `--language de` | 6 | 36 | 0 | `8bf2030565b0c2e92545ad888855264407ca1e689eeac0cdb343acc86d2b0902` |

The digests change whenever the writer's output changes on purpose; re-record this table in the same change. A changed digest also voids every application result below that was recorded against the old one: re-perform those checks on the new decks before citing them.

## LibreOffice Impress — recorded

- **Application:** LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2.
- **Open:** `soffice --headless --convert-to pdf` on each of the three decks exited 0, and each PDF has exactly one page per slide (9, 4 and 6). A visual read of the PDFs showed every text frame, the native bar chart with its bars on one zero line and its labels and literal values on their rows, the system nodes joined by labelled elbow connectors, the notes-free cover, and the register with its linked URLs.
- **Edit:** not recorded. An unattended edit round trip through LibreOffice's bundled scripting interpreter was attempted; macOS terminated that interpreter at launch (SIGKILL, code-signing launch-constraint violation — the embedded helper may only be launched by LibreOffice itself), so no edit result exists from this host.

LibreOffice is a lenient reader: it opens packages that Microsoft PowerPoint would offer to repair. A clean LibreOffice open is therefore necessary evidence, not sufficient evidence, for the no-repair-prompt criterion.

## Microsoft PowerPoint — recorded

- **Application:** Microsoft PowerPoint 16.112.4 on macOS 26.6.2, opened by a human, 2026-09-14.
- **Open:** all three decks in the table above opened with **no repair prompt**.
- **What that caught first.** The writer's first output — the same decks with an empty `p:normalViewPr` in `ppt/viewProps.xml` — made PowerPoint offer to repair all three, while LibreOffice had opened them without complaint. Patching only that part made PowerPoint open them cleanly, which isolated the defect; the writer now emits `restoredLeft` and `restoredTop`, and its output is byte-identical to those patched decks (the digests above). `check-pptx` now rejects a missing required child as `package-schema`, and `drpx-22` holds that guard to a deck written the old way.
- **Edit:** three object classes are checked: text, the system diagram's shapes and connectors, and chart values through Edit Data. A person performed all three on the decks in the table: text and chart data in the first session, from screenshots of PowerPoint and Excel, and the diagram in a second session later the same day:
  - **Text — confirmed.** The narrative deck's register headline was edited in place, from "Sources" to "Sources test": it is live text.
  - **Diagram shapes and connectors — confirmed.** In Microsoft PowerPoint 16.112.4 on macOS 26.6.2, the person opened the narrative deck (sha256 `21ac934faa070bf2e63309877c6929da1409342cc3335a351071c7b5fe7a5650`) at its fourth slide, `u-slide-3`, the conceptual system "Three converging forces make action urgent". They dragged a node shape to a new position: the `converges-with` elbow connectors glued to it followed. They then edited that node's label text in place. They report both steps behaved as expected. A screenshot of the session shows a connector selected with both ends attached to its node shapes. The package-level guard, `drpx-11-editable-shapes`, proves one node shape per entity and each connector glued to exactly its two nodes; this record adds that PowerPoint honours the glue.
  - **Chart data — confirmed.** On the costs deck, **Edit Data** opened the embedded workbook in Excel with `million euros` in B1, the four labels in A2–A5 and the values in B2–B5, shown as 13, 2,1, 0,9 and 1,4 in the German locale — the numeric values of the brief's literals 13.0, 2.1, 0.9 and 1.4. Changing B2 from 13 to 20 made the top bar grow: the chart is live, editable data.
  - **Speaker notes — confirmed.** The notes pane shows each slide's notes: "State the total first; the chart carries the four components." on the costs answer slide, and the talk track followed by the trailer notes on the narrative register slide.
  - **Links — present, not opened.** Every `[n]` cite and every register URL renders as a hyperlink. Opening one in the browser was **not demonstrated**; the package-level check that each target equals its source URL byte for byte is `drpx-13`.
