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

The template renders Strategic Themes as sections, with value chains as cards beneath each
theme. Each card has 1-5 button scoring per TIP candidate. Candidates appearing in multiple
chains are synced — the user scores once, it propagates. A progress bar shows scoring
coverage per theme and overall. "Export" downloads `br-scores.json`.

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
  "total_scored": 30,
  "total_candidates": 38
}
```

1. Read the scores (from downloaded file or inline input)
2. Update each candidate's `business_relevance` in `tips-value-model.json`
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
