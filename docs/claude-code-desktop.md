<!--
Narrowed to platform install + authentication + verification + troubleshooting
only. Plugin ecosystem lives in docs/workflows/install-to-infographic.md.
Low-level MCP server setup lives in docs/deployment-guide.md. Do not re-inflate
without re-consolidation — see Install Surfaces Policy in
cogni-docs/skills/doc-hub/references/doc-templates.md.
-->

# Claude Code desktop installation guide for consultants

This guide gets you from zero to a working **Claude Code** setup — authenticated with your Claude Max subscription and ready to install the insight-wave plugin suite. It covers **macOS 13+** and **Windows 10 (1809+) / 11**, uses Anthropic's **native installer**, and flags the exact places where Mac and Windows steps diverge. Expect about **15 minutes** for a first-time setup; then jump to [From Install to Infographic](workflows/install-to-infographic.md) to add the insight-wave marketplace.

---

## Prerequisites checklist

Before starting, confirm you have each of the following.

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

- **iTerm2** (`brew install --cask iterm2`) — mature, scriptable, great for split panes.
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

### Step 2.4: Fix PowerShell execution policy (if needed)

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

## Part 4 — Verify your install

Run this short sequence to confirm Claude Code itself is healthy before you layer insight-wave on top.

```bash
claude --version
claude doctor
```

`claude doctor` reports your install method, version, ripgrep status, and any config-vs-runtime mismatches. Treat any red flags here before continuing.

Then at the Claude Code prompt, confirm authentication:

```
/status
```

You should see **auth method: subscription** with your correct email. If not, see the [Authentication failures](#authentication-failures) section below.

That's it for Claude Code itself. Plugin-level and MCP-level checks live in the insight-wave walkthrough — head there next.

---

<a name="plugin-ecosystem"></a>
<a name="mcp-servers"></a>

## Part 5 — Next: install insight-wave

Your Claude Code is ready. The plugin ecosystem and MCP servers for insight-wave are installed as one walkthrough — don't configure them à la carte.

**Continue here:** [From Install to Infographic](workflows/install-to-infographic.md) — the 15-minute first-run workflow that adds the insight-wave marketplace, installs the plugins you need, runs `/install-mcp` for Pencil + Excalidraw + claude-in-chrome, and renders your first infographic.

Why one walkthrough rather than separate plugin / MCP steps here? insight-wave ships `cogni-workspace` as the foundation layer (it sets up directories, themes, and MCP defaults), and `/install-mcp` handles all three MCP servers at once. Hand-running `claude mcp add` for each server works for generic Claude Code setups but conflicts with the insight-wave pattern. For enterprise-managed MCP configuration (MDM, allow-lists, managed settings), see [Deployment Guide](deployment-guide.md).

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

MCP servers that call `node` directly need **Node 18 or newer**. Check with `node --version`. Fix by pinning Node via absolute paths in MCP config, or by using MCP servers that don't require a local Node install.

### Authentication failures

Most failures come from a stray `ANTHROPIC_API_KEY` environment variable overriding your subscription. Check with `echo $ANTHROPIC_API_KEY` (macOS) or `echo $env:ANTHROPIC_API_KEY` (Windows). If it's set and you want to use your Max subscription:

```bash
unset ANTHROPIC_API_KEY     # macOS
Remove-Item Env:\ANTHROPIC_API_KEY   # Windows
```

Then `/status` should show subscription auth. If your token genuinely expired, run `/logout` followed by `/login` to refresh.

On macOS, a locked Keychain can prevent credential storage — `claude doctor` flags this; unlock via Keychain Access.

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

### The universal debug move

When anything is off and you don't know why, run:

```bash
claude doctor
```

It reports the install path, version channel, and any environment conflicts. Between `claude doctor` and the `/status` panel, you can self-diagnose the vast majority of Claude-Code-level setup issues. For plugin or MCP troubleshooting specific to insight-wave, see the troubleshooting table in [From Install to Infographic](workflows/install-to-infographic.md).
