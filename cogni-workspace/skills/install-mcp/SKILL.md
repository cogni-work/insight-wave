---
name: install-mcp
description: >-
  End-to-end MCP server installation for the insight-wave ecosystem — clone and build
  git-based MCPs, configure native app MCPs, and write the server into the user's own
  config for Claude Code or Claude Desktop without manual JSON editing. Use this skill
  whenever the user mentions MCP installation, MCP setup, MCP configuration, "my MCPs
  aren't working", "set up excalidraw", "install MCP servers", "update MCP servers",
  "patch desktop config", "MCP not found", "excalidraw tools not available", "excalidraw
  tools missing in Claude Code", "MCP not loaded", "mcpServers missing in
  ~/.claude.json", "pencil MCP not working", port conflicts with MCP servers
  (localhost:3000), or any mention of claude_desktop_config.json. Also trigger when
  manage-workspace needs to handle its MCP installation step (step 5), when
  workspace-status reports MCP servers as not loaded and the user wants to fix it, or
  when a rendering agent (render-infographic-*, web, storyboard) fails because its MCP
  dependency is missing.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, ToolSearch
---

# Install MCP

## Why This Exists

Plugins in insight-wave depend on MCP servers (Excalidraw for diagrams, Pencil for web
rendering, etc.). No plugin declares a server itself. A checked-in declaration asserts
machine state the repository cannot guarantee, so on a machine that never installed the
server it is spawned at session start and fails visibly. The server is therefore installed
on demand and written into the user's own config, which is the one place that can honestly
say what is available. Git-based MCPs also need cloning and building, and users of either
client used to have to edit that config by hand.

This skill handles the full lifecycle: detect what's needed, install it, configure it
for the user's environment, and verify it works. No manual JSON editing required.

## Detect Environment

Determine the user's runtime environment — this affects what needs patching:

1. **Locate the config to write.** Claude Code reads a user-scope config; Claude Desktop
   reads its own. Check both:
   - Claude Code (all platforms): `~/.claude.json`, top-level `mcpServers`
   - Claude Desktop, macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Claude Desktop, Linux: `${XDG_CONFIG_HOME:-~/.config}/Claude/claude_desktop_config.json`
   - Claude Desktop, Windows: `%APPDATA%/Claude/claude_desktop_config.json`

   Only the top-level `mcpServers` in `~/.claude.json` is user scope. The per-project
   `projects.<path>.mcpServers` objects in that same file are local scope — never write
   there, or the server disappears the moment the user changes directory.

2. **Classify environment:**
   - **Claude Code CLI** — needs the git install AND a `--target cli` write to `~/.claude.json`.
   - **Claude Desktop** — needs the git install AND a `--target desktop` write.
   - **Both** — Desktop config exists alongside CLI usage. Use `--target both`.

Record the classification as `MCP_TARGET`, whose only legal values are `cli`, `desktop`
and `both`. The write step below sets and consumes it in a single shell — each invocation
gets a fresh environment, so an assignment made here would not survive to reach it.

Report which environment was detected before proceeding.

## Discover What's Needed

Read the MCP registry to understand what servers exist and which plugins need them:

```bash
REGISTRY="${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json"
cat "$REGISTRY"
```

Cross-reference against installed plugins, determined one of three ways in order of
preference:

1. **During manage-workspace** — the confirmed plugin list is already available from step 2
   (the user-confirmed list, not step 1's raw discovery output)
2. **Standalone invocation** — discover plugins by scanning the marketplace cache:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
   ```
3. **Fallback if discover-plugins returns empty** — the plugin cache may be empty in some
   environments. Fall back to scanning sibling directories for a plugin manifest:
   ```bash
   # Scan sibling plugin directories for a plugin manifest
   for dir in $(dirname "${CLAUDE_PLUGIN_ROOT}")/cogni-*; do
     if [ -f "$dir/.claude-plugin/plugin.json" ]; then
       basename "$dir"
     fi
   done
   ```
   This catches the common case where plugins are installed but the cache index is stale.
   Key it on the manifest, the same file `discover-plugins.sh` globs — no plugin ships a
   `.mcp.json` any more, so a scan keyed on that would silently find nothing and report
   success.

For each server in the registry, check if any installed plugin appears in its `required_by`
list. Only install servers that have at least one requiring plugin present.

Present the installation plan to the user before executing:

Name the config that will actually be written, taken from the environment detected
above — one line per target, so a `both` run shows both. The block below is illustrative;
each server's requiring plugins come from its `required_by` in the registry, never from
this example:

```
MCP Installation Plan:
  mcp_excalidraw  git clone + build    needed by: cogni-portfolio, cogni-workspace
  pencil          native app check     needed by: cogni-website, cogni-workspace

  Config write:    ~/.claude.json (Claude Code user scope)
  Config write:    claude_desktop_config.json (Claude Desktop)
```

## Install Git-Based MCP Servers

For each server with `"type": "git"` that's needed:

```bash
WRAPPER_REL=$(python3 -c "
import json
reg = json.load(open('${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json'))
print(reg['servers']['SERVER_NAME'].get('wrapper', ''))
")

WRAPPER_ARG=""
if [ -n "$WRAPPER_REL" ]; then
  WRAPPER_ARG="--wrapper ${CLAUDE_PLUGIN_ROOT}/${WRAPPER_REL}"
fi

bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-mcp.sh" \
  --name "SERVER_NAME" \
  --repo "REPO_URL" \
  --build "BUILD_CMD" \
  $WRAPPER_ARG
```

`--name` becomes the directory the server is installed into, under `$CLAUDE_MCP_DIR`.
Which registry key belongs here, how it differs from the one naming the host config
entry, and what base `$CLAUDE_MCP_DIR` falls back to, are all stated once in
`${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/mcp-registry.md` under
"## Diagnosing a not-loaded install-mcp server".

The script outputs JSON. On success, `data.action` is `installed` (fresh clone),
`updated` (a `--force` refetch), `rebuilt` (already cloned but unbuilt, so the build
reran) or `skipped` (already built). A failure carries no `action` at all — it reports
`success: false` with the cause in `data.error` — so branch on `success` before reaching
for `action`. If any server fails, continue with the rest but flag the failure clearly.

To force-update an already-installed server (e.g. after upstream changes), add `--force`.

## Check Native App MCP Servers

For each server with `"type": "native"`, check whether the binary exists at its
platform-specific path. Don't try to install it — just report:

- **Found** — binary exists, ready to configure
- **Not found** — tell the user where to get it with a direct link:
  - Pencil: download from https://pencil.dev — install the app, then the MCP binary is bundled inside

## Write MCP Servers Into User Config

Run this **after** the git install succeeds — the writer resolves each server's installed
wrapper, and reports `skipped: not installed` rather than writing an entry that points at
a path which does not exist yet.

With `MCP_TARGET` set to the environment classified above:

- Pass `--target "${MCP_TARGET}"`.
- The script's name predates its remit: despite `desktop` in the file name it writes
  either config, selected by `--target`, so a `--target cli` run writing
  `~/.claude.json` is correct and not a copy-paste slip.
- Scope every invocation to the servers the plan named. An unrequested entry is another
  server spawned at every session or app start, which is what this arrangement exists
  to avoid — for either target.
- Repeat `--server` once per server (`--server mcp_excalidraw --server pencil`). The
  flag appends rather than splitting a comma-separated value, so a CSV is read as one
  server name, matches no registry entry, and the run exits non-zero with
  `Unknown server(s) in registry: ...` having written nothing.

Dry-run first:

```bash
MCP_TARGET="<cli|desktop|both, as classified above>"

python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-desktop-config.py" \
  --registry "${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json" \
  --target "${MCP_TARGET}" --server mcp_excalidraw \
  --dry-run
```

Substitute the classified value for the placeholder; carried through as written, argparse
rejects it rather than silently writing the wrong host's config. Keep the assignment in the
same invocation as the command — a separate one starts a fresh shell and `${MCP_TARGET}`
expands empty.

Show the user what would change. If they confirm (or if running non-interactively from
manage-workspace), run again without `--dry-run`.

The same command covers every environment, because `MCP_TARGET` carries the detection:
`cli` writes the user-scope entry in `~/.claude.json`, `desktop` writes
`claude_desktop_config.json`, and `both` writes each in turn.

**Branch on the target before reading the result**, then build the Summary rows below from
the per-server `actions[]`. The envelope's full shape — the single-target vs `--target both`
split, the `actions[]` entry fields, the target-level verbs, and the shapes that yield
no rows at all — is in
`${CLAUDE_PLUGIN_ROOT}/skills/install-mcp/references/result-envelope.md`.

The script:
- Creates a timestamped backup before modifying an **existing** config — the first-ever-write
  case and its `backup: null` are in
  `${CLAUDE_PLUGIN_ROOT}/skills/install-mcp/references/result-envelope.md` under "## Backups"
- Preserves every other key in the file — `~/.claude.json` holds unrelated user state
- Skips servers that are already configured (use `--force` to overwrite)
- Handles both git-installed servers (resolves wrapper path) and native apps (platform binary)
- Reports JSON with every action taken

After writing, remind the user to restart: **Claude Desktop** for a desktop write, or the
**Claude Code session** for a CLI write. Newly written servers do not appear in the session
that wrote them.

## Verify Installation

After installation and patching, verify that MCP servers are available in the current
session. For each server just installed, use ToolSearch to probe for its tool prefix:

| Server | Probe Tool |
|--------|-----------|
| excalidraw | `mcp__excalidraw__describe_scene` |
| pencil | `mcp__pencil__get_editor_state` |

Report status:
- **Loaded** — tools found, server is active
- **Installed but not loaded** — installed successfully, but needs a session restart to appear
- **Failed** — installation reported success but tools not found even after restart

A "not loaded" result on a server just written is expected, and clears with the restart
described above.

## Summary

Present a compact result:

Name the config actually written, and follow the target for the restart line — a CLI
write needs a new Claude Code session, not a Claude Desktop restart. The Action cell is
the `action` verb taken verbatim from that target's `actions[]`, never a label composed
here:

```
MCP Installation Complete:

  Server            Action          Config Written    Status
  ────────────────  ──────────────  ────────────────  ──────────
  mcp_excalidraw    added           ~/.claude.json    not loaded
  pencil            added           ~/.claude.json    not loaded

  Backup: ~/.claude.backup-20260409T...json
  Next: start a new Claude Code session if any servers show "not loaded"
```

Under `--target both`, give each config its own row per server (reading each entry of
`data.targets[]`), and list a backup line per config written:

```
  Server            Action          Config Written               Status
  ────────────────  ──────────────  ───────────────────────────  ──────────
  mcp_excalidraw    added           ~/.claude.json               loaded
  mcp_excalidraw    added           claude_desktop_config.json   not loaded

  Backup: ~/.claude.backup-20260409T...json
  Backup: claude_desktop_config.backup-20260409T...json
  Next: start a new Claude Code session, and restart Claude Desktop, for any
        server showing "not loaded"
```

## When Called from manage-workspace

manage-workspace delegates its MCP step (Init and Update mode step 5) to this skill.
When invoked that way:

- Skip the plugin discovery step (use the confirmed plugin list from manage-workspace)
- Skip the user confirmation of the plan (manage-workspace already has user consent)
- Run install + patch + verify in sequence
- Return the summary for manage-workspace to include in its final report

## Error Handling

- If `install-mcp.sh` fails for a server, report the error from `data.error` and continue
  with remaining servers
- If `patch-desktop-config.py` fails, show the error and suggest manual patching as fallback
- If the config being written has invalid JSON, warn the user rather than corrupting it
  further. This applies to `~/.claude.json` as much as to `claude_desktop_config.json`.
- `patch-desktop-config.py` does not always return per-server rows. The shapes that produce
  that, and the recovery each one calls for, are in
  `${CLAUDE_PLUGIN_ROOT}/skills/install-mcp/references/result-envelope.md`.

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
