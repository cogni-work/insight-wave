---
title: Translation DE → ES
type: writing-principle
category: core-principles
tags: [translation, de-es, compound-decomposition, usted, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-es
  - clarity-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation DE → ES

<context>
Applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = es`. Faithful semantic transfer into grammatical Spanish; Step 3 applies Spanish clarity discipline (Szigriszt-Pazos readability). The **Spanish-production rules** (usted register, accent + `ñ` correctness, inverted `¿¡`, number/date/currency conventions) are identical to the EN→ES direction — read `translation-en-to-es.md` for them. This file covers only the **German-source** deltas.
</context>

## German-Source Deltas

- **Map Sie → usted.** German `Sie`-register maps to **usted**; `Ihr Team` → `su equipo`.
- **Decompose German compounds into `de`-phrases.** `Digitalisierungsstrategie` → `estrategia de digitalización`. No closed compounds in Spanish.
- **Flatten the Satzklammer.** `Wir haben … migriert` → `Hemos migrado …` (participle next to the auxiliary).
- **Split overlong German sentences** for Pass B's Spanish clause targets.

## Compound Decomposition Examples

| German | Spanish |
|---|---|
| `Wettbewerbsfähigkeit` | `competitividad` |
| `Geschäftsführung` | `dirección` / `consejo de dirección` |
| `Bestandsaufnahme` | `análisis de la situación actual` |
| `IT-Betriebsmodell` | `modelo operativo de TI` |

## Acronyms, Citations, Charset

Acronyms pass through (Step 3 expands). Citation markers + URLs byte-identical at the equivalent position. Spanish accent/`ñ` charset rule per `translation-principles.md` § "Per-Language Charset Rules".

## Worked Example

**DE source:**
```
Wir haben etwa 75 % unserer Workloads erfolgreich in die Cloud migriert [P1-1](https://www.example.org/cloud-2025) und liegen damit über dem Zeitplan.
```

**Pass-A ES output:**
```
Hemos migrado con éxito cerca del 75 % de nuestras cargas de trabajo a la nube [P1-1](https://www.example.org/cloud-2025), lo que nos sitúa por delante del calendario.
```

Note: Satzklammer flattened (`Hemos migrado`); `75 %` Spanish spacing; accents (`éxito`, `sitúa`) present; marker byte-identical; usted-register.

## Cross-References

- `translation-en-to-es.md` — full Spanish-production rules (register, accents, ñ, numbers, idiom).
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
