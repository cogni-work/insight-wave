---
name: tips-bridge
description: >
  Bidirectional integration between cogni-tips TIPS analysis and cogni-portfolio product portfolio.
  Use whenever the user mentions "bridge", "connect tips to portfolio", "import from tips",
  "tips to portfolio", "portfolio to tips", "sync portfolio with tips", "convert solutions to features",
  "map trends to products", "enrich propositions from trends", "what did tips find for my portfolio",
  or wants to flow data between a TIPS value model and a portfolio project. Also trigger when the
  user has completed value-modeler ranking and asks "how does this connect to my portfolio" or
  "what features should I add based on the trends". Trigger on "bridge status", "is my portfolio
  ready for tips", "check bridge readiness", or "can I bridge yet" for the pre-flight check.
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

## Prerequisites & Validation

Every bridge operation runs a pre-flight check before doing any work. This catches
data gaps and industry mismatches early — before wasting time on exports or imports
that will produce poor results.

### Shared Pre-flight (all operations)

1. **Discover projects** — Find the TIPS project (`*/tips-project.json`) and the
   portfolio project (`*/portfolio.json`). If either is missing, stop and report
   which one with a fix suggestion.
2. **Industry alignment** — Compare TIPS and portfolio industries (see below).
   The result is stored for use during market-relevance matching and reported
   in the summary.

### Industry Alignment

The TIPS project targets a specific industry (e.g., manufacturing/automotive) while
the portfolio describes what you sell. Bridging across unrelated industries is unusual
and likely a mistake — but sometimes intentional (e.g., cross-selling into a new vertical).

**How it works:**

1. Read TIPS `industry.primary` and `industry.subsector` from `tips-project.json`
2. Read portfolio `company.industry` from `portfolio.json` (free text)
3. Collect all `segmentation.vertical_codes` from `portfolio/markets/*.json`
4. Slugify `company.industry` (lowercase, replace non-alphanumeric with hyphens)

Match using a 4-tier heuristic:

- **exact** — Slugified `company.industry` matches `industry.primary` or
  `industry.subsector`. Example: company.industry "Automotive OEM" → slug
  "automotive-oem" contains "automotive" matching subsector. Proceed silently.
- **vertical** — Any market `vertical_code` matches `industry.subsector`.
  Example: market has `vertical_codes: ["automotive"]`, TIPS subsector is
  "automotive". Proceed silently.
- **broad** — Any market `vertical_code` is a known subsector of `industry.primary`
  (use the same parent-child logic as market-relevance matching). Example: market
  has `vertical_codes: ["autonomous-vehicles"]`, TIPS primary is "manufacturing".
  Proceed with note: "Portfolio markets have related verticals ({codes}) but no
  direct match to TIPS subsector '{subsector}'. Bridge results may need manual review."
- **none** — No match found. Warn and require explicit user confirmation:
  "Industry mismatch: TIPS analyzes {primary_en}/{subsector_en} but portfolio
  company.industry is '{company.industry}' with market verticals [{codes}].
  Cross-industry bridging is unusual — continue anyway?"

### portfolio-to-tips Validation Gates

Run these after shared pre-flight when executing `portfolio-to-tips` or `sync`.

**Hard gates (block execution):**
- `portfolio.json` must exist and be valid JSON
- At least 1 product in `portfolio/products/`
- At least 1 feature in `portfolio/features/` with a valid `product_slug` reference

If any hard gate fails, stop and report the fix:
- "No products found. Create at least one product first: `/portfolio-setup`"
- "No features found. Add features to your products: `/features create`"

**Soft warnings (report and continue):**
- No propositions: "No propositions found. The exported context will lack
  IS/DOES/MEANS messaging — value-modeler Phase 2 will generate STs without
  portfolio grounding. Consider running `/propositions create` first."
- No markets: "No markets defined. The context file will have no market-relevance
  tagging. Define markets with `/portfolio-setup`."
- Features with descriptions under 15 words: "{N} features have thin descriptions
  (under 15 words). Richer descriptions improve ST-to-feature matching accuracy.
  Consider running `/features enrich` first."
- No solutions: "No solutions found. The exported context will lack pricing and
  delivery data."

### tips-to-portfolio Validation Gates

Run these after shared pre-flight when executing `tips-to-portfolio` or `sync`.

**Hard gates (block execution):**
- `tips-value-model.json` must exist in the TIPS project directory
- `solution_templates` array must be non-empty
- At least 1 ST must have `ranking_value` populated (not null) — confirms that
  value-modeler Phase 4 (ranking) has completed

If any hard gate fails, stop and report the fix:
- "Value model not found. Run the value modeler first: `/value-model`"
- "No solution templates in value model. Complete value-modeler Phase 2:
  `/value-model solutions`"
- "Solution templates have no ranking values. Complete Phase 4 to calculate
  rankings: `/value-model rank`"

**Soft warnings (report and continue):**
- No features in portfolio: "Portfolio has no features. All Solution Templates
  will produce 'Create' actions (no enrichment possible). Consider adding features
  first with `/features create`."
- No propositions: "Portfolio has features but no propositions. Enrichment will
  create new propositions rather than refining existing ones."
- All STs have `business_relevance` = null: "No user-scored business relevance
  found. Rankings use formula-only scores. Consider running `/value-model score`
  for customer-specific prioritization."

## Operations

### status — Check Bridge Readiness

```
/bridge status
```

Quick readiness check without running any operations. Use this to see whether
your data is ready before committing to a full bridge run.

**Step 1: Discover & Validate**

Run the shared pre-flight (project discovery + industry alignment). Report
results but do not block on warnings — status is purely informational.

**Step 2: Portfolio Readiness**

Count portfolio entities and report:

```
Portfolio: {slug}
  Products:     {N}  ✓ (or ✗ if 0)
  Features:     {N}  ✓ (or ✗ if 0)
  Propositions: {N}  ✓ (or — if 0)
  Markets:      {N}  ✓ (or — if 0)
  Solutions:    {N}  (info only)
```

Where ✓ = meets hard gate, ✗ = fails hard gate, — = soft warning.

**Step 3: TIPS Readiness**

```
TIPS: {pursuit-slug}
  Industry:           {primary_en} / {subsector_en}
  Value Model:        {exists/missing}  ✓/✗
  Solution Templates: {N}               ✓/✗
  Ranked STs:         {N} / {total}     ✓/✗
  Portfolio Context:  {v2.0 from DATE / v1.0 / missing}
```

**Step 4: Industry Alignment**

```
Industry Alignment: {EXACT / VERTICAL / BROAD / NONE}
  TIPS:      {primary_en} / {subsector_en}
  Portfolio: {company.industry}
  Verticals: [{vertical_codes joined}]
```

**Step 5: Readiness Verdict**

```
Bridge Readiness:
  portfolio-to-tips: {READY / NOT READY: reason}
  tips-to-portfolio: {READY / NOT READY: reason}
  sync:              {READY / NOT READY: reason}
```

If NOT READY, list fix actions:
- "Add at least 1 feature to a product: `/features create`"
- "Complete value-modeler ranking: `/value-model rank`"
- "Resolve industry mismatch: update portfolio.json company.industry or confirm
  cross-industry intent"

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

**Step 1b: Validate Readiness**

Run the shared pre-flight (industry alignment) and tips-to-portfolio validation
gates. If any hard gate fails — missing value model, empty solution templates,
or no ranked STs — stop and report the fix suggestion. If soft warnings exist
(no features, no propositions, no BR scores), report them and continue.

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
  "source_title": "TIPS Value Model — {pursuit name}",
  "tips_context": "Driven by {trend name}; validated through {metric} across {industry} pursuits"
}
```

The `tips_context` field provides provenance — it captures which trend drove the metric
and what industry validation supports it. This helps portfolio users understand the
evidence's origin without needing to open the TIPS project.

These become candidate evidence entries on the relevant proposition. Mark them as
unverified — the user can later run `/portfolio-verify` to check sourced claims.

**Step 5.5: Propose Solution Stubs**

When an ST maps to a feature that has a proposition but **no solution** for the target
market, propose creating a solution stub:

1. Derive `solution_type` from the product's `revenue_model`:
   - `subscription` → `managed_service`
   - `license` → `project`
   - `service` → `project`
   - `hybrid` → ask the user
2. Suggest implementation phases based on the ST description and its SPIs:
   - Phase 1: Proof of Value (from ST scope)
   - Phase 2-N: Derived from SPI change types (governance, training, workflow)
3. Present as a table for user approval — **never auto-create**:

```
| Feature | Market | Proposed Type | Phases | Source ST | Action |
|---------|--------|---------------|--------|----------|--------|
| predictive-analytics | mid-market-dach | managed_service | 3 | st-001 | Create? |
| compliance-engine | enterprise-eu | project | 2 | st-004 | Create? |
```

Only create solution stubs after explicit user approval for each row.

**Step 5.7: Add Provenance Tracking**

For all propositions enriched in Step 4 and evidence added in Step 5, attach
`tips_enrichment` metadata:

```json
{
  "tips_enrichment": {
    "pursuit_slug": "{tips-pursuit-slug}",
    "enriched_at": "{ISO-8601 timestamp}",
    "st_refs": ["st-001"],
    "enrichment_type": ["does_refined", "evidence_added"]
  }
}
```

Valid `enrichment_type` values:
- `does_refined` — DOES statement was enriched with trend-driven advantage framing
- `means_refined` — MEANS statement was enriched with business outcome context
- `evidence_added` — New evidence entries were suggested from TIPS metrics
- `solution_proposed` — A solution stub was proposed (from Step 5.5)

This metadata is appended to the proposition JSON. Portfolio skills that don't understand
it will ignore it. It enables future auditing of which TIPS pursuit influenced which
portfolio positioning.

**Step 6: Summary**

Report what was created/enriched:
- N new features created
- N propositions enriched (with enrichment type breakdown)
- N evidence entries suggested (with tips_context provenance)
- N solution stubs proposed
- List any high-ranked STs that were skipped (portfolio gaps worth revisiting)

### portfolio-to-tips — Load Portfolio as TIPS Constraints

```
/bridge portfolio-to-tips
```

Loads the portfolio's products, features, propositions, and solutions into the TIPS value
model context so that Phase 2 (Solution Template generation) is grounded in what you
actually sell and how you position it per market.

**This operation is informational** — it writes a `portfolio-context.json` (v2.0) file into
the TIPS project directory that value-modeler Phase 2 can read. The enriched context gives
Phase 2 access to proposition language (IS/DOES/MEANS) and solution summaries so that
Solution Templates are grounded in real portfolio capabilities.

**Step 1: Discover Projects**

Same discovery as `tips-to-portfolio`.

**Step 1b: Validate Readiness**

Run the shared pre-flight (industry alignment) and portfolio-to-tips validation
gates. If any hard gate fails — no products or no features — stop and report
the fix suggestion. If soft warnings exist (no propositions, no markets, thin
descriptions, no solutions), report them and continue.

**Step 2: Extract Products & Features**

Read all products from `portfolio/products/*.json` and features from
`portfolio/features/*.json`. Build the product → feature hierarchy.

**Step 2.5: Enrich Features with Propositions & Solutions**

For each feature, check for matching proposition and solution files:

1. Read all `portfolio/propositions/{feature-slug}--{market-slug}.json` files
2. Read all `portfolio/solutions/{feature-slug}--{market-slug}.json` files
3. Compact each proposition into: `is_statement`, `does_statement`, `means_statement`,
   and `evidence_count` (number of evidence entries — avoids bloating the context file)
4. Compact each solution into: `solution_type`, `pricing_tiers` (tier names only),
   and `price_range` (min, max, currency)
5. Nest the compacted propositions under their parent feature

**Market-Relevance Matching:**

If TIPS project context is available (from `tips-project.json`), match each portfolio
market against the TIPS industry context using a 3-tier heuristic:

- **direct**: Portfolio market's `vertical_codes` contains a value matching the TIPS
  `industry.subsector` (e.g., both say "automotive")
- **industry**: Portfolio market's `vertical_codes` are a subsector of the TIPS
  `industry.primary` (e.g., market says "autonomous-vehicles", TIPS says "automotive")
- **none**: No meaningful relationship between market and TIPS industry

Assign `market_relevance` and `match_reason` to each market entry in the context file.

**Step 3: Build Context File**

Assemble `portfolio-context.json` v2.0:

```json
{
  "schema_version": "2.0",
  "source": "cogni-portfolio",
  "portfolio_slug": "{portfolio-slug}",
  "extracted_at": "{ISO-8601 timestamp}",
  "products": [
    {
      "slug": "cloud-platform",
      "name": "Cloud Platform",
      "revenue_model": "subscription",
      "maturity": "growth",
      "features": [
        {
          "slug": "cloud-monitoring",
          "name": "Cloud Infrastructure Monitoring",
          "description": "Real-time monitoring...",
          "category": "observability",
          "readiness": "ga",
          "propositions": [
            {
              "market_slug": "mid-market-saas-dach",
              "is_statement": "Cloud monitoring for SaaS operations teams",
              "does_statement": "Reduces MTTR by 60% through AI-correlated alerting",
              "means_statement": "Protects SaaS uptime SLAs in a market where churn from downtime costs 5-8% ARR",
              "evidence_count": 3,
              "solution_summary": {
                "solution_type": "project",
                "pricing_tiers": ["proof_of_value", "small", "medium", "large"],
                "price_range": { "min": 15000, "max": 250000, "currency": "EUR" }
              }
            }
          ]
        }
      ]
    }
  ],
  "markets": [
    {
      "slug": "mid-market-saas-dach",
      "name": "Mid-Market SaaS (DACH)",
      "region": "dach",
      "priority": "beachhead",
      "segmentation_summary": "SaaS companies, 50-500 employees",
      "vertical_codes": ["saas"],
      "tam_value": 5000000000,
      "currency": "EUR",
      "market_relevance": "direct",
      "match_reason": "vertical_codes includes 'saas' matching TIPS subsector"
    }
  ]
}
```

Write to `{tips-project-dir}/portfolio-context.json`.

**Backward compatibility:** The `schema_version` field distinguishes v2.0 from earlier
exports. Phase 2 checks this field and falls back to basic feature matching when v1.0
(no `schema_version` field) is encountered.

**Step 4: Advise Value Modeler**

Report a summary to the user:
- N products, M features, P propositions across K markets (R with direct/industry relevance)
- Any features without propositions (messaging gaps)
- Any markets with no TIPS relevance (may not contribute to ST generation)

**Industry alignment summary** — aggregate the per-market relevance tags:
- If any market is `direct`: "Industry alignment: strong ({N} markets with direct
  TIPS match)"
- If any market is `industry` but none `direct`: "Industry alignment: moderate
  ({N} markets with industry-level TIPS match). ST matching may be less precise."
- If all markets are `none`: "Industry alignment: none. No portfolio markets match
  the TIPS industry context. The exported context will have limited utility for
  Phase 2 grounding."

Tell the user: "Portfolio context (v2.0) saved. When you run value-modeler Phase 2, it
will use proposition language and solution data to ground Solution Templates in your
portfolio's actual capabilities and pricing."

### sync — Reconcile Both Directions

```
/bridge sync
```

Runs `portfolio-to-tips` first (so enriched context is available), then `tips-to-portfolio`.
This ordering ensures that ST generation and backflow both benefit from the latest
portfolio propositions and solution data.

**Step 0: Pre-flight Validation**

Run the shared pre-flight (industry alignment) and then BOTH operation-specific
gate sets (portfolio-to-tips gates AND tips-to-portfolio gates). Report all results
together. If any hard gate from either direction fails, stop and report — this
prevents running portfolio-to-tips successfully only to fail on tips-to-portfolio.

**Step 1: Run portfolio-to-tips**

Execute the full `portfolio-to-tips` operation (enriched v2.0 context export).

**Step 2: Run tips-to-portfolio**

Execute the full `tips-to-portfolio` operation (ST matching, enrichment, evidence, stubs).

**Step 3: Enriched Reconciliation**

Present a unified reconciliation table that shows the full picture across both directions:

```
| Feature | Market | Proposition | Solution | TIPS STs | Status |
|---------|--------|-------------|----------|----------|--------|
| predictive-analytics | mid-market-dach | Yes | Yes | st-001 | Aligned |
| compliance-engine | enterprise-eu | Yes | No | st-004 | Needs solution |
| predictive-analytics | enterprise-eu | No | No | st-001 | Needs enrichment |
| — | — | — | — | st-007 | Portfolio gap |
| simulation-engine | mid-market-dach | Yes | Yes | — | TIPS gap |
```

**Status values:**
- **Aligned** — Feature has proposition, solution, and matching ST(s). Full bidirectional coverage.
- **Needs solution** — Proposition exists but no solution for this market. Step 5.5 should have proposed a stub.
- **Needs enrichment** — Feature matches an ST but lacks a proposition for this market.
- **Portfolio gap** — ST has no matching feature at all. Innovation opportunity.
- **TIPS gap** — Feature with proposition/solution has no TIPS relevance signal. Validate market need independently.

**Step 4: Generate Action Plan**

Based on the reconciliation table, generate a prioritized action list:
1. **Immediate**: Create solution stubs for "Needs solution" rows (if not already proposed)
2. **Short-term**: Enrich propositions for "Needs enrichment" rows
3. **Strategic**: Evaluate "Portfolio gap" STs for new feature creation
4. **Validate**: Review "TIPS gap" features for market relevance

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
