---
title: Translation Principles (Two-Pass Translate-then-Polish)
type: writing-principle
category: core-principles
tags: [translation, en-de, de-en, two-pass, citations, preservation]
audience: [all]
related:
  - german-style-principles
  - acronym-handling-principles
  - clarity-principles
  - citation-formatting
version: 1.0
last_updated: 2026-05-19
---

# Translation Principles

<context>
You are running the translation pass (Step 2.5 of the copywriter workflow). Your output is an intermediate target-language draft. The Step 3 polish pass will apply target-language style discipline (Wolf-Schneider for German, Flesch targets for English, audience-tuned acronym expansion) on top of your output. Do not pre-empt Step 3's job.
</context>

## Why Two Passes

A single combined translate-and-polish pass conflates two failure modes. When the output is wrong, you cannot tell whether the meaning slipped (translation problem) or the style is off (polish problem). Splitting the work gives a clear diagnosis:

- **Pass A (this step)** — faithful semantic transfer from source to target language. Sentence structure may stay close to the source. Wolf-Schneider rules do not apply yet.
- **Pass B (Step 3)** — target-language style discipline. Break long sentences, restructure Satzklammer, expand acronyms per audience, hit Flesch/Amstad targets.

Failures in Pass A are translation failures (wrong word, lost nuance, broken citation). Failures in Pass B are style failures (clause too long, Floskel slipped in). The diagnostic clarity is worth the extra pass.

## Translate vs Preserve

Translate the prose. Preserve the scaffolding. The list below is exhaustive — when in doubt, preserve.

### Translate (target language)

- Body paragraphs, sentences, clauses
- Heading text (H1, H2, H3) — except when `arc_id` is present (arc-mode translation is blocked in v1)
- Image captions, table cell prose, list item prose
- Block-quote prose
- Bold and italic phrase content (preserve the formatting markers, translate the text inside)

### Preserve byte-identical

- **URLs** — every `https://...` string. URLs never localize.
- **Citation markers** — `[P1-1]`, `[P1-1](https://...)`, `<sup>[1]</sup>`, `[portfolio-validated]`. Marker format, identifier, and URL all stay exactly as written.
- **Code blocks** — fenced (```` ``` ````) and inline (`` ` ``) — never translated, even if they contain natural-language strings (those are likely identifiers).
- **Technical IDs** — `arc_id`, `entity_ref`, `source_url`, schema keys, filenames, paths.
- **Frontmatter** — the entire YAML block. Add `target_language:` if not already set, but do not translate existing values.
- **Protected content** (the four categories listed under `SKILL.md` § "Protected Content"):
  - `<diagram-placeholder>` XML blocks (full structure including child elements)
  - `Figure N` / `Abbildung N` numeric references — but `Figure` ↔ `Abbildung` itself stays in the source-language form if it appears in inline prose; the numeric identifier never changes
  - `![[assets/*.svg]]` Obsidian embeds
  - Kanban tables with `| Dimension | Act | Plan | Observe |` headers, wikilinks, legends, and `<!-- kanban-board -->` placeholders
- **Power Position structure markers** — `**IS**:`, `**DOES**:`, `**MEANS**:` and standalone `IS` / `DOES` / `MEANS` arc-element labels. These are structural, not vocabulary.
- **Proper nouns and brand names** — `BSI`, `KRITIS-Dachgesetz`, `Magenta Security`, `Open Telekom Cloud`, `SAP S/4HANA`. Regulation acronyms (`NIS2`, `DSGVO`, `DORA`) stay in their original form. The audience-tuned acronym expansion that runs in Step 3 will handle any first-mention parentheticals on the target-language output.
- **Number values inside data points** — keep numeric magnitudes (`5.6`, `40`, `2026`) and currency symbols/codes (`$`, `€`, `EUR`) faithful to the source. Apply target-language *formatting conventions* (thin-space vs no-space before `%`, comma vs period as decimal/thousands separator, currency-symbol position) per the direction guide (`translation-en-to-de.md` / `translation-de-to-en.md`). The acronym/expansion discipline still runs in Step 3.

## Citation-Anchored Translation

Citation markers are atomic. Translate the surrounding sentence; do not disturb the marker. The marker sits inside the sentence at the source position; keep it at the equivalent position in the target sentence.

**EN source:**
```
Industry research indicates that organizations using traditional monitoring approaches experience an average of 15 major incidents per month [P1-2](https://www.pagerduty.com/state-of-digital-ops-2025).
```

**DE target (correct):**
```
Branchenstudien zeigen, dass Organisationen mit klassischen Monitoring-Ansätzen durchschnittlich 15 schwere Vorfälle pro Monat erleben [P1-2](https://www.pagerduty.com/state-of-digital-ops-2025).
```

The marker `[P1-2](https://www.pagerduty.com/state-of-digital-ops-2025)` is byte-identical. The prose around it is translated. The marker stays at the end of the sentence because that is where it sits in the source.

**Validation rule:** after the translate pass, the regex count of `\[P\d+-\d+\]` (and any other citation-marker patterns present in the source) in the output must equal the count in the source. URLs from those markers must all be present in the output. Step 5 enforces this.

## Compound-Noun Strategies

Translation direction changes the noun strategy.

- **EN → DE** — English noun phrases (`the cloud migration strategy`) often map to German compounds (`die Cloud-Migrationsstrategie`) or hyphenated forms. Prefer the compound when it reads naturally; fall back to a preposition phrase (`die Strategie für die Cloud-Migration`) when the compound would exceed ~25 characters or three constituents. See `translation-en-to-de.md` for the heuristic.
- **DE → EN** — German compounds (`Digitalisierungsstrategie`) decompose into English noun phrases (`digitalization strategy`) or, in extreme cases, full clauses. Do not transliterate the compound. See `translation-de-to-en.md` for the rules.

## Audience Expansion is Step 3's Job

Do NOT expand acronyms in the translate pass. The `AUDIENCE`-tuned first-mention expansion runs in Step 3 on the translated text, so any `NIS2 (...)` parenthetical is added downstream. If you expand here, Step 3 may double-expand or skip the expansion. Pass through acronyms unchanged.

The one exception is when the source already contains a parenthetical (e.g., `MDR (Managed Detection and Response)`). Translate both halves: `MDR (Managed Detection and Response — ein Dienstleister erkennt und stoppt Angriffe rund um die Uhr für Sie)` for DE-lay audiences is what Step 3 will produce, but in Pass A simply translate the existing parenthetical (`MDR (Managed Detection and Response)` stays as is since the Vollform happens to be English-only) — Step 3 will add or extend the gloss.

## Per-Direction References

Load the matching direction file for source-target-specific rules:

- **EN → DE** — `translation-en-to-de.md`
- **DE → EN** — `translation-de-to-en.md`

These files contain the linguistic specifics (Satzklammer setup, gender resolution, compound decomposition) that the generic principles above do not cover.
