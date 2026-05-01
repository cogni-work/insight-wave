---
name: trend-research
description: |
  Run the research groundwork stage of the TIPS trend pipeline. Reads agreed
  trend-scout candidates, optionally performs recursive deep research on 3–5
  high-value ACT-horizon trends, then dispatches 4 parallel
  `cogni-trends:trend-report-writer` agents to enrich every candidate with
  web-sourced quantitative evidence and extract verifiable claims. Produces
  per-dimension enriched-trends + claims artefacts and a single research
  manifest (`.metadata/trend-research-output.json`) that downstream skills
  (`/trend-synthesis`, `/trend-booklet`) consume as their gate. Required pipeline:
  trend-scout → value-modeler → trend-research → (trend-synthesis and/or
  trend-booklet) → verify-trend-report. Use when: (1) trend-scout and
  value-modeler have completed, (2) the user wants to refresh evidence without
  rewriting prose, (3) the user mentions "enrich trends", "deep research trends",
  "research evidence", "refresh trend evidence", "prepare trend report",
  "run the trend research stage". Always use this skill when trend-scout output
  exists and the user wants any kind of evidence-enrichment pass over the
  candidate set — even if they don't say "trend-research" verbatim. Auto-recommends
  `/trend-synthesis` and `/trend-booklet` at the end.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
---

# Trend Research

Research groundwork for the TIPS trend pipeline. Reads agreed trend-scout candidates, optionally deep-researches 3–5 high-value Act-horizon trends, dispatches 4 parallel agents (one per Smarter Service dimension) to enrich every candidate with web-sourced quantitative evidence and extract claims, then writes a single research manifest that downstream synthesis and booklet skills consume as their gate.

## Purpose

Produce the canonical research artefacts that both the TIPS report (`/trend-synthesis`) and the comprehensive TIPS catalog (`/trend-booklet`) need:

1. Validate prerequisites (trend-scout `agreed`, value-model with investment themes)
2. Select 3–5 high-value Act-horizon trends for optional deep research
3. Enrich each of the ~60 candidates with quantitative evidence and source citations via 4 parallel `cogni-trends:trend-report-writer` agents
4. Extract per-trend claims for downstream verification
5. Write `.metadata/trend-research-output.json` — the single manifest both `/trend-synthesis` and `/trend-booklet` gate on
6. Auto-recommend `/trend-synthesis` (canonical TIPS report) and `/trend-booklet` (full candidate catalog)

This skill **does not** write the final report — prose composition lives in `/trend-synthesis`. Splitting research from synthesis lets the user re-run either stage independently and lets the booklet skill consume the same evidence pool without duplicating work.

## Language Support

Full German and English support. This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

**Two language concepts:**

1. **Interaction language** — how the skill communicates with the user (prompts, status). Determined by workspace `.workspace-config.json` language setting.
2. **Output language** — what language the enriched evidence and claims are written in. Default priority: (1) trend-scout `project_language`, (2) workspace language, (3) `en`. Always confirm at the start of Phase 0.

Web searches always run bilingually (English tier + market-region local language) regardless of report language for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 60 candidates
- `value-modeler` completed with `tips-value-model.json` containing `investment_themes[]` (the synthesis skill needs this; research validates upfront so users aren't blocked later)
- Web access enabled for evidence enrichment
- Downstream: `trend-synthesis` (TIPS report) and/or `trend-booklet` (catalog), then `verify-trend-report`

## Context Independence

This skill reads ALL required state from project files — it does not depend on prior conversation context. The trends-resume dashboard, earlier questions, and any preceding chat are not inputs. **Context compaction is safe and recommended** before starting.

Before executing Phase 0, run `/compact` to free working memory. Phase 1 delegates evidence enrichment to 4 parallel agents that self-load candidates from disk — the orchestrator never holds the full candidate set in context.

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-trends` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (optional, set by cogni-workspace) | User's workspace directory |

`CLAUDE_PLUGIN_ROOT` is injected automatically. `PROJECT_AGENTS_OPS_ROOT` is set by cogni-workspace — if absent, scripts fall back to `$PWD`.

## Shell Usage

This skill is a pure orchestrator. All file I/O uses Read/Write tools; web research is delegated to agents. Shell commands needed:
- `rm -f pattern` — cleanup of stale research artefacts on re-run
- `bash {script}` — invoke `validate-enriched-trends.sh` after Phase 1

Avoid `jq`, `sed`, `awk`, or `grep` for data processing — the LLM parses JSON inline.

## References Index

Read references **only when needed** for the specific phase:

| Reference | Read when... |
|-----------|--------------|
| [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md) | Language detection (Phase 0.0) |
| [$CLAUDE_PLUGIN_ROOT/references/data-model.md]($CLAUDE_PLUGIN_ROOT/references/data-model.md) | Entity schemas and project structure |
| [references/deep-research-selection.md](references/deep-research-selection.md) | Phase 0.5 — deep-research candidate selection criteria |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Phase 1 — web search strategy passed to writer agents |
| [references/claims-format.md](references/claims-format.md) | Phase 1 — claims extraction schema |
| [references/research-manifest-schema.md](references/research-manifest-schema.md) | Phase 2 — manifest format and field semantics |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English status messages |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German status messages |

## Workflow Overview

```text
Phase 0 → Phase 0.5 → Phase 1 → Phase 2
   │         │           │          │
   │         │           │          └─ Write research manifest, recommend /trend-synthesis + /trend-booklet
   │         │           └─ 4 parallel agents: enrich trends, extract claims; JSON-validity gate
   │         └─ Optional deep research for 3–5 high-value ACT-horizon trends
   └─ Project discovery, load inputs, validate gate, cleanup, language
```

---

### Phase 0: Project Discovery + Input Loading

#### Step 0.0: Detect Interaction Language

Read [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md). Detect workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD). Set `INTERACTION_LANGUAGE` — use this for all user-facing messages from this point on.

#### Step 0.1: Project Discovery

> Trend-scout projects use `trend-scout-output.json` (not `sprint-log.json`), so the shared `project-picker.md` pattern does not apply.

1. If `--project-path` was provided as argument, use it directly
2. Otherwise, run `discover-projects.sh --json` to enumerate all projects
3. For each project, check if `{path}/.metadata/trend-scout-output.json` exists
4. Read the file and check `execution.workflow_state == "agreed"` and `tips_candidates.total >= 60`
5. Collect eligible projects:
   - 0 eligible: ERROR — "No agreed trend-scout projects found. Run trend-scout first."
   - 1 eligible: Auto-select
   - 2+ eligible: Present via AskUserQuestion

#### Step 0.2: Load Input Data

```
REQUIRED (validate only — do NOT hold candidates or signals in context):
  {PROJECT_PATH}/.metadata/trend-scout-output.json
    → Extract: config.industry, config.research_topic
    → Extract: config.market_region (default: "dach" if absent)
    → Extract: project_language (top-level)
    → Validate: tips_candidates.total >= 60, execution.workflow_state == "agreed"
    → Do NOT extract tips_candidates.items — agents read these themselves

REQUIRED (value model — validate only; pruning is /trend-synthesis's job):
  {PROJECT_PATH}/tips-value-model.json
    → Check: investment_themes[] array exists and has ≥1 entry
```

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 60` | HALT: Expected 60 agreed candidates |
| Value model exists | `tips-value-model.json` with investment_themes[] | HALT: Run value-modeler first |
| Config complete | industry, subsector, language present | HALT: Incomplete config |

#### Step 0.4: Confirm Output Language

The `project_language` from trend-scout-output.json is the **default**. Always confirm with the user. Present the question in `INTERACTION_LANGUAGE`:

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "In welcher Sprache soll die Evidenz erfasst werden? trend-scout hat '{project_language}' verwendet."
  header: "Output-Sprache"
  options:
    - label: "Deutsch (DE) ← Standard"
    - label: "English (EN)"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "Output language for enriched evidence? trend-scout used '{project_language}'."
  header: "Output language"
  options:
    - label: "English (EN) ← Default"
    - label: "Deutsch (DE)"
```

Set `LANGUAGE` to the user's choice. Update `project_language` in trend-scout-output.json if changed.

#### Step 0.5: Clean Up Stale Research Artefacts

On re-runs, remove stale research artefacts only — leave synthesis and booklet outputs alone (those skills clean up their own outputs):

```bash
# bash -O nullglob: zsh aborts on first unmatched glob; nullglob makes empty
# matches a no-op so every pattern is evaluated.
bash -O nullglob -c 'rm -f \
  "{PROJECT_PATH}/.logs/section-"*.md \
  "{PROJECT_PATH}/.logs/enriched-trends-"*.json \
  "{PROJECT_PATH}/.logs/claims-"*.json \
  "{PROJECT_PATH}/.logs/deep-research-"*.json \
  "{PROJECT_PATH}/.metadata/trend-research-output.json"'
```

The cleanup is intentionally narrow: synthesis-stage files (`report-header.md`, `macro-section-*.md`, `theme-case-*.md`, `report-shared-primer.md`, `tips-trend-report.md`, `tips-trend-report-claims.json`) are owned by `/trend-synthesis` and may be valid from a previous run; booklet files similarly. Re-running research invalidates synthesis and booklet downstream — the manifest's content hashes (Phase 2) are how those skills detect this.

---

### Phase 0.5: Deep Research Selection (Optional)

**When to run:** Offer this phase when the user wants deeper evidence for high-value trends. Skip if the user wants a fast research pass or explicitly declines.

**Purpose:** Select 3–5 high-value ACT-horizon trends for recursive deep research before standard evidence enrichment. Deep-researched trends get richer evidence (quantitative data, forcing functions, ROI figures) that strengthens the downstream synthesis arguments.

Read [references/deep-research-selection.md](references/deep-research-selection.md) for the full selection criteria.

**Step 0.5.1: Offer Deep Research**

Ask via AskUserQuestion (3 options: auto, skip, manual). See `deep-research-selection.md` for the prompt text.

**Step 0.5.2: Auto-Select or User-Select**

If user chose auto, apply the selection criteria from `deep-research-selection.md`. If user chose manual, present the ACT-horizon trend list and let them pick.

**Step 0.5.3: Dispatch Deep Researchers (Parallel)**

Dispatch one `cogni-trends:trend-deep-researcher` agent per selected trend, all in parallel:

```yaml
Task:
  subagent_type: "cogni-trends:trend-deep-researcher"
  description: "Deep research: {TREND_NAME}"
  prompt: |
    Perform deep research on this trend candidate.

    PROJECT_PATH: {{PROJECT_PATH}}
    TREND_NAME: {{TREND_NAME}}
    TREND_KEYWORDS: {{KEYWORDS}}
    DIMENSION: {{DIMENSION}}
    HORIZON: act
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    SUBSECTOR_LOCAL: {{SUBSECTOR_LOCAL}}
    RESEARCH_HINT: {{RESEARCH_HINT}}
    MARKET_REGION: {{MARKET_REGION}}
```

**Process results:** Each agent writes a `.logs/deep-research-{slug}.json` artifact. Log success/failure counts. These artifacts are consumed by Phase 1 trend-report-writer agents — trends with deep research artifacts skip their own WebSearch and use the richer findings directly.

---

### Phase 1: Evidence Enrichment + Section Generation (PARALLEL)

Read [references/evidence-enrichment.md](references/evidence-enrichment.md) for web search strategy.
Read [references/claims-format.md](references/claims-format.md) for claims extraction schema.

**Deep research integration:** Before each trend-report-writer agent runs its evidence enrichment, it checks for `{PROJECT_PATH}/.logs/deep-research-{trend-slug}.json`. If a deep research artifact exists for a trend in its dimension, the writer uses the artifact's `synthesis` and `sources` instead of running its own WebSearch for that trend. This is a fourth evidence status alongside `signal_sufficient`, `signal_partial`, and `signal_none`: **`deep_research_available`** — richest evidence tier, no additional search needed.

#### Step 1.1: Dispatch 4 Agents

Dispatch all 4 agents in a single message (parallel tool calls) so they run concurrently:

```yaml
Per agent:
  subagent_type: "cogni-trends:trend-report-writer"
  model: sonnet
  prompt: |
    Dimension: {DIMENSION}
    TIPS Role: {TIPS_ROLE}
    Project Path: {PROJECT_PATH}
    Language: {LANGUAGE}
    Market Region: {MARKET_REGION}
    Industry EN/DE: {INDUSTRY_EN} / {INDUSTRY_DE}
    Subsector EN/DE: {SUBSECTOR_EN} / {SUBSECTOR_DE}
    Subsector Local: {SUBSECTOR_LOCAL}
    Topic: {TOPIC}
    Labels: {relevant i18n labels}
```

Agents self-load candidates and raw signals from disk using `PROJECT_PATH` — no need to pass data in the prompt. This keeps the orchestrator context lean.

Dimensions: `externe-effekte` (T), `digitale-wertetreiber` (I), `neue-horizonte` (P), `digitales-fundament` (S).

Each agent writes:
- `{PROJECT_PATH}/.logs/section-{dimension}.md` — narrative section (kept; `verify-trend-report`'s revisor reads it as fallback evidence)
- `{PROJECT_PATH}/.logs/claims-{dimension}.json` — extracted claims
- `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` — per-trend evidence blocks keyed by candidate_ref; `actions_md` uses semicolon-separated keywords (used by downstream synthesis assembly)

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics, and the three output file paths.

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

#### Step 1.3: Validate Agent Output Files

After all 4 agents complete, verify all 12 expected files exist:

```
For each dimension in [externe-effekte, digitale-wertetreiber, neue-horizonte, digitales-fundament]:
  ✓ {PROJECT_PATH}/.logs/section-{dimension}.md
  ✓ {PROJECT_PATH}/.logs/claims-{dimension}.json
  ✓ {PROJECT_PATH}/.logs/enriched-trends-{dimension}.json
```

If any `section-{dimension}.md` is missing, log a WARNING (synthesis can still proceed via enriched-trends).

**JSON-validity gate (issue #182 hardening).** The four `enriched-trends-{dimension}.json` files are consumed by both downstream skills — a single malformed file silently blocks both. After the existence check, run the parse-then-repair gate:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-research/scripts/validate-enriched-trends.sh" "${PROJECT_PATH}"
```

- On `{"ok":true, ...}` (exit 0): proceed. If `repaired[]` is non-empty, log the count per file.
- On `{"ok":false, "error":"json_unrepairable", ...}` (exit 4): HALT. Surface the file path and line/column to the user. Do NOT proceed — the broken file would corrupt downstream assembly. Recovery: re-dispatch the affected dimension's `trend-report-writer` agent.

---

### Phase 2: Write Research Manifest

Read [references/research-manifest-schema.md](references/research-manifest-schema.md) for the full schema and field semantics.

The manifest is the single source of truth that downstream skills use to (a) confirm research is complete, (b) detect drift between research and synthesis runs, and (c) discover the per-dimension artefact paths.

#### Step 2.1: Compute Content Hashes

Compute the candidate-set and value-model hashes that anchor downstream drift detection. Use the same recipe as the legacy trend-report Phase 4.1 hashing block, applied at research time:

```python
import hashlib, json

scout = json.load(open(scout_path))
items = scout.get('tips_candidates', {}).get('items', []) or []
def _key(c): return c.get('id') or c.get('title') or ''
items_sorted = sorted(items, key=_key)
candidates_hash_at_research = 'sha256:' + hashlib.sha256(
    json.dumps(items_sorted, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()

vm = json.load(open(vm_path))
def _sorted(seq, key):
    return sorted(seq or [], key=lambda x: (x.get(key) or '') if isinstance(x, dict) else '')
vm_payload = {
    'investment_themes': _sorted(vm.get('investment_themes'), 'theme_id'),
    'solutions':         _sorted(vm.get('solutions'),         'solution_id'),
    'blueprints':        _sorted(vm.get('blueprints'),        'solution_id'),
}
value_model_hash_at_research = 'sha256:' + hashlib.sha256(
    json.dumps(vm_payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()
```

Hashing rules: always `json.dumps(..., sort_keys=True, separators=(',', ':'), ensure_ascii=False)` for deterministic output across re-runs and locales. Hash only candidate items and the three substantive value-model sections — never timestamps, mtimes, or any field this same step writes back.

#### Step 2.2: Write the Manifest

Write `{PROJECT_PATH}/.metadata/trend-research-output.json`:

```json
{
  "trend_research_complete": true,
  "trend_research_completed_at": "ISO-8601",
  "language": "{LANGUAGE}",
  "market_region": "{MARKET_REGION}",
  "candidates_total": 60,
  "dimensions_enriched": [
    "externe-effekte",
    "digitale-wertetreiber",
    "neue-horizonte",
    "digitales-fundament"
  ],
  "deep_research_trends": [
    { "trend_name": "...", "dimension": "...", "slug": "...", "artifact": ".logs/deep-research-{slug}.json" }
  ],
  "claims_total": 0,
  "claims_by_dimension": {
    "externe-effekte": 0,
    "digitale-wertetreiber": 0,
    "neue-horizonte": 0,
    "digitales-fundament": 0
  },
  "files": {
    "enriched_trends": {
      "externe-effekte": ".logs/enriched-trends-externe-effekte.json",
      "digitale-wertetreiber": ".logs/enriched-trends-digitale-wertetreiber.json",
      "neue-horizonte": ".logs/enriched-trends-neue-horizonte.json",
      "digitales-fundament": ".logs/enriched-trends-digitales-fundament.json"
    },
    "claims": {
      "externe-effekte": ".logs/claims-externe-effekte.json",
      "digitale-wertetreiber": ".logs/claims-digitale-wertetreiber.json",
      "neue-horizonte": ".logs/claims-neue-horizonte.json",
      "digitales-fundament": ".logs/claims-digitales-fundament.json"
    },
    "sections": {
      "externe-effekte": ".logs/section-externe-effekte.json",
      "digitale-wertetreiber": ".logs/section-digitale-wertetreiber.md",
      "neue-horizonte": ".logs/section-neue-horizonte.md",
      "digitales-fundament": ".logs/section-digitales-fundament.md"
    }
  },
  "candidates_hash_at_research": "sha256:...",
  "value_model_hash_at_research": "sha256:..."
}
```

Fill `claims_by_dimension` and `claims_total` by summing `claims_count` from each `.logs/claims-{dimension}.json` (read each file once, extract the integer, no need to load the full claims arrays).

#### Step 2.3: Display Summary

```
Trend Research Complete
─────────────────────
Candidates:    60 enriched across 4 dimensions
Deep research: {COUNT} trends
Claims:        {total_claims} extracted across 4 dimension files
Manifest:      {PROJECT_PATH}/.metadata/trend-research-output.json

Next step → Compose the canonical TIPS report:
             /trend-synthesis

Also available:
   /trend-booklet  — produce the comprehensive TIPS catalog of all candidates
```

Both downstream skills can run in either order; they're independent consumers of this manifest.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `trend-scout-output.json` missing | HALT: Run trend-scout first |
| `workflow_state != "agreed"` | HALT: Complete candidate selection |
| `tips_candidates.total < 60` | HALT: Expected 60 candidates |
| `tips-value-model.json` missing or no investment themes | HALT: Run value-modeler first |
| No raw signals file (both sources) | WARNING: proceed without signals (~120 searches) |
| Phase 1 agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 Phase 1 agents fail | HALT: Check web access is enabled |
| enriched-trends JSON missing after Phase 1 | HALT: Phase 1 agent failed to produce enriched output |
| enriched-trends JSON unrepairable | HALT with file + line/col; re-dispatch the affected dimension |
| Deep researcher returns `ok: false` | Log warning, proceed without that artifact (writer falls back to standard enrichment) |

## Integration

**Upstream:**
- `trend-scout` produces `trend-scout-output.json` (required)
- `value-modeler` produces `tips-value-model.json` (required)

**Pipeline:** `trend-scout → value-modeler → trend-research → (trend-synthesis | trend-booklet) → verify-trend-report`

**Downstream:**
- `cogni-trends:trend-synthesis` — composes the canonical TIPS report (`tips-trend-report.md`) from this manifest
- `cogni-trends:trend-booklet` — builds the comprehensive TIPS catalog (`tips-trend-booklet.md`) from this manifest

Both downstream skills gate on `.metadata/trend-research-output.json` existing and use its `candidates_hash_at_research` / `value_model_hash_at_research` to detect drift.

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `section-{dimension}.md` — narrative dimension sections (4 files; revisor fallback evidence)
- `enriched-trends-{dimension}.json` — per-trend evidence blocks (4 files; consumed by synthesis + booklet)
- `claims-{dimension}.json` — extracted claims (4 files)
- `deep-research-{slug}.json` — deep research artefacts (3–5 files when Phase 0.5 ran)

Metadata in `{PROJECT_PATH}/.metadata/`:
- `trend-research-output.json` — single research manifest

| Issue | Check |
|-------|-------|
| Phase 1 agent hangs | Verify web access is enabled |
| Empty claims | Check if trends have quantitative data in trend-scout output |
| Wrong language | Verify `project_language` in trend-scout-output.json |
| Missing manifest after a successful Phase 1 | Re-run — Phase 2 is idempotent |
