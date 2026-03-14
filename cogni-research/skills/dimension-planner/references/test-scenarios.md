# Test Scenarios

This reference documents comprehensive edge case testing and validation scenarios for the dimension-planner skill.

## When to Load This Reference

Read this file when:
- Implementing validation logic for dimension-planner
- Testing the skill against edge cases
- Debugging unexpected behavior or failures
- Creating test suites for quality assurance

## Input Validation Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty question file | Return error: "Question file appears empty" |
| Invalid YAML frontmatter | Return error: "YAML parsing failed" |
| Missing frontmatter | Default to generic mode, extract question from content |
| No research_type field | Default to `research_type="generic"`, use domain-based mode |
| research_type="nonexistent" | Return error: "Template not found: nonexistent" |
| Relative file path provided | Convert to absolute, validate project structure |
| Directory provided instead of file | Return error: "Not a file" |

## Dimension Generation Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| Only 1 dimension generated | Return error: "Invalid dimension count: 1" |
| 9+ dimensions generated | Return error: "Invalid dimension count: 9" |
| Duplicate dimension slugs | Return error: "Duplicate dimension slug detected" |
| Unicode in dimension names | Translate to English slug, preserve in display_name |
| Very long dimension names (>100 chars) | Truncate slug to 50 chars, keep full display_name |

## Question Generation Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| Only 5 questions total | Return error: "Invalid question count: 5" |
| 41+ questions total | Return error: "Invalid question count: 41" |
| All FINER scores exactly 10 | Average = 10.0, return error (must be ≥11.0) |
| All FINER scores exactly 11 | Average = 11.0, pass validation |
| One question scores 9 | Log warning, attempt reformulation, retry |
| Unicode in questions | Preserve Unicode, detect language, set frontmatter |

## MECE Validation Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| 25% overlap between dimensions | Return error: "MECE validation failed" |
| 19% overlap between dimensions | Pass validation |
| Circular dimension dependencies | Return error: "Dimensions are not independent" |
| Coverage gap (missing question element) | Return error: "Incomplete coverage detected" |

## Mode-Specific Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| Generic research_type | Use domain-based mode |
| Lean-canvas with template | Use research-type-specific mode, parse template |
| Lean-canvas without template | Return error: "Template not found: lean-canvas" |
| Template with 1 dimension | Return error: "Template dimension count out of range" |

## Dependency Tests

| Scenario | Expected Behavior |
|----------|-------------------|
| jq not installed | Return error: "jq command not found" |
| bc not installed | Return error: "bc command not found" |
| CLAUDE_PLUGIN_ROOT not set | Return error: "CLAUDE_PLUGIN_ROOT not set" |
| Enhanced logging script missing | Return error: "Failed to source enhanced-logging.sh" |
