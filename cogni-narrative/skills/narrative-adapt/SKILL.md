---
name: narrative-adapt
description: "Transform existing narratives into derivative formats: executive briefs, talking points, and one-pagers. This skill should be used when the user asks to 'adapt a narrative', 'create executive brief', 'generate talking points', 'make a one-pager', 'shorten narrative', 'condense narrative', 'summarize the narrative', 'narrative to bullets', 'convert narrative to brief', 'prepare briefing notes', or when other plugins need derivative formats from a full narrative. Also trigger when the user wants to 'email this narrative', 'prepare for a meeting', 'print-friendly version', 'quick version', or any request to make an existing narrative shorter or more digestible for a specific audience -- even if they don't use the word 'adapt'."
---

# Narrative Adapt

## Purpose

Transform a full cogni-narrative output (1,450-1,900 word insight summary) into one of three derivative formats. The goal is to condense while preserving the arc's rhetorical power -- each format serves a different communication channel and audience attention span, so the condensation strategy differs accordingly.

**Use this for:**
- Condensing a full narrative into an executive brief for email or messaging
- Extracting key messages as talking points for verbal briefings or presentations
- Creating a structured one-pager for print or quick reference

**Not for:**
- Generating new narratives from source files (use `cogni-narrative:narrative`)
- Reviewing or scoring narratives (use `cogni-narrative:narrative-review`)
- Creating slide decks (use `cogni-visual:story-to-slides`)

---

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Path to the narrative `.md` file to adapt |
| `--format` | Yes | Target format: `executive-brief`, `talking-points`, or `one-pager` |
| `--output` | No | Output file path; defaults to `{source-dir}/{format}.md` |
| `--language` | No | Override language (uses source frontmatter by default) |

---

## Output

A markdown file in the requested derivative format, plus a JSON summary.

### JSON Summary

```json
{
  "success": true,
  "source_path": "insight-summary.md",
  "output_path": "executive-brief.md",
  "format": "executive-brief",
  "arc_id": "corporate-visions",
  "word_count": 420,
  "language": "en"
}
```

---

## Execution Protocol

### Step 1: Load Source Narrative

Read and internalize the source narrative so you can make informed condensation decisions in later steps.

1. Read the narrative file from `--source-path`
2. Extract YAML frontmatter: `title`, `subtitle`, `arc_id`, `arc_display_name`, `word_count`, `language`
3. Parse the narrative structure:
   - Hook paragraph (text between `#` title and first `##`)
   - 4 arc element sections (each `##` section with body text)
   - Citations (all `<sup>[N](file.md)</sup>` references)
4. If frontmatter is missing `arc_id`, detect it from the `##` section headers by matching against known arc element names (see the narrative skill's arc registry for the 6 arc types and their element names)
5. Determine language: explicit `--language` parameter > frontmatter `language` field > default `en`

**Before proceeding,** verify you can identify: the arc type, all 4 element headers, the hook's central tension, and the key quantitative claims. If the file doesn't have exactly 4 `##` sections or lacks recognizable arc structure, it may not be a cogni-narrative output -- halt with an error (see Error Handling).

### Step 2: Extract Key Content

This step builds the "condensation map" -- a mental inventory of what matters most in each section. The goal is to separate the load-bearing content (claims, evidence, transitions) from the supporting material (examples, extended explanations, analogies) so you know what to keep and what to cut.

**For each of the 4 arc element sections, extract:**

- **Core claim:** The central argument of the section -- typically the first or second sentence. This is the one statement that, if removed, would make the section meaningless.
  - Example: In a "Why Now" section, the core claim might be "The convergence of regulatory pressure and market demand has created a 12-18 month window for first-mover advantage."
- **Key evidence:** Up to 3 quantitative claims with their citations. Prefer numbers that are surprising, specific, and directly support the core claim. These are the last things to cut during condensation -- readers remember evidence, not assertions.
  - Example: "EUR 47B market opportunity by 2028<sup>[3](trends.md)</sup>"
- **Transition logic:** The connective tissue between this element and the next. Each arc element builds on the previous one -- "Why Change" establishes urgency, "Why Now" explains timing, etc. The transition logic is what preserves this rhetorical progression in condensed form.
  - Example: Element 2 ends with a timing pressure that sets up Element 3's solution.

**From the hook, extract:**
- **Opening tension:** The central problem or insight that opens the narrative
- **Scope statement:** What the narrative covers and for whom

### Step 3: Transform to Target Format

Read and follow the format-specific template in [references/format-templates.md](references/format-templates.md). The templates contain detailed structures, word budgets, condensation strategies, and format-specific rules.

| Format | Word Target | Channel | Key Feature |
|--------|-------------|---------|-------------|
| Executive Brief | 300-500 | Email, Slack | Condensed arc with citations preserved |
| Talking Points | N/A (bullets) | Presentations, calls | Answer-first bullets, no citations |
| One-Pager | 400-600 | Print, handout | Metrics table + next steps |

**Why arc structure is preserved in every format:** Downstream tools (story-to-slides, story-to-big-picture, story-to-storyboard) parse the 4 arc elements to create matching visual segments. Renaming headers, reordering elements, or merging sections breaks this pipeline. Each format keeps all 4 `##` headers in their original order with the exact arc element names from the source.

**Why fidelity matters:** Derivatives condense -- they never embellish. Adding information that wasn't in the source narrative would break the evidence chain back to the original research. Every claim in the derivative should be traceable to the source. This is especially important for quantitative claims: if a number appears in the derivative, it appeared in the source.

### Step 4: Validate Output

Check the generated derivative in priority order. Fix structural issues first -- content checks are meaningless if the structure is wrong.

**Structural gate (check first):**
- Exactly 4 `##` headers present
- Headers match the source narrative's exact arc element names
- Headers in correct arc sequence (same order as source)

If this fails, rewrite rather than rename sections. Content generated for the wrong structure reads wrong even with correct headers.

**Content gate:**
- Word count within format target range
- No information added beyond what the source contains
- Quantitative claims match source exactly (no rounding, no rephrasing that changes meaning)

**Language gate (if `de`):**
- Proper Unicode umlauts (ä, ö, ü, ß) throughout
- Zero ASCII fallbacks (ae, oe, ue, ss) in body text
- Scan for common failures: "fuer" (should be "für"), "ueber" ("über"), "Aenderung" ("Änderung")

**Format-specific gate:**
- Executive Brief: citations renumbered sequentially, 8-12 total
- Talking Points: no inline citations, Key Numbers section present, **no bullet exceeds 25 words** (split or trim if over)
- One-Pager: metrics table has exactly 4 rows, Next Steps has 3 items, **word count at or above 400** (expand element sections to 3 sentences each if under)

### Step 5: Write Output

1. Write to output path (default: `{source-dir}/{format}.md`)
2. Verify file written correctly
3. Return JSON summary

---

## Language Rules

Derivative formats inherit the source narrative's language. German narratives need proper Unicode umlauts because ASCII transliterations (fuer, ueber) look unprofessional and break German grammar conventions.

- **English (`en`):** Standard output
- **German (`de`):** Proper Unicode umlauts (ä, ö, ü, ß) throughout. Zero ASCII fallbacks in body text. File names and YAML keys remain ASCII.

---

## Error Handling

On any unrecoverable failure, return error JSON:

```json
{
  "success": false,
  "error": "Description of what went wrong",
  "step": "Step where failure occurred"
}
```

| Step | Failure | Action |
|------|---------|--------|
| 1 | Source file not found | Halt with error |
| 1 | File lacks 4 `##` sections | Halt -- likely not a cogni-narrative output |
| 1 | No YAML frontmatter | Attempt to detect arc from headers; warn user |
| 1 | Unrecognized arc type | Halt with list of valid arc types |
| 3 | Format template not found | Halt with error |
| 4 | Structural validation fails | Rewrite the derivative, then re-validate |
| 4 | Word count out of range | Adjust and re-validate |

---

## Bundled Resources

| File | Purpose | Load When |
|------|---------|-----------|
| `references/format-templates.md` | Detailed templates, word budgets, condensation strategies, and examples for each format | Step 3 |
