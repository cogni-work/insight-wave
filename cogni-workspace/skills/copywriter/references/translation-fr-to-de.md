---
title: Translation FR → DE
type: writing-principle
category: core-principles
tags: [translation, fr-de, false-friends, umlaut, sie-form, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-de
  - german-style-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation FR → DE

<context>
Applies to the Step 2.5 translate pass when `source_lang = fr` and `TARGET_LANG = de`. Faithful semantic transfer into grammatical German; Step 3 applies Wolf-Schneider style discipline (`german-style-principles.md`). The **German-production rules** — Sie-register, umlaut/eszett correctness, Satzklammer formation, compound vs preposition-phrase choice, gender resolution — are identical to the EN→DE direction. Read `translation-en-to-de.md` for them. This file covers only the **French-source** deltas.
</context>

## German-Production Rules: See EN→DE

Produce correct German exactly as `translation-en-to-de.md` specifies: **Sie** by default, umlauts/eszett at write time (never `ae/oe/ue/ss`), grammatical Satzklammer (Pass B tightens the Mittelfeld), compound-vs-`von`-phrase heuristic, and gender resolution for loan words.

## French-Source Deltas

- **Map vous → Sie.** French formal address maps straight to German `Sie`; `votre équipe` → `Ihr Team`.
- **Recompose into German compounds.** French `de`-phrases often become German compounds: `stratégie de migration vers le cloud` → `Cloud-Migrationsstrategie`.
- **Watch false friends.** `actuellement` = "derzeit" (not "aktuell" in the English sense), `éventuellement` = "eventuell/möglicherweise", `sensible` = "empfindlich" not "sensibel" in every context. Verify.
- **Number conversion FR → DE.** `35 %` thin-space is shared; `1 234 567` → `1.234.567`; `1,5 million` → `1,5 Millionen`; `5,6 M€` → `5,6 Mio. €`; `26 mai 2026` → `26. Mai 2026` (capitalised month, ordinal dot).

## Worked Example

**FR source:**
```
Une étude récente [P1-1](https://www.example.org/etude-2025) montre que seules 35 % des entreprises disposent d'une stratégie complète.
```

**Pass-A DE output:**
```
Eine aktuelle Studie [P1-1](https://www.example.org/etude-2025) zeigt, dass nur 35 % der Unternehmen über eine umfassende Strategie verfügen.
```

Note: umlauts present (`über`, `umfassende`); `35 %` thin space; marker byte-identical; Sie-context (third-person here, since "Unternehmen" is the subject).

## Cross-References

- `translation-en-to-de.md` — full German-production rules (Sie, umlauts, Satzklammer, compounds, gender).
- `german-style-principles.md` — Pass B Wolf-Schneider discipline.
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
