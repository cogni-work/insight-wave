# Dimension Planner - Runtime Execution Checklist

**Purpose:** Track workflow phase execution to ensure all phases complete successfully.

**Usage:** Mark each checkpoint as complete during execution. Use this to verify no phases are skipped.

---

## Pre-Execution

- [ ] SKILL.md read and understood
- [ ] [workflow-overview.md](workflow-overview.md) read
- [ ] Question file path received
- [ ] Execution mode ready (Skill invocation)

---

## Phase 0: Environment Validation

**Reference:** [phase-0-environment.md](phase-0-environment.md)

- [ ] Reference loaded (Checksum: fa73141e confirmed)
- [ ] Step 0.1: PROJECT_PATH extracted from question file
- [ ] Step 0.2: `validate-environment.sh` executed successfully
- [ ] Step 0.3: LOG_FILE initialized
- [ ] Step 0.4: PROJECT_LANGUAGE loaded from sprint-log.json
- [ ] Step 0.5: Output directories validated/created
- [ ] All success criteria met
- [ ] Variables set: PROJECT_PATH, CLAUDE_PLUGIN_ROOT, LOG_FILE, PROJECT_LANGUAGE

---

## Phase 1: Load Question & Detect Mode

**Reference:** [phase-1-input-loading.md](phase-1-input-loading.md)

- [ ] Reference loaded (Checksum: 4860411b confirmed)
- [ ] Step 1.1: Question file read successfully
- [ ] Step 1.2: `detect-research-mode.sh` executed
- [ ] Step 1.3: Mode-dependent references identified
- [ ] Step 1.4: Frontmatter fields parsed
- [ ] All success criteria met
- [ ] Variables set: RESEARCH_TYPE, DIMENSIONS_MODE, TEMPLATE_PATH (if applicable)
- [ ] Mode branching determined: [ ] Domain-based OR [ ] Research-type-specific

---

## Phase 2: Analysis

**Reference:** [phase-2-analysis.md](phase-2-analysis.md)

- [ ] Reference loaded (Checksum: 9a98bbb6 confirmed)

### Domain-Based Mode (if applicable)

- [ ] DOK classification completed with extended thinking
- [ ] Extended thinking template applied (verb/source/depth analysis)
- [ ] DOK_LEVEL determined (1, 2, 3, or 4)
- [ ] MIN_DIMS and MAX_DIMS set
- [ ] Variables set: DOK_LEVEL, MIN_DIMS, MAX_DIMS, MIN_Q_PER_DIM, TOTAL_Q_MIN, TOTAL_Q_MAX

### Research-Type-Specific Mode (if applicable)

- [ ] Phase 2 file loaded (e.g., phase-2-analysis-smarter-service.md)
- [ ] Embedded dimension definitions applied
- [ ] DIMENSION_COUNT set from embedded structure
- [ ] DIMENSION_SLUGS set from embedded structure
- [ ] Variables set: DIMENSION_COUNT, DIMENSION_SLUGS, DIMENSION_SPECS

- [ ] All success criteria met for selected mode

---

## Phase 3: Planning

**Reference:** [phase-3-planning.md](phase-3-planning.md)

- [ ] Reference loaded (Checksum: 096f682f confirmed)

### Domain-Based Mode (if applicable)

- [ ] Domain template selected (business/academic/product)
- [ ] DIMENSION_COUNT determined within DOK range
- [ ] SELECTED_DIMENSIONS populated
- [ ] Variables set: DOMAIN_TEMPLATE, SELECTED_DOMAINS, DIMENSION_COUNT, SELECTED_DIMENSIONS

### Research-Type-Specific Mode (if applicable)

- [ ] PICOT_PATTERNS extracted for all dimensions
- [ ] TOTAL_QUESTIONS_TARGET calculated
- [ ] GENERATION_LANGUAGE set
- [ ] Template PICOT consistency validated
- [ ] Variables set: PICOT_PATTERNS, MIN_QUESTIONS_PER_DIM, TOTAL_QUESTIONS_TARGET, GENERATION_LANGUAGE

- [ ] All success criteria met for selected mode

---

## Phase 4: Validation & Question Generation (Batched with Extended Thinking)

**Reference:** [phase-4-validation.md](phase-4-validation.md)

- [ ] Reference loaded (Checksum: 8b3e9c94 confirmed)

### Phase 4.1: MECE Planning (Domain-based only)

- [ ] Pairwise overlap validation passed (<20%)
- [ ] Coverage mapping completed (100%)
- [ ] Independence verified
- [ ] SELECTED_DIMENSIONS finalized

### Phase 4.2: PICOT Question Generation (Both modes - BATCHED)

- [ ] PICOT questions generated using BATCHED approach (per-dimension, not per-question)
- [ ] Extended thinking template applied with explicit P/I/C/O/T reasoning
- [ ] Question count meets targets
- [ ] Variables set: PICOT_QUESTIONS, TOTAL_QUESTIONS

### Phase 4.3: Comprehensive Quality Assessment (Both modes - BATCHED + MERGED)

**Note:** Phase 4.3 now combines FINER scoring + quality planning in single batched pass

- [ ] All questions scored using BATCHED approach (5-10 questions per call)
- [ ] Extended thinking template applied with explicit F/I/N/E/R reasoning
- [ ] Individual scores ≥10/15
- [ ] Average FINER score ≥11.0
- [ ] Quality planning completed in SAME batched calls (confidence, triangulation, gaps, complexity)
- [ ] Variables set: FINER_SCORES, AVG_FINER_SCORE, QUALITY_PLAN

### Phase 4.5: Template Validation (Research-type only, if needed)

- [ ] Template validation confirmed (usually done in Phase 2a)

### Phase 4.6: Final Validation (Both modes)

- [ ] `validate-outputs.sh` executed successfully
- [ ] Dimension count: 2-10 ✓
- [ ] Question count: valid for research type (8-50 generic, 60 smarter-service, 57 b2b-ict-portfolio) ✓
- [ ] Average FINER: ≥11.0 ✓

- [ ] All success criteria met

**Performance Note:** Phase 4 optimized with batched generation and comprehensive assessment (40-60s vs previous 90-135s for DOK-3, 20 questions)

---

## Phase 4b: Megatrend Proposal (CONDITIONAL)

**Reference:** [phase-4b-megatrend-proposal.md](phase-4b-megatrend-proposal.md)

**Condition:** Execute ONLY for `generic` or `smarter-service` research types.

- [ ] Reference loaded (Checksum: MEGATREND-PROPOSAL-V2 confirmed)
- [ ] Research type is `generic` OR `smarter-service`? → If NO, skip to Phase 5

### Phase 4b.1: Analyze Research Context

- [ ] Research context extracted (initial question, dimensions, keywords)
- [ ] Scope indicators identified (temporal, geographic, domain)

### Phase 4b.2: Generate Seed Megatrend Candidates

- [ ] 5-10 seed megatrends proposed using extended thinking
- [ ] Each seed has: name, keywords, dimension_affinity, rationale, planning_horizon_hint
- [ ] Planning horizons assigned (act/plan/observe based on maturity)

### Phase 4b.3: Write Seed Megatrends File

- [ ] `.metadata/seed-megatrends.yaml` created
- [ ] File has `user_validated: false` (pending orchestrator validation)
- [ ] All proposed seeds have `proposed_by: "llm"`

### Phase 4b.4: Include in Response

- [ ] Response JSON includes `seed_megatrends` object
- [ ] `seed_megatrends.count` matches number of proposed seeds
- [ ] `seed_megatrends.file` points to `.metadata/seed-megatrends.yaml`
- [ ] `seed_megatrends.pending_validation` is `true`

- [ ] All Phase 4b success criteria met (or skipped for lean-canvas/b2b-ict-portfolio)

---

## Phase 5: Entity Creation (BATCHED ONLY)

**Reference:** [phase-5-entity-creation.md](phase-5-entity-creation.md)

**⛔ CRITICAL:** Only use batched approach. NEVER use Write tool for dimension/question files.

- [ ] Reference loaded (phase-5-entity-creation.md)
- [ ] Understood: Only the batch script creates entity files (not Write tool)

### Phase 5.1: Generate Batch JSON

- [ ] JSON schema from phase-5-entity-creation.md understood
- [ ] Batch JSON generated with ALL dimensions and questions
- [ ] JSON includes `metadata.initial_question_entity_id` field
- [ ] JSON structure validated (dimensions array, questions nested per dimension)

### Phase 5.2: Write JSON to .metadata/

- [ ] JSON written to `${PROJECT_PATH}/.metadata/dimension-plan-batch.json`
- [ ] File exists and contains valid JSON
- [ ] **This is the ONLY Write tool call in Phase 5**

### Phase 5.3: Call Batch Unpack Script (MANDATORY)

- [ ] Script called: `unpack-dimension-plan-batch.sh`
- [ ] Script completed with exit code 0
- [ ] Output JSON shows `"success": true`
- [ ] `dimensions_created` count matches expected
- [ ] `questions_created` count matches expected

**⛔ If script fails:** Fix JSON and retry. NEVER fall back to direct Write calls.

### Phase 5.4: Verify Entity Files

- [ ] Dimension files exist in `01-research-dimensions/data/`
- [ ] Question files exist in `02-refined-questions/data/`
- [ ] Dimension files contain `initial_question_ref` field (backlink to parent question)
- [ ] All entity files have correct `entity_type: dimension` or `entity_type: refined-question`

### Phase 5.5: Update Initial Question Backlinks

- [ ] dimension_ids field added/updated in initial question file
- [ ] All dimension entity_ids included
- [ ] Wikilink format correct
- [ ] YAML still valid

- [ ] All Phase 5 success criteria met

---

## Phase 6: LLM Execution Report

**Reference:** [phase-6-llm-execution-report.md](phase-6-llm-execution-report.md)

**⚠️ MANDATORY:** Always execute Phase 6, even if no issues occurred.

- [ ] Reference loaded (Checksum: v1.0 confirmed)

### Phase 6.1: Reflect on Execution

- [ ] Reviewed Phases 0-5 for issues
- [ ] Self-verification questions answered (scripts, files, schemas, adaptations)

### Phase 6.2: Collect Issues

- [ ] Each issue documented with: type, severity, expected, actual, resolution
- [ ] Issue types classified (script_path, schema_mismatch, file_not_found, etc.)

### Phase 6.3: Create JSON Report

- [ ] Report JSON follows schema from phase-6-llm-execution-report.md
- [ ] `success` field reflects actual outcome quality

### Phase 6.4: Append to JSONL Log

- [ ] Report appended to `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`

- [ ] All Phase 6 success criteria met

---

## Post-Execution

- [ ] JSON summary returned to deeper-research pipeline (with seed_megatrends if applicable)
- [ ] All entity files created successfully
- [ ] All verification gates passed
- [ ] No errors or warnings logged
- [ ] Workflow complete

---

## Variable Tracking (Inter-Phase Validation)

Use this section to verify required variables are set before each phase:

### Before Phase 1
- [ ] QUESTION_FILE (parameter)

### Before Phase 2
- [ ] PROJECT_PATH
- [ ] CLAUDE_PLUGIN_ROOT
- [ ] LOG_FILE
- [ ] PROJECT_LANGUAGE
- [ ] RESEARCH_TYPE
- [ ] DIMENSIONS_MODE

### Before Phase 3
- [ ] DOK_LEVEL (domain-based) OR DIMENSION_SPECS (research-type)

### Before Phase 4
- [ ] SELECTED_DIMENSIONS (domain) OR DIMENSION_SLUGS (research-type)
- [ ] PICOT_PATTERNS or domain context

### Before Phase 5
- [ ] FINAL_DIMENSIONS
- [ ] VALIDATED_QUESTIONS
- [ ] AVG_FINER_SCORE
- [ ] PICOT_QUESTIONS
- [ ] FINER_SCORES
- [ ] QUALITY_PLAN

---

## Error Recovery

If execution fails at any phase:

1. **Identify failure phase** - Check last completed checkpoint above
2. **Review phase prerequisites** - Verify all required variables from previous phases
3. **Check error logs** - Review LOG_FILE for specific error messages
4. **Verify script execution** - Ensure validate-environment.sh, detect-research-mode.sh, validate-outputs.sh ran successfully
5. **Resume from last successful phase** - Use variable tracking to ensure context preserved

---

**Checklist Version:** 1.2 (Phase 4b + Phase 6)
**Last Updated:** 2026-01-12
**Corresponds to:** dimension-planner SKILL.md workflow phases 0-6 with batched generation, Phase 4b megatrend proposal, and Phase 6 LLM execution report
**Key Changes:** Added Phase 4b (megatrend proposal for generic/smarter-service) and Phase 6 (LLM execution report)
