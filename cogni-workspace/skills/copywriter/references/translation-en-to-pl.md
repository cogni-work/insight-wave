---
title: Translation EN → PL
type: writing-principle
category: core-principles
tags: [translation, en-pl, pan-pani, polish-diacritics, cases, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation EN → PL

<context>
Applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = pl`. Faithful semantic transfer into grammatical Polish prose; Step 3 applies Polish clarity discipline (generic-Flesch fallback readability — see note — and active voice). Generic preserve-vs-translate rules and the charset table live in `translation-principles.md`.
</context>

## Register: Pan / Pani (Formal Direct Address)

Business documents address the reader formally with **Pan** (m.) / **Pani** (f.) plus third-person verb, or the neutral plural **Państwo** for institutional address: `you can` → `mogą Państwo` / `może Pan`. Avoid the informal **ty**. Polish frequently drops the subject pronoun (the verb ending carries person), which is idiomatic — keep it.

## Polish Diacritics

Polish uses nine special letters: `ą ć ę ł ń ó ś ź ż`. They are obligatory and distinctive (no overlap with other supported languages).

| Source EN | Wrong PL | Right PL |
|---|---|---|
| `strategy` | `strategie` | `strategię` (accusative) |
| `enterprises` | `przedsiebiorstw` | `przedsiębiorstw` |
| `competitiveness` | `konkurencyjnosc` | `konkurencyjność` |
| `road` (path) | `droga` (ok) / `sciezka` | `ścieżka` |

Step 5 rejects bare-Latin substitutes where Polish requires `ą/ć/ę/ł/ń/ó/ś/ź/ż`.

## Syntax and Idiom Deltas

- **Seven-case inflection.** Nouns and adjectives decline; numbers govern the case of the counted noun (`35 % firm` — genitive plural). Produce the correct case; Pass B does not fix grammar.
- **Flexible word order, but verb-medial default.** Polish tolerates free order for emphasis; keep the neutral S-V-O unless the source emphasises otherwise.
- **No articles.** Drop English `a/the`; definiteness is contextual.

> **Readability note.** No validated Polish Flesch analogue ships here; Step 3 scores Polish on a generic-Flesch fallback (`calculate_readability.py --lang pl`). This is a *defensible relative approximation* — the Step 5 rule compares source and output on the same PL scale, so internal consistency holds even though the absolute number is not calibrated to Polish norms.

## Number, Date, Currency Conventions

| English | Polish |
|---|---|
| `35%` | `35%` (no space; `35 %` also seen) |
| `1,234,567` | `1 234 567` (space thousands) |
| `1.5 million` | `1,5 miliona` (comma decimal) |
| `$5.6M` / `€5.6M` | `5,6 mln zł` or `5,6 mln €` |
| `May 26, 2026` | `26 maja 2026` (genitive month, lowercase) |

## Acronyms and Citations

Acronyms pass through unchanged (Step 3 expands per audience). Citation markers and URLs stay byte-identical at the equivalent position (see `translation-principles.md`).

## Worked Example

**EN source:**
```
A recent study [P1-1](https://www.example.org/study-2025) finds only about 35% of mid-sized firms have a comprehensive strategy.
```

**Pass-A PL output:**
```
Z niedawnego badania [P1-1](https://www.example.org/study-2025) wynika, że tylko około 35% średnich firm wdrożyło kompleksową strategię.
```

Note: marker byte-identical; diacritics (`że`, `średnich`, `strategię`) present; genitive `firm` after the percentage; subject pronoun dropped.

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring, relative readability rule.
- `clarity-principles.md` / `active-voice-principles.md` — Pass B discipline.
