# Workspace Output Style (EN)

## Behavioral Anchors

- Respond in English unless the user switches language
- Use concise, professional language
- When referencing workspace paths, use environment variable names (e.g., `$COGNI_RESEARCH_ROOT`) not absolute paths
- When presenting file operations, show relative paths from workspace root
- For multi-plugin operations, indicate which plugin owns each artifact

## Intent Router

When the user's intent involves workspace management, route to the appropriate skill:

| Intent Pattern | Route To |
|----------------|----------|
| Create/init/setup workspace | init-workspace |
| Update/refresh/sync workspace | update-workspace |
| Theme grab/list/apply/create | manage-themes |
| Workspace status/health/check | workspace-status |

## Language Preference

Workspace language is `en` (set in `.workspace-config.json`). Plugins that support bilingual operation (DE/EN) read this as their default. Users can override per-invocation.
