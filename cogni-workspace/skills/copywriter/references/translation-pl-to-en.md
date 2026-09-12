---
title: Translation PL → EN
type: writing-principle
category: core-principles
tags: [translation, pl-en, false-friends, sentence-splitting, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation PL → EN

<context>
Applies to the Step 2.5 translate pass when `source_lang = pl` and `TARGET_LANG = en`. Faithful semantic transfer into grammatical English; Step 3 applies English clarity targets (15–20 word sentences, 80% active voice, Flesch 50–60). Generic preserve-vs-translate rules live in `translation-principles.md`.
</context>

## Target Charset: No Diacritics

English output carries **no** Polish diacritics (`ą/ć/ę/ł/ń/ó/ś/ź/ż`) except inside preserved proper nouns (`Gdańsk`, `Łódź`, company names) or quoted Polish terms. Step 5 charset validation rejects stray Polish letters in EN output that are not proper nouns.

## Restore Articles and Fix Case-Driven Order

Polish has no articles and uses free, case-driven word order. English needs `a/the` and a fixed S-V-O order. Add articles and normalise order.

**PL source:**
```
Transformacja cyfrowa stanowi dla średnich przedsiębiorstw poważne wyzwanie, którego wiele firm wciąż nie podjęło.
```

**Pass-A EN output (two sentences):**
```
Digital transformation is a serious challenge for mid-sized enterprises. Many companies have still not taken it on.
```

## False Friends and Calque Traps

| Polish | Wrong (calque) | Right English |
|---|---|---|
| `aktualnie` | "actually" | "currently" |
| `ewentualnie` | "eventually" | "possibly / alternatively" |
| `sympatyczny` | "sympathetic" | "likeable" |
| `dewizy` | "devices" | "foreign currency" |
| `ordynarny` | "ordinary" | "vulgar" |

## Number, Date, Currency Conversion

| Polish | English |
|---|---|
| `35%` | `35%` (unchanged) |
| `1 234 567` (space thousands) | `1,234,567` |
| `1,5 miliona` (comma decimal) | `1.5 million` |
| `5,6 mln zł` | `PLN 5.6 million`; `5,6 mln €` → `€5.6M` |
| `26 maja 2026` (genitive month) | `May 26, 2026` or `2026-05-26` |

## Proper Nouns Stay Polish

Institution names keep their Polish form on first mention with a parenthetical when needed: `UODO (Poland's data-protection authority)` first; bare `UODO` after. Step 3's acronym discipline adds the parenthetical.

## Citations

Markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `conciseness-principles.md` / `active-voice-principles.md` — Pass B discipline.
