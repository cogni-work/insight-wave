# cogni-gpt-researcher

Multi-agent research report generator for Claude Code. Native re-implementation of GPT-Researcher's STORM-inspired editorial workflow using Claude Code plugin primitives.

## Features

- **Three report types**: basic (fast), detailed (multi-section), deep (recursive tree)
- **Parallel web research**: haiku agents search concurrently per sub-question
- **Claims-verified review loop**: integrates with cogni-claims for evidence-based quality gates
- **4 entity types**: sub-questions, contexts, sources, report-claims (Obsidian-browsable)
- **Resumable**: interrupted runs pick up from existing entities

## Quick Start

```
# Basic report
"Write a research report on quantum computing's impact on cryptography"

# Detailed report
"Write a detailed research report on AI adoption in healthcare"

# Deep research
"Deep research on the future of autonomous vehicles"
```

## Report Types

| Type | Sub-questions | Agents | Use Case |
|------|--------------|--------|----------|
| Basic | 3-5 | 5-7 | Quick overview, single topic |
| Detailed | 5-10 | 10-15 | Multi-section report with outline |
| Deep | 10-20 (tree) | 15-25 | Recursive exploration, maximum depth |

## Pipeline

```
Phase 0: Init → Phase 1: Plan → Phase 2: Research → Phase 3: Aggregate
→ Phase 4: Write → Phase 5: Claims-Verified Review → Phase 6: Finalize
```

## Cross-Plugin Integration

- **cogni-claims**: Source verification during review loop (primary)
- **cogni-narrative**: Story arc polish (optional)
- **cogni-copywriting**: Executive polish (optional)
- **cogni-visual**: Presentation generation (optional)

## License

AGPL-3.0-only
