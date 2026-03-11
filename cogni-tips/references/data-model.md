# cogni-tips Data Model Reference

## Project Structure

```
cogni-tips/{project-slug}/
├── tips-project.json              # Root manifest (project config + metadata)
├── trend-candidates.md            # Human-readable candidate selection (Phase 3)
├── trend-selector-app.html        # Visual selector app (Phase 3)
├── trend-app-data.json            # Selector app data (Phase 3)
├── tips-trend-report.md           # Final assembled report (trend-report)
├── tips-trend-report-claims.json  # Merged claims registry (trend-report)
├── tips-insight-summary.md        # Narrative insight summary (trend-report Phase 2.5)
├── .metadata/                     # Workflow state + execution data
│   ├── trend-scout-output.json    # Consolidated scout output (config + candidates + state)
│   └── trend-report-verification.json  # Claim verification results
├── .logs/                         # Debug/audit trail (agent outputs)
│   ├── web-research-raw.json      # Full web research signals
│   ├── trend-generator-candidates.json  # Full candidate generation data
│   ├── candidates-compact.json    # Compact format for Phase 3
│   ├── report-header.md           # Report header section
│   ├── report-section-{dimension}.md   # Per-dimension report sections (4 files)
│   ├── claims-{dimension}.json    # Per-dimension claims (4 files)
│   ├── report-portfolio.md        # Portfolio analysis section
│   └── report-claims-registry.md  # Claims table section
└── phase1-research-summary.json   # Fallback copy of web research response
```

## Entity Schemas

### tips-project.json (Project Root)

Lightweight root manifest for project discovery and resume. Created during Phase 0, updated as workflow progresses.

```json
{
  "slug": "automotive-ai-predictive-maintenance-abc12345",
  "name": "Automotive AI Predictive Maintenance",
  "language": "de",
  "industry": {
    "primary": "manufacturing",
    "primary_en": "Manufacturing",
    "primary_de": "Fertigung",
    "subsector": "automotive",
    "subsector_en": "Automotive",
    "subsector_de": "Automobil"
  },
  "research_topic": "AI-driven predictive maintenance",
  "created": "2026-01-15T10:30:00Z",
  "updated": "2026-01-16T14:20:00Z"
}
```

Required fields: `slug`, `name`, `language`, `industry`, `research_topic`, `created`
Optional fields: `updated`

The `language` field is a lowercase ISO 639-1 code (`"de"` or `"en"`). Controls the language of all generated user-facing content. JSON field names and slugs remain in English.

The `industry` object uses bilingual names for web research queries. The `primary` and `subsector` fields are slug-format identifiers; `_en` and `_de` variants are display names.

### trend-scout-output.json (Scout Output)

Location: `.metadata/trend-scout-output.json`

Consolidated output from the trend-scout skill containing project config, candidate data, scoring metadata, and execution state.

```json
{
  "version": "1.0.0",
  "project_id": "automotive-ai-predictive-maintenance-abc12345",
  "project_language": "de",

  "config": {
    "research_type": "smarter-service",
    "dok_level": 4,
    "industry": {
      "primary": "manufacturing",
      "primary_en": "Manufacturing",
      "primary_de": "Fertigung",
      "subsector": "automotive",
      "subsector_en": "Automotive",
      "subsector_de": "Automobil"
    },
    "research_topic": "AI-driven predictive maintenance",
    "organizing_concept": "ai-driven-predictive-maintenance"
  },

  "tips_candidates": {
    "total": 52,
    "source_distribution": {
      "web_signal": 18,
      "training": 32,
      "user_proposed": 2
    },
    "web_research_status": "success",
    "search_timestamp": "2026-01-15T10:25:00Z",
    "scoring_metadata": {
      "avg_score": 0.68,
      "confidence_distribution": { "high": 12, "medium": 18, "low": 5, "uncertain": 1 },
      "intensity_distribution": { "level_1": 4, "level_2": 6, "level_3": 10, "level_4": 12, "level_5": 4 },
      "indicator_distribution": { "leading": 16, "lagging": 20, "leading_pct": 0.44 },
      "diffusion_distribution": {
        "innovators": 3, "early_adopters": 8, "early_majority": 15,
        "late_majority": 8, "laggards": 2, "pre_chasm": 11, "post_chasm": 25
      },
      "scoring_framework_version": "1.0.0"
    },
    "items": []
  },

  "execution": {
    "workflow_state": "agreed",
    "current_phase": 5,
    "phases_completed": ["phase-0", "phase-1", "phase-2", "phase-3", "phase-4", "phase-5"],
    "agreed_at": "2026-01-15T11:45:00Z"
  },

  "deeper_analysis_integration": {
    "source_type": "trend-scout",
    "auto_load_candidates": true,
    "skip_tips_selection": true,
    "auto_configure_research_type": true,
    "auto_configure_dok_level": true,
    "auto_configure_language": true
  }
}
```

Workflow state values (in order): `initialized` → `phase-1` → `phase-2` → `phase-3` → `phase-4` → `phase-5` → `agreed`

### Candidate Object

Each candidate in `tips_candidates.items`:

```json
{
  "dimension": "externe-effekte",
  "subcategory": "regulierung",
  "horizon": "act",
  "sequence": 1,
  "name": "EU AI Act Compliance",
  "trend_statement": "The EU AI Act creates immediate compliance requirements...",
  "keywords": ["ai-act", "regulation", "2024"],
  "research_hint": "Investigate implementation timelines and compliance costs...",
  "source": "web-signal",
  "source_url": "https://ec.europa.eu/...",
  "freshness_date": "2024-12",
  "score": 0.82,
  "confidence_tier": "high",
  "signal_intensity": 5,
  "component_scores": {
    "impact": 0.90,
    "probability": 0.95,
    "strategic_fit": 0.75,
    "source_quality": 0.80,
    "signal_strength": 0.85,
    "uncertainty_penalty": 0.02
  },
  "indicator_classification": {
    "type": "leading",
    "lead_time": "12-24m",
    "source_type": "regulatory"
  },
  "diffusion_stage": {
    "stage": "early_majority",
    "estimated_adoption": 0.25,
    "crossed_chasm": true
  }
}
```

Required fields: `dimension`, `subcategory`, `horizon`, `sequence`, `name`, `trend_statement`, `keywords`, `research_hint`, `source`, `score`, `confidence_tier`, `signal_intensity`

Optional fields: `source_url`, `freshness_date`, `component_scores`, `indicator_classification`, `diffusion_stage`

Valid `dimension` values: `externe-effekte`, `neue-horizonte`, `digitale-wertetreiber`, `digitales-fundament`

Valid `subcategory` values per dimension:
- `externe-effekte`: `wirtschaft`, `regulierung`, `gesellschaft`
- `neue-horizonte`: `strategie`, `fuehrung`, `steuerung`
- `digitale-wertetreiber`: `customer-experience`, `produkte-services`, `geschaeftsprozesse`
- `digitales-fundament`: `kultur`, `mitarbeitende`, `technologie`

Valid `horizon` values: `act` (immediate, 0-12 months), `plan` (medium-term, 12-36 months), `observe` (long-term, 36+ months)

Valid `source` values: `web-signal` (discovered via web research), `training` (generated from model knowledge), `user_proposed` (added by user)

Valid `confidence_tier` values: `high` (0.80-1.0), `medium` (0.50-0.79), `low` (0.30-0.49), `uncertain` (<0.30)

`signal_intensity` (Ansoff scale): 1=turbulence, 2=moderate, 3=emerging, 4=clear signal, 5=foreseeable

### Claims Registry

Location: `tips-trend-report-claims.json`

```json
{
  "status": "success",
  "file_path": "tips-trend-report.md",
  "language": "de",
  "total_claims": 42,
  "claims": [
    {
      "id": "claim_EE_001",
      "dimension": "externe-effekte",
      "tips_role": "T",
      "text": "Der globale KI-Markt wird bis 2027 auf 407 Mrd. USD wachsen.",
      "value": "407",
      "unit": "USD Mrd.",
      "type": "currency",
      "context": "Global AI market size projection",
      "qualifiers": ["global", "2027"],
      "citations": [
        { "url": "https://example.com/report", "proximity_confidence": 0.9 }
      ]
    }
  ]
}
```

Claim `id` format: `claim_{DIMENSION_PREFIX}_{SEQ}` where prefix is `EE` (externe-effekte), `DW` (digitale-wertetreiber), `NH` (neue-horizonte), `DF` (digitales-fundament).

Valid `type` values: `currency`, `percentage`, `count`, `timeframe`, `ratio`

### Verification Metadata

Location: `.metadata/trend-report-verification.json`

```json
{
  "verified_at": "2026-01-16T14:20:00Z",
  "verdict": "PASS",
  "total_claims": 42,
  "verified": 42,
  "passed": 38,
  "failed": 2,
  "review": 2
}
```

## Dimension Matrix

| Dimension | TIPS Role | Subcategories | Candidates per Horizon |
|-----------|-----------|---------------|----------------------|
| `externe-effekte` | T (Trends) | wirtschaft, regulierung, gesellschaft | 5 ACT, 5 PLAN, 3 OBSERVE |
| `neue-horizonte` | P (Possibilities) | strategie, fuehrung, steuerung | 5 ACT, 5 PLAN, 3 OBSERVE |
| `digitale-wertetreiber` | I (Implications) | customer-experience, produkte-services, geschaeftsprozesse | 5 ACT, 5 PLAN, 3 OBSERVE |
| `digitales-fundament` | S (Solutions) | kultur, mitarbeitende, technologie | 5 ACT, 5 PLAN, 3 OBSERVE |

**Total**: 4 dimensions x (5 + 5 + 3) = 52 agreed candidates (selected from 76 generated)

## Workflow Phases

| Phase | Skill | State Value | What Happens |
|-------|-------|-------------|-------------|
| 0 | trend-scout | `initialized` | Language, industry, topic selection; project creation |
| 1 | trend-scout | `phase-1` | Bilingual web research (32 queries + APIs) |
| 2 | trend-scout | `phase-2` | Generate 76 candidates with multi-framework scoring |
| 3 | trend-scout | `phase-3` | Present candidates for user selection |
| 4 | trend-scout | `phase-4` | Validate user selection (52 candidates) |
| 5 | trend-scout | `phase-5` → `agreed` | Finalize output JSON |
| R-0 | trend-report | `agreed` | Load input, validate gate, prep agent inputs |
| R-1 | trend-report | `report-enriching` | 4 parallel agents: evidence + section writing |
| R-2 | trend-report | `report-assembling` | Exec summary + portfolio analysis + assembly |
| R-2.5 | trend-report | `report-insight` | Optional narrative insight summary |
| R-3 | trend-report | `report-verifying` | Optional claim verification |
| R-4 | trend-report | `report-complete` | Finalization + metadata update |
| V-0 | value-modeler | `initialized` | Load scout output, discover portfolio |
| V-1 | value-modeler | `paths-built` | Build T→I→P relationship networks |
| V-2 | value-modeler | `solutions-generated` | Generate Solution Templates |
| V-3 | value-modeler | `scored` | Customer-specific BR scoring (1-5) |
| V-4 | value-modeler | `complete` | Apply F1 formula, rank, Big Block diagram |
| V-5 | value-modeler | `curated` | Optional: promote pursuit patterns to industry catalog |

## Entity Relationships

```
tips-project.json (root manifest)
  └── .metadata/trend-scout-output.json (config + candidates + state)
        ├── .logs/web-research-raw.json (raw signals → candidates)
        ├── .logs/trend-generator-candidates.json (76 generated → 52 selected)
        ├── tips-trend-report.md (report ← candidates)
        │     ├── .logs/report-section-{dimension}.md (4 sections)
        │     ├── tips-trend-report-claims.json (extracted claims)
        │     ├── tips-insight-summary.md (narrative summary)
        │     └── .metadata/trend-report-verification.json (verification results)
        └── tips-value-model.json (value modeler ← candidates)
              ├── paths[] (T→I→P relationship networks)
              ├── solution_templates[] (enablers linked to paths)
              ├── solution_process_improvements[] (SPIs per ST)
              ├── metrics[] (success KPIs per path)
              ├── collaterals[] (supporting content per ST)
              ├── curation_recommendations[] (catalog feedback loop)
              ├── tips-solution-ranking.md (ranked solution list)
              ├── tips-big-block.md (solution architecture diagram)
              ├── value-modeler-scoring.html (interactive BR scoring UI)
              └── .metadata/value-modeler-output.json (execution state)
```

## Value Modeler Schemas

### TIPS Path (Relationship Network)

```json
{
  "path_id": "path-001",
  "name": "AI-Driven Quality Optimization",
  "narrative": "Regulatory pressure drives need for real-time defect detection, enabling predictive quality management",
  "trend": { "candidate_ref": "externe-effekte/act/1", "name": "...", "business_relevance": null },
  "implications": [
    { "candidate_ref": "digitale-wertetreiber/act/3", "name": "...", "business_relevance": null }
  ],
  "possibilities": [
    { "candidate_ref": "neue-horizonte/plan/2", "name": "...", "business_relevance": null }
  ],
  "foundation_requirements": [
    { "candidate_ref": "digitales-fundament/act/2", "name": "...", "relationship": "prerequisite" }
  ],
  "solution_templates": ["st-001", "st-002"]
}
```

### Solution Template

```json
{
  "st_id": "st-001",
  "name": "Predictive Quality Analytics Platform",
  "description": "Deploy ML-based quality prediction integrated with production line sensors",
  "category": "software|hardware|service|hybrid|process",
  "enabler_type": "process_improvement|capability_building|risk_mitigation|revenue_enablement",
  "linked_paths": ["path-001", "path-003"],
  "foundation_dependencies": ["digitales-fundament/act/2"],
  "portfolio_mapping": {
    "product_slug": "cloud-platform",
    "feature_slug": "predictive-analytics",
    "match_confidence": "high|medium|low|none",
    "proposition_exists": true,
    "solution_exists": false
  },
  "business_relevance": null,
  "business_relevance_calculated": null,
  "ranking_value": null
}
```

### Solution Process Improvement (SPI)

```json
{
  "spi_id": "spi-001",
  "name": "Establish data governance policy",
  "description": "Define data ownership, quality standards, and access controls for production sensor data",
  "st_ref": "st-001",
  "change_type": "governance|training|workflow|organization|measurement"
}
```

### Metric

```json
{
  "metric_id": "met-001",
  "name": "Defect rate reduction",
  "unit": "percentage",
  "direction": "increase|decrease",
  "linked_paths": ["path-001", "path-003"]
}
```

### Collateral

```json
{
  "collateral_id": "col-001",
  "name": "Predictive Maintenance ROI Case Study",
  "type": "case-study|whitepaper|reference-architecture|demo|benchmark",
  "st_ref": "st-001",
  "status": "exists|recommended"
}
```

### Enhanced F1: Solution Ranking

Per-path base: `PathScore(p) = avg(BR of scored TIPs in path p)`
Multi-path aggregation: `BR(ST) = 0.6 × max(PathScores) + 0.4 × avg(PathScores)`
Foundation adjustment: `FinalScore = BR(ST) × FoundationFactor`

FoundationFactor: 1.00 (0-1 deps), 0.95 (2-3 deps), 0.90 (4+ deps)
Business Relevance scale: 1 (Very Low) → 5 (Very High).

## Naming Conventions

| Convention | Rule | Example |
|---|---|---|
| Project slug | `{subsector}-{topic}-{hash}` | `automotive-ai-predictive-maintenance-abc12345` |
| Project directory | `cogni-tips/{project-slug}/` | `cogni-tips/automotive-ai-predictive-maintenance-abc12345/` |
| Candidate sequence | `{dimension}/{horizon}/{sequence}` | `externe-effekte/act/1` |
| Claim ID | `claim_{DIM_PREFIX}_{SEQ}` | `claim_EE_001` |
| Path ID | `path-{SEQ}` | `path-001` |
| Solution Template ID | `st-{SEQ}` | `st-001` |
| SPI ID | `spi-{SEQ}` | `spi-001` |
| Metric ID | `met-{SEQ}` | `met-001` |
| Collateral ID | `col-{SEQ}` | `col-001` |
