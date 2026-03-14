# Publisher ID Generation

This reference provides comprehensive guidance for generating deterministic, unique publisher IDs with cross-platform compatibility.

## ⚠️ CRITICAL: Organization Publishers Must Use generate-publisher-id.sh

**For organization publishers (domain-based)**, you MUST use the shared `generate-publisher-id.sh` utility to ensure ID consistency with source-creator.sh.

**Why this matters:** source-creator.sh generates provisional publisher IDs (wikilinks) using `generate-publisher-id.sh`. If publisher-generator uses a different ID algorithm, the wikilinks in source files will be broken and publishers will appear to have no linked sources.

### Required Implementation for Organization Publishers

```bash
# For organization publishers (domain-based), use the shared utility
PUBLISHER_ID_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" \
  --domain "$domain" \
  --json 2>&1)

if [ $? -eq 0 ]; then
  PUBLISHER_ID=$(echo "$PUBLISHER_ID_RESULT" | jq -r '.data.publisher_id')
  ORG_NAME=$(echo "$PUBLISHER_ID_RESULT" | jq -r '.data.org_name')
  log_conditional INFO "  Generated publisher ID: $PUBLISHER_ID (org: $ORG_NAME)"
else
  # DO NOT use fallback - skip this source instead
  log_conditional ERROR "generate-publisher-id.sh failed for domain: $domain"
  # Add to FAILED_ITEMS and continue to next source
fi
```

### ⛔ CRITICAL: Pass --entity-id to create-entity.sh

When calling create-entity.sh to create the publisher file, you **MUST** pass the generated publisher ID via the `--entity-id` parameter. If you omit this, create-entity.sh will generate a random UUID which will NOT match the source file's `publisher_id` wikilink.

**Correct:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "08-publishers" \
  --entity-id "$PUBLISHER_ID" \
  --data "$ENTITY_JSON" \
  --json
```

**WRONG (will break wikilinks):**
```bash
# Missing --entity-id - create-entity.sh will generate random UUID!
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "08-publishers" \
  --data "$ENTITY_JSON" \
  --json
```

**Individual publishers** (author-based) continue to use the standard slug+hash algorithm documented below.

### ⛔ CRITICAL ENFORCEMENT: Actual Bash Execution Required

**DO NOT simulate or manually compute hashes.** You MUST execute the actual bash command using the Bash tool:

```bash
PUBLISHER_ID_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" \
  --domain "$domain" \
  --json 2>&1)
```

**Verification:** After execution, verify the JSON response contains:

- `success: true`
- `data.publisher_id` field with format `publisher-{slug}-{hash}`
- `data.org_name` field with capitalized organization name

**IF YOU ARE TEMPTED TO:**

- Compute the hash yourself → ✗ WRONG, use the script
- Use a different algorithm → ✗ WRONG, use the script
- Skip calling the script → ✗ WRONG, use the script

**The script is the single source of truth for organization publisher IDs.**

---

## ID Format

**Pattern:** `publisher-<slug>-<hash>`

**Example:** `publisher-john-smith-a3f8e9c2`

**Components:**
1. **Prefix:** `publisher-` (constant)
2. **Slug:** Normalized name converted to URL-safe format
3. **Hash:** 8-character hash of original name for uniqueness

## Slug Generation

**Purpose:** Create human-readable, filesystem-safe identifier from publisher name

**Process:**

1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove all non-alphanumeric characters except hyphens
4. Collapse consecutive hyphens to single hyphen

**Bash Implementation:**

```bash
# Input: pub_name="John Smith"
slug=$(echo "$pub_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g')
# Output: slug="john-smith"
```

**Examples:**

| Input Name | Slug |
|------------|------|
| John Smith | john-smith |
| World Health Organization | world-health-organization |
| O'Neill, P. | oneill-p |
| García-López | garcia-lopez |
| MIT (Mass. Inst. Tech.) | mit-mass-inst-tech |

## Hash Generation

**Purpose:** Add uniqueness to prevent collisions from similar names

**Requirements:**
- Deterministic (same name always produces same hash)
- 8 characters (balance between uniqueness and readability)
- Cross-platform compatible (macOS, Linux, Windows)

### Method 1: MD5 (Bash - Cross-Platform)

**macOS:**
```bash
# macOS uses 'md5' command
hash=$(echo "$pub_name" | md5 | cut -c1-8)
```

**Linux:**
```bash
# Linux uses 'md5sum' command
hash=$(echo "$pub_name" | md5sum | cut -c1-8)
```

**Cross-Platform Detection:**
```bash
# Detect OS and use appropriate command
if command -v md5sum &> /dev/null; then
  # Linux
  hash=$(echo "$pub_name" | md5sum | cut -c1-8)
elif command -v md5 &> /dev/null; then
  # macOS
  hash=$(echo "$pub_name" | md5 | cut -c1-8)
else
  echo "Error: No MD5 command available"
  exit 1
fi
```

**CRITICAL:** The `echo` command (WITHOUT `-n` flag) includes a trailing newline in the hash input. This is intentional for backward compatibility with existing publisher files. All publisher ID generation MUST use `echo` (not `echo -n`) for consistency with `generate-publisher-id.sh`.

### Method 2: Python (Truly Portable)

**Recommended for maximum portability:**

```bash
# Works on any system with Python 3
hash=$(python3 -c "import hashlib; print(hashlib.md5(b'$pub_name').hexdigest()[:8])")
```

**Advantages:**
- Python available on all modern systems
- No OS detection needed
- Consistent behavior across platforms

**Example:**
```bash
pub_name="John Smith"
hash=$(python3 -c "import hashlib; print(hashlib.md5(b'$pub_name').hexdigest()[:8])")
# Output: a3f8e9c2 (consistent every time)
```

### Method 3: SHA256 (Alternative)

**If MD5 is unavailable:**

```bash
# macOS and Linux both support shasum
hash=$(echo "$pub_name" | shasum -a 256 | cut -c1-8)
```

**Note:** SHA256 is cryptographically stronger but overkill for this use case. MD5 is sufficient for ID generation (not cryptographic security).

## Complete ID Generation

**Full Implementation:**

```bash
# Input: pub_name="John Smith"

# 1. Generate slug
slug=$(echo "$pub_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g')

# 2. Generate hash (portable method)
hash=$(python3 -c "import hashlib; print(hashlib.md5(b'$pub_name').hexdigest()[:8])")

# 3. Construct ID
publisher_id="publisher-${slug}-${hash}"

# 4. Construct file path
publisher_file="${PROJECT_PATH}/08-publishers/data/${publisher_id}.md"

# Output:
# publisher_id="publisher-john-smith-a3f8e9c2"
# publisher_file="/path/to/project/08-publishers/data/publisher-john-smith-a3f8e9c2.md"
```

## Collision Handling

**Why 8-character hash?**

- 8 hex characters = 4.3 billion possible values
- For publisher names, collision probability is negligible
- Even with 10,000 publishers, collision chance < 0.01%

**If collision occurs:**

Publisher names that produce identical slugs will have different hashes:
- "John Smith" → `publisher-john-smith-a3f8e9c2`
- "John Smith" (same person, duplicate) → Same ID (intentional deduplication)
- "Jon Smith" (different person) → `publisher-jon-smith-b7d4c1e8` (different hash)

**Deduplication logic** (see Step 2.3) checks for existing publishers by slug prefix, allowing detection of potential duplicates.

## Edge Cases

### Case 1: Very Long Names

**Input:** "International Federation of Library Associations and Institutions"

**Result:**
- Slug: `international-federation-of-library-associations-and-institutions` (60+ chars)
- Hash: `e4f2a9d1`
- ID: `publisher-international-federation-of-library-associations-and-institutions-e4f2a9d1`

**Note:** No length limit enforced. Filesystem can handle long filenames (255 chars on most systems).

### Case 2: Non-ASCII Characters

**Input:** "García Martínez"

**Process:**
1. Lowercase: `garcía martínez`
2. Replace spaces: `garcía-martínez`
3. Remove non-alphanumeric: `garca-martnez` (accents removed)
4. Hash: Based on original name (preserves uniqueness)

**Result:** `publisher-garca-martnez-<hash>`

**Note:** Hash is computed from original name including accents, ensuring different hashes for "García" vs "Garcia".

### Case 3: Special Characters Only

**Input:** "O'Neill & Associates, Inc."

**Process:**
1. Lowercase: `o'neill & associates, inc.`
2. Replace spaces: `o'neill-&-associates,-inc.`
3. Remove non-alphanumeric: `oneill-associates-inc`

**Result:** `publisher-oneill-associates-inc-<hash>`

### Case 4: Empty Slug

**Input:** "123" (numbers only, but algorithm removes them)

**Process:**
1. Lowercase: `123`
2. No spaces to replace
3. Remove non-alphanumeric: `` (empty)

**Handling:**
```bash
if [ -z "$slug" ]; then
  # Use hash only as fallback
  slug="unknown"
fi
publisher_id="publisher-${slug}-${hash}"
```

**Result:** `publisher-unknown-<hash>`

## Integration with Deduplication

**In Step 2.3 (Create Publisher Entities):**

1. Generate deterministic ID from publisher name
2. Check for existing publisher with same slug prefix:
   ```bash
   ls "${PROJECT_PATH}/08-publishers/data/publisher-${slug}-"*.md 2>/dev/null | head -1
   ```
3. If match found: Reuse existing publisher (deduplication)
4. If no match: Create new publisher with generated ID

**Glob Pattern Explanation:**
- `publisher-${slug}-`: Matches slug prefix
- `*.md`: Matches any hash suffix
- Finds existing publishers with same normalized name

## Validation

**After generating ID, validate:**

- [ ] ID starts with `publisher-`
- [ ] Slug contains only lowercase letters, numbers, hyphens
- [ ] Hash is exactly 8 hexadecimal characters
- [ ] Total length < 255 characters (filesystem limit)
- [ ] File path is valid and writable

## Performance

**ID generation timing:**
- Slug generation: < 1ms
- Hash generation (Python): < 5ms
- Total: < 10ms per publisher

**For 20 sources with avg 2 publishers each:**
- Total ID generation time: < 400ms
- Negligible compared to web search enrichment (5-10 seconds per publisher)

## Troubleshooting

### Issue: Hash changes between invocations

**Cause:** Inconsistent newline handling (mixing `echo -n` with `echo`)

**Fix:** Always use `echo` (WITH newline) to match `generate-publisher-id.sh`. The newline is intentionally included for backward compatibility.

### Issue: Different hashes on macOS vs Linux

**Cause:** Using OS-specific MD5 commands without detection

**Fix:** Use Python method (Method 2) for consistent cross-platform behavior

### Issue: Collision detected

**Cause:** Two different names producing same slug and hash (extremely rare)

**Fix:**
1. Check if names are actually identical (intended deduplication)
2. If truly different names, manually rename one in source data
3. Log collision for investigation

### Issue: Invalid characters in slug

**Cause:** Special characters not properly removed

**Fix:** Verify sed pattern includes all special character removal: `sed 's/[^a-z0-9-]//g'`
