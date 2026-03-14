# APA Formatting

## Purpose

This reference provides comprehensive APA 7th edition citation formatting rules with multi-language support (English and German). It ensures consistent, standards-compliant citation generation while preventing common YAML artifacts and data integrity issues.

## APA 7th Edition Rules

### Core Format Structure

APA 7th edition citations follow a consistent component order with specific punctuation:

**Standard Format:**
```
Author/Institution. (Year). Title. Publisher. Retrieved [date], from [URL]
```

**Components:**
1. **Author/Institution** - Entity responsible for content
2. **Year** - Publication or access year in parentheses
3. **Title** - Source title in sentence case (capitalize first word only)
4. **Publisher** - Publishing organization (if different from author)
5. **Retrieval Statement** - "Retrieved [formatted date], from [URL]"
6. **Identifiers** - DOI or PMID (if available)

**Punctuation Rules:**
- Period after each major component
- Comma after "Retrieved [date]"
- No period after URL
- Italicize titles for major works
- Use "n.d." for missing dates

### Author vs Institution Handling

**Decision Logic (lines 695-704):**

```bash
# Determine author/institution parameters for APA script
AUTHOR_PARAM=""
INSTITUTION_PARAM=""

if [ -n "$PUBLISHER_NAME" ]; then
  if [ "$PUBLISHER_TYPE" = "individual" ]; then
    AUTHOR_PARAM="$PUBLISHER_NAME"
  else
    INSTITUTION_PARAM="$PUBLISHER_NAME"
  fi
fi
```

**Rules:**
- **Use Author** when `publisher_type: individual`
  - Format: `Last, F. M.` (surname, initials)
  - Example: `Smith, J. D.`
- **Use Institution** when `publisher_type: organization|government|academic|media`
  - Format: Full organization name
  - Example: `World Health Organization`
- **Never use both** - author OR institution, not both

**When to Use Each:**
| Publisher Type | Parameter | Example |
|----------------|-----------|---------|
| individual | author | `Müller, T.` |
| organization | institution | `Deutsche Bundesbank` |
| government | institution | `U.S. Department of Health` |
| academic | institution | `Harvard University` |
| media | institution | `The New York Times` |

### Date Formatting

**Year Extraction (lines 681-682):**
```bash
# Extract year from access date
YEAR=$(echo "$ACCESS_DATE" | cut -d'-' -f1)
```

**Formatted Date Patterns (lines 684-692):**

**English Format (lines 690-691):**
```bash
# English format: "Month Day, Year" (script adds "Retrieved" prefix)
FORMATTED_DATE=$(date -j -f "%Y-%m-%d" "$ACCESS_DATE" "+%B %d, %Y" 2>/dev/null || echo "")
```
- Input: `2024-01-15` (ISO 8601)
- Output: `January 15, 2024`
- Full citation: `Retrieved January 15, 2024, from...`

**German Format (lines 688-689):**
```bash
# German format: "DD. MMMM YYYY" (script adds "Abgerufen am" prefix)
FORMATTED_DATE=$(date -j -f "%Y-%m-%d" "$ACCESS_DATE" "+%d. %B %Y" 2>/dev/null || echo "")
```
- Input: `2024-01-15` (ISO 8601)
- Output: `15. Januar 2024`
- Full citation: `Abgerufen am 15. Januar 2024, von...`

**Language-Specific Prefixes:**
- **English:** "Retrieved" (added by generate-apa-citation.sh)
- **German:** "Abgerufen am" (added by generate-apa-citation.sh)

**Missing Date Handling:**
- Use `n.d.` (no date) when access_date unavailable
- Year required for citation (validates as `n.d.`)

### Identifiers

**DOI and PMID Extraction (lines 569-571):**
```bash
DOI=$(grep "^doi:" "$SOURCE_FILE" | head -1 | sed 's/^doi:[[:space:]]*//' | sed 's/"//g')
PMID=$(grep "^pmid:" "$SOURCE_FILE" | head -1 | sed 's/^pmid:[[:space:]]*//' | sed 's/"//g')
```

**URL Formatting:**
```bash
URL=$(grep "^url:" "$SOURCE_FILE" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/"//g')
```

**Identifier Priority:**
1. **DOI** (Digital Object Identifier) - preferred for academic sources
   - Format: `https://doi.org/10.1000/xyz123`
   - Append after URL: `Retrieved [date], from [URL]. https://doi.org/10.1000/xyz123`
2. **PMID** (PubMed ID) - for medical/biological sources
   - Format: `PMID: 12345678`
   - Append after URL: `Retrieved [date], from [URL]. PMID: 12345678`
3. **URL** - always required as fallback
   - Format: Full URL with protocol
   - Example: `https://example.com/article`

**Rules:**
- DOI takes precedence over PMID
- URL always included
- No period after DOI or PMID
- Validate identifiers are not fabricated

## Multi-Language Support

### English Citations

**Format Example:**
```
Smith, J. D. (2024). Climate change impacts on coastal ecosystems.
National Oceanic and Atmospheric Administration.
Retrieved January 15, 2024, from https://www.noaa.gov/climate-impacts
```

**Components:**
- Retrieval prefix: "Retrieved"
- Date format: "Month Day, Year" (e.g., "January 15, 2024")
- URL prefix: "from"

**Validation (lines 733-735):**
- Check for "Retrieved" in citation text
- Verify month name in English
- Confirm comma after date

### German Citations

**Format Example (lines 58-63):**
```
Müller, T. (2024). Digitalisierung im deutschen Profifußball.
Deutscher Fußball-Bund.
Abgerufen am 15. Januar 2024, von https://www.dfb.de/news/detail/digitalisierung
```

**Components:**
- Retrieval prefix: "Abgerufen am"
- Date format: "DD. MMMM YYYY" (e.g., "15. Januar 2024")
- URL prefix: "von" (from)

**Validation (lines 733-735):**
```bash
# VALIDATION: Check German format if language is de
if [ "$LANGUAGE" = "de" ] && [ "$CITATION_TEXT" != *"Abgerufen am"* ] && [ "$CITATION_TEXT" != *"n.d."* ]; then
  echo "WARNING: German citation missing 'Abgerufen am' format (source: $source_id): $CITATION_TEXT" >&2
fi
```

**Key Differences from English:**
- "Abgerufen am" instead of "Retrieved"
- "von" instead of "from"
- Day before month: "15. Januar" not "Januar 15"
- Period after day number: "15." not "15"
- German month names: Januar, Februar, März, etc.

### Date Conversion

**Language-Specific Patterns (lines 684-692):**

| Language | Input | Pattern | Output | Full Citation |
|----------|-------|---------|--------|---------------|
| English (`en`) | `2024-01-15` | `+%B %d, %Y` | `January 15, 2024` | `Retrieved January 15, 2024, from...` |
| German (`de`) | `2024-01-15` | `+%d. %B %Y` | `15. Januar 2024` | `Abgerufen am 15. Januar 2024, von...` |

**Month Name Mapping (German):**
- Januar (January)
- Februar (February)
- März (March)
- April (April)
- Mai (May)
- Juni (June)
- Juli (July)
- August (August)
- September (September)
- Oktober (October)
- November (November)
- Dezember (December)

**Fallback Behavior:**
```bash
2>/dev/null || echo ""
```
- If date conversion fails, return empty string
- Citation generation handles empty dates as `n.d.`

## YAML Artifact Prevention

### Common Artifacts

**What to Detect (lines 722-735):**

Citations containing these strings indicate YAML parsing errors:
- `domain:`
- `title:`
- `url:`
- `Udomain:` (malformed field name)
- `source_url:`

**Why They Occur:**
- Using `grep` alone without `sed` to strip field names
- Extracting entire YAML line instead of value only
- Insufficient validation before entity creation
- Copy-paste of YAML frontmatter into citation text

**Example of Artifact:**
```
# BAD: Citation with YAML artifact
title: Climate Change Report (2024). Retrieved from url: https://example.com

# GOOD: Clean citation
Climate Change Report (2024). Retrieved January 15, 2024, from https://example.com
```

### Validation Patterns

**Proper YAML Parsing (lines 573-586):**

```bash
# Extract source metadata using proper YAML parsing
TITLE=$(grep "^title:" "$SOURCE_FILE" | head -1 | sed 's/^title:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
URL=$(grep "^url:" "$SOURCE_FILE" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/"//g')
DOMAIN=$(grep "^domain:" "$SOURCE_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')

# Validate extracted values don't contain YAML artifacts
if [ "$DOMAIN" == *":"* ]] || [ "$DOMAIN" == *"domain:"* ]; then
  echo "ERROR: Extracted domain contains YAML artifacts: $DOMAIN (source: $source_id)" >&2
  continue
fi

if [ "$TITLE" == *"title:"* ]] || [ "$TITLE" == *"Obsidian"* ]; then
  echo "ERROR: Extracted title contains YAML artifacts: $TITLE (source: $source_id)" >&2
  continue
fi

if [ "$URL" == *"url:"* ]] || [ "$URL" == *"source_url:"* ]; then
  echo "ERROR: Extracted URL contains YAML artifacts: $URL (source: $source_id)" >&2
  continue
fi
```

**Validation Checklist:**
1. Extract field value using `grep` + `sed`
2. Strip field name (`^field:[[:space:]]*`)
3. Remove quotes (`"` and `'`)
4. Validate extracted value doesn't contain colons
5. Validate field name not present in value
6. Skip entity creation if validation fails

**Citation Text Validation (lines 722-730):**
```bash
# VALIDATION: Check citation doesn't contain YAML artifacts
if [ "$CITATION_TEXT" == *"domain:"* ]] || \
   [ "$CITATION_TEXT" == *"title:"* ]] || \
   [ "$CITATION_TEXT" == *"url:"* ]] || \
   [ "$CITATION_TEXT" == *"Udomain:"* ]; then
  echo "ERROR: Citation text contains YAML field names (source: $source_id):" >&2
  echo "$CITATION_TEXT" >&2
  continue
fi
```

### Value Extraction

**Safe Extraction Pattern:**
```bash
# Template for extracting YAML values
FIELD=$(grep "^fieldname:" "$FILE" | head -1 | sed 's/^fieldname:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
```

**Components:**
1. `grep "^fieldname:"` - Match field at line start
2. `head -1` - Take first occurrence only
3. `sed 's/^fieldname:[[:space:]]*//'` - Remove field name and whitespace
4. `sed 's/"//g'` - Remove double quotes
5. `sed "s/'//g"` - Remove single quotes

**Never Use Grep Alone:**
```bash
# BAD: Returns "domain: example.com"
DOMAIN=$(grep "^domain:" "$SOURCE_FILE")

# GOOD: Returns "example.com"
DOMAIN=$(grep "^domain:" "$SOURCE_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')
```

## Citation Generation

### Script Integration

**generate-apa-citation.sh Usage (lines 706-718):**

```bash
# Generate APA citation using script
citation_result=$(bash "$SCRIPT_GENERATE_CITATION" \
  --title "$TITLE" \
  --url "$URL" \
  --domain "$DOMAIN" \
  --author "$AUTHOR_PARAM" \
  --institution "$INSTITUTION_PARAM" \
  --year "$YEAR" \
  --date "$FORMATTED_DATE" \
  --language "$LANGUAGE" \
  --doi "$DOI" \
  --pmid "$PMID" \
  --json)

CITATION_TEXT=$(echo "$citation_result" | jq -r '.citation')
```

**Script Path (lines 241):**
```bash
SCRIPT_GENERATE_CITATION="${CLAUDE_PLUGIN_ROOT}/scripts/generate-apa-citation.sh"
```

**JSON Response Parsing:**
- Script returns JSON: `{"citation": "..."}`
- Extract citation text using `jq -r '.citation'`
- Validate before writing to entity

### Parameter Mapping

**Source Fields → Citation Parameters:**

| Source Field | Parameter | Extraction | Notes |
|--------------|-----------|------------|-------|
| `title` | `--title` | YAML parsing | Sentence case |
| `url` | `--url` | YAML parsing | Full URL with protocol |
| `domain` | `--domain` | YAML parsing | Normalized (lowercase, no www.) |
| `publisher` (if `publisher_type: individual`) | `--author` | YAML parsing + type check | Last, F. M. format |
| `publisher` (if other type) | `--institution` | YAML parsing + type check | Full organization name |
| `access_date` (year only) | `--year` | Extract year with `cut -d'-' -f1` | YYYY format |
| `access_date` (formatted) | `--date` | Date conversion by language | Language-specific format |
| `--language` parameter | `--language` | Command-line argument | `en` or `de` |
| `doi` | `--doi` | YAML parsing | Optional |
| `pmid` | `--pmid` | YAML parsing | Optional |

**Example Mapping:**
```yaml
# Source entity (07-sources/data/source-climate-report-abc123.md)
title: "Climate Change Impacts on Coastal Ecosystems"
url: "https://www.noaa.gov/climate-impacts"
domain: "noaa.gov"
access_date: "2024-01-15"
doi: "10.1000/noaa.2024.climate"
publisher: "[[08-publishers/data/publisher-national-oceanic-and-atmospheric-administration]]"
```

```bash
# Generated citation parameters
--title "Climate Change Impacts on Coastal Ecosystems"
--url "https://www.noaa.gov/climate-impacts"
--domain "noaa.gov"
--institution "National Oceanic and Atmospheric Administration"
--year "2024"
--date "January 15, 2024"
--language "en"
--doi "10.1000/noaa.2024.climate"
```

### Validation

**Citation Text Checks (lines 722-735):**

1. **YAML Artifact Detection:**
   ```bash
   if [ "$CITATION_TEXT" == *"domain:"* ]] || \
      [ "$CITATION_TEXT" == *"title:"* ]] || \
      [ "$CITATION_TEXT" == *"url:"* ]; then
     echo "ERROR: Citation text contains YAML field names"
     continue
   fi
   ```

2. **German Format Validation:**
   ```bash
   if [ "$LANGUAGE" = "de" ] && [ "$CITATION_TEXT" != *"Abgerufen am"* ] && [ "$CITATION_TEXT" != *"n.d."* ]; then
     echo "WARNING: German citation missing 'Abgerufen am' format"
   fi
   ```

3. **Required Components:**
   - Citation text not empty
   - Contains URL
   - Contains title
   - Contains year or "n.d."
   - Contains retrieval statement (unless n.d.)

## Data Integrity

### Fabrication Prevention

**What Never to Invent (lines 106-122):**

1. **DOIs or PMIDs:**
   - Never generate plausible-looking identifiers
   - Only use if present in source entity
   - Empty string if not available

2. **Author Affiliations:**
   - Never add credentials (PhD, MD, etc.)
   - Never invent institutional affiliations
   - Use publisher metadata only

3. **Enhanced Titles:**
   - Never expand abbreviations without source evidence
   - Never add descriptive subtitles
   - Extract title exactly as written in source

4. **Publisher Links:**
   - Never fabricate `[[08-publishers/data/...]]` links
   - Only link if publisher entity exists
   - Use domain fallback if no match

### Source Fidelity

**Extract Only What Exists (lines 110-112):**

```bash
# ALWAYS use proper YAML parsing (grep+sed, never grep alone)
# ALWAYS validate extracted values before entity creation
```

**Validation Rules:**
- Verify file exists before reading
- Confirm YAML field present before extraction
- Validate extracted value is not empty
- Check for YAML artifacts in extracted values
- Skip entity creation if validation fails

**Example:**
```bash
# Source entity contains:
title: "Climate Report"
# NO doi field present

# Citation generation:
DOI=$(grep "^doi:" "$SOURCE_FILE" | head -1 | sed 's/^doi:[[:space:]]*//' | sed 's/"//g')
# Result: DOI="" (empty string, not fabricated)

# Citation output:
# Does NOT include fabricated DOI like "https://doi.org/10.1000/fake123"
```

## Examples

### Example 1: English Citation with Author and DOI

**Source Data:**
```yaml
title: "Machine Learning in Climate Science"
url: "https://example.edu/ml-climate"
domain: "example.edu"
access_date: "2024-03-15"
doi: "10.1234/example.2024.ml"
publisher: "Smith, J. D." (publisher_type: individual)
```

**Generated Citation:**
```
Smith, J. D. (2024). Machine learning in climate science.
Retrieved March 15, 2024, from https://example.edu/ml-climate.
https://doi.org/10.1234/example.2024.ml
```

---

### Example 2: German Citation with Institution

**Source Data:**
```yaml
title: "Digitalisierung im deutschen Profifußball"
url: "https://www.dfb.de/news/detail/digitalisierung"
domain: "dfb.de"
access_date: "2024-01-15"
publisher: "Deutscher Fußball-Bund" (publisher_type: organization)
```

**Generated Citation:**
```
Deutscher Fußball-Bund. (2024). Digitalisierung im deutschen Profifußball.
Abgerufen am 15. Januar 2024, von https://www.dfb.de/news/detail/digitalisierung
```

---

### Example 3: English Citation without DOI, Institution Publisher

**Source Data:**
```yaml
title: "Global Health Statistics 2024"
url: "https://www.who.int/data/gho/publications/world-health-statistics"
domain: "who.int"
access_date: "2024-02-20"
publisher: "World Health Organization" (publisher_type: organization)
```

**Generated Citation:**
```
World Health Organization. (2024). Global health statistics 2024.
Retrieved February 20, 2024, from https://www.who.int/data/gho/publications/world-health-statistics
```

---

### Example 4: German Citation with PMID

**Source Data:**
```yaml
title: "Neue Therapieansätze in der Kardiologie"
url: "https://www.aerzteblatt.de/archiv/234567"
domain: "aerzteblatt.de"
access_date: "2024-04-10"
pmid: "38456789"
publisher: "Deutscher Ärzteverlag" (publisher_type: media)
```

**Generated Citation:**
```
Deutscher Ärzteverlag. (2024). Neue Therapieansätze in der Kardiologie.
Abgerufen am 10. April 2024, von https://www.aerzteblatt.de/archiv/234567.
PMID: 38456789
```

---

### Example 5: English Citation with Missing Date (n.d.)

**Source Data:**
```yaml
title: "Historical Climate Data Archive"
url: "https://climate-archive.example.org/historical"
domain: "example.org"
access_date: "" (empty)
publisher: "Climate Research Institute" (publisher_type: academic)
```

**Generated Citation:**
```
Climate Research Institute. (n.d.). Historical climate data archive.
Retrieved from https://climate-archive.example.org/historical
```

---

### Example 6: Domain Fallback (No Publisher Entity)

**Source Data:**
```yaml
title: "Community Blog Post on Sustainability"
url: "https://blog.example.com/sustainability-2024"
domain: "blog.example.com"
access_date: "2024-05-01"
publisher: "" (no matching publisher entity)
```

**Generated Citation:**
```
blog.example.com. (2024). Community blog post on sustainability.
Retrieved May 1, 2024, from https://blog.example.com/sustainability-2024
```

**Note:** Domain used as fallback when no publisher entity matches.
