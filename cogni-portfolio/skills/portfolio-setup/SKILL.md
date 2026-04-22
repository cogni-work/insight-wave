---
name: portfolio-setup
description: |
  Initialize a new cogni-portfolio project with company context and directory structure.
  Use whenever the user mentions creating a portfolio, new portfolio project, setting up
  portfolio, "start portfolio planning", "new company", "new project", or wants to begin
  structuring their product/market messaging — even if they don't say "setup" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill
---

# Portfolio Project Setup

Initialize a cogni-portfolio project by capturing company context and creating the project directory structure.

## Core Concept

A portfolio project is the container for all downstream work — products, features, markets, propositions, competitors, and customers all live inside it. Setup captures the minimum viable company context (name, description, industry, products) and scaffolds the directory structure that every other skill depends on.

Getting this right matters because the company context in `portfolio.json` informs every downstream skill. A clear description and accurate industry help the products, markets, and propositions skills generate relevant, on-target output instead of generic filler. A few minutes of care here saves hours of correction later.

If a project already exists for the company (an existing `cogni-portfolio/<slug>/portfolio.json` matching the company), do **not** create a duplicate. Briefly acknowledge that the project exists and **dispatch the `portfolio-resume` skill via the Skill tool** so the user lands on the status dashboard instead of having to re-invoke a command. The two skills bridge to each other in both directions, so users can enter from either side and reach the right place.

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

1. **Project-local short-circuit.** If `{PROJECT_PATH}/taxonomy/template.md` exists, the project already owns its taxonomy — skip the bundled match entirely. Read the project-local template to display its type/dimensions/categories to the user for confirmation.
2. Otherwise, scan `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter for `industry_match` patterns
3. Evaluate matches against the full company context (industry + description + service areas), not just `company.industry`
4. If a template matches (e.g., a company offering managed IT services, cloud infrastructure, and consulting maps to `b2b-ict`), present it:
   - "Based on your company profile, the **B2B ICT Portfolio** template (8 dimensions, 57 service categories) is a good fit. Apply this template?"
5. If user confirms, add taxonomy to `portfolio.json` (schema unchanged)
6. If no template matches or user declines, skip — the portfolio works fine without a taxonomy template
7. **Customize path.** After confirming a bundled template (or hitting the "no match" case), **do not** just mention `portfolio-taxonomy` in passing — Step 5.4 below is where the ownership decision actually happens. That step presents the user with an explicit branch so customization isn't a thing they have to know to ask for.

### 5.4. Taxonomy Ownership Decision

The project now has a taxonomy *referenced* in `portfolio.json` (if Step 5 matched a bundled template). Before proceeding, decide how the project should *own* that taxonomy. This matters because:

- A **bundled** taxonomy lives in the plugin directory and changes when the plugin updates. That is the right default when the match is clean and the user has no intent to tweak categories, search patterns, or product skeleton.
- A **project-local** taxonomy lives in `{PROJECT_PATH}/taxonomy/` and is immune to plugin updates. That is the right default the moment the user wants to rename a category, add an industry-specific dimension, or tweak the web-search patterns used during scan.

Skipping this decision here and letting users "find out later that they needed to customize" is exactly how scan results end up mis-classified against a taxonomy that doesn't fit the business.

#### Branch A — Step 5 already short-circuited on an existing project-local taxonomy

`{PROJECT_PATH}/taxonomy/template.md` was detected in Step 5.1. Display the existing taxonomy's type, dimension count, and category count for confirmation, note that it is project-local (survives plugin updates), and continue to Step 5.5. No ownership prompt — the project already owns its taxonomy.

#### Branch B — Step 5 matched a bundled template

Present this choice via `AskUserQuestion` with four options:

| Option | Label | What happens |
|---|---|---|
| `keep-bundled` *(default)* | Use the bundled **{template name}** template as-is | No action. Future plugin updates to this taxonomy will flow through automatically. Proceed to Step 5.5. |
| `clone` | Clone into the project so edits survive plugin updates | Dispatch `cogni-portfolio:portfolio-taxonomy` in `clone` mode with `{template-type}` pre-selected. The skill copies all 7 canonical taxonomy files into `{PROJECT_PATH}/taxonomy/` and updates `portfolio.json` with `taxonomy.source_path: "taxonomy/"` and `taxonomy.cloned_from: "{template-type}"`. On return, proceed to Step 5.5. |
| `author` | Author a custom taxonomy from scratch | Dispatch `cogni-portfolio:portfolio-taxonomy` in `author` mode. Interactive construction of all 7 canonical files from a blank slate. Returns to Step 5.5 on completion. Use when the bundled match is only approximate. |
| `import` | Import an external taxonomy (JSON, spreadsheet, consultancy model) | Dispatch `cogni-portfolio:portfolio-taxonomy` in `import` mode. Returns to Step 5.5 on completion. |

#### Branch C — Step 5 matched nothing, or the user declined the bundled match

Present this choice via `AskUserQuestion` with four options:

| Option | Label | What happens |
|---|---|---|
| `pick-bundled` | Pick from the 8 bundled templates anyway | Return to Step 5 and present all 8 templates via `AskUserQuestion`; when the user picks one, come back here with Branch B. |
| `author` *(recommended)* | Author a custom taxonomy | Dispatch `cogni-portfolio:portfolio-taxonomy` in `author` mode. Returns to Step 5.5 on completion. |
| `import` | Import an external taxonomy | Dispatch `cogni-portfolio:portfolio-taxonomy` in `import` mode. Returns to Step 5.5 on completion. |
| `skip` | Skip taxonomy — portfolio works without one | No taxonomy set. Downstream scan will be unavailable; products/features can still be authored manually. Proceed to Step 5.5. |

#### Return semantics

After any dispatch to `portfolio-taxonomy` returns, continue at Step 5.5. If the dispatch produced a project-local taxonomy (`clone`, `author`, or `import`), `portfolio-scan` Phase 0 Step 5a will pick it up automatically via the existing resolver precedence — no additional wiring needed.

### 5.5. Ask About Additional Data Sources

Before moving to scanning or next steps, ask the user whether they have additional documents that could enrich the portfolio. This is the natural moment — the project structure exists, `uploads/` is ready, and ingesting documents before scanning gives downstream skills more context to work with.

> "Do you have any **internal documents** I should work with? Strategy decks, pitch decks, product specs, pricing models, competitive analyses, or similar material can give me a much richer starting point. Drop them in `uploads/` and I'll extract products, features, and strategic context from them."

If the user provides documents, recommend running the `ingest` skill before proceeding to scan — ingested context makes every downstream skill sharper.

If the user has no documents or wants to skip, proceed to Step 5.6.

### 5.6. Portfolio Scan (when URL and taxonomy available)

If a company URL/domain was captured in Step 1 AND a taxonomy template was selected in Step 5, offer to scan.

#### 5.6a — Offer the scan

> "You have a taxonomy template ({template name}, {dimension count} dimensions, {category count} categories) and a company domain ({domain}). I can scan their public websites now to discover and classify their service portfolio. This typically takes a few minutes. Proceed?"

If the user declines or no URL was provided, skip to Step 6 — they can run `portfolio-scan` separately later.

If no taxonomy template was selected in Step 5, skip — scanning requires a taxonomy to classify against. Mention: "Portfolio scanning requires a taxonomy template. You can apply one later and run `portfolio-scan` separately."

#### 5.6b — Ask the consolidation-mode question here, before launching scan

The scan's Phase 7 behaviour depends on a **consolidation mode**. The choice determines how many features land in `features/` and whether per-SKU detail is kept at the feature layer or pushed to `solutions/`. This is an executive-level portfolio decision, not a scan implementation detail — so the user must make the call **before** scan starts, not hidden inside scan's Phase 0.

Present the choice via `AskUserQuestion` with these options. Populate `{category count}` from the taxonomy chosen in Step 5 (57 for `b2b-ict`, matching numbers for the other templates).

| Option | Label | Description |
|---|---|---|
| `consolidate` | One feature per SKU (default) | Richest detail — every discovered SKU becomes its own feature with its own proposition / pricing / competitor view. Expect 100–300+ features for a large corporate. Pick this for proposition / sales-enablement workflows. |
| `category-aggregation` | One feature per taxonomy category | Feature grid mirrors the taxonomy you just picked (≤{category count} features). Per-SKU detail (providers, delivery stacks, regions) is preserved for `solutions/`, not at the feature layer. Pick this for consolidation / benchmarking / executive-view workflows. |
| `shadow` | Stage for review | Offerings land in `research/scan-candidates/` for later review — `features/` is untouched. Pick this when scanning a partner / reference provider you don't own. |
| `research-only` | Report only | Phase 6 report only — no feature writes. Pick this when scanning a competitor or prospect whose offerings must not enter your feature set. |

Record the selection as `CONSOLIDATION_MODE` in the session environment before dispatching scan, and also note it back to the user so they can confirm before the scan kicks off a multi-minute run:

> "Scanning {company} in `{mode}` mode — {one-line consequence for this mode}. Starting now."

#### 5.6c — Dispatch scan with the mode pre-answered

Invoke the `portfolio-scan` skill with `CONSOLIDATION_MODE` set in the environment. Scan's Phase 0 Step 6 detects the pre-set value and **skips its own mode prompt** — the user has already made the call here. The portfolio project, `portfolio.json`, and taxonomy are already in place, so scan's Phase 0 will otherwise resolve immediately.

### 6. Confirm and Guide Next Steps

Present the created project structure and suggest next steps.

**If portfolio scan ran in Step 5.6:** Products and features have been discovered and imported.

1. Refine products with the `products` skill (positioning, pricing tier)
2. Refine features with the `features` skill (IS-layer descriptions)
3. Discover target markets with the `markets` skill
4. Generate proposition messaging with the `propositions` skill
5. Define implementation plans and pricing with the `solutions` skill
6. Enrich with `compete` and `customers`
7. Verify web-sourced claims with the `verify` skill
8. Generate deliverables with the `communicate` skill

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
