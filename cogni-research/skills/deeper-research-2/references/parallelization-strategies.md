# Parallelization Strategies

## Overview

The deeper-research workflow uses parallel agent execution in select phases to maximize performance:

- **Phase 3**: Parallel Findings Creation (all refined questions simultaneously, question-based)
- **Phase 5**: Knowledge Extraction (dimension-based: 1 agent per dimension + merge phase)
- **Phase 6**: Publisher Generation (**DEPRECATED** - now sequential, see below)
- **Phase 7**: Fact Verification (15-sources rule: 1 agent per 15 sources)
- **Phase 8.1-8.2**: Synthesis (parallel domain and dimension synthesizers)

## Core Principle: Single Message, Multiple Task Calls

To execute agents in parallel, invoke ALL agents in a single message with multiple Task tool calls. Claude Code automatically manages parallel execution and returns all responses when complete.

### Example: 20 Parallel Agents
```
Single message with all Task invocations:
- Task: findings-creator (wettbewerber-q1.md)
- Task: findings-creator (wettbewerber-q2.md)
- Task: findings-creator (wettbewerber-q3.md)
- ... (all 20 refined questions)
- Task: findings-creator (marktgroesse-q8.md)

Claude Code manages execution automatically, then returns all responses
```

## Phase 3: Parallel Findings Creation

### Strategy: All-Questions Parallel

Execute findings-creator for all refined questions simultaneously, regardless of count. Each agent performs complete workflow: query optimization, batch creation, search execution, and finding extraction.

### Implementation

1. **Count refined questions**:
   ```bash
   question_count=$(find {project-path}/02-refined-questions/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
   ```

2. **Invoke ALL findings-creator agents in parallel** (single message):
   - For each refined question file: create Task invocation
   - Parameters:
     * refined-question-path: `{project-path}/02-refined-questions/data/{question-slug}.md`
     * project-path: From Phase 0

3. **Collect responses** (Claude Code manages execution):
   - Each agent returns: `{"findings": 12, "batch_id": "question-slug-b"}`
   - Aggregate: Sum all findings across questions

4. **Report**:
   ```
   ✓ Phase 3: Created {total_findings} findings across {question_count} query batches
   ```

### Example: 20 Refined Questions

**Invocation**:
```
Invoke 20 findings-creator agents in parallel:
- Agent 0: wettbewerber-q1.md
- Agent 1: wettbewerber-q2.md
...
- Agent 19: marktgroesse-q8.md
```

**Responses**:
```json
Agent 0: {"findings": 9, "batch_id": "wettbewerber-q1-b"}
Agent 1: {"findings": 11, "batch_id": "wettbewerber-q2-b"}
...
Agent 19: {"findings": 8, "batch_id": "marktgroesse-q8-b"}
```

**Aggregation**:
```
total_findings = 9 + 11 + ... + 8 = 195
total_batches = 20 (one per question)
```

**Report**:
```
✓ Phase 3: Created 195 findings across 20 query batches (one per refined question)
```

### Performance

- **Old (Phase 3 + Phase 4 sequential)**: 1 query optimizer + 5 dimension executors × 45s = ~5 minutes
- **New (Phase 3 parallel)**: ~45s (limited by slowest question)
- **Speedup**: ~6× faster

### Note: Source Count Determines Phase 7

Phase 7 uses source count (from Phase 5/6) for parallelization via the 15-sources rule.

## Phase 5: Knowledge Extraction (Dimension-Based)

### Strategy: Dimension-Based Parallelization + Sequential Merge

Extract concepts in parallel (one agent per dimension), then merge and cluster megatrends sequentially.

### Rationale

Dimension-based partitioning is ideal for knowledge extraction because:

- **Natural partition**: Findings are already linked to dimensions via `batch_ref → question_ref → dimension_ref`
- **Good workload distribution**: Dimensions typically have 20-50 findings each
- **Cross-dimension deduplication**: Handled in merge phase to avoid duplicate concepts
- **Megatrend clustering preserved**: Cross-dimension megatrend discovery happens in merge phase

### Architecture

```
Phase 5.1: Parallel Concept Extraction
├── knowledge-extractor --dimension=dim-1 --concepts-only
├── knowledge-extractor --dimension=dim-2 --concepts-only
├── knowledge-extractor --dimension=dim-3 --concepts-only
└── ... (one agent per dimension)

Phase 5.2: Sequential Merge + Megatrend Clustering
└── knowledge-merger
    ├── Deduplicate concepts across dimensions
    ├── Cross-dimension megatrend clustering
    ├── Update dimension backlinks
    └── Generate README mindmaps
```

### Implementation

1. **Discover dimensions**:
   ```bash
   dimensions=()
   for dim_file in "${PROJECT_PATH}"/01-research-dimensions/data/dimension-*.md; do
     [ -f "$dim_file" ] || continue
     dim_slug=$(basename "$dim_file" .md)
     dimensions+=("$dim_slug")
   done
   dimension_count=${#dimensions[@]}
   ```

2. **Invoke ALL knowledge-extractors in parallel** (single message):
   ```python
   for dimension in dimensions:
       Task(
           subagent_type="cogni-research:knowledge-extractor",
           prompt=f"Extract concepts --dimension={dimension} --concepts-only",
           description=f"Extracting concepts for {dimension}"
       )
   ```

3. **Retry failed dimensions once**:
   - Track failed dimensions
   - Retry in a second parallel batch
   - Continue with successful results if retry fails

4. **Invoke knowledge-merger** (sequential):
   ```python
   Task(
       subagent_type="cogni-research:knowledge-merger",
       prompt="Merge concepts and cluster megatrends",
       description="Merging concepts and creating megatrends"
   )
   ```

5. **Report**:
   ```
   ✓ Phase 5: Extracted {concepts_final} concepts, {megatrends_created} megatrends
     ({concepts_deduplicated} duplicates merged across {dimension_count} dimensions)
   ```

### Example: 5 Dimensions, 200 Findings

**Phase 5.1 Invocation**:
```
Invoke 5 knowledge-extractor agents in parallel:
- Agent 0: dimension-market-analysis --concepts-only
- Agent 1: dimension-technology --concepts-only
- Agent 2: dimension-competitors --concepts-only
- Agent 3: dimension-regulations --concepts-only
- Agent 4: dimension-trends --concepts-only
```

**Phase 5.1 Responses**:
```json
Agent 0: {"success": true, "dimension": "market-analysis", "concepts_created": 8}
Agent 1: {"success": true, "dimension": "technology", "concepts_created": 12}
Agent 2: {"success": true, "dimension": "competitors", "concepts_created": 6}
Agent 3: {"success": true, "dimension": "regulations", "concepts_created": 5}
Agent 4: {"success": true, "dimension": "trends", "concepts_created": 9}
```

**Phase 5.2 Merge**:
```json
{
  "success": true,
  "concepts_final": 35,
  "concepts_deduplicated": 5,
  "megatrends_created": 12,
  "dimensions_updated": 5
}
```

### Performance

| Scenario | Old (Sequential) | New (Parallel + Merge) | Speedup |
|----------|------------------|------------------------|---------|
| 5 dimensions, 200 findings | ~15 minutes | ~4 minutes | ~3.75× |
| 8 dimensions, 400 findings | ~30 minutes | ~6 minutes | ~5× |

**Note:** Speedup depends on dimension distribution. More dimensions = better parallelization.

### Error Handling

- **Retry-once**: Failed dimensions are retried once after all parallel agents complete
- **Continue on failure**: If retry fails, continue with successful dimensions
- **Partial results**: Topics can still be clustered from available concepts

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `--dimension` | Dimension slug to filter findings |
| `--concepts-only` | Skip megatrend clustering (deferred to merge phase) |

## Phase 6: Publisher Generation (DEPRECATED - Sequential)

### Deprecation Notice

**Parallel execution for Phase 6 is deprecated.** Use sequential execution with `--all` flag.

**Reason:** Parallel execution via multiple Task calls caused entity-index.json race conditions leading to Phase 6 failures. This is the same issue that affected source-creator (commit 9aa9871).

### Current Strategy: Sequential Execution

Invoke a single publisher-generator agent with `--all` flag to process all sources sequentially.

### Implementation

1. **Validate sources exist**:
   ```bash
   source_count=$(find "{project-path}/07-sources" -name "source-*.md" -type f | wc -l | tr -d ' ') && echo "Sources: $source_count"
   ```

2. **Invoke single publisher-generator** (sequential):
   ```bash
   Task(
     subagent_type="cogni-research:publisher-generator",
     prompt="Process publishers at {project-path} --all",
     description="Generate publishers for all sources"
   )
   ```

3. **Process response** (single JSON, no aggregation needed):
   ```json
   {
     "success": true,
     "sources_processed": 48,
     "publishers_created": 42,
     "publishers_reused": 8,
     "publishers_enriched": 48,
     "batch_id": null,
     "resolution_mode": "all",
     "by_type": {"individual": 25, "organization": 25}
   }
   ```

4. **Report**:
   ```
   ✓ Phase 6: Generated {total_publishers} publishers ({created} created, {reused} reused, {enriched} enriched)
   ```

### Performance

- Sequential execution prioritizes stability over speed
- Avoids entity-index.json race conditions that caused Phase 6 failures

## Phase 7: Fact Verification

### Strategy: 15-Sources Rule (Workload-Based)

Calculate agent count based on source count, with each agent handling approximately 15 sources.

### Rationale

Sources are the actual workload unit for fact-checking: each source is referenced by findings, which yield claims. Using source count provides:

- **Direct workload correlation**: Sources processed → findings verified → claims created
- **Predictable agent load**: ~15 sources ≈ 30-45 findings ≈ 100-200 claims per agent
- **Optimal parallelization**: Manageable processing time (15-30 min) and context per agent

**Formula**: `agent_count = ceiling(source_count / 15)`

- Minimum: 1 agent (for ≤15 sources)
- Maximum: 20 agents (practical concurrency limit)

**Examples**:

- 45 sources → 3 fact-checkers (15 sources each)
- 90 sources → 6 fact-checkers (15 sources each)
- 150 sources → 10 fact-checkers (15 sources each)
- 300 sources → 20 fact-checkers (capped at max)

### Implementation

1. **Count sources from Phase 5/6**:
   ```bash
   source_count=$(find "{project-path}/07-sources/data" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ') && echo "Sources: $source_count"
   ```

2. **Apply 15-sources rule with bounds**:
   ```bash
   # Calculate raw agent count (ceiling division)
   agent_count=$(( (source_count + 14) / 15 ))

   # Apply bounds: minimum 1, maximum 20
   [ $agent_count -lt 1 ] && agent_count=1
   [ $agent_count -gt 20 ] && agent_count=20

   # Example: 90 sources → 6 fact-checker agents
   ```

3. **List findings**:

   **⚠️ ZSH COMPATIBILITY:** Bash arrays require temp script pattern:

   ```bash
   cat > /tmp/list-findings.sh << 'SCRIPT_EOF'
   #!/usr/bin/env bash
   set -eo pipefail
   PROJECT_PATH="$1"
   findings=()
   while IFS= read -r f; do
       findings+=("$f")
   done < <(find "${PROJECT_PATH}/04-findings/data" -maxdepth 1 -name "*.md" -type f | sort)
   finding_count=${#findings[@]}
   echo "$finding_count"
   SCRIPT_EOF
   chmod +x /tmp/list-findings.sh && finding_count=$(bash /tmp/list-findings.sh "{project-path}") && echo "Findings: $finding_count"
   ```

4. **Distribute findings using round-robin**:
   - For agent_index in 0..(agent_count-1):
     * Assign findings: agent_index, agent_index+agent_count, agent_index+(2×agent_count), ...

5. **Invoke ALL fact-checker agents in parallel** (single message):
   - For each agent: provide partition index and total partitions
   - Agent performs self-partitioning based on partition parameters

6. **Collect responses**:
   - Each agent returns: `{"claims": 45, "avg_confidence": 0.78, "findings_processed": 25}`
   - Aggregate:
     * Sum claims across all agents
     * Calculate weighted average confidence
   - Report: "✓ Phase 7: Verified {total_claims} claims (average confidence: {avg_confidence})"

### Example: 90 Sources, 180 Findings → 6 Agents

**Calculation**:
```bash
source_count = 90
agent_count = ceiling(90 / 15) = 6 agents
finding_count = 180
findings_per_agent = 30 (180 / 6)
```

**Distribution** (round-robin):
```
Agent 0: findings 0, 6, 12, 18, ... (30 findings)
Agent 1: findings 1, 7, 13, 19, ... (30 findings)
Agent 2: findings 2, 8, 14, 20, ... (30 findings)
Agent 3: findings 3, 9, 15, 21, ... (30 findings)
Agent 4: findings 4, 10, 16, 22, ... (30 findings)
Agent 5: findings 5, 11, 17, 23, ... (30 findings)
```

**Invocation**:
```
Invoke 6 fact-checker agents in parallel:
- Agent 0: PARTITION_INDEX=0, TOTAL_PARTITIONS=6
- Agent 1: PARTITION_INDEX=1, TOTAL_PARTITIONS=6
- Agent 2: PARTITION_INDEX=2, TOTAL_PARTITIONS=6
- Agent 3: PARTITION_INDEX=3, TOTAL_PARTITIONS=6
- Agent 4: PARTITION_INDEX=4, TOTAL_PARTITIONS=6
- Agent 5: PARTITION_INDEX=5, TOTAL_PARTITIONS=6
```

**Performance**:

- **Old (sequential)**: 180 findings × 30s = 90 minutes
- **New (6 agents)**: ~30 findings × 30s = ~15 minutes
- **Speedup**: ~6× faster

### Comparison: 15-Sources Rule vs Previous 2× Rule

| Metric | 2× Rule (old) | 15-Sources Rule (new) |
|--------|---------------|----------------------|
| Input basis | Batch count | Source count |
| Formula | batch × 2 | ceiling(sources / 15) |
| Typical agents | 8-40 | 3-20 |
| Workload correlation | Indirect | Direct |
| Agent load predictability | Variable | Consistent (~15 sources) |

**Migration**: The new rule produces fewer, more heavily-loaded agents. This improves efficiency by reducing orchestration overhead while maintaining parallel speedup.

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

**Phase 3** (20 refined questions):
- Time: 20 × 45s = 15 minutes

**Phase 6** (48 sources):
- Time: 48 × 20s = 16 minutes (sequential for stability)

**Phase 7** (60 findings):
- Time: 60 × 30s = 30 minutes

**Total**: ~61 minutes

### With Parallelization (Current)

**Phase 3** (20 question-based agents):
- Time: ~45s (limited by slowest question)

**Phase 6** (sequential - parallel deprecated):
- Time: 48 × 20s = 16 minutes (prioritizes stability over speed)

**Phase 7** (6 agents via 15-sources rule, 90 sources):
- Time: ~30 findings × 30s = 15 minutes (limited by largest partition)

**Total**: ~32 minutes

**Note**: Phase 6 runs sequentially to avoid entity-index.json race conditions. The slight performance decrease is acceptable for improved stability.

## Best Practices

1. **Always use single message for parallel invocations**: Don't send sequential messages with individual Task calls
2. **Let Claude Code manage execution**: Don't manually batch or throttle
3. **Use round-robin for load balancing**: Ensures fair distribution
4. **Cap maximum agents**: 20 agents for fact-checking, 10 for citation management
5. **Use workload-based counts**: Source count for Phase 7 parallelization
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

- Phase 3: Unlimited refined questions (typically 8-50, at or below 50)
- Phase 5: 1 per dimension (typically 2-10 dimensions) + 1 merger
- Phase 6: 1 agent (sequential execution - parallel deprecated)
- Phase 7: 1 per 15 sources (typically 3-20, capped at 20)

**Rate Limits**: No known Claude Code rate limits for agent invocations (as of 2025-01)
