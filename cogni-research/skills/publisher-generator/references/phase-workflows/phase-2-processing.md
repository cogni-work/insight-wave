# Phase 2: Process Each Source

Process every source file: read metadata, create publisher, enrich, verify.

**⛔ CRITICAL**: You MUST execute tool calls for EVERY source. Do NOT skip sources or claim to batch process.

---

## Processing Loop

For EACH file in SOURCE_FILES, execute Steps 2.1 through 2.6.

**Progress tracking**: After every 10 sources, use TodoWrite to update:
- "Processing sources: {SOURCES_PROCESSED}/{TOTAL_SOURCES} complete"

---

## Step 2.1: Read Source File

**⛔ MANDATORY TOOL CALL** - Use Read tool:

```text
Read: file_path="{source_file_path}"
```

From the file content, extract YAML frontmatter fields:

- `domain`: Line starting with "domain:" - **REQUIRED**
- `url`: Line starting with "url:"
- `title`: Line starting with "title:" or "dc:title:"
- `source_id`: Filename without .md extension (e.g., "source-example-abc12345")

**If domain is empty or not found**:

1. Increment CREATION_FAILED
2. Add to FAILED_ITEMS:
   ```json
   {"source": "{filename}", "stage": "extraction", "reason": "Missing domain field"}
   ```
3. Log failure using Bash:
   ```bash
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [WARN] Skipping {filename}: missing domain" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
   ```
4. **Continue to next source** (skip Steps 2.2-2.6)

---

## Step 2.2: Generate Publisher ID

**⛔ MANDATORY TOOL CALL** - Use Bash tool:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" --domain "{domain}" --json
```

Parse the JSON response to extract:
- `publisher_id`: e.g., "publisher-example-abc12345"
- `org_name`: e.g., "Example"

**If script fails**, use fallback logic:
1. org_name = Capitalize first segment of domain (before first dot)
2. slug = lowercase org_name with spaces as hyphens
3. hash = first 8 characters of MD5 hash of org_name
4. publisher_id = "publisher-{slug}-{hash}"

---

## Step 2.3: Check If Publisher Exists

**⛔ MANDATORY TOOL CALL** - Use Glob tool:

```text
Glob: pattern="08-publishers/data/publisher-{slug}*.md" path="$PROJECT_PATH"
```

Where `{slug}` is the lowercase hyphenated org_name (e.g., "example" from "Example").

**If Glob returns 1+ files**:
- Set REUSE = true
- Store existing file path as publisher_file
- Increment PUBLISHERS_REUSED
- **Skip to Step 2.5** (only append source reference)

**If Glob returns 0 files**:
- Set REUSE = false
- Continue to Step 2.4

---

## Step 2.4: Create Publisher Entity

**⛔ MANDATORY TOOL CALL** - Use Bash tool with create-entity.sh:

First, construct the entity data JSON:

```json
{
  "frontmatter": {
    "entity_type": "publisher",
    "publisher_type": "organization",
    "name": "{org_name}",
    "domain": "{domain}",
    "enriched": false,
    "enrichment_status": "pending",
    "source_references": ["{source_id}"],
    "tags": ["publisher", "publisher-type/organization"],
    "dc:creator": "publisher-generator",
    "dc:created": "{ISO8601_TIMESTAMP}"
  },
  "content": "## Publisher: {org_name}\n\n**Domain**: {domain}\n\n### Related Sources\n\n- [[{source_id}]]"
}
```

Then execute:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "{PROJECT_PATH}" \
  --entity-type "08-publishers" \
  --data '{ENTITY_JSON}' \
  --json
```

**Parse the response** to get `entity_path`.

### Verification Gate

**⛔ MANDATORY TOOL CALL** - Use Read tool to verify file exists:

```text
Read: file_path="{entity_path}"
```

**If Read fails** (file not found):
1. Increment CREATION_FAILED
2. Add to FAILED_ITEMS:
   ```json
   {"source": "{source_id}", "publisher": "{publisher_id}", "stage": "creation", "reason": "File not created"}
   ```
3. **Continue to next source** (skip Steps 2.5-2.6)

**If Read succeeds**:
- Increment PUBLISHERS_CREATED
- Store entity_path as publisher_file

---

## Step 2.5: Enrich Publisher

### 2.5.1: Web Search

**⛔ MANDATORY TOOL CALL** - Use WebSearch tool:

```text
WebSearch: query="{org_name} company about mission expertise"
```

From search results, extract 2-4 sentences describing:
- What the organization does
- Their area of expertise
- Credibility/reputation (if available)

**If search returns no useful results**:
- Use minimal context: "Publisher information not available from public sources."
- Set enrichment_status = "failed"
- Increment ENRICHMENT_FAILED

### 2.5.2: Update Publisher - Mark Enriched

**⛔ MANDATORY TOOL CALL** - Use Edit tool:

```text
Edit: file_path="{publisher_file}"
      old_string="enriched: false"
      new_string="enriched: true"
```

### 2.5.3: Update Publisher - Add Context

**⛔ MANDATORY TOOL CALL** - Use Edit tool:

```text
Edit: file_path="{publisher_file}"
      old_string="### Related Sources"
      new_string="### Context\n\n{ENRICHMENT_TEXT}\n\n### Related Sources"
```

Where `{ENRICHMENT_TEXT}` is the 2-4 sentences from web search.

### 2.5.4: Update Enrichment Status

**⛔ MANDATORY TOOL CALL** - Use Edit tool:

```text
Edit: file_path="{publisher_file}"
      old_string="enrichment_status: \"pending\""
      new_string="enrichment_status: \"success\""
```

(Or "failed" if web search returned nothing useful)

Increment PUBLISHERS_ENRICHED.

---

## Step 2.6: Log Progress

**⛔ MANDATORY TOOL CALL** - Use Bash tool:

```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Processed: {source_filename} → {publisher_id} (created={!REUSE})" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

Increment SOURCES_PROCESSED.

---

## Phase 2 Completion Checklist

After processing ALL sources, verify:

- [ ] SOURCES_PROCESSED equals TOTAL_SOURCES
- [ ] Every source had Read tool called
- [ ] Every new publisher had Bash (create-entity.sh) called
- [ ] Every publisher had WebSearch called for enrichment
- [ ] Every publisher had Edit tools called to update enrichment
- [ ] Log file has one entry per source

**Count verification**:
```text
SOURCES_PROCESSED should equal:
  PUBLISHERS_CREATED + PUBLISHERS_REUSED + CREATION_FAILED
```

---

## Proceed to Phase 3

After completing all sources and verification, proceed to Phase 3: Return Metrics.
