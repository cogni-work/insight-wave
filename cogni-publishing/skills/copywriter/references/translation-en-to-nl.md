---
title: Translation EN → NL
type: writing-principle
category: core-principles
tags: [translation, en-nl, u-vorm, ascii, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation EN → NL

<context>
Applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = nl`. Faithful semantic transfer into grammatical Dutch prose; Step 3 applies Dutch clarity discipline (Flesch-Douma readability, active voice). Generic preserve-vs-translate rules live in `translation-principles.md`. Dutch business prose is essentially ASCII — see the charset note below.
</context>

## Register: U-vorm by Default

Business documents address the reader with the formal **u**, not **je/jij**. `you can` → `u kunt`; `your team` → `uw team`. Use **je** only for casual B2C copy, and flag it.

## Charset: ASCII (No Special Diacritics)

Dutch business prose needs **no** special diacritic set. A trema (`ë`, `ï`) marks a separate syllable in a few words (`reëel`, `coördinatie`) and `é` survives in a handful of loanwords (`café`, `coördinator`), but these are exceptions, not a required set. Produce them where Dutch orthography demands, but do not invent diacritics. Step 5 charset validation treats NL as the lenient case: it only checks that no German umlauts leak in from an EN source containing brand names.

## Syntax and Idiom Deltas

- **Verb-second + clause-final verbs.** Dutch sends the non-finite verb to the end of subordinate clauses: `omdat het concurrentievermogen ervan afhangt`. Produce grammatical V2 order; Pass B will tighten clause length.
- **Compounds are written closed.** Unlike French/Italian, Dutch *does* form closed compounds: `cloud migration strategy` → `cloudmigratiestrategie` (or hyphenate for clarity: `cloud-migratiestrategie`).
- **Separable verbs.** `to carry out` → `uitvoeren`, splitting in main clauses (`wij voeren … uit`).

## Number, Date, Currency Conventions

| English | Dutch |
|---|---|
| `35%` | `35%` (no space; `35 %` also seen) |
| `1,234,567` | `1.234.567` (period thousands) |
| `1.5 million` | `1,5 miljoen` (comma decimal) |
| `$5.6M` / `€5.6M` | `€ 5,6 mln` or `5,6 miljoen euro` (symbol prefixed, with space) |
| `May 26, 2026` | `26 mei 2026` (lowercase month) |

## Acronyms and Citations

Acronyms pass through unchanged (Step 3 expands per audience). Citation markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Worked Example

**EN source:**
```
A recent study [P1-1](https://www.example.org/study-2025) finds only about 35% of mid-sized firms have a comprehensive strategy.
```

**Pass-A NL output:**
```
Uit een recent onderzoek [P1-1](https://www.example.org/study-2025) blijkt dat slechts ongeveer 35% van de middelgrote bedrijven over een volledige strategie beschikt.
```

Note: marker byte-identical; clause-final verb `beschikt`; ASCII throughout; u-register implied.

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `active-voice-principles.md` — Pass B discipline.
