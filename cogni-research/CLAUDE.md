# CogniWork Research - Development Guide

## Project Identity

Claude Code marketplace plugin implementing a **12-phase research pipeline** that transforms questions into traceable, source-backed syntheses with anti-hallucination controls and Obsidian wikilink integration.

- **Version**: 0.9.80
- **License**: AGPL-3.0-only
- **Plugin root**: `$CLAUDE_PLUGIN_ROOT` (points directly to plugin directory)

## Architecture

### Skills vs Agents

- **Skills** (22) are user-facing entry points invoked by name (e.g., `deeper-research-0`)
- **Agents** (16) are internal sub-processors orchestrated by skills - never invoke directly
- **Contracts** (102) are YAML specs defining script interfaces
- **Hooks** (8) provide pre/post validation for entity operations

### Main Pipeline Skills

| Skill | Phases | Purpose |
|-------|--------|---------|
| `deeper-research-0` | 0-2.5 | Planning: init, question refinement, dimension planning, batch creation |
| `deeper-research-1` | 3 | Discovery: parallel web search and findings extraction |
| `deeper-research-2` | 4-7 | Enrichment: sources, knowledge extraction, citations, claims |
| `deeper-research-3` | 8-10, 12-13 | Synthesis: trends, evidence catalog, report generation |

### Entity Types (13)

```
00-initial-question    01-research-dimensions    02-refined-questions
03-query-batches       04-findings               05-domain-concepts
06-megatrends          07-sources                08-publishers
09-citations           10-claims                 11-trends
12-synthesis
```

Entities are created via `scripts/create-entity.py` (never Write/Edit directly to entity dirs).

### Wikilink Format

Always use workspace-relative paths: `[[dir/data/entity-id]]`
Never use bare filenames: `[[entity-id]]` (rejected by hooks)

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `CLAUDE_PLUGIN_ROOT` | Yes (auto) | Plugin root directory |
| `COGNI_RESEARCH_ROOT` | No | Research workspace root |
| `OBSIDIAN_VAULT_ROOT` | No | Multi-project Obsidian vault root |
| `DEBUG_MODE` | No | Enable verbose logging |

## Development

### Script Patterns

- Shell scripts in `scripts/` use `set -euo pipefail`
- Python scripts use bundled `shared_utils/` (no external dependencies)
- Entity config loaded from `config/entity-schema.json`
- All entity operations go through `create-entity.py` for validation, locking, and indexing

### Testing

```bash
bash tests/source-creator/test-domain-extraction.sh
bash tests/wikilinks/test-repair-wikilinks.sh
```

### Anti-Hallucination Rules

- Never fabricate entity IDs - always read `.metadata/entity-index.json`
- Never invent source URLs - only use URLs from actual web search results
- Every claim must trace to a source via wikilinks
- Hooks auto-detect and block hallucinated entity references

## Dependencies

- **Required**: `bash`, `jq`, `python3` (stdlib only)
- **Optional**: `cogni-workplace` plugin (themes, shared infra) - graceful fallback if absent
