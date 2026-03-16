# Phase 2: Strategic Theme Assembly

Phase 2 assembles the report around strategic themes from `tips-value-model.json`. The dimensional evidence gets enriched in Phase 1 — this phase restructures it into strategic narratives.

The core idea: themes are the skeleton, individual trends are the evidence woven into each theme's story. A CxO reads themes and investment decisions, not a catalog of 60 trends sorted by dimension.

**Architecture:** Theme section writing is delegated to parallel `trend-report-theme-writer` agents (one per theme). Each agent self-loads enriched evidence from disk, writes its theme section, and returns compact JSON. The orchestrator handles the remaining lightweight sections (executive summary, emerging signals, portfolio, claims registry) and final assembly.

---

## Inputs

| Source | Content | Read by |
|--------|---------|---------|
| Strategic Themes | Theme definitions with value chains | Orchestrator (Step 2.1) |
| Value Chains | T→I→P causal paths | Orchestrator (Step 2.1) + theme agents |
| Solution Templates | What to build per theme | Orchestrator (Step 2.1) + theme agents |
| Per-trend evidence | Evidence blocks keyed by candidate_ref | Theme agents (self-load from disk) |
| Claims | Quantitative claims keyed by ID | Theme agents (self-load) + orchestrator (Step 2.6) |
| i18n labels | Section headings in target language | Loaded in Phase 0, passed to agents |

---

## Step 2.1: Read Value Model

Read `.logs/phase2-value-model.json` (pruned subset created in Phase 0 Step 0.2b) and extract:
- `themes[]` — ordered list of strategic themes
- `value_chains[]` — all value chains with candidate_refs
- `solution_templates[]` — solution templates linked to themes (may be empty; only `st_id`, `name`, `category`, `enabler_type`, `theme_ref` fields)
- `coverage` — linked/orphaned/total counts
- `mece_validation` — theme count, ME/CE status
- `orphan_candidates[]` — candidates not in any theme

The `actions_md` field in enriched-trends contains semicolon-separated action keywords (3-5 words each), e.g. `"pilot predictive maintenance; integrate OT/IT data layer; establish vendor shortlist"`. These are compressed intent markers, not full prose — theme agents synthesize complete strategic actions at theme level using these as input.

Do NOT read the enriched-trends or claims JSON files at this step. Theme agents self-load those files, filtered to their own candidate_refs. The orchestrator only reads claims files later in Step 2.6 for the claims registry.

---

## Step 2.2: Dispatch Theme Agents

For each theme (ordered by `theme_id`), dispatch a `trend-report-theme-writer` agent. Dispatch all agents in a single message (parallel tool calls) so they run concurrently.

### Resume Check

Before dispatching an agent for a theme, check if `{PROJECT_PATH}/.logs/report-theme-{theme_id}.md` already exists and is >1000 bytes. If so, skip that agent — display `"{PHASE_2_THEME_AGENT_SKIP_RESUME}"` and continue to the next theme. This means re-runs only dispatch for missing or incomplete themes.

### Agent Prompt Template

```yaml
Per agent:
  subagent_type: "cogni-tips:trend-report-theme-writer"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    THEME_ID: {theme.theme_id}
    THEME_NAME: {theme.name}
    STRATEGIC_QUESTION: {theme.strategic_question}
    EXECUTIVE_SPONSOR_TYPE: {theme.executive_sponsor_type}
    LANGUAGE: {LANGUAGE}
    THEME_INDEX: {1-based index in themes array}
    VALUE_CHAINS: {JSON array of this theme's value chains from value_chains[],
      filtered by theme_ref == theme_id. Include full chain objects:
      chain_id, name, narrative, chain_score, trend, implications,
      possibilities, foundation_requirements — each with candidate_ref and name}
    SOLUTION_TEMPLATES: {JSON array of STs where theme_ref == theme_id.
      Include: st_id, name, category, enabler_type. May be empty []}
    LABELS: {JSON object with relevant i18n labels:
      EXECUTIVE_SPONSOR, INVESTMENT_THESIS, VALUE_CHAINS, TREND,
      IMPLICATION, POSSIBILITY, FOUNDATION, SOLUTION_TEMPLATES,
      SOLUTION, CATEGORY, ENABLER_TYPE, STRATEGIC_ACTIONS,
      WHY_CHANGE, WHY_NOW, WHY_YOU, WHY_PAY}
    NARRATIVE_ARC_PATH: {path to cogni-narrative theme-thesis arc-definition.md, or omit if not available}
    NARRATIVE_TECHNIQUES_PATH: {path to cogni-narrative techniques-overview.md, or omit if not available}
```

### Resolving cogni-narrative Plugin Root

The theme-writer agent optionally loads the `theme-thesis` arc from cogni-narrative for Corporate Visions-guided storytelling. To resolve the arc path:

1. Check if `cogni-narrative` plugin is installed by looking for its arc-definition file at the expected plugin cache path (e.g., `~/.claude/plugins/cache/cogni-works/cogni-narrative/*/skills/narrative/references/story-arc/theme-thesis/arc-definition.md`) or the monorepo path (`{MONOREPO_ROOT}/cogni-narrative/skills/narrative/references/story-arc/theme-thesis/arc-definition.md`)
2. If the file exists, pass its absolute path as `NARRATIVE_ARC_PATH` and the techniques file as `NARRATIVE_TECHNIQUES_PATH`
3. If cogni-narrative is not installed, **omit both parameters** — the agent falls back to the flat template structure (backward-compatible)

Display `"{PHASE_2_THEME_AGENT_DISPATCH}"` after dispatching.

---

## Step 2.3: Write Executive Summary + Emerging Signals

While theme agents run, the orchestrator writes the sections that don't depend on agent output.

### Executive Summary

The executive summary leads with the strategic themes table — this is the first thing the reader sees after the title. It answers "what are our strategic bets?" before anything else.

Write `{PROJECT_PATH}/.logs/report-header.md` containing:

#### Frontmatter

```yaml
---
title: "{REPORT_TITLE}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
generated_by: trend-report
source_skills:
  - trend-scout
  - value-modeler
report_mode: strategic-themes
total_trends: 60
total_themes: {N}
total_claims: {N}
generated_at: "{ISO-8601}"
---
```

Note `report_mode: strategic-themes` and `source_skills` includes `value-modeler`.

#### Executive Summary Content

The executive summary applies the Corporate Visions arc at the report level: unconsidered need → urgency → evidence → cost of inaction. A CxO reading only this section should feel "I must act" — not just "here are some themes."

```markdown
# {REPORT_TITLE}

## {EXEC_SUMMARY_LABEL}

{UNCONSIDERED NEED OPENER: 2-3 sentences reframing the industry's conventional
strategic assumption. NOT neutral landscape framing ("Die Branche steht vor...").
Instead, challenge the reader's mental model:

Pattern: "The prevailing assumption in [industry] is [X]. But [N] converging
forces reveal an unconsidered need: [provocative reframe]."

Source: Synthesize from the theme strategic questions — what do they collectively
reveal that a typical CxO briefing would miss? The opener should make the reader
feel their current mental model is incomplete. Use a surprising data point from
the value model or enriched evidence to anchor the reframe.}

### {STRATEGIC_THEMES_OVERVIEW_LABEL}

| # | {THEME_LABEL} | {STRATEGIC_QUESTION_LABEL} | {EXECUTIVE_SPONSOR_LABEL} |
|---|---------------|---------------------------|---------------------------|
| 1 | {theme.name} | {theme.strategic_question} | {theme.executive_sponsor_type} |
| 2 | ... | ... | ... |

{URGENCY BRIDGE: How these themes create COMPOUND urgency — not neutral "dependencies"
language, but forcing-function convergence across themes.

Pattern: "Any one of these themes justifies action. Together, they create a [N]-month
window where [specific convergence point]."

Reference the strongest forcing functions from the Why Now elements across themes.
Include at least one specific date or regulatory deadline. Name which themes require
immediate action (ACT-horizon) vs. strategic preparation (PLAN-horizon).}

### {HEADLINE_EVIDENCE_LABEL}

{Pick 3-5 of the most impactful quantitative claims across all themes. Each should
support a different theme. Format as a tight bulleted list with inline citations.

SOURCE: Use `top_claims` from theme agent return payloads. Each agent returns its
2-3 most impactful claims. Select the best across all agents, ensuring coverage
of different themes. If agents haven't completed yet, write this section after
Step 2.4 (collect results).}

### {COST_OF_INACTION_LABEL}

{COST-OF-INACTION PUNCH LINE: Replace the neutral horizon assessment with a
compelling business case synthesis across all themes.

Source: Use `why_pay_ratio` and `why_pay_closing_statement` from theme agent returns.
Synthesize the compound cost of inaction across themes.

Pattern: "Organizations that act across [N] themes by [date] position for [advantage].
Organizations that delay face [aggregate compound cost across themes]."

If 3 themes each show 3x cost-of-inaction ratios, the report-level message is
multiplicative — "Across five themes, delay compounds from [X] to [Y]."

Close with a single undeniable sentence: the report-level defining choice.
Example: "Proaktive Investition über fünf Themen: €X Millionen. Kosten der
Untätigkeit: €Y Millionen über drei Jahre. Die Entscheidung liegt vor Ihnen."}
```

Must end with two trailing newlines.

**Timing notes:**
- The unconsidered-need opener, themes table, and urgency bridge can be written from the value model alone (before agents complete).
- The headline evidence section needs `top_claims` from agent returns.
- The cost-of-inaction section needs `why_pay_ratio` and `why_pay_closing_statement` from agent returns.
- If writing the header before agents complete, leave placeholders for headline evidence AND cost-of-inaction, then fill both after Step 2.4 (collect results).

### Emerging Signals

Orphan candidates (trends not in any theme's value chains) still have enriched evidence. Present them as emerging signals worth monitoring — they didn't fit a current theme, which itself is interesting context.

For orphan candidates, the orchestrator reads the enriched-trends files selectively — only the dimensions that contain orphan candidate_refs. This is a lightweight read compared to the old Phase 2 approach where ALL enriched-trends were loaded for theme assembly.

Write `{PROJECT_PATH}/.logs/report-emerging-signals.md`:

```markdown
## {EMERGING_SIGNALS_LABEL}

{EMERGING_SIGNALS_INTRO}

{For each orphan candidate, grouped by dimension:}

### {candidate.name} ({TIPS_ROLE})

{Pull evidence_md from enriched-trends lookup. Write a condensed 2-3 sentence summary.
Note the horizon — observe-horizon orphans are expected; act-horizon orphans may
signal gaps in the theme model.}

---
```

If there are no orphans (100% coverage), write:

```markdown
## {EMERGING_SIGNALS_LABEL}

{ALL_CANDIDATES_THEMED}
```

Must end with two trailing newlines.

---

## Step 2.4: Collect Agent Results

Wait for all theme agents to complete. Each agent returns compact JSON:

```json
{
  "ok": true,
  "theme_id": "theme-001",
  "theme_name": "Theme Name",
  "theme_thesis_heading": "Bewiesene 10:1-Investitionsthese — und 78% der Branche ignoriert sie",
  "element_headings": {
    "why_change": "Netzmodernisierung ist keine Hardware-Frage — es ist eine Datenplattform-Transition",
    "why_now": "Drei Regulierungsfristen konvergieren bis August 2026",
    "why_you": "Digital-Twin-Netzbetrieb schafft 23% Kostenvorsprung",
    "why_pay": "Verzögern kostet 3x mehr als Handeln — €6,9M vs. €2,3M"
  },
  "heading_fallback": false,
  "why_pay_ratio": "3x",
  "why_pay_closing_statement": "Verzögern kostet 3x mehr als Handeln — €6,9M vs. €2,3M über drei Jahre",
  "word_count": 420,
  "citations_count": 5,
  "quality_gate_pass": true,
  "candidates_covered": ["externe-effekte/act/1", ...],
  "top_claims": [
    {"claim_id": "claim_ee_001", "short_text": "...", "value": "...", "unit": "USD", "source_url": "..."}
  ],
  "actions_count": 4,
  "chains_written": 3,
  "theme_file": ".logs/report-theme-theme-001.md"
}
```

### Validation

For each agent result:
1. Check `ok == true`. If `false`: retry once. If retry also fails, HALT with theme name.
2. Check `quality_gate_pass == true`. If `false`: log WARNING but continue — the theme section is written but may be thin.
3. Display `"{PHASE_2_THEME_AGENT_COMPLETE}"` for each successful agent.

All dispatched agents must succeed before proceeding. Agents that were skipped via resume check don't need validation.

### Backfill Headline Evidence + Cost of Inaction

If the executive summary header was written before agents completed (with placeholders), now read `report-header.md` and fill in:

1. **`{HEADLINE_EVIDENCE_LABEL}` section:** Use `top_claims` from across all agent returns. Pick 3-5 claims that each support a different theme.

2. **`{COST_OF_INACTION_LABEL}` section:** Use `why_pay_ratio` and `why_pay_closing_statement` from each agent's return JSON. Synthesize the compound cost of inaction across all themes into a punchy closing section. If multiple themes show 2-3x cost-of-inaction ratios, the aggregate message is multiplicative.

---

## Step 2.5: Generate Strategic Portfolio View

Replace the flat dimensional portfolio analysis with theme-level metrics.

Write `{PROJECT_PATH}/.logs/report-portfolio.md`:

```markdown
## {PORTFOLIO_ANALYSIS_LABEL}

### {THEME_OVERVIEW_LABEL}

| # | {THEME_LABEL} | {CHAINS_LABEL} | {CANDIDATES_LABEL} | {HORIZON_MIX_LABEL} | {EVIDENCE_LABEL} |
|---|---------------|----------------|--------------------|--------------------|-------------------|
| 1 | {theme.name} | {chain_count} | {candidate_count} | {act/plan/observe} | {claims_count} claims |
| 2 | ... | ... | ... | ... | ... |
| | **{TOTAL_LABEL}** | **{N}** | **{N}/{total}** | | **{N}** claims |

### {HORIZON_DISTRIBUTION_LABEL}

| {THEME_LABEL} | ACT | PLAN | OBSERVE |
|---------------|-----|------|---------|
| {theme.name} | {count} | {count} | {count} |
| ... | ... | ... | ... |
| {ORPHANS_LABEL} | {count} | {count} | {count} |

### {MECE_VALIDATION_LABEL}

| {METRIC_LABEL} | {VALUE_LABEL} | {STATUS_LABEL} |
|-----------------|---------------|----------------|
| {THEME_COUNT_LABEL} | {N} | {pass/warn} |
| {MUTUAL_EXCLUSIVITY_LABEL} | {pass/fail} | {from mece_validation} |
| {COLLECTIVE_EXHAUSTIVENESS_LABEL} | {pct}% | {pass if >=80%} |
| {BALANCE_LABEL} | {pass/fail} | {from mece_validation} |

### {EVIDENCE_COVERAGE_LABEL}

| {THEME_LABEL} | {WITH_EVIDENCE_LABEL} | {QUALITATIVE_ONLY_LABEL} | {COVERAGE_PCT_LABEL} |
|---------------|-----------------------|--------------------------|----------------------|
| {theme.name} | {count} | {count} | {pct}% |
| ... | ... | ... | ... |
```

Must end with two trailing newlines.

### Counting Logic

Use a combination of value model data and agent return payloads:

- **Chain count per theme:** Count value chains with matching `theme_ref` in value model
- **Candidates per theme:** Use `candidates_covered` from agent returns (already deduplicated). For resumed themes (no agent return), count unique candidate_refs from the value model's value chains.
- **Horizon mix:** Extract horizon from each candidate_ref format (`{dimension}/{horizon}/{seq}`). For more precise counts, read the enriched-trends files — but the candidate_ref format provides the horizon directly.
- **Claims per theme:** For agents that ran, count from `top_claims`. For precise counts, read claims files in Step 2.6 and count by theme mapping.
- **Evidence coverage per theme:** Requires reading enriched-trends to check `has_quantitative_evidence`. If this creates too much context pressure, use agent word_count and citations_count as proxies.

---

## Step 2.6: Generate Claims Registry

Claims registry includes a `theme` column. This is the one step where the orchestrator reads the claims JSON files directly.

Read all 4 `claims-{dimension}.json` files. Build a `claim_id → claim` lookup.

To determine which theme a claim belongs to: use the value model's value chains to build a `candidate_ref → theme_name` mapping. Then for each claim, find which candidate's `claims_refs` contains it (from the enriched-trends data — or use the agent-returned `candidates_covered` lists as a shortcut). Claims from orphan candidates get "—" in the theme column.

Write `{PROJECT_PATH}/.logs/report-claims-registry.md`:

```markdown
## {CLAIMS_REGISTRY_LABEL}

{CLAIMS_REGISTRY_INTRO}

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {THEME_LABEL} |
|---|---------------|---------------|-----------------|---------------|
| 1 | {claim text} | {value + unit} | [{title}](url) | {theme name or "—"} |
```

Must end with two trailing newlines.

---

## Step 2.7: Assemble Final Report

Verify all files exist, then concatenate in this order:

```bash
# Build file list for theme mode
FILES="{PROJECT_PATH}/.logs/report-header.md"

# Theme sections in order
for theme_id in theme-001 theme-002 ... theme-N; do
  FILES="$FILES {PROJECT_PATH}/.logs/report-theme-${theme_id}.md"
done

# Remaining sections
FILES="$FILES {PROJECT_PATH}/.logs/report-emerging-signals.md"
FILES="$FILES {PROJECT_PATH}/.logs/report-portfolio.md"
FILES="$FILES {PROJECT_PATH}/.logs/report-claims-registry.md"

cat $FILES > "{PROJECT_PATH}/tips-trend-report.md"
```

### Verification

Read first 3 + last 3 lines of the assembled report:
- First lines should start with `---` (YAML frontmatter)
- Last lines should contain the claims total
- Report should contain exactly N theme H2 headers matching `## {N}. {theme.name}`

---

## Step 2.8: Merge Claims

Merge all 4 dimension claims into `tips-trend-report-claims.json`. The claims themselves don't change; only the report structure around them does.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `tips-value-model.json` has themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| Theme agent returns `ok: false` | Retry once, then HALT with theme name |
| Theme agent quality gate fails | WARNING: continue (section written but may be thin) |
| enriched-trends JSON missing (agent reports) | HALT: Phase 1 agent failed to produce enriched output |
| Theme references candidate_ref not found in enriched data | Agent logs warning, skips that candidate |
| Solution templates empty | Agents omit "Solution Templates" subsection |
| MECE validation failed in value model | Include as-is with warning in portfolio view |
| Resume file exists but is corrupt (<1000 bytes) | Re-dispatch agent for that theme |
