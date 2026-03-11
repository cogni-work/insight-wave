# Course 2: Workspace & Obsidian Setup

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 1
**Plugins**: cogni-workspace, cogni-obsidian
**Audience**: Consultants setting up their cogni-works environment

---

## Module 1: What is a cogni-works Workspace?

### Theory (3 min)

A cogni-works workspace is a shared foundation that enables all cogni-works plugins
to collaborate on projects. The **cogni-workspace** plugin orchestrates:

- **Environment variables** — Shared settings across plugins (project name, language, paths)
- **Theme management** — Visual consistency across all outputs (slides, documents, reports)
- **Plugin discovery** — Health monitoring and status of installed plugins
- **Workspace settings** — Centralized configuration

Think of it as the "operating system" for your cogni-works plugins. Without a
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

- Workspace = shared foundation for cogni-works plugins
- Manages env vars, themes, plugin discovery, settings
- Convention-based: plugins share patterns, not dependencies
- Required for cross-plugin consistency

---

## Module 2: Initializing a Workspace

### Theory (3 min)

Initialize a workspace by asking Claude: "Initialize a cogni-works workspace" or
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
2. Ask Claude: "Initialize a cogni-works workspace for a consulting project called 'Digital Strategy 2026'"
3. Show the created files and directory structure
4. Run workspace status to verify health

### Exercise

Ask the user to:
1. Initialize a workspace in their sample project folder
2. Set project name and output language
3. Run workspace status and review the output

Provide the prompt: "Initialize a cogni-works workspace here. Project name: 'My Training Project'. Language: English."

### Quiz

1. **Hands-on**: What files were created when you initialized your workspace? List them.

2. **Multiple choice**: What does `.workplace-env.sh` contain?
   - a) Plugin source code
   - b) Environment variables shared across plugins
   - c) User credentials
   - d) Log files
   **Answer**: b

### Recap

- Initialize with: "Initialize a cogni-works workspace"
- Creates `.workplace-env.sh` with shared env vars
- Check health with workspace status
- Foundation for all subsequent plugin work

---

## Module 3: Theme Management

### Theory (3 min)

Themes ensure visual consistency across all cogni-works outputs — presentations,
documents, reports, posters. The cogni-workspace theme system supports:

**Theme sources**:
- **Presets** — Built-in themes ready to use
- **Website extraction** — Extract colors, fonts, and style from a live website
- **PowerPoint templates** — Extract theme from existing .pptx files

**What a theme defines**:
- Primary, secondary, accent colors
- Typography (headings, body text, fonts)
- Layout preferences

**Applying themes**: Once set, all cogni-works plugins that produce visual
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

**cogni-obsidian** bridges Obsidian (a popular knowledge management app) with
Claude Cowork. It creates an Obsidian vault pre-configured for cogni-works.

What it sets up:
- **Obsidian vault** with Terminal plugin integration
- **Terminal profiles** — Launch Claude Code directly from Obsidian
- **Tokyonight color scheme** for consistent visual experience
- **Workspace layout** — Multi-pane editor for effective navigation
- **15 core plugins** — Explorer, search, graph view, backlinks, etc.

Why this matters for consultants:
- Obsidian becomes your project dashboard
- All cogni-works outputs (narratives, reports, analyses) land in the vault
- Graph view shows relationships between documents
- Terminal integration lets you run cogni-works commands without leaving Obsidian

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

1. **Multiple choice**: What does cogni-obsidian set up?
   - a) A new email client
   - b) An Obsidian vault with Terminal plugin integration for Claude
   - c) A database for project data
   - d) A cloud storage system
   **Answer**: b

2. **Multiple choice**: Why integrate Obsidian with cogni-works?
   - a) Obsidian is required for plugins to work
   - b) It creates a project dashboard where all outputs land and are interconnected
   - c) It replaces Claude Desktop
   - d) It's needed for billing
   **Answer**: b

### Recap

- cogni-obsidian creates pre-configured Obsidian vaults
- Terminal integration for running Claude from Obsidian
- All plugin outputs land in the vault
- Graph view shows document relationships

---

## Module 5: Note Management & Updating

### Theory (3 min)

**Note management**: cogni-obsidian provides a standardized way to create notes
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
useful when cogni-works plugins are updated.

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
1. Create a note: "Create a project note titled 'Training Log' with tags: training, cogni-works"
2. Review the created file and its frontmatter
3. Ask: "Check my workspace status" to verify everything is healthy

### Quiz

1. **Hands-on**: Create a note and tell me what YAML frontmatter fields were added.

2. **Multiple choice**: When should you use "Update my Obsidian vault"?
   - a) Every time you start Claude
   - b) When cogni-works plugins are updated and you want new configurations
   - c) Before every meeting
   - d) Only during initial setup
   **Answer**: b

### Recap

- Notes get standardized YAML frontmatter (title, date, tags, source)
- Updates are incremental — never overwrite customizations
- Workspace + Obsidian = complete project foundation
- Ready for all subsequent cogni-works courses

---

## Course Completion

Congratulations! You now have a complete project foundation:
- A cogni-works workspace with shared environment and themes
- An Obsidian vault (or understanding of one) for project management
- Standardized note management with frontmatter

**Next recommended course**: Course 3 — Basic Tools (Copywriting, Narratives, Claims)
