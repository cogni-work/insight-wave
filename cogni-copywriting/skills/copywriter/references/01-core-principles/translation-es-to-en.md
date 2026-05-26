---
title: Translation ES → EN
type: writing-principle
category: core-principles
tags: [translation, es-en, false-friends, sentence-splitting, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation ES → EN

<context>
Applies to the Step 2.5 translate pass when `source_lang = es` and `TARGET_LANG = en`. Faithful semantic transfer into grammatical English; Step 3 applies English clarity targets (15–20 word sentences, 80% active voice, Flesch 50–60). Generic preserve-vs-translate rules live in `translation-principles.md`.
</context>

## Target Charset: No Accents

English output carries **no** Spanish accents or `ñ` except inside preserved proper nouns (`España` in names, `Telefónica` brands) or quoted Spanish terms. Drop the inverted `¿`/`¡` — English does not use them. Step 5 charset validation rejects stray `á/é/í/ó/ú/ñ` in EN output that are not proper nouns.

## Split Long Spanish Sentences

Spanish favours long subordinate chains. Split when a sentence exceeds ~25 words.

**ES source (~31 words):**
```
La creciente integración de los procesos empresariales, junto con la mayor importancia del análisis de datos, exige una revisión profunda de la infraestructura informática y de los modelos de negocio.
```

**Pass-A EN output (two sentences):**
```
Business processes are increasingly integrated, and data analysis matters more than before. Together these forces require a deep overhaul of IT infrastructure and business models.
```

## False Friends

| Spanish | Wrong (calque) | Right English |
|---|---|---|
| `actualmente` | "actually" | "currently" |
| `eventualmente` | "eventually" | "occasionally / possibly" |
| `sensible` | "sensible" | "sensitive" |
| `éxito` | "exit" | "success" |
| `asistir` | "assist" | "to attend" |
| `realizar` | "realize" | "to carry out" |

## Number, Date, Currency Conversion

| Spanish | English |
|---|---|
| `35 %` | `35%` (no space) |
| `1.234.567` (period thousands) | `1,234,567` |
| `1,5 millones` (comma decimal) | `1.5 million` |
| `5,6 M€` | `€5.6M` or `EUR 5.6 million` |
| `26 de mayo de 2026` | `May 26, 2026` or `2026-05-26` |

## Proper Nouns Stay Spanish

Institution names keep their Spanish form on first mention with a parenthetical when needed: `AEPD (Spain's data-protection agency)` first; bare `AEPD` after. Step 3's acronym discipline adds the parenthetical — do not expand here.

## Citations

Markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `conciseness-principles.md` / `active-voice-principles.md` — Pass B discipline.
