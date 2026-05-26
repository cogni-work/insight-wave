---
title: Translation NL → EN
type: writing-principle
category: core-principles
tags: [translation, nl-en, false-friends, compound-decomposition, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation NL → EN

<context>
Applies to the Step 2.5 translate pass when `source_lang = nl` and `TARGET_LANG = en`. Faithful semantic transfer into grammatical English; Step 3 applies English clarity targets (15–20 word sentences, 80% active voice, Flesch 50–60). Generic preserve-vs-translate rules live in `translation-principles.md`.
</context>

## Target Charset: No Accents

English output carries no Dutch trema/accents except inside preserved proper nouns. Most Dutch business prose is already ASCII, so this is rarely an issue. Step 5 rejects stray `ë/ï/é` that are not part of a proper noun.

## Decompose Dutch Closed Compounds

Dutch forms closed compounds like German. Decompose into English noun phrases — do not transliterate.

| Dutch | Idiomatic English | Wrong |
|---|---|---|
| `concurrentievermogen` | `competitiveness` | "competitionability" |
| `bedrijfsmodellen` | `business models` | "businessmodels" |
| `gegevensbescherming` | `data protection` | "datasprotection" |
| `dienstverlening` | `service delivery` | "servicedelivering" |

## Reorder Clause-Final Verbs

Dutch sends non-finite verbs to the end of subordinate clauses; English keeps verbs adjacent to subjects. Reorder for natural English.

**NL source:**
```
Omdat het concurrentievermogen van deze ontwikkeling afhangt, moeten bedrijven hun infrastructuur grondig herzien.
```

**Pass-A EN output:**
```
Because competitiveness depends on this shift, companies must thoroughly overhaul their infrastructure.
```

## False Friends

| Dutch | Wrong (calque) | Right English |
|---|---|---|
| `eventueel` | "eventually" | "possibly" |
| `actueel` | "actual" | "current / topical" |
| `controleren` | "control" | "to check" |
| `brutaal` | "brutal" | "cheeky / bold" |

## Number, Date, Currency Conversion

| Dutch | English |
|---|---|
| `35%` | `35%` (unchanged) |
| `1.234.567` (period thousands) | `1,234,567` |
| `1,5 miljoen` (comma decimal) | `1.5 million` |
| `€ 5,6 mln` | `€5.6M` or `EUR 5.6 million` |
| `26 mei 2026` | `May 26, 2026` or `2026-05-26` |

## Proper Nouns Stay Dutch

Institution names keep their Dutch form on first mention with a parenthetical when needed: `AP (the Dutch data-protection authority)` first; bare `AP` after. Step 3's acronym discipline adds the parenthetical.

## Citations

Markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `conciseness-principles.md` / `active-voice-principles.md` — Pass B discipline.
