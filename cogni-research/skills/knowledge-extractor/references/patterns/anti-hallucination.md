# Anti-Hallucination Patterns

## Core Principles

**CRITICAL:** Knowledge extraction must be grounded exclusively in finding content.

### Rule 1: No External Knowledge

- NEVER add definitions from outside the findings
- NEVER supplement with general knowledge
- NEVER assume relationships not stated in findings

### Rule 2: No Fabrication

- NEVER invent terms not present in findings
- NEVER generate UUIDs or file references that don't exist
- NEVER create wikilinks to non-existent entities

### Rule 3: Source Attribution

- ALWAYS quote or paraphrase finding content
- ALWAYS trace definitions to specific findings
- ALWAYS verify wikilinks resolve to existing files

## Verification Checkpoints

### Before Creating Concept Entity

```bash
# Verify term exists in findings
if ! grep -riq "$term" "${PROJECT_PATH}/${FINDINGS_DIR}/data/"; then
  log_conditional ERROR "Term '$term' not found in findings - HALLUCINATION RISK"
  continue
fi
```

### Before Writing Wikilink

```bash
# Verify target file exists
target_file="${PROJECT_PATH}/${wikilink_path}.md"
if [ ! -f "$target_file" ]; then
  log_conditional ERROR "Wikilink target does not exist: $target_file"
  continue
fi
```

### Definition Grounding

When synthesizing definitions:

1. Locate exact passages mentioning the term
2. Quote or closely paraphrase those passages
3. Do NOT add explanatory context from general knowledge
4. If insufficient context in findings, reduce confidence score

## Anti-Patterns to Avoid

| Anti-Pattern | Example | Correct Approach |
|--------------|---------|------------------|
| External definition | "RAG is a technique developed by Facebook AI Research..." | Use only what findings say about RAG |
| Assumed relationship | "This is related to transformers because..." | Only state relationships explicit in findings |
| Generated UUID | `[[${FINDINGS_DIR}/data/finding-example-12345678]]` | Use actual UUIDs from existing files |
| Supplemented context | "As is well known in the field..." | Omit if not in findings |

## Confidence Reduction Triggers

Reduce confidence score when:

- Term mentioned but not defined in findings
- Conflicting descriptions across findings
- Ambiguous usage context
- Single brief mention only

## Validation Before Output

```bash
# Final anti-hallucination check
validate_entity_grounding() {
  local entity_file="$1"

  # Check all wikilinks resolve
  while IFS= read -r link; do
    target=$(echo "$link" | sed 's/\[\[\([^]|]*\).*/\1/')
    if [ ! -f "${PROJECT_PATH}/${target}.md" ]; then
      return 1
    fi
  done < <(grep -o '\[\[[^]]*\]\]' "$entity_file")

  return 0
}
```
