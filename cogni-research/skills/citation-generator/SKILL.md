---
name: citation-generator
description: "[Internal] Generate APA citations by linking sources to publishers. Invoked by deeper-research-2."
---

# Citation Generator

---

## ⛔ INVOCATION GUARD - READ BEFORE PROCEEDING

**This is an EXECUTOR skill. It should NOT be invoked directly.**

### Correct Invocation Path

```text
User → deeper-research-2 skill (ORCHESTRATOR)
       └→ Phase 6: Task tool → citation-generator AGENT → this skill
```

### If You Are Reading This Directly

**STOP.** You likely invoked this skill directly via `Skill(skill="cogni-research:citation-generator")`.

**What to do instead:**

1. Use the `deeper-research-2` skill instead:

   ```text
   Skill(skill="cogni-research:deeper-research-2")
   ```

2. The orchestrator will invoke this skill at the correct phase with proper context.

**Why this matters:** Direct invocation bypasses phase gates, entity validation, and source-creator prerequisites. Citations require sources and publishers to exist first (Phases 4-5).

---

## Purpose

Generate formal APA citations by linking source entities to publisher entities through evidence-based multi-strategy resolution. Uses complete entity loading, 4-strategy publisher matching (domain, name, reverse index, fallback), and APA 7th edition formatting with multi-language support.

## When to Use

**In deeper-research Pipeline (Phase 6.2):**
- Transforms sources and publishers into formal citations
- Prerequisites: Sources in `07-sources/data/`, publishers in `08-publishers/data/`
- Outputs: APA citations in `09-citations/data/`

**Standalone Usage:**
- Generating citations for existing research sources
- Converting source lists to formatted bibliography
- Creating APA-formatted reference lists

**Not for:** Creating sources (use source-creator), modifying publishers, or processing findings.

## Template References

**Foundation (Plugin-Level):**
- [../../references/anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md) - Complete entity loading, provenance integrity
- [../../references/entity-structure-guide.md](../../references/entity-structure-guide.md) - Entity frontmatter, UUID patterns
- [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) - Parameter parsing, logging, JSON patterns

**Citation-Specific:**
- [references/publisher-resolution.md](references/publisher-resolution.md) - 4-strategy matching algorithm
- [references/apa-formatting.md](references/apa-formatting.md) - APA 7th edition, multi-language
- [references/implementation-patterns.md](references/implementation-patterns.md) - Entity loading, checkpoints
- [references/partition-execution.md](references/partition-execution.md) - Parallel execution patterns
- [references/entity-templates.md](references/entity-templates.md) - Citation entity structure

---

## Immediate Action: Initialize TodoWrite

**⛔ MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 1: Parameter Validation [in_progress]
2. Phase 2: Environment Setup [pending]
3. Phase 3: Entity Loading & Indexing [pending]
4. Phase 4: Publisher Resolution & Citation Generation [pending]
5. Phase 5: Statistics & Return [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 5 phase-level to ~15-20 step-level).

---

## Progressive TodoWrite Expansion

The citation-generator workflow uses **progressive disclosure** for TodoWrite tracking:

- **Initial state:** 5 phase-level todos (shown above)
- **Progressive expansion:** Each phase adds its step-level todos when started
- **Final state:** ~15-20 step-level todos across all phases

**Pattern:** As you enter each phase, add the step-level todos for that phase. This prevents overwhelming initial context while maintaining detailed tracking.

---

## Core Workflow

Execute phases sequentially with mandatory reference reading and TodoWrite tracking.

### Phase 1: Parameter Validation

#### Step 0.5: Initialize Phase 1 TodoWrite

Add step-level todos for Phase 1:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 1, Step 1: Read shared-bash-patterns.md Section 1 [in_progress]
- Phase 1, Step 2: Validate required parameters [pending]
- Phase 1, Step 3: Validate optional parameters [pending]
- Phase 1, Step 4: Return error if validation fails [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Parameter Parsing Reference

⛔ **MANDATORY:** Read parameter parsing reference BEFORE executing validation:

```bash
USE: Read tool
FILE: ../../references/shared-bash-patterns.md
SECTION: Section 1 (parameter parsing)

EXTRACT:
- Parameter parsing patterns
- Required vs optional parameter handling
- Error JSON format for exit 2
- Partition parameter validation
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Validate Required Parameters

**Required:** `--project-path` (research project directory)

If PROJECT_PATH missing → return error JSON (exit 2)

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Validate Optional Parameters

**Optional:**

- `--language`: Output language (default: en, supported: en, de)
- `--repair-mode`: Fix existing broken publisher links
- `--partition`: Process subset of sources (format: "1/4")

If partition parameter invalid → return error JSON (exit 2)

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Confirm Validation Complete

Update TodoWrite: Phase 1 → completed, Phase 2 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 2.

### Phase 2: Environment Setup

#### Step 0.5: Initialize Phase 2 TodoWrite

Add step-level todos for Phase 2:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 2, Step 1: Read shared-bash-patterns.md Sections 2-3 [in_progress]
- Phase 2, Step 2: Validate working directory [pending]
- Phase 2, Step 3: Initialize logging [pending]
- Phase 2, Step 4: Verify prerequisite directories [pending]
- Phase 2, Step 4a: Verify publishers exist with retry [pending]
- Phase 2, Step 5: Confirm environment setup complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Environment Setup Reference

⛔ **MANDATORY:** Read environment setup reference BEFORE executing setup:

```bash
USE: Read tool
FILE: ../../references/shared-bash-patterns.md
SECTIONS: Sections 2-3 (environment setup and logging)

EXTRACT:
- 4-step working directory validation protocol
- enhanced-logging.sh initialization patterns
- Directory existence verification
- Error JSON format for exit 1
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Validate Working Directory

Execute 4-step validation protocol. Return error JSON (exit 1) if validation fails.

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Initialize Logging

Initialize logging with enhanced-logging.sh.

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Verify Prerequisite Directories

Verify `07-sources/data/` and `08-publishers/data/` exist. Return error JSON (exit 1) if missing.

**Mark Step 4 todo as completed** before proceeding to Step 4a.

#### Step 4a: Verify Publishers Exist with Retry (BUG-039 FIX)

**⛔ CRITICAL:** Citations require publishers to exist. When citation-generator and publisher-generator run in parallel, publishers may not be ready yet. Use retry mechanism to wait for publishers.

```bash
# BUG-039 FIX: Publisher loading with retry and filesystem sync
# Addresses race condition when citation-generator runs before publisher-generator completes

PROJECT_PATH="{project-path}"
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=2

for attempt in $(seq 1 $MAX_RETRY_ATTEMPTS); do
  # Force filesystem sync (resolves macOS caching issues)
  sync 2>/dev/null || true

  # Count publishers
  PUBLISHER_COUNT=$(find "$PROJECT_PATH/08-publishers/data" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$PUBLISHER_COUNT" -gt 0 ]; then
    echo "Found $PUBLISHER_COUNT publishers on attempt $attempt" >&2
    break
  fi

  if [ "$attempt" -lt "$MAX_RETRY_ATTEMPTS" ]; then
    echo "WARNING: No publishers found, waiting ${RETRY_DELAY}s (attempt $attempt/$MAX_RETRY_ATTEMPTS)..." >&2
    sleep $RETRY_DELAY
    RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff: 2s, 4s
  fi
done

# CRITICAL: Verify publishers exist before proceeding
if [ "$PUBLISHER_COUNT" -eq 0 ]; then
  echo '{"success": false, "error": "No publishers loaded - publisher-generator may not have completed. Ensure publisher-generator runs BEFORE citation-generator."}' >&2
  exit 1
fi

echo "Publisher verification passed: $PUBLISHER_COUNT publishers available" >&2
```

**Why This Matters:**

- Publisher-generator and citation-generator may be invoked in parallel
- macOS filesystem caching can cause `find` to return stale results
- The retry mechanism with `sync` ensures citations see newly-created publishers

**Mark Step 4a todo as completed** before proceeding to Step 5.

#### Step 5: Confirm Environment Setup Complete

Update TodoWrite: Phase 2 → completed, Phase 3 → in_progress

**Mark Step 5 todo as completed** before proceeding to Phase 3.

### Phase 3: Entity Loading & Indexing

#### Step 0.5: Initialize Phase 3 TodoWrite

Add step-level todos for Phase 3:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 3, Step 1: Read implementation-patterns.md [in_progress]
- Phase 3, Step 2: Count entities for baseline [pending]
- Phase 3, Step 3: Load all sources [pending]
- Phase 3, Step 4: Load all publishers [pending]
- Phase 3, Step 5: Verify counts match [pending]
- Phase 3, Step 6: Read partition-execution.md if needed [pending]
- Phase 3, Step 7: Apply partition filter [pending]
- Phase 3, Step 8: Build publisher lookup structures [pending]
- Phase 3, Step 9: Execute verification checkpoint [pending]
- Phase 3, Step 10: Confirm entity loading complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Entity Loading Reference

⛔ **MANDATORY:** Read entity loading reference BEFORE executing loading:

```bash
USE: Read tool
FILE: references/implementation-patterns.md

EXTRACT:
- Complete entity loading procedure
- Entity counting patterns
- Array loading patterns
- Verification checkpoint protocol
- Publisher lookup structure construction
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Steps 2-5: Entity Loading

**Process:**

1. Count entities for verification baseline
2. Load ALL sources into SOURCES_TO_PROCESS array
3. Load ALL publishers into PUBLISHERS_LOADED array
4. Verify counts match (loaded = expected)

**Mark Steps 2-5 todos as completed** after loading all entities.

#### Step 6: Read Partition Execution Reference (Conditional)

If `--partition` parameter provided:

⛔ **MANDATORY:** Read partition execution reference:

```bash
USE: Read tool
FILE: references/partition-execution.md

EXTRACT:
- Partition filtering algorithm
- Partition parameter parsing
- Array slicing patterns
```

**Mark Step 6 todo as completed** before proceeding to Step 7.

#### Step 7: Apply Partition Filter

Apply partition filter if `--partition` provided.

**Mark Step 7 todo as completed** before proceeding to Step 8.

#### Step 8: Build Publisher Lookup Structures

Build 4 publisher lookup structures (domain, name, reverse, strategy).

**Mark Step 8 todo as completed** before proceeding to Step 9.

#### Step 9: Execute Verification Checkpoint

**Verification Checkpoint (MANDATORY):**

- If sources empty: return success JSON with 0 created, exit 0
- If publishers empty: return error JSON, exit 1
- Log: "CHECKPOINT: Complete entity loading verified"

**CRITICAL:** Must pass checkpoint before Phase 4.

**Mark Step 9 todo as completed** before proceeding to Step 10.

#### Step 10: Confirm Entity Loading Complete

Update TodoWrite: Phase 3 → completed, Phase 4 → in_progress

**Mark Step 10 todo as completed** before proceeding to Phase 4.

### Phase 4: Publisher Resolution & Citation Generation

#### Step 0.5: Initialize Phase 4 TodoWrite

Add step-level todos for Phase 4:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 4, Step 1: Read publisher-resolution.md [in_progress]
- Phase 4, Step 2: Read apa-formatting.md [pending]
- Phase 4, Step 3: Read entity-templates.md [pending]
- Phase 4, Step 4: Process sources with 4-strategy matching [pending]
- Phase 4, Step 5: Generate APA citations [pending]
- Phase 4, Step 6: Track resolution statistics [pending]
- Phase 4, Step 7: Confirm resolution complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Publisher Resolution Reference

⛔ **MANDATORY:** Read publisher resolution reference BEFORE executing resolution:

```bash
USE: Read tool
FILE: references/publisher-resolution.md

EXTRACT:
- 4-strategy resolution algorithm
- Domain exact matching patterns
- Name exact matching patterns
- Reverse index lookup
- Domain fallback handling
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Read APA Formatting Reference

⛔ **MANDATORY:** Read APA formatting reference BEFORE generating citations:

```bash
USE: Read tool
FILE: references/apa-formatting.md

EXTRACT:
- APA 7th edition formatting rules
- Language-specific date formats
- Citation text construction
- YAML artifact prevention
```

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Read Entity Templates Reference

⛔ **MANDATORY:** Read entity templates reference BEFORE creating entities:

```bash
USE: Read tool
FILE: references/entity-templates.md

EXTRACT:
- Citation entity structure
- Frontmatter requirements
- Wikilink format patterns (CRITICAL: [[07-sources/data/source-id]], [[08-publishers/data/publisher-id]])
- Components section structure with wikilinks
- UUID patterns
- Entity file organization
```

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Steps 4-6: Resolution & Citation Generation

**Resolution Strategies (first match wins):**

1. **Domain exact** - Match source domain to publisher domain
2. **Name exact** - Match source publisher field to publisher name
3. **Reverse index** - Use publisher→source mappings
4. **Domain fallback** - No publisher found (not an error)

**Citation Generation:**

1. Format citation text per APA 7th edition
2. Apply language-specific date format (en: "Retrieved Month Day, Year", de: "Abgerufen am DD. MMMM YYYY")
3. Validate no YAML artifacts in citation text
4. Create citation entity with proper frontmatter
5. **CRITICAL:** Create Components section with wikilink format:
   - Source: `- **Source**: [[07-sources/data/{source_id}]]` (ALWAYS use wikilink with directory prefix)
   - Publisher: `- **Publisher**: [[08-publishers/data/{publisher_id}]]` (ONLY if matched, use wikilink with directory prefix)
   - Match Strategy: `- **Match Strategy**: {strategy}`

Track statistics: match_domain_exact, match_name_exact, match_reverse_index, match_domain_fallback

#### Step 4.1: Validate Source-Publisher Domain Consistency (v3.9.0)

⛔ **CRITICAL VALIDATION:** After publisher resolution succeeds (Strategies 1-3), verify domain consistency before creating citation:

```bash
# Extract source domain from URL
SOURCE_DOMAIN=$(echo "$SOURCE_URL" | sed -E 's|https?://([^/]+).*|\1|' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')

# Validate domain consistency for non-fallback matches
if [ -n "$PUBLISHER_ID" ] && [ "$MATCH_STRATEGY" != "domain_fallback" ]; then
  PUBLISHER_FILE="${PROJECT_PATH}/08-publishers/data/${PUBLISHER_ID}.md"
  PUBLISHER_DOMAIN=$(grep "^domain:" "$PUBLISHER_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')

  # Validate domains match
  if [ -n "$PUBLISHER_DOMAIN" ] && [ "$SOURCE_DOMAIN" != "$PUBLISHER_DOMAIN" ]; then
    echo "WARNING: Domain mismatch detected! Source domain ($SOURCE_DOMAIN) != Publisher domain ($PUBLISHER_DOMAIN)" >&2
    echo "  Source: $source_id" >&2
    echo "  Publisher: $PUBLISHER_ID (resolved via $MATCH_STRATEGY)" >&2

    # Re-resolve using Strategy 1 (domain exact) as override
    CORRECT_PUBLISHER=$(lookup_publisher_by_domain "$SOURCE_DOMAIN")
    if [ -n "$CORRECT_PUBLISHER" ]; then
      echo "  CORRECTING: Using $CORRECT_PUBLISHER instead" >&2
      PUBLISHER_ID="$CORRECT_PUBLISHER"
      MATCH_STRATEGY="domain_exact_corrected"
      match_domain_exact_corrected=$((match_domain_exact_corrected + 1))
    else
      # No correct publisher found - fallback to no publisher
      echo "  FALLBACK: No publisher for domain $SOURCE_DOMAIN" >&2
      PUBLISHER_ID=""
      MATCH_STRATEGY="domain_fallback"
      match_domain_fallback=$((match_domain_fallback + 1))
    fi
  fi
fi
```

**Why This Matters:**
- Strategy 2 (name_exact) or Strategy 3 (reverse_index) may link to wrong publisher
- Example: Source from `sichere-industrie.de` incorrectly linked to `publisher-sequafy`
- This validation catches and corrects such mismatches before citation creation

**Mark Steps 4-6 todos as completed** after processing all sources.

#### Step 7: Confirm Resolution Complete

Update TodoWrite: Phase 4 → completed, Phase 5 → in_progress

**Mark Step 7 todo as completed** before proceeding to Phase 5.

### Phase 5: Statistics & Return

#### Step 0.5: Initialize Phase 5 TodoWrite

Add step-level todos for Phase 5:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 5, Step 1: Read shared-bash-patterns.md Section 4 [in_progress]
- Phase 5, Step 2: Calculate aggregates [pending]
- Phase 5, Step 3: Generate warnings if needed [pending]
- Phase 5, Step 4: Construct JSON response [pending]
- Phase 5, Step 5: Return JSON-only response [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read JSON Construction Reference

⛔ **MANDATORY:** Read JSON construction reference BEFORE generating response:

```bash
USE: Read tool
FILE: ../../references/shared-bash-patterns.md
SECTION: Section 4 (JSON construction)

EXTRACT:
- JSON construction patterns
- Aggregate calculation
- Warning generation conditions
- JSON-only response requirements
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Steps 2-4: Statistics Generation

**Process:**

1. Calculate aggregates (citations_created, citations_skipped)
2. Generate warning if domain_fallback >80%
3. Construct JSON response

**JSON Response:**

```json
{
  "success": true,
  "citations_created": 40,
  "citations_skipped": 2,
  "publisher_matches": {
    "domain_exact": 28,
    "name_exact": 8,
    "reverse_index": 2,
    "domain_fallback": 2
  }
}
```

**Mark Steps 2-4 todos as completed** after constructing JSON.

#### Step 5: Return JSON Response

**CRITICAL:** Response must contain ONLY JSON.

Update TodoWrite: Phase 5 → completed

**Mark Step 5 todo as completed** to finish workflow.

## Error Handling

**Exit Codes:**
- **Exit 2:** Parameter validation errors
- **Exit 1:** Runtime/validation errors
- **Exit 0:** Success

**Read:** `../../references/shared-bash-patterns.md` Sections 5-6 for error patterns.

| Scenario | Recovery | Exit |
|----------|----------|------|
| PROJECT_PATH missing | Return error JSON | 2 |
| Working directory validation fails | Return error JSON | 1 |
| No publishers loaded | Return error JSON | 1 |
| No sources to process | Return success JSON (0 created) | 0 |
| Invalid source format | Skip source, log warning, continue | 0 |
| YAML artifact in citation | Skip citation, log error, continue | 0 |
| Invalid partition parameter | Return error JSON | 1 |

## Success Criteria

Phase 6.2 complete when:
- All assigned sources processed
- Citations created with APA formatting (no YAML artifacts)
- **CRITICAL:** Citations contain wikilinks in Components section: `[[07-sources/data/{source_id}]]` and `[[08-publishers/data/{publisher_id}]]` (NOT plain text like "source-id" or "Publisher Name")
- All 4 resolution strategies attempted
- German citations contain "Abgerufen am" (if language=de)
- Statistics JSON written
- JSON-only summary returned

**If ANY criterion fails, do NOT mark task complete.**

## Debugging

**Read:** [Debugging Guide](https://github.com/cogni-work/dev-work/blob/main/references/debugging-guide.md) for complete debugging architecture.

**Enable verbose logging:** `export DEBUG_MODE=1`

**Logs:** `/tmp/citation-generator-debug.log`, `/tmp/citation-generator-metrics.json`

## Examples

**Read:** `references/implementation-patterns.md` for complete examples:
- Example 1: Multi-strategy matching (42 sources, 23 publishers)
- Example 2: German language citations
- Example 3: Partition mode (80 sources, 4 parallel jobs)
- Example 4: High domain fallback warning
