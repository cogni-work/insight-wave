# Phase Workflows - Implementation Guide (Synthesis Phase)

Complete implementation instructions for Phases 8-10, 12-13 of the deeper-research-3 synthesis workflow.

## Index

| Phase | Name | File |
|-------|------|------|
| 8 | Parallel Trend Generation | [phase-8-domain-synthesis.md](phase-8-domain-synthesis.md) |
| 8.5 | Dimension Synthesis | [phase-8.5-dimension-synthesis.md](phase-8.5-dimension-synthesis.md) |
| 9 | Evidence Synthesis | *Inlined in SKILL.md* |
| 10 | Synthesis Creation | *Inlined in SKILL.md* |
| 10.5 | Insight Summary Generation | [phase-10.5-insight-summary.md](phase-10.5-insight-summary.md) |
| 12 | Wikilink Validation | [phase-12-wikilink-validation.md](phase-12-wikilink-validation.md) |
| 13 | Finalization | [phase-13-finalization.md](phase-13-finalization.md) |

## Phase Sequence

```text
deeper-research-1 (Part 1: Discovery):   Phase 0 → Phase 1 → Phase 2 → Phase 3
                                                                              ↓
deeper-research-2 (Part 2: Enrichment):  Phase 4 → Phase 5 → Phase 6 → Phase 7
                                                                              ↓
deeper-research-3 (Part 3: Synthesis):   Phase 8 → Phase 9 → Phase 10 → Phase 10.5 → Phase 12 → Phase 13
```

## Usage Pattern

When executing a specific phase:

1. Read the corresponding phase file from this directory
2. Follow implementation steps and agent delegation patterns
3. Report completion metrics per Success Criteria
4. Update TodoWrite to track progress

## Progressive Disclosure

Load phase files progressively as needed during orchestration. Each file contains:

- Phase entry verification gates
- TodoWrite expansion templates
- Detailed implementation steps
- Agent delegation patterns (via Task tool)
- Self-verification questions
- Completion checklists
- Error handling guidance
- Expected outputs

## Part 3 Scope

These phase workflows cover **Part 3: Synthesis** (Phases 8-10, 12-13):

| Phase | Focus | Key Output |
|-------|-------|------------|
| **Phase 8** | Parallel trend generation | 11-trends/data/trend-*.md or portfolio-*.md |
| **Phase 8.5** | Dimension synthesis | 12-synthesis/synthesis-*.md |
| **Phase 9** | Evidence synthesis | 09-citations/README.md |
| **Phase 10** | Synthesis creation | research-hub.md |
| **Phase 10.5** | Insight summary (conditional) | insight-summary.md (if arc_id set) |
| **Phase 12** | Wikilink validation | Zero broken links |
| **Phase 13** | Finalization | Completion report |

This skill requires completion of deeper-research-1 (Phases 0-3) and deeper-research-2 (Phases 4-7) before execution. Claims are created in Phase 7 of deeper-research-2.

## Note

This directory contains phase workflows specific to **deeper-research-3** (Part 3: Synthesis). The deeper-research-1 and deeper-research-2 skills have their own phase-workflows directories for Phases 0-3 and 4-7 respectively.
