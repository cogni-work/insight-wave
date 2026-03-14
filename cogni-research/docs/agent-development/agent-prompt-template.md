# Agent Template Reference
**Version**: 2.0.0
**Last Updated**: 2025-01-07
**Purpose**: Comprehensive template for creating new agents in the deeper-research plugin with documentation and best practices
**Audience**: Developers creating or refactoring agents

---

## Overview

This template serves as both:
1. **Copy-paste template**: Start new agents by copying sections
2. **Documentation**: Understand why each section exists and what standards to follow
3. **Best practices guide**: Learn from patterns across high-quality agents

**Key Principles:**
- **Phase 0-5 Standard**: All agents follow consistent workflow structure
- **Complete Data Loading**: Anti-hallucination through full entity reading
- **JSON-only Output**: Enable orchestration integration
- **Graceful Error Handling**: Continue processing when possible, fail fast when necessary
- **Comprehensive Logging**: Track execution for debugging and auditing

---

## Section 1: YAML Frontmatter (REQUIRED)

**Purpose**: Provide metadata for agent discovery, orchestration, and integration.

**Standard Format:**
```yaml
---
name: {{AGENT_NAME}}
description: {{ONE_LINE_DESCRIPTION_WITH_USE_CASE}}
tools: {{COMMA_SEPARATED_TOOL_LIST}}
model: {{CLAUDE_MODEL_ID}}
---
```

### Field Specifications

#### `name` (REQUIRED)
- **Format**: kebab-case (lowercase with hyphens)
- **Length**: 2-4 words maximum
- **Examples**:
  - ✅ `source-creator`
  - ✅ `fact-checker`
  - ✅ `citation-generator`
  - ❌ `source_creator` (wrong case)
  - ❌ `create-source-entities-from-findings` (too long)

#### `description` (REQUIRED)
- **Format**: Single sentence (80-150 chars) with use case context
- **Structure**: `{What agent does} with {key features}. {When to use} in {workflow context}.`
- **Examples**:
  - ✅ `Extract source metadata from findings and create source entities with deduplication. Orchestrator assigns findings via --finding-list-file parameter (file-based contract). Use for Phase 6.1 source creation in deeper-research workflow.`
  - ✅ `Verify claims with dual-layer scoring (evidence reliability + claim quality). Uses 5-factor evidence confidence and 4-dimension quality framework based on Wright et al. (2022) research. Use for Phase 6 parallel fact verification in deeper-research workflow with partition-aware processing.`
  - ❌ `This agent creates sources` (too vague, no context)

#### `tools` (REQUIRED)
- **Format**: Comma-separated list of tool names
- **Standard Tools**: `Read, Write, Bash, Grep, Glob`
- **Order**: Most frequently used first
- **Examples**:
  - ✅ `Read, Write, Bash` (most agents)
  - ✅ `Read, Bash` (read-only agents)
  - ❌ `all` (be specific)

#### `model` (REQUIRED)
- **Purpose**: Specify Claude model for task complexity
- **Standard Models**:
  - `claude-haiku-4-5`: Fast, lightweight tasks (metadata extraction, validation)
  - `claude-sonnet-4-5`: Complex reasoning, multi-strategy matching
  - `claude-sonnet-4-5-20250929`: Specific version for reproducibility
- **When to Choose**:
  - **Haiku**: Simple CRUD, straightforward data processing
  - **Sonnet**: Complex logic, multi-step reasoning, quality evaluation

### Example Frontmatters

**Simple Agent (Haiku):**
```yaml
---
name: source-creator
description: Extract source metadata from findings and create source entities with deduplication. Use for Phase 6.1 in deeper-research workflow.
tools: Read, Write, Bash
model: claude-haiku-4-5
---
```

**Complex Agent (Sonnet):**
```yaml
---
name: fact-checker
description: Verify claims with dual-layer scoring (evidence reliability + claim quality). Uses 5-factor evidence confidence and 4-dimension quality framework. Use for Phase 6 parallel fact verification.
tools: Read, Write, Bash
model: claude-sonnet-4-5-20250929
---
```

---

## Section 2: Your Role (REQUIRED)

**Purpose**: Establish agent identity, domain expertise, and operational context.

**Standard Format:**
```markdown
## Your Role

<context>
You are a {{SPECIALIST_TITLE}} who {{PRIMARY_RESPONSIBILITY}}. Your expertise includes {{KEY_CAPABILITIES_LIST}} and {{ANTI_HALLUCINATION_EMPHASIS}}.
</context>
```

### Writing Guidelines

1. **Specialist Title**: Use domain-specific role names
   - ✅ "fact-checking specialist"
   - ✅ "citation generation specialist"
   - ✅ "research source metadata specialist"
   - ❌ "an agent that" (too generic)

2. **Primary Responsibility**: One clear sentence about core function
   - Focus on WHAT the agent does
   - Include workflow integration context

3. **Key Capabilities**: 3-5 specific skills
   - Technical capabilities (APA formatting, multi-strategy matching)
   - Domain knowledge (evidence scoring, quality frameworks)
   - Data handling patterns (complete loading, deduplication)

4. **Anti-Hallucination Emphasis**: Highlight accuracy protocols
   - Complete data loading
   - Evidence-based decisions
   - No fabrication of data

### Examples

**Example 1: Source Creator**
```markdown
## Your Role

<context>
You are a research source metadata specialist who extracts source information from findings and creates deduplicated source entities with 4-tier reliability classification. You process orchestrator-assigned findings for parallel execution using centralized utilities for semantic slug generation and validation.
</context>
```

**Example 2: Fact Checker**
```markdown
## Your Role

<context>
You are a fact-checking specialist operating within a deeper-research workflow system. Your role is to extract atomic factual claims from research findings, verify them against source evidence, and assign multi-factor confidence scores with complete provenance tracking.
</context>
```

**Example 3: Citation Generator**
```markdown
## Your Role

<context>
You are a citation generation specialist responsible for creating formal APA citations by linking source entities to publisher entities through evidence-based publisher resolution. Your expertise includes APA 7th edition formatting, multi-language citation generation (English, German), multi-strategy publisher matching, and complete data loading to ensure accurate entity linking without hallucination.
</context>
```

---

## Section 3: Your Mission (REQUIRED)

**Purpose**: Define task, objectives, success criteria, and output format with crystal clarity.

**Standard Format:**
```markdown
## Your Mission

<task>
{{TASK_SUMMARY_SENTENCE}}

**Input Parameters:**
- `--param-name` (required): {{DESCRIPTION}}
- `--optional-param` (optional): {{DESCRIPTION_WITH_DEFAULT}}

**Critical Dependencies:**
- `script-name.sh`: {{PURPOSE_AND_VERSION}}
- `another-script.sh`: {{PURPOSE}}

**Your Objectives:**
1. {{OBJECTIVE_1}}
2. {{OBJECTIVE_2}}
3. {{OBJECTIVE_3}}
...

**Success Criteria:**
- {{CRITERION_1}}
- {{CRITERION_2}}
- {{CRITERION_3}}

**Output Format:**
```json
{
  "success": true,
  "key_metric_1": 42,
  "key_metric_2": 15
}
```
</task>
```

### Subsection Guidelines

#### Task Summary
- **Length**: 1-2 sentences maximum
- **Focus**: WHAT the agent accomplishes (not HOW)
- **Example**: `Generate formal APA citations for all sources by linking to publisher entities using complete data loading and multi-strategy publisher resolution.`

#### Input Parameters
- **List ALL parameters** (required and optional)
- **Format**: `--param-name` (type): Description
- **Include defaults** for optional parameters
- **Example**:
  ```markdown
  - `--project-path` (required): Absolute path to research project
  - `--language` (optional): Target language (default: "en")
  - `--partition` (optional): Process subset (format: "1/4")
  ```

#### Critical Dependencies
- **List external scripts/utilities** the agent calls
- **Include version numbers** if critical
- **Explain purpose** briefly
- **Example**:
  ```markdown
  - `create-entity.sh`: Entity creation with automatic deduplication
  - `validate-source-metadata.sh`: Pre-creation validation checkpoint
  - `extract-finding-title.sh`: Centralized title normalization (v2.0.0)
  ```

#### Your Objectives
- **3-7 numbered objectives**
- **Use action verbs**: Load, Generate, Validate, Write, Return
- **Ordered by execution**: Follow workflow sequence
- **Include verification steps**
- **Example**:
  ```markdown
  1. Load ALL sources completely (no truncation)
  2. Build comprehensive publisher lookup structures (4 strategies)
  3. Resolve publishers using multi-strategy matching
  4. Generate APA citations with validated publisher links
  5. Write citation entities to 09-citations/data/ directory
  6. Return JSON summary with statistics
  ```

#### Success Criteria
- **Measurable outcomes**: All sources processed, validation passed
- **Quality requirements**: No YAML artifacts, proper formatting
- **Integration requirements**: JSON-only response, idempotency
- **Example**:
  ```markdown
  - All sources processed completely
  - Citations generated with proper APA formatting
  - Publisher links resolved using best-match strategy
  - JSON-only response (no conversational text)
  ```

#### Output Format
- **Show EXACT JSON structure** expected
- **Include all fields** with example values
- **Document optional fields**
- **Add brief field explanations** if non-obvious
- **Example**:
  ```json
  {
    "success": true,
    "citations_created": 23,
    "citations_skipped": 2,
    "publisher_matches": {
      "domain_exact": 15,
      "name_exact": 5,
      "reverse_index": 2,
      "domain_fallback": 1
    },
    "warnings": ["Optional: warning messages if any"]
  }
  ```

### Complete Examples

**Example 1: Simple Agent (Source Creator)**
```markdown
## Your Mission

<task>
Extract metadata from findings, create source entities with automatic deduplication, validate completeness, update findings with source backlinks, write validation report, and return JSON statistics.

**Parameters:**
- `--project-path` (required): Absolute path to research project
- `--finding-list-file` (required): Path to file containing finding paths (one per line)
- `--language` (optional): Target language (default: en)

**Critical Dependencies:**
- `create-entity.sh`: Entity creation with automatic deduplication
- `validate-source-metadata.sh`: Pre-creation validation checkpoint
- `extract-finding-title.sh`: Centralized title normalization (v2.0.0)
- `generate-semantic-slug.sh`: Content-addressable slug generation

**Output:** JSON-only response (no text before/after):
```json
{
  "success": true,
  "sources_created": 18,
  "sources_reused": 5,
  "validation_passed": true,
  "findings_updated": 23
}
```
</task>
```

**Example 2: Complex Agent (Fact Checker)**
```markdown
## Your Mission

<task>
Process research findings, extract atomic factual claims, verify claims against source evidence, and create individual claim entities with confidence scores and full provenance tracking.

**Input Variables:**

<project_path>{{PROJECT_PATH}}</project_path>
<partition_index>{{PARTITION_INDEX}}</partition_index>
<total_partitions>{{TOTAL_PARTITIONS}}</total_partitions>
<language>{{LANGUAGE}}</language>

**Success Criteria:**
- All assigned findings processed systematically
- Atomic claims extracted and verified against source text
- Confidence scores calculated using 5-factor methodology
- Complete provenance chain for each claim
- Machine-readable statistics delivered to file system

**Output:** Write statistics JSON to `{PROJECT_PATH}/.metadata/partition-{PARTITION_INDEX}-stats.json`:
```json
{
  "success": true,
  "findings_processed": 35,
  "claims_created": 127,
  "avg_evidence_confidence": 0.82,
  "avg_claim_quality": 0.75,
  "flagged_for_review": 15
}
```
</task>
```

---

## Section 4: Constraints (REQUIRED)

**Purpose**: Define scope boundaries, quality requirements, and anti-hallucination protocols.

**Standard Format:**
```markdown
## Constraints

<constraints>

**Scope Boundaries:**
- DO NOT {{PROHIBITED_ACTION_1}}
- DO NOT {{PROHIBITED_ACTION_2}}
- DO NOT {{PROHIBITED_ACTION_3}}

**Quality Requirements:**
- ALWAYS {{QUALITY_REQUIREMENT_1}}
- ALWAYS {{QUALITY_REQUIREMENT_2}}
- MUST {{MANDATORY_BEHAVIOR}}

**Anti-Hallucination Protocol:**
- NEVER {{FABRICATION_PROHIBITION_1}}
- NEVER {{FABRICATION_PROHIBITION_2}}
- ALWAYS {{VERIFICATION_REQUIREMENT}}

</constraints>
```

### Subsection Guidelines

#### Scope Boundaries
- **What agent MUST NOT do**: Clearly define out-of-scope actions
- **Prevent scope creep**: Agent focuses on single responsibility
- **Examples**:
  ```markdown
  - DO NOT create source entities (read existing sources only)
  - DO NOT create publisher entities (read existing publishers only)
  - DO NOT modify existing source or publisher entities
  ```

#### Quality Requirements
- **Positive requirements**: What agent MUST do
- **Use imperative verbs**: ALWAYS, MUST, REQUIRED
- **Focus on measurable behaviors**
- **Examples**:
  ```markdown
  - ALWAYS read complete file contents (no line limits)
  - ALWAYS verify all sources loaded before processing
  - MUST return JSON-only responses (no conversational text)
  ```

#### Anti-Hallucination Protocol
- **Fabrication prohibitions**: What agent NEVER invents
- **Verification requirements**: What agent ALWAYS checks
- **Complete data loading emphasis**: Why truncation is dangerous
- **Examples**:
  ```markdown
  - NEVER fabricate DOIs or PMIDs
  - NEVER invent author affiliations or credentials
  - ALWAYS base publisher matching on loaded entity content only
  - IF publisher loading incomplete → STOP and re-read, DO NOT proceed
  ```

### Complete Example (Citation Generator)

```markdown
## Constraints

<constraints>

**Scope Boundaries:**
- DO NOT create source entities (read existing sources only)
- DO NOT create publisher entities (read existing publishers only)
- DO NOT process findings (citation generation only)
- DO NOT modify existing source or publisher entities

**Complete Data Loading Requirements (Anti-Hallucination):**
- ALWAYS read complete file contents (no line limits)
- ALWAYS verify all sources loaded before processing
- ALWAYS verify all publishers loaded before indexing
- NEVER skip entities to save "time" - completeness prevents fabrication
- NEVER begin processing until all entities fully loaded and verified
- ALWAYS log entity counts for verification

**Anti-Hallucination Safeguards:**
- ALWAYS base publisher matching on loaded entity content only
- NEVER fabricate publisher links when no match found (use domain fallback)
- NEVER invent publisher entities not in loaded files
- NEVER assume publisher exists without verification
- IF publisher loading incomplete → STOP and re-read, DO NOT proceed

**WHY COMPLETE READING MATTERS:**

Truncated loading (e.g., first 20 lines only) creates critical hallucination risk:
- Agent sees partial publisher data → May fabricate or miss matches
- Citations include plausible-sounding links not in actual data
- Knowledge graph integrity compromised by invented connections

Complete entity loading ensures:
- Every publisher match traceable to actual loaded content
- All publisher metadata available for multi-strategy matching
- Citations reference real publisher entities validated in files

**Critical Requirements:**
- ALWAYS write citations to 09-citations/data/ directory
- ALWAYS include 07-sources/data/ prefix in source wikilinks
- ALWAYS validate citation text before writing
- MUST generate semantic citation IDs reusing source slugs

</constraints>
```

---

## Section 5: Instructions (REQUIRED)

**Purpose**: Define executable workflow with phases, bash scripts, and decision logic.

**Standard Format:**
```markdown
## Instructions

<instructions>

### Phase 0: Environment & Working Directory Validation

{{ENVIRONMENT_SETUP}}
{{WORKING_DIRECTORY_VALIDATION}}

### Phase 1: Input Validation & Parameter Parsing

{{PARAMETER_VALIDATION}}
{{LOGGING_INITIALIZATION}}
{{SCRIPT_PATH_RESOLUTION}}

### Phase 2: Data Loading & Preparation

{{ENTITY_LOADING}}
{{VERIFICATION_CHECKPOINTS}}

### Phase 3: Core Processing Logic

{{MAIN_ALGORITHM}}
{{ITERATION_LOGIC}}
{{ERROR_HANDLING}}

### Phase 4: Output Generation & Writing

{{ENTITY_CREATION}}
{{FILE_WRITING}}
{{VALIDATION}}

### Phase 5: Metadata Return (JSON)

{{STATISTICS_CALCULATION}}
{{JSON_GENERATION}}

</instructions>
```

### Phase 0: Environment & Working Directory Validation (REQUIRED)

**Purpose**: Validate environment variables and establish correct working directory.

**Pattern 1: CLAUDE_PLUGIN_ROOT Validation**
```bash
# Validate CLAUDE_PLUGIN_ROOT environment variable
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set. Please configure: export CLAUDE_PLUGIN_ROOT=/path/to/cogni-research"}\n'
  exit 1
fi
```

**Pattern 2: Working Directory Validation (4-Step)**
```bash
# CRITICAL: Agent threads reset cwd between bash calls
# This prevents relative path failures when accessing project resources
# Without this validation, operations may execute in wrong directory

log "DEBUG" "Validating PROJECT_PATH parameter"

# Step 1: Validate PROJECT_PATH variable exists and is not empty
if [ -z "$PROJECT_PATH" ]; then
  log "ERROR" "Missing required parameter: --project-path"
  printf '{"success": false, "error": "Missing required parameter: --project-path"}\n'
  exit 1
fi

log "DEBUG" "PROJECT_PATH = $PROJECT_PATH"

# Step 2: Verify directory exists at PROJECT_PATH
if [ ! -d "$PROJECT_PATH" ]; then
  log "ERROR" "Project directory not found: $PROJECT_PATH"
  printf '{"success": false, "error": "Project directory not found: %s"}\n' "$PROJECT_PATH"
  exit 1
fi

log "DEBUG" "Project directory exists"

# Step 3: Change working directory to PROJECT_PATH
cd "$PROJECT_PATH" 2>/dev/null

# Step 4: Verify cd succeeded by checking exit code
if [ $? -ne 0 ]; then
  log "ERROR" "Failed to change to project directory: $PROJECT_PATH"
  printf '{"success": false, "error": "Failed to change to project directory: %s"}\n' "$PROJECT_PATH"
  exit 1
fi

log "INFO" "Working directory validation successful: $(pwd)"
```

**Why This Pattern:**
- Agent threads reset cwd between bash invocations
- Relative paths will fail without cd to project directory
- 4-step validation ensures all edge cases handled
- Logging provides audit trail for debugging

### Phase 1: Input Validation & Parameter Parsing (REQUIRED)

**Purpose**: Parse parameters, initialize logging, set script paths.

**Step 1.1: Parameter Parsing**

**Simple Pattern (Named Parameters):**
```bash
# Parse required parameters
PROJECT_PATH=""
FINDING_FILES=""
LANGUAGE="en"  # Default

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --finding-list-file)
      FINDING_LIST_FILE="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1" >&2
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing --project-path"}'
  exit 1
fi

if [ -z "$FINDING_LIST_FILE" ]; then
  echo '{"success": false, "error": "Missing --finding-list-file"}'
  exit 1
fi
if [ ! -f "$FINDING_LIST_FILE" ]; then
  echo "{\"success\": false, \"error\": \"Finding list file not found: $FINDING_LIST_FILE\"}"
  exit 1
fi
# Read file and convert to comma-separated for internal processing
FINDING_FILES=$(cat "$FINDING_LIST_FILE" | tr '\n' ',' | sed 's/,$//')
```

**Step 1.2: Logging Initialization (OPTIONAL but RECOMMENDED)**

**Pattern: Structured Logging with File Output**
```bash
# ===== LOGGING INITIALIZATION =====
AGENT_NAME="{{AGENT_NAME}}"
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"

# Ensure metadata directory exists
mkdir -p "${PROJECT_PATH}/.metadata" 2>/dev/null || true

# Logging utility function
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local log_entry="[$timestamp] [$level] ${AGENT_NAME}: $message"
  echo "$log_entry" >&2
  echo "$log_entry" >> "${LOG_FILE}" 2>/dev/null || true
}

# Initialize log file
echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

log "INFO" "========== Phase 1: INPUT VALIDATION =========="
log "INFO" "Parameter: PROJECT_PATH = ${PROJECT_PATH}"
log "INFO" "Parameter: LANGUAGE = ${LANGUAGE}"
```

**When to Use Logging:**
- ✅ Agents with complex multi-step processing
- ✅ Agents calling multiple external scripts
- ✅ Agents that run in parallel (partition mode)
- ✅ Agents with error-prone operations
- ❌ Simple read-only agents
- ❌ Test/validation agents

**Step 1.3: Script Path Resolution (REQUIRED if using utilities)**

**Pattern: Readonly Variables with CLAUDE_PLUGIN_ROOT**
```bash
log "DEBUG" "Setting script paths using CLAUDE_PLUGIN_ROOT"

# Set script paths using CLAUDE_PLUGIN_ROOT from settings.local.json
readonly SCRIPT_EXTRACT_TITLE="${CLAUDE_PLUGIN_ROOT}/scripts/extract-finding-title.sh"
readonly SCRIPT_GENERATE_SLUG="${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh"
readonly SCRIPT_VALIDATE_METADATA="${CLAUDE_PLUGIN_ROOT}/scripts/validate-source-metadata.sh"
readonly SCRIPT_CREATE_ENTITY="${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh"

log "DEBUG" "Script paths configured"
```

**Why Readonly:**
- Prevents accidental modification
- Signals these are constants
- Defensive programming practice

### Phase 2: Data Loading & Preparation (OPTIONAL - Use for Entity-Based Agents)

**Purpose**: Load all required entities completely to prevent hallucination.

**Pattern: Complete Entity Loading with Verification**

```bash
log "INFO" "========== Phase 2: COMPLETE ENTITY LOADING =========="

# Count entities first for verification
SOURCE_COUNT=$(find "${PROJECT_PATH}/07-sources" -name "source-*.md" 2>/dev/null | wc -l | tr -d ' ')
log "INFO" "Loading $SOURCE_COUNT sources completely (no truncation)..."
echo "INFO: Loading $SOURCE_COUNT sources completely (no truncation)..." >&2

# Collect source IDs
SOURCES_LOADED=()
for source_file in "${PROJECT_PATH}"/07-sources/data/source-*.md; do
  [ -f "$source_file" ] || continue
  source_id=$(basename "$source_file" .md)
  SOURCES_LOADED+=("$source_id")
  echo "Loaded source: $source_id" >&2
done

# Verify count matches
if [ ${#SOURCES_LOADED[@]} -ne "$SOURCE_COUNT" ]; then
  log "ERROR" "Source count mismatch: expected $SOURCE_COUNT, loaded ${#SOURCES_LOADED[@]}"
  echo '{"success": false, "error": "Source count mismatch"}' >&2
  exit 1
fi

log "INFO" "VERIFICATION: All $SOURCE_COUNT sources loaded completely"
echo "VERIFICATION: All $SOURCE_COUNT sources loaded completely" >&2

# VERIFICATION CHECKPOINT: Confirm completeness before proceeding
if [ ${#SOURCES_LOADED[@]} -eq 0 ]; then
  log "INFO" "No sources to process - exiting with success"
  echo '{"success": true, "processed": 0}'
  exit 0
fi

log "INFO" "==========================================="
log "INFO" "CHECKPOINT: Complete entity loading verified"
log "INFO" "  Sources: ${#SOURCES_LOADED[@]}"
log "INFO" "  Ready to proceed with processing"
log "INFO" "==========================================="
```

**Anti-Hallucination Principles:**
1. **Count first**: Know how many entities to expect
2. **Load completely**: No truncation (no `head -20`)
3. **Verify match**: Loaded count must equal expected count
4. **Checkpoint**: Explicit verification before proceeding
5. **Log counts**: Audit trail for debugging
6. **Handle empty**: Graceful exit if no entities found

**When to Use Complete Loading:**
- ✅ Agents that reference multiple entities (citation generation)
- ✅ Agents that need cross-entity validation (fact checking)
- ✅ Agents that build lookup structures (publisher matching)
- ❌ Agents processing single assigned entities
- ❌ Agents with explicit file paths provided

### Phase 3: Core Processing Logic (REQUIRED)

**Purpose**: Execute main algorithm with iteration, error handling, and progress tracking.

**Pattern 1: Simple Iteration (Process Assigned Entities)**

```bash
log "INFO" "========== Phase 3: CORE PROCESSING =========="

# Initialize counters
entities_created=0
entities_skipped=0

# Process each assigned entity
for entity_file in "${ENTITIES_TO_PROCESS[@]}"; do
  log "INFO" "Processing: $entity_file"
  echo "Processing: $entity_file" >&2

  # Extract metadata
  FIELD_1=$(grep "^field1:" "$entity_file" | head -1 | sed 's/^field1:[[:space:]]*//' | sed 's/"//g')
  FIELD_2=$(grep "^field2:" "$entity_file" | head -1 | sed 's/^field2:[[:space:]]*//' | sed 's/"//g')

  # Validate extracted values
  if [ -z "$FIELD_1" ] || [ -z "$FIELD_2" ]; then
    log "WARN" "Missing required fields in $entity_file, skipping"
    entities_skipped=$((entities_skipped + 1))
    continue
  fi

  # Call processing logic
  result=$(process_entity "$FIELD_1" "$FIELD_2")

  # Check result
  if [ $? -eq 0 ]; then
    log "INFO" "✓ Successfully processed: $entity_file"
    entities_created=$((entities_created + 1))
  else
    log "ERROR" "✗ Failed to process: $entity_file"
    entities_skipped=$((entities_skipped + 1))
  fi
done

log "INFO" "Processing complete: $entities_created created, $entities_skipped skipped"
```

**Pattern 2: Multi-Strategy Resolution (Complex Matching)**

```bash
log "INFO" "========== Phase 3: MULTI-STRATEGY RESOLUTION =========="

# Build lookup structures (Bash 3.2 compatible - parallel indexed arrays)
LOOKUP_DOMAIN_KEYS=()
LOOKUP_DOMAIN_VALUES=()
LOOKUP_NAME_KEYS=()
LOOKUP_NAME_VALUES=()

for entity in "${ENTITIES[@]}"; do
  domain=$(extract_field "$entity" "domain")
  name=$(extract_field "$entity" "name")

  LOOKUP_DOMAIN_KEYS+=("$domain")
  LOOKUP_DOMAIN_VALUES+=("$entity")
  LOOKUP_NAME_KEYS+=("$name")
  LOOKUP_NAME_VALUES+=("$entity")
done

log "INFO" "Built lookup structures: ${#LOOKUP_DOMAIN_KEYS[@]} by domain, ${#LOOKUP_NAME_KEYS[@]} by name"

# Lookup helper function
lookup_by_key() {
  local keys_ref="$1[@]"
  local values_ref="$2[@]"
  local search_key="$3"
  local keys=("${!keys_ref}")
  local values=("${!values_ref}")
  local i=0
  for key in "${keys[@]}"; do
    if [ "$key" = "$search_key" ]; then
      echo "${values[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

# Process with multi-strategy matching
for source in "${SOURCES[@]}"; do
  source_domain=$(extract_domain "$source")
  source_name=$(extract_name "$source")

  MATCHED_ENTITY=""
  MATCH_STRATEGY=""

  # Strategy 1: Domain exact match
  if [ -z "$MATCHED_ENTITY" ]; then
    match=$(lookup_by_key LOOKUP_DOMAIN_KEYS LOOKUP_DOMAIN_VALUES "$source_domain") && {
      MATCHED_ENTITY="$match"
      MATCH_STRATEGY="domain_exact"
      log "INFO" "✓ Strategy 1: $source_domain → $MATCHED_ENTITY"
    }
  fi

  # Strategy 2: Name exact match
  if [ -z "$MATCHED_ENTITY" ]; then
    match=$(lookup_by_key LOOKUP_NAME_KEYS LOOKUP_NAME_VALUES "$source_name") && {
      MATCHED_ENTITY="$match"
      MATCH_STRATEGY="name_exact"
      log "INFO" "✓ Strategy 2: $source_name → $MATCHED_ENTITY"
    }
  fi

  # Strategy 3: Fallback
  if [ -z "$MATCHED_ENTITY" ]; then
    MATCH_STRATEGY="fallback"
    log "WARN" "⚠ Strategy 3 (fallback): No match for $source"
  fi

  # Use matched entity or fallback
  process_with_strategy "$source" "$MATCHED_ENTITY" "$MATCH_STRATEGY"
done
```

**Pattern 3: Error Handling with Skip Tracking**

```bash
log "INFO" "========== Phase 3: PROCESSING WITH ERROR TRACKING =========="

# Initialize tracking
SKIPPED_ITEMS='[]'

for item in "${ITEMS[@]}"; do
  # Try processing
  result=$(process_item "$item" 2>&1)

  # Check for errors
  if [ $? -ne 0 ]; then
    log "ERROR" "Processing failed for $item: $result"

    # Track skip reason
    SKIP_ENTRY=$(jq -n \
      --arg item_id "$item" \
      --arg skip_reason "processing_failed" \
      --arg error "${result:0:200}" \
      '{item_id: $item_id, skip_reason: $skip_reason, error: $error}')

    SKIPPED_ITEMS=$(echo "$SKIPPED_ITEMS" | jq --argjson entry "$SKIP_ENTRY" '. + [$entry]')
    continue
  fi

  # Success
  log "INFO" "✓ Processed: $item"
done

# Write skip report
SKIP_COUNT=$(echo "$SKIPPED_ITEMS" | jq 'length')
log "INFO" "Skipped $SKIP_COUNT items, writing report"

echo "$SKIPPED_ITEMS" > "${PROJECT_PATH}/.metadata/${AGENT_NAME}-skipped-items.json"
```

**Key Patterns:**
- **Initialize counters** at start of phase
- **Log progress** for each iteration
- **Validate before processing** (fail fast on bad input)
- **Track skipped items** with reasons (don't lose data)
- **Continue on recoverable errors** (resilience)
- **Exit on fatal errors** (fail fast when necessary)

### Phase 4: Output Generation & Writing (REQUIRED)

**Purpose**: Create entities, write files, validate output.

**Pattern 1: Entity Creation with Deduplication**

```bash
log "INFO" "========== Phase 4: ENTITY CREATION =========="

# Prepare entity data
DATA_JSON=$(jq -n \
  --arg name "$NAME" \
  --arg field1 "$FIELD1" \
  --arg field2 "$FIELD2" \
  '{
    frontmatter: {
      name: $name,
      field1: $field1,
      field2: $field2,
      tags: ["entity", "type/category"],
      "dc:creator": "{{AGENT_NAME}}",
      "dc:type": "entity"
    },
    content: ""
  }')

# Create entity (handles deduplication automatically)
log "TRACE" "Calling create-entity.sh"
result=$(bash "$SCRIPT_CREATE_ENTITY" \
  --project-path "$PROJECT_PATH" \
  --entity-type "{{ENTITY_DIR}}" \
  --entity-id "$ENTITY_ID" \
  --data "$DATA_JSON" \
  --json 2>&1)

# Validate script execution
if [ $? -ne 0 ]; then
  log "ERROR" "create-entity.sh execution failed"
  log "DEBUG" "  Output: ${result:0:200}"
  continue  # Skip this entity, continue with others
fi

# Validate JSON output
if ! echo "$result" | jq -e . >/dev/null 2>&1; then
  log "ERROR" "create-entity.sh returned invalid JSON"
  continue
fi

# Check if reused or created
if [ "$(echo "$result" | jq -r '.reused')" = "true" ]; then
  ENTITY_ID=$(echo "$result" | jq -r '.entity_id')
  entities_reused=$((entities_reused + 1))
  log "INFO" "Entity reused (deduplication): $ENTITY_ID"
else
  ENTITY_ID=$(echo "$result" | jq -r '.entity_id')
  entities_created=$((entities_created + 1))
  log "INFO" "Entity created: $ENTITY_ID"
fi
```

**Pattern 2: Direct File Writing with Validation**

```bash
log "INFO" "========== Phase 4: FILE WRITING =========="

# Generate entity ID
ENTITY_ID="{{PREFIX}}-${SEMANTIC_SLUG}-${HASH}"
ENTITY_FILE="${PROJECT_PATH}/{{ENTITY_DIR}}/${ENTITY_ID}.md"

# Create entity file
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$ENTITY_FILE" <<EOF
---
# Obsidian Tags
tags: [entity, type/category]

# Dublin Core Metadata
dc:creator: "{{AGENT_NAME}}"
dc:title: "$TITLE"
dc:date: "$TIMESTAMP"
dc:identifier: "$ENTITY_ID"
dc:type: "entity"

# Legacy Fields
entity_type: "entity"
field1: "$FIELD1"
field2: "$FIELD2"
created_at: "$TIMESTAMP"
---

## Entity Content

$CONTENT

## Metadata

- **Field 1**: $FIELD1
- **Field 2**: $FIELD2
EOF

# Verify file was written
if [ -f "$ENTITY_FILE" ]; then
  LINE_COUNT=$(wc -l < "$ENTITY_FILE" | tr -d ' ')

  if [ "$LINE_COUNT" -lt 20 ]; then
    log "WARN" "Entity $ENTITY_ID suspiciously small ($LINE_COUNT lines)"
  fi

  log "INFO" "✓ Entity written: $ENTITY_FILE ($LINE_COUNT lines)"
  entities_created=$((entities_created + 1))
else
  log "ERROR" "✗ Failed to write entity: $ENTITY_FILE"
  entities_failed=$((entities_failed + 1))
fi
```

**Validation Checklist:**
- ✅ Verify script execution succeeded (`$? -eq 0`)
- ✅ Validate JSON output is parseable
- ✅ Check success field in script response
- ✅ Verify file exists after writing
- ✅ Check file is not suspiciously small
- ✅ Validate no YAML artifacts in content
- ✅ Log creation/reuse/failure

### Phase 5: Metadata Return (JSON) (REQUIRED)

**Purpose**: Calculate statistics, generate JSON response, validate output.

**Pattern: JSON-Only Response with Pre-Return Validation**

```bash
log "INFO" "========== Phase 5: METADATA RETURN =========="
log "INFO" "Summary statistics:"
log "INFO" "  Entities created: $entities_created"
log "INFO" "  Entities reused: $entities_reused"
log "INFO" "  Entities skipped: $entities_skipped"
log "INFO" "========================================="
log "INFO" "Execution completed successfully"
log "INFO" "========================================="

# Generate JSON response (ONLY output to stdout)
cat <<EOF
{
  "success": true,
  "entities_created": ${entities_created},
  "entities_reused": ${entities_reused},
  "entities_skipped": ${entities_skipped},
  "validation_passed": true
}
EOF

exit 0
```

**Pre-Return Validation Checklist:**
- ✅ Response contains ONLY JSON (no text before/after)
- ✅ JSON is well-formed and parseable
- ✅ All required fields present
- ✅ success field is boolean
- ✅ All counts are non-negative integers
- ✅ No explanatory text like "Now I'll return..."
- ✅ No conversational preambles

**JSON Response Guidelines:**

1. **Success Field (REQUIRED)**
   ```json
   "success": true  // Boolean, not string
   ```

2. **Count Fields (Use Descriptive Names)**
   ```json
   "entities_created": 42,
   "entities_reused": 5,
   "entities_skipped": 2,
   "entities_failed": 0
   ```

3. **Optional Metadata**
   ```json
   "warnings": ["Warning message 1", "Warning message 2"],
   "metadata": {
     "strategy_breakdown": {
       "strategy1": 30,
       "strategy2": 12
     }
   }
   ```

4. **Error Response Format**
   ```json
   {
     "success": false,
     "error": "Descriptive error message",
     "error_code": "MISSING_PARAMETER",
     "details": {
       "parameter": "--project-path",
       "suggestion": "Provide absolute path to project"
     }
   }
   ```

---

## Section 6: Error Handling (REQUIRED)

**Purpose**: Define error detection, recovery strategies, and exit behaviors.

**Standard Format:**
```markdown
## Error Handling

| Scenario | Detection | Recovery | Exit |
|----------|-----------|----------|------|
| {{ERROR_SCENARIO_1}} | {{HOW_DETECTED}} | {{RECOVERY_ACTION}} | {{EXIT_CODE}} |
| {{ERROR_SCENARIO_2}} | {{HOW_DETECTED}} | {{RECOVERY_ACTION}} | {{EXIT_CODE}} |
| {{ERROR_SCENARIO_3}} | {{HOW_DETECTED}} | {{RECOVERY_ACTION}} | {{EXIT_CODE}} |
```

### Table Guidelines

1. **Scenario Column**: Describe error condition
   - Be specific (not "error occurs")
   - Use user/system terminology
   - Examples: "Missing --finding-list-file", "Title extraction fails", "Entity creation fails"

2. **Detection Column**: How error is identified
   - Empty parameter check
   - Script exit code
   - JSON validation
   - Field value check

3. **Recovery Column**: What agent does
   - **Return error JSON**: Fatal errors
   - **Skip, warn stderr, continue**: Recoverable item errors
   - **Abort with error**: Data corruption risks
   - **Log warning, continue**: Non-critical issues

4. **Exit Column**: Exit code
   - **0**: Success (even if some items skipped)
   - **1**: Fatal error (cannot continue)

### Complete Example (Source Creator)

```markdown
## Error Recovery

| Scenario | Detection | Recovery | Exit |
|----------|-----------|----------|------|
| Missing --finding-list-file | Empty parameter | Return error JSON | 1 |
| Missing source_url | Frontmatter lacks URL | Skip, warn stderr, continue | 0 |
| Title extraction fails | Utility error | Skip, add to report, continue | 0 |
| URL validation fails | Contains field name/invalid | Skip, add to report, continue | 0 |
| Domain extraction fails | Invalid characters | Skip, add to report, continue | 0 |
| Metadata validation fails | Script returns false | Skip, add to report, continue | 0 |
| Entity creation fails | Script error | Abort with error | 1 |
| Completeness validation fails | Count mismatch | Return error JSON with details | 1 |
| Backlink update fails | File not found/write error | Warn stderr, continue (non-fatal) | 0 |
```

### Error Handling Patterns

**Pattern 1: Fatal Error (Abort Immediately)**
```bash
if [ -z "$PROJECT_PATH" ]; then
  log "ERROR" "Missing required parameter: --project-path"
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 1
fi
```

**Pattern 2: Recoverable Error (Skip Item, Continue)**
```bash
if [ -z "$TITLE" ]; then
  log "WARN" "Missing title for $entity_file, skipping"
  echo "WARNING: Missing title for $entity_file" >&2

  SKIP_ENTRY=$(jq -n \
    --arg id "$(basename "$entity_file" .md)" \
    --arg reason "missing_title" \
    '{id: $id, reason: $reason}')
  SKIPPED_ITEMS=$(echo "$SKIPPED_ITEMS" | jq --argjson entry "$SKIP_ENTRY" '. + [$entry]')

  continue  # Skip to next item
fi
```

**Pattern 3: Validation Error with Detailed Report**
```bash
if [ "$EXPECTED_TOTAL" -ne "$ACTUAL_TOTAL" ]; then
  MISSING_COUNT=$((EXPECTED_TOTAL - ACTUAL_TOTAL))
  log "ERROR" "Completeness validation failed: $MISSING_COUNT items unaccounted for"

  ERROR_JSON=$(jq -n \
    --argjson expected $EXPECTED_TOTAL \
    --argjson actual $ACTUAL_TOTAL \
    --argjson missing $MISSING_COUNT \
    --arg error "Completeness validation failed: $MISSING_COUNT items unaccounted for" \
    '{
      success: false,
      error: $error,
      expected: $expected,
      actual: $actual,
      missing: $missing,
      validation_passed: false
    }')

  echo "$ERROR_JSON" >&2
  exit 1
fi
```

**Decision Tree: When to Exit vs Continue**

```
Error Detected
│
├─ Can agent continue processing other items?
│  ├─ YES → Skip item, log warning, add to skip report, continue
│  │       (Examples: Missing field, validation fails for one item)
│  │
│  └─ NO → Return error JSON, exit 1
│          (Examples: Missing required parameter, working directory not found)
│
└─ Does error indicate data corruption or inconsistency?
   ├─ YES → Abort immediately, exit 1
   │        (Examples: Completeness validation fails, entity creation script broken)
   │
   └─ NO → Log warning, continue
           (Examples: Non-critical optional field missing, fallback strategy used)
```

---

## Section 7: Examples (REQUIRED - Minimum 2)

**Purpose**: Demonstrate agent usage with realistic scenarios and expected outputs.

**Standard Format:**
```markdown
## Examples

### Example 1: {{SCENARIO_NAME}}

**Scenario:** {{DESCRIBE_USE_CASE}}

**Invocation:**
```bash
agent-name --param1 value1 --param2 value2
```

**Process:**
1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

**Expected Output:**
```json
{
  "success": true,
  "key_metric": 42
}
```

**Key Points:**
- {{KEY_POINT_1}}
- {{KEY_POINT_2}}
```

### Example Categories

1. **Success Case (REQUIRED)**: Happy path with typical usage
2. **Edge Case**: Empty input, no entities, boundary conditions
3. **Error Case**: Show error handling in action
4. **Complex Scenario**: Multi-strategy, partition mode, repair mode
5. **Anti-Hallucination Example**: Show what NOT to do and correct behavior

### Complete Examples

**Example 1: Success Case**
```markdown
### Example 1: Successful Source Creation

**Scenario:** Process 23 findings and create source entities with deduplication

**Invocation:**
```bash
source-creator \
  --project-path /Users/name/research/climate-study \
  --finding-list-file /Users/name/research/climate-study/.metadata/finding-list.txt \
  --language en
```

**Process:**
1. Validate 23 finding files exist
2. Extract metadata (title, URL, domain) from each finding
3. Generate semantic slugs for deduplication
4. Create 18 new source entities + reuse 5 existing
5. Update all 23 findings with source_id backlinks
6. Write skip report (0 skipped)

**Expected Output:**
```json
{
  "success": true,
  "sources_created": 18,
  "sources_reused": 5,
  "validation_passed": true,
  "findings_updated": 23
}
```

**Key Points:**
- Deduplication prevented 5 duplicate sources
- All findings updated with backlinks (completeness validation passed)
- Semantic slugs enable consistent entity IDs
```

**Example 2: Edge Case (Empty Input)**
```markdown
### Example 2: No Findings to Process

**Scenario:** Invoked with empty findings directory

**Invocation:**
```bash
source-creator \
  --project-path /Users/name/research/empty-project \
  --finding-list-file /Users/name/research/empty-project/.metadata/finding-list.txt \
  --language en
```

**Process:**
1. Parse parameters (empty finding-files list)
2. Skip processing (no findings to process)
3. Return success with zero counts

**Expected Output:**
```json
{
  "success": true,
  "sources_created": 0,
  "sources_reused": 0,
  "validation_passed": true,
  "findings_updated": 0
}
```

**Key Points:**
- Empty input is NOT an error (valid edge case)
- Graceful handling prevents false alarms
- Exit code 0 (success)
```

**Example 3: Anti-Hallucination Example**
```markdown
### Example 3: Prevent Title Fabrication

**Finding Text:**
```markdown
---
source_url: "https://example.com/article"
---

# Finding Content

The article discusses climate change.
```

❌ **WRONG - Fabricating Title:**
```bash
# Agent extracts title inline without validation
TITLE="Climate Change Article"  # ← Invented, not in finding!
```

✅ **CORRECT - Using Centralized Utility:**
```bash
# Agent calls centralized utility
result=$(bash "$SCRIPT_EXTRACT_TITLE" \
  --finding-file "$FINDING_FILE" \
  --json)

# Validate extraction succeeded
if [ "$(echo "$result" | jq -r '.success')" != "true" ]; then
  log "ERROR" "Title extraction failed"
  # Skip this finding, don't fabricate
  continue
fi

TITLE=$(echo "$result" | jq -r '.data.normalized_title')
```

**Why This Matters:**
- Centralized utility has multi-strategy fallback
- Validation ensures title actually exists
- No title fabrication → knowledge graph integrity preserved
```

---

## Section 8: Quality Standards (OPTIONAL but RECOMMENDED)

**Purpose**: Provide checklist for validation and quality assurance.

**Standard Format:**
```markdown
## Quality Standards

**{{CATEGORY_1}} Checklist:**
- [ ] {{REQUIREMENT_1}}
- [ ] {{REQUIREMENT_2}}
- [ ] {{REQUIREMENT_3}}

**{{CATEGORY_2}} Checklist:**
- [ ] {{REQUIREMENT_1}}
- [ ] {{REQUIREMENT_2}}
```

### Categories to Include

1. **Entity Verification**: Check entity structure and content
2. **YAML Parsing**: Validate metadata extraction
3. **JSON Output**: Verify response format
4. **Anti-Hallucination**: Confirm no fabricated data
5. **Deduplication** (if applicable): Check reuse logic
6. **Complete Data Loading** (if applicable): Verify full entity reading

### Complete Example (Source Creator)

```markdown
## Quality Standards

**Source Entity Verification:**
- [ ] URL validated (https:// protocol, no field names)
- [ ] Domain clean (no colons, slashes, quotes)
- [ ] Title doesn't contain YAML comments
- [ ] Reliability tier (1-4) assigned
- [ ] DOI/PMID only if present in finding
- [ ] Name field included for deduplication
- [ ] Semantic UUID generated via utility
- [ ] Entity file exists and has >20 lines

**YAML Parsing Safety:**
- [ ] Use grep+sed (not grep alone)
- [ ] Strip field names from values
- [ ] Validate no colons in domains
- [ ] Title extraction uses centralized utility
- [ ] Validation checkpoint before entity creation
- [ ] Post-creation verification passed

**Deduplication Workflow:**
- [ ] All entities created via create-entity.sh
- [ ] Name field included in entity data
- [ ] Checked `.reused` field in response
- [ ] Incremented correct counter (created vs reused)

**Completeness Validation:**
- [ ] Tracked all processed findings
- [ ] Validated: processed + skipped = total findings
- [ ] Returned error JSON if counts don't match
- [ ] Updated all findings with backlinks

**JSON Output Verification:**
- [ ] NO text before JSON
- [ ] NO text after JSON
- [ ] NO conversational preambles
- [ ] Response passes `JSON.parse()` test
- [ ] All required fields present
- [ ] `validation_passed` is boolean
```

---

## Anti-Hallucination Protocol Variations

**Purpose**: Provide different anti-hallucination protocols for various agent types.

### Variation 1: Evidence-Based Extraction Only

**Use Case**: Agents extracting data from existing entities

```markdown
## Anti-Hallucination Protocol

**NEVER:**
- Fabricate metadata not in source entity
- Invent relationships between entities
- Enhance titles or descriptions beyond source content
- Generate wikilinks before creating entities
- Assume fields exist without validation

**ALWAYS:**
- Read complete entity files (no truncation)
- Validate extracted values before use
- Use proper YAML parsing (grep+sed)
- Check for empty/null values
- Leave missing data blank rather than guess
- Base all decisions on loaded entity content only
```

### Variation 2: Complete Entity Loading (Multi-Entity Agents)

**Use Case**: Agents that need to cross-reference multiple entities

```markdown
## Anti-Hallucination Protocol

**Complete Data Loading Requirements:**
- ALWAYS read ALL entities completely (no line limits, no truncation)
- ALWAYS verify entity counts before processing
- NEVER skip entities to "save time" - completeness prevents fabrication
- NEVER begin processing until verification checkpoint passed
- IF entity loading incomplete → STOP and re-read, DO NOT proceed

**Why Complete Loading Matters:**

Truncated loading (e.g., first 20 lines only) creates hallucination risk:
- Agent sees partial data → May fabricate missing information
- Relationships may reference entities not in loaded set
- Knowledge graph integrity compromised by invented connections

Complete loading ensures:
- Every relationship traceable to loaded entity
- All metadata available for matching
- No plausible-sounding fabrications
```

### Variation 3: Confidence Scoring (Quality Evaluation Agents)

**Use Case**: Agents that assess evidence quality and assign scores

```markdown
## Anti-Hallucination Protocol

**Source Fidelity Requirements:**
- NEVER strengthen language beyond source (e.g., "may" → "does")
- ALWAYS preserve uncertainty qualifiers ("suggests", "likely", "appears to")
- NEVER merge multiple claims into compound statement
- ALWAYS verify claim text exists in source finding
- IF claim references "the study" → Rewrite with specific entity name

**Scoring Integrity:**
- NEVER fabricate confidence metrics
- ALWAYS base scores on loaded evidence only
- NEVER assume source quality without checking tier
- ALWAYS document scoring rationale
- IF evidence insufficient → Flag for review, don't fabricate confidence
```

### Variation 4: Citation Generation (Linking Agents)

**Use Case**: Agents creating formal citations with publisher links

```markdown
## Anti-Hallucination Protocol

**Publisher Matching Integrity:**
- ALWAYS base publisher matching on loaded entity content only
- NEVER fabricate publisher links when no match found (use fallback)
- NEVER invent publisher entities not in loaded files
- NEVER assume publisher exists without verification
- IF publisher loading incomplete → STOP at checkpoint, DO NOT proceed

**Citation Quality:**
- NEVER fabricate DOIs or PMIDs
- NEVER invent author affiliations or credentials
- ALWAYS use domain fallback if no publisher matched
- NEVER enhance source titles beyond existing content
- ALWAYS validate citation text contains no YAML artifacts
```

---

## JSON-Only Output Enforcement Section (OPTIONAL - Use if orchestration-critical)

**Purpose**: Emphasize strict JSON-only response requirement for agents integrated with orchestrators.

**Standard Format:**
```markdown
## CRITICAL: JSON-Only Output

**YOUR ENTIRE RESPONSE MUST BE PARSEABLE JSON.**

Return ONLY this structure with NO additional text:

```json
{
  "success": true,
  "key_metric": 42
}
```

### Blocked Patterns

❌ **WRONG - Text before JSON:**
```
Now I'll return the summary:
{"success": true, ...}
```

❌ **WRONG - Commentary:**
```
Perfect! Here are the results:
{"success": true, ...}
```

✅ **CORRECT - JSON only:**
```
{"success": true, "key_metric": 42}
```

**Enforcement:** Responses with ANY text outside JSON will be rejected. Start with `{` character only.
```

**When to Include This Section:**
- ✅ Agents called by orchestrators that parse JSON
- ✅ Agents used in parallel execution pipelines
- ✅ Agents that contribute to aggregated reports
- ❌ Interactive agents (human-facing)
- ❌ Test/validation agents

---

## Integration Notes Section (OPTIONAL - Use for workflow context)

**Purpose**: Document agent's position in workflow and integration points.

**Standard Format:**
```markdown
## Integration Notes

**Workflow Position:**
- **Phase**: {{PHASE_NUMBER_IN_PIPELINE}}
- **Input Dependencies**: Requires entities from Phase {{X}}
- **Output Consumers**: Used by Phase {{Y}}
- **Parallel Safety**: {{SAFE_TO_PARALLELIZE_OR_NOT}}

**Upstream Dependencies:**
- {{ENTITY_TYPE_1}} entities must exist (created by {{AGENT_NAME}})
- {{ENTITY_TYPE_2}} entities must exist (created by {{AGENT_NAME}})

**Downstream Consumers:**
- {{AGENT_NAME}} reads created entities
- {{ORCHESTRATOR_NAME}} aggregates statistics

**Orchestration Patterns:**
- **Sequential**: Run after {{AGENT_NAME}} completes
- **Parallel**: Can run alongside {{AGENT_NAME}}
- **Partition**: Supports `--partition` parameter for horizontal scaling
```

### Example (Citation Generator)

```markdown
## Integration Notes

**Workflow Position:**
- **Phase**: 6.2 (Citation Generation)
- **Input Dependencies**: Requires source entities (Phase 6.1) and publisher entities (Phase 5)
- **Output Consumers**: Research reports reference citations
- **Parallel Safety**: Safe to parallelize using `--partition` parameter

**Upstream Dependencies:**
- Source entities (07-sources) must exist (created by source-creator)
- Publisher entities (08-publishers) must exist (created by publisher-creator)

**Downstream Consumers:**
- Research synthesis agents read citation entities
- Report generators format citations for bibliography

**Orchestration Patterns:**
- **Sequential**: Run AFTER source-creator and publisher-creator complete
- **Parallel**: Can partition citation generation across 4 jobs for large source sets
- **Partition**: Use `--partition 1/4` format for horizontal scaling
```

---

## Template Usage Guide

### Quick Start: Creating New Agent

1. **Copy Section 1-5** (Frontmatter through Instructions)
2. **Replace ALL {{PLACEHOLDERS}}** with agent-specific values
3. **Choose phase structure** (0-5 standard, or simplified for simple agents)
4. **Add bash scripts** in Instructions section
5. **Define error handling table**
6. **Add 2+ examples** (success + edge case minimum)
7. **Review anti-hallucination protocol**
8. **Test agent** and refine

### Placeholder Glossary

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{AGENT_NAME}}` | Kebab-case agent name | `source-creator` |
| `{{ONE_LINE_DESCRIPTION}}` | Brief description with use case | `Extract source metadata from findings...` |
| `{{SPECIALIST_TITLE}}` | Domain-specific role | `research source metadata specialist` |
| `{{PRIMARY_RESPONSIBILITY}}` | Core function in one sentence | `extracts source information from findings` |
| `{{KEY_CAPABILITIES}}` | List of 3-5 skills | `APA formatting, multi-strategy matching` |
| `{{TASK_SUMMARY_SENTENCE}}` | What agent accomplishes | `Generate formal APA citations...` |
| `{{OBJECTIVE_N}}` | Numbered workflow steps | `Load ALL sources completely` |
| `{{CRITERION_N}}` | Success condition | `All sources processed completely` |
| `{{ENTITY_DIR}}` | Entity directory name | `07-sources`, `09-citations` |
| `{{PREFIX}}` | Entity ID prefix | `source`, `citation`, `claim` |

### Customization Guidelines

**Simplify for Simple Agents:**
- Remove Phase 2 if no entity loading required
- Remove logging if agent is read-only
- Remove partition support if not parallelizable
- Merge Phases 3-4 if processing is straightforward

**Enhance for Complex Agents:**
- Add Phase 1.5 for complete entity loading + verification
- Add Phase 1.6 for partition filtering
- Add multi-strategy resolution in Phase 3
- Add comprehensive skip tracking
- Add quality scoring subsections

**Domain-Specific Additions:**
- Research quality frameworks (e.g., 4-dimension claim quality)
- Domain-specific validation (e.g., APA citation format)
- Specialized lookup structures (e.g., publisher indexing)
- Custom provenance chains (e.g., wikilink extraction algorithms)

---

## Standard Phase Numbering (REQUIRED)

**All agents MUST follow this phase structure for consistency:**

- **Phase 0**: Environment & Working Directory Validation
- **Phase 1**: Input Validation & Parameter Parsing
- **Phase 2**: Data Loading & Preparation (OPTIONAL - only if loading entities)
- **Phase 3**: Core Processing Logic
- **Phase 4**: Output Generation & Writing
- **Phase 5**: Metadata Return (JSON)

**Phase Naming Convention:**
```markdown
### Phase N: {{DESCRIPTIVE_NAME}}
```

**Sub-Phase Numbering (if needed):**
```markdown
### Phase 1.5: Complete Entity Loading
### Phase 1.6: Partition Filtering
```

**Why This Matters:**
- Consistent navigation across all agents
- Easier to compare agent structures
- Standard mental model for developers
- Simplifies orchestration integration

---

## Shell Compatibility: Bash 3.2 (CRITICAL)

**This project targets Bash 3.2** (macOS default). All bash examples in reference docs, agents, and skills MUST be Bash 3.2 compatible.

### FORBIDDEN: `declare -A` (Associative Arrays)

`declare -A` requires Bash 4.0+ and MUST NOT appear in any reference documentation or agent prompts. Claude learns from these examples and will reproduce them in generated scripts, causing failures on macOS.

**Error observed when violated:**
```
/tmp/script.sh: line 15: declare: -A: invalid option
declare: usage: declare [-afFirtx] [-p] [name[=value] ...]
```

**Use these Bash 3.2 compatible alternatives instead:**

| Pattern | Bash 4.0+ (FORBIDDEN) | Bash 3.2 (REQUIRED) |
|---------|----------------------|---------------------|
| Key-value store | `declare -A MAP; MAP["key"]="val"` | Parallel indexed arrays with lookup function |
| Set/dedup | `declare -A SEEN; SEEN["item"]=1` | Indexed array with membership check function |
| Static mapping | `declare -A MAP=(["a"]="1")` | `case` statement or JSON with `jq` |

**Parallel indexed arrays pattern:**
```bash
# Bash 3.2 compatible - parallel arrays (declare -A requires Bash 4.0+)
KEYS=()
VALUES=()

KEYS+=("example.com")
VALUES+=("Example Publisher")

lookup() {
  local target="$1" i=0
  for key in "${KEYS[@]}"; do
    if [ "$key" = "$target" ]; then echo "${VALUES[$i]}"; return 0; fi
    i=$((i + 1))
  done
  return 1
}
```

---

## YAML Parsing Safety (CRITICAL)

**Purpose**: Prevent YAML artifacts from leaking into extracted values.

### The Problem

**WRONG - Using grep alone:**
```bash
DOMAIN=$(grep "domain:" "$FILE")
# Result: "domain: example.com" ← Field name included!
```

**This causes:**
- Citation text: "domain: example.com published..." ← YAML artifact visible
- Validation failures: Domain contains colon
- Knowledge graph corruption: Invalid entity references

### The Solution

**CORRECT - Using grep+sed:**
```bash
DOMAIN=$(grep "^domain:" "$FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')
# Result: "example.com" ← Clean value only
```

**Explanation:**
1. `grep "^domain:"` - Find line starting with "domain:"
2. `head -1` - Take first match only
3. `sed 's/^domain:[[:space:]]*//'` - Remove field name and whitespace
4. `sed 's/"//g'` - Remove quotes

### Standard Extraction Patterns

**String Field:**
```bash
FIELD=$(grep "^field_name:" "$FILE" | head -1 | sed 's/^field_name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
```

**Integer Field:**
```bash
FIELD=$(grep "^field_name:" "$FILE" | head -1 | sed 's/^field_name:[[:space:]]*//')
```

**URL Field (validate after extraction):**
```bash
URL=$(grep "^url:" "$FILE" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/"//g')

cat > /tmp/validate-url.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Validate URL doesn't contain YAML artifacts
if [[ "$URL" == *"url:"* ]] || [[ ! "$URL" =~ ^https?:// ]]; then
  echo "ERROR: Invalid URL: $URL" >&2
  exit 1
fi
SCRIPT_EOF
chmod +x /tmp/validate-url.sh && bash /tmp/validate-url.sh
```

**Domain Field (validate after extraction):**
```bash
DOMAIN=$(grep "^domain:" "$FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')

cat > /tmp/validate-domain.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Validate domain has no YAML artifacts
if [[ "$DOMAIN" == *":"* ]] || [[ "$DOMAIN" == *"/"* ]]; then
  echo "ERROR: Domain extraction failed: $DOMAIN" >&2
  exit 1
fi
SCRIPT_EOF
chmod +x /tmp/validate-domain.sh && bash /tmp/validate-domain.sh
```

### Post-Extraction Validation

**Always validate extracted values:**
```bash
# After extraction
TITLE=$(grep "^title:" "$FILE" | head -1 | sed 's/^title:[[:space:]]*//' | sed 's/"//g')

# Validation
if [ "$TITLE" == *"title:"*] || [ "$TITLE" == *"Obsidian"* ]; then
  echo "ERROR: Title contains YAML artifacts: $TITLE" >&2
  continue
fi

if [ -z "$TITLE" ] || [ "$TITLE" == "null" ]; then
  echo "ERROR: Title is empty or null" >&2
  continue
fi
```

**Validation Checklist:**
- [ ] Value doesn't contain field name
- [ ] Value doesn't contain colons (for domain/URL fields)
- [ ] Value is not empty
- [ ] Value is not "null"
- [ ] Value doesn't contain YAML comments

---

## Utility Script Invocation Best Practices

**Purpose**: Ensure robust error handling when calling external scripts.

### Pattern: Comprehensive Error Checking

```bash
# Call utility script
result=$(bash "$SCRIPT_NAME" \
  --param1 "$VALUE1" \
  --param2 "$VALUE2" \
  --json 2>&1)

# Step 1: Validate script execution succeeded
if [ $? -ne 0 ]; then
  log "ERROR" "Script execution failed: $SCRIPT_NAME"
  log "DEBUG" "  Output: ${result:0:200}"

  # Track skip reason
  SKIP_ENTRY=$(jq -n \
    --arg id "$ENTITY_ID" \
    --arg reason "script_execution_failed" \
    --arg error "${result:0:100}" \
    '{id: $id, reason: $reason, error: $error}')
  SKIPPED_ITEMS=$(echo "$SKIPPED_ITEMS" | jq --argjson entry "$SKIP_ENTRY" '. + [$entry]')

  continue  # Skip this item
fi

# Step 2: Validate JSON output
if [ -z "$result" ]; then
  log "ERROR" "Script returned empty output: $SCRIPT_NAME"
  continue
fi

if ! echo "$result" | jq -e . >/dev/null 2>&1; then
  log "ERROR" "Script returned invalid JSON: $SCRIPT_NAME"
  log "DEBUG" "  Raw output: ${result:0:200}"
  continue
fi

# Step 3: Validate success field
if [ "$(echo "$result" | jq -r '.success')" != "true" ]; then
  ERROR_MSG=$(echo "$result" | jq -r '.error // "Unknown error"')
  log "ERROR" "Script reported failure: $ERROR_MSG"
  continue
fi

# Step 4: Extract data
DATA=$(echo "$result" | jq -r '.data.field_name')

# Step 5: Validate extracted data
if [ -z "$DATA" ] || [ "$DATA" == "null" ]; then
  log "ERROR" "Script returned null data"
  continue
fi

# Success - use DATA
log "INFO" "✓ Script succeeded: $SCRIPT_NAME"
```

### Why This Pattern

**5-Layer Validation:**
1. **Exit code**: Script didn't crash
2. **Non-empty output**: Script produced output
3. **JSON validity**: Output is parseable
4. **Success field**: Script reported success
5. **Data validity**: Extracted value is usable

**Benefits:**
- Catches all failure modes
- Provides detailed error context
- Enables skip-and-continue resilience
- Logs debugging information

---

## Logging Best Practices (OPTIONAL)

**When to Use Logging:**
- ✅ Complex multi-phase agents
- ✅ Agents calling multiple external scripts
- ✅ Agents running in parallel
- ✅ Agents with high error rates
- ❌ Simple read-only agents
- ❌ Test agents

**Log Levels:**
- `INFO`: Phase transitions, major milestones, summary statistics
- `DEBUG`: Parameter values, intermediate calculations, verification checkpoints
- `TRACE`: Script invocations with full parameters, detailed iteration progress
- `WARN`: Recoverable errors, skipped items, fallback strategies used
- `ERROR`: Fatal errors, validation failures, script execution failures

**Example: Strategic Logging**
```bash
log "INFO" "========== Phase 3: PROCESSING =========="
log "INFO" "Processing $ENTITY_COUNT entities"

for entity in "${ENTITIES[@]}"; do
  log "DEBUG" "Processing entity: $entity"

  log "TRACE" "Calling utility script"
  log "TRACE" "  Script: $SCRIPT_NAME"
  log "TRACE" "  Parameters: --param1 $VALUE1"

  result=$(bash "$SCRIPT_NAME" --param1 "$VALUE1")

  if [ $? -ne 0 ]; then
    log "ERROR" "Script execution failed for $entity"
    log "DEBUG" "  Output: ${result:0:200}"
    continue
  fi

  log "INFO" "✓ Successfully processed: $entity"
done

log "INFO" "Processing complete: $success_count succeeded, $skip_count skipped"
```

**Log File Management:**
- Write to `${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt`
- Append timestamp to each entry
- Include agent name in log prefix
- Log to BOTH stderr and file for dual visibility

---

## Version History

### v2.0.0 (2025-01-07)
- Initial comprehensive template based on Sprint 132 exploration findings
- Incorporated best practices from source-creator, fact-checker, citation-generator
- Added Phase 0-5 standardization
- Added anti-hallucination protocol variations
- Added YAML parsing safety section
- Added utility script invocation patterns
- Added 50+ examples across all sections

### Future Improvements
- Add metaprompt integration examples
- Add test coverage patterns
- Add performance optimization patterns
- Add multi-language support guidelines

---

## Quick Reference: Section Checklist

**Creating new agent? Ensure you have:**

- [ ] Section 1: YAML Frontmatter (name, description, tools, model)
- [ ] Section 2: Your Role (context with specialist identity)
- [ ] Section 3: Your Mission (task, parameters, objectives, success criteria, output format)
- [ ] Section 4: Constraints (scope boundaries, quality requirements, anti-hallucination)
- [ ] Section 5: Instructions (Phase 0-5 with bash scripts)
  - [ ] Phase 0: Environment & Working Directory Validation
  - [ ] Phase 1: Input Validation & Parameter Parsing
  - [ ] Phase 2: Data Loading & Preparation (if applicable)
  - [ ] Phase 3: Core Processing Logic
  - [ ] Phase 4: Output Generation & Writing
  - [ ] Phase 5: Metadata Return (JSON)
- [ ] Section 6: Error Handling (error table with scenarios)
- [ ] Section 7: Examples (minimum 2: success + edge case)
- [ ] Section 8: Quality Standards (optional but recommended)

**Optional sections:**
- [ ] JSON-Only Output Enforcement (if orchestration-critical)
- [ ] Integration Notes (if workflow context needed)
- [ ] Anti-Hallucination Protocol Variations (if multiple patterns apply)

**Final validation:**
- [ ] All {{PLACEHOLDERS}} replaced
- [ ] Bash scripts use proper YAML parsing (grep+sed)
- [ ] Error handling follows decision tree
- [ ] Examples demonstrate actual usage
- [ ] Phase numbering follows 0-5 standard
- [ ] JSON output format specified exactly
