---
title: Translation NL → DE
type: writing-principle
category: core-principles
tags: [translation, nl-de, false-friends, umlaut, sie-form, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-de
  - german-style-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation NL → DE

<context>
Applies to the Step 2.5 translate pass when `source_lang = nl` and `TARGET_LANG = de`. Faithful semantic transfer into grammatical German; Step 3 applies Wolf-Schneider style discipline (`german-style-principles.md`). The **German-production rules** — Sie-register, umlaut/eszett correctness, Satzklammer formation, compound vs preposition-phrase choice, gender resolution — are identical to the EN→DE direction. Read `translation-en-to-de.md` for them. This file covers only the **Dutch-source** deltas.
</context>

## German-Production Rules: See EN→DE

Produce correct German exactly as `translation-en-to-de.md` specifies: **Sie** by default, umlauts/eszett at write time (Dutch has none — you must add them where German requires), grammatical Satzklammer, compound handling, gender resolution.

## Dutch-Source Deltas

Dutch and German are close cousins — exploit the structural similarity, but never assume cognate spelling.

- **Map u → Sie.** Dutch formal `u` → German `Sie`; `uw team` → `Ihr Team`.
- **Re-spell shared compounds; add umlauts.** Both form closed compounds, so `digitaliseringsstrategie` → `Digitalisierungsstrategie` (`-ering` → `-ierung`, `ss` → `ß` where required, add umlauts). Do not carry Dutch spelling into German.
- **Watch false friends.** `bellen` NL "to call" vs DE "to bark"; `meer` NL "lake/more" vs DE "Meer" (sea); `aandacht` = "Aufmerksamkeit". Verify cognates.
- **Number conversion NL → DE.** `35%` → `35 %` (add thin space); `1.234.567` thousands shared; `1,5 miljoen` → `1,5 Millionen`; `€ 5,6 mln` → `5,6 Mio. €` (move/format symbol); `26 mei 2026` → `26. Mai 2026`.

## Worked Example

**NL source:**
```
Uit een recent onderzoek [P1-1](https://www.example.org/onderzoek-2025) blijkt dat slechts 35% van de bedrijven over een volledige strategie beschikt.
```

**Pass-A DE output:**
```
Eine aktuelle Studie [P1-1](https://www.example.org/onderzoek-2025) zeigt, dass nur 35 % der Unternehmen über eine umfassende Strategie verfügen.
```

Note: umlauts added (`über`, `umfassende`); `35%` → `35 %` thin space; marker byte-identical.

## Cross-References

- `translation-en-to-de.md` — full German-production rules.
- `german-style-principles.md` — Pass B Wolf-Schneider discipline.
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
