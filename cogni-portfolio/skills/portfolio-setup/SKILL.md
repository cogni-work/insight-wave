---
name: portfolio-setup
description: |
  Initialize a new cogni-portfolio project with company context and directory structure.
  Use whenever the user mentions creating a portfolio, new portfolio project, setting up
  portfolio, "start portfolio planning", "new company", "new project", or wants to begin
  structuring their product/market messaging — even if they don't say "setup" explicitly.
---

# Portfolio Project Setup

Initialize a cogni-portfolio project by capturing company context and creating the project directory structure.

## Core Concept

A portfolio project is the container for all downstream work — products, features, markets, propositions, competitors, and customers all live inside it. Setup captures the minimum viable company context (name, description, industry, products) and scaffolds the directory structure that every other skill depends on.

Getting this right matters because the company context in `portfolio.json` informs every downstream skill. A clear description and accurate industry help the products, markets, and propositions skills generate relevant, on-target output instead of generic filler. A few minutes of care here saves hours of correction later.

If a project already exists for the company, redirect to the `portfolio-resume` skill instead of creating a duplicate.

## Workflow

### 1. Gather Company Context (Data-First)

The goal is to fill four fields (company name, description, industry, products) with minimal questions. Read available data first, then ask only for what's missing.

#### Step 1a: Silent reads (before asking anything)

- **Workspace config**: Check if `.workspace-config.json` exists in the workspace root. If it contains a `language` field, lowercase it and use as the portfolio language (e.g., `"DE"` → `"de"`).
- **Conversation context**: Extract any company info the user already mentioned (name, URL, industry, what they sell).
- **Uploads**: Scan `uploads/` for existing documents (strategy decks, lean canvases, pitch decks). Their presence means the user has data you can work with.

#### Step 1b: Ask what data is available (one question, not four)

Instead of asking for name, description, industry, and products separately, ask what the user can share:

> "To get started, what can you share? A **company website URL** is ideal — I can extract most of what I need from it. **Documents** (strategy decks, lean canvases, pitch decks) in `uploads/` also work great. Or just tell me the **company name** and I'll work from there."

If the user already provided a URL or company name in their initial message, skip this question and proceed directly to Step 1c.

#### Step 1c: Extract context from the data source provided

- **URL provided →** delegate to a subagent (Agent tool) immediately to extract company name, description, industry sector, and broad service areas from the company's public pages. Store the company domain for use in Step 5.5. Do NOT attempt detailed product discovery or feature-level analysis — that is the job of the full portfolio scan in Step 5.5.
- **Documents in uploads/ →** scan them for company context (name, description, industry, products). A strategy deck or lean canvas often contains all four fields.
- **Canvas file →** extract via canvas mapping (the `portfolio-canvas` skill handles this, but you can extract company-level context directly).
- **Just a name (no URL, no documents) →** fall back to asking for description, industry, and products individually. This is the last resort, not the default path.

#### Step 1d: State what you found

Present your findings as testable assumptions: "From your website, I see Acme Cloud Services is a cloud infrastructure company offering X, Y, Z. Correct me if any of this is off."

#### Step 1e: Ask only for what's missing

If web research or documents filled name, description, and industry, don't re-ask — just confirm. Only ask for fields that no data source could answer. If no language was detected from workspace config, ask which language to use for generated content (default: `"en"`).

### 2. Review with User

Present the gathered context as a summary for confirmation before creating anything:

| Field | Value |
|---|---|
| Company | Acme Cloud Services |
| Description | Cloud infrastructure management for mid-market SaaS |
| Industry | Cloud Infrastructure |
| Products | Cloud Platform, Monitoring Suite |
| Proposed slug | `acme-cloud` |
| Language | `de` (from workspace config) |

The slug is derived from the company name in kebab-case — keep it short and recognizable (e.g., "Acme Cloud Services" -> `acme-cloud`).

Ask: "Correct anything that's off, or confirm to proceed."

Iterate until the user confirms. They know their business best.

### 3. Create Project Structure

Run the init script to create the directory structure:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/project-init.sh "<workspace-dir>" "<project-slug>"
```

The workspace directory is the user's current working directory. The script creates:

```
cogni-portfolio/<project-slug>/
  products/
  features/
  markets/
  propositions/
  solutions/
  competitors/
  customers/
  context/
  uploads/
  output/
```

### 4. Write portfolio.json

After the script creates directories, write `portfolio.json` in the project root with the confirmed company context, including the `language` field. Follow the schema in `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md`.

### 5. Taxonomy Template Selection (Optional)

Match the company to a portfolio taxonomy template using all available context — industry field, company description, and broad service areas from web research (if Step 1 included web research). This is more reliable than matching on an industry keyword alone.

1. Scan `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter for `industry_match` patterns
2. Evaluate matches against the full company context (industry + description + service areas), not just `company.industry`
3. If a template matches (e.g., a company offering managed IT services, cloud infrastructure, and consulting maps to `b2b-ict`), present it:
   - "Based on your company profile, the **B2B ICT Portfolio** template (8 dimensions, 57 service categories) is a good fit. Apply this template?"
4. If user confirms, add taxonomy to `portfolio.json` (schema unchanged)
5. If no template matches or user declines, skip — the portfolio works fine without a taxonomy template

### 5.5. Portfolio Scan (when URL and taxonomy available)

If a company URL/domain was captured in Step 1 AND a taxonomy template was selected in Step 5, offer to scan:

> "You have a taxonomy template ({template name}) and a company domain ({domain}). I can scan their public websites now to discover and classify their service portfolio. This typically takes a few minutes. Proceed?"

If the user confirms, invoke the `portfolio-scan` skill. The portfolio project, `portfolio.json`, and taxonomy are already in place, so scan's Phase 0 will resolve immediately.

If the user declines or no URL was provided, skip to Step 6 — they can run `portfolio-scan` separately later.

If no taxonomy template was selected in Step 5, skip — scanning requires a taxonomy to classify against. Mention: "Portfolio scanning requires a taxonomy template. You can apply one later and run `portfolio-scan` separately."

### 6. Confirm and Guide Next Steps

Present the created project structure and suggest next steps.

**If portfolio scan ran in Step 5.5:** Products and features have been discovered and imported.

1. Refine products with the `products` skill (positioning, pricing tier)
2. Refine features with the `features` skill (IS-layer descriptions)
3. Discover target markets with the `markets` skill
4. Generate proposition messaging with the `propositions` skill
5. Define implementation plans and pricing with the `solutions` skill
6. Enrich with `compete` and `customers`
7. Verify web-sourced claims with the `verify` skill
8. Aggregate with the `synthesize` skill
9. Generate deliverables with the `export` skill

**If scan did not run:** Two paths to populate the portfolio:

- **From documents**: Drop files in `uploads/` and run `ingest`
- **From the web**: Run `scan` to discover and classify offerings

Then continue with downstream skills above.

## Data Model Overview

The portfolio data model has six entity types:

| Entity | Storage | Key Concept |
|---|---|---|
| Product | `products/{slug}.json` | Named offering that bundles features |
| Feature (IS) | `features/{slug}.json` | Market-independent capability (belongs to a product) |
| Market | `markets/{slug}.json` | Target segment with TAM/SAM/SOM |
| Proposition | `propositions/{feat}--{mkt}.json` | Feature x Market = DOES + MEANS |
| Solution | `solutions/{feat}--{mkt}.json` | Implementation plan + pricing tiers per proposition |
| Competitor | `competitors/{feat}--{mkt}.json` | Per-proposition competitive landscape |
| Customer | `customers/{mkt}.json` | Per-market ideal buyer profile |
| Claims | `cogni-claims/claims.json` | Web-sourced claim verification registry |

For complete entity schemas and naming conventions, consult `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md`.

## Important Notes

- Each project lives under `cogni-portfolio/<slug>/` in the workspace
- Multiple projects are supported (one per company or product line)
- If a project already exists, the init script returns `"status": "exists"` without overwriting
- The `updated` field in portfolio.json should be refreshed whenever entities change
- **Communication Language**: Read `portfolio.json` in the project root (or use the language determined during setup). If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
