---
name: story-to-big-block
description: >
  Transform TIPS value-modeler output (tips-value-model.json, tips-big-block.md, tips-solution-ranking.md)
  into a visual Big Block solution architecture brief for Excalidraw rendering. Use this skill whenever
  the user mentions "big block", "solution architecture diagram", "Lösungsarchitektur", "Big Block
  visualisieren", "Big Block rendern", "solution landscape", "solution diagram", "TIPS visual",
  "value model visual", "Big Block erstellen", or wants to convert value-modeler Phase 4 output
  into a structured visual diagram. Also trigger when the user has completed a TIPS value-modeler
  run and asks to visualize, render, or diagram the results. Produces a big-block-brief.md (v1.0)
  that can be rendered via Excalidraw MCP. Important: this skill transforms STRUCTURED DATA
  (not narratives) — the input is JSON/markdown from the value-modeler, not prose. For narrative-based
  visuals, use story-to-big-picture instead.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion
version: 1.0.0
---

# Story-to-Big-Block Skill

## Purpose

Transform TIPS value-modeler Phase 4 output into a big-block-brief (v1.0) that an Excalidraw renderer turns into a solution architecture diagram. You are a **solution architecture visualizer**: read the ranked solutions, group by BR tier, map TIPS path connections, and produce a structured brief that communicates the customer's prioritized solution landscape at a glance.

A Big Block is NOT a narrative journey map. It's a **structured grid diagram** where solution blocks are organized by Business Relevance tier, connected by shared TIPS paths, and supported by SPIs and foundations below. The patent (WO2018046399A1, Fig. 3) describes this as the "specific diagram of industry solutions" — the key customer deliverable.

## Architecture

Two-layer intelligence:
1. **Data Extraction** — parse value-modeler JSON, extract solutions, paths, SPIs, foundations, rankings
2. **Visual Architecture** — group into tiers, layout blocks, route connections, assign waves

The brief describes WHAT to show (blocks, tiers, connections), not HOW to draw it. Rendering agents own visual interpretation via big-block-layouts.md. Briefs contain no color fields — the renderer reads the theme and layout specs directly.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Path to project directory containing value-modeler output |
| `theme` | `smarter-service` | Theme ID from `/cogni-workspace/themes/{theme}/theme.md` |
| `language` | `en` | Language code (en/de) |
| `title` | auto-generated | Override diagram title |
| `subtitle` | auto-generated | Override diagram subtitle |
| `customer_name` | from metadata | Customer organization name |
| `provider_name` | from metadata | Provider organization name |
| `output_path` | `{source_dir}/cogni-visual/big-block-brief.md` | Brief output location |
| `canvas_size` | `A1` | DIN format: A0, A1, A2, A3 (always landscape) |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion |
| `max_solutions` | from canvas | Maximum solutions to include (capped by canvas size) |

Canvas size details: See `$CLAUDE_PLUGIN_ROOT/libraries/big-block-layouts.md` for dimensions and block limits.

---

## Conventions

### Data-Driven, Not Narrative-Driven

The Big Block skill reads structured JSON, not prose. The value-modeler has already done the analysis — this skill visualizes the results. Do not re-analyze or re-rank. Trust the source data.

### User Interaction

When presenting choices, use AskUserQuestion with structured format. On empty or blank responses, auto-select the best option and move on. When `interactive` is `false`, skip all AskUserQuestion calls.

### Language & Formatting

German Big Blocks use real Unicode umlauts: ä ö ü Ä Ö Ü ß. German number formatting: 2.661 (not 2,661). Preserve the source language from the value-modeler output.

### Brief Format v1.0

Separating WHAT from HOW: the brief specifies blocks, tiers, connections, and sections — the renderer decides colors, positions, and line routing using big-block-layouts.md.

---

## Workflow

### Step 0: Source Auto-Discovery

If `source_path` was explicitly provided, set `source_dir` to that path (or its parent if it's a file) and skip to Step 1.

Otherwise, search without asking the user:

1. **Primary:** Glob `**/tips-value-model.json` from CWD (max 3 levels)
2. For each candidate: read, extract `project_name`, `workflow_state`, count STs
3. **Filter:** Only include models where `workflow_state` is `"complete"` or `phases_completed` includes `"phase-4"`
4. Sort: most recently modified first

**If candidates found:** Present via AskUserQuestion (max 4 options, showing project name, ST count, completion date). On selection, set `source_dir`.

**If no candidates:** Ask user for a path or cancel. If they respond empty, stop with: "No value-modeler output found. Run the TIPS value-modeler first (Phases 1-4)."

---

### Step 1: Parse Value-Modeler Output

> **WHY:** All data for the Big Block comes from three files produced by the value-modeler. Parsing them first gives you the complete picture before making any layout decisions.

Read the three source files from `source_dir`:

1. **`tips-value-model.json`** — the complete model data
   - Extract: project metadata (customer, industry, language)
   - Extract: all Solution Templates with `ranking_value`, `category`, `portfolio_mapping`, `path_scores`, `foundation_dependencies`, `spis`
   - Extract: all TIPS paths with names and scores
   - Extract: SPIs, Metrics, Foundations

2. **`tips-solution-ranking.md`** (optional, for verification)
   - Cross-check tier assignments match the JSON

3. **`tips-big-block.md`** (optional, for labels)
   - Extract any human-readable labels or descriptions not in JSON

**Metadata resolution:**
- `customer_name`: from JSON metadata or parameter
- `provider_name`: from JSON metadata or parameter
- `language`: from JSON metadata or parameter (de/en)
- `industry`: from JSON metadata

**Theme resolution:**
- If `interactive=true` and theme wasn't explicitly set: present theme options
- Otherwise: use provided theme or default `smarter-service`
- Resolve and read theme file

**Load libraries:**
- `$CLAUDE_PLUGIN_ROOT/libraries/big-block-layouts.md` — canvas specs and block sizing

---

### Step 2: Classify Solutions into Tiers

> **WHY:** The tier system is the primary organizational principle. Correct tier assignment drives the entire visual hierarchy — Tier 1 blocks are largest and most prominent, Tier 4 smallest.

Sort all Solution Templates by `ranking_value` descending and assign tiers:

| Tier | BR Range | Visual Weight |
|------|----------|---------------|
| Tier 1: Mission Critical | BR >= 4.0 | Heaviest — top band, largest blocks |
| Tier 2: High Impact | BR 3.0 - 3.99 | Medium — second band |
| Tier 3: Moderate Impact | BR 2.0 - 2.99 | Light — third band |
| Tier 4: Low Priority | BR < 2.0 | Lightest — bottom band |

**Unranked solutions** (ranking_value = null, insufficient data): Exclude from the visual or place in a separate "Unranked" section at the bottom.

**Cap by canvas size:** If total solutions exceed the canvas maximum (see big-block-layouts.md), include only the top N by ranking_value. Note excluded solutions in the brief metadata.

For each solution, prepare a block record:
- `block_id`: ST identifier
- `name` / `name_short`: full name and display-friendly short name (max 20 chars)
- `br_score`: ranking_value (2 decimal places)
- `br_stars`: round(br_score) capped at 5
- `category`: software / hybrid / service / infrastructure
- `portfolio_ref`: slug or null
- `portfolio_status`: `mapped` (has ref) or `gap` (null ref)
- `foundation_factor`: from ST data
- `paths`: array of {path_id, path_name, path_score}
- `wave`: assigned in Step 4
- `spis`: linked SPI IDs
- `foundations`: linked foundation names

---

### Step 3: Map Path Connections

> **WHY:** Shared TIPS paths are the Big Block's key differentiator from a simple ranked list. They show HOW solutions relate — which trends and implications connect them. This is the patent's relationship network made visual.

Build a connection map:

1. For each TIPS path, collect all STs that reference it
2. Filter: only include paths that connect 2+ blocks in the diagram
3. For each qualifying path, create a connection record:
   - `path_id`, `path_name`
   - `blocks`: array of block_ids
   - `color`: tier color of the highest-tier block in the connection

Sort connections by the highest BR score of their connected blocks (most important connections first).

**Connection limit:** If more than 8 connections, apply priority rules from big-block-layouts.md:
1. All Tier 1 connections (always shown)
2. Cross-tier connections
3. Drop intra-tier lower-tier connections

---

### Step 4: Assign Implementation Waves

> **WHY:** Waves turn the Big Block from a static snapshot into an actionable roadmap. They answer "what do we do first?" — the most common executive question.

Assign each solution to a wave based on tier and foundation readiness:

- **Wave 1 (Quick Wins, 0-6 months):** Tier 1 solutions with foundation_factor >= 0.95
- **Wave 2 (Strategic Build, 6-18 months):** Remaining Tier 1 + Tier 2 solutions, or solutions needing foundation investment
- **Wave 3 (Future Positioning, 18-36 months):** Tier 3-4 solutions and solutions with foundation_factor < 0.90

If the value-modeler already assigned waves (via `implementation_roadmap`), use those. Otherwise compute from the rules above.

---

### Step 5: Extract SPIs and Foundations

> **WHY:** SPIs and Foundations are the "how" behind the "what" — they show executives that adopting solutions requires organizational change and infrastructure investment, not just procurement.

**SPIs (Solution Process Improvements):**
- Collect all SPIs from the value-modeler output
- For each SPI: id, name (localized), linked solution IDs, description
- Sort by number of linked solutions (most impactful first)
- Cap at 6 for the visual (canvas space constraint)

**Foundations:**
- Collect all unique foundation requirements across all STs
- For each foundation: id, name (localized), maturity level, dependent solution IDs, description
- Sort by dependent solution count
- Cap at 4 for the visual

---

### Step 6: Preview and Confirm

If `interactive=true`:

Present a summary table:

```
Big Block Summary:
- Tier 1 (Mission Critical): {n} solutions
- Tier 2 (High Impact): {n} solutions
- Tier 3 (Moderate): {n} solutions
- Tier 4 (Low Priority): {n} solutions
- Portfolio gaps: {n}
- Path connections: {n}
- SPIs: {n}
- Foundations: {n}
- Waves: 3 ({w1} quick wins, {w2} strategic, {w3} future)
```

Ask via AskUserQuestion: "Proceed with this Big Block structure, or adjust?"

If non-interactive: skip this checkpoint.

---

### Step 7: Validate & Write Brief

> **WHY:** Validation catches structural issues before rendering. A brief with mismatched block IDs or orphaned connections will produce a broken diagram.

**Validate:**

1. **Schema check:** All required fields present, valid YAML, block_ids unique
2. **Tier consistency:** Every block's br_score matches its tier assignment
3. **Connection integrity:** All block_ids in connections exist in the tier sections
4. **SPI links:** All linked solution IDs in SPIs reference existing blocks
5. **Foundation links:** All dependent solution IDs reference existing blocks
6. **Wave coverage:** Every block has a wave assignment
7. **Canvas fit:** Total blocks <= canvas maximum from big-block-layouts.md
8. **Umlaut scan (German only):** Check all text fields for ASCII umlaut substitutions

**Output path resolution:**
- If `output_path` explicitly provided: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/big-block-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

**Write the brief** following `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_BIG_BLOCK_BRIEF.md` format:

- YAML frontmatter: type (`big-block-brief`), version (`1.0`), theme, theme_path, customer, provider, industry, language, canvas_size, canvas_pixels, source paths, scoring summary, title, subtitle
- Tier sections: Each tier with tier metadata + solution blocks
- SPIs section: Process change cards
- Foundations section: Infrastructure prerequisites
- Path connections: Connection map
- Implementation roadmap: Wave assignments
- Generation metadata: Solution counts, gap count, validation results

---

## Bundled Resources

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **big-block-layouts.md** | 1, 7 | Canvas dimensions, block sizing, tier band specs, connection routing |
| **EXAMPLE_BIG_BLOCK_BRIEF.md** | 7 | Output format reference |

### No Additional References Needed

Unlike narrative-based skills, the Big Block skill doesn't need arc taxonomy, story world brainstorming, or copywriting references. The source data (value-modeler output) provides all content. The skill's job is organization and structuring, not content generation.
