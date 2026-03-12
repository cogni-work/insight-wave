# Language Resolution

Shared language resolution pattern for all cogni-tips skills. Defines how skills detect and apply language settings for user interaction and deliverable output.

## Two Language Concepts

| Concept | Purpose | Source | Fallback |
|---------|---------|--------|----------|
| **Interaction language** | User-facing messages, prompts, status updates, questions | Workspace `.workspace-config.json` | `en` |
| **Output language** | Deliverable content (reports, candidates, value models) | Explicit user choice per project | Interaction language |

These are often the same but can differ — e.g., a German-speaking user may want an English report for an international audience.

## Interaction Language Resolution

Every skill MUST detect the interaction language at startup, before any user-facing output:

```text
INTERACTION_LANGUAGE =
  1. Workspace language from .workspace-config.json     (highest priority)
  2. "en"                                                (fallback)
```

### How to read workspace language

```bash
WORKSPACE_DIR="${PROJECT_AGENTS_OPS_ROOT:-$(pwd)}"
if [ -f "${WORKSPACE_DIR}/.workspace-config.json" ]; then
  INTERACTION_LANGUAGE=$(jq -r '.language // "en"' "${WORKSPACE_DIR}/.workspace-config.json")
else
  INTERACTION_LANGUAGE="en"
fi
```

### What it affects

- All AskUserQuestion prompts and option labels
- Status messages and progress updates
- Error messages and warnings
- Phase summaries and next-step recommendations
- Table headers and labels in status displays

### What it does NOT affect

- Technical terms, skill names, and CLI commands (always English)
- JSON field names and schema keys (always English)
- Log file content (always English)

## Output Language Resolution

When a skill produces deliverables (trend candidates, reports, value models), it asks the user for the output language. The interaction language (from workspace) serves as the **pre-selected default**:

```text
OUTPUT_LANGUAGE =
  1. Explicit user choice via AskUserQuestion           (highest priority)
  2. Project language from tips-project.json             (for downstream skills)
  3. Interaction language (= workspace language)         (default)
```

### How to ask

Present the question in the interaction language, with the default pre-selected:

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "In welcher Sprache sollen die Ergebnisse erstellt werden?"
  header: "Ausgabesprache"
  options:
    - label: "Deutsch (DE) ← Workspace-Standard"
    - label: "English (EN)"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "What language should the deliverables be written in?"
  header: "Output language"
  options:
    - label: "English (EN) ← Workspace default"
    - label: "Deutsch (DE)"
```

### When to ask

- **Project-creating skills** (trend-scout): Always ask — this sets `project_language` for all downstream skills
- **Downstream skills** (trend-report, value-modeler): Ask only if the user should be able to override the project language. Present the project language as default.
- **Status/navigation skills** (tips-resume, tips-dashboard): Do NOT ask — use the project language if available, otherwise the interaction language

## i18n Message Catalogs

Load the appropriate message catalog based on the interaction language:

```text
messages-{INTERACTION_LANGUAGE}.md  → for user-facing messages
labels-{OUTPUT_LANGUAGE}.md         → for deliverable content labels
```

## Summary for Skill Authors

1. **First action**: Read workspace language → set `INTERACTION_LANGUAGE`
2. **All user communication**: Use `INTERACTION_LANGUAGE`
3. **When creating deliverables**: Ask user for output language, default to `INTERACTION_LANGUAGE`
4. **Store choice**: Write to `tips-project.json` as `language` field
5. **Downstream skills**: Read `tips-project.json` language as default, workspace language as fallback
