---
name: frameworks-registry
description: Canonical thin registry of consulting structuring frameworks — stable slug, terse structure signature, when-to-use, and deliverable-/field-type affinity. The key for deterministic framework selection at deliverable creation, not a teaching catalog.
---

# Frameworks Registry

When a deliverable is created, the consultant picks a **structuring framework**
— the shape the deliverable's argument takes. This registry pins each framework
to a stable `slug` so the stored choice on a deliverable is a deterministic key
rather than free text, alongside a one-line structure signature, a one-line
when-to-use, and its affinity to the deliverable types and field types in
[deliverable-types.md](deliverable-types.md).

It is deliberately **thin, not a teaching catalog**: the model supplies each
framework's depth at runtime, and where a framework already has a first-party
page elsewhere in the ecosystem the `slug` cell links to it instead of
duplicating. The registry only stabilises the key and the affinity so top-N
selection is reproducible.

## Framework Catalog

| Slug | Structure signature | When to use | Deliverable-type affinity | Field-type affinity |
|---|---|---|---|---|
| `pyramid-principle` | Answer first, then MECE-grouped supporting arguments | Structuring any recommendation top-down for leadership | Executive Summary, Strategic Options Brief, Business Case | `strategy`, `execution` |
| `mece-issue-tree` | Mutually-exclusive, collectively-exhaustive decomposition tree | Breaking a problem into non-overlapping, complete branches | Strategic Options Brief, Canvas Stress-Test Report | `analysis`, `strategy` |
| `hypothesis-driven` | Lead hypothesis → test against evidence → confirm or revise | Focusing research on a falsifiable claim before boiling the ocean | Market Assessment, Lean Canvas | `evidence`, `analysis` |
| `scqa` | Situation → Complication → Question → Answer | Framing a problem narrative that sets up a recommendation | Executive Summary, Solution Brief | `strategy` |
| `bluf` | Bottom line up front, supporting detail after | Time-poor leadership reads and fast decisions | Executive Summary, Decision Board | `strategy`, `execution` |
| `inverted-pyramid` | Most important first, descending detail | Skimmable, news-style briefs and summaries | Executive Summary, Market Assessment | `evidence`, `strategy` |
| `2x2-matrix` | Two decision axes → four positioned quadrants | Positioning options or scenarios on the two dimensions that matter | Scenario Matrix, Portfolio Snapshot, Decision Board | `analysis`, `strategy` |
| `options-trade-off` | Options × weighted criteria → ranked comparison | Comparing alternatives against explicit decision criteria | Strategic Options Brief, Decision Board | `strategy` |
| [`scenario-planning`](../../cogni-workspace/skills/text-to-narrative/references/arc-registry.md) | Signals → scenarios → strategies → decisions | Planning under deep uncertainty with multiple plausible futures | Scenario Matrix, Transformation Roadmap | `analysis`, `strategy` |
| `journey-process` | Sequential stages or steps along a path | Mapping a process, customer journey, or phased rollout | Action Roadmap, Action Plan, Transformation Roadmap | `execution` |
| `fab` | Feature → Advantage → Benefit | Translating capabilities into buyer-facing value | Solution Brief, Lean Canvas | `strategy` |
| `psb` | Problem → Solution → Benefit | Pitching a solution against a stated need | Solution Brief, Business Case | `strategy` |
| `star` | Situation → Task → Action → Result | Evidence narratives, case examples, and track-record proof | Claim Verification Log, Canvas Stress-Test Report | `evidence`, `analysis` |

## Using the Registry

When recommending a framework at deliverable creation (consumed by
deliverable-selection logic, tracked under the engagement's framework choice):

1. Read the deliverable's type and its field's type, then shortlist frameworks
   whose **deliverable-type affinity** or **field-type affinity** matches.
2. Recommend from the shortlist and store the chosen framework's `slug` as the
   stable key — never the display name or free text.
3. Where the `slug` cell links to a first-party page, follow it for the
   framework's depth; the registry intentionally does not restate it.
4. Affinity is a starting recommendation, not a constraint — the consultant can
   pick any framework, and engagement-specific structures outside this registry
   are normal. Give a new structure a clear kebab-case `slug` like any other.

The registry pins *which* structuring shape and its stable key; the model
supplies the framework's substance at runtime, and `deliverable-types.md` owns
*what* deliverable to produce per field.
