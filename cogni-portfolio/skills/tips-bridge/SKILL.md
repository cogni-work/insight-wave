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

**Step 4: Generate Proposition Variants (for "Enrich" actions)**

For features that already have propositions, generate **variants** instead of modifying
the primary DOES/MEANS. Each matched ST's value chain produces a distinct variant that
captures a specific angle.

**Never auto-replace the primary DOES/MEANS.** The primary remains untouched. Only the
user can promote a variant to primary via `/propositions variants promote`.

**For each matched ST:**

1. Extract the ST's theme and linked value chains from the TIPS value model
2. For each value chain narrative, derive:
   - **Angle**: A kebab-case label from the ST's theme (e.g., `regulatory-compliance`,
     `predictive-maintenance`, `supply-chain-resilience`)
   - **Variant DOES**: The feature's advantage framed through this specific T→I→P angle.
     Example: primary says "Reduces defect rate by 40%" → variant says "Anticipates
     regulatory audit triggers before they fire, giving quality teams weeks instead of
     hours to prepare documentation"
   - **Variant MEANS**: The business outcome framed through the narrative's possibility
     and urgency. Example: primary says "Protects production quality" → variant says
     "Avoid the €2-4M cost of a single compliance failure while reducing audit prep
     effort by 70%"
3. Delegate to the `proposition-generator` agent in **variant mode** by passing:
   - `tips_ref`: the cross-reference to the source ST (e.g., `{pursuit-slug}#st-001`)
   - `value_chain_narrative`: the full T→I→P narrative text from the value chain
4. The agent generates the variant with 3 narrative evidence entries (`why_now`,
   `sales_guide`, `proposal_justification`) and appends it to the proposition's
   `variants` array

**Presentation:**

After all variants are generated, present them alongside the primary for user review:

```
Proposition: {feature}--{market}
Primary DOES: "{current primary does_statement}"
Primary MEANS: "{current primary means_statement}"

Generated Variants:
| Variant | Angle | DOES (summary) | Source ST |
|---------|-------|----------------|----------|
| v-001 | regulatory-compliance | Anticipates audit triggers... | st-001 |
| v-002 | cost-optimization | Reduces total quality cost... | st-001 |
| v-003 | talent-retention | Frees quality engineers... | st-003 |
```

The user can then:
- **Keep** variants as alternative positioning for different sales contexts
- **Promote** a variant to primary via `/propositions variants promote {variant_id}`
- **Delete** variants that don't add value via `/propositions variants delete {variant_id}`

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

**Step 5.3: Generate Path Narrative Evidence**

For each matched ST, construct evidence entries from its value chain narratives. These
transform the abstract T→I→P causal story into concrete, sales-ready content that tells
the buyer *why this matters now* and *how the pieces connect*.

**For each ST with "Enrich" action:**

1. Read the ST's `linked_chains` from the value model
2. For each linked value chain, extract the `trend`, `implications`, `possibilities`,
   and the chain's `narrative`
3. Generate **three evidence entries** per chain, each tagged with `narrative_type` and
   a `tips_path` object for traceability:

   **a) `why_now` — Trend urgency framing**
   ```json
   {
     "statement": "{Trend name} creates a {horizon}-term window — organizations acting now gain first-mover advantage in {possibility area}",
     "source_url": null,
     "source_title": "TIPS Value Model — {pursuit name}",
     "narrative_type": "why_now",
     "tips_path": {
       "trend": "{trend candidate name}",
       "implication": "{primary implication name}",
       "possibility": "{primary possibility name}",
       "urgency": "{act|plan|observe}"
     }
   }
   ```
   The `why_now` entry frames the trend's urgency in terms the buyer understands. Use
   the horizon to calibrate urgency: `act` = "immediate window", `plan` = "emerging
   window, 12-24 months", `observe` = "strategic horizon, position now for future".

   **b) `sales_guide` — Implication→Possibility causal link**
   ```json
   {
     "statement": "Because {implication name} is reshaping {domain}, teams that adopt {possibility/feature} gain {specific advantage from ST description}",
     "source_url": null,
     "source_title": "TIPS Value Model — {pursuit name}",
     "narrative_type": "sales_guide",
     "tips_path": { ... }
   }
   ```
   The `sales_guide` entry explains the I→P link in buyer language. This is the "bridge
   sentence" a salesperson uses to connect the customer's pain (implication) to the
   proposed solution (possibility/feature).

   **c) `proposal_justification` — Full T→I→P narrative**
   ```json
   {
     "statement": "{Full chain narrative adapted to portfolio language: trend drives implication, which creates the need for this feature, enabling the business outcome described in the proposition's MEANS}",
     "source_url": null,
     "source_title": "TIPS Value Model — {pursuit name}",
     "narrative_type": "proposal_justification",
     "tips_path": { ... }
   }
   ```
   The `proposal_justification` entry is a complete paragraph suitable for proposal
   background sections. It weaves the T→I→P chain into a coherent argument for
   investing in this specific feature.

4. **Place the evidence**: If a variant was created for this ST (Step 4), add the
   narrative evidence to the variant's `evidence` array. If no variant exists (the ST
   was skipped or mapped to a feature without propositions), add to the primary
   proposition's `evidence` array.

5. **Deduplication**: If the same value chain feeds multiple STs matched to the same
   proposition, generate the narrative evidence only once (keyed by chain_id).

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
- `narrative_evidence_added` — Path narrative evidence (why_now, sales_guide, proposal_justification) was generated from value chains (Step 5.3)
- `variant_created` — One or more proposition variants were created from TIPS value chains (Step 4)
- `solution_proposed` — A solution stub was proposed (from Step 5.5)

This metadata is appended to the proposition JSON. Portfolio skills that don't understand
it will ignore it. It enables future auditing of which TIPS pursuit influenced which
portfolio positioning.

**Step 5.8: Generate Blueprint-Aware Opportunity Pipeline**

With solution blueprints, the opportunity pipeline becomes more granular and actionable.
Instead of generating one opportunity per unmatched ST, analyze individual building blocks
across all STs to surface taxonomy-level gaps. This answers the strategic question: "Which
portfolio dimensions do we need to invest in to deliver our solution portfolio?"

See `references/opportunity-schema.md` for the full schema definition.

**Two levels of opportunity generation:**

#### Level 1: Per-ST Opportunities (existing behavior, enhanced)

For each Solution Template with `match_confidence: "none"` or `"low"`, generate a
structured opportunity assessment:

1. **Calculate opportunity score** (0-10):
   ```
   opportunity_score = (
       (ranking_value / 5) × 0.4 +
       tam_alignment × 0.3 +
       competitive_whitespace × 0.3
   ) × 10
   ```
   - `ranking_value`: The ST's ranking_value from the TIPS value model (0-5)
   - `tam_alignment`: Fraction of portfolio markets with `market_relevance` = `"direct"`
     or `"industry"` for this pursuit (0-1). Read from the market entries in
     `portfolio-context.json`.
   - `competitive_whitespace`: If competitive analysis exists for related propositions,
     estimate whitespace from competitor coverage gaps. Otherwise default to 0.7
     (moderate whitespace assumption).

2. **Classify the opportunity**:
   - **build**: The company has adjacent expertise (existing features in the same taxonomy
     dimension), the opportunity is core to differentiation, and no adequate turnkey
     solution exists. Requires development investment.
   - **buy**: A commercial solution exists that covers 80%+ of the need. Faster
     time-to-market through acquisition or licensing.
   - **partner**: Requires specialized domain expertise the company lacks. Best addressed
     through co-development, white-label, or referral partnership.

   Use the ST's `category`, its **blueprint building blocks** (taxonomy dimensions),
   and the portfolio's existing feature landscape to guide classification. A gap in
   a consulting dimension (7.x) naturally suggests "partner"; a gap in a core technical
   dimension (4.x, 6.x) may suggest "build" or "buy".

3. **Estimate revenue** from market TAM data:
   - Read portfolio markets and filter to those with `market_relevance` = `"direct"`
   - Use TAM values with conservative penetration assumptions (0.05-0.2%)
   - Set confidence: `"high"` (validated TAM + comparable pricing), `"medium"` (TAM
     with assumptions), `"low"` (rough estimate)

4. **Generate feature spec** (roadmap-ready):
   - `proposed_slug`: Derived from ST name (kebab-case)
   - `name` and `description`: Adapted from ST for feature language
   - `category`: Derived from ST category
   - `readiness`: Always `"planned"`
   - `unmet_needs`: From blueprint building blocks with `coverage: "gap"` — each gap
     block's `gaps` array provides specific unmet capabilities. Falls back to
     `portfolio_anchor.theme_needs_undelivered` or ST description extraction.
   - `taxonomy_refs`: Array of taxonomy categories from the ST's blueprint gap blocks
     (e.g., `["1.4", "7.2"]`) — shows which portfolio dimensions this opportunity spans
   - `source_themes` and `source_sts`: Traceability to TIPS value model

5. **Assign priority**: `"high"` (score ≥ 7.0 AND ranking_value ≥ 4.0), `"medium"`
   (score ≥ 4.0 OR ranking_value ≥ 3.0), `"low"` (everything else)

#### Level 2: Taxonomy Gap Analysis (new)

After generating per-ST opportunities, aggregate all blueprint building blocks across
ALL Solution Templates (not just unmatched ones) to produce a taxonomy-level gap report:

1. **Collect all building blocks** from all STs' `solution_blueprint.building_blocks`
2. **Group by taxonomy dimension** (0-7) and then by category (e.g., "6.6")
3. **Count coverage status** per category:
   - How many STs need this category?
   - How many have it covered vs. partial vs. gap?

4. **Generate Taxonomy Gap Report**:

```
Taxonomy Gap Analysis — Portfolio Investment Priorities

| Dim | Taxonomy Category | STs Needing | Covered | Partial | Gap | Priority |
|-----|-------------------|-------------|---------|---------|-----|----------|
| 7   | Digital Transformation (7.2) | 5 | 0 | 1 | 4 | HIGH |
| 1   | 5G & IoT Connectivity (1.4) | 4 | 1 | 2 | 1 | MEDIUM |
| 2   | Cloud Security (2.4) | 3 | 0 | 0 | 3 | HIGH |
| 7   | Program Management (7.4) | 2 | 0 | 0 | 2 | MEDIUM |

Strategic Insight:
- Consulting (Dim 7) is the #1 portfolio gap: 7 building blocks across 5 STs need
  consulting capabilities that don't exist in the portfolio. Consider a consulting
  partnership or practice build.
- Security (Dim 2) gaps affect 3 high-ranked STs. Investing here would improve
  readiness scores across the solution portfolio.
```

Priority for taxonomy gaps: `HIGH` = ≥3 STs affected AND majority are gap (not partial),
`MEDIUM` = 2+ STs affected, `LOW` = 1 ST affected.

This taxonomy gap report is the most strategically valuable output of the bridge — it
transforms individual solution gaps into portfolio-level investment priorities.

**Write** `portfolio-opportunities.json` to the TIPS project directory (alongside
`tips-value-model.json`). Include both per-ST opportunities and the taxonomy gap summary.

**Present** the opportunities table sorted by score, followed by the taxonomy gap report:

```
Innovation Pipeline ({N} opportunities)

| # | Opportunity | Score | Class | Revenue Est. | Readiness | Priority |
|---|-------------|-------|-------|-------------|-----------|----------|
| 1 | Compliance Automation Suite | 8.2 | build | €500K/yr | 0.35 | high |
| 2 | Edge Analytics Gateway | 6.1 | partner | €200K/yr | 0.50 | medium |
| 3 | Digital Twin Connector | 3.4 | buy | €80K/yr | 0.72 | low |

Actions: [Accept] creates a feature stub from the spec. [Defer] keeps it in the
pipeline for future review. [Reject] removes it.
```

For each opportunity the user accepts, create a feature file from the `feature_spec`
using the same process as Step 3 (new feature creation). Mark it with
`tips_ref: "{pursuit-slug}#st-{id}"` for traceability.

**Step 6: Summary**

Report what was created/enriched:
- N new features created (from Step 3 and accepted opportunities)
- N proposition variants created (with angle breakdown)
- N narrative evidence entries generated (why_now, sales_guide, proposal_justification)
- N metric-based evidence entries suggested (with tips_context provenance)
- N solution stubs proposed
- N opportunities identified (with classification breakdown: build/buy/partner)
- Total estimated annual revenue from opportunities: €{total}
- List high-ranked STs with quality flags needing investment
- **Taxonomy gap summary**: Which B2B ICT dimensions have the most building block gaps
  across the solution portfolio, and how many STs are affected per dimension. This is
  the most actionable output for portfolio investment planning.

### portfolio-to-tips — Load Portfolio as TIPS Constraints

```
/bridge portfolio-to-tips
```

Loads the portfolio's products, features, propositions, and solutions into the TIPS value
model context so that Phase 2 (Solution Template generation) is grounded in what you
actually sell and how you position it per market.

**This operation is informational** — it writes a `portfolio-context.json` (v3.0) file into
the TIPS project directory that value-modeler Phase 2 can read. The enriched context gives
Phase 2 access to proposition language (IS/DOES/MEANS), quality assessments, variant counts,
and solution summaries so that Solution Templates are grounded in real portfolio capabilities
with quality awareness.

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

**Step 2.5: Enrich Features with Propositions, Solutions & Quality**

For each feature, check for matching proposition and solution files:

1. Read all `portfolio/propositions/{feature-slug}--{market-slug}.json` files
2. Read all `portfolio/solutions/{feature-slug}--{market-slug}.json` files
3. Compact each proposition into: `is_statement`, `does_statement`, `means_statement`,
   `evidence_count` (number of evidence entries), and `variant_count` (length of `variants`
   array, or 0 if absent)
4. Compact each solution into: `solution_type`, `pricing_tiers` (tier names only),
   and `price_range` (min, max, currency)
5. **Assess proposition quality**: For each proposition, run the `proposition-quality-assessor`
   agent (or read cached assessment if `updated` date hasn't changed since last assessment).
   Compact the result into a `quality_assessment` object:
   ```json
   {
     "quality_assessment": {
       "overall": "pass|warn|fail",
       "does_score": {
         "buyer_centricity": "pass|warn|fail",
         "market_specificity": "pass|warn|fail",
         "differentiation": "pass|warn|fail",
         "status_quo_contrast": "pass|warn|fail",
         "conciseness": "pass|warn|fail"
       },
       "means_score": {
         "outcome_specificity": "pass|warn|fail",
         "escalation": "pass|warn|fail",
         "quantification": "pass|warn|fail",
         "emotional_resonance": "pass|warn|fail",
         "conciseness": "pass|warn|fail"
       },
       "assessed_at": "2026-03-13"
     }
   }
   ```
   Quality assessment is cached — only re-run if the proposition's `updated` date is newer
   than `assessed_at`. If no prior assessment exists, run the assessor. If running assessments
   would slow down the export significantly (>10 propositions), warn the user and offer to
   skip: "Quality assessment of {N} propositions may take a few minutes. Skip for now?"
6. Nest the compacted propositions under their parent feature

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

Assemble `portfolio-context.json` v3.0:

```json
{
  "schema_version": "3.0",
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
              "variant_count": 2,
              "quality_assessment": {
                "overall": "pass",
                "does_score": {
                  "buyer_centricity": "pass",
                  "market_specificity": "pass",
                  "differentiation": "pass",
                  "status_quo_contrast": "warn",
                  "conciseness": "pass"
                },
                "means_score": {
                  "outcome_specificity": "pass",
                  "escalation": "pass",
                  "quantification": "pass",
                  "emotional_resonance": "warn",
                  "conciseness": "pass"
                },
                "assessed_at": "2026-03-12"
              },
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

**Schema version notes:**
- v3.0 adds `variant_count` and `quality_assessment` per proposition (v2.0 consumers ignore these)
- v2.0 had propositions without quality or variant data
- v1.0 (no `schema_version` field) had no embedded propositions at all

**Backward compatibility:** The `schema_version` field distinguishes versions. Phase 2
checks this field: v3.0 enables quality-aware generation and variant tracking, v2.0
enables proposition-grounded generation, v1.0 (no field) falls back to basic feature
matching. Each version is a superset of the previous — new fields are additive.

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

Tell the user: "Portfolio context (v3.0) saved. When you run value-modeler Phase 2, it
will use proposition language, quality assessments, and solution data to ground Solution
Templates in your portfolio's actual capabilities and pricing."

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
| Feature | Market | Proposition | Variants | Solution | TIPS STs | Blueprint | Status |
|---------|--------|-------------|----------|----------|----------|-----------|--------|
| predictive-analytics | mid-market-dach | Yes | 2 | Yes | st-001 | Lead (0.68) | Aligned |
| compliance-engine | enterprise-eu | Yes | 0 | No | st-004 | Lead (0.42) | Needs solution |
| predictive-analytics | enterprise-eu | No | — | No | st-001 | Lead (0.68) | Needs enrichment |
| — | — | — | — | — | st-007 | — (0.35) | Portfolio gap |
| simulation-engine | mid-market-dach | Yes | 1 | Yes | — | — | TIPS gap |
| predictive-analytics | mid-market-dach | Yes (fail) | 2 | Yes | st-001 | Lead (0.68) | Aligned (quality review) |
```

**Status values:**
- **Aligned** — Feature has proposition, solution, and matching ST(s). Full bidirectional coverage.
- **Aligned (quality review)** — Aligned, but the proposition has quality assessment failures. The matched ST has `ranking_value` ≥ 4.0, making quality investment worthwhile.
- **Needs solution** — Proposition exists but no solution for this market. Step 5.5 should have proposed a stub.
- **Needs enrichment** — Feature matches an ST but lacks a proposition for this market.
- **Portfolio gap** — ST has no matching feature at all. Innovation opportunity — see Innovation Pipeline below.
- **TIPS gap** — Feature with proposition/solution has no TIPS relevance signal. Validate market need independently.

**Innovation Pipeline** (from `portfolio-opportunities.json`):

If the `tips-to-portfolio` step generated opportunities (Step 5.8), embed the
innovation pipeline summary in the reconciliation:

```
Innovation Pipeline ({N} opportunities, €{total}/yr estimated)

| # | Opportunity | Score | Class | Revenue | Priority | Decision |
|---|-------------|-------|-------|---------|----------|----------|
| 1 | Compliance Automation | 8.2 | build | €500K/yr | high | — |
| 2 | Edge Analytics Gateway | 6.1 | partner | €200K/yr | medium | — |
```

The user can accept/defer/reject opportunities inline during sync review.

**Step 4: Generate Action Plan**

Based on the reconciliation table and innovation pipeline, generate a prioritized action list:
1. **Immediate**: Create solution stubs for "Needs solution" rows (if not already proposed)
2. **Short-term**: Generate variants for "Needs enrichment" rows; run `/propositions variants add` for propositions without TIPS variants
3. **Quality**: Run proposition quality improvement for "Aligned (quality review)" rows — high-BR STs deserve high-quality propositions
4. **Innovation**: Evaluate accepted opportunities for roadmap inclusion; create features from approved `feature_spec` entries
5. **Validate**: Review "TIPS gap" features for market relevance

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
