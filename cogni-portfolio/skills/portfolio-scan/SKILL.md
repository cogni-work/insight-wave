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

**Plugin root resolution.** Bash invocations below resolve the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}` — the first call works whether or not the harness injects `$CLAUDE_PLUGIN_ROOT`. Keep the inline form in every call; do not strip it.

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
5. **Resolve taxonomy template** (project-local wins over bundled):
   - **Step 5a — project-local check.** If `${PROJECT_PATH}/taxonomy/template.md` exists, the project owns its taxonomy. Set `TEMPLATE_PATH="${PROJECT_PATH}/taxonomy"` and proceed. `portfolio.json` typically records this with `taxonomy.source_path: "taxonomy/"` but the directory check is the source of truth — a present directory always wins.

     **Pre-flight validation.** Project-local taxonomies are user-editable and can drift into scan-breaking shapes silently (malformed category ids, categories without matching search patterns, missing product skeleton). Before Phase 1 dispatches 100+ web searches, validate:

     ```bash
     bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/validate-taxonomy.sh" "${PROJECT_PATH}"
     ```

     The script returns `{"success": true, "data": {...}}` on pass and exits 0. On failure it prints `{"success": false, "error": "...", "data": {"checks": [...]}}` and exits 1 — when this happens, show the failed checks to the user, tell them to run `cogni-portfolio:portfolio-taxonomy` (or hand-fix the pointed-to file, then revalidate), and **stop the scan** without starting Phase 1. Bundled templates (Step 5b) skip this step — they are shape-safe by construction.
   - **Step 5b — bundled fallback.** If no project-local taxonomy exists:
     - If `portfolio.json` has `taxonomy.type` (e.g. `"b2b-ict"`), load `$CLAUDE_PLUGIN_ROOT/templates/{taxonomy.type}/template.md`
     - If absent, scan `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter for `industry_match` patterns that match `company.industry`
     - If multiple matches or no match, present available templates via `AskUserQuestion`
     - Once resolved, set `TEMPLATE_PATH=$CLAUDE_PLUGIN_ROOT/templates/{type}`
   - If the user wants to customize their taxonomy (add/rename categories, tweak search patterns), direct them to the `cogni-portfolio:portfolio-taxonomy` skill before running the scan — that skill clones a bundled template into `${PROJECT_PATH}/taxonomy/` so edits survive plugin updates.
6. **Select consolidation mode:** The scan produces a structured report (Phase 6) regardless of mode. What differs is what Phase 7 does with the discovered offerings — and, consequentially, **how many features end up in `features/`**. See [references/consolidation-modes.md](references/consolidation-modes.md) for the full rationale and when to pick each mode.

   > **Feature-count grain differs sharply by mode.** `consolidate` writes one feature per discovered SKU (often 100–300+ for a large corporate portfolio); `category-aggregation` writes one feature per populated taxonomy category (≤57 for b2b-ict). If the user expects the feature grid to mirror the taxonomy they just confirmed, that is `category-aggregation`.

   **Check for a pre-set mode first.** If `CONSOLIDATION_MODE` is already set in the environment (caller is `portfolio-setup` Step 5.6c or another upstream skill that asked the user before dispatch), **skip the prompt entirely** and honour the pre-set value — the user has already made this call once; do not ask again. Validate the pre-set value is one of `consolidate | shadow | research-only | category-aggregation`; on an unrecognised value, fall through to the prompt rather than erroring.

   If `CONSOLIDATION_MODE` is unset (the skill was invoked directly, not via `portfolio-setup`), present this choice via `AskUserQuestion` with four options:

   | Mode | Feature count | Phase 7 behaviour | Pick when… |
   |---|---|---|---|
   | `consolidate` *(default)* | One per SKU (often 100–300+ for large corporates) | Map offerings → features, dedupe against existing `features/*.json`, write merges and new features | Scanning the portfolio's own company and you want per-SKU granularity in `features/` (each SKU can carry its own proposition / pricing / competitor view downstream) |
   | `shadow` | Zero in `features/` — staged under `research/scan-candidates/` | Map offerings → candidate JSON files under `research/scan-candidates/{COMPANY_SLUG}/` — `features/` is untouched | You want to review proposed features before committing them; scanning a reference / partner provider |
   | `research-only` | Zero | Stop after the Phase 6 report — no feature writes, no candidate files | Scanning a competitor, prospect, or any non-self company whose offerings must not enter the feature set |
   | `category-aggregation` | ≤ taxonomy size (≤57 for b2b-ict, one per populated category) | Group staged candidates by `taxonomy_mapping.category_id` and write one category-grained feature per populated category. Delivery-stack variants are pushed into `research/scan-solutions-draft.json` for downstream solution seeding. | Consolidation / benchmarking scans where the feature count should mirror the taxonomy shape rather than each provider offering. Per-stack detail (OTC / AWS / GCP / on-prem) is preserved for `solutions/`, not kept as feature-level variants. |

   Record the selection as `CONSOLIDATION_MODE` (default `consolidate` if the user dismisses the prompt). The choice is persisted into `scan-output.json` in Phase 6 so downstream dashboards and any "promote candidates" utility know how the scan was run.

7. Set environment variables:

| Variable | Source | Example |
|----------|--------|---------|
| COMPANY_NAME | `portfolio.json` → `company.name` | `Deutsche Telekom` |
| COMPANY_SLUG | `portfolio.json` → `slug` | `deutsche-telekom` |
| PROJECT_PATH | Directory containing `portfolio.json` | `/path/to/cogni-portfolio/deutsche-telekom` |
| OUTPUT_FILE | `{PROJECT_PATH}/research/{COMPANY_SLUG}-portfolio.md` | |
| TEMPLATE_PATH | `$CLAUDE_PLUGIN_ROOT/templates/{type}` | `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict` |
| TEMPLATE_TYPE | `portfolio.json` → `taxonomy.type` | `b2b-ict` |
| LANGUAGE | `portfolio.json` → `language` (default: "en") | `de` |
| CONSOLIDATION_MODE | Step 6 selection | `consolidate` \| `shadow` \| `research-only` \| `category-aggregation` |

8. Read the template files needed for this scan:
   - `${TEMPLATE_PATH}/template.md` — taxonomy definition (dimensions, categories)
   - `${TEMPLATE_PATH}/search-patterns.md` — web search queries
   - `${TEMPLATE_PATH}/provider-unit-rules.md` — entity inclusion/exclusion
   - `${TEMPLATE_PATH}/cross-category-rules.md` — dual assignments
   - `${TEMPLATE_PATH}/product-template.md` — taxonomy→data model mapping
   - `${TEMPLATE_PATH}/report-template.md` — output format

9. Create research directories lazily:
   ```bash
   mkdir -p "${PROJECT_PATH}/research/.logs"
   mkdir -p "${PROJECT_PATH}/research/.metadata"
   ```

**If no portfolio project exists:** Stop and tell the user: "No portfolio project found for {company}. Run `cogni-portfolio:setup` first to create the project structure."

---

### Phase 1: Company Discovery

Search for the target company and its affiliated entities. See `${TEMPLATE_PATH}/search-patterns.md` for the full set of WebSearch queries (Phase 1 section).

Extract the parent company, subsidiaries, business units, consulting arms, field services entities, and industry-vertical brands with their web domains.

See `${TEMPLATE_PATH}/provider-unit-rules.md` for which organizational units count as in-scope **provider units** (subsidiaries, practice areas, acquired products, regional entities). A provider unit is a scoping filter for Phase 3, not a data entity — it does not get its own JSON file. When in doubt, include — Phase 3 returns nothing if a unit has no relevant offerings.

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

**MANDATORY:** Before proceeding to Phase 2, validate and present discovered provider units.

#### Pre-checks (automated, before showing user)

Run these 3 checks silently and fix issues before presenting:

1. **Subsidiary count match:** Domain list count >= entities discovered in Phase 1. If missing, search for their domains.
2. **Domain completeness:** Each entity has a resolvable domain. Probe for missing ones.
3. **Docs subdomain probe:** For each primary domain, check for `docs.*`, `help.*` subdomains.

#### Present Discovery Summary

Use `AskUserQuestion` to present the validated entities:

```markdown
## Discovered Provider Units for {COMPANY_NAME}

*A provider unit is any organizational unit we will scan independently (subsidiary, BU, practice, brand, acquired product). Confirming this list locks Phase 3's domain fan-out.*

| # | Entity | Domain | Type | Include? |
|---|--------|--------|------|----------|
| 1 | {entity} | {domain} | {type} | Y |
| ... | ... | ... | ... | ... |

**Missing any subsidiaries?** Common entity types to check:
- Consulting/advisory subsidiaries
- On-site/field services
- Industry-specific brands (healthcare, automotive, etc.)
- Regional provider units
```

**If user selects "Add more entities":**
1. Ask for entity names or domains
2. Search for each to discover domain
3. Re-present updated list
4. Repeat until confirmed (max 3 iterations)

**If user selects "Confirmed - proceed":** Lock the provider unit list and proceed to Phase 2. Also persist the confirmed list as a skeleton `provider_units` array for the Phase 6 metadata write (see Phase 6 below) — one object per included unit with `{name, domain, type, included: true}`. This records the Phase-1.5 decision for later diagnosis; Phase 7.6 will enrich each entry with a `feature_count`.

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

This is a critical checkpoint — if any domain is missing, the scan will have blind spots for that entire provider unit. Missing domains typically mean the agent wasn't dispatched (check Step 3.2) or silently failed.

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
  "version": "1.3.0",
  "company_name": "{COMPANY_NAME}",
  "company_slug": "{COMPANY_SLUG}",
  "created": "{ISO_TIMESTAMP}",
  "skill": "cogni-portfolio:scan",
  "template_type": "{TEMPLATE_TYPE}",
  "consolidation_mode": "{CONSOLIDATION_MODE}",
  "output_file": "research/{COMPANY_SLUG}-portfolio.md",
  "domains_analyzed": ["domain1.com", "domain2.com"],
  "dimensions_covered": 8,
  "categories_total": 57,
  "status_summary": {
    "confirmed": 0,
    "not_offered": 0,
    "emerging": 0,
    "extended": 0
  },
  "provider_units": [
    {"name": "T-Systems MMS", "domain": "t-systems-mms.com", "type": "ict_delivery", "included": true, "feature_count": 12}
  ],
  "dedupe_summary": {
    "merged_into_existing": 0,
    "collapsed_among_candidates": 0,
    "written_new": 0,
    "legacy_duplicates_flagged": 0,
    "soft_duplicates_deferred": 0
  }
}
```

**`consolidation_mode` semantics** (added in v1.3.0; `category-aggregation` added in v1.4.0):

- `consolidate` — Phase 7 ran the full import+dedupe path; `dedupe_summary` counters are meaningful.
- `shadow` — Phase 7 produced candidate JSON files under `research/scan-candidates/{COMPANY_SLUG}/` but did **not** touch `features/`. `dedupe_summary` counters are all zero except `written_new` may reflect the candidate file count if useful to dashboards — by convention leave them at zero and rely on a filesystem count of the shadow directory instead.
- `research-only` — Phase 7 was skipped entirely. `dedupe_summary` counters are all zero. The report is the only deliverable.
- `category-aggregation` — Phase 7 skipped the per-offering dedupe agent (Steps 7.4–7.5) and ran the Step 7.6 Branch F aggregation path instead. `dedupe_summary` reports `written_new` = the number of populated taxonomy categories and all other counters = 0. Per-stack detail is recorded in `research/scan-solutions-draft.json` for the `solutions/` skill to consume. Dashboards must read `written_new` under this mode as "one feature per populated category", not as a dedupe outcome.

Consumers reading v1.2.0 or earlier must treat absent `consolidation_mode` as `"consolidate"` (that was the only behaviour the skill offered before v1.3.0).

**`provider_units` semantics** (added in v1.2.0):

- One entry per provider unit the user confirmed in Phase 1.5. Skeleton fields (`name`, `domain`, `type`, `included`) are written when the user locks the list; `feature_count` is enriched at Phase 7.6 after dedupe (`feature_count` = total new + merged features whose `_source_offering.domain` matches the unit's domain or docs-subdomains).
- This array is **diagnostic, not authoritative** — if Phase 7 is interrupted, `feature_count` may be missing or partial. Rely on `features/*.json` `source_lineage` for the canonical mapping.
- Consumers reading v1.0.0 or v1.1.0 files must treat absent `provider_units` as "not measured", not as "zero units".

**Counter semantics for `dedupe_summary`** (populated in Phase 7.6 — see below):

- `merged_into_existing` — accepted Table A merges (`candidate_to_existing`); the candidate enriched an existing feature instead of becoming its own file.
- `collapsed_among_candidates` — accepted Table B collapses (`candidate_to_candidate`); two or more candidates merged into one before any file was written.
- `written_new` — fresh feature files created by branches C and D (unclustered candidates plus user-flipped "Keep as new" rows).
- `legacy_duplicates_flagged` — Table E `existing_to_existing` clusters detected this run. Informational only — these are not candidates and are not written by scan; they are surfaced for the `features` Quality Completion Gate to resolve.
- `soft_duplicates_deferred` — branch E writes (deferred Table C rows persisted with `lineage_status.flagged_as: soft_duplicate_pending_review`).

**Sum invariant:** `merged_into_existing + collapsed_among_candidates + written_new + soft_duplicates_deferred` equals the number of candidates staged at Step 7.3 (`feature-candidates.json`). `legacy_duplicates_flagged` does **not** participate in the sum — legacy duplicates are existing-to-existing pairs, not candidates.

**Schema versioning:** This block was added in `scan-output.json` v1.1.0. Consumers reading older v1.0.0 files must treat the absence of `dedupe_summary` as "not measured", not as zero.

---

### Phase 7: Portfolio Import

Map discovered offerings to the portfolio data model using the product template. This bridges the research output into actionable entities that downstream skills (propositions, solutions, packages) can build on.

Unlike earlier versions of this skill, Phase 7 **never writes a feature file before running dedupe**. Mapped offerings become in-memory *candidates*, get pooled with existing `features/*.json` by the `feature-deduplication-detector` agent, and only then either (a) merge into an existing stable feature, (b) collapse against another candidate, or (c) get written as a new feature. This preserves stable slugs for downstream entities (propositions, solutions, dashboards) and prevents re-scans from accumulating near-duplicate files.

See `${TEMPLATE_PATH}/product-template.md` for the taxonomy-to-data-model mapping, default product definitions, and JSON examples.

#### Phase 7 Mode Branching

Branch on `CONSOLIDATION_MODE` (selected in Phase 0) **before** any mapping work. See [references/consolidation-modes.md](references/consolidation-modes.md) for the full rationale.

- **`research-only`** — **Skip Phase 7 entirely.** Do not run Steps 7.1–7.7. Tell the user: "Scan complete in `research-only` mode — report at `${OUTPUT_FILE}`. No features were created or modified." Then stop the skill.
- **`shadow`** — Run Steps 7.1, 7.2 (**categorize only — do not create products in `portfolio.json`**), and a modified Step 7.3 that writes candidate JSONs to `research/scan-candidates/${COMPANY_SLUG}/{slug}.json` instead of the staging file. **Skip Steps 7.4–7.7** — no dedupe, no `features/` writes, no `portfolio.json` taxonomy update. Tell the user: "Scan complete in `shadow` mode — N candidate files under `research/scan-candidates/${COMPANY_SLUG}/`. To adopt a candidate into your portfolio today, copy its JSON into `features/{slug}.json` and run `cogni-portfolio:features` to normalise it. A first-class promote flow inside the `features` skill is tracked as a follow-on issue — it will land in a later release."
- **`consolidate`** — Run Steps 7.1 through 7.7 as documented below. This is today's full-import behaviour.
- **`category-aggregation`** — Run Steps 7.1, 7.2, and 7.3 as documented. **Skip Steps 7.4 and 7.5** (no per-offering dedupe agent — aggregation by category supersedes per-offering similarity). Then run Step 7.6 **Branch F only** (the aggregation write path), which operates on the full staging list instead of per-resolution branches A–E, followed by Step 7.7 as-is (taxonomy update). After the aggregation write, tell the user: "Scan complete in `category-aggregation` mode — N category-grained features written to `features/`, M delivery-stack seeds recorded in `research/scan-solutions-draft.json` for the `solutions/` skill to bootstrap per-stack solution entities."

Shadow candidates use the same feature JSON shape as production features **plus** two diagnostic fields documented in [references/consolidation-modes.md](references/consolidation-modes.md):

```json
{
  "slug": "aws-managed-services",
  "product_slug": "cloud-services",
  "name": "AWS Managed Services",
  "purpose": "...",
  "description": "...",
  "taxonomy_mapping": { "dimension": 4, "category_id": "4.1", "...": "..." },
  "readiness": "ga",
  "source_file": "research/{COMPANY_SLUG}-portfolio.md",
  "created": "<today>",
  "_shadow_candidate": true,
  "_source_offering": {
    "domain": "t-systems.com",
    "link": "https://www.t-systems.com/...",
    "usp": "..."
  }
}
```

Create the shadow directory lazily: `mkdir -p "${PROJECT_PATH}/research/scan-candidates/${COMPANY_SLUG}"`.

#### Step 7.1: Map Offerings to Features

For each confirmed offering, generate a feature entity. The template maps:
- Offering Name → `name` and `slug` (kebab-case)
- Category ID → `taxonomy_mapping.category_id`
- Dimension → `taxonomy_mapping.dimension` (first digit of category ID)
- Horizon → `taxonomy_mapping.horizon` and `readiness` (`current`→`ga`, `emerging`→`beta`, `future`→`planned`)

See [references/scan-entity-schema.md](references/scan-entity-schema.md) for the complete offering-to-feature field mapping.

**Feature purpose (strongly recommended):** Draft a `purpose` field (5-12 words) for each feature — a customer-readable statement answering "what is this feature FOR?". Derive purpose from the offering's web copy, focusing on the problem it solves or capability it provides. Purpose sits between name (label) and description (mechanism) and is used in architecture diagrams, dashboards, and customer narratives.

**Feature description quality (IS-layer):** The `description` field is an IS-layer statement — it describes the mechanism of WHAT the offering is, not what it achieves. Feature descriptions flow directly into downstream proposition generation, so quality here prevents rework later. Each description must:
- Be **20-35 words** (not shorter — a 10-word description lacks the specificity downstream skills need)
- Describe the **mechanism** — what the offering technically IS and how it works, not what outcome it delivers
- Avoid **outcome verbs** (reduces, enables, ensures, improves, optimizes) — those belong in the DOES layer
- Avoid **parity adjectives** (robust, innovative, cutting-edge, best-in-class, seamless, holistic) — these are empty claims
- Include the **provider's specific implementation** or differentiator, not a generic category description

**Description selection (two-pass).** Before applying the quality rules above, decide which text becomes the feature `description`. The candidate text arrives from `portfolio-web-researcher` (Step 3 Description Selection) tagged with `description_confidence: "high"` or `"low"`; the agent flag is advisory — this two-pass rule is the **authoritative** gate at feature-mapping time:

- **Pass A (keep) —** Tokenize `taxonomy_mapping.category_name` (lowercase, kebab-split, strip the dedupe agent's stop-word set: `services`, `platform`, `solution`, `software`, `tools`, `management`). If the candidate description contains **at least one** keyword from the category keyword set, keep it as `description` and proceed to the quality rules above. Pass A is intentionally permissive — a single keyword match is sufficient to keep a candidate; the stricter survivor-pick gate runs only at Step 7.6 Branch F where many candidates compete for the same category-grained feature.
- **Pass B (synthesize) —** Otherwise, synthesize a 1-sentence IS-layer description from `feature_name + usp + category_name` using the template `"{feature_name} — {category_name} delivered as {usp}."`, then trim to fit the 20-35 word budget. The synthesized line is anchored to the canonical capability by construction, so it cannot drift from the feature name or taxonomy.

The `description_confidence` flag from the agent is prompt-level only — never persisted in `features/*.json`. The two-pass rule produces the final text; downstream skills (proposition generation, dashboards) read only `description`.

**Output language (LANGUAGE contract).** When `portfolio.json.language` is set and is not `en`, both the `description` adopted by Pass A and the synthesized `description` produced by Pass B must be written in `LANGUAGE`; the `purpose` field defined in the previous paragraph must also be written in `LANGUAGE`. Translate web-sourced text into `LANGUAGE` rather than copying it verbatim; Pass A keeps the candidate's *content* — the language contract here governs how that content is written into `description`. The proper-noun preservation list — including product names, provider sub-brands, technology partner names, technical abbreviations (`API`, `SD-WAN`, `IaaS`, `PaaS`, `SaaS`, `SASE`, `5G`, `NOC`, `SOC`, `IAM`), compliance frameworks (`BSI C5`, `ISO 27001`, `SOC 2`, `GDPR`/`DSGVO`, `HIPAA`), standards-org names (e.g. `IEEE`, `IETF`, `OASIS`), domain names, and URLs — stays in original form regardless of `LANGUAGE`. The extraction-time twin of this rule lives in `portfolio-web-researcher.md` Step 3 Description Selection (item 5). The bilingual search step (Phase 1) is a separate concern — query language and output language are independent: a German project can search English domains and still produce German descriptions.

**Example — good:** "Multi-tenant Kubernetes platform on Open Telekom Cloud with automated GitOps deployment pipelines, Istio service mesh, and BSI C5-attested container registry for regulated workloads."

**Example — bad:** "Cloud-native platform enabling modern application deployment." (too short, outcome verb, no mechanism)

#### Step 7.2: Map Dimensions to Products

If no products exist in the portfolio, create one product per active dimension using the default product definitions from the template. If products already exist, ask the user to assign each feature to an existing product.

#### Step 7.3: Stage Feature Candidates

Do **not** write feature files yet. The old "skip if file exists" check is lexical-only — it silently drops new evidence about a feature you already know about instead of merging it into the existing record. Instead, collect every mapped feature into an in-memory list of **candidates** and persist that list to a staging file:

```
${PROJECT_PATH}/research/.staging/feature-candidates.json
```

Each candidate is a normal feature JSON object **plus** a `_candidate: true` marker and a `_source_offering` field carrying the original offering's domain, link, and USP so merges in Step 7.5 can enrich lineage without re-reading the scan logs:

```json
[
  {
    "_candidate": true,
    "slug": "aws-managed-services",
    "product_slug": "cloud-services",
    "name": "AWS Managed Services",
    "purpose": "Operate AWS workloads end-to-end for regulated enterprises",
    "description": "...",
    "taxonomy_mapping": { "dimension": 4, "category_id": "4.1", ... },
    "readiness": "ga",
    "sort_order": 190,
    "_source_offering": {
      "domain": "t-systems.com",
      "link": "https://www.t-systems.com/...",
      "usp": "BSI C5-attested AWS operations with German data residency"
    }
  }
]
```

Create the staging directory first with `mkdir -p "${PROJECT_PATH}/research/.staging"`.

#### Step 7.4: Dedupe Candidates Against Existing Features

Dispatch the `feature-deduplication-detector` agent in **candidate mode** once per product that received candidates. Pass:

- `project_dir`: `${PROJECT_PATH}`
- `product_slug`: the product being analyzed
- `candidates_file`: `${PROJECT_PATH}/research/.staging/feature-candidates.json`
- `language`: the portfolio language from `portfolio.json` (hint only)

The agent pools existing features (from `features/*.json`) and candidates into a single similarity matrix and returns clusters tagged with a `resolution_type` per cluster. See the agent's output schema for the full JSON shape.

**Why candidate mode and not the features Quality Gate:** Scan has the source evidence live in context (offering domain, link, USP). The features Quality Gate runs later, with evidence already flattened to `source_file` strings. Merging at scan time means the lineage entries we union in Step 7.5 carry the full provenance, not a stale pointer.

#### Step 7.5: Present Resolutions for Confirmation

Parse the agent output and present the clusters grouped by intent — **not** by confidence bucket. Users make better decisions when every row has the same question attached.

**Table A — Merges into existing features** (`resolution_type: candidate_to_existing`, hard):

| # | Candidate slug | → | Existing slug | Product | Confidence | Rationale | Action |
|---|---|---|---|---|---|---|---|
| 1 | aws-managed-services | → | managed-aws-services | cloud-services | 0.95 | slug variant, same capability | Merge (default) / Keep as new |

Default action: **Merge** — the candidate enriches the existing feature's source lineage and is then discarded. User can flip to **Keep as new** to force-write the candidate as a separate feature.

**Table B — Candidate-to-candidate collapses** (`resolution_type: candidate_to_candidate`, hard):

| # | Candidates | Survivor | Product | Confidence | Rationale | Action |
|---|---|---|---|---|---|---|
| 1 | aws-managed, managed-aws | aws-managed | cloud-services | 0.92 | same capability, different scan domains | Collapse (default) / Keep both |

**Table C — Needs your call** (all soft duplicates, 0.7–0.9, any resolution type):

Present the agent's `user_question` verbatim. Options per row: **Merge into existing / Keep both / Defer**.

**Table D — New features to create** (unclustered candidates — no hard or soft cluster, from the agent's `unclustered_candidates` list):

Same columns as the old "Proposed Entities" table. Default action: **Create**. User can edit fields or skip rows.

**Table E — Legacy duplicates detected** (`resolution_type: existing_to_existing`):

Informational only. Display the clusters with a note:
> These are duplicates that already existed in `features/` before this scan. Scan does not auto-merge legacy state. To resolve, run the `features` skill's Quality Completion Gate after the scan completes.

**Action policy:**
- **Approve all** — apply every default action in Tables A, B, and D; defer every row in Table C. Deferred Table C rows are **not dropped** — Step 7.6 branch E writes each one to `features/{slug}.json` flagged as `soft_duplicate_pending_review`, so the `features` Quality Completion Gate (Layer 0) re-surfaces the pair on its next run with both features' descriptions attached.
- **Review each** — walk the user through rows one at a time. Rows the user explicitly defers follow the same branch E write path as under Approve-all.

#### Step 7.6: Apply Resolutions and Write

**Initialize the dedupe counters** before walking the resolution tables. These five integers are what Phase 6 will write into `scan-output.json` `dedupe_summary` after all branches complete:

```
counters = {
  "merged_into_existing": 0,
  "collapsed_among_candidates": 0,
  "written_new": 0,
  "legacy_duplicates_flagged": <count of Table E clusters from Step 7.5>,
  "soft_duplicates_deferred": 0,
}
```

`legacy_duplicates_flagged` is set once here from the agent output — Table E rows are not written by scan, so there is no per-row increment for them. The other four are incremented as each branch applies, below.

For each accepted resolution:

**A. `candidate_to_existing` merges (accepted)** — update the existing feature file in place:
1. Read `features/{surviving_slug}.json`.
2. Union `source_refs` with a new `source_id` (register the scan report via `bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/source-registry.sh" register ${PROJECT_PATH} "research/{COMPANY_SLUG}-portfolio.md"` if not already registered).
3. Append a new entry to `source_lineage` with `entity_role: "merged_from"`, `ingestion_date: <now>`, and the candidate's `_source_offering.link` as evidence.
4. Take `min(sort_order)`.
5. **Do NOT overwrite `description`, `purpose`, or `name`** — the existing feature may carry human edits. The candidate's richer copy is preserved in `source_lineage` for audit.
6. Set `lineage_status.status` to `"refreshed"` with `flagged_at: <today>`.
7. Drop the candidate from the staging list.
8. `counters.merged_into_existing += 1`.

**B. `candidate_to_candidate` collapses (accepted)** — inside the staging list, merge the cluster's candidates into one (keep the surviving slug's entry, union `_source_offering` into an array). No file I/O. Increment `counters.collapsed_among_candidates` by `(cluster_size - 1)` — the survivor still becomes a written feature later, so only the absorbed siblings count as collapses.

**C. Unclustered candidates + rejected merges** — write to `features/{slug}.json` with `source_file: "research/{COMPANY_SLUG}-portfolio.md"` and `created: <today>`. Strip the `_candidate` and `_source_offering` markers before writing. `counters.written_new += 1` per file written.

**D. Rejected `candidate_to_existing` merges (user chose "Keep as new")** — write the candidate as a new feature, but prefix its slug with a disambiguator (e.g. `{original-slug}-v2`) if the base slug collides with an existing file. `counters.written_new += 1` per file written (branches C and D share the same counter — both produce fresh feature files).

**E. Deferred soft duplicates (Table C — under Approve-all, or explicit "Defer" in Review-each)** — write each deferred candidate to `features/{slug}.json` with `source_file: "research/{COMPANY_SLUG}-portfolio.md"` and `created: <today>`, stripping the `_candidate` and `_source_offering` markers as in branch C. Additionally, set:

```json
"lineage_status": {
  "flagged_as": "soft_duplicate_pending_review",
  "near_match_slug": "<existing_slug from the agent's cluster>",
  "confidence": <agent confidence, e.g. 0.78>,
  "flagged_at": "<today>"
}
```

If the candidate's base slug collides with an existing file, prefix it with a disambiguator (e.g. `{original-slug}-v2`) — same rule as branch D. The `features` Quality Completion Gate Layer 0 (`cogni-portfolio/skills/features/SKILL.md` Completion Loop) will pick the flagged pair up on its next run and re-surface it with both features' descriptions and any attached propositions, which is the right place to make the merge call with full context. Never silently drop a soft-deferred candidate — the dedupe agent's 0.7–0.9 confidence means the distinction is meaningful enough to preserve as evidence. `counters.soft_duplicates_deferred += 1` per deferred row written.

**F. `category-aggregation` aggregation (whole-dataset path)** — runs **only** when `CONSOLIDATION_MODE=category-aggregation`. Branches A–E do not apply in this mode (there was no dedupe agent output to walk). Instead, operate on the full staging list from Step 7.3 and write one feature per populated taxonomy category:

1. Read the staging list from `${PROJECT_PATH}/research/.staging/feature-candidates.json`.
2. Group candidates by `taxonomy_mapping.category_id`. Every candidate must have a category_id from Step 7.1; drop (with a warning) any candidate missing one — it is a mapping bug from Step 7.1, not valid input for aggregation.
3. For each group with ≥1 candidate, derive the category-grained feature:
   - **Name:** pick the most-representative offering name in the group — highest-frequency `name` across the candidates, ties broken by longest common prefix. If no majority emerges (including the case where every candidate name appears exactly once), fall back to `taxonomy_mapping.category_name` from the template.
   - **Slug:** kebab-case of the chosen name. If it collides with an existing feature file, prefix with a disambiguator (same rule as branches D and E).
   - **Product_slug:** from the first candidate in the group (all candidates in a group share the same dimension, and Step 7.2 already mapped dimensions to products).
   - **Description:** pick the candidate with the highest category-keyword overlap (tokenize `taxonomy_mapping.category_name` lowercase, kebab-split, then strip the dedupe agent's stop-word set: `services`, `platform`, `solution`, `software`, `tools`, `management`; score each candidate by distinct keyword matches). Ties break by longest within the 20–35 word IS-layer budget from Step 7.1 — longest wins **inside** the budget, not outside it. Record the unselected candidate descriptions in `source_lineage` with `entity_role: "aggregated_from"` (see the Source_lineage bullet below for the full wire format) so per-stack nuance survives aggregation. This mirrors Pass A from Step 7.1, so the same stop-word set governs both ends of the pipeline.
   - **Purpose:** the candidate purpose with the broadest phrasing (shortest acceptable purpose in the 5–12 word budget from Step 7.1).
   - **Taxonomy_mapping:** copy from the group (all candidates share the same category_id / dimension / horizon by construction). If horizons differ within a group, take `current` > `emerging` > `future` (most-mature horizon wins — downstream dashboards treat the feature's horizon as the provider's **capability** horizon, and the most-mature delivery variant establishes that capability).
   - **Readiness:** derived from horizon per the existing mapping table.
   - **Source_file:** `research/{COMPANY_SLUG}-portfolio.md` (same as branches C/D/E).
   - **Created:** `<today>`.
   - **Source_lineage:** one entry per candidate in the group, with `entity_role: "aggregated_from"`, `ingestion_date: <now>`, and the candidate's `_source_offering.link` as evidence — this preserves the per-stack evidence trail without exploding the feature count.
4. Write each derived feature to `features/{slug}.json`, stripping the `_candidate` and `_source_offering` markers as in branch C. `counters.written_new += 1` per file.
5. **Emit the delivery-stack artifact.** For each group, append one record per candidate (provider-level delivery variant) to `research/scan-solutions-draft.json` (written at the stable `research/` path, **not** under `.staging/`, so it survives the post-write staging sweep and is available to the `solutions/` skill in a later session):

   ```json
   [
     {
       "category_id": "4.1",
       "category_name": "Managed Hyperscaler Services",
       "feature_slug": "sovereign-cloud-iaas",
       "delivery_stacks": [
         {
           "domain": "t-systems.com",
           "provider_unit": "T-Systems International",
           "link": "https://www.t-systems.com/.../otc",
           "usp": "BSI C5-attested, German data residency",
           "delivery_stack": "open-telekom-cloud"
         },
         {
           "domain": "operational-services.de",
           "provider_unit": "Operational Services",
           "link": "https://operational-services.de/.../aws-frankfurt",
           "usp": "AWS Frankfurt with sovereign-by-contract operations",
           "delivery_stack": "aws-frankfurt"
         }
       ]
     }
   ]
   ```

   `delivery_stack` is inferred from `_source_offering.link` host + usp text (e.g. links containing `otc` or `open-telekom-cloud` → `open-telekom-cloud`; `aws`/`amazon` → `aws-{region}`; `gcp`/`google` → `gcp-{region}`; otherwise `on-prem` or `unknown`). The exact inference rules are not load-bearing for this PR — downstream `solutions/` seeding will refine them. Record whatever the scan could infer so the artifact is useful on first pass. Until the `solutions/` seed-from-scan-draft entry point lands (follow-up work), the artifact is purely diagnostic — inspect it manually with `cat` to see what per-stack seeds the scan proposes.
6. Leave `merged_into_existing`, `collapsed_among_candidates`, `legacy_duplicates_flagged`, and `soft_duplicates_deferred` at 0 — they do not apply under aggregation. (`counters.written_new` is already incremented per file inside step 4's per-group loop; do not re-increment it here.) The sum invariant (staged candidates = branches' outputs) does **not** hold under aggregation by design: many candidates collapse into one feature without going through per-candidate dedupe branches. Skip the invariant check under this mode.

After all writes are complete, clean up, sync, and persist the counters into the metadata file written by Phase 6:

```bash
rm -rf "${PROJECT_PATH}/research/.staging"
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/sync-portfolio.sh" "${PROJECT_PATH}"
```

Then update `research/.metadata/scan-output.json` in place: read the file, set `dedupe_summary` to the final `counters` dict, and write it back. The Phase 6 metadata write created the block with all-zero defaults; this step replaces it with the real counts. Also persist the chosen mode — set `consolidation_mode` in the same in-place update to whatever `CONSOLIDATION_MODE` was at runtime (`consolidate` / `shadow` / `research-only` / `category-aggregation`) so downstream dashboards and follow-ups like `solutions/` seed-from-scan-draft can tell which aggregation regime produced the feature set. Verify the sum invariant before writing — `merged_into_existing + collapsed_among_candidates + written_new + soft_duplicates_deferred` must equal the candidate count staged at Step 7.3, **except under `category-aggregation`** where the invariant does not hold by design (see Branch F). If the invariant fails under any of the other three modes, log a warning to the user (do not abort the scan — the data is still useful) and write the counters anyway so the discrepancy is visible in the dashboard.

**Also enrich `provider_units[]` with `feature_count`** in the same in-place update. For each entry in the existing `provider_units` array (written as a skeleton at Phase 1.5 confirmation), set `feature_count` = number of features this scan produced (branches A, C, D, and E of Step 7.6) whose `_source_offering.domain` matches the unit's `domain` or one of its docs/help subdomains discovered in Phase 1.5. Skeleton entries missing `feature_count` mean the scan was interrupted before 7.6 finalized — leave them as-is rather than synthesizing a value.

#### Step 7.7: Set Taxonomy in portfolio.json

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
| CONSOLIDATION_MODE | Phase 0 Step 6 selection — drives Phase 7 behaviour | `consolidate` \| `shadow` \| `research-only` \| `category-aggregation` |
