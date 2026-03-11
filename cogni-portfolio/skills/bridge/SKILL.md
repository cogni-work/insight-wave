---
name: bridge
description: >
  Bidirectional integration between cogni-tips TIPS analysis and cogni-portfolio product portfolio.
  Use whenever the user mentions "bridge", "connect tips to portfolio", "import from tips",
  "tips to portfolio", "portfolio to tips", "sync portfolio with tips", "convert solutions to features",
  "map trends to products", "enrich propositions from trends", "what did tips find for my portfolio",
  or wants to flow data between a TIPS value model and a portfolio project. Also trigger when the
  user has completed value-modeler ranking and asks "how does this connect to my portfolio" or
  "what features should I add based on the trends".
---

# TIPS-Portfolio Bridge

Bidirectional flow between cogni-tips trend analysis and cogni-portfolio product messaging.
This is the operational link between the "Value/Sales" side (TIPS) and the "Services/Best Practices"
side (Portfolio) — connecting trend-driven insights to concrete product positioning and go-to-market.

## Why This Matters

Without the bridge, TIPS and Portfolio are two separate worlds:
- TIPS identifies what matters (trends, implications, ranked solutions) but doesn't touch products
- Portfolio structures what you sell (features, propositions, pricing) but doesn't know why it matters

The bridge connects them: trends inform which features to prioritize, ranked solutions become
new features or enrich existing ones, and portfolio constraints guide solution generation.

## Prerequisites

- A cogni-tips project with a completed value model (`tips-value-model.json`)
- A cogni-portfolio project with at least `portfolio.json` and some products/features

Both must be discoverable in the workspace.

## Operations

### tips-to-portfolio — Flow TIPS Insights into Portfolio

```
/bridge tips-to-portfolio
```

Takes ranked Solution Templates from the value model and creates or enriches portfolio entities.

**Step 1: Discover Projects**

1. Find the TIPS project (same discovery as value-modeler Phase 0)
2. Find the portfolio project (look for `portfolio/portfolio.json` or `*/portfolio.json`)
3. Load `tips-value-model.json` — needs `solution_templates` with ranking values
4. Load portfolio products, features, and existing propositions

**Step 2: Match Solution Templates to Features**

For each Solution Template in the value model:

1. Check `portfolio_mapping` — if already mapped during value-modeler Phase 2, use it
2. If not mapped, attempt semantic matching:
   - Compare ST name + description against all feature names + descriptions
   - Consider product category alignment
   - Assign match confidence: `high` (clear semantic overlap), `medium` (partial),
     `low` (weak signal), `none` (no match)

Present the mapping table to the user:

```
| Solution Template | Rank | Matched Feature | Confidence | Action |
|-------------------|------|-----------------|------------|--------|
| Predictive Quality Analytics | 4.2 | predictive-analytics | high | Enrich |
| Compliance Automation Suite | 3.8 | — | none | Create |
| Digital Twin Platform | 3.5 | simulation-engine | medium | Review |
```

**Actions:**
- **Enrich** — ST maps to existing feature; enrich its propositions with TIPS context
- **Create** — No matching feature; generate a new feature stub from the ST
- **Review** — Uncertain match; ask user to confirm or reject
- **Skip** — User decides this ST doesn't belong in the portfolio

**Step 3: Create New Features (for "Create" actions)**

For each unmapped ST the user approves, generate a feature stub:

```json
{
  "slug": "{derived-from-st-name}",
  "product_slug": "{user-selected-product}",
  "name": "{ST name}",
  "description": "{ST description, adapted to feature language}",
  "category": "{derived from ST category}",
  "readiness": "planned",
  "tips_ref": "{pursuit-slug}#st-{id}",
  "created": "{today}"
}
```

The `tips_ref` field is a cross-reference back to the source ST. It is not part of the
standard portfolio schema — it is added as metadata for traceability. Portfolio skills
that don't understand it will ignore it.

Ask the user which product each new feature belongs to.

**Step 4: Enrich Propositions (for "Enrich" actions)**

For features that already have propositions, offer to enrich the DOES and MEANS statements
with TIPS context:

- **DOES enrichment:** The TIPS path narrative provides trend-driven advantage framing.
  Example: "Reduces defect rate by 40%" → "Addresses EU quality regulation pressure by
  reducing defect rate by 40% through AI-driven prediction"
- **MEANS enrichment:** The BR scoring context provides business outcome framing.
  Example: "Protects production quality" → "Protects production quality in an environment
  where regulatory non-compliance carries 2-4% revenue risk"

Present before/after for user approval. Never overwrite without confirmation.

**Step 5: Map TIPS Metrics to Evidence**

For each TIPS Metric linked to matched paths, suggest portfolio evidence entries:

```json
{
  "statement": "{metric name}: {typical target from catalog or pursuit}",
  "source_url": null,
  "source_title": "TIPS Value Model — {pursuit name}"
}
```

These become candidate evidence entries on the relevant proposition. Mark them as
unverified — the user can later run `/verify` to check sourced claims.

**Step 6: Summary**

Report what was created/enriched:
- N new features created
- N propositions enriched
- N evidence entries suggested
- List any high-ranked STs that were skipped (portfolio gaps worth revisiting)

### portfolio-to-tips — Load Portfolio as TIPS Constraints

```
/bridge portfolio-to-tips
```

Loads the portfolio's products and features into the TIPS value model context so that
Phase 2 (Solution Template generation) is constrained by what you actually sell.

**This operation is informational** — it writes a `portfolio-context.json` file into the
TIPS project directory that value-modeler Phase 2 can read.

**Step 1: Discover Projects**

Same discovery as `tips-to-portfolio`.

**Step 2: Extract Portfolio Context**

Read all products and features and create a compact context file:

```json
{
  "source": "cogni-portfolio",
  "portfolio_slug": "{portfolio-slug}",
  "extracted_at": "{timestamp}",
  "products": [
    {
      "slug": "cloud-platform",
      "name": "Cloud Platform",
      "revenue_model": "subscription",
      "features": [
        {
          "slug": "cloud-monitoring",
          "name": "Cloud Infrastructure Monitoring",
          "description": "Real-time monitoring...",
          "category": "observability",
          "readiness": "ga"
        }
      ]
    }
  ],
  "markets": [
    {
      "slug": "mid-market-saas-dach",
      "name": "Mid-Market SaaS (DACH)",
      "region": "dach",
      "priority": "beachhead"
    }
  ]
}
```

Write to `{tips-project-dir}/portfolio-context.json`.

**Step 3: Advise Value Modeler**

Tell the user: "Portfolio context saved. When you run value-modeler Phase 2, it will use
this to map Solution Templates to your existing products and features, and flag solutions
that don't match your current portfolio as potential expansion opportunities."

### sync — Reconcile Both Directions

```
/bridge sync
```

Runs both `portfolio-to-tips` and `tips-to-portfolio` in sequence, presenting a unified
reconciliation view:

1. Load portfolio context into TIPS project
2. Match all STs against features
3. Present the full mapping with gaps in both directions:
   - TIPS solutions with no portfolio match (innovation opportunities)
   - Portfolio features with no TIPS relevance signal (validate market need)
4. Generate an action plan

## Cross-Reference Convention

Cross-references between plugins use a simple `{pursuit-or-project-slug}#{entity-id}` format:

```
# In portfolio feature.json
"tips_ref": "automotive-ai-predictive-maintenance-abc12345#st-001"

# In TIPS value model
"portfolio_mapping": {
  "product_slug": "cloud-platform",
  "feature_slug": "predictive-analytics",
  "match_confidence": "high"
}
```

These are metadata fields. Each plugin ignores fields it doesn't understand.
No shared database, no tight coupling — just slug-based references resolved at runtime.

## Language

Use the portfolio project's language for all generated content (features, propositions,
evidence). Use the TIPS project's language when reading TIPS data. If they differ,
translate ST descriptions to the portfolio language when creating features.
