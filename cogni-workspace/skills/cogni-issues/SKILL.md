---
name: cogni-issues
description: |
  File and track GitHub issues (bugs, feature requests, change requests, questions) against
  cogni-works ecosystem plugins. Guides users through a short consultation to capture the
  right details, resolves the target plugin's repository automatically, drafts issues from
  templates, creates them via `gh` CLI, and tracks them locally.
  Use this skill whenever the user wants to report a bug, request a feature, file a change
  request, ask a question about a plugin, list filed issues, or check issue status.
  Also trigger when the user says things like "this plugin is broken", "I found a problem
  with {plugin}", "can we get X added to {plugin}", "{plugin} doesn't work", "open an issue",
  "something is wrong with {plugin}", "das Plugin funktioniert nicht", "Fehler in {plugin}",
  or any complaint/suggestion about a specific plugin — even if they don't use the word "issue".
---

# Cogni Issues

Manage the lifecycle of GitHub issues for cogni-works ecosystem plugins: consult with the
user to understand the problem clearly, resolve which repository the plugin belongs to,
draft issues from templates, create them via `gh`, and track them locally.

## Language

Detect the user's language from their message and conduct the entire interaction in that
language — consultation questions, acknowledgments, draft body, and confirmation prompts.

Exceptions where English stays:
- **Title prefixes**: `[Bug]`, `[Feature]`, `[Change]`, `[Question]` — conventions for
  GitHub label automation and cross-team readability.
- **Technical terms**: plugin names, CLI commands, error messages, stack traces.

## Environment

The skill scripts live at `${COGNI_WORKSPACE_PLUGIN}/skills/cogni-issues/scripts/`.
If `COGNI_WORKSPACE_PLUGIN` is not set, fall back to the workspace root's plugin path
(typically the directory containing `.claude-plugin/plugin.json`). If you still can't
find the scripts, tell the user — don't guess paths.

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub, update local record |
| **browse** | "open issue", "show in browser" | Open via `gh issue view --web` |

Default to **list** when intent is unclear.

## Prerequisites

Before any `gh` operation, verify auth:

```bash
gh auth status 2>&1
```

If this fails, guide the user to install (`brew install gh`) and authenticate (`gh auth login`).
Do not attempt issue creation without valid auth — fail fast.

## Workspace init

Run once before any operation (idempotent):

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in `{working_dir}/cogni-issues/`.

## Create mode

### 1. Resolve the plugin

If the user hasn't named a specific plugin, ask which plugin this is about. Then resolve it:

```bash
bash "${SKILL_DIR}/scripts/resolve-plugin.sh" "<plugin_name>"
```

Handle: `"ambiguous": true` → present matches and ask; `"error"` → list available plugins
and ask; success → extract `owner_repo`, `version`, `marketplace`.

### 2. Check for duplicates

Before investing in consultation and drafting, do a quick search for existing issues:

```bash
gh issue list --repo "<owner_repo>" --state open --search "<keywords>" --limit 5
```

Use 2-3 keywords from the user's complaint. If you find a likely match, show it to the
user and ask: "This looks similar — is it the same problem, or something different?" If
it's the same, link them to the existing issue instead of creating a duplicate.

### 3. Determine the issue type

Infer the type from context (match intent across languages, not specific keywords):

| Type | Signals |
|------|---------|
| `bug` | something is broken, errors, crashes, doesn't work, fails, wrong output |
| `feature` | add something new, would be nice, request, support for |
| `change-request` | change existing behavior, modify, adjust, different behavior wanted |
| `question` | how to, why does, confused, wondering |

If genuinely ambiguous, ask. Otherwise trust your judgment.

### 4. Consult the user

Help the user articulate what they need. Many users know something is wrong but haven't
organized their thoughts. Your job is to be a helpful interviewer, not a form.

**First, mine the conversation for existing evidence.** Check recent tool outputs for
error messages, stack traces, or failed commands. Look at what the user was working on —
the conversation often contains the exact workflow that triggered the problem. If you see
a traceback from earlier, use it — don't ask "did you see an error?"

**Then ask only what's missing** — 2-3 questions max, batched in one turn:

- **Bug:** What were you doing? What happened? Reproducible or one-off?
- **Feature:** What problem does this solve? How should it work? Current workaround?
- **Change request:** What does it do now vs what should it do? Why doesn't current behavior work?
- **Question:** What are you trying to accomplish? What have you tried?

**Skip consultation entirely** if the user (or conversation context) already provides
enough detail. Acknowledge it: "You've given me a clear picture — let me draft this up."

### 5. Draft the issue

Read the template from `references/issue-templates.md` for the determined type.

Fill in from conversation + resolver output. Omit sections you can't fill meaningfully —
shorter with real content beats complete with placeholders.

**Auto-detect environment:**

```bash
uname -s && uname -r && node -v 2>/dev/null
```

**Write in the user's language** (except title prefixes and technical terms).

**Transform vague input into precise descriptions.** This is the core value you add:

| User says | You write |
|-----------|-----------|
| "it doesn't work" | "The skill exits with a non-zero status code without producing output when invoked with default arguments" |
| "it's slow" | "Rendering takes 45+ seconds for a 3-station brief, compared to ~15s previously — a 3x regression" |
| "the output looks wrong" | "Generated propositions show placeholder text ('Lorem ipsum') instead of configured descriptions" |
| "es funktioniert nicht mehr" | "Das Skill bricht beim Aufruf mit einem TypeError ab und erzeugt keine Ausgabe" |

The pattern: replace subjective impressions with observable facts, measurable quantities,
or specific error details.

**Add a root cause hypothesis when you can.** If the error or context suggests a likely
cause, include it in "Additional context" — e.g., "The TypeError on `narrative_arc`
suggests a property was renamed or removed in the latest update, possibly a breaking
change in the data model." This helps maintainers triage faster. Only do this when the
evidence supports it — don't speculate wildly.

### 6. Confirm with the user

Show the complete draft (title + body) and ask for approval in the user's language.
Never create without explicit confirmation. If the user wants changes, apply them and
show the updated draft.

### 7. Create on GitHub

```bash
gh issue create --repo "<owner_repo>" --title "<title>" --body "<body>" --label "<label>"
```

Label mapping is in `references/issue-templates.md`. If the label doesn't exist on
the repo, retry without `--label` and mention this to the user.

If creation fails, show the error and suggest next steps — don't retry blindly.

### 8. Log locally

```bash
ID_JSON=$(bash "${SKILL_DIR}/scripts/issue-store.sh" gen-id)
```

Then pipe the issue record as JSON via stdin:

```bash
echo '<json_record>' | bash "${SKILL_DIR}/scripts/issue-store.sh" add "${working_dir}"
```

The record includes: `id`, `plugin`, `marketplace`, `repository`, `github_number`,
`github_url`, `type`, `title`, `status` ("open"), `created_at`, `updated_at`.

Parse `github_number` and `github_url` from `gh issue create` output.

### 9. Confirm

Return the GitHub issue URL and local issue ID.

## List mode

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin: title, type badge, GitHub number + URL, status, date.
If empty, suggest the create flow.

## Status mode

1. Look up the issue in local state to get `owner_repo` and `github_number`
2. Fetch from GitHub:
   ```bash
   gh issue view <number> --repo "<owner_repo>" --json state,title,labels,comments,updatedAt
   ```
3. Update local record via `update-status`
4. Show: state, latest comments summary, labels, last update

## Browse mode

```bash
gh issue view <number> --repo "<owner_repo>" --web
```

## Scripts

- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
