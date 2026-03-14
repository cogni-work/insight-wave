# Wrapper Agent Patterns

This document explains the two wrapper agent patterns used in the deeper-research plugin for delegating work to skills while maintaining context efficiency.

## Overview

Wrapper agents serve as lightweight delegation layers between the main workflow and specialized skills. They enable:
- **Context efficiency** - Heavy processing happens in skill context, not main agent
- **Progressive disclosure** - Skills load large reference documentation, agents stay lightweight
- **Reusability** - Skills can be invoked by multiple agents or directly by users

## Pattern 1: Pure Wrapper

### Characteristics

- **Tool Declaration:** Only `Skill` tool in YAML frontmatter
- **Responsibility:** Pure delegation - invoke skill and return results
- **No Direct Operations:** Does not read files, write entities, or execute scripts
- **Stateless:** No internal state beyond parameter passing

### YAML Structure

```yaml
---
name: example-wrapper
description: Delegate example task to example skill
tools: Skill
model: claude-sonnet-4-5-20250929
---
```

### When to Use

Use Pure Wrapper when:
- The wrapper's only job is to invoke a skill and return results
- No parameter validation or transformation needed beyond simple parsing
- No result aggregation or post-processing required
- The skill is self-contained and handles all work independently

### Examples in deeper-research

1. **research-executor** ([agents/research-executor.md](../agents/research-executor.md))
   - Tools: `Skill`
   - Delegates to: `research-executor` skill
   - Purpose: Execute web searches and extract findings
   - Pure delegation: Parses batch path, invokes skill, returns summary

2. **citation-generator** ([agents/citation-generator.md](../agents/citation-generator.md))
   - Tools: `Skill`
   - Delegates to: `citation-generator` skill
   - Purpose: Generate APA citations linking sources to publishers
   - Pure delegation: Passes parameters through, returns JSON response

3. **publisher-generator** ([agents/publisher-generator.md](../agents/publisher-generator.md))
   - Tools: `Skill`
   - Delegates to: `publisher-generator` skill
   - Purpose: Create and enrich publisher entities
   - Pure delegation: Processes source partition, returns metrics

### Template

```markdown
---
name: your-wrapper
description: Delegate [task] to [skill-name] skill
tools: Skill
model: claude-sonnet-4-5-20250929
---

# Your Wrapper Agent

## Your Role

You are a delegation orchestrator for [task type]. Your sole responsibility is to
invoke the [skill-name] skill with properly structured parameters and return
results to the main agent.

## Your Mission

**Input Specification:**
- parameter1: Description
- parameter2: Description

**Your Objective:**
Invoke the [skill-name] skill and return results to the main agent.

**Success Criteria:**
- Skill invocation successful
- Results returned to main agent
- Context isolation maintained

## Instructions

### Step 1: Parse Input Parameters
Extract parameters from task specification.

### Step 2: Invoke Skill
Use the Skill tool to invoke the skill:
```
Skill(skill="plugin-name:skill-name")
```

### Step 3: Return Results
Return the skill's response to the main agent.
```

---

## Pattern 2: Orchestrator Wrapper

### Characteristics

- **Tool Declaration:** `Skill` plus additional tools needed for orchestration
- **Responsibility:** Orchestrate multiple skill invocations and aggregate results
- **Limited Direct Operations:** May perform parameter validation, partition calculation, result aggregation
- **Lightweight Orchestration:** Heavy work still delegated to skill, wrapper handles coordination

### YAML Structure

```yaml
---
name: example-orchestrator
description: Orchestrate example task via skill delegation
tools: Skill, Read, Write, Bash, TodoWrite
model: claude-sonnet-4-5-20250929
---
```

### When to Use

Use Orchestrator Wrapper when the wrapper needs to:
- **Validate parameters** - Check paths, parse complex inputs, validate formats
- **Calculate partitions** - Divide work across parallel skill invocations
- **Aggregate results** - Combine outputs from multiple skill calls
- **Manage state** - Track progress across multiple skill invocations
- **Execute utilities** - Call validation scripts or helper functions

### Tool Selection Guidelines

| Tool | Common Uses in Orchestrators |
|------|------------------------------|
| `Skill` | Always required for skill delegation |
| `Read` | Parameter validation, discovering entities to process |
| `Write` | Writing aggregated statistics, progress logs |
| `Bash` | Executing validation utilities, path resolution |
| `TodoWrite` | Tracking multi-step orchestration progress |
| `Grep` | Discovering files matching patterns |
| `Glob` | Finding entities to partition |

### Examples in deeper-research

1. **source-creator** ([agents/source-creator.md](../agents/source-creator.md))
   - Tools: `Bash`
   - Delegates to: `scripts/source-creator.sh` (pure script, no skill)
   - Pattern: Script executor (no LLM work required)
   - Why: Source creation is 100% deterministic (YAML extraction, URL parsing, deduplication)

2. **fact-checker** ([agents/fact-checker.md](../agents/fact-checker.md))
   - Tools: `Skill, Read, Write, Bash, TodoWrite`
   - Delegates to: `fact-checker` skill
   - Orchestration Logic:
     - Calculates partition slice (self-partitioning)
     - Discovers findings in assigned partition
     - Invokes skill for each finding
     - Aggregates confidence scores and quality metrics
   - Why extra tools: Bash for partition math, Read for discovery, Write for stats

3. **dimension-planner** ([agents/dimension-planner.md](../agents/dimension-planner.md))
   - Tools: `Skill, Read, Write, Grep, Glob, TodoWrite`
   - Delegates to: `dimension-planner` skill
   - Orchestration Logic:
     - Validates question file exists
     - Parses language parameter with defaults
     - Invokes skill with validated parameters
   - Why extra tools: Read for validation, Grep/Glob for file discovery

### Anti-Pattern: Over-Specification

**Problem:** Including tools in wrapper that are only used by the skill, not the wrapper itself.

**Example:**
```yaml
# Wrapper agent YAML (WRONG)
tools: Skill, Read, Write, WebSearch, Bash

# If WebSearch is only used by the skill, not the wrapper's orchestration logic,
# it should NOT be in the wrapper's tools list.
```

**Solution:** Only include tools the wrapper directly uses for orchestration. The skill declares its own tools separately via `allowed-tools:`.

**Correct Pattern:**
```yaml
# Wrapper agent YAML
tools: Skill, Read, Write, Bash

# Skill YAML (in SKILL.md frontmatter)
allowed-tools: Read, Write, WebSearch, Bash
```

### Template

```markdown
---
name: your-orchestrator
description: Orchestrate [task] via [skill-name] skill with [orchestration features]
tools: Skill, Read, Write, Bash, TodoWrite
model: claude-sonnet-4-5-20250929
---

# Your Orchestrator Agent

## Your Role

You are a delegation orchestrator for [task type]. Your role is to:
1. [Orchestration responsibility 1]
2. [Orchestration responsibility 2]
3. Invoke [skill-name] skill for each [entity]
4. Aggregate results and return to main agent

## Your Mission

**Input Specification:**
- parameter1: Description
- parameter2: Description

**Your Objective:**
[Orchestration objective including aggregation/partitioning/validation]

## Instructions

### Phase 1: Setup
[Parameter validation, environment checks]

### Phase 2: Discovery
[Find entities to process, calculate partitions if needed]

### Phase 3: Skill Invocation Loop
For each [entity]:
- Invoke skill with parameters
- Collect results
- Track progress

### Phase 4: Aggregation
[Combine results, calculate statistics, write reports]

### Phase 5: Return Results
[Return aggregated summary to main agent]
```

---

## Comparison Table

| Aspect | Pure Wrapper | Orchestrator Wrapper |
|--------|-------------|---------------------|
| **Tools** | `Skill` only | `Skill` + orchestration tools |
| **Complexity** | Minimal | Low-to-medium |
| **Invocations** | Single skill call | Multiple skill calls or complex setup |
| **State Management** | Stateless | May track progress |
| **Result Handling** | Pass-through | Aggregation/transformation |
| **Use Case** | 1:1 delegation | 1:N delegation or validation |

---

## Design Principles

### 1. Separation of Concerns

**Wrapper Responsibility:**
- Parameter parsing and validation
- Partition calculation
- Skill invocation coordination
- Result aggregation

**Skill Responsibility:**
- Domain logic and heavy computation
- File reading and entity creation
- Reference documentation loading
- Complex analysis and synthesis

### 2. Context Efficiency

**Why This Matters:**
- Skills contain large reference documents (10-50KB)
- Progressive disclosure keeps references hidden until needed
- Wrapper stays lightweight (1-3KB) for fast main context
- Heavy processing isolated in skill context

### 3. Tool Minimalism

**Principle:** Only include tools the wrapper actually uses for its orchestration logic.

**Ask These Questions:**
1. Does the wrapper directly call this tool? (Yes → include)
2. Is this tool only used inside the skill? (Yes → exclude from wrapper)
3. Is this tool for orchestration (aggregation, partitioning)? (Yes → include)
4. Is this tool for domain logic (synthesis, analysis)? (Yes → skill only)

### 4. Delegation Over Duplication

**Anti-Pattern:** Implementing business logic in both wrapper and skill

**Correct Pattern:**
- Wrapper: Coordination and aggregation
- Skill: All domain-specific logic

---

## Migration Guide

### Converting Pure Wrapper to Orchestrator

**When to Consider:**
- Need to process multiple entities (loop over skill calls)
- Need to aggregate results from parallel executions
- Need to calculate partitions for parallel processing
- Need complex parameter validation

**Steps:**
1. Identify orchestration requirements (aggregation, partitioning, validation)
2. Determine which tools are needed for orchestration logic
3. Add tools to wrapper YAML frontmatter
4. Implement orchestration phases (setup, discovery, loop, aggregation)
5. Ensure skill retains all domain logic

### Converting Regular Agent to Wrapper

**When to Consider:**
- Agent contains heavy reference documentation (>20KB)
- Agent could benefit from progressive disclosure
- Logic could be reused by other agents or direct invocation

**Steps:**
1. Create new skill in `skills/` directory
2. Move domain logic and references to skill
3. Define skill's `allowed-tools:` based on operations it performs
4. Convert agent to wrapper (pure or orchestrator depending on needs)
5. Add Skill tool to wrapper's tools list
6. Update agent prompt to invoke skill instead of performing work

---

## Examples Summary

### Pure Wrappers (Skill Only)

| Agent | Skill | Purpose |
|-------|-------|---------|
| [research-executor](../agents/research-executor.md) | [research-executor](../skills/research-executor/) | Execute web searches, extract findings |
| [citation-generator](../agents/citation-generator.md) | [citation-generator](../skills/citation-generator/) | Generate APA citations |
| [publisher-generator](../agents/publisher-generator.md) | [publisher-generator](../skills/publisher-generator/) | Create and enrich publishers |

### Orchestrator Wrappers (Skill + Tools)

| Agent | Skill | Tools | Orchestration Logic |
|-------|-------|-------|---------------------|
| [source-creator](../agents/source-creator.md) | `scripts/source-creator.sh` (script only) | Bash | Script executor - no LLM work |
| [fact-checker](../agents/fact-checker.md) | [fact-checker](../skills/fact-checker/) | Read, Write, Bash, TodoWrite | Calculate partitions, aggregate confidence scores |
| [dimension-planner](../agents/dimension-planner.md) | [dimension-planner](../skills/dimension-planner/) | Read, Write, Grep, Glob, TodoWrite | Validate inputs, parse parameters |

---

## Related Documentation

- [../agents/README.md](../agents/README.md) - Agent directory overview
- [../skills/README.md](../skills/README.md) - Skill directory overview
- Claude Code Subagents Reference - Context efficiency patterns
- Claude Code Skills Reference - Progressive disclosure architecture

---

## Version History

- **v1.0.0** (2025-11-13, Sprint 257) - Initial documentation of wrapper patterns based on analysis of 8 wrapper agents in deeper-research plugin
