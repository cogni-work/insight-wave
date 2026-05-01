# Booklet Density Tiers

Reference for the per-entry word budget that scales the booklet's length and depth. The user picks a tier in `trend-booklet` Phase 0; the choice is persisted to `tips-project.json → booklet_density` for resume.

---

## Tier Definitions

| Tier | Per-entry summary | Per-entry citations | Approx. booklet length (60 candidates) |
|---|---|---|---|
| **compact** | 80 words | top 2 citations | ~30 pages |
| **standard** *(default)* | 150 words | top 4 citations | ~60 pages |
| **exhaustive** | 300 words | all available citations | ~120 pages |

Page counts are rough estimates assuming standard PDF layout. The actual rendered HTML / PDF varies with the renderer.

---

## Per-Tier Block Budget

These budgets are per **entry**, not per dimension. Across all 60 candidates the totals scale 60×.

```
compact:
  summary_word_budget: 80
  max_citations: 2
  keywords_max: 6

standard:
  summary_word_budget: 150
  max_citations: 4
  keywords_max: 10

exhaustive:
  summary_word_budget: 300
  max_citations: -1   # render all available citations from enriched evidence
  keywords_max: -1
```

The formatter agent reads the tier name from its prompt and applies these budgets per entry.

---

## Tier Selection Guidance

| Reader need | Recommended tier |
|---|---|
| Quick scannable reference; one-page-per-dimension summary | compact |
| Working catalog for a strategy team that wants enough context to discuss each candidate | standard |
| Archival reference; due-diligence companion that retains every cited source | exhaustive |

When the user is unsure, default to `standard` — it matches the depth of a typical trend dossier and aligns with how downstream visualizers (`cogni-visual:enrich-report`) lay out the booklet.

---

## Hard Floors

Independent of the tier:

- Every entry MUST render the H3 heading + the italic coordinate line + the keyword block. These are structural markers, not budgeted prose.
- Every entry SHOULD render the summary block; if `evidence_md` is empty for a candidate, render `*[no quantitative evidence available]*` rather than omitting the block.
- Every entry with at least one citation MUST render the citations block (orphan candidates often have zero citations — omit the block in that case).
- Every entry with at least one theme back-reference MUST render the themes block; orphans (zero back-references) omit the block entirely.

Entries that hit the hard floors but lack tier-budget content are still well-formed; the booklet's role is coverage, not selective curation.

---

## Override (custom)

A power user can pre-seed `booklet_density: "custom"` in `tips-project.json` along with explicit budget fields:

```json
{
  "booklet_density": "custom",
  "booklet_summary_word_budget": 200,
  "booklet_max_citations": 5
}
```

The Phase 0 prompt is skipped; the values flow through to the formatter agent's prompt directly. Validate that the integers are within sensible bounds (summary 50–500, citations 1–10 or -1) before dispatch.
