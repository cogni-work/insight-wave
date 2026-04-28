# Phase 3: Business Relevance Scoring

## Objective

Enable the user to assign customer-specific Business Relevance (BR) scores to each TIP
entity in the value chains, organized by Strategic Theme. This is the step that makes
the model customer-specific rather than generic.

## Why Customer-Specific Scoring?

Two different customers in the same industry will have different priorities. A manufacturer
focused on quality might rate "Real-time Defect Detection" as BR=5, while one focused on
cost reduction might rate it BR=2. The scoring step captures this customer context and
propagates it through to solution rankings via formula F1.

Scoring is organized by theme so the user can focus on one strategic area at a time.
This also naturally surfaces which themes matter most to this customer — a theme where
all TIPs score 2-3 may be deprioritized entirely, while a theme scoring 4-5 across the
board is clearly mission-critical.

## Business Relevance Scale

| Score | Label | Meaning |
|-------|-------|---------|
| 1 | Very Low | Secondary process, very little impact on customer activities |
| 2 | Low | May bring some limited value in individual business domains |
| 3 | Average | Significant benefits in some customer activities but not cross-domain critical |
| 4 | High | Impacts multiple business areas and key processes, substantial benefits expected |
| 5 | Very High | Mission critical with the possibility to massively impact company KPIs |

## Step 0.5: LLM Pre-Score with Rationale

Before generating the scoring UI, dispatch the `br-pre-scorer` agent to draft a
suggested score (1–5) and one-line rationale per candidate. The user sees the
suggestion in the UI as the prefilled score plus an editable rationale, and
becomes an editor instead of an author. This eliminates the cold-start problem
and produces an audit-trail rationale alongside every score (issue #176).

This step is **best-effort**: a missing or failed pre-score does not block
scoring — the UI still renders, just without suggestions or pre-filled
rationales.

### Step 0.5.1: Dispatch the agent

Run `br-pre-scorer` with the project path and language. The agent reads
`tips-project.json`, walks `tips-value-model.json` for unique candidate_refs,
enriches each with description/rationale/evidence/sources from
`.metadata/trend-scout-output.json` if present, and writes
`.metadata/br-pre-scores.json` per its output schema.

```text
Agent: br-pre-scorer
  PROJECT_PATH: <project_path>
  LANG: <project_language>  # de or en, from tips-project.json
```

### Step 0.5.2: Merge suggestions into the value model

Read `.metadata/br-pre-scores.json`. For each entry in `suggestions[]`, walk
every value chain in `tips-value-model.json` and update each occurrence of
the candidate (in `trend`, `implications[*]`, `possibilities[*]`):

- `business_relevance_suggested` ← `suggested_score`
- `business_relevance_rationale` ← `rationale`
- `business_relevance_suggested_confidence` ← `confidence`

A candidate appearing in multiple chains gets the same suggestion in every
occurrence. Do NOT touch `business_relevance` itself — that field stays `null`
until the user submits scores.

If `br-pre-scores.json` is missing or has `scored_count == 0`, skip the merge
silently and proceed to Step 1. The template degrades gracefully (no badge,
no pre-filled rationale).

### Step 0.5.3: Brief the user

Print one line so the user sees the suggestions exist before the UI opens:

```
Pre-scored 34 candidates (distribution 1=2, 2=6, 3=8, 4=12, 5=6).
Open the scoring UI to accept, adjust, or override.
```

If the agent produced 100% scores in `{3, 4}` (signal that calibration failed),
add a one-line warning so the user knows the suggestions are weakly
discriminating.

## Step 1: Generate Scoring Interface

Use the HTML template at `$CLAUDE_PLUGIN_ROOT/skills/value-modeler/templates/scoring-ui.html`.

1. Read the template
2. Replace placeholders:
   - `__LANG__` → project language code (`de` or `en`)
   - `__PROJECT_NAME__` → project name from tips-project.json
   - `__INDUSTRY__` → industry display name (in project language)
   - `__MODEL_DATA_PLACEHOLDER__` → the value model JSON. Include `themes` and `value_chains`
     arrays (with candidate refs/names), plus `project_id` — not the full model.
3. Write to `value-modeler-scoring.html` in the project directory
4. Open it: `open value-modeler-scoring.html`

### TIP candidate enrichment in the payload

When you build the TIP entries inside `value_chains[].trend`, `value_chains[].implications[]`,
and `value_chains[].possibilities[]`, carry the full candidate context — not just the short
name. The template renders an expandable `<details>` block per TIP that shows description,
rationale, evidence, and sources so the user can score 30+ candidates without keeping
`trend-candidates.md` open in a second window (issue #175).

For each TIP entry in the payload, include these fields alongside the existing `name`,
`candidate_ref`, `score`, and horizon fields:

| Field | Type | Source |
|-------|------|--------|
| `description` | string | `tips_candidates.items[].description` from `.metadata/trend-scout-output.json` |
| `rationale` | string | `tips_candidates.items[].rationale` from same |
| `evidence` | array of strings | `tips_candidates.items[].evidence` from same (bullet points) |
| `sources` | array of `{title, url}` objects (or plain strings) | `tips_candidates.items[].sources` from same |
| `business_relevance_suggested` | integer 1–5 (or null) | `tips-value-model.json` candidate field, populated by Step 0.5 |
| `business_relevance_rationale` | string (or null) | same — the LLM-drafted one-line justification |
| `business_relevance_suggested_confidence` | `"high"`/`"low"` (or null) | same |

Look up each candidate by `candidate_ref` against `tips_candidates.items[*].candidate_ref`
(or `id`) and merge the four fields into the TIP entry before serializing. Any of the four
may be empty or omitted on the source candidate — the template degrades gracefully and
omits the corresponding section, so do not synthesize placeholder content. If
`trend-scout-output.json` is missing entirely (legacy projects), serialize the payload
without these fields and the template will simply skip the details block on each row.

The template renders Strategic Themes as sections, with value chains as cards beneath each
theme. Each card has 1-5 button scoring per TIP candidate. Candidates appearing in multiple
chains are synced — the user scores once, it propagates. A progress bar shows scoring
coverage per theme and overall. Each TIP row carries an inline expandable "Details" section
(native HTML5 `<details>`/`<summary>`, no JS) that reveals description, rationale, evidence,
and sources when clicked. "Export" downloads `br-scores.json`.

The user may show this to stakeholders — it's designed to be professional and self-contained.
The theme-level grouping makes it practical even for non-technical stakeholders to work
through systematically — one investment area at a time.

### Quality Flag Awareness

When presenting STs for scoring, surface any `quality_flag: "quality_investment_needed"` markers
set by Phase 2. These indicate the matched portfolio proposition scored "fail" on quality
dimensions (market_specificity or differentiation). Show a warning icon next to affected STs
in both the HTML template and inline views so the user knows the underlying proposition needs
improvement — their BR score still applies, but customer-facing materials should wait until
the proposition is refined.

### Generic Portfolio Context

When using generic portfolio context (`generation_mode: "generic-portfolio-anchored"`), quality
flags are absent on all STs — propositions were generated dynamically from taxonomy features
without quality assessment history. Scoring remains fully valid: Business Relevance captures
customer-specific relevance regardless of portfolio source. Omit the quality warning icon for
generic-anchored STs in both HTML and inline views.

## Step 2: Present to User

Open the scoring HTML in the browser and tell the user:

"I've created a scoring interface. For each trend, implication, and possibility, rate how
relevant it is for your specific customer on a 1-5 scale. You don't have to score everything —
unscored items will be excluded from the ranking calculation. When you're done, click
'Submit Scores' and come back here."

## Step 3: Alternative — Inline Scoring

If the user prefers not to use the HTML interface (or it's not practical), offer inline scoring:

Present one theme at a time, with its chains:

```
## Theme 1: Health & Nutrition Transformation
Strategic Question: How do we reformulate for the GLP-1-era consumer?

### VC-1: GLP-1 Portfolio Reformulation

T: GLP-1 Market Impact (score: 0.85, act)
   → How relevant is this for your customer? [1-5 or skip]

I: Personalized Digital Experiences (score: 0.78, act)
   → How relevant is this for your customer? [1-5 or skip]

P: GLP-1 Portfolio Reformulation (score: 0.72, act)
   → How relevant is this for your customer? [1-5 or skip]

### VC-2: Functional Ingredients Innovation
...
```

For efficiency, also offer batch scoring:
"Want to score all at once? Give me a list like: T1=4, I1=5, P1=3, T2=2, ..."
Or theme-level shorthand: "Theme 1 = all 4s, Theme 3 = all 2s"

## Step 4: Process Scores

Once the user provides scores, read them. The HTML scorer exports `br-scores.json` (likely
in `~/Downloads/`). The format is:

```json
{
  "project_id": "...",
  "scores": {
    "externe-effekte/act/1": 5,
    "digitale-wertetreiber/act/3": 4,
    ...
  },
  "rationales": {
    "externe-effekte/act/1": "Rechtlicher Zwang im DACH-Markt — Compliance ist nicht verhandelbar.",
    "digitale-wertetreiber/act/3": "Direkter Hebel auf CSAT — passt zur 2026-Roadmap.",
    ...
  },
  "total_scored": 30,
  "total_candidates": 38
}
```

`rationales` is keyed by `candidate_ref` and carries the user-edited rationale
text from the scoring UI (initialized from `business_relevance_rationale` and
overwritten if the user typed in the textarea). A candidate that was scored but
has an empty rationale string omits the key.

1. Read the scores (from downloaded file or inline input)
2. Update each candidate's `business_relevance` in `tips-value-model.json`,
   and overwrite `business_relevance_rationale` from the `rationales` map when
   present (the user's edit always wins over the LLM draft)
3. Report scoring coverage:
   - How many candidates were scored vs skipped
   - Average BR across all scored candidates
   - Distribution: how many 1s, 2s, 3s, 4s, 5s

If < 50% of candidates are scored, warn that the ranking will be based on limited data
and suggest scoring more items. But don't block — partial scoring is valid.

## Step 5: Allow BR Override on Solution Templates

Per the patent, the user may also directly assign BR to Solution Templates — overriding
the calculated value. This is useful when no parent TIPs are scored but the user knows
the solution matters.

Ask: "Want to also directly rate any Solution Templates, or should I calculate their
relevance purely from the TIP scores?"

If the user provides ST overrides, store them as `business_relevance` (distinct from
`business_relevance_calculated` which comes from F1).

## Output

Update `tips-value-model.json`:
- Set `business_relevance` on all scored candidates within paths
- Set `business_relevance` on any directly-scored Solution Templates

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"scored"`
- Add `"phase-3"` to `phases_completed`
- Record `scored_candidates`, `total_candidates`, `avg_br`, `scoring_coverage_pct`
