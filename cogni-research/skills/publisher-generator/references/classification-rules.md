# Publisher Classification Rules

## Organization Type Classification

When creating organization publishers, classify them into one of 10 categories based on domain analysis and content patterns.

### Classification Table

| Type | Domain Indicators | Example Domains |
|------|-------------------|-----------------|
| `multilateral_development_bank` | worldbank, imf, adb, iadb | worldbank.org, imf.org |
| `government_agency` | .gov, .eu, oecd, europa | treasury.gov, oecd.org |
| `ngo` | oxfam, amnesty, greenpeace | oxfam.org, amnesty.org |
| `industry_association` | iso, ieee, industry associations | iso.org, ieee.org |
| `academic_institution` | .edu, university, research institute | mit.edu, stanford.edu |
| `financial_institution` | bank, jpmorgan, goldman | jpmorgan.com |
| `news_organization` | nytimes, reuters, bbc, media | nytimes.com, reuters.com |
| `international_organization` | un, who, wto, global bodies | un.org, who.int |
| `private_company` | microsoft, shell, corporations | microsoft.com |
| `think_tank` | brookings, rand, policy research | brookings.edu |

### Classification Algorithm

```bash
classify_organization_type() {
  local domain="$1"

  # Extract TLD and domain name
  tld="${domain##*.}"
  domain_name="${domain%.*}"

  # Classification rules (priority order)
  case "$domain" in
    *worldbank*|*imf.org*|*adb.org*|*iadb.org*)
      echo "multilateral_development_bank" ;;
    *.gov*|*oecd.org*|*europa.eu*)
      echo "government_agency" ;;
    *oxfam*|*amnesty*|*greenpeace*)
      echo "ngo" ;;
    *iso.org*|*ieee.org*)
      echo "industry_association" ;;
    *.edu*|*university*|*institute*)
      echo "academic_institution" ;;
    *bank*|*jpmorgan*|*goldman*|*financial*)
      echo "financial_institution" ;;
    *nytimes*|*reuters*|*bbc*|*news*|*media*)
      echo "news_organization" ;;
    *un.org*|*who.int*|*wto.org*)
      echo "international_organization" ;;
    *brookings*|*rand.org*|*think*)
      echo "think_tank" ;;
    *)
      echo "private_company" ;;
  esac
}
```

## Individual vs Organization Detection

### Detection Priority

1. **Individual Detection (Priority 1):**
   - `authors` field present and non-empty
   - Byline patterns: "By {name}", "Author: {name}"
   - Personal name patterns: "{FirstName} {LastName}"
   - NOT generic: "Staff", "Editorial Board"

2. **Organization Detection (Priority 2):**
   - NO `authors` field OR empty
   - Domain-based attribution present
   - Organizational header in content
   - Generic author field: "Staff", "Editorial Board"

### Extraction Examples

**Example 1: Individual Publisher**

```yaml
# Source entity
---
domain: climatebonds.net
authors: Dr. Jane Smith, John Doe
---

# Creates two individual publishers:
# → publisher-dr-jane-smith-{hash}.md
# → publisher-john-doe-{hash}.md
```

**Example 2: Organization Publisher**

```yaml
# Source entity
---
domain: climatebonds.net
authors: Staff
---

# Creates one organization publisher:
# → publisher-climatebonds-{hash}.md
# With organization_type: ngo
```

## Organization Name Extraction

Extract organization name from domain using direct string parsing (NOT LLM-based extraction):

```bash
extract_org_name_from_domain() {
  local domain="$1"

  # Strip protocol and www prefix
  domain="${domain#http://}"
  domain="${domain#https://}"
  domain="${domain#www.}"

  # Extract primary domain name (first component before dot)
  local org_name
  org_name=$(echo "$domain" | cut -d'.' -f1)

  # Capitalize first letter only
  org_name="$(echo "${org_name:0:1}" | tr '[:lower:]' '[:upper:]')${org_name:1}"

  echo "$org_name"
}
```

**Example:**
- Input: `climatebonds.net`
- Output: `Climatebonds`

## Type-Specific Tags

### Individual Publishers

```yaml
tags:
  - publisher
  - publisher-type/individual
```

### Organization Publishers

```yaml
tags:
  - publisher
  - publisher-type/organization
  - organization-type/{classification}
```

**Example for NGO:**
```yaml
tags:
  - publisher
  - publisher-type/organization
  - organization-type/ngo
```

## Anti-Hallucination Rules

**NEVER:**
- Fabricate publisher names from thin air
- Guess organization types without domain evidence
- Create publishers without source attribution
- Create publishers for sources without valid domain fields
- Use LLM-based extraction for organization names (causes OCR-like corruption)

**ALWAYS:**
- Use create-entity.sh for deduplication
- Validate source metadata before extraction
- Use direct string parsing for organization name extraction
- Log detection reasoning to stderr (not JSON response)
