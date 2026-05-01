# English Labels for Trend Booklet

Language: `en`

## Booklet Title

```text
BOOKLET_TITLE: "TIPS Trend Booklet"
BOOKLET_SUBTITLE: "Comprehensive catalog of all scouted trend candidates organized by Smarter Service dimension, subcategory, and horizon."
```

## Dimension Headers (H2 in assembled booklet)

```text
DIMENSION_HEADER_T: "Forces — External Effects"
DIMENSION_HEADER_I: "Impact — Digital Value Drivers"
DIMENSION_HEADER_P: "Horizons — New Horizons"
DIMENSION_HEADER_S: "Foundations — Digital Foundation"
```

## Subcategory Headers (H3, generic; subcategory text comes from scout output)

```text
SUBCATEGORY_HEADER: "Subcategory"
```

## Horizon Labels (H4)

```text
HORIZON_LABEL_ACT: "ACT (0-2 Years)"
HORIZON_LABEL_PLAN: "PLAN (2-5 Years)"
HORIZON_LABEL_OBSERVE: "OBSERVE (5+ Years)"
```

## Per-Entry Block Headers

```text
ENTRY_SUMMARY_HEADER: "Summary"
ENTRY_CITATIONS_HEADER: "Key citations"
ENTRY_THEMES_HEADER: "Supports investment themes"
ENTRY_KEYWORDS_HEADER: "Keywords:"
ENTRY_NO_EVIDENCE: "[no quantitative evidence available]"
```

## Orphan Appendix

```text
ORPHAN_APPENDIX_HEADER: "Unanchored Signals (Orphan Appendix)"
ORPHAN_APPENDIX_INTRO: "{N} candidates in this dimension are not currently anchored to any investment theme. They are listed here for completeness; consider revisiting /value-modeler to incorporate them into a theme."
```

## Empty Bucket Note

```text
EMPTY_BUCKET_NOTE: "*No candidates in this horizon for this dimension.*"
```

## Density Tier Selection (Phase 0)

```text
PHASE_0_DENSITY_QUESTION: "How dense should the booklet be? Density controls per-entry summary length and citation count; the catalog covers all 60 candidates regardless."
PHASE_0_DENSITY_HEADER: "Booklet density"
DENSITY_COMPACT: "Compact (~30 pages)"
DENSITY_COMPACT_DESC: "80-word summary + top 2 citations per entry. Quick scannable reference."
DENSITY_STANDARD: "Standard (~60 pages)"
DENSITY_STANDARD_DESC: "150-word summary + top 4 citations per entry. Working catalog. Recommended default."
DENSITY_EXHAUSTIVE: "Exhaustive (~120 pages)"
DENSITY_EXHAUSTIVE_DESC: "300-word summary + all available citations per entry. Archival reference."
```

## Status Messages

```text
PHASE_1_INDEX_BUILDING: "Building per-candidate booklet index..."
PHASE_1_INDEX_COMPLETE: "Booklet index built: {N} candidates, {M} orphans"
PHASE_2_FORMATTERS_DISPATCH: "Dispatching 4 booklet formatter agents in parallel..."
PHASE_2_FORMATTER_COMPLETE: "Booklet formatter complete: {dimension} ({entries} entries)"
PHASE_2_FORMATTER_SKIP_RESUME: "Skipping booklet formatter (resume): {dimension}"
PHASE_3_ASSEMBLY_COMPLETE: "Booklet assembled: {PATH}"
PHASE_4_COMPLETE: "Trend booklet complete"
```
