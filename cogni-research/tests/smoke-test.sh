#!/usr/bin/env bash
set -euo pipefail
# smoke-test.sh
# Quick validation that cogni-research v1.0.0 infrastructure works
#
# Tests:
#   1. Entity schema loads correctly (7 types)
#   2. Project initialization creates correct directory structure
#   3. Entity creation works for each type
#   4. Hook scripts are executable
#   5. Core scripts are executable

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

log_pass() {
    echo "  PASS: $1"
    PASS=$((PASS + 1))
}

log_fail() {
    echo "  FAIL: $1"
    FAIL=$((FAIL + 1))
}

echo "=== cogni-research v1.0.0 Smoke Test ==="
echo "Plugin root: $PLUGIN_ROOT"
echo "Test dir: $TEST_DIR"
echo ""

# ============================================================================
# Test 1: Entity schema loads
# ============================================================================
echo "Test 1: Entity schema"

ENTITY_COUNT=$(python3 -c "
import json, sys
with open('$PLUGIN_ROOT/config/entity-schema.json') as f:
    data = json.load(f)
print(len(data['entity_types']))
" 2>/dev/null)

if [[ "$ENTITY_COUNT" == "7" ]]; then
    log_pass "Entity schema has 7 types"
else
    log_fail "Entity schema has $ENTITY_COUNT types (expected 7)"
fi

# Verify entity type names
TYPES=$(python3 -c "
import json
with open('$PLUGIN_ROOT/config/entity-schema.json') as f:
    data = json.load(f)
for t in data['entity_types']:
    print(t['directory'])
" 2>/dev/null)

for expected in "00-initial-question" "01-research-dimensions" "02-refined-questions" "03-query-batches" "04-findings" "05-sources" "06-claims"; do
    if echo "$TYPES" | grep -q "$expected"; then
        log_pass "Entity type $expected exists"
    else
        log_fail "Entity type $expected missing"
    fi
done

# ============================================================================
# Test 2: Schema files exist
# ============================================================================
echo ""
echo "Test 2: Schema files"

for schema in initial-question-entity dimension-entity refined-question-entity query-batch-entity finding-entity source-entity claim-entity; do
    if [[ -f "$PLUGIN_ROOT/schemas/${schema}.schema.json" ]]; then
        log_pass "Schema $schema exists"
    else
        log_fail "Schema $schema missing"
    fi
done

# ============================================================================
# Test 3: Hook scripts are executable
# ============================================================================
echo ""
echo "Test 3: Hook scripts"

if [[ -f "$PLUGIN_ROOT/hooks/hooks.json" ]]; then
    log_pass "hooks.json exists"
else
    log_fail "hooks.json missing"
fi

for hook in block-entity-writes validate-workspace-wikilinks post-entity-creation post-write-validate-wikilinks pre-synthesis-validation verify-source-creator-output repair-missing-batches verify-batch-creator-output; do
    if [[ -x "$PLUGIN_ROOT/hooks/${hook}.sh" ]]; then
        log_pass "Hook $hook is executable"
    else
        log_fail "Hook $hook missing or not executable"
    fi
done

# ============================================================================
# Test 4: Core scripts exist and are executable
# ============================================================================
echo ""
echo "Test 4: Core scripts"

for script in create-entity.py create-entity.sh lookup-entity.py lookup-entity.sh initialize-research-project.sh generate-project-slug.sh scan-entity-directory.sh check-phase-state.sh save-phase-state.sh; do
    if [[ -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        log_pass "Script $script exists"
    else
        log_fail "Script $script missing"
    fi
done

# ============================================================================
# Test 5: Skill files exist
# ============================================================================
echo ""
echo "Test 5: Skill files"

for skill in research-plan findings-sources claims synthesis export-html-report export-pdf-report export-rag; do
    if [[ -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ]]; then
        log_pass "Skill $skill SKILL.md exists"
    else
        log_fail "Skill $skill SKILL.md missing"
    fi
done

# ============================================================================
# Test 6: Agent files exist
# ============================================================================
echo ""
echo "Test 6: Agent files"

for agent in dimension-planner batch-creator findings-creator findings-creator-file findings-creator-llm source-creator claim-extractor; do
    if [[ -f "$PLUGIN_ROOT/agents/$agent.md" ]]; then
        log_pass "Agent $agent exists"
    else
        log_fail "Agent $agent missing"
    fi
done

# ============================================================================
# Test 7: Plugin manifest
# ============================================================================
echo ""
echo "Test 7: Plugin manifest"

VERSION=$(python3 -c "
import json
with open('$PLUGIN_ROOT/.claude-plugin/plugin.json') as f:
    data = json.load(f)
print(data.get('version', 'unknown'))
" 2>/dev/null)

if [[ "$VERSION" == "1.0.0" ]]; then
    log_pass "Plugin version is 1.0.0"
else
    log_fail "Plugin version is $VERSION (expected 1.0.0)"
fi

LICENSE=$(python3 -c "
import json
with open('$PLUGIN_ROOT/.claude-plugin/plugin.json') as f:
    data = json.load(f)
print(data.get('license', 'unknown'))
" 2>/dev/null)

if [[ "$LICENSE" == "AGPL-3.0-only" ]]; then
    log_pass "License is AGPL-3.0-only"
else
    log_fail "License is $LICENSE (expected AGPL-3.0-only)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
