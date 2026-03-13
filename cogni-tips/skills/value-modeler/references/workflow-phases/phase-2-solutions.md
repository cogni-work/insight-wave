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

## Step 0.5: Portfolio-Anchored Generation (when v2.0+ context exists)

This step runs **only** when `portfolio-context.json` has `schema_version` >= `"2.0"`. When the
context is absent or v1.0, skip directly to Step 1 (unchanged behavior).

Portfolio-anchored generation inverts the normal flow: instead of starting from themes and
imagining solutions, it starts from **existing products/features** and asks what each theme
needs that those features can deliver. This produces STs with high portfolio confidence by
construction.

### 0.5.1: Read Portfolio Context

Read `portfolio-context.json` from the TIPS project directory and extract:
- All products and their features (slugs, descriptions, categories)
- All propositions per feature (IS/DOES/MEANS, market slugs, evidence counts)
- Market relevance tags (`direct`, `industry`, `adjacent`)
- If v3.0: quality assessments per proposition (`market_specificity`, `differentiation`, `value_quantification`)

### 0.5.2: Match Features to Strategic Themes

For each feature in the portfolio context, use semantic analysis to determine which Strategic
Themes it could serve. Consider:

- **Description overlap**: Does the feature's description address the theme's strategic question?
- **Category alignment**: Does the feature's category (software, hardware, service) align with the theme's value chain domains?
- **Market-relevance filtering**: Only consider features that have at least one proposition in a `direct` or `industry` market. Features with only `adjacent` market propositions are deprioritized.
- **Proposition language**: Do any DOES/MEANS statements echo the theme's narrative or the needs of its value chains?

Produce a feature-theme match matrix before generating any STs.

### 0.5.3: Generate Portfolio-Anchored STs

For each feature-theme match, generate a Solution Template:

1. **Start from the feature** as the delivery mechanism — the ST describes what can be
   delivered using this feature's real capabilities
2. **Ask the grounding questions**:
   - "What does this theme need that this feature can deliver?" → becomes `theme_needs_delivered`
   - "What does this theme need that this feature cannot deliver?" → becomes `theme_needs_undelivered`
3. **Generate the ST** with these fields:
   - All standard ST fields (`st_id`, `name`, `description`, `category`, `enabler_type`, `theme_ref`, `linked_chains`, `foundation_dependencies`)
   - `generation_mode: "portfolio-anchored"` — marks this ST as feature-first
   - `portfolio_anchor`:
     ```json
     {
       "feature_slug": "predictive-analytics",
       "product_slug": "cloud-platform",
       "theme_needs_delivered": ["AI-driven quality prediction", "real-time sensor integration"],
       "theme_needs_undelivered": ["legacy MES integration", "operator training program"]
     }
     ```
   - `portfolio_mapping.match_confidence: "high"` — automatically high because the ST was generated FROM the feature
   - If the feature has propositions in the context, populate `portfolio_grounding` entries (same format as Step 2.5 in the original flow):
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

### 0.5.5: Reduce Abstract Targets

For each theme that received portfolio-anchored STs, reduce the target for Step 1 abstract
generation:

- **2+ anchored STs**: The theme may not need abstract STs at all. Still generate 1 abstract
  ST if the anchored STs don't fully cover the theme's strategic question (check whether
  `theme_needs_undelivered` items suggest a significant gap)
- **1 anchored ST**: Reduce the abstract target by 1 (e.g., from 2-4 to 1-3)
- **0 anchored STs**: No change — Step 1 runs at full capacity for this theme

### 0.5.6: Report

Present portfolio-anchored STs first, grouped by theme:

```markdown
## Portfolio-Anchored Solution Templates

### Theme 1: Smart Manufacturing & Supply Chain (2 anchored STs)

**ST-001: Predictive Quality Analytics Platform** [ANCHORED]
Feature: predictive-analytics (cloud-platform)
Delivers: AI-driven quality prediction, real-time sensor integration
Cannot deliver: legacy MES integration, operator training program
Quality: OK
> Deploy ML-based quality prediction using the existing predictive-analytics
> feature, integrated with production line sensor data.

**ST-002: Digital Twin Production Optimizer** [ANCHORED]
Feature: digital-twin-engine (cloud-platform)
Delivers: production line simulation, throughput optimization
Cannot deliver: physical sensor retrofit, brownfield integration
Quality: quality_investment_needed (market_specificity: fail)
> Simulate and optimize line throughput using the digital-twin-engine,
> grounded in existing DOES claims for mid-market manufacturing.
```

Then note which themes still need abstract STs:
```
Themes needing abstract STs in Step 1:
- Theme 3: Regulatory Compliance (0 anchored STs → full abstract generation)
- Theme 5: Sustainability & ESG (1 anchored ST → reduced target: 1-3 abstract STs)
```

## Step 1: Generate Solution Templates

> **Note:** If portfolio-anchored STs were generated in Step 0.5, adjust the target per
> theme — generate abstract STs only for themes or theme areas not covered by anchored STs.
> Themes with 2+ anchored STs may need only 0-1 abstract STs. Themes with 0 anchored STs
> use the full 2-4 target.

For each **Strategic Theme**, generate 2-4 Solution Templates using extended thinking.
Working at the theme level (rather than per-chain) naturally deduplicates — chains within
a theme share strategic direction, so a single ST often serves multiple chains.

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
- `theme_ref`: The primary Strategic Theme this ST belongs to
- `linked_chains`: Which value chains this ST addresses (can span multiple chains within the theme)
- `foundation_dependencies`: Which foundation candidates are prerequisites

**Generation guidelines:**
- Consider all value chains within the theme holistically — what enabler would address
  the theme's strategic question most directly?
- A single ST can address multiple chains within a theme (this is expected and desirable)
- Cross-theme STs are rare but allowed — if an ST genuinely serves two themes, link it
  to both but assign a primary `theme_ref`
- Prefer concrete over abstract — name specific technologies, platforms, methodologies
- Consider the project's industry context (automotive solutions differ from pharma)
- Use the chain's horizon alignment to set implementation urgency:
  - All-act chains → immediate implementation STs
  - Act-plan chains → near-term STs with phased rollout
  - Plan-observe chains → strategic initiative STs

**Target: 2-4 STs per theme → 8-20 total.** This range reflects that themes consolidate
what would otherwise be 15-25 STs spread across redundant paths. If you find yourself
generating >4 STs for a single theme, the theme may be too broad — revisit the Phase 1
split criteria.

## Step 2: Portfolio Mapping (if available)

If a cogni-portfolio project was discovered in Phase 0:

1. **Read all features** from `portfolio/features/*.json`
2. **For each ST**, find the best-matching feature by:
   - Keyword overlap between ST description and feature description
   - Category alignment (software ST → software feature)
   - Semantic similarity of the enabler to the feature's capability
3. **Assign match confidence:**
   - `high`: Clear 1:1 mapping, the feature directly enables this ST
   - `medium`: Partial overlap, the feature covers some aspects of the ST
   - `low`: Loose thematic connection only
   - `none`: No meaningful match — this ST represents a portfolio gap

4. **For high/medium matches**, also check for existing propositions and solutions:
   - Read `portfolio/propositions/{feature}--{market}.json` if exists
   - Read `portfolio/solutions/{feature}--{market}.json` if exists
   - Enrich the ST with IS/DOES/MEANS messaging and pricing data

5. **Enrich from Portfolio Propositions (v2.0 context):**

   When `portfolio-context.json` has `schema_version` = `"2.0"`, the propositions are
   already embedded in the context file under each feature. For high/medium matches:

   a. Read the `propositions` array from the matched feature in `portfolio-context.json`
   b. Filter to propositions from markets where `market_relevance` is `direct` or `industry`
   c. Use proposition language to ground the ST description:
      - The **DOES** statement provides advantage framing → incorporate into ST description
      - The **MEANS** statement provides business outcome language → inform ST justification
   d. Add a `portfolio_grounding` array to each ST:

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

   The `does_echo` captures the specific advantage claim from the portfolio that grounds
   this ST. `evidence_available` is `true` when `evidence_count` > 0 in the proposition.

   When v2.0 context is not available, fall back to reading proposition files directly
   from the portfolio directory (Step 4 above).

6. **Report portfolio gaps**: STs with `none` or `low` match confidence are worth
   flagging — they represent market opportunities not yet captured in the portfolio.

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

If no portfolio is discovered, set `portfolio_mapping` to `null` on all STs.

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

## Step 3: Consolidate & Deduplicate

Because STs are now generated per theme rather than per chain, most deduplication happens
naturally. Still, review all generated STs and:
- Merge any remaining duplicates (especially cross-theme STs that overlap)
- Ensure each ST has a unique, descriptive name
- Verify that every theme has at least 2 linked STs
- Verify that every value chain is covered by at least 1 ST (via its parent theme)
- Check that no ST is orphaned (linked to zero chains)

## Step 3.5: Define Success Metrics

For each Strategic Theme, define 2-4 success Metrics — KPIs that measure whether the
theme's solutions are delivering expected value. Metrics make the business case tangible
and provide the basis for post-implementation tracking. Link metrics to specific value
chains where appropriate.

**For each Metric, define:**
- `metric_id`: Sequential identifier (met-001, met-002, ...)
- `name`: KPI name (e.g., "OEE Improvement %")
- `unit`: Measurement unit (e.g., "percentage", "hours", "EUR", "count")
- `direction`: `increase` | `decrease` — which direction indicates improvement
- `theme_ref`: The Strategic Theme this metric measures
- `linked_chains`: Which value chains this metric applies to (optional, for granularity)

**Example:**
- Theme: "Smart Manufacturing & Supply Chain", Chain: "AI-Driven Quality Optimization"
  - Metric: "Defect rate reduction" (percentage, decrease)
  - Metric: "Mean time to defect detection" (hours, decrease)
  - Metric: "First-pass yield improvement" (percentage, increase)

**Guidelines:**
- Metrics should be measurable and specific to the industry context
- Avoid vanity metrics — focus on KPIs the customer already tracks or should track
- A single metric may apply to multiple chains within a theme (e.g., OEE spans several solution areas)
- Include both leading indicators (early signals) and lagging indicators (outcome measures)

## Step 4: Present to User

Present the Solution Templates grouped by Strategic Theme:

```markdown
## Solution Templates by Strategic Theme

### Theme 1: Health & Nutrition Transformation (3 STs)
Strategic Question: How do we reformulate for the GLP-1-era consumer?

**ST-001: AI Personalization Platform for Health Products**
Chains: GLP-1 Portfolio Reformulation, Functional Ingredients Innovation
Category: software | Enabler: revenue_enablement | Urgency: near-term
Portfolio match: predictive-analytics (high confidence)
Propositions: 2 relevant (mid-market-dach: "Reduces MTTR by 60%...", enterprise-eu: "...")
> AI-driven product recommendations based on health profiles, GLP-1 medication,
> and dietary preferences.

**ST-002: Protein/Fiber Reformulation Framework**
Chains: GLP-1 Portfolio Reformulation
Category: process | Enabler: process_improvement | Urgency: immediate
Portfolio match: none (PORTFOLIO GAP)
Propositions: —
> Systematic reformulation framework for protein- and fiber-rich product lines.

### Theme 2: Regulatory Compliance & Sustainable Packaging (3 STs)
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

Ask: "These are the Solution Templates derived from your Strategic Themes. Want to adjust
any before we move to Business Relevance scoring?"

## Output

Update `tips-value-model.json`:
- Add `solution_templates` array with all STs (each has `theme_ref` and `linked_chains`)
- Add `solution_process_improvements` array with all SPIs
- Add `metrics` array with all success Metrics (each has `theme_ref`)
- Add `collaterals` array with all Collateral items
- Update each theme's `solution_templates` field with linked ST IDs
- Update each value chain's `solution_templates` field with linked ST IDs
- Add `portfolio_gaps` array listing STs with no portfolio match

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"solutions-generated"`
- Add `"phase-2"` to `phases_completed`
- Record `solution_template_count`, `portfolio_matches`, `portfolio_gaps`
