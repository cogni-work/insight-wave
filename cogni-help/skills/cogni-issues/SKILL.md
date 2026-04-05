---
name: cogni-issues
version: 0.3.0
description: |
  File and track GitHub issues (bugs, feature requests, change requests, questions) against
  insight-wave ecosystem plugins using browser automation (browsermcp). Guides users
  through a short consultation to capture the right details, resolves the target plugin's
  repository automatically, drafts issues from templates, creates them via browser automation on
  github.com, and tracks them locally.
  Use this skill whenever the user wants to report a bug, request a feature, file a change
  request, ask a question about a plugin, list filed issues, or check issue status.
  Also trigger when the user says things like "this plugin is broken", "I found a problem
  with {plugin}", "can we get X added to {plugin}", "{plugin} doesn't work", "open an issue",
  "something is wrong with {plugin}", "das Plugin funktioniert nicht", "Fehler in {plugin}",
  "set up GitHub issues", "configure issue filing", "ich kann kein Issue erstellen",
  or any complaint/suggestion about a specific plugin — even if they don't use the word "issue".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, mcp__browsermcp__browser_navigate, mcp__browsermcp__browser_snapshot, mcp__browsermcp__browser_click, mcp__browsermcp__browser_type, mcp__browsermcp__browser_press_key, mcp__browsermcp__browser_wait, mcp__browsermcp__browser_screenshot
---

# Cogni Issues

Manage the lifecycle of GitHub issues for insight-wave ecosystem plugins: consult with the
user to understand the problem clearly, resolve which repository the plugin belongs to,
draft issues from templates, create them via browser cobrowsing on github.com, and track
them locally.

All GitHub operations use **browser automation via browsermcp** (Playwright headless) —
navigating to github.com, reading pages, and filling forms directly. This works in any
environment, including Cowork VMs. No Personal Access Tokens or `gh` CLI needed —
browsermcp auto-installs via the plugin's `.mcp.json` when the plugin is loaded.

**Important:** Do NOT use `gh` CLI commands — all GitHub operations go through
browser automation. The `gh` CLI is not required and should not be invoked.

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

## Browser Tools for GitHub

All GitHub operations use browsermcp (Playwright headless) tools:

| Operation | Tools | URL Pattern |
|-----------|-------|-------------|
| Create issue | `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type` | `github.com/{owner}/{repo}/issues/new` |
| List issues | `browser_navigate`, `browser_snapshot` | `github.com/{owner}/{repo}/issues` |
| Search issues | `browser_navigate`, `browser_snapshot` | `github.com/{owner}/{repo}/issues?q={keywords}` |
| Get issue | `browser_navigate`, `browser_snapshot` | `github.com/{owner}/{repo}/issues/{number}` |

The browsermcp tools are declared in the skill's `allowed-tools` and auto-loaded from
the plugin's `.mcp.json`. No ToolSearch needed.

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **setup** | browsermcp not available or user not logged into GitHub, "set up issues", "ich kann kein Issue erstellen" | Verify browsermcp, guide user to log into GitHub |
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub via browser, update local record |
| **browse** | "open issue", "show in browser" | Navigate to the GitHub issue in the browser |

Default to **list** when intent is unclear.

## Prerequisites

Before any GitHub operation, verify browsermcp availability and GitHub login:

1. Try `mcp__browsermcp__browser_navigate` to `https://github.com`
2. If the tool fails or is not found, tell the user: "This skill requires browsermcp.
   Please ensure the cogni-help plugin is properly installed (it bundles browsermcp
   via .mcp.json)."
3. Use `mcp__browsermcp__browser_snapshot` to read the page
4. Check the snapshot for a logged-in indicator (profile menu, avatar, or username).
   If the page shows a "Sign in" link instead, switch to **setup mode**
5. If the user is logged in — proceed

## Setup mode

browsermcp runs headless (Playwright) — no visible browser window. The user needs
to have GitHub credentials available for headless login.

### 1. Check browsermcp availability

Try `mcp__browsermcp__browser_navigate` to `about:blank`. If the tool is not
available, inform the user that browsermcp is required and should auto-install
when the cogni-help plugin is loaded via `.mcp.json`.

### 2. Check GitHub login

Navigate to `https://github.com` and use `mcp__browsermcp__browser_snapshot` to
read the page. Look for signs of a logged-in session (profile avatar, user menu)
vs "Sign in" link.

If the snapshot shows the user is already logged in, tell them they're all set
and offer to file an issue.

### 3. If not logged in

Navigate to `https://github.com/login` and guide the user through headless login:

1. Use `browser_snapshot` to find the username/email field
2. Use `browser_click` on the username field, then `browser_type` to enter credentials
3. Ask the user for their GitHub username/email (via AskUserQuestion)
4. Click the password field, ask for password input
5. Click "Sign in" and wait for redirect

**Alternative:** If headless login is complex (2FA, SSO), suggest the user set up
a GitHub Personal Access Token and use the `gh` CLI as a fallback:

> Headless GitHub login requires credentials. If you have 2FA enabled, it may be
> easier to use a Personal Access Token. Would you like me to guide you through that?

### 4. After login

Re-check with `browser_snapshot` on `https://github.com`. If the page shows a
logged-in state, confirm success. If still not logged in, suggest the PAT fallback.

### 5. Setup complete

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

First, verify browser access and GitHub login (see Prerequisites). If not ready,
enter **setup mode** and return here once the user is logged in.

If the user hasn't named a specific plugin, ask which plugin this is about. Then resolve it:

```bash
bash "${SKILL_DIR}/scripts/resolve-plugin.sh" "<plugin_name>"
```

Handle: `"ambiguous": true` -> present matches and ask; `"error"` -> list available plugins
and ask; success -> extract `owner_repo`, `version`, `marketplace`.

### 2. Check for duplicates

Before investing in consultation and drafting, search for existing issues via the browser:

1. Navigate to `https://github.com/{owner}/{repo}/issues?q=is%3Aopen+{url_encoded_keywords}`
   using 2-3 keywords from the user's complaint
2. Use `browser_snapshot` to read the search results page
3. Look for issue titles and links in the accessibility snapshot

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

### 7. Create on GitHub via browser

Navigate to `https://github.com/{owner}/{repo}/issues/new` and fill the form:

1. Use `browser_snapshot` to verify the "New Issue" form has loaded — look for the
   title input field and body textarea in the snapshot
2. Use `browser_click` on the title field (by ref from snapshot), then `browser_type`
   to enter the title
3. Use `browser_click` on the body textarea, then `browser_type` to enter the full
   drafted body
4. **Labels** (optional): Use `browser_click` on the "Labels" gear icon in the sidebar,
   wait for the label filter to appear, then `browser_type` the label name and
   `browser_click` the matching label. Label mapping is in `references/issue-templates.md`.
   If the interaction fails, skip it — the issue can be created without labels.
5. Use `browser_click` on the **"Submit new issue"** button
6. Use `browser_wait` for navigation, then `browser_snapshot` to read the new issue
   page. Extract `github_number` (from the URL or heading) and `github_url`

If creation fails entirely, show the error and suggest next steps — don't retry blindly.

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

Parse `github_number` and `github_url` from the browser redirect URL after submission.

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
2. Navigate to `https://github.com/{owner}/{repo}/issues/{github_number}`
3. Use `browser_snapshot` to read the issue page — extract state (open/closed), labels,
   latest comments, and last update timestamp from the accessibility tree
4. Update local record via `update-status`
5. Show: state, latest comments summary, labels, last update

## Browse mode

Navigate to the GitHub issue URL using `browser_navigate`. The URL follows
the pattern: `https://github.com/<owner>/<repo>/issues/<number>`

If browsermcp is unavailable, provide the URL as text instead.

## Edge cases

- **2FA / SSO prompts**: If navigating to github.com triggers additional authentication,
  the snapshot will show auth prompts instead of normal GitHub content. Detect this and
  tell the user: "GitHub is asking for additional authentication. If you have 2FA
  enabled, consider using a Personal Access Token with the `gh` CLI instead."
- **Private repos**: browsermcp session cookies persist within the session, so private
  repos work as long as the user has logged in during this session.
- **GitHub HTML changes**: If expected form fields don't appear in the snapshot, use
  `browser_screenshot` to visually inspect the page and adapt element references.
- **Rate limiting**: If GitHub returns a rate-limit page, inform the user to wait a few
  minutes before retrying.
- **Headless limitations**: browsermcp runs headless (no visible browser window). The user
  cannot see what the browser is doing. Use `browser_screenshot` to share visual state
  when the user needs to verify something.

## Scripts

- **`scripts/setup-gh.sh`** — Platform info script. Returns JSON with OS detection. The primary readiness check is done via browsermcp tools (navigate + snapshot).
- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files. All insight-wave plugins resolve to the monorepo `cogni-work/insight-wave`.
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
