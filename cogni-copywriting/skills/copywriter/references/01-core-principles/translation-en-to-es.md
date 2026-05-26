---
title: Translation EN → ES
type: writing-principle
category: core-principles
tags: [translation, en-es, usted, accents, inverted-punctuation, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation EN → ES

<context>
Applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = es`. Faithful semantic transfer into grammatical Spanish prose; Step 3 applies Spanish clarity discipline (Szigriszt-Pazos/INFLESZ readability, active voice). Generic preserve-vs-translate rules and the charset table live in `translation-principles.md`.
</context>

## Register: Usted by Default

Business documents address the reader with **usted** (third-person), not **tú**. `you can` → `usted puede` (or implied via the verb form `puede`); `your team` → `su equipo`. Use **tú** only for casual B2C copy, and flag it.

## Accent and Ñ Correctness

Spanish uses the acute accent on stressed syllables that break the default stress rule, and `ñ` is a distinct letter. Both are obligatory.

| Source EN | Wrong ES | Right ES |
|---|---|---|
| `strategy` | `estrategia` (ok) / `migracion` | `migración` |
| `company` | `compania` | `compañía` |
| `also` | `tambien` | `también` |
| `how much` | `cuanto` | `cuánto` |

**Inverted punctuation:** questions and exclamations open with `¿` / `¡` and close with `?` / `!` — `¿Cuál es el riesgo?`. Step 5 rejects bare-vowel substitutes and missing `ñ`.

## Syntax and Idiom Deltas

- **Compounds become `de` phrases.** `cloud migration strategy` → `estrategia de migración a la nube`.
- **Adjectives usually follow the noun.** `digital transformation` → `transformación digital`.
- **Contractions.** `of the` → `del`; `to the` → `al`.

## Number, Date, Currency Conventions

| English | Spanish |
|---|---|
| `35%` | `35 %` (space; `35%` also seen) |
| `1,234,567` | `1.234.567` (period thousands; space also valid) |
| `1.5 million` | `1,5 millones` (comma decimal) |
| `$5.6M` / `€5.6M` | `5,6 M€` or `5,6 millones de euros` |
| `May 26, 2026` | `26 de mayo de 2026` (lowercase month) |

## Acronyms and Citations

Acronyms pass through unchanged (Step 3 expands per audience). Citation markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Worked Example

**EN source:**
```
A recent study [P1-1](https://www.example.org/study-2025) finds only about 35% of mid-sized firms have a comprehensive strategy.
```

**Pass-A ES output:**
```
Un estudio reciente [P1-1](https://www.example.org/study-2025) revela que solo cerca del 35 % de las empresas medianas dispone de una estrategia completa.
```

Note: marker byte-identical; `35 %` Spanish spacing; accents (`revela`, `estrategia`) and `ñ` discipline ready; usted-register implied.

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `active-voice-principles.md` — Pass B discipline.
