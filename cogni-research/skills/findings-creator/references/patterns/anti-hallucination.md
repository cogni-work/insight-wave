---
reference: anti-hallucination
version: 1.8.0
changelog: |
  v1.8.0: Added Pattern 17 (Content Fidelity Verification) - validate snippet-only mode doesn't exceed snippet scope; Extended Pattern 16 with unnamed_statistic_mismatch detection
  v1.7.0: Added Pattern 16 (Content-URL Coherence) - validate generated content matches attributed source URL to prevent training data hallucinations
  v1.6.0: Added Pattern 15 (Phase 5 Statistics Safe Output) - prevent zsh parse errors by separating command substitution from semicolons
  v1.5.0: Added Pattern 14 (Python Heredoc Variable Passing) - use sys.argv instead of os.environ for passing shell variables to Python heredocs
  v1.4.0: Added Pattern 13 (Shell Quoting Safety) and updated Pattern 12 to use heredoc+stdin for shell-safe JSON passing
  v1.3.0: Added Pattern 11 (Bash Variable Definition) and Pattern 12 (Entity Creation Tool Selection) to prevent undefined LOG_FILE errors and heredoc entity creation
  v1.2.0: Added Pattern 7-10 for fake URL detection and snippet-only content constraints
---

# Anti-Hallucination Patterns for Findings Creator

This skill implements 17 core anti-hallucination patterns from the deeper-research framework.

## Pattern 1: Complete Entity Loading

**Principle:** Load complete entities before processing to ensure all required information is available.

**Application in findings-creator:**
- Phase 1: Load complete refined question entity before query generation
- Phase 3: Load complete batch entity before search execution
- Phase 4: Load complete finding template before entity creation

**Implementation:**
```bash
# Load complete entity
entity_content=$(cat "$entity_path")

# Verify entity loaded
if [ -z "$entity_content" ]; then
  log_conditional ERROR "Failed to load entity: $entity_path"
  exit 1
fi
```

## Pattern 2: Verification Checkpoints

**Principle:** Validate outputs at each phase gate before proceeding.

**Application in findings-creator:**
- Phase gates: Verify required outputs from previous phase exist
- UUID validation: Verify query_id format matches specification
- Entity validation: Verify created entities exist on filesystem
- Count validation: Verify FINDINGS_CREATED > 0

**Implementation:**
```bash
# Phase gate check (zsh-compatible - no array syntax)
if [ -z "${QUERY_COUNT:-}" ] || [ "$QUERY_COUNT" -eq 0 ]; then
  log_conditional ERROR "Phase 1 incomplete: QUERY_COUNT not set"
  exit 1
fi
```

## Pattern 3: Evidence-Based Processing

**Principle:** All content must come from loaded sources, never fabricated.

**Application in findings-creator:**
- Query generation: Based on question text and metadata only
- Finding extraction: Content from search results only
- Wikilink creation: Referenced entities must exist in entity index

**Critical Rules:**
- Never invent search results
- Never fabricate metadata
- Never create wikilinks to non-existent entities

## Pattern 4: No Fabrication Rule

**Principle:** When searches fail or data is missing, explicitly state this rather than inventing content.

**Application in findings-creator:**
- Phase 3: If WebSearch returns no results, log "No results" and apply fallback
- Phase 4: If no findings can be extracted, exit with code 6 (not success)
- Never create "placeholder" findings with invented content

**Implementation:**
```bash
if [ "$usable_count" -eq 0 ]; then
  log_conditional WARN "No usable results for query: $query_text"
  # Apply fallback or skip, never fabricate
fi
```

## Pattern 5: Provenance Integrity

**Principle:** All wikilinks must reference actual entities that exist in the workspace.

**Application in findings-creator:**
- Validate batch_id wikilink before creating findings
- Validate dimension_id wikilink before creating findings
- Validate refined_question_id wikilink before creating findings
- All validation against entity-index.json

**Implementation:**
```bash
# Validate wikilink
entity_path=$(echo "$wikilink" | sed 's/\[\[\(.*\)\]\]/\1/')

if ! jq -e ".entities[] | select(.path == \"$entity_path\")" "$entity_index" > /dev/null; then
  log_conditional ERROR "Invalid wikilink: $wikilink"
  exit 1
fi
```

## Pattern 6: No Empty Placeholder Files

**Principle:** Never create empty files as "placeholders" or "fixes" for failed entity creation.

**Application in findings-creator:**

- Phase 2: If create-entity.sh fails, exit with 122 - DO NOT create empty batch file
- Phase 4: If create-entity.sh fails, exit with 131 - DO NOT create empty finding file
- Never use Write tool to "fix" missing files - this breaks evidence chains

**Why This Matters:**

Empty batch files (0 bytes) break the synthesis phase because:

1. Findings reference batch_ref wikilinks pointing to empty files
2. Dimension-synthesizer cannot extract query metadata from empty files
3. Evidence chain is broken (finding → batch → question)

**Implementation:**

```bash
# Verify batch file has content (not empty)
file_size=$(wc -c < "$entity_file" | tr -d ' ')
if [ "$file_size" -eq 0 ]; then
  log_conditional ERROR "Entity file is empty (0 bytes): $entity_file"
  exit 122  # MUST fail - do NOT create placeholder
fi

# Verify minimum expected content size
if [ "$file_size" -lt 500 ]; then
  log_conditional ERROR "Entity file too small ($file_size bytes): $entity_file"
  exit 122  # MUST fail - incomplete entity
fi
```

**Critical Rules:**

- Never use Write tool to create empty batch or finding files
- If entity creation fails, the phase MUST fail with appropriate exit code
- The orchestrating skill will retry or handle the failure
- Empty files are worse than missing files (they silently break downstream processing)

---

## Checksum Verification

Each phase workflow file includes a verification checksum that MUST be output after reading to confirm the complete workflow was loaded:

- Phase 1: `phase-1-query-optimization-v1.0.0-a1b2c3d4`
- Phase 2: `phase-2-batch-creation-v1.0.0-b2c3d4e5`
- Phase 3: `phase-3-search-execution-v1.0.0-c3d4e5f6`
- Phase 4: `phase-4-finding-extraction-v1.0.0-d4e5f6a7`

**Purpose:** Observable confirmation that reference files were read completely.

## See Also

- [../../research-executor/references/patterns/anti-hallucination.md](../../research-executor/references/patterns/anti-hallucination.md) - Original implementation
- [../../research-query-optimizer/SKILL.md](../../research-query-optimizer/SKILL.md) - Query optimization patterns

## Pattern 7: Fake URL Detection

**Principle:** Detect and reject URLs that appear to be fabricated rather than returned by WebSearch.

**Application in findings-creator:**

- Phase 4, Step 4.3.7: Validate URLs before content generation
- Reject generic placeholder domains (example.com, beispiel.de, test.com)
- Reject suspiciously clean URL paths (real URLs are messier)
- Flag generic institutional-sounding domains for review

**Known Fabrication Patterns:**

| Pattern | Examples | Action |
|---------|----------|--------|
| Generic placeholders | example.com, beispiel.de, muster.de | Reject |
| Clean paths | /agile-fuehrung, /ai-copilots | Reject |
| Fake institutions | research-center.de, study-institute.org | Flag |
| Localhost/test | localhost, test.com, demo.example | Reject |

**Implementation:**

```bash
cat > /tmp/fc-validate-url.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Reject known fake URL patterns
if [[ "$url" =~ (example\.com|beispiel\.|muster\.|test\.com) ]]; then
  log_conditional ERROR "FABRICATION DETECTED: Fake URL pattern: $url"
  continue
fi
SCRIPT_EOF
chmod +x /tmp/fc-validate-url.sh && bash /tmp/fc-validate-url.sh
```

## Pattern 8: Content Sufficiency Gate

**Principle:** Skip finding creation when source content is insufficient rather than fabricating content.

**Application in findings-creator:**

- Phase 4, Step 4.3.7.2: Check content length before generation
- Minimum 100 characters for snippet-only mode
- Minimum 200 characters for WebFetch content
- Log all skipped findings to `.metadata/skipped-findings.json`

**Critical Rule:** It is BETTER to skip a finding than to fabricate one. Empty results are honest; fabricated results destroy research integrity.

**Implementation:**

```bash
if [ "$content_source" == "snippet" ] && [ ${#enhanced_content} -lt 100 ]; then
  log_conditional ERROR "INSUFFICIENT CONTENT: Cannot generate without fabricating"
  continue  # Skip - do NOT fabricate
fi
```

## Pattern 9: Snippet-Only Mode Constraints

**Principle:** When webfetch_success=false, strictly limit content to what's in the original snippet.

**Application in findings-creator:**

- Phase 4, Step 4.3.7.4: Enforce content constraints when WebFetch fails
- PROHIBIT: Invented statistics, fabricated studies, made-up methodology
- ALLOW: Direct quotes, paraphrasing, neutral summary, explicit disclaimers

**Snippet-Only Content Rules:**

| Section | Constraint |
|---------|------------|
| Content | Direct paraphrase only (no elaboration) |
| Key Trends | Only extract what's explicitly in snippet |
| Methodology | MUST include disclaimer about missing content |
| Source | Add note: "Full content not retrieved" |

**Validation:**

```bash
# Detect fabrication: more stats in content than in snippet
if [ $content_stats -gt $snippet_stats ]; then
  log_conditional ERROR "FABRICATION DETECTED: Statistics invented"
  continue
fi
```

## Pattern 10: Source Verification

**Principle:** Verify that finding URLs actually came from WebSearch results, not fabricated.

**Application in findings-creator:**

- Phase 4, Step 4.3.7.3: Cross-reference URLs against search results
- Track all URLs returned by WebSearch
- Reject findings with URLs not in search results

**Implementation:**

```bash
# Verify URL came from WebSearch (zsh-compatible - using numbered variables)
url_verified=false
i=1
while [ "$i" -le "$SEARCH_RESULT_COUNT" ]; do
  eval "search_url=\$SEARCH_URL_$i"
  if [ "$url" = "$search_url" ]; then
    url_verified=true
    break
  fi
  i=$((i + 1))
done

if [ "$url_verified" = "false" ]; then
  log_conditional ERROR "URL not from search results - may be hallucinated"
  continue
fi
```

## Pattern 11: Bash Variable Definition Enforcement

**Principle:** All bash variables referenced in generated scripts MUST be defined before use. Undefined variables cause silent failures or cryptic errors.

**Application in findings-creator:**

- Phase 0: MUST define LOG_FILE before any logging statements
- All phases: Variables like PROJECT_PATH, ENTITY_DIR, BATCH_ID must be set before use
- Each Bash tool invocation starts a fresh shell - variables are NOT preserved between calls

**Why This Matters:**

When a script references `$LOG_FILE` without defining it:

1. Bash expands `$LOG_FILE` to empty string
2. `>> ""` tries to redirect to an empty filename
3. Shell error: `no such file or directory:` (confusing error message)

**Implementation:**

```bash
# WRONG - LOG_FILE used but never defined
FINDINGS_CREATED=3
echo "[$(date)] Created $FINDINGS_CREATED findings" >> "$LOG_FILE"
# Error: (eval):N: no such file or directory:

# CORRECT - Define before use
PROJECT_PATH="/path/to/project"
LOG_FILE="${PROJECT_PATH}/.logs/findings-creator/execution-log.txt"
mkdir -p "$(dirname "$LOG_FILE")"
FINDINGS_CREATED=3
echo "[$(date)] Created $FINDINGS_CREATED findings" >> "$LOG_FILE"
```

**Critical Rules:**

- Every bash script block MUST define all variables it references
- Use default values for optional variables: `${VAR:-default}`
- Never assume variables persist between Bash tool invocations
- Phase 0 initialization block defines: LOG_FILE, PROJECT_PATH, QUESTION_ID, etc.

**Detection Pattern:**

If you see `>> "$LOG_FILE"` but no `LOG_FILE=` assignment above it, the script will fail.

## Pattern 12: Entity Creation Tool Selection

**Principle:** For entity file creation, ALWAYS use `create-entity.sh`. NEVER use Write tool, cat heredocs, or echo redirection.

**Application in findings-creator:**

- Phase 4: Create finding entities via create-entity.sh only
- All entity directories: query-batches, findings, sources, publishers
- The Write Tool Prohibition in SKILL.md is an absolute rule

**Why This Matters:**

`create-entity.sh` provides:

1. **Validation** - Verifies frontmatter schema, required fields
2. **Locking** - Prevents concurrent creation race conditions
3. **Index updates** - Atomically adds entity to entity-index.json
4. **Transactional safety** - Rollback on failure (entity + index)
5. **Batch validation** - Verifies batch_ref exists for findings

Heredocs/Write tool bypass ALL of these protections.

**Implementation:**

```bash
# WRONG - Using heredoc to write directly to file (bypasses all safety mechanisms)
cat > "${PROJECT_PATH}/04-findings/data/finding-abc.md" << 'EOF'
---
entity_type: finding
batch_ref: "[[03-query-batches/data/batch-xyz]]"
---
# Finding content
EOF

# CORRECT - Using heredoc to pipe JSON to create-entity.sh stdin
cat << 'ENTITY_JSON' | bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --data - \
  --json
{"frontmatter": {"tags": ["finding"], "dc:title": "Finding Title", "batch_ref": "[[03-query-batches/data/batch-xyz]]"}, "content": "# Finding content"}
ENTITY_JSON
```

**Critical Rules:**

- NEVER use Write tool for entity directories (04-findings, 03-query-batches, 07-sources, 01-research-dimensions, 02-refined-questions, 08-publishers)
- NEVER use `cat << EOF > file` or `echo > file` for entity files
- ALWAYS use create-entity.sh with --json flag for machine-parseable output
- Use `--data -` with heredoc for shell-safe JSON (see Pattern 13)
- Violation = broken evidence chains, orphaned entities, index corruption

**Dimension/Question Entity Creation:**

For dimension-planner skill, use `unpack-dimension-plan-batch.sh` instead of `create-entity.sh`:

```bash
# WRONG - Direct Write tool or heredoc
cat > "${PROJECT_PATH}/01-research-dimensions/data/dimension-xyz.md" << 'EOF'
---
entity_type: dimension
---
EOF

# CORRECT - Using batch unpack script
bash "${CLAUDE_PLUGIN_ROOT}/skills/dimension-planner/scripts/unpack-dimension-plan-batch.sh" \
  --json-file "${PROJECT_PATH}/.metadata/dimension-plan-batch.json" \
  --project-path "${PROJECT_PATH}" \
  --json
```

**Why dimension entities require the batch script:**

1. Generates proper wikilinks (`initial_question_ref`, `dimension_ref`)
2. Creates README files with provenance chains
3. Validates question counts per dimension
4. Creates both dimensions AND questions atomically

## Pattern 13: Shell Quoting Safety for JSON Data

**Principle:** When passing JSON data to shell commands, NEVER use single-quoted inline strings that may contain apostrophes. Use heredoc with stdin instead.

**Application in findings-creator:**

- Phase 3/4: All create-entity.sh invocations use `--data -` with heredoc
- Any script that accepts JSON via command line arguments

**Why This Matters:**

When JSON content contains apostrophes (common in academic text like "niche's", "cell's", "body's"), single-quoted shell strings break:

```bash
# WRONG - Apostrophe in content terminates single-quoted string
bash create-entity.sh --data '{"content": "The niche's capacity..."}'
# Error: (eval):1: unmatched "
```

The shell sees the apostrophe as the end of the quoted string, leaving the rest unparsed.

**Implementation:**

```bash
# WRONG - Single-quoted inline JSON (breaks on apostrophes)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --data '{"content": "The niche's capacity to support hematopoiesis..."}' \
  --json
# Error: (eval):1: unmatched "

# CORRECT - Heredoc pipes JSON to stdin
cat << 'ENTITY_JSON' | bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --data - \
  --json
{"frontmatter": {...}, "content": "The niche's capacity to support hematopoiesis..."}
ENTITY_JSON
```

**Why the heredoc pattern works:**

1. Single-quoted delimiter (`'ENTITY_JSON'`) prevents variable expansion inside heredoc
2. Apostrophes inside the heredoc are passed literally (not interpreted as shell quotes)
3. The script reads JSON from stdin with `--data -`
4. Python's stdin reader handles all special characters correctly

**Critical Rules:**

- ALWAYS use `--data -` with heredoc for entity creation
- NEVER use `--data '...'` with inline JSON that may contain apostrophes
- Academic and scientific content frequently contains possessives (niche's, cell's, body's)
- The heredoc delimiter MUST be single-quoted (`'ENTITY_JSON'` not `ENTITY_JSON`) to prevent expansion

## Pattern 14: Python Heredoc Variable Passing

**Principle:** When passing variables to Python heredocs, use `sys.argv` (command-line arguments), NOT `os.environ`. Shell variables are NOT automatically exported to child processes.

**Application in findings-creator:**

- Phase 5: Statistics generation uses Python heredoc for JSON output
- Any inline Python that needs access to shell variables

**Why This Matters:**

Python's `os.environ` only sees **exported** environment variables, not shell variables:

```bash
# WRONG - Shell variable not available in Python
QUESTION_ID="my-question"; python3 << 'EOF'
import os
question_id = os.environ["QUESTION_ID"]  # KeyError!
EOF

# The variable is a SHELL variable, not an ENVIRONMENT variable
# Python child process cannot see it
```

**Implementation:**

```bash
# CORRECT - Pass variables as command-line arguments
QUESTION_ID="my-question"
BATCH_ID="${QUESTION_ID}-batch"

python3 - "$QUESTION_ID" "$BATCH_ID" << 'PYTHON_STATS'
import sys
import json

question_id = sys.argv[1]  # Access via argv, not environ
batch_id = sys.argv[2]

stats = {"question_id": question_id, "batch_id": batch_id}
print(json.dumps(stats))
PYTHON_STATS
```

**Alternative (if environ is required):**

```bash
# Export variables explicitly before Python invocation
export QUESTION_ID="my-question"
export BATCH_ID="${QUESTION_ID}-batch"

python3 << 'PYTHON_STATS'
import os
question_id = os.environ["QUESTION_ID"]  # Now works
PYTHON_STATS
```

**Critical Rules:**

- PREFER `sys.argv` for passing variables to Python heredocs (simpler, explicit)
- Shell variables (`VAR=value`) are NOT inherited by child processes
- Only `export VAR=value` makes variables available in `os.environ`
- Use `python3 - "$VAR1" "$VAR2"` with `-` to read script from stdin while accepting args
- Single-quoted heredoc delimiter (`'EOF'`) prevents shell expansion inside heredoc

## Pattern 15: Phase 5 Statistics Safe Output

**Principle:** Never combine `$()` command substitution with `;` semicolons on the same line in Phase 5 statistics generation. This causes zsh parse errors: `(eval):1: parse error near '('`.

**Application in findings-creator:**

- Phase 5: Statistics Return must NOT use `VAR=$(...); echo ...` pattern
- Any bash block that calculates metrics and outputs JSON

**Why This Matters:**

Claude Code executes via zsh on macOS. When zsh parses command substitution followed by semicolon in eval context, it fails:

```bash
# WRONG - Causes zsh parse error
FINDING_COUNT=$(ls "${PROJECT_PATH}/${FINDINGS_DIR}/data/finding-"*.md 2>/dev/null | grep -c "finding-" || echo 0); echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 5: Statistics - Total findings created: ${FINDING_COUNT}" >> "$LOG_FILE"; echo "{\"success\": true, ...}"
# Error: (eval):1: parse error near `('
```

**Implementation - Option A (Separate Bash Tool Calls):**

Split the command into separate Bash tool invocations:

```bash
# Bash call 1: Count findings
PROJECT_PATH="/path/to/project"
FINDINGS_DIR="04-findings"
ls "${PROJECT_PATH}/${FINDINGS_DIR}/data/finding-"*.md 2>/dev/null | grep -c "finding-" || echo 0
```

```bash
# Bash call 2: Log statistics (use FINDING_COUNT from previous output)
PROJECT_PATH="/path/to/project"
LOG_FILE="${PROJECT_PATH}/.logs/findings-creator/execution-log.txt"
FINDING_COUNT=12  # Use value from Bash call 1
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 5: Statistics - Total findings created: ${FINDING_COUNT}" >> "$LOG_FILE"
```

```bash
# Bash call 3: Output JSON statistics
echo '{"success": true, "findings_created": 12, ...}'
```

**Implementation - Option B (Python Heredoc):**

Use Python with sys.argv per Pattern 14:

```bash
PROJECT_PATH="/path/to/project"
FINDINGS_DIR="04-findings"
QUESTION_ID="my-question-id"

python3 - "$PROJECT_PATH" "$FINDINGS_DIR" "$QUESTION_ID" << 'PYTHON_STATS'
import sys
import json
import glob
import os

project_path = sys.argv[1]
findings_dir = sys.argv[2]
question_id = sys.argv[3]

# Count findings safely in Python
pattern = os.path.join(project_path, findings_dir, "data", "finding-*.md")
finding_count = len(glob.glob(pattern))

stats = {
    "success": True,
    "question_id": question_id,
    "batch_id": f"{question_id}-batch",
    "findings_created": finding_count,
    "schema_version": "3.0"
}

print(json.dumps(stats))
PYTHON_STATS
```

**Critical Rules:**

- NEVER use `VAR=$(...); echo ...` in a single bash command
- PREFER Option B (Python heredoc) for complex JSON with multiple computed fields
- Use Option A (separate calls) for simple counting operations
- Each Bash tool call is a fresh shell - variables do NOT persist between calls
- When using Option A, manually pass computed values between calls

## Pattern 16: Content-URL Coherence

**Principle:** Validate that generated content semantically matches the attributed source URL to prevent LLM hallucination where training data is incorrectly attributed to WebSearch results.

**Application in findings-creator:**

- Phase 4, Step 4.5.5: Coherence validation after content generation
- Validates semantic alignment between finding content and source_url
- Prevents training data leakage attributed to wrong sources
- Applied to ALL findings before entity creation

**Why This Matters:**

LLMs may generate content from training data (reports, studies, statistics) but incorrectly attribute it to a WebSearch URL that doesn't contain that content. This creates false provenance chains and destroys research integrity.

**Mismatch Types Detected:**

| Mismatch Type | Description | Example |
| --------------- | ------------- | --------- |
| `report_name_mismatch` | Report/study name doesn't match URL source | IW-Report cited but URL is iapm.de |
| `publisher_contradiction` | Content cites publisher different from URL domain | McKinsey content attributed to harvard.edu URL |
| `topic_mismatch` | Content topic unrelated to URL path/domain | AI ethics content from manufacturing-tech.com |
| `entity_mismatch` | Named entities don't connect to URL authority | Gartner statistics from non-Gartner URL |
| `unnamed_statistic_mismatch` | Statistics cited without named source from generic/blog URL (v1.8.0) | "67% of companies..." from personal-blog.de |

**Detection Approach:**

Perform semantic comparison between content and URL:

1. Extract domain from source_url
2. Extract path segments from source_url
3. Identify named entities in content (organizations, reports, studies)
4. Identify specific claims (statistics, percentages, findings)
5. Cross-reference content entities against URL domain/path
6. Flag mismatches where content authority differs from URL authority
7. **(v1.8.0)** Detect unnamed statistics from non-authoritative URLs

**Unnamed Statistics Detection (v1.8.0):**

Detect statistics that lack named source attribution when URL is generic/blog:

```python
# Patterns indicating unnamed statistics
unnamed_stat_patterns = [
    r'\d+%\s+of\s+(companies|organizations|enterprises|firms|businesses)',
    r'according to (studies|research|surveys|data|findings)',
    r'(study|research|survey|report) (shows|found|indicates|reveals)',
    r'recent (studies|research|findings|data) (show|indicate|suggest)',
    r'\d+\s+(companies|organizations|enterprises) (surveyed|analyzed|reported)',
]

# Non-authoritative URL patterns (trigger unnamed stat check)
generic_url_patterns = [
    r'blog\.',
    r'\.wordpress\.',
    r'medium\.com',
    r'personal',
    r'\.blogspot\.',
]

def detect_unnamed_statistics(content, source_url):
    domain = extract_domain(source_url)

    # Only flag if URL is generic/blog AND content has unnamed stats
    is_generic_url = any(re.search(p, domain) for p in generic_url_patterns)
    has_unnamed_stats = any(re.search(p, content) for p in unnamed_stat_patterns)
    has_named_source = bool(re.search(r'(Report|Study|Studie|Bericht)\s+\d{4}', content))

    if is_generic_url and has_unnamed_stats and not has_named_source:
        return {
            "valid": False,
            "mismatch_type": "unnamed_statistic_mismatch",
            "violation": f"Unnamed statistics from non-authoritative URL: {domain}"
        }
    return {"valid": True}
```

**When to Flag `unnamed_statistic_mismatch`:**

| Condition | URL Type | Content Pattern | Outcome |
|-----------|----------|-----------------|---------|
| Named report + authoritative URL | mckinsey.com | "McKinsey Report 2024" | PASS |
| Named report + wrong URL | blog.example.com | "McKinsey Report 2024" | FAIL (report_name_mismatch) |
| Unnamed stats + authoritative URL | fraunhofer.de | "67% of companies..." | PASS (trusted source) |
| Unnamed stats + generic URL | blog.example.com | "67% of companies..." | FAIL (unnamed_statistic_mismatch) |

**Implementation:**

```bash
# Step 4.5.5: Coherence validation
cat > /tmp/fc-validate-coherence.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

source_url="$1"
content="$2"

# Extract domain from URL
domain=$(echo "$source_url" | sed -E 's|https?://([^/]+).*|\1|')

# Detect report/study names in content
report_names=$(echo "$content" | grep -oE '(IW-Report|McKinsey Study|Gartner Report|Forrester Research)' || true)

# Detect publisher organizations in content
publishers=$(echo "$content" | grep -oE '(Institut der deutschen Wirtschaft|McKinsey|Gartner|Forrester)' || true)

# Check for coherence violations
if [ -n "$report_names" ]; then
  # Validate report name matches domain authority
  for report in $report_names; do
    case "$report" in
      "IW-Report")
        if [[ ! "$domain" =~ (iwkoeln\.de|iw\.de) ]]; then
          echo "COHERENCE_VIOLATION: IW-Report cited but URL is $domain"
          exit 1
        fi
        ;;
      "Gartner")
        if [[ ! "$domain" =~ gartner\. ]]; then
          echo "COHERENCE_VIOLATION: Gartner cited but URL is $domain"
          exit 1
        fi
        ;;
    esac
  done
fi

echo "COHERENCE_VALID"
SCRIPT_EOF

chmod +x /tmp/fc-validate-coherence.sh
if ! bash /tmp/fc-validate-coherence.sh "$source_url" "$finding_content"; then
  log_conditional ERROR "Coherence validation failed - content doesn't match URL"
  continue  # Skip finding - do NOT create with mismatched provenance
fi
```

**Example Violation (Real Bug Case):**

```yaml
# Finding entity with coherence violation
source_url: "https://iapm.de/risikomanagement/risikoanalyse"
content: |
  IW-Report 2024 shows that 67% of German companies have experienced
  economic crime in the past two years. The Institut der deutschen
  Wirtschaft study surveyed 500 enterprises...

# VIOLATION DETECTED:
# - Content cites "IW-Report 2024" (Institut der deutschen Wirtschaft)
# - Content cites "Institut der deutschen Wirtschaft" explicitly
# - URL is iapm.de (International Association of Project Managers)
# - Domain authority (IAPM) has no connection to IW/IW-Report
# - Content was generated from LLM training data, not from URL source
# - This is FABRICATED PROVENANCE
```

**Coherence Validation Logic:**

```python
# Pseudocode for coherence check
def validate_coherence(content, source_url):
    domain = extract_domain(source_url)
    path_segments = extract_path_segments(source_url)

    # Extract named entities from content
    report_names = extract_entities(content, entity_type="report")
    organizations = extract_entities(content, entity_type="organization")

    # Check if content entities align with URL authority
    for report in report_names:
        expected_domain = get_authoritative_domain(report)
        if expected_domain not in domain:
            return {
                "valid": False,
                "mismatch_type": "report_name_mismatch",
                "violation": f"{report} cited but URL is {domain}"
            }

    for org in organizations:
        expected_domain = get_authoritative_domain(org)
        if expected_domain not in domain:
            return {
                "valid": False,
                "mismatch_type": "publisher_contradiction",
                "violation": f"{org} content attributed to {domain}"
            }

    return {"valid": True}
```

**Critical Rules:**

- ALWAYS validate coherence before creating finding entities
- NEVER create findings where content authority differs from URL authority
- Training data content must NOT be attributed to unrelated URLs
- Log all coherence violations to `.metadata/coherence-rejected.json`
- It is BETTER to skip a finding than to create false provenance
- Coherence validation is the final defense against hallucination

**When to Skip Finding:**

Skip finding creation when coherence validation detects:

1. Report/study name that doesn't match URL domain
2. Organization name in content that contradicts URL publisher
3. Specific statistics attributed to wrong source
4. Named entities with no semantic connection to URL

**Fallback Strategy:**

When coherence violation detected:

1. Log violation with full details (content excerpt, URL, mismatch type)
2. Skip finding creation (do NOT create entity)
3. Continue to next search result
4. Report skipped count in Phase 5 statistics
5. Never attempt to "fix" by modifying content or URL

## Pattern 17: Content Fidelity Verification (v1.8.0)

**Principle:** Verify that generated finding content doesn't exceed the scope of the source snippet in snippet-only mode. This prevents the LLM from elaborating beyond available information using training data.

**Application in findings-creator:**

- Phase 4, Step 4.5.4: Content Fidelity Gate (runs BEFORE Step 4.5.5 Coherence Validation)
- Activated only when `webfetch_success=false` (snippet-only mode)
- Compares generated content against original snippet
- Detects "novel entities" - information in content not present in snippet

**Why This Matters:**

In snippet-only mode, the finding content (150-300 words) is generated from a WebSearch snippet (~100 characters). The LLM may "fill in" missing details from training data, creating findings that attribute fabricated information to the source URL. Pattern 16 catches named report mismatches, but Pattern 17 catches general elaboration beyond snippet bounds.

**Detection Approach:**

1. Extract entities from original snippet (organizations, numbers, dates, claims)
2. Extract entities from generated finding content
3. Identify "novel entities" in content not present in snippet
4. Apply threshold-based gate decision

**Novel Entity Types:**

| Entity Type | Example in Snippet | Example Novel (Fabricated) |
|-------------|-------------------|---------------------------|
| Statistics | "companies report growth" | "67% of companies report 15% growth" |
| Organizations | "German manufacturers" | "VDMA survey of German manufacturers" |
| Timeframes | "recent study" | "2024 Q3 longitudinal study" |
| Sample sizes | "survey results" | "N=1,247 enterprise survey results" |
| Specific claims | "cost reduction" | "40% average cost reduction within 18 months" |

**Gate Decision Logic:**

| Novel Entity Count | Status | Action |
|-------------------|--------|--------|
| 0-2 | PASS | Continue to Step 4.5.5 (coherence validation) |
| 3-5 | WARN | Add `fidelity_warning: true`, continue |
| >5 | FAIL | Skip finding, log to `.metadata/fidelity-rejected.json` |

**Implementation:**

```python
def verify_content_fidelity(original_snippet, generated_content):
    """
    Verify generated content doesn't exceed snippet scope.
    Only called when webfetch_success=false (snippet-only mode).
    """
    # Extract entities from both sources
    snippet_entities = extract_entities(original_snippet)
    content_entities = extract_entities(generated_content)

    # Identify novel entities (in content but not in snippet)
    novel_entities = content_entities - snippet_entities

    # Apply threshold decision
    novel_count = len(novel_entities)

    if novel_count <= 2:
        return {
            "status": "PASS",
            "novel_count": novel_count,
            "novel_entities": list(novel_entities)
        }
    elif novel_count <= 5:
        return {
            "status": "WARN",
            "novel_count": novel_count,
            "novel_entities": list(novel_entities),
            "fidelity_warning": True
        }
    else:
        return {
            "status": "FAIL",
            "novel_count": novel_count,
            "novel_entities": list(novel_entities),
            "rejection_reason": f"Content fidelity violation: {novel_count} novel entities exceed threshold"
        }

def extract_entities(text):
    """Extract factual entities from text for comparison."""
    entities = set()

    # Extract percentages with context
    for match in re.findall(r'(\d+%\s+\w+)', text):
        entities.add(match.lower())

    # Extract numbers with context
    for match in re.findall(r'(\d+(?:,\d+)?\s+(?:companies|organizations|enterprises|respondents))', text):
        entities.add(match.lower())

    # Extract named organizations
    for match in re.findall(r'((?:VDMA|McKinsey|Gartner|Forrester|Fraunhofer|IW)[^,\.]*)', text):
        entities.add(match.lower().strip())

    # Extract timeframes
    for match in re.findall(r'(\d{4}(?:\s*[-–]\s*\d{4})?(?:\s+Q[1-4])?)', text):
        entities.add(match)

    # Extract specific claims with numbers
    for match in re.findall(r'(\d+(?:\.\d+)?%?\s+(?:reduction|increase|improvement|growth))', text):
        entities.add(match.lower())

    return entities
```

**Example Violation:**

```yaml
# Snippet-only mode input
webfetch_success: false
original_snippet: "German manufacturing companies are increasingly adopting digital tools for customer engagement"

# Generated content (VIOLATES fidelity)
generated_content: |
  A 2024 VDMA study of 1,247 German manufacturing companies shows that
  67% have implemented digital customer engagement tools, with an average
  40% reduction in support costs within 18 months of deployment...

# Fidelity analysis:
# - snippet_entities: {"german manufacturing companies", "digital tools", "customer engagement"}
# - content_entities: {"2024 vdma study", "1,247 german manufacturing companies", "67%", "40% reduction", "18 months"}
# - novel_entities: {"2024 vdma study", "1,247", "67%", "40% reduction", "18 months"}
# - novel_count: 5 → WARN status

# IF novel_count > 5: FAIL, skip finding creation
```

**Metadata Fields Added:**

When Pattern 17 is applied, add to finding frontmatter:

```yaml
# Content Fidelity (Pattern 17)
fidelity_validated: true
fidelity_status: "PASS" | "WARN" | "FAIL"
fidelity_novel_count: 2
fidelity_novel_entities: ["entity1", "entity2"]
fidelity_framework_version: "1.0"
content_source: "snippet" | "webfetch"
```

**Critical Rules:**

- Pattern 17 ONLY applies when `webfetch_success=false` (snippet-only mode)
- When `webfetch_success=true`, skip Pattern 17 (WebFetch provided full content)
- WARN findings should be reviewed but are not blocked
- FAIL findings must NOT be created - log and skip
- Novel entity extraction is approximate - err on side of caution (WARN > FAIL)
- Pattern 17 runs BEFORE Pattern 16 (Step 4.5.4 before Step 4.5.5)

**Relationship to Pattern 16:**

| Pattern | Focus | Trigger | Detection |
|---------|-------|---------|-----------|
| Pattern 16 | Named source misattribution | All findings | Report/org name vs URL domain |
| Pattern 17 | Snippet elaboration | Snippet-only mode | Novel entities beyond snippet |

Pattern 17 catches elaboration; Pattern 16 catches misattribution. Both are required for comprehensive anti-hallucination.

**Fallback Strategy:**

When fidelity violation detected (FAIL):

1. Log violation with snippet, content, and novel entities
2. Skip finding creation (do NOT create entity)
3. Continue to next search result
4. Report in Phase 5 statistics: `fidelity_rejected_count`
5. Consider: If many FAIL, snippet quality may be too low for this query
