# Deeper Research Plugin Documentation

**Version:** 1.0.0
**Last Updated:** 2025-11-09
**Purpose:** Cross-cutting documentation for the deeper-research plugin

---

## Overview

This directory contains **plugin-wide documentation** that applies across all agents and skills in the deeper-research plugin. For skill-specific documentation, see the `references/` directory within each skill.

### What Belongs Here

✅ **Plugin-Wide Documentation:**
- Guides that apply to all agents and skills
- Cross-agent patterns and standards
- System architecture and workflows
- Data schemas used across multiple components

❌ **What Doesn't Belong Here:**
- Skill-specific operational guides → Use `skills/*/references/`
- Agent-specific implementation details → Document in agent files
- Sprint deliverables and historical reports → Deleted (not operational)

---

## Directory Structure

```
docs/
├── README.md           # This file - navigation guide
├── guides/             # User-facing operational guides
├── patterns/           # Cross-agent patterns and standards
├── schemas/            # Data schemas
└── architecture/       # System architecture documentation
```

---

## Documentation Index

### Guides

**[debugging-guide.md](guides/debugging-guide.md)**
- **Purpose:** Comprehensive guide to DEBUG_MODE and logging utilities
- **Audience:** Developers, troubleshooters
- **Size:** 1,780 lines
- **Contents:**
  - DEBUG_MODE configuration and usage
  - Enhanced logging utilities reference
  - Migration guide for agents
  - Log viewing and aggregation tools
  - Troubleshooting common issues
  - Best practices for production vs development
- **When to Use:** Setting up debugging, troubleshooting agent failures, analyzing performance

---

### Patterns

**[script-path-resolution.md](patterns/script-path-resolution.md)**
- **Purpose:** Standard pattern for resolving script and reference paths using CLAUDE_PLUGIN_ROOT
- **Audience:** Agent developers
- **Size:** 622 lines
- **Contents:**
  - Rationale for CLAUDE_PLUGIN_ROOT-based paths
  - Standard pattern templates (complete and minimal)
  - Usage patterns for scripts, references, and dynamic paths
  - Environment setup and validation
  - Error handling standards
  - Migration guide from hardcoded paths
  - Troubleshooting path resolution issues
- **When to Use:** Creating new agents, migrating agents, fixing path errors

**[entity-path-conventions.md](patterns/entity-path-conventions.md)**
- **Purpose:** Standardized entity path resolution across all agents
- **Audience:** Agent developers, maintainers
- **Size:** 928 lines
- **Contents:**
  - Three path formats (absolute, root-relative, wikilink)
  - Directory structure standards (flat vs nested)
  - Agent-specific guidelines (research-executor, fact-checker, etc.)
  - Common mistakes and anti-patterns
  - Validation checklist
  - Troubleshooting path issues
- **When to Use:** Creating entities, writing agents that reference entities, fixing path errors

---

### Schemas

**[entity-metadata-schema.md](schemas/entity-metadata-schema.md)**
- **Purpose:** Metadata schema definitions for all entity types
- **Audience:** Agent developers
- **Contents:**
  - Schema specifications for all entity types
  - Required vs optional fields
  - Validation rules
  - Examples and patterns
- **When to Use:** Creating entity files, validating metadata, understanding entity structure

---

### Architecture

**[workflow-target-state.md](architecture/workflow-target-state.md)**
- **Purpose:** Target workflow architecture and design
- **Audience:** Plugin maintainers, architects
- **Contents:**
  - System architecture overview
  - Workflow phases and transitions
  - Integration patterns
  - Design decisions and rationale
- **When to Use:** Understanding overall system design, planning architectural changes

**[phase-summary.md](architecture/phase-summary.md)**
- **Purpose:** Summary of workflow phases
- **Audience:** Developers, users
- **Contents:**
  - Phase-by-phase breakdown
  - Inputs, outputs, and responsibilities
  - Phase dependencies
- **When to Use:** Understanding workflow execution, debugging phase transitions

---

## How to Use This Documentation

### For New Agent Developers

**Start here:**
1. Read [patterns/script-path-resolution.md](patterns/script-path-resolution.md) - Learn path standards
2. Read [patterns/entity-path-conventions.md](patterns/entity-path-conventions.md) - Understand entity paths
3. Read [schemas/entity-metadata-schema.md](schemas/entity-metadata-schema.md) - Learn entity structure
4. Reference [guides/debugging-guide.md](guides/debugging-guide.md) - Set up debugging

### For Troubleshooting

**Common scenarios:**
- **Path errors:** Check [patterns/script-path-resolution.md](patterns/script-path-resolution.md) and [patterns/entity-path-conventions.md](patterns/entity-path-conventions.md)
- **Agent failures:** Use [guides/debugging-guide.md](guides/debugging-guide.md)
- **Metadata validation errors:** See [schemas/entity-metadata-schema.md](schemas/entity-metadata-schema.md)
- **Workflow understanding:** Read [architecture/phase-summary.md](architecture/phase-summary.md)

### For Plugin Maintenance

**When making changes:**
- Update relevant docs when changing patterns
- Add new patterns to `patterns/` if cross-cutting
- Keep skill-specific docs in `skills/*/references/`
- Document architectural changes in `architecture/`

---

## Relationship to Skill Documentation

**Plugin-Level (docs/) vs Skill-Level (skills/*/references/):**

| Scope | Location | Example |
|-------|----------|---------|
| **Cross-cutting patterns** | `docs/patterns/` | script-path-resolution, entity-path-conventions |
| **Plugin architecture** | `docs/architecture/` | workflow-target-state, phase-summary |
| **Development guides** | `docs/guides/` | debugging-guide |
| **Skill-specific workflows** | `skills/deeper-research-0/references/`, `skills/deeper-research-1/references/` | research-types, question-analysis |

**Rule of Thumb:**
- If it applies to **ALL agents across ALL skills** → `docs/`
- If it applies to **one skill only** → `skills/*/references/`
- If it's **operational** → Keep it
- If it's **historical** (sprint deliverables) → Delete it

---

## Contributing to Documentation

### Adding New Documentation

**Before adding to docs/:**
1. **Ask:** Does this apply to multiple skills/agents? If no → add to skill references
2. **Choose category:**
   - User-facing guides → `guides/`
   - Cross-agent patterns → `patterns/`
   - Data schemas → `schemas/`
   - Architecture → `architecture/`
3. **Update this README** with entry in appropriate section
4. **Cross-reference** from plugin README if relevant

### Updating Existing Documentation

1. Keep docs **accurate** - update when implementation changes
2. Include **version** and **last updated** date
3. Add **examples** for clarity
4. Link to **related docs** for navigation

### Documentation Standards

- **Format:** Markdown (.md)
- **Headings:** Use ATX-style (`#`, `##`, `###`)
- **Code blocks:** Specify language for syntax highlighting
- **Length:** No artificial limits - comprehensive is good
- **Audience:** State clearly at document start
- **Examples:** Include real examples from the codebase

---

## Quick Reference

### File Count by Category

- **Guides:** 1 file (debugging-guide.md)
- **Patterns:** 2 files (script-path-resolution.md, entity-path-conventions.md)
- **Schemas:** 1 file (entity-metadata-schema.md)
- **Architecture:** 2 files (workflow-target-state.md, phase-summary.md)
- **Total:** 6 operational documentation files

### Most Referenced Documents

1. **script-path-resolution.md** - Required reading for all agent developers
2. **entity-path-conventions.md** - Essential for entity manipulation
3. **debugging-guide.md** - First stop for troubleshooting

### Document Sizes

- **debugging-guide.md:** ~1,780 lines (comprehensive reference)
- **entity-path-conventions.md:** ~928 lines (detailed patterns)
- **script-path-resolution.md:** ~622 lines (complete guide)
- **Others:** Varies

---

## History

**2025-11-09:** Reorganized docs/ directory
- Created subdirectories: guides/, patterns/, schemas/, architecture/
- Moved 6 operational docs to organized structure
- Deleted 10 historical sprint deliverables
- Created this README for navigation

**Previous Structure:**
- Flat directory with 16 files
- Mixed operational and historical documentation
- No clear categorization

---

## Support

**For questions about documentation:**
- Check this README first
- Search for keywords in relevant category
- Review cross-references in files
- Consult plugin README for high-level overview

**For reporting documentation issues:**
- Missing content
- Inaccurate information
- Broken links
- Unclear explanations

**Maintainer:** deeper-research plugin team
**Plugin:** cogni-research
**Repository:** cogni-research
