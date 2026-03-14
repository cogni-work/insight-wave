# Agent Response Validation Protocols

## JSON-Only Enforcement

All agents in the deeper-research workflow MUST return minimal JSON responses. This ensures token efficiency and consistent parsing.

## Standard Validation Workflow

Execute this workflow after EVERY agent invocation:

### 1. Check Format
Verify if response starts with `{` or `[` or ` ```json`

- IF not → Extract JSON block from response text (look for ```json...``` or {...})
- Log: "⚠ Verbose response detected from {agent_name}"

### 2. Parse JSON
Attempt to parse extracted JSON

- IF parse succeeds → Continue to step 3
- IF parse fails → Log error, attempt regex extraction, report failure

### 3. Validate Structure
Verify expected fields present per phase

- Check required fields exist (agent-specific, see "Expected Response Formats")
- Check field types match expectations
- IF fields missing → Log warning, proceed with available data

### 4. Detect Verbosity
Calculate response verbosity ratio

```bash
text_length = total response character count
json_length = extracted JSON character count
verbosity_ratio = text_length / json_length
```

- IF verbosity_ratio > 2.0 → Flag as "highly verbose"
- IF verbosity_ratio > 1.2 → Increment verbose_warning_count
- Log: "Agent {name} returned {text_length} chars ({json_length} JSON, ratio: {ratio})"

**Rationale for Thresholds:**
- **1.2x ratio**: Allows for minimal context text (3-5 lines explanation with JSON)
- **2.0x ratio**: Indicates excessive verbosity requiring improvement
- **Limitation**: Ratio affected by JSON formatting (minified vs pretty-printed)
- **Alternative approach**: Use character count delta (e.g., `excess_chars = total - json_length`) for more consistent detection

### 5. Track Compliance
Maintain global compliance statistics

- total_agents_invoked += 1
- IF verbose_response → verbose_agents += 1, append to verbose_agent_names[]
- Calculate compliance_rate = (total - verbose) / total

### 6. Extract Data
Parse required fields from JSON for next phase

### 7. Report Non-Compliance
IF verbose:
- Log to stderr: "Agent {name} violated JSON-only format"
- Track for Phase 9 compliance report

## Expected Response Formats

### Phase 1: Question Refinement
```json
{
  "success": true,
  "entity_path": "/path/to/00-initial-question/data/question.md"
}
```

**Required Fields**: `success`, `entity_path`

### Phase 2: Dimensional Planning
```json
{
  "success": true,
  "dimensions": 4,
  "questions": 12
}
```

**Required Fields**: `success`, `dimensions`, `questions`

### Phase 3: Query Construction
```json
{
  "success": true,
  "batches": 3,
  "total_queries": 18
}
```

**Required Fields**: `success`, `batches`, `total_queries`

### Phase 4: Research Execution
```json
{
  "success": true,
  "batch_id": "technical",
  "findings_created": 15,
  "megatrends_created": 4
}
```

**Required Fields**: `success`, `batch_id`, `findings_created`, `megatrends_created`

### Phase 4.5: Concept Extraction
```json
{
  "success": true,
  "concepts_created": 12
}
```

**Required Fields**: `success`, `concepts_created`

**Note:** Phase 5 (Publisher Creation/Enrichment) has been moved to the standalone `publisher` skill. See publisher-generator skill documentation for validation protocols.

### Phase 6.1: Source Creation
```json
{
  "success": true,
  "sources_created": 18,
  "sources_reused": 5
}
```

**Required Fields**: `success`, `sources_created`, `sources_reused`

### Phase 6.2: Citation Generation
```json
{
  "success": true,
  "citations_created": 23,
  "citations_skipped": 2,
  "publisher_matches": {
    "exact": 18,
    "fuzzy": 3,
    "domain_fallback": 2
  }
}
```

**Required Fields**: `success`, `citations_created`

**Optional Fields**: `citations_skipped`, `publisher_matches`

### Phase 7: Fact Verification
```json
{
  "claims": 23,
  "avg_confidence": 0.78
}
```

**Required Fields**: `claims`, `avg_confidence`

### Phase 8: Synthesis Generation
```json
{
  "success": true,
  "synthesis_files": {
    "readme": "README.md",
    "report": "research-hub.md",
    "evidence": "09-citations/README.md"
  },
  "total_entities": 835,
  "concepts_integrated": 12,
  "wikilinks_generated": 450
}
```

**Required Fields**: `success`, `synthesis_files`, `total_entities`

**synthesis_files must contain**: `readme`, `report`, `evidence`

### Phase 8.5: Knowledge Graph Validation
```json
{
  "valid_links": 245,
  "broken_links": 0,
  "orphaned_entities": 3,
  "validation_time": "2025-10-21T08:45:00Z"
}
```

**Required Fields**: `valid_links`, `broken_links`, `orphaned_entities`

## Agent Response Standards

### ✅ CORRECT: Minimal JSON Only
```json
{
  "claims": 23,
  "avg_confidence": 0.78
}
```

### ❌ INCORRECT: Verbose Text + JSON
```
I have processed the findings and created 23 claims with an average confidence of 0.78...

{
  "claims": 23,
  "avg_confidence": 0.78
}
```

## Error Handling

### JSON Parse Failures
- Log error with full response text
- Attempt to extract JSON using regex: `\{[\s\S]*\}` or `\[[\s\S]*\]`
- If extraction succeeds, proceed with validation
- If extraction fails, report failure to user and halt workflow

### Invalid Structure
- Log warning with missing fields
- Proceed with available data if non-critical fields missing
- Halt workflow if critical fields (e.g., `success`, `entity_path`) missing

### Verbose Text Detection
- Log warning (non-blocking)
- Suggest agent prompt update in Phase 9 compliance report
- Continue workflow with extracted JSON

## Compliance Reporting

Generate compliance report in Phase 9:

```
Agent Response Compliance:
- Total agents invoked: {total_agents_invoked}
- JSON-only responses: {total - verbose_agents} ({compliance_rate}%)
- Verbose responses: {verbose_agents} ({100 - compliance_rate}%)
```

IF verbose_agents > 0:
```
- Agents needing updates: {verbose_agent_names joined by ", "}
- Recommendation: "Consider updating verbose agents with stricter prompts"
```

IF compliance_rate >= 90%:
- Report: "✓ Excellent JSON-only compliance ({compliance_rate}%)"

IF compliance_rate < 90%:
- Report: "⚠ Low JSON-only compliance ({compliance_rate}%), review agent prompts"

## Phase-Specific Error Handling

### During Any Phase
If agent returns `{"success": false, "error": "..."}`:
- Report error to user with message
- Ask: "Would you like to retry this phase or adjust and continue?"
- If retry selected: Re-invoke the agent for that phase
- If continue: Skip to next phase (if possible) or abort workflow

### For Script Failures
If Bash script returns error:
- Display error message to user
- Offer: "Retry with alternative parameters or proceed without this step?"
- Document any skipped steps in final report

### For Validation Failures (Phase 8.5)
If broken_links > 0:
- Report error to user with broken link details
- List affected entities
- Ask: "Fix wikilinks before proceeding?"
- If yes: Halt workflow for manual review
- If no: Continue with warning

