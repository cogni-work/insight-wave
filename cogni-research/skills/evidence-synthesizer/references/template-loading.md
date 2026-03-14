# Template Loading Patterns

## Overview

Research-type templates provide specialized organization structures for evidence catalogs. Templates are loaded from the research-type directory if available, otherwise generic template is used.

## Template Discovery Process

### Step 1: Read Research Metadata

```bash
METADATA_FILE="${PROJECT_PATH}/.metadata/sprint-log.json"

if [ -f "$METADATA_FILE" ]; then
    # Extract research_type from JSON
    research_type=$(jq -r '.research_type // "generic"' "$METADATA_FILE")
    log_conditional INFO "Research type: $research_type"
else
    research_type="generic"
    log_conditional WARN "Metadata file not found, using generic template"
fi
```

**Fallback:** If metadata missing or research_type field absent, default to "generic"

### Step 2: Locate Template File

```bash
if [ "$research_type" != "generic" ]; then
    # Research-type specific template
    TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/research-types/${research_type}/template-${research_type}-evidence.md"

    if [ -f "$TEMPLATE_PATH" ]; then
        log_conditional INFO "Using research-type template: $research_type"
    else
        log_conditional WARN "Template not found: $TEMPLATE_PATH"
        log_conditional INFO "Falling back to generic template"
        TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/templates/template-evidence.md"
        research_type="generic"
    fi
else
    # Generic template
    TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/templates/template-evidence.md"
fi
```

### Step 3: Load Template Structure

Use Read tool to load complete template:

```markdown
**Read:** `{TEMPLATE_PATH}` to understand:
- Section headings and organization
- Markdown formatting patterns
- Placeholder locations for data insertion
- Template-specific requirements
```

## Research-Type Templates

### action-oriented-radar Template

**Organization Pattern:** Sources grouped by action horizon

```markdown
## Sources by Action Horizon

### Act (0-2 years) - Immediate Implementation
Sources supporting near-term action items
- Technical maturity: High
- Market adoption: Established
- Economic viability: Proven

### Plan (2-5 years) - Strategic Planning
Sources for medium-term initiatives
- Technical maturity: Moderate
- Market adoption: Growing
- Economic viability: Emerging

### Observe (5+ years) - Future Monitoring
Sources for long-term trends
- Technical maturity: Early
- Market adoption: Nascent
- Economic viability: Uncertain
```

**Source Assignment Logic:**
1. Check source frontmatter for horizon tags
2. Match source publication date to time horizon
3. Evaluate technical readiness indicators
4. Group by closest matching horizon

### trend-radar Template

**Organization Pattern:** Gartner Hype Cycle stages

```markdown
## Sources by Technology Lifecycle Stage

### Innovation Trigger
Early breakthrough sources, proof-of-concept demonstrations

### Peak of Inflated Expectations
Hype-cycle peak sources, optimistic projections

### Trough of Disillusionment
Reality-check sources, implementation challenges

### Slope of Enlightenment
Practical application sources, best practices emerging

### Plateau of Productivity
Mature technology sources, established standards
```

**Source Assignment Logic:**
1. Analyze source content for maturity indicators
2. Check for TRL (Technology Readiness Level) tags
3. Match publication sentiment to lifecycle stage
4. Group by content focus area

### lean-canvas Template

**Organization Pattern:** Lean Canvas blocks

```markdown
## Sources by Business Model Component

### Problem Sources
Evidence supporting problem definition

### Customer Segments Sources
Market research and user studies

### Unique Value Proposition Sources
Competitive analysis and differentiation

### Solution Sources
Technical feasibility and implementation

### Channels Sources
Distribution and market access

### Revenue Streams Sources
Monetization and business models

### Cost Structure Sources
Economic analysis and pricing

### Key Metrics Sources
KPI definitions and measurement

### Unfair Advantage Sources
Strategic positioning and moats
```

**Source Assignment Logic:**
1. Tag sources by canvas block relevance
2. Group by primary business model focus
3. Enable multi-block assignment if applicable

### Generic Template

**Organization Pattern:** Reliability tier grouping (default)

```markdown
## Sources by Reliability Tier

### Tier 1: Academic Sources
{academic and peer-reviewed sources}

### Tier 2: Industry & Government Sources
{institutional reports and government publications}

### Tier 3: Professional Sources
{trade publications and expert content}
```

**Always valid:** Used when research_type not specified or template missing

## Template Structure Analysis

### Extract Section Headings

```python
def extract_template_sections(template_content):
    """Parse template to identify section structure"""
    sections = []
    for line in template_content.split('\n'):
        if line.startswith('## '):
            sections.append(line[3:].strip())
        elif line.startswith('### '):
            sections.append(line[4:].strip())
    return sections
```

### Identify Placeholder Patterns

Common placeholders in templates:

```markdown
{source_count}          # Total sources loaded
{citation_count}        # Total citations loaded
{institution_count}     # Total institutions mapped
{tier1_pct}            # Tier 1 percentage
{domain_name}          # Domain organization
{organization_name}    # Institution full name
{title_from_entity}    # Source title
{url_from_entity}      # Source URL
```

### Template Validation

Before using template:
1. Verify all required sections present
2. Check placeholder consistency
3. Validate markdown formatting
4. Ensure anti-hallucination patterns preserved

## Language-Aware Template Selection

When `{{LANGUAGE}}` is not "en":

```bash
# Check for localized template
LOCALIZED_TEMPLATE="${CLAUDE_PLUGIN_ROOT}/references/research-types/${research_type}/template-${research_type}-evidence-${LANGUAGE}.md"

if [ -f "$LOCALIZED_TEMPLATE" ]; then
    TEMPLATE_PATH="$LOCALIZED_TEMPLATE"
    log_conditional INFO "Using localized template: $LANGUAGE"
else
    # Fall back to English template, translate section headings
    log_conditional INFO "No localized template, using English with translated headings"
fi
```

**Section Heading Translation:**
- Tier 1 → Stufe 1 (German)
- Academic → Académique (French)
- Sources → Fuentes (Spanish)

## Template Adherence Validation

### Post-Generation Check

After generating catalog, validate template adherence:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/evidence-synthesizer/scripts/validate-template-adherence.sh" \
    --project-path "${PROJECT_PATH}" \
    --research-type "${research_type}" \
    --document-type "evidence" \
    --document-path "09-citations/README.md" \
    --json
```

**Validation Criteria:**
- All template sections present
- Placeholders replaced with actual data
- Markdown formatting consistent
- Wikilinks properly formatted

**Non-Blocking:** Validation warns but doesn't halt synthesis

## Error Handling

| Scenario | Recovery |
|----------|----------|
| Metadata file missing | Use generic template |
| research_type field missing | Use generic template |
| Template file not found | Fall back to generic |
| Template parsing fails | Use generic with warning |
| Localized template missing | Use English template |

## Example: Complete Template Loading

```bash
# Phase 1.3: Load Research Type Template

# Step 1: Read metadata
METADATA_FILE="${PROJECT_PATH}/.metadata/sprint-log.json"
if [ -f "$METADATA_FILE" ]; then
    research_type=$(jq -r '.research_type // "generic"' "$METADATA_FILE")
else
    research_type="generic"
fi
log_conditional INFO "Research type detected: $research_type"

# Step 2: Locate template
if [ "$research_type" != "generic" ]; then
    TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/research-types/${research_type}/template-${research_type}-evidence.md"
    if [ ! -f "$TEMPLATE_PATH" ]; then
        log_conditional WARN "Template not found, falling back to generic"
        TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/templates/template-evidence.md"
        research_type="generic"
    fi
else
    TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/references/templates/template-evidence.md"
fi

# Step 3: Load template
# Use Read tool: $TEMPLATE_PATH
# Parse sections and placeholders
log_conditional INFO "Template loaded successfully: $(basename $TEMPLATE_PATH)"
log_metric "template_type" "$research_type" "string"
```
