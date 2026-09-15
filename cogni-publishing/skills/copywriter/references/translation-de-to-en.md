---
title: Translation DE → EN
type: writing-principle
category: core-principles
tags: [translation, de-en, compound-decomposition, nominal-vs-verbal, sentence-splitting]
audience: [all]
related:
  - translation-principles
  - clarity-principles
  - conciseness-principles
  - active-voice-principles
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-19
---

# Translation DE → EN

<context>
This file applies to the Step 2.5 translate pass when `source_lang = de` and `TARGET_LANG = en`. The Step 3 polish pass that runs after this applies English clarity targets (15–20 word sentences, 80% active voice, 3–5 sentence paragraphs, Flesch 50–60). Your job here is faithful semantic transfer into grammatical English prose. Pass B handles the Flesch tuning.
</context>

## Decompose German Compounds

German compound nouns rarely have one-to-one English equivalents. Decompose them into noun phrases or, in extreme cases, full clauses.

| German | Idiomatic English | Wrong: transliteration |
|---|---|---|
| `Digitalisierungsstrategie` | `digitalization strategy` | "digitalizationstrategy" |
| `Geschäftsführung` | `executive leadership` / `management board` | "businessleadership" |
| `Wettbewerbsfähigkeit` | `competitiveness` (when the compound is lexicalized) | "competitionfähigability" |
| `Datenschutz-Grundverordnung` | `General Data Protection Regulation` (proper-noun expansion of DSGVO) | "data-protection foundation-regulation" |
| `Qualitätssicherungssysteme` | `quality assurance systems` | "qualityassurance-systems" |
| `Bestandsaufnahme` | `inventory` / `current-state assessment` | "stock-uptaking" |

For ambiguous compounds (`Mittelstand` — culturally specific German SME term), prefer a short noun phrase (`mid-sized businesses`) over a calque (`middle-stand`). The first occurrence may carry a one-time parenthetical: `mid-sized businesses (the German Mittelstand)`.

## Split Long German Sentences

German tolerates 30–40 word sentences with multiple subordinate clauses; English readers do not. Split aggressively when a German sentence exceeds 25 words.

**DE source (38 words, one sentence):**
```
Die zunehmende Vernetzung von Geschäftsprozessen, die steigende Bedeutung von Datenanalyse und die wachsenden Kundenerwartungen an digitale Interaktionsmöglichkeiten erfordern eine grundlegende Neuausrichtung der IT-Infrastruktur und der Geschäftsmodelle.
```

**Pass-A EN output (two sentences, ~20 words each):**
```
Three forces are reshaping how mid-sized businesses operate: tighter process integration, the rising importance of data analysis, and growing customer expectations for digital interaction. Together they require a fundamental redesign of IT infrastructure and business models.
```

Pass B (Step 3 English polish) will further tune sentence length to 15–20 words on average and check Flesch score, but Pass A should already deliver readable English structure.

## Replace Nominal with Verbal Style

German leans nominal ("Substantivstil") — long noun phrases describing actions. English leans verbal — verbs carry the meaning. Convert when natural.

| German nominal | English verbal |
|---|---|
| `die Durchführung der Bestandsaufnahme` | `conducting the assessment` |
| `die Implementierung der Strategie erfolgte` | `the team implemented the strategy` |
| `eine Steigerung der Erfolgsquote um 60 %` | `success rates rise by 60%` |
| `die Berücksichtigung der Mitarbeiterkompetenzen` | `accounting for employee skills` |

This is consistent with the active-voice and concrete-verb principles in `clarity-principles.md` and `active-voice-principles.md` that Pass B applies on top.

## Preserve Citation Markers Exactly

Every `[P1-1]`, `[P1-1](https://...)`, `<sup>[1]</sup>` stays byte-identical, including the URL. Translate the surrounding sentence; the marker stays at the equivalent position.

**DE source:**
```
Laut einer aktuellen Studie [P1-1](https://www.bitkom.org/digital-index-2025) haben nur etwa 35 % der deutschen Mittelständler eine umfassende Digitalisierungsstrategie implementiert.
```

**EN target (correct):**
```
A recent study [P1-1](https://www.bitkom.org/digital-index-2025) finds that only about 35% of German mid-sized businesses have implemented a comprehensive digitalization strategy.
```

The marker `[P1-1](https://www.bitkom.org/digital-index-2025)` is identical. Step 5 validation enforces this — any change to marker identifier or URL rejects the output.

## Number and Date Formatting

| German | English |
|---|---|
| `35 %` (thin space) | `35%` (no space) |
| `1.234.567` (period as thousands separator) | `1,234,567` |
| `1,5 Millionen` (comma as decimal) | `1.5 million` |
| `19.05.2026` | `May 19, 2026` or `2026-05-19` (ISO; pick one and stay consistent) |
| `5,6 Mio. €` | `€5.6M` or `EUR 5.6 million` |
| `Q1/2026` | `Q1 2026` |

Currency-symbol position: English typically prefixes (`€5M`), German typically suffixes (`5 Mio. €`). Apply target-language convention.

## Proper Nouns Stay German

Regulation names, agency names, and German-specific institutions keep their original form on first English occurrence, with a parenthetical when the English reader cannot reasonably know them:

- `BSI (Federal Office for Information Security)` on first mention; bare `BSI` thereafter
- `KRITIS-Dachgesetz` (no English translation; can add a parenthetical "Critical-Infrastructure Umbrella Act")
- `DSGVO` / `GDPR` — both are valid; prefer `GDPR` for English-only audiences
- `Mittelstand` — keep German term; add parenthetical "Germany's mid-sized business segment" on first mention

The audience-tuned acronym expansion in Step 3 (`acronym-handling-principles.md`) handles these parentheticals based on `AUDIENCE`. Do not expand here — pass through and let Pass B add the parenthetical.

## Worked Example (from german-with-citations.md)

**DE source:**
```
Die Digitalisierung stellt für viele mittelständische Unternehmen eine große Herausforderung dar.
Laut einer aktuellen Studie [P1-1](https://www.bitkom.org/digital-index-2025) haben nur etwa 35 % der
deutschen Mittelständler eine umfassende Digitalisierungsstrategie implementiert. Dies führt dazu,
dass erhebliche Effizienzpotenziale ungenutzt bleiben und die Wettbewerbsfähigkeit langfristig
gefährdet wird.
```

**Pass-A EN output (translate only — Pass B will tune Flesch and active voice):**
```
Digitalization is a major challenge for many mid-sized businesses.
A recent study [P1-1](https://www.bitkom.org/digital-index-2025) finds that only about 35% of
Germany's mid-sized businesses have implemented a comprehensive digitalization strategy. The
result: significant efficiency gains go untapped, and long-term competitiveness is at risk.
```

Note:
- Citation marker `[P1-1](https://www.bitkom.org/digital-index-2025)` byte-identical.
- `mittelständische Unternehmen` decomposed to `mid-sized businesses`.
- `Mittelständler` rendered as `Germany's mid-sized businesses` on first mention.
- `35 %` (thin space) → `35%` (no space) per English convention.
- Long German sentence split into a shorter setup + a punchy "The result:" sentence — Pass B may tighten further.
- No umlauts present in the English output (Step 5 charset check will pass).
