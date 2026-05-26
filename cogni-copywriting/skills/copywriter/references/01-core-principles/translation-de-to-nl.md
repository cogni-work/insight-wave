---
title: Translation DE → NL
type: writing-principle
category: core-principles
tags: [translation, de-nl, compound-handling, u-vorm, number-formatting]
audience: [all]
related:
  - translation-principles
  - translation-en-to-nl
  - clarity-principles
version: 1.0
last_updated: 2026-05-26
---

# Translation DE → NL

<context>
Applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = nl`. Faithful semantic transfer into grammatical Dutch; Step 3 applies Dutch clarity discipline (Flesch-Douma readability). The **Dutch-production rules** (u-vorm register, ASCII charset, closed-compound formation, V2/clause-final verbs, number/date/currency conventions) are identical to the EN→NL direction — read `translation-en-to-nl.md` for them. This file covers only the **German-source** deltas.
</context>

## German-Source Deltas

German and Dutch are close cousins, which helps and traps in equal measure.

- **Map Sie → u.** German `Sie`-register maps to the formal **u**; `Ihr Team` → `uw team`.
- **Compounds usually survive — but re-spell.** Both languages form closed compounds, so `Digitalisierungsstrategie` maps to `digitaliseringsstrategie` — translate the morphemes, do **not** carry German spelling (`-ierung` → `-ering`, `ß` → `ss`, no umlauts).
- **Watch false friends.** `bellen` DE "to bark" vs NL "to call"; `meinen` DE "to think" vs NL `menen`. `See` DE → `meer`/`zee`. Verify, do not assume cognates align.
- **Satzklammer largely transfers** (Dutch also uses V2 + clause-final verbs), but confirm the participle/infinitive lands correctly.

## Morpheme Re-spelling Examples

| German | Dutch |
|---|---|
| `Wettbewerbsfähigkeit` | `concurrentievermogen` |
| `Geschäftsführung` | `directie` / `raad van bestuur` |
| `Bestandsaufnahme` | `inventarisatie` |
| `IT-Betriebsmodell` | `IT-operatiemodel` |

## Acronyms, Citations, Charset

Acronyms pass through (Step 3 expands). Citation markers + URLs byte-identical. Dutch is ASCII — strip any German umlauts/ß; per `translation-principles.md` § "Per-Language Charset Rules".

## Worked Example

**DE source:**
```
Wir haben etwa 75 % unserer Workloads erfolgreich in die Cloud migriert [P1-1](https://www.example.org/cloud-2025) und liegen damit über dem Zeitplan.
```

**Pass-A NL output:**
```
Wij hebben ongeveer 75% van onze workloads succesvol naar de cloud gemigreerd [P1-1](https://www.example.org/cloud-2025), waarmee wij vóór op schema liggen.
```

Note: clause-final `gemigreerd`/`liggen`; ASCII output (no umlauts); marker byte-identical; u-register.

## Cross-References

- `translation-en-to-nl.md` — full Dutch-production rules (register, compounds, V2 order, numbers).
- `translation-principles.md` — preserve-vs-translate, charset table, citation anchoring.
