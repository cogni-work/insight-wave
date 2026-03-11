# Phase 5: Curate (Optional)

## Objective

Review the pursuit-specific value model and generate recommendations for promoting
reusable patterns back to the industry catalog. This implements the patent's curation
feedback loop (WO2018046399A1, Claim 3) where customer-specific pursuit data enriches
the base catalog over time.

## When to Run

This phase is optional and advisory. Trigger it when:
- The value model is complete (Phase 4 finished)
- The user asks about catalog improvements or reusable patterns
- Multiple projects in the same industry exist and cross-project learning is valuable

## Step 1: Identify Promotion Candidates

Scan the completed value model for patterns worth promoting to the industry catalog:

**High-value TIPS paths** — paths with BR >= 4.0 that represent recurring industry themes:
- Does this path reflect a broad industry trend or is it customer-specific?
- Would other customers in the same subsector benefit from this path?

**Proven Solution Templates** — STs ranked in Tier 1-2 that address common needs:
- Is this ST generalizable beyond the specific customer context?
- Does the ST fill a gap in the current industry catalog?

**Validated SPIs** — process improvements that consistently accompany high-value STs:
- Are these SPIs industry-standard or customer-specific?

**Effective Metrics** — KPIs that proved useful for measuring solution success:
- Are these metrics applicable across the industry subsector?

## Step 2: Generate Curation Recommendations

For each promotion candidate, generate a recommendation:

```json
{
  "recommendation_id": "cur-001",
  "entity_type": "path|solution_template|spi|metric",
  "entity_ref": "path-001",
  "action": "promote|merge|flag",
  "target_catalog": "manufacturing/automotive",
  "rationale": "High-BR path addressing a recurring industry need for predictive quality",
  "generalization_notes": "Remove customer-specific sensor references; generalize to 'production line sensors'",
  "confidence": "high|medium|low"
}
```

**Actions:**
- `promote` — add this entity to the industry catalog as a new entry
- `merge` — combine with an existing catalog entry to strengthen it
- `flag` — mark for human review before any catalog changes

**Guidelines:**
- Be conservative — only recommend promotion for clearly reusable patterns
- Always suggest generalization: strip customer names, specific product references
- Prefer `flag` over `promote` when unsure about generalizability
- Target 3-8 recommendations per project — quality over quantity

## Step 3: Present Curation Summary

Present recommendations to the user grouped by entity type:

```markdown
## Catalog Curation Recommendations

Based on this pursuit, the following patterns could enrich the {industry} catalog:

### Paths Worth Promoting (2)
- **path-001: AI-Driven Quality Optimization** — recurring theme across automotive
  Action: promote to manufacturing/automotive catalog
  Generalize: replace specific sensor brands with generic references

### Solution Templates Worth Promoting (1)
- **st-003: Compliance Automation Suite** — addresses EU AI Act across all manufacturing
  Action: promote to manufacturing (cross-subsector)

### Process Improvements Worth Sharing (1)
- **spi-002: Train quality engineers on ML interpretation** — standard enabler
  Action: merge with existing training recommendations

These are advisory recommendations. No catalog changes are made automatically.
```

## Step 4: Store Curation Data

This phase is advisory — it generates recommendations but does not modify any catalogs.

Update `tips-value-model.json`:
- Add `curation_recommendations` array with all recommendations

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"curated"`
- Add `"phase-5"` to `phases_completed`
- Record `curation_candidates_reviewed`, `curation_recommendations_count`

## Output

The curation output is informational. It serves as input for a future catalog management
workflow or manual review process. No industry catalogs are modified by this phase.
