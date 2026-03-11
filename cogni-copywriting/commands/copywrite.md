---
name: copywrite
description: Polish markdown documents for executive readability using McKinsey Pyramid Principle through copywriter agent orchestration
usage: /copywrite <file> [--scope=full|structure|tone|formatting] [--flesch-target=50-60]
aliases: [polish, executive-polish]
category: content-editing
allowed-tools: [Read, Task, Bash]
---

# Copywrite Command

Polish markdown documents into executive-ready content through the copywriter agent, applying McKinsey Pyramid Principle, tone transformation, and quality validation.

## Usage

```
/copywrite <file> [--scope=full|structure|tone|formatting] [--flesch-target=50-60]
```

## Parameters

### File (Required)

- **<file>** - Path to markdown file to polish
  - Accepts relative or absolute paths
  - Must be .md format
  - If path contains spaces, use quotes: "/path/to/my document.md"

### Optional Flags

- **--scope** - Polishing scope (default: full)
  - `full` - Complete polishing (structure, tone, formatting)
  - `structure` - McKinsey Pyramid restructuring only
  - `tone` - Academic to executive tone transformation only
  - `formatting` - Visual hierarchy and formatting only

- **--flesch-target** - Target Flesch Reading Ease score (default: language-aware)
  - English default: 50-60 (standard business difficulty)
  - German default: 30-50 (Amstad formula; compound words produce lower scores)
  - Easier reading: +10 above default range
  - More technical: -10 below default range

## Examples

### Example 1: Full Document Polish

```bash
/copywrite ./research-report.md
```

Polishes entire document with McKinsey Pyramid structure, executive tone, and optimized formatting.

**Output:**
```
**Document Polished**: research-report.md

**Quality Metrics:**
- Flesch Reading Ease: 56 (target: 50-60) ✓
- Avg Paragraph Length: 4.2 sentences (target: 3-5) ✓
- Visual Elements: 12 (callouts, tables, lists)
- Header Levels: 3 (target: ≤3) ✓

**Key Improvements:**
1. Applied McKinsey Pyramid structure (answer-first)
2. Transformed academic tone to executive voice
3. Added 8 visual elements for scannability

**Status**: ✅ Ready for executive presentation

**Next step:** Run `/review-doc research-report.md` to get stakeholder feedback from multiple perspectives
```

### Example 2: Structure-Only Polishing

```bash
/copywrite research-findings.md --scope=structure
```

Applies McKinsey Pyramid Principle restructuring without changing tone or formatting.

**Output:**
```
**Document Polished**: research-findings.md

**Scope**: Structure only (McKinsey Pyramid Principle)

**Changes Applied:**
- Moved answer to document start
- Grouped supporting arguments into 4 MECE categories
- Reordered sections by logical priority
- Preserved original tone and formatting

**Status**: ✅ Restructured with answer-first approach

**Next step:** Run `/review-doc research-findings.md` to validate with stakeholder perspectives
```

### Example 3: Tone Transformation Only

```bash
/copywrite technical-report.md --scope=tone
```

Transforms academic writing to executive voice while preserving structure.

**Output:**
```
**Document Polished**: technical-report.md

**Scope**: Tone transformation only

**Transformations:**
- Removed hedging language (38 instances)
- Converted passive to active voice (52 sentences)
- Simplified complex constructions (24 instances)
- Front-loaded important information

**Flesch Score**: 48 → 58 (20% improvement)

**Status**: ✅ Executive tone applied

**Next step:** Run `/review-doc technical-report.md` to get multi-stakeholder feedback
```

### Example 4: Formatting and Visual Hierarchy

```bash
/copywrite analysis.md --scope=formatting
```

Optimizes scannability through visual elements and paragraph optimization.

**Output:**
```
**Document Polished**: analysis.md

**Scope**: Formatting and visual hierarchy

**Enhancements:**
- Broke 18 dense paragraphs into 3-5 sentence units
- Added 10 callouts for key insights
- Created 4 comparison tables
- Optimized header hierarchy (5 levels → 3)

**Visual Elements**: 6 → 18 (3x improvement)

**Status**: ✅ Highly scannable with visual hierarchy

**Next step:** Run `/review-doc analysis.md` to validate readability with stakeholder personas
```

### Example 5: Custom Flesch Target

```bash
/copywrite executive-summary.md --flesch-target=60-70
```

Polishes document targeting easier readability for broader audiences.

**Output:**
```
**Document Polished**: executive-summary.md

**Custom Target**: Flesch 60-70 (easier reading)

**Quality Metrics:**
- Flesch Reading Ease: 65 (target: 60-70) ✓
- Avg Sentence Length: 12 words (simplified)
- Avg Paragraph Length: 3.8 sentences

**Key Improvements:**
1. Simplified vocabulary and sentence structures
2. Applied McKinsey Pyramid structure
3. Enhanced scannability with visual elements

**Status**: ✅ Accessible for broad executive audience

**Next step:** Run `/review-doc executive-summary.md` to get stakeholder feedback
```

## Features

✅ **Complete Copywriting Workflow**
- McKinsey Pyramid Principle restructuring (answer-first)
- SCR framework (Situation-Complication-Resolution)
- Academic to executive tone transformation
- Visual hierarchy optimization
- Quality validation with measurable metrics

✅ **Flexible Scoping**
- Full polish (default): All transformations
- Structure-only: Pyramid Principle restructuring
- Tone-only: Academic to executive voice
- Formatting-only: Visual elements and scannability

✅ **Quality Standards**
- Flesch Reading Ease: 50-60 (configurable)
- Paragraph length: 3-5 sentences average
- Visual elements: ~1 per 2 paragraphs
- Header hierarchy: Max 3 levels

✅ **Preservation Guarantees**
- Frontmatter metadata unchanged
- Wikilinks preserved exactly
- Technical accuracy maintained
- Citations intact

## Command Implementation

### 1. Parse Arguments

```
EXTRACT file_path from $1
  - IF empty: ERROR "file parameter required"
  - IF relative path: CONVERT to absolute using pwd
  - IF path contains spaces: HANDLE quoted strings

VALIDATE file_path:
  - File must exist
  - File must be .md extension
  - File must be readable

PARSE flags from $ARGUMENTS:
  - --scope: Extract value (full|structure|tone|formatting), default: full
  - --flesch-target: Extract range (e.g., "50-60"), default: "50-60"

VALIDATE parsed values:
  - Scope must be valid option
  - Flesch target must be numeric range
```

### 2. Prepare Task Parameters

```
CREATE task_parameters:
  FILE_PATH = absolute_file_path
  SCOPE = parsed_scope (default: "full")
  QUALITY_TARGETS = {
    "flesch_target": parsed_flesch_target,
    "preserve_technical": true
  }

FORMAT instructions for copywriter agent:
  "Polish the markdown document at {{FILE_PATH}}.

  Scope: {{SCOPE}}
  - full: Complete polishing (structure, tone, formatting)
  - structure: McKinsey Pyramid restructuring only
  - tone: Academic to executive transformation only
  - formatting: Visual hierarchy optimization only

  Quality Targets:
  - Flesch Reading Ease: {{QUALITY_TARGETS.flesch_target}}
  - Avg Paragraph Length: 3-5 sentences
  - Visual Elements: ~1 per 2 paragraphs
  - Header Hierarchy: Max 3 levels

  Return comprehensive quality metrics report with before/after comparison."
```

### 3. Execute Copywriter Agent

```
Task: copywriter
Instructions: {{formatted_instructions}}

WAIT for agent completion

RECEIVE polishing_result with:
  - Polished document written to filesystem
  - Quality metrics (Flesch score, paragraph stats, visual elements)
  - Key improvements applied
  - Before/after comparison
```

### 4. Format and Present Results

```
PARSE polishing_result:
  - filename = extract from path
  - quality_metrics = parse metrics object
  - improvements = parse improvements list
  - status = overall success/warnings

DISPLAY formatted output:
  "**Document Polished**: {filename}"
  ""
  IF custom scope:
    "**Scope**: {scope_description}"
    ""

  "**Quality Metrics:**"
  "- Flesch Reading Ease: {flesch} (target: {target}) {✓ or ⚠️}"
  "- Avg Paragraph Length: {avg} sentences (target: 3-5) {✓ or ⚠️}"
  "- Visual Elements: {count}"
  "- Header Levels: {max} (target: ≤3) {✓ or ⚠️}"
  ""

  "**Key Improvements:**"
  FOR EACH improvement IN improvements:
    "{index}. {improvement}"
  ""

  "**Status**: {status_icon} {status_message}"
  ""
  "**Next step:** Run `/review-doc {filename}` to get multi-stakeholder feedback before distribution"
```

### 5. Error Handling

**Missing File:**
```
IF file_path empty OR not exists:
  ERROR: "File not found: {file_path}"

  Usage: /copywrite <file> [--scope=full|structure|tone|formatting]

  Example: /copywrite ./document.md
```

**Invalid File Format:**
```
IF file_extension != ".md":
  ERROR: "Invalid file format: {extension}"

  Expected: Markdown file (.md)

  The copywriter command only supports markdown documents.
```

**Invalid Scope:**
```
IF scope NOT IN [full, structure, tone, formatting]:
  ERROR: "Invalid scope: {scope}"

  Valid options:
  - full (default): Complete polishing
  - structure: McKinsey Pyramid restructuring only
  - tone: Academic to executive transformation only
  - formatting: Visual hierarchy optimization only

  Usage: /copywrite <file> --scope=structure
```

**Agent Execution Failure:**
```
IF copywriter agent fails:
  ERROR: "Copywriter agent execution failed"

  Details: {agent_error}

  Troubleshooting:
  1. Verify copywriter agent exists at cogni-copywriting/agents/copywriter.md
  2. Check copywriter skill exists at cogni-copywriting/skills/copywriter/
  3. Ensure file path is valid and readable

  For help: /help copywrite
```

## Integration with Framework

**Agents Used:**
- **copywriter** - Orchestrates document polishing by delegating to copywriter skill

**Skills Used (via copywriter agent):**
- **copywriter** - Executes complete copywriting workflow with McKinsey Pyramid, tone transformation, quality frameworks, and validation

**Scripts Utilized (via copywriter skill):**
- `calculate_readability.py` - Compute Flesch Reading Ease scores, paragraph metrics, visual element counts

**Reference Files (via copywriter skill):**
- `quality-frameworks.md` - McKinsey Pyramid, SCR, MECE principles with detailed examples
- `tone-transformation.md` - 50+ academic-to-executive transformation patterns

**Execution Pattern:**
1. Command parses arguments and validates file
2. Command invokes copywriter agent with task parameters
3. Copywriter agent invokes copywriter skill
4. Copywriter skill executes 7-step polishing workflow
5. Results flow back: skill → agent → command → user

## Quality Standards

✅ **Claude Code Command Compliance**
- Rich frontmatter with usage, aliases, category
- Comprehensive 6-section structure minimum
- Multiple detailed examples (5 scenarios)
- Clear parameter documentation
- Detailed implementation logic
- Integration documentation

✅ **LLM-Control Architecture**
- Command orchestrates (parses args, formats output)
- Agent delegates (invokes skill with parameters)
- Skill executes (complete copywriting workflow)
- Scripts compute (readability calculations)
- Clear delegation boundaries

✅ **User Experience**
- Intuitive command syntax
- Flexible scoping options
- Clear quality metrics
- Actionable error messages
- Professional output formatting

## Notes

- Documents are overwritten in place (original content replaced)
- Frontmatter and wikilinks always preserved
- Technical accuracy maintained throughout
- Multiple invocations safe (idempotent within quality targets)
- Works with any markdown file (not limited to synthesis documents)
