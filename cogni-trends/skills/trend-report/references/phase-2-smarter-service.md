# Phase 2: Smarter-Service Macro-Skeleton Assembly

> **When to read this file:** when `REPORT_ARC_ID == "smarter-service"`. When the user picked any other arc, read [phase-2-strategic-themes.md](phase-2-strategic-themes.md) instead. The two flows do not mix — this one rewrites the H2 layout; the legacy flow keeps themes as H2.

Phase 2 in smarter-service mode produces a report whose H2 spine is the four Smarter Service dimensions (Forces / Impact / Horizons / Foundations), each opening with a 250–400 word dimension narrative composed from cross-theme evidence, followed by 1–3 anchored theme-cases as H3 (slim 3-beat: Stake / Move / Cost-of-Inaction). The architecture is described in [report-arc-frames.md § 8](report-arc-frames.md).

**Three structural fixes vs. legacy:**

1. **A shared dimension primer (Step 2.0)** — written once by the orchestrator before any theme-case dispatch — gives theme writers the macro framing they must reference instead of re-establishing.
2. **Slim 3-beat theme-cases (Step 2.1)** — `trend-report-investment-theme-writer` runs in `MICRO_ARC=investment-case` mode, producing Stake / Move / Cost-of-Inaction. Themes do not own macro framing.
3. **Sequential dimension composer (Step 2.2)** — `trend-report-composer` is invoked four times, once per macro section, with manageable context (one dimension's evidence). The composer integrates dimension narrative + nested theme-cases into a single voice per macro section.

---

## Inputs

| Source | Content | Read by |
|--------|---------|---------|
| Investment Themes | Theme definitions with value chains | Orchestrator (Step 2.0a anchoring), Composer (Step 2.2) |
| Value Chains | T→I→P causal paths | Orchestrator + theme-case agents + composer |
| Solution Templates | What to build per theme | Theme-case agents (Move beat) |
| Per-trend evidence (4 enriched-trends-{dimension}.json) | Evidence blocks keyed by candidate_ref | Theme-case agents (self-load) + composer (self-load for own dimension) |
| Claims | Quantitative claims keyed by ID | Theme-case agents + orchestrator (Step 2.4 claims registry) |
| `report-shared-primer.md` | 4-paragraph macro framing — written by orchestrator at 2.0b | Theme-case agents + composer |
| i18n labels | Section headings in target language | Loaded in Phase 0, passed to agents |

---

## Step 2.0a: Compute Theme Anchoring

For each investment theme in `tips-value-model.json → investment_themes[]`:

1. **Build `candidate_count_per_pole`**: walk the theme's value chains, count distinct `candidate_ref` per dimension (`externe-effekte`, `digitale-wertetreiber`, `neue-horizonte`, `digitales-fundament`).
2. **Anchor pole** = the dimension with the highest count.
3. **Tiebreaker** = highest single-candidate composite score across this theme's `candidate_ref` entries (read from `trend-candidates.md` or trend entity files for `composite_score`). If still tied, fall back to TIPS letter order (T > I > P > S — Forces wins ties).
4. **Secondary poles** = dimensions where the theme has at least 1 `candidate_ref` but did not win the anchor.

Persist the result to `{PROJECT_PATH}/.logs/report-theme-anchors.json`:

```json
{
  "anchors": [
    {
      "theme_id": "it-001",
      "theme_name": "Intelligent Grid & Asset Optimization",
      "anchor_dimension": "neue-horizonte",
      "anchor_pole": "P",
      "candidate_counts": { "externe-effekte": 1, "digitale-wertetreiber": 2, "neue-horizonte": 4, "digitales-fundament": 2 },
      "secondary_poles": ["digitale-wertetreiber", "digitales-fundament", "externe-effekte"],
      "rationale": "Highest candidate count in neue-horizonte (4)"
    },
    ...
  ],
  "anchor_distribution": {
    "externe-effekte": 1,
    "digitale-wertetreiber": 2,
    "neue-horizonte": 1,
    "digitales-fundament": 1
  }
}
```

**Quality check:** if any single dimension would carry more than 3 themes, log a WARNING — the report will be unbalanced. The composer can still write it, but consider re-running value-modeler to redistribute.

**Resume:** if `report-theme-anchors.json` already exists and has an `anchors[]` entry for every theme in the value model, skip Step 2.0a.

---

## Step 2.0b: Write the Shared Dimension Primer

Display `"{PHASE_2_PRIMER_START}"`.

The orchestrator writes a single short document — `{PROJECT_PATH}/.logs/report-shared-primer.md` — that establishes the cross-theme macro narrative for each of the four Smarter Service dimensions. The primer is the **single source of truth** for macro framing; both theme-case agents and the dimension composer reference it.

**Process:**

1. Read all four `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` from Phase 1.
2. Read the value model + theme anchors from Step 2.0a.
3. Read `report-arc-frames.md § 8` for the smarter-service exec opener and macro bridge patterns.
4. Write `report-shared-primer.md` in a single pass, four sections:

```markdown
# Shared Dimension Primer (smarter-service)

> Internal artefact — referenced by theme-case agents and the dimension composer.
> Theme-case agents MUST quote this primer's framing once in their Stake beat
> (one sentence) and pivot to theme-specific content. They MUST NOT re-establish
> the macro narrative.

## Forces (Externe Effekte) — Macro Framing

[~120 words. Lead with the highest-confidence Act-horizon force across the
landscape. Cluster forces by subcategory (economy / regulation / society).
End with the anchor pivot: which themes are anchored here.]

## Impact (Digitale Wertetreiber) — Macro Framing

[~120 words. Open with explicit Forces→Impact bridge. Cluster disruptions by
CX / products / processes. End with the anchor pivot.]

## Horizons (Neue Horizonte) — Macro Framing

[~120 words. Open with explicit Impact→Horizons bridge. Cluster opportunities
by strategy / leadership / governance. End with the anchor pivot.]

## Foundations (Digitales Fundament) — Macro Framing

[~120 words. Open with explicit Horizons→Foundations bridge. Sequence
dependencies (culture → workforce → technology). End with the anchor pivot.]
```

**Total target:** ~480 words. Each paragraph ≤140 words. Use the same i18n labels as the final report (Forces / Impact / Horizons / Foundations).

**Quality gates for the primer:**

- [ ] Each dimension paragraph cites at least 1 specific quantitative evidence point with citation
- [ ] Each anchor pivot sentence names the themes anchored to that dimension explicitly
- [ ] Forces→Impact, Impact→Horizons, Horizons→Foundations bridges are present
- [ ] Each paragraph ends with the anchor pivot — no free-floating closing paragraph

Display `"{PHASE_2_PRIMER_WRITTEN}"`.

**Resume:** if `report-shared-primer.md` exists and is >800 bytes, skip Step 2.0b.

---

## Step 2.1: Dispatch Theme-Case Writers (slim mode, parallel)

For each investment theme, dispatch a `trend-report-investment-theme-writer` agent with `MICRO_ARC = "investment-case"`. Dispatch all agents in a single message (parallel tool calls).

### Resume Check

Before dispatching for a theme, check if `{PROJECT_PATH}/.logs/report-theme-case-{theme_id}.md` exists and is >600 bytes. If so, skip — display `"{PHASE_2_THEME_CASE_AGENT_SKIP_RESUME}"`.

> Note the file naming differs from the legacy flow: smarter-service uses `report-theme-case-{theme_id}.md` (slim 3-beat output) instead of `report-investment-theme-{theme_id}.md` (full Why-* output). Resume across modes is intentionally not supported — switching `REPORT_ARC_ID` requires regenerating Phase 2.

### Agent Prompt Template

```yaml
Per agent:
  subagent_type: "cogni-trends:trend-report-investment-theme-writer"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    MICRO_ARC: "investment-case"
    INVESTMENT_THEME_ID: {theme.investment_theme_id}
    INVESTMENT_THEME_NAME: {theme.name}
    STRATEGIC_QUESTION: {theme.strategic_question}
    EXECUTIVE_SPONSOR_TYPE: {theme.executive_sponsor_type}
    LANGUAGE: {LANGUAGE}
    ANCHOR_DIMENSION: {theme.anchor_dimension from report-theme-anchors.json}
    SECONDARY_POLES: {JSON array of secondary poles from anchors file}
    SHARED_PRIMER_PATH: "{PROJECT_PATH}/.logs/report-shared-primer.md"
    SHARED_PRIMER_DIGEST: {200-char summary of the primer paragraph for ANCHOR_DIMENSION}
    INVESTMENT_THEME_INDEX: {1-based index in investment_themes array}
    VALUE_CHAINS: {JSON array of this theme's value chains — same shape as legacy flow}
    SOLUTION_TEMPLATES: {JSON array of STs where investment_theme_ref == investment_theme_id}
    PORTFOLIO_PROVIDER: {Display name from portfolio-context.json, empty string if absent}
    MARKET_REGION: {MARKET_REGION from config, default "dach"}
    PORTFOLIO_PRODUCTS: {JSON array — same shape as legacy flow}
    SOLUTION_PRICING: {JSON array — same shape as legacy flow}
    STUDY_MODE: {"vendor" | "open"}
    EXAMPLE_REFERENCES: {JSON object keyed by st_id — same shape as legacy flow}
    THEME_CASE_TARGET_WORDS: {Integer per-theme-case target computed by Phase 0.4e.
      Default split: Stake 25% / Move 50% / Cost-of-Inaction 25%.
      Per-element minimums: Stake 80, Move 130, Cost-of-Inaction 80 (sum 290).
      Tolerance ±15% for the total case section.}
    LABELS: {JSON object with relevant i18n labels:
      EXECUTIVE_SPONSOR, STRATEGIC_QUESTION_LABEL,
      STAKE, MOVE, COST_OF_INACTION (these may be silent — see beat rules below),
      THEME_CASE_REFERENCE_PATTERN (de: "→ Siehe auch Handlungsfeld {N} unter {Macro Section}",
        en: "→ See also Theme {N} in {Macro Section}")}
    NARRATIVE_ARC_PATH: {path to cogni-narrative smarter-service arc-definition.md}
    NARRATIVE_TECHNIQUES_PATH: {path to cogni-narrative techniques-overview.md}
```

### Beat Rules (the slim 3-beat micro-arc)

The agent produces output with exactly 3 beats. Beat headers are **silent** — they do not appear as visible markdown headings; they're rhetorical structure only. The output looks like:

```markdown
### {INVESTMENT_THEME_INDEX}.{theme_index_within_section}: {theme.name}

> {theme.strategic_question} | {EXECUTIVE_SPONSOR}: {executive_sponsor_type}

[Stake beat — 1 sentence quoting primer, then theme-specific framing,
then theme-specific quantification + forcing function. ~120 words at extended tier, floor 80.]

[Move beat — flowing prose covering Solution Templates (IS), P-candidates (DOES),
S-candidates (MEANS). No labels visible. ~250 words at extended tier, floor 130.]

[Cost-of-Inaction beat — 3-year cost ratio with specific window.
Closes with a specific ratio anchored to a date or event. ~120 words at extended tier, floor 80.]

{Optional secondary-pole callouts at the end of the case, 1 line each:}
> {THEME_CASE_REFERENCE_PATTERN with theme number and macro section name}
```

**Anti-restate rules (enforced by quality gate):**

- The Stake beat must reference the primer's framing for `ANCHOR_DIMENSION` exactly **once** (one sentence). Subsequent paragraphs in Stake must be theme-specific.
- The Move beat must NOT restate the macro disruption / opportunity framing — those live in the dimension narrative (composed in Step 2.2). The Move beat opens with the bet, not the context.
- The Cost-of-Inaction beat must close with a specific ratio (e.g., "3.4x") tied to a specific window (date or event). Generic phrases ("inaction is costly", "delaying compounds risk") fail the gate.

### Agent Return Schema

```json
{
  "ok": true,
  "investment_theme_id": "it-001",
  "investment_theme_name": "Intelligent Grid & Asset Optimization",
  "anchor_dimension": "neue-horizonte",
  "stake_word_count": 118,
  "move_word_count": 248,
  "cost_word_count": 122,
  "total_word_count": 488,
  "cost_ratio": "3.4x",
  "cost_window": "EU AI Act enforcement deadline (August 2026)",
  "primer_referenced": true,
  "secondary_pole_callouts": ["digitale-wertetreiber", "digitales-fundament"],
  "citations_count": 6,
  "quality_gate_pass": true,
  "candidates_covered": ["neue-horizonte/act/2", "digitale-wertetreiber/act/3", ...],
  "top_claims": [
    {"claim_id": "claim_nh_002", "short_text": "...", "value": "...", "unit": "USD", "source_url": "..."}
  ],
  "theme_case_file": ".logs/report-theme-case-it-001.md"
}
```

### Validation

- `ok == true` — retry once on failure; HALT if retry also fails.
- `primer_referenced == true` — quality gate: WARN if false (theme didn't reference primer).
- `cost_ratio` non-empty AND `cost_window` non-empty — quality gate: WARN if missing.
- `quality_gate_pass == true` — WARN if false but continue.

Display `"{PHASE_2_THEME_CASE_AGENT_DISPATCH}"` after dispatching, `"{PHASE_2_THEME_CASE_AGENT_COMPLETE}"` per success.

---

## Step 2.2: Dispatch Dimension Composer Agents (sequential, 4 calls)

Once all theme-case agents complete (or were skipped via resume), dispatch the `trend-report-composer` agent **sequentially** — once per macro dimension, in TIPS order: T → I → P → S (`externe-effekte` first, `digitales-fundament` last).

> **Why sequential:** the composer carries the arc voice through the report. Running them in parallel produces voice drift between macro sections. The composer is dimension-scoped, so each call sees only its own evidence — context stays manageable even at maximum tier.

### Resume Check (per dimension)

Before dispatching for a dimension, check if `{PROJECT_PATH}/.logs/report-macro-section-{dimension}.md` exists and is >800 bytes. If so, skip — display `"{PHASE_2_COMPOSER_SKIP_RESUME}"`.

### Agent Prompt Template

```yaml
Per dimension (4 sequential calls):
  subagent_type: "cogni-trends:trend-report-composer"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    DIMENSION: {dimension_slug — externe-effekte | digitale-wertetreiber | neue-horizonte | digitales-fundament}
    DIMENSION_INDEX: {1 | 2 | 3 | 4 — TIPS order}
    DIMENSION_NAME_EN: {English dimension name from labels}
    DIMENSION_NAME_LOCAL: {language-localized dimension name}
    MACRO_HEADING_LABEL: {label for this macro element from report-arc-frames.md § 8 — e.g., "Forces — Externe Effekte"}
    LANGUAGE: {LANGUAGE}
    SHARED_PRIMER_PATH: "{PROJECT_PATH}/.logs/report-shared-primer.md"
    THEME_CASE_PATHS: {JSON array of report-theme-case-{theme_id}.md paths for themes anchored to this dimension, ordered by composite-score of anchor pole (highest first). May be empty.}
    SECONDARY_CALLOUTS: {JSON array of one-line callouts to render at end of dimension narrative for themes anchored elsewhere but with secondary pole here. Format: "→ See also Theme {N} in {Macro Section}"}
    DIMENSION_NARRATIVE_TARGET_WORDS: {Integer from Phase 0.4e — typically 250 at standard tier, 400 at maximum tier. Floor 250.}
    LABELS: {JSON object with relevant i18n labels for headings, transitions, and section markers}
    NARRATIVE_ARC_PATH: {path to cogni-narrative smarter-service arc-definition.md}
    DIMENSION_PATTERN_PATH: {path to {dimension}-patterns.md inside smarter-service arc directory}
```

### Composer Output

The composer writes `{PROJECT_PATH}/.logs/report-macro-section-{dimension}.md`:

```markdown
## {DIMENSION_INDEX}. {MACRO_HEADING_LABEL}

[Dimension narrative — opens with explicit cross-element bridge sentence
(except DIMENSION_INDEX=1 which opens by quoting/extending the primer).
Cascades by horizon (Act → Plan → Observe). Synthesizes — no trend listing.
Closes with anchor pivot sentence naming the themes anchored here.
~250–400 words depending on tier.]

[Concatenate the theme-case files in order, with one blank line between.
The composer does NOT rewrite theme cases — theme-case agents own their content.
The composer's job is ONLY the dimension narrative + section headers + final callouts.]

{Optional: secondary callout block at end of section}
```

The composer's only writing is the dimension narrative + the H2 heading + secondary callouts. It must NOT modify theme-case content (read-only consumption). It does this in two passes internally:

1. Read all inputs (primer, theme-case files for this dimension, dimension pattern file, enriched-trends for this dimension only).
2. Compose the dimension narrative (≥250 words floor) using the dimension's element-pattern guidance.
3. Concatenate: H2 heading + dimension narrative + theme-case files + secondary callout block.
4. Return JSON metadata.

### Composer Return Schema

```json
{
  "ok": true,
  "dimension": "externe-effekte",
  "dimension_index": 1,
  "dimension_narrative_word_count": 312,
  "theme_cases_concatenated": ["report-theme-case-it-001.md", "report-theme-case-it-003.md"],
  "secondary_callout_count": 2,
  "horizon_cascade_present": true,
  "anchor_pivot_sentence_present": true,
  "primer_referenced": true,
  "macro_section_file": ".logs/report-macro-section-externe-effekte.md"
}
```

### Validation

- `ok == true` — retry once on failure; HALT on second failure.
- `dimension_narrative_word_count >= 250` — quality gate.
- `horizon_cascade_present == true` — WARN if false.
- `anchor_pivot_sentence_present == true` — quality gate: WARN if false (means composer didn't introduce anchored themes).

Display `"{PHASE_2_COMPOSER_DISPATCH}"`, `"{PHASE_2_COMPOSER_COMPLETE}"` per dimension.

---

## Step 2.3: Write Executive Summary

After all 4 macro sections are composed, write the executive summary in a single pass.

### Process

1. Read the primer (`report-shared-primer.md`) — it contains the macro framings.
2. Read all 4 macro section files — pull the strongest evidence and theme anchor pivots.
3. Read `report-arc-frames.md § 8` for the smarter-service exec opener / closer patterns.
4. Write `{PROJECT_PATH}/.logs/report-header.md`.

### Frontmatter

```yaml
---
title: "{TITLE}"
subtitle: "{SUBTITLE}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
arc_id: smarter-service
generated_by: trend-report
source_skills:
  - trend-scout
  - value-modeler
report_mode: smarter-service-themed
total_trends: {N}
total_investment_themes: {N}
total_macro_sections: 4
total_claims: {N}
themes:
  - theme_id: it-001
    name: "..."
    anchor_dimension: "neue-horizonte"
  - ...
generated_at: "{ISO-8601}"
---
```

### Executive Summary Content

Smarter-service exec summary structure:

```markdown
# {TITLE}

*{SUBTITLE}*

## {EXEC_SUMMARY_LABEL}

{ARC OPENER — 2-3 sentences. Cross-dimensional panorama opener from
report-arc-frames.md § 8: Pattern: "[N] converging forces across [industry]
reshape [external pressure] and [value-chain shift], opening [strategic window]
— but only for organizations that build [foundation requirement]. Across [N]
investment themes, the report names where to bet and what to build first."}

{BRIDGE SENTENCE: One sentence that frames the structure of what follows.
Pattern: "Vier Smarter-Service-Dimensionen tragen [N] Handlungsfelder — von
Externe Effekte bis Digitales Fundament:" or "Four Smarter Service dimensions
carry [N] investment themes — from Forces to Foundations:"}

1. **{Forces / Externe Effekte}**: {one-sentence summary of macro Forces story —
   pulled from report-macro-section-externe-effekte.md dimension narrative}.
   Anchored: {comma-separated theme names whose anchor_dimension == "externe-effekte"}.
2. **{Impact / Digitale Wertetreiber}**: {one-sentence summary}.
   Anchored: {theme names}.
3. **{Horizons / Neue Horizonte}**: {one-sentence summary}.
   Anchored: {theme names}.
4. **{Foundations / Digitales Fundament}**: {one-sentence summary}.
   Anchored: {theme names}.

{ARC CLOSER — 2-3 sentences. Pattern from report-arc-frames.md § 8:
"Identifying the right trends is necessary but insufficient. These [N] investment
themes share [M] foundation requirements. Without these foundations, opportunities
remain theoretical. The trend panorama shows what's changing; the investment
themes show where to bet; the capability imperative shows what to build first."}
```

**Rules:**

- The numbered list is over **dimensions**, not themes (4 entries always, regardless of N themes).
- Each dimension entry names the anchored themes; theme names are NOT bolded a second time at the dimension level.
- NO `###` subsections inside the exec summary.
- NO standalone evidence section — all numbers are woven into opener / closer / dimension entries.
- Length: target `EXEC_TARGET_WORDS` ±20% (computed in Phase 0.4e — typically 200 at standard tier, 280 at maximum).

Must end with two trailing newlines.

---

## Step 2.4: Generate Claims Registry

Same as legacy flow, with one column relabeled. Claims registry includes a `dimension` column (instead of `investment_theme`):

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {DIMENSION_LABEL} | {INVESTMENT_THEME_LABEL} |

For each claim:
1. Read all 4 `claims-{dimension}.json` files. Build a `claim_id → claim` lookup with the dimension recorded.
2. Determine the investment theme by walking the value model: find which candidate's `claims_refs` contains the claim, then the theme that contains that candidate.
3. Render: dimension column = "Forces" / "Impact" / "Horizons" / "Foundations" (i18n localized); theme column = theme name or "—".

Write `{PROJECT_PATH}/.logs/report-claims-registry.md`. Same trailing newline rule.

---

## Step 2.5: Write Synthesis Section ("The Capability Imperative")

Display `"{PHASE_2_SYNTHESIS_START}"`.

The synthesis section in smarter-service mode is **Foundations-anchored** — it aggregates capability requirements across themes. See [report-arc-frames.md § 8 → Synthesis Frame](report-arc-frames.md) and the Foundations element pattern in cogni-narrative (`smarter-service/foundations-patterns.md`).

**Process:**

1. Read all 4 macro section files (already in context from Step 2.3) and the agent-returned metadata (cost_ratio, cost_window, top_claims, etc.).
2. Look up the synthesis heading: `SYNTHESIS_HEADING_SMARTER_SERVICE` (i18n: "The Capability Imperative" / "Der Fähigkeitsimperativ").
3. Write the synthesis section.

**Synthesis structure** (target `SYNTHESIS_TARGET_WORDS` ±15%, typically 320 at standard tier, 640 at maximum):

```markdown
## {SYNTHESIS_HEADING_SMARTER_SERVICE}

{Opening: 2 sentences. Pattern: "Identifying trends is necessary but insufficient.
These [N] investment themes share [M] foundation requirements. Without them,
opportunities remain theoretical."}

{Body: ~60% of SYNTHESIS_TARGET_WORDS}

- Aggregate the strongest capability evidence across all themes (culture / workforce / technology)
- Identify *shared* foundations that unlock multiple themes ("invest once, unlock many")
- Sequence the build order: culture → workforce → technology → outcome
- Combined cost-of-inaction across all themes (sum of individual ratios where they share denominators); combined proactive investment

### {UNIFIED_CAPABILITY_ROADMAP_LABEL}

1. **{Calendar timeframe — e.g., "Q3 2026"}**: {Cross-theme action; names which themes it enables}
2. **{Calendar timeframe}**: {Cross-theme action}
3. **{Calendar timeframe}**: {Cross-theme action}
4. **{Calendar timeframe}**: {Cross-theme action}

{Closing: 1-2 sentences. Pattern: "The trend panorama shows what's changing;
the investment themes show where to bet; the capability imperative shows what
to build first."}
```

Write to `{PROJECT_PATH}/.logs/report-synthesis.md`. Display `"{PHASE_2_SYNTHESIS_WRITTEN}"`.

Must end with two trailing newlines.

---

## Step 2.6: Assemble Final Report

Verify all files exist, then concatenate in this order:

```bash
FILES="{PROJECT_PATH}/.logs/report-header.md"

# 4 macro sections in TIPS order
for DIM in externe-effekte digitale-wertetreiber neue-horizonte digitales-fundament; do
  FILES="$FILES {PROJECT_PATH}/.logs/report-macro-section-${DIM}.md"
done

# Synthesis section (Foundations-anchored close)
FILES="$FILES {PROJECT_PATH}/.logs/report-synthesis.md"

# Claims registry
FILES="$FILES {PROJECT_PATH}/.logs/report-claims-registry.md"

cat $FILES > "{PROJECT_PATH}/tips-trend-report.md"
```

> **No bridge files.** Smarter-service has no `report-bridge-*.md` files because there are no bridges between H3 theme-cases — those live nested under macro elements. The bridges between macro sections are part of the dimension narrative (composed by `trend-report-composer`).

### Verification

Read first 3 + last 3 lines of the assembled report:
- First lines should start with `---` (YAML frontmatter)
- Last lines should contain the claims total
- Report should contain exactly 4 macro H2 headers matching the dimension-name labels
- Report should contain N H3 theme-case headers (where N = number of themes), distributed across the 4 macro sections per the anchoring map
- Report should contain the synthesis H2 header matching `## {SYNTHESIS_HEADING_SMARTER_SERVICE}`

---

## Step 2.7: Merge Claims

Same as legacy flow — merge all 4 dimension claims into `tips-trend-report-claims.json`. Claims data does not change between modes.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `tips-value-model.json` has investment themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| Theme anchoring distribution gives one dimension >3 themes | WARN; composer can still write but report unbalanced |
| Theme-case agent returns `ok: false` | Retry once, then HALT with theme name |
| Theme-case agent quality gate fails (`primer_referenced: false` or missing cost ratio) | WARN; continue (case may be thin) |
| Composer returns `ok: false` | Retry once, then HALT with dimension name |
| Composer dimension narrative <250 words | WARN; macro section may feel thin |
| `report-shared-primer.md` missing when theme-case agent dispatches | HALT: Step 2.0b must complete before Step 2.1 |
| `report-theme-case-{theme_id}.md` missing when composer dispatches for that anchor | HALT: Step 2.1 must complete before Step 2.2 |
| Resume file exists but is corrupt (smaller than threshold) | Re-dispatch the relevant agent |

---

## Comparison with Legacy Flow (for reference only)

| Aspect | Legacy (`phase-2-strategic-themes.md`) | Smarter-service (this file) |
|--------|----------------------------------------|------------------------------|
| H2 layout | One H2 per investment theme (3–7) | 4 H2s — one per Smarter Service dimension |
| Per-theme arc | Why Change → Why Now → Why You → Why Pay (`theme-thesis`) | Stake / Move / Cost-of-Inaction (slim 3-beat) |
| Per-theme word target | ~660 at extended tier | ~490 at extended tier |
| Bridges | `report-bridge-*.md` between consecutive themes | No theme-case bridges; macro bridges live in dimension narratives |
| Composer agent | None — orchestrator stitches | New `trend-report-composer` (4 sequential calls) |
| Shared primer | None — each theme writes its own macro framing | 1 primer (~480 words) shared by all theme-case agents |
| Synthesis | Arc-specific frame from `report-arc-frames.md` | "The Capability Imperative" — Foundations-anchored, fixed |
