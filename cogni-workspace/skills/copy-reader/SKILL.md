---
name: copy-reader
description: This skill should be used when the user wants to review a document from different stakeholder perspectives, simulate how different audiences would read a document, or get multi-perspective feedback before distribution. Common triggers include "review document as stakeholder", "stakeholder review", "reader review", "read as executive", "review from technical perspective", "does this document work for [audience]", "get feedback on this document", "what would [role] think of this", "check if this is ready for stakeholders", or "simulate different readers".
allowed-tools: Read, Edit, Bash, Agent, TodoWrite
---

# Reader Skill

## Critical Constraints

### German Character Preservation

German characters (ä, ö, ü, ß and their uppercase forms) stay exactly as written in every part of the text — body, headers, citations, technical terms. Converting them to ASCII equivalents (ae, oe, ue, ss) changes meaning — "Masse" (mass) vs "Maße" (measurements) — and signals to German readers that the text was processed carelessly.

### Citation Preservation

Citation markers and their URLs stay exactly as written. They are the evidence trail a reviewer audits the document against, so a persona summary that drops or rewrites one has destroyed the thing it was asked to evaluate.

### Protected Content

Leave diagram placeholders, figure references, figure captions, Obsidian embeds and kanban tables untouched — they are rendered by other tooling, and a persona reading them as prose produces feedback about scaffolding rather than content.

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
- `PERSONAS`: Array of perspectives to simulate (default: all five generic)
  - Built-in: `executive`, `technical`, `legal`, `marketing`, `end-user`
  - Custom: any `references/persona-<name>.md` file is a valid persona; pass the `<name>` part (e.g. `cdo-utility` for `references/persona-cdo-utility.md`, `cmo-provider` for `references/persona-cmo-provider.md`)
- `AUTO_IMPROVE`: Whether to apply improvements directly (default: true)

**Validate:**

1. File exists and is readable
2. File is markdown format (.md)
3. Personas are valid options

**Load persona references:**

```text
FOR EACH persona IN PERSONAS:
  READ: references/persona-{persona}.md
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

Launch one subagent per persona via the Agent tool to analyze the document in parallel. Each persona agent reads the document and produces structured feedback from their perspective.

**For each persona, launch an Agent with this prompt:**

```
You are a {PERSONA_NAME} stakeholder reading a document. Your job is to evaluate it from your specific perspective and produce structured feedback.

DOCUMENT PATH: {FILE_PATH}

Read the document, then evaluate using the criteria from your persona profile.

PERSONA PROFILE:
{content from references/persona-{persona}.md}

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
2. **Identify cross-persona themes**, then **resolve conflicts** — apply the
   `### Priority Escalation` table and the tiebreaker hierarchy from
   `references/synthesis-protocol.md`, loaded above. That file is the single
   copy of both: its escalation rows are ordered and applied first-match-wins,
   and its tiebreaker ranking puts safety/compliance above style. Do not
   restate either here — a second copy is what drifts.
3. **Deduplicate recommendations** - merge similar actions, keep highest priority
4. **Rank final recommendations** by priority then by number of personas who raised the issue

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

### Persona Profiles (references/persona-*.md)

Each persona file defines:
- Perspective philosophy and priorities
- 5 weighted evaluation criteria
- Scoring guidelines
- Question generation patterns
- Common improvement patterns

Available personas (any `references/persona-<name>.md` file is valid; the persona name is the `<name>` part):
- **persona-executive.md** - Decision-readiness, quantification, time respect, clarity, credibility
- **persona-technical.md** - Accuracy, logical flow, precision, completeness, terminology
- **persona-legal.md** - Risk language, regulatory alignment, liability, evidence standards, disclosure
- **persona-marketing.md** - Audience resonance, persuasiveness, brand tone, CTA, emotional connection
- **persona-end-user.md** - Plain language, immediate clarity, actionability, visual clarity, empathy
- **persona-cdo-utility.md** - CDO of energy utility (buyer): unconsidered need landing, actionability, regulatory urgency, ROI credibility, operational relevance
- **persona-cmo-provider.md** - CMO of IT provider (seller): pipeline opening, portfolio differentiation, narrative arc, go-to-market utility, competitive moat

### Synthesis Protocol (references/synthesis-protocol.md)

- Cross-persona theme identification rules
- Conflict resolution patterns and tiebreaker hierarchy
- Recommendation merging and deduplication
- Auto-improvement validation checklist

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
