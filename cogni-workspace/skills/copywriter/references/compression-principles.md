---
title: Compression Principles
type: writing-principle
category: core-principles
tags: [compression, word-count, precision-preservation, lossless]
audience: [all]
related:
  - conciseness-principles
  - clarity-principles
  - translation-principles
version: 1.0
last_updated: 2026-06-15
---

# Compression Principles

<context>
You are compressing an existing document under `--scope=compress`. Minimizing word count is the PRIMARY objective here — not a side effect of readability targets. The hard constraint is zero precision loss: every citation, number, named entity, and distinct claim in the source survives in the output. This is a different trade-off than conciseness-principles, which optimizes readability and lets word count fall out of it. Here, word count is the goal and precision is the floor you may never cross. When a cut would drop a fact, you do not make the cut.
</context>

## Quick Reference

**Use when:** `--scope=compress` — the reader needs the shortest faithful version of a document (e.g. a long synthesis tightened for circulation) with no information loss.
**Core principle:** Remove words, never facts. If a shorter rendering would drop or soften a citation, number, entity, or claim, keep the longer rendering.
**Key techniques:** Apply the conciseness passes (filler, redundancy, strong verbs, structural bloat, paragraph compression) as aggressively as the precision floor allows; relax decorative formatting; keep baseline readability.
**Target:** Maximum word reduction subject to the precision gate passing. There is no fixed ratio — a dense, fact-packed source may compress only 10%, a verbose one 40%. The gate, not a ratio, is the stopping rule.

## How Compress Differs From Conciseness

Conciseness optimizes readability; compression optimizes brevity. The mechanics overlap (both strip filler and redundancy) but the priorities and the relaxations differ:

| Dimension | `--scope=tone` (readability conciseness) | `--scope=compress` |
|---|---|---|
| Primary objective | Readable executive prose | Minimum word count |
| Sentence-length target | EN 15-20 words / DE ≤12 words per clause | As short as precision allows; no floor |
| Decorative formatting | Bold anchoring (2-3/para), visual-element rhythm | RELAXED — dropped to save words |
| Baseline readability | Enforced | Enforced (paragraph separation, white space, headings) |
| Stopping rule | Readability targets met | Precision gate passes and no further lossless cut exists |

## How to Compress: Step by Step

Work the conciseness passes first (they are lossless by construction), then push further with compression-specific moves. Re-run the precision checklist after every aggressive cut.

### Pass 1-5: Apply the conciseness passes

Run all five passes from `conciseness-principles.md` (strip filler, eliminate redundancy, strengthen verbs, fix structural bloat, compress paragraphs). These remove words without removing meaning, so they are always safe.

### Pass 6: Relax decorative formatting

Under compress, decorative formatting spends words and screen space that the brevity objective wants back. RELAX — do not enforce — these `--scope=tone`/Step-3 targets:

- **Bold anchoring density** (the "2-3 bold instances per paragraph" target). Bold only where it genuinely prevents a misread; do not add bold to hit a density.
- **Visual-element rhythm** (the "insert a visual element every 2-3 prose paragraphs" target). Add a table/list only when it is genuinely shorter than the prose it replaces.

KEEP the baseline readability fundamentals — they cost few words and a wall of unbroken text is not "compressed", it is unreadable:

- **Paragraph separation** — keep logical paragraph breaks and blank lines between blocks.
- **White space** — blank lines between every paragraph, heading, list, table, and block quote.
- **Heading levels** — keep the document's heading structure (max H1-H3).

### Pass 7: Merge and tighten at the structural level

Once sentence-level passes are exhausted, look for whole sentences or clauses that restate a fact already present. Merge two sentences that share a subject. Collapse a "background" sentence into the claim it supports — but only when no number, entity, or citation is lost in the merge.

<example>
<input>The pilot ran for six months. During that six-month pilot, the team observed a 12% reduction in processing time [P3-1](https://example.org/report).</input>
<output>Over a six-month pilot, the team observed a 12% reduction in processing time [P3-1](https://example.org/report).</output>
<reasoning>Merged the redundant restatement of "six-month pilot" into one clause. The number (12%, six months) and the citation [P3-1] are both retained byte-identically. Word count: 27 to 18.</reasoning>
</example>

## What NOT to Cut

Compression has a hard floor. Every item below is precision-bearing and is NEVER a candidate for removal, no matter how aggressive the target. Dropping any of them fails the Step 5 precision gate and the compressed output is rejected.

<constraints>
- **Citations.** Every citation marker in the source must appear in the output, with byte-identical URLs. The four marker patterns are enumerated in the Step 5 gate (and in `translation-principles.md` § "Preserve byte-identical"). Citation markers do not count toward word-count reduction. Never replace inline citations with a "see sources" footer.
- **Numbers and data points.** Every percentage, count, ratio, date, and monetary figure in the source is retained. Replace vague language with numbers when possible, but never delete a number to save words.
- **Named entities.** Every named organization, person, product, regulation, or place in the source is retained. Do not generalize "the Bundesnetzagentur" to "the regulator" if that drops the name.
- **Distinct claims.** Every distinct factual claim survives. Merging two sentences is allowed; silently dropping the assertion one of them made is not.
- **Charset.** Per-language diacritics are preserved exactly per `translation-principles.md` § "Per-Language Charset Rules" — never ASCII substitutes (DE ä/ö/ü/ß, FR é/è/ê/ç, IT à/è/é/ì/ò/ù, PL ą/ć/ę/ł/ń/ó/ś/ź/ż, ES á/é/í/ó/ú/ñ).
- **Protected content.** Diagram-placeholder blocks, figure/Abbildung references, Obsidian `![[assets/*.svg]]` embeds, and kanban tables are byte-identical to the source.
- **Frontmatter technical IDs.** `arc_id`, slugs, synthesis IDs, `source_url`, `entity_ref`, and any other technical identifier fields are unchanged.
</constraints>

## Mode interactions

- **`arc_mode`:** Incompatible with compress. Arc preservation enforces per-element word bands (±50 words via `arc-preservation.md`), which directly conflicts with word-count minimization. When both are requested, abort with a message explaining the conflict — do not silently pick one.
- **`TARGET_LANG` (translation):** Compress and translation must NOT be fused into a single pass. Reject the combination with guidance to translate first, then compress the translated output as a separate run. The `TARGET_LANG` scope override must not silently re-expand a compress request into a full translate-and-polish.

## Validation Checklist

Before finalizing a compressed document, verify each item. Any failure rejects the output (re-compress less aggressively, restoring whatever the failing check protects).

- [ ] Citation count per marker pattern equals the source count; every URL byte-identical.
- [ ] Every number / data point in the source is present in the output.
- [ ] Every named entity in the source is present in the output.
- [ ] Every distinct claim in the source is present (none silently dropped to save words).
- [ ] Per-language diacritics preserved — no ASCII substitutes.
- [ ] Protected content (diagram placeholders, figure/Abbildung refs, `![[assets/*.svg]]` embeds, kanban tables) byte-identical.
- [ ] Frontmatter technical IDs unchanged.
- [ ] Baseline readability kept (paragraph separation, white space, heading levels); decorative density rules suspended, not the structural fundamentals.
- [ ] Word count materially reduced versus source; if not, either the source was already minimal or the lossless passes were not applied aggressively enough.

## See Also
- `conciseness-principles.md` — the five lossless passes compress builds on; readability-driven brevity
- `clarity-principles.md` — short sentences, concrete language
- `translation-principles.md` — per-language charset rules and the byte-identical citation contract the precision gate reuses
