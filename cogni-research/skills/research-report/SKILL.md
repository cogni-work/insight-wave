---
name: research-report
description: |
  Generate a multi-agent research report using parallel web, local document, or wiki
  research with structural review. Three modes: basic (fast single-pass), detailed
  (multi-section with outline), deep (recursive tree exploration). Four source modes:
  web (default), local (user's files), wiki (cogni-wiki), hybrid. Requires an initialized
  project — routes to research-setup first if none exists. Runs localized search for the
  project's configured market (18 supported: DACH, DE, FR, IT, PL, NL, ES, CZ, SK, HU, HR, GR, MX, BR, CN, US, UK, EU)
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

Depth (`report_type`) and length (`target_words`) are independent knobs. The word counts below are the **defaults for `target_words`** when the user does not set it explicitly — they are not hard coupling between depth and length. Set `target_words` directly in project-config.json (or via `initialize-project.sh --target-words <N>`) to override per project.

| Type | Trigger | Sub-Questions | Default target_words | Use Case |
|------|---------|--------------|-------|----------|
| **basic** | "research report on X" | 5 | 3000 | Standard research report |
| **detailed** | "detailed research report on X" | 5-10 | 5000 | Comprehensive analysis |
| **deep** | "deep research on X" | 10-20 (tree) | 5000 (reduced from 8000 in v0.7.7; set `target_words: 8000+` for long-form) | Maximum depth + breadth |
| **outline** | "outline on X" | 5 | 1000 | Structured framework, no prose |
| **resource** | "sources on X", "reading list" | 5 | 1500 | Annotated bibliography |

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

Available markets (keys of `references/market-sources.json`): `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `mx`, `us`, `uk`, `eu`. There is no `global` option — research-setup resolves ambiguity by asking the user before the project is initialized. The market and output language are usually aligned (e.g., market=dach → output_language=de, market=it → output_language=it) but can diverge (e.g., market=fr, output_language=en for an English report about the French market). The `eu` market is a composite that fans out per-country researchers — see composite dispatch below.

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
  "channel_agents":     <per-channel agent count — see "Resolving channel_agents" below.
                         Always includes one entry per channel in plan.channels.
                         Web stays 1:1 with sub_question_count; wiki/local batch
                         against a shared corpus sweep so their count is usually
                         much smaller than N.>,
  "total_agents":       <sum of channel_agents values across plan.channels
                         (no longer sub_question_count × len(channels))>,
  "batch_count":        <ceil(total_agents / batch_size)>,
  "est_cost_usd":       <from references/model-strategy.md cost table,
                         matched by report_type × source_mode>,
  "curate_sources":     <true if detailed/deep AND projected source count ≥ 8,
                         OR if curate_sources is explicitly true in config;
                         false if explicitly false>,
  "target_words":       <target_words from project-config.json. Default
                         resolution when the field is missing: basic 3000,
                         detailed 5000, deep 5000, outline 1000, resource 1500.
                         In v0.7.7 the deep default was reduced from 8000 to
                         5000 (issue #35) — if the field is missing AND
                         report_type == "deep", set `target_words_restore_notice: true`
                         on the plan object so 1.5b can print a one-line
                         restore instruction. Projects created with
                         initialize-project.sh >= v0.7.7 always have
                         target_words set explicitly, so the notice only fires
                         on pre-v0.7.7 project re-runs.>
}
```

**Resolving `channels`** (the set of researcher types that will actually run):
- `source_mode == "web"`   → `["web"]`
- `source_mode == "local"` → `["local"]` (requires `document_paths`)
- `source_mode == "wiki"`  → `["wiki"]` (requires `wiki_paths`)
- `source_mode == "hybrid"` → include `"web"` always; add `"wiki"` if `wiki_paths` set; add `"local"` if `document_paths` set

If `source_mode == "hybrid"` but neither `wiki_paths` nor `document_paths` is set, `channels` collapses to `["web"]` only. Don't fail — the user asked for hybrid and should get the web leg — but flag this silent downgrade in the 1.5b trade-off lines (see below) so they can fix the config if they meant otherwise.

**Channel stats for the plan echo**: when `local` is in channels, glob each `document_paths` entry with Bash (`ls`, `find`, or shell glob) and count the matching files into `plan.document_count`. When `wiki` is in channels, for each path in `wiki_paths` count the markdown pages under `wiki/pages/` (e.g., `find "$wiki_root/wiki/pages" -name '*.md' | wc -l`) and sum into `plan.wiki_page_count`. These counts feed the Market & sources block in 1.5b — they make local/wiki visible as real, measurable channels instead of abstract options. If a glob matches zero files, keep the zero and let the echo flag it ("Local: 0 documents matched your paths — add files or fix the glob") so silent empty channels don't stay silent.

**Resolving `channel_agents`** (asymmetric allocation, v0.7.14+): web research is open-ended and genuinely benefits from one agent per sub-question — different queries, different sources, different recursion trees. Wiki and local research operate over **bounded, shared corpora**: N agents would each re-read the same `wiki/index.md`, re-run the same Document Relevance Assessment over the same PDFs, and re-extract publication metadata from the same pages. That duplication is the waste we size down here. Compute one agent count per channel using this heuristic:

```
DOCS_PER_AGENT    = 25     # one local-researcher per ~25 documents
ENTRIES_PER_AGENT = 40     # one wiki-researcher per ~40 wiki pages (sum across all wikis)
CAP               = 4      # hard ceiling on wiki/local agents — no channel ever fans out beyond this
TRIGGER_FLOOR     = 4      # N < 4 keeps the legacy 1:1 dispatch; savings aren't worth the extra code path

N = plan.sub_question_count

if N < TRIGGER_FLOOR:
    channel_agents = {c: N for c in plan.channels}     # legacy path, unchanged
else:
    channel_agents = {}
    if "web"   in plan.channels: channel_agents["web"]   = N
    if "local" in plan.channels: channel_agents["local"] = clamp(ceil(plan.document_count  / DOCS_PER_AGENT),    1, min(N, CAP))
    if "wiki"  in plan.channels: channel_agents["wiki"]  = clamp(ceil(plan.wiki_page_count / ENTRIES_PER_AGENT), 1, min(N, CAP))
```

**Dispatch semantics** (Phase 2 reads these):
- `channel_agents[c] == N` → legacy path: one agent per sub-question, same as today.
- `channel_agents[c] == 1` → one agent receives **all** sub-question paths and the **full** corpus. It sweeps the corpus once and emits one context entity per sub-question.
- `1 < channel_agents[c] < N` → the corpus is partitioned evenly across the `k` agents. Each agent receives **all** sub-question paths but only its slice of the corpus and emits one (partial) context entity per sub-question. `scripts/merge-context.py` Phase 3 already deduplicates multiple contexts per sub-question, so no script change is needed.

Web is never partitioned this way — it always gets `N` agents, one per sub-question, because there is no shared corpus to deduplicate.

**Market summary for the plan echo**: shell out once to `${CLAUDE_PLUGIN_ROOT}/scripts/market-summary.py <market> --format block` and capture the output into `plan.market_block`. This produces the multi-line "Market: X — N authority domains boosted (research: A, associations: B, …)" block that 1.5b embeds under Market & sources. The script reads `references/market-sources.json` directly, so no drift is possible between what the menu promised at setup and what the plan says at dispatch.

**Cost estimate** lookup: use the row from `references/model-strategy.md` ("Cost Estimation" table) that matches `report_type × source_mode`. Do not compute a new cost formula — the table is the source of truth. For the hybrid row, report the full low–high range.

#### 1.5b: Print the plan

Print this summary **unconditionally** — even when `confirm_plan=false`. Silent mode only suppresses the confirmation question in 1.5c; the plan itself should always appear in the transcript so the cost/quality decision is auditable after the fact. A silent run that never showed the user what was about to happen defeats the whole point of this phase.

Produce a compact text summary for the user. Use this exact shape (fill in the computed values):

```
## Execution plan

Topic: <topic from project-config.json>
Report type: <type> → <sub_question_count> sub-questions generated
Length: <target_words> words (<"user-set" if field was present in project-config.json, else "default for <type>">)
Source mode: <mode> (channels: <comma-separated channels>)

Market & sources:
  <plan.market_block — multi-line output from market-summary.py --format block>
  Local:   <plan.document_count> documents ready            (only if local in channels)
  Wiki:    <plan.wiki_page_count> pages indexed across <len(wiki_paths)> wiki(s)   (only if wiki in channels)

Per channel:
  • web    → <channel_agents.web> agent(s) — <web_agent> (recursion: <on depth=N | off>) — one per sub-question
  • wiki   → <channel_agents.wiki> agent(s) — wiki-researcher (batched: <wiki_page_count> pages, <sub_question_count> sub-Qs)     (only if wiki in channels)
  • local  → <channel_agents.local> agent(s) — local-researcher (batched: <document_count> docs, <sub_question_count> sub-Qs)    (only if local in channels)

Fan-out: <total_agents> researchers  (<channel breakdown, e.g. "8 web + 2 wiki + 1 local">)
         (was <sub_question_count × len(channels)> under symmetric allocation)   ← only print when total_agents < sub_question_count × len(channels); the suffix is the user-visible proof batching is doing something. Omit the line entirely when the legacy 1:1 path fires (N < 4).
Batching: <batch_size> concurrent → <batch_count> batches
Source curation: <enabled | disabled> (<reason>)
Estimated cost: $<low> – $<high>  (from model-strategy.md, <type>[ (hybrid)])

Trade-offs:
  • Recursion <on|off>: <one-line explanation of the choice and what flipping it would cost>
  • Authority boost: market-curated domains get priority in query generation and source ranking — this is why a DACH report reads different from a US report on the same topic. Disable only by picking a market with no authority list (never the default).
  • <source-mode-specific note>
  • Batch size <N>: <rate-limit vs. speed note>
```

The trade-off lines are where the user actually learns the cost/quality geometry. Keep them short and concrete. Examples:

- "Recursion off: faster and roughly 2–3× cheaper than recursive deep-research. Turn it on if a sub-question genuinely needs multi-hop exploration rather than one good pass."
- "Recursion on (depth 2): each web sub-question explores 2–3 follow-ups internally. Better coverage, roughly 2–3× the web cost."
- "Hybrid channels: wiki and local agents batch sub-questions over a shared corpus sweep (capped at 4 agents per bounded channel, v0.7.14+); the web channel is the long pole for cost and time."
- "Hybrid requested but no wiki/document paths configured → running web-only. Add `document_paths` or `wiki_paths` in project-config.json to activate the other channels." (only when hybrid degraded to web-only per 1.5a)
- "Batch size 4: respects WebFetch rate limits. Drop to 2 if you've seen rate-limit errors on this market; raise to 6 only if you've verified the market is quiet."
- "Deep-mode default length reduced from 8K to 5K in v0.7.7 — set `target_words: 8000` in project-config.json to restore the old long-form deep floor." (only when `target_words_restore_notice == true` on the plan — pre-v0.7.7 project re-run)

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
    "channel_agents": {"web": 5},
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

Spawn `plan.channel_agents["local"]` local-researcher agent(s) — **not** necessarily one per sub-question. All sub-questions research from the same document set; one agent can efficiently sweep the whole corpus and emit findings for every sub-question in a single pass. See the "Resolving `channel_agents`" block in Phase 1.5a for the heuristic.

**Dispatch rule** — partition documents across `k = plan.channel_agents["local"]` agents; give every agent all sub-question paths and its slice of the corpus:

```
k = plan.channel_agents["local"]
doc_slices = partition_evenly(resolved(document_paths), k)   # k lists; flatten singletons into one list if k==1
all_sub_q_paths = sorted(00-sub-questions/data/*.md)

For each slice in doc_slices:
  Task(local-researcher,
    SUB_QUESTION_PATHS=<comma-separated all_sub_q_paths>,   # plural — batched contract (v0.7.14+)
    PROJECT_PATH=<project_path>,
    DOCUMENT_PATHS=<comma-separated slice>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Back-compat: when `k == N` (legacy path, e.g. N < 4 sub-questions), fall back to the original one-agent-per-sub-question dispatch with the singular `SUB_QUESTION_PATH`:

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

Spawn `plan.channel_agents["wiki"]` wiki-researcher agent(s). Each agent queries all configured cogni-wiki instances (or its slice, when partitioned) for findings relevant to every sub-question. The wiki-researcher follows wiki-query's index-first discovery pattern: read `wiki/index.md`, select relevant pages, read those pages, extract grounded findings. A single agent reading the index once and producing findings for every sub-question is strictly cheaper than N agents each re-reading the same index.

**Dispatch rule** — partition `wiki_paths` across `k = plan.channel_agents["wiki"]` agents (usually `k <= len(wiki_paths)`; if `k == 1` all wikis go to the single agent):

```
k = plan.channel_agents["wiki"]
wiki_slices = partition_evenly(wiki_paths, k)
all_sub_q_paths = sorted(00-sub-questions/data/*.md)

For each slice in wiki_slices:
  Task(wiki-researcher,
    SUB_QUESTION_PATHS=<comma-separated all_sub_q_paths>,
    PROJECT_PATH=<project_path>,
    WIKI_PATHS=<comma-separated slice>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Back-compat (`k == N`): one wiki-researcher per sub-question, singular `SUB_QUESTION_PATH`, full `wiki_paths` to each — original dispatch shape preserved for small runs.

Deep mode with wiki sources: use wiki-researcher (not deep-researcher), same rationale as local — the recursive tree algorithm is designed for web search breadth, not pre-synthesized knowledge.

#### Hybrid mode (report_source = "hybrid")

Run the researcher types listed in `plan.channels` in parallel, then merge all findings in Phase 3. This produces the richest context.

Hybrid mode is **asymmetric**: `plan.channel_agents["web"] == N`, but wiki and local agents batch sub-questions against a shared corpus sweep (one agent per partition, see Phase 1.5a heuristic). Example: deep mode with 8 leaf sub-questions, `channels=["web","wiki"]`, 30 wiki pages total → 8 web + 1 wiki = 9 researchers (vs. 16 under the pre-v0.7.14 symmetric allocation). Users can still drop channels via the "Web-only" option in Phase 1.5c when they want a cheaper run.

**Dispatch rule** — iterate once per channel; inside each channel use the per-mode rule above:

```
# Wiki channel (only if "wiki" in plan.channels)
if "wiki" in plan.channels:
  k = plan.channel_agents["wiki"]
  wiki_slices = partition_evenly(wiki_paths, k)
  for slice in wiki_slices:
    Task(wiki-researcher,
      SUB_QUESTION_PATHS=<comma-separated all_sub_q_paths>,
      PROJECT_PATH=<project_path>,
      WIKI_PATHS=<comma-separated slice>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

# Local channel (only if "local" in plan.channels)
if "local" in plan.channels:
  k = plan.channel_agents["local"]
  doc_slices = partition_evenly(resolved(document_paths), k)
  for slice in doc_slices:
    Task(local-researcher,
      SUB_QUESTION_PATHS=<comma-separated all_sub_q_paths>,
      PROJECT_PATH=<project_path>,
      DOCUMENT_PATHS=<comma-separated slice>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

# Web channel (always N agents — never batched)
For each sub-question entity in 00-sub-questions/data/:
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

For small runs (`N < 4`), `channel_agents` degrades to the symmetric `{c: N}` shape, and the wiki/local blocks above reduce to the legacy per-sub-question loop automatically (`k == N` → one agent per slice == one agent per sub-question).

All researcher types create separate context entities for the same sub-question. When a batched wiki/local agent handles multiple sub-questions, it emits one context entity per sub-question (keyed in the filename by sub-question slug); when the corpus is partitioned across several agents, each emits its own partial context per sub-question. The merge-context script (Phase 3) handles deduplication across wiki, local, and web sources — and across multiple partial contexts for the same sub-question.

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

**Accumulate research quality signals while batches return.** Alongside the per-agent `cost_estimate` accumulation, collect from each researcher JSON:
- `authority_domains_matched` (section-researcher, deep-researcher) — take the union across all web researchers; duplicates collapse.
- `documents_analyzed`, `documents_words`, `documents_strongly_matched` (local-researcher) — sum across local runs.
- `wiki_pages_consulted`, `wiki_instance` (wiki-researcher) — sum pages; take the unique set of wiki_instance slugs.

Stash these into an in-session `research_quality` dict. Phase 6 persists it to `execution-log.json` and feeds it to `research-quality-footer.py`. If an agent's JSON is missing a field (older agent run, degraded mode, unresolvable market), treat it as zero / empty — this accumulator must never block the pipeline on a missing count.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/merge-context.py" \
  --project-path "${PROJECT_PATH}" --json
```

Verify output: contexts count, sources count, total words. If too few sources (< 3), consider re-running failed sub-questions.

### Phase 4: Report Writing

All report types dispatch a single writer agent in full mode. The writer produces both the outline (`.metadata/writer-outline-v{DRAFT_VERSION}.json`) and the complete draft in one response. Deep mode does **not** shard per section — empirical comparison on the KI-Adoption corpus showed section-sharded dispatch produces fragmented voice, repeated framings, mini-conclusions per section, and hero-stat duplication by construction, while a single-voice expansion chain (writer → revisor → revisor) compounds past the single-call output ceiling via Phase 4.5 / Phase 5 whole-draft re-dispatch and reaches the configured `target_words` floor (historically 8K; 5K default in v0.7.7+) with readable single-voice coherence.

Spawn writer agent:
```
Task(writer,
  PROJECT_PATH=<project_path>,
  DRAFT_VERSION=1,
  REPORT_TYPE=<type>,
  RESEARCHER_ROLE=<role from project-config.json>,
  TONE=<tone from project-config.json, default "objective">,
  CITATION_FORMAT=<citation_format from project-config.json, default "apa">,
  OUTPUT_LANGUAGE=<output_language>,
  TARGET_MIN_WORDS=<target_words resolved on the Phase 1.5a plan object — Phase 1.5a is the single resolution site; it reads project-config.json target_words with the default-by-depth fallback when the field is missing, then pins the value onto the plan at .logs/phase-1.5-plan.json for every downstream phase to consume>)
```

**Always pass `TARGET_MIN_WORDS` on every writer dispatch**, not just expansion re-dispatches. Since length is decoupled from depth in v0.7.7 (issue #35), the writer no longer has a safe fallback to a per-type constant — it needs the orchestrator-resolved `target_words` value on the first pass so its Phase 1 outline budgets match the project's actual length floor. Phase 4 reads the value from the Phase 1.5a plan object (it does not re-resolve from project-config.json); this keeps Phase 1.5a as the single source of truth and prevents three-site drift. The writer's documented per-type fallback table is retained only as a last-resort safety net for agent-level testing where the orchestrator is absent.

Note: no `WRITER_MODE` parameter — the writer defaults to `full` mode for every report type including deep.

Verify: writer's outline plan written to `.metadata/writer-outline-v1.json` (see `agents/writer.md` Phase 1). **The authoritative file-existence check for the draft itself happens in Phase 4.5 Step 0 below** — do not treat the writer's return JSON as proof of persistence, and do not assume `output/draft-v1.md` exists until Step 0 has confirmed it.

#### Phase 4.5: Word-count gate (authoritative, file-level)

The writer's self-reported `words` in return JSON has historically drifted (observed: agent claimed 12,500, actual file was 3,356). The orchestrator must measure the draft itself, not trust the agent's self-report. Deep mode goes through the same whole-draft re-dispatch path as every other report type — the writer may need one or more expansion passes to compound past the ~5.6–6.1K single-call output ceiling toward the 8K deep floor, and the Phase 5 word-deficit iteration loop (raised to 3 iterations for deep mode, see below) exists to make that compounding safe.

**Step 0: File-existence precheck (authoritative).** Before measuring word count, confirm that the writer actually persisted the draft. The writer can exhaust its output token budget writing prose into its response body instead of calling the `Write` tool, leaving the file missing or zero-byte. The word-count gate below would then silently treat this as a catastrophic shortfall and trigger a full expansion re-dispatch for a run that needs a different fix entirely — the writer needs to be told to actually write the file, not to write more words.

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
    TARGET_MIN_WORDS=<target_words>,
    EXPANSION_NOTES="Your previous run returned draft text in the response body instead of writing output/draft-v{N}.md to disk. Call the Write tool with the full drafted markdown as content. After Write returns, call Read on the same path to verify persistence. Return only the compact status JSON — never the drafted prose itself. See agents/writer.md Phase 3 for the read-back contract.")
  ```
- **0d. Re-check and decide.** After the retry, re-run the existence check. If the file is still missing or empty, **halt Phase 4**: print a user-visible error block containing the topic, the project path, and a pointer to `.metadata/execution-log.json phases.phase_4_writer.write_failure`, then stop. Do not fall through to the `wc -w` measurement or Phase 5 — a phantom draft would corrupt every downstream phase (reviewer, revisor, verify-report). If the retry succeeds, set `phases.phase_4_writer.write_failure.recovered: true` in the execution log so the Phase 6 summary can surface the recovery, then continue to the word-count measurement with the recovered file.

Only once Step 0 confirms the file is present do the remaining gate steps apply:

1. Measure the actual word count from the file:
   ```bash
   ACTUAL_WORDS=$(wc -w < "${PROJECT_PATH}/output/draft-v1.md" | tr -d ' ')
   ```
2. Read the resolved floor from the Phase 1.5a plan object:

   ```bash
   floor=$(jq -r '.target_words' "${PROJECT_PATH}/.logs/phase-1.5-plan.json")
   ```

   Phase 1.5a is the single resolution site — it reads `target_words` from `project-config.json` with the default-by-depth fallback (basic 3000, detailed 5000, deep 5000, outline 1000, resource 1500) when the field is missing, and pins the resolved value onto the plan object at plan-confirmation time. Phase 4.5 is a **consumer**: do not re-read `project-config.json` here and do not re-apply the fallback table. Three resolution sites invite drift; one resolution site and two consumers (Phase 4.5, Phase 6) is the contract. If you need to inspect the fallback logic or the v0.7.7 8K→5K deep-default change, read Phase 1.5a — the restore notice and the fallback table live there, not here.

3. Compute `gate_floor = floor × 0.9` uniformly across all report types (10% tolerance band). Deep mode uses the same tolerance as every other type — the ~5.6–6.1K single-call output ceiling means a first-pass deep draft targeting `target_words >= 8000` is expected to land under floor, and the expansion re-dispatch + Phase 5 word-deficit loop compound it back up. A hard wall at `1.0 × floor` would uselessly bounce drafts that are one paragraph short of the target, which is exactly what the new `[0.98, 1.00) = 0.75 cap` reviewer band also exists to prevent. At the new default `target_words: 5000` for deep, a single writer pass reaches the floor without expansion in most cases — the expansion chain becomes an opt-in for explicit 8K+ runs rather than the common path.
4. Decision:
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
5. After the re-dispatch, measure `wc -w output/draft-v2.md`. If still below `gate_floor`, do NOT re-dispatch a third time — cap at one expansion attempt to bound Phase 4 cost. Instead:
   - Log `phase_4_word_deficit: {actual_v1, actual_v2, floor, action: "writer_cap_reached"}` in `.metadata/execution-log.json`
   - Continue to Phase 5 with `draft-v2.md` as the input — the reviewer's stepped completeness cap will downgrade the verdict, and the Phase 5 expansion-review loop (see Phase 5 below — raised to 3 iterations for deep mode) gives the revisor up to two more chances to close the gap

6. Record the gate outcome in `.metadata/execution-log.json` under `phases.phase_4_writer`:
   ```json
   {
     "phase_4_writer": {
       "mode": "single_voice",
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

**Iteration cap** — conditional on the verdict's issue profile and report type:

- **Default: 1 structural review iteration.** After revision, or if the first review accepts and its issues list contains no high-severity `Word deficit` entry, proceed to Phase 5.5. This is the common case and costs no more than today.
  - **Word-deficit carve-out on accept.** The reviewer's Word Count Gate can emit a high-severity `Word deficit` issue alongside an `accept` verdict when the draft lands at the accept threshold with a completeness cap applied (score e.g. `0.820`, ratio e.g. `0.970`). In that edge case the default short-circuit does **not** fire — the word-deficit expansion loop below does, because the Phase 6 promotion gate would otherwise block promotion in deep mode (and emit `⚠ Below target` warnings in other modes) on a draft Phase 5 just let through.
- **Word-deficit expansion loop**, triggered when **any iteration's** verdict JSON contains an entry in `issues[]` where `severity == "high"` AND `issue.startswith("Word deficit")` — regardless of the top-level `verdict` field. This is the predicate that resolves the documented orchestration contradiction "accept verdict says ship, word-deficit issue says expand". When this issue is present, the revisor runs in expansion mode (see `agents/revisor.md` — the +20% cap is lifted for expansion). Without follow-up review passes, the expansion cannot be verified and the word-count gate would be a dead letter.

  The iteration cap in this branch depends on report type:

  | Report type | Cap | Rationale |
  |---|---:|---|
  | basic, detailed, outline, resource | **2 iterations** | One revisor pass is enough to close a single-call shortfall |
  | deep | **3 iterations** | Deep mode needs to compound past the ~5.6–6.1K single-call output ceiling to the 8K floor; empirical evidence from the KI-Adoption corpus shows 3 writer/revisor calls (writer + 2 revisor expansions) reach ~8,400 words with single-voice coherence; 2 iterations are structurally insufficient |

  The loop:
  - After the revisor produces `draft-v{N+1}.md`, re-run the reviewer with `REVIEW_ITERATION=N+1`, generating `.metadata/review-verdicts/v{N+1}.json`.
  - **Iteration persistence is mandatory.** After each follow-up reviewer dispatch returns, verify the verdict file exists and is non-empty via `[ -s "${PROJECT_PATH}/.metadata/review-verdicts/v${N+1}.json" ]`. If missing, the reviewer failed to persist its verdict — log `phase_5_review.iteration_{N+1}_missing: true` in `.metadata/execution-log.json` and halt Phase 5 with a user-visible error. Do not fall through to Phase 5.5 or Phase 6 with an unverified post-revisor draft — the whole point of the follow-up iteration is to confirm whether the expansion closed the gap.
  - If the verdict is `accept`, exit the loop and proceed to Phase 5.5.
  - If the verdict is still `revise` with another `Word deficit` issue AND the cap for the current report type has not been reached, dispatch another revisor expansion pass and then another reviewer pass. Non-deep modes stop after iteration 2; deep mode stops after iteration 3.
  - Regardless of the final iteration's verdict (accept or revise), proceed to Phase 5.5 once the cap is reached. The expansion-review loop is a bounded compound-and-verify cycle, not an unbounded retry. **Record `phase_5_review.word_deficit_cleared: true|false`** on the final iteration — Phase 6 reads this flag to decide whether to block promotion.
  - If `project-config.json` has `allow_short: true`, skip the follow-up iterations entirely — the user opted out of auto-expansion in Phase 4.5, so there is no point spending tokens verifying an expansion that did not happen.

This word-deficit exception is the only multi-iteration branch. Every other revise reason (structural issues, coherence gaps, source diversity) still caps at 1 iteration — no behavior change for the common case, no runaway cost.

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

**Promotion gate.** Before copying the accepted draft to `output/report.md`, verify the word-count floor is actually cleared. The **hard promotion gate** fires when `report_type == "deep"` AND `target_words >= 8000` AND `allow_short != true` AND `actual_words < target_words` — that is, a long-form deep run (explicit opt-in to 8K+) that fell short. In that case, do not silently promote. Instead:

1. Measure the final draft: `wc -w < "${PROJECT_PATH}/output/draft-v${N}.md"`.
2. Read the resolved floor from the Phase 1.5a plan object (`.logs/phase-1.5-plan.json target_words`). That value was pinned at plan-confirmation time and already consumed by Phase 4.5 — do not re-resolve from project-config.json here, and do not assume Phase 4.5 recomputed it. Three resolution sites invite drift; one resolution site and two consumers is the contract.
3. **Hard-gate branch (`report_type == "deep"` AND `target_words >= 8000` AND `allow_short` unset)**: if `actual_words < target_words`, present the user with an `AskUserQuestion` choice:
   - **Option A: Accept shorter report** — promote the draft anyway, record `phase_6_promotion.floor_override: true` and `phase_6_promotion.shortfall_words: <target_words - actual>` in the execution log, and set `allow_short_accepted` in the summary.
   - **Option B: Retry expansion** — dispatch one more revisor expansion pass against the current accepted draft with `TARGET_MIN_WORDS=<target_words>` + `EXPANSION_NOTES` naming the remaining deficit, then re-run the reviewer. Cap at one additional retry — if the new draft still falls short, fall through to the same question with Option B removed.
   - **Option C: Abort** — stop without promotion. Leave the latest `draft-v{N}.md` in place for manual inspection. Print the project path and a pointer to `.metadata/execution-log.json`.
4. **Soft-gate branch (everything else — including deep with `target_words < 8000`, the new v0.7.7 default)**: keep the advisory behavior. The reviewer's verdict and Phase 6 summary warnings are informational. Short drafts are still promoted automatically with a `⚠ Below target` line in the summary. This is the right default for the 5K-deep common case: the single-voice writer reaches 5K on first pass in most runs, and a one-paragraph shortfall does not justify a hard stop-the-world question.
5. For outline / resource modes, the per-type floor is advisory and promotion is never blocked. Same rule applies regardless of whether the user set `target_words` explicitly — these modes are structural, not prose-floor-driven.

The hard-gate narrowing (deep AND `target_words >= 8000`) preserves today's behavior for users who explicitly opted into the 8K+ long-form path while letting the new 5K-deep default promote through the soft path like detailed/basic. Users who want the old hard stop back set `target_words: 8000` in project-config.json.

Once the promotion gate passes (or the user selects Option A), continue with the existing finalization steps:

1. Copy final accepted draft to `output/report.md`
   - The project directory is a self-contained unit of output — report, sources, and metadata together, all Obsidian-browsable. Keep the canonical deliverable at `{project_path}/output/report.md` and do not copy or symlink it elsewhere. If the user wants a different format or location, the enrich-report phase (Phase 5.5) handles that.
   - **Aggregate research quality signals** (collected from researcher agent JSON across Phase 2 — see the agents' return contract in `agents/section-researcher.md`, `agents/local-researcher.md`, `agents/wiki-researcher.md`). Build one JSON object:
     ```
     {
       "market": "<market from project-config.json>",
       "authority_domains_cited": <union of authority_domains_matched across all section-researcher / deep-researcher results — preserves which of the market's curated domains actually made it into citations>,
       "sub_questions": <count of sub-questions that ran>,
       "local_documents": <sum of documents_analyzed across local-researcher results, 0 if no local channel>,
       "local_strongly_matched": <sum of documents_strongly_matched across local-researcher results>,
       "wiki_pages": <sum of wiki_pages_consulted across wiki-researcher results, 0 if no wiki channel>,
       "wiki_instances": <unique wiki_instance values from wiki-researcher results>
     }
     ```
     Persist this object to `.metadata/execution-log.json phases.phase_6_finalization.research_quality` so verify-report, research-resume, and downstream tools can read the same numbers.
   - **Append "## Research method" section to `output/report.md`.** Pipe the quality JSON to `${CLAUDE_PLUGIN_ROOT}/scripts/research-quality-footer.py --mode markdown` and append the resulting markdown block to the end of `output/report.md` **before** the Report-Metadaten footer (written next step). The section makes the market curation and local/wiki coverage visible in the deliverable itself — a reader receiving only the report still sees what profile it was researched against. This is the point of the whole quality-signal pass: what the README promises, the artifact should declare. The script degrades gracefully on zero-authority-match edge cases (`_default` fallback, tiny markets, wiki-only runs with no web citations) — never silently skip this step.
   - **Write deterministic Report-Metadaten footer.** Immediately after the Research method append, run `${CLAUDE_PLUGIN_ROOT}/scripts/write-report-metadata.sh --project-path {project_path} --target-file {project_path}/output/report.md`.
     - The script owns the `**Report-Metadaten**:` / `**Report Metadata**:` block at the tail of `output/report.md` — it replaces only that named region, never other content. Inputs: `agents/revisor.md` YAML `model:` field (source of truth for author attribution), `.metadata/execution-log.json` `phases.phase_5_review.iteration_count`, and `project-config.json` `output_language` for date formatting and DE/EN labels.
     - Fail-open: on non-zero exit or `{"success": false}` JSON (including the degenerate case where `agents/revisor.md` has no `model:` field and the script raises `ValueError`), log the error to `.metadata/execution-log.json` `phases.phase_6_finalization.metadata_write_error` and continue — the report ships without the footer rather than blocking finalization.
     - Why this step exists: replaces the hallucinated LLM-generated footer that caused issue #49 (revisor self-attributing as Haiku when the agent YAML declares Sonnet).
2. **Accumulate cost estimates**: Sum `cost_estimate.estimated_usd` from all agent outputs collected during Phases 2-5. Group by agent role (researchers, writer, reviewer, revisor, claim_extractor, source_curator). Write cost summary to `execution-log.json`
3. Update `.metadata/execution-log.json` with:
   - Phase completion timestamps
   - Agent counts and durations
   - Final structural review score and iteration count
   - `phase_5_review.claims_verification: "deferred to verify-report"`
   - `phase_5_review.word_deficit_expansion_triggered: true|false` — `true` if the Phase 5 word-deficit expansion loop fired this run (any iteration's verdict had a `severity == "high"` issue starting with `Word deficit`, regardless of the top-level `verdict` field), `false` if Phase 5 exited via the default single-iteration short-circuit. This is distinct from `phase_5_review.word_deficit_cleared` recorded inside the loop body — the trigger flag records whether the loop ran at all, the cleared flag records whether the loop's final iteration closed the gap. Downstream tooling (Phase 6 promotion gate, audit trails) reads both fields to distinguish "expansion triggered but did not clear" from "loop never triggered".
   - Cost summary: `{"total_estimated_usd": N, "breakdown": {"researchers": N, "writer": N, ...}}`
   - `enrich_report_applied`: true/false
   - `enrich_report_path`: path to enriched HTML or null
4. Report summary to user:
   - Topic and report type
   - **Word count**: always formatted as `Delivered: N words (target: {target_words} words)`. Read `{target_words}` from the Phase 1.5a plan object at `.logs/phase-1.5-plan.json` — the single resolution site that Phase 4 dispatch, Phase 4.5 Step 2, and the Phase 6 promotion gate all consume. Do not re-resolve from `project-config.json` here. Length is decoupled from depth in v0.7.7 — there is no per-type range; the user committed to a specific target in setup (or via the default-by-depth fallback Phase 1.5a applied), and the summary reports against that target. If `phases.phase_4_writer.re_dispatches >= 1`, also show `(expanded from {v1_words} via expansion chain)` so the user sees when the gate earned its cost.
   - **Word-count gate status** — read `.metadata/execution-log.json phases.phase_4_writer`:
     - If `phases.phase_4_writer.write_failure` exists and `write_failure.recovered == true`: print `✓ Phase 4.5 write-failure recovery: writer persisted the draft on retry after a first-run silent-persist failure.` Then continue to the branches below — the write-failure line is additive, not a replacement for the word-count status.
     - If `re_dispatches == 0` and the final `actual_words >= floor`: do not print any warning
     - If `re_dispatches == 1` and the final `actual_words >= floor`: print `✓ Word-count gate: expansion re-dispatch succeeded ({v1} → {v2} words).` — a positive signal the gate earned its cost
     - If the final `actual_words < floor`: print `⚠ Below target by {floor - actual_words} words.` followed by one of:
       - `allow_short: true was set — expansion skipped.` (opt-out path)
       - `Writer re-dispatch cap reached after one attempt.` (cap-hit path)
     - If `phase_5_review.iteration_count >= 2`: print `✓ Phase 5 expansion-review loop ran — reviewer re-verified the revised draft ({iteration_count} iterations).`
   - Section count
   - Sources cited
   - **Citation URL coverage** — compute this from `.metadata/aggregated-context.json sources[]`:
     - Partition cited sources (those with `citation_count > 0`) into three buckets by their URL state:
       - **exact**: `url.startswith("https://")` OR (`original_url.startswith("https://")` AND `url_precision` != `"publisher"`). These are per-document publisher URLs — what the reader expects.
       - **publisher**: `original_url.startswith("https://")` AND `url_precision == "publisher"`. These are publisher landing pages from the wiki-researcher's `publisher_base_url` fallback — honest but imprecise.
       - **none**: no usable URL. These render as unlinked citations in the bibliography.
     - Print `Citation URL coverage: {exact+publisher}/{total} sources linkable ({exact} exact, {publisher} publisher landing, {none} unlinked)`. Example: `Citation URL coverage: 68/72 sources linkable (58 exact, 10 publisher landing, 4 unlinked)`.
     - If `none > 0` and the `none` sources are wiki-sourced (check `publisher.startswith("cogni-wiki:")`), append a follow-up line naming the first three offending source entity IDs so the user can backfill `publisher_url` in the wiki pages: `  ⚠ {n} wiki sources missing publisher URL: src-xxx-..., src-yyy-..., src-zzz-... — add publisher_url to the page frontmatter or publisher_base_url to the wiki's .cogni-wiki/config.json`.
     - Persist the three counts to `.metadata/execution-log.json phases.phase_6_finalization.citation_url_coverage` as `{total, exact, publisher, none}` so verify-report can read the same numbers and the soft-warning is auditable across runs.
     - This is a soft signal, not a hard gate — it never blocks promotion. Its job is to surface where the wiki-to-research URL pipeline leaks, not to fail runs on incomplete wikis.
   - Structural review score
   - **Estimated cost** (total USD from cost_summary)
   - **Research quality** — pipe the same research_quality JSON (from `phases.phase_6_finalization.research_quality`) to `${CLAUDE_PLUGIN_ROOT}/scripts/research-quality-footer.py --mode echo` and print the multi-line block verbatim. This surfaces the market curation and channel coverage in the live transcript — the user sees that DACH boosted 27 domains, 14 made it into the cited sources, 8 local documents contributed, 12 wiki pages were consulted. The echo complements the markdown footer: the footer lives in the artifact, the echo lives in the session.
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
| Writer below minimum word count | Phase 4.5 gate re-dispatches writer once with `TARGET_MIN_WORDS` and `EXPANSION_NOTES`. If the second attempt still falls short, Phase 5 expansion-review loop runs (capped at iteration 2 for basic/detailed/outline/resource, iteration 3 for deep — deep needs the extra revisor pass to compound past the single-call output ceiling to the 8K floor). Final deficit surfaced in Phase 6 summary |
| Writer self-reports inflated word count | Phase 4.5 measures `wc -w` on the file — self-reported value is ignored for the gate, logged as diagnostic |
| Claims verification needed | Handled by verify-report skill in a separate context window — not run here |
| Review loop reaches max (3) | Accept current draft with quality warning |
| Local documents unreadable | Log skipped files, proceed with readable ones. If none readable, ask user for alternative paths |
| No relevant content in local docs | Suggest switching to web mode or providing different documents |
| Hybrid mode: local fails, web succeeds | Proceed with web-only context, note in report that local sources were unavailable |
| Document path glob matches nothing | Report error, ask user to verify paths |
