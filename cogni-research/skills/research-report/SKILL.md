---
name: research-report
description: |
  Generate a multi-agent research report using parallel web, local document, or wiki
  research with structural review. Three modes: basic (fast single-pass), detailed
  (multi-section with outline), deep (recursive tree exploration). Four source modes:
  web (default), local (user's files), wiki (cogni-wiki), hybrid. Requires an initialized
  project — routes to research-setup first if none exists. Runs localized search for the
  project's configured market (10 supported: DACH, DE, FR, IT, PL, NL, ES, US, UK, EU)
  with intent-based bilingual search and per-market authority sources. Use whenever the user asks
  for a research report, wants to investigate a topic, says "deep research", "gpt-researcher
  style", "multi-agent research", "analyze these documents", "research from my files",
  "query the wiki", or requests comprehensive topic analysis with citations. Claims
  verification runs separately via verify-report. For resuming an interrupted run or
  checking report progress, use research-resume instead.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, Task, Skill
---

# Research Report Skill

This skill executes the research pipeline (Phases 0.5-6) on an initialized project. Configuration and project creation are handled by the **research-setup** skill — this skill does not present configuration menus or ask the user for preferences.

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

1. Skill checks for an initialized project (project-config.json)
2. Not found -> invokes `Skill("research-setup")` with the user's topic. Setup handles all configuration turns.
3. After setup completes, reads project-config.json and starts Phase 0.5.

**Result**: A 5000-10000 word report with inline citations, produced via:
1. Topic decomposition into sub-questions
2. Parallel web research (sonnet agents, one per sub-question)
3. Context aggregation and source deduplication
4. Report compilation (sonnet writer agent)
5. Structural review and polish
6. Final report at `output/report.md`

Then run `/verify-report` to verify claims against cited sources in a fresh context window.

## Prerequisites

- Active workspace directory for project output
- cogni-claims plugin installed (for claims-verified review loop)

## Report Types

| Type | Trigger | Sub-Questions | Words | Use Case |
|------|---------|--------------|-------|----------|
| **basic** | "research report on X" | 5 | 3000-5000 | Standard research report |
| **detailed** | "detailed research report on X" | 5-10 | 5000-10000 | Comprehensive analysis |
| **deep** | "deep research on X" | 10-20 (tree) | 8000-15000 | Maximum depth + breadth |
| **outline** | "outline on X" | 5 | 1000-2000 | Structured framework, no prose |
| **resource** | "sources on X", "reading list" | 5 | 1500-3000 | Annotated bibliography |

Default: **basic** unless user specifies otherwise.

## References Index

Read these reference files when the corresponding phase needs them:

| Reference | Read When |
|-----------|-----------|
| `references/report-types.md` | Phase 1 — choosing report type and planning |
| `references/sub-question-generation.md` | Phase 1 — decomposing user query |
| `references/deep-research-tree.md` | Phase 1 (deep mode) — building research tree |
| `references/model-strategy.md` | Phase 1.5 — cost estimate table for plan preview |
| `references/agent-roles.md` | Phase 1 — auto-selecting researcher role |
| `references/writing-tones.md` | Phase 0 — resolving tone parameter |
| `references/citation-formats.md` | Phase 0 — resolving citation format |
| `references/review-criteria.md` | Phase 5 — understanding review scoring |

## Workflow

### Phase 0: Project Prerequisite

Check for an initialized project. Look for `project-config.json` in:
1. Path provided by user (if any)
2. `cogni-research/{topic-slug}/.metadata/project-config.json` (relative to cwd)
3. `./{topic-slug}/.metadata/project-config.json`

**If project-config.json exists**: Store `PROJECT_PATH` and continue to Phase 0.1.

**If project-config.json does NOT exist**: Invoke `Skill("research-setup", args: "<user's original request>")` and STOP. Do not proceed to any research phase. The research-setup skill handles all configuration and project initialization. After setup completes, read the created `project-config.json` and continue to Phase 0.1.

### Phase 0.1: Market & Language Resolution

Read `market` and `output_language` from `project-config.json` (stored by `initialize-project.sh`). These control search localization and report output language respectively.

Backward compatibility: `market` is normally written by `initialize-project.sh` from the resolved research-setup choice. The only auto-fallback still in place is legacy `--language de` → `market=dach`; any other missing-market case is rejected by the script, so you should never see a project without a real market here. If `output_language` is absent, look up the market's `default_output_language` in `${CLAUDE_PLUGIN_ROOT}/references/market-sources.json`, falling back to `"en"`.

**`MARKET`** controls search localization for researcher agents:
- Researcher agents load `${CLAUDE_PLUGIN_ROOT}/references/market-sources.json` and use the market entry to generate intent-based bilingual queries, boost authority sources, and apply geographic modifiers
- Unknown market codes fall back to `_default` (English-only, no authority boosts)

**`OUTPUT_LANGUAGE`** controls report output for writer/reviewer/revisor:
- Writer produces the report in the specified language
- Reviewer evaluates prose quality in the output language

Available markets (keys of `references/market-sources.json`): `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. There is no `global` option — research-setup resolves ambiguity by asking the user before the project is initialized. The market and output language are usually aligned (e.g., market=dach → output_language=de, market=it → output_language=it) but can diverge (e.g., market=fr, output_language=en for an English report about the French market). The `eu` market is a composite that fans out per-country researchers — see composite dispatch below.

#### Composite Market Dispatch (market=eu)

When `market` is `"eu"`, load the market entry from `market-sources.json` and check for the `composite_markets` field. If present:

1. **Store composite context**: `COMPOSITE_MARKETS` = `["de", "fr", "it", "pl", "nl", "es"]`, `IS_COMPOSITE` = true
2. **Default output language to English**: Cross-market reports are written in English unless explicitly overridden
3. **Phase 1 sub-question generation**: Generate sub-questions with two types:
   - **Market-specific**: Questions about individual countries (e.g., "What is the regulatory landscape for LEO satellite in Italy?"). Tag with `target_market: "it"`
   - **Cross-market**: Questions comparing across countries or about EU-wide aspects (e.g., "How do European spectrum allocation policies compare across DE, FR, IT, PL, NL, ES?"). Tag with `target_market: "eu"`
4. **Phase 2 researcher dispatch**: For market-specific sub-questions, dispatch section-researcher with `MARKET=<country>`. For cross-market sub-questions, dispatch section-researcher with `MARKET=eu` (uses EU-wide authority sources + geographic modifiers for all 6 countries)
5. **EU-wide sources**: The `eu` entry in market-sources.json provides EU-level authority sources (EUR-Lex, Eurostat, ESA, BEREC, ETNO, DigitalEurope) used for cross-market questions

This approach leverages the existing parallel researcher dispatch — the composite market simply maps to more researchers with different market parameters. No new agent types needed.

### Phase 0.5: Preliminary Search

**PREREQUISITE**: `project-config.json` must exist. If it does not, STOP — invoke `Skill("research-setup")` to configure and initialize the project. Do not proceed without an initialized project.

Before generating sub-questions, gather context about what information is actually available online. Sub-questions generated in a vacuum often target angles that have no searchable content, wasting researcher agents on dead ends.

1. Run 2-3 broad WebSearch queries on the user's topic
2. Review top 3-5 result snippets to understand the information landscape
3. Note: dominant angles, key organizations, recent developments, terminology
4. Feed these observations as context when generating sub-questions in Phase 1

### Phase 1: Sub-Question Generation

The quality of sub-questions determines the quality of the entire report. Orthogonal decomposition prevents researchers from duplicating each other's work, while collectively exhaustive coverage prevents blind spots. Poor sub-questions produce redundant contexts and missing perspectives that the review loop cannot fix — it can only catch factual errors, not structural gaps.

**Read**: `references/sub-question-generation.md` for decomposition patterns.

Use the preliminary search context from Phase 0.5 to inform sub-question generation — ensure questions target angles that have actual web content available.

**Agent Role Selection**: If `researcher_role` is already set in `project-config.json` (user-specified via `--researcher-role`), use it directly. Otherwise, auto-select the best-fit persona by reading `${CLAUDE_PLUGIN_ROOT}/references/agent-roles.md` and matching the topic's domain signals against the role catalog. Store the selected role in `project-config.json` as `researcher_role` and pass it to the writer agent as `RESEARCHER_ROLE`.

Generate sub-questions based on report type. If `max_subtopics` is set in `project-config.json`, use that count instead of the defaults below:

**Basic (default 5 sub-questions, or `max_subtopics` if set)**:
1. Decompose the topic into orthogonal research questions — more sub-questions mean more parallel researchers, which means more diverse sources and richer context for the writer
2. Each question should target a distinct aspect of the topic
3. Include: background/context, current state, key developments, challenges/limitations, implications/outlook

**Detailed (default 5-10 section outline, or `max_subtopics` if set)**:
1. Generate a multi-section outline first
2. Create one sub-question per section
3. Include: executive framing, multiple analytical angles, cross-cutting themes, recommendations

**Outline (default 5 sub-questions, or `max_subtopics` if set)**:
1. Same decomposition as basic — generate orthogonal sub-questions
2. Add `search_guidance` emphasizing key findings and structure over depth
3. Writer will produce hierarchical outline, not prose

**Resource (default 5 sub-questions, or `max_subtopics` if set)**:
1. Same decomposition as basic — generate sub-questions targeting distinct source categories
2. Add `search_guidance` emphasizing source diversity and quality over depth of individual findings
3. Writer will produce annotated bibliography, not narrative

**Deep (research tree, `max_subtopics` controls leaf count if set)**:
Read `references/deep-research-tree.md` for tree decomposition algorithm.
1. Decompose into 3-5 top-level branches
2. For each branch, generate 2-3 sub-branches
3. Create sub-question entities for all leaf nodes

For each sub-question, create entity:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "${PROJECT_PATH}" \
  --entity-type sub-question \
  --data '{"frontmatter": {"query": "...", "parent_topic": "...", "section_index": N, "report_type": "basic", "search_guidance": "...", "status": "pending"}, "content": ""}' \
  --json
```

### Phase 1.5: Execution Plan Preview

Search strategy is not an implementation detail — it is a cost/quality trade-off the user should see and be able to steer before agents start spawning. Deep + hybrid on a 13-sub-question topic can quietly become 26+ researchers and $2-3 of spend; silently picking `deep-researcher` over `section-researcher`, or `batch_size=4` over `batch_size=2`, hides decisions the user would often prefer to make themselves. This phase surfaces the plan, explains the trade-offs in plain language, and lets the user confirm or adjust before any researcher is dispatched.

This phase runs after Phase 1 (sub-questions already created) and before Phase 2 (researcher fan-out). It makes no LLM calls and spawns no agents — it computes, prints, asks, and records.

#### 1.5a: Compute the plan

Read the just-created sub-question entities and the full `project-config.json`, then derive a plan object (in your head — no script, this is a few lines of arithmetic):

```
plan = {
  "report_type":        <from project-config.json>,
  "sub_question_count": <actual count in 00-sub-questions/data/>,
  "source_mode":        <report_source from project-config.json>,
  "channels":           <resolved list — see below>,
  "web_agent":          <"deep-researcher" if deep mode AND recursive_depth > 0,
                         else "section-researcher">,
  "recursive_depth":    <recursive_depth from project-config.json.
                         Default resolution: if the field is absent or null,
                         use 2 when report_type == "deep", otherwise 0.
                         This default matters — a missing field in deep mode
                         must NOT silently downgrade to flat section-researcher.
                         A user who consciously wants depth=0 in deep mode can
                         still choose "Disable recursion" in 1.5c>,
  "batch_size":         <batch_size from project-config.json; default 4>,
  "total_agents":       <sub_question_count × number of active channels>,
  "batch_count":        <ceil(total_agents / batch_size)>,
  "est_cost_usd":       <from references/model-strategy.md cost table,
                         matched by report_type × source_mode>,
  "curate_sources":     <true if detailed/deep AND projected source count ≥ 8,
                         OR if curate_sources is explicitly true in config;
                         false if explicitly false>
}
```

**Resolving `channels`** (the set of researcher types that will actually run):
- `source_mode == "web"`   → `["web"]`
- `source_mode == "local"` → `["local"]` (requires `document_paths`)
- `source_mode == "wiki"`  → `["wiki"]` (requires `wiki_paths`)
- `source_mode == "hybrid"` → include `"web"` always; add `"wiki"` if `wiki_paths` set; add `"local"` if `document_paths` set

If `source_mode == "hybrid"` but neither `wiki_paths` nor `document_paths` is set, `channels` collapses to `["web"]` only. Don't fail — the user asked for hybrid and should get the web leg — but flag this silent downgrade in the 1.5b trade-off lines (see below) so they can fix the config if they meant otherwise.

**Cost estimate** lookup: use the row from `references/model-strategy.md` ("Cost Estimation" table) that matches `report_type × source_mode`. Do not compute a new cost formula — the table is the source of truth. For the hybrid row, report the full low–high range.

#### 1.5b: Print the plan

Print this summary **unconditionally** — even when `confirm_plan=false`. Silent mode only suppresses the confirmation question in 1.5c; the plan itself should always appear in the transcript so the cost/quality decision is auditable after the fact. A silent run that never showed the user what was about to happen defeats the whole point of this phase.

Produce a compact text summary for the user. Use this exact shape (fill in the computed values):

```
## Execution plan

Topic: <topic from project-config.json>
Report type: <type> → <sub_question_count> sub-questions generated
Source mode: <mode> (channels: <comma-separated channels>)

Per sub-question:
  • web    → <web_agent> (recursion: <on depth=N | off>)
  • wiki   → wiki-researcher       (only if wiki in channels)
  • local  → local-researcher      (only if local in channels)

Fan-out: <sub_question_count> sub-Q × <channel_count> channel(s) = <total_agents> researchers
Batching: <batch_size> concurrent → <batch_count> batches
Source curation: <enabled | disabled> (<reason>)
Estimated cost: $<low> – $<high>  (from model-strategy.md, <type>[ (hybrid)])

Trade-offs:
  • Recursion <on|off>: <one-line explanation of the choice and what flipping it would cost>
  • <source-mode-specific note>
  • Batch size <N>: <rate-limit vs. speed note>
```

The trade-off lines are where the user actually learns the cost/quality geometry. Keep them short and concrete. Examples:

- "Recursion off: faster and roughly 2–3× cheaper than recursive deep-research. Turn it on if a sub-question genuinely needs multi-hop exploration rather than one good pass."
- "Recursion on (depth 2): each web sub-question explores 2–3 follow-ups internally. Better coverage, roughly 2–3× the web cost."
- "Hybrid channels: wiki and local are cheap file reads; the web channel is the long pole for cost and time."
- "Hybrid requested but no wiki/document paths configured → running web-only. Add `document_paths` or `wiki_paths` in project-config.json to activate the other channels." (only when hybrid degraded to web-only per 1.5a)
- "Batch size 4: respects WebFetch rate limits. Drop to 2 if you've seen rate-limit errors on this market; raise to 6 only if you've verified the market is quiet."

#### 1.5c: Confirm or adjust

If `confirm_plan` is `false` in project-config.json, skip only the `AskUserQuestion` below — the plan from 1.5b has already been printed, and 1.5d will still record it. Continue to Phase 2 with `user_confirmed: false` in the recorded plan.

Otherwise, ask the user exactly one `AskUserQuestion` with these options — include only those that are meaningful for the current plan:

| Option | When to offer | Effect |
|---|---|---|
| **Proceed as planned** | always | Continue to Phase 2 with the current plan values |
| **Fewer sub-questions** | always | Ask for a new count (text output), regenerate sub-question entities, recompute the plan, and re-display |
| **Enable recursion** | only if `report_type == "deep"` AND `recursive_depth == 0` | Set `recursive_depth=2`, switch `web_agent` to `deep-researcher`, recompute cost, re-display |
| **Disable recursion** | only if `report_type == "deep"` AND `recursive_depth > 0` | Set `recursive_depth=0`, switch `web_agent` to `section-researcher`, recompute cost, re-display |
| **Web-only** | only if `source_mode == "hybrid"` | Drop wiki and local from `channels`, recompute fan-out and cost, re-display |
| **Smaller batches** | only if `batch_size > 2` | Set `batch_size=2`, recompute batch count, re-display |
| **Abort** | always | Write the abort marker to `execution-log.phases.phase_1_5_plan` in 1.5d (see below) and stop without spawning any researcher |

When the user picks a non-Proceed option, apply the change, recompute 1.5a, re-print 1.5b, and ask again. Cap this loop at two rounds — after the second adjustment, default to Proceed on the next turn to avoid endless re-planning on unclear input.

Adjustments that mutate `project-config.json` (recursion depth, batch size, channels, max_subtopics from a "Fewer sub-questions" choice) should be written back so resumed runs inherit the user's decision. Adjustments to sub-question count require deleting the existing sub-question entities and regenerating them via Phase 1 before returning to 1.5a.

#### 1.5d: Record the plan

Whether the user confirmed or silent mode was active, write the final plan object to `.logs/phase-1.5-plan.json` so the user can audit it later and so Phase 2 reads a single source of truth for `web_agent`, `channels`, `batch_size`, and `recursive_depth`.

Also record a completion marker in `.metadata/execution-log.json` under `phases.phase_1_5_plan`, so `research-resume` can detect "plan locked, researchers not yet dispatched" without parsing the full plan file:

```json
{
  "phase_1_5_plan": {
    "status": "done",
    "web_agent": "section-researcher",
    "channels": ["web"],
    "batch_size": 4,
    "recursive_depth": 0,
    "sub_question_count": 5,
    "total_agents": 5,
    "est_cost_usd": "0.15-0.40",
    "confirmed_at": "<ISO-8601 timestamp>",
    "user_confirmed": true
  }
}
```

`.logs/phase-1.5-plan.json` remains the full source of truth (including trade-off prose and curation flag); this execution-log entry is the compact summary the resume dashboard surfaces. If the user picked **Abort** in 1.5c, write `{"status": "aborted", "aborted_at": "<ISO timestamp>"}` instead — Phase 2 will check for this marker on re-entry.

### Phase 2: Parallel Web Research

Parallel execution is the key throughput optimization — a basic report with 5 sub-questions completes research in the time of one. All researchers use sonnet for richer source extraction and better findings quality. Each agent runs independently, so a failure in one does not block the others.

**Abort-marker pre-check.** Before reading the plan, check `.metadata/execution-log.json` for `phases.phase_1_5_plan.status == "aborted"` (or an `aborted_at` field). If set, the previous session aborted in Phase 1.5 — do not silently dispatch researchers on the old plan. Re-enter Phase 1.5 (recompute, re-print, re-confirm) and clear the abort marker in 1.5d once the user confirms a new plan. This preserves the "user owns the cost/quality decision" guarantee across session boundaries.

Read the confirmed plan from `.logs/phase-1.5-plan.json` — it is the single source of truth for `web_agent`, `channels`, `batch_size`, and `recursive_depth`. Do not re-derive these values from `project-config.json` in this phase, because the user may have adjusted them during Phase 1.5 without the changes being written back to config.

#### Web mode (report_source = "web", default)

Resolve the current year for recency-aware search queries:
```bash
CURRENT_YEAR=$(date +%Y)
```

Spawn web researcher agents in parallel batches of `batch_size` (from the plan).

The agent type is `plan.web_agent` — either `section-researcher` (no recursion) or `deep-researcher` (recursive). Deep mode defaults to `deep-researcher` at depth 2, but the user may have disabled recursion in Phase 1.5, in which case deep mode runs through `section-researcher` across the full leaf sub-question set.

**`section-researcher` path** (all modes when `plan.web_agent == "section-researcher"`):
```
For each sub-question entity in 00-sub-questions/data/:
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    run_in_background=true)
```

**`deep-researcher` path** (deep mode when `plan.web_agent == "deep-researcher"`):
```
For each leaf sub-question in 00-sub-questions/data/:
  Task(deep-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    DEPTH=<plan.recursive_depth>,
    run_in_background=true)
```

#### Local mode (report_source = "local")

Spawn local-researcher agents instead of section-researchers. All sub-questions research from the same document set, but each agent extracts findings relevant to its specific sub-question.

```
For each sub-question entity in 00-sub-questions/data/:
  Task(local-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    DOCUMENT_PATHS=<from project-config.json document_paths>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Deep mode with local sources: use local-researcher (not deep-researcher). The recursive tree algorithm is designed for web search breadth — local documents don't benefit from recursive decomposition. If the user requests deep + local, run local-researchers with the deep sub-question tree but without internal recursion.

#### Wiki mode (report_source = "wiki")

Spawn wiki-researcher agents instead of section-researchers. Each agent queries all configured cogni-wiki instances for findings relevant to its sub-question. The wiki-researcher follows wiki-query's index-first discovery pattern: read `wiki/index.md`, select relevant pages, read those pages, extract grounded findings.

```
For each sub-question entity in 00-sub-questions/data/:
  Task(wiki-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    WIKI_PATHS=<comma-separated wiki roots from project-config.json wiki_paths>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Deep mode with wiki sources: use wiki-researcher (not deep-researcher), same rationale as local — the recursive tree algorithm is designed for web search breadth, not pre-synthesized knowledge.

#### Hybrid mode (report_source = "hybrid")

Run the researcher types listed in `plan.channels` in parallel, then merge all findings in Phase 3. This produces the richest context.

Hybrid mode is additive: each active channel gets the full sub-question set. If deep mode produces 8 leaf sub-questions and `plan.channels` is `["web", "wiki"]`, hybrid spawns 8 web-researchers + 8 wiki-researchers (16 total). Wiki and local researchers are cheap (local file reads, no rate limiting), so the added coverage usually justifies the extra agents — but the user can drop channels via the "Web-only" option in Phase 1.5 if they want a cheaper run.

```
For each sub-question entity in 00-sub-questions/data/:
  # Wiki research (only if "wiki" in plan.channels)
  if "wiki" in plan.channels:
    Task(wiki-researcher,
      SUB_QUESTION_PATH=<path>,
      PROJECT_PATH=<project_path>,
      WIKI_PATHS=<comma-separated wiki roots from project-config.json wiki_paths>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

  # Local research (only if "local" in plan.channels)
  if "local" in plan.channels:
    Task(local-researcher,
      SUB_QUESTION_PATH=<path>,
      PROJECT_PATH=<project_path>,
      DOCUMENT_PATHS=<from project-config.json document_paths>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

  # Web research (always active in hybrid — always in plan.channels)
  Task(<plan.web_agent>,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    DEPTH=<plan.recursive_depth>,   # only if plan.web_agent == "deep-researcher"
    run_in_background=true)
```

All researcher types create separate context entities for the same sub-question. The merge-context script (Phase 3) handles deduplication across wiki, local, and web sources.

Batch in groups of `plan.batch_size` to respect concurrency limits. Wait for each batch before starting next.

After all researchers complete:
- Check return values for failures
- Update sub-question entity status to "researched" or "failed"
- Log results to `.logs/phase-2-research.jsonl`

### Phase 2.5: Source Curation (conditional)

Source curation ranks sources by quality, relevance, authority, and recency before the writer sees them. This prevents the writer from treating all sources equally when some are clearly more authoritative.

**Activation rules** (check in order):
1. If `curate_sources` is explicitly `false` in project-config.json → **skip**
2. If `curate_sources` is explicitly `true` → **run** (any report type, any source count)
3. If report type is `detailed` or `deep` AND source entity count >= 8 → **run**
4. Otherwise → **skip**

When activated:
```
Task(source-curator,
  PROJECT_PATH=<project_path>,
  MARKET=<market>)
```

The source-curator produces `.metadata/curated-sources.json` with quality rankings (primary/secondary/supporting tiers) and diversity analysis. The writer agent reads this in Phase 4 to prioritize citations.

### Phase 3: Context Aggregation

Aggregation deduplicates sources and enforces a context word limit (25,000 words) to prevent writer overload. Without this step, deep reports with 15+ researchers can produce far more raw context than a single writer agent can meaningfully synthesize, leading to shallow treatment of all topics rather than deep treatment of each.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/merge-context.py" \
  --project-path "${PROJECT_PATH}" --json
```

Verify output: contexts count, sources count, total words. If too few sources (< 3), consider re-running failed sub-questions.

### Phase 4: Report Writing

The writer path branches by report type. **Deep mode uses section-sharded dispatch (Phase 4a/4b/4c)** to escape the single-response output ceiling that pins monolithic deep drafts at ~4–5K words regardless of their declared budget. **Every other mode (basic, detailed, outline, resource) uses the historical single-pass dispatch** — they work today and do not need sharding.

#### Phase 4 (non-deep modes — basic, detailed, outline, resource)

Spawn writer agent in full mode:
```
Task(writer,
  PROJECT_PATH=<project_path>,
  DRAFT_VERSION=1,
  REPORT_TYPE=<type>,
  RESEARCHER_ROLE=<role from project-config.json>,
  TONE=<tone from project-config.json, default "objective">,
  CITATION_FORMAT=<citation_format from project-config.json, default "apa">,
  OUTPUT_LANGUAGE=<output_language>)
```

Note: no `WRITER_MODE` parameter — the writer defaults to `full` mode and produces both the outline and the complete draft in one response.

Verify: writer's outline plan written to `.metadata/writer-outline-v1.json` (see `agents/writer.md` Phase 1). **The authoritative file-existence check for the draft itself happens in Phase 4.5 Step 0 below** — do not treat the writer's return JSON as proof of persistence, and do not assume `output/draft-v1.md` exists until Step 0 has confirmed it.

#### Phase 4a (deep mode — outline commit)

Spawn writer agent in outline-only mode. This call commits the section plan and budgets but writes no prose.

```
Task(writer,
  PROJECT_PATH=<project_path>,
  DRAFT_VERSION=1,
  REPORT_TYPE=deep,
  WRITER_MODE=outline,
  RESEARCHER_ROLE=<role>,
  TONE=<tone>,
  CITATION_FORMAT=<citation_format>,
  OUTPUT_LANGUAGE=<output_language>)
```

Verify `.metadata/writer-outline-v1.json` exists, has `"sections"` array with at least 3 entries, every section has a zero-padded two-digit `"index"`, and `sum(budgets) >= 8400` (5% headroom over the 8,000 deep floor). If any check fails, halt Phase 4 with a user-visible error pointing to the outline file — do not fall through to Phase 4b with a broken plan.

#### Phase 4b (deep mode — per-section context slicing and section fan-out)

1. **Slice aggregated context per section.** Run:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/merge-context.py" \
     --project-path "${PROJECT_PATH}" --slice-sections --draft-version 1 --json
   ```
   This reads `.metadata/writer-outline-v1.json` + `.metadata/aggregated-context.json` and emits `.metadata/section-contexts/section-{NN}.json` — one compact slice per outline entry, containing only the contexts whose `sub_question_ref` is in the section's `covers_sub_questions` plus the sources those contexts cite. The slice is small by design; each section writer reads one file instead of the full 45K-word aggregated context.

2. **Initialize the rolling section summary.** Create `.metadata/section-summary.txt` as an empty file. This file accumulates a one-paragraph running summary of sections already written and is passed to each subsequent section writer via `PRIOR_SECTIONS_SUMMARY` for coherence.

3. **Dispatch section writers sequentially.** For each section entry in `.metadata/writer-outline-v1.json` (in outline order), dispatch one writer call:
   ```
   Task(writer,
     PROJECT_PATH=<project_path>,
     DRAFT_VERSION=1,
     REPORT_TYPE=deep,
     WRITER_MODE=section,
     SECTION_INDEX=<section.index>,
     SECTION_HEADING=<section.heading>,
     SECTION_BUDGET=<section.budget>,
     CONTEXT_SLICE_PATH=.metadata/section-contexts/section-<section.index>.json,
     PRIOR_SECTIONS_SUMMARY=<contents of .metadata/section-summary.txt, or empty string for section 00>,
     RESEARCHER_ROLE=<role>,
     TONE=<tone>,
     CITATION_FORMAT=<citation_format>,
     OUTPUT_LANGUAGE=<output_language>)
   ```
   After each section dispatch returns, verify `.metadata/draft-sections/section-{index}.md` exists and is non-empty. If missing or empty, re-dispatch that section **once** with `EXPANSION_NOTES="Your previous run did not persist the section file. Call the Write tool with the full section markdown as content, then Read it back to verify. Return only the compact status JSON."` On a second failure, halt Phase 4 with a user-visible error naming the section index.

   After verifying the section file, append a one-sentence summary of that section to `.metadata/section-summary.txt` for the next dispatch. Keep the rolling summary under 500 words total — if it grows past that, trim the oldest entries. This is a cheap coherence tether, not a full recap.

   **Sequential, not parallel.** Deep-mode section dispatch runs one section at a time so the rolling summary stays in order and so each section can reference the evidence already used by prior sections without restating it. The cost overhead vs. parallel dispatch is minor (section-writer calls are ~$0.02 each) and the coherence benefit is real.

4. **Assemble the draft.** After all sections are written, run:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/assemble-draft.sh" \
     --project-path "${PROJECT_PATH}" --draft-version 1
   ```
   This concatenates `.metadata/draft-sections/section-*.md` in outline order to `output/draft-v1.md`, updates each section entry's `drafted_words` field in `writer-outline-v1.json` with the actual word count, and exits non-zero if any section is below 80% of its declared budget. Parse the JSON output — the `deficits` array names any sections that need Phase 4.5 per-section re-dispatch, and the `total_words` field is the authoritative draft length. No need to re-run `wc -w` separately.

#### Phase 4c (deep mode — draft file verification)

After `assemble-draft.sh` returns, confirm `output/draft-v1.md` exists and is non-empty — same existence check as non-deep Phase 4.5 Step 0. In the rare case the assembly step succeeded but the file was deleted between then and now, treat it as a Phase 4 halt: do not fall through to Phase 4.5 expansion logic, print a user-visible error, stop.

#### Phase 4.5: Word-count gate (authoritative, file-level)

The writer's self-reported `words` in return JSON has historically drifted (observed: agent claimed 12,500, actual file was 3,356). The orchestrator must measure the draft itself, not trust the agent's self-report.

**Deep mode note:** Phase 4c already confirmed `output/draft-v1.md` exists, and `assemble-draft.sh` already wrote per-section `drafted_words` into the outline plus returned a `deficits` array. In deep mode, Step 0 below collapses to "the file exists" (already confirmed in Phase 4c), Steps 1–2 run against the assembled draft, and the re-dispatch branch in Step 4 uses **per-section re-dispatch** rather than a whole-draft re-dispatch. See "Deep mode per-section expansion" at the end of this section.

**Step 0: File-existence precheck (authoritative — non-deep modes only; deep mode covered by Phase 4c).** Before measuring word count, confirm that the writer actually persisted the draft. In hybrid and full-mode runs the writer can exhaust its output token budget writing prose into its response body instead of calling the `Write` tool, leaving the file missing or zero-byte. The word-count gate below would then silently treat this as a catastrophic shortfall and trigger a full expansion re-dispatch for a run that needs a different fix entirely — the writer needs to be told to actually write the file, not to write more words.

- **0a. Existence check.** Test `[ -s "${PROJECT_PATH}/output/draft-v${DRAFT_VERSION}.md" ]` (exists and non-zero size). If the file is present, skip straight to the word-count measurement at step 1 below.
- **0b. Log the failure.** If the file is missing or empty, record `phases.phase_4_writer.write_failure` in `.metadata/execution-log.json`:
  ```json
  {"version": 1, "reason": "missing_or_empty_file", "recovery": "retry_dispatch"}
  ```
- **0c. Re-dispatch once.** Re-spawn the writer with the same parameters, reusing the same `DRAFT_VERSION` (not N+1, so the rest of the pipeline sees a normal v1 and the word-count gate below runs against the recovered file), plus an emphatic `EXPANSION_NOTES` that names the failure mode explicitly so the next writer invocation understands what went wrong:
  ```
  Task(writer,
    PROJECT_PATH=<project_path>,
    DRAFT_VERSION=<same N as before>,
    REPORT_TYPE=<type>,
    RESEARCHER_ROLE=<role>,
    TONE=<tone>,
    CITATION_FORMAT=<citation_format>,
    OUTPUT_LANGUAGE=<output_language>,
    EXPANSION_NOTES="Your previous run returned draft text in the response body instead of writing output/draft-v{N}.md to disk. Call the Write tool with the full drafted markdown as content. After Write returns, call Read on the same path to verify persistence. Return only the compact status JSON — never the drafted prose itself. See agents/writer.md Phase 3 for the read-back contract.")
  ```
- **0d. Re-check and decide.** After the retry, re-run the existence check. If the file is still missing or empty, **halt Phase 4**: print a user-visible error block containing the topic, the project path, and a pointer to `.metadata/execution-log.json phases.phase_4_writer.write_failure`, then stop. Do not fall through to the `wc -w` measurement or Phase 5 — a phantom draft would corrupt every downstream phase (reviewer, revisor, verify-report). If the retry succeeds, set `phases.phase_4_writer.write_failure.recovered: true` in the execution log so the Phase 6 summary can surface the recovery, then continue to the word-count measurement with the recovered file.

Only once Step 0 confirms the file is present (or Phase 4c confirmed it in deep mode) do the remaining gate steps apply:

1. Measure the actual word count from the file:
   ```bash
   ACTUAL_WORDS=$(wc -w < "${PROJECT_PATH}/output/draft-v1.md" | tr -d ' ')
   ```
2. Resolve the minimum floor for this report type:

   | Report type | Minimum floor |
   |---|---|
   | basic | 3000 |
   | detailed | 5000 |
   | deep | 8000 |
   | outline | 1000 |
   | resource | 1500 |

3. Compute `gate_floor`. **Deep mode tightens the floor to `1.0 × floor`** (no tolerance band) because Phase 4a/4b section dispatch is expected to reliably hit the budget — the historical 10% tolerance existed only to accommodate the broken single-pass monolithic dispatch. Non-deep modes keep the 10% tolerance:
   - Deep: `gate_floor = floor` (8,000 for deep — hard wall)
   - Basic / detailed / outline / resource: `gate_floor = floor × 0.9` (10% tolerance band, unchanged)
4. Decision (non-deep branch — deep mode uses the per-section branch below):
   - **`ACTUAL_WORDS >= gate_floor`** → gate passes. Continue to Phase 5.
   - **`ACTUAL_WORDS < gate_floor` AND `project-config.json` has `allow_short: true`** → log the deficit but skip the re-dispatch. Record `phase_4_word_deficit: {actual, floor, action: "allow_short_opt_out"}` in `.metadata/execution-log.json`. Continue to Phase 5.
   - **`ACTUAL_WORDS < gate_floor` AND no `allow_short` opt-out** → re-dispatch the writer **once** with:
     ```
     Task(writer,
       PROJECT_PATH=<project_path>,
       DRAFT_VERSION=2,
       REPORT_TYPE=<type>,
       RESEARCHER_ROLE=<role>,
       TONE=<tone>,
       CITATION_FORMAT=<citation_format>,
       OUTPUT_LANGUAGE=<output_language>,
       TARGET_MIN_WORDS=<floor>,
       EXPANSION_NOTES="Previous draft ({actual_words} words) fell below the {floor}-word {type}-mode minimum by {floor - actual_words} words. Read .metadata/writer-outline-v1.json and identify sections whose drafted length fell below their planned budget — expand those first. Add evidence density (cross-source comparison, implications, methodological context, concrete examples from untapped context entities). Do not add new top-level sections. Do not pad with filler or 'in conclusion' restatements.")
     ```
5. After the re-dispatch, measure `wc -w output/draft-v2.md`. If still below `gate_floor`, do NOT re-dispatch a third time — cap at one expansion attempt to bound cost. Instead:
   - Log `phase_4_word_deficit: {actual_v1, actual_v2, floor, action: "writer_cap_reached"}` in `.metadata/execution-log.json`
   - Continue to Phase 5 with `draft-v2.md` as the input — the reviewer's stepped completeness cap will downgrade the verdict, and the Phase 5 expansion-review loop (see Phase 5 below) gives the revisor one more chance to close the gap

**Deep mode per-section expansion (replaces Steps 4–5 in deep mode):**

Deep mode never re-dispatches the whole draft. Instead, Phase 4.5 consumes the `deficits` array that `assemble-draft.sh` already computed in Phase 4b Step 4, and re-dispatches only the underrunning sections.

- **D1. Parse the assembly report.** The JSON stdout from `assemble-draft.sh` includes `deficits: [{index, heading, budget, drafted_words, shortfall, ratio}, ...]`. If `deficits` is empty **and** `total_words >= 8000`, the gate passes — continue to Phase 5.
- **D2. `allow_short` opt-out.** If `project-config.json` has `allow_short: true`, log `phase_4_word_deficit: {total_words, floor, deficits, action: "allow_short_opt_out"}` and continue to Phase 5 without re-dispatch.
- **D3. Per-section re-dispatch.** For each entry in `deficits`, re-dispatch exactly that section via:
  ```
  Task(writer,
    PROJECT_PATH=<project_path>,
    DRAFT_VERSION=1,
    REPORT_TYPE=deep,
    WRITER_MODE=section,
    SECTION_INDEX=<deficit.index>,
    SECTION_HEADING=<deficit.heading>,
    SECTION_BUDGET=<deficit.budget>,
    CONTEXT_SLICE_PATH=.metadata/section-contexts/section-<deficit.index>.json,
    PRIOR_SECTIONS_SUMMARY=<current contents of .metadata/section-summary.txt>,
    RESEARCHER_ROLE=<role>,
    TONE=<tone>,
    CITATION_FORMAT=<citation_format>,
    OUTPUT_LANGUAGE=<output_language>,
    EXPANSION_NOTES="Previous section draft ({drafted_words} words) fell below the {budget}-word budget by {shortfall} words. Expand with additional evidence from the context slice — cross-source comparison, implications, methodological context, untapped findings. Do not pad with filler or restatements.")
  ```
  Reuse the same `SECTION_INDEX` so the re-dispatch overwrites `draft-sections/section-{index}.md` in place. Do not bump to `DRAFT_VERSION=2` — the whole outline is still v1, and only the deficient sections are being patched.
- **D4. Re-assemble and re-check.** After all per-section re-dispatches return, re-run `assemble-draft.sh` with the same arguments. Parse the new output. If `deficits` is still non-empty or `total_words < 8000`, **cap at one per-section expansion attempt** — log `phase_4_word_deficit: {total_words_v1, total_words_v2, floor, deficits_v2, action: "section_expansion_cap_reached"}` and continue to Phase 5. The Phase 5 expansion-review loop gives the revisor one more chance to close the gap.
- **D5. Record the gate outcome.** Write to `.metadata/execution-log.json` under `phases.phase_4_writer`:
  ```json
  {
    "phase_4_writer": {
      "mode": "deep_sectioned",
      "sections_dispatched": 10,
      "assembly_passes": [
        {"pass": 1, "total_words": 7200, "deficits": [{"index": "04", "budget": 1200, "drafted_words": 800}]},
        {"pass": 2, "total_words": 8350, "deficits": []}
      ],
      "floor": 8000,
      "gate_floor": 8000,
      "section_re_dispatches": 1,
      "allow_short": false,
      "gate_passed": true
    }
  }
  ```

6. Record the gate outcome in `.metadata/execution-log.json` under `phases.phase_4_writer` (non-deep modes only — deep mode uses the D5 shape above):
   ```json
   {
     "phase_4_writer": {
       "mode": "monolithic",
       "drafts": [
         {"version": 1, "actual_words": 3356, "self_reported_words": 12500, "gate_passed": false},
         {"version": 2, "actual_words": 8240, "self_reported_words": 8400, "gate_passed": true}
       ],
       "floor": 5000,
       "gate_floor": 4500,
       "re_dispatches": 1,
       "allow_short": false
     }
   }
   ```
   The `self_reported_words` field surfaces the honesty-drift signal — a large gap between self-reported and actual is informational (not a block), but useful diagnostics for maintainers.

### Phase 5: Structural Review

This phase runs a lightweight structural-only review to catch organizational and stylistic issues before finalization. Claims verification — the factual accuracy check — runs separately via the **verify-report** skill in a dedicated context window. This architectural split ensures claims verification gets full context attention rather than competing with research data from Phases 0-4.

**Read**: `references/review-criteria.md` for scoring rubric.

**Outline and Resource modes**: Accept the draft if structural score >= 0.65 or iterate once. Then proceed to Phase 6.

**Basic, Detailed, and Deep modes**: Run one structural review iteration as described below.

#### 5a: Review (structural only)
```
Task(reviewer,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  REVIEW_ITERATION=1,
  OUTPUT_LANGUAGE=<output_language>)
```

Note: no `CLAIMS_DASHBOARD` parameter — the reviewer runs structural criteria only (completeness, coherence, source diversity, depth, clarity). The higher accept threshold (0.82) for structural-only review applies automatically.

#### 5b: Revise (if verdict="revise")
```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  VERDICT_PATH=".metadata/review-verdicts/v1.json",
  NEW_DRAFT_VERSION=N+1,
  OUTPUT_LANGUAGE=<output_language>,
  MARKET=<market>)
```

**Iteration cap** — conditional on the verdict's issue profile:

- **Default: 1 structural review iteration.** After revision (or if the first review accepts), proceed to Phase 5.5. This is the common case and costs no more than today.
- **Exception: 2 iterations when iteration 1's verdict contains a high-severity issue whose text begins with `Word deficit`** (the exact phrase emitted by the reviewer's Word Count Gate — see `agents/reviewer.md`). When this issue is present, the revisor runs in expansion mode (see `agents/revisor.md` — the +20% cap is lifted for expansion). Without a second review pass, the expansion cannot be verified and the word-count gate would be a dead letter.
  - After the revisor produces `draft-v{N+1}.md`, re-run the reviewer once more with `REVIEW_ITERATION=2`, generating `.metadata/review-verdicts/v2.json`.
  - **Iteration-2 persistence is mandatory.** After the iteration-2 reviewer dispatch returns, verify that `.metadata/review-verdicts/v2.json` exists and is non-empty via `[ -s "${PROJECT_PATH}/.metadata/review-verdicts/v2.json" ]`. If missing, the reviewer failed to persist its verdict — log `phase_5_review.iteration_2_missing: true` in `.metadata/execution-log.json` and halt Phase 5 with a user-visible error. Do not fall through to Phase 5.5 or Phase 6 with an unverified post-revisor draft — the whole point of iteration 2 is to confirm whether the expansion closed the gap.
  - Regardless of the iteration-2 verdict (accept or revise), proceed to Phase 5.5 — no third iteration. The expansion-review loop is a one-shot: close the gap or log it and move on. **But record `phase_5_review.iteration_2_word_deficit_cleared: true|false`** based on whether v2.json still contains a `Word deficit` issue — Phase 6 reads this flag to decide whether to block promotion.
  - If `project-config.json` has `allow_short: true`, skip the second iteration entirely — the user opted out of auto-expansion in Phase 4.5, so there is no point spending tokens verifying an expansion that did not happen.

This narrow exception applies only to word-deficit deficits. Every other revise reason (structural issues, coherence gaps, source diversity) still caps at 1 iteration — no behavior change for the common case, no runaway cost.

### Phase 5.5: Visual Enrichment via cogni-visual (Optional)

Ask the user whether to generate a themed HTML version of the report with interactive charts and diagrams. This transforms the markdown report into a polished, presentation-ready HTML deliverable.

1. Check whether `cogni-visual:enrich-report` is available. If not installed, display a warning and skip to Phase 6.
2. Ask the user which visual pipeline to use:
   - **Option 1: Full visual pipeline** (recommended) — First create a dedicated infographic via `cogni-visual:story-to-infographic`, then render it via `/render-infographic`, then enrich the report via `cogni-visual:enrich-report`. Best results: the infographic header is Pencil-rendered with 10-step distillation, 4-layer validation, and reviewer agent.
   - **Option 2: Quick enrichment** — Run `cogni-visual:enrich-report` directly. It generates a simplified infographic inline (fewer validation steps, hardcoded to economist preset).
   - **Option 3: Skip** visual enrichment.
3. If the user declines (option 3), skip to Phase 6.
4. If option 1: invoke `cogni-visual:story-to-infographic` with `source_path` pointing to the final accepted draft, then `/render-infographic` to render it, then invoke `cogni-visual:enrich-report` (which will detect and reuse the infographic artifacts).
5. If option 2: invoke `cogni-visual:enrich-report` directly with `source_path` pointing to the final accepted draft (`output/report.md` if already copied, otherwise the latest `output/draft-v{N}.md`). The enrich-report skill handles theme selection, enrichment planning, and interactive review — do not duplicate that logic here.
6. Record the result for the Phase 6 summary.

### Phase 6: Finalization

**Promotion gate (new in v0.7.0).** Before copying the accepted draft to `output/report.md`, verify the word-count floor is actually cleared. In deep mode the gate is hard: if `output/draft-v{N}.md` is below 8,000 words **and** `allow_short: true` is not set, do not silently promote. Instead:

1. Measure the final draft: `wc -w < "${PROJECT_PATH}/output/draft-v${N}.md"`.
2. Resolve the floor from the table in Phase 4.5 Step 2 (8,000 for deep).
3. **Deep mode only**: if `actual_words < 8000` and `allow_short` is not `true`, present the user with an `AskUserQuestion` choice:
   - **Option A: Accept shorter report** — promote the draft anyway, record `phase_6_promotion.floor_override: true` and `phase_6_promotion.shortfall_words: <floor - actual>` in the execution log, and set `allow_short_accepted` in the summary.
   - **Option B: Retry deficient sections** — re-enter Phase 4.5 D3 with the current `deficits` array from the latest assembly report (if available) or from a fresh `assemble-draft.sh` run. Cap at one additional retry pass — if it still fails, fall through to the same question with Option B removed.
   - **Option C: Abort** — stop without promotion. Leave the latest `draft-v{N}.md` in place for manual inspection. Print the project path and a pointer to `.metadata/execution-log.json`.
4. For non-deep modes, keep the existing behavior: the reviewer's verdict and Phase 6 summary warnings are advisory. Short drafts are still promoted automatically with a `⚠ Below target` line in the summary.
5. For outline / resource modes, the per-type floor is advisory and promotion is never blocked.

Once the promotion gate passes (or the user selects Option A), continue with the existing finalization steps:

1. Copy final accepted draft to `output/report.md`
   - The project directory is a self-contained unit of output — report, sources, and metadata together, all Obsidian-browsable. Keep the canonical deliverable at `{project_path}/output/report.md` and do not copy or symlink it elsewhere. If the user wants a different format or location, the enrich-report phase (Phase 5.5) handles that.
2. **Accumulate cost estimates**: Sum `cost_estimate.estimated_usd` from all agent outputs collected during Phases 2-5. Group by agent role (researchers, writer, reviewer, revisor, claim_extractor, source_curator). Write cost summary to `execution-log.json`
3. Update `.metadata/execution-log.json` with:
   - Phase completion timestamps
   - Agent counts and durations
   - Final structural review score and iteration count
   - `phase_5_review.claims_verification: "deferred to verify-report"`
   - Cost summary: `{"total_estimated_usd": N, "breakdown": {"researchers": N, "writer": N, ...}}`
   - `enrich_report_applied`: true/false
   - `enrich_report_path`: path to enriched HTML or null
4. Report summary to user:
   - Topic and report type
   - **Word count**: always formatted as `Delivered: N words (target: {min}–{max} for {report_type} mode)`. Resolve `{min}` and `{max}` from the Report Types table in Phase 1 (basic 3000–5000, detailed 5000–10000, deep 8000–15000, outline 1000–2000, resource 1500–3000).
   - **Word-count gate status** — read `.metadata/execution-log.json phases.phase_4_writer`:
     - If `phases.phase_4_writer.write_failure` exists and `write_failure.recovered == true`: print `✓ Phase 4.5 write-failure recovery: writer persisted the draft on retry after a first-run silent-persist failure.` Then continue to the branches below — the write-failure line is additive, not a replacement for the word-count status.
     - If `re_dispatches == 0` and the final `actual_words >= floor`: do not print any warning
     - If `re_dispatches == 1` and the final `actual_words >= floor`: print `✓ Word-count gate: expansion re-dispatch succeeded ({v1} → {v2} words).` — a positive signal the gate earned its cost
     - If the final `actual_words < floor`: print `⚠ Below target by {floor - actual_words} words.` followed by one of:
       - `allow_short: true was set — expansion skipped.` (opt-out path)
       - `Writer re-dispatch cap reached after one attempt.` (cap-hit path)
     - If `phase_5_review.iteration_count == 2`: print `✓ Phase 5 expansion-review loop ran — reviewer re-verified the revised draft.`
   - Section count
   - Sources cited
   - Structural review score
   - **Estimated cost** (total USD from cost_summary)
   - Full absolute path to `output/report.md`
   - Project folder path (for browsing sources and metadata)
4. **Recommend next steps** (in order):

> **Next steps:**
> 1. `/verify-report` — Verify claims against cited sources. Runs in a clean context window for thorough fact-checking.
> 2. `/copywriter` — Polish the report for executive readability (BLUF structure, tighter prose, consistent tone).
> 3. `/story-to-infographic` + `/render-infographic` + `/enrich-report` — Create an editorial infographic first, then generate themed HTML with charts and diagrams. enrich-report detects and reuses the infographic. (Skip if already done in Phase 5.5.)

## Resumption

If a project directory already exists at init:
1. Read `.metadata/execution-log.json` for phase completion state
2. Check which entity directories have data
3. Resume from the first incomplete phase
4. Report resumption status to user

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| All researchers fail | Ask user to rephrase topic or try different sub-questions |
| Most researchers fail | Proceed with available contexts, note gaps in report |
| Writer returns `write_failed` (read-back verification failed twice) | Phase 4.5 Step 0 detects the missing/empty draft file, logs `phases.phase_4_writer.write_failure` in `.metadata/execution-log.json`, and re-dispatches the writer once — reusing the same `DRAFT_VERSION` — with emphatic `EXPANSION_NOTES` naming the silent-persist failure mode. On a second failure, Phase 4 halts with a user-visible error pointing to the log entry — no phantom draft reaches Phase 5. On successful recovery, the Phase 6 summary prints the `✓ Phase 4.5 write-failure recovery` line |
| Draft file missing or zero-byte after writer returns `ok` | Same Phase 4.5 Step 0 recovery path as above — the orchestrator trusts the filesystem, not the return JSON, so the `ok`/`write_failed` distinction does not change the flow |
| Writer below minimum word count | Phase 4.5 gate re-dispatches writer once with `TARGET_MIN_WORDS` and `EXPANSION_NOTES`. If the second attempt still falls short, Phase 5 expansion-review loop runs (capped at iteration 2). Final deficit surfaced in Phase 6 summary |
| Writer self-reports inflated word count | Phase 4.5 measures `wc -w` on the file — self-reported value is ignored for the gate, logged as diagnostic |
| Claims verification needed | Handled by verify-report skill in a separate context window — not run here |
| Review loop reaches max (3) | Accept current draft with quality warning |
| Local documents unreadable | Log skipped files, proceed with readable ones. If none readable, ask user for alternative paths |
| No relevant content in local docs | Suggest switching to web mode or providing different documents |
| Hybrid mode: local fails, web succeeds | Proceed with web-only context, note in report that local sources were unavailable |
| Document path glob matches nothing | Report error, ask user to verify paths |
