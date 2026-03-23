---
name: setup-github-mcp
description: >-
  Guide users through installing and configuring the GitHub MCP server in Claude
  Desktop. Checks prerequisites (Docker or Node.js), walks through GitHub PAT
  creation, edits the Claude Desktop config file, and verifies the setup.
  Use this skill whenever the user asks about setting up GitHub access in Claude
  Desktop, configuring MCP servers, "GitHub MCP", "set up GitHub for Claude Desktop",
  "I need GitHub access in Claude", "configure MCP", "GitHub integration for Claude",
  "install GitHub MCP", "MCP Server einrichten", "GitHub in Claude Desktop installieren",
  "GitHub in Claude Desktop konfigurieren", "GitHub MCP einrichten",
  or when another skill detects the user needs GitHub MCP access in Claude Desktop.
  Also trigger when the user mentions MCP server setup problems, broken GitHub
  integration in Claude Desktop, or wants to update their GitHub token.
version: 0.1.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# Setup GitHub MCP

Guide users through configuring the GitHub MCP server in Claude Desktop, step by step.
This enables GitHub integration (issues, PRs, repos) directly from Claude Desktop.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`) as the default interaction language. If the
user's message is in a different language, prefer the user's language (message
detection overrides the workspace setting).

If `.workspace-config.json` is missing, fall back to detecting the user's language
from their message. If still unclear, default to English.

Conduct the entire interaction in the chosen language — explanations, prompts, and
confirmations.

Keep in English regardless of language setting:
- Technical terms: Docker, MCP, GitHub, PAT, JSON, config
- File paths and config keys
- CLI commands
- Error messages

## Environment

Scripts live at `${CLAUDE_PLUGIN_ROOT}/skills/setup-github-mcp/scripts/`.
Config templates are at `${CLAUDE_PLUGIN_ROOT}/skills/setup-github-mcp/references/config-templates.md`.

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **setup** | "set up GitHub MCP", "install GitHub MCP", default | Full guided walkthrough |
| **check** | "is GitHub MCP configured?", "check my MCP config" | Run check script, report status |
| **repair** | "GitHub MCP stopped working", "fix MCP config", "update token" | Re-check, diagnose, fix |

Default to **setup** when intent is unclear.

## Prerequisites Check

Before any operation, run the check script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup-github-mcp/scripts/check-mcp.sh" check
```

The output tells you the current state: platform, config file location, Docker/npx
availability, and whether GitHub MCP is already configured.

If `all_ready` is `true` and mode is **setup**, tell the user they're already set up.
Offer to reconfigure (update token) or verify the config.

## Setup Flow

### Step 1: Assess the situation

Run `check-mcp.sh check` and read the JSON output. This determines which steps
to show the user and which to skip.

### Step 2: Choose installation method

Three methods are available. Pick the simplest one that works for the user's system.

**Method 1 — `gh mcp-server` (simplest, if `gh` CLI v2.80+ is authenticated):**
If the check script shows `gh` is installed and authenticated, this is the easiest
path — it reuses existing `gh auth` credentials with zero token setup. Check the
version with `gh --version`. If v2.80+, use this method. If older, mention the user
can upgrade with `brew upgrade gh` (macOS) or their package manager. The config block
needs no `env` section at all — see `references/config-templates.md`.

**Method 2 — Docker (if Docker is installed and running):**
Uses the official GitHub MCP server Docker image. Self-contained and matches
the official documentation. Requires a GitHub PAT.

**Method 3 — npx (fallback, if Node.js is available):**
Uses the community MCP server package. Simpler than Docker, just needs Node.js 18+.
Requires a GitHub PAT.

**If none are available:** Ask the user which they'd prefer to install:
- GitHub CLI (`brew install gh`) — simplest, no token needed
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- Node.js (includes npx): https://nodejs.org/

Wait for the user to install their choice, then re-run `check-mcp.sh check`.

**If Docker is installed but not running:** Tell the user to start Docker Desktop
and wait for it to be ready, then re-run the check.

### Step 3: Create a GitHub Personal Access Token

The user needs a GitHub PAT (classic) for the MCP server. Walk them through it:

1. Open https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a descriptive name (e.g., "Claude Desktop MCP")
4. Set an expiration (90 days recommended — they can always create a new one)
5. Select these scopes:
   - `repo` — repository access
   - `read:packages` — package read access
   - `read:org` — organization membership read access
6. Click **"Generate token"**
7. **Copy the token immediately** — GitHub will not show it again

Ask the user to paste the token back. Reassure them: the token will only be written
to their local Claude Desktop config file, nowhere else.

If the user already has a PAT they want to use, skip this step.

### Step 4: Edit the Claude Desktop config file

The config file path comes from `check-mcp.sh` output (`config_path` field).

Read `references/config-templates.md` for the exact config blocks.

**Scenario A — No config file exists:**
Create the directory if needed, then write the full config with the GitHub MCP
server block using the Write tool.

**Scenario B — Config file exists but has no `mcpServers` or is empty `{}`:**
Write the full config with the GitHub MCP server block.

**Scenario C — Config file exists with other MCP servers:**
This is the most common and delicate case. Other MCP servers (Excalidraw, Pencil,
etc.) must not be disturbed.

1. Read the existing config file
2. Parse the JSON and add the `github` key to `mcpServers`
3. Show the user **only the `mcpServers` section** with the new addition — do not
   display the full config file (it may contain private settings like trusted folders,
   preferences, etc. that are not relevant and should not be echoed back).
   Collapse existing server entries as `{ ... }` to keep the diff focused, e.g.:
   ```json
   "mcpServers": {
     "excalidraw": { ... },
     "github": { "command": "npx", ... }
   }
   ```
4. After confirmation, write the merged config back

Use python3 for reliable JSON merging:

```bash
python3 -c "
import json
with open('<config_path>') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})
cfg['mcpServers']['github'] = {
    'command': '<command>',
    'args': <args_list>,
    'env': {
        'GITHUB_PERSONAL_ACCESS_TOKEN': '<token>'
    }
}
with open('<config_path>', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
"
```

**Scenario D — `github` key already exists in `mcpServers`:**
Ask if the user wants to update it (e.g., new token, switch Docker↔npx).
Show the current config and the proposed change.

### Step 5: Restart Claude Desktop

The MCP server configuration only takes effect after restarting Claude Desktop.

Tell the user: "Please quit Claude Desktop completely and reopen it. The GitHub
MCP server will connect automatically on startup."

On macOS, you can offer to restart automatically (with explicit permission):

```bash
osascript -e 'quit app "Claude"' && sleep 2 && open -a "Claude"
```

**Important:** Warn the user that restarting will close their current session.
The conversation will end — they should come back after restart to verify.

### Step 6: Verification

After the user restarts and returns, tell them to look for the **hammer/tool icon**
in the Claude Desktop chat input area. Clicking it should show GitHub-specific tools
(like `create_issue`, `search_repositories`, `get_file_contents`). If the tools
appear, the MCP server loaded successfully.

Then suggest they test by asking Claude something like:
- "List my GitHub repositories"
- "Show recent issues in [repo-name]"

If it works, the setup is complete. If not, switch to **repair** mode.

## Repair Mode

When the user reports GitHub MCP isn't working, be a reactive troubleshooter — not
a setup wizard. Focus on diagnosing the specific problem they described rather than
walking through a generic checklist. Ask targeted follow-up questions based on what
the diagnostics reveal.

1. Run `check-mcp.sh check` to get current status
2. **Interpret the results in context of what the user reported.** If they said
   "it broke after updating Docker", focus on Docker — don't also lecture about
   PAT scopes. If they said "I get auth errors", focus on the token.
3. Common issues and their fixes:
   - **Docker not running:** "Start Docker Desktop and try again"
   - **Docker CLI missing after update:** Check if Docker.app exists but the CLI
     symlink broke. Suggest re-enabling "Install Docker CLI in system PATH" in
     Docker Desktop settings, or offer to switch to npx/gh method instead
   - **Token expired:** Guide through creating a new PAT (Step 3) and updating the config
   - **Config file has invalid JSON:** Read the file, report the parse error, offer to
     back up the broken file and write a corrected version
   - **GitHub MCP entry missing from config:** May have been lost during a Claude Desktop
     update. Re-add it using the setup flow's config editing step
   - **Wrong config path:** The check script auto-detects, but if the user installed
     Claude Desktop in a non-standard location, ask for the path
4. **Check Claude Desktop logs** for error details: `~/Library/Logs/Claude/` (macOS)
   or `~/.config/Claude/logs/` (Linux). These often contain the exact MCP server
   startup error.
5. After fixing, remind to restart Claude Desktop

## Platform-Specific Config Paths

| Platform | Config path |
|----------|-------------|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Linux | `~/.config/Claude/claude_desktop_config.json` |

The check script resolves these automatically.

## Scripts

- **`scripts/check-mcp.sh`** — Checks Docker, npx, config file, and GitHub MCP
  configuration status. Returns JSON with `all_ready` boolean. Run with `check` command.

## References

- **`references/config-templates.md`** — Docker and npx config blocks, required PAT
  scopes, GitHub Enterprise config, and security notes.
