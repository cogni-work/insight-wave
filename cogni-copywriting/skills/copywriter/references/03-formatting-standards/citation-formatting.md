---
title: Citation Formatting Standards
type: formatting-standard
category: formatting
tags: [citations, references, markdown, superscript]
audience: [all]
related:
  - markdown-basics
  - visual-elements
version: 2.0
last_updated: 2026-02-25
---

# Citation Formatting Standards

## Quick Reference

**Purpose:** Format and preserve inline citations so every claim remains traceable to its source
**Compatibility:** Markdown with HTML superscript tags
**Cardinal rule:** Citations are evidence markers for audit trails -- never remove, relocate, merge, or reformat them

## Why Citations Matter

Citations in business documents serve a fundamentally different purpose than in academic papers. They are **audit trail anchors** -- they let a reader trace any specific claim back to the research insight, data point, or source that supports it. When you polish or create a document, your job is to make the prose better while keeping every citation intact and correctly positioned.

Think of citations as load-bearing structural elements. You can repaint the walls (improve prose), but you cannot move or remove the beams (citations).

## The Three Formatting Rules

Apply these rules in order when working with citations. Each rule builds on the previous one.

### Rule 1: Place Citations at the Specific Claim, Not the Section Header

Each citation must attach directly to the claim it supports. Never cluster citations at a section header or topic sentence when the claims they support appear in sub-items below.

**Think step by step:** For each citation in the source document, ask: "Which specific fact or claim does this citation support?" Then attach it to exactly that text.

<example>
BEFORE (citations dumped at header level):

```markdown
**Begruendung:** Industrial SaaS offers compelling economics<sup>[1](path)</sup><sup>[2](path)</sup>.

**Umsetzung:**
1. Higher KGV multiples (2-5x)
2. Reduced cyclical volatility
3. Faster revenue growth
```

AFTER (citations at the specific claims they support):

```markdown
**Begruendung:** Industrial SaaS offers compelling economics.

**Umsetzung:**
1. Higher KGV multiples (2-5x)<sup>[1](path)</sup>
2. Reduced cyclical volatility<sup>[2](path)</sup>
3. Faster revenue growth<sup>[1](path)</sup>
```
</example>

**Why this matters:**
- A reader checking claim #2 can go directly to source [2] without guessing which of the header-level citations applies
- When claims are added or removed during editing, the correct citation travels with its claim
- Fact-checking becomes precise rather than approximate

### Rule 2: Use the Begruendung/Umsetzung Pattern for Recommendation Lists

When a document uses the "Begruendung" (rationale) and "Umsetzung" (implementation) structure, follow this specific pattern:

```markdown
## {Recommendation Title}

**Begruendung:** {Explanation of why -- no citations here, this is synthesis}

**Umsetzung:**
1. {Specific action item with evidence}<sup>[n](path)</sup>
2. {Specific action item with evidence}<sup>[m](path)</sup>
3. {Action item without a specific source -- no citation needed}
```

**When to apply this pattern:**
- Documents with TIPS-style insights
- Strategic recommendations backed by research
- Any document using "Begruendung -> Umsetzung" structure

**Key distinction:** The Begruendung line is your synthesis of multiple sources into a rationale. Individual Umsetzung items carry the specific citations because they contain the verifiable claims.

### Rule 3: Separate Consecutive Citations with Superscript Commas

When multiple citations appear next to each other, insert a superscript comma between them so they read as a visual list rather than a wall of brackets.

<example>
WRONG -- citations jammed together with no separation:

```markdown
Text with multiple sources<sup>[15](path)</sup><sup>[16](path)</sup><sup>[17](path)</sup>.
```

WRONG -- baseline commas break the visual line:

```markdown
Text with multiple sources<sup>[15](path)</sup>, <sup>[16](path)</sup>, <sup>[17](path)</sup>.
```

CORRECT -- superscript commas maintain consistent elevation:

```markdown
Text with multiple sources<sup>[15](path)</sup><sup>,</sup> <sup>[16](path)</sup><sup>,</sup> <sup>[17](path)</sup>.
```
</example>

**The pattern to recognize and fix:**
- Detect: `</sup><sup>[` (two citations with no separator)
- Replace with: `</sup><sup>,</sup> <sup>[` (superscript comma inserted)

## Citation Count by Scenario

Use the correct separator pattern based on how many citations appear:

**Single citation** -- no separator needed:
```markdown
This claim is supported<sup>[42](path)</sup>.
```

**Two citations** -- one superscript comma:
```markdown
This claim has dual support<sup>[15](path)</sup><sup>,</sup> <sup>[16](path)</sup>.
```

**Three or more citations** -- superscript comma between each pair:
```markdown
Extensively documented<sup>[1](path)</sup><sup>,</sup> <sup>[2](path)</sup><sup>,</sup> <sup>[3](path)</sup>.
```

**Mid-sentence citations** -- same rules apply regardless of position:
```markdown
Research shows<sup>[5](path)</sup><sup>,</sup> <sup>[6](path)</sup> that performance improves significantly.
```

## Citation Formats You Will Encounter

Documents may use different citation styles. Preserve whichever format the source document uses -- never convert between formats.

| Format | Example | When Used |
|--------|---------|-----------|
| Numeric with link | `<sup>[15](11-insights/insight-id.md)</sup>` | Research-backed documents |
| Labeled with link | `<sup>[C1](10-claims/claim-id.md)</sup>` | Claim-referenced documents |
| Numeric only | `<sup>[1]</sup>` | Simpler citation style |
| Provenance marker | `[portfolio-validated]` | After citations for audit context |
| Portfolio-derived | `[portfolio-derived]` | Inline provenance markers |

**Mixed citations are valid.** A single sentence may combine numeric and labeled citations:
```markdown
Market data<sup>[15](path)</sup><sup>,</sup> <sup>[C2](path)</sup> supports this conclusion.
```

## Common Mistakes and How to Avoid Them

### Mistake: Removing citations during compression

When asked to shorten a document, you may be tempted to remove citations to save characters. This is a critical failure. Always reduce word count from prose, never from evidence markers.

<example>
WRONG -- citations removed to save space:

```markdown
Industrial SaaS shows strong multiples and reduced volatility.
```

CORRECT -- prose compressed but citations preserved:

```markdown
Industrial SaaS: higher multiples (2-5x)<sup>[1](path)</sup>, lower volatility<sup>[2](path)</sup>.
```
</example>

### Mistake: Relocating citations during restructuring

When reorganizing sections, ensure citations travel with their specific claims. If you move a bullet point, its citation must move with it.

### Mistake: Changing citation format

If the source uses `<sup>[P1-1](https://...)</sup>`, output must use exactly that format. Do not simplify to `[1]` or `<sup>[1]</sup>`.

### Mistake: Merging citations

If two separate claims each have their own citation, do not merge them into a single claim with both citations unless the source document does so.

## Pre-Output Validation

Before returning any document that contains citations, verify all of the following:

1. **Count check:** The output contains at least as many citation markers as the source document. If not, you have lost citations -- find and restore them.
2. **Placement check:** Each citation is attached to the specific claim it supports, not clustered at a header or topic sentence.
3. **Format check:** Every citation follows the `<sup>[n](path)</sup>` pattern (or whichever format the source uses).
4. **Separator check:** Consecutive citations are separated by superscript commas (`<sup>,</sup> `), not baseline commas or nothing.
5. **Preservation check:** No citation URLs have been truncated, no citation markers have been reformatted, no provenance markers have been removed.

If any check fails, fix the issue before returning the document.

## See Also

- `markdown-basics.md` (Core markdown syntax)
- `visual-elements.md` (Visual hierarchy principles)
