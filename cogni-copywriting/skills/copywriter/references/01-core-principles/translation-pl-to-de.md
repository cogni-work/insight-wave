---
title: Translation PL → DE
type: writing-principle
category: core-principles
tags: [translation, pl-de, false-friends, umlaut, sie-form, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-de
  - german-style-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation PL → DE

<context>
Applies to the Step 2.5 translate pass when `source_lang = pl` and `TARGET_LANG = de`. Faithful semantic transfer into grammatical German; Step 3 applies Wolf-Schneider style discipline (`german-style-principles.md`). The **German-production rules** — Sie-register, umlaut/eszett correctness, Satzklammer formation, compound vs preposition-phrase choice, gender resolution — are identical to the EN→DE direction. Read `translation-en-to-de.md` for them. This file covers only the **Polish-source** deltas.
</context>

## German-Production Rules: See EN→DE

Produce correct German exactly as `translation-en-to-de.md` specifies: **Sie** by default, umlauts/eszett at write time, grammatical Satzklammer, compound handling, gender resolution.

## Polish-Source Deltas

- **Map Pan/Pani/Państwo → Sie.** Polish formal address maps to German `Sie`; `Państwa zespół` → `Ihr Team`.
- **Add articles.** Polish has none; German requires `der/die/das` with correct gender and case.
- **Recompose case-phrases into German compounds.** `strategia cyfryzacji` (noun + genitive) → `Digitalisierungsstrategie`.
- **Resolve Polish free word order into German Satzklammer.** Reorder to verb-second with the participle/infinitive at the clause end.
- **Watch false friends.** `aktualnie` = "derzeit", `ewentualnie` = "gegebenenfalls/möglicherweise", `sympatyczny` = "sympathisch/nett", `dywan` = "Teppich" not "divan". Verify.
- **Number conversion PL → DE.** `35%` → `35 %` (add thin space); `1 234 567` → `1.234.567`; `1,5 miliona` → `1,5 Millionen`; `5,6 mln zł` stays PLN (`5,6 Mio. zł`), `5,6 mln €` → `5,6 Mio. €`; `26 maja 2026` → `26. Mai 2026`.

## Worked Example

**PL source:**
```
Z niedawnego badania [P1-1](https://www.example.org/badanie-2025) wynika, że tylko 35% firm dysponuje kompleksową strategią.
```

**Pass-A DE output:**
```
Eine aktuelle Studie [P1-1](https://www.example.org/badanie-2025) zeigt, dass nur 35 % der Unternehmen über eine umfassende Strategie verfügen.
```

Note: umlauts present (`über`, `umfassende`); articles added (`der`, `eine`); `35%` → `35 %` thin space; marker byte-identical.

## Cross-References

- `translation-en-to-de.md` — full German-production rules.
- `german-style-principles.md` — Pass B Wolf-Schneider discipline.
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
