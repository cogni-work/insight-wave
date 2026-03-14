# Wikilink Extraction Algorithms

5 algorithms for extracting research entity links from findings' provenance chain to create meaningful knowledge graph connections in claim entities.

## Variable Prerequisites

**MANDATORY:** Before using these algorithms, ensure entity directory variables are resolved in Phase 2 Step 4:

```bash
# Variables must be exported before wikilink extraction
# FINDINGS_DIR="04-findings"
# CLAIMS_DIR="10-claims"
# CITATIONS_DIR="09-citations"
# MEGATRENDS_DIR="06-megatrends"
# etc.
```

**Note:** Examples in this document use `{{placeholder}}` syntax to show the entity type conceptually. In actual code, replace with resolved variables like `${FINDINGS_DIR}`.

## Overview

**Purpose:** Generate wikilinks by extracting entity references from findings to build provenance chain

**Input:** Finding markdown files in `${PROJECT_PATH}/${FINDINGS_DIR}/data/`

**Output:** Provenance object with 5 wikilink arrays + 2 metadata fields

```yaml
provenance:
  # RESEARCH ENTITIES (meaningful knowledge graph links)
  # ALL wikilinks MUST be workspace-relative (include PROJECT_AGENTS prefix)
  refined_question_ids: ["[[cogni-research/project-name/02-refined-questions/data/question-tech-q1]]", "[[cogni-research/project-name/02-refined-questions/data/question-econ-q2]]"]
  dimension_id: "[[cogni-research/project-name/01-research-dimensions/data/dimension-economic-analysis]]"
  megatrend_ids: ["[[cogni-research/project-name/06-megatrends/data/megatrend-safety-features-a3f5]]"]

  # SOURCE PROVENANCE (evidence chain)
  finding_ids: ["[[cogni-research/project-name/04-findings/data/finding-a3f5b2c1]]"]
  source_ids: ["[[cogni-research/project-name/07-sources/data/source-xyz]]"]

  # AUDIT METADATA (technical provenance, not wikilinks)
  query_batch: "query-batch-economic"
  verification_agent: "fact-checker"
  verification_timestamp: "2025-01-01T12:00:00Z"
```

## Canonical Wikilink Generation (MANDATORY)

**CRITICAL:** All wikilinks MUST be generated using the generate-wikilink.sh script to ensure workspace-relative paths. DO NOT hardcode project-relative paths.

### Script Location

```bash
WIKILINK_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/generate-wikilink.sh"
```

### Usage Pattern

```bash
# Generate workspace-relative wikilink for any entity
WIKILINK_JSON=$(bash "$WIKILINK_SCRIPT" \
  --project-path "$PROJECT_PATH" \
  --entity-dir "02-refined-questions" \
  --filename "customer-segments-q1")

# Extract wikilink from JSON response
WIKILINK=$(echo "$WIKILINK_JSON" | jq -r '.data.wikilink')
# Result: [[cogni-research/project-name/02-refined-questions/data/question-customer-segments-q1]]
```

### Why Workspace-Relative?

1. **PROJECT_AGENTS_OPS_ROOT** is the Obsidian vault root (where .obsidian/ lives)
2. **Multi-project vaults** have structure: `vault-root/plugin-dir/project-dir/entities/`
3. **Wikilinks must resolve from vault root**, not from project root
4. **generate-wikilink.sh auto-detects** workspace mode via:
   - Priority 1: `PROJECT_AGENTS_OPS_ROOT` environment variable
   - Priority 2: `OBSIDIAN_VAULT_ROOT` environment variable
   - Priority 3: Traverse up to find `.obsidian/` directory
   - Priority 4: Fall back to single-project mode

### Critical Anti-Pattern

**NEVER hardcode project-relative paths:**

```bash
# WRONG - breaks in multi-project vaults (project-relative only)
"[[07-sources/data/source-xyz]]"
"[[02-refined-questions/data/question-tech-q1]]"
"[[01-research-dimensions/data/dimension-economic-analysis]]"

# CORRECT - workspace-relative via generate-wikilink.sh
"[[cogni-research/project-name/07-sources/data/source-xyz]]"
"[[cogni-research/project-name/02-refined-questions/data/question-tech-q1]]"
"[[cogni-research/project-name/01-research-dimensions/data/dimension-economic-analysis]]"
```

### Integration with Entity Extraction

When extracting wikilinks from existing entities (e.g., refined questions), they may contain project-relative paths. You MUST convert them to workspace-relative using generate-wikilink.sh:

```bash
# Entity contains project-relative wikilink
# **Parent Dimension**: [[01-research-dimensions/data/dimension-customer-segments]]

# Extract entity-dir and filename
ENTITY_DIR="01-research-dimensions"
FILENAME="customer-segments"

# Convert to workspace-relative
WORKSPACE_WIKILINK=$(bash "$WIKILINK_SCRIPT" \
  --project-path "$PROJECT_PATH" \
  --entity-dir "$ENTITY_DIR" \
  --filename "$FILENAME" | jq -r '.data.wikilink')

# Result: [[cogni-research/project-name/01-research-dimensions/data/dimension-customer-segments]]
```

## Algorithm 1: Extract Refined Questions

Extract source question IDs from query batch files referenced by findings.

### Process

**Step 1:** Read finding frontmatter to extract `batch_id`

```yaml
batch_id: [[03-query-batches/data/query-batch-economic]]
```

**Format Specification:** The `batch_id` field in finding frontmatter MUST be a wikilink string (enclosed in `[[...]]`). This format:
- Enables clickable navigation in Obsidian
- Contains full relative path from project root
- Example: `[[03-query-batches/data/query-batch-economic]]`

**Not Accepted:** Plain string without brackets (e.g., `batch_id: query-batch-economic`)

**Step 2:** Extract batch filename from wikilink

- Input: `[[03-query-batches/data/query-batch-economic]]`
- Extracted: `03-query-batches/data/query-batch-economic` (strip `[[` and `]]`)

**Step 3:** Read batch file at `${project_path}/03-query-batches/data/query-batch-economic.md`

**Step 4:** Extract "Source Questions" wikilinks from batch content

```markdown
## Source Questions

This batch addresses the following refined questions:
- [[tech-q1]]
- [[tech-q2]]
- [[econ-q1]]
```

**Bash Pattern:**
```bash
# Read batch file
BATCH_CONTENT=$(cat "$BATCH_FILE")

# Extract wikilinks from "Source Questions" section
REFINED_QUESTIONS=$(echo "$BATCH_CONTENT" | \
  awk '/## Source Questions/,/^## [^S]/ {print}' | \
  grep -oE '\[\[[^]]+\]\]' | \
  sort -u)

# Convert to array
REFINED_QUESTION_IDS=()
while IFS= read -r question; do
  if [ -n "$question" ]; then
    REFINED_QUESTION_IDS+=("$question")
  fi
done <<< "$REFINED_QUESTIONS"
```

**Step 5:** Collect unique refined question IDs across all findings

If claim uses findings from 2 batches, union the source questions and deduplicate:

Example: `["[[tech-q1]]", "[[tech-q2]]", "[[econ-q1]]"]`

**Step 6:** Use in claim provenance

```yaml
refined_question_ids: ["[[tech-q1]]", "[[tech-q2]]", "[[econ-q1]]"]
```

### Error Handling

| Error | Recovery |
|-------|----------|
| batch_id missing from finding | Skip this finding, log warning |
| Batch file doesn't exist | Use empty array, log error |
| No "Source Questions" section | Use empty array |

## Algorithm 2: Extract Parent Dimension

Use first refined question to find parent dimension.

### Process

**Step 1:** Select first refined question ID from extracted list

Example: `[[cogni-research/project-name/02-refined-questions/data/question-tech-q1]]`

**Step 2:** Read refined question file at `${project_path}/02-refined-questions/data/question-tech-q1.md`

**Step 3:** Extract "Parent Dimension" wikilink from content

```markdown
**Parent Dimension**: [[01-research-dimensions/data/dimension-economic-analysis]]
```

**CRITICAL:** The wikilink contains the directory path and filename. Extract EXACTLY as found.

**Step 4:** Parse extracted wikilink to get entity-dir and filename

```bash
# Extract from: [[01-research-dimensions/data/dimension-economic-analysis]]
EXTRACTED="01-research-dimensions/data/dimension-economic-analysis"
ENTITY_DIR=$(dirname "$EXTRACTED")    # "01-research-dimensions"
FILENAME=$(basename "$EXTRACTED")      # "economic-analysis"
```

**Step 5:** Convert to workspace-relative using generate-wikilink.sh

```bash
DIMENSION_WIKILINK=$(bash "$WIKILINK_SCRIPT" \
  --project-path "$PROJECT_PATH" \
  --entity-dir "$ENTITY_DIR" \
  --filename "$FILENAME" | jq -r '.data.wikilink')

# Result: [[cogni-research/project-name/01-research-dimensions/data/dimension-economic-analysis]]
```

**Step 6:** Use in claim provenance

```yaml
dimension_id: "[[cogni-research/project-name/01-research-dimensions/data/dimension-economic-analysis]]"
```

### Critical Constraint: DO NOT MODIFY DIMENSION NAME

**DO NOT add any prefix to the dimension filename:**

```bash
# WRONG - hallucinated "dimension-" prefix
FILENAME="dimension-economic-analysis"  # DO NOT DO THIS

# CORRECT - use filename EXACTLY as extracted
FILENAME="economic-analysis"
```

The dimension filename is the actual file on disk. Any modification breaks the wikilink.

### Error Handling

| Error | Recovery |
|-------|----------|
| No refined questions | Skip dimension extraction, set null |
| Refined question file doesn't exist | Set null, log warning |
| No "Parent Dimension" section | Set null |
| **Dimension file doesn't exist** | **Log ERROR: broken wikilink, set null** |

## Algorithm 3: Extract Related Megatrends (Optional)

Find megatrends that reference the same findings as this claim.

### Process

**Step 1:** Collect claim's finding IDs

Example: `["finding-a3f5b2c1", "finding-xyz789"]`

**Step 2:** List all megatrend files

```bash
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"

DIR_MEGATRENDS="$(get_directory_by_key "megatrends")"
DATA_SUBDIR="$(get_data_subdir)"

ls ${project_path}/$DIR_MEGATRENDS/$DATA_SUBDIR/*.md
```

**Step 3:** For each megatrend file

- Read YAML frontmatter
- Extract `finding_refs` array (wikilinks to findings)
- Check for intersection with claim's finding IDs

**Step 4:** Collect matching megatrend IDs

If megatrend links to ANY of the claim's findings, include it.

Example: `["[[megatrend-safety-features-a3f5]]", "[[megatrend-payload-capacity-b7c9]]"]`

**Step 5:** Use in claim provenance

```yaml
megatrend_ids: ["[[megatrend-safety-features-a3f5]]", "[[megatrend-payload-capacity-b7c9]]"]
```

### Performance Note

- Megatrends are created in Phase 4 (same as findings)
- May not exist for all research projects
- If no megatrends directory → Set empty array, skip

### Error Handling

| Error | Recovery |
|-------|----------|
| Megatrends directory doesn't exist | Set empty array |
| Megatrend file read fails | Skip that megatrend, continue with others |

## Algorithm 4: Extract Source IDs from Findings

Extract source entity IDs from finding frontmatter to link claims to original sources.

### Process

**Step 1:** Collect claim's finding IDs

Example: `["finding-a3f5b2c1", "finding-xyz789"]`

**Step 2:** For each finding file

Read `${PROJECT_PATH}/${FINDINGS_DIR}/data/{finding_id}.md` and extract `source_id` field from YAML frontmatter:

```bash
SOURCE_ID=$(grep "^source_id:" "$finding_file" | head -1 | sed 's/^source_id:[[:space:]]*//')
```

If `source_id` exists and not empty: Add to source_ids array

**Step 3:** Deduplicate source IDs

Multiple findings may reference same source. Use `sort -u` to remove duplicates.

**Step 4:** Format as wikilinks

Prefix with `07-sources/data/` directory.

Example: `["[[07-sources/data/source-worldbank-report-b7d6]]"]`

**Step 5:** Use in claim provenance

```yaml
source_ids: ["[[07-sources/data/source-worldbank-report-b7d6]]", "[[07-sources/data/source-climate-bonds-xyz]]"]
```

### Correct Implementation

```bash
# Initialize array
source_ids=()

# Process each finding
for finding_file in "${FINDING_IDS[@]}"; do
  # Note: || true prevents script exit if grep finds no match (when using set -e)
  RAW_SOURCE_ID=$(grep "^source_id:" "$finding_file" 2>/dev/null | head -1 | sed 's/^source_id:[[:space:]]*//' || true)

  # Remove surrounding quotes if present
  RAW_SOURCE_ID="${RAW_SOURCE_ID%\"}"
  RAW_SOURCE_ID="${RAW_SOURCE_ID#\"}"

  # Skip if empty
  if [ -z "$RAW_SOURCE_ID" ]; then
    continue
  fi

  # Check if already a wikilink (source_id stored as [[07-sources/data/source-xxx]])
  if [[ "$RAW_SOURCE_ID" =~ ^\[\[.*\]\]$ ]]; then
    # Already a wikilink - use directly
    source_ids+=("$RAW_SOURCE_ID")
  else
    # Plain ID - wrap in wikilink format (legacy support)
    source_ids+=("[[07-sources/data/$RAW_SOURCE_ID]]")
  fi
done

# Deduplicate
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
unique_source_ids=()
while IFS= read -r id; do
    unique_source_ids+=("$id")
done < <(printf '%s\n' "${source_ids[@]}" | sort -u)
source_ids=("${unique_source_ids[@]}")
```

### Why Empty Array Better Than Placeholder

- Empty array `[]` = "sources not yet processed" (valid state in workflow)
- Placeholder `["source-uuid"]` = broken wikilink that will never resolve
- Wikilink validation can differentiate between "pending" and "broken"

### Error Handling

| Error | Recovery |
|-------|----------|
| Finding file doesn't exist | Skip this finding, log warning |
| source_id field missing or empty | Skip this finding's source (do not add to array) |
| No sources extracted | Use empty array `[]` in YAML (NOT placeholder) |

## Algorithm 5: Preserve Query Batch as Metadata

Keep query batch reference for technical audit trail (NOT as wikilink).

### Process

**Step 1:** Extract batch ID from finding (same as Algorithm 1 steps 1-2)

**Step 2:** Extract batch name without directory or extension

- Input: `03-query-batches/data/query-batch-economic`
- Extracted: `query-batch-economic`

**Step 3:** If multiple batches, comma-separate

Example: `"query-batch-economic,query-batch-market"`

**Step 4:** Use in claim provenance as string (not wikilink)

```yaml
query_batch: "query-batch-economic"  # String only, no [[brackets]]
```

### Why String Not Wikilink

- Query batches are technical constructs for parallel execution
- Not meaningful knowledge entities for graph navigation
- Preserves audit trail without cluttering knowledge graph

## Complete Worked Example

### Scenario

Extract research entity links for claim from 2 findings. Project is located at `/vault/cogni-research/climate-research/` with vault root at `/vault/`.

### Step 1: Collect Finding Data

Claim extracted from:
- finding-green-bond-market-size-a3f5b2c1.md
- finding-institutional-investor-demand-xyz789.md

### Step 2: Extract Refined Questions (Algorithm 1)

**Finding 1 frontmatter:**
```yaml
batch_id: [[03-query-batches/data/query-batch-economic]]
```

**Read** `03-query-batches/data/query-batch-economic.md`:
```markdown
## Source Questions

This batch addresses:
- [[02-refined-questions/data/question-econ-q1]]
- [[02-refined-questions/data/question-econ-q2]]
- [[02-refined-questions/data/question-econ-q3]]
```

**Convert each to workspace-relative using generate-wikilink.sh:**
```bash
# For each question, extract entity-dir and filename, then generate wikilink
bash "$WIKILINK_SCRIPT" --project-path "$PROJECT_PATH" --entity-dir "02-refined-questions" --filename "econ-q1"
# Result: [[cogni-research/climate-research/02-refined-questions/data/question-econ-q1]]
```

**Finding 2 frontmatter:**
```yaml
batch_id: [[03-query-batches/data/query-batch-market]]
```

**Read** `03-query-batches/data/query-batch-market.md`:
```markdown
## Source Questions

- [[02-refined-questions/data/question-market-q1]]
- [[02-refined-questions/data/question-market-q2]]
```

**Deduplicated refined questions (workspace-relative):**
```
[
  "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q1]]",
  "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q2]]",
  "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q3]]",
  "[[cogni-research/climate-research/02-refined-questions/data/question-market-q1]]",
  "[[cogni-research/climate-research/02-refined-questions/data/question-market-q2]]"
]
```

### Step 3: Extract Parent Dimension (Algorithm 2)

**Read** `02-refined-questions/data/question-econ-q1.md`:
```markdown
**Parent Dimension**: [[01-research-dimensions/data/dimension-economic-analysis]]
```

**Parse and convert to workspace-relative:**
```bash
# Extract from project-relative path
EXTRACTED="01-research-dimensions/data/dimension-economic-analysis"
ENTITY_DIR="01-research-dimensions"
FILENAME="economic-analysis"  # DO NOT add "dimension-" prefix!

# Generate workspace-relative wikilink
bash "$WIKILINK_SCRIPT" --project-path "$PROJECT_PATH" --entity-dir "$ENTITY_DIR" --filename "$FILENAME"
# Result: [[cogni-research/climate-research/01-research-dimensions/data/dimension-economic-analysis]]
```

**Result:** `dimension_id: "[[cogni-research/climate-research/01-research-dimensions/data/dimension-economic-analysis]]"`

### Step 4: Extract Related Megatrends (Algorithm 3)

**List megatrends:** `06-megatrends/data/*.md`

**Megatrend** `megatrend-market-growth-trends-b7c9.md` frontmatter contains:
```yaml
finding_refs:
  - "[[04-findings/data/finding-green-bond-market-size-a3f5b2c1]]"  # MATCH!
  - "[[04-findings/data/finding-other-abc123]]"
```

**Megatrend** `megatrend-investor-behavior-d2f1.md` frontmatter contains:
```yaml
finding_refs:
  - "[[04-findings/data/finding-institutional-investor-demand-xyz789]]"  # MATCH!
  - "[[04-findings/data/finding-retail-participation-def456]]"
```

**Convert matched megatrends to workspace-relative:**
```bash
bash "$WIKILINK_SCRIPT" --project-path "$PROJECT_PATH" --entity-dir "06-megatrends" --filename "megatrend-market-growth-trends-b7c9"
# Result: [[cogni-research/climate-research/06-megatrends/data/megatrend-market-growth-trends-b7c9]]
```

**Matched megatrends (workspace-relative):**
```
[
  "[[cogni-research/climate-research/06-megatrends/data/megatrend-market-growth-trends-b7c9]]",
  "[[cogni-research/climate-research/06-megatrends/data/megatrend-investor-behavior-d2f1]]"
]
```

### Step 5: Extract Source IDs (Algorithm 4)

**Read finding 1 frontmatter** (`finding-green-bond-market-size-a3f5b2c1.md`):
```yaml
source_id: source-climate-bonds-initiative-abc
```

**Read finding 2 frontmatter** (`finding-institutional-investor-demand-xyz789.md`):
```yaml
source_id: source-blackrock-report-xyz
```

**Extract source_ids and convert to workspace-relative:**
```bash
# For finding 1
SOURCE_ID_1=$(grep "^source_id:" "${FINDINGS_DIR}/data/finding-green-bond-market-size-a3f5b2c1.md" | head -1 | sed 's/^source_id:[[:space:]]*//')
# Returns: source-climate-bonds-initiative-abc

# Generate workspace-relative wikilink
bash "$WIKILINK_SCRIPT" --project-path "$PROJECT_PATH" --entity-dir "07-sources" --filename "$SOURCE_ID_1"
# Result: [[cogni-research/climate-research/07-sources/data/source-climate-bonds-initiative-abc]]

# For finding 2
SOURCE_ID_2=$(grep "^source_id:" "${FINDINGS_DIR}/data/finding-institutional-investor-demand-xyz789.md" | head -1 | sed 's/^source_id:[[:space:]]*//')
# Returns: source-blackrock-report-xyz

bash "$WIKILINK_SCRIPT" --project-path "$PROJECT_PATH" --entity-dir "07-sources" --filename "$SOURCE_ID_2"
# Result: [[cogni-research/climate-research/07-sources/data/source-blackrock-report-xyz]]
```

**Source IDs (workspace-relative):**
```
[
  "[[cogni-research/climate-research/07-sources/data/source-climate-bonds-initiative-abc]]",
  "[[cogni-research/climate-research/07-sources/data/source-blackrock-report-xyz]]"
]
```

### Step 6: Construct Claim Provenance (All Algorithms)

```yaml
provenance:
  # ALL wikilinks are workspace-relative (include PROJECT_AGENTS prefix)
  refined_question_ids:
    - "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q1]]"
    - "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q2]]"
    - "[[cogni-research/climate-research/02-refined-questions/data/question-econ-q3]]"
    - "[[cogni-research/climate-research/02-refined-questions/data/question-market-q1]]"
    - "[[cogni-research/climate-research/02-refined-questions/data/question-market-q2]]"
  dimension_id: "[[cogni-research/climate-research/01-research-dimensions/data/dimension-economic-analysis]]"
  megatrend_ids:
    - "[[cogni-research/climate-research/06-megatrends/data/megatrend-market-growth-trends-b7c9]]"
    - "[[cogni-research/climate-research/06-megatrends/data/megatrend-investor-behavior-d2f1]]"
  finding_ids:
    - "[[cogni-research/climate-research/04-findings/data/finding-green-bond-market-size-a3f5b2c1]]"
    - "[[cogni-research/climate-research/04-findings/data/finding-institutional-investor-demand-xyz789]]"
  source_ids:
    - "[[cogni-research/climate-research/07-sources/data/source-climate-bonds-initiative-abc]]"
    - "[[cogni-research/climate-research/07-sources/data/source-blackrock-report-xyz]]"
  query_batch: "query-batch-economic,query-batch-market"  # Comma-separated if multiple
  verification_agent: "fact-checker"
  verification_timestamp: "2025-10-27T12:00:00Z"
```

### Benefits Demonstrated

- Claim answers 5 specific research questions (clear traceability)
- Belongs to "Economic Analysis" dimension (contextual grouping)
- Related to 2 thematic megatrends (synthesis organization)
- Preserves technical audit trail (query batches as string)
- Maintains source provenance chain (findings → sources)
- Extracts actual source IDs from findings (no placeholder)
- **ALL wikilinks are workspace-relative** (resolve from Obsidian vault root)

## Integration with Fact-Checker Workflow

1. Load finding content (Phase 1)
2. Extract atomic claims (Phase 2)
3. Calculate evidence confidence (Phase 3)
4. Calculate claim quality (Phase 4)
5. **Execute wikilink extraction (Phase 5)** ← These 5 algorithms + generate-wikilink.sh
6. Create claim entity with provenance (Phase 6)

## Usage Notes

- **MANDATORY: Use generate-wikilink.sh for ALL wikilinks** (ensures workspace-relative paths)
- Execute all 5 algorithms for each claim
- Handle errors gracefully (use empty arrays)
- Never use placeholder wikilinks (prefer empty array)
- Deduplicate arrays before writing to YAML
- Use English slugs in wikilinks (not localized names)
- **NEVER hardcode project-relative paths** (breaks multi-project vaults)
- **DO NOT modify extracted entity names** (no "dimension-" prefix, no "megatrend-" prefix)
- Always validate target file exists before creating wikilink
