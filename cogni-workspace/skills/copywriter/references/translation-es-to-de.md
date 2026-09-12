---
title: Translation ES → DE
type: writing-principle
category: core-principles
tags: [translation, es-de, false-friends, umlaut, sie-form, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-de
  - german-style-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation ES → DE

<context>
Applies to the Step 2.5 translate pass when `source_lang = es` and `TARGET_LANG = de`. Faithful semantic transfer into grammatical German; Step 3 applies Wolf-Schneider style discipline (`german-style-principles.md`). The **German-production rules** — Sie-register, umlaut/eszett correctness, Satzklammer formation, compound vs preposition-phrase choice, gender resolution — are identical to the EN→DE direction. Read `translation-en-to-de.md` for them. This file covers only the **Spanish-source** deltas.
</context>

## German-Production Rules: See EN→DE

Produce correct German exactly as `translation-en-to-de.md` specifies: **Sie** by default, umlauts/eszett at write time, grammatical Satzklammer, compound-vs-`von`-phrase heuristic, gender resolution.

## Spanish-Source Deltas

- **Map usted → Sie.** Spanish formal address maps to German `Sie`; `su equipo` → `Ihr Team`.
- **Drop the inverted punctuation.** German does not use `¿`/`¡`; render a normal sentence/question.
- **Recompose `de`-phrases into German compounds.** `estrategia de digitalización` → `Digitalisierungsstrategie`.
- **Watch false friends.** `actualmente` = "derzeit", `eventualmente` = "gelegentlich/möglicherweise", `sensible` = "empfindlich", `realizar` = "durchführen" not "realisieren"-as-"notice". Verify.
- **Number conversion ES → DE.** `35 %` thin-space shared; `1.234.567` thousands shared; `1,5 millones` → `1,5 Millionen`; `5,6 M€` → `5,6 Mio. €`; `26 de mayo de 2026` → `26. Mai 2026`.

## Worked Example

**ES source:**
```
Un estudio reciente [P1-1](https://www.example.org/estudio-2025) muestra que solo el 35 % de las empresas dispone de una estrategia completa.
```

**Pass-A DE output:**
```
Eine aktuelle Studie [P1-1](https://www.example.org/estudio-2025) zeigt, dass nur 35 % der Unternehmen über eine umfassende Strategie verfügen.
```

Note: umlauts present (`über`, `umfassende`); inverted punctuation absent; `35 %` thin space; marker byte-identical.

## Cross-References

- `translation-en-to-de.md` — full German-production rules.
- `german-style-principles.md` — Pass B Wolf-Schneider discipline.
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
