---
title: Acronym Handling Principles (Audience-Tuned First-Mention Expansion)
type: writing-principle
category: core-principles
tags: [acronyms, abbreviations, audience-tuning, clarity, first-mention, plain-language]
audience: [all]
related:
  - clarity-principles
  - plain-language-principles
  - power-positions
  - arc-preservation
version: 1.0
last_updated: 2026-05-19
---

# Acronym Handling Principles

<context>
You are applying acronym and abbreviation handling as a default polish discipline. This applies to every copywriting task — standard, sales, and arc modes — and sits alongside Wolf-Schneider clarity, active voice, paragraph splitting, and bold anchoring in Step 3 of the workflow.

Your goal: on first mention, expand each acronym to a form the reader can carry through the rest of the document. On subsequent mentions, leave the acronym verbatim. Tune the depth of expansion to the AUDIENCE so the result reads neither belehrend (for experts) nor opaque (for lay readers).
</context>

## Audience Resolution

The skill resolves `AUDIENCE` in this exact priority order (defined in `SKILL.md` Step 1):

1. **Explicit `AUDIENCE` skill arg** — `expert` | `mixed` | `lay`
2. **Frontmatter `audience:` field** — same vocabulary
3. **Default** — `mixed`

Treat `AUDIENCE` as the single source of truth for expansion depth. Do not infer it from other frontmatter fields (`market`, `seniority`, etc.) — upstream callers are responsible for setting `audience:` correctly.

The stakeholder-review audience vocabulary (`executive` / `technical` / `general` / `legal` / `sales/marketing`) in `SKILL.md` Step 4 is a separate, parallel concept used for reviewer persona selection. Both vocabularies coexist; a future iteration may unify them.

## Detection Heuristic

Treat the following patterns as candidate acronyms/abbreviations:

- **Two or more consecutive uppercase letters** — `SIEM`, `MDR`, `BSI`, `DSGVO`, `NIS2`, `MTTI`
- **Mixed notations** — `BSI-C5`, `BSIG-NIS2`, `ISO 27001`, `M365`, `S/4HANA`
- **Versioning suffixes** — `NIS2`, `DORA`, `IPv6`, `HTTP/2` (treat the version as part of the token)
- **Compound references with a paragraph sigil or section number** — `§38 BSIG-NIS2`, `Art. 32 DSGVO`
- **Domain-specific lowercase acronyms** — rare but real: `s.o.`, `z.B.` (these are usually expanded everywhere and are not the focus of this discipline; see plain-language-principles)

Candidate ≠ expand. Apply the audience-tuned table and exclusions below.

## Audience-Tuned Depth

| Audience | Behaviour |
|---|---|
| `expert` | Expand only genuinely technical or ambiguous acronyms (`SIEM`, `MTTI`, `B3S`, niche product codes). Regulation proper nouns like `NIS2`, `DSGVO`, `BSI`, `DORA` stay unaltered — expanding them in front of a KRITIS-CISO reads as belehrend. |
| `mixed` *(default)* | Expand technical acronyms in full; explain common regulation acronyms once on first mention (`DSGVO (Datenschutz-Grundverordnung)`). Keep it short — no plain-language gloss. |
| `lay` | Expand virtually every acronym on first mention and add a short plain-language gloss in the document language: `MDR (Managed Detection and Response — ein Dienstleister erkennt und stoppt Angriffe rund um die Uhr für Sie)`. |

### Worked Examples (DE pitch context)

| Acronym | `expert` first mention | `mixed` first mention | `lay` first mention |
|---|---|---|---|
| `SIEM` | `SIEM (Security Information and Event Management)` | `SIEM (Security Information and Event Management)` | `SIEM (Security Information and Event Management — sammelt und korreliert Sicherheitsdaten aus dem ganzen Unternehmen)` |
| `MDR` | `MDR (Managed Detection and Response)` | `MDR (Managed Detection and Response)` | `MDR (Managed Detection and Response — ein Dienstleister erkennt und stoppt Angriffe rund um die Uhr für Sie)` |
| `MTTI` | `MTTI (Mean Time to Identify)` | `MTTI (Mean Time to Identify)` | `MTTI (Mean Time to Identify — wie schnell ein Angriff überhaupt bemerkt wird)` |
| `NIS2` | `NIS2` *(unchanged — regulation proper noun)* | `NIS2 (Netz- und Informationssicherheitsrichtlinie 2)` | `NIS2 (Netz- und Informationssicherheitsrichtlinie 2 — die EU-Vorgabe, die Mindeststandards für die IT-Sicherheit vorschreibt)` |
| `DSGVO` | `DSGVO` *(unchanged)* | `DSGVO (Datenschutz-Grundverordnung)` | `DSGVO (Datenschutz-Grundverordnung — die EU-Regel, wie persönliche Daten geschützt werden müssen)` |
| `BSI` | `BSI` *(unchanged)* | `BSI (Bundesamt für Sicherheit in der Informationstechnik)` | `BSI (Bundesamt für Sicherheit in der Informationstechnik — die deutsche Behörde für IT-Sicherheit)` |

### Worked Examples (EN context)

| Acronym | `expert` | `mixed` | `lay` |
|---|---|---|---|
| `SIEM` | `SIEM (Security Information and Event Management)` | `SIEM (Security Information and Event Management)` | `SIEM (Security Information and Event Management — a system that collects and correlates security signals across your organization)` |
| `NIS2` | `NIS2` | `NIS2 (Network and Information Security Directive 2)` | `NIS2 (Network and Information Security Directive 2 — the EU rule setting minimum IT-security standards for critical sectors)` |

## Format Convention

```
ACRONYM (Vollform — optional plain-language gloss for lay)
```

Rules:

- **Vollform language matches the document language** — DE document → German Vollform; EN document → English Vollform. Use the language detected in Step 3 of `SKILL.md`.
- **The em-dash separator (`—`) precedes the lay gloss.** No em-dash for `expert` / `mixed`.
- **First mention only.** Track which acronyms have already been introduced *in the current document*. The skill does not polish across files.
- **Per-document scope.** Each document is treated independently.

## Exclusions (never expand)

### Proper nouns

Recognised regulation, framework, and standard names with their own brand identity. Never expand these — they read as the proper noun, not the acronym they originated from:

- `KRITIS-Dachgesetz`, `EU AI Act`, `BSI C5`, `B3S`, `ISO 27001`, `ISO 9001`, `TISAX`, `DAX`, `MDAX`, `SDAX`, `TecDAX`

### Brand and product names

Acronym-shaped brand names belong to their owners — leave them verbatim:

- `Magenta Security`, `Open Telekom Cloud`, `T-Cloud`, `Microsoft Entra ID`, `CrowdStrike Falcon`, `SAP S/4HANA`

### Audience-trivial tokens

| Token | `expert` | `mixed` | `lay` |
|---|---|---|---|
| `IT`, `EU`, `USD`, `EUR`, `URL`, `PDF` | skip | skip | skip |
| `M365` | skip | skip | expand |
| `KI`/`AI` | skip | skip | expand once |

### Arc and sales structure markers

The Power Position markers `**IS**:`, `**DOES**:`, `**MEANS**:` and standalone `IS` / `DOES` / `MEANS` tokens used as arc-element labels in the portfolio JTBD map are **never** acronym candidates. They are structural markers, not abbreviations. See:

- `08-sales-techniques/power-positions.md` — structure marker preservation (line 318)
- `09-preservation-modes/arc-preservation.md` — arc structure preservation rules

If you cannot tell from context whether a token is a structural marker or an acronym, treat it as a structural marker (safer default).

## Compound Reference Rule

When a compound reference like `§38 BSIG-NIS2` appears and the constituent acronym (`BSIG`) has not been introduced earlier, attach the explanation to the **compound**, not the bare token:

- ✅ `§38 BSIG-NIS2 (BSI-Gesetz in der NIS-2-Umsetzungsfassung; §38 regelt die persönliche Haftung der Geschäftsleitung)`
- ❌ Expanding bare `BSIG` later in the document when only the compound appeared earlier.

This keeps the explanation co-located with the actual reader question ("what does §38 in this regulation say?") rather than splitting it across two introductions.

## Validation

A polished document satisfies this discipline when:

1. Every auflösungswürdig acronym is expanded **once**, on its first occurrence.
2. Every subsequent mention of the same acronym is **verbatim** — no re-expansion.
3. Excluded tokens (proper nouns, brand names, audience-trivial words, arc/sales markers) are **unchanged** anywhere in the document.
4. The expansion **depth** matches the resolved `AUDIENCE` (no lay glosses in `expert` output; no raw `MDR` in `lay` output).
5. Vollform **language** matches the document language.
6. Compound references carry the explanation on the compound, not the bare token.

If any of (1)–(6) fail, fix in place — do not revert the whole polish.
