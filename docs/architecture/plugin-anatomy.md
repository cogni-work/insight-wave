# Plugin Anatomy

This document describes how insight-wave plugins are structured. Every plugin follows the same conventions for directories, files, naming, and metadata. Understanding the anatomy helps you read any plugin quickly and build new plugins that integrate naturally.

---

## Standard Directory Structure

A fully featured plugin looks like this:

```
{plugin-name}/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata and version
├── skills/
│   └── {skill-name}/
│       ├── SKILL.md             # Skill definition (frontmatter + body)
│       └── references/          # Optional: skill-local reference files
├── agents/
│   └── {agent-name}.md         # Agent definition (frontmatter + system prompt)
├── commands/
│   └── {command-name}.md       # Slash command definition
├── hooks/
│   ├── hooks.json               # Hook event bindings
│   └── {script-name}.sh        # Hook implementation scripts
├── scripts/
│   └── {script-name}.sh        # Utility scripts (bash or python3)
├── references/
│   └── {reference-name}.md     # Plugin-wide reference files
├── templates/
│   └── {template-name}/        # Pluggable templates (e.g., industry taxonomies)
├── CLAUDE.md                    # Developer reference (architecture, conventions)
├── CONTRIBUTING.md              # Contribution terms
├── LICENSE                      # AGPL-3.0-only
└── README.md                    # User-facing introduction
```

Not every plugin uses every directory. cogni-claims has no `scripts/` directory. cogni-workspace has no `agents/` directory. cogni-visual has a `libraries/` directory (shared reference material loaded by multiple agents) rather than per-skill `references/` subdirectories.

---

## `.claude-plugin/plugin.json`

The plugin manifest identifies the plugin and its version. Claude Code uses this file to discover and register the plugin.

```json
{
  "name": "cogni-claims",
  "version": "1.0.6",
  "description": "Claim verification and management system. Verifies sourced claims against cited URLs, detects deviations, and guides users through resolution.",
  "author": {
    "name": "Stephan de Haas",
    "email": "stephan@cogni-work.ai"
  },
  "license": "AGPL-3.0-only",
  "keywords": [
    "claim-verification",
    "fact-checking",
    "source-validation",
    "deviation-detection",
    "cross-plugin-contract"
  ]
}
```

Versions follow semantic versioning. The `description` field is read by marketplace tooling — write it as one or two sentences describing what the plugin does, not why it exists.

---

## SKILL.md Structure

A skill definition is a Markdown file with YAML frontmatter. Claude Code reads the frontmatter to determine when to activate the skill and which tools it may use. The Markdown body is the system prompt that runs when the skill activates.

```yaml
---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with structural
  review. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Claims verification runs separately via verify-report.
  ...
  Use when the user asks to "research report", "investigate", "deep research", "write a report",
  ...
  Also use when the user wants to "resume research", "continue research report", ...
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, Task, Skill, AskUserQuestion
---

# Research Report Skill

When this skill loads:
1. If no topic was provided → ask: "What topic should I research?"
...
```

**`name`** — the skill identifier, used in slash commands and inter-plugin `Skill` tool calls.

**`description`** — the trigger specification. This field determines when Claude Code activates this skill instead of running without a skill context. Write it as a plain-language description of what the skill does, then add explicit trigger phrases covering how users actually phrase requests, including common variants and other languages if the plugin targets multilingual audiences.

**`allowed-tools`** — the tool allowlist. The skill runs with exactly these tools available. Skills that spawn agents include `Agent` in the list. Skills that perform web research include `WebSearch` and `WebFetch`. Skills that need to ask clarifying questions include `AskUserQuestion`.

The Markdown body is the full operating instructions for the skill. Structure it however makes sense for the workflow: numbered phases, conditional branches, quick examples, configuration menus. The skill body is not shown to the user — it is the assistant's working instructions.

---

## Agent Definition

Agent files live in `agents/` as Markdown files with YAML frontmatter. Agents are invoked by skills using the `Task` tool (via the `Agent` allowed-tool).

```yaml
---
name: section-researcher
description: |
  Use this agent when performing parallel web research for a single sub-question or
  report section. Executes WebSearch queries, fetches relevant pages, extracts
  findings, and creates context + source entities.

  <example>
  Context: research-report skill Phase 2 spawns parallel researchers.
  user: "Research sub-question at /project/00-sub-questions/data/sq-post-quantum-crypto-a1b2c3d4.md"
  assistant: "Invoke section-researcher to execute web searches and create context/source entities."
  <commentary>Each sub-question gets its own section-researcher instance.</commentary>
  </example>

model: sonnet
color: cyan
tools: ["WebSearch", "WebFetch", "Read", "Write", "Bash", "Glob"]
---

# Section Researcher Agent

## Role
...
```

**`name`** — the agent identifier. By convention, worker agents use noun-verb or role-based names (`section-researcher`, `claim-verifier`). Orchestrator-wrapper agents use the output type (`storyboard`, `web`).

**`description`** — the routing specification. Include `<example>` blocks with realistic context, user message, and `<commentary>` explaining when this agent is the right choice. This helps the skill's orchestration logic select the correct agent.

**`model`** — the model to use. Common values:
- `sonnet` — default for research, synthesis, and writing agents
- `haiku` — quality assessment agents and web research at scale (cost-sensitive parallelism)
- `inherit` — use the caller's model (appropriate for delegation agents that don't do independent reasoning)

**`color`** — the terminal color for this agent's output (used by Claude Code's agent display). Common conventions: `cyan` for research agents, `green` for generation/verification agents, `yellow` for review agents.

**`tools`** — JSON array of tool names available to this agent. Agents receive a narrower tool set than skills because they perform specific, bounded tasks.

The Markdown body is the agent's system prompt. Start with a clear role statement ("You research a single sub-question..."). Then describe the input contract (what the agent receives), the output contract (what it produces), and any behavioral constraints.

---

## Hook Patterns

Hooks let a plugin intercept tool calls and lifecycle events to enforce constraints, guard against state corruption, or trigger side effects.

Hooks are defined in `hooks/hooks.json`:

```json
{
  "version": "1.0",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-entity-writes.sh",
            "timeout": 5,
            "enabled": true,
            "name": "block-entity-writes",
            "description": "Blocks Write/Edit to entity directories — forces create-entity.sh usage"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/review-loop-guard.sh",
            "timeout": 10,
            "enabled": true,
            "name": "review-loop-guard",
            "description": "Enforces max 3 review iterations."
          }
        ]
      }
    ]
  }
}
```

**`PreToolUse`** — runs before a tool call. Use this to validate, block, or modify the action before it happens. cogni-portfolio uses a PreToolUse hook to block direct Write/Edit calls to entity directories, forcing all entity creation through `create-entity.sh` (which applies hooks, timestamps, and frontmatter correctly).

**`PostToolUse`** — runs after a tool call completes. Use this to enforce invariants on the outcome. A review-loop guard hook can count completed review iterations after each `Task` call and signal forced acceptance when the limit is reached, preventing infinite review cycles.

**`Stop`** — runs when the conversation turn ends. Useful for cleanup or state persistence.

**`matcher`** — a regex pattern matching tool names. `"Write|Edit"` matches both Write and Edit tools. `"mcp__excalidraw__.*"` matches any Excalidraw MCP tool. `"Skill"` matches the Skill invocation tool.

Hook scripts receive context via environment variables including `CLAUDE_PLUGIN_ROOT` (the plugin's directory path). Scripts must complete within the `timeout` (seconds) and should exit 0 for success, non-zero to block the tool call.

---

## Naming Conventions

**Skill names** follow a tiered convention:

| Tier | When to use | Pattern | Examples |
|------|-------------|---------|---------|
| A — Domain-unique | Only one plugin would ever own this word | bare name | `propositions`, `customers`, `compete` |
| B — Generic verb/noun | Multiple plugins could have this skill | `{domain}-{verb}` | `portfolio-scan`, `trends-catalog`, `copy-reader` |
| C — Cross-plugin | Skill spans two domains | descriptive compound | `trends-bridge` |

Order is always `domain-verb`, not `verb-domain`. This groups skills alphabetically by plugin domain in the skill list.

Generic words that always require a prefix: `setup`, `scan`, `ingest`, `export`, `dashboard`, `verify`, `bridge`, `catalog`, `reader`, `config`, `status`, `analyze`, `resume`.

Validate names with `cogni-workspace/scripts/check-skill-names.sh` before submitting a PR.

**Agent names** follow role-based patterns:
- Worker agents: `{role}-{task}` — `section-researcher`, `claim-verifier`
- Orchestrator-wrapper agents: `{output-type}` — `storyboard`, `web`
- Assessment agents: `{entity}-{task}-assessor` — `proposition-quality-assessor`, `feature-review-assessor`

**File slugs** use kebab-case derived from the entity or concept name. No underscores, no camelCase, no spaces.

**Script names** describe the operation: `create-entity.sh`, `project-status.sh`, `cascade-rename.sh`. Scripts use JSON output format: `{"success": bool, "data": {...}, "error": "string"}`. All scripts are stdlib-only — no pip dependencies, no npm dependencies.

---

## Related Documents

- [design-philosophy.md](design-philosophy.md) — the principles that explain why this structure exists
- [contributing/plugin-development.md](../contributing/plugin-development.md) — step-by-step guide to building a plugin
