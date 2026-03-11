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

For each TIPS path, generate 1-3 Solution Templates using extended thinking:

**For each ST, define:**
- `st_id`: Sequential identifier (st-001, st-002, ...)
- `name`: Descriptive name (3-7 words)
- `description`: What it does and how (1-2 sentences)
- `category`: `software` | `hardware` | `service` | `hybrid` | `process`
- `enabler_type`: `process_improvement` | `capability_building` | `risk_mitigation` | `revenue_enablement`
- `linked_paths`: Which paths this ST addresses (can be multiple)
- `foundation_dependencies`: Which foundation candidates are prerequisites

**Generation guidelines:**
- A single ST can address multiple paths (shared enablers are valuable — they signal high ROI)
- Prefer concrete over abstract — name specific technologies, platforms, methodologies
- Consider the project's industry context (automotive solutions differ from pharma)
- Use the path's horizon alignment to set implementation urgency:
  - All-act paths → immediate implementation STs
  - Act-plan paths → near-term STs with phased rollout
  - Plan-observe paths → strategic initiative STs

**Target: 15-25 Solution Templates total.** Fewer means the analysis is too coarse;
more means insufficient consolidation.

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

5. **Report portfolio gaps**: STs with `none` or `low` match confidence are worth
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

Review all generated STs and:
- Merge STs that are essentially the same enabler approached from different paths
- Ensure each ST has a unique, descriptive name
- Verify that every path has at least 1 linked ST
- Check that no ST is orphaned (linked to zero paths)

## Step 3.5: Define Success Metrics

For each TIPS path, define 2-4 success Metrics — KPIs that measure whether the solution
path is delivering expected value. Metrics make the business case tangible and provide
the basis for post-implementation tracking.

**For each Metric, define:**
- `metric_id`: Sequential identifier (met-001, met-002, ...)
- `name`: KPI name (e.g., "OEE Improvement %")
- `unit`: Measurement unit (e.g., "percentage", "hours", "EUR", "count")
- `direction`: `increase` | `decrease` — which direction indicates improvement
- `linked_paths`: Which TIPS paths this metric measures

**Example:**
- Path: "AI-Driven Quality Optimization"
  - Metric: "Defect rate reduction" (percentage, decrease)
  - Metric: "Mean time to defect detection" (hours, decrease)
  - Metric: "First-pass yield improvement" (percentage, increase)

**Guidelines:**
- Metrics should be measurable and specific to the industry context
- Avoid vanity metrics — focus on KPIs the customer already tracks or should track
- A single metric may apply to multiple paths (e.g., OEE spans several solution areas)
- Include both leading indicators (early signals) and lagging indicators (outcome measures)

## Step 4: Present to User

Present the Solution Templates grouped by enabler type:

```markdown
## Solution Templates

### Process Improvements (8 templates)

**ST-001: Predictive Quality Analytics Platform**
Paths: AI-Driven Quality Optimization, Smart Manufacturing Scale-up
Category: software | Urgency: immediate
Portfolio match: predictive-analytics (high confidence)
> Deploy ML-based quality prediction integrated with production line sensors,
> reducing defect rates through real-time anomaly detection.

**ST-002: Regulatory Compliance Automation Suite**
Paths: Compliance-Driven Automation
Category: software | Urgency: near-term
Portfolio match: none (PORTFOLIO GAP)
> Automate EU AI Act audit trails and documentation requirements,
> turning compliance burden into competitive advantage.

### Capability Building (5 templates)
...

### Risk Mitigation (3 templates)
...

### Revenue Enablement (4 templates)
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

Ask: "These are the Solution Templates derived from your trend paths. Want to adjust
any before we move to Business Relevance scoring?"

## Output

Update `tips-value-model.json`:
- Add `solution_templates` array with all STs
- Add `solution_process_improvements` array with all SPIs
- Add `metrics` array with all success Metrics
- Add `collaterals` array with all Collateral items
- Update each path's `solution_templates` field with linked ST IDs
- Add `portfolio_gaps` array listing STs with no portfolio match

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"solutions-generated"`
- Add `"phase-2"` to `phases_completed`
- Record `solution_template_count`, `portfolio_matches`, `portfolio_gaps`
