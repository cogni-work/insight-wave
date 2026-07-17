---
name: projects-entities
description: |
  This skill should be used when the user wants to author or register a
  consultant, project, or assignment record in a cogni-projects portfolio —
  the entities the staffing engine scores over. Trigger on: "add a consultant",
  "add a project", "create an assignment", "author a projects entity", "register
  a consultant/project", "record a staffing assignment", "populate the projects
  portfolio", or any request to write consultant/project/assignment data into a
  cogni-projects portfolio — even if the user does not name the entity type.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Projects Entities

Author one consultant, project, or assignment record into a cogni-projects
portfolio and register it in the portfolio manifest. This is the data-entry
foundation the staffing-match engine, backfilling recommender, and
partner-meeting dashboard all read from — every entity you write here is a row
those later skills reason over.

Entities are Obsidian-browsable markdown files with YAML frontmatter. The full
field contract lives in [`references/data-model.md`](../../references/data-model.md);
read it before authoring so the frontmatter matches what `validate-entities.py`
enforces.

## Core concept

Each entity is one markdown file under its type's subdirectory of a portfolio:

- **consultant** → `consultants/<slug>.md`
- **project** → `projects/<slug>.md`
- **assignment** → `assignments/<consultant>--<project>.md`

Authoring an entity does three things atomically: write the file, register a
compact summary ref into the matching `projects-portfolio.json` array, and
append a transition to `.metadata/execution-log.json`. Registration is
**idempotent** — re-authoring the same slug updates the file and de-duplicates
the manifest ref rather than appending a second one, so a resumed or repeated run
never double-registers.

## Workflow

### Step 1: Locate the target portfolio

Find the portfolio directory the user means. If they name a slug, use
`cogni-projects/<slug>/`. Otherwise glob `cogni-projects/*/projects-portfolio.json`
and, when more than one portfolio exists, ask which one. If none exists, tell the
user to run `/cogni-projects:projects-setup` first — this skill authors into an
initialized portfolio, it does not scaffold one.

### Step 2: Determine the entity type and gather fields

Decide whether the user is authoring a **consultant**, **project**, or
**assignment**, then gather the required fields for that type from
`references/data-model.md` (ask only for what is missing):

- **consultant** — `name`, `seniority`, `skills`; optionally grade, location,
  availability window, allocation.
- **project** — `name`, `client`, `strategic_impact` (1–5); optionally open
  roles, timeline, status.
- **assignment** — the `consultant` and `project` slugs, `role`, `start_date`,
  `end_date`; optionally allocation, status. The slug is composite:
  `<consultant-slug>--<project-slug>`.

Derive the slug from the name (kebab-case) unless the user supplies one. For an
assignment, confirm both referenced entities already exist under `consultants/`
and `projects/` — read them first (this is also how you avoid a dangling
reference).

### Step 3: Read siblings, then write the entity file

Read the existing entities in the target subdirectory so the new record is
consistent with them (naming, skill vocabulary, role labels). Then write the
single entity file with its YAML frontmatter per the data model. Write **only**
the one entity file — never a summary, index, or batch file.

### Step 4: Validate before registering

Run the validator against the new file and gate registration on its success:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/validate-entities.py" "cogni-projects/<slug>/<subdir>/<entity>.md"
```

The validator returns `{"success": bool, "data": {"errors": [...], "warnings":
[...]}, "error": str}`. If `success` is `false`, fix each `data.errors[]` entry
(they name the offending `field` and `message`) and re-run — do **not** register
a malformed entity into the manifest.

### Step 5: Register in the manifest and log the transition

Once validation passes, update `projects-portfolio.json`:

1. Append a summary ref to the matching array (`consultants[]`, `projects[]`, or
   `assignments[]`) — the compact `{slug, name/…, file}` shape in the data
   model's "Manifest registration" section. **Dedupe by `slug`**: if an entry
   with the same slug exists, replace it in place instead of appending.
2. Bump the manifest `updated` field to today's date.

Then append a transition to `.metadata/execution-log.json` (`transitions[]`)
recording the entity slug, type, and action (`created` / `updated`) so the audit
trail stays complete.

### Step 6: Summarize

Report the file written, the manifest array it was registered in, and the
validation result. Keep it short. Point to the next entity or, once consultants
and projects exist, to the staffing-match engine as it ships.

## Notes

- **Scripts return `{success, data, error}` JSON**, stdlib-only — the validator
  follows the plugin convention; do not add pip dependencies.
- **The manifest is the source of truth** for what exists in the portfolio;
  entity files hold full field values. Keep them consistent — every authored
  file has exactly one manifest ref.
- **One entity per invocation** keeps each write reviewable and the execution log
  legible. To author several, run the skill once per entity.
