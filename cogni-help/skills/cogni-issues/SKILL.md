---
name: cogni-issues
version: 0.4.0
description: |
  File and track GitHub issues (bugs, features, change requests, questions) against
  insight-wave plugins via the GitHub CLI (`gh`). Consults the user, resolves the
  plugin repository, drafts from templates, creates atomically with labels, and
  tracks locally.
  Use whenever the user wants to report a bug, request a feature, file a change
  request, ask a plugin question, list filed issues, or check issue status. Also
  trigger on "this plugin is broken", "open an issue", "set up GitHub issues",
  "das Plugin funktioniert nicht", "Fehler in {plugin}", "ich kann kein Issue
  erstellen", or any complaint about a specific plugin — even without the word
  "issue".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Cogni Issues

Manage the lifecycle of GitHub issues for insight-wave ecosystem plugins: consult with the
user to understand the problem clearly, resolve which repository the plugin belongs to,
draft issues from templates, create them via `gh issue create`, and track them locally.

All GitHub operations use the **`gh` CLI** — atomic, scriptable, and the same transport
the rest of the cogni-service pipeline uses. The user must have `gh` installed and
authenticated (`gh auth login`) before this skill runs.

The reliability win over a browser-automation transport is concrete: labels are applied
in the same API call that creates the issue (no "best-effort fallback" that silently
drops type signals), the flow runs equally well from a remote routine, and the skill has
no MCP-server dependency.

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

## gh CLI commands

All GitHub operations route through `scripts/gh-issues-helper.sh`. JSON on stdout,
errors on stderr.

> **Canonical command list.** This table and the `usage()` function in
> `scripts/gh-issues-helper.sh` describe the same surface. Update both together
> when adding or renaming a subcommand.

| Operation | Command |
|-----------|---------|
| Readiness check | `bash gh-issues-helper.sh check` |
| Create issue | `bash gh-issues-helper.sh create <repo> --title T --body-file F [--labels L1,L2]` |
| List issues | `bash gh-issues-helper.sh list <repo> [--state open\|closed\|all] [--limit N] [--label L] [--search Q]` |
| Search issues (dedup) | `bash gh-issues-helper.sh search <repo> "keywords" [--state open\|all]` |
| View issue | `bash gh-issues-helper.sh view <repo> <number>` |
| Browse URL | `bash gh-issues-helper.sh browse-url <repo> <number>` |

The helper validates that requested labels exist on the target repo before invoking
`gh issue create`, so a missing label fails fast with a structured error instead of
half-creating an issue without its type label.

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **setup** | `gh` not installed, `gh auth status` not authenticated, "set up issues", "ich kann kein Issue erstellen" | Probe gh + auth, guide through `gh auth login` |
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub via `gh`, update local record |
| **browse** | "open issue", "show in browser" | Print the GitHub issue URL (the user opens it) |

Default to **list** when intent is unclear.

## Prerequisites

Before any GitHub operation, verify `gh` readiness:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" check
```

The probe returns JSON like:

```json
{ "platform": "macos", "gh_installed": true, "gh_version": "2.89.0",
  "authenticated": true, "gh_user": "sdh07",
  "install_hint": "brew install gh", "login_hint": "gh auth login" }
```

Branch on `gh_installed` and `authenticated`:

- both `true` → proceed.
- `gh_installed: false` → switch to **setup mode** (install path).
- `gh_installed: true`, `authenticated: false` → switch to **setup mode** (login path).

## Setup mode

`gh` is a single binary with a one-time `gh auth login`. The setup is short and the user
keeps full control of their credentials — `gh` walks them through the OAuth flow in their
default browser.

### 1. Probe readiness

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" check
```

### 2. If `gh` is missing

Read `install_hint` from the probe output and tell the user how to install for their
platform:

> **macOS:** `brew install gh` (or download from https://cli.github.com/)
>
> **Linux:** see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
>
> Once installed, run `gh auth login` and let me know when you're ready.

After the user installs, re-run the probe.

### 3. If `gh` is installed but not authenticated

Tell the user:

> Run `gh auth login` in your terminal. Choose **GitHub.com**, then **HTTPS**, and
> authenticate with your browser (recommended) or a personal access token. When the
> CLI confirms login, let me know and I'll continue.

`gh auth login` handles 2FA and SSO transparently — the user authenticates in their
own browser using the github.com flow, no credential handling on our side.

After login, re-run the probe and confirm `authenticated: true` before proceeding.

### 4. Setup complete

If the user came here because they were trying to file an issue, continue with the
**create** flow.

## Create mode

### 1. Initialize workspace, check readiness, resolve the plugin

Initialize local issue state once per working directory (idempotent — safe to re-run
on every create):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in
`{working_dir}/cogni-issues/`.

Then verify `gh` readiness (see Prerequisites). If not ready, enter **setup mode** and
return here once `authenticated: true`.

If the user hasn't named a specific plugin, ask which plugin this is about. Then resolve it:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/resolve-plugin.sh" "<plugin_name>"
```

Handle: `"ambiguous": true` -> present matches and ask; `"error"` -> list available plugins
and ask; success -> extract `owner_repo`, `version`, `marketplace`.

### 2. Check for duplicates

Before investing in consultation and drafting, search for existing issues:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" \
  search "<owner_repo>" "<2-3 keywords from the user's complaint>" --limit 5
```

The output is a JSON array of `{number, title, labels, state, url, ...}` objects.
If you find a likely match, show it to the user and ask: "This looks similar — is it
the same problem, or something different?" If it's the same, link them to the existing
issue instead of creating a duplicate.

### 3. Determine the issue type

Infer the type from context (match intent across languages, not specific keywords):

| Type | Signals |
|------|---------|
| `bug` | something is broken, errors, crashes, doesn't work, fails, wrong output |
| `feature` | add something new, would be nice, request, support for |
| `change-request` | change existing behavior, modify, adjust, different behavior wanted |
| `question` | how to, why does, confused, wondering |

If genuinely ambiguous, ask. Otherwise trust your judgment.

**When the complaint involves config changes or unexpected output**, do a quick sanity
check before classifying: scan the plugin's data model or config schema to verify the
user's premise. For example, if a user says "I updated the logo in the config but it
still shows the old one," check whether the config actually has a logo field. The user's
mental model of how the plugin works may not match reality — what looks like a bug might
be a feature gap, a wrong-config-file situation, or a misunderstanding of which component
owns that functionality. A 30-second `Grep` or `Read` of the relevant schema can save
everyone from filing a misleading issue.

### 4. Consult the user

Help the user articulate what they need. Many users know something is wrong but haven't
organized their thoughts. Your job is to be a helpful interviewer, not a form.

**First, mine the conversation for existing evidence.** Check recent tool outputs for
error messages, stack traces, or failed commands. Look at what the user was working on —
the conversation often contains the exact workflow that triggered the problem. If you see
a traceback from earlier, use it — don't ask "did you see an error?"

**If you did a premise check (above) and found a mismatch**, incorporate that finding
into your consultation. Instead of generic "what happened?" questions, tell the user
what you found and ask targeted questions to resolve the gap — e.g., "I checked the
portfolio config schema and it doesn't have a logo field. Where exactly are you seeing
the logo, and which file did you edit?"

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

### 7. Create on GitHub via `gh`

Write the drafted body to a temp file, then invoke the helper. Labels come from the
type → label mapping in `references/issue-templates.md` and are applied atomically —
the helper fails fast if any label is missing on the repo, so the issue never lands
half-labelled.

```bash
BODY_FILE=$(mktemp -t cogni-issue.XXXXXX.md)
cat > "$BODY_FILE" <<'EOF'
<the drafted markdown body>
EOF

bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" \
  create "<owner_repo>" \
  --title "<title>" \
  --body-file "$BODY_FILE" \
  --labels "<csv of labels from the mapping>"

rm -f "$BODY_FILE"
```

The helper returns:

```json
{ "status": "created", "number": 142, "url": "https://github.com/.../issues/142",
  "title": "...", "labels": ["bug"] }
```

Capture `number` and `url` for the next step. If the helper exits non-zero, surface the
JSON error to the user and stop — never retry blindly. Common errors:

- `label(s) missing from repo` → tell the user which labels are missing and ask whether
  to file without them or to create the labels first.
- `gh issue create failed` → surface the `detail` field; usually a network or auth issue.

### 8. Log locally

```bash
ID_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/issue-store.sh" gen-id)
```

Then pipe the issue record as JSON via stdin:

```bash
echo '<json_record>' | bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/issue-store.sh" \
  add "${working_dir}"
```

The record includes: `id`, `plugin`, `marketplace`, `repository`, `github_number`,
`github_url`, `type`, `title`, `status` ("open"), `created_at`, `updated_at`.

`github_number` and `github_url` come straight from the helper's create response — no
URL parsing required.

### 9. Confirm

Return the GitHub issue URL and local issue ID.

## List mode

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin: title, type badge, GitHub number + URL, status, date.
If empty, suggest the create flow.

## Status mode

1. Look up the issue in local state to get `repository` and `github_number`.
2. Fetch the live state via `gh`:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" \
     view "<repository>" "<github_number>"
   ```

3. Parse the JSON response: `state` (OPEN/CLOSED), `labels[].name`, `comments[]` (the
   most recent few), `updatedAt`.
4. Update the local record via `update-status`.
5. Show the user: state, latest comments summary, labels, last update.

## Browse mode

Get the canonical URL and print it for the user — the SKILL doesn't open browsers
itself.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/gh-issues-helper.sh" \
  browse-url "<repository>" "<github_number>"
```

If the user wants the URL opened directly, suggest `open <url>` (macOS) or
`xdg-open <url>` (Linux) — those are the user's default-browser commands and don't
require any extra dependencies.

## Edge cases

- **Rate limiting**: `gh` surfaces GitHub's `X-RateLimit-Remaining: 0` as a clear
  error message. Inform the user to wait a few minutes; secondary rate limits clear
  in 1–2 minutes, primary limits in up to an hour.
- **Private repos**: `gh auth login` scopes determine access. If a user can't view a
  private repo, ask them to re-run `gh auth login` and grant the `repo` scope.
- **SSO-enforced orgs**: GitHub may require a one-time SSO authorization for the
  CLI's token. The error message names the URL the user must visit; pass it through
  verbatim.
- **Network failure**: surface the `gh` error and ask the user to retry. Local state
  is unaffected — the issue is created or it isn't.
- **Repo not found**: usually a typo in the resolver output. Re-run `resolve-plugin.sh`
  and verify the `owner_repo` field.

## Scripts

- **`scripts/gh-issues-helper.sh`** — gh CLI wrapper. Subcommands: `check`, `create`,
  `list`, `view`, `search`, `browse-url`. JSON on stdout, errors on stderr. Validates
  labels exist on the target repo before invoking `gh issue create`.
  - `list` accepts `--search Q` for inline keyword filtering on top of `--state` and
    `--label` (no need to switch to the `search` subcommand for simple substring filters).
- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning
  marketplace.json files. All insight-wave plugins resolve to the monorepo
  `cogni-work/insight-wave`.
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read,
  update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill
  placeholders and label mapping.
