---
name: narrative-adapt
description: "Transform a narrative into derivative formats: executive brief, talking points, or one-pager"
argument-hint: "[source_path] --format executive-brief|talking-points|one-pager [-o output_path]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - TodoWrite
---

# /narrative-adapt Command

Transform a full cogni-narrative output into a derivative format for different communication contexts.

## Argument Parsing

Parse the user's arguments to extract:
- `source_path` (required) -- path to the narrative `.md` file to adapt
- `--format` (required) -- target format: `executive-brief`, `talking-points`, or `one-pager`
- `--output` or `-o` (optional) -- output file path (defaults to `{source-dir}/{format}.md`)
- `--lang` or `--language` (optional) -- override language (uses source frontmatter by default)

If `source_path` is missing, ask the user for it.
If `--format` is missing, present the available formats to the user for selection.

## Available Formats

| Format | Output | Purpose |
|--------|--------|---------|
| `executive-brief` | 300-500 word condensed narrative | Email, Slack sharing |
| `talking-points` | Bullet list by arc element | Presentations, verbal briefings |
| `one-pager` | Structured reference with key stats | Print, quick reference |

## Execution

1. Load the `cogni-narrative:narrative-adapt` skill using the Skill tool
2. Follow the skill's transformation workflow with the parsed parameters
3. Present the output summary to the user after completion

## Examples

```
/narrative-adapt ./insight-summary.md --format executive-brief
/narrative-adapt ./insight-summary.md --format talking-points -o ./briefing-notes.md
/narrative-adapt ./bericht.md --format one-pager --lang de
```
