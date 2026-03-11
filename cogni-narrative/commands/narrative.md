---
name: narrative
description: "Transform input files into an executive narrative using a story arc framework"
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

# /narrative Command

Transform a set of input markdown files into a compelling executive narrative using one of 6 story arc frameworks.

## Argument Parsing

Parse the user's arguments to extract:
- `source_path` (required) -- directory with .md files or single .md file
- `--arc` or `--arc-id` (optional) -- explicit arc: `corporate-visions`, `technology-futures`, `competitive-intelligence`, `strategic-foresight`, `industry-transformation`, `trend-panorama`
- `--lang` or `--language` (optional) -- `en` (default) or `de`
- `--output` or `-o` (optional) -- output file path

If `source_path` is missing, ask the user for it.

## Execution

1. Load the `cogni-narrative:narrative` skill using the Skill tool
2. Follow the skill's 6-phase workflow with the parsed parameters
3. Present the arc selection to the user for confirmation before transforming
4. Write the output and report the summary

## Examples

```
/narrative ./research-output/
/narrative ./analysis/ --arc technology-futures --lang de
/narrative ./report.md --arc corporate-visions -o ./insight-summary.md
```
