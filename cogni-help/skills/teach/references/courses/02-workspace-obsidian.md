# Course 2: Workspace & Obsidian Setup

**Duration**: 55 minutes | **Modules**: 6 | **Prerequisites**: Course 1
**Plugins**: cogni-workspace, cogni-help:cogni-issues
**Audience**: Consultants setting up their insight-wave environment

---

## Module 1: What is a insight-wave Workspace?

### Theory (3 min)

A insight-wave workspace is a shared foundation that enables all insight-wave plugins
to collaborate on projects. The **cogni-workspace** plugin orchestrates:

- **Environment variables** — Shared settings across plugins (project name, language, paths)
- **Theme management** — Visual consistency across all outputs (slides, documents, reports)
- **Plugin discovery** — Health monitoring and status of installed plugins
- **Workspace settings** — Centralized configuration

Think of it as the "operating system" for your insight-wave plugins. Without a
workspace, each plugin operates in isolation. With a workspace, they share context
and produce consistent, branded outputs.

**Convention-based zero-coupling**: Plugins don't depend on each other directly.
They follow shared conventions (file locations, naming, environment variables)
that the workspace establishes.

### Demo

Show the concept with a real example:
1. A consulting project folder with scattered files
2. After workspace init: organized structure with shared env, themes, and plugin awareness
3. How plugins discover each other through the workspace

### Exercise

Ask the user to:
1. Create a new folder for a sample consulting project (e.g., `~/Desktop/sample-project`)
2. Describe what they would want in a project workspace: project name, client name, output language

### Quiz

1. **Multiple choice**: What does cogni-workspace manage?
   - a) Code version control
   - b) Shared environment, themes, plugin discovery, and settings
   - c) Email and calendar
   - d) File backup and sync
   **Answer**: b

2. **Multiple choice**: Why is a workspace needed?
   - a) Plugins won't install without it
   - b) It enables plugins to share context and produce consistent outputs
   - c) It's required by Claude Desktop
   - d) It stores your login credentials
   **Answer**: b

### Recap

- Workspace = shared foundation for insight-wave plugins
- Manages env vars, themes, plugin discovery, settings
- Convention-based: plugins share patterns, not dependencies
- Required for cross-plugin consistency

---

## Module 2: Initializing a Workspace

### Theory (3 min)

Initialize a workspace by asking Claude: "Initialize a insight-wave workspace" or
"Set up my workspace." The cogni-workspace plugin handles the rest.

What gets created:
- `.workplace-env.sh` — Environment variables (project name, language, paths)
- Shared settings directory for plugin configuration
- Theme defaults for visual outputs

Key environment variables:
- `PROJECT_NAME` — Your project identifier
- `OUTPUT_LANG` — Default output language (en/de)
- `WORKSPACE_ROOT` — Base path for the project

The workspace status command checks health: which plugins are installed,
which are active, and if any configuration is missing.

### Demo

Walk through initializing a workspace:
1. Navigate to the sample project folder
2. Ask Claude: "Initialize a insight-wave workspace for a consulting project called 'Digital Strategy 2026'"
3. Show the created files and directory structure
4. Run workspace status to verify health

### Exercise

Ask the user to:
1. Initialize a workspace in their sample project folder
2. Set project name and output language
3. Run workspace status and review the output

Provide the prompt: "Initialize a insight-wave workspace here. Project name: 'My Training Project'. Language: English."

### Quiz

1. **Hands-on**: What files were created when you initialized your workspace? List them.

2. **Multiple choice**: What does `.workplace-env.sh` contain?
   - a) Plugin source code
   - b) Environment variables shared across plugins
   - c) User credentials
   - d) Log files
   **Answer**: b

### Recap

- Initialize with: "Initialize a insight-wave workspace"
- Creates `.workplace-env.sh` with shared env vars
- Check health with workspace status
- Foundation for all subsequent plugin work

---

## Module 3: Theme Management

### Theory (3 min)

Themes ensure visual consistency across all insight-wave outputs — presentations,
documents, reports, posters. The cogni-workspace theme system supports:

**Theme sources**:
- **Presets** — Built-in themes ready to use
- **Website extraction** — Extract colors, fonts, and style from a live website
- **PowerPoint templates** — Extract theme from existing .pptx files

**What a theme defines**:
- Primary, secondary, accent colors
- Typography (headings, body text, fonts)
- Layout preferences

**Applying themes**: Once set, all insight-wave plugins that produce visual
outputs (cogni-visual, cogni-narrative exports, etc.) use the workspace theme
automatically.

### Demo

Walk through theme management:
1. Show available preset themes
2. Demonstrate extracting a theme from a website (e.g., a client's website)
3. Show how the theme settings are stored
4. Explain how other plugins consume the theme

### Exercise

Ask the user to:
1. Ask Claude: "Show me available workspace themes"
2. Apply a preset theme to their workspace
3. Or if they have a client website URL, try: "Extract a theme from [URL]"

### Quiz

1. **Multiple choice**: From which sources can you extract a theme?
   - a) Only built-in presets
   - b) Presets, live websites, and PowerPoint templates
   - c) Only CSS files
   - d) Only PowerPoint templates
   **Answer**: b

2. **Hands-on**: What theme is currently active in your workspace?

### Recap

- Themes provide visual consistency across all outputs
- Three sources: presets, websites, PowerPoint templates
- Applied automatically to all visual-producing plugins
- Set once, used everywhere

---

## Module 4: Obsidian Integration

### Theory (3 min)

**cogni-workspace's Obsidian integration** bridges Obsidian (a popular knowledge management app) with
Claude Cowork. It creates an Obsidian vault pre-configured for insight-wave.

What it sets up:
- **Obsidian vault** with Terminal plugin integration
- **Terminal profiles** — Launch Claude Code directly from Obsidian
- **Tokyonight color scheme** for consistent visual experience
- **Workspace layout** — Multi-pane editor for effective navigation
- **15 core plugins** — Explorer, search, graph view, backlinks, etc.

Why this matters for consultants:
- Obsidian becomes your project dashboard
- All insight-wave outputs (narratives, reports, analyses) land in the vault
- Graph view shows relationships between documents
- Terminal integration lets you run insight-wave commands without leaving Obsidian

**Cross-platform**: Works on macOS, Linux, and Windows (WSL).

### Demo

Walk through Obsidian setup:
1. Show the command: "Set up an Obsidian vault for this project"
2. Explain the created `.obsidian/` directory and its contents
3. Show the Terminal plugin profiles
4. Demonstrate the workspace layout

### Exercise

Ask the user to:
1. If they have Obsidian installed: "Set up an Obsidian vault for my training project"
2. If not: review the structure that would be created and discuss how they currently manage project documents

### Quiz

1. **Multiple choice**: What does cogni-workspace's Obsidian integration set up?
   - a) A new email client
   - b) An Obsidian vault with Terminal plugin integration for Claude
   - c) A database for project data
   - d) A cloud storage system
   **Answer**: b

2. **Multiple choice**: Why integrate Obsidian with insight-wave?
   - a) Obsidian is required for plugins to work
   - b) It creates a project dashboard where all outputs land and are interconnected
   - c) It replaces Claude Desktop
   - d) It's needed for billing
   **Answer**: b

### Recap

- cogni-workspace's Obsidian integration creates pre-configured Obsidian vaults
- Terminal integration for running Claude from Obsidian
- All plugin outputs land in the vault
- Graph view shows document relationships

---

## Module 5: Note Management & Updating

### Theory (3 min)

**Note management**: cogni-workspace's Obsidian integration provides a standardized way to create notes
with YAML frontmatter (metadata). Every note gets:

```yaml
---
title: Meeting Notes Q1 Review
date: 2026-03-07
tags: [meeting, quarterly-review]
source: client-call
---
```

This frontmatter enables:
- Consistent metadata across all project notes
- Searchability by tags, date, source
- Integration with Obsidian's dataview and graph features

**Updating an existing vault**: Use "Update my Obsidian vault" to incrementally
update terminal configurations without overwriting your customizations. This is
useful when insight-wave plugins are updated.

**Workspace + Obsidian together**:
1. Initialize workspace (shared env, themes)
2. Set up Obsidian vault (project dashboard)
3. All subsequent plugin work benefits from both

### Demo

Walk through note creation:
1. Ask Claude: "Create a note titled 'Project Kickoff' with tags: meeting, kickoff"
2. Show the created markdown file with frontmatter
3. Show it in Obsidian's graph view
4. Demonstrate updating vault configuration

### Exercise

Ask the user to:
1. Create a note: "Create a project note titled 'Training Log' with tags: training, insight-wave"
2. Review the created file and its frontmatter
3. Ask: "Check my workspace status" to verify everything is healthy

### Quiz

1. **Hands-on**: Create a note and tell me what YAML frontmatter fields were added.

2. **Multiple choice**: When should you use "Update my Obsidian vault"?
   - a) Every time you start Claude
   - b) When insight-wave plugins are updated and you want new configurations
   - c) Before every meeting
   - d) Only during initial setup
   **Answer**: b

### Recap

- Notes get standardized YAML frontmatter (title, date, tags, source)
- Updates are incremental — never overwrite customizations
- Workspace + Obsidian = complete project foundation
- Ready for all subsequent insight-wave courses

---

## Module 6: Getting Help & Filing Issues

### Theory (3 min)

When something goes wrong — a plugin produces unexpected output, a command fails,
or you have an idea for improvement — you need a structured way to communicate that.
Think of it as filing a **structured support request**: you describe what happened,
and the maintainer gets exactly the context needed to act on it.

insight-wave uses **GitHub issues** for this. The **cogni-issues** skill (part of
cogni-workspace) handles everything for you — you describe the problem in plain
language, and Claude drafts and files the issue on your behalf.

**Four issue types**:

| Type | When to use | Example |
|------|-------------|---------|
| **Bug** | Something is broken or produces wrong output | "cogni-trends scout crashed mid-run" |
| **Feature** | You want something new | "Add PDF export to trend reports" |
| **Change request** | Something works but should work differently | "Change default output language to German" |
| **Question** | You need clarification | "How do I reset my workspace theme?" |

All issues go to the insight-wave monorepo — you don't need to know which plugin
lives where. cogni-issues figures that out automatically.

### Demo

Walk through the cogni-issues consultation flow:

1. The user describes a problem: "The trend scout keeps timing out on my project"
2. Claude asks 1-2 clarifying questions: "Which trend topic? How long did it run?"
3. Claude drafts the issue with a structured template (title, description, steps to reproduce)
4. The user reviews and confirms before anything is submitted
5. Claude creates the GitHub issue and returns the URL

Key point: **nothing is submitted without explicit confirmation**. The learner
always sees the full draft before it goes to GitHub.

### Exercise

Before starting, check if browsermcp is available and the user is logged into GitHub:

1. Try `mcp__browsermcp__browser_navigate` to `https://github.com` — if the tool
   is not available, the cogni-help plugin's `.mcp.json` may not have loaded.
   Guide the user to verify the plugin is installed.
2. Use `mcp__browsermcp__browser_snapshot` to check login state — look for a
   logged-in indicator (profile menu, avatar) vs a "Sign in" link.
3. If not logged in, walk the user through signing into GitHub via browsermcp
   or suggest using a Personal Access Token for headless environments.

Once the browser is connected and logged in, ask the user to file their first issue:

> "Tell Claude: **I have a question about insight-wave — which course should I
> take after finishing Course 2?**"

This triggers the cogni-issues skill, which will consult, draft a `[Question]`
issue, and ask for confirmation. The learner experiences the full flow with a
safe, real interaction.

Create `_teacher-exercises/first-issue.md` with the template from
`references/exercises/first-issue.md` to record what they filed.

### Quiz

1. **Multiple choice**: Which issue type would you use if a plugin produces wrong output?
   - a) Feature
   - b) Question
   - c) Bug
   - d) Change request
   **Answer**: c

2. **Hands-on**: Show me the URL of the issue you just created. What type and label did it get?

### Recap

- Four issue types: Bug, Feature, Change request, Question
- cogni-issues handles the consultation flow — you describe, Claude drafts, you confirm
- All issues go to the insight-wave monorepo automatically
- Nothing is submitted without your explicit approval
- Whenever something feels wrong or you have an idea, just tell Claude

---

## Course Completion

Congratulations! You now have a complete project foundation:
- A insight-wave workspace with shared environment and themes
- An Obsidian vault (or understanding of one) for project management
- Standardized note management with frontmatter
- The ability to report issues and request features via cogni-issues

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.

**Next recommended course**: Course 3 — Basic Tools (Copywriting, Narratives, Claims)
