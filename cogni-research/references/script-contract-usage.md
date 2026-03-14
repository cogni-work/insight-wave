# Script Contract Usage Guide

How to use contract specifications when calling scripts in the deeper-research plugin.

**Read this when:** Invoking scripts from skills/agents, understanding script interfaces, debugging script call failures, or implementing contract-compliant code.

## Purpose

This reference explains how to:

1. **Discover contracts** - Find contract files for scripts
2. **Read contract specifications** - Understand parameters, outputs, exit codes
3. **Call scripts with contracts** - Implement contract-compliant invocations
4. **Handle missing contracts** - Work with undocumented scripts

## Section 1: Contract Location and Discovery

### Contract Directory

All deeper-research contracts are centralized in:

```
cogni-research/contracts/
```

**Contract naming convention:** `{script-name}.yml`

Examples:
- `create-entity.sh` → `contracts/create-entity.yml`
- `validate-wikilinks.sh` → `contracts/validate-wikilinks.yml`
- `generate-semantic-slug.sh` → `contracts/generate-semantic-slug.yml`

### Finding a Contract

**Method 1: Direct lookup (if you know the script name)**
```bash
CONTRACT_FILE="${CLAUDE_PLUGIN_ROOT}/contracts/create-entity.yml"
if [ -f "$CONTRACT_FILE" ]; then
  # Contract exists - read specification
  cat "$CONTRACT_FILE"
fi
```

**Method 2: List all contracts**
```bash
ls -1 cogni-research/contracts/*.yml
```

**Method 3: Search by script purpose**
```bash
grep -r "purpose:" cogni-research/contracts/ | grep "entity"
```

### Contract Coverage

**Current status:** 38 contracts for 148 scripts (25.7% coverage)

**Contracted scripts (examples):**
- Entity creation: `create-entity.yml`
- Validation: `validate-working-directory.yml`, `validate-wikilinks.yml`
- UUID generation: `generate-semantic-slug.yml`
- Citation management: `citation-registry.yml`
- Data quality: `detect-duplicate-sources.yml`, `cleanup-orphaned-sources.yml`

**Missing contracts:** 110 scripts without contracts yet (validation audits identify these)

## Section 2: Reading Contract Specifications

### Contract Structure

All contracts follow this YAML schema:

```yaml
version: "X.Y.Z"
script:
  name: "script-name.sh"
  path: "/absolute/path/to/script.sh"
  purpose: "What the script does"
  category: "utilities|validation|entities|synthesis"
interface:
  parameters:
    - name: "--parameter-name"
      type: "string|path|json|boolean|number"
      required: true|false
      description: "Parameter description"
  output:
    format: "json|text"
    schema:
      field1: "type"
      field2: "type"
  exit_codes:
    0: "Success description"
    1: "Error type 1"
    2: "Error type 2"
compatibility:
  min_bash_version: "3.2"
  dependencies: ["jq", "awk", "sed"]
  environment:
    - "CLAUDE_PLUGIN_ROOT (required)"
changelog:
  - version: "X.Y.Z"
    date: "YYYY-MM-DD"
    changes: "Change description"
    breaking: true|false
```

### Example: create-entity.yml

```yaml
version: "2.2.0"
script:
  name: "create-entity.sh"
  purpose: "Generate entity file with UUID, YAML frontmatter, deduplication"
interface:
  parameters:
    - name: "--project-path"
      type: "path"
      required: true
    - name: "--entity-type"
      type: "type"
      required: false
    - name: "--data"
      type: "json"
      required: false
    - name: "--json"
      type: "boolean"
      required: false
  output:
    format: "json"
    schema:
      success: "boolean"
      data: {}
      error: "string (if success=false)"
  exit_codes:
    0: "Success"
    1: "Validation error"
    2: "Invalid arguments"
```

### Reading Parameters

**Required vs Optional:**
```yaml
required: true   # MUST provide this parameter
required: false  # MAY provide this parameter (has default or optional)
```

**Parameter Types:**
- `string` - Text value
- `path` - File/directory path
- `json` - JSON string or @file.json
- `boolean` - Flag (presence = true)
- `number` - Integer or float
- `type` - Enum value (e.g., entity type)

### Reading Exit Codes

Exit codes indicate success/failure type:
- `0` - Success (always)
- `1` - Runtime error (file not found, validation failed)
- `2` - Parameter error (missing required, invalid format)
- `3+` - Script-specific errors (check contract)

### Reading Output Schema

JSON output structure:
```yaml
output:
  format: "json"
  schema:
    success: "boolean"        # Required
    error: "string|null"      # Required
    entity_id: "string"       # Script-specific
    entity_created: "boolean" # Script-specific
```

Always expect `success` and `error` fields in JSON responses.

## Section 3: Calling Scripts with Contracts

### Basic Invocation Pattern

```bash
# 1. Read contract to understand interface
# Contract: create-entity.yml
#   Required: --project-path, --entity-type, --data, --json
#   Output: JSON with success, entity_id, entity_created
#   Exit codes: 0=success, 1=validation, 2=parameters

# 2. Prepare parameters from contract specification
ENTITY_DATA='{"id": "source-abc123", "name": "Title"}'

# 3. Invoke script with all required parameters
RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "source" \
  --data "$ENTITY_DATA" \
  --json)

# 4. Check exit code (from contract exit_codes section)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  # Exit code 1 = validation error, 2 = parameter error
  log_conditional ERROR "create-entity.sh failed with exit code: $EXIT_CODE"
  echo "$RESULT" >&2
  exit 1
fi

# 5. Parse output using contract schema
SUCCESS=$(echo "$RESULT" | jq -r '.success')
if [ "$SUCCESS" != "true" ]; then
  ERROR=$(echo "$RESULT" | jq -r '.error')
  log_conditional ERROR "Entity creation failed: $ERROR"
  exit 1
fi

# 6. Extract response fields from contract schema
ENTITY_ID=$(echo "$RESULT" | jq -r '.entity_id')
ENTITY_CREATED=$(echo "$RESULT" | jq -r '.entity_created')

log_conditional INFO "Entity created: $ENTITY_ID (new=$ENTITY_CREATED)"
```

### Parameter Mapping from Contract

Map skill parameters to script parameters using contract:

```yaml
# Contract specifies:
parameters:
  - name: "--project-path"
    required: true
  - name: "--entity-type"
    required: false
    description: "Entity type (source, publisher, etc.)"
```

```bash
# Skill invocation:
PROJECT_PATH="/path/to/project"    # From skill parameter
ENTITY_TYPE="source"                # Skill-specific constant

# Map to script invocation:
bash script.sh \
  --project-path "$PROJECT_PATH" \  # Required (from contract)
  --entity-type "$ENTITY_TYPE"      # Optional (from contract)
```

### Error Handling Based on Exit Codes

```bash
RESULT=$(bash script.sh --param "$VALUE")
EXIT_CODE=$?

# Contract specifies:
#   0: Success
#   1: Validation error (retryable, fix input)
#   2: Parameter error (non-retryable, programming error)

case $EXIT_CODE in
  0)
    # Success - process result
    ;;
  1)
    # Validation error - log and skip
    log_conditional WARN "Validation failed: $RESULT"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    ;;
  2)
    # Parameter error - fatal (programming error)
    log_conditional ERROR "Invalid parameters: $RESULT"
    exit 2
    ;;
  *)
    # Unexpected error
    log_conditional ERROR "Unexpected exit code: $EXIT_CODE"
    exit 1
    ;;
esac
```

### Response Parsing with Schema

```yaml
# Contract output schema:
output:
  format: "json"
  schema:
    success: "boolean"
    entities_created: "number"
    entities_reused: "number"
    error: "string|null"
```

```bash
# Parse all fields from schema:
SUCCESS=$(echo "$RESULT" | jq -r '.success')
CREATED=$(echo "$RESULT" | jq -r '.entities_created')
REUSED=$(echo "$RESULT" | jq -r '.entities_reused')
ERROR=$(echo "$RESULT" | jq -r '.error // empty')

# Validate expected fields present
if [ -z "$SUCCESS" ] || [ -z "$CREATED" ]; then
  log_conditional ERROR "Response missing required fields"
  exit 1
fi
```

## Section 4: Handling Missing Contracts

### Generating Contracts

Use generate-script-contract.sh to create contracts from script headers:

```bash
# Generate contract for script without one (using dev-work repository)
bash "path/to/dev-work/scripts/generate-script-contract.sh" \
  --script-path "/path/to/script.sh" \
  --output-path "cogni-research/contracts/script-name.yml" \
  --json

# Review generated contract
cat "cogni-research/contracts/script-name.yml"
```

### Temporary Interfaces (Undocumented Scripts)

When working with scripts without contracts:

1. **Read script header** - Check for usage documentation
```bash
head -50 script.sh | grep -A20 "^# Usage:"
```

2. **Examine parameter parsing** - Find while loop + case statement
```bash
grep -A50 "while.*\$#" script.sh | grep -B2 "shift"
```

3. **Check exit codes** - Search for explicit exits
```bash
grep "exit [0-9]" script.sh
```

4. **Test with --help** (if supported)
```bash
bash script.sh --help
```

5. **Document findings** - Create temporary interface notes
```markdown
# Temporary Interface: script-name.sh
## Parameters (observed)
- `--project-path` (required)
- `--entity-id` (required)

## Exit Codes (observed)
- 0: Success
- 1: Error

## Output Format
JSON with success/error fields
```

### Contract Validation Tools

Run validation tools to identify missing contracts:

```bash
# Use interface-validator skill to find missing contracts
# Use this skill with --plugin cogni-research

# Expected output:
# - 110 scripts without contracts identified
# - Remediation guidance for each
```

### Contract Review Process

When contracts are missing:

1. **Generate** using generate-script-contract.sh
2. **Review** generated contract for accuracy
3. **Test** script invocation against contract
4. **Update** contract if interface changed
5. **Commit** contract to repository

## Common Anti-Patterns

❌ **Don't:** Assume parameter names without checking contract
```bash
# Bad: Guessed parameter name
bash script.sh --path "$PATH"  # Contract specifies --project-path
```

❌ **Don't:** Ignore exit codes
```bash
# Bad: No error handling
RESULT=$(bash script.sh ...)
SUCCESS=$(echo "$RESULT" | jq -r '.success')  # Script may have failed
```

❌ **Don't:** Parse output without checking schema
```bash
# Bad: Assumes field exists
ID=$(echo "$RESULT" | jq -r '.id')  # Contract specifies '.entity_id'
```

❌ **Don't:** Skip contract version checking
```bash
# Bad: No version awareness
bash script.sh ...  # Contract may have breaking changes in v2.0.0
```

✅ **Do:** Follow contract specification exactly
```bash
# Good: Contract-compliant invocation
# 1. Read contract for interface
# 2. Map parameters correctly
# 3. Handle exit codes
# 4. Parse using schema
# 5. Validate response structure
```

## Contract Compliance Validation

### Tool: prompt-contract-validator

Validate skill prompts follow contracts:

```bash
# Use prompt-contract-validator skill with --skill path/to/skill

# Detects:
# - Parameter mismatches
# - Missing required parameters
# - Unknown parameters
# - Exit code handling issues
# - Output parsing errors
```

### Tool: interface-validator

Validate scripts have contracts:

```bash
# Use interface-validator skill with --plugin path/to/plugin

# Detects:
# - Scripts without contracts (110 in deeper-research)
# - Breaking changes without version bumps
# - Parameter mismatches
# - Missing contracts
```

## Related References

- [shared-bash-patterns.md](shared-bash-patterns.md) - Parameter parsing, JSON responses
- [entity-structure-guide.md](entity-structure-guide.md) - Entity creation patterns
- [anti-hallucination-foundations.md](anti-hallucination-foundations.md) - Verification patterns
- [../contracts/](../contracts/) - 38 contract files

## Version History

**v1.0.0 (Sprint 001)** - Initial creation
- Section 1: Contract location and discovery
- Section 2: Reading contract specifications
- Section 3: Calling scripts with contracts
- Section 4: Handling missing contracts
- Establishes contract-based development pattern for plugin
