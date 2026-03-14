# Schema Migration Notes

This document tracks the migration status from local skill schemas to centralized plugin-level schemas.

**Related Documentation**:
- [README.md](README.md) - Schema overview and entity types
- [linking-architecture.md](linking-architecture.md) - Entity relationship patterns
- [INTEGRATION.md](INTEGRATION.md) - Integration patterns for scripts and agents

## Migration Status

### ✅ Completed

- **Centralized schemas created**: All 10 entity type schemas in `/cogni-research/schemas/`
- **Validation script created**: `/cogni-research/scripts/validate-entity-schema.sh`
- **UML diagram created**: `/cogni-research/docs/entity-relationships.uml`
- **Documentation created**: README, conventions, integration guide, developer guide

### ✅ Completed (Sprint 386)

#### Dimension-Planner Schema Migration

**Completed Actions:**

- ✅ Updated schema references in `phase-5-entity-creation.md`
- ✅ Deleted duplicate local schemas:
  - `dimension-entity.schema.json` (now using `../../schemas/dimension-entity.schema.json`)
  - `question-entity.schema.json` (now using `../../schemas/refined-question-entity.schema.json`)
- ✅ Retained skill-specific schema: `dimension-plan-batch.schema.json` (correct decision - skill-specific validation)
- ✅ Integrated schema validation into `create-entity.sh` (warning mode)
- ✅ Consolidated to single batched approach (removed sequential JSON schema approach)

**Current State**:
- dimension-planner now uses centralized schemas for dimension and question entities
- Only 1 local schema remains in `skills/dimension-planner/schemas/`:
  - `dimension-plan-batch.schema.json` (skill-specific batched validation)

### 🔄 Pending

#### Validation Rollout

**Current State**:
- Validation integrated in warning mode (non-blocking)
- Logs validation failures without blocking entity creation

**Migration Plan**:

1. **Update References**:
   ```bash
   # Change from:
   schemas/dimension-entity.schema.json

   # To:
   ../../schemas/dimension-entity.schema.json
   # Or use CLAUDE_PLUGIN_ROOT:
   ${CLAUDE_PLUGIN_ROOT}/schemas/dimension-entity.schema.json
   ```

2. **Update Scripts**:
   - `scripts/unpack-dimension-plan-batch.sh` - Update schema validation paths

3. **Decision on Local Schemas**:
   - **Option A**: Keep `dimension-plan-batch.schema.json` local (skill-specific, not a general entity)
   - **Option B**: Move to centralized location as `schemas/dimension-plan-batch.schema.json`
   - **Recommendation**: Option A - dimension-plan-batch is skill-specific validation, not a general entity type

4. **Update Documentation**:
   - Update dimension-planner SKILL.md references
   - Update workflow phase documentation

**Why Not Migrated in Sprint 384**:
- User requested "start fresh" approach without backward compatibility
- Dimension-planner migration requires careful testing to avoid breaking existing functionality
- Should be its own focused task with validation tests
- Sprint 384 focused on establishing centralized schema foundation

**Recommended Next Sprint**: Create focused task for dimension-planner schema migration with:
- Update all references from local to centralized schemas
- Test dimension-planner workflow end-to-end
- Verify schema validation still works
- Consider keeping dimension-plan-input.schema.json local (skill-specific)

---

## Migration Checklist for Other Skills

When migrating skills to use centralized schemas:

### Pre-Migration

- [ ] Identify all schema references in skill SKILL.md
- [ ] Identify all schema references in skill scripts
- [ ] Identify all schema references in skill references/
- [ ] Check if schemas are entity-level (migrate) or skill-specific (keep local)

### Migration Steps

- [ ] Update SKILL.md schema paths to centralized location
- [ ] Update script schema paths (use `CLAUDE_PLUGIN_ROOT`)
- [ ] Update reference documentation
- [ ] Test skill workflow end-to-end
- [ ] Verify validation still works
- [ ] Update skill README if needed

### Post-Migration

- [ ] Remove local schema files (if migrated)
- [ ] Update this document with migration status
- [ ] Document any skill-specific schemas that remain local

---

## Schema Location Decision Tree

**Is this schema used by multiple skills?**
- YES → Centralize to `/cogni-research/schemas/`
- NO → Keep checking

**Does this schema define a research entity type?**
- YES → Centralize to `/cogni-research/schemas/`
- NO → Keep checking

**Is this schema skill-specific workflow validation?**
- YES → Keep in `skills/{skill-name}/schemas/`
- NO → Consider centralizing

**Examples**:

✅ **Centralize**:
- `dimension-entity.schema.json` - Research entity used by multiple components
- `source-entity.schema.json` - Research entity used by multiple components
- `finding-entity.schema.json` - Research entity used by multiple components

✅ **Keep Local:**

- `dimension-plan-batch.schema.json` - Skill-specific batched input validation for dimension-planner
- `synthesis-config.schema.json` - Skill-specific configuration schema

---

## Benefits of Centralized Schemas

**Achieved in Sprint 384**:
1. ✅ Single source of truth for entity definitions
2. ✅ Consistent validation across all components
3. ✅ Clear documentation and conventions
4. ✅ UML diagram for relationship visualization
5. ✅ Centralized validation script

**Future Benefits** (after full migration):
1. Eliminate schema duplication
2. Ensure all skills use same entity structure
3. Simplify schema updates (one place to change)
4. Better developer onboarding (clear schema reference)
5. Automated validation in CI/CD

---

## Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Centralized Schemas | ✅ Complete | All 10 entity schemas created |
| Schema Documentation | ✅ Complete | README, linking-architecture, INTEGRATION docs |
| Validation Script | ✅ Complete | validate-entity-schema.sh operational |
| dimension-planner Integration | ✅ Complete | Using centralized schemas (Sprint 386) |
| Other Skills Migration | 🔄 Pending | Skills still using local/template patterns |
| Strict Validation Mode | 🔄 Pending | Currently in warning mode |

---

**Document Version**: 1.0.1
**Created**: 2025-11-26
**Last Updated**: 2025-11-26
**Status**: Foundation Complete, Skills Migration In Progress
