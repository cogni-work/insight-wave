# Deeper-Research Agent Development

Templates and guidelines for creating and modifying deeper-research agents.

## Purpose

This directory contains development resources for building and maintaining the specialized agents used by the deeper-research skill. These are **not** loaded during skill execution but are preserved for future agent development and modifications.

## Available Templates

### [agent-prompt-template.md](agent-prompt-template.md)

Complete agent prompt template with all phases, patterns, and best practices for creating deeper-research agents.

**Size:** ~60KB
**Use When:** Creating new agents or significantly refactoring existing ones
**Audience:** Plugin developers and maintainers

**Template Sections:**
- System prompt structure
- Context efficiency patterns
- Delegation patterns
- JSON response formatting
- Error handling
- Progressive disclosure patterns
- Anti-hallucination safeguards

## When to Use These Resources

**Creating New Agents:**
1. Start with agent-prompt-template.md
2. Customize for specific phase/task
3. Follow established patterns for consistency

**Modifying Existing Agents:**
1. Reference template for best practices
2. Maintain consistency with other agents
3. Preserve JSON response contracts

**Not Needed For:**
- Skill execution (orchestration only)
- End-user research workflows
- Agent invocation (handled by Task tool)

## Related Documentation

- Skill execution (Part 0): See [skills/deeper-research-0/SKILL.md](../../skills/deeper-research-0/SKILL.md)
- Skill execution (Part 1): See [skills/deeper-research-1/SKILL.md](../../skills/deeper-research-1/SKILL.md)
- Skill execution (Part 2): See [skills/deeper-synthesis/SKILL.md](../../skills/deeper-synthesis/SKILL.md)
- Agent invocation patterns: See [skills/deeper-synthesis/references/agent-invocation-patterns.md](../../skills/deeper-synthesis/references/agent-invocation-patterns.md)
- Validation protocols: See [skills/deeper-research-0/references/validation-protocols.md](../../skills/deeper-research-0/references/validation-protocols.md)
