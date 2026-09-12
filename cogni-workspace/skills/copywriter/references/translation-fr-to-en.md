---
title: Translation FR → EN
type: writing-principle
category: core-principles
tags: [translation, fr-en, false-friends, sentence-splitting, number-formatting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation FR → EN

<context>
Applies to the Step 2.5 translate pass when `source_lang = fr` and `TARGET_LANG = en`. Faithful semantic transfer into grammatical English; Step 3 applies English clarity targets (15–20 word sentences, 80% active voice, Flesch 50–60). Generic preserve-vs-translate rules live in `translation-principles.md`.
</context>

## Target Charset: No Accents

English output carries **no** French accents except inside preserved proper nouns (`Citroën`, `Thales`, place names) or explicitly quoted French terms. Strip accents from translated common nouns. Step 5 charset validation rejects stray `é/è/ê/ç` in EN output that are not part of a proper noun.

## Split Long French Sentences

French tolerates long sentences chained with relative clauses (`qui`, `dont`, `lequel`). English readers prefer shorter units — split when a French sentence exceeds ~25 words.

**FR source (~34 words):**
```
La transformation numérique, qui touche désormais tous les secteurs et bouleverse les modèles économiques établis, exige une refonte profonde de l'infrastructure informatique et des compétences internes.
```

**Pass-A EN output (two sentences):**
```
Digital transformation now reaches every sector and upends established business models. It demands a deep overhaul of IT infrastructure and in-house skills.
```

## False Friends

| French | Wrong (calque) | Right English |
|---|---|---|
| `actuellement` | "actually" | "currently" |
| `éventuellement` | "eventually" | "possibly" |
| `important` (size) | "important" | "large / significant" |
| `contrôler` | "control" | "to check / verify" |
| `assister à` | "assist" | "to attend" |
| `sensible` | "sensible" | "sensitive" |

## Number, Date, Currency Conversion

| French | English |
|---|---|
| `35 %` (thin space) | `35%` (no space) |
| `1 234 567` | `1,234,567` |
| `1,5 million` (comma decimal) | `1.5 million` |
| `5,6 M€` | `€5.6M` or `EUR 5.6 million` (symbol prefixed) |
| `26 mai 2026` | `May 26, 2026` or `2026-05-26` (pick one, stay consistent) |

## Proper Nouns Stay French

Institution and programme names keep their French form on first English mention, with a parenthetical when an English reader cannot reasonably know them: `CNIL (France's data-protection authority)` on first mention; bare `CNIL` thereafter. The audience-tuned acronym expansion in Step 3 adds the parenthetical — do not expand here.

## Citations

Markers and URLs stay byte-identical at the equivalent sentence position (see `translation-principles.md`).

## Cross-References

- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
- `clarity-principles.md` / `conciseness-principles.md` / `active-voice-principles.md` — Pass B discipline.
