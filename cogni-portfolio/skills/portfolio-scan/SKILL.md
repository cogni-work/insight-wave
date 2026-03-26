---
name: portfolio-scan
description: |
  Discover what services a company offers by scanning their websites, classify findings
  against a portfolio taxonomy template, and import them as features and products into
  the portfolio data model. Use when user asks to scan, map, or research a company's
  service portfolio, product offerings, or solution catalog. Triggers on "scan [company]
  portfolio", "what does [company] sell", "map [company] services", "competitor portfolio",
  "vendor assessment", "ict scan", "[company] service offerings", "portfolio scan".
  Also trigger when the user wants to populate a portfolio project from public web data
  rather than from uploaded documents (that's the ingest skill). Requires an existing
  cogni-portfolio project (run setup first).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Task
---

# Portfolio Scan

## Core Concept

This skill is the **web discovery counterpart to `ingest`**. Where `ingest` populates a portfolio from uploaded documents, `scan` populates it from a company's public websites — discovering subsidiaries, scanning their domains for service offerings, classifying everything against the portfolio's taxonomy template, and importing the results as portfolio entities.

The scan produces two outputs:
1. A **portfolio report** (`research/{slug}-portfolio.md`) — structured markdown covering all taxonomy dimensions and categories with evidence-linked offerings
2. **Portfolio entities** (products and features) — ready for downstream use in propositions, solutions, and packages

The taxonomy template maps to the data model via the **product template**: dimensions become products, discovered offerings become features. See the template's `product-template.md` for the full mapping.

**Pipeline position:**
```
setup → scan (web) → features (refine) → products (organize) → propositions → ...
setup → ingest (docs) → features (refine) → products (organize) → propositions → ...
```

## Prerequisites

A cogni-portfolio project must exist for this company. If `cogni-portfolio/{slug}/portfolio.json` does not exist, instruct the user to run `cogni-portfolio:setup` first.

**Setup integration:** This skill is typically invoked from `portfolio-setup` Step 5.5 when a company URL and taxonomy template are available. It also works standalone after setup. When invoked from setup, Phase 0 prerequisites are already satisfied.

The `company.products` array in `portfolio.json` (if present) provides initial orientation but will be superseded by scan's structured discovery.

**Note (zsh compatibility):** Do NOT combine variable assignment with `$()` command substitution and pipes in a single command. Use separate Bash tool calls.

---

## Workflow

### Phase 0: Prerequisite Check & Template Resolution

1. Identify the target company from the user's request (or ask via AskUserQuestion)
2. Derive `COMPANY_SLUG` (kebab-case):
   ```bash
   echo "Company Name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
   ```
3. Locate the existing portfolio project:
   ```bash
   find . -path "*/cogni-portfolio/*/portfolio.json" -type f 2>/dev/null
   ```
4. Read `portfolio.json` and extract `slug`, `company.name`
5. **Resolve taxonomy template:**
   - Check `portfolio.json` for `taxonomy.type` field
   - If set (e.g., `"b2b-ict"`), load template from `$CLAUDE_PLUGIN_ROOT/templates/{taxonomy.type}/template.md`
   - If absent, scan `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter for `industry_match` patterns that match `company.industry`
   - If multiple matches or no match, present available templates via AskUserQuestion
   - Once resolved, set `TEMPLATE_PATH=$CLAUDE_PLUGIN_ROOT/templates/{type}`
6. Set environment variables:

| Variable | Source | Example |
|----------|--------|---------|
| COMPANY_NAME | `portfolio.json` → `company.name` | `Deutsche Telekom` |
| COMPANY_SLUG | `portfolio.json` → `slug` | `deutsche-telekom` |
| PROJECT_PATH | Directory containing `portfolio.json` | `/path/to/cogni-portfolio/deutsche-telekom` |
| OUTPUT_FILE | `{PROJECT_PATH}/research/{COMPANY_SLUG}-portfolio.md` | |
| TEMPLATE_PATH | `$CLAUDE_PLUGIN_ROOT/templates/{type}` | `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict` |
| TEMPLATE_TYPE | `portfolio.json` → `taxonomy.type` | `b2b-ict` |
| LANGUAGE | `portfolio.json` → `language` (default: "en") | `de` |

7. Read the template files needed for this scan:
   - `${TEMPLATE_PATH}/template.md` — taxonomy definition (dimensions, categories)
   - `${TEMPLATE_PATH}/search-patterns.md` — web search queries
   - `${TEMPLATE_PATH}/delivery-unit-rules.md` — entity inclusion/exclusion
   - `${TEMPLATE_PATH}/cross-category-rules.md` — dual assignments
   - `${TEMPLATE_PATH}/product-template.md` — taxonomy→data model mapping
   - `${TEMPLATE_PATH}/report-template.md` — output format

8. Create research directories lazily:
   ```bash
   mkdir -p "${PROJECT_PATH}/research/.logs"
   mkdir -p "${PROJECT_PATH}/research/.metadata"
   ```

**If no portfolio project exists:** Stop and tell the user: "No portfolio project found for {company}. Run `cogni-portfolio:setup` first to create the project structure."

---

### Phase 1: Company Discovery

Search for the target company and its affiliated entities. See `${TEMPLATE_PATH}/search-patterns.md` for the full set of WebSearch queries (Phase 1 section).

Extract the parent company, subsidiaries, business units, consulting arms, field services entities, and industry-vertical brands with their web domains.

See `${TEMPLATE_PATH}/delivery-unit-rules.md` for inclusion/exclusion criteria. The guiding principle: when in doubt, include — Phase 3 research will naturally return nothing if an entity isn't relevant.

**Subsidiary discovery depth matters.** A scan that only covers the main domain will miss entire product lines that live on subsidiary websites. Run at minimum these searches:
1. `"{COMPANY_NAME}" subsidiaries` and `"{COMPANY_NAME}" Tochtergesellschaften` (if LANGUAGE=de)
2. `"{COMPANY_NAME}" brands portfolio companies`
3. `site:{parent_domain} "powered by" OR "a company of" OR "part of"`
4. For system houses / VARs / resellers: search for their managed services brand, cloud brand, and security brand separately — these companies often operate service arms under different domains

**Minimum discovery targets:** Aim for at least 3 distinct domains for companies with >5,000 employees, at least 2 for companies with >1,000 employees. If you find only the parent domain, explicitly search for `"{COMPANY_NAME}" managed services brand` and `"{COMPANY_NAME}" cloud services subsidiary` before concluding there are no subsidiaries.

#### Phase 1 Output Schema

Store discovered entities in structured format for downstream phases:

```json
{
  "company_name": "{company}",
  "parent_domain": "{domain}",
  "subsidiaries": [
    {
      "name": "{entity}",
      "domain": "{domain}",
      "type": "ict_delivery|consulting|field_services|industry_vertical|regional|digital",
      "docs_subdomains": [],
      "search_priority": "high"
    }
  ]
}
```

---

### Phase 1.5: User Confirmation & Validation

**MANDATORY:** Before proceeding to Phase 2, validate and present discovered delivery units.

#### Pre-checks (automated, before showing user)

Run these 3 checks silently and fix issues before presenting:

1. **Subsidiary count match:** Domain list count >= entities discovered in Phase 1. If missing, search for their domains.
2. **Domain completeness:** Each entity has a resolvable domain. Probe for missing ones.
3. **Docs subdomain probe:** For each primary domain, check for `docs.*`, `help.*` subdomains.

#### Present Discovery Summary

Use `AskUserQuestion` to present the validated entities:

```markdown
## Discovered Delivery Units for {COMPANY_NAME}

| # | Entity | Domain | Type | Include? |
|---|--------|--------|------|----------|
| 1 | {entity} | {domain} | {type} | Y |
| ... | ... | ... | ... | ... |

**Missing any subsidiaries?** Common entity types to check:
- Consulting/advisory subsidiaries
- On-site/field services
- Industry-specific brands (healthcare, automotive, etc.)
- Regional delivery units
```

**If user selects "Add more entities":**
1. Ask for entity names or domains
2. Search for each to discover domain
3. Re-present updated list
4. Repeat until confirmed (max 3 iterations)

**If user selects "Confirmed - proceed":** Lock the delivery unit list and proceed to Phase 2.

---

### Phase 2: Provider Profile Discovery (Dimension 0)

Search for provider business metrics within discovered domains. See `${TEMPLATE_PATH}/search-patterns.md` for the search queries and category mapping (Phase 2 section).

Map findings to the provider profile categories defined in the taxonomy template (Dimension 0).

---

### Phase 3: Portfolio Discovery (Service Dimensions)

Use the `portfolio-web-researcher` agent for parallel, domain-scoped web research. Each agent searches one domain across all service categories.

#### Step 3.1: Prepare Domain List

Extract discovered domains from Phase 1 into a list. Include both primary domains AND any docs/help subdomains discovered in Phase 1.5 — these often contain detailed technical product pages that the main marketing site lacks.

```text
DOMAINS = [
  {"domain": "{domain}", "provider_unit": "{entity}"},
  {"domain": "docs.{domain}", "provider_unit": "{entity} (docs)"},
  ...
]
```

#### Step 3.2: Invoke portfolio-web-researcher Agents (Parallel)

**Invoke ALL domain agents in a SINGLE message to enable parallel execution.**

For each domain, invoke the `portfolio-web-researcher` agent:

```text
Task(
  subagent_type="cogni-portfolio:portfolio-web-researcher",
  description="Portfolio research for {provider_unit}",
  prompt="Execute domain-scoped portfolio research.

PROJECT_PATH={PROJECT_PATH}
COMPANY_NAME={COMPANY_NAME}
DOMAIN={domain}
PROVIDER_UNIT={provider_unit}
TEMPLATE_PATH={TEMPLATE_PATH}
LANGUAGE={LANGUAGE}

Execute all service category searches and return compact JSON. NO PROSE."
)
```

#### Step 3.3: Parse Agent Responses

Each agent returns compact JSON (~200 chars):

```json
{"ok":true,"d":"{domain}","u":"{unit}","s":{"ex":51,"ok":48},"o":{"tot":56,"cur":45,"emg":8,"fut":3},"log":"research/.logs/portfolio-web-research-{domain-slug}.json"}
```

#### Step 3.4: Load Full Results from Log Files

Read detailed offerings from each agent's log file:

```text
${PROJECT_PATH}/research/.logs/portfolio-web-research-{domain-slug}.json
```

#### Step 3.5: Verify All Domains Were Researched

After all agents complete, verify that **every discovered domain** produced a log file:

```bash
for domain_slug in {list-of-all-domain-slugs}; do
  test -f "${PROJECT_PATH}/research/.logs/portfolio-web-research-${domain_slug}.json" && echo "OK: ${domain_slug}" || echo "MISSING: ${domain_slug}"
done
```

This is a critical checkpoint — if any domain is missing, the scan will have blind spots for that entire delivery unit. Missing domains typically mean the agent wasn't dispatched (check Step 3.2) or silently failed.

**If any log files are missing:**
1. Check whether the agent was actually invoked for that domain in Step 3.2
2. Retry the missing domain(s) individually
3. Do NOT proceed to Phase 4 until all discovered domains have log files

**If an agent returns `{"ok":false,...}`:** Retry that domain individually. After 2 failures, log the domain as unreachable and proceed — but note the gap in the report.

---

### Phase 4: Offering Aggregation

Aggregate offerings from all agent log files.

#### Step 4.1: Load All Log Files

Log file completeness was already verified in Phase 3.5.

For each domain, read the log file and extract offerings.

#### Step 4.2: Merge Offerings by Category

Combine offerings from all domains, grouped by category ID. See [references/scan-entity-schema.md](references/scan-entity-schema.md) for the 11-field offering schema, Service Horizon definitions, and the offering-to-feature mapping.

### Phase 4.5: Cross-Category Entity Resolution

After merging, analyze each offering for multi-category fit. See `${TEMPLATE_PATH}/cross-category-rules.md` for the detection rules and dual-category assignment patterns.

---

### Phase 5: Discovery Status Assignment

For each taxonomy category, assign a **Discovery Status**:

| Status | Meaning | Action |
|--------|---------|--------|
| Confirmed | Provider offers this service (evidence found) | Populate entity table |
| Not Offered | No evidence found for this category | Mark as "No offerings found" |
| Emerging | Announced or pilot status (not yet GA) | Note in Horizon column |
| Extended | Provider-specific variant beyond standard taxonomy | Capture separately |

Extended discoveries should not exceed ~10-15 additional entities beyond the standard categories.

---

### Phase 6: Report Generation

Create the portfolio report at `${PROJECT_PATH}/research/${COMPANY_SLUG}-portfolio.md`.

Use the template from `${TEMPLATE_PATH}/report-template.md` for the complete output structure. Include:

- Header with generation date and analyzed domains
- Service Horizons and Discovery Status legends
- All dimensions and categories from the taxonomy
- Full entity tables with 11 columns
- Cross-Cutting Attributes section

See `${TEMPLATE_PATH}/template.md` for category definitions.

#### Update Project Metadata

**After generating the report**, derive the `status_summary` counts by scanning the actual report content — do not estimate or pre-compute them. Count the occurrences of each `[Status: X]` tag in the generated markdown to ensure the metadata matches the report exactly. The four counts must sum to the total number of categories in the taxonomy (e.g., 57 for b2b-ict).

Write portfolio metadata to `research/.metadata/scan-output.json`:

```json
{
  "version": "1.0.0",
  "company_name": "{COMPANY_NAME}",
  "company_slug": "{COMPANY_SLUG}",
  "created": "{ISO_TIMESTAMP}",
  "skill": "cogni-portfolio:scan",
  "template_type": "{TEMPLATE_TYPE}",
  "output_file": "research/{COMPANY_SLUG}-portfolio.md",
  "domains_analyzed": ["domain1.com", "domain2.com"],
  "dimensions_covered": 8,
  "categories_total": 57,
  "status_summary": {
    "confirmed": 0,
    "not_offered": 0,
    "emerging": 0,
    "extended": 0
  }
}
```

---

### Phase 7: Portfolio Import

Map discovered offerings to the portfolio data model using the product template. This bridges the research output into actionable entities that downstream skills (propositions, solutions, packages) can build on.

See `${TEMPLATE_PATH}/product-template.md` for the taxonomy-to-data-model mapping, default product definitions, and JSON examples.

#### Step 7.1: Map Offerings to Features

For each confirmed offering, generate a feature entity. The template maps:
- Offering Name → `name` and `slug` (kebab-case)
- Category ID → `taxonomy_mapping.category_id`
- Dimension → `taxonomy_mapping.dimension` (first digit of category ID)
- Horizon → `taxonomy_mapping.horizon` and `readiness` (`current`→`ga`, `emerging`→`beta`, `future`→`planned`)

See [references/scan-entity-schema.md](references/scan-entity-schema.md) for the complete offering-to-feature field mapping.

**Feature description quality (IS-layer):** The `description` field is an IS-layer statement — it describes the mechanism of WHAT the offering is, not what it achieves. Feature descriptions flow directly into downstream proposition generation, so quality here prevents rework later. Each description must:
- Be **20-35 words** (not shorter — a 10-word description lacks the specificity downstream skills need)
- Describe the **mechanism** — what the offering technically IS and how it works, not what outcome it delivers
- Avoid **outcome verbs** (reduces, enables, ensures, improves, optimizes) — those belong in the DOES layer
- Avoid **parity adjectives** (robust, innovative, cutting-edge, best-in-class, seamless, holistic) — these are empty claims
- Include the **provider's specific implementation** or differentiator, not a generic category description

**Example — good:** "Multi-tenant Kubernetes platform on Open Telekom Cloud with automated GitOps deployment pipelines, Istio service mesh, and BSI C5-attested container registry for regulated workloads."

**Example — bad:** "Cloud-native platform enabling modern application deployment." (too short, outcome verb, no mechanism)

#### Step 7.2: Map Dimensions to Products

If no products exist in the portfolio, create one product per active dimension using the default product definitions from the template. If products already exist, ask the user to assign each feature to an existing product.

#### Step 7.3: Present Mapping for Confirmation

Present proposed entities for user review (same pattern as the `ingest` skill):

```markdown
## Proposed Portfolio Entities

### Products (new)
| # | Slug | Name | Offerings | Action |
|---|------|------|-----------|--------|
| 1 | connectivity-services | Connectivity Services | 7 | Create |

### Features
| # | Slug | Name | Product | Readiness | Taxonomy | Action |
|---|------|------|---------|-----------|----------|--------|
| 1 | managed-sd-wan | Managed SD-WAN Pro | connectivity-services | ga | 1.1 WAN Services | Create |
| 2 | sase-gateway | SASE Gateway | connectivity-services | ga | 1.2 SASE | Create |
| ... | ... | ... | ... | ... | ... | ... |
```

Allow the user to:
- **Approve all** — create all proposed entities
- **Select individually** — approve, edit, or skip each
- **Edit before creating** — modify fields before writing

#### Step 7.4: Write Entities and Sync

Before writing, check for pre-existing feature files in `features/`. If any exist from a prior scan or manual creation, skip them unless the user explicitly asks to overwrite. This prevents stale features (which may lack taxonomy_mapping or readiness) from contaminating the output.

For each confirmed entity:
1. Write product JSON to `products/{slug}.json` (if new products created)
2. Write feature JSON to `features/{slug}.json` (skip if file already exists)
3. Set `created` to today's date
4. Include `"source_file": "research/{COMPANY_SLUG}-portfolio.md"` for traceability
5. Assign `sort_order` to each feature following the value-to-utility spectrum: customer-facing value features get low numbers (10, 20, 30...), infrastructure/utility features get high numbers (70+). Use increments of 10 to leave room for insertions. This controls display ordering in the dashboard and reports.

After writing, sync the portfolio:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/sync-portfolio.sh "${PROJECT_PATH}"
```

#### Step 7.5: Set Taxonomy in portfolio.json

If not already set, update `portfolio.json` to include the taxonomy reference:

```json
{
  "taxonomy": {
    "type": "{TEMPLATE_TYPE}",
    "version": "3.7",
    "dimensions": 8,
    "categories": 57,
    "source": "cogni-portfolio/templates/{TEMPLATE_TYPE}/template.md"
  }
}
```

---

## Quality Requirements

- **Domain restriction — strict enforcement:** Only search within discovered company domains. The Link column in every offering table row MUST point to a page on one of the `domains_analyzed` domains. Never use Wikipedia, analyst sites (Gartner, ISG, Forrester), news sites, partner vendor sites (aws.amazon.com, cloud.google.com), or any other external domain as a Link value. If you cannot find a direct source page on the company's own domain for an offering, use the closest company page that references the capability and note the limitation — but never substitute an external URL.
- **Evidence-based:** Every offering must link to a source page (Domain + Link columns required)
- **Complete coverage:** Include all dimensions and categories from the taxonomy
- **Full entity schema:** Capture all 11 fields per offering where available
- **Discovery Status:** Mark each category with Confirmed/Not Offered/Emerging/Extended
- **Service Horizons:** Classify each offering as Current/Emerging/Future
- **Mark gaps:** Use "No offerings found" for empty categories with [Status: Not Offered]

## Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| COMPANY_NAME | Target company name | `Deutsche Telekom` |
| COMPANY_SLUG | From portfolio.json slug | `deutsche-telekom` |
| PROJECT_PATH | Path to portfolio project dir | `/path/to/cogni-portfolio/deutsche-telekom` |
| OUTPUT_FILE | Path to portfolio markdown | `${PROJECT_PATH}/research/${COMPANY_SLUG}-portfolio.md` |
| TEMPLATE_PATH | Path to taxonomy template dir | `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict` |
| TEMPLATE_TYPE | Taxonomy type identifier | `b2b-ict` |
| LANGUAGE | ISO 639-1 from portfolio.json | `de` |
