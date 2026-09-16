---
title: Translation IT → DE
type: writing-principle
category: core-principles
tags: [translation, it-de, false-friends, umlaut, sie-form, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-de
  - german-style-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation IT → DE

<context>
Applies to the Step 2.5 translate pass when `source_lang = it` and `TARGET_LANG = de`. Faithful semantic transfer into grammatical German; Step 3 applies Wolf-Schneider style discipline (`german-style-principles.md`). The **German-production rules** — Sie-register, umlaut/eszett correctness, Satzklammer formation, compound vs preposition-phrase choice, gender resolution — are identical to the EN→DE direction. Read `translation-en-to-de.md` for them. This file covers only the **Italian-source** deltas.
</context>

## German-Production Rules: See EN→DE

Produce correct German exactly as `translation-en-to-de.md` specifies: **Sie** by default, umlauts/eszett at write time (never `ae/oe/ue/ss`), grammatical Satzklammer, compound-vs-`von`-phrase heuristic, gender resolution.

## Italian-Source Deltas

- **Map Lei → Sie.** Italian courtesy form maps to German `Sie`; `il Suo team` → `Ihr Team`.
- **Recompose `di`-phrases into German compounds.** `strategia di digitalizzazione` → `Digitalisierungsstrategie`.
- **Watch false friends.** `eventualmente` = "möglicherweise" (not "eventuell"-as-"definitely"), `sensibile` = "empfindlich", `argomento` = "Thema" not "Argument", `educato` = "höflich". Verify.
- **Number conversion IT → DE.** `35%` → `35 %` (add thin space); `1.234.567` thousands shared; `1,5 milioni` → `1,5 Millionen`; `5,6 mln €` → `5,6 Mio. €`; `26 maggio 2026` → `26. Mai 2026`.

## Worked Example

**IT source:**
```
Uno studio recente [P1-1](https://www.example.org/studio-2025) mostra che solo il 35% delle imprese dispone di una strategia completa.
```

**Pass-A DE output:**
```
Eine aktuelle Studie [P1-1](https://www.example.org/studio-2025) zeigt, dass nur 35 % der Unternehmen über eine umfassende Strategie verfügen.
```

Note: umlauts present (`über`, `umfassende`); `35%` → `35 %` thin space added; marker byte-identical.

## Cross-References

- `translation-en-to-de.md` — full German-production rules.
- `german-style-principles.md` — Pass B Wolf-Schneider discipline.
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
