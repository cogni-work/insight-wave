## Environment Validation

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 2 (CLAUDE_PLUGIN_ROOT validation) and Section 3 (Logging initialization)


## Question Loading

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 1 (Parameter parsing)

### Detect Research Type

```bash
RESEARCH_TYPE=$(grep -E "^research_type:" "$QUESTION_FILE" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'" | head -1)

# Default to generic if not specified
if [ -z "$RESEARCH_TYPE" ] || [ "$RESEARCH_TYPE" = "null" ]; then
  RESEARCH_TYPE="generic"
fi

log_conditional INFO "Research type: $RESEARCH_TYPE"
```

### Select Dimension Template

```bash
readonly SKILL_BASE="${CLAUDE_PLUGIN_ROOT}/skills/dimension-planner"
readonly DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/${RESEARCH_TYPE}/dimensions-${RESEARCH_TYPE}.md"

if [ "$RESEARCH_TYPE" != "generic" ] && [ -f "$DIMENSION_TEMPLATE" ]; then
  log_conditional INFO "Loading template: $DIMENSION_TEMPLATE"
  DIMENSIONS_MODE="research-type-specific"
else
  DIMENSIONS_MODE="domain-based"
fi

log_conditional INFO "Mode: $DIMENSIONS_MODE"
log_phase "Phase 1" "Complete"
```



## Variable Assignment Examples

### Phase 1.2 - Both Modes (Research Type Detection)

```bash
# After extracting RESEARCH_TYPE from frontmatter
RESEARCH_TYPE=$(grep -E "^research_type:" "$QUESTION_FILE" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'" | head -1)

if [ -z "$RESEARCH_TYPE" ] || [ "$RESEARCH_TYPE" = "null" ]; then
  RESEARCH_TYPE="generic"
fi

log_conditional INFO "Research type: $RESEARCH_TYPE"
log_metric "research_type" "$RESEARCH_TYPE" "string"
```

### Phase 1.3 - Both Modes (Mode Selection)

```bash
# After determining DIMENSIONS_MODE
log_conditional INFO "Mode: $DIMENSIONS_MODE"
log_metric "dimensions_mode" "$DIMENSIONS_MODE" "string"
```


## Filename Generation

### Dimension Filenames

Use English kebab-case slugs (NOT localized names):

```bash
# "Technical Feasibility" → technical-feasibility.md
# "Wirtschaftliche Analyse" → economic-analysis.md (NOT wirtschaftliche-analyse.md)
```

### Question IDs

Use dimension slug prefix:

```bash
# Economic → economic-q1, economic-q2
# Technical → tech-q1, tech-q2
# Problem-Solution → problem-solution-q1
```


## Dimension Purpose

Diese Dimension untersucht die Zielkunden, ihre Bedürfnisse, Verhaltensweisen und Kaufmuster...


## Key Topics

Kundensegmente, Bedürfnisse und Schmerzpunkte, Käuferpersönlichkeiten, Marktgröße...
```

### Technical Invariants (Always English)

Even in multilingual projects, these elements must remain English:

```bash
# Phase 5.1: Dimension entity frontmatter (always English keys)
---
dc:identifier: "customer-analysis"          # English
entity_type: "dimension"                    # English
display_name: "Kundenanalyse"              # Localized (German in this case)
language: "de"                             # Language code (ISO 639-1)
rationale: |                               # Content in target language
  Diese Dimension untersucht...
research_focus: |                          # Content in target language
  Kundensegmente, Bedürfnisse...
---

# Wikilink targets (always English)
- [[01-research-dimensions/data/dimension-customer-analysis]]  # NOT kundenanalyse
```

**Phase 5.2: Question entities (same pattern)**
```bash
---
dc:identifier: "customer-analysis-q1"      # English
entity_type: "refined-question"            # English
display_name: "Wer sind unsere primären Kundensegmente?"  # Localized
language: "de"                             # Language code
dimension: "[[01-research-dimensions/data/dimension-customer-analysis]]"  # English wikilink
---
```


