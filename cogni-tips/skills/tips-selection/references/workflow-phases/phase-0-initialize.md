# Phase 0: Initialize & Load Context

Load project context and validate prerequisites before generating candidates.

## Steps

### 1. Extract PROJECT_PATH

The user provides a question file path. Extract the project root:

```
question file: /path/to/project/00-initial-question/data/question-foo-abc123.md
project root:  /path/to/project/
```

Validate that `00-initial-question/` exists in the project structure.

### 2. Read Question Frontmatter

Read the question file and extract:

- `research_type` — must be `smarter-service`
- `industry_sector` — target industry for candidate generation
- `web_research` — optional, defaults to `true`
- `research_context` — fallback source for industry sector

### 3. Validate Research Type

This skill only supports `research_type: smarter-service`. If the project uses a different research type, stop and inform the user.

### 4. Determine Industry Sector

Priority order:
1. Explicit `industry_sector` field in frontmatter
2. Infer from `research_context` text (look for industry keywords)
3. Ask the user to provide it

The industry sector drives candidate generation — every trend candidate should be contextualized to this sector. Getting it right matters because generic candidates produce generic research.

### 5. Create Directories

Ensure these directories exist:
- `{PROJECT_PATH}/02-refined-questions/data/` — for trend-candidates.md
- `{PROJECT_PATH}/.metadata/` — for agreed-trend-candidates.json
- `{PROJECT_PATH}/.logs/` — for execution logging

### 6. Configure Web Research

Web research is enabled by default because it produces fresher, more grounded candidates. Check for `web_research: false` in frontmatter to disable.

### 7. Check for Existing Selection

If `trend-candidates.md` already exists:
- Status `agreed` → Nothing to do. Inform the user.
- Status `draft` → Skip to Phase 2 (present) or Phase 3 (finalize) depending on context.

If no existing file and web research enabled → proceed to Phase 0.5.
If no existing file and web research disabled → proceed to Phase 1.

## Variables to Carry Forward

| Variable | Purpose |
|----------|---------|
| PROJECT_PATH | Root path of the research project |
| INDUSTRY_SECTOR | Target industry for candidates |
| WEB_RESEARCH_ENABLED | Whether to run web searches (default: true) |

## Next Phase

- Web research enabled → [phase-0.5-web-research.md](phase-0.5-web-research.md)
- Web research disabled → [phase-1-generate.md](phase-1-generate.md)
- Existing agreed file → Stop (nothing to do)
