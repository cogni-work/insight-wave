# Script Reference — research-plan

Quick reference for scripts used during planning phases. All scripts live in `${CLAUDE_PLUGIN_ROOT}/scripts/`.

## initialize-research-project.sh

Creates the full project directory structure.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/initialize-research-project.sh \
  --project-name "my-research" \
  --research-type generic \
  --language en
```

**Creates:**
- 7 entity directories: `00-initial-question/` through `06-claims/`, each with `data/` subdirectory
- `.metadata/` with:
  - `project-config.json` — project name, research type, language
  - `entity-index.json` — entity registry (keyed by entity type, not array)
  - `sprint-log.json` — phase state tracking

**Workspace resolution order:** `COGNI_RESEARCH_ROOT` > `CLAUDE_PROJECT_DIR` > `~/research-projects`

**Output format:**
```json
{"success": true, "data": {"project_path": "/path/to/project", "research_type": "generic"}, "error": ""}
```

## create-entity.sh

Creates a single entity file with YAML frontmatter. Delegates to `create-entity.py`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh \
  --entity-type 00-initial-question \
  --project-path /path/to/project \
  --slug "my-research-question" \
  --frontmatter '{"research_type":"generic","dok_level":3,"language":"en","research_question":"..."}'
```

**Initial question frontmatter fields:**
- `research_type` — generic | lean-canvas | b2b-ict-portfolio
- `dok_level` — 1-4 (integer)
- `language` — en | de
- `research_question` — the refined question text

Entity files are `.md` with YAML frontmatter, designed to be Obsidian-browsable. Never create entities via Write/Edit — hooks will block this.

## scan-resumption-state.sh

Checks filesystem to determine whether a previous run was interrupted.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh \
  --phase planning \
  --project-path /path/to/project
```

**Returns JSON with recommendation:**
- `FULL_RUN` — no prior progress, start from Phase 0
- `RESUME` — some phases completed, skip them
- `COMPLETE` — planning already finished, proceed to findings-sources

## sprint-log.json Fields

Located at `.metadata/sprint-log.json` in the project directory.

| Field | Type | Set By |
|-------|------|--------|
| `research_type` | string | Phase 0 (init script) |
| `language` | string | Phase 0 (init script) |
| `planning_complete` | boolean | Phase 3 (batch creation) |
| `created_at` | ISO 8601 | Phase 0 (init script) |
| `updated_at` | ISO 8601 | Each phase update |

`planning_complete: true` is the signal that findings-sources can begin.
