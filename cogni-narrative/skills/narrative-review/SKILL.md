---
name: narrative-review
description: "Score and review existing narrative files against story arc quality gates. This skill should be used when the user asks to 'review a narrative', 'score a narrative', 'check narrative quality', 'validate narrative', 'audit narrative', 'grade a narrative', 'evaluate narrative quality', 'narrative scorecard', 'rate my narrative', 'run quality gates on a narrative', or when the narrative-reviewer agent evaluates a generated narrative."
---

# Narrative Review

## Purpose

Evaluate an existing narrative markdown file against the cogni-narrative quality gates. Produce a structured scorecard with pass/warn/fail per gate, an overall score (0-100), and the top 3 actionable improvement suggestions.

## When to Use

- Review a narrative after generation to assess quality
- Audit an existing insight summary for arc compliance
- Compare narrative quality before and after edits
- Score narratives for quality tracking across projects

**Not for:**
- Generating new narratives (use `cogni-narrative:narrative` skill instead)
- Editing or rewriting narratives (use copywriter skill instead)
- Adapting narratives to other formats (use `cogni-narrative:narrative-adapt` skill instead)

---

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Path to the narrative `.md` file to review |
| `--arc-id` | No | Override arc detection (uses frontmatter `arc_id` by default) |
| `--language` | No | Override language detection (uses frontmatter `language` by default) |

---

## Output

Two outputs:

1. **Markdown scorecard** written to `{source-dir}/narrative-review.md`
2. **JSON summary** returned on completion

### JSON Summary

```json
{
  "success": true,
  "source_path": "insight-summary.md",
  "arc_id": "corporate-visions",
  "overall_score": 82,
  "grade": "B",
  "gates": {
    "structural": "pass",
    "critical": "pass",
    "evidence": "warn",
    "structure": "pass",
    "language": "pass"
  },
  "top_improvements": [
    "Add 3 more citations to reach minimum 15 (currently 12)",
    "Expand 'Why Now' section by ~40 words to meet 300-word minimum",
    "Add citation to uncited quantitative claim in paragraph 3 of 'Why Change'"
  ]
}
```

### Grading Scale

| Score | Grade | Meaning |
|-------|-------|---------|
| 90-100 | A | Publication-ready, all gates pass |
| 80-89 | B | Strong, minor improvements possible |
| 70-79 | C | Acceptable, several improvements needed |
| 60-69 | D | Below standard, significant rework needed |
| 0-59 | F | Fails critical gates, major rework required |

---

## Execution Protocol

### Step 1: Load Narrative

1. Read the narrative file from `--source-path`
2. Extract YAML frontmatter fields: `title`, `subtitle`, `arc_id`, `arc_display_name`, `word_count`, `language`, `date_created`, `source_file_count`
3. If frontmatter is missing or incomplete, flag as critical issue
4. Determine `arc_id` from: explicit parameter > frontmatter > detection failure
5. Determine `language` from: explicit parameter > frontmatter > default `en`

### Step 2: Load Arc Standards

Read the arc definition to know expected element names, word targets, and quality gates:

1. **Read:** `../narrative/references/story-arc/arc-registry.md` -- for arc metadata
2. **Read:** `../narrative/references/story-arc/{arc_id}/arc-definition.md` -- for element definitions and word targets
3. **Read:** `../narrative/references/language-templates.md` -- for localized header names

Store the expected element names, word targets, and citation requirements.

### Step 3: Run Quality Gates

Evaluate the narrative against each gate category. Use the scoring rubric in [references/scoring-rubric.md](references/scoring-rubric.md).

**Gate evaluation order (matches narrative skill Phase 5):**

1. **Structural Gate** (30 points max)
2. **Critical Gate** (25 points max)
3. **Evidence Gate** (25 points max)
4. **Structure Gate** (10 points max)
5. **Language Gate** (10 points max)

For each gate:
- Count specific pass/fail criteria
- Assign points based on rubric
- Determine gate status: `pass` / `warn` / `fail`

### Step 4: Generate Scorecard

Write `narrative-review.md` to the same directory as the source file:

```markdown
---
type: narrative-review
source: "{source filename}"
arc_id: "{arc_id}"
overall_score: {0-100}
grade: "{A-F}"
date_reviewed: "{ISO 8601}"
---

# Narrative Review: {source filename}

**Arc:** {arc_display_name} | **Score:** {score}/100 ({grade}) | **Language:** {language}

---

## Gate Results

| Gate | Status | Score | Details |
|------|--------|-------|---------|
| Structural | {pass/warn/fail} | {x}/30 | {summary} |
| Critical | {pass/warn/fail} | {x}/25 | {summary} |
| Evidence | {pass/warn/fail} | {x}/25 | {summary} |
| Structure | {pass/warn/fail} | {x}/10 | {summary} |
| Language | {pass/warn/fail} | {x}/10 | {summary} |
| **Total** | | **{total}/100** | |

---

## Top 3 Improvements

1. {Most impactful improvement with specific action}
2. {Second improvement with specific action}
3. {Third improvement with specific action}

---

## Detailed Analysis

### Structural Gate ({x}/30)

{Detailed findings for each structural criterion}

### Critical Gate ({x}/25)

{Detailed findings for each critical criterion}

### Evidence Gate ({x}/25)

{Detailed findings for each evidence criterion}

### Structure Gate ({x}/10)

{Detailed findings for each structure criterion}

### Language Gate ({x}/10)

{Detailed findings for each language criterion}
```

### Step 5: Return JSON Summary

Return the JSON summary (see Output section above).

---

## Gate Evaluation Details

For detailed scoring criteria per gate -- including partial credit rules, counting methods, and edge cases -- load [references/scoring-rubric.md](references/scoring-rubric.md).

**Gate summary:** Structural (30 pts) | Critical (25 pts) | Evidence (25 pts) | Structure (10 pts) | Language (10 pts)

---

## Constraints

- DO NOT modify the narrative file -- this is a read-only review
- DO NOT fabricate or assume quality issues -- only report what is measurably found
- ALWAYS use the arc definition's exact word targets for scoring
- ALWAYS check against the language-specific header names

---

## Bundled Resources

| File | Purpose | Load When |
|------|---------|-----------|
| `references/scoring-rubric.md` | Detailed scoring weights and edge cases | Step 3 |

**Cross-skill dependencies** (files owned by the `narrative` skill):

| File | Purpose | Load When |
|------|---------|-----------|
| `../narrative/references/story-arc/arc-registry.md` | Arc metadata and detection algorithm | Step 2 |
| `../narrative/references/story-arc/{arc_id}/arc-definition.md` | Element names and word targets | Step 2 |
| `../narrative/references/language-templates.md` | Localized header names per arc | Step 2 |
