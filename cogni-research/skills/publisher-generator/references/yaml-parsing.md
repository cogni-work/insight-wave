# YAML Frontmatter Parsing Techniques

This reference provides detailed guidance for parsing YAML frontmatter from source entity files in the publisher-generator workflow.

## Overview

Source files use YAML frontmatter wrapped in `---` delimiters. The publisher-generator skill must extract metadata fields reliably across different YAML formatting styles.

## Field Extraction Methods

### Method 1: Using Grep + Sed (Bash Tool)

**For simple single-line fields:**

```bash
# Extract domain field
domain=$(grep "^domain:" source_file.md | sed 's/^domain: *//' | sed 's/^"\(.*\)"$/\1/')

# Extract url field (canonical field name per entity-templates.md)
url=$(grep "^url:" source_file.md | sed 's/^url: *//' | sed 's/^"\(.*\)"$/\1/')
```

**Handles:**
- Quoted values: `domain: "example.com"`
- Unquoted values: `domain: example.com`
- Extra whitespace: `domain:    example.com`

### Method 2: Using Awk (Bash Tool)

**For multi-line values:**

```bash
# Extract multi-line field (stops at next field or closing ---)
awk '/^field_name:/,/^[a-z_]+:/ {if (/^field_name:/) print; else if (!/^[a-z_]+:/) print}' source_file.md
```

### Method 3: Read Tool + Text Parsing

**For complex parsing:**

1. Use Read tool to load entire file
2. Extract frontmatter section (between first and second `---`)
3. Parse line by line in skill logic

```
Read source_file.md
Extract lines 2 to N (where line N+1 is second "---")
For each line:
  If starts with "field_name:", extract value
  If indented, treat as continuation of previous field
```

## Field Types

### String Fields

**Single-line string:**
```yaml
domain: example.com
url: "https://example.com/article"
```

**Extraction:** Grep/sed method (Method 1)

### Array Fields

**YAML list format:**
```yaml
authors:
  - John Smith
  - Jane Doe
```

**Comma-separated format:**
```yaml
authors: John Smith, Jane Doe
```

**Single author format:**
```yaml
authors: John Smith
```

**Extraction approach:**
1. Check if field has value (not null, not empty)
2. If multi-line (starts with `-`), collect all indented lines
3. If single-line, check for comma separator
4. Split accordingly

**Example bash extraction:**
```bash
# Check if authors field exists and has value
if grep -q "^authors:" source_file.md && ! grep -q "^authors: *$" source_file.md; then
  # Extract authors (handles both formats)
  authors=$(grep "^authors:" source_file.md | sed 's/^authors: *//')

  # If empty on same line, look for list format
  if [ -z "$authors" ]; then
    authors=$(awk '/^authors:/,/^[a-z_]+:/ {if (/^ *- /) print}' source_file.md | sed 's/^ *- *//' | tr '\n' ',')
  fi
fi
```

### Null vs Missing vs Empty

**Distinguish between:**

```yaml
# Null (field present with no value)
authors:

# Empty string (field present with empty value)
authors: ""

# Missing (field not in frontmatter)
# (no authors line at all)
```

**Detection:**
```bash
# Check if field exists
if grep -q "^authors:" source_file.md; then
  # Field exists, check if has value
  value=$(grep "^authors:" source_file.md | sed 's/^authors: *//')
  if [ -z "$value" ]; then
    # Null or empty string
    # Distinguish by checking for quotes
    if grep -q '^authors: *""' source_file.md; then
      echo "Empty string"
    else
      echo "Null"
    fi
  else
    echo "Has value: $value"
  fi
else
  echo "Field missing"
fi
```

## Common Parsing Patterns

### Pattern 1: Required Field Extraction

```bash
# Extract domain (required field)
domain=$(grep "^domain:" "$source_file" | sed 's/^domain: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate
if [ -z "$domain" ]; then
  echo "Error: Missing domain field"
  # Handle error
fi
```

### Pattern 2: Optional Field Extraction

```bash
# Extract url (optional field - canonical field name per entity-templates.md)
if grep -q "^url:" "$source_file"; then
  url=$(grep "^url:" "$source_file" | sed 's/^url: *//' | sed 's/^"\(.*\)"$/\1/')
else
  url=""
fi
```

### Pattern 3: Array Field with Validation

```bash
# Extract authors array, skip if null/missing/empty
if grep -q "^authors:" "$source_file" && ! grep -q "^authors: *$" "$source_file"; then
  authors_line=$(grep "^authors:" "$source_file" | sed 's/^authors: *//')

  if [ -n "$authors_line" ]; then
    # Single-line format (comma-separated or single author)
    # Process authors
  else
    # Multi-line list format
    # Extract with awk pattern
  fi
else
  # Skip authors (null, missing, or empty)
fi
```

## Edge Cases

### Quoted Values with Special Characters

```yaml
domain: "example.com/path?query=value"
authors: "Smith, John (University of X)"
```

**Handling:** Preserve quotes during extraction, remove only outer quotes

### Multi-line String Values

```yaml
description: |
  This is a long
  multi-line description
  that spans several lines
```

**Handling:** Use awk to capture all indented lines until next field

### Comments in YAML

```yaml
domain: example.com  # This is a comment
```

**Handling:** Remove inline comments with sed: `sed 's/ *#.*$//'`

## Validation Checklist

After parsing, validate:

- [ ] Required fields are present and non-empty
- [ ] String fields don't contain YAML delimiters
- [ ] Array fields are properly split
- [ ] Quotes are removed from values
- [ ] Null/missing/empty distinctions are correct

## Performance Considerations

**For large files (>1MB):**
- Use grep/sed/awk for targeted extraction (faster than full Read + parsing)
- Read only frontmatter section (lines 1 to N where line N is second `---`)

**For small files (<100KB):**
- Full Read + parsing is acceptable
- More flexibility for complex parsing logic

## Integration with Publisher-Generator

**In Step 2.1 (Read & Validate Source):**

1. Use Read tool to load source file
2. Apply Method 1 (grep/sed) for required fields (domain)
3. Apply Pattern 3 for optional array fields (authors)
4. Validate required fields before proceeding
5. Handle null/missing/empty authors gracefully (skip individual publishers)

**Error Handling:**
- Missing required field → Add to failed_items, increment creation_failed, skip source
- Malformed YAML → Log error, treat as missing field
- Parsing exceptions → Catch and handle as validation failure
