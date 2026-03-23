---
name: cogni-issues
description: |
  File and track GitHub issues (bugs, feature requests, change requests, questions) against
  insight-wave ecosystem plugins using the GitHub MCP connector in Cowork. Guides users
  through a short consultation to capture the right details, resolves the target plugin's
  repository automatically, drafts issues from templates, creates them via GitHub MCP tools,
  and tracks them locally.
  Use this skill whenever the user wants to report a bug, request a feature, file a change
  request, ask a question about a plugin, list filed issues, or check issue status.
  Also trigger when the user says things like "this plugin is broken", "I found a problem
  with {plugin}", "can we get X added to {plugin}", "{plugin} doesn't work", "open an issue",
  "something is wrong with {plugin}", "das Plugin funktioniert nicht", "Fehler in {plugin}",
  "set up GitHub issues", "configure issue filing", "ich kann kein Issue erstellen",
  or any complaint/suggestion about a specific plugin — even if they don't use the word "issue".
---

# Cogni Issues

Manage the lifecycle of GitHub issues for insight-wave ecosystem plugins: consult with the
user to understand the problem clearly, resolve which repository the plugin belongs to,
draft issues from templates, create them via GitHub MCP tools, and track them locally.

All GitHub operations go through the **GitHub connector** — the built-in Cowork integration
that provides `mcp__github__*` tools. Never shell out to the `gh` CLI for issue operations.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`) as the default interaction language. If the
user's message is in a different language, prefer the user's language (message
detection overrides the workspace setting — someone writing in German wants a
German response even if the workspace is set to English).

If `.workspace-config.json` is missing, fall back to detecting the user's language
from their message. If still unclear, default to English.

Conduct the entire interaction in the chosen language — consultation questions,
acknowledgments, draft body, and confirmation prompts.

Exceptions where English stays:
- **Title prefixes**: `[Bug]`, `[Feature]`, `[Change]`, `[Question]` — conventions for
  GitHub label automation and cross-team readability.
- **Technical terms**: plugin names, CLI commands, error messages, stack traces.

## Environment

The skill scripts live at `${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/`.
`CLAUDE_PLUGIN_ROOT` points to the cogni-help plugin directory. If you can't
find the scripts, tell the user — don't guess paths.

## GitHub MCP Tools

All GitHub operations use MCP tools from the built-in GitHub connector. The key tools:

| Operation | MCP Tool | Purpose |
|-----------|----------|---------|
| Create issue | `mcp__github__create_issue` | Create a new issue on a repository |
| List issues | `mcp__github__list_issues` | List issues for a repository |
| Get issue | `mcp__github__get_issue` | Get details of a specific issue |
| Search issues | `mcp__github__search_issues` | Search across issues |

Before using any MCP tool, load it via `ToolSearch` first (e.g., `select:mcp__github__create_issue`).

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **setup** | First-time detection (MCP tools not available), "set up issues", "ich kann kein Issue erstellen" | Guide user to enable GitHub connector |
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub via MCP, update local record |
| **browse** | "open issue", "show in browser" | Provide the GitHub issue URL |

Default to **list** when intent is unclear.

## Prerequisites

Before any GitHub MCP operation, verify the connector is enabled:

1. Use `ToolSearch` to look for `mcp__github__create_issue`
2. If the tool is found, the GitHub connector is active — proceed
3. If the tool is not found, switch to **setup mode**

## Setup mode

The GitHub connector is a built-in Cowork integration — no CLI tools, tokens, or
Docker containers to install. The user just needs to toggle it on.

### 1. Check connector status

Use `ToolSearch` with query `mcp__github__create_issue`. If it returns a tool
definition, the connector is already enabled — tell the user they're all set and
offer to file an issue.

### 2. If the connector is not enabled

Walk the user through enabling it in the Cowork UI, in their language:

**English:**
> To file GitHub issues, you need to enable the GitHub connector:
> 1. Click the **+** button in the lower left of the chat
> 2. Hover over **Connectors**
> 3. Find **GitHub** and toggle it **on**
> 4. Follow the OAuth prompt to authorize access to your GitHub account
>
> Once that's done, tell me and I'll verify the connection.

**German:**
> Um GitHub Issues erstellen zu können, musst du den GitHub Connector aktivieren:
> 1. Klicke auf das **+** unten links im Chat
> 2. Fahre mit der Maus über **Connectors**
> 3. Finde **GitHub** und schalte es **ein**
> 4. Folge der OAuth-Aufforderung, um den Zugriff auf dein GitHub-Konto zu autorisieren
>
> Sag mir Bescheid, wenn du fertig bist — ich prüfe dann die Verbindung.

### 3. After the user confirms

Re-check with `ToolSearch`. If the tools are now available, confirm success. If
still missing, suggest the user refresh Cowork or check if OAuth completed
successfully.

### 4. Setup complete

If the user came here because they were trying to file an issue, continue with
the **create** flow.

## Workspace init

Run once before any operation (idempotent):

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in `{working_dir}/cogni-issues/`.

## Create mode

### 1. Check readiness and resolve the plugin

First, verify GitHub MCP tools are available (see Prerequisites). If not, enter
**setup mode** and return here once the connector is enabled.

If the user hasn't named a specific plugin, ask which plugin this is about. Then resolve it:

```bash
bash "${SKILL_DIR}/scripts/resolve-plugin.sh" "<plugin_name>"
```

Handle: `"ambiguous": true` → present matches and ask; `"error"` → list available plugins
and ask; success → extract `owner_repo`, `version`, `marketplace`.

### 2. Check for duplicates

Before investing in consultation and drafting, search for existing issues using MCP:

Use `mcp__github__search_issues` with a query like `repo:<owner_repo> is:open <keywords>`
using 2-3 keywords from the user's complaint. If you find a likely match, show it to the
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

### 7. Create on GitHub via MCP

Use the `mcp__github__create_issue` tool with the owner, repo, title, body, and labels.

Label mapping is in `references/issue-templates.md`. If creation fails due to a
non-existent label, retry without labels and mention this to the user.

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

Parse `github_number` and `github_url` from the MCP tool response.

### 9. Confirm

Return the GitHub issue URL and local issue ID.

## List mode

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin: title, type badge, GitHub number + URL, status, date.
If empty, suggest the create flow.

## Status mode

1. Look up the issue in local state to get `owner`, `repo`, and `github_number`
2. Fetch from GitHub using `mcp__github__get_issue` with the owner, repo, and issue number
3. Update local record via `update-status`
4. Show: state, latest comments summary, labels, last update

## Browse mode

Provide the GitHub issue URL from local state. The URL follows the pattern:
`https://github.com/<owner>/<repo>/issues/<number>`

## Scripts

- **`scripts/setup-gh.sh`** — Legacy check script. The primary readiness check is now done via `ToolSearch` for GitHub MCP tools. This script provides platform info only.
- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files. All insight-wave plugins resolve to the monorepo `insight-wave/insight-wave`.
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
