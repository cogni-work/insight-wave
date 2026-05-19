---
title: Example — Audience-Tuned Acronym Expansion (expert / mixed / lay)
type: discipline-example
category: discipline-example
discipline: acronym-handling
language: de
audience: [all]
related:
  - acronym-handling-principles
version: 1.0
last_updated: 2026-05-19
---

# Example — Audience-Tuned Acronym Expansion

## Purpose

This reference shows the acronym-handling discipline applied to the *same source paragraph* across the three audience tiers (`expert`, `mixed`, `lay`). Study what changes per tier and what stays constant — first-mention only, structure markers preserved, proper nouns and brand names left raw.

Use this as a calibration set when polishing DACH security pitches, regulated-industry briefs, or any document whose acronym density makes audience-tuning consequential.

## Source Paragraph (DE, unpolished)

> Unser MDR-Angebot deckt SIEM-Korrelation, Threat-Hunting und Incident Response über Magenta Security ab. Es ist auf §38 BSIG-NIS2 zugeschnitten und reduziert die MTTI auf unter 8 Minuten. Der Compliance-Bezug zu NIS2, DSGVO und den BSI C5-Kontrollen ist im Lieferumfang dokumentiert. Bei einer Folge-Eskalation übergibt das MDR-Team direkt an den Kunden-CISO.

Token inventory: `MDR`, `SIEM`, `Magenta Security` (brand — excluded), `§38 BSIG-NIS2` (compound), `MTTI`, `NIS2`, `DSGVO`, `BSI C5` (proper noun — excluded), and a repeat `MDR` in the last sentence.

---

## Polished — `AUDIENCE=expert`

> Unser MDR (Managed Detection and Response)-Angebot deckt SIEM (Security Information and Event Management)-Korrelation, Threat-Hunting und Incident Response über Magenta Security ab. Es ist auf §38 BSIG-NIS2 (BSI-Gesetz in der NIS-2-Umsetzungsfassung; §38 regelt die persönliche Haftung der Geschäftsleitung) zugeschnitten und reduziert die MTTI (Mean Time to Identify) auf unter 8 Minuten. Der Compliance-Bezug zu NIS2, DSGVO und den BSI C5-Kontrollen ist im Lieferumfang dokumentiert. Bei einer Folge-Eskalation übergibt das MDR-Team direkt an den Kunden-CISO.

**What happened:**

- `MDR`, `SIEM`, `MTTI` expanded with the bare German/English Vollform — no plain-language gloss, no belehrender Ton.
- `NIS2`, `DSGVO` left raw — a KRITIS-CISO does not need these explained.
- `BSI C5`, `Magenta Security` untouched (proper noun / brand).
- `§38 BSIG-NIS2` carries the explanation on the **compound**, not on a later bare `BSIG`.
- Second mention `MDR-Team` verbatim.

## Polished — `AUDIENCE=mixed` *(default)*

> Unser MDR (Managed Detection and Response)-Angebot deckt SIEM (Security Information and Event Management)-Korrelation, Threat-Hunting und Incident Response über Magenta Security ab. Es ist auf §38 BSIG-NIS2 (BSI-Gesetz in der NIS-2-Umsetzungsfassung; §38 regelt die persönliche Haftung der Geschäftsleitung) zugeschnitten und reduziert die MTTI (Mean Time to Identify) auf unter 8 Minuten. Der Compliance-Bezug zu NIS2 (Netz- und Informationssicherheitsrichtlinie 2), DSGVO (Datenschutz-Grundverordnung) und den BSI C5-Kontrollen ist im Lieferumfang dokumentiert. Bei einer Folge-Eskalation übergibt das MDR-Team direkt an den Kunden-CISO.

**What changed vs. `expert`:**

- `NIS2` and `DSGVO` now expand once with the bare Vollform — enough for a Pre-Sales-Ansprache where some readers may not carry the regulation alphabet by heart.
- Everything else identical: technical acronyms expanded bare, brands untouched, compound reference handled on the compound, second mention verbatim.

## Polished — `AUDIENCE=lay`

> Unser MDR (Managed Detection and Response — ein Dienstleister erkennt und stoppt Angriffe rund um die Uhr für Sie)-Angebot deckt SIEM (Security Information and Event Management — sammelt und korreliert Sicherheitsdaten aus dem ganzen Unternehmen)-Korrelation, gezielte Angriffsjagd und Vorfallsbearbeitung über Magenta Security ab. Es ist auf §38 BSIG-NIS2 (BSI-Gesetz in der NIS-2-Umsetzungsfassung — die deutsche Auslegung der EU-Sicherheitsregel; §38 regelt die persönliche Haftung der Geschäftsleitung) zugeschnitten und reduziert die MTTI (Mean Time to Identify — wie schnell ein Angriff überhaupt bemerkt wird) auf unter 8 Minuten. Der Compliance-Bezug zu NIS2 (Netz- und Informationssicherheitsrichtlinie 2 — die EU-Vorgabe, die Mindeststandards für die IT-Sicherheit vorschreibt), DSGVO (Datenschutz-Grundverordnung — die EU-Regel, wie persönliche Daten geschützt werden müssen) und den BSI C5-Kontrollen ist im Lieferumfang dokumentiert. Bei einer Folge-Eskalation übergibt das MDR-Team direkt an den Kunden-CISO (Chief Information Security Officer — die Person im Unternehmen, die für IT-Sicherheit verantwortlich ist).

**What changed vs. `mixed`:**

- Every acronym (`MDR`, `SIEM`, `MTTI`, `NIS2`, `DSGVO`) now carries the em-dashed plain-language gloss in the document language.
- Even `CISO` (typically `expert`/`mixed` audience-trivial) is glossed on first mention because the lay reader cannot be assumed to know the role.
- The English-loanword "Threat-Hunting" / "Incident Response" softened to "gezielte Angriffsjagd" / "Vorfallsbearbeitung" — adjacent plain-language discipline, not strictly part of acronym handling but consistent with the lay audience.
- `BSI C5` still untouched (proper noun).
- `Magenta Security` still untouched (brand).
- Second mention `MDR-Team` still verbatim.

## What stays constant across all three

| Token | `expert` | `mixed` | `lay` |
|---|---|---|---|
| `Magenta Security` | unchanged | unchanged | unchanged |
| `BSI C5` | unchanged | unchanged | unchanged |
| Second `MDR-Team` | verbatim | verbatim | verbatim |
| `§38 BSIG-NIS2` | explanation on compound | explanation on compound | explanation on compound |

## Arc-mode note

If the same paragraph appeared *inside* a JTBD Portfolio arc element labelled `IS:` / `DOES:` / `MEANS:` (or with bold structure markers `**IS**:` / `**DOES**:` / `**MEANS**:`), the discipline marker tokens themselves are **never** treated as acronyms — they stay verbatim. See `09-preservation-modes/arc-preservation.md` and `08-sales-techniques/power-positions.md`.
