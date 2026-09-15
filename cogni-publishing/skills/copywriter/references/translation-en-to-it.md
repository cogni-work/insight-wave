---
title: Translation EN → IT
type: writing-principle
category: core-principles
tags: [translation, en-it, forma-di-cortesia, accents, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation EN → IT

<context>
Applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = it`. Faithful semantic transfer into grammatical Italian prose; Step 3 applies Italian clarity discipline (Flesch-Vacca readability, active voice, shorter clauses). Generic preserve-vs-translate rules and the charset table live in `translation-principles.md`.
</context>

## Register: Forma di Cortesia (Lei)

Business documents address the reader with the courtesy form **Lei** (third-person singular, capitalised), not **tu**. `you can` → `Lei può`; `your team` → `il Suo team` (capitalised courtesy possessive). Plural/institutional address uses **Voi** sparingly. Use **tu** only for casual B2C copy, and flag it.

## Accent Correctness

Italian uses grave accents on most final stressed vowels (`à è ì ò ù`) and acute on final stressed `é` (`perché`, `affinché`). They are obligatory.

| Source EN | Wrong IT | Right IT |
|---|---|---|
| `city` | `citta` | `città` |
| `because` | `perche` | `perché` |
| `it is` | `e` | `è` (verb, vs `e` "and") |
| `more` | `piu` | `più` |

Step 5 rejects bare finals where Italian requires the accent — note especially `è` (is) vs `e` (and).

## Syntax and Idiom Deltas

- **Compounds become `di` phrases.** `cloud migration strategy` → `strategia di migrazione verso il cloud`.
- **Adjectives usually follow the noun.** `digital transformation` → `trasformazione digitale`.
- **Articles combine with prepositions.** `of the company` → `dell'azienda`; `in the model` → `nel modello`.

## Number, Date, Currency Conventions

| English | Italian |
|---|---|
| `35%` | `35%` (no space; `35 %` also acceptable) |
| `1,234,567` | `1.234.567` (period as thousands separator) |
| `1.5 million` | `1,5 milioni` (comma decimal) |
| `$5.6M` / `€5.6M` | `5,6 mln €` or `5,6 milioni di euro` |
| `May 26, 2026` | `26 maggio 2026` (lowercase month) |

## Acronyms and Citations

Acronyms pass through unchanged (Step 3 expands per audience). Citation markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Worked Example

**EN source:**
```
A recent study [P1-1](https://www.example.org/study-2025) finds that only about 35% of mid-sized firms have a comprehensive strategy.
```

**Pass-A IT output:**
```
Uno studio recente [P1-1](https://www.example.org/study-2025) rileva che solo circa il 35% delle imprese di medie dimensioni dispone di una strategia completa.
```

Note: marker byte-identical; `35%` Italian spacing; `è`/accent discipline ready for Pass B; Lei-register implied.

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `active-voice-principles.md` — Pass B discipline.
