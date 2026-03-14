# Parallelization Strategies

## Overview

The deeper-research workflow uses parallel agent execution in five phases to maximize performance:

- **Phase 4**: Research Execution (all batches simultaneously, dimension-based)
- **Phase 6**: Publisher Generation (dimension-based partitioning)
- **Phase 7**: Fact Verification (2× rule based on batch count)
- **Phase 8**: Trend Generation (parallel, one agent per dimension)

## Core Principle: Single Message, Multiple Task Calls

To execute agents in parallel, invoke ALL agents in a single message with multiple Task tool calls. Claude Code automatically manages parallel execution and returns all responses when complete.

### Example: 18 Parallel Agents
```
Single message with all Task invocations:
- Task: research-executor (batch-001.md)
- Task: research-executor (batch-002.md)
- Task: research-executor (batch-003.md)
- ... (all 18 batches)
- Task: research-executor (batch-018.md)

Claude Code manages execution automatically, then returns all responses
```

## Phase 4: Research Execution

### Strategy: All-Batches Parallel

Execute all query batches simultaneously, regardless of count.

### Implementation

1. **Count batches**:
   ```bash
   batch_count=$(find {project-path}/03-query-batches/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
   ```

2. **Invoke ALL research-executor agents in parallel** (single message):
   - For each batch file: create Task invocation
   - Parameters:
     * Batch path: `{project-path}/03-query-batches/data/batch-{N}.md`
     * Project path: From Phase 0

3. **Collect responses** (Claude Code manages execution):
   - Each agent returns: `{"findings": 15}`
   - Aggregate: Sum all findings across batches

4. **Report**:
   ```
   ✓ Phase 4: Created {total_findings} findings across {batch_count} batches
   ```

### Example: 18 Batches

**Invocation**:
```
Invoke 18 research-executor agents in parallel:
- Agent 0: batch-001.md
- Agent 1: batch-002.md
...
- Agent 17: batch-018.md
```

**Responses**:
```json
Agent 0: {"findings": 7}
Agent 1: {"findings": 8}
...
Agent 17: {"findings": 6}
```

**Aggregation**:
```
total_findings = 7 + 8 + ... + 6 = 123
```

**Report**:
```
✓ Phase 4: Created 123 findings across 18 batches
```

### Performance

- **Old (sequential)**: 18 batches × 45s = 13.5 minutes
- **New (parallel)**: ~45s (limited by slowest batch)
- **Speedup**: ~18× faster

### Note: Batch Count Determines Phase 7

Save `batch_count` from Phase 4 for Phase 7 parallelization (2× rule).

## Phase 6: Publisher Generation

### Strategy: Dimension-Based Partitioning (Natural Workflow Alignment)

Partition sources by dimension (using finding metadata) and invoke one publisher-generator sub-agent per dimension in parallel.

**Rationale**: Sources naturally group by research dimension through their findings' batch_id. This alignment leverages the existing dimension-based architecture from Phase 4 (research execution) for optimal parallelization without artificial partitioning.

### Implementation

1. **Partition sources by dimension**:
   ```bash
   # Discover sources (Bash 3.2 compatible)
   sources=()
   while IFS= read -r -d '' file; do
     sources+=("$file")
   done < <(find {project-path}/07-sources -name "source-*.md" -type f -print0)

   # Create dimension partitions (Bash 3.2 compatible - parallel indexed arrays)
   DIMENSION_KEYS=()
   DIMENSION_SOURCES=()  # dimension -> source paths (space-separated)
   DIMENSION_COUNTS=()   # dimension -> count

   # Helper to find or add dimension
   get_or_add_dimension_index() {
     local dim="$1"
     local i=0
     for key in "${DIMENSION_KEYS[@]}"; do
       if [[ "$key" == "$dim" ]]; then
         echo "$i"
         return 0
       fi
       i=$((i + 1))
     done
     # Add new dimension
     DIMENSION_KEYS+=("$dim")
     DIMENSION_SOURCES+=("")
     DIMENSION_COUNTS+=(0)
     echo "$i"
   }

   # Extract dimension from each source via finding metadata
   for source in "${sources[@]}"; do
     # Get first finding wikilink from source
     first_finding=$(grep -m1 '\[\[04-findings/data/finding-' "$source" | \
       sed 's/.*\[\[\(04-findings\/finding-[^]]*\)\]\].*/\1/')
     finding_path="{project-path}/${first_finding}.md"

     # Get batch_id (dimension) from finding
     batch_file=$(grep -m1 'batch_id:' "$finding_path" | \
       sed 's/.*\[\[03-query-batches\/\([^]]*\)\]\].*/\1/')

     # Add to partition
     idx=$(get_or_add_dimension_index "$batch_file")
     DIMENSION_SOURCES[$idx]="${DIMENSION_SOURCES[$idx]}$source "
     DIMENSION_COUNTS[$idx]=$((DIMENSION_COUNTS[$idx] + 1))
   done

   dimension_count=${#DIMENSION_KEYS[@]}
   ```

2. **Invoke ALL publisher-generator sub-agents in parallel** (single message):
   - For each dimension: create Task invocation with assigned sources
   - Agent: `cogni-research:publisher-generator`
   - Parameters: `--project-path {path} --source-files {source-list}`

3. **Collect responses** (JSON from each sub-agent):
   ```json
   {
     "success": true,
     "sources_processed": 8,
     "publishers_created": 6,
     "publishers_reused": 2,
     "publishers_enriched": 8,
     "by_type": {"individual": 3, "organization": 5}
   }
   ```

4. **Aggregate metrics**:
   - Sum: `sources_processed`, `publishers_created`, `publishers_reused`, `publishers_enriched`
   - Merge: `by_type` counts (individuals, organizations)

5. **Report**:
   ```
   ✓ Phase 6: Generated {total_publishers} publishers across {dimension_count} dimensions ({created} created, {reused} reused, {enriched} enriched)
   ```

### Example: 6 Dimensions, 48 Sources → 6 Agents

**Calculation**:
```bash
dimension_count = 6
agent_count = dimension_count = 6
```

**Distribution** (by dimension):
```
Dimension economic (query-batch-001): 8 sources
Dimension technical (query-batch-002): 12 sources
Dimension regulatory (query-batch-003): 6 sources
Dimension operational (query-batch-004): 10 sources
Dimension market-landscape (query-batch-005): 7 sources
Dimension stakeholder (query-batch-006): 5 sources

Total: 48 sources across 6 dimensions
```

**Invocation**:
```
Invoke 6 publisher-generator sub-agents in parallel:
- Agent 0 (economic): 8 sources
- Agent 1 (technical): 12 sources
- Agent 2 (regulatory): 6 sources
- Agent 3 (operational): 10 sources
- Agent 4 (market-landscape): 7 sources
- Agent 5 (stakeholder): 5 sources
```

**Performance**:
- **Old (sequential)**: 48 sources × 20s = 16 minutes
- **New (6 agents, largest partition)**: ~12 sources × 20s = ~4 minutes
- **Speedup**: ~4× faster (limited by largest partition)

### Key Properties

**Natural Alignment**:
- Dimensions already exist from Phase 2 (dimensional planning)
- Findings tagged with batch_id from Phase 4 (research execution)
- Sources inherit dimension affinity from findings
- No artificial partitioning needed

**Load Balancing**:
- Distribution reflects research breadth per dimension
- Uneven loads acceptable (dimensions naturally vary in source count)
- Largest partition determines completion time

**Typical Performance**:
- **Dimension count**: 4-8 (based on research complexity)
- **Sources per dimension**: 5-15 (varies by research depth)
- **Expected speedup**: 4-8× vs. sequential

### Edge Cases

**Single Dimension** (rare):
```bash
dimension_count = 1
agent_count = 1
```
- Single agent processes all sources (no parallelization)
- Same behavior as sequential processing

**Uneven Distribution**:
```bash
# Example: 4 dimensions with [20, 5, 3, 2] sources
dimension_count = 4
# Agent 0 processes 20 sources (~7 min)
# Agent 1 processes 5 sources (~2 min)
# Agent 2 processes 3 sources (~1 min)
# Agent 3 processes 2 sources (~40s)
# Total time: ~7 min (limited by largest partition)
```

**Orphaned Sources**:
- Sources with no valid finding → batch_id mapping are skipped
- Logged as warnings during partitioning
- Data quality manager (Phase 6.1) handles cleanup

## Phase 7: Fact Verification

### Strategy: 2× Rule (Based on Batch Count)

Calculate agent count as 2× the number of query batches from Phase 4.

### Rationale

Batch count correlates with dimension count (architectural choice: one batch per dimension from Phase 3).

**Current Formula**: `agent_count = batch_count × 2`
- 3 batches (3 dimensions) → 6 fact-checkers
- 9 batches (9 dimensions) → 18 fact-checkers
- 18 batches (18 dimensions) → 36 fact-checkers

**Alternative Approach**: Use findings-based calculation like Phase 6:
- `agent_count = finding_count / 10` (max 10)
- More directly tied to workload size

**Current formula maintained** for consistency with existing projects. The 2× multiplier provides reasonable parallelization without over-segmentation.

### Implementation

1. **Retrieve batch count from Phase 4**:
   ```bash
   batch_count=$(find {project-path}/03-query-batches/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
   ```

2. **Apply 2× rule**:
   ```bash
   agent_count=$((batch_count * 2))
   # Example: 4 batches → 8 fact-checker agents
   ```

3. **List findings**:
   ```bash
   # Bash 3.2 compatible (mapfile requires Bash 4.0+)
   findings=()
   while IFS= read -r f; do
       findings+=("$f")
   done < <(find "{project-path}/04-findings/data" -maxdepth 1 -name "*.md" -type f | sort)
   finding_count=${#findings[@]}
   ```

4. **Distribute findings using round-robin**:
   - For agent_index in 0..(agent_count-1):
     * Assign findings: agent_index, agent_index+agent_count, agent_index+(2×agent_count), ...

5. **Invoke ALL fact-checker agents in parallel** (single message):
   - For each agent: provide assigned finding file paths
   - Example prompt: "Process findings: finding-001.md, finding-009.md, ..."

6. **Collect responses**:
   - Each agent returns: `{"claims": 23, "avg_confidence": 0.78}`
   - Aggregate:
     * Sum claims across all agents
     * Calculate weighted average confidence
   - Report: "✓ Phase 7: Verified {total_claims} claims (average confidence: {avg_confidence})"

### Example: 4 Batches, 60 Findings → 8 Agents

**Calculation**:
```bash
batch_count = 4
agent_count = 4 × 2 = 8 agents
finding_count = 60
```

**Distribution** (round-robin):
```
Agent 0: findings 0, 8, 16, 24, 32, 40, 48, 56 (8 findings)
Agent 1: findings 1, 9, 17, 25, 33, 41, 49, 57 (8 findings)
Agent 2: findings 2, 10, 18, 26, 34, 42, 50, 58 (8 findings)
Agent 3: findings 3, 11, 19, 27, 35, 43, 51, 59 (8 findings)
Agent 4: findings 4, 12, 20, 28, 36, 44, 52 (7 findings)
Agent 5: findings 5, 13, 21, 29, 37, 45, 53 (7 findings)
Agent 6: findings 6, 14, 22, 30, 38, 46, 54 (7 findings)
Agent 7: findings 7, 15, 23, 31, 39, 47, 55 (7 findings)
```

**Invocation**:
```
Invoke 8 fact-checker agents in parallel:
- Agent 0: finding-001.md finding-009.md ... finding-057.md (8 files)
- Agent 1: finding-002.md finding-010.md ... finding-058.md (8 files)
...
- Agent 7: finding-008.md finding-016.md ... finding-056.md (7 files)
```

**Performance**:
- **Old (sequential)**: 60 findings × 30s = 30 minutes
- **New (8 agents)**: ~8 findings × 30s = ~4 minutes
- **Speedup**: ~8× faster

## Phase 8: Trend Generation

### Strategy: Parallel Dimension-Based Invocation

Always invoke one trends-creator agent per dimension in parallel (one agent per dimension from `01-research-dimensions/data/`).

### Implementation

1. **Extract dimensions**:

   ```bash
   # List dimension files
   # Bash 3.2 compatible (mapfile requires Bash 4.0+)
   dimension_files=()
   while IFS= read -r f; do
       dimension_files+=("$f")
   done < <(find "01-research-dimensions/data" -maxdepth 1 -name "dimension-*.md" -type f | sort)
   dimension_count=${#dimension_files[@]}

   # Extract dimension slugs
   # Pattern: dimension-{slug}-{entity-id}.md
   dimension_slugs=()
   for file in "${dimension_files[@]}"; do
       basename=$(basename "$file" .md)
       # Remove "dimension-" prefix and entity ID suffix
       slug=$(echo "$basename" | sed 's/^dimension-//' | sed 's/-[a-f0-9]\{8\}$//')
       dimension_slugs+=("$slug")
   done
   ```

2. **Invoke ALL trends-creator agents in parallel** (single message):

   ```python
   # For N dimensions, invoke ALL in single message:
   Task(
     subagent_type="cogni-research:trends-creator",
     prompt="Generate trends at {project-path} for dimension: {dimension_slug_1}",
     description="Creating trends for {dimension_slug_1}"
   )
   Task(
     subagent_type="cogni-research:trends-creator",
     prompt="Generate trends at {project-path} for dimension: {dimension_slug_2}",
     description="Creating trends for {dimension_slug_2}"
   )
   # ... one Task per dimension
   ```

3. **Collect responses** (JSON from each agent):

   ```json
   {
     "success": true,
     "dimension": "dimension-slug",
     "trends_created": 12,
     "total_citations": 45,
     "findings_coverage": "15/18"
   }
   ```

4. **Aggregate metrics**:

   ```text
   total_trends = sum(agent.trends_created for each agent)
   total_citations = sum(agent.total_citations for each agent)
   findings_coverage = "{sum(referenced)}/{total_findings}"
   ```

5. **Report**:

   ```text
   ✓ Phase 8: Generated {total_trends} trends across {dimension_count} dimensions ({total_citations} citations, coverage: {findings_coverage})
   ```

### Example: 4 Dimensions

**Distribution**:

```text
Dimension externe-effekte: 12 trends
Dimension neue-horizonte: 11 trends
Dimension digitale-wertetreiber: 13 trends
Dimension digitales-fundament: 10 trends

Total: 46 trends across 4 dimensions
```

**Performance**:

- **Old (sequential)**: 4 dimensions × ~3 min = ~12 minutes
- **New (4 parallel agents)**: ~3 min (limited by slowest dimension)
- **Speedup**: ~4× faster

### Example: 8 Dimensions (b2b-ict-portfolio)

**Distribution**:

```text
Dimension provider-profile-metrics: 6 trends
Dimension cloud: 8 trends
Dimension consulting: 6 trends
Dimension connectivity: 9 trends
Dimension security: 7 trends
Dimension digital-workplace: 5 trends
Dimension application: 6 trends
Dimension managed-infrastructure: 8 trends

Total: 55 trends across 8 dimensions (0-7)
```

**Performance**:

- **Old (sequential)**: 8 dimensions × ~3 min = ~24 minutes
- **New (8 parallel agents)**: ~3 min (limited by slowest dimension)
- **Speedup**: ~8× faster

## Round-Robin Distribution Algorithm

### Pseudocode

```python
def distribute_round_robin(items, agent_count):
    """Distribute items across agents using round-robin."""
    agents = [[] for _ in range(agent_count)]

    for index, item in enumerate(items):
        agent_index = index % agent_count
        agents[agent_index].append(item)

    return agents

# Example: 10 items, 3 agents
items = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
agents = distribute_round_robin(items, 3)
# Result:
# Agent 0: [0, 3, 6, 9]
# Agent 1: [1, 4, 7]
# Agent 2: [2, 5, 8]
```

### Bash Implementation

```bash
# Count items
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
items=()
while IFS= read -r item; do
    items+=("$item")
done < <(find "{directory}" -maxdepth 1 -name "*.md" -type f | sort)
item_count=${#items[@]}

# Calculate agent count (based on strategy)
agent_count=...  # Phase-specific calculation

# Distribute items using portable bash for-loop (compatible with all shells)
for ((agent_index = 0; agent_index < agent_count; agent_index++)); do
    agent_items=()
    for ((item_index = agent_index; item_index < item_count; item_index += agent_count)); do
        agent_items+=("${items[$item_index]}")
    done

    # Invoke agent with assigned items
    echo "Agent $agent_index: ${agent_items[@]}"
done
```

### Properties

**Load Balancing**:
- Agents receive similar workloads
- Difference: ≤1 item between any two agents

**Deterministic**:
- Same input → same distribution
- Reproducible for debugging

**Race-Safe**:
- No shared state between agents
- Each agent processes independent items

## Performance Comparison

### Without Parallelization (Sequential)

**Phase 4** (8 batches/dimensions):
- Time: 8 × 45s = 6 minutes

**Phase 6** (48 sources):
- Time: 48 × 20s = 16 minutes

**Phase 7** (60 findings):
- Time: 60 × 30s = 30 minutes

**Total**: ~52 minutes

### With Parallelization

**Phase 4** (8 dimension-based agents):
- Time: ~45s (limited by slowest batch)

**Phase 6** (6 dimension-based agents, 8 sources average):
- Time: ~12 sources × 20s = 4 minutes (limited by largest partition)

**Phase 7** (16 agents via 2× rule):
- Time: ~4 findings × 30s = 2 minutes

**Total**: ~7 minutes

**Speedup**: ~7-8× faster overall

## Best Practices

1. **Always use single message for parallel invocations**: Don't send sequential messages with individual Task calls
2. **Let Claude Code manage execution**: Don't manually batch or throttle
3. **Use round-robin for load balancing**: Ensures fair distribution
4. **Cap maximum agents**: 10 agents for citation management, unlimited for research execution
5. **Save intermediate counts**: Batch count from Phase 4 needed for Phase 7
6. **Aggregate responses carefully**: Sum counts, calculate weighted averages for confidence scores
7. **Report concisely**: "✓ Phase N: {summary}" format

---

## Concurrency Limits

**Claude Code Agent Concurrency:**
- Supports unlimited parallel Task invocations
- **Practical limit**: ~50 agents per invocation for optimal performance
- If >50 agents needed: Batch in waves of 50
- **Example**: 72 agents → Wave 1 (50 agents), Wave 2 (22 agents)

**Current Usage:**
- Phase 4: Unlimited batches (typically 3-18, well below 50)
- Phase 6: Max 10 agents (capped by strategy)
- Phase 7: 2× batch count (typically 6-36, may exceed 50 for very complex research)

**Rate Limits**: No known Claude Code rate limits for agent invocations (as of 2025-01)
