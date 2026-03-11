---
name: reader
version: 1.0
description: This skill should be used when the user wants to review a document from different stakeholder perspectives, simulate how different audiences would read a document, or get multi-perspective feedback before distribution. Common triggers include "review document as stakeholder", "stakeholder review", "reader review", "read as executive", "review from technical perspective", "does this document work for [audience]", "get feedback on this document", "what would [role] think of this", "check if this is ready for stakeholders", or "simulate different readers".
allowed-tools: Read, Write, Edit, Bash, Task, TodoWrite, TodoRead
---

# Reader Skill

## Critical Constraints

### German Character Preservation

**MANDATORY:** ALL German-specific characters MUST be preserved exactly as written. NEVER convert to ASCII equivalents (ae, oe, ue, ss). This applies to ALL text: body, headers, citations, technical terms.

### Citation Preservation

**MANDATORY:** ALL citation markers and their URLs MUST be preserved exactly as written. Removing or omitting citations is a CRITICAL FAILURE. Citations are evidence markers for audit trail integrity.

### Protected Content

DO NOT modify diagram placeholders, figure references, figure captions, Obsidian embeds, or kanban tables. Preserve exactly as-is.

## When to Use

- Reviewing a finished document from specific stakeholder perspectives
- Validating document readiness for target audiences
- Getting structured feedback before distribution
- Identifying blind spots across different reader types
- Improving document quality through multi-perspective analysis

## Workflow

**Initialize TodoWrite** with these 6 steps, then execute sequentially:

1. Parse parameters and validate document
2. Create document backup
3. Run parallel persona analysis
4. Synthesize multi-persona feedback
5. Apply auto-improvement loop
6. Report results

### Step 1: Parse Parameters & Validate Document

**Extract from user request or agent invocation:**

- `FILE_PATH`: Absolute path to markdown document (required)
- `PERSONAS`: Array of perspectives to simulate (default: all five)
  - Options: `executive`, `technical`, `legal`, `marketing`, `end-user`
- `AUTO_IMPROVE`: Whether to apply improvements directly (default: true)

**Validate:**

1. File exists and is readable
2. File is markdown format (.md)
3. Personas are valid options

**Load persona references:**

```text
FOR EACH persona IN PERSONAS:
  READ: references/personas/{persona}.md
```

### Step 2: Create Document Backup

Before any analysis, create a backup:

```bash
dir=$(dirname "${FILE_PATH}")
filename=$(basename "${FILE_PATH}")
backup_path="${dir}/.${filename}.pre-reader-review"
cp "${FILE_PATH}" "${backup_path}"
```

Report: `Backup created: {backup_path}`

### Step 3: Run Parallel Persona Analysis

Launch one Task agent per persona to analyze the document in parallel. Each persona agent reads the document and produces structured feedback from their perspective.

**For each persona, launch a Task agent with this prompt:**

```
You are a {PERSONA_NAME} stakeholder reading a document. Your job is to evaluate it from your specific perspective and produce structured feedback.

DOCUMENT PATH: {FILE_PATH}

Read the document, then evaluate using the criteria from your persona profile.

PERSONA PROFILE:
{content from references/personas/{persona}.md}

INSTRUCTIONS:
1. Read the entire document carefully
2. Evaluate against each criterion in your profile
3. Generate 3-5 questions a real {PERSONA_NAME} stakeholder would ask after reading
4. Identify specific concerns with line references where possible
5. Provide concrete improvement recommendations

OUTPUT FORMAT (JSON only):
{
  "perspective": "{persona}",
  "score": <0-100>,
  "questions": ["Question 1?", "Question 2?", ...],
  "concerns": ["Concern with specific reference", ...],
  "recommendations": [
    {"priority": "CRITICAL|HIGH|OPTIONAL", "action": "Specific improvement to make", "location": "Section or paragraph reference"}
  ],
  "strengths": ["What works well", ...]
}
```

**Agent configuration per persona:**
- Model: use a fast model for parallel efficiency
- Tools: Read, Bash
- Wait for all agents to complete before proceeding

### Step 4: Synthesize Multi-Persona Feedback

After all persona agents return, synthesize their feedback.

**Load synthesis protocol:**

```text
READ: references/synthesis-protocol.md
```

**Synthesis process:**

1. **Collect all persona results** into a single array
2. **Identify cross-persona themes:**
   - Same issue raised by 3+ personas → CRITICAL
   - Same issue raised by 2 personas → HIGH
   - Same issue raised by 1 persona → keep original priority
   - Executive + 1 other on same issue → CRITICAL
3. **Resolve conflicts** using tiebreaker hierarchy:
   1. Primary audience perspective (infer from document type/content)
   2. Safety/compliance (legal concerns override style preferences)
   3. Clarity (end-user accessibility concerns override sophistication)
   4. Impact (executive/marketing persuasiveness)
4. **Deduplicate recommendations** - merge similar actions, keep highest priority
5. **Rank final recommendations** by priority then by number of personas who raised the issue

**Synthesis output:**

```json
{
  "persona_scores": {"executive": 78, "technical": 85, ...},
  "overall_score": 82,
  "cross_cutting_themes": [
    {"theme": "Missing quantification", "personas": ["executive", "marketing"], "priority": "CRITICAL"}
  ],
  "merged_recommendations": [
    {"priority": "CRITICAL", "action": "...", "sources": ["executive", "marketing"]},
    {"priority": "HIGH", "action": "...", "sources": ["technical"]}
  ],
  "all_questions": [
    {"persona": "executive", "question": "What's the expected ROI timeline?"},
    ...
  ]
}
```

### Step 5: Apply Auto-Improvement Loop

**If `AUTO_IMPROVE` is true (default):**

Apply ONE improvement pass based on synthesized recommendations.

**Process:**

1. **Apply all CRITICAL recommendations:**
   - For each: locate section, make the edit, verify protected content preserved
   - If edit would violate citation/German char rules, skip and log

2. **Apply HIGH recommendations where feasible:**
   - Only apply if: no external data needed, doesn't conflict with CRITICAL edits
   - Skip with reason if infeasible

3. **Log OPTIONAL recommendations** without applying

4. **Validate final document:**
   - German characters preserved (compare against backup)
   - Citations preserved (count must equal or exceed backup)
   - Protected content unchanged (diagrams, figures, embeds)
   - Readability maintained (run readability script if available)

**If validation fails:** Revert to backup and report failure reason.

### Step 6: Report Results

Present a comprehensive report to the user or calling agent.

**User-facing format:**

```markdown
## Reader Review: {filename}

**Personas consulted:** {list}
**Overall score:** {score}/100
**Backup:** {backup_path}
**Improvements applied:** {count}

### Persona Scores

| Persona | Score | Top Concern |
|---------|-------|-------------|
| Executive | 78 | Missing ROI timeline |
| Technical | 85 | Vague implementation details |
| ... | ... | ... |

### Questions Your Stakeholders Would Ask

**Executive:**
1. What's the expected payback period?
2. What happens if we delay this decision?

**Technical:**
1. What are the system dependencies?
2. How does this handle failure scenarios?

...

### Improvements Applied

1. **CRITICAL:** Added decision timeline (March 15, 2025) - raised Executive score to 88
2. **HIGH:** Broke dense paragraph into bullets - raised End-user score to 95
3. **OPTIONAL (logged):** Add vendor comparison table - requires external research

### Summary

{1-2 sentence summary of document readiness after improvements}
```

**JSON format (for agent/skill callers):**

```json
{
  "success": true,
  "file": "{filename}",
  "backup_path": "{backup_path}",
  "personas_consulted": ["executive", "technical", ...],
  "overall_score": 84,
  "persona_results": [...],
  "improvements_applied": 4,
  "improvements_skipped": 1,
  "questions": [...],
  "protected_content_preserved": true
}
```

## Bundled Resources

### Persona Profiles (references/personas/)

Each persona file defines:
- Perspective philosophy and priorities
- 5 weighted evaluation criteria
- Scoring guidelines
- Question generation patterns
- Common improvement patterns

Available personas:
- **executive.md** - Decision-readiness, quantification, time respect, clarity, credibility
- **technical.md** - Accuracy, logical flow, precision, completeness, terminology
- **legal.md** - Risk language, regulatory alignment, liability, evidence standards, disclosure
- **marketing.md** - Audience resonance, persuasiveness, brand tone, CTA, emotional connection
- **end-user.md** - Plain language, immediate clarity, actionability, visual clarity, empathy

### Synthesis Protocol (references/synthesis-protocol.md)

- Cross-persona theme identification rules
- Conflict resolution patterns and tiebreaker hierarchy
- Recommendation merging and deduplication
- Auto-improvement validation checklist
