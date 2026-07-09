# cogni-consult Deliverable Dependency Model Reference

Deliverables in an engagement are not islands. A market-sizing deliverable feeds
the proposition that sizes the opportunity; a competitor landscape feeds the
go-to-market play. When an upstream deliverable changes, its dependents may no
longer rest on current ground. This reference defines how those dependencies are
declared, validated, and propagated — the foundation the write side and read side
both consume.

The engine is `scripts/deliverable-graph.py` (stdlib python3, `{success, data, error}`
JSON envelope, engagement directory as its first positional argument). It is
read-mostly: every subcommand except `cascade-stale` is pure read; `cascade-stale`
performs the single write this model allows — flagging dependents stale, never
rewriting them.

## Edge schema

A dependency is declared on the **dependent**, inside its `field.json` deliverable
entry, as a `depends_on[]` array of WBS-coordinate objects:

```json
{
  "slug": "go-to-market-play",
  "title": "Go-to-market play",
  "state": "pending",
  "dt_stage": "empathize",
  "producing_route": "consult-design-thinking",
  "persona_review": "pending",
  "depends_on": [
    { "action_field": "market-evidence", "deliverable": "market-sizing" },
    { "action_field": "market-evidence", "deliverable": "competitor-landscape" }
  ]
}
```

Each entry is an object with exactly two string fields:

| Field | Required | Description |
|-------|----------|-------------|
| `action_field` | Yes | The action-field slug that owns the upstream deliverable |
| `deliverable` | Yes | The upstream deliverable's slug within that field |

`depends_on[]` may be omitted or empty (the default — no dependencies). Edges may
cross field boundaries: a deliverable in `go-to-market` can depend on one in
`market-evidence`. The pair `{action_field, deliverable}` is the **WBS coordinate**
of the upstream node; its canonical string form (used in tooling output and the CLI
shorthand below) is `<action_field>/<deliverable>`.

### `used_by[]` — the assumption reference edge (derive-at-write)

Assumption records in the engagement-root `assumptions.json` carry the second
edge type of this model: `used_by[]`, the list of files that cite the
assumption via a `{{asm:<slug>}}` placeholder. Unlike `depends_on[]` it is
**never hand-authored** — `scripts/resolve-assumptions.py` records the citer
automatically whenever an in-place resolve substitutes the assumption's value.
Each entry is:

```json
{ "file": "action-fields/market-evidence/market-sizing.md",
  "resolved_at": "2026-07-09T05:10:00+00:00" }
```

| Field | Description |
|-------|-------------|
| `file` | The citing file's path relative to the engagement root |
| `resolved_at` | UTC timestamp of the first resolve that recorded this citer |

The two edge types deliberately sit at opposite ends of the derivation
spectrum. `depends_on[]` → `blocks[]` is **declare-then-derive**: the
consultant declares the forward edge, the inverse is computed at read time
(below). `{{asm:id}}` citation → `used_by[]` is **derive-at-write**: the
citation event is a past fact — which file resolved against the value, and
when — that cannot be recomputed from current state (a rendered brief no
longer contains the placeholder), so the resolver stores it at the moment it
happens, the same stored-because-it-happened rationale as `lineage_status`.
Writes are idempotent: a citer already present in `used_by[]` (matched on its
relative path) is skipped, and when nothing new was cited the registry file is
not rewritten, so repeated publish or design-thinking renders never churn the
registry. The edge lands **before** the citing file is rewritten, so a failed
edge write leaves the placeholders intact and the resolve safely retryable.
Dry-run resolves (no `--in-place`) record nothing. Edge recording assumes the
engagement's single-session write model (the same assumption every
`field.json` write makes): concurrent in-place resolves against one
engagement are not serialized, and the last registry writer wins.

`used_by[]` is what makes an assumption propagatable: once the registry knows
every citer, a value correction can cascade staleness to exactly the files
that rest on the old number.

### `blocks[]` is derived, never stored

The inverse relation — "what does this deliverable block?" — is **not** written to
`field.json`. It is derived at read time by inverting `depends_on` across every
field's `field.json`. This is the same single-source-of-truth discipline the data
model applies to field/engagement completion (see `references/data-model.md`,
*State Ownership*): storing both directions would double the write surface and make
drift between the two copies possible. `deliverable-graph.py impact` computes the
inverse on demand.

### CLI coordinate shorthand

The stored schema is the object form. On the command line, the WBS coordinate is
passed in the `<action_field>/<deliverable>` **slash shorthand** and parsed into the
object form internally:

```bash
python3 scripts/deliverable-graph.py <engagement-dir> trace go-to-market/go-to-market-play
```

## `lineage_status` — the stored staleness flag

Independently of `state`, each deliverable carries an optional `lineage_status`:

```json
"lineage_status": {
  "status": "stale",
  "reason": "upstream deliverable market-evidence/market-sizing changed (trigger: deliverable_update)",
  "flagged_at": "2026-06-15T15:30:00Z",
  "trigger": "deliverable_update"
}
```

| Field | Description |
|-------|-------------|
| `status` | Currently always `"stale"` when present; `null` (or the field absent) means current |
| `reason` | Human-readable explanation naming the upstream coordinate and the trigger |
| `flagged_at` | ISO-8601 UTC timestamp of when the flag was raised |
| `trigger` | `"deliverable_update"` (an upstream deliverable was reworked) or `"claims_correction"` (a cogni-claims correction cascaded in) |

`lineage_status` is **orthogonal to `state`**: a deliverable can be `complete` and
`stale` at the same time. That is the point — the completed artifact and its DT
stage stay intact (a human did real work to produce them), but the flag records that
an upstream change may have invalidated the ground beneath it. Re-working the
deliverable (or a deliberate human "still current" decision) clears `lineage_status`
back to `null`.

This is why `lineage_status` **is stored** while `blocks[]` is derived: staleness is
a fact about a past event (an upstream change at a point in time) that cannot be
recomputed from current state alone, so it must be persisted.

## Validation rules (hard errors)

`deliverable-graph.py validate` walks every `field.json` and fails (`success:false`)
on either of two structural defects:

- **Cycles.** A `depends_on` chain that loops back on itself (`A → B → A`) has no
  valid refresh order and signals a modeling error. Reported as the offending node
  sequence.
- **Dangling references.** A `depends_on` entry whose `{action_field, deliverable}`
  names a deliverable that does not exist in any `field.json`. Reported as the
  `from → to` pair.

A clean graph returns `success:true` with the node and edge counts. Validation is
the gate the write side runs before accepting a newly declared edge.

## Inferred edges (unrecorded dependencies from `sources[]`)

A dependency can exist in fact without ever being declared: a deliverable's artifact
may cite another deliverable's artifact through its frontmatter `sources[]` lineage
triple (an `entity_ref` or a `file://` `source_url` carrying an
`action-fields/<af>/<deliverable>` segment) while no `depends_on[]` edge was recorded.
The declared graph then reports zero dependents for the cited deliverable, so a
correction or rework never cascades to the deliverable that actually consumes it — a
silent gap.

`deliverable-graph.py` surfaces these as **inferred edges**. `load_graph` reads each
deliverable's artifact frontmatter `sources[]`, resolves any entry that names a sibling
deliverable, and records an inferred edge (`dependent → dependency`) whenever the
resolved target is a real, distinct node **not** already in the dependent's
`depends_on[]`. A self-referential `entity_ref` — the lineage triple naming the
deliverable's own coordinate, as carried alongside an external `source_url` — resolves
to the node itself and is skipped, so an external https source raises no edge.

Inferred edges are **advisory**:

- `validate` surfaces them in `inferred_edges[]` / `inferred_edge_count` plus a
  human-readable `warnings[]` entry, and **stays `success:true`** — they never feed
  cycle or dangling detection (those remain `depends_on`-only hard errors).
- They are **never written** to `field.json`. Making an inferred edge authoritative is
  an explicit author action: declare it in `depends_on[]`. This preserves the
  flag-not-rewrite contract — the engine never mutates author-declared graph state from
  a heuristic.
- `impact` and `cascade-stale` accept `--include-inferred` to fold the inferred edges
  into the blast radius (closing the silent-zero-dependents gap). Default is the
  declared graph only, so existing callers are unaffected.

Resolution degrades gracefully: a deliverable with no artifact `.md`, no frontmatter,
no `sources[]`, or only external/unresolvable references contributes no inferred edge.

## Stale diagnostic gate (non-terminal field-0 target)

`consult-action-fields` auto-wires each solution-field deliverable's `depends_on[]` to
the **positional terminal** (last entry) of the diagnostic field-0's `deliverables[]` —
the gate "depends on the diagnostic's conclusion". The wiring is positional; there is no
separate terminal marker. The idempotency guard deliberately leaves prior-session edges
alone, so if field-0 is re-planned **after** the gate was wired (a new deliverable
appended), the existing edge keeps pointing at the **former** terminal — a real
diagnostic deliverable, but no longer the conclusion. This is staleness, not breakage.

`deliverable-graph.py validate` surfaces it as a **stale diagnostic gate** advisory:

- It derives the current terminal by reading the diagnostic field's `field.json`
  (`deliverables[-1]` bearing a slug) and reports any solution-field → `diagnostic-as-is`
  edge whose target is not that terminal in `stale_diagnostic_gate_edges[]` /
  `stale_diagnostic_gate_edge_count`, plus a human-readable `warnings[]` entry, and
  **stays `success:true`** — like inferred edges, it never feeds cycle or dangling
  detection (those remain `depends_on`-only hard errors).
- It is **detect-only**: the lint never re-points the edge and never writes `field.json`
  — re-pointing the gate at the current terminal is an explicit author action. This
  preserves the leave-prior-edges-alone idempotency discipline (the lint makes the drift
  machine-detectable; it does not auto-repair) and the read-time `blocks[]` contract.
- When the engagement has no diagnostic field, or the diagnostic `field.json` is
  unreadable, the check skips silently — it never degrades the hard-error path.

## Cascade semantics

When an upstream deliverable changes, `cascade-stale` propagates the staleness to
everything downstream of it:

```bash
python3 scripts/deliverable-graph.py <engagement-dir> cascade-stale \
    market-evidence/market-sizing --trigger deliverable_update
```

- The **transitive downstream set** is computed by following the derived `blocks`
  relation from the named coordinate. The named (upstream) deliverable is itself
  **not** flagged — it is the fresh one; its dependents are.
- Each downstream deliverable's `lineage_status` is set via **read-modify-write**:
  the field's `field.json` is read, only the matching deliverable entries are
  updated, every sibling field (`slug`, `title`, `state`, `dt_stage`,
  `producing_route`, `persona_review`, …) is preserved, and the file is written
  back.
- The write is **idempotent.** A deliverable already carrying `status:"stale"` is
  left untouched (its original `flagged_at` survives), so re-running `cascade-stale`
  produces no new write and no churn. Only not-yet-stale dependents are flagged.

## Topological refresh semantics

`deliverable-graph.py refresh-order` takes the set of currently-stale deliverables
and groups them into **refresh layers** so they are reworked upstream-first:

- Layer 0 = stale deliverables with no stale dependency.
- Layer N = stale deliverables whose stale dependencies all sit in layers < N.

Refreshing layer by layer guarantees an upstream stale deliverable is reworked
before any stale deliverable that depends on it — there is no point refreshing a
dependent against an upstream that is itself about to change. A cycle among stale
deliverables makes layering undefined and is surfaced as an error.

## The flag-not-rewrite contract

This model **surfaces refresh candidates; it never auto-rewrites a deliverable.**
`cascade-stale` writes only the `lineage_status` flag — it never touches a
deliverable's `state`, `dt_stage`, or markdown artifact, and it never regenerates
content. Deciding whether (and how) to rework a stale deliverable is human work,
routed through the normal design-thinking loop. This mirrors cogni-knowledge's
`knowledge-refresh`, which flags syntheses for re-synthesis rather than silently
overwriting them. Non-destructive by design: the worst a wrong cascade can do is
raise a flag a human then clears.
