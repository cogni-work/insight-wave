# Test Assumption Promote-Check

The completion-time assumption-registration contract for the design-thinking
Test stage. When the draft survives (consultant accepts), this contract runs in
the same survive branch as the evidence-provenance gate and the
framework-adherence review — after the persona challenges have settled and any
revisions are applied, and before the `state` → `"complete"` write. It closes
the gap the Assumption Registry design left open: the registry is the single
source of truth for planning numbers (`{{asm:<slug>}}` placeholders resolved by
`scripts/resolve-assumptions.py`), but nothing wired the authoring stages to
*populate* it — so load-bearing numbers shipped inlined as prose instead of
registered. This rung **acts by default** rather than only warning; the
design-thinking loop points here, and the contract below is authoritative.

## When it runs

Runs once per completion, in the Test survive → `complete` branch, after the
framework-adherence review (`test-adherence-review.md`) and the copywriter
polish, before the `state` → `"complete"` write. It has no framework
precondition — unlike the adherence review it fires for every completing
deliverable, because any deliverable can carry a bare planning literal.

## Idempotency

The check fires only on the survive → `complete` branch, which is reached once
per completion. Before scanning, look in `.metadata/decision-log.json` for an
`assumption-promotion` entry whose `(action_field, deliverable)` coordinates
match this deliverable: if one exists and the deliverable is already `complete`
with no intervening rework (a `complete` → `in-progress` re-open), the check
already ran for this completion — skip the re-scan (a Step-7 resume on an
already-complete deliverable never re-promotes and never double-logs). A genuine
rework re-opens the deliverable and re-runs the check because the artifact
changed, appending a fresh entry.

## Scan and propose

Scan the finished artifact for **bare quantified planning literals** — planning
numbers a reader would expect to stay current (market sizes, rates, headcounts,
price points, budgets, capacities, dates-as-targets) written directly in the
text rather than cited as a `{{asm:<slug>}}` placeholder backed by the
engagement-root `assumptions.json` registry. Skip numbers already carried by a
placeholder, numbers inside the frontmatter `sources[]` lineage, and incidental
figures a reader would not expect to recompute (footnote references, figure
counts).

For each promotable literal, propose an `assumptions.json` entry with the
registry's mandatory fields (`id` = `asm-` + kebab-case slug, `name`, `value`
verbatim including unit) plus a `provenance_type` and a **capped** `status`:

- `given` (a stipulated planning figure — a guess) → `status: "stated"` only.
- `estimate` (a derived / calculated figure) → `status: "reviewed"` at most.

A scanned bare literal is almost always `given` or `estimate`; do **not** assign
`provenance_type: "claim"` here — reaching `verified` requires the live
cogni-claims round-trip (`scripts/submit-assumption-claim.py`), which is out of
scope for an authoring-time promotion. `used_by[]` is resolver-owned — never
hand-author it (the resolver appends it on `--in-place`). The full field
contract is `references/data-model.md`, Assumption Registry.

## Convert to placeholders

Offer to convert each accepted literal's occurrences in the artifact to its
`{{asm:<slug>}}` placeholder, and add the proposed entries to the engagement-root
`assumptions.json`. The consultant may accept all, accept a subset, or decline
(see **Advisory, never gating**). Registry adds and placeholder swaps land
together for each accepted literal so the artifact never references an
unregistered slug.

## Verify

After the accepted swaps, run `scripts/resolve-assumptions.py` as a **dry-run**
(the read-only `resolve` form, *without* `--in-place`) over the artifact to
confirm every new `{{asm:<slug>}}` resolves and its `provenance_type`/`status`
pair passes the fail-loud provenance-cap check:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/resolve-assumptions.py <engagement-dir> \
    resolve <engagement-dir>/action-fields/<field-slug>/<deliverable-slug>.md
```

The resolver returns the single-line `{success, data, error}` envelope with
`data.failed_check` on failure (unknown placeholder id, malformed placeholder,
defective registry entry, unresolved-after-substitution leftover, illegal
provenance cap). On a failure, surface `data.failed_check`, repair the offending
entry, and re-run the dry-run before treating the promotion as done — a promotion
that does not resolve cleanly is not complete.

## Advisory, never gating

The check **acts by default** but is **strictly non-blocking** — matching the
sibling adherence-review and copywriter-polish rungs. In auto-walk mode, perform
the promotion (propose → convert accepted → verify) and proceed to the completion
write without pausing. In interactive mode, surface the proposed entries before
the write; the consultant may accept, accept a subset, or **opt out on the
record**. Whether the promotion runs in full, in part, or is declined, the DT
loop proceeds to completion unchanged — a promotable literal must never stall the
flow.

## Record the outcome

Append one `assumption-promotion` entry to `.metadata/decision-log.json`'s
`decisions[]` array, discriminated by `kind` and keyed by the WBS coordinates —
following the discriminated-kind pattern of the sibling `adherence-review` and
`copywriter-polish` entries, with discrete filterable keys (no prose `decision`
string):

```json
{"id": "d-NNN", "kind": "assumption-promotion", "action_field": "<field-slug>",
 "deliverable": "<deliverable-slug>", "outcome": "promoted | declined | none-found",
 "promoted_ids": ["asm-<slug>", "..."], "promoted_count": 0,
 "declined_count": 0, "timestamp": "<ISO>"}
```

`outcome` is `promoted` when at least one literal was registered, `declined` when
promotable literals were found but the consultant opted out (record it — an
opt-out is a decision), and `none-found` when the scan surfaced nothing to
promote. `promoted_ids[]` names the registered entry ids; `promoted_count` /
`declined_count` are the discrete filterable counts. Write it in the same
completion moment as the `state` → `"complete"` write. The entry shape is
registered alongside the other decision-log kinds in
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
