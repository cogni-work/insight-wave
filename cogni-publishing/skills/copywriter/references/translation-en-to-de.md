---
title: Translation EN → DE
type: writing-principle
category: core-principles
tags: [translation, en-de, satzklammer, compound-nouns, sie-form, umlaut]
audience: [all]
related:
  - translation-principles
  - german-style-principles
  - german-hook-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-19
---

# Translation EN → DE

<context>
This file applies to the Step 2.5 translate pass when `source_lang = en` and `TARGET_LANG = de`. The Step 3 polish pass that runs after this applies Wolf-Schneider rules (`german-style-principles.md`) — that is where Satzklammer-breaking, Mittelfeld-shortening, and Floskel-elimination happen. Your job here is faithful semantic transfer into grammatical German prose. You may produce long sentences; Pass B will break them.
</context>

## Register: Sie by Default

Business documents in the insight-wave ecosystem use **Sie** unless the source explicitly signals informal address (e.g. a casual internal blog post in the source uses "you" in a peer-to-peer way, with no exec audience). When in doubt, use Sie.

- `you reduce diagnostic errors` → `Sie reduzieren Diagnosefehler`
- `your team` → `Ihr Team` (capitalized possessive)
- Verbs conjugate to Sie-form: `Sie haben`, `Sie können`, `Sie sollten`

If the source document is a B2C blog or social copy and clearly addresses individuals casually, use Du — but flag this in the validation report so the user can override.

## Umlaut and Eszett Correctness

The general rule lives in `SKILL.md` § "German Character Preservation" — never substitute ASCII equivalents (ae/oe/ue/ss). In a translate pass, this means the *output* must already contain the correct German characters; relying on a post-translation fixup is fragile. Translator must produce them at write time.

Common translation traps:

| Source EN | Wrong DE output | Right DE output |
|---|---|---|
| `the measure` | `Massnahme` | `Maßnahme` |
| `the executive board` | `Geschaeftsfuehrung` | `Geschäftsführung` |
| `the street` | `Strasse` | `Straße` |
| `for the team` | `fuer das Team` | `für das Team` |

Step 5 validation rejects any output that contains ASCII substitutes where the German lexicon requires umlauts/eszett.

## Satzklammer Formation (Pass A vs Pass B)

German splits verbs into two parts. The finite verb sits in position 2; the rest (infinitive, past participle, separable prefix) lands at the end. Everything between them is the Mittelfeld.

```
Wir haben [... Mittelfeld ...] migriert.
   ^                            ^
   Verb-Teil 1                  Verb-Teil 2
```

In the **translate pass** (this file), produce grammatical Satzklammer constructions — do not flatten German syntax into English-style SVO chains. Pass B (Step 3, `german-style-principles.md`) will shorten the Mittelfeld and break overlong clauses. If your translate-pass Mittelfeld reaches 8–12 words, that is acceptable for now; Pass B handles it.

**EN source:**
```
We have successfully migrated about 75% of our workloads to AWS, which is ahead of schedule.
```

**Acceptable Pass-A output (Satzklammer present, Pass B will tighten):**
```
Wir haben etwa 75 % unserer Workloads erfolgreich nach AWS migriert, was über dem ursprünglichen Zeitplan liegt.
```

Do **not** flatten into:
```
Wir migrierten erfolgreich etwa 75 % unserer Workloads nach AWS, das ist vor dem Plan.
```
The flattened form loses idiomatic German verb placement and produces awkward subordinate-clause phrasing.

## Compound Noun vs Preposition Phrase

English noun phrases (`the cloud migration strategy`) map to either German compounds (`die Cloud-Migrationsstrategie`) or preposition phrases (`die Strategie für die Cloud-Migration`).

Heuristic for choosing:

| Source pattern | Prefer compound when | Prefer preposition phrase when |
|---|---|---|
| 2-noun phrase (`security gap`) | Always (`Sicherheitslücke`) | Never |
| 3-noun phrase (`cloud security posture`) | Reads naturally (`Cloud-Sicherheitslage`) | Compound would exceed ~25 characters or feel artificial |
| 4+-noun phrase (`enterprise IT operations strategy`) | Almost never | Always: `die Strategie für den IT-Betrieb im Unternehmen` |
| Genitive English (`the cost of inaction`) | Almost never | `die Kosten der Untätigkeit` (genitive) or `die Kosten für Untätigkeit` |

Hyphenated compounds are acceptable and often clearer than agglutinated forms: prefer `Cloud-Migrationsstrategie` over `Cloudmigrationsstrategie`.

## Gender Resolution for Technical Terms

When translating a noun whose gender is not obvious in German, follow this priority:

1. **Established German loan-word gender** — `der Server`, `die Cloud`, `das Cloud-Computing`, `der Workflow`, `die API`, `das Backup`, `die App`, `der Container`, `das Kubernetes`.
2. **Analogous German native term** — `die Migration` (`Wanderung`), `der Trend` (`die Tendenz` → masculine in tech usage), `der Container` (`der Behälter`).
3. **Default to neuter for ambiguous English nouns ending in -ing** — `das Caching`, `das Monitoring`, `das Logging`.
4. **Consistency within the document** — once chosen, do not flip gender across the document.

If genuinely ambiguous, flag the term in the validation report rather than guess silently.

## Acronyms: Pass Through Unchanged

The Step 3 audience-tuned acronym expansion (see `acronym-handling-principles.md`) runs after this pass. Do not expand acronyms here, with one exception:

- If the source contains a parenthetical Vollform (e.g. `SIEM (Security Information and Event Management)`), keep both halves and translate any prose around them. Step 3 will adjust for `AUDIENCE`.
- Otherwise leave `NIS2`, `DSGVO`, `BSI`, `DORA`, `MDR`, `SIEM`, `MTTI` unchanged.

## Worked Example (from english-memo.md)

**EN source:**
```
We have successfully migrated about 75% of our workloads to AWS which is ahead of schedule.
The team has been working really hard and we should be proud of what we've accomplished so far.
Performance has improved significantly and we're seeing much better response times across the board.
```

**Pass-A DE output (translate only — Pass B will tighten):**
```
Wir haben etwa 75 % unserer Workloads erfolgreich nach AWS migriert und liegen damit über dem ursprünglichen Zeitplan.
Das Team hat sehr engagiert gearbeitet und kann auf das bisher Erreichte stolz sein.
Die Performance hat sich deutlich verbessert, und wir beobachten durchweg bessere Antwortzeiten.
```

Note:
- Umlauts present (`über`, `für`).
- Sie-form for the implied audience (though "we" here is internal, so wir-form is correct).
- 75% formatted with the German thin space (`75 %`).
- Sentence lengths are reasonable but Pass B (Wolf Schneider) may still split the first sentence further.
- No citations in this source — output count matches.
