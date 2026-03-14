# Entity Index Repair Scripts

## Overview

The entity index repair system detects and fixes drift between `.metadata/entity-index.json` and the filesystem when entities exist as markdown files but are missing from the index. This commonly occurs due to concurrent write failures during parallel processing.

## Architecture

Following **LLM-Control Architecture**, the repair system splits responsibilities:

- **Orchestrator**: `repair-entity-index.sh` - Coordinates workflow, generates reports
- **Services**: Three focused scripts performing single computational tasks

```
repair-entity-index.sh (orchestrator)
├── scan-entity-directory.sh (extract metadata from filesystem)
├── detect-index-drift.sh (compare filesystem vs index)
└── update-index-section.sh (atomic index updates)
```

## Scripts

### 1. repair-entity-index.sh (Orchestrator)

**Purpose**: Coordinate entity index repair workflow
**Location**: `cogni-research/scripts/repair-entity-index.sh`
**Complexity Score**: 2 (acceptable for orchestrator)
- LOC: 165 (score 2)
- JSON: Moderate (score 1)
- Control Flow: Conditional loops (score 1)
- State: Report generation (score 1)

**Usage**:
```bash
# Dry run to detect drift
repair-entity-index.sh --project-path ~/research/sprint-280 --dry-run --json

# Repair specific entity type
repair-entity-index.sh --project-path ~/research/sprint-280 --entity-type 07-sources

# Full repair with report
repair-entity-index.sh --project-path ~/research/sprint-280
```

**Parameters**:
- `--project-path <path>` - Research project directory (required)
- `--entity-type <type>` - Specific entity type like "07-sources" (optional, default: all)
- `--dry-run` - Report drift without modifying index (optional)
- `--json` - Return JSON response (optional)

**Output**:
```json
{
  "success": true,
  "dry_run": false,
  "entities_scanned": 156,
  "index_entries_before": 142,
  "index_entries_after": 156,
  "missing_entries_added": 14,
  "orphaned_entries_removed": 0,
  "entity_types_repaired": ["07-sources", "08-publishers"],
  "repair_report_path": "reports/index-repair-20251114-130000.md"
}
```

### 2. scan-entity-directory.sh (Extractor Service)

**Purpose**: Scan entity directory and extract metadata from markdown files
**Location**: `cogni-research/scripts/scan-entity-directory.sh`
**Complexity Score**: 0 (production-ready)
- LOC: 78 (score 0)
- JSON: Simple (score 0)
- Control Flow: Linear with single loop (score 0)
- State: Read-only (score 0)

**Usage**:
```bash
scan-entity-directory.sh --project-path ~/research/sprint-280 --entity-type 07-sources
```

**Output**:
```json
{
  "success": true,
  "data": {
    "entity_type": "07-sources",
    "entities": [
      {"id": "source-abc123", "name": "Article Title", "url": "https://...", "type": "07-sources"}
    ],
    "count": 68
  }
}
```

### 3. detect-index-drift.sh (Validator Service)

**Purpose**: Compare filesystem entities with .metadata/entity-index.json to detect drift
**Location**: `cogni-research/scripts/detect-index-drift.sh`
**Complexity Score**: 0 (production-ready)
- LOC: 70 (score 0)
- JSON: Simple (score 0)
- Control Flow: Linear (score 0)
- State: Read-only (score 0)

**Usage**:
```bash
detect-index-drift.sh \
  --index-file .metadata/entity-index.json \
  --entity-type 07-sources \
  --filesystem-entities '[...]'
```

**Output**:
```json
{
  "success": true,
  "data": {
    "entity_type": "07-sources",
    "missing_entries": [{"id": "source-abc123", ...}],
    "orphaned_entries": [],
    "filesystem_count": 68,
    "index_count": 54,
    "has_drift": true
  }
}
```

### 4. update-index-section.sh (Utility Service)

**Purpose**: Update .metadata/entity-index.json section with filesystem entities
**Location**: `cogni-research/scripts/update-index-section.sh`
**Complexity Score**: 1 (production-ready)
- LOC: 60 (score 0)
- JSON: Simple (score 0)
- Control Flow: Linear (score 0)
- State: Single file write with backup (score 1)

**Usage**:
```bash
update-index-section.sh \
  --index-file .metadata/entity-index.json \
  --entity-type 07-sources \
  --entities '[...]'
```

**Output**:
```json
{
  "success": true,
  "data": {
    "index_file": ".metadata/entity-index.json",
    "entity_type": "07-sources",
    "entries_written": 68,
    "backup_created": ".metadata/entity-index.json.backup-20251114-130000"
  }
}
```

## Workflow

1. **Scan Filesystem**: For each entity type, extract metadata from markdown files
2. **Detect Drift**: Compare filesystem entities with index entries
3. **Update Index**: Rebuild index sections for types with drift (if not dry-run)
4. **Generate Report**: Create detailed markdown report with statistics

## Safety Features

- **Automatic backups**: Creates timestamped backup before modifications
- **Atomic updates**: Uses temp file + mv for safe index writes
- **Dry-run mode**: Preview changes without modifying index
- **Detailed reporting**: Markdown report with all missing/orphaned entries

## Use Cases

### Scenario 1: Post-Pipeline Repair

After citation-generator runs with 41% fallback rate:

```bash
# Check drift
repair-entity-index.sh --project-path ~/research/sprint-280 --dry-run

# Repair if needed
repair-entity-index.sh --project-path ~/research/sprint-280
```

### Scenario 2: Specific Entity Type

Repair only sources after concurrent write failures:

```bash
repair-entity-index.sh \
  --project-path ~/research/sprint-280 \
  --entity-type 07-sources \
  --json
```

### Scenario 3: Integration with Skills

```bash
# In deeper-research skill
REPAIR_RESULT=$(repair-entity-index.sh \
  --project-path "$PROJECT_PATH" \
  --json)

MISSING=$(echo "$REPAIR_RESULT" | jq '.missing_entries_added')
if [ "$MISSING" -gt 0 ]; then
  echo "⚠️ Repaired $MISSING missing index entries"
fi
```

## Contract

Full contract specification: `cogni-research/contracts/repair-entity-index.yml`

## Quality Metrics

| Script | LOC | Complexity | Status |
|--------|-----|------------|--------|
| repair-entity-index.sh | 165 | 2 | ✅ Acceptable (orchestrator) |
| scan-entity-directory.sh | 78 | 0 | ✅ Production-ready |
| detect-index-drift.sh | 70 | 0 | ✅ Production-ready |
| update-index-section.sh | 60 | 1 | ✅ Production-ready |

All scripts:
- ✅ Bash 3.2 compatible
- ✅ JSON service pattern (jq -n with --arg)
- ✅ Comprehensive error handling
- ✅ Syntax validated
- ✅ Follow LLM-Control Architecture

## Testing

Validate all scripts:

```bash
# Syntax validation
bash -n repair-entity-index.sh
bash -n scan-entity-directory.sh
bash -n detect-index-drift.sh
bash -n update-index-section.sh

# Test on real project
repair-entity-index.sh \
  --project-path ~/research/sprint-280 \
  --dry-run \
  --json | jq .
```

## Dependencies

- `jq` - JSON processing
- `awk` - Frontmatter extraction
- `find` - Filesystem scanning
- `bash` 3.2+
