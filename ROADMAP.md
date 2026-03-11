# cogni-works Ecosystem Roadmap

> Based on patent WO2018046399A1 vision, cogni-tips value-modeler implementation,
> b2b-ict-portfolio taxonomy from cogni-research, and cross-plugin integration analysis.
>
> Created: 2026-03-11 | Last updated: 2026-03-11

---

## Vision

Complete the patent's closed-loop system across the cogni-works ecosystem:

```
Industry Catalog (generic knowledge) ──inherit──> Pursuit (customer-specific)
       ^                                                    |
       └──────────── curate (promote learnings) <───────────┘
                              |
                    Product Portfolio (solutions)
```

Three structural pillars fill the gaps between what's built and the full patent vision:
1. **Industry Catalog** — persistent, reusable knowledge base across pursuits
2. **TIPS <> Portfolio Bridge** — bidirectional flow between trend analysis and portfolio
3. **Portfolio Taxonomy** — enterprise-grade classification for ICT service providers

---

## Status Legend

- [ ] Not started
- [~] In progress
- [x] Complete

---

## P1: Core Patent Completion

### 1. Industry Catalog Skill (cogni-tips)

**Goal:** Persistent industry catalogs that accumulate knowledge across pursuits.
The patent's central value proposition — reuse and consistency.

**Plugin:** cogni-tips | **Effort:** Medium | **Depends on:** value-modeler (complete)

```
cogni-tips/catalogs/{industry}/{subsector}/
├── catalog.json              # Root manifest
├── tips-entities.json        # Curated TIPs
├── solution-templates.json   # Proven STs with portfolio mappings
├── spis.json                 # Validated SPIs
├── metrics.json              # Effective KPIs
├── collaterals.json          # Available content assets
└── .history/                 # Version snapshots
```

- [x] Design catalog schema (entities, versioning, cross-pursuit refs)
- [x] Create `catalog` skill SKILL.md with init/import/export/analytics
- [x] Modify Phase 0 to discover and load relevant industry catalog
- [x] Modify Phase 5 to write-back with user approval (not just advisory)
- [x] Add catalog discovery to `resume-tips` status dashboard
- [ ] Initialize first catalog from b2b-ict-portfolio taxonomy template

### 2. TIPS <> Portfolio Bridge (cogni-portfolio or cogni-workspace)

**Goal:** Bidirectional entity flow between cogni-tips value-modeler and cogni-portfolio.
Connects the "Sales/Value" side to the "Services/Best Practices" side (patent Fig. 1).

**Plugin:** cogni-portfolio | **Effort:** Medium | **Depends on:** value-modeler (complete), catalog (P1.1)

| Direction | What Flows | Current State |
|-----------|-----------|---------------|
| TIPS > Portfolio | Ranked STs become Features/Propositions | Mapping exists, no action |
| Portfolio > TIPS | Existing products constrain ST generation | Not implemented |
| TIPS > Portfolio | BR scores inform market prioritization | Not implemented |
| Portfolio > TIPS | Feature quality gates STs | Not implemented |

- [x] Design bridge skill with `tips-to-portfolio` and `portfolio-to-tips` modes
- [x] Implement ST-to-Feature stub generation (unmapped high-ranked STs)
- [x] Implement Proposition enrichment (trend narrative > DOES, outcome > MEANS)
- [x] Implement portfolio loading as ST constraints for Phase 2
- [x] Add TIPS Metrics > portfolio evidence claim mapping
- [x] Register bridge skill in cogni-portfolio plugin.json

---

## P2: Enterprise Enrichment

### 3. Portfolio Taxonomy Support (cogni-portfolio)

**Goal:** Adopt industry-standard classification systems (like b2b-ict-portfolio's 57 categories
across 8 dimensions) for enterprise ICT service providers.

**Plugin:** cogni-portfolio | **Effort:** Medium | **Depends on:** none

```json
// portfolio.json addition
{ "taxonomy": { "type": "b2b-ict-portfolio", "version": "3.7" } }

// feature.json addition
{ "taxonomy_mapping": { "dimension": 4, "category_id": "4.6", "category_name": "Cloud-Native Platform" } }
```

- [x] Design taxonomy schema (dimension/category structure, feature mapping)
- [x] Add `taxonomy` field to portfolio.json and `taxonomy_mapping` to feature.json
- [x] Import b2b-ict-portfolio as first taxonomy reference
- [ ] Add taxonomy coverage heatmap to `/dashboard`
- [ ] Add gap analysis: dimensions/categories with no features
- [x] Add service horizon tagging (Current/Emerging/Future)
- [ ] Update `validate-entities.sh` for taxonomy validation

### 4. Big Block Visual Rendering (cogni-visual)

**Goal:** Render the Big Block diagram as a visual artifact instead of markdown.
This is the patent's "specific diagram of industry solutions" — the key customer deliverable.

**Plugin:** cogni-visual | **Effort:** Low | **Depends on:** value-modeler (complete)

- [ ] Design big-block-brief.md format (structured brief from Phase 4 output)
- [ ] Create `story-to-big-block` skill or extend existing big-picture skill
- [ ] Solution categories as visual blocks, color-coded by BR tier
- [ ] TIPS path connections shown as links between blocks
- [ ] Excalidraw and/or PPTX output

---

## P3: Analytics & Feedback

### 5. Cross-Pursuit Dashboard (cogni-tips)

**Goal:** Aggregate insights across multiple pursuits for the same industry catalog.

**Plugin:** cogni-tips | **Effort:** Low | **Depends on:** catalog (P1.1)

- [ ] Trend frequency analysis (which TIPs appear across pursuits)
- [ ] ST selection patterns (portfolio priorities signal)
- [ ] Catalog maturity tracking (entity counts, coverage over time)
- [ ] Pursuit conversion tracking (ranked > proposed > delivered)

### 6. Realization Tracking (cogni-portfolio)

**Goal:** Track actual customer outcomes vs. predicted TIPS Metrics.
Closes the ML feedback loop from patent Claim 4.

**Plugin:** cogni-portfolio | **Effort:** Medium | **Depends on:** bridge (P1.2)

- [ ] Design outcomes schema (metric, predicted, actual, delta)
- [ ] Add `realize` skill or extend `solutions` with outcome tracking
- [ ] Feed outcome data back to catalog ranking model calibration

---

## P4: Extended Pipeline

### 7. cogni-research > cogni-portfolio Pipeline

**Goal:** Competitor portfolio discovery feeds directly into portfolio gap analysis.

**Plugins:** cogni-research + cogni-portfolio | **Effort:** Medium | **Depends on:** taxonomy (P2.3)

- [ ] cogni-research discovers competitor portfolios mapped to taxonomy
- [ ] Results feed into cogni-portfolio via `ingest` skill
- [ ] Competitive analysis pre-populated with taxonomy-aligned data

---

## Architecture Principle

No monolithic shared repository. Each plugin owns its data. Cross-references use slugs/paths:

```
cogni-tips/catalogs/manufacturing/automotive/solution-templates.json
  └── portfolio_ref: "cogni-portfolio/{project}/features/predictive-analytics"

cogni-portfolio/{project}/features/predictive-analytics.json
  └── tips_ref: "cogni-tips/{pursuit}/tips-value-model.json#st-001"
```

The bridge skill resolves references at runtime. Loose coupling, independent evolution.

---

## Patent Coverage Matrix

| Patent Feature | Claim | Implementation | Status |
|---------------|-------|---------------|--------|
| Repository with TIP entities | 1b | trend-scout candidates | Complete |
| Repository with solution entities | 1c | value-modeler Phase 2 STs | Complete |
| Relationship networks (TIPS paths) | 1d | value-modeler Phase 1 | Complete |
| Link paths to solution entities | 1e | value-modeler Phase 2 | Complete |
| Customer-specific TIP selection | 1f | trend-scout Phase 3 selection | Complete |
| Business Relevance scoring (1-5) | 1g | value-modeler Phase 3 | Complete |
| Generate solution subset from paths | 1h | value-modeler Phase 2 | Complete |
| Ranking value (F1 formula) | 2 | value-modeler Phase 4 (Enhanced F1) | Complete |
| Curation / repository update | 3 | value-modeler Phase 5 (advisory) | Partial |
| Machine learning update | 4 | — | P3.6 |
| Industry catalog inheritance | Fig.4 | — | P1.1 |
| Product portfolio mapping | Fig.1 | portfolio_mapping field | Partial |
| Bidirectional portfolio flow | Fig.1 | — | P1.2 |
| Big Block diagram (visual) | Fig.3 | markdown only | P2.4 |
| Solution Process Improvements | Fig.3 | value-modeler Phase 2 SPIs | Complete |
| Metrics | Fig.3 | value-modeler Phase 2 | Complete |
| Collaterals | Fig.3 | value-modeler Phase 2 | Complete |
| Delivery/Adoption/Realization | Fig.1 | solutions/packages exist, realize missing | P3.6 |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-03-11 | Initial roadmap created from patent analysis + ecosystem review |
| 2026-03-11 | P1.1: Created catalog skill (SKILL.md, schemas, taxonomy ref), updated Phase 0/5, resume-tips, data-model, plugin.json v0.3.0 |
| 2026-03-11 | P1.2: Created bridge skill in cogni-portfolio (tips-to-portfolio, portfolio-to-tips, sync), plugin.json v0.8.0 |
| 2026-03-11 | P2.3: Added taxonomy support to data-model.md (portfolio.json taxonomy, feature taxonomy_mapping, horizon), imported b2b-ict-portfolio taxonomy |
