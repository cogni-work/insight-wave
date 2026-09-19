# PPTX smoke evidence

Recorded application evidence for decks rendered by `design-render --target pptx`. The package, relationship, frozen-copy, chart and editability checks run on every suite run (`tests/test-design-render-pptx.sh`); what no suite can run is a real presentation application opening and editing a deck, so that evidence is recorded here. Grade it by reading it.

## Fixture decks

Rendered from the plugin directory with the fixture theme `tests/fixtures/render/themes/cogni-work`. A deck is byte-deterministic — `generated_at` and `run_id` live only in the manifest and provenance — so these digests reproduce from the same inputs, on Python 3.9.6 and 3.14.2 alike.

| Fixture | Brief / composition | Slides | Objects (editable unless a declared fallback) | Fallbacks | `deck.pptx` sha256 |
|---|---|---|---|---|---|
| narrative | `tests/fixtures/narrative-slides-v1.expected.json` / `tests/fixtures/composition-narrative-v2.json` | 9 | 52 | 0 | `9de003679d7c1e74330fb6be6821f47aa8e901f26debb3cc7da4d47fd063abcb` |
| costs | normalized `tests/fixtures/direct-costs-v1.json` / `tests/fixtures/composition-direct-costs-v2.json` | 4 | 18 | 0 | `dcaa4698ad123ed871a29a275433e80d556a35450afcc8ade718a4cf9576895a` |
| German edge | normalized `tests/fixtures/render/direct-de-edge-v1.json` / `tests/fixtures/render/composition-direct-de-edge-v2.json`, `--language de` | 6 | 36 | 0 | `a27f6858b9311f1da832395f084af77f363e1a52acc0d4fe7e4831f1f93697ac` |
| feedback loop | normalized `tests/fixtures/render/direct-loop-v1.json` / `tests/fixtures/render/composition-direct-loop-v2.json` | 4 | 18 (17 editable, 1 declared fallback picture) | 1 | `bf4cc9434eed6926262c96c4aaeadecbfb1e6b11a7c6659ed8ab49f9d8091f81` |
| wrapped chart label | normalized `tests/fixtures/render/direct-wrap-v1.json` / `tests/fixtures/render/composition-direct-wrap-v2.json` | 4 | 18 | 0 | `e7daee79da21472dea03a0174f25eea9d940b27dba807da7afd8a0addb2a202f` |

The feedback-loop deck is the one fixture that carries a declared fallback: the `conceptual-system/feedback-loop` return track as a picture, a PNG primary with the SVG in its blip extension. Its digest reproduces on Python 3.9.6 and 3.14.2. None of the application results below were recorded against it — see the pending section at the end. The wrapped-chart-label deck has its own section below.

The digests change whenever the writer's output changes on purpose; re-record this table in the same change. A changed digest also voids every application result below that was recorded against the old one: re-perform those checks on the new decks before citing them.

**Re-recorded narrative digest, 2026-09-19.** A fresh render from the current merged inputs produced `9de003679d7c1e74330fb6be6821f47aa8e901f26debb3cc7da4d47fd063abcb` (9 slides, 52 editable objects, no fallback). The prior digest `21ac934faa070bf2e63309877c6929da1409342cc3335a351071c7b5fe7a5650` is historical only. All narrative application results below are **pending** for the new bytes, including LibreOffice open, PowerPoint no-repair open, text and connector edits, and speaker notes. The table and invalidated results are corrected together in this change, satisfying the re-record-in-the-same-change rule. The maintainer will test directly and report new issues; no new application pass is claimed here.

**Re-recorded costs and German-edge digests.** When the writer began taking its figure geometry from `render_core`'s shared helpers, the costs and German-edge decks changed from `5812a8134d9ca0436f612a5e4ed3976b3a91fbda87c7b7a974bcc7c7f818ca55` and `8bf2030565b0c2e92545ad888855264407ca1e689eeac0cdb343acc86d2b0902` to the digests in the table, and the table was not re-recorded then. The shared chart row, which makes every row of a chart as tall as its tallest label, left both decks, the then-current narrative deck and the feedback-loop deck byte-identical: none of their charts has a label that wraps. The table now carries the digests that reproduce, on Python 3.9.6 and 3.14.2 alike. The application results below that were recorded against the two old digests are relabelled accordingly: LibreOffice was re-performed on the new decks, and the Microsoft PowerPoint results for them are **pending**.

**Re-recorded chart-deck digests: the chart's text alternative and zero bound.** The chart frame now carries a `descr` text alternative — the variant's purpose from the pattern library, never copy. A chart whose values share one sign also pins its value axis at zero. That changed three decks:

| Deck | Old digest | New digest |
|---|---|---|
| costs | `6d80b37ba8c2468b152848f6fa2384105cb3867139cd80c340661b896631da07` | the table's |
| German edge | `b2c1e6b8facdf39258c1dfc8ed06b193fdbbd2fe9ce02ca13385429a3d6a63d0` | the table's |
| wrapped chart label | `9ccf302345582dbe9b077017cdffca300efc00895da6b5accf1b2715b4c069e9` | the table's |

At that chart-only change, the narrative and feedback-loop decks carried no chart and stayed byte-identical; the later narrative change is recorded separately above. The new digests reproduce on Python 3.9.6 and 3.14.2 alike.

LibreOffice was re-performed on the three new decks on 2026-09-14, with the same build as below. Each deck exported with exit 0, to 4, 6 and 4 pages. Every page, rasterised at 96 dpi with pdftoppm 25.09.1, is pixel-identical to the same page of the old deck, rasterised the same way. So the LibreOffice reads below carry over to the new digests, the wrapped deck's bar-offset column among them. Every Microsoft PowerPoint result for these three decks is **pending**.

## LibreOffice Impress — recorded

- **Application:** LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2.
- **Open:** `soffice --headless --convert-to pdf` on each of the three decks exited 0, and each PDF has exactly one page per slide (9, 4 and 6). A visual read of the PDFs showed every text frame, the native bar chart with its bars on one zero line and its labels and literal values on their rows, the system nodes joined by labelled elbow connectors, the notes-free cover, and the register with its linked URLs. That read was recorded against the old narrative digest; the current narrative deck’s LibreOffice open is **pending**. For the costs and German-edge decks it was recorded against their old digests, so it was **re-performed on 2026-09-14** on the decks in the table, with the same LibreOffice build on the same macOS, as `soffice -env:UserInstallation=file://<scratch-profile> --headless --convert-to pdf --outdir <dir> <deck>.pptx`. Both runs exited 0 with PDFs of 4 and 6 pages, one per slide. The same visual read holds: every text frame, the German copy with its umlauts and its literal `<script>` and `&amp;` text, the bars on one zero line beside their labels and literal values, the system's labelled elbow connectors, and the linked register.
- **Edit:** not recorded. An unattended edit round trip through LibreOffice's bundled scripting interpreter was attempted; macOS terminated that interpreter at launch (SIGKILL, code-signing launch-constraint violation — the embedded helper may only be launched by LibreOffice itself), so no edit result exists from this host.

LibreOffice is a lenient reader: it opens packages that Microsoft PowerPoint would offer to repair. A clean LibreOffice open is therefore necessary evidence, not sufficient evidence, for the no-repair-prompt criterion.

## Microsoft PowerPoint — recorded

- **Application:** Microsoft PowerPoint 16.112.4 on macOS 26.6.2, opened by a human, 2026-09-14.
- **Open:** the narrative, costs and German-edge decks opened with **no repair prompt**. The narrative result was recorded against its old digest; its current PowerPoint no-repair open is **pending**. The costs and German-edge opens were of those decks at their old digests (`5812a813…` and `8bf20305…`, see the re-recorded digests above), so for the costs and German-edge decks now in the table the PowerPoint open is **pending**.
- **What that caught first.** The writer's first output — the same decks with an empty `p:normalViewPr` in `ppt/viewProps.xml` — made PowerPoint offer to repair all three, while LibreOffice had opened them without complaint. Patching only that part made PowerPoint open them cleanly, which isolated the defect; the writer now emits `restoredLeft` and `restoredTop`, and the historical output was byte-identical to those patched decks; later changes invalidate application results as noted above. `check-pptx` now rejects a missing required child as `package-schema`, and `drpx-22` holds that guard to a deck written the old way.
- **Edit:** three object classes are checked: text, the system diagram's shapes and connectors, and chart values through Edit Data. A person performed all three on the decks as the table then recorded them — the narrative and costs decks both at their old digests: text and chart data in the first session, from screenshots of PowerPoint and Excel, and the diagram in a second session later the same day:
  - **Text — confirmed on the old narrative deck; pending on the current one.** The narrative deck's register headline was edited in place, from "Sources" to "Sources test": it is live text.
  - **Diagram shapes and connectors — confirmed on the old narrative deck; pending on the current one.** In Microsoft PowerPoint 16.112.4 on macOS 26.6.2, the person opened the narrative deck (sha256 `21ac934faa070bf2e63309877c6929da1409342cc3335a351071c7b5fe7a5650`) at its fourth slide, `u-slide-3`, the conceptual system "Three converging forces make action urgent". They dragged a node shape to a new position: the `converges-with` elbow connectors glued to it followed. They then edited that node's label text in place. They report both steps behaved as expected. A screenshot of the session shows a connector selected with both ends attached to its node shapes. The package-level guard, `drpx-11-editable-shapes`, proves one node shape per entity and each connector glued to exactly its two nodes; this historical record shows PowerPoint honoured the glue on the old deck; the current deck’s diagram/connector edit is **pending**.
  - **Chart data — confirmed on the old costs deck; pending on the current one.** The result below was recorded against the costs deck at its old digest, `5812a813…`; on the costs deck now in the table it is **pending**. On that deck, **Edit Data** opened the embedded workbook in Excel with `million euros` in B1, the four labels in A2–A5 and the values in B2–B5, shown as 13, 2,1, 0,9 and 1,4 in the German locale — the numeric values of the brief's literals 13.0, 2.1, 0.9 and 1.4. Changing B2 from 13 to 20 made the top bar grow: the chart is live, editable data.
  - **Speaker notes — confirmed on the old decks; pending on the current narrative and costs decks.** The notes pane shows each slide's notes: the talk track followed by the trailer notes on the narrative register slide, and "State the total first; the chart carries the four components." on the costs answer slide. The costs half was seen on the costs deck at its old digest, so on the costs deck now in the table it is **pending**.
  - **Links — present, not opened.** Every `[n]` cite and every register URL renders as a hyperlink. Opening one in the browser was **not demonstrated**; the package-level check that each target equals its source URL byte for byte is `drpx-13`.

## Declared fallback deck — pending

Every check below is **pending**: no person has opened the feedback-loop deck (sha256 `bf4cc9434eed6926262c96c4aaeadecbfb1e6b11a7c6659ed8ab49f9d8091f81`) in an application, so no result for it may be cited anywhere yet. The package-level guards run on every suite run — `drpx-27` for the picture's structure, `drpx-28` for its manifest entry, `drpx-29` and `drpx-30` for the checker's fallback arms.

- **LibreOffice Impress open — pending.** Whether the deck opens and the return track shows beside the native nodes.
- **Microsoft PowerPoint open — pending.** Whether the deck opens with no repair prompt.
- **SVG display — pending.** Whether an SVG-capable PowerPoint shows the SVG drawing rather than the PNG primary, and whether an application without SVG support shows the PNG.
- **Editability beside the picture — pending.** Whether the nodes, connectors and kind labels on that slide stay editable, and whether the picture is selectable as one non-editable image.

## Wrapped chart label deck

A native bar chart spreads its categories evenly over its plot area. A chart point's label row, though, is as tall as the plan measures it. So when one label wraps and the others do not, the bars stay on their label rows only if every row of that chart is the same height. This deck is the witness for that.

- **Inputs.** Brief `tests/fixtures/render/direct-wrap-v1.json`, normalized; composition `tests/fixtures/render/composition-direct-wrap-v2.json`; theme `tests/fixtures/render/themes/cogni-work`. The brief is the costs brief with one change: the `wage-premium` label reads "Wage premium paid to technicians who cover short-notice shifts on nights and weekends", 85 characters. The chart's labels are set at the body size, 15 px with a 1.6 line height, in a label column that holds 59 characters of the resolved `system-ui` face (465.6 px at 0.52 em). So that label takes two lines, and "Unplanned downtime", "Insurance surcharges" and "Compliance retrofit" take one each.
- **Render.** From the plugin directory, with the normalized brief's `data` object saved as `<brief>`:

  ```bash
  python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/render/direct-wrap-v1.json
  python3 scripts/design-render.py render --target pptx --brief <brief> --composition tests/fixtures/render/composition-direct-wrap-v2.json --theme tests/fixtures/render/themes/cogni-work --out <dir>
  ```

  `deck.pptx` sha256 `e7daee79da21472dea03a0174f25eea9d940b27dba807da7afd8a0addb2a202f` (re-recorded when the chart frame gained its text alternative and its zero bound; see the note below the fixture table). It reproduces from a second render with another `--generated-at` and `--run-id`, and on Python 3.9.6 and 3.14.2 alike. The deck has 4 slides and 18 objects, all editable, with no fallback.
- **Method: offsets derived from the package.** For point *i*, counted from the top because the category axis is `c:orientation val="maxMin"`, the category band's centre is:

  graphicFrame `a:off y` + `c:manualLayout` `y` × `a:ext cy` + (*i* + 0.5) × `c:manualLayout` `h` × `a:ext cy` / `c:ptCount`

  The plot area's manual layout is `inner`, in `edge` mode, with `y` 0 and `h` 1. The label row's centre is the `copy:data:<id>#label` frame's `a:off y` + `a:ext cy` / 2. The offset is the label row's centre minus the band's centre, in px (EMU / 9525). `drpx-33-wrapped-chart-alignment` computes the same numbers with the suite's own reader on every run and requires each to be at most 0.5 px.
- **Before the shared row.** The writer sized each point's row from its own label. Rendered from the same inputs, that writer's deck (sha256 `45c1bf8421aa5f5fe09dd4cc1a79bb2a425837e1c760f910b1801390f3c476f0`) had rows of 40 / 60 / 40 / 40 px under a 180 px chart frame. The derived offsets were −2.50 / +2.50 / +7.50 / +2.50 px, beyond the 0.5 px tolerance, so a remedy was due.
- **With the shared row.** Every row takes the tallest label's `max(lines × line height, 28 px) + spacing-3`, which is 60 px here, set once in `render_core.series_rows` for the plan and both targets. The chart frame is 240 px tall, each band is 60 px, and the derived offsets are 0.00 / 0.00 / 0.00 / 0.00 px. Every label and value frame still equals the plan's row, the chart and its workbook carry exactly the brief's four labels and literals, and no text shrinks.

| Point | Label lines | Row before (px) | Offset before (px) | Row after (px) | Offset after (px) | LibreOffice, after (px) |
|---|---|---|---|---|---|---|
| `downtime` | 1 | 40 | −2.50 | 60 | 0.00 | −0.36 |
| `wage-premium` | 2 | 60 | +2.50 | 60 | 0.00 | −0.09 |
| `insurance-surcharge` | 1 | 40 | +7.50 | 60 | 0.00 | +0.15 |
| `compliance-retrofit` | 1 | 40 | +2.50 | 60 | 0.00 | +0.42 |

- **LibreOffice Impress open — recorded.** Performed on 2026-09-14 with LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2:
  - The command was `soffice -env:UserInstallation=file://<scratch-profile> --headless --convert-to pdf --outdir <dir> deck.pptx`. It exited 0 and wrote a 4-page PDF, one page per slide.
  - On the chart slide, every bar sits on its label's row, beside its literal value, with the wrapped label's two lines centred on the second bar. No bar crosses into a neighbouring row.
  - Read from the PDF's bar paths in slide px (PDF points × 4 / 3), each bar's centre is within 0.5 px of its label row's centre: the last column of the table, label row minus bar.
  - The deck from before the shared row, opened the same way (exit 0, 4 pages), showed what its derived offsets predict. The second and third bars sat visibly high on their rows, and the PDF put the label-row-minus-bar offsets at −2.87 / +2.39 / +7.64 / +2.90 px, within 0.4 px of the derived −2.50 / +2.50 / +7.50 / +2.50.

  LibreOffice is a lenient reader, so this open is necessary evidence, not sufficient evidence, for PowerPoint.
- **Microsoft PowerPoint open — pending.** No person has opened this deck in Microsoft PowerPoint. Three things stay open. Whether the deck opens with no repair prompt. Whether PowerPoint honours the inner plot area filling the whole chart frame, with no chart-area padding of its own, so that each bar sits on its label row. And whether rows sized to the tallest label read acceptably on the slide beside a single two-line label.

## Proof decks

These are the two decks of the design-verify two-brand proof, one per bundled brand: `docs/design-verify-proof/boardroom/pptx/deck.pptx` (sha256 `0dddf52dbb4bdc0d87419febebcc2119835ee2bb2b486c1a6291e7873dacd44b`) and `docs/design-verify-proof/editorial/pptx/deck.pptx` (sha256 `a5a2aa950fc6dfddd7e3a585dbf5a2848447edac6f06ba4d6fefed46c184f043`). Each has 6 slides and no fallback picture. [`design-verify-proof.md`](design-verify-proof.md) gives their inputs and reproduce commands; its package-level edit witnesses are not application results.

- **LibreOffice Impress open — recorded.** Performed on 2026-09-14 with LibreOffice 25.8.1.1 (`54047653041915e595ad4e45cccea684809c77b5`), headless, on macOS 26.6.2, as `soffice -env:UserInstallation=file://<scratch-profile> --headless --convert-to pdf --outdir <dir> deck.pptx`. Both runs exited 0, each writing a 6-page PDF, one page per slide. Every slide was then read at 96 dpi, and one detail again at 192 dpi, for the visual review (`docs/design-verify-proof/review-record.json`). That read found: every text frame; the answer and its accent rule; the four comparison rows; the native bar chart with its bars on one zero line, each beside its label and literal value; the three system nodes joined by labelled `depends-on` connectors; and the linked register. The committed overviews are `docs/design-verify-proof/overview/boardroom-pptx.png` and `editorial-pptx.png`, each stacking all six rasterised slides in order at 640 px wide. LibreOffice is a lenient reader, so this open is necessary evidence, not sufficient evidence, for PowerPoint.
- **Microsoft PowerPoint open — pending.** No person has opened either proof deck in Microsoft PowerPoint. Whether it opens with no repair prompt stays open.
- **Microsoft PowerPoint edit — pending.** The text edit, the Edit Data chart edit and what the accessibility checker reports for the chart's text alternative all stay open.
