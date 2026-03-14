# Phase Workflows - Implementation Guide (Collection Phase)

Complete implementation instructions for Phases 0-7 of the deeper-research collection workflow.

## Index

- [Phase 0: Project Initialization](phase-0-initialization.md)
- [Phase 1: Question Refinement](phase-1-question-refinement.md)
- [Phase 2: Dimensional Planning](phase-2-dimensional-planning.md)
- [Phase 3: Parallel Findings Creation](phase-3-parallel-findings-creation.md)
- [Phase 4: Source Creation & Validation](phase-4-source-creation.md) (includes 4.1 and 4.2)
- [Phase 5: Knowledge Extraction](phase-5-knowledge-extraction.md) (concepts and megatrends)
- [Phase 6: Publisher & Citation Management](phase-6-publisher-citation.md) (includes 6, 6.1, 6.2)
- [Phase 7: Claims Creation](phase-7-claims-creation.md)

## Usage Pattern

When executing a specific phase:
1. Read the corresponding phase file from this directory
2. Follow implementation steps and agent delegation patterns
3. Report completion metrics per Success Criteria
4. Update TodoWrite to track progress

## Progressive Disclosure

Load phase files progressively as needed during orchestration. Each file contains:
- Detailed implementation steps
- Agent delegation patterns (via Task tool)
- Validation criteria
- Error handling guidance
- Expected outputs

## Part 1 Scope

These phase workflows cover **Part 1: Collection** (Phases 0-7):

- **Phases 0-2**: Setup and planning
- **Phase 3**: Parallel findings creation (consolidated query + research execution)
- **Phase 4**: Source creation and validation (NEW)
- **Phase 5**: Knowledge extraction (concepts and megatrends)
- **Phase 6**: Publisher generation and citation management
- **Phase 7**: Claims creation (fact verification with confidence scoring)

## Phase Dependency Graph

```text
Phase 3 (Findings) → Phase 4 (Sources) → Phase 5 (Concepts/Megatrends) → Phase 6 (Publishers) → Phase 7 (Claims)
```

**Key Change:** Source creation (formerly Phase 5.2) now runs SEQUENTIALLY in Phase 4 with validation, rather than in parallel with knowledge extraction.

After Phase 7 completion, use `deeper-synthesis` skill for Part 2 (Phases 8-10).

## Note

This directory contains phase workflows specific to the **collection** phase of deeper-research. The synthesize skill has its own phase-workflows directory for Phases 8-10.
