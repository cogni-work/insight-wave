---
title: Translation DE → IT
type: writing-principle
category: core-principles
tags: [translation, de-it, compound-decomposition, forma-di-cortesia, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-it
  - clarity-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation DE → IT

<context>
Applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = it`. Faithful semantic transfer into grammatical Italian; Step 3 applies Italian clarity discipline (Flesch-Vacca readability). The **Italian-production rules** (Lei register, accent correctness incl. `è`/`e`, number/date/currency conventions) are identical to the EN→IT direction — read `translation-en-to-it.md` for them. This file covers only the **German-source** deltas.
</context>

## German-Source Deltas

- **Map Sie → Lei.** German `Sie`-register maps to the Italian courtesy form **Lei**; `Ihr Team` → `il Suo team`.
- **Decompose German compounds into `di`-phrases.** `Digitalisierungsstrategie` → `strategia di digitalizzazione`. No closed compounds in Italian.
- **Flatten the Satzklammer.** `Wir haben … migriert` → `Abbiamo migrato …` (participle next to the auxiliary).
- **Split overlong German sentences** so Pass B can reach Italian clause-length targets.

## Compound Decomposition Examples

| German | Italian |
|---|---|
| `Wettbewerbsfähigkeit` | `competitività` |
| `Geschäftsführung` | `direzione` / `consiglio di gestione` |
| `Bestandsaufnahme` | `analisi dello stato attuale` |
| `IT-Betriebsmodell` | `modello operativo IT` |

## Acronyms, Citations, Charset

Acronyms pass through (Step 3 expands). Citation markers + URLs byte-identical at the equivalent position. Italian accent charset rule per `translation-principles.md` § "Per-Language Charset Rules".

## Worked Example

**DE source:**
```
Wir haben etwa 75 % unserer Workloads erfolgreich in die Cloud migriert [P1-1](https://www.example.org/cloud-2025) und liegen damit über dem Zeitplan.
```

**Pass-A IT output:**
```
Abbiamo migrato con successo circa il 75% dei nostri carichi di lavoro verso il cloud [P1-1](https://www.example.org/cloud-2025), risultando così in anticipo sul calendario.
```

Note: Satzklammer flattened (`Abbiamo migrato`); `75%` Italian spacing; marker byte-identical; Lei-register.

## Cross-References

- `translation-en-to-it.md` — full Italian-production rules (register, accents, numbers, idiom).
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
