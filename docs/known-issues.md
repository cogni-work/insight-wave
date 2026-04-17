# Known Issues Registry

> Last updated: 2026-04-17 | 1 open, 0 mitigated, 0 resolved

## Open Issues

<a id="ki-001"></a>

### KI-001: Chrome native messaging host conflict between Cowork and Claude Code (S2-major)

When both Claude Desktop (Cowork) and Claude Code are installed, they register competing native messaging host configurations for the Chrome extension using incompatible socket formats. The Chrome extension connects to one native host and ignores the other, causing 16 of 19 browser automation tools to silently vanish — with no error message surfaced to the user.

**Affected plugins:**

| Plugin | Skills | Feature | Impact |
|--------|--------|---------|--------|
| cogni-claims | claims | cobrowse | Browser-based claim source co-browsing unavailable when Claude Code's native host is active — claim verification falls back to web fetch only |
| cogni-help | cogni-issues | browser-based GitHub issue filing | Cannot file GitHub issues via browser automation — must use gh CLI or manual filing instead |
| cogni-visual | zone-reviewer | browser-based visual review | Browser-based zone review for rendered visuals may fail silently when tools are missing |
| cogni-workspace | manage-themes | website theme extraction via browser | Live website theme extraction requires browser automation — falls back to manual theme specification |

**Workaround:** Toggle native messaging host configs by renaming the .json file for the unused product and restarting Chrome.

1. To use Cowork's Chrome integration: rename `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json` to `.disabled`
2. To use Claude Code's Chrome integration: rename `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_browser_extension.json` to `.disabled`
3. Restart Chrome after switching — the extension reconnects to the remaining native host
4. On Windows: equivalent registry entries under `HKCU\Software\Google\Chrome\NativeMessagingHosts\`

Community shell function `chrome-mcp-toggle` automates the toggle. Trail of Bits published a troubleshooting Agent Skill (`trailofbits/skills/claude-in-chrome-troubleshooting`) for automated diagnosis.

**Related bugs:**
- Desktop auto-update tool regression: March 2026 update (v1.1.6679 to v1.1.8629) caused toolCount to drop from 19 to 3 on Windows (GitHub #38783, unresolved)
- Service worker idle disconnection: Chrome extension service worker sleeps during long sessions, severing the connection — reconnect via `/chrome` or restart extension
- Windows named pipe path omission: Claude Code v2.1.20+ `getSocketPaths()` returns only Unix-style paths, omitting Windows named pipe path (community one-line patch exists)
- Multiple Chrome installations: Chrome Canary present alongside Chrome causes browser tools to connect to Canary (which lacks the extension) — uninstall Canary to fix
- MCP tool approval non-persistence: Cowork "Always allow" choices for MCP tools reset at the start of every new session, requiring re-approval each time

**Sources:** `claude-in-chrome-trouble-shoot.md`

---

## Mitigated Issues

*None.*

## Resolved Issues

*None.*
