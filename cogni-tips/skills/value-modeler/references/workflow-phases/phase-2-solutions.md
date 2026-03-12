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

## Step 1: Generate Solution Templates

For each **Strategic Theme**, generate 2-4 Solution Templates using extended thinking.
Working at the theme level (rather than per-chain) naturally deduplicates — chains within
a theme share strategic direction, so a single ST often serves multiple chains.

**Portfolio-grounded generation (when `portfolio-context.json` v2.0 exists):**
When an enriched portfolio context is available (check for `schema_version` = `"2.0"`),
ST descriptions should reference capability language from matched propositions. Specifically:
- Use DOES statements to frame the ST's advantage (what measurable improvement it delivers)
- Use MEANS statements to anchor the ST's business outcome (why the customer should care)
- The ST remains TIPS-native (solution-oriented), but is **grounded** in what the portfolio
  already articulates — this avoids generating STs in a vacuum

If no v2.0 context exists, generate STs using industry context alone (unchanged behavior).

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
- Total STs generated
- Distribution by category and enabler type
- Portfolio matches vs gaps
- Path coverage (every path should have 1+ STs)

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
