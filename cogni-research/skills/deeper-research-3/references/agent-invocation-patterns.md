# Agent Invocation Patterns Reference

Quick reference for correct parameter usage when invoking deeper-research agents via Task tool.

## Overview

This reference provides concrete invocation patterns for all deeper-research agents. Use this when orchestrating research phases to ensure correct parameter passing.

**Critical Distinction:**
- ✅ **File List Agents**: Accept comma-separated file paths (`source-creator`)
- ✅ **Partition Agents**: Accept partition indices (`fact-checker`)
- ✅ **Batch ID Agents**: Accept single batch identifier (`research-executor`)

## Agent Parameter Reference

### Phase 4: Research Execution

#### research-executor

**Required Parameters:**
- `--project-path`: Absolute path to research project
- `--batch-id`: Single batch identifier (e.g., "economic", "technical")

**Optional Parameters:**
- `--language`: Target language code (default: "en")

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:research-executor",
  prompt="Execute research at {project-path} --batch-id economic --language en",
  description="Researching economic dimension"
)
```

**Notes:**
- ONE agent per batch (not parallelized across batch)
- Batch IDs come from dimension names in Phase 2
- Creates findings AND megatrends in single execution

---

### Phase 4.5: Concept Extraction

#### concept-extractor

**Required Parameters:**
- `--project-path`: Absolute path to research project

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:concept-extractor",
  prompt="Extract concepts from {project-path}",
  description="Extracting domain concepts"
)
```

**Notes:**
- Single agent (not parallelized)
- Processes ALL findings automatically
- Run in parallel with Phase 6.1 (same message)

---

**Note:** Publisher creation and enrichment (formerly Phase 5.1 and 5.2) are now handled by the separate `publisher` skill. See publisher-generator skill documentation for invocation patterns.

---

### Phase 6.1: Source Creation

#### source-creator

**Required Parameters:**
- `--project-path`: Absolute path to research project
- `--finding-list-file`: Path to file containing finding paths (one per line)

**Optional Parameters:**
- `--language`: Target language code (default: "en")

**Invocation Pattern:**
```python
# Write findings to file first (file-based contract)
finding_list_file="{project-path}/.metadata/phase5-finding-list.txt"

Task(
  subagent_type="cogni-research:source-creator",
  prompt=f"Create sources at {{project-path}} --finding-list-file {finding_list_file} --language en",
  description="Creating sources from findings"
)
```

**Notes:**
- Uses file-based contract to avoid prompt length issues
- Orchestrator writes finding paths to file (one per line)
- Filter out no-results findings first
- Sequential execution for stability

---

### Phase 6.2: Citation Generation

#### citation-generator

**Required Parameters:**
- `--project-path`: Absolute path to research project

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:citation-generator",
  prompt="Generate citations at {project-path}",
  description="Generating citations"
)
```

**Notes:**
- Single agent (not parallelized)
- Processes ALL sources and publishers automatically
- Uses multi-strategy publisher resolution

---

### Phase 7: Fact Verification

#### fact-checker

**Required Parameters:**
- `--project-path`: Absolute path to research project
- `--partition-id`: Zero-based partition index
- `--total-partitions`: Total number of partitions

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:fact-checker",
  prompt="Verify facts at {project-path} --partition-id 0 --total-partitions 8",
  description="Verifying claims (partition 1/8)"
)
```

**Notes:**
- ✅ Supports partition-based distribution
- Use 2× Rule: agent_count = batch_count × 2
- Auto-distributes findings internally
- All agents return text summary + JSON in reports/

---

### Phase 8: Synthesis Agents

All synthesis agents use similar patterns:

#### trends-creator

**Required Parameters:**

- `--project-path`: Absolute path to research project
- `--dimension`: Dimension slug to process (one agent per dimension)

**Invocation Pattern (Parallel - one agent per dimension):**

```python
# Invoke ALL dimension agents in SINGLE message for parallel execution:
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at {project-path} for dimension: {dimension-slug-1}",
  description="Creating trends for {dimension-slug-1}"
)
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at {project-path} for dimension: {dimension-slug-2}",
  description="Creating trends for {dimension-slug-2}"
)
# ... one Task per dimension
```

**Notes:**

- **Always parallel:** One agent per dimension from `01-research-dimensions/data/`
- **Critical:** All Task invocations MUST be in SINGLE message for parallel execution
- Performance: N× faster (limited by slowest dimension)

#### evidence-synthesizer

**Required Parameters:**
- `--project-path`: Absolute path to research project

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:evidence-synthesizer",
  prompt="Synthesize evidence at {project-path}",
  description="Synthesizing evidence catalog",
  run_in_background=false  # MUST block - orchestrator needs response metrics
)
```

#### synthesis-hub

**Required Parameters:**
- `--project-path`: Absolute path to research project

**Invocation Pattern:**
```python
Task(
  subagent_type="cogni-research:synthesis-hub",
  prompt="Create synthesis at {project-path}",
  description="Creating research synthesis"
)
```

---

## Troubleshooting

### Error: "Missing required parameter: --source-files"

**Cause:** Not providing source file list to source-creator

**Solution:**
```bash
# Build comma-separated list first
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
sources=()
while IFS= read -r f; do
    sources+=("$f")
done < <(find "{project-path}/07-sources/data" -maxdepth 1 -name "*.md" -type f | sort)
source_list="$(IFS=,; echo "${sources[*]}")"

# Then pass to agent
--source-files $source_list
```

### Error: "Missing required parameter: --finding-list-file"

**Cause:** Not providing finding list file to source-creator

**Solution:**
```bash
# Write findings to file first (file-based contract)
find {project-path}/04-findings -name '*.md' -type f > {project-path}/.metadata/finding-list.txt

# Then pass file path to agent
--finding-list-file {project-path}/.metadata/finding-list.txt
```

### Error: "No files processed" or empty results

**Cause:** Incorrect file list format (spaces after commas, relative paths)

**Solution:**
- Use absolute paths only
- No spaces in comma-separated list: `file1.md,file2.md` ✅ not `file1.md, file2.md` ❌
- Verify files exist before passing to agent

---

## Best Practices

1. **Always check agent documentation** for required parameters before invocation
2. **Use absolute paths** for all file parameters (never relative paths)
3. **Build file lists in bash** using array joining: `IFS=,; echo "${array[*]}"`
4. **Parallel execution requires single message** with multiple Task calls
5. **Validate parameters** match agent expectations before invoking
6. **Reference phase-workflows.md** for concrete bash examples

---

## Quick Lookup Table

| Agent | Parameter Type | Example |
|-------|---------------|---------|
| research-executor | Batch ID | `--batch-id economic` |
| concept-extractor | Project only | `--project-path {path}` |
| source-creator | File path | `--finding-list-file /p/.metadata/finding-list.txt` |
| citation-generator | Project only | `--project-path {path}` |
| fact-checker | Partition | `--partition-id 0 --total-partitions 8` |
| trends-creator | Project only | `--project-path {path}` |
| evidence-synthesizer | Project only | `--project-path {path}` |
| synthesis-hub | Project only | `--project-path {path}` |
