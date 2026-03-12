# Phase 0: Initialize & Load

## Objective

Load the trend-scout output, validate prerequisites, and discover optional integrations.

## Steps

### Step 1: Discover Project

Search the workspace for TIPS projects:

1. Look for `cogni-tips/*/tips-project.json` files
2. If multiple projects exist, list them and ask the user which one to model
3. If only one exists, confirm with the user

### Step 2: Load Trend-Scout Output

Read `.metadata/trend-scout-output.json` from the selected project.

**Validation gates:**
- `execution.workflow_state` must be `"agreed"` — the user must have completed candidate selection
- `tips_candidates.total` must be >= 20 (minimum viable set for relationship building)
- `tips_candidates.items` must contain candidates from at least 3 of the 4 dimensions

If validation fails, tell the user what's missing and suggest running `trend-scout` first.

### Step 3: Discover Industry Catalog (Optional)

Search for a matching industry catalog:

1. Read `industry.primary` and `industry.subsector` from the project config
2. Check for `cogni-tips/catalogs/{primary}/{subsector}/catalog.json`
3. If found, read it and report:
   - "Found {industry}/{subsector} catalog with {stats summary}. Catalog data will inform relationship building and solution generation."
   - Store catalog path for use in Phases 1 and 2
4. If not found: "No industry catalog found. You can create one later with `/tips-catalog init` to accumulate knowledge across pursuits."

### Step 4: Discover Portfolio (Optional)

Search the workspace for a cogni-portfolio project:

1. Look for `portfolio/portfolio.json` or `*/portfolio.json`
2. If found, read it and catalog:
   - Products and their features
   - Any existing markets, propositions, solutions
3. Report to the user: "Found portfolio with X products and Y features. I'll map Solution Templates to these where relevant."
4. If not found: "No portfolio found. Solution Templates will be standalone — you can connect them to a portfolio later."

### Step 5: Load Existing Value Model (Resume Support)

Check for `tips-value-model.json` in the project directory:

1. If found, load it and determine which phases are complete
2. Report progress and ask if the user wants to continue or restart
3. If not found, initialize a fresh value model

### Step 6: Confirm Configuration

Present to the user:

```
Project: {project name}
Industry: {industry/subsector}
Language: {language}
Candidates: {total} across {dimensions} dimensions
Catalog: {found with N entities / not found}
Portfolio: {found/not found}
```

Ask: "Ready to build the value model? I'll start by mapping relationship networks across your {total} trend candidates."

## Output

Create `.metadata/value-modeler-output.json`:

```json
{
  "version": "1.0.0",
  "project_id": "{project-slug}",
  "project_language": "{language}",
  "catalog_discovered": true|false,
  "catalog_path": "cogni-tips/catalogs/manufacturing/automotive" | null,
  "portfolio_discovered": true|false,
  "portfolio_path": "path/to/portfolio.json" | null,
  "candidate_count": 60,
  "execution": {
    "workflow_state": "initialized",
    "current_phase": 0,
    "phases_completed": ["phase-0"]
  }
}
```
