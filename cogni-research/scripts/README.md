# Deeper-Research Scripts

Supporting scripts for the deeper-research skill with cross-platform Python support.

## Cross-Platform Support

As of v4.0.0, core entity operations use Python backends with thin bash wrappers for cross-platform compatibility (macOS, Linux, Windows).

### Architecture

```text
[Caller] → [script.sh (wrapper)] → [script.py (Python backend)]
```

**Python requirement:** Python 3.8+ is required.

### Python-Backed Scripts

| Script | Python Backend |
|--------|----------------|
| create-entity.sh | create-entity.py |
| lookup-entity.sh | lookup-entity.py |
| normalize-url.sh | normalize-url.py |
| scan-resumption-state.sh | scan_resumption_state.py |

### Shared Python Utilities

Python backends use shared modules from `cogni-workplace/python/`:

- **entity_lock.py** - Directory-based advisory locks
- **entity_index.py** - Entity index management with transactional updates
- **entity_ops.py** - Entity validation and ID generation
- **logging_utils.py** - DEBUG_MODE/QUIET_MODE aware logging

## Script Execution Pattern

All scripts in this directory follow consistent interface standards.

**Pattern:**
```bash
# Required validation
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

# Call script with absolute path
bash "${CLAUDE_PLUGIN_ROOT}/scripts/{script-name}.sh" \
  --arg "value" \
  --json
```

**Requirements:**
- All scripts support `--json` flag for structured output
- All scripts use `--flag value` argument format (not `-f` short flags)
- `CLAUDE_PLUGIN_ROOT` environment variable must be set

**Example:**
```bash
# Validate environment
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

# Call script
bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
  --title "Project Title" \
  --content-key "key" \
  --max-length 60 \
  --json
```

## Environment Setup

Scripts expect `CLAUDE_PLUGIN_ROOT` to be configured in `.claude/settings.local.json`:

```json
{
  "env": {
    "CLAUDE_PLUGIN_ROOT": "/path/to/plugins/cogni-research"
  }
}
```

**Validation:** The skill performs environment validation during initialization. If the skill loads successfully, all scripts have access to valid environment variables.

## Script Categories

### Project Management
- **initialize-research-project.sh** - Creates project directory structure and workspace
- **check-project-existence.sh** - Checks for existing projects and previews slug normalization
- **generate-semantic-slug.sh** - Centralized semantic UUID generation with word-boundary truncation

### Data Quality
- **detect-duplicate-sources.sh** - Scan sources for URL-based duplicates and orphans
- **merge-duplicate-sources.sh** - Safely merge duplicate sources with backup and dry-run
- **cleanup-orphaned-sources.sh** - Archive sources with no finding references

### Validation
- **validate-wikilinks.sh** - Validates entity cross-references (Phase 9)
- **validate-source-metadata.sh** - Validates source entity metadata completeness
- **validate-script-interfaces.sh** - Validates script interface compliance
- **scan-resumption-state.sh** - Scans findings/claims coverage for rate-limit resumption (Python backend)

### Entity Operations
- **create-entity.sh** - Creates entity files with YAML frontmatter (Python backend)
- **lookup-entity.sh** - Looks up entity by ID or title (Python backend)
- **normalize-url.sh** - Normalizes URLs for deduplication (Python backend)
- **deduplicate-entities.sh** - Deduplicates entities within a directory
- **generate-wikilink.sh** - Generates Obsidian wikilinks for entities

### Utilities
- **partition-entities.sh** - Partitions entity lists for parallel processing
- **map-findings-to-dimensions.sh** - Maps findings to research dimensions
- **entity-lock-utils.sh** - Entity-level locking utilities for concurrent operations
- **citation-generator.sh** - Generates APA citations (legacy, prefer citation-generator agent)
- **generate-apa-citation.sh** - APA citation formatting helper
- **detect-workspace-root.sh** - Detects workspace root directory
- **validate-working-directory.sh** - Validates current working directory context
- **test-partition-entities.sh** - Test suite for partition-entities.sh

## Common Usage Patterns

### Check for Errors

```bash
result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/some-script.sh" --arg "value" --json)

if [ "$(echo "$result" | jq -r '.success')" != "true" ]; then
  echo "ERROR: Script failed"
  echo "$result" | jq -r '.error'
  exit 1
fi
```

### Extract Data

```bash
result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
  --title "My Project" \
  --content-key "project" \
  --json)

entity_id=$(echo "$result" | jq -r '.data.semantic_uuid')
echo "Generated ID: $entity_id"
```

### Handle Validation

```bash
validation=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-wikilinks.sh" \
  --project-path "$PROJECT_PATH" \
  --json)

broken_links=$(echo "$validation" | jq -r '.broken_links')

if [ "$broken_links" -gt 0 ]; then
  echo "WARNING: Found $broken_links broken wikilinks"
  # Handle broken links...
fi
```

## Script Interface Standards

All scripts follow the conventions defined in [Script Interface Standards](https://github.com/cogni-work/dev-work/blob/main/references/script-interface-standards.md):

- **Parameter Format:** `--flag value` (not `-f value` or `--flag=value`)
- **JSON Output:** Use `--json` flag for structured output
- **Success Field:** All JSON responses include `{"success": true|false}`
- **Error Handling:** Graceful degradation with informative error messages
- **Exit Codes:** 0 for success, non-zero for errors

## Debugging

Enable debug output for script troubleshooting:

```bash
# Set DEBUG_MODE before script execution
export DEBUG_MODE=true
export DEBUG_LEVEL=DEBUG

bash "${CLAUDE_PLUGIN_ROOT}/scripts/some-script.sh" --arg "value" --json
```

See [references/validation-protocols.md](../references/validation-protocols.md) for validation and debugging patterns.
