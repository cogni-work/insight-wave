---
name: troubleshoot
description: >-
  Diagnose and fix common issues with insight-wave plugins. Use this skill whenever
  the user reports something broken, a skill not working, an error from a plugin,
  needs debugging help, or says things like "something is wrong", "plugin error",
  "skill not responding", "it doesn't work", "fix my setup", "diagnose this issue",
  "why isn't X working", or mentions any plugin malfunction. Also trigger when the
  user encounters unclear errors during plugin use — even if they don't explicitly
  ask for troubleshooting.
version: 0.1.0
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# troubleshoot: Plugin Diagnostics

Diagnose and resolve issues with insight-wave plugins. This complements
cogni-workspace's `workspace-status` skill, which checks infrastructure (env vars,
themes, settings). Troubleshoot focuses on plugin-level and cross-plugin problems.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Present diagnostic findings, explanations,
and fix instructions in that language (Problem → Cause → Fix stays as a pattern,
but the content within each section uses the workspace language).

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names, command names, file paths
- Status values (`OK`, `WARN`, `FAIL`)
- Error messages, stack traces, code snippets
- Column headers in diagnostic tables

## Scope Boundary

| This skill owns | cogni-workspace owns |
|-----------------|---------------------|
| Plugin availability and integrity | Workspace env vars and settings |
| Skill file validation | Theme installation and config |
| Cross-plugin dependency checks | Plugin discovery/registry |
| Progress/state file health | Session hooks and lifecycle |
| Stale state from renames | Dependency tool versions (node, gh, etc.) |

If the issue is clearly infrastructure (missing env var, broken theme), suggest
the user run `/workspace-status` instead.

## Diagnostic Flow

When a user reports a problem:

1. **Identify the scope** — is this about a specific plugin, a cross-plugin workflow,
   or something vague? Ask if unclear.

2. **Run targeted checks** based on what the user describes. Don't run everything
   every time — start with the most likely cause and expand if needed.

3. **Report findings clearly** — state what's wrong, why, and how to fix it. Use
   the format: Problem → Cause → Fix.

## Diagnostic Checks

### 1. Plugin Availability

Verify the plugin directory exists and has a valid plugin.json:

```bash
# Check plugin exists in marketplace
cat .claude-plugin/marketplace.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data['plugins']:
    print(f\"{p['name']}: {p['source']}\")
"
```

Then verify the source directory exists and contains `.claude-plugin/plugin.json`.

### 2. Skill File Integrity

For a named plugin, check that all skill directories contain a valid SKILL.md
with YAML frontmatter (at minimum: `name` and `description` fields):

```bash
# List all skills for a plugin
ls -d <plugin-dir>/skills/*/SKILL.md 2>/dev/null
```

Read each SKILL.md and verify the frontmatter parses correctly.

### 3. Progress/State File Health

Check `.claude/*.local.md` files for valid YAML frontmatter structure.
Common issues:
- Malformed YAML (missing closing `---`, bad indentation)
- Stale course IDs from renamed plugins
- Corrupted status values

For cogni-help specifically:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/course-status.sh" .
```

### 4. Cross-Plugin Dependencies

Many plugins require others to function. Check that dependencies are installed:

| Plugin | Requires |
|--------|----------|
| cogni-marketing | cogni-trends, cogni-portfolio |
| cogni-sales | cogni-portfolio, cogni-narrative |
| cogni-consulting | most other plugins |
| cogni-help:teach | all plugins (for exercises) |

Verify by checking if the required plugin directories exist in the marketplace.

### 5. Stale State Detection

After plugin renames, orphaned files may linger:

```bash
# Check for old cogni-teacher progress file
ls .claude/cogni-teacher.local.md 2>/dev/null

# Check for old cogni-diamond state
ls **/diamond-project.json 2>/dev/null
```

If found, suggest renaming to the current filename.

### 6. Common Misconfigurations

- **Missing COGNI_WORKSPACE_ROOT**: Many plugins need this env var. Check
  `.workspace-env.sh` exists and is sourced.
- **GitHub not logged in**: Required for cogni-issues. The skill uses browser
  automation — navigate to `https://github.com` and check login state.
- **Missing node/npm**: Required for PPTX generation (cogni-visual, course-deck).

## Full Scan Mode

When `/troubleshoot` is invoked with no argument, run all checks and present a
summary table:

| Check | Status | Details |
|-------|--------|---------|
| Marketplace | OK/WARN/FAIL | N plugins registered |
| Plugin integrity | OK/WARN/FAIL | Any missing SKILL.md files |
| State files | OK/WARN/FAIL | Any corrupted or stale files |
| Dependencies | OK/WARN/FAIL | Any missing cross-plugin deps |
| Environment | OK/WARN/FAIL | Key env vars and tools |

## Reference

See `references/known-issues.md` for a maintained list of known issues and their fixes.
