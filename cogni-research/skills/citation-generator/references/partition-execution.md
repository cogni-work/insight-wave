# Partition Execution

## Purpose

Partition execution enables parallel processing of large source sets by dividing work into independent chunks. This prevents timeout failures on projects with 70+ sources while maintaining complete data loading and backward compatibility.

**Key Benefits:**
- Horizontal scaling: Process N sources across M parallel jobs
- Timeout prevention: Each partition completes within reasonable time limits
- Independent execution: No coordination or locking required between partitions
- Complete indexing: All entities loaded before filtering ensures accurate matching

## Partition Parameter

### Format

The partition parameter uses "N/T" format where:
- **N** = Current partition number (1-indexed, 1 to T)
- **T** = Total number of partitions

**Examples:**
- `1/4` = Partition 1 of 4 (first quarter)
- `3/4` = Partition 3 of 4 (third quarter)
- `4/4` = Partition 4 of 4 (last quarter)

### Parsing

Extract partition components using `cut` command:

```bash
# Parse partition (format: "1/4" means partition 1 of 4)
CURRENT=$(echo "$PARTITION" | cut -d'/' -f1)
TOTAL=$(echo "$PARTITION" | cut -d'/' -f2)
```

**How it works:**
- `-d'/'` = Use forward slash as delimiter
- `-f1` = Extract first field (current partition)
- `-f2` = Extract second field (total partitions)

### Validation

Validate partition parameters before processing:

```bash
# Validate partition parameters
if [ "$CURRENT" -lt 1 ] || [ "$CURRENT" -gt "$TOTAL" ]; then
  echo '{"success": false, "error": "Invalid partition: '"$PARTITION"'"}' >&2
  exit 1
fi
```

**Validation Rules:**
- Current partition must be ≥ 1
- Current partition must be ≤ total partitions
- Both values must be positive integers

**Invalid Examples:**
- `0/4` = Invalid (partition numbers start at 1)
- `5/4` = Invalid (current exceeds total)
- `-1/4` = Invalid (negative partition number)

## Partition Filtering Algorithm

### Overview

The algorithm divides an array of N sources into T partitions as evenly as possible, then extracts the slice corresponding to partition N.

**Input:**
- `SOURCES_TO_PROCESS` = Array of all source IDs (size N)
- `CURRENT` = Partition number (1-indexed)
- `TOTAL` = Total partition count

**Output:**
- `SOURCES_TO_PROCESS` = Array slice for current partition

### Ceiling Division

Calculate sources per partition using ceiling division to handle remainders:

```bash
# Calculate sources per partition (ceiling division)
SOURCES_PER_PARTITION=$(( (${#SOURCES_TO_PROCESS[@]} + TOTAL - 1) / TOTAL ))
```

**Why Ceiling Division?**

Standard floor division would leave remainder sources unprocessed. Ceiling division ensures every source assigned to a partition.

**Formula:**
```
sources_per_partition = ⌈N / T⌉ = (N + T - 1) / T
```

**Example with 70 sources, 3 partitions:**
```
sources_per_partition = ⌈70 / 3⌉ = (70 + 3 - 1) / 3 = 72 / 3 = 24
```

Result: 24 sources per partition (some partitions may get fewer due to bounds checking)

### Index Calculation

Calculate start and end indices for array slicing:

```bash
# Calculate start and end indices
START_IDX=$(( (CURRENT - 1) * SOURCES_PER_PARTITION ))
END_IDX=$(( START_IDX + SOURCES_PER_PARTITION ))
```

**Index Calculation Logic:**
- `START_IDX` = Zero-based starting index for partition
- `END_IDX` = Exclusive end index (first index NOT included)

**Formula:**
```
START_IDX = (CURRENT - 1) × sources_per_partition
END_IDX = START_IDX + sources_per_partition
```

**Example with 80 sources, 4 partitions (20 each):**

| Partition | CURRENT | START_IDX | END_IDX | Range |
|-----------|---------|-----------|---------|-------|
| 1/4 | 1 | 0 | 20 | 0-19 (20 sources) |
| 2/4 | 2 | 20 | 40 | 20-39 (20 sources) |
| 3/4 | 3 | 40 | 60 | 40-59 (20 sources) |
| 4/4 | 4 | 60 | 80 | 60-79 (20 sources) |

### Array Bounds

Ensure end index doesn't exceed array size:

```bash
# Ensure END_IDX doesn't exceed array size
if [ "$END_IDX" -gt "${#SOURCES_TO_PROCESS[@]}" ]; then
  END_IDX="${#SOURCES_TO_PROCESS[@]}"
fi
```

**Why Bounds Checking?**

When total sources don't divide evenly, the last partition gets fewer elements. Without bounds checking, END_IDX would exceed array size.

**Example with 70 sources, 3 partitions:**

Ceiling division gives 24 sources per partition:
- Partition 1: indices 0-23 (24 sources) ✓
- Partition 2: indices 24-47 (24 sources) ✓
- Partition 3: indices 48-71 → **bounds check** → 48-69 (22 sources) ✓

Total: 24 + 24 + 22 = 70 sources (all covered)

### Array Slicing

Extract partition slice using bash array slicing syntax:

```bash
# Extract partition slice
SOURCES_TO_PROCESS=("${SOURCES_TO_PROCESS[@]:$START_IDX:$SOURCES_PER_PARTITION}")
```

**Bash Array Slicing Syntax:**
```
${array[@]:offset:length}
```

- `offset` = Starting index (zero-based)
- `length` = Number of elements to extract

**Note:** Even though we calculated `END_IDX`, bash slicing uses **length**, not end index. The length is `SOURCES_PER_PARTITION` (may extract fewer if near array end).

### Logging Partition Assignment

Log partition assignment for debugging and verification:

```bash
log_conditional INFO "Processing partition $CURRENT/$TOTAL: sources $START_IDX to $((END_IDX-1)) (${#SOURCES_TO_PROCESS[@]} sources)"
echo "Processing partition $CURRENT/$TOTAL: sources $START_IDX to $((END_IDX-1)) (${#SOURCES_TO_PROCESS[@]} sources)" >&2
```

**Example Output:**
```
Processing partition 2/4: sources 20 to 39 (20 sources)
```

### Complete Algorithm

```bash
# ===== PARTITION FILTERING (if specified) =====

if [ -n "$PARTITION" ]; then
  log_conditional INFO "Step 2.2: Partition Filtering"
  echo "Partition mode: $PARTITION" >&2

  # Parse partition (format: "1/4" means partition 1 of 4)
  CURRENT=$(echo "$PARTITION" | cut -d'/' -f1)
  TOTAL=$(echo "$PARTITION" | cut -d'/' -f2)

  # Validate partition parameters
  if [ "$CURRENT" -lt 1 ] || [ "$CURRENT" -gt "$TOTAL" ]; then
    echo '{"success": false, "error": "Invalid partition: '"$PARTITION"'"}' >&2
    exit 1
  fi

  # Calculate sources per partition (ceiling division)
  SOURCES_PER_PARTITION=$(( (${#SOURCES_TO_PROCESS[@]} + TOTAL - 1) / TOTAL ))

  # Calculate start and end indices
  START_IDX=$(( (CURRENT - 1) * SOURCES_PER_PARTITION ))
  END_IDX=$(( START_IDX + SOURCES_PER_PARTITION ))

  # Ensure END_IDX doesn't exceed array size
  if [ "$END_IDX" -gt "${#SOURCES_TO_PROCESS[@]}" ]; then
    END_IDX="${#SOURCES_TO_PROCESS[@]}"
  fi

  # Extract partition slice
  SOURCES_TO_PROCESS=("${SOURCES_TO_PROCESS[@]:$START_IDX:$SOURCES_PER_PARTITION}")

  log_conditional INFO "Processing partition $CURRENT/$TOTAL: sources $START_IDX to $((END_IDX-1)) (${#SOURCES_TO_PROCESS[@]} sources)"
  echo "Processing partition $CURRENT/$TOTAL: sources $START_IDX to $((END_IDX-1)) (${#SOURCES_TO_PROCESS[@]} sources)" >&2
fi

echo "Sources to process in this invocation: ${#SOURCES_TO_PROCESS[@]}" >&2
```

## Backward Compatibility

### No Partition Mode

When `--partition` parameter is not provided, process all sources:

```bash
PARTITION=""   # Default: empty string

# Later in workflow...
if [ -n "$PARTITION" ]; then
  # Apply partition filtering
else
  # Process all sources (no filtering)
fi
```

**Behavior:**
- No partition parameter = Process entire `SOURCES_TO_PROCESS` array
- Maintains compatibility with existing workflows
- Single-job execution for small projects

### Optional Parameter

The partition parameter is completely optional:

**Parameter Definition:**
```bash
PARTITION=""   # Partition parameter

while [ $# -gt 0 ]; do
  case "$1" in
    --partition)
      PARTITION="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
```

**Conditional Execution:**
```bash
if [ -n "$PARTITION" ]; then
  # Partition filtering logic executes
  # SOURCES_TO_PROCESS array filtered to partition slice
else
  # No filtering
  # SOURCES_TO_PROCESS array remains complete
fi
```

## Parallel Execution

### Benefits

**1. Timeout Prevention:**
- Large source sets (70+) can exceed execution time limits
- Partitioning divides work into manageable chunks
- Each partition completes within reasonable timeframe

**2. Horizontal Scaling:**
- Process N sources across M parallel jobs
- Linear speedup: 4 partitions = ~4x faster
- No coordination overhead between jobs

**3. Independent Processing:**
- Each partition loads complete dataset
- Filtering happens after indexing
- No shared state or locking required

**4. Fault Isolation:**
- Failure in one partition doesn't affect others
- Retry individual partitions without reprocessing all
- Easier debugging with smaller data slices

### Invocation Pattern

Launch parallel jobs for 4 partitions:

**Sequential (baseline):**
```bash
citation-generator --project-path /path/to/project
# Processes all 80 sources in ~240 seconds
```

**Parallel (4 jobs):**
```bash
# Terminal 1
citation-generator --project-path /path/to/project --partition 1/4 &

# Terminal 2
citation-generator --project-path /path/to/project --partition 2/4 &

# Terminal 3
citation-generator --project-path /path/to/project --partition 3/4 &

# Terminal 4
citation-generator --project-path /path/to/project --partition 4/4 &

# Wait for all jobs to complete
wait
# All 80 sources processed in ~60 seconds
```

**Using xargs for parallel execution:**
```bash
seq 1 4 | xargs -P 4 -I {} citation-generator \
  --project-path /path/to/project \
  --partition {}/4
```

### Independence

**No Coordination Required:**

Each partition is completely independent:
1. **Read-only operations:** Only reads existing source/publisher entities
2. **Unique outputs:** Each source gets unique citation ID (no collisions)
3. **Idempotent writes:** Skips citations that already exist
4. **No shared state:** No locks, semaphores, or coordination primitives

**File System Safety:**

Citation IDs use source slugs + URL hashes:
```bash
CITATION_ID="citation-${SOURCE_SLUG}-${CITATION_HASH}"
```

Different sources = Different citation IDs = No write conflicts

**Verification:**
```bash
# Partition 1 processes source-climate-001
# Creates: citation-climate-001-a3b2c1d4.md

# Partition 2 processes source-climate-025
# Creates: citation-climate-025-e5f6g7h8.md

# No collision possible
```

### Aggregation

**Orchestrator combines results:**

```json
{
  "partition_1": {"citations_created": 20, "citations_skipped": 0},
  "partition_2": {"citations_created": 20, "citations_skipped": 0},
  "partition_3": {"citations_created": 20, "citations_skipped": 0},
  "partition_4": {"citations_created": 20, "citations_skipped": 0}
}
```

**Total Summary:**
```json
{
  "total_citations_created": 80,
  "total_citations_skipped": 0,
  "partitions_completed": 4
}
```

**Aggregation Logic:**

Sum metrics across partition results:
- `total_citations_created` = sum of all `citations_created`
- `total_citations_skipped` = sum of all `citations_skipped`
- `total_domain_exact` = sum of all `domain_exact` matches
- etc.

## Integration with Workflow

### Load Phase

**Phase 2.1: Complete Entity Loading**

Load ALL entities before filtering:

```bash
# Source entity configuration for directory resolution
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_SOURCES="$(get_directory_by_key "sources")"
DATA_SUBDIR="$(get_data_subdir)"

# Count sources first for verification
SOURCE_COUNT=$(find "${PROJECT_PATH}/$DIR_SOURCES" -name "source-*.md" 2>/dev/null | wc -l | tr -d ' ')
log_conditional INFO "Loading $SOURCE_COUNT sources completely (no truncation)..."

# Collect ALL source IDs
SOURCES_TO_PROCESS=()
for source_file in "${PROJECT_PATH}"/$DIR_SOURCES/$DATA_SUBDIR/source-*.md; do
  [ -f "$source_file" ] || continue
  source_id=$(basename "$source_file" .md)
  SOURCES_TO_PROCESS+=("$source_id")
done

# Verify count matches
if [ ${#SOURCES_TO_PROCESS[@]} -ne "$SOURCE_COUNT" ]; then
  log_conditional ERROR "Source count mismatch"
  exit 1
fi

log_conditional INFO "VERIFICATION: All $SOURCE_COUNT sources loaded completely"
```

**Key Points:**
- Load complete dataset (no truncation)
- Verify counts match expected
- Log verification checkpoint
- No filtering yet

### Filter Phase

**Phase 2.2: Partition Filtering**

Apply partition filtering AFTER complete loading:

```bash
# ===== PARTITION FILTERING (if specified) =====

if [ -n "$PARTITION" ]; then
  log_conditional INFO "Step 2.2: Partition Filtering"

  # Apply partition algorithm (see above)
  # Filters SOURCES_TO_PROCESS to partition slice

  SOURCES_TO_PROCESS=("${SOURCES_TO_PROCESS[@]:$START_IDX:$SOURCES_PER_PARTITION}")

  log_conditional INFO "Processing partition $CURRENT/$TOTAL: ${#SOURCES_TO_PROCESS[@]} sources"
fi
```

**Key Points:**
- Filtering happens after loading
- Modifies existing `SOURCES_TO_PROCESS` array
- Logs filtered count
- Proceeds to Phase 3 with filtered array

### Why This Order

**Load First, Filter Second:**

```
┌─────────────────────────────────────────────────────────┐
│ Phase 2.1: Complete Entity Loading                      │
│                                                          │
│ Load ALL sources:     [S1, S2, S3, ..., S80]           │
│ Load ALL publishers:  [P1, P2, P3, ..., P50]           │
│ Build ALL indexes:    domain_map, name_map, reverse    │
│                                                          │
│ Result: Complete knowledge graph in memory              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 2.2: Partition Filtering (Optional)               │
│                                                          │
│ Filter sources only:  [S21, S22, ..., S40]             │
│ Keep all publishers:  [P1, P2, P3, ..., P50]           │
│ Keep all indexes:     domain_map, name_map, reverse    │
│                                                          │
│ Result: Process subset, match against complete data    │
└─────────────────────────────────────────────────────────┘
```

**Why Not Filter During Loading?**

**Problem:** Early filtering breaks publisher matching

```bash
# WRONG: Filter during loading
for source_file in "${PROJECT_PATH}"/07-sources/data/source-*.md; do
  # Only load sources in current partition
  if source_in_partition "$source_file" "$PARTITION"; then
    SOURCES_TO_PROCESS+=("$source_id")
  fi
done
# Result: Incomplete source list → Broken reverse index
```

**Solution:** Filter after loading

```bash
# CORRECT: Load all, then filter
for source_file in "${PROJECT_PATH}"/07-sources/data/source-*.md; do
  SOURCES_TO_PROCESS+=("$source_id")  # Load all sources
done
# Build complete indexes
# Then filter SOURCES_TO_PROCESS array
```

**Indexing Needs Complete Data:**

Publisher resolution uses 4 strategies:
1. **Domain exact match:** Requires complete domain→publisher map
2. **Name exact match:** Requires complete name→publisher map
3. **Reverse index:** Requires complete source→publisher map
4. **Domain fallback:** Requires domain extracted from all sources

Incomplete loading → Incomplete indexes → Failed matches → Higher fallback rate

## Examples

### Example 1: 80 Sources, 4 Partitions

**Setup:**
- Total sources: 80
- Total partitions: 4
- Sources per partition: ⌈80/4⌉ = 20

**Partition 1/4:**
```bash
CURRENT=1, TOTAL=4
SOURCES_PER_PARTITION = (80 + 4 - 1) / 4 = 83 / 4 = 20
START_IDX = (1 - 1) × 20 = 0
END_IDX = 0 + 20 = 20
Bounds check: 20 ≤ 80 ✓
Slice: [0:20] → sources 0-19 (20 sources)
```

**Partition 2/4:**
```bash
CURRENT=2, TOTAL=4
START_IDX = (2 - 1) × 20 = 20
END_IDX = 20 + 20 = 40
Bounds check: 40 ≤ 80 ✓
Slice: [20:20] → sources 20-39 (20 sources)
```

**Partition 3/4:**
```bash
CURRENT=3, TOTAL=4
START_IDX = (3 - 1) × 20 = 40
END_IDX = 40 + 20 = 60
Bounds check: 60 ≤ 80 ✓
Slice: [40:20] → sources 40-59 (20 sources)
```

**Partition 4/4:**
```bash
CURRENT=4, TOTAL=4
START_IDX = (4 - 1) × 20 = 60
END_IDX = 60 + 20 = 80
Bounds check: 80 ≤ 80 ✓
Slice: [60:20] → sources 60-79 (20 sources)
```

**Summary:**
| Partition | Range | Count | Status |
|-----------|-------|-------|--------|
| 1/4 | 0-19 | 20 | ✓ |
| 2/4 | 20-39 | 20 | ✓ |
| 3/4 | 40-59 | 20 | ✓ |
| 4/4 | 60-79 | 20 | ✓ |
| **Total** | **0-79** | **80** | **✓** |

### Example 2: 70 Sources, 3 Partitions (Uneven Division)

**Setup:**
- Total sources: 70
- Total partitions: 3
- Sources per partition: ⌈70/3⌉ = ⌈23.33⌉ = 24

**Partition 1/3:**
```bash
CURRENT=1, TOTAL=3
SOURCES_PER_PARTITION = (70 + 3 - 1) / 3 = 72 / 3 = 24
START_IDX = (1 - 1) × 24 = 0
END_IDX = 0 + 24 = 24
Bounds check: 24 ≤ 70 ✓
Slice: [0:24] → sources 0-23 (24 sources)
```

**Partition 2/3:**
```bash
CURRENT=2, TOTAL=3
START_IDX = (2 - 1) × 24 = 24
END_IDX = 24 + 24 = 48
Bounds check: 48 ≤ 70 ✓
Slice: [24:24] → sources 24-47 (24 sources)
```

**Partition 3/3:**
```bash
CURRENT=3, TOTAL=3
START_IDX = (3 - 1) × 24 = 48
END_IDX = 48 + 24 = 72
Bounds check: 72 > 70 → END_IDX = 70
Slice: [48:24] → sources 48-69 (22 sources, bounds limited)
```

**Summary:**
| Partition | Range | Count | Notes |
|-----------|-------|-------|-------|
| 1/3 | 0-23 | 24 | Full partition |
| 2/3 | 24-47 | 24 | Full partition |
| 3/3 | 48-69 | 22 | **Bounds check** reduced count |
| **Total** | **0-69** | **70** | **✓ All covered** |

**Key Trend:** Ceiling division ensures last partition gets remainder sources (not lost).

### Example 3: No Partition (Process All)

**Setup:**
- Total sources: 42
- Partition parameter: (not provided)

**Behavior:**
```bash
PARTITION=""  # Empty string

# Load all sources
SOURCES_TO_PROCESS=(source-001 source-002 ... source-042)  # 42 sources

# Partition filtering check
if [ -n "$PARTITION" ]; then
  # NOT executed (PARTITION is empty)
fi

# Continue with full array
echo "Sources to process: ${#SOURCES_TO_PROCESS[@]}"  # 42
```

**Result:**
- All 42 sources processed in single job
- No filtering applied
- Backward compatible with existing workflows

## Testing

### Edge Cases

**1. Partition N/N (Single Partition = All Sources):**
```bash
# 50 sources, partition 1/1
CURRENT=1, TOTAL=1
SOURCES_PER_PARTITION = (50 + 1 - 1) / 1 = 50
START_IDX = 0
END_IDX = 50
Slice: [0:50] → sources 0-49 (50 sources)
Result: Identical to no partition mode ✓
```

**2. Partition 1/1 vs No Partition:**
```bash
# Should produce identical results
--partition 1/1  →  Process all 50 sources
(no partition)   →  Process all 50 sources
```

**3. Single Source Per Partition:**
```bash
# 4 sources, 4 partitions
SOURCES_PER_PARTITION = (4 + 4 - 1) / 4 = 7 / 4 = 1

Partition 1/4: sources 0-0 (1 source)
Partition 2/4: sources 1-1 (1 source)
Partition 3/4: sources 2-2 (1 source)
Partition 4/4: sources 3-3 (1 source)
Result: Each partition gets exactly 1 source ✓
```

**4. More Partitions Than Sources:**
```bash
# 3 sources, 5 partitions
SOURCES_PER_PARTITION = (3 + 5 - 1) / 5 = 7 / 5 = 1

Partition 1/5: START=0, END=1 → source 0 (1 source)
Partition 2/5: START=1, END=2 → source 1 (1 source)
Partition 3/5: START=2, END=3 → source 2 (1 source)
Partition 4/5: START=3, END=4 → bounds check → END=3 → [] (0 sources)
Partition 5/5: START=4, END=5 → bounds check → END=3 → [] (0 sources)

Result: Partitions 4-5 empty, all sources covered in 1-3 ✓
```

**5. Empty Source Array:**
```bash
# 0 sources, 4 partitions
SOURCES_PER_PARTITION = (0 + 4 - 1) / 4 = 3 / 4 = 0

All partitions: START=0, END=0 → [] (0 sources)
Result: All partitions empty, graceful handling ✓
```

### Validation

**Test 1: No Sources Missed**

Verify all sources processed across partitions:

```bash
# For 80 sources, 4 partitions
partition_1_sources=20
partition_2_sources=20
partition_3_sources=20
partition_4_sources=20
total=$((partition_1_sources + partition_2_sources + partition_3_sources + partition_4_sources))

if [ "$total" -eq 80 ]; then
  echo "✓ All sources covered"
else
  echo "✗ Missing sources: expected 80, got $total"
fi
```

**Test 2: No Sources Duplicated**

Verify no overlap between partitions:

```bash
# Collect all source IDs from each partition
partition_1_ids=(...)  # Sources 0-19
partition_2_ids=(...)  # Sources 20-39
partition_3_ids=(...)  # Sources 40-59
partition_4_ids=(...)  # Sources 60-79

# Check for duplicates
all_ids=("${partition_1_ids[@]}" "${partition_2_ids[@]}" "${partition_3_ids[@]}" "${partition_4_ids[@]}")
unique_ids=$(printf '%s\n' "${all_ids[@]}" | sort -u | wc -l)

if [ "${#all_ids[@]}" -eq "$unique_ids" ]; then
  echo "✓ No duplicates"
else
  echo "✗ Duplicates found"
fi
```

**Test 3: Partition Boundaries**

Verify partition boundaries are correct:

```bash
# For 70 sources, 3 partitions
# Expected: [0-23], [24-47], [48-69]

# Partition 1: Last source should be 23
# Partition 2: First source should be 24, last should be 47
# Partition 3: First source should be 48, last should be 69

# Check gaps
if partition_1_end + 1 == partition_2_start && \
   partition_2_end + 1 == partition_3_start; then
  echo "✓ No gaps between partitions"
else
  echo "✗ Gaps detected"
fi
```

**Test 4: Edge Case Handling**

Test edge cases systematically:

```bash
test_cases=(
  "50:1"   # 50 sources, 1 partition
  "50:50"  # 50 sources, 50 partitions (1 each)
  "50:100" # 50 sources, 100 partitions (some empty)
  "0:4"    # 0 sources, 4 partitions (all empty)
  "1:4"    # 1 source, 4 partitions (1 full, 3 empty)
)

for test_case in "${test_cases[@]}"; do
  sources=$(echo "$test_case" | cut -d: -f1)
  partitions=$(echo "$test_case" | cut -d: -f2)

  # Run partition algorithm
  # Verify correctness
  echo "Test: $sources sources, $partitions partitions"
done
```

## Performance Characteristics

**Time Complexity:**
- Parsing: O(1)
- Validation: O(1)
- Ceiling division: O(1)
- Index calculation: O(1)
- Array slicing: O(k) where k = partition size
- **Total: O(k)** per partition

**Space Complexity:**
- Original array: O(n) where n = total sources
- Partition slice: O(k) where k = n/partitions
- **Total: O(n)** (complete array kept in memory before slicing)

**Parallel Speedup:**
- Sequential: T seconds for n sources
- Parallel (p partitions): ~T/p seconds (assuming perfect parallelism)
- Overhead: Minimal (independent jobs, no coordination)

**Example:**
- 80 sources, sequential: 240 seconds
- 80 sources, 4 partitions: 60 seconds (~4x speedup)
