# Plugin Development Guide

This guide walks through building a new insight-wave plugin from scratch. It covers directory structure, the SKILL.md format, agent definitions, documentation conventions, and the marketplace submission process.

Before you start, read [architecture/plugin-anatomy.md](../architecture/plugin-anatomy.md) for the structural reference, and [architecture/design-philosophy.md](../architecture/design-philosophy.md) for the principles your plugin should follow.

---

## Before You Start

### Prerequisites

- Claude Code installed and configured
- At least one existing plugin installed so you can see how skills activate in practice
- A clear idea of what your plugin will do that no existing plugin already does

Run `/cogni-help workflow` if you want a guided tour of the ecosystem before starting.

### Design Decisions to Make First

**What does your plugin own?** Every plugin owns a specific data domain. Before writing a single file, decide what entities your plugin creates and where they live on disk. If your plugin produces files that other plugins might consume, define the schema now.

**Who is upstream and who is downstream?** Does your plugin depend on output from an existing plugin? Does it produce output that another plugin consumes? Map these dependencies so you can write the right frontmatter contracts and bridge files from the start.

**Does this need to be a plugin, or a skill in an existing plugin?** If your capability fits naturally inside an existing plugin's domain, contributing a skill there is simpler than a standalone plugin. New plugins make sense when the domain is genuinely separate and the plugin needs its own data directory structure.

**What tools does your skill need?** Skills only have access to the tools listed in `allowed-tools`. Decide before writing the skill body so you don't paint yourself into a corner. If your skill spawns agents, add `Agent` to the list. If it needs web access, add `WebSearch` and `WebFetch`.

---

## Scaffold the Plugin

### Create the Directory Structure

```bash
mkdir -p my-plugin/.claude-plugin
mkdir -p my-plugin/skills/my-first-skill
mkdir -p my-plugin/agents
mkdir -p my-plugin/scripts
mkdir -p my-plugin/references
```

Add `hooks/`, `commands/`, `templates/`, and `libraries/` only if you need them.

### Write `plugin.json`

Create `my-plugin/.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "One or two sentences describing what the plugin does.",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "license": "Apache-2.0",
  "keywords": [
    "relevant-keyword",
    "domain-term"
  ]
}
```

Use semantic versioning. Start at `0.1.0`. The `description` field appears in marketplace listings — describe the function, not the value.

### Create a `CLAUDE.md`

Write a developer reference document at `my-plugin/CLAUDE.md`. This is the first file a developer reads when working on your plugin. Include:

- A one-paragraph identity statement (what the plugin is and does)
- The directory structure with inline comments
- The data model (entity types, storage format, schema overview)
- Cross-plugin integration points
- Key conventions (naming rules, script output format, any invariants that hooks enforce)

Model it on cogni-portfolio's or cogni-knowledge's CLAUDE.md — both are thorough examples.

---

## Write Your First Skill

### SKILL.md Structure

Create `my-plugin/skills/my-first-skill/SKILL.md`. A skill file has two parts: YAML frontmatter and a Markdown body.

```yaml
---
name: my-first-skill
description: |
  One paragraph describing what the skill does.
  Then a list of trigger phrases covering how users actually ask for this:
  Use when the user asks to "do the thing", "run X", "help with Y",
  or mentions "Z concept", "W workflow", "V problem".
  Also use when the user wants to "resume", "continue", "pick up where we left off"
  with this skill's workflow.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# My First Skill

When this skill loads:
1. If no context provided → ask: "What [specific input] should I work with?"
2. If context provided → [describe what to do with it]
```

**Writing the `description` field** is the most important part of the skill. Claude Code uses this field to decide when to activate your skill. The trigger phrases must cover the full range of ways a real user would ask for this capability — including natural language variants, domain synonyms, and (if relevant) other languages. Read an existing skill's description field to see the pattern in action.

**Writing the `allowed-tools` list** controls what the skill can do. Start minimal and add tools as you discover you need them:
- Always include `Read`, `Glob`, `Grep` for any skill that reads project state
- Add `Write`, `Edit` only if the skill creates or modifies files
- Add `Bash` only if the skill runs scripts
- Add `Agent` if the skill delegates to agents
- Add `WebSearch`, `WebFetch` if the skill does web research
- Add `AskUserQuestion` if the skill needs clarification before proceeding

**Writing the skill body** is writing a system prompt. The skill body is not seen by the user — it is the instructions the assistant follows. Be specific about phases, decision points, and output formats. Use numbered phases for multi-step workflows. Document what questions to ask and when. Describe what a good output looks like.

### Skill Naming

Check the naming convention before you choose a name:

| Tier | When | Pattern | Examples |
|------|------|---------|----------|
| A — Domain-unique | Your word is unambiguous in the ecosystem | bare name | `propositions`, `customers` |
| B — Generic verb/noun | The word could belong to multiple plugins | `{domain}-{verb}` | `portfolio-scan`, `trends-catalog` |
| C — Cross-plugin | The skill spans two domains explicitly | descriptive compound | `trends-bridge` |

Always `domain-verb`, never `verb-domain`. This groups your skills alphabetically in the skill list.

Words that always need a prefix: `setup`, `scan`, `ingest`, `export`, `dashboard`, `verify`, `bridge`, `catalog`, `reader`, `config`, `status`, `analyze`, `resume`.

---

## Add Agents

### When to Use an Agent

Add an agent when your skill needs to delegate a bounded, repeatable task to a separate context. Agents are appropriate when:

- The task requires a fresh context window (no accumulated state from the skill run)
- The task runs in parallel with other identical tasks (N researchers, N reviewers)
- The task has a specific input/output contract that the skill orchestrates
- The task is expensive enough that you want a dedicated model selection (e.g., haiku for cost-sensitive work)

Do not create an agent for every sub-step. If the logic is sequential and the context is shared, keep it in the skill body.

### Agent Frontmatter

Create `my-plugin/agents/my-agent.md`:

```yaml
---
name: my-agent
description: |
  One sentence describing what the agent does and when to use it.

  <example>
  Context: The skill has identified a set of items to process.
  user: "Process these items"
  assistant: "I'll launch my-agent instances in parallel for each item."
  <commentary>
  One agent instance per item. Results are compact JSON to preserve orchestrator context.
  </commentary>
  </example>

model: sonnet
color: cyan
tools: ["Read", "Write", "Bash"]
---

# My Agent

## Role

You [single sentence role statement].

## Input

[Describe what the agent receives — file paths, JSON payloads, configuration flags]

## Output

[Describe what the agent produces — files written, JSON returned, status signals]
```

**`model` selection:**
- `sonnet` — default for research, synthesis, and generation tasks
- `haiku` — quality assessment, web research at scale, any task running in high-volume parallel
- `inherit` — use the caller's model; appropriate when the agent is a thin delegation wrapper

**`color`** conventions across the ecosystem:
- `cyan` — research and data-gathering agents
- `green` — generation and verification agents
- `yellow` — review and assessment agents

Include at least one `<example>` block in the description. The example teaches the orchestrating skill when this agent is the right choice and what to pass it.

### Model Strategy Table

Document your model choices in CLAUDE.md:

```
| Tier | Model | Used by |
|------|-------|---------|
| Generation | sonnet | my-generator, my-writer |
| Assessment | haiku | my-quality-assessor, my-reviewer |
```

---

## Document Your Plugin

### README Structure

The README is what a user reads before installing the plugin. Follow the IS/DOES/MEANS structure that cogni-portfolio uses for propositions — it maps cleanly to a plugin README:

- **IS** — what the plugin is (one sentence, factual anchor)
- **DOES** — what the user can do with it (workflow steps, skill list)
- **MEANS** — what changes for the user as a result

Avoid marketing language in the README. Describe the workflow concretely: "Run `/research-report` to start a research session. The skill asks for a topic and report type, then runs parallel web research agents." That is more useful than "Unlock the power of multi-agent research."

### cogni-docs Integration

Once your plugin is working, register it with cogni-docs so it appears in the docs pipeline. Run `/doc-hub` and follow the prompts to generate a plugin guide, or write the guide manually at `docs/plugin-guide/{plugin-name}.md` following the structure of existing guides.

---

## Test and Iterate

### Eval Patterns

cogni-portfolio uses a dedicated eval directory (`cogni-portfolio-evals/`) with test scenarios for key skills. cogni-knowledge has a `tests/` directory with contract tests for its pipeline scripts and skills.

For your plugin, create test scenarios that cover:

1. **Happy path** — the primary workflow with typical inputs
2. **Resume** — an interrupted workflow that picks up correctly from saved state
3. **Edge cases** — missing inputs, malformed data, empty entity sets
4. **Cross-plugin integration** — if your plugin consumes another plugin's output, test with real output from that plugin

Test by running your skill in a real Claude Code session with the test inputs. Observe where the skill makes incorrect assumptions or produces unexpected output.

### Hook Validation

If your plugin uses hooks, test the hooks explicitly:

- For `PreToolUse` hooks: trigger the blocked action and confirm the hook intercepts it
- For `PostToolUse` hooks: trigger the guarded action past the limit and confirm the signal fires
- Confirm `CLAUDE_PLUGIN_ROOT` resolves correctly in hook scripts

### Script Conventions

All scripts must:
- Use only stdlib — no `pip install`, no `npm install`
- Return JSON: `{"success": bool, "data": {...}, "error": "string"}`
- Exit 0 on success, non-zero on error
- Complete within 30 seconds for interactive-use scripts

Run scripts manually from the command line to verify behavior before hooking them into a skill workflow.

---

## Submit to Marketplace

### Before Submitting

Your plugin must satisfy the quality standards in [MARKETPLACE_TERMS.md](https://github.com/cogni-work/insight-wave/blob/main/MARKETPLACE_TERMS.md):

- Apache-2.0 `LICENSE` file present
- `README.md` with installation and usage instructions
- `plugin.json` with accurate description and version
- At least one working skill with a tested trigger description
- No undeclared external dependencies

Run `cogni-workspace/scripts/check-skill-names.sh` to validate your skill names against the naming convention.

Run `scripts/check-breadcrumbs.py` to confirm your `SKILL.md` and agent files carry no maintainer breadcrumbs — issue/PR refs (`#NNN`), plugin-version tags, or milestone/slice/finding codes. The **Maintainer-breadcrumb guard** CI check (`.github/workflows/lint.yml`) enforces this on every PR. It ratchets against `scripts/baselines/breadcrumb-baseline.json`, so it fails only on *newly introduced* breadcrumbs; the fix is to remove the breadcrumb and state the rationale semantically, keeping provenance in git history, CHANGELOG, or `references/` rather than in the prompt the model executes. Use a per-line `breadcrumb-guard:allow` marker only for a genuine false positive (e.g. an Apple M-series chip name).

### Marketplace Entry

To list your plugin, submit a PR to the insight-wave repository that adds your plugin to `marketplace.json`. The entry format is:

```json
{
  "name": "my-plugin",
  "source": "./my-plugin",
  "version": "0.1.0",
  "description": "One sentence description matching plugin.json",
  "keywords": ["relevant-keyword"]
}
```

### PR Checklist

- [ ] `plugin.json` has accurate name, version, and description
- [ ] All skills have been tested against their trigger descriptions
- [ ] `CLAUDE.md` documents the architecture and conventions
- [ ] `CONTRIBUTING.md` is present (use the template at `community-plugin-contributing-template.md`)
- [ ] `LICENSE` file is present with Apache-2.0 text
- [ ] Skill names pass the naming convention check
- [ ] No external package dependencies in scripts

### Contribution Terms

You retain full copyright and all rights to your plugin. You are free to dual-license it, sell commercial licenses, and distribute it elsewhere. The marketplace listing requires Apache-2.0, not an assignment of rights.

For PRs to your own plugin from other contributors, set up your own contribution terms. See `community-plugin-contributing-template.md` for a starting template covering both simple inbound=outbound and CLA-based dual-licensing options.

---

## Related Documents

- [architecture/plugin-anatomy.md](../architecture/plugin-anatomy.md) — reference for every file type and naming convention
- [architecture/design-philosophy.md](../architecture/design-philosophy.md) — the principles behind the structure
- [architecture/er-diagram.md](../architecture/er-diagram.md) — cross-plugin entity relationships to understand integration points
