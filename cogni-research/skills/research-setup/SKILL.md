---
name: research-setup
description: |
  Configure and initialize a cogni-research project — interactive menu for report type,
  tone, citation style, target market (18 supported: DACH, DE, FR, IT, PL, NL, ES, CZ, SK, HU, HR, GR,
  MX, BR, CN, US, UK, EU — each with per-market authority sources and intent-based bilingual search),
  output language, and source mode (web / local / wiki / hybrid). Creates the project
  directory and project-config.json. Mandatory first step before research-report can
  run; research-report routes here automatically when no project is initialized.
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
> **Depth:** basic (5 sub-questions) | detailed (up to 10) | deep (recursive tree) | outline | resource
> **Length:** brief (1.5K) | standard (3K) | deep-dive (5K) *(default for deep)* | comprehensive (8K) | whitepaper (12K) — or specify e.g. "~6500 words"
> **Tone:** objective *(default)* | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive
> **Citations:** APA *(default)* | MLA | Chicago | Harvard | IEEE | Wikilink | Local-Wikilink
> **Market** *(required — curated authority sources per region)*:
> ```
>   dach   DACH (DE/AT/CH) — 27 authority domains (fraunhofer.de, bitkom.org, vdma.org +24); bilingual DE/EN
>   de     Germany — 14 authority domains (fraunhofer.de, bitkom.org +11); bilingual DE/EN
>   fr     France — 16 authority domains (inria.fr, cnrs.fr, insee.fr +13); bilingual FR/EN
>   it     Italy — 15 authority domains (cnr.it, asi.it, istat.it +12); bilingual IT/EN
>   pl     Poland — 14 authority domains (pan.pl, nask.pl, stat.gov.pl +11); bilingual PL/EN
>   nl     Netherlands — 15 authority domains (tno.nl, nwo.nl, cbs.nl +12); bilingual NL/EN
>   es     Spain — 14 authority domains (csic.es, inta.es, ine.es +11); bilingual ES/EN
>   cz     Czechia — 12 authority domains (czso.cz, avcr.cz, ctu.cz +9); bilingual CS/EN
>   sk     Slovakia — 11 authority domains (slovak.statistics.sk, sav.sk, teleoff.gov.sk +8); bilingual SK/EN
>   hu     Hungary — 11 authority domains (ksh.hu, hun-ren.hu, nmhh.hu +8); bilingual HU/EN
>   hr     Croatia — 10 authority domains (dzs.hr, hazu.hr, hakom.hr +7); bilingual HR/EN
>   gr     Greece — 11 authority domains (www.statistics.gr, academyofathens.gr, eett.gr +8); bilingual EL/EN
>   mx     Mexico — 14 authority domains (inegi.org.mx, inai.org.mx, unam.mx +11); bilingual ES/EN
>   br     Brazil — 14 authority domains (ibge.gov.br, cnpq.br, fapesp.br +11); bilingual PT/EN
>   cn     China — 12 authority domains (stats.gov.cn, cas.cn, caict.ac.cn +9); bilingual ZH/EN
>   us     United States — 13 authority domains (nist.gov, mit.edu, bls.gov +10); English-only
>   uk     United Kingdom — 10 authority domains (gov.uk, ukri.org, ons.gov.uk +7); English-only
>   eu     EU composite — 10 EU-wide domains; fans out per-country (de, fr, it, pl, nl, es; cz/sk/hu/hr/gr included in EU and mx/br/cn excluded as non-EU — the fan-out composite still uses the 6 Big-EU countries today, follow-up issue to extend)
> ```
> (The exact list comes from `scripts/market-summary.py --format table --all` — the skill renders it fresh so the counts and top domains never drift from `references/market-sources.json`.)
>
> **Sources** *(how evidence is gathered)*:
> - `web` *(default)* — search the internet with market-boosted authority domains (above)
> - `local` — analyze your own PDF, DOCX, MD, CSV, XLSX, PPTX documents — zero web calls
> - `wiki` — query your cogni-wiki knowledge bases — fast, pre-synthesized, cached
> - `hybrid` — run web + local + wiki in parallel; use when you have proprietary docs AND want fresh web evidence
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
- **Target words (length)**: length is now independent of depth (v0.7.7, issue #35). Capture explicit integers and named presets separately from report type, and only apply a detected length if it actually differs from the depth default — otherwise let the default-by-depth table handle it.
  - **Named presets**: `brief` → 1500, `standard` → 3000, `deep-dive` → 5000, `comprehensive` → 8000, `whitepaper` → 12000. Trigger on phrases like "brief", "short", "standard length", "deep-dive", "comprehensive", "long-form", "whitepaper", "white paper", "reference document".
  - **Explicit integers**: "5K words", "~8000 words", "roughly 6500", "about 5,000 words", "10K", "12k" → parse to the nearest 500-word value and pass through.
  - **Interaction with `report_type`**: the two are orthogonal. "deep research, whitepaper length" → `report_type=deep, target_words=12000`. "detailed but short" → `report_type=detailed, target_words=3000`. "basic, make it thorough" → `report_type=basic, target_words=5000`. "deep research on X" with no length cue → `report_type=deep, target_words=5000` (the v0.7.7 default, reduced from 8000). To restore the legacy 8K floor, the user must say so explicitly ("deep research, ~8000 words" or "deep, comprehensive") — never infer it.
  - **Default resolution**: if no length cue was detected, do NOT pass `--target-words` to `initialize-project.sh`; let the script apply its default-by-depth table. If a length cue was detected, pass `--target-words <N>` with the resolved integer.
  - **Ambiguity guard**: if the user only said "long" or "short" without a scale anchor, ask a clarifying follow-up ("about 3K words, 5K, or closer to 10K?") — don't guess.
- **Tone**: style keywords like "analytical", "persuasive", "formal" -> map to tone. Default: "objective"
- **Citation format**: "IEEE", "APA format", "Chicago style", "wikilink", "local wikilink" / "local-wikilink" -> capture. Default: "apa"
- **Market**: must resolve to one of the 18 canonical codes defined in `references/market-sources.json`: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `cz`, `sk`, `hu`, `hr`, `gr`, `mx`, `br`, `cn`, `us`, `uk`, `eu`. There is no "global" option — downstream researchers use these codes to pick authority-source profiles, and an unknown code silently falls back to the DACH `_default` profile, masking user intent.

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
     - "Mexico" / "México" / "mercado mexicano" / "para México" / "CDMX" → `mx`
     - "Brazil" / "Brasil" / "mercado brasileiro" / "para o Brasil" / "São Paulo" / "SP" → `br`
     - "Czech Republic" / "Česká republika" / "Česko" / "český trh" / "Czechia" → `cz`
     - "Slovakia" / "Slovensko" / "slovenský trh" / "Slovak Republic" → `sk`
     - "Hungary" / "Magyarország" / "magyar piac" → `hu`
     - "Croatia" / "Hrvatska" / "hrvatsko tržište" → `hr`
     - "Greece" / "Ελλάδα" / "ελληνική αγορά" / "Hellenic Republic" → `gr`
     - "China" / "中国" / "中国市场" / "Chinese market" / "Mainland China" / "mercado chino" / "marché chinois" / "chinesischer Markt" → `cn`
     - "US market" / "USA" / "United States" → `us`
     - "UK market" / "Great Britain" / "United Kingdom" → `uk`
     - "European market" / "EU" / "pan-European" / "EU-weit" → `eu`

  2. **Output-language signal** (only if no phrase matched in tier 1):
     - topic written in German with no other country cue → `dach` (DACH is the working default for German-language research)
     - topic written in French → `fr`, Italian → `it`, Polish → `pl`, Dutch → `nl`
     - topic written in Spanish with a Mexico cue (CDMX / Monterrey / Guadalajara / CFDI / SAT / Banxico / IFT / INAI) → `mx`
     - topic written in Spanish without any country cue → **ambiguous**, fall through to tier 3 (do NOT silently default to `es` — Mexican queries must never land on Spain by accident)
     - topic written in Portuguese → `br` (Brazil is the only PT market; no ambiguity guard needed — if Portugal or another Lusophone market is added later, introduce a PT tier-3 guard at that point)
     - topic written in Czech (cs) → `cz` (single market, no ambiguity)
     - topic written in Slovak (sk) → `sk` (single market, no ambiguity)
     - topic written in Hungarian (hu) → `hu` (single market, no ambiguity)
     - topic written in Croatian (hr) → `hr` (single market, no ambiguity)
     - topic written in Greek (el) → `gr` (single market, no ambiguity)
     - topic written in Chinese (Simplified or Traditional) → `cn` (China is the only ZH market today; no ambiguity guard needed — if Taiwan or Hong Kong is added later as a distinct market, introduce a ZH tier-3 guard at that point)
     - topic written in English with no country cue → **ambiguous**, fall through to tier 3

  3. **Ambiguous — ask the user**: do NOT invent a default. Render the Configuration Menu with the Market row expanded and a one-line note telling the user you could not tell which market from the topic. Their reply in the next turn resolves it. Never call `initialize-project.sh` without a resolved market — the script will reject it.
- **Output language**: "in German", "auf Deutsch" -> "de" (+ market=dach if no explicit market). "in French" -> "fr". "in Italian" -> "it". "in Polish" -> "pl". "in Dutch" -> "nl". "in Spanish" -> resolve via market tiers above; do not silently default to `es` — Mexican queries must never land on Spain by accident. "in Portuguese" / "em português" -> "pt" (+ market=br). "in Czech" / "česky" -> "cs" (+ market=cz). "in Slovak" / "slovensky" -> "sk" (+ market=sk). "in Hungarian" / "magyarul" -> "hu" (+ market=hu). "in Croatian" / "hrvatski" -> "hr" (+ market=hr). "in Greek" / "στα ελληνικά" -> "el" (+ market=gr). "in Chinese" / "in Mandarin" / "中文" -> "zh" (+ market=cn). Default: auto (derived from market)
- **Source URLs**: any URLs in the prompt -> collect for pre-fetch
- **Query domains**: "only .gov sources", "restrict to arxiv" -> collect domains
- **Max subtopics**: "use 8 sub-questions", "12 dimensions" -> capture count
- **Report source**: "analyze these PDFs", "research from my files" -> "local"; "use my wiki" -> "wiki"; combinations -> "hybrid". Default: "web"
- **Document paths**: file paths or glob patterns for local/hybrid mode
- **Wiki paths**: paths to cogni-wiki roots -> collect for wiki_paths
- **Curate sources**: "prioritize authoritative sources" -> enable
- **Confirm plan**: "just run it", "don't ask", "silent", "skip confirmation" -> `confirm_plan: false`. Default: `true`
- **Recursion (deep mode)**: "recursive", "multi-hop", "go deeper" -> `recursive_depth: 2`. "no recursion", "single-pass", "flat", "cheaper" -> `recursive_depth: 0`. **Default for deep mode: 2** (on) — deep mode runs the full sub-question tree with `deep-researcher` so leaf sub-questions get 2-level internal recursion. A user who wants the cheaper flat path can say "flat" or pick "Disable recursion" in the Phase 1.5 plan-confirmation menu. All non-deep report types default to `recursive_depth: 0` (the field is ignored outside deep mode).
- **Batch size**: "batch size N", "N at a time", "gentler batches" -> capture int (2/4/6). Default: 4
- **Allow short**: "short is fine", "don't expand", "I'll edit prose myself", "skip the word-count gate" -> `allow_short: true`. Default: `false`. When false, the Phase 4.5 gate re-dispatches the writer once if the draft falls below the report-type minimum, and Phase 5 runs a second review iteration to verify the expansion. When true, those gates log the deficit but take no expansion action — intended for power users who want the tree structure but will hand-edit length downstream

### Step 2: Configuration Menu (text output, turn ends)

Assemble the menu dynamically and render it as text output:

**Assemble the menu dynamically:**

1. Show the detected topic
2. List any options already extracted from the prompt (e.g., "Detected: type = deep, citations = IEEE")
3. For **unset primary options**, show the compact chooser:
   - **Depth** (only if report type not yet detected): list all 5 types with one-line descriptions **without** word counts — length is decoupled from depth and has its own row. Example: "basic = standard report, 5 sub-questions | detailed = multi-section with outline, 5-10 sub-questions | deep = recursive tree, 10-20 leaf sub-questions | outline = structured framework, no prose | resource = annotated bibliography".
   - **Length** (only if target_words not detected): show the 5 named presets with their word counts and mark the default derived from the detected or selected depth: `brief (1.5K) | standard (3K) | deep-dive (5K, deep default in v0.7.7) | comprehensive (8K) | whitepaper (12K)`. Add a one-line note: "Length is optional — defaults to 3K/5K/5K/1K/1.5K for basic/detailed/deep/outline/resource. Override with a preset above or an explicit integer (e.g., `target_words: 6500`)."
   - **Tone** (only if not detected): show these options: objective *(default)* | formal | analytical | persuasive | informative | explanatory | descriptive | critical | comparative | speculative | narrative | optimistic | simple | casual | executive
   - **Citations** (only if not detected): list all 7 formats (`apa`, `mla`, `chicago`, `harvard`, `ieee`, `wikilink`, `local-wikilink`), mark `apa` as default. Keep this list in sync with `VALID_CITATION_FORMATS` in `scripts/initialize-project.sh` — if a new format is added there, add it here.
   - **Market** (only if not detected with confidence, or ambiguous): render the full headline table by shelling out to `${CLAUDE_PLUGIN_ROOT}/scripts/market-summary.py --format table --all` and embedding the output under a `**Market** *(required — curated authority sources per region)*:` heading. Each row shows the code, the region name, the count of curated authority domains, the top 3 example domains, and whether queries run bilingually or English-only. The table is data-derived so it never drifts from `references/market-sources.json` — if a new market is added there, the menu picks it up automatically. If Step 1 flagged the market as ambiguous (tier 3), prefix the table with the one-line note `> I couldn't tell which market you mean from the topic — please pick one.`. Surfacing the curation upfront is the point: the user should see *what* DACH actually means (Fraunhofer, BITKOM, VDMA, +24 more) before picking it, so the quality signal registers at the moment of choice rather than staying hidden in a reference file.
   - **Sources** (only if report_source not detected): show all 4 modes with a one-line "when to pick this" description. The local/wiki options are a differentiator users routinely miss — name the *value* not just the mechanism:
     - `web` *(default)* = search the internet with market-boosted authority domains (the table above)
     - `local` = analyze your own PDF, DOCX, MD, CSV, XLSX, PPTX documents — zero web calls, fastest path when you already have the evidence
     - `wiki` = query your cogni-wiki knowledge bases — pre-synthesized, cached, near-instant
     - `hybrid` = run web + local + wiki in parallel; use when you have proprietary docs AND want fresh web evidence on top
4. Always include one line for advanced options: "Advanced: output language, sub-question count, domain filter, researcher role, diagram generation, allow short (skip word-count expansion gates) — ask about any of these"
5. End with: `Reply with your choices, or "go" for defaults.`

**Menu variations** (both as text output — auto-starting research without confirmation wastes compute if the user wanted to tweak something):

- **Normal case** (any option unset): Show the full menu with all choosers above.
- **All four primary options pre-specified** (type + tone + citations + source mode all in the user's original prompt), or user said "just go" / "defaults are fine" / "start now": Show a compact confirmation instead:
  "Starting **{type}** research on {topic} — {tone} tone, {citations} citations, {source} sources. Change anything? (reply 'go' to confirm)"

**Handling user responses (next turn):**
- "go" / "defaults" / "start" -> accept detected + default values. **Exception**: if market was ambiguous (tier 3 in Step 1) and the user's "go" reply did not pick a market, do NOT proceed — re-render the menu with just the Market row and the note "I still need a market — pick one of: dach, de, fr, it, pl, nl, es, cz, sk, hu, hr, gr, mx, br, cn, us, uk, eu". The script will reject a missing market anyway; catching it here keeps the conversation clean.
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
  [--citation-format "<apa|mla|chicago|harvard|ieee|wikilink|local-wikilink>"] \
  [--source-urls "<url1,url2,...>"] \
  [--query-domains "<domain1,domain2,...>"] \
  [--max-subtopics <N>] \
  [--report-source "<web|local|wiki|hybrid>"] \
  [--document-paths "<path1,path2,...>"] \
  [--curate-sources] \
  [--confirm-plan <true|false>] \
  [--recursive-depth <0|2>] \
  [--batch-size <2|4|6>] \
  [--target-words <N>]
```

Pass `--confirm-plan`, `--recursive-depth`, `--batch-size` only if the user explicitly picked a non-default value in the Execution defaults block. Omit them otherwise — `research-report` applies the documented defaults (confirm: on, recursion: off, batch size: 4) when the keys are missing from `project-config.json`.

Pass `--target-words` only if the user explicitly picked a length preset or integer in Step 1 (from a named preset like "whitepaper" or an integer like "~5000 words"). Omit it when the user accepted depth-default length — `initialize-project.sh` applies the default-by-depth table (basic 3000, detailed 5000, **deep 5000**, outline 1000, resource 1500) and writes `target_words` into project-config.json at creation so the value is pinned for the project's lifetime. In v0.7.7 the deep default was reduced from 8000 to 5000 (issue #35); users who want the old 8K-deep floor set `target_words: 8000` explicitly (via a length preset choice, an integer in the prompt, or hand-editing project-config.json).

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
