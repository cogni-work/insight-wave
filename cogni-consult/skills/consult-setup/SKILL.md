---
name: consult-setup
description: |
  This skill should be used when the user wants to start a new cogni-consult engagement —
  the action-fields-WBS consulting plugin. Trigger on: "start a consult engagement",
  "new cogni-consult engagement", "set up a consult project", "begin an action-fields
  engagement", or any request to start structured consulting work explicitly aimed at
  cogni-consult rather than cogni-consulting (route Double Diamond phrasing like
  "diamond engagement" to cogni-consulting:consulting-setup instead). Scaffolds the
  engagement directory, binds one cogni-knowledge base, and registers it globally.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill
---

# Engagement Setup

Initialize a cogni-consult engagement: frame the desired outcome with the consultant, scaffold the action-fields-WBS directory structure, bind the one cogni-knowledge base the whole engagement compounds research into, and register the engagement for cross-session discovery. This is the entry point — without it, no later skill has a project to write to.

Setup deliberately stays light: it captures the outcome and the research spine, nothing more. The SMART key question, the five scoping dimensions, and the 3-6 action fields are `consult-scope`'s job; personas ship with `consult-personas`; deliverables emerge inside action fields. If an engagement already exists for this client/topic, do not create a duplicate — dispatch `Skill("cogni-consult:consult-resume")` to re-enter it.

## Workflow

### 1. Gather Engagement Context

Collect these fields, extracting whatever the user already provided and asking only for what is missing:

- **Engagement name**: Descriptive name (e.g., "ACME DACH Cloud Expansion")
- **Client**: Company or organization name
- **Desired outcome**: One sentence describing what success looks like
- **Market**: One of `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu` — collected explicitly, never derived from language (the mapping is ambiguous, e.g. `de` could mean `dach` or `de`)
- **Language**: ISO 639-1 communication language (default `en`; check a `.workspace-config.json` `language` field in the workspace root first)

Derive the engagement slug from the name in kebab-case — short and recognizable.

### 2. Confirm With the Consultant

Present a summary table (engagement, client, desired outcome, market, language, proposed slug) and iterate until confirmed. The slug doubles as the knowledge-base slug in step 4, so flag that it becomes a directory name in two places.

### 3. Scaffold the Engagement

Run the init script from the workspace root:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-init.sh "<engagement-slug>" "<engagement-name>"
```

The script creates `cogni-consult/<slug>/{scope,action-fields,personas,.metadata}/`, writes the three `.metadata/` logs, and writes `consult-project.json` last (its existence is the idempotency key). On `"success": false` with `"engagement already initialized"`, stop and route to the existing engagement via `consult-resume` — never overwrite.

Then enrich `consult-project.json` with `Edit` — never rewrite the file (the `created`/`updated` timestamps the script set must survive):

- Set `language` to the confirmed value. Skip this edit when the confirmed language is `en` — the script default already matches, and an identical old/new `Edit` errors
- Leave `key_question`, `action_fields`, and `workflow_state.scope` untouched — those belong to `consult-scope`

### 4. Bind One cogni-knowledge Base

Every deliverable's research runs through a single knowledge base bound here, once, so evidence compounds across the whole engagement instead of fragmenting into throwaway reports.

Dispatch the setup non-interactively, passing everything it would otherwise prompt for:

```
Skill: cogni-knowledge:knowledge-setup
  --knowledge-slug <engagement-slug>
  --knowledge-title "<engagement name> knowledge base"
  --market <market>
  --output-language <language>
  --charter-domain "<desired outcome>"
  --charter-audience "consultant"
  --charter-scope "<client>, <market> market"
```

Prefer the charter flags over `--no-charter` — the gathered context gives the base a real charter instead of an empty one. Charter scope means in/out boundaries (geography, segment, horizon), so compose it from the client plus the confirmed market rather than passing a bare client name. After the dispatch succeeds, record the binding in `consult-project.json` via `Edit`:

```json
"plugin_refs": {
  "knowledge_base": "<engagement-slug>"
}
```

The value is the slug string, not a path. Later skills pass `--knowledge-slug <plugin_refs.knowledge_base>` to every `knowledge-plan`/`knowledge-query` run.

### 5. Register the Engagement Globally

Register the engagement so `consult-resume` finds it from any directory:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --register "<absolute-path-to-engagement-dir>"
```

The wrapper delegates to the cogni-workspace discovery helper with the cogni-consult registry (`$HOME/.claude/cogni-consult-projects.json`, auto-created on first use). Verify with `bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json`, which lists every known engagement with its scope state.

### 6. Recommend the Next Step

Close by confirming what exists (engagement directory, bound knowledge base, registry entry) and recommend `consult-scope` as the next step — the SMART key question and five scoping dimensions anchor the engagement before any action field is derived. When the user wants to continue immediately, dispatch `Skill("cogni-consult:consult-scope")` in the same session; otherwise stop here and report that the engagement is ready for scoping.

## Important Notes

- **State ownership**: `consult-project.json` holds only the `scope` workflow state. Deliverable state lives exclusively in each field's `field.json` — setup never touches it (no fields exist yet). See `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
- **One base per engagement**: never bind a second knowledge base; re-runs reuse `plugin_refs.knowledge_base`.
- **Communication language**: when `language` is set, communicate in that language; technical terms, skill names, and CLI commands stay English.
- **Evaluation boundary**: cogni-consulting engagements and cogni-consult engagements never share directories; the two plugins are compared, not mixed.
