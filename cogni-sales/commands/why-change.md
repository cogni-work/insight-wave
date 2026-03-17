---
name: why-change
description: Create a Why Change sales pitch for a named customer
usage: /why-change [--project-path <path>]
aliases: [pitch, sales-pitch]
category: sales
allowed-tools: [Read, Bash, Skill]
---

# /why-change

Create or resume a Why Change sales pitch for a named customer.

## Usage

```
/why-change                        # Start new pitch or discover existing
/why-change --project-path <path>  # Resume specific pitch project
```

## Behavior

**New pitch:** If no `--project-path` is provided:
1. Discover existing pitch projects via `pitch-status.sh`
2. If incomplete projects found: ask user to resume or start new
3. If no projects: invoke the `why-change` skill to start fresh

**Resume pitch:** If `--project-path` is provided:
1. Read pitch-log.json for current state
2. Resume from the last incomplete phase

## Examples

```
/why-change
> "Starting new pitch. Which customer are you pitching to?"

/why-change --project-path ./siemens-pitch
> "Resuming Siemens pitch — Phase 2 (Why Now) is next."
```

## Implementation

Invoke the `cogni-sales:why-change` skill:

```
Skill tool: cogni-sales:why-change
Args: {provided arguments}
```

If `--project-path` is provided, pass it through. Otherwise, first scan for existing projects:

```bash
# Find pitch projects in workspace
for dir in */; do
  if [ -f "${dir}.metadata/pitch-log.json" ]; then
    "${CLAUDE_PLUGIN_ROOT}/scripts/pitch-status.sh" "$dir"
  fi
done
```

Present discovered projects to user, then invoke the skill.
