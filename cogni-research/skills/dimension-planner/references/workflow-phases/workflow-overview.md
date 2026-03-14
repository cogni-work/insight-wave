# Workflow Phases Reference

## Overview

This directory contains detailed documentation for each phase of the dimension-planner workflow. Use these references during execution to understand implementation details, variable assignments, and edge cases that are condensed in the main SKILL.md.

## Execution Tracking

**IMPORTANT:** Use [RUNTIME-CHECKLIST.md](RUNTIME-CHECKLIST.md) during execution to:

- Track phase completion systematically
- Verify no phases are skipped
- Validate inter-phase variable flow
- Enable error recovery with resume points

## Reference Verification Protocol

Each phase reference file includes a **checksum verification header**. After reading each reference, confirm complete load by outputting the verification string shown in the reference header.

**Example:**

```text
Reference Loaded: phase-0-environment.md | Checksum: fa73141e
```

This ensures references are fully loaded into context before phase execution.

## Phase Structure

The dimension-planner executes 7 sequential phases, with research_type-dependent branching at Phase 2, Phase 3, and Phase 4b:

```text
Phase 0: Environment Validation
    ↓
Phase 1: Load Question & Detect Mode
    ↓
    ┌─────────────────────────────────────┐
    │   Research Type Routing             │
    └─────────────────────────────────────┘
    ↓
    ├─→ GENERIC                    ├─→ SMARTER-SERVICE           ├─→ LEAN-CANVAS              ├─→ B2B-ICT-PORTFOLIO
    │   Phase 2: DOK Classification │   Phase 2: TIPS Context    │   Phase 2: Canvas Analysis  │   Phase 2: ICT Dimensions
    │   Phase 3: Domain Selection   │   Phase 3: Momentum Focus  │   Phase 3: Stage Planning   │   Phase 3: Horizon Planning
    │                                │                            │                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────→
    ↓
Phase 4: Validation (MECE, PICOT, FINER, Quality)
    ↓
    ┌─────────────────────────────────────┐
    │   Phase 4b Routing                  │
    │   (generic/smarter-service ONLY)    │
    └─────────────────────────────────────┘
    ↓
    ├─→ GENERIC/SMARTER-SERVICE           ├─→ LEAN-CANVAS/B2B-ICT-PORTFOLIO
    │   Phase 4b: Megatrend Proposal      │   (Skip Phase 4b)
    │   - Generate seed megatrends        │
    │   - Write seed-megatrends.yaml      │
    │   - pending_validation: true        │
    └─────────────────────────────────────────────────────────────────────────→
    ↓
Phase 5: Create Entities (Batched)
    ↓
Phase 6: LLM Execution Report
    ↓
Return JSON Summary (with seed_megatrends if Phase 4b executed)
```

**Phase 4b Note:** Phase 4b generates seed megatrends for megatrend clustering. It only executes for `generic` and `smarter-service` research types. The seeds are written to `.metadata/seed-megatrends.yaml` with `user_validated: false`. The orchestrator (deeper-research-0) handles user validation in Phase 2b after dimension-planner returns.

## Research Type Routing

The workflow branches at Phase 2 and Phase 3 based on the `research_type` frontmatter field detected in Phase 1:

| Research Type | Phase 2 File | Phase 3 File | Dimensions | Questions |
|---------------|--------------|--------------|------------|-----------|
| `generic` (default) | [phase-2-analysis-generic.md](phase-2-analysis-generic.md) | [phase-3-planning-generic.md](phase-3-planning-generic.md) | 2-10 (DOK-adaptive) | 8-50 (DOK-based) |
| `smarter-service` | [phase-2-analysis-smarter-service.md](phase-2-analysis-smarter-service.md) | [phase-3-planning-smarter-service.md](phase-3-planning-smarter-service.md) | 4 (fixed: TIPS) | 16-20 (4-5 per dim) |
| `lean-canvas` | [phase-2-analysis-lean-canvas.md](phase-2-analysis-lean-canvas.md) | [phase-3-planning-lean-canvas.md](phase-3-planning-lean-canvas.md) | 9 (fixed: canvas blocks) | 27-45 (3-5 per block) |
| `b2b-ict-portfolio` | [phase-2-analysis-b2b-ict-portfolio.md](phase-2-analysis-b2b-ict-portfolio.md) | [phase-3-planning-b2b-ict-portfolio.md](phase-3-planning-b2b-ict-portfolio.md) | 8 (fixed: provider + ICT services, 0-7) | 57 (1 per category) |

**Key Difference:**
- **Generic:** Domain-based, DOK-adaptive dimension planning with dynamic dimension count (2-10) and question targets (8-50)
- **Smarter-Service:** Template-driven, fixed 4 dimensions (TIPS framework), momentum-focused questions
- **Lean-Canvas:** Template-driven, fixed 9 dimensions (canvas blocks), hypothesis validation questions
- **B2B-ICT-Portfolio:** Template-driven, fixed 8 dimensions (provider profile + 7 ICT service categories, 0-7), service horizon-focused questions

## Phase Loading Guide

Load each phase reference when executing that phase:

| Phase | Common File | Methodology-Specific Files | Load At | Key Content |
|-------|-------------|---------------------------|---------|-------------|
| 0 | [phase-0-environment.md](phase-0-environment.md) | N/A | Beginning of execution | Environment setup, logging initialization, variable setup |
| 1 | [phase-1-input-loading.md](phase-1-input-loading.md) | N/A | After Phase 0 completes | Question parsing, mode detection, frontmatter extraction |
| 2 | N/A | [phase-2-analysis-generic.md](phase-2-analysis-generic.md)<br>[phase-2-analysis-smarter-service.md](phase-2-analysis-smarter-service.md)<br>[phase-2-analysis-lean-canvas.md](phase-2-analysis-lean-canvas.md)<br>[phase-2-analysis-b2b-ict-portfolio.md](phase-2-analysis-b2b-ict-portfolio.md) | After Phase 1 completes | DOK classification, TIPS context, canvas block analysis, or ICT dimension analysis |
| 3 | N/A | [phase-3-planning-generic.md](phase-3-planning-generic.md)<br>[phase-3-planning-smarter-service.md](phase-3-planning-smarter-service.md)<br>[phase-3-planning-lean-canvas.md](phase-3-planning-lean-canvas.md)<br>[phase-3-planning-b2b-ict-portfolio.md](phase-3-planning-b2b-ict-portfolio.md) | After Phase 2 completes | Domain selection, momentum focus, stage-based planning, or horizon planning |
| 4 | [phase-4-validation.md](phase-4-validation.md) | N/A | Before Phase 4.1 starts | MECE validation, FINER scoring, quality planning workflows |
| 4b | [phase-4b-megatrend-proposal.md](phase-4b-megatrend-proposal.md) | N/A | After Phase 4 completes (generic/smarter-service only) | Seed megatrend generation, seed-megatrends.yaml creation |
| 5 | [phase-5-entity-creation.md](phase-5-entity-creation.md) | N/A | Before Phase 5 starts | **BATCHED ONLY**: JSON generation, batch script execution |
| 6 | [phase-6-llm-execution-report.md](phase-6-llm-execution-report.md) | N/A | After Phase 5 completes | LLM execution report (Layer 4 debugging) |

**⛔ Phase 4b Note:** Only executes for `generic` and `smarter-service` research types. Skip for `lean-canvas` and `b2b-ict-portfolio`.

**⛔ Phase 5 Note:** Only use `phase-5-entity-creation.md`. Files in `archived/` directory are deprecated and produce incorrect entity schemas.

## Methodology-Specific Workflow Files

### New Phase 2 Analysis Files (Research Type-Specific)

1. **phase-2-analysis-generic.md** - DOK classification for generic research questions
   - Webb's DOK framework (1-4 levels)
   - Extended thinking for complexity assessment
   - Dynamic dimension ranges (2-10)
   - Question targets (8-50)

2. **phase-2-analysis-smarter-service.md** - TIPS context extraction for smarter service questions
   - Technology dimension analysis
   - Implementation dimension analysis
   - People dimension analysis
   - Strategy dimension analysis
   - Momentum indicators identification

3. **phase-2-analysis-lean-canvas.md** - Canvas block analysis for business validation questions
   - 9 Lean Canvas blocks validation
   - Stage focus determination (Problem, Solution, Validation, Scale)
   - Evidence pattern establishment
   - Hypothesis validation targets

### New Phase 3 Planning Files (Research Type-Specific)

1. **phase-3-planning-generic.md** - Domain-based planning for generic research
   - Original question context preservation
   - Domain selection (Business/Academic/Product)
   - DIMENSION_CONTEXT blending with templates
   - PICOT pattern customization with context overrides

2. **phase-3-planning-smarter-service.md** - TIPS-aligned planning for smarter service questions
   - Momentum-focused question generation
   - Service evolution timeline establishment
   - TIPS dimension PICOT patterns
   - Implementation roadmap integration

3. **phase-3-planning-lean-canvas.md** - Canvas-block-specific planning for business validation
   - Stage-appropriate question generation
   - Hypothesis validation question patterns
   - Canvas block PICOT patterns
   - Risk and assumption identification

## Variable Flow

Variables are accumulated across phases and used in subsequent phases:

**Phase 0 → Phase 1:**
- PROJECT_PATH, CLAUDE_PLUGIN_ROOT, LOG_FILE, PROJECT_LANGUAGE

**Phase 1 → Phase 2:**
- QUESTION_FILE, RESEARCH_TYPE, DIMENSIONS_MODE, TEMPLATE_PATH (if applicable)

**Phase 2 → Phase 3 (Generic):**
- DOK_LEVEL, MIN_DIMS, MAX_DIMS, MIN_Q_PER_DIM, TOTAL_Q_MIN, TOTAL_Q_MAX

**Phase 2 → Phase 3 (Smarter-Service):**
- TIPS_DIMENSIONS (4 fixed), MOMENTUM_INDICATORS, SERVICE_CONTEXT

**Phase 2 → Phase 3 (Lean-Canvas):**
- CANVAS_BLOCKS (9 fixed), STAGE_FOCUS, EVIDENCE_PATTERNS

**Phase 3 → Phase 4 (Generic):**
- SELECTED_DIMENSIONS, DIMENSION_CONTEXT, PICOT_OVERRIDES, TOTAL_QUESTIONS

**Phase 3 → Phase 4 (Smarter-Service):**
- TIPS_QUESTIONS, MOMENTUM_TIMELINE, SERVICE_EVOLUTION_PHASES

**Phase 3 → Phase 4 (Lean-Canvas):**
- CANVAS_QUESTIONS, HYPOTHESIS_TARGETS, VALIDATION_CRITERIA

**Phase 4 → Phase 4b (Generic/Smarter-Service):**
- FINAL_DIMENSIONS, VALIDATED_QUESTIONS, AVG_FINER_SCORE, RESEARCH_TYPE

**Phase 4b → Phase 5 (Generic/Smarter-Service):**
- SEED_MEGATRENDS (proposed seeds), SEED_FILE_PATH

**Phase 4 → Phase 5 (Lean-Canvas/B2B-ICT-Portfolio):**
- FINAL_DIMENSIONS, VALIDATED_QUESTIONS, AVG_FINER_SCORE (skip Phase 4b)

**Phase 5 → Phase 6:**
- DIMENSION_SLUGS (for backlinks), Entity file paths, SEED_MEGATRENDS (if applicable)

**Phase 6 → Return:**
- LLM execution report, seed_megatrends object (if Phase 4b executed)

## Success Criteria Tracking

Each phase has defined success criteria. Track these to ensure workflow integrity:

- **Phase 0:** CLAUDE_PLUGIN_ROOT validated, logging initialized, variables set
- **Phase 1:** Question parsed, research_type detected, mode determined
- **Phase 2 (Generic):** DOK level determined with extended thinking, dimension ranges set
- **Phase 2 (Smarter-Service):** 4 TIPS dimensions validated, momentum indicators identified
- **Phase 2 (Lean-Canvas):** 9 canvas blocks confirmed, stage focus determined
- **Phase 3 (Generic):** Domain template selected, DIMENSION_CONTEXT preserved, PICOT overrides set
- **Phase 3 (Smarter-Service):** TIPS-aligned questions generated, momentum timeline established
- **Phase 3 (Lean-Canvas):** Canvas-block questions generated, hypothesis targets set
- **Phase 4:** MECE validated, FINER scored, quality planning complete
- **Phase 4b (Generic/Smarter-Service):** Seed megatrends generated, seed-megatrends.yaml created with pending_validation: true
- **Phase 5:** Entities created, backlinks updated, JSON prepared
- **Phase 6:** LLM execution report appended to JSONL log

## Common Errors by Phase

**Phase 0:** CLAUDE_PLUGIN_ROOT not set, logging initialization fails
**Phase 1:** Question file not found, frontmatter malformed, research_type detection failed
**Phase 2 (Generic):** DOK classification ambiguous, extended thinking incomplete
**Phase 2 (Smarter-Service):** TIPS dimension not recognized, momentum indicators missing
**Phase 2 (Lean-Canvas):** Canvas block not found in template, stage focus unclear
**Phase 3 (Generic):** Domain template undefined, DIMENSION_CONTEXT empty, PICOT patterns generic
**Phase 3 (Smarter-Service):** Momentum timeline missing, service evolution phases incomplete
**Phase 3 (Lean-Canvas):** Hypothesis targets undefined, validation criteria unclear
**Phase 4:** MECE overlap >20%, FINER score <10, dimension count invalid
**Phase 5:** Entity file conflicts, backlink syntax errors, JSON malformed

## Research Type Detection

Phase 1 detects the research type using the `detect-research-mode.sh` script:

```bash
bash scripts/detect-research-mode.sh --question-file "$QUESTION_FILE" --json
```

**Output JSON:**
```json
{
  "success": true,
  "data": {
    "research_type": "generic|smarter-service|lean-canvas|b2b-ict-portfolio",
    "dimensions_mode": "domain-based|template-driven",
    "template_path": "/path/to/template.yml" // Optional, only for template-driven
  }
}
```

**Routing Logic:**
- `research_type: generic` or omitted → Use generic Phase 2/3 files (DOK-adaptive)
- `research_type: smarter-service` → Use smarter-service Phase 2/3 files (TIPS framework)
- `research_type: lean-canvas` → Use lean-canvas Phase 2/3 files (Canvas blocks)
- `research_type: b2b-ict-portfolio` → Use b2b-ict-portfolio Phase 2/3 files (ICT service dimensions)

## Cross-Phase References

- **Multilingual patterns:** See [../multilingual-patterns.md](../multilingual-patterns.md)
- **Error recovery:** See [../error-recovery-patterns.md](../error-recovery-patterns.md)
- **Validation patterns:** See [../validation-patterns.md](../validation-patterns.md)
- **MECE methodology:** See [../mece-validation.md](../mece-validation.md)
- **FINER scoring:** See [../finer-criteria.md](../finer-criteria.md)
- **PICOT components:** See [../picot-framework.md](../picot-framework.md)
- **DOK classification:** See [../../../../references/dok-classification.md](../../../../references/dok-classification.md)
- **Research type templates:** See [../../references/research-types/](../../references/research-types/)

## Refactoring History

**Version 2.0 (2025-12-04):** Split Phase 2 and Phase 3 into research_type-specific files
- **Before:** Single `phase-2-analysis.md` and `phase-3-planning.md` with conditional logic
- **After:** 6 methodology-specific files (3 for Phase 2, 3 for Phase 3)
- **Benefits:**
  - Clearer separation of concerns
  - Easier maintenance and updates
  - Reduced cognitive load per workflow
  - Better alignment with research type frontmatter
  - Progressive disclosure of complexity

**Migration Guide:**
- Old workflows using `phase-2-analysis.md` → Now use `phase-2-analysis-generic.md`
- Old workflows using `phase-3-planning.md` → Now use `phase-3-planning-generic.md`
- Research type routing now explicit at Phase 2/3 entry points

## Return to SKILL.md

After executing specific phases, return to [../../SKILL.md](../../SKILL.md) to continue the workflow at the next phase reference.

---

**Size: ~6.5KB** | Last Updated: 2026-01-12 | Version: 2.1 (Phase 4b Integration)
