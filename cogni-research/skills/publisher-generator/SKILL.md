---
name: publisher-generator
description: "[Internal] Create and enrich publisher entities from source files. Invoked by deeper-research-2."
---

# Publisher Generator Skill

---

## ⛔ INVOCATION GUARD - READ BEFORE PROCEEDING

**This is an EXECUTOR skill. It should NOT be invoked directly.**

### Correct Invocation Path

```text
User → deeper-research-2 skill (ORCHESTRATOR)
       └→ Phase 6: Task tool → publisher-generator AGENT → this skill
```

### If You Are Reading This Directly

**STOP.** You likely invoked this skill directly via `Skill(skill="cogni-research:publisher-generator")`.

**What to do instead:**

1. Use the `deeper-research-2` skill instead:

   ```text
   Skill(skill="cogni-research:deeper-research-2")
   ```

2. The orchestrator will invoke this skill at the correct phase with proper context.

**Why this matters:** Direct invocation bypasses phase gates and source-creator prerequisites. Publishers require sources (Phase 4) to exist first.

---

Process source files to create and enrich publisher entities using explicit tool calls.

**CRITICAL**: This skill requires you to make ACTUAL tool calls. Do NOT simulate or claim to execute - you MUST invoke the tools specified.

---

## Operating Modes

This skill supports TWO operating modes:

### Mode A: Full Processing (Legacy)
Creates publishers from sources AND enriches them. Use `--all` or `--source-files`.

### Mode B: Enrich-Only (Recommended for Large Batches)
Only enriches existing publisher files. Use `--enrich-only --files`.
This mode is Phase B of the two-phase architecture that eliminates entity-index.json race conditions.

---

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `PROJECT_PATH` | Yes | Absolute path to research project directory |
| `--all` | No* | Process all sources in 07-sources/data/ (Mode A) |
| `--source-files` | No* | Comma-separated source file paths (Mode A) |
| `--enrich-only` | No* | Enable enrich-only mode (Mode B) |
| `--files` | No** | Comma-separated publisher file paths (Mode B only) |

*One mode required: Mode A (`--source-files` or `--all`) OR Mode B (`--enrich-only`)
**Required when using `--enrich-only`

---

## Workflow Overview

```
Phase 1: Initialize → Enumerate sources using Glob tool
Phase 2: Process   → For each source: Read → Create → Enrich → Verify
Phase 3: Return    → Output JSON metrics
```

---

## Phase 1: Initialization

### Step 1.1: Validate PROJECT_PATH

Use the Bash tool to verify the project directory exists:

```
Bash: ls -d "$PROJECT_PATH" && ls -d "$PROJECT_PATH/07-sources/data"
```

If either fails, return error JSON:
```json
{"success": false, "error": "Invalid PROJECT_PATH or missing sources directory"}
```

### Step 1.2: Enumerate Source Files

**⛔ MANDATORY TOOL CALL** - Use the Glob tool:

```
Glob: pattern="07-sources/data/source-*.md" path="$PROJECT_PATH"
```

Store the returned file paths as your SOURCE_FILES list.

**Verification**: Count the files. If 0 files found:
```json
{"success": false, "error": "No source files found", "sources_processed": 0}
```

Log the count:
```
Bash: echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Found {COUNT} source files" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

### Step 1.3: Initialize Metrics

Set these counters to 0:

- SOURCES_PROCESSED = 0
- PUBLISHERS_CREATED = 0
- PUBLISHERS_REUSED = 0
- PUBLISHERS_ENRICHED = 0
- CREATION_FAILED = 0
- ENRICHMENT_FAILED = 0
- FAILED_ITEMS = []

### Step 1.4: Pre-Loop Validation

**⛔ MANDATORY** - Verify environment before processing any source:

**Check 1: CLAUDE_PLUGIN_ROOT is set**

```
Bash: test -n "$CLAUDE_PLUGIN_ROOT" && echo "PLUGIN_ROOT_OK" || echo "PLUGIN_ROOT_MISSING"
```

If PLUGIN_ROOT_MISSING, return error:
```json
{"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set"}
```

**Check 2: generate-publisher-id.sh exists**

```
Bash: test -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" && echo "SCRIPT_OK" || echo "SCRIPT_MISSING"
```

If SCRIPT_MISSING, return error:
```json
{"success": false, "error": "generate-publisher-id.sh not found at ${CLAUDE_PLUGIN_ROOT}/scripts/utils/"}
```

**Check 3: Publishers directory exists or can be created**

```
Bash: mkdir -p "$PROJECT_PATH/08-publishers/data" && echo "DIR_OK" || echo "DIR_FAILED"
```

If DIR_FAILED, return error:
```json
{"success": false, "error": "Cannot create publishers directory at $PROJECT_PATH/08-publishers/data"}
```

**Check 4: At least one source file exists (from Step 1.2)**

If SOURCE_FILES is empty, return error (already handled in Step 1.2).

Log validation success:
```
Bash: echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Pre-loop validation passed" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

---

## Phase 2: Process Each Source

**⛔ CRITICAL**: You MUST process EVERY source file. Do NOT skip files or batch process.

For EACH source file in SOURCE_FILES, execute Steps 2.1-2.5:

### Step 2.1: Read Source File

**⛔ MANDATORY TOOL CALL** - Use the Read tool:

```
Read: file_path="$source_file"
```

Extract from YAML frontmatter:
- `domain`: Value after "domain:" (REQUIRED)
- `url`: Value after "url:"
- `title`: Value after "title:" or "dc:title:"

**If domain is empty or missing**:
- Increment CREATION_FAILED
- Add to FAILED_ITEMS: `{"source": "$filename", "stage": "extraction", "reason": "Missing domain"}`
- Continue to next source (skip Steps 2.2-2.5)

### Step 2.2: Generate Publisher ID

**⛔ CRITICAL**: You MUST use `generate-publisher-id.sh` to generate the publisher ID. Do NOT let create-entity.sh generate its own ID - the IDs will NOT match the source file's `publisher_id` wikilink.

**⛔ MANDATORY TOOL CALL** - Use the Bash tool:

```
Bash: bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" --domain "$domain" --json
```

Parse the JSON response:
- `data.publisher_id`: **SAVE THIS** - you MUST pass it to create-entity.sh via --entity-id
- `data.org_name`: Use as publisher name (properly capitalized, without TLD)

**Example response:**
```json
{"success": true, "data": {"domain": "www.computerweekly.com", "org_name": "Computerweekly", "publisher_id": "publisher-computerweekly-54e967c9"}}
```

**⛔ DO NOT:**
- Let create-entity.sh generate its own ID (random UUID)
- Compute the hash yourself
- Include the TLD in org_name (wrong: "Computerweeklycom", correct: "Computerweekly")

If the script fails, return error and skip this source - do NOT use fallback ID generation.

### Step 2.3: Check If Publisher Exists

Use the Glob tool to check for existing publisher:

```
Glob: pattern="08-publishers/data/publisher-{slug}*.md" path="$PROJECT_PATH"
```

Where {slug} is the lowercase, hyphenated org_name.

**If file exists**:
- Set REUSE = true
- Set $existing_publisher_path to the matched file path
- Continue to Step 2.3.1 (update existing publisher)

**If no file exists**:
- Set REUSE = false
- Continue to Step 2.4

### Step 2.3.1: Update Existing Publisher (REUSE case only)

**Skip this step if REUSE = false.**

When reusing an existing publisher, you MUST add the current source to its references.

**⛔ MANDATORY TOOL CALL** - Read the existing publisher:

```
Read: file_path="$existing_publisher_path"
```

Extract the source ID from the current source file (from Step 2.1):
- Look for `id:` field in the YAML frontmatter

**Check if source already linked:**
- If `source_references` array already contains `$source_id`, skip updates
- If Related Sources section already has wikilink to this source, skip updates

**If source NOT already linked, update the publisher:**

**⛔ MANDATORY TOOL CALL** - Add source to source_references array:

```
Edit: file_path="$existing_publisher_path"
      old_string="source_references: ["
      new_string="source_references: [\"$source_id\", "
```

(If source_references is empty `[]`, use: `old_string="source_references: []"` → `new_string="source_references: [\"$source_id\"]"`)

**⛔ MANDATORY TOOL CALL** - Add wikilink to Related Sources section:

```
Edit: file_path="$existing_publisher_path"
      old_string="### Related Sources"
      new_string="### Related Sources\n- [[07-sources/data/$source_id]]"
```

Increment PUBLISHERS_REUSED.
Continue to Step 2.5 (enrichment).

### Step 2.4: Create Publisher Entity

**⛔ MANDATORY TOOL CALL** - Use the Bash tool with create-entity.sh:

**First**, extract the source ID from the source file you read in Step 2.1:
- Look for `id:` field in the YAML frontmatter (e.g., `id: source-it-ot-konvergenz-erh-oht-sicherheitsrisiken-bei-2425d471`)
- This is `$source_id` - you need it for source_references and wikilinks

Prepare the entity JSON using values from Step 2.2:

```json
{
  "frontmatter": {
    "entity_type": "publisher",
    "publisher_type": "organization",
    "name": "$org_name",
    "domain": "$domain",
    "enriched": false,
    "enrichment_status": "pending",
    "source_references": ["$source_id"],
    "tags": ["publisher", "publisher-type/organization"]
  },
  "content": "## Publisher: $org_name\n\n**Domain**: $domain\n\n### Related Sources\n- [[07-sources/data/$source_id]]"
}
```

**⛔ CRITICAL**: Pass the publisher_id from Step 2.2 via --entity-id:

```
Bash: bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "08-publishers" \
  --entity-id "$publisher_id" \
  --data '$ENTITY_JSON' \
  --json
```

**Parse response** for `entity_path`.

**⛔ VERIFICATION GATE** - Use Read tool to confirm file exists AND has correct content:

```
Read: file_path="$entity_path"
```

Verify:
- File exists at expected path (08-publishers/data/$publisher_id.md)
- `source_references` array contains the source ID
- `name` field is properly capitalized (no TLD like "com")
- Related Sources section has wikilink to source

If file does NOT exist or content is wrong:
- Increment CREATION_FAILED
- Add to FAILED_ITEMS: `{"source": "$source_id", "stage": "creation", "reason": "File not created or invalid"}`
- Continue to next source

If file exists with correct content:
- Increment PUBLISHERS_CREATED

### Step 2.5: Enrich Publisher

Determine the publisher file path:
- If REUSE = true: use `$existing_publisher_path`
- If REUSE = false: use `$entity_path` from Step 2.4

**First, check if already enriched:**
- If publisher has `enriched: true`, skip enrichment and continue to Step 2.6

**⛔ MANDATORY TOOL CALL** - Use WebSearch tool:

```
WebSearch: query="$org_name company about mission"
```

Extract from search results:
- 2-4 sentences about the organization
- Focus on: mission, expertise, credibility
- If no useful results, set $ENRICHMENT_TEXT = "Publisher information not available from web sources."

**⛔ MANDATORY TOOL CALL** - Update enrichment status:

```
Edit: file_path="$publisher_file"
      old_string="enriched: false"
      new_string="enriched: true"
```

**⛔ MANDATORY TOOL CALL** - Update enrichment_status:

```
Edit: file_path="$publisher_file"
      old_string="enrichment_status: pending"
      new_string="enrichment_status: success"
```

**⛔ MANDATORY TOOL CALL** - Add context section:

```
Edit: file_path="$publisher_file"
      old_string="### Related Sources"
      new_string="### Context\n\n$ENRICHMENT_TEXT\n\n### Related Sources"
```

**⛔ POST-ENRICHMENT VERIFICATION GATE** - Use Read tool to confirm updates:

```
Read: file_path="$publisher_file"
```

Verify ALL of the following:
- `enriched: true` is set
- `enrichment_status: success` (or `failed` if no results)
- Context section exists between Domain and Related Sources

**If verification fails:**
- Retry the failed Edit tool call
- If still failing after retry, set enrichment_status to "failed"
- Increment ENRICHMENT_FAILED
- Log: `"$publisher_id enrichment verification failed"`

**If verification passes:**
- Increment PUBLISHERS_ENRICHED

### Step 2.6: Log Progress

**⛔ MANDATORY** - Log after EACH source:

```
Bash: echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Processed: $source_filename → $publisher_id" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

Increment SOURCES_PROCESSED.

### Step 2.7: Update TodoWrite

After every 10 sources, update TodoWrite to show progress:
- "Processing sources: {SOURCES_PROCESSED}/{TOTAL} complete"

---

## Phase 3: Return Metrics

After processing ALL sources, return this JSON:

```json
{
  "success": true,
  "sources_processed": $SOURCES_PROCESSED,
  "publishers_created": $PUBLISHERS_CREATED,
  "publishers_reused": $PUBLISHERS_REUSED,
  "publishers_enriched": $PUBLISHERS_ENRICHED,
  "creation_failed": $CREATION_FAILED,
  "enrichment_failed": $ENRICHMENT_FAILED,
  "resolution_mode": "all-sources",
  "failed_items": $FAILED_ITEMS
}
```

**Final log entry**:
```
Bash: echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [PHASE] ========== publisher-generator Completed ==========" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

---

## Anti-Hallucination Enforcement

**⛔ YOU MUST NOT:**

- Claim to process files without using Read tool
- Claim to create entities without using Bash tool with create-entity.sh
- Claim to enrich without using WebSearch tool
- Report success metrics without actual tool calls
- Skip the verification gate after entity creation
- Generate publisher IDs yourself - MUST use generate-publisher-id.sh
- Let create-entity.sh generate random UUIDs - MUST pass --entity-id
- Create publishers without source_references populated
- Skip enrichment verification

**⛔ VERIFICATION CHECKLIST (answer YES to all before returning):**

- [ ] Did I run pre-loop validation (Step 1.4)?
- [ ] Did I use Glob to enumerate source files?
- [ ] Did I use Read on EACH source file?
- [ ] Did I use Bash with generate-publisher-id.sh for EACH publisher ID?
- [ ] Did I pass --entity-id to create-entity.sh for EACH new publisher?
- [ ] Did I use Read to verify EACH created file exists with correct content?
- [ ] Does EACH publisher have source_references populated (not empty [])?
- [ ] Does EACH publisher have wikilinks in Related Sources section?
- [ ] Did I use WebSearch for EACH publisher enrichment?
- [ ] Did I use Edit to update EACH publisher with enrichment?
- [ ] Did I verify enrichment with Read tool (enriched: true)?
- [ ] Does my log file have one entry per source processed?

**IF ANY ANSWER IS "NO"**: You have failed. Go back and execute the missing tool calls.

---

## Allowed Tools

- **Glob**: Enumerate source files, check for existing publishers
- **Read**: Read source files, verify created entities
- **Bash**: Create entities via create-entity.sh, log progress
- **Edit**: Update publishers with enrichment data
- **WebSearch**: Research publishers for enrichment
- **TodoWrite**: Track progress

**⛔ PROHIBITED:**
- Write tool for entity files (use create-entity.sh instead)
- Simulating tool calls without execution
- Skipping verification steps

---

## Error Handling

| Error | Action |
|-------|--------|
| Source missing domain | Skip source, log failure, continue |
| create-entity.sh fails | Log failure, continue to next source |
| WebSearch returns nothing | Use minimal context, mark enrichment_status: "failed" |
| File verification fails | Log failure, continue to next source |

**Always continue processing remaining sources** - do not fail-fast.

---

## Mode B: Enrich-Only Workflow

This mode is used after `create-publishers-batch.py` has created skeleton publishers.
It ONLY enriches existing publishers - no entity creation, no entity-index.json writes.

### Mode B Parameters

```
PROJECT_PATH --enrich-only --files {comma-separated-publisher-paths}
```

Example:
```
/path/to/project --enrich-only --files 08-publishers/data/publisher-gartner-abc123.md,08-publishers/data/publisher-forrester-def456.md
```

### Mode B Workflow

#### Step B.1: Parse Publisher Files

Split the `--files` parameter by comma to get the list of publisher file paths.

#### Step B.2: Initialize Metrics

```
PUBLISHERS_ENRICHED = 0
ENRICHMENT_FAILED = 0
FAILED_ITEMS = []
```

#### Step B.3: Process Each Publisher

For EACH publisher file in the list:

**B.3.1: Read Publisher File**

```
Read: file_path="$PROJECT_PATH/$publisher_path"
```

Extract from YAML frontmatter:
- `name`: Publisher/organization name
- `domain`: Domain string
- `publisher_type`: "organization" or "individual"
- `enriched`: Check if already enriched

**If `enriched: true`**: Skip this publisher, continue to next.

**B.3.2: WebSearch Enrichment**

```
WebSearch: query="$name company about mission"
```

For individuals: `query="$name $affiliation expertise background"`

Extract from search results:
- 2-4 sentences about the organization/individual
- Focus on: mission, expertise, credibility

**B.3.3: Update Publisher**

```
Edit: file_path="$publisher_path"
      old_string="enriched: false"
      new_string="enriched: true"
```

```
Edit: file_path="$publisher_path"
      old_string="enrichment_status: \"pending\""
      new_string="enrichment_status: \"success\""
```

```
Edit: file_path="$publisher_path"
      old_string="### Related Sources"
      new_string="### Context\n\n$ENRICHMENT_TEXT\n\n### Related Sources"
```

**B.3.4: Verify Enrichment**

```
Read: file_path="$publisher_path"
```

Verify:
- `enriched: true` is set
- `enrichment_status: success` (or `failed`)
- Context section exists

If verification passes: Increment PUBLISHERS_ENRICHED
If verification fails: Increment ENRICHMENT_FAILED, add to FAILED_ITEMS

### Mode B Return

```json
{
  "success": true,
  "mode": "enrich-only",
  "publishers_enriched": $PUBLISHERS_ENRICHED,
  "enrichment_failed": $ENRICHMENT_FAILED,
  "failed_items": $FAILED_ITEMS
}
```

### Mode B Allowed Tools

- **Read**: Read publisher files
- **Edit**: Update publishers with enrichment data
- **WebSearch**: Research publishers
- **TodoWrite**: Track progress

**⛔ Mode B PROHIBITED:**
- Bash with create-entity.sh (entities already exist)
- Glob (file list provided explicitly)
- Write tool
- Any entity-index.json modifications
