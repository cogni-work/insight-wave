---
title: Markdown Basics Reference
type: formatting-standard
category: formatting
tags: [markdown, syntax, formatting]
audience: [all]
related:
  - visual-elements
  - heading-hierarchy
version: 2.0
last_updated: 2026-02-25
---

# Markdown Formatting Standards for Business Documents

<context>
You are formatting business documents (memos, briefs, reports, proposals, emails, one-pagers, executive summaries, blog posts). Your markdown output must be syntactically correct, visually clean, and optimized for readability in rendered environments (Obsidian, GitHub, web previews). This reference defines the exact formatting rules to follow. When in doubt, favor the simpler construction.
</context>

## Syntax Conventions

Use CommonMark-compliant markdown exclusively. Use these exact markers -- no alternatives.

| Element | Use this | Do NOT use |
|---------|----------|------------|
| Bold | `**text**` | `__text__` |
| Italic | `*text*` | `_text_` |
| Unordered list | `- item` | `* item` or `+ item` |
| Horizontal rule | `---` | `***` or `___` |
| Heading | `## Title` (with space after `#`) | `##Title` (no space) |

## Headings

Use H1 exactly once per document as the document title. Use H2 through H4 for content structure. Never use H5 or H6.

```markdown
# Document Title (one per document)

## Major Section (primary divisions)

### Subsection (subdivisions within an H2)

#### Detail Level (use sparingly -- consider bold text instead)
```

Heading rules:
- Always place a blank line before and after every heading
- Do not skip levels (H2 directly to H4 without an H3 between them)
- Keep headings concise: H2 at 2-6 words, H3 at 2-5 words, H4 at 2-4 words
- See `heading-hierarchy.md` for parallel structure and keyword front-loading rules

## Emphasis

Apply emphasis with specific purpose, not for decoration.

| Formatting | Purpose | Frequency |
|------------|---------|-----------|
| **Bold** | Key terms (first use), critical findings, labels | 2-3 per paragraph max |
| *Italic* | Titles of works, subtle emphasis, foreign terms | As needed |
| ***Bold italic*** | Extreme emphasis | Rare -- 1-2 per document max |

<wrong>
**Entire sentences should never be bold because it defeats the purpose of emphasis and makes everything look equally important, which means nothing stands out.**
</wrong>

<right>
The analysis revealed a **40x improvement** in error detection, making this the most effective approach tested.
</right>

## Lists

### When to Use Each Type

Use **unordered lists** (`-`) when items have no priority or sequence. Use **ordered lists** (`1.`) when sequence, priority, or ranking matters.

### Unordered Lists

```markdown
- First item
- Second item
- Third item
```

### Ordered Lists

```markdown
1. Gather requirements
2. Draft proposal
3. Submit for review
```

### Nested Lists

Indent nested items by exactly 2 spaces. Limit nesting to 2 levels maximum.

```markdown
- Main point
  - Supporting detail A
  - Supporting detail B
- Another main point
  - Supporting detail C
```

### List Formatting Rules

1. Always place a blank line before the first list item and after the last list item
2. Keep list items parallel in grammatical structure (all verbs, all nouns, or all phrases)
3. Do not create single-item lists -- use a sentence instead
4. Break lists longer than 7 items into categorized sub-groups
5. End list items with no punctuation (short phrases) or consistent punctuation (full sentences)

<wrong>
- Analyzing data
- Cost reduction
- To improve the workflow
- The system deployment process is handled next
</wrong>

<right>
- Analyze data
- Reduce costs
- Improve workflows
- Deploy systems
</right>

## Tables

Tables require a header row, a separator row, and at least one data row. Without the separator row, the table will not render.

### Basic Table

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data A   | Data B   | Data C   |
| Data D   | Data E   | Data F   |
```

### Column Alignment

```markdown
| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:--------------:|--------------:|
| Text         | Text           |           123 |
| Text         | Text           |         4,567 |
```

Default alignment is left. Use right alignment for numeric columns. Use center alignment sparingly (headers of narrow columns).

### Table Rules

- Limit tables to 3-5 columns for readability
- Keep cell content concise (1-5 words per cell)
- Always place a blank line before and after every table
- Use tables for 3+ rows of comparative or structured data -- for fewer items, use inline text or a list
- Align pipe characters vertically for source readability when practical

## Links

```markdown
[Descriptive link text](https://example.com)
```

Link text should describe the destination, not say "click here" or "this link." In business documents, links are less common than in web content. When referencing internal documents, use relative paths.

## Block Quotes

Use block quotes for testimonials, external citations, and key insight callouts.

```markdown
> "This solution reduced our processing time from 5 days to 4 hours."
> -- Sarah Martinez, Engineering Director
```

For key insight callouts (see `visual-elements.md`):

```markdown
> **Key Insight**: Teams using automated review reduced wait times by 75%.
```

## Code

### Inline Code

Use backticks for file names, commands, variable names, and technical terms in running text.

```markdown
Run the `calculate_readability.py` script to validate the document.
```

### Code Blocks

Use fenced code blocks with a language identifier for multi-line code, commands, or structured data.

````markdown
```bash
python3 scripts/calculate_readability.py document.md --lang auto
```
````

Always specify the language after the opening fence (`bash`, `python`, `json`, `markdown`, `text`). Use `text` when no specific language applies.

## Horizontal Rules

Use `---` on its own line to create a horizontal rule. Place a blank line before and after it. Use horizontal rules only for major topic transitions -- not between every section.

```markdown
Content of one major section ends here.

---

A distinctly different topic begins here.
```

## Spacing Rules

These spacing rules are mandatory. Incorrect spacing causes rendering failures or degraded readability.

<rule>
Place exactly one blank line before and after each of these elements:
- Headings
- Lists (before the first item and after the last item)
- Tables
- Code blocks
- Block quotes
- Horizontal rules
</rule>

Separate paragraphs with exactly one blank line. Never use multiple consecutive blank lines.

### Correct Spacing

```markdown
## Section Title

This is the first paragraph of content under the heading.

This is the second paragraph. Note the single blank line between paragraphs.

- List item one
- List item two
- List item three

The paragraph continues after the list with a blank line separating them.
```

### Incorrect Spacing (Common Failure Modes)

```markdown
## Section Title
Text immediately after heading with no blank line.
- List starts without blank line separation
Another paragraph without blank line after list.
```

The incorrect version above will render with headings that visually collide with body text and lists that may not render as lists in some parsers.

## Less Common Elements

Use these only when the business document specifically requires them.

### Footnotes

```markdown
The analysis confirms a significant improvement.[^1]

[^1]: Based on Q3 2025 internal benchmarking data (n=2,847).
```

### Task Lists

```markdown
- [x] Draft completed
- [ ] Stakeholder review
- [ ] Final approval
```

### Strikethrough

```markdown
~~Previous approach~~ replaced by the new methodology.
```

Strikethrough support varies across renderers. Use only when the tracked-change meaning is important to the document.

## Decision Guide

When you are unsure which formatting element to use, follow this logic:

1. **Comparing 3+ items across shared attributes?** Use a table.
2. **Listing 3+ items without comparison?** Use a list (ordered if sequence matters, unordered otherwise).
3. **Highlighting a single critical finding?** Use a block quote callout.
4. **Introducing a technical term for the first time?** Use bold.
5. **Showing a command or file reference?** Use inline code or a code block.
6. **Separating two unrelated major topics?** Use a horizontal rule.
7. **None of the above?** Use a regular paragraph. Prose is the default.

## Validation Checklist

Before finalizing any document, verify all of the following:

- Exactly one H1 exists (the document title)
- No heading levels are skipped (no H2 directly to H4)
- Maximum heading depth is H4
- Blank lines surround all headings, lists, tables, code blocks, and block quotes
- All list items within a list use the same marker (`-` for unordered, `1.` etc. for ordered)
- All tables have a separator row (`|---|---|`)
- Bold uses `**` exclusively (never `__`)
- Italic uses `*` exclusively (never `_`)
- Unordered lists use `-` exclusively (never `*` or `+`)
- No multiple consecutive blank lines appear anywhere
- Code blocks specify a language identifier

## See Also

- `heading-hierarchy.md` -- Parallel structure, keyword front-loading, and per-deliverable heading patterns
- `visual-elements.md` -- When and how to deploy tables, callouts, lists, and bold for scannability
- `citation-formatting.md` -- Citation marker placement and superscript formatting rules
