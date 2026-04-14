---
name: research-setup
description: |
  Configure and initialize a cogni-research project — interactive menu for report type,
  tone, citation style, market, and source mode (web / local / wiki / hybrid). Creates
  the project directory and project-config.json. Mandatory first step before research-report
  can run; research-report routes here automatically when no project is initialized.
  Use when the user says "set up research project", "configure research", "new research
  project", "initialize research", "research settings", "change research options",
  "research preferences", or wants to start a research project before any report is generated.
allowed-tools: Read, Bash, Glob, ToolSearch, AskUserQuestion, Skill
---

# Research Setup

This skill configures and initializes a research project. It collects user preferences through an interactive text menu and creates the project directory. It does not perform any research — that is handled by the research-report skill after setup completes.

## Interaction Model

This skill uses two interaction modes depending on the question type:

1. **Text output** — for open-ended questions (topic), the Configuration Menu (multi-option selection), source path requests, advanced option explanations, and the final project-initialized confirmation. Text lets the user reply naturally with free-form answers or partial selections. On text-output turns, produce ONLY text — no AskUserQuestion call.

2. **AskUserQuestion** — for discrete choices with a small option set: project location (standard / here / custom path) and conflict resolution (resume / new / different location). The structured dialog renders well for "pick one of three" choices. On AskUserQuestion turns, produce NO text output — the question parameter carries all content. Before your first AskUserQuestion call, fetch its schema: call `ToolSearch(query="select:AskUserQuestion")`.

Never combine both modes in the same turn. Each turn is either pure text or a single AskUserQuestion call.

### Turn Structure

- **Turn 1** (no topic provided): Text output — "What topic should I research?"
- **Turn 1 or 2** (topic known): Text output — extract options (Step 1), render the Configuration Menu (Step 2)
- **Next turn** (user replied to config menu): Process choices. If source mode needs paths, text output asking for paths. Otherwise, AskUserQuestion for project location (Step 3).
- **Next turn** (location answered): Run initialize-project.sh (Step 4). Text output with the project path. Setup is complete.

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

**Skill renders this as text output** (no AskUserQuestion — the Configuration Menu is open-ended):

> **Research Configuration**
>
> Topic: quantum computing's impact on cryptography
>
> **Depth:** basic (3-5K, 5 sub-questions) | detailed (5-10K, up to 10) | deep (8-15K, recursive) | outline | resource
> **Tone:** objective *(default)* | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive
> **Citations:** APA *(default)* | MLA | Chicago | Harvard | IEEE | Wikilink
> **Market:** dach | de | fr | it | pl | nl | es | us | uk | eu   *(required — pick one)*
> **Sources:** web *(default)* | local (your documents) | wiki (cogni-wiki) | hybrid (web + docs + wiki)
>
> **Execution defaults** (research-report will show the full plan before running; change here to pre-set):
> - **Confirm before running:** yes *(default)* | no   — show the execution plan preview and ask before spawning researchers
> - **Deep-mode recursion:** off *(default)* | on (depth 2)   — recursive deep-research costs ~2-3× more but explores multi-hop questions
> - **Batch size:** 4 *(default)* | 2 (gentler) | 6 (faster, only if no rate limits)
>
> Advanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these.
>
> Reply with your choices, or "go" for defaults.

The user replies naturally: "go", "deep, analytical", "detailed with IEEE citations for DACH", etc.

## Workflow

### Step 1: Extract Options from User's Prompt

Scan the user's request and extract any options they already specified. These become "detected" settings that will not be re-asked in the configuration menu.

- **Report type**: keywords like "detailed", "deep research", "outline", "sources" -> map to basic/detailed/deep/outline/resource
- **Tone**: style keywords like "analytical", "persuasive", "formal" -> map to tone. Default: "objective"
- **Citation format**: "IEEE", "APA format", "Chicago style", "wikilink" -> capture. Default: "apa"
- **Market**: must resolve to one of the 10 canonical codes defined in `references/market-sources.json`: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. There is no "global" option — downstream researchers use these codes to pick authority-source profiles, and an unknown code silently falls back to the DACH `_default` profile, masking user intent.

  Resolve the market in three tiers, stopping at the first confident match:

  1. **Explicit market phrase** → direct mapping:
     - "DACH" / "für DACH" → `dach`
     - "Deutschland" / "for Germany" / "German market" → `de`
     - "Österreich" / "Austria" / "Schweiz" / "Switzerland" → `dach` (composite)
     - "French market" / "pour la France" / "Frankreich" → `fr`
     - "Italy" / "Italia" / "italienischer Markt" → `it`
     - "Poland" / "Polska" / "polnischer Markt" → `pl`
     - "Netherlands" / "Nederland" / "Dutch market" → `nl`
     - "Spain" / "España" / "spanischer Markt" → `es`
     - "US market" / "USA" / "United States" → `us`
     - "UK market" / "Great Britain" / "United Kingdom" → `uk`
     - "European market" / "EU" / "pan-European" / "EU-weit" → `eu`

  2. **Output-language signal** (only if no phrase matched in tier 1):
     - topic written in German with no other country cue → `dach` (DACH is the working default for German-language research)
     - topic written in French → `fr`, Italian → `it`, Polish → `pl`, Dutch → `nl`, Spanish → `es`
     - topic written in English with no country cue → **ambiguous**, fall through to tier 3

  3. **Ambiguous — ask the user**: do NOT invent a default. Render the Configuration Menu with the Market row expanded and a one-line note telling the user you could not tell which market from the topic. Their reply in the next turn resolves it. Never call `initialize-project.sh` without a resolved market — the script will reject it.
- **Output language**: "in German", "auf Deutsch" -> "de" (+ market=dach if no explicit market). "in French" -> "fr". "in Italian" -> "it". "in Polish" -> "pl". "in Dutch" -> "nl". "in Spanish" -> "es". Default: auto (derived from market)
- **Source URLs**: any URLs in the prompt -> collect for pre-fetch
- **Query domains**: "only .gov sources", "restrict to arxiv" -> collect domains
- **Max subtopics**: "use 8 sub-questions", "12 dimensions" -> capture count
- **Report source**: "analyze these PDFs", "research from my files" -> "local"; "use my wiki" -> "wiki"; combinations -> "hybrid". Default: "web"
- **Document paths**: file paths or glob patterns for local/hybrid mode
- **Wiki paths**: paths to cogni-wiki roots -> collect for wiki_paths
- **Curate sources**: "prioritize authoritative sources" -> enable
- **Confirm plan**: "just run it", "don't ask", "silent", "skip confirmation" -> `confirm_plan: false`. Default: `true`
- **Recursion (deep mode)**: "recursive", "multi-hop", "go deeper" -> `recursive_depth: 2`. "no recursion", "single-pass", "flat" -> `recursive_depth: 0`. Default: 0 (off) — deep mode still runs the full sub-question tree, but with `section-researcher` rather than `deep-researcher`, since recursion is a large cost multiplier most users don't actually need
- **Batch size**: "batch size N", "N at a time", "gentler batches" -> capture int (2/4/6). Default: 4

### Step 2: Configuration Menu (text output, turn ends)

Assemble the menu dynamically and render it as text output:

**Assemble the menu dynamically:**

1. Show the detected topic
2. List any options already extracted from the prompt (e.g., "Detected: type = deep, citations = IEEE")
3. For **unset primary options**, show the compact chooser:
   - **Depth** (only if report type not yet detected): list all 5 types with word counts and one-line descriptions
   - **Tone** (only if not detected): show these options: objective *(default)* | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive
   - **Citations** (only if not detected): list all 5 formats, mark default
   - **Market** (only if not detected with confidence, or ambiguous): `dach | de | fr | it | pl | nl | es | us | uk | eu`. If Step 1 flagged the market as ambiguous (tier 3), prefix this row with a one-line note: `> I couldn't tell which market you mean from the topic — please pick one.` The canonical list equals the keys of `references/market-sources.json` minus `_default` — keep this menu in sync with that file (if a new market is added there, add it here; if one is removed, remove it here).
   - **Sources** (only if report_source not detected): show all 4 modes with one-line descriptions:
     - `web` *(default)* = search the internet
     - `local` = analyze your documents (PDF, DOCX, MD, CSV, ...)
     - `wiki` = query your cogni-wiki knowledge bases
     - `hybrid` = combine web + documents + wiki
4. Always include one line for advanced options: "Advanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these"
5. End with: `Reply with your choices, or "go" for defaults.`

**Menu variations** (both as text output — auto-starting research without confirmation wastes compute if the user wanted to tweak something):

- **Normal case** (any option unset): Show the full menu with all choosers above.
- **All four primary options pre-specified** (type + tone + citations + source mode all in the user's original prompt), or user said "just go" / "defaults are fine" / "start now": Show a compact confirmation instead:
  "Starting **{type}** research on {topic} — {tone} tone, {citations} citations, {source} sources. Change anything? (reply 'go' to confirm)"

**Handling user responses (next turn):**
- "go" / "defaults" / "start" -> accept detected + default values. **Exception**: if market was ambiguous (tier 3 in Step 1) and the user's "go" reply did not pick a market, do NOT proceed — re-render the menu with just the Market row and the note "I still need a market — pick one of: dach, de, fr, it, pl, nl, es, us, uk, eu". The script will reject a missing market anyway; catching it here keeps the conversation clean.
- Specific choices ("deep, analytical, IEEE") -> merge with detected values
- Question about an advanced option ("what roles are available?") -> read the relevant reference file from `${CLAUDE_PLUGIN_ROOT}/references/` (agent-roles.md, writing-tones.md, citation-formats.md), explain the option as text output, then re-present the menu as text
- Partial choices ("make it detailed") -> update that option, ask if anything else or proceed

After accepting configuration: if the resolved `report_source` is `local`, `wiki`, or `hybrid`, run the **Source mode follow-up** below before proceeding to Step 3. If `report_source` is `web` (or defaulted to web), skip to Step 3.

**Source mode follow-up** (text output, turn ends): When the user selects `local`, `wiki`, or `hybrid`:

- **`local`**: Text output: "Which documents should I analyze? Provide file paths or glob patterns (e.g., `~/docs/*.pdf`, `./data/`)."
- **`wiki`** or **`hybrid`** (wiki path needed): Run **wiki discovery** first (see below), then present results.
- **`hybrid`**: Also ask for document paths if not already set.

If the user already provided paths in their original prompt (detected in Step 1), skip the follow-up for that path type.

**Wiki discovery** — instead of asking the user to type wiki paths from memory, auto-discover available wikis:

1. Use `Glob` to find `.cogni-wiki/config.json` files. Search these locations in order, stop after the first that yields results:
   - Current working directory tree: `**/.cogni-wiki/config.json`
   - `$HOME` with shallow depth: `*/.cogni-wiki/config.json` and `*/*/.cogni-wiki/config.json`
2. For each found config, `Read` the JSON and extract `name`, `slug`, `description`. The wiki root is the config file's parent's parent directory.
3. Present discovered wikis as a numbered pick-list (text output):

```
Available wikis:

1. {{name}} — {{description}} ({{wiki-root-path}})
2. {{name}} — {{description}} ({{wiki-root-path}})

Select wikis by number (e.g., "1" or "1,2"), or provide a custom path.
```

4. If **no wikis found**: fall back to the manual prompt: "No wikis detected in your workspace. Provide the wiki root path(s) (e.g., `~/my-wiki/`)."
5. Parse the user's reply: numbers map to discovered paths, free-text paths are used as-is. Collect all selected paths into `wiki_paths`.

### Step 3: Ask for Project Location (AskUserQuestion, turn ends)

After research configuration is confirmed, **always** ask where to store the project. The only exception is when the user already specified a location (e.g., "save in standard", "put it in ~/research", "here").

This is a discrete three-option choice — use AskUserQuestion (fetch its schema via ToolSearch first if not yet loaded):
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
  [--curate-sources] \
  [--confirm-plan <true|false>] \
  [--recursive-depth <0|2>] \
  [--batch-size <2|4|6>]
```

Pass `--confirm-plan`, `--recursive-depth`, `--batch-size` only if the user explicitly picked a non-default value in the Execution defaults block. Omit them otherwise — `research-report` applies the documented defaults (confirm: on, recursion: off, batch size: 4) when the keys are missing from `project-config.json`.

Check the `already_exists` field in the JSON output.

**If `already_exists` is `false`**: Print the project path. Setup is complete.

**If `already_exists` is `true`**: A project with the same slug already exists. This is a discrete three-option choice — use `AskUserQuestion`:

"A research project already exists at {project_path}\n- Topic: {existing_topic}\n- Completed phases: {completed_phases}\n\nWhat would you like to do?\n1. Resume — continue this existing project\n2. New project — create a separate project alongside\n3. Different location — save elsewhere"

Handle the response:
- **Resume**: Print the existing project path with a note to resume
- **New project**: Re-run `initialize-project.sh` with `--suffix 2` (increment if needed)
- **Different location**: Call `AskUserQuestion` for a new path, then re-run

## Output

When setup is complete, print:

> Research project initialized at `{project_path}` — starting research...

Then immediately invoke `Skill("research-report")` to begin the research pipeline. The research-report skill will read the just-created `project-config.json` and start Phase 0.5 without further user interaction.
