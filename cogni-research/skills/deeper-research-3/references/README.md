# References - deeper-research-3

Reference documentation for the synthesis phase (Phases 8-10, 12-13) of the deeper-research workflow.

**Note:** Phase 7 (Fact Verification with claims) is part of deeper-research-2. This skill (deeper-research-3) executes Part 3 starting at Phase 8.

## Contents

### Phase Workflows

**[phase-workflows/](phase-workflows/)** - Complete implementation instructions for Phases 8-10, 12-13

| Phase | Name | File |
| ----- | ---- | ---- |
| 8 | Parallel Trend Generation | [phase-8-domain-synthesis.md](phase-workflows/phase-8-domain-synthesis.md) |
| 8.5 | Dimension Synthesis | [phase-8.5-dimension-synthesis.md](phase-workflows/phase-8.5-dimension-synthesis.md) |
| 9 | Evidence Synthesis | *Inlined in SKILL.md* |
| 10 | Synthesis Creation | *Inlined in SKILL.md* |
| 12 | Wikilink Validation | [phase-12-wikilink-validation.md](phase-workflows/phase-12-wikilink-validation.md) |
| 13 | Finalization | [phase-13-finalization.md](phase-workflows/phase-13-finalization.md) |

### Methodology & Standards

**[validation-protocols.md](validation-protocols.md)** - JSON validation workflows

- Entity file validation
- Metadata verification
- Cross-reference validation
- Synthesis output verification

**[token-efficiency.md](token-efficiency.md)** - Agent output requirements

- Context optimization patterns
- Progressive disclosure techniques
- Output size constraints
- Efficiency metrics

### Operational Guides

**[parallelization-strategies.md](parallelization-strategies.md)** - Parallel execution patterns

- Phase 8: Dimension-based parallelization (smarter-service: one agent per dimension, others: single agent)
- Load balancing strategies

**[agent-invocation-patterns.md](agent-invocation-patterns.md)** - Agent delegation patterns

- Task tool invocation templates
- Parameter passing conventions
- Response validation
- Error handling

## Usage Pattern

When implementing a phase:

1. Read the corresponding phase workflow file for orchestration steps
2. Reference operational guides for agent delegation patterns
3. Apply validation protocols at phase boundaries
4. Use parallelization strategies for concurrent agent execution

## Progressive Disclosure

Load reference files progressively as needed:

- Phase workflows contain high-level orchestration steps
- Operational guides provide agent invocation patterns
- Methodology files ensure quality and efficiency

## Part 3 Scope

These references support **Part 3: Synthesis** (Phases 8-10, 12-13). This skill requires completion of deeper-research-0 (Phases 0-2.5), deeper-research-1 (Phase 3), and deeper-research-2 (Phases 4-7) before execution.

### Phase Sequence

| Phase | Focus | Key Output |
| ----- | ----- | ---------- |
| **Phase 8** | Parallel trend generation (1 agent/dimension) | 11-trends/data/trend-*.md or portfolio-*.md |
| **Phase 8.5** | Dimension synthesis | 12-synthesis/synthesis-*.md |
| **Phase 9** | Evidence synthesis | 09-citations/README.md |
| **Phase 10** | Synthesis creation | research-hub.md |
| **Phase 12** | Wikilink validation | Zero broken links |
| **Phase 13** | Finalization | Completion report |

## Related Skills

- **deeper-research-0** - Part 0: Initialization (Phases 0-2.5: project initialization, question refinement, dimensional planning, megatrend validation, batch creation)
- **deeper-research-1** - Part 1: Discovery (Phase 3: parallel findings creation)
- **deeper-research-2** - Part 2: Enrichment (Phases 4-7, including fact verification and claims)

## Related Agents

- **cogni-research:trends-creator** - Phase 8 trends (parallelized per dimension)
- **cogni-research:evidence-synthesizer** - Phase 9 evidence catalog
- **cogni-research:synthesis-hub** - Phase 10 synthesis creation
