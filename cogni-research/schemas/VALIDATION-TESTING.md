# Schema Validation Testing Plan

**Related**: Sprint 386 (Integration), Sprint 387 (Production Testing)

---

## Overview

This document tracks schema validation testing across development and production environments following the integration completed in Sprint 386.

---

## Sprint 386: Integration Testing (Complete ✅)

**Date**: 2025-11-26
**Status**: Complete
**Environment**: Development (local git repository)

### Results

#### Validation Hook Integration

- ✅ Validation hook integrated in [create-entity.sh:830-854](../scripts/create-entity.sh#L830-L854)
- ✅ 10 centralized schemas available and functional
- ✅ Warning mode (non-blocking) working as designed
- ✅ Graceful degradation when CLAUDE_PLUGIN_ROOT unavailable

#### Functional Testing

**Test Case 1: Invalid Entity**

- Created source entity with 8 schema violations
- Result: All violations correctly detected
- Exit code: 1 (failure), Status: "failure"

**Test Case 2: Valid Entity**

- Created compliant source entity
- Result: Validation passed
- Exit code: 0 (success), Status: "success"

**Test Case 3: Pattern Validation**

- Verified strict schema requirements (hex hashes, wikilinks, ISO timestamps)
- Result: Pattern enforcement working correctly

#### LLM Source Schema Extension

- ✅ Extended source-entity.schema.json for `llm://` URLs
- ✅ Added llm_model and llm_knowledge_cutoff fields
- ✅ Created publisher-anthropic-claude.md entity
- ✅ Updated findings-creator-llm and source-creator workflows
- ✅ Committed in [90fd692](https://github.com/cogni-work/cogni-research/commit/90fd692)

### Key Findings

- No schema violations detected in test entities
- Schemas well-defined and comprehensive
- Validation integration working correctly
- Ready for production testing

---

## Sprint 387: Production Testing (Planned)

**Status**: Pending deployment to marketplace
**Environment**: Production (CLAUDE_PLUGIN_ROOT marketplace path)
**Objective**: Execute end-to-end validation tests in production workflows

### Prerequisites

- [ ] Sprint 386 changes deployed to marketplace
- [ ] User has active research project with deeper-research plugin
- [ ] Validation hook accessible via marketplace path

### Test Plan

#### 1. Dimension-Planner Phase 5 Integration Test

**Goal**: Verify validation works in dimension-planner workflow

- [ ] Create test research project with initial question
- [ ] Execute dimension-planner through Phase 5 (entity creation)
- [ ] Verify validation executes for dimension and refined-question entities
- [ ] Confirm entities created successfully (warning mode non-blocking)
- [ ] Check logs for validation SUCCESS/WARN messages
- [ ] Validate centralized schema references work (../../schemas/)

**Expected Outcomes**:

- Dimension entities validated against `dimension-entity.schema.json`
- Refined question entities validated against `refined-question-entity.schema.json`
- Both entity types created regardless of validation result (warning mode)

#### 2. Multi-Entity Type Validation

**Goal**: Verify validation across all entity types

- [ ] Execute findings-creator workflow (creates finding entities)
- [ ] Execute source-creator workflow (creates source entities)
- [ ] Execute publisher-creator workflow (creates publisher entities)
- [ ] Verify validation runs for all 3 entity types
- [ ] Collect validation metrics (pass/fail rates per entity type)

**Expected Outcomes**:

- All 10 entity types trigger validation automatically
- <5% validation failure rate for production entities
- Validation logs accessible and parseable

#### 3. LLM Source Integration Test

**Goal**: Verify LLM source schema extensions work in production

- [ ] Execute findings-creator-llm workflow
- [ ] Verify LLM source entities created with `llm://` URLs
- [ ] Confirm LLM-specific schema fields validated (llm_model, llm_knowledge_cutoff)
- [ ] Check publisher-anthropic-claude.md entity created/reused

**Expected Outcomes**:

- LLM sources validate successfully with new schema fields
- Publisher entity properly links to LLM sources
- No breaking changes to existing web source workflows

#### 4. Validation Failure Analysis

**Goal**: Identify schema improvements needed

- [ ] Review all WARN logs from validation failures
- [ ] Categorize failure types (missing fields, pattern mismatches, etc.)
- [ ] Identify schema improvements needed
- [ ] Document false positives (if any)

**Metrics to Track**:

- Total entities created: `_____`
- Total validations executed: `_____`
- Validation passes: `_____` (%)
- Validation failures: `_____` (%)
- Breakdown by entity type:
  - dimension: _____ pass / _____ fail
  - refined-question: _____ pass / _____ fail
  - finding: _____ pass / _____ fail
  - source: _____ pass / _____ fail
  - publisher: _____ pass / _____ fail
  - citation: _____ pass / _____ fail
  - claim: _____ pass / _____ fail
  - megatrend: _____ pass / _____ fail
  - initial-question: _____ pass / _____ fail
  - query-batch: _____ pass / _____ fail

#### 5. Performance Baseline

**Goal**: Assess validation overhead

- [ ] Measure entity creation time with validation enabled
- [ ] Compare against historical baselines (if available)
- [ ] Assess validation overhead per entity

**Performance Targets**:

- <100ms validation overhead per entity
- No workflow timeouts introduced
- Minimal impact on user experience

### Success Criteria

- ✅ All entity types trigger validation automatically
- ✅ No workflow breaking changes (warning mode respected)
- ✅ Validation logs accessible and parseable
- ✅ <5% validation failure rate for production entities
- ✅ <100ms validation overhead per entity

### Deliverables

1. Sprint 387 test results report
2. Validation metrics dashboard (entity types, pass/fail rates)
3. Schema refinement recommendations (if violations found)
4. Decision on strict mode readiness

---

## Sprint 388+: Long-Term Roadmap

### Strict Mode Rollout (If Sprint 387 successful)

- Enable strict validation for high-confidence entity types
- Block entity creation on validation failure
- Update documentation and error messages

### CI/CD Integration

- Add schema validation to pre-commit hooks
- Integrate validation into CI/CD pipeline
- Automate schema compliance checking

### Validation Metrics & Monitoring

- Track validation pass/fail rates over time
- Alert on schema violation trends
- Monitor validation performance impact

---

## Reference Documentation

- Sprint 386 Build Report: `.sprints/sprint-386-integrate-validation-and-migrate-dimension-planner/build-report.md` (local only)
- Integration Pattern: [schemas/INTEGRATION.md](INTEGRATION.md)
- Migration Notes: [schemas/MIGRATION-NOTES.md](MIGRATION-NOTES.md)
- Centralized Schemas: [schemas/](.) (10 entity types)
- Validation Script: [scripts/validate-entity-schema.sh](../scripts/validate-entity-schema.sh)

---

**Last Updated**: 2025-11-26
**Status**: Sprint 386 complete, Sprint 387 pending deployment
