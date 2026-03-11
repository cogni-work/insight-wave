---
name: setup
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

If a project already exists for the company, redirect to the `resume-portfolio` skill instead of creating a duplicate.

## Workflow

### 1. Gather Company Context

Collect four required fields:

- **Company name**: Legal or trading name
- **Description**: One-sentence summary of what the company does
- **Industry**: Primary industry sector (e.g., "Cloud Infrastructure", "B2B SaaS")
- **Products**: List of main products or services offered

If the user has provided some context already, extract what is available and ask only for missing fields.

**Language detection**: After collecting the four fields above, check if a `.workspace-config.json` file exists in the workspace root directory. If it contains a `language` field, lowercase the value and use it as the portfolio language (e.g., `"DE"` becomes `"de"`). If no workspace config exists or it has no `language` field, ask the user which language to use for generated content (default: `"en"`).

**Web research (optional)**: When the user provides a company URL or website, delegate to a subagent (Agent tool) to extract company description, industry, and product offerings from the company's public pages. This is especially useful when the user knows the company but hasn't articulated structured context yet. Present findings to the user for confirmation — never auto-populate without review.

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

Ask explicitly:
- Does this look right?
- Anything to add or correct?
- Happy with the project slug?

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
  uploads/
  output/
```

### 4. Write portfolio.json

After the script creates directories, write `portfolio.json` in the project root with the confirmed company context, including the `language` field. Follow the schema in `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md`.

### 5. Confirm and Guide Next Steps

Present the created project structure and suggest the full workflow. If the user has existing documents (product specs, market research, pitch decks, etc.), mention they can drop files into the `uploads/` folder and run the `ingest` skill to import data automatically.

1. (Optional) Drop existing documents into `uploads/` and run the `ingest` skill
2. Define products with the `products` skill
3. Add features to each product with the `features` skill
4. Discover target markets with the `markets` skill
5. Generate proposition messaging with the `propositions` skill
6. Define implementation plans and pricing with the `solutions` skill
7. Enrich with `compete` (competitor analysis) and `customers` (buyer profiles)
8. Verify web-sourced claims with the `verify` skill
8. Aggregate into messaging repository with the `synthesize` skill
9. Generate deliverables with the `export` skill

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

For complete entity schemas and naming conventions, consult `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md`.

## Important Notes

- Each project lives under `cogni-portfolio/<slug>/` in the workspace
- Multiple projects are supported (one per company or product line)
- If a project already exists, the init script returns `"status": "exists"` without overwriting
- The `updated` field in portfolio.json should be refreshed whenever entities change
- **Communication Language**: Read `portfolio.json` in the project root (or use the language determined during setup). If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
