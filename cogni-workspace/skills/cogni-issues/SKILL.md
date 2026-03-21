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
  "set up GitHub issues", "configure issue filing", "ich kann kein Issue erstellen",
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
| **setup** | "set up issues", "configure gh", first-time detection, "ich kann kein Issue erstellen" | Check gh status, guide install + auth |
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub, update local record |
| **browse** | "open issue", "show in browser" | Open via `gh issue view --web` |

Default to **list** when intent is unclear.

## Prerequisites

Before any `gh` operation, check readiness:

```bash
bash "${SKILL_DIR}/scripts/setup-gh.sh" check
```

If `all_ready` is `true`, proceed. If `false`, switch to **setup mode** and guide the user
through what's missing. Do not attempt issue creation without valid auth — fail fast but
fail helpfully.

## Setup mode

Many users — especially in Cowork — have never used GitHub or the `gh` CLI. Setup mode
walks them through everything they need, one step at a time, in their own language.

### 1. Run the check

```bash
bash "${SKILL_DIR}/scripts/setup-gh.sh" check
```

The output tells you exactly what's missing: `gh_installed`, `gh_authenticated`, `platform`,
and `package_manager`.

### 2. If `all_ready` is already true

Tell the user they're all set and offer to file an issue. No further setup needed.

### 3. If `gh_installed` is false

The user needs the GitHub CLI. Present the right install command based on `package_manager`:

| Package manager | Command |
|----------------|---------|
| `brew` (macOS) | `brew install gh` |
| `apt` (Debian/Ubuntu) | First add the repo, then `sudo apt install gh` |
| `dnf` (Fedora/RHEL) | `sudo dnf install gh` |
| `snap` | `sudo snap install gh` |
| `null` (none found) | Direct them to https://cli.github.com/ for manual download |

**Explain in plain language** what `gh` is: "It's a small command-line tool from GitHub
that lets you create issues, pull requests, and more — right from your terminal. You only
need to install it once."

Ask the user to run the install command in their terminal and tell you when it's done.
Then re-run `setup-gh.sh check` to confirm.

### 4. If `gh_authenticated` is false

The user needs to log in to GitHub. This step is interactive — Claude cannot run it for
them because it opens a browser for OAuth.

**If the user doesn't have a GitHub account yet**, tell them:
- Go to https://github.com/join
- Create a free account (they only need a username, email, and password)
- Come back when done

**Once they have an account**, walk them through authentication:

1. Tell them to type `gh auth login` in their terminal
2. Explain what they'll see — a series of questions:
   - **Where do you use GitHub?** → Choose "GitHub.com"
   - **Preferred protocol?** → Choose "HTTPS"
   - **Authenticate?** → Choose "Login with a web browser"
3. A code will appear in the terminal — they paste it in the browser window that opens
4. They authorize the GitHub CLI in the browser
5. Done — the terminal confirms they're logged in

After they confirm, re-run `setup-gh.sh check` to verify `gh_authenticated` is now `true`.

### 5. Setup complete

Confirm everything is ready. If the user came here because they were trying to file an
issue, offer to continue with the **create** flow now.

## Workspace init

Run once before any operation (idempotent):

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in `{working_dir}/cogni-issues/`.

## Create mode

### 1. Check readiness and resolve the plugin

First, run `setup-gh.sh check`. If `all_ready` is `false`, tell the user you need to set
up a few things first, enter **setup mode**, and return here once setup completes.

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

- **`scripts/setup-gh.sh`** — Checks gh CLI installation and authentication status. Returns JSON with `all_ready` boolean. Run with `check` command.
- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files. All cogni-works plugins resolve to the monorepo `cogni-work/cogni-works`.
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
