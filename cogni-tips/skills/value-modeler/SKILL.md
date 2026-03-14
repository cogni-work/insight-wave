---
name: value-modeler
description: >
  Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates.
  Use whenever the user mentions "value modeler", "solution mapping", "TIPS paths", "relationship networks",
  "solution templates", "big block", "solution diagram", "rank solutions", "business relevance scoring",
  "map trends to solutions", "what should we build", "which solutions matter", "prioritize solutions",
  "re-anchor solutions", "remap blueprints", "rebuild portfolio mapping", "re-anchor STs",
  or wants to go from trend insights to actionable, ranked solution recommendations.
  Also trigger when the user has completed a trend-scout project and asks "what's next" or "now what".
---

# Value Modeler

Transform agreed trend candidates into customer-specific, ranked solution recommendations by building
TIPS relationship networks and generating Solution Templates — the missing link between trend insight
and concrete action.

Based on the TIPS Value Modeler methodology (Siemens patent WO2018046399A1, freely usable).

## What This Skill Does

The trend-scout skill produces 60 agreed candidates across 4 dimensions. Each candidate lives in its
dimension as a standalone item. This skill connects them:

1. **Builds TIPS value chains** — explicit Trend → Implication → Possibility causal chains across dimensions
2. **Consolidates into Strategic Themes** — clusters value chains into 3-7 MECE investment domains
3. **Generates Solution Templates with Blueprints** — concrete enablers per theme with multi-dimensional portfolio composition (natural deduplication)
4. **Generates SPIs** — operational process changes that accompany each Solution Template
5. **Defines success Metrics** — KPIs that measure value delivery per theme
6. **Suggests Collaterals** — supporting content (case studies, reference architectures) per ST
7. **Enables Business Relevance scoring** — customer-specific 1-5 ratings per TIP
8. **Ranks solutions automatically** — using the F1 averaging formula from the patent
9. **Generates a Big Block diagram** — the customer-specific solution architecture organized by theme
10. **Curates catalog feedback** — promotes pursuit-specific insights back to industry catalogs

The output is a structured strategy with 3-7 strategic themes, each containing ranked solutions
backed by trend evidence and scored for business relevance. This gives the customer a CxO-ready
investment portfolio — not a flat list of 18 solutions, but 5 distinct areas to fund and champion.

## Prerequisites

- A completed trend-scout project with `workflow_state: "agreed"` in `.metadata/trend-scout-output.json`
- **Recommended:** If a cogni-portfolio project exists in the workspace, run `/bridge portfolio-to-tips`
  before starting value-modeler. This exports your product features, propositions, and pricing so Phase 2
  generates Solution Templates grounded in your actual products. Without it, solutions will be abstract
  and require manual portfolio mapping later. If trend-scout was linked to a portfolio market, this skill
  automatically picks up that connection — no need to re-discover.

## Language Support

This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

**Interaction language:** Read workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD) at startup. Use this for all user-facing messages — scoring prompts, progress updates, phase summaries, AskUserQuestion prompts, and next-step recommendations.

**Output language:** Inherited from `project_language` in `trend-scout-output.json`. Value-modeler does not re-ask — it is a downstream skill that respects the project language set during trend-scout.

All output files use UTF-8 encoding. When the project language is German, use proper
umlauts (ä, ö, ü, ß) — never ASCII substitutes (ae, oe, ue, ss). This applies to all
generated markdown, JSON string values, and HTML content.

## Workflow

Read the phase reference file for each phase before executing it.

### Phase 0: Initialize
Reference: `references/workflow-phases/phase-0-load.md`

Load the trend-scout output, validate prerequisites, discover optional portfolio.

### Phase 1: Build Relationship Networks & Strategic Themes
Reference: `references/workflow-phases/phase-1-relationships.md`

Two-pass architecture: First, build granular T→I→P value chains via semantic affinity
analysis (bottom-up). Then consolidate chains into 3-7 MECE Strategic Themes — the
distinct investment domains where this customer should allocate budget and executive
attention (top-down). Each theme groups 1-4 value chains and represents a CxO-level
strategic decision.

### Phase 2: Generate Solution Templates
Reference: `references/workflow-phases/phase-2-solutions.md`

For each Strategic Theme, generate Solution Templates — concrete process improvement
enablers. Working at the theme level naturally deduplicates STs that would otherwise
appear redundantly across overlapping chains. Target 2-4 STs per theme.
If a cogni-portfolio project exists, map templates to existing products/features.
When portfolio context v2.0+ is available, Phase 2 starts with **portfolio-anchored
generation** (Step 0.5): features from the portfolio are matched to themes and used as
delivery anchors for STs with automatic high-confidence mapping. Each ST gets a **solution
blueprint** — a multi-dimensional composition of building blocks mapped to B2B ICT taxonomy
categories (connectivity, security, cloud, applications, consulting, etc.) that captures
the full solutioning expertise: what portfolio is needed to BUILD and DELIVER the solution,
not just which single feature matches. Blueprint readiness scores (0.0-1.0) surface portfolio
gaps and feed into the ranking formula.
Quality-aware generation (v3.0) flags STs where underlying propositions need improvement.
**Re-anchoring** (Step 2.7): When portfolio context changes or initial mappings need revision,
re-anchor rebuilds each ST's solution blueprint from scratch using LLM solutioning intelligence —
re-analyzing which taxonomy categories are needed and re-matching against the current portfolio.
This is intellectual solutioning work, not mechanical keyword matching. Can be invoked
independently (outside a full Phase 2 run) via "re-anchor solutions". See
`references/workflow-phases/phase-2-solutions.md` Step 2.7.

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
├── tips-value-model.json              # Complete value model (themes + chains + solutions + scores)
├── tips-solution-ranking.md           # Human-readable ranked solution list by theme
├── tips-big-block.md                  # Big Block solution diagram organized by theme
├── value-modeler-scoring.html         # Interactive BR scoring UI grouped by theme
└── .metadata/
    └── value-modeler-output.json      # Execution state + metadata
```

## Data Model

### Strategic Theme

A theme groups 1-4 value chains into a distinct investment domain. Themes are the primary
organizing unit of the value model — they represent CxO-level decisions about where to invest.

```json
{
  "theme_id": "theme-001",
  "name": "Health & Nutrition Transformation",
  "strategic_question": "How do we reformulate our portfolio for the health-conscious, GLP-1-era consumer?",
  "executive_sponsor_type": "CPO / Head of Product Development",
  "narrative": "GLP-1 medications and functional food demand are fundamentally reshaping what consumers want. This theme covers reformulation, personalization, and nutritional innovation.",
  "value_chains": ["vc-001", "vc-002"],
  "solution_templates": ["st-001", "st-002", "st-003"],
  "business_relevance_avg": null,
  "ranking_value": null
}
```

Themes must satisfy MECE:
- **Mutually Exclusive**: Each theme answers a different strategic question. Different executive sponsor, different budget line.
- **Collectively Exhaustive**: Together, themes cover ≥80% of linked candidates.

Target: **5 themes** (ideal). Range: 3 (minimum) to 7 (maximum, Miller's law).

**Theme-level Business Relevance** is the average `ranking_value` of the theme's Solution
Templates (calculated after Phase 4). This represents the theme's overall importance to
the customer as expressed through its solutions' scores. Use this for theme ranking.

### Value Chain (TIPS Path)

A value chain connects candidates across dimensions into a coherent causal narrative.
Value chains are nested under their parent Strategic Theme.

```json
{
  "chain_id": "vc-001",
  "name": "GLP-1 Portfolio Reformulation",
  "theme_ref": "theme-001",
  "narrative": "GLP-1 medications reshape consumption (T), requiring AI-driven personalization (I), enabling health-optimized portfolio reformulation (P)",
  "trend": {
    "candidate_ref": "externe-effekte/act/1",
    "name": "GLP-1 Market Impact",
    "business_relevance": null
  },
  "implications": [
    {
      "candidate_ref": "digitale-wertetreiber/act/29",
      "name": "Personalized Digital Experiences",
      "business_relevance": null
    }
  ],
  "possibilities": [
    {
      "candidate_ref": "neue-horizonte/act/14",
      "name": "GLP-1 Portfolio Reformulation",
      "business_relevance": null
    }
  ],
  "foundation_requirements": [
    {
      "candidate_ref": "digitales-fundament/act/41",
      "name": "AI/ML Engineer Demand",
      "relationship": "prerequisite"
    }
  ],
  "solution_templates": ["st-001", "st-002"]
}
```

A single candidate may appear in multiple chains — the same Trend can drive different
Implications depending on context. The chain captures the *reasoning*, not just grouping.

### Solution Template

```json
{
  "st_id": "st-001",
  "name": "Predictive Quality Analytics Platform",
  "description": "Deploy ML-based quality prediction integrated with production line sensors",
  "category": "software",
  "enabler_type": "process_improvement",
  "generation_mode": "portfolio-anchored",
  "theme_ref": "theme-003",
  "linked_chains": ["vc-005", "vc-006"],
  "solution_blueprint": {
    "building_blocks": [
      { "role": "lead", "capability": "Predictive analytics engine", "taxonomy_ref": "6.6", "taxonomy_name": "AI, Data & Analytics", "taxonomy_dimension": 6, "coverage": "covered", "feature_slug": "predictive-analytics", "product_slug": "cloud-platform", "delivers": ["ML model training", "anomaly detection"], "gaps": ["edge inference"] },
      { "role": "supporting", "capability": "IoT sensor connectivity", "taxonomy_ref": "1.4", "taxonomy_name": "5G & IoT Connectivity", "taxonomy_dimension": 1, "coverage": "partial", "feature_slug": "iot-gateway", "product_slug": "connectivity-suite", "delivers": ["sensor data collection"], "gaps": ["private 5G"] },
      { "role": "enabling", "capability": "Implementation consulting", "taxonomy_ref": "7.2", "taxonomy_name": "Digital Transformation", "taxonomy_dimension": 7, "coverage": "gap", "feature_slug": null, "product_slug": null, "delivers": [], "gaps": ["domain consulting"] }
    ],
    "readiness": { "covered_count": 1, "partial_count": 1, "gap_count": 1, "unknown_count": 0, "readiness_score": 0.64, "taxonomy_span": [1, 6, 7], "taxonomy_depth": 3 }
  },
  "portfolio_mapping": {
    "product_slug": "cloud-platform",
    "feature_slug": "predictive-analytics",
    "match_confidence": "high"
  },
  "portfolio_anchor": {
    "feature_slug": "predictive-analytics",
    "product_slug": "cloud-platform",
    "theme_needs_delivered": ["ML model training", "anomaly detection"],
    "theme_needs_undelivered": ["edge inference"]
  },
  "quality_flag": null,
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
  "theme_ref": "theme-003",
  "linked_chains": ["vc-005", "vc-006"]
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
`generation_mode`: `"portfolio-anchored"` when generated from Step 0.5 (feature-first),
`"abstract"` when generated from Step 1 (theme-first). Defaults to `"abstract"`.
`solution_blueprint` captures the multi-dimensional portfolio composition needed to deliver
this ST — building blocks mapped to B2B ICT taxonomy categories with coverage assessment.
Every ST gets a blueprint (both anchored and abstract). See `references/data-model.md` for
the full SolutionBlueprint and BuildingBlock schemas.
`portfolio_anchor` is derived from the blueprint's lead building block for backward
compatibility. It records the primary feature and what it can/cannot deliver.
`quality_flag`: `"quality_investment_needed"` when v3.0 quality assessment shows a fail
on `market_specificity` or `differentiation` for a matched proposition. `null` otherwise.
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
In practice, simple averaging flattens differentiation — a chain with T=5,I=4,P=2 scores
the same as T=4,I=4,P=3. Cross-cutting solutions serving multiple chains get pulled toward
the mean instead of being rewarded for breadth.

The enhanced formula addresses this with two adjustments:

**Step 1: Per-chain score (F1 base)**
```
ChainScore(c) = (sum(BR_T_j) + sum(BR_I_n) + sum(BR_P_k)) / (j + n + k)
```

**Step 2: Peak-weighted aggregation across chains**
```
BR(ST_i) = 0.6 × max(ChainScore) + 0.4 × avg(ChainScore)
```

For single-chain STs, this equals the original F1.
For multi-chain STs, it rewards breadth while still anchoring on the strongest chain.
The peak-weighting prevents cross-cutting solutions from being penalized by averaging
in weaker chains — the best chain dominates, with breadth as a bonus.

**Step 3: Foundation and blueprint readiness adjustment**
```
FinalScore(ST_i) = BR(ST_i) × FoundationFactor × BlueprintFactor
```

Where `FoundationFactor`:
- 1.0 if 0-1 foundation dependencies
- 0.95 if 2-3 foundation dependencies
- 0.90 if 4+ foundation dependencies

Where `BlueprintFactor` (from `solution_blueprint.readiness.readiness_score`):
- 1.00 if readiness >= 0.8 (well-covered portfolio)
- 0.95 if readiness >= 0.5 (partial coverage)
- 0.90 if readiness >= 0.3 (significant gaps)
- 0.85 if readiness < 0.3 (mostly gaps)
- 1.00 if no blueprint (no penalty for legacy STs)

These mild penalties surface two distinct risk dimensions without dominating the ranking:
- **FoundationFactor**: prerequisite complexity (how much must be in place first)
- **BlueprintFactor**: portfolio readiness (can you deliver this with your current portfolio?)

A solution with BR 4.0, moderate dependencies, and partial portfolio coverage scores
4.0 × 0.95 × 0.95 = 3.61 — still high-priority, but both risks are visible.

**Fields on each ST:**
- `chain_scores`: array of per-chain F1 scores
- `business_relevance_calculated`: result of Step 2
- `foundation_factor`: the foundation readiness multiplier
- `blueprint_factor`: the portfolio readiness multiplier
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
