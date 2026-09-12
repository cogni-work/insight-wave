---
title: Translation DE → FR
type: writing-principle
category: core-principles
tags: [translation, de-fr, compound-decomposition, vouvoiement, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-fr
  - clarity-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation DE → FR

<context>
Applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = fr`. Faithful semantic transfer into grammatical French; Step 3 applies French clarity discipline (Kandel-Moles readability). The **French-production rules** (vous register, accent correctness, number/date/currency conventions, worked-example style) are identical to the EN→FR direction — read `translation-en-to-fr.md` for them. This file covers only the **German-source** deltas.
</context>

## German-Source Deltas

- **Map Sie → vous.** German `Sie`-register maps directly to French **vous**; `Ihr Team` → `votre équipe`.
- **Decompose German compounds into `de`-phrases.** German agglutinates (`Digitalisierungsstrategie`); French does not. Render as a preposition phrase: `stratégie de numérisation`. Never carry a German-style closed compound into French.
- **Flatten the Satzklammer.** German splits the verb (`Wir haben … migriert`); French keeps the verb together (`Nous avons migré …`). Reorder so the participle sits next to the auxiliary.
- **Split overlong German sentences.** German tolerates 30–40 word periods; aim for French sentences Pass B can bring to 15–20 words.

## Compound Decomposition Examples

| German | French |
|---|---|
| `Wettbewerbsfähigkeit` | `compétitivité` |
| `Geschäftsführung` | `direction` / `comité de direction` |
| `Bestandsaufnahme` | `état des lieux` |
| `IT-Betriebsmodell` | `modèle d'exploitation informatique` |

## Acronyms, Citations, Charset

Acronyms pass through (Step 3 expands). Citation markers + URLs byte-identical at the equivalent position. French accent charset rule per `translation-principles.md` § "Per-Language Charset Rules".

## Worked Example

**DE source:**
```
Wir haben etwa 75 % unserer Workloads erfolgreich in die Cloud migriert [P1-1](https://www.example.org/cloud-2025) und liegen damit über dem Zeitplan.
```

**Pass-A FR output:**
```
Nous avons migré avec succès environ 75 % de nos charges de travail vers le cloud [P1-1](https://www.example.org/cloud-2025), ce qui nous place en avance sur le calendrier.
```

Note: Satzklammer flattened (`avons migré`); `75 %` thin-space retained (same convention both languages); marker byte-identical; vous-register.

## Cross-References

- `translation-en-to-fr.md` — full French-production rules (register, accents, numbers, idiom).
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
