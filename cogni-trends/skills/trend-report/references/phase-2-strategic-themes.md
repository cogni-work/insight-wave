# Phase 2: Investment Theme Assembly

Phase 2 assembles the report around investment themes from `tips-value-model.json`. The dimensional evidence gets enriched in Phase 1 — this phase restructures it into strategic narratives.

The core idea: investment themes are the skeleton, individual trends are the evidence woven into each investment theme's story. A CxO reads investment themes and investment decisions, not a catalog of 60 trends sorted by dimension.

**Architecture:** Investment theme section writing is delegated to parallel `trend-report-investment-theme-writer` agents (one per investment theme). Each agent self-loads enriched evidence from disk, writes its investment theme section, and returns compact JSON. The orchestrator handles the remaining lightweight sections (executive summary, claims registry) and final assembly.

---

## Inputs

| Source | Content | Read by |
|--------|---------|---------|
| Investment Themes | Investment theme definitions with value chains | Orchestrator (Step 2.1) |
| Value Chains | T→I→P causal paths | Orchestrator (Step 2.1) + investment theme agents |
| Solution Templates | What to build per investment theme | Orchestrator (Step 2.1) + investment theme agents |
| Per-trend evidence | Evidence blocks keyed by candidate_ref | Investment theme agents (self-load from disk) |
| Claims | Quantitative claims keyed by ID | Investment theme agents (self-load) + orchestrator (Step 2.6) |
| i18n labels | Section headings in target language | Loaded in Phase 0, passed to agents |

---

## Step 2.1: Read Value Model

Read `.logs/phase2-value-model.json` (pruned subset created in Phase 0 Step 0.2b) and extract:
- `investment_themes[]` — ordered list of investment themes
- `value_chains[]` — all value chains with candidate_refs
- `solution_templates[]` — solution templates linked to investment themes (may be empty; only `st_id`, `name`, `category`, `enabler_type`, `investment_theme_ref` fields)
- `coverage` — linked/orphaned/total counts
- `mece_validation` — investment theme count, ME/CE status
- `orphan_candidates[]` — candidates not in any investment theme

The `actions_md` field in enriched-trends contains semicolon-separated action keywords (3-5 words each), e.g. `"pilot predictive maintenance; integrate OT/IT data layer; establish vendor shortlist"`. These are compressed intent markers, not full prose — investment theme agents synthesize complete strategic actions at investment theme level using these as input.

Do NOT read the enriched-trends or claims JSON files at this step. Investment theme agents self-load those files, filtered to their own candidate_refs. The orchestrator only reads claims files later in Step 2.6 for the claims registry.

**Portfolio product resolution:** If `{PROJECT_PATH}/portfolio-context.json` exists, read it and:
1. Extract `portfolio_slug` → resolve to display name (e.g., `"t-systems"` → `"T-Systems"`). This becomes `PORTFOLIO_PROVIDER`.
2. Build a `product_slug → { product_name, product_url }` lookup from `products[]`. This is used in Step 2.2 to resolve `PORTFOLIO_PRODUCTS` for each investment theme agent. `product_url` comes from `products[].url` if available (may be null).

**Study mode + example reference resolution:**

1. Read `{PROJECT_PATH}/tips-project.json → study_mode`. Default `"open"` when absent.
   This becomes `STUDY_MODE` for every dispatched investment-theme agent.

2. For each ST in `tips-value-model.json → solution_templates[]`, read the active
   example array based on `STUDY_MODE`:
   - `vendor` → `vendor_references[]` (each entry includes `source_ref` that resolves inside `cogni-portfolio/{vendor_source.portfolio_ref}/`)
   - `open` → `published_cases[]` (each entry has a public `source_url` and tiered `source_authority`)

3. Build a `st_id → { mode, entries[] }` lookup. Empty arrays and missing keys both
   mean "no examples for this ST" — the agent falls back to plain capability prose.

4. In Step 2.2, filter this lookup per theme (only include STs whose
   `investment_theme_ref == theme.investment_theme_id`) and pass the filtered object
   as `EXAMPLE_REFERENCES` to that theme's agent.

When `study_mode` is missing on older projects, both `vendor_references[]` and
`published_cases[]` will also be absent on all STs — `EXAMPLE_REFERENCES` will be an
empty object, and the agent will render the pre-change output (backward compatible).

---

## Step 2.2: Dispatch Investment Theme Agents

For each investment theme (ordered by `investment_theme_id`), dispatch a `trend-report-investment-theme-writer` agent. Dispatch all agents in a single message (parallel tool calls) so they run concurrently.

### Resume Check

Before dispatching an agent for an investment theme, check if `{PROJECT_PATH}/.logs/report-investment-theme-{investment_theme_id}.md` already exists and is >1000 bytes. If so, skip that agent — display `"{PHASE_2_INVESTMENT_THEME_AGENT_SKIP_RESUME}"` and continue to the next investment theme. This means re-runs only dispatch for missing or incomplete investment themes.

### Agent Prompt Template

```yaml
Per agent:
  subagent_type: "cogni-trends:trend-report-investment-theme-writer"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    INVESTMENT_THEME_ID: {theme.investment_theme_id}
    INVESTMENT_THEME_NAME: {theme.name}
    STRATEGIC_QUESTION: {theme.strategic_question}
    EXECUTIVE_SPONSOR_TYPE: {theme.executive_sponsor_type}
    LANGUAGE: {LANGUAGE}
    REPORT_ARC_ID: {REPORT_ARC_ID}
    INVESTMENT_THEME_INDEX: {1-based index in investment_themes array}
    VALUE_CHAINS: {JSON array of this investment theme's value chains from value_chains[],
      filtered by investment_theme_ref == investment_theme_id. Include full chain objects:
      chain_id, name, narrative, chain_score, trend, implications,
      possibilities, foundation_requirements — each with candidate_ref and name}
    SOLUTION_TEMPLATES: {JSON array of STs where investment_theme_ref == investment_theme_id.
      Include: st_id, name, category, enabler_type. May be empty []}
    PORTFOLIO_PROVIDER: {Display name from portfolio-context.json, e.g. "T-Systems".
      Resolve portfolio_slug to display name (capitalize, replace hyphens).
      Empty string if no portfolio-context.json.}
    MARKET_REGION: {MARKET_REGION from config, default "dach"}
    PORTFOLIO_PRODUCTS: {JSON array of distinct portfolio products grounding this theme's STs.
      Built by collecting portfolio_grounding[].product_slug from all STs in this theme,
      deduplicating by product_slug, and resolving each to { product_name, product_url }.
      product_name comes from portfolio-context.json products[].name (matched by slug).
      product_url comes from portfolio-context.json products[].url (if available, else null).
      May be empty [] if no STs or no portfolio_grounding.}
    SOLUTION_PRICING: {JSON array of solution pricing data for this theme's grounded features.
      Built by: for each unique (feature_slug, market_slug) pair in this theme's
      STs' portfolio_grounding[] entries, read the solution file from the portfolio
      project directory (at {PORTFOLIO_PATH}/solutions/{feature_slug}--{market_slug}.json)
      and extract:
      { feature_slug, market_slug, solution_type, pricing, cost_model, implementation }.
      May be empty [] if no portfolio grounding or solution files not found.
      The orchestrator resolves the portfolio project path from portfolio-context.json →
      portfolio_slug → workspace discovery.}
    STUDY_MODE: {"vendor" | "open" — read from tips-project.json → study_mode.
      Default "open" when absent. Drives the Why You example-rendering rule.}
    EXAMPLE_REFERENCES: {JSON object keyed by st_id for STs in this theme.
      Shape depends on STUDY_MODE:
      - vendor: { st_id: { mode: "vendor", entries: [{ customer_name, outcome_claim, roi_claim?, source, source_ref, publication_date? }, ...] } }
      - open:   { st_id: { mode: "open",   entries: [{ vendor_or_customer, outcome, source_url, source_authority, publication_date? }, ...] } }
      STs with no examples are omitted from the object. May be {} if no STs
      in this theme have example arrays populated.}
    LABELS: {JSON object with relevant i18n labels:
      EXECUTIVE_SPONSOR, INVESTMENT_THESIS, VALUE_CHAINS, TREND,
      IMPLICATION, POSSIBILITY, FOUNDATION, SOLUTION_TEMPLATES,
      SOLUTION, CATEGORY, ENABLER_TYPE, STRATEGIC_ACTIONS,
      WHY_CHANGE, WHY_NOW, WHY_YOU, WHY_PAY,
      REFERENCES_BLOCK_LABEL (de: "Referenzbeispiele", en: "Industry reference cases")
        — used by the investment-theme writer to label the open-mode
        references block.}
    NARRATIVE_ARC_PATH: {path to cogni-narrative theme-thesis arc-definition.md, or omit if not available}
    NARRATIVE_TECHNIQUES_PATH: {path to cogni-narrative techniques-overview.md, or omit if not available}
```

### Resolving cogni-narrative Plugin Root

The investment-theme-writer agent optionally loads the `theme-thesis` arc from cogni-narrative for Corporate Visions-guided storytelling. To resolve the arc path:

1. Check if `cogni-narrative` plugin is installed by looking for its arc-definition file at the expected plugin cache path (e.g., `~/.claude/plugins/cache/insight-wave/cogni-narrative/*/skills/narrative/references/story-arc/theme-thesis/arc-definition.md`) or the monorepo path (`{MONOREPO_ROOT}/cogni-narrative/skills/narrative/references/story-arc/theme-thesis/arc-definition.md`)
2. If the file exists, pass its absolute path as `NARRATIVE_ARC_PATH` and the techniques file as `NARRATIVE_TECHNIQUES_PATH`
3. If cogni-narrative is not installed, **omit both parameters** — the agent falls back to the flat template structure (backward-compatible)

Display `"{PHASE_2_INVESTMENT_THEME_AGENT_DISPATCH}"` after dispatching.

---

## Step 2.3: Collect Agent Results

Wait for all investment theme agents to complete. Each agent returns compact JSON:

```json
{
  "ok": true,
  "investment_theme_id": "it-001",
  "investment_theme_name": "Investment Theme Name",
  "investment_theme_thesis_heading": "Bewiesene 10:1-Investitionsthese — und 78% der Branche ignoriert sie",
  "element_headings": {
    "why_change": "Netzmodernisierung ist keine Hardware-Frage — es ist eine Datenplattform-Transition",
    "why_now": "Drei Regulierungsfristen konvergieren bis August 2026",
    "why_you": "Diese drei Lösungen zur Netzdigitalisierung müssen Sie jetzt anpacken",
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
  "investment_theme_file": ".logs/report-investment-theme-it-001.md"
}
```

### Validation

For each agent result:
1. Check `ok == true`. If `false`: retry once. If retry also fails, HALT with investment theme name.
2. Check `quality_gate_pass == true`. If `false`: log WARNING but continue — the investment theme section is written but may be thin.
3. Display `"{PHASE_2_INVESTMENT_THEME_AGENT_COMPLETE}"` for each successful agent.

All dispatched agents must succeed before proceeding. Agents that were skipped via resume check don't need validation.

### Regulatory Deduplication Check

After collecting all agent results, check the `primary_forcing_function` field from each agent's return JSON. If the same forcing function (e.g., "EU AI Act 2. August 2026") appears as the primary in more than 2 themes, log a WARNING:

```
WARNING: "{forcing_function}" is the primary forcing function in {N} themes ({theme_names}).
Consider re-running affected themes with guidance to diversify forcing functions.
```

This does not HALT the pipeline — the report is still usable — but it flags a quality issue that reduces the reader's sense of urgency through repetition. Each theme should ideally lead with a forcing function specific to its domain (Energy-Sharing for CX, NIS2 for Cybersecurity, CCfD for Dekarbonisierung, etc.).

---

## Step 2.4: Write Executive Summary (after reading investment theme sections)

The executive summary is written AFTER all investment theme agents complete. The orchestrator reads every `report-investment-theme-{investment_theme_id}.md` file to synthesize a grounded Zusammenfassung from the actual prose — not from metadata or agent return JSON alone.

**Why this ordering matters:** The Zusammenfassung is crispier and more specific when the LLM has read the full investment theme narratives. It can pull the most surprising evidence, the sharpest reframes, and the most compelling cost-of-inaction ratios directly from the written sections.

### Process

1. Read ALL `{PROJECT_PATH}/.logs/report-investment-theme-{investment_theme_id}.md` files (in investment theme order)
2. Read the value model for investment theme names and strategic questions
3. Write `{PROJECT_PATH}/.logs/report-header.md` in a single pass

### Frontmatter

```yaml
---
title: "{TITLE}"
subtitle: "{SUBTITLE}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
arc_id: {REPORT_ARC_ID}
generated_by: trend-report
source_skills:
  - trend-scout
  - value-modeler
report_mode: strategic-themes
total_trends: 60
total_investment_themes: {N}
total_claims: {N}
generated_at: "{ISO-8601}"
---
```

### Executive Summary Content — Arc-Aware

The Zusammenfassung is ONE flat section — no subsections (`###`), no tables. A CxO reading only this section should feel "I must act."

**The opener and closer adopt the report-level arc's rhetorical frame.** Read the selected arc's templates from [references/report-arc-frames.md](references/report-arc-frames.md) and use the "Exec Summary Opener" and "Exec Summary Closer" patterns. The middle section (bridge sentence + numbered list) stays the same for all arcs.

```markdown
# {TITLE}

*{SUBTITLE}*

## {EXEC_SUMMARY_LABEL}

{ARC-SPECIFIC OPENER: 2-3 tight sentences using the selected arc's opener pattern.
Synthesized from reading all investment theme sections — pull the most surprising
evidence across investment themes. Anchor with one specific data point lifted from
the investment theme prose. NOT neutral landscape framing.

Examples by arc:
- corporate-visions: Challenge prevailing assumption with unconsidered need
- technology-futures: Open with most surprising technology convergence
- strategic-foresight: Open with strongest converging signals
- industry-transformation: Open with dominant structural forces
- competitive-intelligence: Open with most significant competitive shift
- trend-panorama: Open with force-to-foundation chain
- theme-thesis: Open with portfolio investment framing}

{BRIDGE SENTENCE: One sentence that transitions from the opener to the investment theme list.
It frames what the bullets are — strategic questions that demand answers.

Pattern: "Fünf Handlungsfelder bündeln den Handlungsbedarf:" or
"[N] investment themes crystallize the agenda:"}

1. **{theme_1.name}**: {theme_1.thesis_heading}
2. **{theme_2.name}**: {theme_2.thesis_heading}
...
{N}. **{theme_N.name}**: {theme_N.thesis_heading}

{ARC-SPECIFIC CLOSER: 2-3 sentences using the selected arc's closer pattern.
Source everything from the investment theme sections — specific numbers, deadlines, ratios.

Examples by arc:
- corporate-visions: Aggregate cost-of-inaction vs. proactive investment ratio
- technology-futures: Capability readiness and learning advantage window
- strategic-foresight: Decision framing with hedging approach
- industry-transformation: Leadership positioning in transformed landscape
- competitive-intelligence: Strategic positioning window with first-mover advantage
- trend-panorama: Foundation urgency — awareness without foundations is theater
- theme-thesis: Portfolio return vs. aggregate delay cost}
```

**Rules:**
- NO `###` subsections inside Zusammenfassung
- NO tables — investment themes as a numbered list: `1. **Name**: Thesis heading`
- Each list item uses the investment theme's thesis heading (the H2 from the theme section, e.g., "Rechenzentren verdoppeln die Stromlast — Netzdigitalisierung ist jetzt existenziell") as a compressed summary — NOT the strategic question. The thesis heading communicates the insight; the question is internal scaffolding.
- **No name echo:** If a thesis heading starts with or repeats the theme name, drop the redundant part. Example: `**KI-Gestützte Operative Exzellenz**: KI-Gestützte Operative Exzellenz schafft...` → `**KI-Gestützte Operative Exzellenz**: Regulatorisches und wirtschaftliches Doppel-Advantage durch compliance-geführte Automatisierung`. The colon already separates name from insight — the heading after the colon must add NEW information.
- NO separate Kernevidenz section — weave 2-3 evidence highlights into the closing paragraph
- NO separate Handlungskosten section — merge cost-of-inaction into the closing paragraph
- The entire Zusammenfassung should be tight: opener (2-3 sentences) + numbered list + closing (2-3 sentences)

Must end with two trailing newlines.

---

## Step 2.5: Generate Claims Registry

Claims registry includes an `investment_theme` column. This is the one step where the orchestrator reads the claims JSON files directly.

Read all 4 `claims-{dimension}.json` files. Build a `claim_id → claim` lookup.

To determine which investment theme a claim belongs to: use the value model's value chains to build a `candidate_ref → investment_theme_name` mapping. Then for each claim, find which candidate's `claims_refs` contains it (from the enriched-trends data — or use the agent-returned `candidates_covered` lists as a shortcut). Claims from orphan candidates get "---" in the investment theme column.

Write `{PROJECT_PATH}/.logs/report-claims-registry.md`:

```markdown
## {CLAIMS_REGISTRY_LABEL}

{CLAIMS_REGISTRY_INTRO}

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {INVESTMENT_THEME_LABEL} |
|---|---------------|---------------|-----------------|--------------------------|
| 1 | {claim text} | {value + unit} | [{title}](url) | {investment theme name or "—"} |
```

Must end with two trailing newlines.

---

## Step 2.5b: Generate Bridge Paragraphs

Display `"{PHASE_2_BRIDGES_START}"`.

The orchestrator already has all investment theme sections in context from Step 2.4. For each consecutive pair of themes (Theme 1→2, Theme 2→3, ..., Theme N-1→N), generate a bridge paragraph.

**Process:**
1. Read the arc-specific bridge pattern from [references/report-arc-frames.md](references/report-arc-frames.md) for `REPORT_ARC_ID`
2. For each pair (Theme N, Theme N+1):
   - Extract 1-2 specific data points from Theme N's section (numbers, deadlines, entities)
   - Extract 1-2 specific data points from Theme N+1's section
   - Write a 2-4 sentence bridge using the arc's bridge pattern and vocabulary
   - The bridge must demonstrate a causal or strategic link — NOT a generic transition
3. Write each bridge to `{PROJECT_PATH}/.logs/report-bridge-{N}-{N+1}.md`
4. Display `"{PHASE_2_BRIDGE_WRITTEN}"` for each

**Bridge format:**

```markdown

> **{BRIDGE_LABEL}:** {2-4 sentences using the arc's bridge pattern. Must reference specific
> evidence from both the preceding and following theme — numbers, entities, or deadlines.
> Generic transitions like "Building on the previous theme" are insufficient.}

```

**Quality gate:** Every bridge must contain at least one specific data point from the preceding theme AND one from the following theme. If evidence is insufficient, write the bridge anyway using qualitative connections — but log a WARNING.

Must start and end with one blank line (for clean concatenation between theme sections).

---

## Step 2.5c: Generate Synthesis Section

Display `"{PHASE_2_SYNTHESIS_START}"`.

The synthesis section is a 300-500 word closing section that ties all investment themes together through the report-level arc's final element lens. It replaces the pattern where the report simply stops after the last theme's "Nächste Schritte."

**Process:**
1. Read the arc-specific synthesis frame from [references/report-arc-frames.md](references/report-arc-frames.md) for `REPORT_ARC_ID`
2. Look up the synthesis heading from i18n labels: `SYNTHESIS_{REPORT_ARC_ID_UPPERCASE}` (e.g., `SYNTHESIS_CORPORATE_VISIONS`)
3. Read all theme sections (already in context) and the agent-returned metadata (why_pay_ratio, top_claims, etc.)
4. Write the synthesis section following the arc's synthesis frame

**Synthesis format:**

```markdown
## {SYNTHESIS_HEADING}

{Opening: 2-3 sentences through the arc's synthesis lens}

{Body: 200-350 words that:
- Aggregate the strongest evidence across themes
- Identify shared foundations / investments that unlock multiple themes
- Present the combined cost-of-inaction vs. proactive investment
- Apply the arc's specific synthesis technique}

{Unified Action Roadmap — sequences ACROSS themes:}
1. **{Calendar timeframe}**: {Cross-theme action — names which themes it enables}
2. **{Calendar timeframe}**: {Cross-theme action}
3. **{Calendar timeframe}**: {Cross-theme action}

{Closing: 1-2 sentences — the arc's decisive closing statement}
```

Write to `{PROJECT_PATH}/.logs/report-synthesis.md`. Display `"{PHASE_2_SYNTHESIS_WRITTEN}"`.

Must end with two trailing newlines.

> **Note:** Per-theme "Nächste Schritte" remain in each theme section — they're specific and actionable per domain. The synthesis roadmap is the cross-theme orchestration layer on top.

---

## Step 2.6: Assemble Final Report

Verify all files exist, then concatenate in this order — bridges interleaved between themes, synthesis before claims:

```bash
# Build file list: header
FILES="{PROJECT_PATH}/.logs/report-header.md"

# Investment theme sections with bridges interleaved
THEME_IDS=(it-001 it-002 ... it-N)
for i in "${!THEME_IDS[@]}"; do
  FILES="$FILES {PROJECT_PATH}/.logs/report-investment-theme-${THEME_IDS[$i]}.md"
  # Add bridge after each theme except the last
  NEXT=$((i + 1))
  if [ $NEXT -lt ${#THEME_IDS[@]} ]; then
    BRIDGE_FILE="{PROJECT_PATH}/.logs/report-bridge-$((i+1))-$((i+2)).md"
    if [ -f "$BRIDGE_FILE" ]; then
      FILES="$FILES $BRIDGE_FILE"
    fi
  fi
done

# Synthesis section (before claims)
FILES="$FILES {PROJECT_PATH}/.logs/report-synthesis.md"

# Claims registry
FILES="$FILES {PROJECT_PATH}/.logs/report-claims-registry.md"

cat $FILES > "{PROJECT_PATH}/tips-trend-report.md"
```

### Verification

Read first 3 + last 3 lines of the assembled report:
- First lines should start with `---` (YAML frontmatter)
- Last lines should contain the claims total
- Report should contain exactly N investment theme H2 headers matching `## {N}. {theme.name}`
- Report should contain the synthesis H2 header matching `## {SYNTHESIS_HEADING}`
- Report should contain N-1 bridge blockquotes between theme sections

---

## Step 2.7: Merge Claims

Merge all 4 dimension claims into `tips-trend-report-claims.json`. The claims themselves don't change; only the report structure around them does.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `tips-value-model.json` has investment themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| Investment theme agent returns `ok: false` | Retry once, then HALT with investment theme name |
| Investment theme agent quality gate fails | WARNING: continue (section written but may be thin) |
| enriched-trends JSON missing (agent reports) | HALT: Phase 1 agent failed to produce enriched output |
| Investment theme references candidate_ref not found in enriched data | Agent logs warning, skips that candidate |
| Solution templates empty | Agents omit "Solution Templates" subsection |
| Resume file exists but is corrupt (<1000 bytes) | Re-dispatch agent for that investment theme |
