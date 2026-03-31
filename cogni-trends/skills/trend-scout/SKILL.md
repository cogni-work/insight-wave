---
name: trend-scout
description: |
  Interactive trend scouting workflow with industry selection, bilingual support (DE/EN), and downstream pipeline integration. Scouts trends across 4 dimensions (each trend gets full TIPS expansion). Creates research projects with web-grounded industry-contextualized trend candidates (variable count based on web research signals) that feed directly into value-modeler or trend-report. Use when: (1) Starting smarter-service research with industry context, (2) User wants to scout trends for a specific industry and subsector, (3) User mentions "trend scouting", "industry trends", "trend scout", (4) Preparing input for the TIPS pipeline (value-modeler, trend-report).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, Task, AskUserQuestion, TodoWrite
---

# Trend Scout

Interactive workflow for scouting trends across 4 dimensions with industry selection and bilingual support. Each trend discovered is later analyzed through the complete TIPS framework (Trend → Implications → Possibilities → Solutions). Produces configuration files for downstream `value-modeler` and `trend-report` skills.

## Purpose

This skill enables users to:

1. Select an industry and subsector from a standardized taxonomy
2. Initialize a research project with semantic slug
3. Generate web-grounded trend candidates (1-5 per cell × 12 cells: 4 dimensions × 3 horizons, variable total based on web signals)
4. Write the final trend list and produce configuration for downstream pipeline skills (`value-modeler`, `trend-report`)

## Language Support

Full German and English support throughout. This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

**Two language concepts:**

1. **Interaction language** — how the skill communicates with the user (prompts, status, questions). Determined by workspace `.workspace-config.json` language setting. All AskUserQuestion prompts, status messages, and instructions use this language.
2. **Output language** — what language deliverables are written in. Asked explicitly in Phase 0 with workspace language as default. Stored as `project_language`.

- Industry taxonomy presented in both languages
- Web research queries in both languages (global + DACH regions)
- User-facing messages in interaction language
- Output files respect `project_language` setting

## Context Independence

This skill reads configuration from project files and generates all outputs to disk — it does not depend on prior conversation context. If invoked after trends-resume or other conversational setup, **context compaction is safe and recommended** before starting.

**Before executing Phase 0**, run `/compact` to free working memory. This skill dispatches a web research agent with 32+ searches (Phase 1) and generates web-grounded scored candidates with extended thinking (Phase 2) — both require substantial context for processing research signals and candidate scoring. Compacting early maximizes the context available for these heavy phases.

If `/compact` is unavailable or this is the first skill in the session (no prior context to reclaim), skip compaction and proceed directly.

## Prerequisites

- Projects are stored relative to the workspace root (`$PROJECT_AGENTS_OPS_ROOT`, falling back to `$PWD`)
- Web access enabled for live trend research

## Shell Execution Constraints

**CRITICAL - Do NOT improvise shell commands:**

1. All project initialization MUST use the provided scripts
2. NEVER generate inline bash code for slug generation or project creation
3. If a script is not found, report the error and ask user to verify installation
4. Do NOT attempt workarounds with inline `$(...)` command substitution

**Path Variable Distinction:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (scripts, skills) | `~/.claude/plugins/marketplaces/cogni-trends` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (optional, set by cogni-workspace) | User's workspace directory |

**IMPORTANT - Environment Variables:**

- `CLAUDE_PLUGIN_ROOT` is automatically injected by Claude Code from `settings.local.json`
- `PROJECT_AGENTS_OPS_ROOT` is set by cogni-workspace's `generate-settings.sh` — if not present, scripts fall back to `$PWD`
- DO NOT source `.workplace-env.sh` - variables are already available at runtime

**Script Locations (always use CLAUDE_PLUGIN_ROOT):**

- `${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/generate-project-slug.sh`
- `${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/update-industry-metadata.sh`
- `${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/finalize-candidates.sh`
- `${CLAUDE_PLUGIN_ROOT}/scripts/discover-portfolio-markets.sh`
- `${CLAUDE_PLUGIN_ROOT}/scripts/initialize-trend-project.sh`

## References Index

Read references **only when needed** for the specific task:

| Reference | Read when... |
|-----------|--------------|
| [$CLAUDE_PLUGIN_ROOT/references/data-model.md]($CLAUDE_PLUGIN_ROOT/references/data-model.md) | Understanding entity schemas and project structure |
| [references/industry-taxonomy.md](references/industry-taxonomy.md) | Presenting industry selection to user |
| [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md) | Language detection and resolution pattern |
| [references/i18n/messages-en.md](references/i18n/messages-en.md) | English user messages |
| [references/i18n/messages-de.md](references/i18n/messages-de.md) | German user messages |
| [references/methodology.md](references/methodology.md) | Academic foundations (Ansoff, Rohrbeck, Rogers), full methodology explanation |
| [references/dach-sources.md](references/dach-sources.md) | DACH site-specific web searches (Phase 1) |
| [references/funding-signals.md](references/funding-signals.md) | VC/funding signal queries (Phase 1) |
| [references/job-market-signals.md](references/job-market-signals.md) | Job market signal queries (Phase 1) |
| [references/academic-api-queries.md](references/academic-api-queries.md) | Academic API searches - OpenAlex, Semantic Scholar, arXiv (Phase 1) |
| [references/patent-api-queries.md](references/patent-api-queries.md) | Patent API searches - USPTO, Lens.org, EPO (Phase 1) |
| [references/regulatory-feeds.md](references/regulatory-feeds.md) | Regulatory API searches - EUR-Lex, SEC EDGAR, FDA (Phase 1) |
| [references/workflow-phases/phase-0-initialize.md](references/workflow-phases/phase-0-initialize.md) | Project init + industry selection |
| [references/workflow-phases/phase-3-present.md](references/workflow-phases/phase-3-present.md) | Writing final trend-candidates.md with scores |
| [references/workflow-phases/phase-4-finalize.md](references/workflow-phases/phase-4-finalize.md) | Finalizing output for downstream pipeline |

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite immediately with workflow phases:

1. Phase 0: Initialize Project + Industry Selection [in_progress]
2. Phase 1: Bilingual Web Research [pending]
3. Phase 2: Generate Candidate Pool [pending]
4. Phase 3: Write Final Trend List [pending]
5. Phase 4: Finalize Output + Pipeline Config [pending]

Update todo status as you progress through each phase.

---

## Core Workflow

```text
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
   │          │          │         │         │
   │          │          │         │         └─ Write config + JSON, finalize
   │          │          │         └─ Write final trend-candidates.md with scores
   │          │          └─ Generate + score web-grounded candidates (1-5 per cell)
   │          └─ 32 web searches + academic/patent/regulatory APIs
   └─ Language detect, industry select, project init
```

### Phase 0: Initialize Project + Industry Selection

Read [references/workflow-phases/phase-0-initialize.md](references/workflow-phases/phase-0-initialize.md) and [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md), then execute:

1. **Detect interaction language:** Read workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD). Set `INTERACTION_LANGUAGE` — use this for all user-facing messages from this point on. Load the matching i18n message catalog (`messages-{INTERACTION_LANGUAGE}.md`).
2. **Ask user for output language:** Present AskUserQuestion in the interaction language. Workspace language is the pre-selected default (e.g., "Deutsch (DE) <- Workspace-Standard" or "English (EN) <- Workspace default"). User can override. Set `PROJECT_LANGUAGE` from explicit choice. Do NOT skip asking — always confirm with user.
3. **Portfolio discovery (optional):** Scan workspace for cogni-portfolio projects with markets. If the primary workspace (`$PROJECT_AGENTS_OPS_ROOT` or `$PWD`) has no portfolio projects, perform a broader scan — check parent directories and common cloud storage locations (`~/Library/CloudStorage`, `~/OneDrive`, `~/Documents`). If still nothing found, ask the user if they have a workspace directory to scan. If portfolio found, offer user to pre-populate industry/subsector from a portfolio market. If selected, skip steps 4-6 and suggest a research topic from the market context. See Step 0.1c in [references/workflow-phases/phase-0-initialize.md](references/workflow-phases/phase-0-initialize.md).
4. Load [references/industry-taxonomy.md](references/industry-taxonomy.md) *(skip if portfolio market selected)*
5. Present industries with subsectors (bilingual) *(skip if portfolio market selected)*
6. Capture user selection via AskUserQuestion (in interaction language) *(skip if portfolio market selected)*
7. Capture research topic/focus (in interaction language) — with optional suggestion from portfolio market
8. Generate project slug: `{subsector}-{topic}-{hash}`
9. Initialize project via `initialize-trend-project.sh` in the current working directory under `cogni-trends/`
10. Update `tips-project.json` with full industry context (bilingual names, subsector, research_topic) — see Step 0.8b in phase-0-initialize.md. The `update-industry-metadata.sh` script only updates `.metadata/trend-scout-output.json`, so you MUST also update `tips-project.json` inline with jq (industry.primary, primary_en, primary_de, subsector, subsector_en, subsector_de, research_topic).
11. Update `.metadata/trend-scout-output.json` with industry context (and portfolio_source if applicable)

**Required outputs:**

- PROJECT_PATH, PROJECT_SLUG variables set
- PROJECT_LANGUAGE set from explicit user choice (de/en)
- INDUSTRY, SUBSECTOR selected
- RESEARCH_TOPIC captured
- Project structure initialized in current working directory under `cogni-trends/`

### Phase 1: Bilingual Web Research + API Queries (DELEGATED)

**Context Efficiency:** This phase is delegated to the `web-researcher` agent to prevent context depletion from 20+ WebSearch results. The agent returns a compact JSON summary (~500 tokens) while logging full results to `.logs/`.

**Invoke the web-researcher agent:**

```yaml
Task:
  subagent_type: "cogni-trends:trend-web-researcher"
  description: "Execute bilingual web research"
  prompt: |
    Execute Phase 1 web research for trend-scout.

    PROJECT_PATH: {{PROJECT_PATH}}
    INDUSTRY_EN: {{INDUSTRY_EN}}
    INDUSTRY_DE: {{INDUSTRY_DE}}
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    MARKET_REGION: {{MARKET_REGION}}
```

**Agent responsibilities:**

1. Build 32 web search configurations (16 standard + 8 DACH site-specific + 4 funding + 4 job market)
2. Execute WebSearch for each config in parallel batches
3. Execute mandatory API queries (academic, patent, regulatory) with fallback handling
4. Extract and deduplicate trend signals
5. Classify signals by indicator type (leading/lagging) and source type
6. Write full results to `{{PROJECT_PATH}}/.logs/web-research-raw.json`
7. Return compact JSON with ~85 aggregated signals

**Note:** The web-researcher agent is self-contained with all search configurations and deduplication logic.

**Process agent response:**

The agent returns compact JSON with abbreviated fields for token efficiency:

```json
{
  "ok": true,
  "signals": {
    "total": 85,
    "by_dimension": {...},
    "by_source": {"web": 48, "dach_site": 12, "funding": 8, "jobs": 6, "academic": 5, "patent": 4, "regulatory": 2},
    "by_indicator": {"leading": 38, "lagging": 47}
  },
  "items": [{"d": "dimension", "n": "name", "k": ["keywords"], "u": "url", "f": "freshness", "a": 5, "t": "type", "i": "leading", "lt": "12-24m"}]
}
```

**Log file format** (`.logs/web-research-raw.json`):

The log file uses **full field names** for debugging readability. Key structure:

```json
{
  "metadata": {...},
  "searches_executed": {"total": 32, "successful": 30, "failed": 2, "by_category": {...}},
  "raw_signals_before_dedup": [
    {"dimension": "...", "signal": "...", "keywords": [...], "source": "url", "freshness": "...", "indicator_type": "leading|lagging", "lead_time": "...", "source_type": "..."}
  ],
  "api_queries_executed": {...}
}
```

To query the log file directly:

```bash
jq '.raw_signals_before_dedup[] | {dimension, signal, keywords, source}' .logs/web-research-raw.json
```

**Set availability flag:**

- Set `WEB_RESEARCH_AVAILABLE = (response.ok == true)`
- Do NOT expand or group signals — the trend-generator agent self-loads them from disk

**Persist compact response for downstream fallback:**

Write the agent's raw compact JSON response (the full response object including the `.items` array) to:
`{PROJECT_PATH}/phase1-research-summary.json`

This file serves as a fallback for `trend-report` when `.logs/web-research-raw.json` is missing or incomplete.

**Required outputs:**

- WEB_RESEARCH_AVAILABLE flag set
- Signal data persisted to disk (agent will self-load from `.logs/web-research-raw.json` or `phase1-research-summary.json`)

**Fallback Hierarchy:**

1. **Agent returns `{"ok": false}`** — proceed to inline fallback research (below)
2. **Agent unavailable** (subagent dispatch fails) — proceed to inline fallback research (below)
3. **Inline fallback research also fails** — proceed with training-only generation (warning logged)

**Inline Fallback Research (when web-researcher agent is unavailable):**

If the web-researcher agent cannot be dispatched (e.g., nested subagent context, agent not found), perform a reduced set of web searches directly using WebSearch. This is less thorough than the agent's 32 searches but ensures candidates have some web grounding rather than being 100% training-only.

Execute these 12 targeted searches organized by source authority tier. The first 6 target authoritative institutional sources (CRAAP authority 4-5) to ensure the candidate pool has credible grounding. The remaining 6 broaden coverage.

**Tier 1 — Authoritative institutional sources (run these first):**

```text
1. "site:fraunhofer.de {SUBSECTOR_DE} {RESEARCH_TOPIC} Studie 2025"
2. "site:ec.europa.eu OR site:eur-lex.europa.eu {SUBSECTOR_EN} {RESEARCH_TOPIC} regulation"
3. "site:bitkom.org OR site:{ASSOCIATION_DOMAIN} {SUBSECTOR_DE} {RESEARCH_TOPIC} 2025"
4. "{SUBSECTOR_EN} {RESEARCH_TOPIC} site:gartner.com OR site:mckinsey.com OR site:rolandberger.com"
5. "site:destatis.de OR site:bmwk.de {SUBSECTOR_DE} {RESEARCH_TOPIC} Statistik"
6. "{SUBSECTOR_EN} {RESEARCH_TOPIC} arxiv.org OR ieee.org OR sciencedirect.com 2024 2025"
```

For search 3, replace `{ASSOCIATION_DOMAIN}` with the subsector's primary industry association from [references/dach-sources.md](references/dach-sources.md) (e.g., `vda.de` for automotive, `bvmed.de` for healthcare).

**Tier 2 — Broader market and signal sources:**

```text
7. "{SUBSECTOR_EN} trends {RESEARCH_TOPIC} 2025 2026"
8. "{SUBSECTOR_DE} {RESEARCH_TOPIC} Markt DACH Mittelstand"
9. "{SUBSECTOR_EN} {RESEARCH_TOPIC} market outlook DACH"
10. "{SUBSECTOR_DE} Digitalisierung {RESEARCH_TOPIC} Trend"
11. "{SUBSECTOR_EN} {RESEARCH_TOPIC} funding investment startups DACH"
12. "{SUBSECTOR_EN} {RESEARCH_TOPIC} patent filing 2024 2025"
```

For each search result, extract trend signals (name, keywords, source URL, freshness). Write the aggregated signals to `{PROJECT_PATH}/.logs/web-research-raw.json` in the same format the agent would produce, and to `{PROJECT_PATH}/phase1-research-summary.json` as compact fallback. Set `WEB_RESEARCH_AVAILABLE = true`.

**Source tagging:** When extracting signals, tag each with its source authority level based on domain:
- Authority 5: `.gov`, `.eu`, fraunhofer.de, ieee.org, arxiv.org, nature.com
- Authority 4: gartner.com, mckinsey.com, rolandberger.com, industry associations (.org)
- Authority 3: handelsblatt.com, reuters.com, industry trade publications
- Authority 2-1: commercial blogs, vendor sites, social media

This tagging flows into the trend-generator's CRAAP scoring — candidates grounded in authority 4-5 sources will score higher on the 15% Source Quality weight.

### Phase 2: Generate Candidate Pool (DELEGATED)

**Context Efficiency:** This phase is delegated to the `trend-generator` agent to leverage Opus model's extended thinking for complex multi-framework reasoning. The agent returns a compact JSON summary (~600 tokens) while logging full candidate data to `.logs/`.

**Invoke the trend-generator agent:**

```yaml
Task:
  subagent_type: "cogni-trends:trend-generator"
  description: "Generate web-grounded scored trend candidates"
  prompt: |
    Execute Phase 2 candidate generation for trend-scout.

    PROJECT_PATH: {{PROJECT_PATH}}
    INDUSTRY_EN: {{INDUSTRY_EN}}
    INDUSTRY_DE: {{INDUSTRY_DE}}
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    PROJECT_LANGUAGE: {{PROJECT_LANGUAGE}}
    WEB_RESEARCH_AVAILABLE: {{WEB_RESEARCH_AVAILABLE}}
```

**Agent responsibilities:**

1. Apply embedded scoring framework
2. Generate web-grounded trend candidates (1-5 per cell × 12 cells) using extended thinking (MANDATORY)
3. Every candidate must be grounded in a web research signal — no training-sourced padding
4. Apply multi-framework scoring (TIPS, Ansoff, Rogers, CRAAP)
5. Classify indicator types (leading/lagging) and diffusion stages
6. Report subcategory coverage (best effort within available web signals)
7. Validate portfolio balance (≥40% leading indicators)
8. Write full results to `{{PROJECT_PATH}}/.logs/trend-generator-candidates.json`
9. Return compact JSON summary

**Process agent response:**

The agent returns compact JSON:

```json
{
  "ok": true,
  "candidates": {"total": 38, "web_signals_available": 42, "by_dimension": {...}, "empty_cells": [...]},
  "scoring": {"avg_score": 0.72, "confidence": {...}, "indicator": {...}},
  "coverage": {"cells_with_candidates": 11, "cells_total": 12},
  "validation": {"passed": true, "warnings": []},
  "log": ".logs/trend-generator-candidates.json"
}
```

**Prepare Phase 3 data files:**

Execute data preparation script to generate compact candidate data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/prepare-phase3-data.sh" "${PROJECT_PATH}"
```

This generates:
- `.logs/candidates-compact.json` (compact format for Claude reading)

**Load compact candidate data:**

Read `{{PROJECT_PATH}}/.logs/candidates-compact.json` to build trend-candidates.md.

Field mapping for compact format:
- `d` → dimension, `h` → horizon, `n` → name
- `s` → trend_statement, `r` → research_hint, `k` → keywords
- `sc` → score, `ct` → confidence_tier, `si` → signal_intensity
- `url` → source_url

**Required outputs:**

- CANDIDATES_BY_CELL loaded from log file
- TOTAL_CANDIDATES = variable (12-60, based on web signals)
- SCORING_METADATA populated from agent response
- Validation status confirmed

**Fallback Hierarchy:**

1. **Agent returns `{"ok": false}`** — log error and halt workflow
2. **Agent unavailable** (subagent dispatch fails) — perform inline candidate generation (below)

**Inline Fallback Generation (when trend-generator agent is unavailable):**

If the trend-generator agent cannot be dispatched, generate web-grounded candidates inline. This loses the benefit of extended thinking in a separate context, but still produces the required output.

Steps:
1. Load web research signals from `{PROJECT_PATH}/.logs/web-research-raw.json` or `{PROJECT_PATH}/phase1-research-summary.json`. If no signals exist, halt — do not generate candidates without web evidence.
2. **Web-only generation:** For each cell, create candidates grounded in available web signals only. If a cell has 2 web signals, it gets 2 candidates. If a cell has 0 web signals, it gets 0 candidates. Do not pad with training knowledge.
3. Generate candidates (1-5 per cell based on signals) following the same dimension/horizon/subcategory structure
4. Apply the scoring weights from [references/scoring-framework.md](references/scoring-framework.md)
5. Report subcategory coverage — gaps indicate where web research found no signals
6. **Validate and repair horizon-intensity alignment:** ACT candidates must have signal_intensity 4-5 (if < 4, set to 4). OBSERVE candidates must have intensity 1-2 (if > 2, set to 2). PLAN candidates: clamp to [2, 4]. This is a core Ansoff methodology constraint — a trend in the "act now" horizon must show strong signals, and a long-horizon OBSERVE trend must show weak/emerging signals.
7. Write results to `{PROJECT_PATH}/.logs/trend-generator-candidates.json`
8. Run `prepare-phase3-data.sh` to generate compact format

### Phase 3: Write Final Trend List

Read [references/workflow-phases/phase-3-present.md](references/workflow-phases/phase-3-present.md), then execute:

1. Write `trend-candidates.md` to `{PROJECT_PATH}/` (project root) as the **final trend list**
2. Use bilingual template based on PROJECT_LANGUAGE
3. Include all web-grounded candidates organized by dimension and horizon with scores and metadata
4. Include source coverage summary and references

All generated candidates are the final agreed list — no user selection step. Proceed directly to Phase 4.

### Phase 4: Finalize Output

Read [references/workflow-phases/phase-4-finalize.md](references/workflow-phases/phase-4-finalize.md), then execute:

1. Update consolidated `trend-scout-output.json` with all candidates
2. Update `tips-project.json` with current timestamp (`updated` field)
3. Update `trend-candidates.md` frontmatter status to `agreed`
4. Log completion with next-step instructions
5. Recommend `/trends-resume` for the next session

**Required outputs:**

- `.metadata/trend-scout-output.json` - consolidated output (config + candidates)
- `tips-project.json` - updated timestamp
- `trend-candidates.md` status updated to `agreed`

---

## Output Schema

### trend-scout-output.json (Consolidated)

Location: `{PROJECT_PATH}/.metadata/trend-scout-output.json`

```json
{
  "version": "1.0.0",
  "project_id": "automotive-ai-predictive-maintenance-abc12345",
  "project_name": "automotive-ai-predictive-maintenance-abc12345",
  "project_path": "/path/to/project",
  "project_language": "de",
  "created": "2025-12-16T10:30:00Z",

  "config": {
    "research_type": "smarter-service",
    "dok_level": 4,
    "industry": {
      "primary": "manufacturing",
      "primary_en": "Manufacturing",
      "primary_de": "Fertigung",
      "subsector": "automotive",
      "subsector_en": "Automotive",
      "subsector_de": "Automobil"
    },
    "research_topic": "AI-driven predictive maintenance",
    "organizing_concept": "ai-driven-predictive-maintenance"
  },

  "tips_candidates": {
    "total": 60,
    "source_distribution": {
      "web_signal": 28,
      "training": 32,
    },
    "web_research_status": "success",
    "search_timestamp": "2025-12-16T10:25:00Z",
    "scoring_metadata": {
      "avg_score": 0.68,
      "confidence_distribution": {
        "high": 12,
        "medium": 18,
        "low": 5,
        "uncertain": 1
      },
      "intensity_distribution": {
        "level_1": 4,
        "level_2": 6,
        "level_3": 10,
        "level_4": 12,
        "level_5": 4
      },
      "indicator_distribution": {
        "leading": 16,
        "lagging": 20,
        "leading_pct": 0.44
      },
      "diffusion_distribution": {
        "innovators": 3,
        "early_adopters": 8,
        "early_majority": 15,
        "late_majority": 8,
        "laggards": 2,
        "pre_chasm": 11,
        "post_chasm": 25
      },
      "scoring_framework_version": "1.0.0"
    },
    "coverage": {
      "cells_with_candidates": 11,
      "cells_total": 12,
      "min_per_cell": 0,
      "max_per_cell": 5
    },
    "items": [
      {
        "dimension": "externe-effekte",
        "dimension_de": "Externe Effekte",
        "subcategory": "regulierung",
        "subcategory_en": "Regulation",
        "subcategory_de": "Regulierung",
        "horizon": "act",
        "horizon_de": "Handeln",
        "sequence": 1,
        "trend_name": "EU AI Act Compliance",
        "keywords": ["ai-act", "regulation", "2024"],
        "rationale": "Immediate deadline pressure",
        "source": "web-signal",
        "source_url": "https://ec.europa.eu/...",
        "freshness_date": "2024-12",
        "score": 0.82,
        "confidence_tier": "high",
        "signal_intensity": 5,
        "indicator_classification": {
          "type": "leading",
          "lead_time": "12-24 months",
          "source_type": "regulatory"
        },
        "diffusion_stage": {
          "stage": "early_majority",
          "estimated_adoption": 0.25,
          "crossed_chasm": true
        }
      }
    ]
  },

  "execution": {
    "workflow_state": "agreed",
    "current_phase": 4,
    "phases_completed": ["phase-0", "phase-1", "phase-2", "phase-3", "phase-4"],
    "agreed_at": "2025-12-16T11:45:00Z"
  },

  "downstream_integration": {
    "source_type": "trend-scout",
    "auto_load_candidates": true,
    "auto_configure_research_type": true,
    "auto_configure_dok_level": true,
    "auto_configure_language": true
  }
}
```

---

## Dimension Matrix

Each dimension is used to scout trends. Each trend discovered in any dimension is then analyzed through the complete TIPS framework (T→I→P→S).

**Each dimension has 3 subcategories** to ensure balanced trend discovery across all aspects:

| Dimension | Subcategory | German | Focus | Trend Anchors |
|-----------|-------------|--------|-------|---------------|
| externe-effekte | wirtschaft | Wirtschaft | Market forces, competition, economic factors | Multikrise, Digital Transform, Net Neutral |
| externe-effekte | regulierung | Regulierung | Policy, compliance, legal frameworks | CSR-D/LKSG, EU AI Act, EU Data Act |
| externe-effekte | gesellschaft | Gesellschaft | Demographics, societal shifts | Demografie, De-Coupling, De-Carbonisation |
| neue-horizonte | strategie | Strategie | Business model direction, strategic goals | Nachhaltigkeit, Resilienz, OPs Excellence |
| neue-horizonte | fuehrung | Führung | Leadership approaches, organizational change | Business Agility, Open Leadership, Purpose |
| neue-horizonte | steuerung | Steuerung | Governance, analytics, control systems | Trends Driven, Risk Management, Predictive KI |
| digitale-wertetreiber | customer-experience | Customer Experience | Customer touchpoints, engagement | Digital First, Omnichannel, Metaverse |
| digitale-wertetreiber | produkte-services | Produkte & Services | Offerings, product innovation | Smartification, Digital Twin, Digital Ecosystem |
| digitale-wertetreiber | geschaeftsprozesse | Geschäftsprozesse | Operations, process optimization | Hyperautomate, Smart Manufacturing, Digi Supply Chain |
| digitales-fundament | kultur | Kultur | Organizational culture, mindset | New Work, Employee Wellbeing, Data Culture |
| digitales-fundament | mitarbeitende | Mitarbeitende | Workforce, skills, talent | Digital Workplace, Up/Reskilling, Talent Management |
| digitales-fundament | technologie | Technologie | Tech infrastructure, platforms | Cyber Security, Data Platforms, Industry X-Cloud |

**Balancing Rule:** Each cell (dimension × horizon) must have at least 1 candidate from each subcategory. With 5 candidates per cell and 3 subcategories, this ensures complete coverage with flexibility.

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Industry not selected | Cannot proceed - prompt user |
| Project init fails | Exit with error details |
| All web searches fail | Continue with training-only (warning) |

---

## Integration with Downstream Pipeline

After `trend-scout` completes, the user proceeds with one of two paths:

### Option A — Trend Report (simpler path)

Invoke `/trend-report` directly to generate a narrative TIPS trend report:

1. trend-report auto-discovers this project via `tips-project.json`
2. Enriches each trend with web-sourced quantitative evidence
3. Produces the CxO-level report organized by investment themes

### Option B — Value Modeling (recommended, full pipeline)

Invoke `/value-modeler` to build T→I→P→S relationship networks and ranked solution templates:

1. value-modeler discovers the project and loads `.metadata/trend-scout-output.json`
2. Auto-configures research_type, DOK level, language from `.config`
3. Loads candidates from `.tips_candidates.items`
4. Builds relationship networks, investment themes, and solution templates
5. After value-modeler completes, invoke `/trend-report` for the full CxO narrative

---

## Debugging

### Logging

```bash
# Log file location
${PROJECT_PATH}/.logs/trend-scout-execution-log.txt

# View phase transitions
grep "\[PHASE\]" "${PROJECT_PATH}/.logs/trend-scout-execution-log.txt"

# View validation results
grep "\[VALIDATION\]" "${PROJECT_PATH}/.logs/trend-scout-execution-log.txt"
```

### Common Issues

1. **"Industry not selected"** - User must select from taxonomy
2. **"Project init failed"** - Check workspace root (`$PROJECT_AGENTS_OPS_ROOT` or current directory) is writable
