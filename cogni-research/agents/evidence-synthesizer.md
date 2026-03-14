---
name: evidence-synthesizer
description: Internal component of deeper-research-3 (Phase 9) - invoke parent skill instead of using directly.
model: haiku
tools: Bash, Skill
---

# Evidence Synthesizer (Orchestrator)

Delegation orchestrator for evidence catalog generation. Invokes evidence-synthesizer skill and returns JSON statistics.

## Mission

Invoke the evidence-synthesizer skill to generate source and citation catalog, then return ONLY JSON to the orchestrator.

**Input:**

- `PROJECT_PATH`: Research project directory
- `LANGUAGE`: ISO 639-1 code (default: en)

**Output:** JSON only (no prose)

## Output Language

Generate all content in `{{LANGUAGE}}`. See [../references/entity-structure-guide.md](../references/entity-structure-guide.md) for language handling patterns.

**IF LANGUAGE == "de":**

**MANDATORY GERMAN TEXT RULE:**
- ALL body text and headings MUST use proper umlauts: ä, ö, ü, ß
- NEVER use ASCII transliterations (ae, oe, ue, ss) in prose
- ASCII only for: file names, slugs, frontmatter identifiers

## Constraints

- DO NOT perform tier classification directly (delegate to skill)
- DO NOT calculate institutional authority mapping (delegate to skill)
- MUST return JSON-only response

## Instructions

### Step 0: Initialize Logging

```bash
mkdir -p "${PROJECT_PATH}/.logs"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [PHASE] evidence-synthesizer Started" >> "${PROJECT_PATH}/.logs/evidence-synthesizer-execution-log.txt"
```

### Phase 1: Validate Parameters

1. Check `PROJECT_PATH` non-empty
2. If invalid, return error JSON and exit

### Phase 1.5: Verify Prerequisites (BLOCKING)

Before invoking evidence-synthesizer skill, verify Phase 8 artifacts exist:

```bash
cd "${PROJECT_PATH}"
trend_count=$(find 11-trends/data -maxdepth 1 -type f -name "*.md" 2>/dev/null | xargs -I {} basename {} 2>/dev/null | grep -E "^(trend|portfolio)-.*\.md$" | wc -l | tr -d ' ')
```

IF `trend_count == 0`:

Return error JSON:

```json
{
  "success": false,
  "error": "Prerequisites missing for evidence-synthesizer",
  "missing": ["11-trends/data/ (deeper-research-3 Phase 8 output)"],
  "action": "Run deeper-research-3 skill to execute Phase 8 first",
  "command": "Skill(skill=\"cogni-research:deeper-research-3\")"
}
```

DO NOT proceed to Phase 2 (skill invocation) if trends are missing.

### Phase 2: Invoke Skill [MANDATORY SKILL DELEGATION]

⛔ **CRITICAL REQUIREMENT:** This step MUST use the Skill tool with args parameter.

<example>
<invoke name="Skill">
  <parameter name="skill">cogni-research:evidence-synthesizer</parameter>
  <parameter name="args">PROJECT_PATH={{PROJECT_PATH}} LANGUAGE={{LANGUAGE}}</parameter>
</invoke>
</example>

**Parameter Substitution:** Replace placeholders with actual values.

**⛔ SELF-CHECK (all must be YES):**

1. Did I invoke using the Skill tool? [YES/NO]
2. Did I pass parameters via the `args` parameter? [YES/NO]
3. Did I receive JSON output from the skill? [YES/NO]

**IF ANY ANSWER IS NO:** STOP. Re-invoke using the Skill tool exactly as shown above.

### Phase 3: Return JSON Only

**⚠️ CRITICAL:** Return ONLY JSON. No emojis, no summaries, no prose.

**Success:**

```json
{
  "success": true,
  "file": "09-citations/README.md",
  "sources_cataloged": 0,
  "citations_formatted": 0,
  "institutions_mapped": 0,
  "tier1_sources": 0,
  "tier2_sources": 0,
  "tier3_sources": 0,
  "research_type": "action-oriented-radar",
  "template_validation": "passed"
}
```

**Error:**

```json
{
  "success": false,
  "error": "{error_message}"
}
```

## Error Recovery

| Scenario | Action |
|----------|--------|
| Missing PROJECT_PATH | Return error JSON |
| Skill fails | Return skill error |
| Output not created | Return error JSON |
