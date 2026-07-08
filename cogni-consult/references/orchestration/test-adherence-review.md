# Test Framework-Adherence Review

The completion-time framework-adherence contract for the design-thinking Test
stage. When the draft survives (consultant accepts), this contract runs in the
same survive branch as the evidence-provenance gate — after the persona
challenges have settled and any revisions are applied, and before the
`state` → `"complete"` write. It adds the middle rung of the repo's
Three-Layer Quality Gate (structural validation → **framework-adherence /
quality** → stakeholder review): the persona challenge already covers
stakeholder voice; this pass covers structural conformance to the deliverable's
chosen framework. The design-thinking loop points here; the contract below is
authoritative.

## When it runs

Read the deliverable's `chosen_framework` (already in hand from the Prerequisite
Gate — no extra read):

- **`null`** → there is no framework to conform to. Skip this step entirely: no
  agent is dispatched and no `adherence-review` entry is written. The
  deliverable completes with no adherence stop.
- **a `slug` or `combo:<slugA>+<slugB>`** → run the review once for this
  completion.

## Idempotency

The review fires only on the survive → `complete` branch, which is reached once
per completion. Before dispatching, scan `.metadata/decision-log.json` for an
`adherence-review` entry whose `(action_field, deliverable)` coordinates match
this deliverable: if one exists and the deliverable is already `complete` with
no intervening rework (a `complete` → `in-progress` re-open), the review
already ran for this completion — skip the re-dispatch (a Step-7 resume on an
already-complete deliverable never re-reviews). A genuine rework re-opens the
deliverable and re-runs the review because the artifact changed, appending a
fresh entry.

## Dispatch

Dispatch the read-only `consult-framework-adherence-reviewer` agent — it scores
the artifact against the stored `chosen_framework` and returns concrete drift
findings, never a pass/fail bit (it holds no Write/Edit tools). Pass its four
required inputs:

- `engagement_dir`: absolute path to the engagement directory (the one holding
  `consult-project.json`).
- `field_slug`: the deliverable's action field.
- `deliverable_slug`: the deliverable under review.
- `plugin_root`: `$CLAUDE_PLUGIN_ROOT`.

The agent resolves the framework signature(s), reads the artifact, and returns
the standard envelope with `data.adherence` (`strong` / `partial` / `drifted`),
`data.findings[]` (each naming the expected structure, what the artifact does
instead, and a concrete fix), and a one-paragraph `data.summary`. It returns
`data.applicable: false` for a `null` framework or an undrafted artifact — a
defensive fallback; the `null`-framework case is already short-circuited above.

## Advisory, never gating

The review is **advisory**, matching the sibling persona challenge — it never
blocks completion. In auto-walk mode, surface the `adherence` band, the
findings, and the summary, then proceed to the completion write without pausing
(so auto-walk never deadlocks on a gate that needs consultant input). In
interactive mode, surface the findings before the completion write; the
consultant may elect to loop back to `define`/`prototype` to close a drift, but
electing to complete anyway is always available. Drift is reported, not
enforced.

## Record the outcome

Append one `adherence-review` entry to `.metadata/decision-log.json`'s
`decisions[]` array, discriminated by `kind` and keyed by the WBS coordinates —
following the discriminated-kind pattern of the sibling `framework-selection`
and `evidence-provenance-waiver` entries, with discrete filterable keys (no
prose `decision` string):

```json
{"id": "d-NNN", "kind": "adherence-review", "action_field": "<field-slug>",
 "deliverable": "<deliverable-slug>", "chosen_framework": "<slug or combo>",
 "adherence": "strong | partial | drifted", "findings_count": 0,
 "summary": "<the agent's one-paragraph verdict>", "timestamp": "<ISO>"}
```

Write it in the same completion moment as the `state` → `"complete"` write. The
entry shape is registered alongside the other decision-log kinds in
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
