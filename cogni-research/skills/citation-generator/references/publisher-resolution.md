# Publisher Resolution

## Purpose

Multi-strategy publisher matching system for citation generation. Resolves source entities to publisher entities through 4 hierarchical strategies: domain exact match, name exact match, reverse index (backward compatibility), and domain fallback. Ensures evidence-based publisher linking without hallucination through complete entity loading and normalization algorithms.

**Use Cases:**
- Link citations to publisher entities with validated references
- Handle edge cases (no publisher found) without errors
- Support backward compatibility with existing publisher→source links
- Track resolution strategy for quality analysis

---

## 4-Strategy Resolution

### Strategy 1: Domain Exact Match

**Algorithm:**
1. Extract domain from source URL: `https://example.com/page` → `example.com`
2. Normalize domain: lowercase, remove `www.` prefix
3. Lookup in `PUBLISHER_DOMAIN_KEYS/VALUES` parallel arrays
4. If match found, return publisher_id immediately

**Code Pattern:**
```bash
# Extract domain from URL
source_domain=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')

# Strategy 1: Domain exact match (Bash 3.2 compatible - use lookup helper)
if [ -z "$PUBLISHER_ID" ] && [ -n "$source_domain" ]; then
  match=$(lookup_publisher_by_domain "$source_domain") && {
    PUBLISHER_ID="$match"
    MATCH_STRATEGY="domain_exact"
    match_domain_exact=$((match_domain_exact + 1))
    echo "  ✓ Strategy 1 (domain_exact): $source_domain → $PUBLISHER_ID" >&2
  }
fi
```

**When It Matches:**
- Source URL domain matches publisher domain field
- Most common strategy (60-70% of citations)
- Requires publisher entity has valid `domain:` frontmatter field

**Examples:**
| Source URL | Publisher Domain | Match? | Publisher ID |
|------------|-----------------|--------|--------------|
| `https://www.nature.com/articles/123` | `nature.com` | ✅ Yes | `nature-publishing-group` |
| `https://arxiv.org/abs/2301.12345` | `arxiv.org` | ✅ Yes | `arxiv` |
| `https://blog.example.com/post` | `example.com` | ✅ Yes | `example-blog` |
| `https://unknown-site.org/page` | (no publisher) | ❌ No | - |

**Normalization Rules:**
- Convert to lowercase: `Example.COM` → `example.com`
- Remove `www.` prefix: `www.nature.com` → `nature.com`
- Preserve subdomains: `blog.example.com` → `blog.example.com`

---

### Strategy 2: Name Exact Match

**Algorithm:**
1. Extract `publisher:` field from source entity frontmatter
2. Normalize publisher name: lowercase, remove non-alphanumeric characters
3. Lookup in `PUBLISHER_NAME_KEYS/VALUES` parallel arrays
4. If match found, return publisher_id immediately

**Code Pattern:**
```bash
# Strategy 2: Name exact match (Bash 3.2 compatible - use lookup helper)
if [ -z "$PUBLISHER_ID" ]; then
  source_publisher=$(grep "^publisher:" "$SOURCE_FILE" | head -1 | sed 's/^publisher:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
  if [ -n "$source_publisher" ]; then
    normalized=$(echo "$source_publisher" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    match=$(lookup_publisher_by_name "$normalized") && {
      PUBLISHER_ID="$match"
      MATCH_STRATEGY="name_exact"
      match_name_exact=$((match_name_exact + 1))
      echo "  ✓ Strategy 2 (name_exact): $source_publisher → $PUBLISHER_ID" >&2
    }
  fi
fi
```

**When It Matches:**
- Source entity has explicit `publisher:` field in frontmatter
- Publisher name (after normalization) matches publisher entity name
- Less common (10-20% of citations) - requires manual publisher annotation

**Examples:**
| Source Publisher Field | Publisher Name | Normalized | Match? | Publisher ID |
|------------------------|----------------|------------|--------|--------------|
| `"Nature Publishing Group"` | `Nature Publishing Group` | `naturepublishinggroup` | ✅ Yes | `nature-publishing-group` |
| `"The New York Times"` | `The New York Times` | `thenewyorktimes` | ✅ Yes | `new-york-times` |
| `"arXiv"` | `arXiv` | `arxiv` | ✅ Yes | `arxiv` |
| `"Unknown Publisher"` | (no match) | `unknownpublisher` | ❌ No | - |

**Normalization Rules:**
- Convert to lowercase: `Nature` → `nature`
- Remove non-alphanumeric: `Nature Publishing Group` → `naturepublishinggroup`
- Spaces removed: `The New York Times` → `thenewyorktimes`
- Punctuation removed: `St. John's` → `stjohns`

---

### Strategy 3: Reverse Index

**Algorithm:**
1. Check if source_id exists in `PUBLISHER_BY_SOURCE` associative array
2. If found, extract publisher_id from reverse link
3. Return publisher_id with `reverse_index` strategy

**Code Pattern:**
```bash
# Strategy 3: Reverse index (backward compatibility)
if [ -z "$PUBLISHER_ID" ] && [ -n "${PUBLISHER_BY_SOURCE[$source_id]}" ]; then
  PUBLISHER_INFO="${PUBLISHER_BY_SOURCE[$source_id]}"
  PUBLISHER_ID=$(echo "$PUBLISHER_INFO" | cut -d'|' -f1)
  MATCH_STRATEGY="reverse_index"
  match_reverse_index=$((match_reverse_index + 1))
  echo "  ✓ Strategy 3 (reverse_index): $source_id → $PUBLISHER_ID" >&2
fi
```

**When Used:**
- Backward compatibility with existing publisher→source links
- Publisher entity already references source in body content
- Less common (5-10% of citations) - legacy linking pattern

**Example:**

**Publisher Entity (`nature-publishing-group.md`):**
```markdown
## Sources Published

- [[07-sources/data/source-nature-article-123]]
- [[07-sources/data/source-nature-review-456]]
```

**Reverse Index Construction:**
```bash
# Extract source links from publisher entity
while IFS= read -r source_link; do
  source_id=$(echo "$source_link" | sed 's/.*\/\(source-[^]]*\)\]\]/\1/')
  PUBLISHER_BY_SOURCE["$source_id"]="${publisher_id}|${publisher_name}|${publisher_type}"
done < <(grep -o '\[\[07-sources/data/source-[^]]*\]\]' "$publisher_file")
```

**Result:**
- `PUBLISHER_BY_SOURCE["source-nature-article-123"]` = `"nature-publishing-group|Nature Publishing Group|organization"`
- Citation generation finds `source-nature-article-123` → resolves to `nature-publishing-group`

---

### Strategy 3.5: Cross-Validation Guard (v3.9.0)

**Purpose:** Verify publisher resolution consistency before accepting match from Strategy 2 or 3.

**Algorithm:**

1. IF publisher resolved via Strategy 2 (name_exact) or Strategy 3 (reverse_index):
   - Extract normalized domain from source URL
   - Extract normalized domain from resolved publisher entity
   - IF domains don't match:
     - Log warning with source_id, publisher_id, both domains
     - Discard resolution, fall through to Strategy 4

**Code Pattern:**

```bash
# Strategy 3.5: Cross-validation guard (after Strategy 2 or 3 match)
if [ -n "$PUBLISHER_ID" ] && [ "$MATCH_STRATEGY" != "domain_exact" ]; then
  # Get publisher's registered domain
  publisher_file="${PROJECT_PATH}/08-publishers/data/${PUBLISHER_ID}.md"
  publisher_domain=$(grep "^domain:" "$publisher_file" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')

  # Compare with source domain
  if [ -n "$publisher_domain" ] && [ "$source_domain" != "$publisher_domain" ]; then
    echo "  ⚠ Strategy 3.5 (cross_validation): FAILED" >&2
    echo "    source_domain=$source_domain, publisher_domain=$publisher_domain" >&2
    echo "    Discarding $MATCH_STRATEGY match for $PUBLISHER_ID" >&2
    PUBLISHER_ID=""
    MATCH_STRATEGY=""
    # Fall through to Strategy 4 (domain_fallback)
  fi
fi
```

**When It Triggers:**

- Strategy 2 or 3 found a match, but domains don't align
- Prevents citation linking source from `sichere-industrie.de` to `publisher-sequafy`
- Logs detailed warning for debugging

**Examples:**

| Source Domain | Publisher Domain | Strategy | Result |
|--------------|-----------------|----------|--------|
| sichere-industrie.de | sequafy.com | reverse_index | ⚠ DISCARDED → fallback |
| nature.com | nature.com | name_exact | ✅ KEPT |
| arxiv.org | cornell.edu | reverse_index | ⚠ DISCARDED → fallback |

**Why This Matters:**

- The reverse index (Strategy 3) is built from publisher→source links in publisher entity bodies
- If a publisher entity incorrectly contains a wikilink to the wrong source, Strategy 3 will find a match
- This guard ensures the match is valid by verifying domain consistency
- Prevents orphaned publishers caused by incorrect backlinks

---

### Strategy 4: Domain Fallback

**Algorithm:**
1. If all previous strategies fail (no publisher match found)
2. Set `MATCH_STRATEGY="domain_fallback"`
3. Continue citation generation without publisher link
4. **This is NOT an error** - valid edge case

**Code Pattern:**
```bash
# Strategy 4: Domain fallback (no publisher entity found)
if [ -z "$PUBLISHER_ID" ]; then
  MATCH_STRATEGY="domain_fallback"
  match_domain_fallback=$((match_domain_fallback + 1))
  echo "  ⚠ Strategy 4 (domain_fallback): No publisher found for $source_id (domain: $source_domain)" >&2
fi
```

**When Used:**
- No publisher entity exists for source domain
- Source is from personal blog, niche website, or new publication
- Publisher entities not yet created
- Typical: 5-15% of citations

**Citation Output Example:**
```markdown
## Citation

Smith, J. (2024). Article title. Retrieved January 15, 2024, from https://personal-blog.com/article

### Components

- **Source**: [[07-sources/data/source-personal-blog-article]]
- **Reliability**: Tier 3
- **Match Strategy**: domain_fallback
```

**Warning Threshold:**
If >80% citations use `domain_fallback`, generate warning:
```json
{
  "warnings": ["85% citations used domain_fallback - check publisher loading"]
}
```

This indicates potential issues:
- Publisher entities not loaded completely
- Publisher indexing failed
- Missing publisher entities in project

---

## Indexing Algorithms

### Building Domain Map

**Purpose:** Map normalized domains to publisher IDs for Strategy 1 matching.

**Code Pattern:**
```bash
# Strategy 1: Build domain→publisher map (Bash 3.2 compatible - parallel indexed arrays)
PUBLISHER_DOMAIN_KEYS=()
PUBLISHER_DOMAIN_VALUES=()

for publisher_file in "${PROJECT_PATH}"/08-publishers/data/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id=$(basename "$publisher_file" .md)

  # Extract domain using proper YAML parsing
  publisher_domain=$(grep "^domain:" "$publisher_file" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')

  if [ -n "$publisher_domain" ]; then
    # Normalize domain (remove www., lowercase)
    normalized_domain=$(echo "$publisher_domain" | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')
    PUBLISHER_DOMAIN_KEYS+=("$normalized_domain")
    PUBLISHER_DOMAIN_VALUES+=("$publisher_id")
    echo "  Domain index: $normalized_domain → $publisher_id" >&2
  fi
done
```

**Normalization Steps:**
1. Extract `domain:` field from publisher frontmatter
2. Remove surrounding quotes: `"nature.com"` → `nature.com`
3. Convert to lowercase: `Nature.COM` → `nature.com`
4. Remove `www.` prefix: `www.nature.com` → `nature.com`
5. Store in parallel arrays: `PUBLISHER_DOMAIN_KEYS+=("nature.com")` / `PUBLISHER_DOMAIN_VALUES+=("nature-publishing-group")`

**Examples:**

| Publisher File | Domain Field | Normalized Key | Publisher ID |
|----------------|--------------|----------------|--------------|
| `nature-publishing-group.md` | `"Nature.com"` | `nature.com` | `nature-publishing-group` |
| `arxiv.md` | `"arXiv.org"` | `arxiv.org` | `arxiv` |
| `new-york-times.md` | `"www.nytimes.com"` | `nytimes.com` | `new-york-times` |

**Critical Requirements:**
- ✅ Complete publisher loading before indexing
- ✅ Proper YAML parsing (grep+sed, not grep alone)
- ✅ Validate domain non-empty before adding to index
- ✅ Log each index entry for debugging

---

### Building Name Map

**Purpose:** Map normalized publisher names to publisher IDs for Strategy 2 matching.

**Code Pattern:**
```bash
# Strategy 2: Build name→publisher map (Bash 3.2 compatible - parallel indexed arrays)
PUBLISHER_NAME_KEYS=()
PUBLISHER_NAME_VALUES=()

for publisher_file in "${PROJECT_PATH}"/08-publishers/data/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id=$(basename "$publisher_file" .md)

  # Extract publisher name using proper YAML parsing
  publisher_name=$(grep "^name:" "$publisher_file" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")

  if [ -n "$publisher_name" ]; then
    # Normalize for matching (lowercase, remove non-alphanumeric)
    normalized_name=$(echo "$publisher_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    PUBLISHER_NAME_KEYS+=("$normalized_name")
    PUBLISHER_NAME_VALUES+=("$publisher_id")
    echo "  Name index: $normalized_name → $publisher_id" >&2
  fi
done
```

**Normalization Rules:**
1. Extract `name:` field from publisher frontmatter
2. Remove surrounding quotes (both `"` and `'`)
3. Convert to lowercase: `Nature` → `nature`
4. Remove non-alphanumeric characters: Keep only `[a-z0-9]`
5. Store in parallel arrays

**Examples:**

| Publisher Name | Normalization Steps | Final Key | Publisher ID |
|----------------|---------------------|-----------|--------------|
| `"Nature Publishing Group"` | lowercase → remove spaces → `naturepublishinggroup` | `naturepublishinggroup` | `nature-publishing-group` |
| `"The New York Times"` | lowercase → remove spaces/punctuation → `thenewyorktimes` | `thenewyorktimes` | `new-york-times` |
| `"arXiv"` | lowercase → `arxiv` | `arxiv` | `arxiv` |
| `"O'Reilly Media"` | lowercase → remove apostrophe → `oreillymedia` | `oreillymedia` | `oreilly-media` |

**Why Aggressive Normalization?**
- Handles variations: `"Nature"` vs `"nature"` vs `"Nature Publishing"`
- Removes punctuation differences: `"St. John's"` vs `"St Johns"`
- Ignores whitespace: `"New York Times"` vs `"NewYorkTimes"`
- Improves match rate for Strategy 2

---

### Building Reverse Index

**Purpose:** Map source IDs to publisher IDs for Strategy 3 (backward compatibility).

**Code Pattern:**
```bash
# Strategy 3: Build reverse index (Bash 3.2 compatible - parallel indexed arrays)
PUBLISHER_SOURCE_KEYS=()
PUBLISHER_SOURCE_VALUES=()

for publisher_file in "${PROJECT_PATH}"/08-publishers/data/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id=$(basename "$publisher_file" .md)

  # Extract publisher metadata
  publisher_name=$(grep "^name:" "$publisher_file" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g')
  publisher_type=$(grep "^publisher_type:" "$publisher_file" | head -1 | sed 's/^publisher_type:[[:space:]]*//' | sed 's/"//g')

  # Extract all source IDs this publisher links to
  while IFS= read -r source_link; do
    source_id=$(echo "$source_link" | sed 's/.*\/\(source-[^]]*\)\]\]/\1/')
    PUBLISHER_SOURCE_KEYS+=("$source_id")
    PUBLISHER_SOURCE_VALUES+=("${publisher_id}|${publisher_name}|${publisher_type}")
    echo "  Reverse index: $source_id → $publisher_id" >&2
  done < <(grep -o '\[\[07-sources/data/source-[^]]*\]\]' "$publisher_file")
done
```

**How It Works:**

1. **Scan Publisher Entities:**
   - Read each publisher file in `08-publishers/data/`
   - Extract publisher_id, name, type from frontmatter

2. **Find Source Wikilinks:**
   - Search for `[[07-sources/data/source-*]]` patterns in publisher body
   - Extract source_id from each wikilink

3. **Build Reverse Map:**
   - Store `PUBLISHER_BY_SOURCE[source_id] = "publisher_id|name|type"`
   - Creates inverse relationship: source → publisher

**Example:**

**Publisher Entity (`nature-publishing-group.md`):**
```markdown
---
name: "Nature Publishing Group"
publisher_type: "organization"
domain: "nature.com"
---

## Sources Published

- [[07-sources/data/source-nature-article-123]]
- [[07-sources/data/source-nature-review-456]]
- [[07-sources/data/source-nature-news-789]]
```

**Resulting Reverse Index:**
```bash
PUBLISHER_BY_SOURCE["source-nature-article-123"] = "nature-publishing-group|Nature Publishing Group|organization"
PUBLISHER_BY_SOURCE["source-nature-review-456"] = "nature-publishing-group|Nature Publishing Group|organization"
PUBLISHER_BY_SOURCE["source-nature-news-789"] = "nature-publishing-group|Nature Publishing Group|organization"
```

**When Strategy 3 Runs:**
- Citation generation for `source-nature-article-123`
- Strategies 1 & 2 fail (no domain/name match)
- Strategy 3 checks: `PUBLISHER_BY_SOURCE["source-nature-article-123"]` → found!
- Resolves to `nature-publishing-group`

---

## Resolution Decision Tree

```
┌──────────────────────────────────────────────────┐
│ Start: Process Source Entity                     │
│ - Extract URL, domain, metadata                  │
│ - Initialize: PUBLISHER_ID=""                    │
└───────────────────┬──────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────────┐
    │ Strategy 1: Domain Exact Match            │
    │ - Extract domain from URL                 │
    │ - Normalize: lowercase, remove www.       │
    │ - Lookup: PUBLISHER_BY_DOMAIN[domain]     │
    └───────────────┬───────────────────────────┘
                    │
          ┌─────────┴─────────┐
          │ Found?            │
          └───┬───────────┬───┘
              │ YES       │ NO
              │           │
              ▼           ▼
    ┌─────────────────┐  ┌──────────────────────────────────┐
    │ Return:         │  │ Strategy 2: Name Exact Match     │
    │ - Publisher ID  │  │ - Extract publisher field from   │
    │ - Strategy:     │  │   source frontmatter             │
    │   domain_exact  │  │ - Normalize: lowercase, alphaNum │
    │ [END]           │  │ - Lookup: PUBLISHER_BY_NAME[name]│
    └─────────────────┘  └────────────┬─────────────────────┘
                                      │
                            ┌─────────┴─────────┐
                            │ Found?            │
                            └───┬───────────┬───┘
                                │ YES       │ NO
                                │           │
                                ▼           ▼
                      ┌─────────────────┐  ┌────────────────────────────────┐
                      │ Return:         │  │ Strategy 3: Reverse Index      │
                      │ - Publisher ID  │  │ - Lookup: PUBLISHER_BY_SOURCE  │
                      │ - Strategy:     │  │   [source_id]                  │
                      │   name_exact    │  │ - Check if publisher already   │
                      │ [END]           │  │   links to this source         │
                      └─────────────────┘  └────────────┬───────────────────┘
                                                        │
                                              ┌─────────┴─────────┐
                                              │ Found?            │
                                              └───┬───────────┬───┘
                                                  │ YES       │ NO
                                                  │           │
                                                  ▼           ▼
                                        ┌─────────────────┐  ┌─────────────────┐
                                        │ Return:         │  │ Strategy 4:     │
                                        │ - Publisher ID  │  │ Domain Fallback │
                                        │ - Strategy:     │  │ - No match      │
                                        │   reverse_index │  │ - Strategy:     │
                                        │ [END]           │  │   domain_fallbac│
                                        └─────────────────┘  │ - Continue      │
                                                             │   without       │
                                                             │   publisher link│
                                                             │ [END]           │
                                                             └─────────────────┘
```

**Decision Flow:**

1. **Try Strategy 1** → Domain exact match
   - ✅ Match found → Return immediately (60-70% of cases)
   - ❌ No match → Continue to Strategy 2

2. **Try Strategy 2** → Name exact match
   - ✅ Match found → Return immediately (10-20% of cases)
   - ❌ No match → Continue to Strategy 3

3. **Try Strategy 3** → Reverse index
   - ✅ Match found → Return immediately (5-10% of cases)
   - ❌ No match → Continue to Strategy 4

4. **Strategy 4** → Domain fallback
   - Always succeeds (no error)
   - Citation generated without publisher link
   - Warning if >80% citations use this strategy

**Key Principles:**
- **First Match Wins:** Stop immediately when any strategy succeeds
- **Ordered Priority:** Domain > Name > Reverse > Fallback
- **No Errors:** Fallback ensures citation always generated
- **Tracking:** Match strategy stored in citation entity frontmatter

---

## Validation & Error Handling

### Empty Publisher ID Validation

**Critical Check:** Reject empty `publisher_id` for non-fallback strategies.

**Code Pattern:**
```bash
# ===== VALIDATION: Reject empty publisher_id for non-fallback strategies =====

if [ "$MATCH_STRATEGY" != "domain_fallback" ] && [ -z "$PUBLISHER_ID" ]; then
  echo "ERROR: Empty publisher_id for strategy $MATCH_STRATEGY (source: $source_id)" >&2
  continue  # Skip this citation, log error
fi
```

**Why This Matters:**
- Strategies 1-3 should always return valid publisher_id
- Empty ID indicates bug in indexing or matching logic
- Prevents citations with broken publisher links
- Logs error for investigation without halting entire workflow

**Example Error Scenario:**
```bash
# Strategy 1 reports match but publisher_id is empty
MATCH_STRATEGY="domain_exact"
PUBLISHER_ID=""  # BUG: Should have value

# Validation catches this
ERROR: Empty publisher_id for strategy domain_exact (source: source-nature-article-123)
# Citation skipped, continues with next source
```

---

### Domain Extraction from URL

**Purpose:** Extract clean domain from source URL for Strategy 1 matching.

**Code Pattern:**
```bash
# Extract domain from URL for matching
source_domain=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')
```

**Extraction Steps:**
1. **Strip protocol:** `https://example.com/page` → `example.com/page`
2. **Extract host:** `example.com/page` → `example.com`
3. **Lowercase:** `Example.COM` → `example.com`
4. **Remove www.:** `www.example.com` → `example.com`

**Examples:**

| Source URL | Extracted Domain | Notes |
|------------|------------------|-------|
| `https://www.nature.com/articles/nature12345` | `nature.com` | Protocol, www., path removed |
| `https://arxiv.org/abs/2301.12345` | `arxiv.org` | No www., path removed |
| `http://BLOG.EXAMPLE.COM/post/123` | `blog.example.com` | Lowercase, subdomain preserved |
| `https://example.com:8080/page` | `example.com:8080` | Port preserved (edge case) |

**Validation:**
```bash
# Validate extracted values don't contain YAML artifacts
if [ "$DOMAIN" == *":"* ]] || [ "$DOMAIN" == *"domain:"* ]; then
  echo "ERROR: Extracted domain contains YAML artifacts: $DOMAIN (source: $source_id)" >&2
  continue
fi
```

---

### Publisher Metadata Extraction

**Purpose:** Load publisher name and type when match found (for citation generation).

**Code Pattern:**
```bash
# ===== EXTRACT PUBLISHER METADATA (if matched) =====

if [ -n "$PUBLISHER_ID" ]; then
  PUBLISHER_FILE="${PROJECT_PATH}/08-publishers/data/${PUBLISHER_ID}.md"
  if [ -f "$PUBLISHER_FILE" ]; then
    PUBLISHER_NAME=$(grep "^name:" "$PUBLISHER_FILE" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
    PUBLISHER_TYPE=$(grep "^publisher_type:" "$PUBLISHER_FILE" | head -1 | sed 's/^publisher_type:[[:space:]]*//' | sed 's/"//g')
  fi
fi
```

**Validation Steps:**
1. Check `PUBLISHER_ID` is non-empty
2. Verify publisher file exists at path
3. Extract `name:` field (remove quotes, whitespace)
4. Extract `publisher_type:` field (organization/individual)

**Usage in Citation:**
- **Individual:** Use as author → `Smith, J. (2024). Article Title.`
- **Organization:** Use as institution → `Nature Publishing Group. (2024). Article Title.`

**Example:**
```bash
PUBLISHER_ID="nature-publishing-group"
PUBLISHER_FILE="/Users/name/research/project/08-publishers/data/nature-publishing-group.md"

# Extract metadata
PUBLISHER_NAME="Nature Publishing Group"    # From name: field
PUBLISHER_TYPE="organization"                # From publisher_type: field

# Use in APA citation
citation_result=$(bash "$SCRIPT_GENERATE_CITATION" \
  --title "$TITLE" \
  --institution "$PUBLISHER_NAME" \         # Organization type
  --year "$YEAR" \
  --url "$URL")
```

---

### YAML Artifact Detection

**Critical Safeguard:** Prevent citation text from containing YAML field names.

**Code Pattern:**
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

**Common Bugs This Prevents:**
```bash
# ❌ BAD: Grep alone (includes YAML field name)
DOMAIN=$(grep "domain:" "$SOURCE_FILE")
# Result: "domain: example.com" (YAML artifact in value)

# ✅ GOOD: Grep + sed (strips field name)
DOMAIN=$(grep "^domain:" "$SOURCE_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')
# Result: "example.com" (clean value)
```

**Why This Matters:**
- Prevents malformed citations: `"domain: example.com (2024). Article Title."`
- Ensures APA compliance: `"Nature Publishing Group. (2024). Article Title."`
- Catches parsing bugs early (skip citation, log error)

---

## Examples

### Example 1: Domain Exact Match (Strategy 1)

**Scenario:** Source from Nature.com with domain match.

**Source Entity (`source-nature-article-123.md`):**
```yaml
---
title: "Climate Change Impact on Arctic Ice"
url: "https://www.nature.com/articles/nature12345"
domain: "nature.com"
reliability_tier: 1
access_date: "2024-01-15"
---
```

**Publisher Entity (`nature-publishing-group.md`):**
```yaml
---
name: "Nature Publishing Group"
domain: "nature.com"
publisher_type: "organization"
---
```

**Resolution Process:**
1. Extract domain from URL: `https://www.nature.com/articles/nature12345`
2. Normalize: `www.nature.com` → `nature.com`
3. **Strategy 1:** Lookup `PUBLISHER_BY_DOMAIN["nature.com"]` → `"nature-publishing-group"` ✅
4. Match found immediately, skip strategies 2-4

**Result:**
```bash
PUBLISHER_ID="nature-publishing-group"
PUBLISHER_NAME="Nature Publishing Group"
PUBLISHER_TYPE="organization"
MATCH_STRATEGY="domain_exact"
```

**Generated Citation:**
```markdown
Nature Publishing Group. (2024). Climate Change Impact on Arctic Ice. Retrieved January 15, 2024, from https://www.nature.com/articles/nature12345
```

---

### Example 2: Name Exact Match (Strategy 2)

**Scenario:** Source with explicit publisher field, domain match fails.

**Source Entity (`source-arxiv-paper-456.md`):**
```yaml
---
title: "Deep Learning for NLP"
url: "https://arxiv.org/abs/2301.12345"
domain: "arxiv.org"
publisher: "arXiv"
reliability_tier: 2
access_date: "2024-02-10"
---
```

**Publisher Entity (`arxiv.md`):**
```yaml
---
name: "arXiv"
domain: "arxiv.org"
publisher_type: "organization"
---
```

**Resolution Process:**
1. **Strategy 1:** Lookup `PUBLISHER_BY_DOMAIN["arxiv.org"]` → Match found ✅
   - (In this example, domain match succeeds, so Strategy 2 not needed)

**Alternative Scenario (Domain Mismatch):**
- If publisher domain was `"cornell.edu"` instead of `"arxiv.org"`
- **Strategy 1** fails (no domain match)
- **Strategy 2:** Extract `publisher: "arXiv"` from source
- Normalize: `"arXiv"` → `arxiv`
- Lookup `PUBLISHER_BY_NAME["arxiv"]` → `"arxiv"` ✅

**Result:**
```bash
PUBLISHER_ID="arxiv"
PUBLISHER_NAME="arXiv"
PUBLISHER_TYPE="organization"
MATCH_STRATEGY="name_exact"  # (If domain failed)
```

---

### Example 3: Reverse Index Match (Strategy 3)

**Scenario:** Existing publisher entity already links to source.

**Publisher Entity (`medium-blog.md`):**
```markdown
---
name: "Medium Blog Collection"
domain: "medium.com"
publisher_type: "organization"
---

## Sources Published

- [[07-sources/data/source-medium-ai-article]]
- [[07-sources/data/source-medium-tech-post]]
```

**Source Entity (`source-medium-custom-domain.md`):**
```yaml
---
title: "AI in Healthcare"
url: "https://custom-domain.example.com/ai-healthcare"
domain: "custom-domain.example.com"
reliability_tier: 3
access_date: "2024-03-05"
---
```

**Resolution Process:**
1. **Strategy 1:** Lookup `PUBLISHER_BY_DOMAIN["custom-domain.example.com"]` → Not found ❌
2. **Strategy 2:** No `publisher:` field in source → Skip ❌
3. **Strategy 3:** Reverse index built during indexing:
   - Publisher `medium-blog.md` contains `[[07-sources/data/source-medium-ai-article]]`
   - But source is `source-medium-custom-domain` → Not in reverse index ❌
4. **Strategy 4:** Domain fallback → Success

**Note:** Strategy 3 would succeed if source_id was `source-medium-ai-article`:
```bash
PUBLISHER_BY_SOURCE["source-medium-ai-article"] = "medium-blog|Medium Blog Collection|organization"
# Lookup succeeds → PUBLISHER_ID="medium-blog"
```

---

### Example 4: Domain Fallback (Strategy 4)

**Scenario:** Personal blog with no publisher entity.

**Source Entity (`source-personal-blog-post.md`):**
```yaml
---
title: "My Thoughts on Software Development"
url: "https://john-personal-blog.com/post/software-dev"
domain: "john-personal-blog.com"
reliability_tier: 4
access_date: "2024-04-20"
---
```

**No Publisher Entity Exists for `john-personal-blog.com`**

**Resolution Process:**
1. **Strategy 1:** Lookup `PUBLISHER_BY_DOMAIN["john-personal-blog.com"]` → Not found ❌
2. **Strategy 2:** No `publisher:` field in source → Skip ❌
3. **Strategy 3:** No reverse link exists → Not found ❌
4. **Strategy 4:** Domain fallback → Always succeeds

**Result:**
```bash
PUBLISHER_ID=""  # Empty - no publisher matched
PUBLISHER_NAME=""
PUBLISHER_TYPE=""
MATCH_STRATEGY="domain_fallback"
```

**Generated Citation (No Publisher Link):**
```markdown
---
source_id: "[[07-sources/data/source-personal-blog-post]]"
publisher_id: ""  # Empty
match_strategy: "domain_fallback"
---

## Citation

(n.d.). My Thoughts on Software Development. Retrieved April 20, 2024, from https://john-personal-blog.com/post/software-dev

### Components

- **Source**: [[07-sources/data/source-personal-blog-post]]
- **Reliability**: Tier 4
- **Match Strategy**: domain_fallback
```

**Warning Generation:**
If 85% of citations use `domain_fallback`:
```json
{
  "success": true,
  "citations_created": 20,
  "publisher_matches": {
    "domain_exact": 2,
    "name_exact": 1,
    "reverse_index": 0,
    "domain_fallback": 17
  },
  "warnings": ["85% citations used domain_fallback - check publisher loading"]
}
```

---

### Example 5: Multi-Language Resolution (German)

**Scenario:** German research project with domain match.

**Source Entity (`source-bundesliga-studie.md`):**
```yaml
---
title: "Digitalisierung im deutschen Profifußball"
url: "https://www.dfb.de/news/detail/digitalisierung"
domain: "dfb.de"
reliability_tier: 2
access_date: "2024-01-15"
---
```

**Publisher Entity (`deutscher-fussball-bund.md`):**
```yaml
---
name: "Deutscher Fußball-Bund"
domain: "dfb.de"
publisher_type: "organization"
---
```

**Resolution Process:**
1. **Strategy 1:** Lookup `PUBLISHER_BY_DOMAIN["dfb.de"]` → `"deutscher-fussball-bund"` ✅
2. Match found immediately

**Result:**
```bash
PUBLISHER_ID="deutscher-fussball-bund"
PUBLISHER_NAME="Deutscher Fußball-Bund"
PUBLISHER_TYPE="organization"
MATCH_STRATEGY="domain_exact"
```

**Generated Citation (German Format):**
```markdown
Deutscher Fußball-Bund. (2024). Digitalisierung im deutschen Profifußball. Abgerufen am 15. Januar 2024, von https://www.dfb.de/news/detail/digitalisierung
```

**Key Differences from English:**
- Date format: `"Abgerufen am 15. Januar 2024"` (not `"Retrieved January 15, 2024"`)
- Month name in German: `"Januar"` (not `"January"`)
- Validation checks for `"Abgerufen am"` presence

---

## Quality Checklist

**Publisher Resolution Checklist:**
- ✅ Complete entity loading before indexing (no truncation)
- ✅ 4 lookup structures built (domain, name, reverse, fallback)
- ✅ Strategies tried in order (1 → 2 → 3 → 4)
- ✅ First successful match used (short-circuit evaluation)
- ✅ Match strategy logged in citation frontmatter
- ✅ Match statistics tracked in JSON response
- ✅ Domain fallback used when no match (no error)
- ✅ Empty publisher_id validation for strategies 1-3
- ✅ Domain_fallback percentage calculation and warning
- ✅ YAML artifacts detected and rejected
- ✅ Domain normalization applied consistently
- ✅ Name normalization applied consistently
- ✅ Publisher metadata extracted when matched
- ✅ Verification checkpoint passed before resolution

**Indexing Quality:**
- ✅ Domain map size logged: `"Indexed N publishers by domain"`
- ✅ Name map size logged: `"Indexed N publishers by name"`
- ✅ Reverse index size logged: `"Indexed N source→publisher links"`
- ✅ Each index entry logged for debugging
- ✅ Non-empty values validated before adding to index
- ✅ Proper YAML parsing (grep+sed, not grep alone)
- ✅ Quotes and whitespace stripped from extracted values

**Validation Quality:**
- ✅ Empty publisher_id rejected for non-fallback strategies
- ✅ YAML artifacts detected in domain/title/URL
- ✅ Citation text validated before writing
- ✅ Publisher file existence checked before metadata extraction
- ✅ German format validated (`"Abgerufen am"` present)
- ✅ Domain extraction produces clean values (no colons/field names)
- ✅ Errors logged to stderr without halting workflow
- ✅ Warnings generated if >80% use domain_fallback
