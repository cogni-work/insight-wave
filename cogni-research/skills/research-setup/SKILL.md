---
name: research-setup
description: |
  Configure and initialize a cogni-research project. Presents an interactive
  Configuration Menu for report type, tone, citations, market, source mode,
  and advanced options. Creates the project directory with project-config.json.
  Use when setting up a new research project, configuring research options,
  or when research-report detects no initialized project.
  Also use when the user says "configure research", "set up research project",
  "research settings", or "research options".
allowed-tools: Read, Bash, Glob, ToolSearch, AskUserQuestion
---

# Research Setup

This skill configures and initializes a research project. It collects user preferences via AskUserQuestion and creates the project directory. It does NOT perform any research — that is handled by the research-report skill after setup completes.

## CRITICAL: Tool Setup and Question Discipline

**Before your first AskUserQuestion call**, fetch its schema: call `ToolSearch(query="select:AskUserQuestion")`. Do this once per session — after that, AskUserQuestion is callable.

**All user-facing questions go through AskUserQuestion — never as text output.**

DO NOT output configuration menus, confirmations, or settings as text in your response.
DO NOT auto-confirm defaults (no "Perfekt", "Great", "Starting research", or any acknowledgment).
DO NOT produce text that duplicates or previews what the AskUserQuestion dialog will show.

The ONLY way to present a question is via the `AskUserQuestion` tool call. The content goes in the tool's `question` parameter — not in your text output. After calling `AskUserQuestion`, your turn is OVER. Produce no further tool calls, no further text.

**Turn 1** (no topic provided): Call `AskUserQuestion` with question "What topic should I research?"
YOUR TURN ENDS.

**Turn 1 or 2** (topic known): Extract options (Step 1), assemble the Configuration Menu (Step 2), pass it as the `question` parameter of `AskUserQuestion`.
YOUR TURN ENDS. Do not auto-confirm. Do not initialize the project.

**Next turn** (user replied to config menu): Process their choices. If source mode needs paths -> call `AskUserQuestion` for paths. YOUR TURN ENDS.
Otherwise -> call `AskUserQuestion` for project location (Step 3). YOUR TURN ENDS.

**Next turn** (location answered): Run initialize-project.sh (Step 4). Print the project path. Setup is complete.

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

**Skill's ONLY action this turn** — call AskUserQuestion with the menu as the question parameter:

    AskUserQuestion(question="Research Configuration\n\nTopic: quantum computing's impact on cryptography\nDetected: type = basic\n\nDepth:\n- basic = 3-5K words, 5 sub-questions\n- detailed = 5-10K words, up to 10 sub-questions\n- deep = 8-15K words, recursive tree\n- outline = structured framework only\n- resource = annotated source list\n\nTone: objective (default) | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive\nCitations: APA (default) | MLA | Chicago | Harvard | IEEE | Wikilink\nMarket: global (default) | dach | de | us | uk | fr\nSources: web (default) | local | wiki | hybrid\n\nAdvanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these\n\nReply with your choices, or 'go' for defaults.")

**TURN ENDS.** No text output. No "Perfekt". No "Starting research". The user sees the AskUserQuestion dialog and replies in the next turn.

## Workflow

### Step 1: Extract Options from User's Prompt

Scan the user's request and extract any options they already specified. These become "detected" settings that will not be re-asked in the configuration menu.

- **Report type**: keywords like "detailed", "deep research", "outline", "sources" -> map to basic/detailed/deep/outline/resource
- **Tone**: style keywords like "analytical", "persuasive", "formal" -> map to tone. Default: "objective"
- **Citation format**: "IEEE", "APA format", "Chicago style", "wikilink" -> capture. Default: "apa"
- **Market**: "French market", "DACH", "for Germany", "US market" -> map to region code (fr, dach, de, us, uk). Default: "global"
- **Output language**: "in German", "auf Deutsch" -> "de" (+ market=dach if no explicit market). "in French" -> "fr". Default: auto (derived from market)
- **Source URLs**: any URLs in the prompt -> collect for pre-fetch
- **Query domains**: "only .gov sources", "restrict to arxiv" -> collect domains
- **Max subtopics**: "use 8 sub-questions", "12 dimensions" -> capture count
- **Report source**: "analyze these PDFs", "research from my files" -> "local"; "use my wiki" -> "wiki"; combinations -> "hybrid". Default: "web"
- **Document paths**: file paths or glob patterns for local/hybrid mode
- **Wiki paths**: paths to cogni-wiki roots -> collect for wiki_paths
- **Curate sources**: "prioritize authoritative sources" -> enable

### Step 2: Configuration Menu (TURN-ENDING)

**GATE RULE**: This step produces exactly ONE action — an `AskUserQuestion` tool call — and NOTHING else.

**DO NOT:**
- Print the menu as markdown text, blockquotes, or conversational output
- Auto-select defaults and skip asking ("deep, analytical, APA — starting now")
- Acknowledge detected settings before asking ("Perfekt — deep, analytical, APA")
- Produce any text output before or after the tool call

**DO:** Assemble the menu text below, then pass it as the `question` parameter of a single `AskUserQuestion` call. That call is your entire turn.

**Assemble the menu dynamically:**

1. Show the detected topic
2. List any options already extracted from the prompt (e.g., "Detected: type = deep, citations = IEEE")
3. For **unset primary options**, show the compact chooser:
   - **Depth** (only if report type not yet detected): list all 5 types with word counts and one-line descriptions
   - **Tone** (only if not detected): show these options: objective *(default)* | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive
   - **Citations** (only if not detected): list all 5 formats, mark default
   - **Market** (only if not detected): global | dach | de | us | uk | fr
   - **Sources** (only if report_source not detected): show all 4 modes with one-line descriptions:
     - `web` *(default)* = search the internet
     - `local` = analyze your documents (PDF, DOCX, MD, CSV, ...)
     - `wiki` = query your cogni-wiki knowledge bases
     - `hybrid` = combine web + documents + wiki
4. Always include one line for advanced options: "Advanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these"
5. End with: `Reply with your choices, or "go" for defaults.`

**Menu variations** (AskUserQuestion is always called — there is no skip path):

- **Normal case** (any option unset): Show the full menu with all choosers above.
- **All four primary options pre-specified** (type + tone + citations + source mode all in the user's original prompt), or user said "just go" / "defaults are fine" / "start now": Show a compact confirmation instead:
  "Starting **{type}** research on {topic} — {tone} tone, {citations} citations, {source} sources. Change anything? (reply 'go' to confirm)"

Either way, call `AskUserQuestion`. Either way, your turn ends.

**Handling user responses (next turn):**
- "go" / "defaults" / "start" -> accept detected + default values
- Specific choices ("deep, analytical, IEEE") -> merge with detected values
- Question about an advanced option ("what roles are available?") -> read the relevant reference file from `${CLAUDE_PLUGIN_ROOT}/references/` (agent-roles.md, writing-tones.md, citation-formats.md), explain the option, then re-present the menu via `AskUserQuestion`
- Partial choices ("make it detailed") -> update that option, ask if anything else or proceed

After accepting configuration: if the resolved `report_source` is `local`, `wiki`, or `hybrid`, run the **Source mode follow-up** below before proceeding to Step 3. If `report_source` is `web` (or defaulted to web), skip to Step 3.

**Source mode follow-up** (TURN-ENDING): When the user selects `local`, `wiki`, or `hybrid`:

- **`local`**: Call `AskUserQuestion` with: "Which documents should I analyze? Provide file paths or glob patterns (e.g., `~/docs/*.pdf`, `./data/`)."
- **`wiki`**: Call `AskUserQuestion` with: "Which cogni-wiki should I query? Provide the wiki root path(s) (e.g., `~/cogni-wikis/my-wiki`)."
- **`hybrid`**: Ask for both document paths (if not already set) and wiki paths (if not already set).

If the user already provided paths in their original prompt (detected in Step 1), skip the follow-up for that path type.

### Step 3: Ask for Project Location (TURN-ENDING)

After research configuration is confirmed, **always** ask where to store the project. The only exception is when the user already specified a location (e.g., "save in standard", "put it in ~/research", "here").

Call `AskUserQuestion` with:
"Where should I store this project?\n- standard (recommended) — cogni-research/{project-slug}\n- here — current directory\n- Or provide a custom path"

**Handling location responses (next turn):**
- "standard" / "recommended" -> `cogni-research/` relative to current working directory
- "here" -> current working directory
- Any path -> use as-is

### Step 4: Initialize Project

Resolve the workspace path, then run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-project.sh" \
  --topic "<user topic>" --type <basic|detailed|deep|outline|resource> \
  --workspace "<workspace path>" \
  [--market "<region-code>"] \
  [--output-language "<lang>"] \
  [--tone "<tone>"] \
  [--citation-format "<apa|mla|chicago|harvard|ieee>"] \
  [--source-urls "<url1,url2,...>"] \
  [--query-domains "<domain1,domain2,...>"] \
  [--max-subtopics <N>] \
  [--report-source "<web|local|hybrid>"] \
  [--document-paths "<path1,path2,...>"] \
  [--curate-sources]
```

Check the `already_exists` field in the JSON output.

**If `already_exists` is `false`**: Print the project path. Setup is complete.

**If `already_exists` is `true`**: A project with the same slug already exists. Call `AskUserQuestion` with:

"A research project already exists at {project_path}\n- Topic: {existing_topic}\n- Completed phases: {completed_phases}\n\nWhat would you like to do?\n1. Resume — continue this existing project\n2. New project — create a separate project alongside\n3. Different location — save elsewhere"

Handle the response:
- **Resume**: Print the existing project path with a note to resume
- **New project**: Re-run `initialize-project.sh` with `--suffix 2` (increment if needed)
- **Different location**: Call `AskUserQuestion` for a new path, then re-run

## Output

When setup is complete, print:

> Research project initialized at `{project_path}`
> Run `/research-report` to start the research, or the research-report skill will pick it up automatically.
