---
title: Translation DE → PL
type: writing-principle
category: core-principles
tags: [translation, de-pl, compound-decomposition, pan-pani, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-pl
  - clarity-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation DE → PL

<context>
Applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = pl`. Faithful semantic transfer into grammatical Polish; Step 3 applies Polish clarity discipline (generic-Flesch fallback readability — see `translation-en-to-pl.md` for the note). The **Polish-production rules** (Pan/Pani register, the `ą/ć/ę/ł/ń/ó/ś/ź/ż` diacritics, seven-case inflection, article dropping, number/date/currency conventions) are identical to the EN→PL direction — read `translation-en-to-pl.md` for them. This file covers only the **German-source** deltas.
</context>

## German-Source Deltas

- **Map Sie → Pan/Pani/Państwo.** German `Sie`-register maps to Polish formal **Pan** (m.) / **Pani** (f.) / **Państwo** (institutional). German `Ihr Team` → `Państwa zespół`.
- **Decompose German compounds.** `Digitalisierungsstrategie` → `strategia cyfryzacji` (noun + genitive), not a single fused word.
- **Flatten the Satzklammer into case-driven order.** German's split verb maps to Polish inflected forms; the participle/verb lands per Polish syntax, not German position.
- **Drop German articles; add Polish case.** German `der/die/das` vanish; the noun takes the case its role and any governing number requires.

## Compound Decomposition Examples

| German | Polish |
|---|---|
| `Wettbewerbsfähigkeit` | `konkurencyjność` |
| `Geschäftsführung` | `zarząd` / `kierownictwo` |
| `Bestandsaufnahme` | `analiza stanu obecnego` |
| `IT-Betriebsmodell` | `model operacyjny IT` |

## Acronyms, Citations, Charset

Acronyms pass through (Step 3 expands). Citation markers + URLs byte-identical. Polish diacritic charset rule per `translation-principles.md` § "Per-Language Charset Rules".

## Worked Example

**DE source:**
```
Wir haben etwa 75 % unserer Workloads erfolgreich in die Cloud migriert [P1-1](https://www.example.org/cloud-2025) und liegen damit über dem Zeitplan.
```

**Pass-A PL output:**
```
Pomyślnie zmigrowaliśmy około 75% naszych obciążeń do chmury [P1-1](https://www.example.org/cloud-2025), wyprzedzając tym samym harmonogram.
```

Note: diacritics (`Pomyślnie`, `obciążeń`, `wyprzedzając`); subject pronoun dropped; marker byte-identical; genitive `obciążeń` after the percentage.

## Cross-References

- `translation-en-to-pl.md` — full Polish-production rules (register, diacritics, cases, numbers, readability note).
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
