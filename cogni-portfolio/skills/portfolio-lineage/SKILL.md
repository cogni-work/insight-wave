---
name: portfolio-lineage
description: |
  Track source lineage, detect changes in input documents and URLs, and cascade
  refresh through the feature-proposition-solution chain. Use whenever the user
  mentions "lineage", "source lineage", "what sources", "what changed", "refresh
  stale", "source registry", "check sources", "which documents fed", "trace back
  to source", "show dependencies", "what's affected by", "stale sources",
  "source drift", "cascade refresh", "where did this come from", "re-upload",
  or wants to understand or act on the relationship between input sources and
  portfolio entities.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# Source Lineage

Track input sources, detect changes, and guide refresh cascades through the portfolio entity chain.

## Core Concept

Portfolio entities (features, propositions, solutions) are derived from input sources — uploaded documents, web research URLs, and TIPS enrichment. When those sources change (a document is re-uploaded, a URL's content changes), downstream entities become stale. This skill manages the full lineage lifecycle:

1. **Register** sources with fingerprints during ingestion
2. **Detect** when sources have changed
3. **Trace** which entities came from which sources
4. **Cascade** staleness through the dependency chain
5. **Guide** the user through a refresh in the correct order

The source registry (`source-registry.json`) is the central manifest. It tracks every input source, its SHA-256 fingerprint, and which entities it created. The `portfolio-ingest` skill creates registry entries automatically; this skill manages the registry lifecycle afterward.

## Prerequisites

- An active cogni-portfolio project (`portfolio.json` must exist)
- For full lineage tracking: a `source-registry.json` (created automatically by `portfolio-ingest` or via the status mode of this skill)

## Workflow Modes

Detect the user's intent and route to the appropriate mode. If ambiguous, start with **Status** to orient.

### Mode 1: Status

**Triggers**: "lineage status", "source status", "show sources", "lineage overview"

1. Find the active project (same discovery as `portfolio-resume`).
2. Run the source-registry script:
   ```bash
   bash $CLAUDE_PLUGIN_ROOT/scripts/source-registry.sh "<project-dir>" status
   ```
3. If no registry exists, offer to create one:
   - Run `bash $CLAUDE_PLUGIN_ROOT/scripts/source-registry.sh "<project-dir>" init`
   - Then scan for existing `source_file` fields on entities and offer to backfill registry entries from them
4. Present a summary table:

   | Metric | Value |
   |--------|-------|
   | Document sources | N |
   | URL sources | N |
   | Stale sources | N |
   | Tracked entities | N / total |
   | Untracked entities | N |

5. If untracked entities exist (entities with no `source_refs` and no registry link), list them and offer to backfill by scanning `source_file` fields.
6. If stale sources exist, recommend running **Check** mode or **Refresh** mode.

### Mode 2: Check

**Triggers**: "check sources", "what changed", "detect drift", "source check"

1. Find the active project and verify registry exists.
2. Run document check:
   ```bash
   bash $CLAUDE_PLUGIN_ROOT/scripts/source-registry.sh "<project-dir>" check-docs
   ```
3. Present findings in three groups:

   **Changed documents** (re-uploaded with different content):
   | Document | Entities Affected | Context Entries |
   |----------|------------------|-----------------|
   | pricing-2026.pdf | features/cloud-monitoring, products/cloud-platform | pricing-2026--001, pricing-2026--002 |

   **New uploads** (never ingested):
   - List filenames, recommend running `portfolio-ingest`

   **Missing sources** (registered but file not found):
   - List filenames and source IDs

4. For changed documents: ask the user whether to:
   - **Mark as stale** — update the registry entry status to `stale` and flag all linked entities with `lineage_status`
   - **Re-ingest** — recommend running `portfolio-ingest` to re-process the changed documents
   - **Ignore** — the document was replaced intentionally and entities are still valid

5. For URL source checking (only when user explicitly requests):
   - Ask for confirmation before making network requests
   - For each URL source in the registry, fetch the URL and compare content hash
   - Report changed, unreachable, and unchanged URLs
   - Recommend running `portfolio-verify` for changed URLs

### Mode 3: Trace

**Triggers**: "trace {entity}", "where did X come from", "what sources feed X", "lineage of X"

1. Identify the entity the user wants to trace (by slug or name).
2. Look up the entity's `source_refs` field. If absent, fall back to `source_file` and match against registry entries by filename.
3. For each source found, read the registry entry and show:
   - Source type (document/URL), filename or URL, ingestion date, status
   - Other entities created from the same source
   - Context entries from the same source
4. Walk **upstream**: what inputs created this entity?
   - For propositions: trace to the parent feature and market, and their sources
   - For solutions: trace to the parent proposition, then to feature/market/sources
5. Walk **downstream**: what depends on this entity?
   - For features: list all propositions using this feature
   - For propositions: list the solution, competitor analysis, and any packages including it
6. Present as a dependency tree:
   ```
   Source: pricing-strategy-2025.pdf (doc--pricing-strategy-2025, current)
   +-- features/cloud-monitoring
   |   +-- propositions/cloud-monitoring--mid-market-saas-dach
   |   |   +-- solutions/cloud-monitoring--mid-market-saas-dach
   |   |   +-- competitors/cloud-monitoring--mid-market-saas-dach
   |   +-- propositions/cloud-monitoring--enterprise-dach
   +-- context/pricing-strategy-2025--001
   +-- context/pricing-strategy-2025--002
   ```

### Mode 4: Impact

**Triggers**: "what's affected by X", "impact of changing X", "blast radius", "if I update X"

1. Identify the source (by filename, URL, or source_id).
2. Look up the registry entry and collect all directly linked entities.
3. Run the staleness cascade:
   ```bash
   bash $CLAUDE_PLUGIN_ROOT/scripts/source-registry.sh "<project-dir>" staleness
   ```
4. Filter to only entities affected by the specified source.
5. Present as a cascade summary:
   - **Direct impact**: N features, N products, N markets
   - **Cascade to propositions**: N propositions (list the first few)
   - **Cascade to solutions**: N solutions
   - **Cascade to packages**: N packages (if any include affected solutions)
   - **Context entries**: N entries may need review
6. Show total blast radius count and offer to proceed with **Refresh** mode.

### Mode 5: Refresh

**Triggers**: "refresh stale", "cascade refresh", "fix stale entities", "update from sources"

1. Find all stale entities by running:
   ```bash
   bash $CLAUDE_PLUGIN_ROOT/scripts/source-registry.sh "<project-dir>" staleness
   ```
2. If no stale entities, report "All entities are current" and exit.
3. Group stale entities by refresh layer (dependency order):

   **Layer 1 — Features** (must refresh first, as propositions depend on them):
   - List stale features with their staleness reason
   - Recommend: "Run the `features` skill to review and update these N features"

   **Layer 2 — Propositions** (refresh after features are current):
   - List stale propositions
   - Recommend: "Run the `propositions` skill to regenerate messaging for these N pairs"

   **Layer 3 — Solutions** (refresh after propositions are current):
   - List stale solutions
   - Recommend: "Run the `solutions` skill to update pricing and implementation plans"

4. Ask whether to re-ingest first: if the staleness was caused by a changed document, recommend running `portfolio-ingest` before refreshing entities, so the new document content informs the refresh.
5. After the user completes each layer (by running the appropriate skill), offer to:
   - Clear `lineage_status` on refreshed entities (remove the field from their JSON)
   - Update the source registry (set changed source status back to `current` with new fingerprint)
   - Check if more layers need refresh
6. After all layers are refreshed, confirm: "All N entities have been refreshed. Source registry is current."

## Registry Backfill

When a project has existing entities with `source_file` fields but no `source-registry.json`, this skill can reconstruct the registry:

1. Scan all entity JSON files in `products/`, `features/`, `markets/` for `source_file` fields
2. Scan all context entries for `source_file` fields
3. For each unique filename found:
   - Check if the file exists in `uploads/processed/` — if so, compute its hash
   - Create a registry entry linking the file to all entities that reference it
4. Write `source-registry.json` with all discovered sources
5. Optionally write `source_refs` arrays on entities (ask user first)

## Integration Points

- **portfolio-ingest**: Creates registry entries after ingestion (Step 8b). Detects re-uploaded documents by comparing hashes.
- **portfolio-resume**: Displays source lineage status in the status table. Surfaces drift warnings before stale entity warnings.
- **portfolio-verify**: Checks URL source freshness before running claim verification.
- **propositions**: Registers evidence URLs in the registry. Warns when evidence URLs are stale.
- **project-status.sh**: Includes `source_lineage` in health-check output.

## Language

Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
