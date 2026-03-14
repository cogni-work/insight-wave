# Token Efficiency Guidelines

## Overview

To maintain reasonable token usage throughout research orchestration, follow these guidelines for agent output, orchestrator behavior, file reading, and progress updates.

## Agent Output Requirements

All specialized agents MUST adhere to these output standards:

### MUST Return JSON Only
- No conversational text before or after JSON
- No explanatory preambles
- No verbose descriptions
- Single JSON object or array only

### MUST Use Minimal Field Names
- Use short, clear field names: `findings` not `findings_created_count`
- Avoid redundant prefixes: `claims` not `total_claims`
- Use abbreviations when unambiguous: `avg_confidence` not `average_confidence_score`

### MUST Omit Empty/Null Fields
- Skip fields with no value
- Don't include `null` or `""` fields
- Only return fields with meaningful data

### MUST Avoid Redundant Metadata
- No timestamp fields unless explicitly needed
- No version numbers in responses
- No agent identification in output
- No duplicate information

### Examples

✅ **GOOD** (15 tokens):
```json
{
  "findings": 23,
  "megatrends": 4
}
```

❌ **BAD** (45 tokens):
```json
{
  "total_findings_created": 23,
  "total_megatrends_clustered": 4,
  "agent_name": "research-executor",
  "timestamp": "2025-10-21T08:45:00Z",
  "version": "1.0"
}
```

## Orchestrator Responsibilities

The orchestration skill (deeper-research SKILL.md) MUST:

### Validate JSON Responses Immediately
- Check format and structure after each agent invocation
- Extract required fields only
- Don't load full JSON into narrative text

### Log Warnings for Verbose Agents
- Track non-compliant agents
- Report in Phase 9 compliance summary
- Non-blocking: continue workflow despite verbosity

### Track Token Usage Per Phase
- Monitor approximate token consumption
- Flag phases exceeding budget
- Optimize agent prompts if excessive tokens detected

### Optimize Agent Prompts
If Phase token usage > 10K:
- Review agent prompt for unnecessary instructions
- Consider breaking into smaller sub-agents
- Evaluate if parallel execution helps

## Selective File Reading

### Only Read Files When Necessary
Read files only for:
- Final presentation (Phase 8, Phase 9)
- Debugging broken workflows
- User-requested content inspection

### Do NOT Read Files For
- Intermediate phase validation
- Counting entities (use `ls | wc -l` instead)
- Aggregating statistics (agents return counts)
- Confirming entity creation (trust agent JSON)

### Trust Agent JSON Responses
- If agent reports `{"findings": 23}`, trust it
- No need to verify by reading all 23 finding files
- Only validate if suspicious (e.g., `findings: 0` after 18 query batches)

### Use Bash Commands for Counting
Instead of reading files:

**⚠️ ZSH COMPATIBILITY:** Each command below must be a **SEPARATE Bash tool call**. Never combine multiple `$()` in one call.

```bash
# Bash call 1: Count findings
finding_count=$(find "{project-path}/04-findings/data" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l) && echo "Findings: $finding_count"
```

```bash
# Bash call 2: Count batches
batch_count=$(find "{project-path}/03-query-batches/data" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l) && echo "Batches: $batch_count"
```

```bash
# Bash call 3: Check file exists
test -f "{entity-path}" && echo "exists" || echo "missing"
```

### Let Agents Read Entities
- synthesis-hub reads all entities to generate synthesis
- concept-extractor reads findings to extract concepts
- Orchestrator doesn't need to duplicate this work

## Progress Updates

### Keep Messages Terse and Structured
Format: `✓ Phase {N}: {brief summary}`

Examples:
- ✅ `✓ Phase 4: Created 47 findings across 3 batches`
- ❌ `I have successfully completed Phase 4 of the research workflow. The research-executor agents have processed all query batches and created a total of 47 findings, which have been organized across 3 batches.`

### Skip Detailed Execution Logs
Don't report:
- Individual agent invocations
- File paths being written
- Intermediate validation steps
- Bash command outputs (unless errors)

Focus on:
- Phase completion status
- Key metrics (entity counts, confidence scores)
- Errors requiring user attention

### Avoid Repeating Data
Don't convert JSON to narrative:

❌ **BAD**:
```
Agent returned: {"findings": 23, "megatrends": 4}

I have created 23 findings and organized them into 4 megatrend clusters.
```

✅ **GOOD**:
```
✓ Phase 4: Created 23 findings (4 megatrends)
```

### Batch Updates
Update TodoWrite and report to user simultaneously:
- Don't say: "Marking Phase 4 complete" (implied by next message)
- Just report: "✓ Phase 4: ..." (TodoWrite happens in background)

## Target Metrics

### Per Agent Response
- **Target**: <200 tokens
- **Warning**: >500 tokens
- **Critical**: >1000 tokens

If agent exceeds warning threshold, log for Phase 9 compliance report.

### Per Phase Execution
- **Target**: <3K tokens total (prompt + response + orchestration)
- **Warning**: >5K tokens
- **Critical**: >10K tokens

If phase exceeds warning threshold:
- Review agent prompt efficiency
- Consider parallel execution to reduce orchestration overhead
- Evaluate if reference files can reduce prompt size

### Full Workflow (10 Phases)
- **Target**: <40K tokens (efficient orchestration)
- **Acceptable**: <60K tokens (typical workflow)
- **Warning**: >80K tokens (needs optimization)
- **Critical**: >100K tokens (requires refactoring)

## Token Optimization Strategies

### 1. Reduce Agent Prompt Size
- Move detailed instructions to agent prompt files (not orchestrator prompts)
- Use references for complex logic (e.g., validation protocols)
- Avoid repeating context in every invocation

### 2. Parallelize Expensive Phases
Phases with high token cost:
- Phase 4: Research execution (N agents × query processing)
- Phase 6: Citation management (N agents × finding processing)
- Phase 7: Fact verification (N agents × claim verification)

Parallel execution reduces orchestration overhead:
- Sequential: N × (prompt + response + update) tokens
- Parallel: 1 × (batch_prompt) + N × (response) + 1 × (aggregate) tokens

### 3. Cache Stable Context
Reuse context across invocations:
- Project path
- Entity directory structure
- Validation protocols
- Response format expectations

### 4. Compress Progress Reports
Use symbols and abbreviations:
- ✓ for completed
- ⚠ for warnings
- ✗ for errors
- Abbreviate: "3D 12Q" instead of "3 dimensions, 12 questions"

### 5. Defer Content Reading
Don't read entity files until:
- User explicitly requests content
- Phase 9 final report requires sampling
- Debugging workflow failures

## Monitoring Token Usage

### Track Per-Phase Usage
Maintain running total:
```
Phase 0: 500 tokens
Phase 1: 1200 tokens
Phase 2: 1800 tokens
Phase 3: 2100 tokens
Phase 4: 8500 tokens (parallel execution)
...
Total: 42,000 tokens
```

### Flag Anomalies
If phase significantly exceeds historical average:
- Log warning
- Investigate agent verbosity
- Check for unexpected file reads
- Review orchestration logic

### Report in Phase 9
Include token efficiency in final report:
```
✓ Phase 9: Research complete
Token Usage: 42,000 (target: <60K) ✓
JSON Compliance: 95% (19/20 agents) ✓
```

## Best Practices Summary

1. **Agents**: Return minimal JSON only (<200 tokens)
2. **Orchestrator**: Validate responses without verbose logging
3. **File I/O**: Read files only when necessary for user output
4. **Progress**: Terse structured updates (✓ Phase N: ...)
5. **Parallelization**: Use for high-token phases (4, 6, 7)
6. **Monitoring**: Track per-phase usage, flag anomalies
7. **Optimization**: Move complex logic to references, cache stable context
