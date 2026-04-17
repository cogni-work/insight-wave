# Claude Code desktop installation guide for consultants

This guide gets you from zero to a working Claude Code setup — authenticated with your Claude Max subscription, connected to the cogni-work plugin marketplace, and wired to the MCP servers you need for client work. It covers **macOS 13+** and **Windows 10 (1809+) / 11**, uses Anthropic's **native installer** (now the recommended path as of April 2026), and flags the exact places where Mac and Windows steps diverge. Expect about **20–30 minutes** for a first-time setup.

A note on what changed in 2026: Anthropic replaced the old npm-based installer with a one-line native installer that auto-updates in the background. **Windows no longer requires WSL2** — native Windows works fine as long as Git for Windows is installed. If you followed an older guide, the instructions below supersede it.

---

## Prerequisites checklist

Before starting, confirm you have each of the following. You do **not** need to install Node.js unless you plan to use the deprecated npm path (we don't recommend it).

| Item | macOS | Windows |
|---|---|---|
| Supported OS | macOS 13 Ventura or newer | Windows 10 build 1809+ or Windows 11 |
| Active Claude subscription | Claude Max 5x ($100/mo) or Max 20x ($200/mo) — Pro also works | Same |
| Hardware | 4 GB RAM, Apple Silicon or Intel x64 | 4 GB RAM, x64 or ARM64 |
| Internet connection | Required for install and auth | Required |
| Admin rights | Not required | Not required |
| Git | Recommended (for normal work) | **Required** — Git for Windows |
| Terminal | Terminal.app, iTerm2, or Warp | Windows Terminal + PowerShell |

**Free Claude.ai accounts do not include Claude Code.** You need an active Max (or Pro/Team/Enterprise) plan. Verify at [claude.ai/settings/billing](https://claude.ai/settings/billing) before continuing.

---

## Part 1 — macOS installation

### Step 1.1: Install Git (if missing)

Open **Terminal** (Applications → Utilities → Terminal) and run:

```bash
git --version
```

If you see a version number, skip ahead. If macOS prompts you to install the Xcode Command Line Tools, accept — this gives you Git plus a few other tools Claude Code can call on. Alternatively, install Git via Homebrew later (Step 1.2).

### Step 1.2: Install Homebrew (optional but useful)

Homebrew is macOS's package manager. You only need it if you want the Homebrew-based install path or other tools later. Skip if you prefer the one-liner in Step 1.3.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts. At the end, Homebrew prints two lines to add it to your PATH — **copy-paste them into Terminal exactly as shown**, then close and reopen Terminal.

Verify: `brew --version` should print something like `Homebrew 4.x.x`.

### Step 1.3: Install Claude Code (native installer — recommended)

This is the single command most consultants should use. It installs a self-contained binary to `~/.local/bin/claude` and sets up background auto-updates.

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Expected output:** progress lines ending with something like `Claude Code 2.1.x installed successfully. Run 'claude' to get started.`

Close Terminal and reopen it so the new PATH takes effect, then verify:

```bash
claude --version
```

You should see `2.1.x (Claude Code)` or similar. If the command is not found, see the [PATH troubleshooting section](#path-and-command-not-found-issues) below.

**Alternative: Homebrew cask.** If you'd rather manage Claude Code with brew (upgrades are manual, not automatic):

```bash
brew install --cask claude-code
```

### Step 1.4: Choose your terminal (optional)

The built-in **Terminal.app** works fine. Most consultants prefer one of:

- **iTeam2** (`brew install --cask iterm2`) — mature, scriptable, great for split panes.
- **Warp** (`brew install --cask warp`) — modern UI, AI features, block-based command history.

Any of the three works with Claude Code. Pick one and stick with it.

---

## Part 2 — Windows installation

### Step 2.1: Install Git for Windows (required)

Download from [git-scm.com/downloads/win](https://git-scm.com/downloads/win) and run the installer. Accept the defaults **with one exception**: on the "Adjusting your PATH environment" screen, choose **"Git from the command line and also from 3rd-party software."** This makes Git Bash available to Claude Code, which it uses internally to execute shell commands — even when you launch it from PowerShell.

Verify in a fresh PowerShell window:

```powershell
git --version
```

### Step 2.2: Install Windows Terminal (recommended)

Windows Terminal gives you a modern tabbed terminal with good Unicode rendering. Install from the Microsoft Store or via WinGet:

```powershell
winget install Microsoft.WindowsTerminal
```

Open Windows Terminal and make sure the default profile is **PowerShell** (not the older Windows PowerShell 5.x — you want PowerShell 7+). Install it if needed:

```powershell
winget install Microsoft.PowerShell
```

### Step 2.3: Install Claude Code (native installer — recommended)

In PowerShell:

```powershell
irm https://claude.ai/install.ps1 | iex
```

This installs `claude.exe` to `%USERPROFILE%\.local\bin\` and adds it to your user PATH. **Close and reopen Windows Terminal** for PATH changes to register.

**Expected output:** progress messages followed by `Claude Code 2.1.x installed successfully.`

Verify:

```powershell
claude --version
```

**Alternative: WinGet.** No auto-updates, but cleanly integrated with Windows package management:

```powershell
winget install Anthropic.ClaudeCode
```

### Step 2.4: Do I still need WSL2? (short answer: no)

**Native Windows is the recommended path in 2026.** WSL2 is only worth it if you specifically need: (a) Linux-only developer toolchains, or (b) sandboxed command execution (a Claude Code safety feature only available under WSL2). For normal consulting work — documents, spreadsheets, MCP tools, plugins — native Windows works perfectly.

If your firm mandates WSL2, install Ubuntu from the Microsoft Store, open it, and run the **Linux** install command (`curl -fsSL https://claude.ai/install.sh | bash`) inside the WSL shell.

### Step 2.5: Fix PowerShell execution policy (if needed)

If the install script fails with "running scripts is disabled on this system," run this once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Then rerun Step 2.3.

---

## Part 3 — Authenticate with your Claude Max subscription

The first time you launch Claude Code it opens a browser to sign you in. Your Max plan's usage pool is shared across **claude.ai, Claude Desktop, and Claude Code** — one subscription, one quota.

### Step 3.1: Start Claude Code

From Terminal (macOS) or Windows Terminal (Windows):

```bash
claude
```

A browser window opens automatically. If it doesn't, **press `c` in the terminal** to copy the login URL to your clipboard, then paste it into any browser.

### Step 3.2: Complete the browser login

1. Sign in with the **same email and password** you use at [claude.ai](https://claude.ai).
2. On the authorization screen, choose **"Claude account with subscription"** (not API credits).
3. Click **Authorize**.
4. The browser shows a success message. Return to your terminal and press **Enter** to continue past the security notes.

If the browser displays a login **code** instead of redirecting, copy that code and paste it at the terminal's `Paste code here if prompted` line.

### Step 3.3: Verify you're signed in correctly

At the Claude Code prompt, type:

```
/status
```

You should see your email, your organization (if any), and **auth method: subscription** (or similar wording). If it says "API key," your `ANTHROPIC_API_KEY` environment variable is overriding your subscription — see [troubleshooting](#authentication-failures) below.

### Max vs Pro — what it means for Claude Code

Your Max plan gets you the same Claude Code experience as Pro, but with far more usage headroom. Both Max tiers include **priority access** to new models.

| | Pro ($20) | Max 5x ($100) | Max 20x ($200) |
|---|---|---|---|
| Usage per 5-hour window | 1x baseline | **5× Pro** | **20× Pro** |
| Weekly limits | Lower | Higher | Highest |
| Separate Sonnet + Opus weekly caps | No | Yes | Yes |
| Claude Code included | ✓ | ✓ | ✓ |

Anthropic doesn't publish hard message counts — limits are framed as multipliers of Pro. You'll see a 5-hour rolling window that resets from your first message, plus weekly caps (one for Sonnet, one for Opus on Max). Monitor with `/status` or `/usage` inside Claude Code.

**If you hit a limit,** you can wait for the reset, enable pay-as-you-go top-ups in your account, or upgrade from Max 5x to Max 20x. Max 20x is the typical choice for consultants running Claude Code heavily across multiple client engagements.

---

## Part 4 — Set up the plugin ecosystem

Plugins extend Claude Code with commands, sub-agents, skills, and bundled MCP servers. Anthropic's **official marketplace is pre-registered** — you get it for free. For the cogni-work plugins (your firm's custom toolkit), you need to add that marketplace manually.

### Step 4.1: Understand the two-step model

Claude Code separates **marketplaces** (catalogs that point to plugins) from **plugins** (the actual tools you install). You add a marketplace once, then install specific plugins from it.

### Step 4.2: Add the cogni-work marketplace

Inside Claude Code, run:

```
/plugin marketplace add <your-cogni-work-repo>
```

The `<your-cogni-work-repo>` value is whatever your firm distributes — typically a GitHub shorthand like `your-org/cogni-work-plugins`, a full HTTPS URL, or a local path. Examples of valid formats:

```
/plugin marketplace add your-org/cogni-work-plugins
/plugin marketplace add https://github.com/your-org/cogni-work-plugins.git
/plugin marketplace add git@github.com:your-org/cogni-work-plugins.git#v1.2.0
/plugin marketplace add ./cogni-work-plugins
```

Your firm's internal setup instructions specify the exact value — use what they provide verbatim.

Verify the add worked:

```
/plugin marketplace list
```

You should see `cogni-work` (or whatever name the marketplace declares) alongside the auto-registered `claude-plugins-official`.

### Step 4.3: Install the cogni plugins

Install plugins one at a time with the `name@marketplace` syntax. Assuming the marketplace name is `cogni-work`:

```
/plugin install cogni-portfolio@cogni-work
/plugin install cogni-narrative@cogni-work
/plugin install cogni-sales@cogni-work
/plugin install cogni-claims@cogni-work
/plugin install cogni-tips@cogni-work
/plugin install cogni-diamond@cogni-work
```

By default these install at **user scope** — available in every project on your machine. If you want a plugin scoped to just one client project (useful for `cogni-claims` on a litigation engagement, for example), `cd` into that project first and run:

```
/plugin install cogni-claims@cogni-work --scope project
```

Project scope writes to `.claude/settings.json` in the repo so your team gets the same plugin when they clone it.

### Step 4.4: Verify plugins loaded

Open the plugin panel:

```
/plugin
```

You'll see four tabs (**Discover**, **Installed**, **Marketplaces**, **Errors**). Check **Installed** — all six cogni plugins should be listed with green status. If any show in **Errors**, note the message and see [troubleshooting](#plugin-marketplace-or-plugin-errors).

Each plugin's commands are namespaced by plugin name. For example, `cogni-portfolio` might expose `/cogni-portfolio:summarize`, which you can tab-complete at the Claude Code prompt.

### Step 4.5: Managing plugins over time

Common commands you'll use later:

- `/plugin marketplace update cogni-work` — pull the latest catalog from your firm
- `/plugin update cogni-portfolio@cogni-work` — update one plugin
- `/plugin disable cogni-claims@cogni-work` — temporarily turn off a plugin
- `/plugin uninstall cogni-tips@cogni-work` — remove a plugin

Plugin files live in `~/.claude/plugins/cache/`. Persistent per-plugin data (notes, tokens, local state) lives in `~/.claude/plugins/data/<plugin-id>/` and survives updates.

---

## Part 5 — Configure MCP servers for consulting work

MCP (Model Context Protocol) servers let Claude Code read and write to external systems — your filesystem, Google Drive, Gmail, Microsoft 365, and drawing tools. Each server is a small adapter process that Claude Code launches when needed.

### Step 5.1: Where MCP config lives

Two places matter:

- **Project-scoped `.mcp.json`** — a JSON file at the root of a client project folder, checked into git so teammates share the same servers. This is the right place for client-specific connections.
- **User-scoped** (stored in `~/.claude.json` on all platforms) — servers available across every project on your machine. Good for personal tools like your own Google Drive.

You add servers either interactively via the `/mcp` command inside Claude Code, or from the shell via `claude mcp add`.

### Step 5.2: Add the Filesystem server (start here)

The **Filesystem** server is the official Anthropic reference MCP — it lets Claude Code read and edit files in specific directories you authorize. Recommended for every consultant.

**macOS / Linux:**

```bash
claude mcp add filesystem --scope user -- npx -y @modelcontextprotocol/server-filesystem "$HOME/Documents" "$HOME/Desktop"
```

**Windows (PowerShell):** use a `cmd /c` wrapper because npx on Windows needs it:

```powershell
claude mcp add filesystem --scope user -- cmd /c npx -y "@modelcontextprotocol/server-filesystem" "$env:USERPROFILE\Documents" "$env:USERPROFILE\Desktop"
```

Replace the paths with any directories you want Claude Code to access. **The server will only touch these directories** — everything else on your disk is off-limits.

### Step 5.3: Add Google Drive and Gmail

Google connections require a one-time OAuth setup. In Google Cloud Console ([console.cloud.google.com](https://console.cloud.google.com)):

1. Create a project (or use an existing one).
2. Enable the **Google Drive API** and **Gmail API** under "APIs & Services."
3. Under "OAuth consent screen," configure the app (internal if your firm uses Google Workspace).
4. Under "Credentials," create an **OAuth client ID** of type **Desktop app**, download the JSON as `gcp-oauth.keys.json`.

**Important context:** Anthropic's own Google Drive MCP reference server has been archived — maintained community forks are the current best option. For Gmail, there is no Anthropic-built server; most consultants use the `@gongrzhe/server-gmail-autoauth-mcp` community package. Both require your `gcp-oauth.keys.json`. Follow the installation instructions on the specific repo you choose and register the result with:

```bash
claude mcp add gmail --scope user -- npx -y @gongrzhe/server-gmail-autoauth-mcp
```

Tokens are stored in `~/.gmail-mcp/`. **Never commit these files to git.**

### Step 5.4: Add Microsoft 365 (Outlook, OneDrive, Teams)

The most capable community server is **Softeria's MS 365 MCP**, which uses Microsoft Graph to reach Outlook mail/calendar, OneDrive, SharePoint, and Teams. Register an app in **Entra ID → App Registrations** to get a client ID and tenant ID.

**macOS:**

```bash
claude mcp add ms365 --scope user -- npx -y @softeria/ms-365-mcp-server --org-mode
```

**Windows:**

```powershell
claude mcp add ms365 --scope user -- cmd /c npx -y "@softeria/ms-365-mcp-server" --org-mode
```

First-time login (once only):

```bash
npx @softeria/ms-365-mcp-server --login
```

This opens a device-code flow in your browser. If your firm has Microsoft 365 Copilot licensing, ask IT about Microsoft's pre-certified **Work IQ MCP servers** — those are the "official Microsoft" path but require enterprise setup through Microsoft's Agent 365 control plane.

### Step 5.5: Add Excalidraw for diagrams

Excalidraw is useful for whiteboard-style diagrams during strategy work. The community-maintained `yctimlin/mcp_excalidraw` offers a full canvas and works on both platforms via Docker:

```bash
docker run -d -p 3000:3000 --name mcp-excalidraw-canvas ghcr.io/yctimlin/mcp_excalidraw-canvas:latest

claude mcp add excalidraw --scope user -- docker run -i --rm -e EXPRESS_SERVER_URL=http://host.docker.internal:3000 -e ENABLE_CANVAS_SYNC=true ghcr.io/yctimlin/mcp_excalidraw:latest
```

If you prefer not to run Docker, the Excalidraw team has blessed `excalidraw/excalidraw-mcp` as an official alternative — check that repo for a simpler stdio-based install.

### Step 5.6: Example project-scoped `.mcp.json`

For a client engagement folder, create a `.mcp.json` at the project root so every teammate who clones the repo gets the same servers. A practical template:

```json
{
  "mcpServers": {
    "client-files": {
      "command": "npx",
      "args": [
        "-y", "@modelcontextprotocol/server-filesystem",
        "./deliverables", "./research"
      ]
    },
    "drive": {
      "command": "npx",
      "args": ["-y", "@gongrzhe/server-gmail-autoauth-mcp"]
    }
  }
}
```

When Claude Code opens a project with a `.mcp.json`, it prompts you to trust the file before launching any servers — review it first, especially for repos shared across the firm.

### Step 5.7: Verify MCP servers connected

Inside Claude Code:

```
/mcp
```

You'll see each server listed with its connection status. Green = connected and tools available. Red = failed to start (check `claude doctor` for diagnostics). For servers that need OAuth (most Google and Microsoft ones), the panel offers an "Authenticate" action that walks you through the browser flow.

---

## Part 6 — First-run verification

Run this sequence to confirm every layer works before you start real client work.

**Check the install:**

```bash
claude --version
claude doctor
```

`claude doctor` reports your install method, version, ripgrep status, MCP server health, and any config-vs-runtime mismatches. Treat any red flags here before continuing.

**Check auth:** at the Claude Code prompt, type `/status` and confirm **auth method: subscription** with your correct email.

**Check plugins:** type `/plugin` and visit the **Installed** tab. All six cogni plugins should be present with no errors.

**Check MCP servers:** type `/mcp`. Filesystem, Gmail, Drive, MS 365, and Excalidraw should show as connected (after completing each one's OAuth the first time).

**Hello world smoke test:** start a fresh Claude Code session in any folder and ask:

> *List the files in my Documents folder and summarize what types of documents are there.*

If Claude Code uses the filesystem tool to read your directory and returns a sensible summary, **everything is wired up correctly**.

---

## Troubleshooting common issues

### PATH and "command not found" issues

After a fresh install, close and reopen your terminal — PATH changes don't apply to already-open sessions. If `claude` is still not found:

- **macOS:** add the install directory to your shell config. For zsh (default):
  ```bash
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  ```
- **Windows PowerShell:**
  ```powershell
  [Environment]::SetEnvironmentVariable("Path", "$([Environment]::GetEnvironmentVariable('Path','User'));$env:USERPROFILE\.local\bin", "User")
  ```
  Then close and reopen Windows Terminal.

### Node version mismatches

You only hit this if you use the deprecated npm install path or run MCP servers that call `node` directly. Check with `node --version` — Claude Code and most MCP servers need **Node 18 or newer**. If you manage Node via `nvm`, MCP subprocesses may not find your Node version because they launch in non-interactive shells. Fix by using absolute paths to `node` in your `.mcp.json`'s `command` field, or install the native Claude Code binary which has zero Node dependency.

### Authentication failures

Most failures come from a stray `ANTHROPIC_API_KEY` environment variable overriding your subscription. Check with `echo $ANTHROPIC_API_KEY` (macOS) or `echo $env:ANTHROPIC_API_KEY` (Windows). If it's set and you want to use your Max subscription:

```bash
unset ANTHROPIC_API_KEY     # macOS
Remove-Item Env:\ANTHROPIC_API_KEY   # Windows
```

Then `/status` should show subscription auth. If your token genuinely expired, run `/logout` followed by `/login` to refresh.

On macOS, a locked Keychain can prevent credential storage — `claude doctor` flags this; unlock via Keychain Access.

### Plugin marketplace or plugin errors

- **"Marketplace not found":** verify the repo URL is correct and reachable. For private repos, make sure your git credentials are set up (`git clone` the repo manually first to confirm access).
- **"Unknown command /plugin":** your Claude Code is too old. Run `claude update` (native install) or reinstall via the one-liner.
- **Plugin loads but commands don't appear:** run `/reload-plugins`, or restart Claude Code.

### Windows-specific gotchas

- **Execution policy blocks scripts:** `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` (one-time fix).
- **MAX_PATH 260-character limit** breaks some MCP servers and plugins. Fix both pieces:
  ```powershell
  # In an admin PowerShell:
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
  ```
  ```bash
  git config --system core.longpaths true
  ```
  Reboot after the registry change.
- **Git line endings mangle scripts:** set `git config --global core.autocrlf true` on Windows and `input` on macOS. Better, commit a `.gitattributes` with `* text=auto eol=lf` so shell scripts stay LF-only.
- **MCP `npx` servers fail with "Connection closed":** wrap them with `cmd /c`, as shown in the examples above.

### The universal debug move

When anything is off and you don't know why, run:

```bash
claude doctor
```

It reports the install path, version channel, MCP server health, and any environment conflicts. Between `claude doctor` and the `/mcp`, `/plugin`, and `/status` panels, you can self-diagnose the vast majority of setup issues.

---

## What's next

You're now running Claude Code with your Max subscription, the full cogni-work plugin suite, and MCP servers reaching into your filesystem, email, drive, and diagrams. Two directions to take from here:

**Go deeper on plugins.** Each cogni plugin has its own command set — run `/plugin` and browse the **Installed** tab to see what each exposes. Tab-completion at the Claude Code prompt reveals commands like `/cogni-portfolio:*` or `/cogni-sales:*`. Your firm's internal docs should cover recommended workflows per plugin.

**Tune MCP per engagement.** For a new client project, create a project-scoped `.mcp.json` at the folder root with only the servers that engagement needs. This keeps context tight and prevents Claude Code from accidentally pulling data from unrelated clients. Commit the file to the project repo so your team shares the same setup.

Bookmark two pages for reference: [code.claude.com/docs](https://code.claude.com/docs/en/setup) for official Claude Code documentation, and your firm's internal cogni-work repo for plugin-specific guidance and marketplace updates.