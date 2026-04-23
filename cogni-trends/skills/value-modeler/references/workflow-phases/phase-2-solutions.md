# Phase 2: Generate Solution Templates

## Objective

For each TIPS path, generate concrete Solution Templates — enablers of process improvement
that address the value story captured in the path. Optionally map to existing portfolio items.

## What is a Solution Template?

A Solution Template (ST) is not a vague recommendation. It is a concrete, nameable enabler
that a solution supplier could deliver. Think of it as: "If this path is relevant to the
customer, then *this* is what we should propose."

**Good Solution Templates:**
- "Predictive Quality Analytics Platform" — deploy ML-based quality prediction
- "Regulatory Compliance Automation Suite" — automate EU AI Act audit trails
- "Digital Twin for Production Line Optimization" — simulate and optimize line throughput

**Bad Solution Templates (too vague):**
- "Improve quality" — not actionable
- "Digital transformation" — not specific enough
- "Better analytics" — no clear scope

## Step 0: Portfolio Context Check

Before generating any Solution Templates, check the Phase 0 output metadata for portfolio discovery:

1. **Portfolio discovered, no context file**: If `portfolio_discovered` is `true` in the Phase 0
   metadata but no `portfolio-context.json` exists in the project directory, warn the user:

   > "A portfolio project was found in your workspace, but no portfolio context has been exported
   > yet. Without it, Phase 2 will generate abstract Solution Templates instead of grounding them
   > in your actual products. This means solutions may not map to real offerings."

   Offer two options:
   - **Run `/bridge portfolio-to-tips` now** (recommended) — pauses Phase 2, runs the bridge,
     then resumes with portfolio-anchored generation
   - **Continue with abstract generation** — proceeds without portfolio context

2. **Context exists but v1.0** (no `schema_version` field): Same recommendation as above —
   v1.0 context lacks proposition data needed for grounding.

3. **Context exists at v2.0**: Note that v3.0 adds quality-aware generation. Proceed to Step 0.5
   without blocking.

4. **Context exists at v3.0**: Proceed silently to Step 0.5.

5. **No portfolio discovered**: Proceed silently to Step 1 (abstract generation).

6. **Generic portfolio context** (`portfolio_generic` is `true` in Phase 0 metadata):
   The context file has `is_generic_template: true`. Proceed to Step 0.5 — the generic
   portfolio has features with IS/DOES/MEANS propositions that enable feature-to-theme
   matching and ST grounding. See Step 0.5.4b for generic-specific handling.

## Phase 2 Decision Flow

The steps in this phase depend on whether portfolio context is available:

```
Portfolio context v2.0+ exists (company-specific):
  Step 0.5 (anchored STs from portfolio features)
  → Step 1 (abstract STs for investment themes not fully covered by Step 0.5)
  → Step 1.5 (blueprint composition for abstract STs, coverage assessed against portfolio)
  → Step 2 (enrich all blueprints with real portfolio data)

Generic portfolio context (is_generic_template: true):
  Step 0.5 (anchored STs from generic taxonomy features — see Step 0.5.4b)
  → Step 1 (abstract STs for investment themes not fully covered by Step 0.5)
  → Step 1.5 (blueprint composition for abstract STs, coverage assessed against generic features)
  → Skip Step 2 (no company-specific data to enrich from)

Portfolio context v1.0 or absent:
  Skip Step 0.5
  → Step 1 (abstract STs for all investment themes)
  → Step 1.5 (blueprint composition with coverage: "unknown" on all blocks)
  → Skip Step 2 (no portfolio data to enrich from)

Re-anchor mode (independent invocation or explicit request):
  Step 2.7 (re-analyze and re-match existing STs against current portfolio using LLM solutioning)
  → Optionally re-run Phase 4 if ranking was already done
```

## Step 0.5: Portfolio-Anchored Generation (when v2.0+ context exists)

This step runs **only** when `portfolio-context.json` has `schema_version` >= `"2.0"`. When the
context is absent or v1.0, skip directly to Step 1 (unchanged behavior).

Portfolio-anchored generation inverts the normal flow: instead of starting from investment themes and
imagining solutions, it starts from **existing products/features** and asks what each investment theme
needs that those features can deliver. This produces STs with high portfolio confidence by
construction.

### 0.5.1: Read Portfolio Context

Read `portfolio-context.json` from the TIPS project directory and extract:
- All products and their features (slugs, descriptions, categories)
- All propositions per feature (IS/DOES/MEANS, market slugs, evidence counts)
- Market relevance tags (`direct`, `industry`, `adjacent`)
- If v3.0: quality assessments per proposition (`market_specificity`, `differentiation`, `value_quantification`)

### 0.5.2: Match Features to Investment Themes

For each feature in the portfolio context, use semantic analysis to determine which Investment
Themes it could serve. Consider:

- **Description overlap**: Does the feature's description address the investment theme's strategic question?
- **Category alignment**: Does the feature's category (software, hardware, service) align with the investment theme's value chain domains?
- **Market-relevance filtering**: Only consider features that have at least one proposition in a `direct` or `industry` market. Features with only `adjacent` market propositions are deprioritized.
- **Proposition language**: Do any DOES/MEANS statements echo the investment theme's narrative or the needs of its value chains?

Produce a feature-to-investment-theme match matrix before generating any STs.

### 0.5.3: Generate Portfolio-Anchored STs with Solution Blueprints

For each feature-to-investment-theme match, generate a Solution Template with a full **solution blueprint** —
a multi-dimensional composition of building blocks that captures what portfolio is needed to
deliver this solution. This is the core solutioning expertise: knowing that a "Predictive Quality
Analytics Platform" isn't just one analytics feature, but requires connectivity, cloud, security,
and consulting capabilities working together.

1. **Start from the feature** as the delivery mechanism — this becomes the `lead` building block
2. **Ask the grounding questions** for the lead block:
   - "What does this investment theme need that this feature can deliver?" → becomes `delivers` on the lead block
   - "What does this investment theme need that this feature cannot deliver?" → becomes `gaps` on the lead block
3. **Identify additional building blocks**: Analyze the investment theme's strategic question and its
   value chain narratives to determine what other capabilities are required beyond the lead
   feature. Reference the B2B ICT taxonomy (`$CLAUDE_PLUGIN_ROOT/references/taxonomies/b2b-ict-portfolio.md`)
   to categorize each needed capability into its taxonomy dimension and category.

   For each additional capability:
   - Map it to the most specific taxonomy category (e.g., "1.4 5G & IoT Connectivity", "7.2 Digital Transformation")
   - Assign a role: `"supporting"` for necessary technical layers, `"enabling"` for organizational/advisory prerequisites
   - Scan the portfolio context for features that could serve this capability:
     - If a matching feature exists and fully covers the need → `coverage: "covered"`
     - If a matching feature exists but gaps remain → `coverage: "partial"`
     - If no matching feature exists → `coverage: "gap"`
   - Populate `delivers` and `gaps` for each block based on what the matched feature can/cannot provide

   **Typical blueprint composition** (2-5 blocks):
   - 1 lead block (the matched feature)
   - 1-2 supporting blocks (technical dependencies: cloud, connectivity, security, data)
   - 0-2 enabling blocks (consulting, training, governance)

4. **Assemble the solution blueprint**:
   ```json
   {
     "solution_blueprint": {
       "building_blocks": [
         {
           "role": "lead",
           "capability": "Predictive analytics engine",
           "taxonomy_ref": "6.6",
           "taxonomy_name": "AI, Data & Analytics",
           "taxonomy_dimension": 6,
           "coverage": "covered",
           "feature_slug": "predictive-analytics",
           "product_slug": "cloud-platform",
           "delivers": ["ML model training", "anomaly detection", "real-time alerting"],
           "gaps": ["edge inference", "explainable AI"]
         },
         {
           "role": "supporting",
           "capability": "IoT sensor connectivity",
           "taxonomy_ref": "1.4",
           "taxonomy_name": "5G & IoT Connectivity",
           "taxonomy_dimension": 1,
           "coverage": "partial",
           "feature_slug": "iot-gateway",
           "product_slug": "connectivity-suite",
           "delivers": ["sensor data collection"],
           "gaps": ["private 5G", "edge processing"]
         },
         {
           "role": "supporting",
           "capability": "Cloud-native runtime",
           "taxonomy_ref": "4.6",
           "taxonomy_name": "Cloud-Native Platform",
           "taxonomy_dimension": 4,
           "coverage": "covered",
           "feature_slug": "k8s-platform",
           "product_slug": "cloud-platform",
           "delivers": ["container orchestration", "auto-scaling"],
           "gaps": []
         },
         {
           "role": "enabling",
           "capability": "Manufacturing transformation consulting",
           "taxonomy_ref": "7.2",
           "taxonomy_name": "Digital Transformation",
           "taxonomy_dimension": 7,
           "coverage": "gap",
           "feature_slug": null,
           "product_slug": null,
           "delivers": [],
           "gaps": ["domain consulting", "change management"]
         }
       ],
       "readiness": {
         "covered_count": 2,
         "partial_count": 1,
         "gap_count": 1,
         "unknown_count": 0,
         "readiness_score": 0.68,
         "taxonomy_span": [1, 4, 6, 7],
         "taxonomy_depth": 4
       }
     }
   }
   ```

5. **Calculate readiness score** using the role-weighted formula:
   ```
   role_weight:    lead=1.0, supporting=0.7, enabling=0.4
   coverage_value: covered=1.0, partial=0.5, gap=0.0, unknown=0.5
   readiness_score = sum(coverage_value × role_weight) / sum(role_weight)
   ```
   In the example: (1.0×1.0 + 0.5×0.7 + 1.0×0.7 + 0.0×0.4) / (1.0 + 0.7 + 0.7 + 0.4) = 1.75 / 2.8 ≈ 0.625

6. **Derive `portfolio_anchor`** from the lead building block for backward compatibility:
   ```
   portfolio_anchor.feature_slug = lead.feature_slug
   portfolio_anchor.product_slug = lead.product_slug
   portfolio_anchor.investment_theme_needs_delivered = lead.delivers
   portfolio_anchor.investment_theme_needs_undelivered = lead.gaps
   ```

7. **Set remaining ST fields**:
   - All standard fields (`st_id`, `name`, `description`, `category`, `enabler_type`, `investment_theme_ref`, `linked_chains`, `foundation_dependencies`)
   - `generation_mode: "portfolio-anchored"`
   - `portfolio_mapping.match_confidence: "high"` — automatically high because the ST was generated FROM the feature
   - If the feature has propositions in the context, populate `portfolio_grounding` entries:
     ```json
     {
       "portfolio_grounding": [
         {
           "feature_slug": "predictive-analytics",
           "market_slug": "mid-market-saas-dach",
           "does_echo": "Reduces MTTR by 60% through AI-correlated alerting",
           "evidence_available": true
         }
       ]
     }
     ```

### 0.5.4: Quality-Aware Generation (v3.0)

When the portfolio context has `quality_assessment` data (v3.0):

- If a matched proposition has quality `"fail"` on `market_specificity` or `differentiation`,
  add `quality_flag: "quality_investment_needed"` to the ST
- Include a note in the ST description that adds market-specific language the bridge can use
  for variant generation later — this creates a feedback loop where TIPS insights improve
  portfolio quality
- If all propositions for a feature pass quality checks, omit the `quality_flag` (no flag = healthy)

### 0.5.4b: Generic Portfolio Handling

When the portfolio context has `is_generic_template: true` and `proposition_mode: "dynamic"`
(set by Phase 0 when using the generic B2B ICT portfolio):

The generic portfolio contains only IS-layer feature descriptions and taxonomy mappings — no
pre-baked DOES/MEANS propositions. The target market context comes from the trend-scout project
(`industry.primary`, `industry.subsector`, `research_topic` in `tips-project.json`), not from
the portfolio template. This means DOES/MEANS must be generated dynamically during ST creation.

**What works normally:**
- Step 0.5.1 (Read Portfolio Context) — features have `description` (IS statement) and `taxonomy_mapping`
- Step 0.5.2 (Match Features to Investment Themes) — use feature `description` and `taxonomy_mapping`
  for semantic matching between features and investment themes. IS-layer descriptions are
  market-independent and sufficient for mapping features to themes without DOES/MEANS language
- Step 0.5.3 (Generate Portfolio-Anchored STs) — blueprint composition works as normal;
  building blocks map to generic taxonomy features with `coverage: "covered"` or `"partial"`

**What changes:**
- **Generate DOES/MEANS dynamically** — after matching features to themes, generate
  market-adapted propositions for each matched feature based on:
  - The project's research context: `industry.primary`, `industry.subsector`, and
    `research_topic` from `tips-project.json`
  - The investment theme's strategic question and value chain narrative
  - The feature's IS description and taxonomy category
  - The generated DOES frames the advantage (what measurable improvement the capability
    delivers in the project's target context)
  - The generated MEANS anchors the business outcome (why a buyer in this industry/subsector
    cares about the advantage)
  - Store on each ST building block as `generated_proposition: { does: "...", means: "..." }`
    so downstream phases can reference the language
- **Skip Step 0.5.4** (Quality-Aware Generation) — dynamically generated propositions have no
  `quality_assessment` data, so quality flags cannot be computed
- **Skip `portfolio_grounding`** entries — there are no company-specific DOES claims to echo
- **Set `generation_mode: "generic-portfolio-anchored"`** on each ST (instead of
  `"portfolio-anchored"`) — this distinguishes STs grounded in generic taxonomy features
  from STs grounded in real company products
- **Add `generic_portfolio_note`** to each ST:
  ```json
  {
    "generic_portfolio_note": "Grounded in generic B2B ICT taxonomy features, not company-specific capabilities. Replace with your own portfolio via /portfolio-setup + /bridge portfolio-to-tips, then run /value-model re-anchor."
  }
  ```
- **Set `portfolio_mapping.is_generic: true`** on each building block that maps to a
  generic feature — this tells the trends-bridge to treat all mappings as "Create" actions
  (not "Enrich") when later running `/bridge tips-to-portfolio`

**Coverage interpretation:** Since the generic portfolio has one feature per taxonomy category
(51 features across 57 categories, excluding dimension 0), most building blocks will show
`coverage: "covered"`. This is expected and clearly labeled — it means the *taxonomy category*
exists, not that a specific company can deliver it. The `generation_mode` and
`generic_portfolio_note` fields make this distinction explicit in all downstream outputs.

### 0.5.5: Reduce Abstract Targets

For each investment theme that received portfolio-anchored STs, reduce the target for Step 1 abstract
generation:

- **2+ anchored STs**: The investment theme may not need abstract STs at all. Still generate 1 abstract
  ST if the anchored STs don't fully cover the investment theme's strategic question (check whether
  `investment_theme_needs_undelivered` items suggest a significant gap)
- **1 anchored ST**: Reduce the abstract target by 1 (e.g., from 2-4 to 1-3)
- **0 anchored STs**: No change — Step 1 runs at full capacity for this investment theme

### 0.5.6: Report

Present portfolio-anchored STs first, grouped by investment theme. Show the full blueprint composition
so the user can see the solutioning expertise — which building blocks are needed and which
are covered, partial, or gaps:

```markdown
## Portfolio-Anchored Solution Templates

### Investment Theme 1: Smart Manufacturing & Supply Chain (2 anchored STs)

**ST-001: Predictive Quality Analytics Platform** [ANCHORED]
Blueprint: 4 building blocks across 4 taxonomy dimensions
  ● Lead:       AI, Data & Analytics (6.6) — predictive-analytics ✓ COVERED
  ◐ Supporting: 5G & IoT Connectivity (1.4) — iot-gateway ◐ PARTIAL
  ● Supporting: Cloud-Native Platform (4.6) — k8s-platform ✓ COVERED
  ✗ Enabling:   Digital Transformation (7.2) — ✗ GAP
Readiness: 0.68 | Taxonomy span: [1, 4, 6, 7]
Quality: OK
> Deploy ML-based quality prediction using the existing predictive-analytics
> feature, integrated with production line sensor data via IoT gateway.

**ST-002: Digital Twin Production Optimizer** [ANCHORED]
Blueprint: 3 building blocks across 3 taxonomy dimensions
  ● Lead:       Cloud-Native Platform (4.6) — digital-twin-engine ✓ COVERED
  ◐ Supporting: 5G & IoT Connectivity (1.4) — iot-gateway ◐ PARTIAL
  ✗ Enabling:   Program & Project Management (7.4) — ✗ GAP
Readiness: 0.60 | Taxonomy span: [1, 4, 7]
Quality: quality_investment_needed (market_specificity: fail)
> Simulate and optimize line throughput using the digital-twin-engine,
> grounded in existing DOES claims for mid-market manufacturing.
```

Then note which investment themes still need abstract STs:
```
Investment themes needing abstract STs in Step 1:
- Investment Theme 3: Regulatory Compliance (0 anchored STs → full abstract generation)
- Investment Theme 5: Sustainability & ESG (1 anchored ST → reduced target: 1-3 abstract STs)
```

## Step 1: Generate Solution Templates

> **Note:** If portfolio-anchored STs were generated in Step 0.5, adjust the target per
> investment theme — generate abstract STs only for investment themes or investment theme areas not covered by anchored STs.
> Investment themes with 2+ anchored STs may need only 0-1 abstract STs. Investment themes with 0 anchored STs
> use the full 2-4 target.

For each **Investment Theme**, generate 2-4 Solution Templates using extended thinking.
Working at the investment theme level (rather than per-chain) naturally deduplicates — chains within
an investment theme share strategic direction, so a single ST often serves multiple chains.

**Portfolio-grounded generation (when `portfolio-context.json` v2.0+ exists):**
When an enriched portfolio context is available (check for `schema_version` >= `"2.0"`),
ST descriptions should reference capability language from matched propositions. Specifically:
- Use DOES statements to frame the ST's advantage (what measurable improvement it delivers)
- Use MEANS statements to anchor the ST's business outcome (why the customer should care)
- The ST remains TIPS-native (solution-oriented), but is **grounded** in what the portfolio
  already articulates — this avoids generating STs in a vacuum

**Quality-driven refinement (when v3.0 context with `quality_assessment` exists):**
When the portfolio context includes quality assessments per proposition, use them to
improve abstract ST descriptions:
- If a matched proposition's `quality_assessment.does_score.market_specificity` is `"fail"`,
  the ST description should compensate by adding market-specific language that the bridge
  can later use for variant generation. Example: instead of a generic "quality analytics
  platform", write "quality analytics platform targeting {TIPS subsector} production
  environments where {specific trend} drives {specific implication}."
- If `differentiation` is `"fail"`, the ST description should emphasize what makes this
  solution unique relative to category alternatives — draw on the value chain's specific
  T→I→P narrative to articulate a competitor-proof angle.
- Add `quality_flag: "quality_investment_needed"` to abstract STs whose matched propositions
  have overall quality `"fail"`. Report these in the Phase 2 summary so the user knows
  which propositions need improvement before customer-facing use.

If no v2.0+ context exists, generate STs using industry context alone (unchanged behavior).

**For each ST, define:**
- `st_id`: Sequential identifier (st-001, st-002, ...)
- `name`: Descriptive name (3-7 words)
- `description`: What it does and how (1-2 sentences)
- `category`: `software` | `hardware` | `service` | `hybrid` | `process`
- `enabler_type`: `process_improvement` | `capability_building` | `risk_mitigation` | `revenue_enablement`
- `investment_theme_ref`: The primary Investment Theme this ST belongs to
- `linked_chains`: Which value chains this ST addresses (can span multiple chains within the investment theme)
- `foundation_dependencies`: Which foundation candidates are prerequisites

**Generation guidelines:**
- Consider all value chains within the investment theme holistically — what enabler would address
  the investment theme's strategic question most directly?
- A single ST can address multiple chains within an investment theme (this is expected and desirable)
- Cross-investment-theme STs are rare but allowed — if an ST genuinely serves two investment themes, link it
  to both but assign a primary `investment_theme_ref`
- Prefer concrete over abstract — name specific technologies, platforms, methodologies
- Consider the project's industry context (automotive solutions differ from pharma)
- Use the chain's horizon alignment to set implementation urgency:
  - All-act chains → immediate implementation STs
  - Act-plan chains → near-term STs with phased rollout
  - Plan-observe chains → strategic initiative STs

**Target: 2-4 STs per investment theme → 8-20 total.** This range reflects that investment themes consolidate
what would otherwise be 15-25 STs spread across redundant paths. If you find yourself
generating >4 STs for a single investment theme, the investment theme may be too broad — revisit the Phase 1
split criteria.

## Step 1.5: Blueprint Composition for Abstract STs

Abstract STs also get solution blueprints. While portfolio-anchored STs have their blueprints
populated from real portfolio matches (Step 0.5.3), abstract STs need their composition
analyzed from their description and investment theme context. This ensures every ST carries solutioning
expertise metadata — the knowledge of what portfolio dimensions are needed to deliver it.

For each abstract ST:

1. **Identify the primary taxonomy category** — what B2B ICT taxonomy category (from
   `$CLAUDE_PLUGIN_ROOT/references/taxonomies/b2b-ict-portfolio.md`) best describes this
   ST's core capability? This becomes the `lead` building block.

2. **Identify supporting and enabling capabilities** — analyze the ST description, its
   investment theme's strategic question, and its linked value chain narratives. What additional
   taxonomy categories are needed to deliver this solution? Typical patterns:
   - Software STs often need cloud infrastructure (Dim 4), connectivity (Dim 1)
   - Process STs often need consulting (Dim 7), training (Dim 7)
   - Hardware STs often need managed infrastructure (Dim 5), integration (Dim 6)
   - Security-critical STs need security services (Dim 2)

3. **Assess coverage against portfolio context** (when available):
   - If `portfolio-context.json` v2.0+ exists, scan its features for each building block
   - A feature in the same taxonomy dimension whose description semantically matches
     the building block's capability → `coverage: "covered"` or `"partial"`
   - No matching feature → `coverage: "gap"`
   - If no portfolio context exists → all blocks get `coverage: "unknown"`

4. **Assemble the blueprint** — same structure as portfolio-anchored STs:
   - 1 lead block (primary taxonomy category)
   - 1-4 supporting/enabling blocks (additional taxonomy categories)
   - Calculate readiness score using the role-weighted formula

5. **Derive `portfolio_anchor`** from the lead block (for backward compatibility). For
   abstract STs without portfolio matches, `feature_slug` and `product_slug` will be null.

When portfolio context exists but coverage is assessed as all-gap or all-unknown, the
readiness score naturally reflects this (≤ 0.5). This is informational — it tells the user
"this is a good solution idea but you don't have the portfolio to deliver it yet."

## Step 2: Portfolio Mapping and Blueprint Enrichment (if available)

If a cogni-portfolio project was discovered in Phase 0, this step enriches the solution
blueprints with real portfolio data and populates `portfolio_mapping` for each ST.

With solution blueprints, Step 2 becomes a **blueprint enrichment** step: instead of
mapping each ST to a single feature, it iterates over every building block in the blueprint
and attempts to match each one against the portfolio.

1. **Read all features** from `portfolio/features/*.json` (or from `portfolio-context.json`
   if v2.0+ exists)

2. **For each ST**, iterate over its `solution_blueprint.building_blocks`:
   - For blocks with `coverage: "unknown"` or `"gap"`, attempt feature matching:
     - Keyword overlap between block capability and feature description
     - Taxonomy category alignment (same dimension → higher priority)
     - Semantic similarity of the block's capability to the feature's capability
   - For matched blocks, update:
     - `coverage`: "unknown" → "covered" or "partial" based on match quality
     - `feature_slug` and `product_slug`: from the matched feature
     - `delivers` and `gaps`: based on what the feature can/cannot provide for this block

3. **Assign match confidence** on `portfolio_mapping` using the lead building block:
   - `high`: Lead block coverage is "covered" (clear match)
   - `medium`: Lead block coverage is "partial" (some overlap)
   - `low`: Lead block has a feature but coverage is weak
   - `none`: Lead block coverage is "gap" or "unknown" — no portfolio match for the primary capability

4. **Recalculate `readiness_score`** after all blocks are assessed — the enrichment may
   have upgraded blocks from "unknown" to "covered" or confirmed them as "gap".

5. **Enrich from Portfolio Propositions (v2.0 context):**

   When `portfolio-context.json` has `schema_version` >= `"2.0"`, the propositions are
   already embedded in the context file. For each building block with a matched feature:

   a. Read the `propositions` array from the matched feature
   b. Filter to propositions from markets where `market_relevance` is `direct` or `industry`
   c. Use proposition language to ground the ST description:
      - The **DOES** statement provides advantage framing → incorporate into ST description
      - The **MEANS** statement provides business outcome language → inform ST justification
   d. Add entries to the ST's `portfolio_grounding` array:

   ```json
   {
     "portfolio_grounding": [
       {
         "feature_slug": "predictive-analytics",
         "market_slug": "mid-market-saas-dach",
         "does_echo": "Reduces MTTR by 60% through AI-correlated alerting",
         "evidence_available": true
       }
     ]
   }
   ```

   When v2.0 context is not available, fall back to reading proposition files directly
   from the portfolio directory.

6. **Report portfolio gaps with taxonomy context**: STs with `none` or `low` match
   confidence are portfolio gaps — but now with blueprint data, the report shows exactly
   *which taxonomy dimensions* are missing:

   ```
   Portfolio Gaps (by taxonomy dimension):
     Dim 2 (Security): 3 blocks across 2 STs — no matching features
     Dim 7 (Consulting): 4 blocks across 3 STs — no matching features
     Dim 1 (Connectivity): 2 blocks across 2 STs — partial coverage only
   ```

```json
{
  "portfolio_mapping": {
    "product_slug": "cloud-platform",
    "feature_slug": "predictive-analytics",
    "match_confidence": "high",
    "proposition_exists": true,
    "solution_exists": false
  }
}
```

If no portfolio is discovered, set `portfolio_mapping` to `null` on all STs. Blueprint
blocks will have `coverage: "unknown"` — the taxonomy mapping is still valuable for
understanding solution composition even without portfolio data.

## Step 2.5: Generate Solution Process Improvements

For each Solution Template, generate 1-3 Solution Process Improvements (SPIs) — operational
process changes that accompany the ST. While an ST is the *what* (a product, platform, or tool),
SPIs are the *how* (organizational and process changes needed to realize value from the ST).

**For each SPI, define:**
- `spi_id`: Sequential identifier (spi-001, spi-002, ...)
- `name`: Descriptive name (3-7 words)
- `description`: What process change is required (1-2 sentences)
- `st_ref`: The parent Solution Template ID
- `change_type`: `governance` | `training` | `workflow` | `organization` | `measurement`

**Example:**
- ST: "Predictive Quality Analytics Platform"
  - SPI: "Establish data governance policy" (governance)
  - SPI: "Train quality engineers on ML interpretation" (training)
  - SPI: "Integrate prediction alerts into shift handover workflow" (workflow)

**Guidelines:**
- SPIs should be concrete and actionable, not generic ("improve culture" is too vague)
- Focus on the process changes that are essential for the ST to deliver value
- Consider training, governance, workflow integration, and organizational alignment
- SPIs are lightweight — they flag what needs to change, not how to change it

## Step 2.6: Example Enrichment (vendor references or published cases)

Enrich each Solution Template with concrete **practical examples**. The rendered trend report
needs proof points — "who has done this, what happened, here is the source". Today's trend
research surfaces quantitative claims from web signals, but not case-study evidence tied to a
specific ST. Step 2.6 closes that gap.

The enrichment source depends on `tips-project.json → study_mode` (captured in trend-scout
Phase 0 Step 0.8c). The field is optional; when absent, treat as `"open"`.

```bash
STUDY_MODE=$(jq -r '.study_mode // "open"' "${PROJECT_PATH}/tips-project.json")
```

**Skip condition.** If `study_mode == "vendor"` but no `vendor_source.portfolio_ref` resolves to
a readable portfolio project, log a WARNING and fall back to open-mode behavior for this run —
do not HALT. A misconfigured vendor project should still produce a report.

**Dispatch caps** (to bound latency and cost — enforce per ST):

| Mode | Dispatch budget per ST |
|------|-----------------------|
| vendor | max 2 `cogni-research:local-researcher` calls + max 2 `cogni-wiki:wiki-query` calls + plain JSON reads (unbounded) |
| open | max 1 `cogni-research:section-researcher` call with ≤ 4 sub-queries |

### 2.6.A: Vendor Mode — Source References from the Portfolio Corpus

Applies when `study_mode == "vendor"`. Zero open-web URLs are written — every `source_ref`
resolves inside `cogni-portfolio/{vendor_source.portfolio_ref}/`.

For each ST where the `solution_blueprint.building_blocks[]` contains any block with
`coverage ∈ {"covered", "partial"}`:

1. **Read `portfolio_grounding[]`.** Each entry is `{feature_slug, market_slug, does_echo, evidence_available}` — this
   is the feature×market mapping to search against. STs with empty `portfolio_grounding[]` (pure
   gap blueprints) receive an empty `vendor_references[]` and move on.

2. **Named customers** — for each `market_slug` in `portfolio_grounding[]`, read
   `cogni-portfolio/{portfolio_ref}/customers/{market_slug}.json`. Select `named_customers[]`
   entries whose industry or pain_points resonate with the ST's lead building-block capability.
   Prefer entries with higher `fit_score`. Emit one `vendor_references[]` entry per qualifying
   customer:

   ```json
   {
     "customer_name": "{named_customer.company_name}",
     "outcome_claim": "{derived 1-2 sentence outcome from named_customer.key_pain_points + ST.name}",
     "source": "customers",
     "source_ref": "customers/{market_slug}.json#named_customers[{index}]",
     "portfolio_grounding_entry_ref": "{feature_slug}--{market_slug}",
     "source_origin": "vendor",
     "publication_date": null
   }
   ```

3. **Proposition evidence** — for each `(feature_slug, market_slug)` pair, read
   `cogni-portfolio/{portfolio_ref}/propositions/{feature_slug}--{market_slug}.json` and scan
   `evidence[]`. Include entries tagged `source_origin == "vendor"` (vendor-authored proof
   points). When the tag is absent on older projects, include only entries whose `source_url`
   is empty (portfolio-internal only) — never web-sourced evidence.

4. **Uploaded collateral** — dispatch `cogni-research:local-researcher` once per ST against
   `cogni-portfolio/{portfolio_ref}/{vendor_source.case_study_uploads || "uploads/"}`. Build
   sub-questions from the ST name + lead building-block capability + investment theme name, e.g.:
   *"Which uploaded case studies describe an implementation of {ST.name} in {industry.subsector_en} and what outcome was reported?"*.
   Limit to max 4 sub-questions per dispatch. Each matching file becomes a `vendor_references[]`
   entry with `source: "uploads"` and `source_ref: "uploads/{filename}"`.

5. **Vendor wiki (optional)** — when `vendor_source.case_study_wiki` is set, dispatch
   `cogni-wiki:wiki-query` once per ST against that wiki path with the same sub-question style.
   Each hit becomes a `vendor_references[]` entry with `source: "wiki"` and
   `source_ref: "{wiki_path}#{page_slug}"`.

6. **Dedupe.** If the same underlying customer appears across sources (e.g., a customer entry
   plus an uploaded case study describing the same engagement), keep the richest entry —
   prefer `uploads` > `wiki` > `propositions` > `customers` when the engagement is confirmed by
   an actual case-study artifact; otherwise keep the `customers` entry for the structured metadata.

7. **Write `vendor_references[]` to the ST.** When no portfolio evidence matched, leave the
   array empty — the writer downstream will fall back to the plain capability prose for that ST
   (backward-compatible behavior).

### 2.6.B: Open Mode — Research Published Industry Case Studies

Applies when `study_mode == "open"` (explicitly set at Phase 0 or absent). This is the
dedicated case-study research pass that complements today's trend-signal research — the report's
"Why You" gains a `Referenzbeispiele` block of concrete industry implementations.

For each ST, dispatch **one** `cogni-research:section-researcher` call with ≤ 4 sub-queries
drawn from the templates below. The agent already handles market localization and parallel
search — do not reinvent that here.

**Query templates** (substitute `{st.name}`, `{lead_block.capability}`, `{industry.primary_en}`,
`{industry.subsector_en}`, localized variants from `tips-project.json → industry.*_de`, and
`{year_range}` = last 3 calendar years):

- `"{st.name}" "case study" {industry.subsector_en} {year_range}`
- `"{lead_block.capability}" implementation reference {industry.subsector_en} {year_range}`
- `"{st.name}" pilot results OR rollout OR deployment {industry.primary_en}`
- DACH localization (when `language == "de"` or `MARKET_REGION ∈ {"dach","de"}`): `"{st.name}" Referenz OR Kundenprojekt OR Umsetzung {industry.subsector_de}`

**Authority classification.** For each returned hit, classify `source_authority` by domain:

| Tier | Examples |
|------|----------|
| `tier-1` | Analyst firms (Gartner, Forrester, IDC), academic (.edu, Fraunhofer, arxiv), regulator (EUR-Lex, BSI, ENISA) |
| `tier-2` | Trade press (Handelsblatt, FT, Computerwoche), major vendor reference pages |
| `tier-3` | Community blogs, smaller vendor case pages |

**Citation diversity cap.** No more than 1 entry may share the same second-level domain — e.g.,
two hits from `cisco.com` collapse to the single strongest one. This prevents a single vendor's
reference library from dominating the ST's evidence.

**Target output.** 2–3 `published_cases[]` entries per ST when feasible. When the agent returns
fewer than 2 usable hits, keep what was found and emit an empty array if nothing usable was
returned — the writer downstream falls back to plain capability prose for that ST.

```json
{
  "vendor_or_customer": "{implementer_name}",
  "outcome": "{1-line outcome summary}",
  "source_url": "{url}",
  "source_authority": "tier-1|tier-2|tier-3",
  "publication_date": "{YYYY-MM if available, else null}",
  "source_origin": "third_party"
}
```

### 2.6.C: Write Results

After per-ST dispatch, update the in-memory `solution_templates[]` array and write
`tips-value-model.json`. The two arrays are mutually exclusive per ST — emit **either**
`vendor_references[]` (vendor mode) **or** `published_cases[]` (open mode), never both.

Skipped STs (no blueprint, no grounding) keep both arrays absent — downstream consumers treat
absence identically to empty.

### 2.6.D: Quality Gate

Log a WARNING (do not HALT) when:

- **Vendor mode**: > 30% of STs with a `covered` or `partial` lead block ended up with empty
  `vendor_references[]`. This usually means `customers/{market}.json` is thin or no case-study
  uploads exist — surface the gap so the user can enrich the portfolio before re-running.
- **Open mode**: > 30% of STs ended up with fewer than 2 `published_cases[]` entries.
- **Any mode**: a `source_ref` points outside the allowed corpus (vendor mode: outside
  `cogni-portfolio/{portfolio_ref}/`; open mode: not a URL). Acceptance criterion #2 depends on
  this invariant.

## Step 2.7: Re-Anchor Existing Solution Templates

Re-anchoring rebuilds solution blueprints on existing STs using **LLM solutioning intelligence**.
This is not a mechanical keyword-matching operation — it applies the same solutioning competence
as Steps 0.5.3 and 1.5, but to STs that already exist rather than generating new ones. The LLM
must reason about what each solution genuinely needs across B2B ICT taxonomy dimensions, drawing
on investment theme narratives, value chain context, and portfolio capabilities.

The reason this cannot be scripted: a "Smart Grid Digital Twin" solution doesn't just need "the
feature with 'digital twin' in the name." It needs IoT connectivity for sensor data, cloud
infrastructure for simulation workloads, AI/analytics for predictive models, and consulting for
organizational adoption. Only an LLM with solutioning expertise can compose this multi-dimensional
blueprint correctly.

### 2.7.0: Invocation Modes

Re-anchoring can be triggered in two ways:

1. **As part of a full Phase 2 run** — sequential, after Step 2.5, only when the user explicitly
   requests re-anchoring during an active Phase 2 workflow
2. **As an independent operation** — invoked via trigger phrases like "re-anchor solutions",
   "remap blueprints", "rebuild portfolio mapping", "re-anchor STs". When invoked independently,
   load Phase 0 data (portfolio context, value model) and jump directly to Step 2.7.1

**Scope parameter:**
- `all` (default) — re-anchor every ST in the value model
- Specific `st_id` list — re-anchor only the named STs (e.g., "re-anchor st-003, st-007, st-012")

### 2.7.1: Load Current State

1. Read `tips-value-model.json` to get the current `solution_templates` array and `investment_themes` array
2. Read `portfolio-context.json` from the TIPS project directory
   - **Requires v2.0+** — if absent or v1.0, abort with:
     > "Re-anchoring requires portfolio context v2.0 or later. Run `/bridge portfolio-to-tips`
     > first to export your current portfolio."
3. Read the B2B ICT taxonomy from `$CLAUDE_PLUGIN_ROOT/references/taxonomies/b2b-ict-portfolio.md`
4. If scope is specific ST IDs, filter to only those STs; otherwise process all
5. **Snapshot** each ST's current `solution_blueprint`, `portfolio_anchor`, and `portfolio_mapping`
   — these will be used for the change log in Step 2.7.5

### 2.7.2: Re-Analyze Building Blocks (LLM Solutioning)

This is the core step. For each ST in scope, the LLM performs a fresh solutioning analysis
to determine what building blocks the solution genuinely needs. **This must never be delegated
to a script, keyword matcher, or mechanical algorithm** — the value of this step is the LLM's
ability to reason about solution architecture in context.

For each ST:

1. Read the ST's `name`, `description`, `category`, `enabler_type`
2. Read the parent investment theme's `strategic_question` and `narrative` (via `investment_theme_ref`)
3. Read the linked value chains' narratives (via `linked_chains`) — the T→I→P stories that
   give context to why this solution exists
4. With this full context, determine from scratch:

   **a) Lead building block (exactly 1):**
   What is the primary capability this solution delivers? Which B2B ICT taxonomy category
   best describes it? This is the core delivery mechanism — the thing the customer is
   actually buying.

   **b) Supporting building blocks (1-2):**
   What technical layers does this solution require? Consider:
   - Software STs often need cloud infrastructure (Dim 4), connectivity (Dim 1)
   - Data-intensive STs need AI/analytics (Dim 6), data platforms (Dim 4)
   - Security-critical STs need security services (Dim 2)
   - Integration-heavy STs need application services (Dim 6)

   **c) Enabling building blocks (0-2):**
   What organizational or advisory prerequisites exist? Consider:
   - Process change → consulting (Dim 7)
   - Skills gap → training (Dim 7)
   - Governance need → compliance (Dim 2)
   - Infrastructure readiness → managed services (Dim 5)

5. Map each building block to the most specific taxonomy category (e.g., "6.6 AI, Data &
   Analytics", not just "Dimension 6"). Use `taxonomy_ref`, `taxonomy_name`, and
   `taxonomy_dimension` fields.

6. Target 2-5 building blocks total (same as initial generation). If you find yourself
   composing more than 5, the ST may be too broad.

### 2.7.3: Re-Match Against Current Portfolio

For each building block identified in 2.7.2, scan the portfolio context for matches:

1. For each building block:
   - Search `portfolio-context.json` features for semantic matches against the block's capability
   - Consider taxonomy dimension alignment (same dimension = higher priority)
   - Consider proposition DOES/MEANS language (does it echo the block's capability?)

2. Assess coverage:
   - Feature fully covers the block's capability → `coverage: "covered"`, populate `delivers`
   - Feature partially covers (some capabilities present, gaps remain) → `coverage: "partial"`,
     populate both `delivers` and `gaps`
   - No matching feature in the portfolio → `coverage: "gap"`, set `feature_slug` and
     `product_slug` to null

3. For matched blocks, populate:
   - `feature_slug` and `product_slug` from the matched feature
   - `delivers`: specific capabilities this feature provides for the block
   - `gaps`: specific capabilities the feature cannot provide (empty when fully covered)

### 2.7.4: Reassemble Blueprint and Derived Fields

1. Assemble the new `solution_blueprint` with building blocks from 2.7.3

2. Calculate `readiness` using the role-weighted formula:
   ```
   role_weight:    lead=1.0, supporting=0.7, enabling=0.4
   coverage_value: covered=1.0, partial=0.5, gap=0.0, unknown=0.5
   readiness_score = sum(coverage_value × role_weight) / sum(role_weight)
   ```

3. Populate `readiness` sub-fields: `covered_count`, `partial_count`, `gap_count`,
   `unknown_count`, `taxonomy_span`, `taxonomy_depth`

4. Derive `portfolio_anchor` from the lead building block:
   ```
   portfolio_anchor.feature_slug = lead.feature_slug
   portfolio_anchor.product_slug = lead.product_slug
   portfolio_anchor.investment_theme_needs_delivered = lead.delivers
   portfolio_anchor.investment_theme_needs_undelivered = lead.gaps
   ```

5. Update `portfolio_mapping`:
   - `feature_slug` and `product_slug` from lead block
   - `match_confidence`: `"high"` if lead is covered, `"medium"` if partial, `"low"` if weak,
     `"none"` if gap
   - `proposition_exists`: check if the matched feature has propositions in the context

6. Update `generation_mode` to `"re-anchored"` — this distinguishes from the original
   `"portfolio-anchored"` or `"abstract"` generation and tracks that a re-analysis occurred

7. If v3.0 context is available, re-check quality flags: when a matched proposition has
   `quality_assessment` with `market_specificity` or `differentiation` = `"fail"`, set
   `quality_flag: "quality_investment_needed"`

### 2.7.5: Generate Change Log

For each re-anchored ST, produce a change record comparing the snapshot from 2.7.1 with
the new values:

```json
{
  "st_id": "st-005",
  "st_name": "Smart Grid Digital Twin & Predictive Maintenance",
  "timestamp": "2026-03-14T15:30:00Z",
  "changes": {
    "lead_block_changed": true,
    "old_lead": {"taxonomy_ref": "5.4", "feature_slug": "monitoring-suite"},
    "new_lead": {"taxonomy_ref": "6.6", "feature_slug": "ai-analytics-engine"},
    "old_anchor": {"feature_slug": "monitoring-suite", "product_slug": "infrastructure-services"},
    "new_anchor": {"feature_slug": "ai-analytics-engine", "product_slug": "application-services"},
    "old_readiness": 0.45,
    "new_readiness": 0.72,
    "blocks_added": 1,
    "blocks_removed": 0,
    "blocks_remapped": 2,
    "coverage_upgrades": ["supporting:1.4 gap→covered", "enabling:7.2 unknown→partial"],
    "coverage_downgrades": []
  }
}
```

Append all change records to a `reanchor_log` array in `tips-value-model.json`. Each entry
includes a timestamp so multiple re-anchor runs are traceable. Do not overwrite prior log entries.

### 2.7.6: Report

Present the re-anchoring results in the same format as Step 0.5.6, showing old→new comparisons:

```markdown
## Re-Anchored Solution Templates

### {N} STs re-anchored | Avg readiness: {old_avg} → {new_avg}

**ST-005: Smart Grid Digital Twin & Predictive Maintenance** [RE-ANCHORED]
  Old anchor: monitoring-suite (infrastructure-services) → readiness 0.45
  New anchor: ai-analytics-engine (application-services) → readiness 0.72
  Blueprint: 4 building blocks across 4 taxonomy dimensions
    ● Lead:       AI, Data & Analytics (6.6) — ai-analytics-engine ✓ COVERED [was: monitoring-suite in 5.4]
    ◐ Supporting: 5G & IoT Connectivity (1.4) — iot-gateway ◐ PARTIAL [was: GAP]
    ● Supporting: Cloud-Native Platform (4.6) — k8s-platform ✓ COVERED [unchanged]
    ◐ Enabling:   Digital Transformation (7.2) — consulting-team ◐ PARTIAL [was: UNKNOWN]

**ST-009: Cross-Sektor Energie-Trading-Hub** [RE-ANCHORED]
  Old anchor: (none — was abstract) → readiness 0.00
  New anchor: system-integration-api (application-services) → readiness 0.55
  ...
```

Summary:
- STs re-anchored: {N} (of {total})
- Lead blocks changed: {N}
- Readiness improved: {N} | Degraded: {N} | Unchanged: {N}
- Coverage upgrades: {N} blocks (gap/unknown → covered/partial)
- New portfolio gaps: {N} blocks confirmed as gap
- Quality flags: {N} STs flagged with quality_investment_needed

### 2.7.7: Update tips-value-model.json

Write back the changes:
- Replace each re-anchored ST's `solution_blueprint`, `portfolio_anchor`, `portfolio_mapping`,
  `generation_mode`, and `quality_flag`
- Append to `reanchor_log` array (create if it doesn't exist)
- **Preserve unchanged fields**: `st_id`, `name`, `description`, `category`, `enabler_type`,
  `investment_theme_ref`, `linked_chains`, `foundation_dependencies`, `business_relevance`,
  `business_relevance_calculated`, `ranking_value`, `chain_scores`, `foundation_factor`,
  `portfolio_grounding`

### 2.7.8: Downstream Impact

After re-anchoring, check whether ranking has already been performed:

- If `ranking_value` is populated on any re-anchored ST:
  > "Blueprints have been re-anchored, which changes readiness scores. The BlueprintFactor
  > in the ranking formula may now produce different final scores. Consider re-running
  > Phase 4 (Rank & Visualize) to update rankings."

- If BR scoring has been done but ranking has not, note that `blueprint_factor` will be
  calculated correctly during the next ranking run — no immediate action needed.

- If neither scoring nor ranking has been done, no warning is needed.

## Step 3: Consolidate & Deduplicate

Because STs are now generated per investment theme rather than per chain, most deduplication happens
naturally. Still, review all generated STs and:
- Merge any remaining duplicates (especially cross-investment-theme STs that overlap)
- Ensure each ST has a unique, descriptive name
- Verify that every investment theme has at least 2 linked STs
- Verify that every value chain is covered by at least 1 ST (via its parent investment theme)
- Check that no ST is orphaned (linked to zero chains)

## Step 3.5: Define Success Metrics

For each Investment Theme, define 2-4 success Metrics — KPIs that measure whether the
investment theme's solutions are delivering expected value. Metrics make the business case tangible
and provide the basis for post-implementation tracking. Link metrics to specific value
chains where appropriate.

**For each Metric, define:**
- `metric_id`: Sequential identifier (met-001, met-002, ...)
- `name`: KPI name (e.g., "OEE Improvement %")
- `unit`: Measurement unit (e.g., "percentage", "hours", "EUR", "count")
- `direction`: `increase` | `decrease` — which direction indicates improvement
- `investment_theme_ref`: The investment theme this metric measures
- `linked_chains`: Which value chains this metric applies to (optional, for granularity)

**Example:**
- Investment Theme: "Smart Manufacturing & Supply Chain", Chain: "AI-Driven Quality Optimization"
  - Metric: "Defect rate reduction" (percentage, decrease)
  - Metric: "Mean time to defect detection" (hours, decrease)
  - Metric: "First-pass yield improvement" (percentage, increase)

**Guidelines:**
- Metrics should be measurable and specific to the industry context
- Avoid vanity metrics — focus on KPIs the customer already tracks or should track
- A single metric may apply to multiple chains within an investment theme (e.g., OEE spans several solution areas)
- Include both leading indicators (early signals) and lagging indicators (outcome measures)

## Step 4: Present to User

Present the Solution Templates grouped by Investment Theme:

```markdown
## Solution Templates by Investment Theme

### Investment Theme 1: Health & Nutrition Transformation (3 STs)
Strategic Question: How do we reformulate for the GLP-1-era consumer?

**ST-001: AI Personalization Platform for Health Products**
Chains: GLP-1 Portfolio Reformulation, Functional Ingredients Innovation
Category: software | Enabler: revenue_enablement | Urgency: near-term
Blueprint: 3 blocks | Readiness: 0.82
  ● Lead:       AI, Data & Analytics (6.6) — predictive-analytics ✓ COVERED
  ● Supporting: Cloud-Native Platform (4.6) — cloud-platform ✓ COVERED
  ◐ Enabling:   Business & Industry Consulting (7.3) — ◐ PARTIAL
Portfolio match: predictive-analytics (high confidence)
Propositions: 2 relevant (mid-market-dach: "Reduces MTTR by 60%...", enterprise-eu: "...")
> AI-driven product recommendations based on health profiles, GLP-1 medication,
> and dietary preferences.

**ST-002: Protein/Fiber Reformulation Framework**
Chains: GLP-1 Portfolio Reformulation
Category: process | Enabler: process_improvement | Urgency: immediate
Blueprint: 2 blocks | Readiness: 0.50
  ✗ Lead:       Business & Industry Consulting (7.3) — ✗ GAP
  ✗ Enabling:   Digital Transformation (7.2) — ✗ GAP
Portfolio match: none (PORTFOLIO GAP)
Propositions: —
> Systematic reformulation framework for protein- and fiber-rich product lines.

### Investment Theme 2: Regulatory Compliance & Sustainable Packaging (3 STs)
Strategic Question: How do we turn regulatory pressure into competitive advantage?
...
```

## Step 4.5: Suggest Collaterals

For each Solution Template, suggest relevant Collateral — supporting content that
strengthens the solution proposal. Collaterals are references to existing or recommended
assets, not generated content.

**For each Collateral, define:**
- `collateral_id`: Sequential identifier (col-001, col-002, ...)
- `name`: Descriptive title (e.g., "Predictive Maintenance ROI Case Study")
- `type`: `case-study` | `whitepaper` | `reference-architecture` | `demo` | `benchmark`
- `st_ref`: The parent Solution Template ID
- `status`: `exists` | `recommended` — whether the asset already exists or should be created

**Guidelines:**
- Suggest 1-2 collaterals per ST — keep the list actionable, not exhaustive
- Prioritize case studies and reference architectures over generic whitepapers
- Mark existing collaterals as `exists` only when a cogni-portfolio mapping confirms them
- Collaterals marked `recommended` are suggestions for future content creation

Report summary:
- Total STs generated (N portfolio-anchored + M abstract)
- Distribution by category and enabler type
- Portfolio matches vs gaps
- Path coverage (every path should have 1+ STs)
- Quality flags: N STs flagged with `quality_investment_needed` (list them with the
  specific quality dimensions that failed, so the user knows what to improve)
- **Blueprint readiness**: Average readiness score across all STs, distribution
  (N high-readiness ≥0.8, N medium 0.5-0.8, N low <0.5)
- **Taxonomy coverage**: Which B2B ICT dimensions appear across all blueprints,
  which have gaps. Example: "Solutions span 6 of 8 taxonomy dimensions. Gaps
  concentrated in Dim 2 (Security) and Dim 7 (Consulting)."

Ask: "These are the Solution Templates derived from your investment themes. Want to adjust
any before we move to Business Relevance scoring?"

## Output

Update `tips-value-model.json`:
- Add `solution_templates` array with all STs (each has `investment_theme_ref` and `linked_chains`)
- Add `solution_process_improvements` array with all SPIs
- Add `metrics` array with all success Metrics (each has `investment_theme_ref`)
- Add `collaterals` array with all Collateral items
- Update each investment theme's `solution_templates` field with linked ST IDs
- Update each value chain's `solution_templates` field with linked ST IDs
- Add `portfolio_gaps` array listing STs with no portfolio match

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"solutions-generated"`
- Add `"phase-2"` to `phases_completed`
- Record `solution_template_count`, `portfolio_matches`, `portfolio_gaps`
