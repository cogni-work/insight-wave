# Scoring Rubric

Detailed scoring rules and edge cases for narrative review quality gates.

## Scoring Principles

1. **Binary where possible** -- Most criteria are pass/fail for their allocated points
2. **Partial credit** -- Some criteria allow partial points (documented below)
3. **Gate status** -- Derived from percentage of points earned:
   - `pass`: >= 80% of gate points
   - `warn`: 50-79% of gate points
   - `fail`: < 50% of gate points

---

## Structural Gate (30 points)

### Exactly 4 `##` headers (10 points)

- **10 points:** Exactly 4 `##` lines in narrative body
- **5 points:** 3 or 5 `##` lines (close but wrong)
- **0 points:** Fewer than 3 or more than 5

**How to count:** Only count lines starting with `## ` (hash-hash-space) below the YAML frontmatter closing `---`. Do not count `#` (h1) or `###` (h3) lines.

### Headers match arc element names (10 points)

- **10 points:** All 4 headers match expected names exactly
- **7 points:** 3 of 4 match
- **5 points:** 2 of 4 match
- **0 points:** Fewer than 2 match

**Matching rules:**
- Compare against `language-templates.md` for the detected `arc_id` and `language`
- Match is case-sensitive
- Trailing/leading whitespace is trimmed before comparison
- Subtitles after `:` are part of the expected name (e.g., "Why Change: Unconsidered Needs")

### Headers in correct sequence (5 points)

- **5 points:** All headers in correct arc order
- **0 points:** Any header out of order

Only evaluated if at least 3 headers match expected names.

### No extra `##` headers (5 points)

- **5 points:** No extra `##` headers beyond the 4 arc elements
- **2 points:** 1 extra `##` header
- **0 points:** 2+ extra `##` headers

---

## Critical Gate (25 points)

### Total word count (10 points)

- **10 points:** 1,450-1,900 words
- **7 points:** 1,350-1,449 or 1,901-2,000 (close range)
- **3 points:** 1,200-1,349 or 2,001-2,200 (extended range)
- **0 points:** Below 1,200 or above 2,200

**Word count method:** Count all words in the markdown body below frontmatter. Exclude YAML frontmatter, citation markup (`<sup>`, `</sup>`), and markdown formatting characters.

### Arc-specific title (5 points)

- **5 points:** Title is specific, compelling, and reflects the arc's rhetorical frame
- **2 points:** Title exists but is generic or does not reflect the arc
- **0 points:** Title missing or is literally "Insight Summary"

**Generic title indicators:** "Summary", "Report", "Analysis", "Overview", "Insight Summary", "Research Results" used alone without arc-specific framing.

### Hook present (5 points)

- **5 points:** Hook paragraph exists (150-200 words) between `#` title and first `##`
- **3 points:** Hook exists but outside word range (100-149 or 201-250)
- **0 points:** No hook paragraph or fewer than 100 words before first `##`

### Frontmatter complete (5 points)

Required fields: `title`, `arc_id`, `word_count`, `language`, `date_created`

- **5 points:** All required fields present
- **3 points:** 3-4 fields present
- **0 points:** Fewer than 3 fields present

---

## Evidence Gate (25 points)

### Minimum 15 citations (10 points)

- **10 points:** 15+ unique citations
- **7 points:** 12-14 citations
- **5 points:** 8-11 citations
- **2 points:** 4-7 citations
- **0 points:** Fewer than 4 citations

**Counting method:** Count unique `<sup>[N]` patterns where N is a citation number. Each unique N counts once regardless of how many times it appears.

### All quantitative claims cited (10 points)

- **10 points:** Every number, percentage, or quantitative claim has an adjacent citation
- **7 points:** 1-2 uncited quantitative claims
- **3 points:** 3-5 uncited quantitative claims
- **0 points:** 6+ uncited quantitative claims

**Quantitative claim detection:** Look for patterns like:
- Percentages: `X%`, `X percent`
- Currency: `$X`, `EUR X`, numbers followed by "million", "billion"
- Specific numbers in context: "X companies", "X-fold increase", "grew by X"
- Ratios and multipliers: "3x", "doubled", "tripled"

**Exclusions:** Page numbers, citation numbers, list ordinals, dates, and version numbers are NOT quantitative claims.

### No broken citation refs (5 points)

- **5 points:** All citations use valid `<sup>[N](file.md)</sup>` format
- **3 points:** 1-2 citations with format issues
- **0 points:** 3+ citations with format issues

**Format issues:** Missing closing `</sup>`, missing `(file.md)` link, non-sequential numbering, duplicate numbers.

---

## Structure Gate (10 points)

### Element word counts within targets (5 points)

Compare each `##` section's word count against the arc definition's per-element targets.

- **5 points:** All 4 elements within target +/-50 words
- **3 points:** 3 of 4 elements within target
- **1 point:** 2 of 4 elements within target
- **0 points:** Fewer than 2 elements within target

### Transitions between elements (5 points)

Check for transition text: the last paragraph of each section (except the last) should connect to the next section's theme.

- **5 points:** Clear transitions between all 3 section boundaries
- **3 points:** Transitions at 2 of 3 boundaries
- **1 point:** Transition at 1 boundary
- **0 points:** No transition text detected

**Transition indicators:** Phrases like "Building on...", "This urgency...", "Against this backdrop...", "With these capabilities...", opening sentences that reference the prior section's conclusion.

---

## Language Gate (10 points)

### Proper umlauts (5 points) -- only if `language: de`

- **5 points:** Zero ASCII fallbacks found
- **3 points:** 1-3 ASCII fallbacks
- **0 points:** 4+ ASCII fallbacks

**ASCII fallback patterns to search for:** `ue` (should be `ü`), `ae` (should be `ä`), `oe` (should be `ö`), `ss` where `ß` is correct. Common false positives: compound words where "ue", "ae", "oe" are natural letter combinations at morpheme boundaries (e.g., "aeroplane") -- use German language knowledge to distinguish.

If `language: en`, award full 5 points automatically.

### Consistent language (5 points)

- **5 points:** Body text is consistently in the declared language
- **3 points:** Minor language mixing (1-2 foreign sentences)
- **0 points:** Significant language mixing

**Exceptions:** Framework names (TIPS, MECE, SWOT), brand names, and technical terms may remain in English regardless of language setting.

If `language: en`, award full 5 points automatically (English is the default).
