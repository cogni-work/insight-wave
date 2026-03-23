# GitHub MCP Server — Configuration Templates

## gh CLI Method (Simplest)

Uses the GitHub CLI's built-in MCP server. Requires `gh` CLI v2.80+ with active
authentication (`gh auth login`). No PAT needed — reuses existing `gh` credentials.

```json
{
  "mcpServers": {
    "github": {
      "command": "gh",
      "args": [
        "mcp-server"
      ]
    }
  }
}
```

To upgrade gh: `brew upgrade gh` (macOS) or see https://cli.github.com/

## Docker Method

Uses the official GitHub MCP server Docker image. Requires Docker Desktop installed and running.

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_TOKEN>"
      }
    }
  }
}
```

## npx Method (Fallback)

Uses the MCP community server package via npx. Requires Node.js (v18+) installed.

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_TOKEN>"
      }
    }
  }
}
```

## Required GitHub PAT Scopes

When creating the Personal Access Token (classic), these scopes are needed:

| Scope | Purpose |
|-------|---------|
| `repo` | Full access to repositories (read/write issues, PRs, code) |
| `read:packages` | Read access to GitHub Packages |
| `read:org` | Read access to organization membership |

## GitHub Enterprise

For GitHub Enterprise Server, add the `GITHUB_HOST` environment variable:

```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_TOKEN>",
  "GITHUB_HOST": "github.your-company.com"
}
```

## Security Note

The PAT is stored in plaintext in the Claude Desktop config file. Treat this file as sensitive:
- Do not commit it to version control
- Restrict file permissions where possible
- Use a PAT with the minimum required scopes
- Rotate the token periodically
