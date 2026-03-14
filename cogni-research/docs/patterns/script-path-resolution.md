# Agent Pattern: Script Path Resolution

## Overview

This document defines the standard pattern for resolving script, reference, and template file paths within deep-research sub-agents. All agents must use the `CLAUDE_PLUGIN_ROOT` environment variable to construct portable, maintainable paths.

## Rationale

### Problems with Hardcoded Paths

**Before (❌ Don't do this)**:
```bash
# Hardcoded absolute path - breaks on different machines
SKILL_BASE_DIR="/Users/stephandehaas/GitHub/dev-cogni-research/cogni-research/skills/deeper-research-1"
DIMENSION_TEMPLATE="${SKILL_BASE_DIR}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
```

**Problems**:
- ❌ Not portable across different environments
- ❌ Breaks when repository is cloned to different location
- ❌ Hard to maintain when repository structure changes
- ❌ Username-specific paths won't work for other users
- ❌ CI/CD environments will fail

### Benefits of Standard Pattern

**After (✅ Standard Pattern)**:
```bash
# Validate environment
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set. Please configure environment."}\n'
  exit 1
fi

# CLAUDE_PLUGIN_ROOT points directly to the plugin directory
# For skills within the plugin:
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"

# Construct specific paths
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
```

**Benefits**:
- ✅ Portable across all environments
- ✅ Single source of truth for repository location
- ✅ Clear error messages when environment not configured
- ✅ Easy to test and validate
- ✅ Consistent pattern across all agents

---

## Standard Pattern Template

### Complete Template

Copy this template into every agent file that needs script or reference access:

```bash
#!/usr/bin/env bash
set -euo pipefail

#===============================================================================
# Environment Validation
#===============================================================================

# Validate CLAUDE_PLUGIN_ROOT is set
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set. Please configure: export CLAUDE_PLUGIN_ROOT=/path/to/cogni-research"}\n' >&2
  exit 1
fi

#===============================================================================
# Path Configuration
#===============================================================================

# CLAUDE_PLUGIN_ROOT points directly to the plugin directory
# Define skill base for nested skills
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"

# Define script paths (if needed) - scripts at plugin root level
readonly SCRIPT_GENERATE_SLUG="${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh"
readonly SCRIPT_CREATE_ENTITY="${SKILL_BASE}/scripts/create-entity.sh"
readonly SCRIPT_VALIDATE_METADATA="${SKILL_BASE}/scripts/validate-source-metadata.sh"

# Define reference paths (if needed)
readonly SCHEMA_DIR="${SKILL_BASE}/references/schemas"
readonly TEMPLATE_DIR="${SKILL_BASE}/references/templates"

# Define dynamic reference paths (if needed)
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
readonly QUERY_SCHEMA="${SCHEMA_DIR}/query-schema.json"

#===============================================================================
# Path Validation (Optional but Recommended)
#===============================================================================

# Validate critical paths exist (fail fast if misconfigured)
if [ ! -f "${SCRIPT_CREATE_ENTITY}" ]; then
  printf '{"success": false, "error": "Script not found: %s. Please verify CLAUDE_PLUGIN_ROOT is correct."}\n' "${SCRIPT_CREATE_ENTITY}" >&2
  exit 1
fi

# Your agent logic here...
```

### Minimal Template (No Scripts)

For agents that only need reference files:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate environment
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}\n' >&2
  exit 1
fi

# Define base paths
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"

# Define reference paths
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"

# Your agent logic here...
```

---

## Usage Patterns

### Pattern 1: Script Resolution

When your agent needs to call utility scripts:

```bash
# Define script paths
readonly SCRIPT_GENERATE_SLUG="${SKILL_BASE}/scripts/generate-semantic-slug.sh"
readonly SCRIPT_CREATE_ENTITY="${SKILL_BASE}/scripts/create-entity.sh"

# Call scripts with absolute path
source_slug=$(bash "${SCRIPT_GENERATE_SLUG}" --title "${source_title}" --content-key "${source_title}" --json | jq -r '.data.semantic_uuid')
result=$(bash "${SCRIPT_CREATE_ENTITY}" \
  --type "source" \
  --slug "${source_slug}" \
  --project-path "${PROJECT_PATH}")
```

**Benefits**:
- Scripts always found regardless of current working directory
- Clear error if script doesn't exist
- Easy to grep for script usage across agents

### Pattern 2: Reference File Resolution

When your agent needs to read templates, schemas, or reference data:

```bash
# Define reference paths
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
readonly SOURCE_SCHEMA="${SKILL_BASE}/references/schemas/source-metadata-schema.json"

# Read reference files
if [ ! -f "${DIMENSION_TEMPLATE}" ]; then
  printf '{"success": false, "error": "Dimension template not found for research type: %s"}\n' "${RESEARCH_TYPE}" >&2
  exit 1
fi

dimension_template=$(cat "${DIMENSION_TEMPLATE}")
```

**Benefits**:
- Clear error messages with specific file paths
- Easy to validate files exist before processing
- Supports dynamic path construction (e.g., by research type)

### Pattern 3: Dynamic Path Construction

When paths depend on runtime variables:

```bash
# Dynamic path based on entity type
readonly ENTITY_TEMPLATE="${SKILL_BASE}/references/templates/${ENTITY_TYPE}-template.md"
readonly ENTITY_SCHEMA="${SKILL_BASE}/references/schemas/${ENTITY_TYPE}-schema.json"

# Dynamic path based on research type
readonly TYPE_DIMENSIONS="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
readonly TYPE_QUERIES="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/query-patterns.json"

# Validate before use
if [ ! -f "${ENTITY_TEMPLATE}" ]; then
  printf '{"success": false, "error": "Template not found for entity type: %s"}\n' "${ENTITY_TYPE}" >&2
  exit 1
fi
```

**Benefits**:
- Flexible path construction
- Runtime validation
- Clear error messages include the specific missing file

---

## Environment Setup

### Setting CLAUDE_PLUGIN_ROOT

When running through Claude Code, `CLAUDE_PLUGIN_ROOT` is automatically set to the plugin's root directory (either the cached location or the development location).

For manual testing during development:

#### Temporary (Current Session)

```bash
# Point directly to the plugin directory
export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/dev/cogni-research"
```

#### Persistent (Recommended)

Add to shell profile (`.zshrc`, `.bashrc`, or `.bash_profile`):

```bash
# For zsh users
echo 'export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/dev/cogni-research"' >> ~/.zshrc
source ~/.zshrc

# For bash users
echo 'export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/dev/cogni-research"' >> ~/.bashrc
source ~/.bashrc
```

#### Verification

```bash
# Check if set
echo $CLAUDE_PLUGIN_ROOT
# Should output: /Users/username/GitHub/dev/cogni-research

# Verify path exists
ls -la "$CLAUDE_PLUGIN_ROOT/scripts"
# Should show the plugin's scripts directory
```

---

## Error Handling

### Error Message Standards

All environment-related errors should follow this format:

```bash
# Missing CLAUDE_PLUGIN_ROOT
printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set. Please configure: export CLAUDE_PLUGIN_ROOT=/path/to/cogni-research"}\n' >&2

# Script not found
printf '{"success": false, "error": "Script not found: %s. Please verify CLAUDE_PLUGIN_ROOT points to cogni-research root."}\n' "${SCRIPT_PATH}" >&2

# Reference file not found
printf '{"success": false, "error": "Reference file not found: %s. Available types: %s"}\n' "${REFERENCE_PATH}" "comprehensive, domain-specific" >&2

# Invalid research type
printf '{"success": false, "error": "Dimension template not found for research type: %s. Available types: comprehensive, domain-specific, discovery"}\n' "${RESEARCH_TYPE}" >&2
```

**Error Message Principles**:
1. Always output JSON format for machine parsing
2. Include actionable resolution steps
3. Show the specific path that failed
4. Suggest valid alternatives when applicable
5. Write to stderr (`>&2`)

### Error Handling Best Practices

```bash
# Pattern 1: Fail fast with environment validation
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}\n' >&2
  exit 1
fi

# Pattern 2: Validate critical paths before use
if [ ! -f "${SCRIPT_CREATE_ENTITY}" ]; then
  printf '{"success": false, "error": "Script not found: %s"}\n' "${SCRIPT_CREATE_ENTITY}" >&2
  exit 1
fi

# Pattern 3: Provide helpful context in errors
if [ ! -f "${DIMENSION_TEMPLATE}" ]; then
  available_types=$(ls -1 "${SKILL_BASE}/references/research-types" | tr '\n' ', ')
  printf '{"success": false, "error": "Template not found for: %s. Available: %s"}\n' \
    "${RESEARCH_TYPE}" "${available_types}" >&2
  exit 1
fi

# Pattern 4: Defensive checks for optional files
if [ -f "${OPTIONAL_CONFIG}" ]; then
  source "${OPTIONAL_CONFIG}"
else
  # Use defaults
  echo "Using default configuration (no custom config found)"
fi
```

---

## Testing Your Pattern Implementation

### Test 1: Environment Not Set

```bash
# Clear environment
unset CLAUDE_PLUGIN_ROOT

# Run agent (should fail with clear message)
result=$(bash dimension-planner.md --project-path /test 2>&1)

# Expected output:
# {"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set..."}
```

### Test 2: Environment Set Correctly

```bash
# Set environment
export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/cogni-research"

# Run agent (should succeed)
result=$(bash dimension-planner.md --project-path /test/project 2>&1)

# Expected: Success output with no environment errors
```

### Test 3: Invalid Environment Path

```bash
# Set to non-existent path
export CLAUDE_PLUGIN_ROOT="/nonexistent/path"

# Run agent (should fail with file not found)
result=$(bash dimension-planner.md --project-path /test 2>&1)

# Expected output includes:
# "Script not found" or "No such file or directory"
```

### Test 4: Script Path Resolution

```bash
# Verify script paths are constructed correctly
export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/cogni-research"

# Check constructed path exists
SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
test -f "${SKILL_BASE}/scripts/create-entity.sh"
echo $?  # Should output 0 (success)
```

---

## Migration from Hardcoded Paths

### Step-by-Step Migration

**Step 1: Identify hardcoded paths**
```bash
# Search for hardcoded paths in your agent
grep -n '"/Users/' your-agent.md
grep -n 'SKILL_BASE_DIR="/' your-agent.md
```

**Step 2: Add environment validation**
```bash
# Add at the beginning of your agent's bash section
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}\n' >&2
  exit 1
fi
```

**Step 3: Replace hardcoded base paths**
```bash
# Before:
SKILL_BASE_DIR="/Users/username/GitHub/dev-cogni-research/cogni-research/skills/deeper-research"

# After:
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
```

**Step 4: Update all path references**
```bash
# Before:
DIMENSION_TEMPLATE="${SKILL_BASE_DIR}/references/research-types/${RESEARCH_TYPE}/dimensions.md"

# After:
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions.md"
```

**Step 5: Test the migration**
```bash
# Test with environment set
export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/cogni-research"
bash your-agent.md --project-path /test/project

# Test without environment (should fail gracefully)
unset CLAUDE_PLUGIN_ROOT
bash your-agent.md --project-path /test/project
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Missing Environment Validation

```bash
# Bad: No validation
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"

# Good: Validate first
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}\n' >&2
  exit 1
fi
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
```

### ❌ Mistake 2: Using Relative Paths

```bash
# Bad: Relative path (depends on working directory)
SCRIPT_PATH="../../scripts/create-entity.sh"

# Good: Absolute path from CLAUDE_PLUGIN_ROOT
readonly SCRIPT_PATH="${SKILL_BASE}/scripts/create-entity.sh"
```

### ❌ Mistake 3: Not Using readonly

```bash
# Bad: Mutable path variable
SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"

# Good: Immutable constant
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
```

### ❌ Mistake 4: Cryptic Error Messages

```bash
# Bad: Unhelpful error
echo "Error: File not found"

# Good: Specific error with path and resolution
printf '{"success": false, "error": "Script not found: %s. Verify CLAUDE_PLUGIN_ROOT=%s"}\n' \
  "${SCRIPT_PATH}" "${CLAUDE_PLUGIN_ROOT}" >&2
```

### ❌ Mistake 5: Mixing Path Patterns

```bash
# Bad: Inconsistent patterns in same agent
SCRIPT_ONE="${CLAUDE_PLUGIN_ROOT}/scripts/one.sh"
SCRIPT_TWO="/Users/hardcoded/path/scripts/two.sh"

# Good: Consistent pattern
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
readonly SCRIPT_ONE="${SKILL_BASE}/scripts/one.sh"
readonly SCRIPT_TWO="${SKILL_BASE}/scripts/two.sh"
```

---

## Quick Reference

### Standard Variables

```bash
# Always define these
CLAUDE_PLUGIN_ROOT        # Root of plugin directory (from environment, set by Claude Code)
SKILL_BASE                # Root of skill within plugin (skills/deeper-research-1 or skills/deeper-synthesis)
```

### Standard Directories

```bash
${SKILL_BASE}/scripts/                 # Utility scripts
${SKILL_BASE}/references/schemas/      # JSON schemas
${SKILL_BASE}/references/templates/    # File templates
${SKILL_BASE}/references/research-types/  # Research type configs
```

### Validation Checklist

- [ ] `CLAUDE_PLUGIN_ROOT` validated at start
- [ ] All paths use `readonly` declarations
- [ ] No hardcoded absolute paths
- [ ] Clear error messages with JSON format
- [ ] Critical paths validated before use
- [ ] Errors written to stderr (`>&2`)
- [ ] Exit codes: 0 = success, 1 = error

---

## Examples from Real Agents

### Example 1: dimension-planner.md (Before & After)

**Before (Hardcoded)**:
```bash
SKILL_BASE_DIR="/Users/stephandehaas/GitHub/dev-cogni-research/cogni-research/skills/deeper-research-1"
DIMENSION_TEMPLATE="${SKILL_BASE_DIR}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"
```

**After (Standard Pattern)**:
```bash
# Validate environment
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}\n' >&2
  exit 1
fi

# Define base paths
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/deeper-research-1"
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"

# Validate template exists
if [ ! -f "${DIMENSION_TEMPLATE}" ]; then
  printf '{"success": false, "error": "Dimension template not found: %s"}\n' "${DIMENSION_TEMPLATE}" >&2
  exit 1
fi
```

### Example 2: publisher-generator.md (Good Example)

**Already following standard pattern**:
```bash
# Environment validation would be added here

# Script resolution (already good)
readonly SCRIPT_GENERATE_SLUG="${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh"
readonly SCRIPT_CREATE_ENTITY="${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh"

# Use with confidence
slug=$(bash "${SCRIPT_GENERATE_SLUG}" --title "${title}" --content-key "${title}" --json | jq -r '.data.semantic_uuid')
```

---

## Troubleshooting

### Problem: "CLAUDE_PLUGIN_ROOT not set" error

**Solution**:
```bash
# Check if variable is set
echo $CLAUDE_PLUGIN_ROOT

# If empty, set it
export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/cogni-research"

# Add to shell profile for persistence
echo 'export CLAUDE_PLUGIN_ROOT="/Users/username/GitHub/cogni-research"' >> ~/.zshrc
source ~/.zshrc
```

### Problem: "Script not found" even with CLAUDE_PLUGIN_ROOT set

**Solution**:
```bash
# Verify CLAUDE_PLUGIN_ROOT points to the plugin directory
ls -la "$CLAUDE_PLUGIN_ROOT/scripts"

# Check constructed path
echo "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh"
ls -la "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh"

# If file exists but agent can't find it, check for typos in agent code
```

### Problem: "Permission denied" when running scripts

**Solution**:
```bash
# Make scripts executable
chmod +x "${CLAUDE_PLUGIN_ROOT}/scripts/"*.sh

# Or run with bash explicitly (recommended)
bash "${SCRIPT_PATH}" --args
```

### Problem: Paths work locally but fail in CI/CD

**Solution**:
```bash
# Ensure CI/CD environment has CLAUDE_PLUGIN_ROOT set
# Example in GitHub Actions:
env:
  CLAUDE_PLUGIN_ROOT: ${{ github.workspace }}

# Or in script:
export CLAUDE_PLUGIN_ROOT="${GITHUB_WORKSPACE}"
```

---

## Additional Resources

- **Deep Research README**: [cogni-research/README.md](../../README.md)
- **Debugging Guide**: [debugging-guide.md](../guides/debugging-guide.md)

---

## Pattern Version

**Version**: 1.0
**Last Updated**: 2025-11-07
**Sprint**: 131
**Status**: Active Standard
