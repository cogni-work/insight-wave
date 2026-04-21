# Deployment Guide

Enterprise deployment reference for Claude Code and Claude Cowork — security configuration, GDPR compliance, network setup, and operations.

> **Data last researched:** 2026-04-16 | **Sources:** 23 unique URLs
>
> If this guide is more than 90 days old, consider running `/doc-deploy` in the cogni-docs plugin to refresh the underlying data before relying on specific configuration values.

For the canonical plugin and workspace setup, see [Install to Infographic](workflows/install-to-infographic.md). This guide covers the infrastructure and compliance layer that sits underneath.

## Table of Contents

- [Claude Code — Default Deployment (Recommended for insight-wave)](#claude-code--default-deployment-recommended-for-insight-wave)
  - [New to terminals?](#new-to-terminals)
  - [Install on macOS](#install-on-macos)
  - [Install on Windows](#install-on-windows)
  - [Sign in with Claude Max](#sign-in-with-claude-max)
  - [Install the insight-wave plugins](#install-the-insight-wave-plugins)
  - [Turn on MCP servers](#turn-on-mcp-servers)
  - [Troubleshooting](#troubleshooting)
  - [Enterprise Configuration](#enterprise-configuration)
  - [Team Deployment](#team-deployment)
  - [IDE Integration](#ide-integration)
  - [CI/CD Integration](#cicd-integration)
- [Claude Cowork — Secondary Deployment (Limited for insight-wave)](#claude-cowork--secondary-deployment-limited-for-insight-wave)
  - [Installation](#installation)
  - [Workspace Policies](#workspace-policies)
  - [Collaboration Features](#collaboration-features)
  - [MCP Server Configuration](#mcp-server-configuration)
- [Security Configuration](#security-configuration)
  - [API Key Management](#api-key-management)
  - [Network Configuration](#network-configuration)
  - [Authentication & SSO](#authentication--sso)
  - [Audit Logging](#audit-logging)
  - [Data Handling](#data-handling)
- [GDPR Compliance](#gdpr-compliance)
  - [Data Residency](#data-residency)
  - [Data Processing Agreement (DPA)](#data-processing-agreement-dpa)
  - [Data Retention](#data-retention)
  - [Sub-Processors](#sub-processors)
  - [Data Subject Rights](#data-subject-rights)
  - [Compliance Certifications](#compliance-certifications)
- [Operations & Monitoring](#operations--monitoring)
  - [Monitoring](#monitoring)
  - [Rate Limits](#rate-limits)
  - [Update Management](#update-management)
  - [Cost Management](#cost-management)

## Claude Code — Default Deployment (Recommended for insight-wave)

### New to terminals?

A terminal is a built-in app on your laptop that lets Claude Code run locally. You don't write any code — you just paste one command, wait for it to finish, then paste the next one. The installation below is a one-time setup. After that, you type `claude` whenever you want to work.

Every step tells you what to paste and what you should see on screen. If something doesn't look right, the fallback line at the end of the step tells you what to try. You can always paste any error message back into Claude and ask "what does this mean?" — that's the fastest way to get unstuck.

**Why Claude Code and not Cowork?** Insight-wave workflows are long — deep research, narrative pipelines, and trend reports routinely need more context than Cowork's 200K-token limit. Claude Code desktop runs on 1M-context Opus and does not compress mid-session. Claude Code also renders editorial infographics via Pencil MCP at client-grade fidelity, which Cowork currently does not.

### Install on macOS

1. **Open the Terminal app.** Press `Cmd + Space`, type `Terminal`, press Enter. A window with a blinking cursor opens.
2. **Paste the install command and press Enter:**

   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

   **What you'll see:** a short progress log, then a final line that looks like `Claude installed to /Users/you/.local/bin/claude`. The whole thing usually takes under a minute.

3. **If your team standardizes on Homebrew**, you can use this instead — same result:

   ```bash
   brew install --cask claude-code
   ```

   Homebrew updates are manual (`brew upgrade claude-code`) — you lose auto-update from the native installer.

4. **If this doesn't work:** close and reopen the Terminal window, then paste the command again. If it still fails with an SSL or network error, your company firewall may be blocking the download — see the [Troubleshooting](#troubleshooting) table below.

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup)

### Install on Windows

1. **Open Windows Terminal.** Press the Windows key, type `Terminal`, press Enter. If Windows Terminal isn't installed, you can install it from the Microsoft Store first (free).
2. **Paste the install command and press Enter:**

   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```

   **What you'll see:** a short progress log, then a final line confirming `Claude installed to %USERPROFILE%\.local\bin\`. The whole thing usually takes under a minute.

3. **If the install fails with "cannot be loaded because running scripts is disabled":** this is one-time setup your laptop may need before Claude can run. Paste this line, press Enter, then re-run the install command from step 2:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

   This only affects your user account, not your whole laptop.

4. **If your team uses WinGet**, you can use this instead:

   ```powershell
   winget install Anthropic.ClaudeCode
   ```

   WinGet updates are manual (`winget upgrade Anthropic.ClaudeCode`).

5. **If this still doesn't work:** close and reopen Windows Terminal. If the install script fails with an SSL or proxy error, your company firewall may be blocking the download — ask your IT team to allowlist `claude.ai`, `downloads.claude.ai`, `storage.googleapis.com`, and `api.anthropic.com`.

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup)

### Sign in with Claude Max

1. **In the terminal, type `claude` and press Enter.** A browser tab opens at claude.ai.
2. **Sign in with your work email.** When prompted, choose **"Claude account with subscription"** (Max or Pro). This ties Claude Code to the same quota as claude.ai and Claude Desktop — you don't pay twice.
3. **Return to the terminal and paste `/status`.**

   **What you'll see:** a small report with your account email, the model in use, and a line that reads `auth method: subscription`. If you see `auth method: subscription`, you're done.

4. **If you see `auth method: API key` instead:** an old API key environment variable on your laptop is overriding your subscription. Paste `/logout` to sign out, then paste `/login` to sign back in. If that doesn't fix it, ask your IT team — they may have set `ANTHROPIC_API_KEY` on your laptop for an earlier project.

**Which subscription tier?** For heavy insight-wave workloads — deep research, multi-agent narrative pipelines, trend reports — Claude Max 20x is the recommended tier. Max 5x works for mixed use; Pro (1x) works for occasional use. All three tiers include Claude Code.

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup), [Installing Claude Desktop](https://support.claude.com/en/articles/10065433-installing-claude-desktop)

### Install the insight-wave plugins

Plugins give Claude the tools to do insight-wave work — building portfolios, writing narratives, scouting trends, and so on. Installing is a two-step process: register the marketplace once, then install the plugins you want.

1. **Register the insight-wave marketplace** (paste in the terminal, press Enter):

   ```
   /plugin marketplace add cogni-work/insight-wave
   ```

   **What you'll see:** a confirmation message that the marketplace was added.

2. **Install the core plugins you need.** Start with these three:

   ```
   /plugin install cogni-workspace@insight-wave
   /plugin install cogni-portfolio@insight-wave
   /plugin install cogni-visual@insight-wave
   ```

   Paste them one at a time, waiting for each to finish. Each install takes 5–15 seconds.

3. **Browse everything available** by pasting `/plugin` and pressing Enter — a menu shows every plugin in the marketplace with a short description. Install others as you need them (cogni-narrative, cogni-sales, cogni-trends, cogni-research, cogni-consulting, cogni-claims, cogni-marketing, cogni-wiki, cogni-website).

4. **If this doesn't work:** the most common cause is that Claude Code lost its internet connection. Close and reopen the terminal, then re-run `/plugin marketplace add`. If the marketplace URL says "not reachable," ask your IT team to allowlist `github.com` and `raw.githubusercontent.com`.

Sources: [Discover and install plugins](https://code.claude.com/docs/en/discover-plugins)

### Turn on MCP servers

MCP servers are small helper programs that let Claude see your files, your email, and your design tools. Insight-wave needs three of them: **Pencil** (for editorial infographics), **Excalidraw** (for hand-drawn diagrams and sketchnotes), and **claude-in-chrome** (for reading live websites during research and theme extraction). Cogni-workspace has a one-shot command that installs all three.

1. **Run the cogni-workspace installer** (paste in the terminal):

   ```
   /install-mcp
   ```

   **What you'll see:** a checklist of MCP servers being installed one by one, with a progress line for each. The whole thing usually takes 2–3 minutes.

2. **Verify the MCP servers are running** by pasting:

   ```
   /mcp
   ```

   **What you'll see:** a list of MCP servers with a green dot next to each one. Green means connected. A red dot means the server is registered but not running — usually a restart fixes it.

3. **Optional — consulting email and cloud drive MCPs.** If you want Claude to read your Gmail, Google Drive, or Microsoft 365 (Outlook, OneDrive, Teams) during consulting work, those are separate installs. The Gmail and Drive MCPs need your Google Cloud admin to create an OAuth client first. Microsoft 365 uses a simpler device-code login. For either one, your IT team is the right first stop — they will already have the admin console access you need.

4. **Excalidraw needs Docker Desktop.** If the Excalidraw MCP fails to install, the cause is usually that Docker Desktop isn't installed yet. Your IT team can help — Docker Desktop is a standard install on most engineering laptops.

5. **If this still doesn't work:** close the terminal and reopen it — some MCP servers only register on fresh startup. If the problem persists, paste `claude doctor` into the terminal and send the output to your IT team.

Sources: [Claude Code MCP docs](https://code.claude.com/docs/en/mcp), [Model Context Protocol servers](https://github.com/modelcontextprotocol/servers), [Gmail MCP server](https://github.com/GongRzhe/Gmail-MCP-Server), [Microsoft 365 MCP server](https://github.com/softeria/ms-365-mcp-server), [Filesystem MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem)

### Troubleshooting

Run `claude doctor` first — it is the universal diagnostic. It reports your install method, Claude Code version, whether ripgrep is present, and the health of every MCP server you've configured. For a first-time-user issue, paste its output to your IT team or back into Claude with the question "what does this mean?".

| What you see | What it means | What to do |
|--------------|---------------|------------|
| `command not found: claude` after install | Your terminal hasn't picked up the new install location yet | Close and reopen the terminal window. If still failing, restart the laptop. |
| Install script fails with SSL certificate or proxy timeout | Corporate proxy or firewall is blocking the download | Ask IT to allowlist `claude.ai`, `downloads.claude.ai`, `storage.googleapis.com`, and `api.anthropic.com` |
| Browser tab for sign-in never loads after running `claude` | Firewall is blocking the claude.ai redirect, or your default browser is misconfigured | Check that claude.ai is reachable from your browser manually. If still blocked, paste `claude --no-browser` and copy the printed URL to a different browser. |
| Windows install fails with "cannot be loaded because running scripts is disabled" | PowerShell execution policy is restricted (one-time setup your laptop needs) | Run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` once, then re-run the installer |
| `/status` shows "auth method: API key" instead of "subscription" | An old API key on your laptop is overriding your subscription | Paste `/logout`, then `/login`. If that doesn't work, ask IT to unset `ANTHROPIC_API_KEY`. |
| An MCP server that uses npx fails silently on Windows | Windows needs a small wrapper around npx for MCP processes to launch | Ask your IT team — they'll edit the MCP config to add a `cmd /c` wrapper. This is a known Windows quirk. |
| Long file path errors on Windows during plugin install | Windows limits file paths to 260 characters by default | Ask your IT team to enable long-path support. One-time fix. |

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup), [Network Configuration](https://code.claude.com/docs/en/network-config)

### Enterprise Configuration

Enterprise deployments can enforce organization-wide settings via managed settings, control release channels (`latest` vs `stable` — ~1 week delayed), and disable auto-updates. Windows supports Group Policy and Intune deployment. macOS supports MDM configuration profiles (Jamf Pro, Kandji, Intune).

- `autoUpdatesChannel`: `latest` (default) or `stable` (~1 week delayed)
- `DISABLE_AUTOUPDATER=1` to disable auto-updates entirely
- `disableAutoUpdates` (enterprise policy, Boolean)
- `autoUpdaterEnforcementHours` (1–72 hours, force restart window)
- `isDesktopExtensionEnabled`, `isDesktopExtensionDirectoryEnabled` (Boolean, default true)
- `isLocalDevMcpEnabled` (Boolean, default true — controls local MCP server access)
- `isClaudeCodeForDesktopEnabled` (Boolean, default true)
- `secureVmFeaturesEnabled` (Boolean, default true — controls Cowork access)
- Enterprise policy controls override in-app allowlist

Key config files:
- `~/.claude/settings.json` (user settings)
- `.claude/settings.json` (project settings)
- Managed settings via MDM (macOS) or Group Policy/Intune (Windows)

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup), [Enterprise Configuration](https://support.claude.com/en/articles/12622667-enterprise-configuration)

### Team Deployment

- Claude for Teams: self-service subscription, centralized billing, admin tools
- Claude for Enterprise: SSO, domain capture, SCIM, compliance API, managed policies
- Console authentication: bulk invite via Settings → Members, SSO setup
- Console roles: "Claude Code" (Claude Code keys only) or "Developer" (any API key)
- Cloud provider path: distribute environment variables for Bedrock/Vertex/Foundry credentials
- Managed settings enforce consistent release channels and configurations org-wide
- Binary integrity verification via signed manifest with Anthropic GPG key

Sources: [Team authentication](https://code.claude.com/docs/en/team), [Claude Code Setup](https://code.claude.com/docs/en/setup)

### IDE Integration

- VS Code (extension)
- JetBrains IDEs (plugin)
- Claude Code Desktop app (macOS, Windows) — graphical interface, no terminal required after install

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup), [Claude Code Desktop](https://code.claude.com/docs/en/desktop)

### CI/CD Integration

- Non-interactive mode: `claude -p` for CI/CD pipelines
- Hooks for pre/post-tool-use automation
- `apiKeyHelper` for vault-based credential retrieval
- `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` for custom refresh intervals
- `ANTHROPIC_AUTH_TOKEN` for LLM gateway/proxy bearer authentication
- Binary verification via GPG-signed manifest with SHA256 checksums

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup), [Team authentication](https://code.claude.com/docs/en/team)

---

## Claude Cowork — Secondary Deployment (Limited for insight-wave)

> **Compliance note**: Cowork sessions are stored locally on each user's machine. Activity does not appear in Enterprise audit logs or the Compliance API. If your organization requires compliance logging for all AI tool usage, use Claude Code for regulated workloads instead.

> **Not production-ready for insight-wave**: (1) Cowork's ~200K context window triggers frequent mid-session compressions during insight-wave's long multi-agent workflows (deep research, narrative pipelines, trend reports), which silently drops context downstream skills depend on. (2) Pencil MCP renders at lower visual fidelity in Cowork than in Claude Code desktop, which blocks client-grade editorial infographic, storyboard, and web outputs. Use Claude Code desktop (1M-context Opus) for any insight-wave work. We'll update this guidance when Cowork is ready to be the primary interface for insight-wave.

Cowork remains useful for lighter, text-only tasks that fit inside the 200K-token limit and don't require Pencil MCP output. Examples:
- Summarize a folder of meeting notes into an executive brief
- Create a formatted Excel report from raw CSV data
- Draft a client proposal using your template and project notes

### Installation

- Download Claude Desktop from [claude.ai/download](https://claude.ai/download) (macOS, Windows)
- Switch to Cowork mode via the mode selector (Chat → Cowork/Tasks)
- Requires paid plan (Pro, Max, Team, Enterprise)
- Requires active internet connection throughout sessions

Sources: [Getting Started with Cowork](https://support.claude.com/en/articles/13345190-get-started-with-cowork), [Installing Claude Desktop](https://support.claude.com/en/articles/10065433-installing-claude-desktop)

### Workspace Policies

Enterprise admins control Cowork availability and behavior org-wide:

- Cowork toggle: Organization settings → Capabilities (Enterprise/Team owners)
- `secureVmFeaturesEnabled` enterprise policy controls Cowork access
- `isLocalDevMcpEnabled` controls local MCP server access
- `isDesktopExtensionEnabled` controls extension access
- Standing instructions per project for standardized behavior
- Enterprise policies override in-app settings

Sources: [Cowork on Enterprise](https://support.claude.com/en/articles/13455879-use-cowork-on-team-and-enterprise-plans), [Enterprise Configuration](https://support.claude.com/en/articles/12622667-enterprise-configuration)

### Collaboration Features

- Collaborative working sessions with local file access
- Projects: group tasks with separate files, context, and memory
- Standing instructions per project for tone, format, and domain context
- Plugin support via marketplace integration
- Team and Enterprise plan sharing and management features

Sources: [Getting Started with Cowork](https://support.claude.com/en/articles/13345190-get-started-with-cowork), [Plugins in Cowork](https://support.claude.com/en/articles/13837440-use-plugins-in-cowork)

### MCP Server Configuration

- Configure MCP servers in Claude Desktop settings
- Follow: [Getting started with local MCP servers](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop)
- Custom connectors via remote MCP for external service integration
- Enterprise policy `isLocalDevMcpEnabled` controls local MCP access
- Plugin marketplace provides pre-built MCP integrations

Sources: [MCP in Desktop](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop), [Remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)

---

## Security Configuration

### API Key Management

Store API keys in environment variables or encrypted secret managers (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault) — never in code or version control. Rotate keys every 90 days, use separate keys for development/testing/production, and enable GitHub secret scanning which automatically deactivates exposed Claude API keys.

- Store keys in environment variables, not in code or configuration files
- Add `.env` files to `.gitignore` to prevent accidental commits
- Use encrypted secret storage in cloud environments
- Rotate API keys every 90 days
- Use separate keys for development, testing, and production environments
- Enable GitHub secret scanning — Anthropic partnership auto-deactivates exposed keys
- Implement a Key Management System (KMS) for centralized control and audit trails
- Integrate secret scanning into CI/CD pipelines before main branch pushes
- If a key is suspected compromised, revoke immediately via Claude Console
- Use the `apiKeyHelper` setting for dynamic or rotating credentials from a vault

Sources: [API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure), [Authentication](https://code.claude.com/docs/en/team)

### Network Configuration

Claude Code requires allowlisting specific Anthropic endpoints in proxy and firewall rules. Enterprise environments can route traffic through corporate proxies, trust custom Certificate Authorities, and authenticate with mutual TLS (mTLS) client certificates.

**Required endpoints:**

| Endpoint | Purpose |
|----------|---------|
| `api.anthropic.com` | Claude API |
| `claude.ai` | Authentication (claude.ai accounts) |
| `platform.claude.com` | Authentication (Console accounts) |
| `storage.googleapis.com` | Binary downloads and auto-updater |
| `downloads.claude.ai` | Install script, manifests, signing keys, plugins |
| `statsig.anthropic.com` | Telemetry and metrics |

**Proxy configuration:**

```bash
export HTTPS_PROXY=https://proxy.example.com:8080
export NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem
export CLAUDE_CODE_CLIENT_CERT=/path/to/client-cert.pem
export CLAUDE_CODE_CLIENT_KEY=/path/to/client-key.pem
```

Note: SOCKS proxies are not supported.

Sources: [Enterprise Network Configuration](https://code.claude.com/docs/en/network-config)

### Authentication & SSO

Claude for Enterprise includes SSO with domain capture, SCIM for automated user provisioning, and role-based permissions. Console-based authentication supports SSO setup and role assignment. Cloud provider authentication (Bedrock, Vertex AI, Foundry) uses environment variables instead of browser login.

- Claude for Enterprise: SSO with domain capture
- SCIM for automating user provisioning and access controls
- Role-based permissions (Claude Code role, Developer role)
- Console SSO setup via Settings → Members
- Cloud provider authentication: Amazon Bedrock, Google Vertex AI, Microsoft Foundry
- `apiKeyHelper` for dynamic credential scripts (vault integration)
- Authentication precedence: Cloud provider > ANTHROPIC_AUTH_TOKEN > ANTHROPIC_API_KEY > apiKeyHelper > OAuth

Sources: [Authentication](https://code.claude.com/docs/en/team), [Enterprise Configuration](https://support.claude.com/en/articles/12622667-enterprise-configuration), [Enterprise Plan](https://www.anthropic.com/enterprise)

### Audit Logging

Claude for Enterprise includes audit logs for security and compliance monitoring. The compliance API provides programmatic access to audit data.

- Audit logs available on Enterprise plan
- Compliance API for programmatic audit data access
- Usage monitoring via Claude Console
- Custom rate limits and spend limits as safeguards

Sources: [Enterprise Plan](https://www.anthropic.com/enterprise)

### Data Handling

Data is encrypted in transit and at rest. For API and Enterprise customers, inputs and outputs are not used for model training. Zero data retention is available for enterprise API customers where no inputs or outputs are stored except as required by law.

- Data encrypted in transit and at rest
- API and commercial inputs/outputs are NOT used for model training by default
- Consumer product training is opt-in only
- Zero data retention available for enterprise API customers (subject to approval)
- Claude Code credentials stored in encrypted macOS Keychain (macOS) or mode-0600 file (Linux/Windows)
- Safety-flagged content retained up to 2 years; safety scores up to 7 years

Sources: [Data Retention](https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data), [Zero Retention](https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to)

---

## GDPR Compliance

GDPR compliance is a shared responsibility between Anthropic (as data processor for commercial customers) and the deploying organization (as data controller). The sections below cover what Anthropic provides. Organizations must also conduct their own Data Protection Impact Assessment (DPIA) and establish a legal basis for processing.

### Data Residency

Standard Contractual Clauses (SCCs) are included in the DPA for lawful international data transfers. For specific EU data residency options, enterprise customers should contact Anthropic sales.

- US (default API hosting)
- EU data transfers governed by Standard Contractual Clauses in DPA

Sources: [GDPR Approach](https://privacy.claude.com/en/articles/10015887-what-is-your-approach-to-gdpr-or-related-issues), [DPA](https://privacy.claude.com/en/articles/7996862-i-am-a-commercial-customer-how-do-i-view-your-data-processing-addendum-dpa)

### Data Processing Agreement (DPA)

Anthropic's DPA with Standard Contractual Clauses is automatically incorporated into the Commercial Terms of Service — no separate signing is required. Applies to commercial products (Claude for Work, Claude API) but not consumer products.

DPA: [anthropic.com/legal/data-processing-addendum](https://www.anthropic.com/legal/data-processing-addendum)

Note: If you access Claude through a third-party provider (Bedrock, Vertex AI), that provider's terms govern.

Sources: [DPA Access](https://privacy.claude.com/en/articles/7996862-i-am-a-commercial-customer-how-do-i-view-your-data-processing-addendum-dpa)

### Data Retention

For API users, inputs and outputs are automatically deleted within 30 days unless a special agreement exists. Enterprise customers can configure custom retention periods (minimum 30 days). Zero data retention is available for enterprise API customers subject to approval.

- API inputs/outputs: auto-deleted within 30 days (default)
- Enterprise: custom data retention controls (minimum 30 days)
- Zero data retention: available for enterprise API (including Claude Code via commercial key)
- Deleted conversations removed from backend within 30 days

Sources: [Data Retention](https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data), [Zero Retention](https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to), [Custom Retention](https://privacy.claude.com/en/articles/10440198-custom-data-retention-controls-for-enterprise-plans)

### Sub-Processors

Anthropic maintains a sub-processor list. Enterprise customers should request the current list via the Trust Center or sales contact.

Trust Center: [trust.anthropic.com](https://trust.anthropic.com/)

Sources: [Trust Center](https://trust.anthropic.com/)

### Data Subject Rights

Users can delete conversations at any time — deleted data is removed from backend storage within 30 days. Anthropic acts as a data processor for commercial API customers (the customer is the controller) and as a controller for consumer product users.

- Self-service conversation deletion (removed from backend within 30 days)
- Data subject requests via Anthropic support
- Anthropic = data processor for commercial/API customers
- Anthropic = data controller for consumer product users
- **Organization responsibility**: implement DPIA, establish legal basis, notify employees when deploying Claude in workplace settings

Sources: [Data Retention](https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data), [Processor vs Controller](https://privacy.claude.com/en/articles/9267385-does-anthropic-act-as-a-data-processor-or-controller)

### Compliance Certifications

- SOC 2 Type I and Type II
- ISO 27001:2022 (Information Security Management)
- ISO/IEC 42001:2023 (AI Management Systems)
- HIPAA-ready (Business Associate Agreement available)

Certification documents available via [Anthropic Trust Center](https://trust.anthropic.com/).

Sources: [Trust Center](https://trust.anthropic.com/), [ISO 42001 Announcement](https://www.anthropic.com/news/anthropic-achieves-iso-42001-certification-for-responsible-ai)

---

## Operations & Monitoring

### Monitoring

- Claude Console: review logs and usage patterns
- Custom Rate Limit API: set usage and spend limits
- Compliance API (Enterprise): programmatic audit data access

Sources: [API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure), [Enterprise Plan](https://www.anthropic.com/enterprise)

### Rate Limits

- Rate limits vary by plan tier
- Custom Rate Limit API for organization-specific safeguards
- Enterprise customers can negotiate custom rate limits

Sources: [Enterprise Plan](https://www.anthropic.com/enterprise)

### Update Management

- Native installs auto-update in background
- Release channels: `latest` or `stable` (1 week delayed)
- Enforce channel via managed settings (enterprise)
- Pin specific version: `curl -fsSL https://claude.ai/install.sh | bash -s <version>`
- Binaries code-signed: macOS (Anthropic PBC, Apple notarized), Windows (Anthropic, PBC)
- Verify integrity via GPG-signed manifest with SHA256 checksums

Sources: [Claude Code Setup](https://code.claude.com/docs/en/setup)

### Cost Management

- Claude Console for usage monitoring and spend tracking
- Custom Rate Limit API for budget safeguards
- Separate API keys per environment for granular cost attribution
- Enterprise: centralized billing with per-seat pricing
- See [Anthropic pricing](https://www.anthropic.com/pricing) for current rates

Sources: [Enterprise Plan](https://www.anthropic.com/enterprise)
