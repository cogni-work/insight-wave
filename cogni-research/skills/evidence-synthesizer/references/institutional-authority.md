# Institutional Authority Mapping

## Overview

Map research institutions into authority categories to understand the diversity and credibility of the evidence base. Categories reflect organizational mandate and expertise domain.

## Authority Categories

### Academic Institutions

**Definition:** Organizations primarily focused on research and education

**Identification Patterns:**
- Institution type contains: "university", "research", "institute", "college"
- Mandate includes: education, research, scholarly
- Examples: MIT, Stanford, Oxford, Max Planck Institute

**Authority Strength:** Foundational research, methodological rigor, peer review standards

### Multilateral Organizations

**Definition:** International bodies with cross-border mandates

**Identification Patterns:**
- Institution type contains: "multilateral", "international", "intergovernmental"
- Organization names: World Bank, IMF, OECD, UN agencies, WHO, WTO
- Regional development banks: ADB, EBRD, AfDB

**Authority Strength:** Global perspective, policy influence, extensive data collection

### Government Agencies

**Definition:** National/regional regulatory and policy bodies

**Identification Patterns:**
- Institution type contains: "government", "agency", "regulatory", "ministry"
- Examples: EPA, DOE, FDA, NIST, national statistics offices
- Includes: Standards bodies, regulatory authorities

**Authority Strength:** Regulatory trend, compliance expertise, official statistics

### Industry Associations

**Definition:** Trade groups and professional bodies

**Identification Patterns:**
- Institution type contains: "association", "industry", "trade", "professional"
- Examples: IEEE, ACM, AMA, industry consortiums
- Includes: Trade associations, professional societies

**Authority Strength:** Practitioner perspective, industry standards, market knowledge

## Classification Logic

### From Institution Entity Frontmatter

```yaml
# Example institution entity
---
name: "World Economic Forum"
mandate: "Improve state of the world through public-private cooperation"
type: "multilateral/intergovernmental"
expertise: ["economics", "global governance", "technology"]
---
```

**Classification Algorithm:**

```python
def classify_institution(institution_type):
    type_lower = institution_type.lower()

    # Priority order (most specific first)
    if any(kw in type_lower for kw in ["university", "research", "institute", "college", "academic"]):
        return "academic"
    elif any(kw in type_lower for kw in ["multilateral", "international", "intergovernmental", "un ", "world bank", "imf", "oecd"]):
        return "multilateral"
    elif any(kw in type_lower for kw in ["government", "agency", "regulatory", "ministry", "federal", "national"]):
        return "government"
    elif any(kw in type_lower for kw in ["association", "industry", "trade", "professional", "consortium"]):
        return "industry"
    else:
        return "other"
```

**Bash Implementation:**

```bash
classify_institution() {
    local type="$1"
    local type_lower=$(echo "$type" | tr '[:upper:]' '[:lower:]')

    if echo "$type_lower" | grep -qE "university|research|institute|college|academic"; then
        echo "academic"
    elif echo "$type_lower" | grep -qE "multilateral|international|intergovernmental"; then
        echo "multilateral"
    elif echo "$type_lower" | grep -qE "government|agency|regulatory|ministry"; then
        echo "government"
    elif echo "$type_lower" | grep -qE "association|industry|trade|professional"; then
        echo "industry"
    else
        echo "other"
    fi
}
```

## Authority Distribution Analysis

### Count Institutions Per Category

```bash
# Initialize counters
academic_count=0
multilateral_count=0
government_count=0
industry_count=0
other_count=0

# Classify each institution
for institution in "${INSTITUTIONS[@]}"; do
    category=$(classify_institution "$institution_type")
    case "$category" in
        academic) academic_count=$((academic_count + 1)) ;;
        multilateral) multilateral_count=$((multilateral_count + 1)) ;;
        government) government_count=$((government_count + 1)) ;;
        industry) industry_count=$((industry_count + 1)) ;;
        *) other_count=$((other_count + 1)) ;;
    esac
done
```

### Generate Representative Lists

For each category, compile institution names:

```bash
# Build comma-separated list
academic_institutions=""
for inst in "${ACADEMIC_LIST[@]}"; do
    if [ -n "$academic_institutions" ]; then
        academic_institutions="${academic_institutions}, "
    fi
    academic_institutions="${academic_institutions}${inst}"
done
```

## Markdown Output Structure

```markdown
## Institutional Authority

### Academic Institutions ({count} institutions)
{comma-separated list of institution names}

Provides: Foundational research, methodological rigor, peer-reviewed trends

### Multilateral Organizations ({count} institutions)
{comma-separated list of institution names}

Provides: Global perspective, cross-border data, policy coordination

### Government Agencies ({count} institutions)
{comma-separated list of institution names}

Provides: Regulatory compliance, official statistics, policy enforcement

### Industry Associations ({count} institutions)
{comma-separated list of institution names}

Provides: Practitioner expertise, market standards, industry benchmarks
```

## Anti-Hallucination Requirements

**CRITICAL: Extract institution data only from loaded entity files**

- Institution names must come from entity files
- Types must be explicitly stated in frontmatter
- Do NOT infer institution type from name alone
- Do NOT fabricate institutional relationships

**Verification:**
- All institution names exist in 12-institutions/ directory
- All types extracted from actual frontmatter
- No assumptions about missing type fields

## Handling Edge Cases

### Missing Institution Directory

```bash
if [ ! -d "${PROJECT_PATH}/12-institutions" ]; then
    log_conditional INFO "No institutions directory found"
    # Skip institutional authority section in catalog
    # Return counts as 0
fi
```

### Missing Type Field

```bash
if [ -z "$institution_type" ]; then
    log_conditional WARN "Institution $inst_name missing type field"
    # Classify as "other" or skip
fi
```

### Ambiguous Classification

When type contains multiple keywords (e.g., "government research institute"):
- Use priority order: academic > multilateral > government > industry
- Academic takes precedence (research focus)

## Quality Indicators

**Balanced Authority:**
- 25-35% academic (research foundation)
- 15-25% multilateral (global context)
- 25-35% government (policy trend)
- 15-25% industry (practical perspective)

**Skewed Authority:**
- >50% single category → May lack perspective diversity
- <10% academic → Limited peer-reviewed foundation
- <10% government → May miss regulatory considerations

## Example: Complete Authority Mapping

**Input:** 84 institution entities

**Processing:**
1. Extract type from each institution frontmatter
2. Classify using priority algorithm
3. Count: Academic=32, Multilateral=18, Government=21, Industry=13
4. Generate representative lists
5. Format output section

**Output:**
```markdown
## Institutional Authority

### Academic Institutions (32 institutions)
MIT, Stanford University, Oxford Research Institute, Max Planck Society...

### Multilateral Organizations (18 institutions)
World Bank, IMF, OECD, UN Environment Programme, WHO...

### Government Agencies (21 institutions)
U.S. EPA, DOE, European Commission, UK Health Security Agency...

### Industry Associations (13 institutions)
IEEE, Climate Bonds Initiative, Solar Energy Industries Association...
```
