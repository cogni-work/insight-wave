# Security Policy

## Supported Versions

Only the latest version of each plugin on the `main` branch is supported with security updates.

## Reporting a Vulnerability

If you discover a security vulnerability in any insight-wave plugin, please report it responsibly.

**Email:** [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai)

**Do not** open a public issue for security vulnerabilities.

### What to include

- Description of the vulnerability
- Steps to reproduce
- Affected plugin(s) and version(s)
- Potential impact

### Response timeline

- **Acknowledgment:** within 3 business days
- **Initial assessment:** within 7 business days
- **Fix or mitigation:** depends on severity, but critical issues are prioritized

### Scope

Security issues in insight-wave plugins include:

- Code that could execute unintended commands on the user's system
- Data exfiltration or unauthorized file access
- Prompt injection vulnerabilities in skill/agent definitions
- Dependencies with known vulnerabilities

Out of scope:

- Issues in upstream tools (Claude Code, Obsidian, Excalidraw) — report these to their respective maintainers
- Feature requests or non-security bugs — use [GitHub Issues](https://github.com/cogni-work/insight-wave/issues)

## Disclosure

We follow coordinated disclosure. Once a fix is available, we will credit the reporter (unless they prefer anonymity) in the release notes.
