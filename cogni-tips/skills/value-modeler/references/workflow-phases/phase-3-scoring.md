# Phase 3: Business Relevance Scoring

## Objective

Enable the user to assign customer-specific Business Relevance (BR) scores to each TIP
entity in the relationship networks. This is the step that makes the model customer-specific
rather than generic.

## Why Customer-Specific Scoring?

Two different customers in the same industry will have different priorities. A manufacturer
focused on quality might rate "Real-time Defect Detection" as BR=5, while one focused on
cost reduction might rate it BR=2. The scoring step captures this customer context and
propagates it through to solution rankings via formula F1.

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
   - `__MODEL_DATA_PLACEHOLDER__` → the value model JSON (paths array with candidate refs/names,
     plus `project_id`). Only include `paths` and `project_id` — not the full model.
3. Write to `value-modeler-scoring.html` in the project directory
4. Open it: `open value-modeler-scoring.html`

The template renders each path as a card with 1-5 button scoring per TIP candidate.
Candidates appearing in multiple paths are synced — the user scores once, it propagates.
A progress bar shows scoring coverage. "Export" downloads `br-scores.json`.

The user may show this to stakeholders — it's designed to be professional and self-contained.

## Step 2: Present to User

Open the scoring HTML in the browser and tell the user:

"I've created a scoring interface. For each trend, implication, and possibility, rate how
relevant it is for your specific customer on a 1-5 scale. You don't have to score everything —
unscored items will be excluded from the ranking calculation. When you're done, click
'Submit Scores' and come back here."

## Step 3: Alternative — Inline Scoring

If the user prefers not to use the HTML interface (or it's not practical), offer inline scoring:

Present each path one at a time and ask for scores:

```
Path 1: AI-Driven Quality Optimization

T: EU Quality Standards Tightening (score: 0.85, act)
   → How relevant is this for your customer? [1-5 or skip]

I: Real-time Defect Detection Gap (score: 0.78, act)
   → How relevant is this for your customer? [1-5 or skip]

P: Predictive Quality Management (score: 0.72, plan)
   → How relevant is this for your customer? [1-5 or skip]
```

For efficiency, also offer batch scoring:
"Want to score all at once? Give me a list like: T1=4, I1=5, P1=3, T2=2, ..."

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
