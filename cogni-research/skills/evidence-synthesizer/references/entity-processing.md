# Entity Processing Patterns

## Overview

Complete entity loading is critical for anti-hallucination compliance. This reference documents patterns for loading sources, citations, and institutions with full content verification.

## Critical Principle: No Truncation

**NEVER truncate entity loading.** Partial reads create hallucination risk where the agent may:
- Infer missing data
- Fabricate metadata fields
- Assume relationships not present

**Always:**
- Use Read tool without line limits
- Verify complete content loaded
- Extract only from loaded content

## Source Entity Processing

### Source Entity Structure

```yaml
---
source_id: source-climate-bonds-2024-abc123
url: "https://climatebonds.net/reports/2024"
tier: 2
access_date: "2025-01-15"
title: "Global Green Bond Market Report 2024"
publisher_id: "[[08-publishers/data/publisher-climatebonds-org]]"
finding_ids: ["[[04-findings/data/finding-xyz]]"]
created_at: "2025-01-15T10:30:00Z"
tags: [source, tier-2, green-bonds]
---

# Source Content

{Extracted content from source}
```

### Loading Pattern

```bash
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_SOURCES="$(get_directory_by_key "sources")"
DATA_SUBDIR="$(get_data_subdir)"

# Step 1: List all source files
SOURCE_COUNT=$(find "${PROJECT_PATH}/$DIR_SOURCES" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
log_conditional INFO "Found $SOURCE_COUNT sources to load"

if [ "$SOURCE_COUNT" -eq 0 ]; then
    log_conditional WARN "No sources found in $DIR_SOURCES/$DATA_SUBDIR/"
    # Continue with empty source list
fi

# Step 2: Get file list
SOURCE_FILES=$(find "${PROJECT_PATH}/$DIR_SOURCES" -name "*.md" -type f | sort)
```

### Complete Reading

Use Read tool for EACH source file:

```markdown
**Read:** `{{PROJECT_PATH}}/07-sources/data/{source-entity-id}.md` (complete file, no line limit)
```

**Verification:**
```bash
# After Read tool returns content
if [ -n "$CONTENT" ]; then
    log_conditional INFO "Source ${source_id} loaded completely"
    # Extract metadata from content
else
    log_conditional ERROR "Source ${source_id} load failed"
fi
```

### Metadata Extraction

```bash
extract_source_metadata() {
    local content="$1"

    # Extract from YAML frontmatter
    url=$(echo "$content" | grep "^url:" | sed 's/url: *//' | tr -d '"')
    tier=$(echo "$content" | grep "^tier:" | sed 's/tier: *//')
    title=$(echo "$content" | grep "^title:" | sed 's/title: *//' | tr -d '"')
    access_date=$(echo "$content" | grep "^access_date:" | sed 's/access_date: *//' | tr -d '"')

    # Validate required fields
    if [ -z "$url" ] || [ -z "$tier" ] || [ -z "$title" ]; then
        log_conditional ERROR "Source missing required fields"
        return 1
    fi

    # Extract domain from URL
    domain=$(echo "$url" | sed 's|https\?://||' | sed 's|www\.||' | cut -d'/' -f1)
}
```

## Citation Entity Processing

### Citation Entity Structure

```yaml
---
citation_id: citation-cbi-2024-abc123
source_id: "[[07-sources/data/source-climate-bonds-2024-def456]]"
publisher_id: "[[08-publishers/data/publisher-climatebonds-org]]"
apa_citation: "Climate Bonds Initiative. (2024). Global Green Bond Market Report 2024. https://climatebonds.net/reports/2024"
author: "Climate Bonds Initiative"
year: 2024
title: "Global Green Bond Market Report 2024"
source_name: "Climate Bonds Initiative"
created_at: "2025-01-15T10:35:00Z"
tags: [citation, green-bonds]
---

# Citation

Climate Bonds Initiative. (2024). Global Green Bond Market Report 2024. https://climatebonds.net/reports/2024
```

### Loading Pattern

```bash
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_CITATIONS="$(get_directory_by_key "citations")"

# List citation files
CITATION_COUNT=$(find "${PROJECT_PATH}/$DIR_CITATIONS" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
log_conditional INFO "Found $CITATION_COUNT citations to load"

CITATION_FILES=$(find "${PROJECT_PATH}/$DIR_CITATIONS" -name "*.md" -type f | sort)
```

### APA Citation Extraction

Two methods depending on entity structure:

**Method 1: From Frontmatter**
```bash
apa_citation=$(echo "$content" | grep "^apa_citation:" | sed 's/apa_citation: *//' | tr -d '"')
```

**Method 2: From Content Section**
```bash
# Find ## Citation section and extract next non-empty line
apa_citation=$(echo "$content" | grep -A2 "^## Citation$" | tail -1 | sed 's/^ *//')
```

### Citation Components

```bash
extract_citation_components() {
    local content="$1"

    author=$(echo "$content" | grep "^author:" | sed 's/author: *//' | tr -d '"')
    year=$(echo "$content" | grep "^year:" | sed 's/year: *//')
    title=$(echo "$content" | grep "^title:" | sed 's/title: *//' | tr -d '"')

    # For sorting: extract last name of first author
    author_sort_key=$(echo "$author" | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')
}
```

## Institution Entity Processing

### Institution Entity Structure

```yaml
---
institution_id: institution-climate-bonds-initiative-abc123
name: "Climate Bonds Initiative"
mandate: "Mobilize global capital for climate action"
type: "industry/nonprofit"
expertise: ["green finance", "climate bonds", "sustainable investment"]
website: "https://climatebonds.net"
created_at: "2025-01-15T10:40:00Z"
tags: [institution, green-finance]
---

# Climate Bonds Initiative

{Institution description}
```

### Loading Pattern

```bash
# Check if institutions directory exists
if [ -d "${PROJECT_PATH}/12-institutions" ]; then
    INST_COUNT=$(find "${PROJECT_PATH}/12-institutions" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    log_conditional INFO "Found $INST_COUNT institutions to load"

    INSTITUTION_FILES=$(find "${PROJECT_PATH}/12-institutions" -name "*.md" -type f | sort)
else
    log_conditional INFO "No institutions directory found"
    INST_COUNT=0
fi
```

### Institution Metadata Extraction

```bash
extract_institution_metadata() {
    local content="$1"

    name=$(echo "$content" | grep "^name:" | sed 's/name: *//' | tr -d '"')
    mandate=$(echo "$content" | grep "^mandate:" | sed 's/mandate: *//' | tr -d '"')
    type=$(echo "$content" | grep "^type:" | sed 's/type: *//' | tr -d '"')

    # Type is required for authority classification
    if [ -z "$type" ]; then
        log_conditional WARN "Institution $name missing type field"
        type="other"
    fi
}
```

## Data Structure Management

### In-Memory Storage

Use bash arrays for entity data:

```bash
# Declare arrays
declare -a SOURCE_IDS
declare -a SOURCE_URLS
declare -a SOURCE_TITLES
declare -a SOURCE_TIERS
declare -a SOURCE_DOMAINS
declare -a SOURCE_ACCESS_DATES

# Populate during loading
SOURCE_IDS+=("$source_id")
SOURCE_URLS+=("$url")
SOURCE_TITLES+=("$title")
SOURCE_TIERS+=("$tier")
SOURCE_DOMAINS+=("$domain")
SOURCE_ACCESS_DATES+=("$access_date")
```

### Domain Grouping

```bash
# Bash 3.2 compatible domain grouping using parallel indexed arrays
DOMAIN_KEYS=()
DOMAIN_SOURCES=()

# Helper to find or add domain
get_or_add_domain_index() {
    local dom="$1"
    local i=0
    for key in "${DOMAIN_KEYS[@]}"; do
        if [[ "$key" == "$dom" ]]; then
            echo "$i"
            return 0
        fi
        i=$((i + 1))
    done
    # Add new domain
    DOMAIN_KEYS+=("$dom")
    DOMAIN_SOURCES+=("")
    echo "$i"
}

# Group sources by domain
for i in "${!SOURCE_IDS[@]}"; do
    domain="${SOURCE_DOMAINS[$i]}"
    source_id="${SOURCE_IDS[$i]}"

    # Find or create domain entry
    idx=$(get_or_add_domain_index "$domain")
    if [ -z "${DOMAIN_SOURCES[$idx]}" ]; then
        DOMAIN_SOURCES[$idx]="$source_id"
    else
        DOMAIN_SOURCES[$idx]="${DOMAIN_SOURCES[$idx]} $source_id"
    fi
done

# Iterate domains
for i in "${!DOMAIN_KEYS[@]}"; do
    domain="${DOMAIN_KEYS[$i]}"
    sources="${DOMAIN_SOURCES[$i]}"
    # Process domain group
done
```

## Verification Checkpoints

### After Entity Loading

```bash
log_conditional INFO "==========================================="
log_conditional INFO "CHECKPOINT: Entity loading complete"
log_conditional INFO "  Sources loaded: $SOURCE_COUNT"
log_conditional INFO "  Citations loaded: $CITATION_COUNT"
log_conditional INFO "  Institutions loaded: $INST_COUNT"
log_conditional INFO "  Total entities: $((SOURCE_COUNT + CITATION_COUNT + INST_COUNT))"
log_conditional INFO "==========================================="
```

### Before Catalog Generation

```bash
# Verify all metadata extracted
verify_metadata_completeness() {
    local issues=0

    # Check sources
    for i in "${!SOURCE_IDS[@]}"; do
        if [ -z "${SOURCE_URLS[$i]}" ]; then
            log_conditional ERROR "Source ${SOURCE_IDS[$i]} missing URL"
            issues=$((issues + 1))
        fi
        if [ -z "${SOURCE_TIERS[$i]}" ]; then
            log_conditional ERROR "Source ${SOURCE_IDS[$i]} missing tier"
            issues=$((issues + 1))
        fi
    done

    if [ $issues -gt 0 ]; then
        log_conditional ERROR "$issues metadata issues found"
        return 1
    fi

    log_conditional INFO "Metadata verification passed"
    return 0
}
```

## Error Recovery Patterns

### Missing Entity Files

```bash
if [ ! -f "$entity_file" ]; then
    log_conditional WARN "Entity file not found: $entity_file"
    # Skip entity, continue processing others
    continue
fi
```

### Malformed YAML

```bash
if ! echo "$content" | grep -q "^---"; then
    log_conditional ERROR "Malformed YAML in $entity_file"
    # Skip entity, log error
    continue
fi
```

### Empty Content

```bash
if [ -z "$content" ] || [ $(echo "$content" | wc -l) -lt 5 ]; then
    log_conditional WARN "Entity appears empty: $entity_file"
    # Skip or flag for review
    continue
fi
```

## Performance Considerations

### Batch Processing

For large entity counts (>100), consider:

1. **Memory management:** Arrays may consume significant memory
2. **Progress logging:** Log every N entities processed
3. **Checkpoint saves:** Write intermediate results for recovery

```bash
# Progress logging
entity_count=0
for file in $SOURCE_FILES; do
    entity_count=$((entity_count + 1))
    if [ $((entity_count % 50)) -eq 0 ]; then
        log_conditional INFO "Processed $entity_count of $SOURCE_COUNT sources"
    fi
done
```

### File I/O Optimization

- Load entities sequentially (Read tool handles buffering)
- Don't re-read files unnecessarily
- Store extracted metadata in memory for reuse

## Anti-Hallucination Compliance

**Final Verification Before Output:**

```bash
# Every catalog entry must trace to loaded entity
verify_no_fabrication() {
    # Check: All source URLs in catalog match loaded URLs
    # Check: All titles match loaded titles
    # Check: All institutions from loaded entities
    # Check: All citations from loaded content

    log_conditional INFO "Anti-hallucination verification passed"
}
```

**Red Flags (immediate failure):**
- Source URL not in loaded data
- Institution name not from entity file
- Citation format not matching loaded content
- Tier classification without source data
