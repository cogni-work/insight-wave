# Booklet Structure

Reference for the catalog layout and per-entry block template used by the `cogni-trends:trend-booklet-formatter` agent.

---

## Three-Level Nesting

Every booklet is organized as:

```
Dimension (H1 within each per-dimension formatter file; assembled as part of the larger H1 at the booklet level)
└─ Subcategory (H2)
   └─ Horizon (H3)
      └─ Per-candidate entry (H3 # Trend Name with bracketed metadata)
```

In the assembled `tips-trend-booklet.md`:

- The booklet H1 is the booklet title (written in `booklet-header.md`)
- Each dimension is an H2 section (`## {DIMENSION_HEADER for this dim}`)
- Subcategories are H3 (`### {SUBCATEGORY_HEADER}`)
- Horizons are H4 (`#### {HORIZON_LABEL_ACT/PLAN/OBSERVE}`)
- Per-candidate entries are H3 inside the horizon (numbered `### {N}.{n}.{a} {Trend Name}`) — the numbering is `dimension_index.subcategory_index.entry_index`

This lets a reader scan the table of contents and find any candidate by dimension → subcategory → horizon coordinates.

---

## Per-Entry Block Template

Each candidate gets one block:

```markdown
### {N}.{n}.{a} {Trend Name}

*{horizon} • {subcategory}*

**{ENTRY_SUMMARY_HEADER}** — 2-3 sentences from enriched evidence_md + implications_md.

**{ENTRY_CITATIONS_HEADER}**
- [Source title](url) — context
- [Source title](url) — context

**{ENTRY_THEMES_HEADER}**
- *{theme_name}* (theme_id) — role in that theme's value chain (trend / implication / possibility / foundation)

**{ENTRY_KEYWORDS_HEADER}** {comma-separated keyword list}
```

The italic line under the title (`*{horizon} • {subcategory}*`) makes the entry's coordinates visible without re-reading the H4 / H3 above. Useful when a reader lands on a deep-link to a single entry.

---

## Per-Tier Density

Density tier (passed as `DENSITY_TIER` in the formatter prompt) controls per-entry word budget. See [booklet-length-tiers.md](booklet-length-tiers.md) for the tier definitions and the per-block summary / citation budgets.

---

## Theme-Backref Block

The `**{ENTRY_THEMES_HEADER}**` block lists every theme this candidate participates in, derived from the value model walk in [candidate-to-theme-backref.md](candidate-to-theme-backref.md). When a candidate appears under multiple themes, render one bullet per theme. When a candidate has no theme back-references, **omit this block entirely** — the formatter renders the entry under the orphan appendix instead.

Role values from the value-chain walk:
- `trend` — candidate is the chain's `trend` (T-pole)
- `implication` — listed in `chain.implications[]` (I-pole)
- `possibility` — listed in `chain.possibilities[]` (P-pole)
- `foundation` — listed in `chain.foundation_requirements[]` (S-pole)

Localize the role label using the synthesis-side i18n labels (TREND / IMPLICATION / POSSIBILITY / FOUNDATION) so booklet and report use consistent vocabulary.

---

## Orphan Appendix (per dimension)

Orphan candidates (no `theme_backrefs[]`) appear at the end of each dimension's section under a dedicated appendix:

```markdown
## {ORPHAN_APPENDIX_HEADER}

*{N} candidates in this dimension are not currently anchored to any
investment theme. They are listed here for completeness; consider revisiting
/value-modeler to incorporate them into a theme.*

### {trend name}
... (same per-entry block, minus the **{ENTRY_THEMES_HEADER}** block)
```

Keeping orphans dimension-local (rather than as a single global appendix at the end of the booklet) makes them visible to a reader scanning that dimension and signals that this dimension has un-anchored signals worth revisiting.

---

## Empty Buckets

When a dimension has zero candidates in a horizon (e.g., zero ACT-horizon trends in `digitales-fundament`), the formatter still renders the H4 horizon heading with a one-line note:

```markdown
#### {HORIZON_LABEL_ACT}

*No candidates in this horizon for this dimension.*
```

Don't omit the horizon heading entirely — the structural symmetry across dimensions matters for readability.
