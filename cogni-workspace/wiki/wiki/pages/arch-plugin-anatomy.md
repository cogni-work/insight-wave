---
id: arch-plugin-anatomy
title: Plugin anatomy (architecture)
type: summary
tags: [architecture, plugin-structure, conventions]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/plugin-anatomy.md
status: stable
---

How insight-wave plugins are structured on disk. Every plugin follows the same shape so reading one makes the next one familiar.

## Standard directory structure

```
{plugin-name}/
├── .claude-plugin/plugin.json    Plugin manifest, version, semver
├── skills/{skill-name}/SKILL.md  Skill definitions (frontmatter + body)
├── agents/{agent-name}.md        Agent definitions
├── commands/{command-name}.md    Slash command definitions
├── hooks/hooks.json + *.sh       Hook bindings + scripts (optional)
├── scripts/*.sh                  Utility scripts (bash + python3, stdlib only)
├── references/*.md               Plugin-wide framework references
├── templates/                    Pluggable templates (optional)
├── CLAUDE.md                     Developer reference
├── CONTRIBUTING.md, LICENSE      Apache-2.0
└── README.md                     User-facing introduction
```

Not every plugin uses every directory. cogni-claims has no `scripts/`, cogni-workspace has no `agents/`, cogni-visual has `libraries/` instead of per-skill `references/`.

## The four file kinds

- **`plugin.json`** — name, version, description, author, license, keywords. The description is read by marketplace tooling, so it's one or two sentences about what the plugin does, not why it exists.
- **`SKILL.md`** — YAML frontmatter (`name`, `description`, `allowed-tools`) followed by the system prompt body. The description field is the trigger specification — it determines when Claude Code activates this skill — so it lists explicit trigger phrases including multilingual variants when relevant.
- **`agents/{name}.md`** — frontmatter (`name`, `description`, `model`, `color`, `tools`) plus the agent's system prompt. Models are picked per role — see [[concept-agent-model-strategy]]. Tools are narrower than a skill's tool set because agents do bounded tasks.
- **`hooks/hooks.json` + scripts** — `PreToolUse`/`PostToolUse`/`Stop` matchers binding regex tool patterns to bash scripts. cogni-research uses these to block direct entity writes and cap review iterations.

## Naming conventions

Skill names follow tier rules (see [[concept-naming-conventions]]): bare names for domain-unique skills (`propositions`, `customers`), `{domain}-{verb}` for generic ones (`portfolio-scan`, `trends-catalog`), descriptive compounds for cross-plugin skills (`trends-bridge`). Generic words like `setup`, `scan`, `dashboard`, `verify`, `resume` always require a domain prefix. Validate with `cogni-workspace/scripts/check-skill-names.sh`.

Agent names follow role-based patterns: worker agents `{role}-{task}` (`section-researcher`), orchestrator-wrappers use the output type (`storyboard`, `web`), assessors use `{entity}-{task}-assessor` (`proposition-quality-assessor`).

File slugs use kebab-case from entity or concept names — no underscores, no camelCase, no spaces. Scripts use the standard JSON output format ([[concept-script-output-format]]) and are stdlib-only — no pip or npm dependencies anywhere.

**Source**: [docs/architecture/plugin-anatomy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/plugin-anatomy.md)
