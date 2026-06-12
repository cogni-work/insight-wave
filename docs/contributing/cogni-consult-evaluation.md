# cogni-consult Evaluation — Dogfood Comparison vs cogni-consulting

cogni-consult (action-fields-as-WBS, design thinking per deliverable, acting
personas, one compounding knowledge base) is the evaluation candidate
alongside cogni-consulting (Double Diamond). This document is the evaluation
protocol and scorecard: one real engagement brief, run end-to-end through
both plugins, scored side-by-side against the six criteria defined in
[`cogni-consult/references/evaluation-criteria.md`](../../cogni-consult/references/evaluation-criteria.md).

**Status: protocol ready — results pending the live run.** Scores come from
a real, human-driven engagement run, not from a simulated one: an automated
pipeline scoring its own simulated engagement would manufacture exactly the
kind of evidence this evaluation exists to avoid. Every results cell is
marked `TBD — pending live run` until a maintainer executes the protocol.

**What this evaluation does not decide.** The completed scorecard is
evidence for a replace/archive decision about cogni-consulting — it is not
that decision. The decision itself is a separate human go/no-go gate, the
same maintainer-sign-off pattern the ecosystem uses for its other archival
gates. Until that gate is explicitly passed by a maintainer, cogni-consulting
remains active and untouched: this evaluation does not modify, deprecate, or
archive it, and nothing downstream may treat a filled scorecard as an
archival trigger.

## The two candidates

| | cogni-consult | cogni-consulting |
|---|---|---|
| Work structure | 3-6 action fields as the WBS; every deliverable lives in exactly one field | Five gated phases (scope → discover → define → develop → deliver) |
| Process rhythm | Design-thinking loop (empathize→define→ideate→prototype→test) per deliverable | One Double Diamond pass for the whole engagement |
| Personas | Acting personas challenge deliverables in their own voice before completion | Design-for personas + quality-gate personas evaluate at phase gates |
| Research | One cogni-knowledge base bound at setup; every run routes through it and compounds | One base bound per engagement; cogni-knowledge dispatched in the Discover phase, claims verified in Define/Deliver |
| Progress state | Per deliverable (in the field's `field.json` manifest) | Per phase (state machine in `consulting-project.json`) |
| Re-entry | `consult-resume`: WBS dashboard + single next action | `consulting-resume`: phase status + next step |

Both plugins are pre-1.0 (see each plugin's maturity callout).

## Protocol

1. **Pick one real brief.** A genuine consulting question the maintainer
   actually needs answered — not a toy. The brief must be rich enough to
   produce at least two deliverables in at least two action fields, so the
   research-compounding and persona-review criteria are exercised.
2. **Run cogni-consult end-to-end.** `consult-setup` → `consult-scope` →
   `consult-action-fields` → `consult-design-thinking` (per deliverable) →
   `consult-personas` review → leave the engagement for at least a day →
   `consult-resume`. Capture session notes as you go: interruptions, manual
   state repairs, dead ends, and anything that surprised you.
3. **Run cogni-consulting on the same brief.** The full Double Diamond
   (setup → scope → discover → define → develop → deliver), with its own
   resume check after the same break. Same note-taking discipline. Separate
   engagement directories — the runs share nothing.
4. **Score side-by-side.** Score each plugin on every criterion per the
   Scoring section of `evaluation-criteria.md`, citing concrete artifacts —
   file paths, not impressions.
5. **Keep artifacts local, summarize here.** Live engagement directories
   are not committed (repo convention: live runs stay out of the tree).
   The filled scorecard plus the cited excerpts in this file are the
   committed evidence of record.

## Scorecard

| # | Criterion | cogni-consult | cogni-consulting | Notes |
|---|---|---|---|---|
| 1 | Deliverable quality | TBD — pending live run | TBD — pending live run | |
| 2 | Scope sharpness | TBD — pending live run | TBD — pending live run | |
| 3 | Persona-challenge usefulness | TBD — pending live run | TBD — pending live run | |
| 4 | Research depth and compounding | TBD — pending live run | TBD — pending live run | |
| 5 | Consultant effort and flow | TBD — pending live run | TBD — pending live run | |
| 6 | Re-entry and resume clarity | TBD — pending live run | TBD — pending live run | |

### Per-criterion findings

To be filled from the live run — one subsection per criterion, each with the
score rationale and the artifact citations the protocol's step 4 requires.

**TBD — pending live run.**

## After the run

A filled scorecard feeds the maintainer's replace/archive go/no-go gate on
cogni-consulting. Three outcomes are possible, and all three are maintainer
calls, not automated ones:

- **Evidence favors cogni-consult** — the maintainer may open the archival
  gate for cogni-consulting.
- **Evidence favors cogni-consulting** — cogni-consult is frozen or
  re-scoped; the comparison stands as the record of why.
- **Evidence is mixed or thin** — both plugins stay active and the protocol
  is re-run on a second brief before any decision.
