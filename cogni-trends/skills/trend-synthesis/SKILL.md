---
name: trend-synthesis
description: |
  Compose the canonical TIPS trend report from research artefacts produced by
  `/trend-research`. The report is always organized around the four Smarter
  Service dimensions (Forces → Impact → Horizons → Foundations) as H2 sections,
  with investment themes nested as anchored H3 cases written in a slim 3-beat
  structure (Stake / Move / Cost-of-Inaction). Closes on a "Capability
  Imperative" synthesis. The four dimensions form a single CxO story arc — see
  the Storytelling Spine — and the writer agents thread protagonist-shaped
  micro-stories under the structural beats. Produces `tips-trend-report.md`
  plus `tips-trend-report-claims.json` — the same canonical filenames the
  legacy `trend-report` skill produced, so `/verify-trend-report` keeps working
  unchanged. Required pipeline: trend-scout → value-modeler → trend-research
  → trend-synthesis → verify-trend-report. Use when: (1) `/trend-research`
  has completed and written `.metadata/trend-research-output.json`, (2) the
  user wants a written trend report, (3) the user mentions "trend report",
  "TIPS report", "write up trends", "compose trend report", "synthesize trends",
  "investment themes report", "strategic trend report", (4) preparing a
  deliverable from enriched evidence. Always use this skill when the research
  manifest exists and the user wants the prose report — even if they don't say
  "synthesis" verbatim. Auto-recommends `/verify-trend-report` at the end.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
---

# Trend Synthesis

Compose the canonical TIPS trend report from `/trend-research` output. The report's H2 spine is the 4 Smarter Service dimensions (T → I → P → S); investment themes nest under their anchor dimension as H3 theme-cases (Stake / Move / Cost-of-Inaction). Closes on a Foundations-anchored "Capability Imperative" synthesis. The four dimensions are not parallel essays — they trace a single rising-tension arc. The Storytelling Spine section below is the load-bearing reference for that arc.

## Purpose

Transform the research manifest plus enriched per-trend evidence into a CxO-grade strategic report:

1. Locate the research output (gate on manifest existing; warn on drift)
2. Propose a punchy report title (subtitle = research topic)
3. Pick a length tier and compute per-section word budgets (smarter-service formula only)
4. Anchor each investment theme to its dominant TIPS dimension
5. Write the shared dimension primer (orchestrator)
6. Dispatch N parallel theme-case writers — each writes a micro-story (Storytelling Spine)
7. Dispatch 4 sequential dimension composers (T → I → P → S, voice consistency, with bridge sentences)
8. Compose the executive summary — opens on the Why-Now hook
9. Build the claims registry with a dimension column
10. Write the "Capability Imperative" synthesis section — closes with a callback to the Why-Now hook
11. Assemble + merge claims → `tips-trend-report.md` + `tips-trend-report-claims.json`
12. Update finalization metadata; auto-recommend `/verify-trend-report`

Evidence lives in research outputs; this skill never re-runs WebSearch.

## Language Support

Full German and English support. This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

The report inherits `language` from the research manifest (set during `/trend-research` Phase 0). The user may override at the title-proposal step (Step 0.5) but the new value also propagates to the manifest mirror in finalization metadata.

## Prerequisites

- `/trend-research` completed with `.metadata/trend-research-output.json` present
- `tips-value-model.json` with `investment_themes[]` and `value_chains[]`
- The 4 `enriched-trends-{dimension}.json` files referenced in the manifest
- Downstream: `verify-trend-report` (in this plugin) handles claim verification, structural review, revision, and the final polish/visualize menu

## Context Independence

This skill reads ALL required state from project files. **Context compaction is safe and recommended** before starting. Phase 2 delegates theme-case writing to N parallel agents and dimension composition to 4 sequential agents; the orchestrator stays lean by reading per-dimension evidence on demand.

If `/compact` is unavailable, proceed without it — Phase 2's agent-based architecture is designed to stay within context limits.

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-trends` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (optional) | User's workspace directory |

## Shell Usage

Pure orchestrator. Shell commands needed:
- `cat file1 file2 ... > output` — concatenation of log files into the final report (Step 2.6)
- `rm -f pattern` — cleanup of stale synthesis artefacts on re-run
- `[ -f file ]` — existence checks before concatenation

Avoid `jq`, `sed`, `awk`, or `grep` for data processing.

## References Index

Read references **only when needed** for the specific phase:

| Reference | Read when... |
|-----------|--------------|
| [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md) | Language detection (Phase 0.0) |
| [$CLAUDE_PLUGIN_ROOT/references/data-model.md]($CLAUDE_PLUGIN_ROOT/references/data-model.md) | Entity schemas |
| [references/synthesis-skeleton.md](references/synthesis-skeleton.md) | Phase 2 — the canonical macro-skeleton flow (anchoring → primer → theme-cases → composers → exec → synthesis → assembly) |
| [references/report-structure.md](references/report-structure.md) | Phase 1–2 — dimension section template (also used by writer agents in research) |
| [references/report-length-tiers.md](references/report-length-tiers.md) | Phase 1 — length tier definitions and budget formula |
| [references/capability-imperative.md](references/capability-imperative.md) | Phase 2.5 — "The Capability Imperative" synthesis pattern |
| [references/claims-registry-format.md](references/claims-registry-format.md) | Phase 2.4 — claims registry table format |
| [references/story-arc-loop.md](references/story-arc-loop.md) | Authoring-time only — methodology audit of how the storytelling guidance in this SKILL.md was derived (closed-loop reviews with `cogni-narrative:narrative-reviewer`). Read when extending storytelling guidance. |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German headings and labels |

## Workflow Overview

```text
Phase 0 → Phase 0.5 → Phase 1 → Phase 2 → Phase 3
   │         │           │         │         │
   │         │           │         │         └ Finalize metadata, auto-recommend /verify-trend-report
   │         │           │         └ Anchor → primer → theme-cases (parallel) → composers (4 sequential, with bridges) → exec (Why-Now hook) → claims registry → synthesis (callback) → assemble
   │         │           └ Length tier + budgets (smarter-service formula)
   │         └ Title proposal
   └ Locate research output, drift check, value-model subset, language, cleanup
```

## Storytelling Spine

The 4 dimensions are not 4 parallel essays. They trace a single CxO arc:
the report opens on an inciting incident, climbs through rising tension and a
decision threshold, and lands on a capability test the reader must answer.
Writer and composer agents must trace this arc — `references/story-arc-loop.md`
records how this guidance was derived through closed-loop reviews with
`cogni-narrative:narrative-reviewer` as the storytelling expert.

| Dimension | Story role | Reader question this section answers |
|-----------|------------|---------------------------------------|
| Forces (T) | Inciting incident | "Why now?" |
| Impact (I) | Rising tension | "What changes for the business?" |
| Horizons (P) | Decision threshold | "What new ground opens up?" |
| Foundations (S) | Capability test | "Can we afford to wait?" |

**Opener (executive summary).** Opens on the inciting incident — the most
acute Forces theme — *not* on a topic recap. The first sentence is a Why-Now
hook the closer can call back to. The protagonist is named by role and
decision context ("the head of after-sales watching warranty cost ratios
drift"), never as the abstract "CxO".

**Theme-cases.** Each theme-case is a *micro-story* with five elements:

- **Protagonist** — the operating leader, named by role + decision context.
- **Obstacle** — a specific market force from enriched evidence, named.
  Never abstract ("competition", "disruption").
- **Stakes** — cost ratio + window, drawn from the value model.
- **Move** — the capability investment.
- **Payoff** — one phrase the synthesis can pick up as a recurring motif.

The Stake / Move / Cost-of-Inaction beats remain the load-bearing *structure*
underneath the micro-story. They must not surface as visible headers in the
rendered prose.

**Bridges.** Each dimension narrative ends with a one-sentence bridge that
names the tension carried forward. Composers pick one of three patterns,
*varying* across the four dimensions so the report doesn't read as a
checklist:

- **Causal:** "...which is why X must change."
- **Contrastive:** "...but the move that follows isn't Y, it's Z."
- **Escalating:** "...and the bill arrives faster than the planning cycle."

The Foundations bridge specifically hands the reader to the Capability
Imperative by naming the single capability the synthesis will frame.

**Closer (Capability Imperative).** Closes with a callback to the Why-Now
hook from the opener — the report ends where it started, but with stakes now
specified and the load-bearing capability named. This is what makes the
report read as one story instead of four essays plus a wrap-up.

---

### Phase 0: Locate Research Output + Load Inputs

#### Step 0.0: Detect Interaction Language

Read [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md). Detect workspace language from `.workspace-config.json`. Set `INTERACTION_LANGUAGE`.

#### Step 0.1: Project Discovery

If `--project-path` was provided, use it. Otherwise run `discover-projects.sh --json`. Filter to projects where `.metadata/trend-research-output.json` exists. 0 → HALT ("Run /trend-research first"); 1 → auto-select; 2+ → AskUserQuestion.

#### Step 0.2: Load Research Manifest + Drift Check

Read `{PROJECT_PATH}/.metadata/trend-research-output.json`. Extract `language`, `market_region`, `dimensions_enriched`, `files`, `claims_total`, `candidates_hash_at_research`, `value_model_hash_at_research`.

**Drift detection** (per the contract in `trend-research/references/research-manifest-schema.md`):

1. Recompute current `candidates_hash` from `.metadata/trend-scout-output.json` using the canonical recipe.
2. Recompute current `value_model_hash` from `tips-value-model.json` using the canonical recipe.
3. Compare to the manifest values.
4. On mismatch, WARN with the impact line ("60 candidates differ…" or "Investment themes changed…") and offer to re-run `/trend-research`. The user may proceed with stale evidence on explicit confirmation — they own that risk.

#### Step 0.2b: Backwards-Compat Cleanup (legacy projects only)

If the project carries legacy `report_arc_id` or `trend_report_arc_id` fields from a pre-split run, log a single info line:

```
legacy report_arc_id ignored — using canonical TIPS skeleton
```

Do NOT halt; the legacy field is harmless once finalization (Phase 3) overwrites it.

#### Step 0.2c: Extract Phase 2 Value-Model Subset

The full `tips-value-model.json` contains scoring matrices, blueprints, and reanchor logs that Phase 2 does not need. To reduce context pressure, extract only the fields Phase 2 uses and write a pruned subset.

Write `{PROJECT_PATH}/.logs/phase2-value-model.json` containing ONLY these top-level keys:

```json
{
  "investment_themes": [],
  "value_chains": [],
  "orphan_candidates": [],
  "coverage": {},
  "mece_validation": {},
  "solution_templates": [
    { "st_id": "...", "name": "...", "category": "...", "enabler_type": "...", "investment_theme_ref": "...", "portfolio_grounding": [...] }
  ]
}
```

- Copy `investment_themes`, `value_chains`, `orphan_candidates`, `coverage`, `mece_validation` in full
- For each `solution_templates[]` entry, keep ONLY: `st_id`, `name`, `category`, `enabler_type`, `investment_theme_ref`, `portfolio_grounding` — omit `solution_blueprint`, `description`, and all other fields
- Omit all other top-level keys (`reanchor_log`, `solution_process_improvements`, `metrics`, `collaterals`, `portfolio_gaps`, etc.)

#### Step 0.3: Load i18n Labels

Read the labels file matching the report language (from manifest):
- English: [references/i18n/labels-en.md](references/i18n/labels-en.md)
- German: [references/i18n/labels-de.md](references/i18n/labels-de.md)

#### Step 0.4: Clean Up Stale Synthesis Outputs

On re-runs, remove stale synthesis artefacts. Research outputs (enriched-trends, claims, deep-research) are owned by `/trend-research` and untouched.

```bash
bash -O nullglob -c 'rm -f \
  "{PROJECT_PATH}/.logs/report-header.md" \
  "{PROJECT_PATH}/.logs/theme-case-"*.md \
  "{PROJECT_PATH}/.logs/macro-section-"*.md \
  "{PROJECT_PATH}/.logs/report-shared-primer.md" \
  "{PROJECT_PATH}/.logs/report-theme-anchors.json" \
  "{PROJECT_PATH}/.logs/report-synthesis.md" \
  "{PROJECT_PATH}/.logs/report-claims-registry.md" \
  "{PROJECT_PATH}/tips-trend-report.md" \
  "{PROJECT_PATH}/.logs/phase2-value-model.json" \
  "{PROJECT_PATH}/tips-trend-report-claims.json" \
  "{PROJECT_PATH}/tips-insight-summary.md"'
```

Legacy artefacts (`investment-theme-*.md`, `report-bridge-*.md`, `report-section-*.md`) from pre-split runs are also removed by the wider glob if present — the canonical TIPS skeleton does not produce them.

---

### Phase 0.5: Propose Report Title

The research question (`{TOPIC}` from `.metadata/trend-scout-output.json → config.research_topic`) becomes the **subtitle**. Generate a punchy **title** (max 8 words) from `{TOPIC}`, `INDUSTRY`, and the investment-theme names. The title should:

- Be CxO-level — sharp, memorable, forward-looking
- Reflect the smarter-service stance (capability convergence, foundation urgency)
- NOT repeat the research question or be a generic label like "Trend Report"

The subtitle is `{TOPIC}`, optionally shortened for readability (drop redundant geographic/industry qualifiers if obvious from context).

Present via AskUserQuestion (template in `i18n/labels-{en,de}.md` under `PHASE_0_TITLE_*`). Store the final values as `{TITLE}` and `{SUBTITLE}`.

---

### Phase 1: Length Tier + Budgets

Read [references/report-length-tiers.md](references/report-length-tiers.md) for tier definitions and the smarter-service budget formula.

**Resume rule:** Read `{PROJECT_PATH}/tips-project.json`. If it already contains `report_tier` (and optionally `report_target_words`), skip the question — display `"Length tier: {report_tier} (~{report_target_words} prose words)"` and continue.

Otherwise present the AskUserQuestion (4 tier options; default `standard` = 4,000 prose words). Persist the choice to `tips-project.json`:

```json
{
  "report_tier": "{tier}",
  "report_target_words": {N}
}
```

#### Compute Length Budget (smarter-service formula)

```text
# Initial allocation
exec_words              = clamp(REPORT_TARGET_WORDS * 0.10, 200, 350)
synthesis_words         = clamp(REPORT_TARGET_WORDS * 0.08, 300, 800)
dim_narrative_words     = clamp(REPORT_TARGET_WORDS * 0.12, 250, 600)   # PER dimension
theme_cases_total       = REPORT_TARGET_WORDS - exec_words - synthesis_words - 4 * dim_narrative_words

# Floor-binding redistribution: when per-theme-case would land at or below the
# structural floor (290), shift budget from dim_narrative_words (down to its 250
# floor) into theme_cases_total to give the writer agent realistic headroom.
COMFORT_TARGET = 340
if theme_cases_total < COMFORT_TARGET * N:
    desired_total      = COMFORT_TARGET * N
    gap                = desired_total - theme_cases_total
    available_from_dim = 4 * (dim_narrative_words - 250)
    redistributed      = min(gap, available_from_dim)
    dim_narrative_words = dim_narrative_words - round(redistributed / 4)
    theme_cases_total   = REPORT_TARGET_WORDS - exec_words - synthesis_words - 4 * dim_narrative_words

per_theme_case_words = max(290, round(theme_cases_total / N))
floor_bound_after_rebalance = (per_theme_case_words == 290 and theme_cases_total < COMFORT_TARGET * N)
rebalance_fired = (dim_narrative_words < clamp(REPORT_TARGET_WORDS * 0.12, 250, 600))
```

Set:
- `THEME_CASE_TARGET_WORDS = per_theme_case_words` — passed to each theme-case writer
- `DIMENSION_NARRATIVE_TARGET_WORDS = dim_narrative_words` — passed to each composer
- `SYNTHESIS_TARGET_WORDS = synthesis_words`
- `EXEC_TARGET_WORDS = exec_words`

Display:
- `"Budget computed: ~{REPORT_TARGET_WORDS} prose words across 4 dimensions + {N} theme-cases (~{DIMENSION_NARRATIVE_TARGET_WORDS} per dimension narrative, ~{THEME_CASE_TARGET_WORDS} per theme-case)"`
- When `rebalance_fired` is true and `floor_bound_after_rebalance` is false: also display `{LENGTH_BUDGET_REBALANCED_NOTE}` (informational).
- When `floor_bound_after_rebalance` is true: also display `{LENGTH_BUDGET_FLOOR_WARNING}` (transparency — the per-theme-case target is binding at the structural floor; theme cases will land 30–60% above target).

The claims registry is excluded from word accounting at every stage.

---

### Phase 2: Report Assembly

Read [references/synthesis-skeleton.md](references/synthesis-skeleton.md) for the full step-by-step protocol. The skeleton file is the canonical reference for how to write each section; this SKILL.md only orchestrates the dispatch order. The Storytelling Spine section above is the authoritative reference for narrative shape — writers and composers must follow it.

**Hard ordering constraints:**
- Step 2.0b must complete before Step 2.1 (theme writers need the primer)
- Step 2.1 must complete (all themes) before Step 2.2 (composers concatenate theme-cases)
- Step 2.2 must run sequentially across the 4 dimensions, not in parallel — voice consistency

#### Step 2.0a: Compute Theme Anchoring

For each theme, compute `anchor_dimension` (highest `candidate_ref` count per pole; tiebreak on highest single-candidate composite score; final tiebreak T > I > P > S). Persist to `.logs/report-theme-anchors.json`. Skip if file exists with all themes mapped. See `synthesis-skeleton.md § Step 2.0a` for the full algorithm.

Quality check on `anchor_distribution`: WARN if any dimension carries >3 themes (theme-heavy) or 0 themes (visibly thin section).

#### Step 2.0b: Write Shared Dimension Primer (orchestrator)

Read all 4 `enriched-trends-{dimension}.json` files (paths from manifest) and the value model. Write 4 paragraphs (~120 words each, ~480 total) to `.logs/report-shared-primer.md` — one per Smarter Service dimension, each ending with the anchor pivot sentence naming themes anchored there. The four primer paragraphs should already foreshadow the dimension's story role from the Storytelling Spine — Forces sets up "why now", Impact frames the rising tension, Horizons names the decision, Foundations frames the capability test. Skip if primer file exists and is >800 bytes. Full template in `synthesis-skeleton.md § Step 2.0b`.

#### Step 2.1: Dispatch Theme-Case Writers (parallel)

For each theme, dispatch a `cogni-trends:trend-report-investment-theme-writer` agent in a single parallel message:

```yaml
Task:
  subagent_type: "cogni-trends:trend-report-investment-theme-writer"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    INVESTMENT_THEME_ID: {theme.investment_theme_id}
    INVESTMENT_THEME_NAME: {theme.name}
    STRATEGIC_QUESTION: {theme.strategic_question}
    EXECUTIVE_SPONSOR_TYPE: {theme.executive_sponsor_type}
    LANGUAGE: {LANGUAGE}
    ANCHOR_DIMENSION: {from report-theme-anchors.json}
    SECONDARY_POLES: {JSON array}
    SHARED_PRIMER_PATH: "{PROJECT_PATH}/.logs/report-shared-primer.md"
    SHARED_PRIMER_DIGEST: {200-char summary of the anchor-dimension primer paragraph}
    INVESTMENT_THEME_INDEX: {1-based index}
    VALUE_CHAINS: {JSON array of this theme's value chains}
    SOLUTION_TEMPLATES: {JSON array filtered to investment_theme_ref == this theme}
    PORTFOLIO_PROVIDER: {Display name from portfolio-context.json, empty string if absent}
    MARKET_REGION: {market_region from manifest}
    PORTFOLIO_PRODUCTS: {JSON array}
    SOLUTION_PRICING: {JSON array}
    STUDY_MODE: {"vendor" | "open"}
    EXAMPLE_REFERENCES: {JSON object keyed by st_id}
    THEME_CASE_TARGET_WORDS: {THEME_CASE_TARGET_WORDS from Phase 1}
    LABELS: {JSON object with relevant i18n labels}
    NARRATIVE_ARC_PATH: {path to cogni-narrative smarter-service arc-definition.md, optional}
    NARRATIVE_TECHNIQUES_PATH: {path to cogni-narrative techniques-overview.md, optional}
    STORY_PROTAGONIST: {role + decision context derived from EXECUTIVE_SPONSOR_TYPE and the dominant evidence pattern; e.g. "the head of after-sales watching warranty cost ratios drift" — never abstract like "the CxO"}
    STORY_OBSTACLE: {a specific named market force drawn from the enriched-trend evidence — never abstract like "competition" or "disruption"}
    STORY_MOMENT: {one sensory or behavioural detail anchored in a specific evidence_ref from EXAMPLE_REFERENCES; used once in the case to ground the abstract capability in lived reality. MUST cite the evidence_ref it derives from — never invent}
    STORY_PAYOFF_HANDOFF: {one phrase the synthesis section will pick up as a recurring motif — keep terse, specific, and reusable}
```

The writer agent threads the Stake / Move / Cost-of-Inaction beats *underneath* the protagonist → obstacle → stakes → move → payoff micro-story arc from the Storytelling Spine. The beats are load-bearing but invisible: never surface them as headers. If the prose reads as a feature list, the protagonist or obstacle has gone abstract — re-anchor on evidence.

Resume: skip if `.logs/theme-case-{theme_id}.md` exists and is >600 bytes. Validation per agent: `ok == true`, `primer_referenced == true`, `cost_ratio` and `cost_window` non-empty, `quality_gate_pass == true`, `story_moment_evidence_ref` non-empty (the evidence_ref the STORY_MOMENT is bound to). Retry once on failure.

#### Step 2.2: Dispatch Dimension Composers (sequential, 4 calls)

For each dimension in TIPS order (`externe-effekte` → `digitale-wertetreiber` → `neue-horizonte` → `digitales-fundament`), dispatch one `cogni-trends:trend-report-composer` agent. **Sequential, NOT parallel** — voice consistency depends on this. Each composer writes `macro-section-{dimension}.md` (= H2 heading + dimension narrative + concatenated theme-cases anchored here + secondary callouts). Resume per dimension: skip if file exists and is >800 bytes.

Each composer's dimension narrative MUST end with a one-sentence **bridge** that names the tension carried forward into the next dimension. Composers *choose* one of the three patterns from the Storytelling Spine (causal / contrastive / escalating), and across the four dimensions the patterns must vary — the report should not use the same template four times. The Foundations (S) bridge specifically hands the reader to the Capability Imperative by naming the single capability the synthesis will frame.

Full prompt template and validation in `synthesis-skeleton.md § Step 2.2`.

#### Step 2.3: Write Executive Summary

Read the primer and all 4 macro section files. Write `report-header.md` with YAML frontmatter + cross-dimensional opener + numbered list over the 4 dimensions (naming anchored themes within each entry) + capability-imperative closer. Length: target `EXEC_TARGET_WORDS ± 20%`. Two trailing newlines. Full template in `synthesis-skeleton.md § Step 2.3`.

The opener MUST start with a single-sentence **Why-Now hook** tied to the most acute Forces theme — not a topic recap. The hook names the protagonist by role and decision context (per the Storytelling Spine), and introduces the tension the rest of the report resolves. Treat this sentence as load-bearing: the Capability Imperative closer will call back to it verbatim or in a close paraphrase, so make it memorable and self-contained.

The frontmatter omits `arc_id` (the canonical TIPS skeleton has no arc selector; `report_mode` is the constant `"smarter-service-themed"`).

#### Step 2.4: Generate Claims Registry

Read the 4 `claims-{dimension}.json` files (paths from manifest). Build the `claim_id → claim` lookup with the dimension recorded. Determine investment theme by walking the value model. Render the table per [references/claims-registry-format.md](references/claims-registry-format.md). Write `.logs/report-claims-registry.md`. Two trailing newlines.

#### Step 2.5: Write Synthesis Section ("The Capability Imperative")

Read [references/capability-imperative.md](references/capability-imperative.md) for the full pattern. Foundations-anchored, aggregates capability requirements across themes. Write `.logs/report-synthesis.md`. Length: target `SYNTHESIS_TARGET_WORDS ± 15%`. Two trailing newlines.

The synthesis MUST close with a **callback** to the Why-Now hook from Step 2.3 — the report ends where it started, but with stakes now specified and the single load-bearing capability named. The callback can be verbatim or a close paraphrase; it must not be a generic restatement. Pull at least two STORY_PAYOFF_HANDOFF phrases from the theme-cases as recurring motifs in the synthesis prose, so the reader feels the cases converging on one capability rather than enumerating four.

#### Step 2.6: Assemble Final Report

Verify all files exist, then concatenate in this order:

```bash
FILES="{PROJECT_PATH}/.logs/report-header.md"
for DIM in externe-effekte digitale-wertetreiber neue-horizonte digitales-fundament; do
  FILES="$FILES {PROJECT_PATH}/.logs/macro-section-${DIM}.md"
done
FILES="$FILES {PROJECT_PATH}/.logs/report-synthesis.md {PROJECT_PATH}/.logs/report-claims-registry.md"
cat $FILES > "{PROJECT_PATH}/tips-trend-report.md"
```

Verification: read first 3 + last 3 lines of the assembled report. First lines should be `---` (YAML frontmatter); last lines should contain the claims total. Report should contain exactly 4 macro H2 headers and N H3 theme-case headers distributed per the anchoring map.

#### Step 2.7: Merge Claims

Merge all 4 dimension claims into `tips-trend-report-claims.json` (filename preserved from legacy trend-report so `verify-trend-report` keeps working unchanged). Schema in `trend-research/references/claims-format.md § Merged Claims File`.

---

### Phase 3: Finalize Metadata

#### Step 3.1: Update `tips-project.json` and Scout Output Metadata

Update `{PROJECT_PATH}/tips-project.json` with current timestamp:
```json
{ "updated": "ISO-8601" }
```

Add to `{PROJECT_PATH}/.metadata/trend-scout-output.json`:

```json
{
  "trend_report_complete": true,
  "trend_report_path": "tips-trend-report.md",
  "trend_report_claims_path": "tips-trend-report-claims.json",
  "trend_report_mode": "smarter-service-themed",
  "trend_report_investment_theme_count": N,
  "trend_report_generated_at": "ISO-8601",
  "report_tier": "{REPORT_TIER}",
  "report_target_words": {REPORT_TARGET_WORDS},
  "content_hash_at_report": "sha256:<hex>",
  "value_model_hash_at_report": "sha256:<hex>",
  "candidate_signature": { "<id>": "<short-hash>", ... }
}
```

`trend_report_mode` is the constant `"smarter-service-themed"` — the canonical TIPS skeleton has no arc selector. There is intentionally **no `trend_report_arc_id` field** in the synthesis output; legacy projects that carry it inherit it harmlessly from prior writes.

`report_tier` and `report_target_words` are mirrored into trend-scout-output.json so `verify-trend-report` can read the prose-word target without re-loading `tips-project.json` — the reviewer uses it for tier-aware Completeness scoring.

`content_hash_at_report`, `value_model_hash_at_report`, and `candidate_signature` are the **drift anchor** consumed by `project-status.sh --health-check`. Compute them immediately **before** writing the metadata block (so the hash reflects pre-mirror content):

```python
import hashlib, json

scout = json.load(open(scout_path))
items = scout.get('tips_candidates', {}).get('items', []) or []
def _key(c): return c.get('id') or c.get('title') or ''
items_sorted = sorted(items, key=_key)
content_hash = 'sha256:' + hashlib.sha256(
    json.dumps(items_sorted, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()
candidate_signature = {
    _key(c): hashlib.sha256(
        json.dumps(c, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    ).hexdigest()[:12]
    for c in items_sorted if _key(c)
}

vm = json.load(open(vm_path))
def _sorted(seq, key):
    return sorted(seq or [], key=lambda x: (x.get(key) or '') if isinstance(x, dict) else '')
vm_payload = {
    'investment_themes': _sorted(vm.get('investment_themes'), 'theme_id'),
    'solutions':         _sorted(vm.get('solutions'),         'solution_id'),
    'blueprints':        _sorted(vm.get('blueprints'),        'solution_id'),
}
value_model_hash = 'sha256:' + hashlib.sha256(
    json.dumps(vm_payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()
```

Hashing rules: always `json.dumps(..., sort_keys=True, separators=(',', ':'), ensure_ascii=False)`; hash only candidate items and the three substantive value-model sections; never timestamps or any field this same step writes back.

#### Step 3.2: Display Summary

```
Trend Synthesis Complete (Canonical TIPS Skeleton)
─────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Macro spine:  4 dimensions (Forces → Impact → Horizons → Foundations)
Theme cases:  {N} investment themes anchored across the 4 dimensions
Length tier:  {REPORT_TIER} (~{REPORT_TARGET_WORDS} prose words target; registry excluded)
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json ({total_claims} claims)

Next step → Run /verify-trend-report to verify claims against sources, run
cross-theme structural review, apply corrections, and pick a downstream path
(executive polish or themed-HTML visualization).

Then /trends-resume shows the full option set (slides, web, storyboard,
catalog, dashboard).
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `.metadata/trend-research-output.json` missing | HALT: Run /trend-research first |
| Manifest hashes don't match current scout/value-model state | WARN with impact line; offer to re-run /trend-research; allow proceed on confirmation |
| `tips-value-model.json` has investment themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| Theme anchoring distribution gives one dimension >3 themes | WARN; composer can still write but report theme-heavy in that dimension |
| Theme anchoring distribution gives one dimension 0 themes | WARN; composer can still write but the dimension section will read visibly thin |
| Theme-case agent returns `ok: false` | Retry once, then HALT with theme name |
| Theme-case quality gate fails (`primer_referenced: false`, missing cost ratio, or empty `story_moment_evidence_ref`) | WARN; continue (case may be thin or the story-moment may have gone abstract — flag for human review) |
| Composer returns `ok: false` | Retry once, then HALT with dimension name |
| Composer dimension narrative <250 words | WARN; macro section may feel thin |
| Composer dimension narrative does not end on a bridge sentence | WARN; voice will land flat into the next dimension |
| All four composer bridges use the same template | WARN; report will read as a checklist — surface to human before publishing |
| Capability Imperative does not contain a callback to the Why-Now hook | WARN; report will land as four parallel essays plus a closer |
| `report-shared-primer.md` missing when theme-case agent dispatches | HALT: Step 2.0b must complete before Step 2.1 |
| `theme-case-{theme_id}.md` missing when composer dispatches for that anchor | HALT: Step 2.1 must complete before Step 2.2 |
| Resume file exists but is corrupt (smaller than threshold) | Re-dispatch the relevant agent |
| Legacy `report_arc_id` present in `tips-project.json` | Log info, ignore; finalization writes the canonical fields |

## Integration

**Upstream:**
- `trend-scout` produces `trend-scout-output.json`
- `value-modeler` produces `tips-value-model.json`
- `trend-research` produces `.metadata/trend-research-output.json` and the per-dimension enriched-trends + claims artefacts

**Pipeline:** `trend-scout → value-modeler → trend-research → trend-synthesis → verify-trend-report`

**Optional cross-plugin:** `cogni-narrative` smarter-service arc — theme-case writer + dimension composer guidance (graceful fallback if absent). The Storytelling Spine in this SKILL.md is self-contained; the cogni-narrative arc-definition is supplementary, not required.

**Downstream (via `/verify-trend-report`):** claim verification (`cogni-claims:claims`), cross-theme structural review, post-verification revision, executive polish (`cogni-copywriting:copywriter`), themed HTML (`cogni-visual:enrich-report`)

**Sibling:** `/trend-booklet` consumes the same research manifest to produce a comprehensive TIPS catalog of all candidates. The two skills are independent; either can run first.

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary (must contain Why-Now hook)
- `phase2-value-model.json` — pruned value-model subset for Phase 2
- `report-theme-anchors.json` — per-theme anchor + secondary poles + distribution
- `report-shared-primer.md` — 4-paragraph macro framing (internal artefact)
- `theme-case-{theme_id}.md` — slim 3-beat investment cases threading the micro-story arc (N files)
- `macro-section-{dimension}.md` — dimension narrative (ending in a bridge) + concatenated theme-cases (4 files)
- `report-synthesis.md` — "Capability Imperative" closing with callback to Why-Now hook
- `report-claims-registry.md` — claims table

Output files in `{PROJECT_PATH}/`:
- `tips-trend-report.md` — assembled final report
- `tips-trend-report-claims.json` — merged claims registry

| Issue | Check |
|-------|-------|
| Theme-case agent hangs | Verify enriched-trends files exist in .logs/ (paths from manifest) |
| Empty claims registry | Check `claims_total` in research manifest |
| Wrong language | Verify `language` in `.metadata/trend-research-output.json` |
| Missing macro sections | Check `.logs/` for partial composer output; resume gates skip files >800 bytes |
| Per-theme-case word counts overshooting | Check whether `LENGTH_BUDGET_FLOOR_WARNING` fired in Phase 1 |
| Report reads as a feature list, not a story | Check `theme-case-*.md` for abstract protagonist ("the CxO") or abstract obstacle ("competition") — the writer skipped the Storytelling Spine micro-story. Re-dispatch the affected theme(s). |
| Report reads as four parallel essays | Check that each `macro-section-*.md` ends on a bridge sentence and that the four bridges use varied templates (Storytelling Spine § Bridges). Check the synthesis for a callback to the executive-summary Why-Now hook. |
| Story-moment cites no evidence_ref | The writer invented a sensory detail. Halt the case, surface for human review — the rest of the case is likely sound but the moment must re-anchor on `EXAMPLE_REFERENCES`. |
