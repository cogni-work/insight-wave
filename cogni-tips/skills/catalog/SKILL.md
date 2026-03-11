---
name: catalog
description: >
  Manage persistent industry catalogs that accumulate TIPS knowledge across pursuits.
  Use whenever the user mentions "industry catalog", "catalog", "initialize catalog",
  "import to catalog", "promote to catalog", "catalog status", "list catalogs",
  "create catalog", "export catalog", "catalog analytics", "cross-pursuit",
  "reusable patterns", "industry knowledge base", or wants to manage the persistent
  repository of TIPs, Solution Templates, SPIs, Metrics, and Collaterals that new
  pursuits inherit from. Also trigger when the user has completed value-modeler
  curation (Phase 5) and wants to actually persist the recommendations.
---

# Industry Catalog

Manage persistent industry catalogs — the reusable knowledge base that makes each
successive customer pursuit faster, more consistent, and more valuable.

## Why Catalogs Matter

Without catalogs, every TIPS pursuit starts from scratch. The trend-scout generates
candidates, the value-modeler builds paths and solutions, but all that structured
knowledge lives only in the pursuit directory. The next customer engagement in the
same industry repeats the same work.

Catalogs solve this by creating a persistent, curated repository per industry/subsector.
When a new pursuit is initialized, it inherits relevant TIPs, Solution Templates, SPIs,
and Metrics from the catalog — giving the consultant a head start and ensuring consistency
across engagements.

This implements the centralized repository concept from the TIPS Value Modeler methodology
(WO2018046399A1, Claim 3 and Fig. 4).

## Catalog Structure

```
cogni-tips/catalogs/{industry}/{subsector}/
├── catalog.json              # Root manifest (industry, version, stats)
├── tips-entities.json        # Curated TIP entities (T, I, P roles)
├── solution-templates.json   # Proven Solution Templates
├── spis.json                 # Validated Solution Process Improvements
├── metrics.json              # Effective success KPIs
├── collaterals.json          # Available supporting content
└── .history/                 # Version snapshots (catalog.json copies)
```

Catalogs live at the plugin workspace level (`cogni-tips/catalogs/`), not inside
any pursuit project directory. They persist across projects and sessions.

## Operations

### init — Create a New Catalog

Create an empty catalog for an industry/subsector combination.

```
/catalog init
```

**Steps:**

1. Ask user for industry and subsector (use the same taxonomy as trend-scout:
   read `$CLAUDE_PLUGIN_ROOT/skills/trend-scout/references/industry-taxonomy.md`)
2. Optionally load a taxonomy template as seed data (see Taxonomy Templates below)
3. Create the directory structure and `catalog.json`

**catalog.json schema:**

```json
{
  "version": "1.0.0",
  "industry": {
    "primary": "manufacturing",
    "primary_en": "Manufacturing",
    "primary_de": "Fertigung",
    "subsector": "automotive",
    "subsector_en": "Automotive",
    "subsector_de": "Automobil"
  },
  "created": "2026-03-11T10:00:00Z",
  "updated": "2026-03-11T10:00:00Z",
  "stats": {
    "tips_entities": 0,
    "solution_templates": 0,
    "spis": 0,
    "metrics": 0,
    "collaterals": 0,
    "pursuits_contributed": 0
  },
  "taxonomy_template": null,
  "pursuit_history": []
}
```

### import — Promote Pursuit Data to Catalog

Import curated entities from a completed value-modeler pursuit into the catalog.
This is the write-back loop that makes catalogs grow smarter over time.

```
/catalog import
```

**Steps:**

1. Discover TIPS projects with completed value models (`workflow_state: "curated"` or `"complete"`)
2. If curation recommendations exist (`tips-value-model.json` → `curation_recommendations`),
   use them as the starting point — these are pre-analyzed by Phase 5
3. If no curation recommendations exist, analyze the value model directly
   (same criteria as Phase 5: paths with BR >= 4.0, Tier 1-2 STs, etc.)
4. Find the matching catalog (by industry/subsector) or offer to create one
5. Present import candidates to user for approval — show what will be added/merged
6. On approval, write entities to catalog files

**Import rules:**

- **Generalize before importing.** Strip customer names, specific product references,
  and pursuit-specific context. The catalog should contain industry-general patterns.
- **Deduplicate.** Check if a semantically similar entity already exists in the catalog.
  If so, offer to merge (strengthen the existing entry) rather than create a duplicate.
- **Track provenance.** Each imported entity gets a `provenance` field:

```json
{
  "source_pursuit": "automotive-ai-predictive-maintenance-abc12345",
  "imported_at": "2026-03-11T14:00:00Z",
  "original_ref": "st-001",
  "generalization_notes": "Replaced 'BMW Regensburg line sensors' with 'production line sensors'"
}
```

- **Update stats.** Increment `stats` counts and add pursuit to `pursuit_history`:

```json
{
  "pursuit_slug": "automotive-ai-predictive-maintenance-abc12345",
  "imported_at": "2026-03-11T14:00:00Z",
  "entities_imported": { "tips": 3, "sts": 2, "spis": 1, "metrics": 2, "collaterals": 0 }
}
```

### list — Show Available Catalogs

```
/catalog list
```

List all catalogs in `cogni-tips/catalogs/` with their industry, subsector, entity counts,
and last update date. Show a compact table.

### show — Display Catalog Contents

```
/catalog show [industry/subsector]
```

Display the full contents of a specific catalog with entity counts per type, most recent
imports, and coverage summary. If the catalog was initialized from a taxonomy template,
show coverage against the template categories.

### analytics — Cross-Pursuit Insights

```
/catalog analytics [industry/subsector]
```

Analyze patterns across all pursuits that contributed to a catalog:

- **Trend frequency:** Which TIP entities appear in multiple pursuits? These are market signals.
- **Solution popularity:** Which STs are most frequently selected? These are portfolio priorities.
- **BR distribution:** How do BR scores distribute across pursuits for the same entities?
- **Coverage gaps:** Which catalog areas have few or no entities?
- **Maturity curve:** How has the catalog grown over time?

Present insights as a structured summary with actionable recommendations.

## Entity Schemas

### Catalog TIP Entity

TIP entities in the catalog are generalized versions of pursuit-specific candidates.
They retain the TIPS role (T/I/P) and dimension mapping but are stripped of pursuit context.

```json
{
  "entity_id": "cat-tip-001",
  "name": "Increasing regulatory pressure on AI systems",
  "description": "Governments worldwide are implementing AI governance frameworks that create compliance requirements for industrial AI deployments",
  "tips_role": "T",
  "dimension": "externe-effekte",
  "subcategory": "regulierung",
  "keywords": ["ai-regulation", "compliance", "governance"],
  "horizon": "act",
  "provenance": {
    "source_pursuit": "automotive-ai-predictive-maintenance-abc12345",
    "imported_at": "2026-03-11T14:00:00Z",
    "original_ref": "externe-effekte/act/1",
    "generalization_notes": "Broadened from EU AI Act to global AI governance"
  },
  "pursuit_appearances": 3,
  "avg_business_relevance": 4.2
}
```

### Catalog Solution Template

```json
{
  "st_id": "cat-st-001",
  "name": "Predictive Quality Analytics Platform",
  "description": "ML-based quality prediction integrated with production line sensor data for real-time defect detection",
  "category": "software",
  "enabler_type": "process_improvement",
  "typical_linked_tips": ["cat-tip-001", "cat-tip-005", "cat-tip-012"],
  "portfolio_mapping_hint": {
    "suggested_dimension": 6,
    "suggested_category": "6.6",
    "suggested_category_name": "AI, Data & Analytics"
  },
  "provenance": {
    "source_pursuit": "automotive-ai-predictive-maintenance-abc12345",
    "imported_at": "2026-03-11T14:00:00Z",
    "original_ref": "st-001",
    "generalization_notes": "Removed brand-specific sensor references"
  },
  "pursuit_appearances": 2,
  "avg_ranking_value": 4.1
}
```

The `portfolio_mapping_hint` uses b2b-ict-portfolio taxonomy category IDs when a taxonomy
template is loaded. This enables downstream mapping to cogni-portfolio features.

### Catalog SPI

```json
{
  "spi_id": "cat-spi-001",
  "name": "Establish data governance policy for sensor data",
  "description": "Define data ownership, quality standards, and access controls for production data",
  "change_type": "governance",
  "typical_st_refs": ["cat-st-001"],
  "provenance": { "..." : "..." },
  "pursuit_appearances": 2
}
```

### Catalog Metric

```json
{
  "metric_id": "cat-met-001",
  "name": "Defect rate reduction",
  "unit": "percentage",
  "direction": "decrease",
  "typical_baseline_range": "2-8%",
  "typical_target_range": "0.5-2%",
  "provenance": { "..." : "..." },
  "pursuit_appearances": 3
}
```

### Catalog Collateral

```json
{
  "collateral_id": "cat-col-001",
  "name": "Predictive Maintenance ROI Case Study",
  "type": "case-study",
  "typical_st_refs": ["cat-st-001"],
  "status": "exists",
  "provenance": { "..." : "..." }
}
```

## Taxonomy Templates

Catalogs can be initialized from a taxonomy template that pre-defines the category
structure. The template does not provide entities — it provides the dimensional framework
that guides what kinds of entities should be collected.

Currently supported template:

| Template | Source | Categories |
|----------|--------|-----------|
| `b2b-ict-portfolio` | cogni-research | 57 categories across 8 dimensions (0-7) |

When a taxonomy is loaded, the catalog gains:
- A `taxonomy_template` field in `catalog.json` pointing to the template
- Coverage tracking: which taxonomy categories have catalog entities mapped to them
- Gap analysis: which categories remain empty

To use: during `/catalog init`, when asked about taxonomy, reference the b2b-ict-portfolio
framework. Read the taxonomy definition from:
`$CLAUDE_PLUGIN_ROOT/references/taxonomies/b2b-ict-portfolio.md`

If the file does not exist yet, the user can provide the taxonomy source or skip taxonomy loading.

## Integration with Value Modeler

### Phase 0 Enhancement: Load Catalog

When value-modeler Phase 0 discovers a project, it should also search for a matching
industry catalog:

1. Read the project's industry/subsector from `tips-project.json`
2. Check `cogni-tips/catalogs/{industry}/{subsector}/catalog.json`
3. If found, report: "Found {industry}/{subsector} catalog with X entities. Catalog data will inform relationship building and solution generation."
4. Store catalog path in `.metadata/value-modeler-output.json` as `catalog_path`

The catalog does NOT replace trend-scout candidates. It supplements them:
- Phase 1 can use catalog TIP entities as seed patterns for path building
- Phase 2 can pre-populate Solution Templates from catalog STs
- Phase 2 can suggest SPIs and Metrics from the catalog

### Phase 5 Enhancement: Write-Back

When Phase 5 curation completes and generates recommendations:
- If a matching catalog exists, offer to run `/catalog import` immediately
- If no catalog exists, suggest creating one with `/catalog init`
- The curation recommendations become the import candidate list

## Language

Match the project or user language. Catalog entity names and descriptions can be
bilingual (matching the pursuit language). The `industry` object always carries both
`_en` and `_de` variants for consistency with the industry taxonomy.

## Output

All catalog operations report results to the user with clear counts and summaries.
Import operations always require explicit user approval before writing.
