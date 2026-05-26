---
title: Translation Principles (Two-Pass Translate-then-Polish)
type: writing-principle
category: core-principles
tags: [translation, multilingual, en-de, de-en, fr, it, pl, nl, es, two-pass, citations, preservation, charset, dispatch-matrix]
audience: [all]
related:
  - german-style-principles
  - acronym-handling-principles
  - clarity-principles
  - citation-formatting
version: 1.1
last_updated: 2026-05-26
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
- Heading text (H1, H2, H3) — **except arc-element and bridge headings in `arc_mode`**, which are **substituted** (not freely translated) from the canonical target-language set in `09-preservation-modes/arc-preservation.md` (see SKILL.md Step 2.5). EN↔DE arc-mode translation ships for `corporate-visions` and `jtbd-portfolio`; other arcs and non-EN/DE pairs stay blocked (#318).
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

## Readability in Translation Mode

The absolute Flesch (EN 50–60) and Amstad (DE 30–50) bands are tuned for content *produced fresh* in the target language. A faithful translation inherits the source's information density — Latinate B2B vocabulary, multi-syllable compounds, regulatory terms — so rewriting to hit the absolute band crosses into paraphrase and risks unfaithful translation. The Step 5 translation validator therefore uses a **relative-to-source rule** instead of the absolute band.

**The rule.** Score source and output on the *target-language* scale; require `output_score ≥ source_score − 5`.

**Same scale on both sides.** Flesch (EN) and Amstad (DE) use different coefficients and cannot be compared cross-scale. Scoring the source on the target-language scale gives a like-for-like baseline. The `--lang` flag on `scripts/calculate_readability.py` already supports this — it applies the matching syllable counter + formula regardless of which language the input prose is actually in. Read the `flesch_score` field from each invocation's JSON:

```bash
python3 scripts/calculate_readability.py <source.md> --lang $TARGET_LANG   # source_score = flesch_score
python3 scripts/calculate_readability.py <output.md> --lang $TARGET_LANG   # output_score = flesch_score
```

**The 5-point soft floor.** Covers compound-length drift (EN→DE: German compounds inflate average word length, pushing Amstad down 2–4 points even for a clean rendering) and sentence-splitting drift (DE→EN: long German sentences often decompose into multiple shorter English ones with their own syllable budgets). Five points is the empirical headroom needed to absorb this without licensing genuine degradation.

**Language-faithful syllable counting.** The Flesch *formula* runs on the target-language scale (per the rule above), but the *syllable counter* always reflects the actual source prose: the EN vowel set includes umlauts (so DE words score correctly), and the silent-`e` adjustment is skipped when source prose is detected as non-English. This keeps the score sensitive to information density rather than phonological-rule mismatches. See `scripts/calculate_readability.py` (`count_syllables_en` `source_lang` parameter).

**Step 3 still runs.** Pass B continues to apply target-language style discipline — Wolf-Schneider for DE (12-word clauses, Satzklammer, Floskel elimination); 15–20 word sentences and 80%+ active voice for EN. The relative rule is a *floor*, not a *ceiling*: landing inside the absolute band is still preferable, just not required. If translation work *can* hit the absolute band without paraphrasing source vocabulary, do so.

See `SKILL.md` § Step 5 "Translation-specific validation" → "Readability relative to source" for the validator wiring.

## Per-Language Charset Rules

Each target language has a required diacritic set. The translate pass must produce these characters at write time — never ASCII substitutes — and Step 5 validation rejects output that violates the rule. This table is the single source of truth; `SKILL.md` Step 5 and `copy-json` Step 3 both point here.

| Target | Required diacritics | ASCII substitutes (forbidden) |
|---|---|---|
| `de` | ä ö ü ß (+ uppercase) | ae oe ue ss |
| `fr` | é è ê ç (also à â ë î ï ô û ù) | bare a/e/c |
| `it` | à è é ì ò ù | bare a/e/i/o/u |
| `pl` | ą ć ę ł ń ó ś ź ż | bare a/c/e/l/n/o/s/z |
| `es` | á é í ó ú ñ (also ¿ ¡) | bare a/e/i/o/u, n for ñ |
| `nl` | none (ASCII) — Dutch business prose needs no special diacritics | n/a |
| `en` | none — output must contain **no** ä/ö/ü/ß except inside preserved proper nouns or quoted source-language terms | n/a |

When translating **into** EN, the charset rule is *absence*: the only umlauts/accents permitted are inside preserved proper nouns (`Müller`, `Citroën`) or explicitly quoted source-language terms.

## Per-Direction References (Deterministic Dispatch)

There is exactly one direction file per valid pair, named `translation-{source}-to-{target}.md`. After loading this `translation-principles.md` hub, construct the filename from the resolved `source_lang` and `TARGET_LANG` and load it:

```
LOAD: references/01-core-principles/translation-{source_lang}-to-{TARGET_LANG}.md
```

These files contain the linguistic specifics (register, diacritic traps, compound handling, clause-splitting, number/date conventions, worked example) that the generic principles above do not cover.

### Validity matrix (which pairs have a direction file)

Slice 1 (#255) supports any direction with **EN or DE on one end** — the lingua-franca pivot. Direct non-EN/DE pairs are Phase 3 and are rejected by the Step 1 pivot guard before this dispatch runs. The diagonal is a no-op (source == target).

| src \ tgt | en | de | fr | it | pl | nl | es |
|---|---|---|---|---|---|---|---|
| **en** | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **de** | ✓ | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| **fr** | ✓ | ✓ | — | ✗ | ✗ | ✗ | ✗ |
| **it** | ✓ | ✓ | ✗ | — | ✗ | ✗ | ✗ |
| **pl** | ✓ | ✓ | ✗ | ✗ | — | ✗ | ✗ |
| **nl** | ✓ | ✓ | ✗ | ✗ | ✗ | — | ✗ |
| **es** | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | — |

✓ = direction file exists (22 total: the 2 original EN↔DE + 20 added in Slice 1). ✗ = Phase 3 (pivot via EN or DE, or follow #255). The pre-checks in `SKILL.md` Step 1 guarantee that only ✓ pairs reach the dispatch.
