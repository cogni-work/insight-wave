---
name: narrative-review
description: "Score and review a narrative file against story arc quality gates"
argument-hint: "[source_path] [--arc arc_id] [--lang en|de]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - TodoWrite
---

# /narrative-review Command

Score an existing narrative markdown file against cogni-narrative quality gates. Produces a scorecard with pass/warn/fail per gate, overall score (0-100), and top 3 improvement suggestions.

## Argument Parsing

Parse the user's arguments to extract:
- `source_path` (required) -- path to the narrative `.md` file to review
- `--arc` or `--arc-id` (optional) -- override arc detection (uses frontmatter `arc_id` by default)
- `--lang` or `--language` (optional) -- override language detection (uses frontmatter `language` by default)

If `source_path` is missing, ask the user for it.

## Execution

1. Load the `cogni-narrative:narrative-review` skill using the Skill tool
2. Follow the skill's evaluation workflow with the parsed parameters
3. Present the scorecard summary to the user after completion
4. Highlight the top 3 improvements

## Examples

```
/narrative-review ./insight-summary.md
/narrative-review ./output/insight-summary.md --arc technology-futures
/narrative-review ./bericht.md --lang de
```
