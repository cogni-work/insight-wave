---
title: Translation EN → FR
type: writing-principle
category: core-principles
tags: [translation, en-fr, vouvoiement, accents, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation EN → FR

<context>
Applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = fr`. Your job is faithful semantic transfer into grammatical French prose. Step 3 polish applies French clarity discipline (15–20 word sentences, active voice, Kandel-Moles readability). You may leave longer sentences for Pass B to tighten. Generic preserve-vs-translate rules and the charset table live in `translation-principles.md`.
</context>

## Register: Vouvoiement by Default

Business documents use **vous**, never **tu**, unless the source is casual B2C copy with no executive audience. Possessives and verbs agree: `your team` → `votre équipe`, `you reduce` → `vous réduisez`. If the source clearly addresses individuals informally, use **tu** but flag it in the validation report.

## Accent Correctness

French accents are not optional — they change meaning (`a` "has" vs `à` "to"; `ou` "or" vs `où` "where"). Produce them at write time; do not rely on a fixup.

| Source EN | Wrong FR | Right FR |
|---|---|---|
| `strategy` | `strategie` | `stratégie` |
| `because` | `a cause de` | `à cause de` |
| `controlled` | `controle` | `contrôlé` |
| `we hope` | `nous esperons` | `nous espérons` |

Cedilla on `ç` before a/o/u (`façon`, `reçu`). Step 5 rejects bare-vowel substitutes where French orthography requires an accent.

## Syntax and Idiom Deltas

- **Prefer preposition phrases over compounds.** English noun stacks (`cloud migration strategy`) become `de`-linked phrases: `stratégie de migration vers le cloud`. Never calque a German-style agglutinated compound.
- **Adjective placement.** Most descriptive adjectives follow the noun: `digital transformation` → `transformation numérique`.
- **Negation is two-part.** `we do not` → `nous ne … pas` (`nous ne disposons pas de`).

## Number, Date, Currency Conventions

| English | French |
|---|---|
| `35%` | `35 %` (espace insécable before %) |
| `1,234,567` | `1 234 567` (space as thousands separator) |
| `1.5 million` | `1,5 million` (comma decimal) |
| `$5.6M` / `€5.6M` | `5,6 M€` or `5,6 millions d'euros` (symbol suffixed) |
| `May 26, 2026` | `26 mai 2026` (no capital on month) |

## Acronyms and Citations

Pass acronyms through unchanged — audience-tuned first-mention expansion is Step 3's job (`acronym-handling-principles.md`). Keep citation markers and URLs byte-identical and at the equivalent sentence position (see `translation-principles.md` § "Citation-Anchored Translation").

## Worked Example

**EN source:**
```
Industry research indicates organizations using legacy monitoring experience 15 major incidents per month [P1-2](https://www.example.org/ops-2025), which is ahead of competitors.
```

**Pass-A FR output (translate only — Pass B tightens):**
```
Les études sectorielles indiquent que les organisations recourant à une supervision héritée subissent en moyenne 15 incidents majeurs par mois [P1-2](https://www.example.org/ops-2025), un niveau supérieur à celui de leurs concurrents.
```

Note: accents present (`héritée`, `supérieur`, `concurrents`); `15` and the marker byte-identical; `%`-style spacing not triggered here; vous-register implied for the reader.

## Cross-References

- `translation-principles.md` — preserve-vs-translate list, charset table, citation anchoring, relative readability rule.
- `clarity-principles.md` / `active-voice-principles.md` — applied by Pass B.
