---
title: Translation IT → EN
type: writing-principle
category: core-principles
tags: [translation, it-en, false-friends, sentence-splitting, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation IT → EN

<context>
Applies to the Step 2.5 translate pass when `source_lang = it` and `TARGET_LANG = en`. Faithful semantic transfer into grammatical English; Step 3 applies English clarity targets (15–20 word sentences, 80% active voice, Flesch 50–60). Generic preserve-vs-translate rules live in `translation-principles.md`.
</context>

## Target Charset: No Accents

English output carries **no** Italian accents except inside preserved proper nouns (`Città`-names, `Telecom Italia` brands) or quoted Italian terms. Step 5 charset validation rejects stray `à/è/é/ì/ò/ù` in EN output that are not proper nouns.

## Split Long Italian Sentences

Italian builds long periodic sentences with subordinate chains. Split when a sentence exceeds ~25 words.

**IT source (~32 words):**
```
La crescente integrazione dei processi aziendali, unita all'aumento dell'importanza dell'analisi dei dati, richiede una profonda revisione dell'infrastruttura informatica e dei modelli di business.
```

**Pass-A EN output (two sentences):**
```
Business processes are increasingly integrated, and data analysis matters more than ever. Together these forces require a deep overhaul of IT infrastructure and business models.
```

## False Friends

| Italian | Wrong (calque) | Right English |
|---|---|---|
| `attualmente` | "actually" | "currently" |
| `eventualmente` | "eventually" | "possibly" |
| `sensibile` | "sensible" | "sensitive / noticeable" |
| `argomento` | "argument" | "topic / subject" |
| `fattoria` | "factory" | "farm" |
| `educato` | "educated" | "polite" |

## Number, Date, Currency Conversion

| Italian | English |
|---|---|
| `35%` | `35%` (unchanged) |
| `1.234.567` (period thousands) | `1,234,567` |
| `1,5 milioni` (comma decimal) | `1.5 million` |
| `5,6 mln €` | `€5.6M` or `EUR 5.6 million` |
| `26 maggio 2026` | `May 26, 2026` or `2026-05-26` |

## Proper Nouns Stay Italian

Institution names keep their Italian form on first mention with a parenthetical when needed: `Garante (Italy's data-protection authority)` first; bare `Garante` after. Step 3's acronym discipline adds the parenthetical — do not expand here.

## Citations

Markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `conciseness-principles.md` / `active-voice-principles.md` — Pass B discipline.
