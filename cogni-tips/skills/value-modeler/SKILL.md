---
name: value-modeler
description: >
  Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates.
  Use whenever the user mentions "value modeler", "solution mapping", "TIPS paths", "relationship networks",
  "solution templates", "big block", "solution diagram", "rank solutions", "business relevance scoring",
  "map trends to solutions", "what should we build", "which solutions matter", "prioritize solutions",
  or wants to go from trend insights to actionable, ranked solution recommendations.
  Also trigger when the user has completed a trend-scout project and asks "what's next" or "now what".
---

# Value Modeler

Transform agreed trend candidates into customer-specific, ranked solution recommendations by building
TIPS relationship networks and generating Solution Templates — the missing link between trend insight
and concrete action.

Based on the TIPS Value Modeler methodology (Siemens patent WO2018046399A1, freely usable).

## What This Skill Does

The trend-scout skill produces 52 agreed candidates across 4 dimensions. Each candidate lives in its
dimension as a standalone item. This skill connects them:

1. **Builds TIPS paths** — explicit Trend → Implication → Possibility chains across dimensions
2. **Generates Solution Templates** — concrete enablers linked to each path
3. **Generates SPIs** — operational process changes that accompany each Solution Template
4. **Defines success Metrics** — KPIs that measure value delivery per path
5. **Suggests Collaterals** — supporting content (case studies, reference architectures) per ST
6. **Enables Business Relevance scoring** — customer-specific 1-5 ratings per TIP
7. **Ranks solutions automatically** — using the F1 averaging formula from the patent
8. **Generates a Big Block diagram** — the customer-specific solution architecture
9. **Curates catalog feedback** — promotes pursuit-specific insights back to industry catalogs

The output is a ranked list of solutions the customer should pursue, backed by the trend evidence
from the scout phase and scored for business relevance.

## Prerequisites

- A completed trend-scout project with `workflow_state: "agreed"` in `.metadata/trend-scout-output.json`
- Optionally: a cogni-portfolio project (enables mapping Solution Templates to actual products/features)

## Language & Encoding

All output files use UTF-8 encoding. When the project language is German, use proper
umlauts (ä, ö, ü, ß) — never ASCII substitutes (ae, oe, ue, ss). This applies to all
generated markdown, JSON string values, and HTML content.

## Workflow

Read the phase reference file for each phase before executing it.

### Phase 0: Initialize
Reference: `references/workflow-phases/phase-0-load.md`

Load the trend-scout output, validate prerequisites, discover optional portfolio.

### Phase 1: Build Relationship Networks
Reference: `references/workflow-phases/phase-1-relationships.md`

Analyze the 52 candidates across all 4 dimensions and build TIPS paths — chains of
Trend → Implication → Possibility that form coherent narratives. Each path represents
a "value story" connecting an external force to strategic opportunity.

### Phase 2: Generate Solution Templates
Reference: `references/workflow-phases/phase-2-solutions.md`

For each relationship network, generate Solution Templates — concrete process improvement
enablers. If a cogni-portfolio project exists, map templates to existing products/features.

### Phase 3: Business Relevance Scoring
Reference: `references/workflow-phases/phase-3-scoring.md`

Present the TIPS paths and Solution Templates to the user for customer-specific
Business Relevance (BR) scoring on a 1-5 scale. Generate an interactive scoring UI.

### Phase 4: Rank & Visualize
Reference: `references/workflow-phases/phase-4-rank.md`

Apply the F1 formula to calculate solution rankings, generate the ranked solution list,
and produce the Big Block solution diagram.

### Phase 5: Curate (Optional)
Reference: `references/workflow-phases/phase-5-curate.md`

Review pursuit-specific data (paths, STs, SPIs, Metrics) and generate recommendations
for promoting high-value, reusable patterns back to the industry catalog. This creates
a learning loop where customer engagements improve the base catalog over time.

## Output Files

```
{project-dir}/
├── tips-value-model.json              # Complete value model (paths + solutions + scores)
├── tips-solution-ranking.md           # Human-readable ranked solution list
├── tips-big-block.md                  # Big Block solution diagram (markdown)
├── value-modeler-scoring.html         # Interactive BR scoring UI
└── .metadata/
    └── value-modeler-output.json      # Execution state + metadata
```

## Data Model

### TIPS Path (Relationship Network)

A path connects candidates across dimensions into a coherent value narrative:

```json
{
  "path_id": "path-001",
  "name": "AI-Driven Quality Optimization",
  "narrative": "Regulatory pressure on quality standards (T) drives need for real-time defect detection (I), enabling predictive quality management (P)",
  "trend": {
    "candidate_ref": "externe-effekte/act/1",
    "name": "EU Quality Standards Tightening",
    "business_relevance": null
  },
  "implication": {
    "candidate_ref": "digitale-wertetreiber/act/3",
    "name": "Real-time Defect Detection Gap",
    "business_relevance": null
  },
  "possibility": {
    "candidate_ref": "neue-horizonte/plan/2",
    "name": "Predictive Quality Management",
    "business_relevance": null
  },
  "solution_templates": ["st-001", "st-002"]
}
```

A single candidate may appear in multiple paths — the same Trend can drive different
Implications depending on context. The path captures the *reasoning chain*, not just grouping.

### Solution Template

```json
{
  "st_id": "st-001",
  "name": "Predictive Quality Analytics Platform",
  "description": "Deploy ML-based quality prediction integrated with production line sensors",
  "category": "software",
  "enabler_type": "process_improvement",
  "linked_paths": ["path-001", "path-003"],
  "portfolio_mapping": {
    "product_slug": "cloud-platform",
    "feature_slug": "predictive-analytics",
    "match_confidence": "high"
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
  "change_type": "governance"
}
```

`change_type` values: `governance` | `training` | `workflow` | `organization` | `measurement`

### Metric

```json
{
  "metric_id": "met-001",
  "name": "Defect rate reduction",
  "unit": "percentage",
  "direction": "decrease",
  "linked_paths": ["path-001", "path-003"]
}
```

`direction` values: `increase` | `decrease`

### Collateral

```json
{
  "collateral_id": "col-001",
  "name": "Predictive Maintenance ROI Case Study",
  "type": "case-study",
  "st_ref": "st-001",
  "status": "recommended"
}
```

`type` values: `case-study` | `whitepaper` | `reference-architecture` | `demo` | `benchmark`
`status` values: `exists` | `recommended`

`portfolio_mapping` is only populated when a cogni-portfolio project is discovered.
`business_relevance` is the user override (if set). `business_relevance_calculated` is
computed via formula F1.

### Business Relevance Scale

| Score | Meaning |
|-------|---------|
| 1 | Secondary process, very little impact on customer activities |
| 2 | May bring some limited value in individual business domains |
| 3 | Significant benefits in some customer activities, not cross-domain critical |
| 4 | Impacts multiple business areas, substantial benefits expected |
| 5 | Mission critical, possibility to massively impact company KPIs |

### Ranking Formula: Enhanced F1

The patent's original F1 is a simple average of Business Relevance scores across linked TIPs.
In practice, simple averaging flattens differentiation — a path with T=5,I=4,P=2 scores
the same as T=4,I=4,P=3. Cross-cutting solutions serving multiple paths get pulled toward
the mean instead of being rewarded for breadth.

The enhanced formula addresses this with two adjustments:

**Step 1: Per-path score (F1 base)**
```
PathScore(p) = (sum(BR_T_j) + sum(BR_I_n) + sum(BR_P_k)) / (j + n + k)
```

**Step 2: Peak-weighted aggregation across paths**
```
BR(ST_i) = 0.6 × max(PathScore) + 0.4 × avg(PathScore)
```

For single-path STs, this equals the original F1.
For multi-path STs, it rewards breadth while still anchoring on the strongest path.
The peak-weighting prevents cross-cutting solutions from being penalized by averaging
in weaker paths — the best path dominates, with breadth as a bonus.

**Step 3: Foundation readiness adjustment**
```
FinalScore(ST_i) = BR(ST_i) × FoundationFactor
```

Where `FoundationFactor`:
- 1.0 if 0-1 foundation dependencies
- 0.95 if 2-3 foundation dependencies
- 0.90 if 4+ foundation dependencies

This mild penalty surfaces implementation risk without dominating the ranking.
A solution with BR 4.0 and heavy prerequisites scores 3.60 — still high-priority,
but the risk is visible.

**Fields on each ST:**
- `path_scores`: array of per-path F1 scores
- `business_relevance_calculated`: result of Step 2
- `foundation_factor`: the readiness multiplier
- `ranking_value`: final score after Step 3 (or user override if set)
- `business_relevance`: user override (bypasses all calculation)

## Integration with cogni-portfolio

When a portfolio project is discovered in the workspace:

1. **Feature matching** — Solution Templates are mapped to existing features by semantic similarity
2. **Proposition linking** — If a feature+market proposition exists, the ST inherits its IS/DOES/MEANS messaging
3. **Solution enrichment** — If a portfolio solution exists, the ST inherits implementation phases and pricing
4. **Gap identification** — STs that don't map to any existing feature represent portfolio gaps worth exploring

This creates a bidirectional bridge: trends inform which features matter most, and existing
portfolio data enriches the solution templates with real commercial context.
