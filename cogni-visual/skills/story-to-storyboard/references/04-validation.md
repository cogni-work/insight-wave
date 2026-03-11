# Storyboard Brief Validation

## Purpose

Define the hybrid web + print validation framework for storyboard-brief.md files. Every brief must pass all four layers plus print-specific checks before being written to output.

---

## Layer 1: Schema Compliance

Verify the brief structure matches the expected format.

### Frontmatter Checks

- [ ] `type` field is `"storyboard-brief"`
- [ ] `version` field is `"2.0"`
- [ ] `theme` field references a valid theme ID
- [ ] `theme_path` points to an existing theme.md
- [ ] `style_guide` field contains a style guide name
- [ ] `poster_size` is one of: A0, A1, A2, A3
- [ ] `poster_count` is 3-5
- [ ] `language` is "en" or "de"
- [ ] `governing_thought` is a single sentence
- [ ] `arc_type` is a valid arc type

### Poster Structure Checks

- [ ] Total poster count is 3-5
- [ ] Each poster has a `poster_label` (arc station name)
- [ ] Each poster has a `sequence` in "N/M" format
- [ ] Sequence numbers are contiguous: "1/N", "2/N", ..., "N/N"
- [ ] N matches `poster_count` in frontmatter
- [ ] Each poster contains 1-3 sections

### Per-Section Field Checks

**hero sections:**
- [ ] Has `headline` (string)
- [ ] Has `subline` (string)
- [ ] Has `section_theme: dark`
- [ ] Has `image_prompt` (optional but recommended)

**stat-row sections:**
- [ ] Has `headline` (string)
- [ ] Has `stats` array with 3-4 items, each with `number` and `label`
- [ ] Has `section_theme: dark`

**feature-alternating sections:**
- [ ] Has `headline` (string)
- [ ] Has `body` (string)
- [ ] Has `image_prompt` (string)
- [ ] Has `section_theme` (light or light-alt)

**comparison sections:**
- [ ] Has `headline` (string)
- [ ] Has `left_label`, `left_headline`, `left_bullets`
- [ ] Has `right_label`, `right_headline`, `right_bullets`
- [ ] Has `section_theme` (light or light-alt)

**timeline sections:**
- [ ] Has `headline` (string)
- [ ] Has `steps` array with 3-5 items
- [ ] Has `section_theme` (light or light-alt)

**cta sections:**
- [ ] Has `headline` (string)
- [ ] Has `cta_text` (string)
- [ ] Has `section_theme: accent`

**feature-grid sections:**
- [ ] Has `headline` (string)
- [ ] Has `cards` array with 4-6 items
- [ ] Has `section_theme` (light or light-alt)

**problem-statement sections:**
- [ ] Has `headline` (string)
- [ ] Has `body` or `bullets`
- [ ] Has `section_theme` (light or light-alt)

**testimonial sections:**
- [ ] Has `quote` (string)
- [ ] Has `author_name` (string)
- [ ] Has `section_theme: dark`

**text-block sections:**
- [ ] Has `headline` (string)
- [ ] Has `section_theme` (light or light-alt)

---

## Layer 2: Message Quality

Verify that content communicates effectively.

### Headline Quality

- [ ] Every section headline is an assertion (contains a verb)
- [ ] No topic labels ("Overview", "Summary", "Introduction")
- [ ] Headlines are unique across all sections (no duplicates)
- [ ] All headlines are under 70 characters

### Body Text Quality

- [ ] Every body text is 2-3 complete sentences
- [ ] No body text exceeds 50 words
- [ ] Body text supports the headline's claim

### Stat Number Quality (where present)

- [ ] Numbers are reframed with number plays (not raw data)
- [ ] Units/labels included
- [ ] Numbers are contextually meaningful

---

## Layer 3: Visual Coherence

Verify that the brief will produce a visually coherent storyboard.

### Poster Composition

- [ ] 3-5 total posters
- [ ] Each poster has 1-3 stacked sections
- [ ] No poster has more than 3 sections
- [ ] First poster starts with `hero` section
- [ ] Last poster ends with `cta` section
- [ ] Section type variety: not all posters have identical compositions

### Section Theme Rhythm

- [ ] `hero` sections are `dark`
- [ ] `stat-row` and `testimonial` sections are `dark`
- [ ] `cta` sections are `accent`
- [ ] No two adjacent sections within a poster are both `dark` (unless hero+stat-row on first poster)
- [ ] Content sections alternate between `light` and `light-alt`

### Section Type Distribution

- [ ] At least 2 different section types used across all posters
- [ ] No section type appears more than 4 times total
- [ ] Feature-alternating sections use portrait adaptation (vertical stack)

### Image Consistency

- [ ] All image prompts include "print resolution, high detail"
- [ ] All image prompts include "No text, no people"
- [ ] Max 2 images per poster
- [ ] Image prompts are contextually compatible across posters

---

## Layer 4: Content Integrity

Verify that the brief faithfully represents the source narrative.

### Completeness

- [ ] Every major narrative section is represented across posters
- [ ] No important evidence or arguments are missing
- [ ] Governing thought is supported by the poster content
- [ ] Arc type is correctly identified

### Language Consistency

- [ ] All text is in the specified language (en or de)
- [ ] German umlauts preserved (ä, ö, ü, ß)
- [ ] Number formatting matches language (EN: 2,661 / DE: 2.661)
- [ ] No mixed-language content within a poster

### Source Preservation

- [ ] Citations with URLs preserved in `source` fields where available
- [ ] No URLs invented or fabricated
- [ ] Key statistics traceable to source material

---

## Print-Specific Checks

### Poster Count

- [ ] Total posters <= 5
- [ ] Total posters >= 3

### Section Stacking Height

- [ ] Each section's allocated height is sufficient for its content type:
  - hero: minimum 600px at base
  - stat-row: minimum 400px at base
  - feature-alternating: minimum 500px at base
  - comparison: minimum 500px at base
  - timeline: minimum 400px at base
  - cta: minimum 300px at base
  - feature-grid: minimum 500px at base
  - problem-statement: minimum 450px at base
  - testimonial: minimum 350px at base
  - text-block: minimum 250px at base

### Font Size Minimums (at base resolution)

- [ ] Section headline >= 32px
- [ ] Body text >= 14px
- [ ] Stat number >= 40px
- [ ] Section label >= 12px
- [ ] Footer text >= 12px

### Safe Area

- [ ] No text content specified for areas within the bleed margin

### Sequence Numbering

- [ ] All sequence numbers follow "N/M" format
- [ ] Sequence numbers are contiguous
- [ ] M matches total poster count

---

## Validation Execution

Run validation after all poster content is finalized:

```
FOR each layer:
  Run all checks
  IF any check fails:
    Log failure with: layer, check, expected, actual
    STOP -- fix before proceeding

FOR print-specific checks:
  Run all checks
  IF any check fails:
    Log failure with: check, expected, actual
    STOP -- fix before proceeding

Report:
  "Validation: Schema {pass/fail} | Messages {pass/fail} | Visual {pass/fail} | Integrity {pass/fail} | Print {pass/fail}"
```

If any layer fails, return to the responsible step and fix before writing the brief.
