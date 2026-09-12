# Design Brief Template

The one file Phase 7 hands to Claude Design (claude.ai/design). It is self-contained: a reader with nothing but this file knows the target, the copy, the ceilings the copy was cut to, how citations resolve, and what the renderer may and may not do. `scripts/check-design-brief.py` enforces everything below that is mechanical; the rest is the writer's judgment, exercised once per unit.

Two principles govern every target:

- **Copy is frozen.** Every line on the brief is a verbatim selection from the finished narrative — a sentence, a clause, a phrase, a number with its unit — after `<sup>[N](file)</sup>` has been reduced to `[N]`. The writer selects and drops; it never paraphrases, never rounds, never merges two sentences into one. A line that does not fit a ceiling is replaced by a shorter selection or dropped, and on the slides target the dropped material goes into the `talk_track`. The checker proves the weak form mechanically (every number on the brief occurs in the narrative); the strong form — every line is a substring — is the writer's rule and the reviewer's check.
- **The brief carries its own numbers.** The ceilings Phase 7 applied are written into `density.ceilings` from `references/density-ceilings.md`, so the brief documents the constraint it was cut to and a reader never has to open the reference.

Full worked examples, one per target, are the green fixtures at `cogni-workspace/tests/fixtures/design-brief/` — `slides-en.md`, `document-en.md`, `infographic-en.md`, `web-en.md` and `slides-de.md` — every one derived from a narrative fixture under `tests/fixtures/narrative-output/` and graded green by the checker.

## Document shape

```
---            frontmatter (below)
---

# {Title}
*{Subtitle}*

# Rendering Contract          (de: # Rendering-Vertrag) — five `- ` clauses
{target preamble keys}         executive_summary: / headline: subline: hero_numbers: / hero:
## {Kind} 1: {headline}        units, numbered from 1 without gaps
...
cta: {one line}                infographic and web only
note: ...                      four meta-instructions
**Sources**                    the narrative's block, verbatim
```

Units are `## Slide N:` (slides), `## Section N:` (document, web) or `## Block N:` (infographic). The kind word is a machine marker and stays English in a German brief; the headline after it is in the brief's language. Inside a unit, fields are column-0 `key:` lines: an inline scalar (`type: bluf`), a `- ` list (`slide_points:`), or a prose block running to the next key (`talk_track:`, `body:`). No fenced blocks anywhere. Field order inside a slide unit is fixed: `type`, optional `evidence_status`, `element`, `visual_intent`, then the copy fields, then `talk_track`; the other targets retain their target-specific grammar below.

## Frontmatter

| Key | Targets | Value |
|-----|---------|-------|
| `type` | all | `design-brief` |
| `version` | all | `"1.1"`, quoted |
| `target` | all | `slides` \| `document` \| `infographic` \| `web` |
| `language` | all | `en` \| `de`, the narrative's |
| `arc_id`, `arc_display_name` | all | from the narrative's frontmatter |
| `title` | all | the narrative's title, quoted |
| `governing_thought` | all | the TL;DR's first sentence, verbatim, `[N]` markers kept |
| `source_narrative` | all | path of the narrative the brief was cut from |
| `target_length` | document | the narrative's `target_length`; the body band is computed from it |
| `theme_path` | all, optional | the caller's `--theme-path`, verbatim; never resolved, never prompted |
| `decision_required` | all, optional | copied from resolved narrative frontmatter; never inferred or invented in the brief |
| `management_ask` | all, optional | copied from resolved narrative frontmatter; never inferred or invented in the brief |
| `density.profile` | all | `standard`; `dense` is defined for infographic only |
| `density.ceilings` | all | every key of the target's table in `references/density-ceilings.md`, same values |
| `design` | slides, web | `register`, `dark_slides` (slides), `speaker_notes` (slides), `imagery`, `variations` — the presentation-intent fields, defaults below |
| `key_figures` | all, optional | 3-6 hero numbers lifted out of prose, each verbatim and ending `(src: [N])` |
| `climax` | slides, infographic, web | the unit number of the point of emphasis, a bare integer |

`design` defaults, from the presentation-intent layer this skill shares with `libraries/presentation-intent.md`: `register: quiet-executive`, `dark_slides: []`, `speaker_notes: full-script`, `imagery: none`, `variations: 1`. A caller override is recorded verbatim.

## Rendering Contract

Five `- ` clauses under the localized heading, placed after the subtitle and before the first preamble key or unit. Clauses 1 and 4 are fixed for every target; clauses 2, 3 and 5 are addressed to the target's renderer.

**English.** Clause 1: `Copy is frozen: reproduce every headline, bullet, number and label verbatim — a renderer that rewrites a line has changed the deliverable, not styled it.` (document: "sentence" for "bullet"; infographic: "label, number and point"). Clause 4: `Styling comes only from the theme or the renderer's own design system; the brief carries no color, font, or coordinate, and none may be inferred from its wording.`

The same fence governs the `visual_intent` block (`references/visual-intent.md`): visual intent is semantic, not art direction — it names the relationship the audience must perceive and the idea that must dominate, never how the renderer draws them. This is a principle of the brief, not a sixth clause: the contract stays at five.

| Clause | slides | document | infographic | web |
|--------|--------|----------|-------------|-----|
| 2 | The talk track travels complete into the renderer's native notes channel; truncated or summarized notes are an incorrect rendering. | The executive summary never substitutes for the body; every section's prose travels complete into the document. | Nothing on this brief is renderer guidance to be paraphrased; every line is canvas copy, and a line that does not fit is dropped with the author, never shortened. | Every section's body travels complete onto the page; nothing collapses into a tooltip, an accordion or a read-more. |
| 3 | Citation markers `[N]` become hyperlink runs on the number, and a sources slide built from the Sources block stays last in the deck. | Citation markers `[N]` become footnotes carrying the URL from the Sources block, and the Sources section stays last in the document. | Citation markers `[N]` collapse into one sources footer built from the Sources block; none stays inline on the canvas. | Citation markers `[N]` become footnote anchors, and a sources section built from the Sources block closes the page. |
| 5 | `type` is a content shape: map each unit to the nearest native layout and never invent content to fill one. | The four sections and their order are the deliverable: map each to the nearest native document structure and never add, merge or reorder one. | Block `type` is a content shape: map each block to the nearest native arrangement and never split or pad a block to fill a grid. | Section `type` is a content shape: map each section to the nearest native pattern and never add a section to fix the rhythm. |

**German** (`# Rendering-Vertrag`). Clause 1: `Texte sind eingefroren: Überschriften, Aufzählungen, Zahlen und Beschriftungen exakt übernehmen — wer eine Zeile umformuliert, ändert das Ergebnis, statt es zu gestalten.` Clause 4: `Gestaltung stammt ausschließlich aus dem Theme oder dem Designsystem des Renderers; der Brief enthält keine Farben, Schriften oder Koordinaten, und es dürfen auch keine aus dem Wortlaut abgeleitet werden.` Clauses 2, 3 and 5 are the table above in German, addressed the same way: slides — `Der Sprechtext geht vollständig in den nativen Notizkanal des Renderers; gekürzte oder zusammengefasste Notizen sind eine fehlerhafte Umsetzung.` / ``Zitatmarker `[N]` werden zu Hyperlinks auf der Zahl, und eine aus dem Quellenblock gebaute Quellenfolie bleibt die letzte Folie.`` / `` `type` ist eine Inhaltsform: jede Einheit auf das nächstgelegene native Layout abbilden und niemals Inhalte erfinden, um eines zu füllen.`` The document, infographic and web German clauses translate their English row with the same discipline: real umlauts and ß, no anglicism where a German word is precise.

## The `type` enum

Every unit on the slides, infographic and web targets carries `type:`, one of `cover`, `bluf`, `two-column`, `table`, `timeline`, `quote`, `metric`, `roles`, `sources` — the presentation-intent tags, reused for every target because Claude Design reads a content shape, not a layout name. Pick by content: the title unit is `cover`; the TL;DR and the close are `bluf`; a list of parallel positions is `roles`; stacked costs or a comparison is `table`; a sequence of dated forces is `timeline`; a contrast is `two-column`; a hero-number moment is `metric`; a verbatim voice is `quote`. The trailing source register is `sources`: the renderer builds it from the narrative's `**Sources**` block verbatim, so it carries no invented bullets and is the one unit exempt from the `slide_points` requirement. `cover` stays available to the infographic and web targets; only the slides derivation stops emitting it. The document target carries no `type:` — its four sections are the arc's elements and the renderer's document structure follows them.

## Unit grammar per target

### slides

```
## Slide N: {assertion headline, ≤110 characters}

type: {enum}
evidence_status: {direct | triangulated | proxy | interpretation | mixed}    optional
element: {1-4}            only on a unit cut from one of the four elements
visual_intent:                            required on every copy-bearing unit; see references/visual-intent.md
  message_pattern: {enum}
  relationship: {the semantic relationship}
  focal_point: {what must dominate}
  preferred_expression: {enum}         optional hint, never a mandate
  asset_signal: {enum}                optional hint, never a mandate
slide_points:
- {≤10 words; ≤20 when type is table}     at most 4 lines
- ...

talk_track:
{prose; ≤450 words; ≥150 on an element unit}
```

`evidence_status` records the strongest label the unit's underlying claims genuinely support: `direct` for a claim stated by a supplied source; `triangulated` when several supplied sources independently support it; `proxy` when a source uses a broader or adjacent measure; `interpretation` for the narrative's own strategic inference; and `mixed` only when a unit deliberately combines statuses. It is metadata, not frozen on-slide copy. Surface it only where the design system has a neutral evidence-status pattern; otherwise keep it in notes.

Derivation: `bluf` carrying the Executive TL;DR, with the narrative title as its headline or kicker and the subtitle integrated there → one unit per element in arc order, or two when the element exceeds 300 words and each half keeps at least 150 words of `talk_track` → a `metric` unit when `key_figures` carries three or more entries → a closing `bluf` carrying the decision implication → a `sources` unit built from the `**Sources**` block verbatim. That is seven to twelve units. The deck opens on the answer, not on a title card: no standalone `cover` unit is emitted for slides. When the count exceeds `--max-units`, re-merge split elements starting with the smallest `## Composition` share, then drop the optional `metric` unit; never drop slide 1, an arc element, the decision close where it adds distinct content, or the final `sources` unit. An element unit's `talk_track` is the element's prose, verbatim and complete unless it exceeds 450 words, in which case the unit is split. `climax` defaults to the decision close, else the `metric` unit when present, else the last element unit — never the `sources` unit.

### document

```
executive_summary:
{the Executive TL;DR verbatim: 2-4 sentences, 60-100 words}

## Section N: {the narrative's N-th `##` heading, byte-equal}

body:
{the element's prose verbatim, paragraphs kept, `[N]` markers kept}
```

Exactly four sections. The bodies total the narrative's body word count, which the checker holds inside `band_lower`–`band_upper` × `target_length`. No `type:`, no `design:`, no `climax`, no `visual_intent:`. This is the one target where nothing is cut: the document generator consumes the whole narrative, and the brief's value is the contract, the summary lead and the resolved sources.

### infographic

```
headline: {≤12 words}
subline: {≤15 words}
hero_numbers:
- {figure} — {label ≤4 words} (src: [N])       3-5 lines
## Block N: {block title}

type: {enum}
visual_intent:                            optional but recommended; see references/visual-intent.md
  message_pattern: {enum}
  relationship: {the semantic relationship}
  focal_point: {what must dominate}
  preferred_expression: {enum}         optional hint, never a mandate
  asset_signal: {enum}                optional hint, never a mandate
points:
- {≤6 words}
cta: {one line}
```

Three to eight blocks (fourteen under `profile: dense`); on-brief words — headline, subline, hero labels, block titles, points and the CTA — at most 150 (250 dense). The compression is severe on purpose: a 2,000-word narrative becomes about 100 words, all of them numbers, labels and one assertion. Nothing else survives; the narrative stays beside the brief for anyone who needs the argument.

### web

```
hero:
  headline: {≤10 words, ≤70 characters}
  subline: {≤25 words}

## Section N: {assertion headline, ≤12 words, ≤70 characters}

type: {enum}
visual_intent:                            optional but recommended; see references/visual-intent.md
  message_pattern: {enum}
  relationship: {the semantic relationship}
  focal_point: {what must dominate}
  preferred_expression: {enum}         optional hint, never a mandate
  asset_signal: {enum}                optional hint, never a mandate
body:
{≤50 words, 2-3 sentences}
bullets:                        optional, ≤8 words each
- ...
quote: {≤30 words}              optional, with
attribution: {≤10 words}
cta: {one line}
```

Six to ten sections. Derivation: one `bluf` section from the TL;DR, then one or two sections per element in arc order, choosing the sentences with the numbers, then a `metric` section for the decisive figure. The `cta:` line closes the page.

## Trailer

After the last unit (and the `cta:` line where the target has one), four `note:` lines the renderer must honour — English: `copy is frozen — reproduce every line verbatim`, `render citations as footnotes and keep the URLs` (infographic: `render citations as one sources footer and keep the URLs`), `attach theme.md only when no organization design system is configured`, `the units and their order are the deliverable — ask before adding, merging or reordering` (with "units" as slides, sections or blocks); German: `Texte sind eingefroren — jede Zeile wörtlich übernehmen`, `Zitate als Fußnoten rendern und die URLs erhalten`, `theme.md nur anhängen, wenn kein Designsystem der Organisation konfiguriert ist`, `die Einheiten und ihre Reihenfolge sind das Ergebnis — vor dem Hinzufügen, Zusammenlegen oder Umsortieren nachfragen`.

Then the narrative's `**Sources**` block, copied verbatim — every `[N] ` entry with its per-source file, publisher, title, date and URL. Because the block is the narrative's own, every `[N]` a unit carries resolves by construction, and the brief carries every URL the renderer needs for its footnotes, sources slide or footer.

## What the checker proves and what it does not

`check-design-brief.py` proves: the frontmatter type and version; the target and language enums; the contract heading in the brief's language, before unit 1, with five clauses; unit kind and numbering; on slides, that unit 1 is `bluf` and the last unit is `sources`, each named with its unit number; `density.ceilings` equal to the reference row; every ceiling of the target against the units and preamble; every number on the brief present in the narrative; every `[N]` resolving in Sources and no `<sup>` surviving; every `key_figures` / `hero_numbers` entry carrying a resolvable `(src: [N])`; no styling key; that every copy-bearing slides unit carries a well-formed `visual_intent` block, that its keys and enum values are in range, and that no `visual_intent` appears on the document target. It does not prove that a line is a substring of the narrative, that a headline is an assertion, that the `type` fits the content, that the named visual intent is the relationship the evidence supports, or that the selection kept the arc's argument — those are the writer's five judgments, and the reviewer reads for them.
