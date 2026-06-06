# cogni-trends changelog

## 0.6.5 — 2026-06-06 — value-modeler Phase 2 evidence dispatch rerouted to cogni-knowledge

`value-modeler` Phase 2 (`references/workflow-phases/phase-2-solutions.md`) no longer
dispatches the deprecated cogni-wiki / cogni-research surfaces for two of its three
solution-evidence sites:

- **Vendor wiki (Step 2.6.A)** — the optional `cogni-wiki:wiki-query` dispatch is replaced by
  cogni-knowledge's re-homed native discovery primitive,
  `wiki-grounding.py rank --wiki-root … --question … --theme-label …`, then `Read` of the ranked
  `data.pages[]` + inline synthesis. No plugin dispatch, no binding, no file-back.
- **Open-mode published cases (Step 2.6.B)** — the `cogni-research:section-researcher` dispatch is
  replaced by a native cogni-knowledge research pass (inline `WebSearch` + `WebFetch`, or
  `cogni-knowledge:knowledge-ingest-source` per discovered URL), preserving the ≤ 4-sub-query budget.

The per-ST dispatch budget table and the `data-model.md` attribution prose (`source: "wiki"`,
`published_cases[]` preamble) are updated to match. Output shape (`vendor_references[]`,
`published_cases[]`, per-ST mutual exclusivity) and all `source` field *values* are unchanged —
downstream writers are unaffected. The uploaded-corpus `cogni-research:local-researcher` site
(Step 2.6 point 4, `source: "uploads"`) is deliberately untouched; it is carved out to a separate
follow-up gated on cogni-knowledge local-source ingest. Part of the FMO Migrate epic (Epic B).

## 0.6.4 — 2026-05-29 — Discoverability — manifest description compacted (closes #351 for this plugin)

`description` in `.claude-plugin/plugin.json` and the matching `marketplace.json`
entry compacted from 793 to 368 chars. All load-bearing qualifiers retained
inline (Smarter Service Trendradar, TIPS framework, full pipeline shape,
market reach). Per-skill enrichment narrative ("trend-research enriches every
candidate...", "4 H2 dimensions × anchored H3 theme-cases, closing on a
Capability Imperative", booklet "dimension → subcategory → horizon")
moved to README. `keywords[]` adds `value-modeler`, `verify-trend-report`,
`trendradar`, `capability-imperative`, `investment-theme`. No behavioural
change. No schema change. No skill change.
