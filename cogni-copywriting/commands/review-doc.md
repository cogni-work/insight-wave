---
name: review-doc
description: Review a document through parallel stakeholder persona simulation with Q&A feedback and automatic improvement
usage: /review-doc <file> [--personas=executive,technical,legal,marketing,end-user] [--no-improve]
aliases: [reader-review, stakeholder-review]
category: content-editing
allowed-tools: [Read, Task, Bash]
---

# Review-Doc Command

Review markdown documents from multiple stakeholder perspectives simultaneously, synthesize feedback, and optionally apply improvements.

## Usage

```
/review-doc <file> [--personas=executive,technical,legal,marketing,end-user] [--no-improve]
```

## Parameters

### File (Required)

- **<file>** - Path to markdown file to review
  - Accepts relative or absolute paths
  - Must be .md format
  - If path contains spaces, use quotes

### Optional Flags

- **--personas** - Comma-separated stakeholder perspectives (default: all five)
  - `executive` - Decision-readiness, quantification, clarity
  - `technical` - Accuracy, logic, precision, completeness
  - `legal` - Risk language, compliance, liability, disclosure
  - `marketing` - Audience resonance, persuasiveness, CTA
  - `end-user` - Plain language, clarity, actionability

- **--no-improve** - Skip automatic improvement, produce feedback only

## Examples

### Example 1: Full Review with All Personas

```bash
/review-doc ./proposal.md
```

Reviews document from all 5 stakeholder perspectives, synthesizes feedback, and applies improvements.

**Output:**
```
## Reader Review: proposal.md

**Personas consulted:** executive, technical, legal, marketing, end-user
**Overall score:** 82/100
**Backup:** ./.proposal.md.pre-reader-review
**Improvements applied:** 4

### Persona Scores

| Persona | Score | Top Concern |
|---------|-------|-------------|
| Executive | 78 | Missing decision timeline |
| Technical | 85 | Vague implementation details |
| Legal | 80 | Absolute guarantee language |
| Marketing | 82 | Weak call-to-action |
| End-user | 90 | Paragraph 3 too dense |

### Questions Your Stakeholders Would Ask

**Executive:**
1. What's the expected payback period?
2. What are our alternatives?

**Technical:**
1. What are the system dependencies?
2. How does this handle failures?

### Improvements Applied

1. CRITICAL: Added decision deadline (March 15)
2. CRITICAL: Hedged absolute guarantee language
3. HIGH: Strengthened call-to-action
4. HIGH: Broke dense paragraph into bullets

Status: Document improved, backup preserved
```

### Example 2: Targeted Persona Review

```bash
/review-doc ./memo.md --personas=executive,legal
```

Reviews only from executive and legal perspectives.

### Example 3: Feedback Only (No Edits)

```bash
/review-doc ./report.md --no-improve
```

Produces stakeholder feedback without modifying the document.

## Command Implementation

### 1. Parse Arguments

```
EXTRACT file_path from $1
  - IF empty: ERROR "file parameter required"
  - IF relative: CONVERT to absolute using pwd

PARSE flags from $ARGUMENTS:
  - --personas: Extract comma-separated list (default: all)
  - --no-improve: Set AUTO_IMPROVE=false (default: true)

VALIDATE:
  - File exists and is .md format
  - Personas are valid options
```

### 2. Execute Reader Agent

```
Task: reader
Instructions: Review {FILE_PATH}
  PERSONAS: {parsed personas}
  AUTO_IMPROVE: {true unless --no-improve}

WAIT for agent completion
RECEIVE review results
```

### 3. Format and Present Results

Format the reader agent's JSON output as user-friendly markdown with:
- Persona score table
- Top questions per persona
- Improvements applied (if any)
- Backup location
- Overall assessment

### 4. Error Handling

**Missing File:**
```
ERROR: "File not found: {file_path}"
Usage: /review-doc <file> [--personas=executive,technical]
```

**Invalid Personas:**
```
ERROR: "Invalid persona: {persona}"
Valid: executive, technical, legal, marketing, end-user
```

## Integration

**Agents Used:**
- **reader** - Orchestrates document review by delegating to reader skill

**Skills Used (via reader agent):**
- **reader** - Executes parallel persona analysis, synthesis, and improvement

**Execution Pattern:**
1. Command parses arguments and validates file
2. Command invokes reader agent with parameters
3. Reader agent invokes reader skill
4. Reader skill runs parallel persona agents, synthesizes, and improves
5. Results flow back: skill -> agent -> command -> user
