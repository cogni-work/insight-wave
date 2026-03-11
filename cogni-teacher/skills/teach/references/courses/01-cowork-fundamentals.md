# Course 1: Claude Cowork Fundamentals

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: None
**Plugins**: cogni-teacher (this course is delivered by it)
**Audience**: Consultants using Claude Cowork for knowledge work

---

## Module 1: What is Claude Cowork?

### Theory (3 min)

Claude Cowork is an agentic mode in Claude Desktop that goes beyond chat.
Instead of answering one question at a time, Cowork executes complex, multi-step
tasks autonomously — reading files, creating documents, coordinating sub-agents,
and delivering professional outputs.

Key differences from Chat mode:

| Feature | Chat | Cowork |
|---------|------|--------|
| Interaction | Single Q&A | Multi-step task execution |
| File access | Upload/download | Direct read/write on your machine |
| Output | Text responses | Documents, spreadsheets, presentations |
| Duration | Short exchanges | Long-running tasks (minutes to hours) |
| Coordination | Single thread | Sub-agent parallelism |

Cowork runs in an isolated virtual machine on your computer with controlled file
and network access. You explicitly grant permissions before Claude accesses files
or internet resources.

**Meta-moment**: You're experiencing Cowork right now. This course is delivered by
**cogni-teacher** — a Cowork plugin that guides you through structured lessons with
theory, demos, exercises, and quizzes. The fact that an AI can teach you how to use
itself is a good example of what makes Cowork powerful.

### Demo

Walk through switching from Chat to Cowork mode:
1. Open Claude Desktop
2. Point out the mode selector with "Chat" and "Cowork" tabs
3. Click "Cowork" to switch to Tasks mode
4. Show the task input area and explain how it differs from chat

### Exercise

Ask the user to:
1. Open Claude Desktop on their machine
2. Switch to Cowork mode
3. Describe what they see — the task input, the sidebar, the Customize menu

### Quiz

1. **Multiple choice**: What makes Cowork different from Chat mode?
   - a) It uses a different AI model
   - b) It can execute multi-step tasks and access your files directly
   - c) It only works online
   - d) It requires a separate application
   **Answer**: b

2. **Multiple choice**: Where does Cowork run?
   - a) In the cloud on Anthropic's servers
   - b) In an isolated virtual machine on your computer
   - c) In your web browser
   - d) On a remote desktop
   **Answer**: b

### Recap

- Cowork = agentic mode for multi-step knowledge work
- Direct file access (read, write, create) on your machine
- Runs in isolated VM with explicit permission grants
- Available on Claude Desktop (macOS and Windows)

---

## Module 2: Setup — Folders, Instructions & Permissions

### Theory (3 min)

Cowork needs two things to work effectively: **folder access** and **instructions**.

**Folder access**: Grant Cowork access to specific folders on your machine. It can
then read, edit, and create files within those folders. Always scope access to
what the task needs — avoid granting access to your entire home directory.

**Global Instructions** (Settings > Cowork > Global Instructions):
Standing preferences that apply to every Cowork task. Examples:
- "I am a management consultant at XYZ. Always write in professional tone."
- "Default output language: English. Use metric units."
- "Never delete files without asking first."

**Folder Instructions**: Project-specific context. When you select a folder,
you can add instructions that apply only when working in that folder. Claude can
also update these autonomously during tasks.

**Permissions**: Cowork asks for confirmation before:
- Accessing new files or folders
- Making network requests
- Deleting files
- Installing packages

### Demo

Walk through the setup process:
1. Open Settings > Cowork
2. Show Global Instructions — edit and save a sample instruction
3. Show how to add a folder with folder-specific instructions
4. Explain the permission confirmation dialogs

### Exercise

Ask the user to:
1. Set a Global Instruction: "I am a consultant. Use professional business tone in all outputs."
2. Create a project folder on their desktop called `cowork-training`
3. Add it as a Cowork folder with the instruction: "This is a training project for learning Claude Cowork."

### Quiz

1. **Multiple choice**: What are Global Instructions used for?
   - a) One-time task descriptions
   - b) Standing preferences that apply to every Cowork task
   - c) Scheduling tasks
   - d) Installing plugins
   **Answer**: b

2. **Hands-on**: Show me the Global Instruction you just set.

### Recap

- Grant folder access to let Cowork read/write files
- Global Instructions = standing preferences for all tasks
- Folder Instructions = project-specific context
- Cowork always asks permission before sensitive actions

---

## Module 3: Plugins — Install, Browse & Customize

### Theory (3 min)

Plugins turn Claude into a specialist for your role. Each plugin bundles:

- **Skills** — Specialized knowledge Claude can leverage
- **Connectors** — Integrations with external tools (Google Drive, Gmail, etc.)
- **Slash commands** — Structured workflows you trigger with `/command-name`
- **Sub-agents** — Specialized Claude instances for particular functions

**Installing plugins**:
1. Click "Customize" in the left sidebar
2. Browse available plugins by category (sales, finance, legal, marketing, etc.)
3. Click "Install" on the plugin you want
4. Optionally upload custom plugin files

**Customizing plugins**: After installing, click "Customize" on the plugin card.
Claude walks you through adjusting skills, connectors, and commands to match
your workflow.

**cogni-works marketplace**: A set of open-source plugins specifically for
consulting, B2B sales, and marketing work. These are the plugins you will learn
in subsequent courses.

**cogni-teacher is itself a cogni-works plugin**. You're using it right now —
it bundles skills (`teach`, `course-deck`), slash commands (`/teach`, `/courses`),
and course reference files. It's a concrete example of how plugins package
knowledge and workflows into reusable tools.

### Demo

Walk through plugin installation and the cogni-works marketplace deployment:
1. Open Customize menu in sidebar
2. Browse plugins by category
3. Show a plugin card — its description, components, install button
4. Install the cogni-works marketplace — walk through each plugin:

| Plugin | What it does |
|--------|-------------|
| cogni-workspace | Shared environment, themes, plugin discovery |
| cogni-obsidian | Obsidian vault setup with terminal integration |
| cogni-copywriting | Document polishing with messaging frameworks |
| cogni-narrative | Executive narratives using story arcs |
| cogni-claims | Fact-checking and source verification |
| cogni-tips | Trend scouting and reporting (TIPS framework) |
| cogni-portfolio | Portfolio messaging and positioning |
| cogni-visual | Presentations, posters, visual deliverables |
| cogni-teacher | This training program (you're using it now) |

5. After installation, verify with `/courses` — all 7 courses should appear
6. Show the customization flow on one plugin

### Exercise

Ask the user to:
1. Open the Customize menu
2. Install the full cogni-works marketplace — all plugins listed above
3. After installation, run `/courses` to confirm the curriculum is available
4. Pick any installed plugin and list the slash commands it provides
5. Confirm: how many cogni-works plugins are now installed?

If any plugin fails to install, troubleshoot before continuing — every
subsequent course depends on having the marketplace deployed.

### Quiz

1. **Multiple choice**: What are the four components a plugin can bundle?
   - a) Files, folders, scripts, logs
   - b) Skills, connectors, slash commands, sub-agents
   - c) Documents, spreadsheets, presentations, images
   - d) Databases, APIs, webhooks, cron jobs
   **Answer**: b

2. **Hands-on**: Run `/courses` and tell me what you see. How many courses
   are listed, and what's the status of each?

3. **Multiple choice**: How do you customize an installed plugin?
   - a) Edit the source code
   - b) Click "Customize" on the plugin card — Claude guides you
   - c) Uninstall and reinstall with different settings
   - d) Contact the plugin developer
   **Answer**: b

### Recap

- Plugins bundle skills, connectors, commands, and sub-agents
- Install from Customize menu or upload custom plugins
- cogni-works = open-source plugins for consulting work
- You deployed the full cogni-works marketplace — all plugins are ready
- `/courses` confirms your training program is active
- Customize any plugin after installation

---

## Module 4: Slash Commands & Connectors

### Theory (3 min)

**Slash commands** are structured workflows you trigger by typing `/` followed by
the command name. For example:
- `/sales:call-prep` — Prepare for a sales call
- `/copywrite report.md` — Polish a document
- `/narrative --arc=corporate-visions` — Create an executive narrative

You've already used two slash commands to get here:
- `/teach` — started this course (or `/teach 1` to jump to a specific one)
- `/courses` — shows the full curriculum with your progress

To use slash commands:
- Type `/` in the Cowork task input to see available commands
- Or click `+` > Plugins to browse commands by plugin
- Commands may have arguments (file paths, options, flags)

**Connectors** integrate Cowork with external services:
- Google Drive, Gmail, Google Calendar
- DocuSign, Slack
- Apollo, Clay, Outreach (sales tools)
- FactSet, MSCI (financial data)

Connectors are configured per plugin. Each connector requires authentication
(usually OAuth) and you control what data Claude can access.

### Demo

Walk through using a slash command:
1. Type `/` in the task input
2. Browse available commands from installed plugins
3. Select a command and show its form/arguments
4. Execute the command and observe the output

Walk through connectors:
1. Open Settings > Connectors
2. Show available connectors
3. Explain the authentication flow (without actually connecting)

### Exercise

Ask the user to:
1. Type `/` in a Cowork task to see available commands
2. List 3 slash commands they find from cogni-works plugins
3. Describe what each command does based on its description

### Quiz

1. **Hands-on**: Type `/` and tell me how many cogni-works commands you see.

2. **Multiple choice**: What do connectors do?
   - a) Connect plugins to each other
   - b) Integrate Cowork with external services like Google Drive and Gmail
   - c) Connect your computer to the internet
   - d) Link multiple Claude accounts
   **Answer**: b

### Recap

- Slash commands = structured workflows triggered with `/command-name`
- Commands can have arguments (files, flags, options)
- Connectors integrate with external services (Google, Slack, etc.)
- Each connector needs authentication and explicit permission

---

## Module 5: Scheduled Tasks & Best Practices

### Theory (3 min)

**Scheduled tasks** let you automate recurring work:
- Type `/schedule` in any Cowork task
- Set frequency: hourly, daily, weekly, weekdays only, or on-demand
- Claude runs the task automatically and delivers finished outputs

Common uses for consultants:
- Daily briefing: summarize emails, calendar, and Slack
- Weekly report compilation from shared drives
- Recurring competitor monitoring

**Important limitations**:
- Tasks only run when your computer is awake and Claude Desktop is open
- Skipped tasks run automatically when you reopen the app
- No memory persistence between separate sessions
- Cowork tasks consume more tokens than regular chat

**Best practices for consultants**:
1. Scope folder access narrowly — only the folders needed for the task
2. Write clear Global Instructions with your role and preferences
3. Batch related work into single sessions to save tokens
4. Use scheduled tasks for routine work, Cowork tasks for creative work
5. Review outputs before sharing — Cowork is a draft producer, not a publisher
6. Start with the cogni-works course sequence to build skills progressively
7. Use `/courses` to track your learning progress across sessions
8. Use `course-deck` to generate presentation materials for team onboarding

### Demo

Walk through creating a scheduled task:
1. Type `/schedule` in a Cowork task
2. Describe a sample recurring task: "Every Monday at 9am, summarize my project folder"
3. Show the scheduling options (frequency, time)
4. Show the Scheduled tasks panel in the left sidebar

### Exercise

Ask the user to:
1. Think of one recurring task in their consulting work that could be automated
2. Describe it as a Cowork task prompt
3. Identify: what folder access is needed? What frequency? What output format?

(Do not actually schedule it — just plan it.)

### Quiz

1. **Multiple choice**: When do scheduled tasks run?
   - a) Always, even when your computer is off
   - b) Only when your computer is awake and Claude Desktop is open
   - c) Only on weekdays
   - d) Only when you manually trigger them
   **Answer**: b

2. **Open-ended**: Name one best practice for using Cowork efficiently as a consultant.

### Recap

- `/schedule` creates recurring automated tasks
- Tasks need computer awake + Claude Desktop open
- Batch related work to save tokens
- Always review Cowork outputs before sharing
- Next course: Workspace & Obsidian Setup — your project foundation

---

## Course Completion

Congratulations! You now understand:
- What Claude Cowork is and how it differs from Chat
- How to set up folders, instructions, and permissions
- How to install, browse, and customize plugins
- How to use slash commands and connectors
- How to schedule recurring tasks and follow best practices

You've also seen cogni-teacher in action — the plugin delivering this course.
You now know how plugins, slash commands, and structured workflows come together.

**Next recommended course**: Course 2 — Workspace & Obsidian Setup
