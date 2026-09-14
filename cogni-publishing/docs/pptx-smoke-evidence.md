# PPTX smoke evidence

Recorded application evidence for decks rendered by `design-render --target pptx`. The package, relationship, frozen-copy, chart and editability checks run on every suite run (`tests/test-design-render-pptx.sh`); what no suite can run is a real presentation application opening and editing a deck, so that evidence is recorded here. Grade it by reading it.

## Fixture decks

Rendered from the plugin directory with the fixture theme `tests/fixtures/render/themes/cogni-work`. A deck is byte-deterministic — `generated_at` and `run_id` live only in the manifest and provenance — so these digests reproduce from the same inputs, on Python 3.9.6 and 3.14.2 alike.

| Fixture | Brief / composition | Slides | Objects (all editable) | Fallbacks | `deck.pptx` sha256 |
|---|---|---|---|---|---|
| narrative | `tests/fixtures/narrative-slides-v1.expected.json` / `tests/fixtures/composition-narrative-v2.json` | 9 | 52 | 0 | `3efdf73854df641da4e0bbf1e1b41d3620ad262ae90cb74f9becf59cccca713c` |
| costs | normalized `tests/fixtures/direct-costs-v1.json` / `tests/fixtures/composition-direct-costs-v2.json` | 4 | 18 | 0 | `64c4a065fa2182a5126d09014e70a7f9b6bb5b4f052355465cec3f74f85d556c` |
| German edge | normalized `tests/fixtures/render/direct-de-edge-v1.json` / `tests/fixtures/render/composition-direct-de-edge-v2.json`, `--language de` | 6 | 36 | 0 | `d6d4103a6b0c20204fb516658d4f0d329642b925a6d31cd2e4a3c0b9d5b6a1fc` |

The digests change whenever the writer's output changes on purpose; re-record this table in the same change.

## LibreOffice Impress — recorded

- **Application:** LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2.
- **Open:** `soffice --headless --convert-to pdf` on each of the three decks above exited 0, and each PDF has exactly one page per slide (9, 4 and 6). A visual read of the PDFs showed every text frame, the native bar chart with its bars on one zero line and its labels and literal values on their rows, the system nodes joined by labelled elbow connectors, the notes-free cover, and the register with its linked URLs.
- **Edit:** not recorded. An unattended edit round trip through LibreOffice's bundled scripting interpreter was attempted; macOS terminated that interpreter at launch (SIGKILL, code-signing launch-constraint violation — the embedded helper may only be launched by LibreOffice itself), so no edit result exists from this host.

LibreOffice is a lenient reader: it opens packages that Microsoft PowerPoint would offer to repair. A clean LibreOffice open is therefore necessary evidence, not sufficient evidence, for the no-repair-prompt criterion.

## Microsoft PowerPoint — pending a human

Not yet recorded. Driving PowerPoint's interface or scripting it raises operating-system permission prompts that an unattended run cannot answer. To record it, render the three fixture decks as above (their digests must match the table), then for each:

1. Open the deck in Microsoft PowerPoint and confirm no repair prompt appears.
2. Edit a text box — for example append a word to the answer headline — and confirm it is live text.
3. On the costs and German decks, select the chart, choose **Edit Data**, change one value in the embedded workbook, and confirm the bar moves.
4. Confirm the notes pane shows each slide's speaker notes and a citation such as `[1]` opens its source URL.

Record the PowerPoint version, the platform, each deck's sha256 and the four results here, replacing this section.
