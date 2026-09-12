---
library_id: brief-validation-core
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# Brief Validation Core — the reasoning layers

The validation every brief type shares, stated once. Each brief type's checklist — `presentation-brief-validation.md`, `web-brief-validation.md`, `storyboard-brief-validation.md`, `infographic-brief-validation.md`, all in this directory — runs `scripts/check-brief.py` as its Layer 1 and points here for the layers a model has to reason through; it keeps only the rules that are specific to its type. Nothing in this file is mechanizable: a scripted proxy for "is this an assertion" would produce false fails and erode trust in the checker, so these stay judgment.

## Core principle

> Validation is argument about correctness, not mechanical checking. For each unit — slide, section, poster, block — ask: "Would this survive in front of the audience?" If the answer is no, something is wrong.

Do not tick boxes. For each layer, first reason about what is most likely to go wrong given *this* brief, then check systematically.

## Severity

| Severity | Symbol | Meaning | Action |
|----------|--------|---------|--------|
| **CRITICAL** | `[C]` | The renderer fails, produces a broken layout, or shows wrong content | Fix before writing; stop and repair immediately |
| **WARNING** | `[W]` | Renders, but with degraded quality, inconsistent visuals, or weak messaging | Fix unless a deviation is justified and documented |
| **INFO** | `[I]` | An improvement; the brief works without it | Fix if time allows; note in the report |

A `fail` from `check-brief.py` is CRITICAL; a `warn` is WARNING.

## Protocol

For each reasoning layer:

- **Anticipate** — what is unusual about this brief (arc type, language, unit count, domain)? Which checks are most likely to fail? Which edge cases would the standard list miss?
- **Check** — run every check; for each failure record severity, expected vs found, and the specific fix.
- **Repair** — fix every CRITICAL now, every WARNING unless justified; re-check the repaired items.

Stop on the first failing layer, fix, re-check, then continue. Never write a brief with an unresolved CRITICAL.

## Assertion headlines

- **The title-only test.** Read every unit heading in sequence and nothing else. Does the argument come through from the headings alone? If not, message architecture failed — the audience reads headings first and decides whether to engage; a heading that needs the body to make its point has already lost.
- **The "About:" test.** If "About:" can be put in front of a heading and it still reads naturally, it is a topic label, not an assertion. "Overview", "Summary", "Our Approach", "Überblick", "Zusammenfassung", "Einleitung", "Fazit" are topic labels. Rewrite as `{subject} + {verb} + {consequence}`: "Overview of Predictive Maintenance" becomes "Predictive Maintenance eliminates unplanned downtime".
- **Uniqueness.** Two headings that make the same claim in different words are near-duplicates; the narrative feels repetitive. Differentiate by emphasising a different aspect of the argument.
- **Completeness.** A heading delivers what happens *and* why it matters. When a banner, subline or body carries the "so what" the heading lacks, fold it into the heading — the anti-pattern is subtle, because the output looks plausible until the heading is read alone.
- **Imperative CTAs.** A CTA headline or button starts with an action verb ("Start", "Discover", "Starten", "Entdecken") tied to a specific outcome; "Contact Us" and "Mehr erfahren" are passive labels.

## Number plays

- Statistics are reframed for impact, not pasted raw: ratio framing ("1 in 3 budgets"), before/after contrast ("48 hours → 15 minutes"), hero isolation (one dominant number on its own).
- One hero number per unit. Two competing hero-weight numbers split attention and neither lands; supporting numbers belong in a sublabel or the body.
- A number field carries only the number (digits, separators, `%`, ratio notation); units and scope go in the label. `23 Tage` in a number field breaks the visual hierarchy.
- Ask whether a different framing would be more visceral — a ratio over a percentage, a total over a per-unit figure — and take it when the source supports it.

## Bullets and body text

- Bullets are scannable phrases, not sentences: the audience scans in seconds and stops listening the moment it starts reading. The per-type word ceilings are mechanized; the judgment here is whether a bullet that fits the count still reads as a phrase.
- Bullets within one field are parallel in structure — all noun phrases or all verb phrases, never mixed.
- Body text supports the heading's claim with a fact, a mechanism or evidence the heading does not contain; a body that restates the heading in more words is thin.
- No hedging in headings or bullets: "might", "could", "potentially", "somewhat", "relatively", "it seems", "possibly". A brief makes confident claims.
- No placeholder text: "Lorem ipsum", "TODO", "TBD", "[insert here]", "xxx".

## Language consistency

- Every text field is in the brief's declared `language`; an English CTA in a German brief is the common failure, and mixed languages inside one unit read as broken.
- German copy uses real Unicode — ä/ö/ü/ß, never the ASCII substitutes — and German number formatting (`2.661`, dot as thousands separator; English `2,661`). Filenames, slugs and a skill's frontmatter trigger phrases are outside this rule (see `brief-conventions.md` § German fidelity).
- Localized labels match the language: the slides IS/DOES/MEANS badges are mechanized; section labels, CTA verbs and unit headings are not.
- Special characters in URLs are preserved exactly.

## Source preservation

- Every number and claim traces to the source narrative. A statistic that does not exist in the source, or a claim the source does not support, is a credibility failure — and briefs are shared and cited.
- No URL is invented. Every URL in a `source`, `Source` or citation field appears in the narrative; a URL that does not is removed or replaced with the narrative's own.
- Citations with URLs are preserved where the narrative provides them — as inline markers in the body, as `source` fields, and in the references appendix where the type carries one. The marker format, numbering and exclusion zones are mechanized for slides; the judgment is whether the *right* claim carries the citation.
- The source narrative's own Sources block is a lookup for attribution, never content.

## Completeness against the source

- Every major argument of the narrative — the 3–5 the governing thought rests on — has a unit; an argument with no unit is a gap a skeptical reader will probe.
- The key statistics are present somewhere — as a hero number, in body text or bullets.
- The governing thought is supported by the units in order: read the headings in sequence and confirm they build to its conclusion.
- The arc type is the one the narrative actually follows; a mismatch makes the unit sequence template suboptimal.

## Report

After the reasoning layers, record the result per layer with the counts of CRITICAL, WARNING and INFO findings and the fixes applied, in the format the producer's checklist specifies. A layer passes with zero CRITICAL after repair; the brief passes when every layer passes; unfixed WARNINGs carry a justification.
