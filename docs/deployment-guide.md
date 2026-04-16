# Deployment Guide

Enterprise deployment reference for Claude Code and Claude Cowork — security configuration, GDPR compliance, network setup, and operations.

> **Data last researched:** 2026-04-04 | **Sources:** 18 unique URLs
>
> If this guide is more than 90 days old, consider running `/doc-deploy` in the cogni-docs plugin to refresh the underlying data before relying on specific configuration values.

For the canonical plugin and workspace setup, see [Install to Infographic](workflows/install-to-infographic.md). This guide covers the infrastructure and compliance layer that sits underneath.

---

## Two Deployment Paths

| Path | Who it's for | Key differences |
|------|-------------|-----------------|
| **Claude Cowork** | Business users, analysts, project managers | Desktop app, visual interface, local file access, no CLI |
| **Claude Code** | Developers, power users, CI/CD pipelines | CLI + IDE extensions, sandboxed execution, full audit logging |

**Compliance note:** Cowork sessions are stored locally on each user's machine and do **not** appear in Enterprise audit logs or the Compliance API. If your organization requires compliance logging for all AI tool usage, use Claude Code for regulated workloads.

---

## Claude Cowork Deployment

Cowork is the standard path for most enterprise users — consultants, sales teams, marketing teams, and business professionals. It provides a visual interface with local file access and plugin support through Claude Desktop. No terminal required. Start here for the majority of your organization's workforce.

### Installation

Claude Desktop (which hosts Cowork) is available for macOS 11+ and Windows 10+. Cowork is available on Pro, Max, Team, and Enterprise paid plans. Linux is not supported.

1. Download from [claude.ai/download](https://claude.ai/download)
2. Install and launch
3. Sign in with your organizational account
4. Select the **Cowork** tab in the mode selector

Your computer must remain awake with Claude Desktop open during tasks. An active internet connection is required throughout sessions.

### Workspace Policies

Enterprise admins enable or disable Cowork organization-wide via **Organization settings > Capabilities**. The following policy settings are available:

- `secureVmFeaturesEnabled` — controls Cowork access (Boolean)
- `isDesktopExtensionEnabled` — controls extension access (Boolean, default true)
- `isDesktopExtensionDirectoryEnabled` — controls extension directory (Boolean, default true)
- `isLocalDevMcpEnabled` — controls local MCP server access (Boolean, default true)
- `isClaudeCodeForDesktopEnabled` — controls Claude Code Desktop integration (Boolean, default true)
- Standing instructions per project for standardized behavior
- Enterprise policies override in-app settings

For selective enablement (per team or per role), contact Anthropic Sales. Network egress permissions are respected; web search can be disabled separately. Custom data retention controls are available on Enterprise (minimum 30 days).

<details><summary>Sources</summary>

- https://support.claude.com/en/articles/13455879-use-cowork-on-team-and-enterprise-plans
- https://support.claude.com/en/articles/12622667-enterprise-configuration

</details>

### Plugins and MCP Server Configuration

Claude Desktop uses **Desktop Extensions** (`.mcpb` files) — bundled packages with an MCP server and all dependencies. A built-in Node.js runtime means no separate installation required.

To install extensions:
- Via **Settings > Extensions > Browse extensions**, or drag-and-drop a `.mcpb` file
- Enterprise: pre-install approved plugins via Group Policy (Windows) or MDM (macOS), block publishers, disable the public directory, or host a private directory

To configure MCP servers manually:
1. Open Claude Desktop settings and navigate to the MCP section
2. Follow the [local MCP server setup guide](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop)
3. For external service integration, configure [remote MCP connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)

Sensitive settings (API keys, tokens) are encrypted via OS keychain.

### Collaboration Features

Each project in Cowork maintains separate files, context, memory, and standing instructions. Standing instructions let teams standardize tone, output format, and domain context across sessions. The plugin marketplace provides pre-built integrations for common workflows.

<details><summary>Sources</summary>

- https://support.claude.com/en/articles/13345190-get-started-with-cowork
- https://support.claude.com/en/articles/13837440-use-plugins-in-cowork
- https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop
- https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp

</details>

---

## Claude Code Deployment

Claude Code is the specialist path for developers and power users who need CLI access, IDE integration, and CI/CD automation. It complements Cowork for teams that include both business users and developers.

### Installation Methods

| Method | Command | Auto-Updates |
|--------|---------|:------------:|
| **Native (recommended)** | `curl -fsSL https://claude.ai/install.sh \| bash` | Yes |
| **Native (Windows PS)** | `irm https://claude.ai/install.ps1 \| iex` | Yes |
| **Native (Windows CMD)** | `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd` | Yes |
| Homebrew | `brew install --cask claude-code` | No |
| WinGet | `winget install Anthropic.ClaudeCode` | No |

Requires macOS 13.0+, Windows 10 1809+, or Ubuntu 20.04+, 4 GB+ RAM, and a paid plan (Pro, Max, Team, Enterprise, or Console account). Post-install: run `claude --version` to verify and `claude doctor` to check configuration.

The npm method (`npm install -g @anthropic-ai/claude-code`) is **deprecated** — migrate to the native installer or Homebrew.

To pin a specific version: `curl -fsSL https://claude.ai/install.sh | bash -s <version>`

Binaries are code-signed: macOS binaries are signed by Anthropic PBC and notarized by Apple; Windows binaries are signed by Anthropic, PBC.

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/setup

</details>

### Enterprise Configuration

Claude Code uses a layered settings system. **Managed settings** (highest priority) are deployed by IT via MDM, Group Policy, or filesystem and cannot be overridden by users.

**Settings precedence** (highest to lowest): Managed > CLI args > Local > Project > User

**Managed settings locations:**
- macOS: `/Library/Application Support/ClaudeCode/` or MDM preference domain `com.anthropic.claudecode`
- Linux/WSL: `/etc/claude-code/`
- Windows: `C:\Program Files\ClaudeCode\` or Registry `HKLM\SOFTWARE\Policies\ClaudeCode`

**Key enterprise controls:**
- `autoUpdatesChannel`: `'latest'` (default) or `'stable'` (~1 week delayed, skipping regression releases)
- `disableAutoUpdates`: prevent auto-updates entirely (Boolean)
- `autoUpdaterEnforcementHours`: force-restart window for pending updates (1–72 hours)
- `forceLoginMethod`: restrict to `claudeai` or `console`
- `forceLoginOrgUUID`: restrict to a specific organization
- `availableModels`: restrict model selection
- `allowedMcpServers` / `deniedMcpServers`: control MCP server access
- `allowManagedHooksOnly`, `allowManagedMcpServersOnly`: lock down user overrides
- `apiKeyHelper`: script path for custom auth integration (rotating credentials from a vault)

You can also set `DISABLE_AUTOUPDATER=1` as an environment variable to disable auto-updates without deploying a managed settings file.

Binary integrity is verified via SHA256 checksums and GPG signatures. macOS binaries are Apple-notarized.

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/setup
- https://support.claude.com/en/articles/12622667-enterprise-configuration

</details>

### Team Deployment

Teams deploy via one of two paths:

- **Claude for Teams**: self-service subscription, centralized billing, admin tools — suited to smaller or lower-regulation teams
- **Claude for Enterprise**: SSO with domain capture, SCIM provisioning, compliance API, and managed policies — suited to regulated environments

To onboard via Claude for Teams or Enterprise:
1. Go to **Settings > Members** in the Console to bulk-invite users via email or SSO
2. Assign roles: `Claude Code` (Claude Code keys only) or `Developer` (any API key)
3. Distribute environment variables if using cloud provider paths (Bedrock, Vertex AI, Foundry)
4. Deploy managed settings via MDM or Group Policy to enforce consistent release channels

Teams share configuration via a committed `.claude/` directory:
- **`.claude/settings.json`**: shared permission rules, hooks, tool configs (committed)
- **`CLAUDE.md`**: project conventions (committed, advisory ~80% adherence)
- **`.claude/settings.local.json`**: personal overrides (auto-gitignored)

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/team
- https://code.claude.com/docs/en/setup

</details>

### IDE Integration

| IDE | Installation | Key features |
|-----|-------------|-------------|
| VS Code (1.98.0+) | Extensions marketplace | Inline diff review, @-mention files, parallel conversations, Plan mode |
| JetBrains IDEs | JetBrains Marketplace | CLI in IDE terminal, native diff viewer |
| Cursor | Extensions marketplace | Similar to VS Code integration |
| Claude Code Desktop | [claude.ai/download](https://code.claude.com/docs/en/desktop) | Graphical interface, no terminal required |

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/setup
- https://code.claude.com/docs/en/desktop

</details>

### CI/CD Integration

Claude Code supports non-interactive pipelines and hook-based automation.

- **Non-interactive mode**: `claude -p` runs a single prompt and exits — suitable for CI/CD pipelines
- **Hooks**: 24 lifecycle events including `PreToolUse`, `PostToolUse`, and `Stop`
  - `PreToolUse` hooks fire before permission checks and can block execution even in `bypassPermissions` mode
  - `PostToolUse` hooks for auto-formatting, logging, and quality checks
- **`apiKeyHelper`**: script path in settings that retrieves credentials from a vault at runtime
  - Set `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` to configure how frequently credentials are refreshed
- **`ANTHROPIC_AUTH_TOKEN`**: bearer token for LLM gateway or proxy authentication
- **Binary verification**: validate installs via the GPG-signed manifest with SHA256 checksums before deploying to CI runners

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/setup
- https://code.claude.com/docs/en/team

</details>

### Security and Sandboxing

Claude Code uses OS-level sandboxing for filesystem and network isolation:

- **Filesystem**: macOS Seatbelt, Linux bubblewrap — write access restricted to the working directory
- **Network**: domain-based proxy filtering
- **Command blocklist**: `curl`, `wget` blocked by default
- Sandbox reduces permission prompts significantly
- Prompt injection protections: context-aware analysis, input sanitization, isolated web fetch context
- **Fail-closed**: unmatched commands default to manual approval

---

## Security Configuration

### API Key Management

Store your API key in an environment variable or encrypted secret manager (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault) — never in code or version control. When you add a `.env` file to a project, add it to `.gitignore` immediately to prevent accidental commits.

Recommended practices:
- Use separate keys for development, testing, and production environments
- Rotate keys every 90 days
- Enable GitHub secret scanning — Anthropic's partnership with GitHub automatically deactivates any Claude API key that is pushed to a public repository
- Implement a Key Management System (KMS) for centralized control and audit trails
- Integrate secret scanning into CI/CD pipelines so leaked keys are caught before they reach the main branch
- If you suspect a key is compromised, revoke it immediately via the Claude Console and generate a new one
- Use the `apiKeyHelper` setting to retrieve rotating or short-lived credentials from a vault at runtime, so long-lived keys never sit in configuration files

Admin API keys (`sk-ant-admin...`) require the admin role and are separate from standard API keys. Keys are scoped to organizations, not individual users — they persist when users leave.

<details><summary>Sources</summary>

- https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure
- https://code.claude.com/docs/en/team

</details>

### Network Configuration

Claude Code requires the following endpoints to be allowlisted in your proxy and firewall rules:

**Required endpoints:**

| Endpoint | Purpose |
|----------|---------|
| `api.anthropic.com` | Claude API |
| `claude.ai` | Authentication (claude.ai accounts) |
| `platform.claude.com` | Authentication (Console accounts) |
| `storage.googleapis.com` | Binary downloads and auto-updater |
| `downloads.claude.ai` | Install scripts, manifests, signing keys, plugins |
| `statsig.anthropic.com` | Telemetry and metrics |

**Optional endpoints:**

| Endpoint | Purpose | Disable with |
|----------|---------|-------------|
| `statsig.anthropic.com` | Telemetry | `DISABLE_TELEMETRY=1` |
| `sentry.io` | Error reporting | `DISABLE_ERROR_REPORTING=1` |

**Proxy configuration:**

```bash
export HTTPS_PROXY=https://proxy.example.com:8080
export NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem
export CLAUDE_CODE_CLIENT_CERT=/path/to/client-cert.pem
export CLAUDE_CODE_CLIENT_KEY=/path/to/client-key.pem
```

SOCKS proxies are not supported. For NTLM or Kerberos proxy authentication, use an LLM Gateway — basic auth works directly via `HTTPS_PROXY`. For GitHub Enterprise Server behind a firewall, allowlist Anthropic API IP addresses.

Alternative providers (AWS Bedrock, Google Vertex AI, Microsoft Foundry) route through their own endpoints and do not require allowlisting `api.anthropic.com`.

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/network-config

</details>

### Authentication and SSO

Claude for Enterprise includes SSO with domain capture, SCIM for automated user provisioning, and role-based permissions.

Available authentication options:
- **Claude for Enterprise**: SSO with domain capture for centralized provisioning
- **SCIM**: automate user provisioning and access controls
- **Role-based permissions**: `Claude Code` role (Claude Code keys only) or `Developer` role (any API key)
- **Console SSO setup**: Settings > Members
- **Cloud provider authentication**: Amazon Bedrock, Google Vertex AI, Microsoft Foundry — these use environment variables instead of browser login
- **`apiKeyHelper`**: script for dynamic credential retrieval from a vault
- **SSO enforcement**: option to prevent non-SSO access when required

Authentication precedence (Claude Code): Cloud provider > `ANTHROPIC_AUTH_TOKEN` > `ANTHROPIC_API_KEY` > `apiKeyHelper` > OAuth subscription

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/team
- https://support.claude.com/en/articles/12622667-enterprise-configuration
- https://www.anthropic.com/enterprise

</details>

### Audit Logging

| Channel | What it captures | Plan |
|---------|-----------------|------|
| Enterprise audit logs | claude.ai and Claude Code activity | Enterprise |
| Compliance API | Programmatic access (NDA required) | Enterprise |
| OpenTelemetry | Metrics, events, traces | All Claude Code |
| Usage/Cost API | Token and cost tracking | All API |

OpenTelemetry metrics include `session.count`, `lines_of_code.count`, `cost.usage`, and `token.usage`. Supported exporters: OTLP, Prometheus, console. Prompt content is not logged by default — enable with `OTEL_LOG_USER_PROMPTS=1`.

**Important:** Cowork sessions are not captured in Enterprise audit logs or the Compliance API. If compliance logging is required for all AI activity, route regulated workloads through Claude Code.

<details><summary>Sources</summary>

- https://www.anthropic.com/enterprise
- https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure

</details>

### Data Handling

Data is encrypted in transit and at rest. For API and Enterprise customers, inputs and outputs are not used for model training. Commercial data (Team, Enterprise, API) is never used for model training unless the customer opts into the Development Partner Program.

| Data type | Retention |
|-----------|-----------|
| Standard API inputs/outputs | Auto-deleted within 30 days |
| Zero Data Retention (ZDR) | No storage after response |
| Enterprise UI (custom) | Minimum 30 days, configurable |
| Safety classifier results | Retained even under ZDR |
| Policy violation flags | Up to 2 years; safety scores up to 7 years |

Zero Data Retention is available per-organization via Anthropic Sales, subject to approval. ZDR does not apply to: Console/Workbench, consumer products, Batch API, Files API, Code Execution, or MCP Connector.

Claude Code credentials are stored in the encrypted macOS Keychain on macOS, or in a mode-0600 file on Linux and Windows.

Telemetry opt-out: set `DISABLE_TELEMETRY=1`, `DISABLE_ERROR_REPORTING=1`, or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`.

<details><summary>Sources</summary>

- https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data
- https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to
- https://code.claude.com/docs/en/team

</details>

---

## GDPR Compliance

GDPR compliance is a shared responsibility between Anthropic (as data processor for commercial customers) and the deploying organization (as data controller). The sections below cover what Anthropic provides. Your organization must also conduct its own Data Protection Impact Assessment (DPIA), establish a legal basis for processing, and notify employees when deploying Claude in workplace settings.

> **Does your Claude deployment process personal data?** If prompts or responses contain employee data, customer PII, or other personal data, GDPR applies. If Claude is used only for tasks without personal data (code generation, internal documentation), the sections below may not be relevant.

### Data Residency

The direct Anthropic API hosts data in the US by default. EU data transfers are governed by Standard Contractual Clauses (SCCs) included in the DPA — no separate negotiation is required for SCCs.

There is no dedicated EU inference endpoint in the direct Anthropic API at this time. For guaranteed EU data residency, use AWS Bedrock or Google Vertex AI with EU regional endpoints:

**AWS Bedrock EU regions** (use `eu.` prefix inference profiles):

| Region | Location |
|--------|----------|
| eu-central-1 | Frankfurt |
| eu-central-2 | Vienna |
| eu-west-1 | Ireland |
| eu-west-3 | Paris |

**Google Vertex AI** offers EU regions including Belgium, Frankfurt, Netherlands, Zurich, and Paris.

For specific EU data residency arrangements through the direct API, contact Anthropic Sales — options may be available on a case-by-case basis.

<details><summary>Sources</summary>

- https://privacy.claude.com/en/articles/10015887-what-is-your-approach-to-gdpr-or-related-issues
- https://privacy.claude.com/en/articles/7996862-i-am-a-commercial-customer-how-do-i-view-your-data-processing-addendum-dpa

</details>

### Data Processing Agreement (DPA)

Anthropic's DPA with Standard Contractual Clauses is **automatically incorporated** into the Commercial Terms of Service — no separate signing is required. It applies to commercial products (Claude for Work, Claude API) but not consumer products.

The DPA includes:
- EU Standard Contractual Clauses (SCCs): Module Two and Module Three
- UK International Data Transfer Addendum
- Swiss Data Protection Act addendum
- Sub-processor notice: 15 days advance, 10-day customer objection window
- Commitment to delete or return data within 30 days of contract termination

DPA: [anthropic.com/legal/data-processing-addendum](https://www.anthropic.com/legal/data-processing-addendum)

**Note:** If you access Claude through a third-party provider (Bedrock, Vertex AI), that provider's terms govern — not Anthropic's DPA directly.

<details><summary>Sources</summary>

- https://privacy.claude.com/en/articles/7996862-i-am-a-commercial-customer-how-do-i-view-your-data-processing-addendum-dpa

</details>

### Data Retention

For API users, inputs and outputs are automatically deleted within 30 days unless a special agreement exists. Enterprise customers can configure custom retention periods.

| Configuration | Retention |
|---------------|-----------|
| Default (API) | Auto-deleted within 30 days |
| Enterprise UI | Custom, minimum 30 days |
| Zero Data Retention | No storage after response (subject to approval) |
| Deleted conversations | Removed from backend within 30 days |

Zero data retention applies to eligible Anthropic APIs and products using a commercial organization API key, including Claude Code.

<details><summary>Sources</summary>

- https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data
- https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to
- https://privacy.claude.com/en/articles/10440198-custom-data-retention-controls-for-enterprise-plans

</details>

### Sub-Processors

Anthropic maintains a sub-processor list. Enterprise customers should request the current list via the Trust Center or Anthropic Sales. The DPA includes a 15-day advance notice mechanism for sub-processor changes, with a 10-day objection window for customers.

Trust Center: [trust.anthropic.com](https://trust.anthropic.com/)

### Data Subject Rights

For commercial products (Team, Enterprise, API): your organization is the **data controller** and Anthropic is the **data processor**. Anthropic forwards data subject access requests (DSARs) to the customer organization — you must implement your own DSAR process.

Available mechanisms:
- Self-service conversation deletion — removed from backend storage within 30 days
- Data subject requests via Anthropic support for consumer product users
- Enterprise organizations must establish their own DPIA and legal basis for processing

<details><summary>Sources</summary>

- https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data
- https://privacy.claude.com/en/articles/9267385-does-anthropic-act-as-a-data-processor-or-controller

</details>

### Compliance Certifications

| Certification | Status |
|---------------|--------|
| SOC 2 Type I | Completed |
| SOC 2 Type II | Completed |
| ISO 27001:2022 | Certified (Information Security Management) |
| ISO/IEC 42001:2023 | Certified (AI Management Systems) |
| HIPAA | BAA available |
| FedRAMP High | Met (via Vertex AI) |

Anthropic signed the EU GPAI Code of Practice (July 2025). Full EU AI Act enforcement begins August 2, 2026.

Certification documents are available at the [Anthropic Trust Center](https://trust.anthropic.com/).

<details><summary>Sources</summary>

- https://trust.anthropic.com/
- https://www.anthropic.com/news/anthropic-achieves-iso-42001-certification-for-responsible-ai

</details>

---

## Operations and Monitoring

### Monitoring

Monitor usage and API activity through the Claude Console. For programmatic access, use the Usage API (5-minute freshness) and Cost API (daily tracking).

| Tool | Purpose | Setup |
|------|---------|-------|
| Claude Console | Review logs and usage patterns | No setup required |
| OpenTelemetry | Metrics, events, traces | Configure exporters in settings |
| Usage API | Token tracking | `/v1/organizations/usage_report/messages` |
| Cost API | Daily cost tracking | `/v1/organizations/cost_report` |
| Compliance API | Programmatic audit data access (Enterprise) | NDA required |
| Partner integrations | CloudZero, Datadog, Grafana, Honeycomb, Vantage | Supported natively |

<details><summary>Sources</summary>

- https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure
- https://www.anthropic.com/enterprise

</details>

### Rate Limits

Rate limits vary by plan tier. Enterprise customers can negotiate custom limits.

- Custom Rate Limit API for setting organization-specific usage and spend safeguards
- Standard Rate Limit API with auto-reload and configurable thresholds
- Claude Code access requires a Pro, Max, Team, Enterprise, or Console account

For current limits per tier, see [Anthropic's documentation](https://docs.anthropic.com/).

<details><summary>Sources</summary>

- https://www.anthropic.com/enterprise

</details>

### Update Management

Native Claude Code installations auto-update in the background. Two release channels are available:

- **`latest`** (default): immediate updates as released
- **`stable`**: ~1 week delay, skipping regression releases — recommended for enterprise stability

Configure the release channel in settings.json:

```json
{ "autoUpdatesChannel": "stable" }
```

Disable auto-updates entirely:

```json
{ "env": { "DISABLE_AUTOUPDATER": "1" } }
```

To enforce an update window (force restart within N hours): set `autoUpdaterEnforcementHours` (1–72) in managed settings.

Homebrew (`brew upgrade claude-code`) and WinGet (`winget upgrade Anthropic.ClaudeCode`) require manual updates.

Allowlist `storage.googleapis.com` and `downloads.claude.ai` for the auto-updater to function behind a firewall.

<details><summary>Sources</summary>

- https://code.claude.com/docs/en/setup

</details>

### Cost Management

Use the Claude Console to monitor usage and set spend limits. The Custom Rate Limit API adds budget safeguards.

- **Spend caps**: set at the organizational and individual user levels (Enterprise)
- **Separate API keys per environment**: use distinct keys for dev/test/prod for granular cost attribution
- **Multi-team allocation**: use `OTEL_RESOURCE_ATTRIBUTES` for department or cost-center segmentation
- **Usage filtering**: filter by API key, workspace, or model for chargeback
- **Auto-reload thresholds**: configure to prevent unexpected charges
- Enterprise billing is centralized with per-seat pricing

For current rates, see the [Anthropic pricing page](https://www.anthropic.com/pricing) — pricing changes frequently and is not listed in this guide.

<details><summary>Sources</summary>

- https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure
- https://www.anthropic.com/enterprise

</details>

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `SELF_SIGNED_CERT_IN_CHAIN` | Set `NODE_EXTRA_CA_CERTS` to your corporate CA bundle path |
| NTLM/Kerberos proxy auth fails | Use an LLM Gateway; basic auth works via `HTTPS_PROXY` |
| Auto-updater blocked by firewall | Allowlist `storage.googleapis.com` and `downloads.claude.ai` |
| General installation issues | Run `claude doctor` |
| Check active settings sources | Run `/status` inside Claude Code |
| Suspected key compromise | Revoke immediately in Claude Console; generate a new key |

---

## Further Reading

- [Install to Infographic](workflows/install-to-infographic.md) — workspace and plugin setup
- [Ecosystem Overview](ecosystem-overview.md) — how the plugins fit together
- [cogni-workspace plugin guide](plugin-guide/cogni-workspace.md) — workspace initialization details
- [Anthropic documentation](https://docs.anthropic.com/)
- [Claude Code setup](https://code.claude.com/docs/en/setup)
- [Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-cowork)
- [Anthropic Trust Center](https://trust.anthropic.com/)
- [Anthropic Privacy](https://www.anthropic.com/privacy)
