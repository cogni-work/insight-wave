---
name: cheatsheet
description: >-
  Generate quick-reference cards for any insight-wave plugin. Use this skill whenever
  the user asks for a cheatsheet, cheat sheet, quick reference, summary of a plugin,
  "commands for cogni-X", "tldr cogni-X", "what does cogni-X do", "remind me how to
  use cogni-X", or wants a compact overview of a plugin's capabilities without taking
  a full course. Also trigger when a user needs a refresher on a plugin they've used
  before but can't remember the exact commands or concepts.
version: 0.1.0
allowed-tools: Read, Glob, Grep
---

# cheatsheet: Quick Reference Cards

Generate concise, one-screen reference cards for any insight-wave plugin. Faster than
reading docs or taking a course — designed for users who need a quick refresher.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Write cheatsheet descriptions, concept
explanations, and pattern guidance in that language.

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names (`cogni-trends`, `cogni-narrative`, etc.)
- Command names (`/cheatsheet`, `/workflow`, etc.)
- Column headers in the Commands table (`Command`, `What it does`)
- Technical terms, file paths, code snippets

## How to Generate a Cheatsheet

1. **Identify the plugin** from the user's request. Accept plugin names with or
   without the `cogni-` prefix ("tips" = "cogni-trends").

2. **Read the plugin's key files**:
   - `<plugin>/README.md` — overview, components, data model
   - `<plugin>/.claude-plugin/plugin.json` — name, description, version
   - `<plugin>/skills/*/SKILL.md` — skill descriptions (frontmatter only, not full body)
   - `<plugin>/commands/*.md` — available commands (frontmatter only)

3. **Generate the cheatsheet** using this exact template:

```
# <Plugin Name> Cheatsheet (v<version>)

<One-line description>

## Commands
| Command | What it does |
|---------|-------------|
| /command-1 | Brief description |
| /command-2 | Brief description |

## Core Concepts
- **Concept 1**: One-sentence explanation
- **Concept 2**: One-sentence explanation
- **Concept 3**: One-sentence explanation

## Data Model
<Key files/state the plugin creates and where they live>

## Common Patterns
1. Pattern name — when and how to use it
2. Pattern name — when and how to use it

## Related Plugins
- **cogni-X**: How it connects (feeds into / requires / complements)
- **cogni-Y**: How it connects

## Learn More
Full guide: docs/plugin-guide/<plugin-name>.md | Tour: /teach <tour-id>
```

## Guidelines

- **Brevity is the point.** Each section should fit in a few lines. If you need
  more space, you're including too much detail — point to the README instead.
- **Commands first.** Users come to cheatsheets primarily for command references.
- **3-5 core concepts.** Pick the ones that are essential to using the plugin
  effectively. Skip implementation details.
- **Actionable patterns.** "Start with X, then Y" is more useful than explaining
  what X does abstractly.
- **Always include related plugins.** The ecosystem is interconnected — showing
  how plugins connect helps users plan their workflow.
- **Include a Learn More footer.** If `docs/plugin-guide/<plugin>.md` exists, link to
  it. Also include the corresponding `/teach` workflow tour from the curriculum
  (e.g., cogni-trends → `tour-trends-to-solutions`, cogni-portfolio →
  `tour-portfolio-to-pitch`, cogni-research → `tour-research-to-report`).

## Listing Plugins

When `/cheatsheet` is invoked with no argument, list all available plugins with
a one-line description and suggest the user pick one. Use the plugin catalog from
the guide skill (`../guide/references/plugin-catalog.md`) for the list.
