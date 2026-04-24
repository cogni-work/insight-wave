# trends-bridge evals fixtures

Minimal synthetic portfolio + TIPS project pairs used by `evals/evals.json` as
repeatable smoke tests for the bridge. Each fixture is intentionally tiny —
one product, one feature, one market, optional customers — so the test exercises
the bridge's control flow without turning the eval into a data review.

## Fixtures

### `status-ready/`

Portfolio with 1 product / 1 feature / 1 proposition / 1 market, TIPS project
with a ranked `tips-value-model.json`, and a pre-existing
`portfolio-context.json` at `schema_version: "3.2"`. Exercises the `status`
operation's happy path — all hard gates pass and the readiness ladder should
report v3.2.

### `with-customers/`

Portfolio with populated `portfolio/customers/{market-slug}.json →
named_customers[]` (two entries with canonical enum `fit_score`). Exercises
`portfolio-to-tips` Step 2.8 — the written `portfolio-context.json` should
include a non-empty `named_customer_references[]` that passes the eval 2
assertions (canonical enum, empty `feature_slugs`, portfolio-sourced
`outcome_summary`).

### `without-customers/`

Same as `with-customers/` but with **no** `portfolio/customers/` directory at
all. Exercises the Step 2.8 missing-file fallback — the written
`portfolio-context.json` should still be v3.2 and contain
`named_customer_references: []` cleanly, with Step 4 reporting zero refs.

## Running the evals

These fixtures are scaffolding for future skill-creator iteration loops or for
manual smoke tests. They are **not** wired into CI today. To run eval 2
manually:

```
cd cogni-portfolio/skills/trends-bridge/evals/fixtures/with-customers
# Point the bridge at this directory pair and run:
#   /bridge portfolio-to-tips
# Then validate the written ./tips/portfolio-context.json against eval 2's
# assertions (schema_version, named_customer_references contents, fit_score
# enum, feature_slugs empty, outcome_summary traceability).
```
