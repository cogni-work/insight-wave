# Closed Storytelling Review Loop — Authoring Methodology

This document is an **authoring-time** record, not a runtime feature. It
captures the closed-loop review process used to harden the storytelling
guidance baked into `trend-synthesis/SKILL.md`. The methodology mirrors
`skill-creator`'s iterate-against-evals pattern, with a domain-specific
reviewer in the grader role: `cogni-narrative:narrative-reviewer`, treated
as a storytelling expert that scores prose against narrative quality gates
(structural, critical, evidence, structure, language) and returns the top
three improvements.

At runtime, `trend-synthesis` is expected to produce a story-arc-strong
report on the first pass. The loop captured here was the process used to
make that the case.

## The pattern

1. Snapshot the current SKILL.md.
2. The storytelling reviewer scores the SKILL.md treated as a meta-narrative
   (instructions for how the report should land), or — when there is a
   sample report — scores the report itself.
3. Map each of the top three improvements to the SKILL.md sections that
   produced the weak guidance, then edit those sections.
4. Re-score. The loop terminates when `overall_score >= 75` and no gate is
   marked `fail`, or when the iteration cap is reached.

## Iteration log — first pass

### Iteration 1

```json
{
  "overall_score": 62,
  "grade": "D",
  "gates": {
    "structural": "warn",
    "critical":   "fail",
    "evidence":   "pass",
    "structure":  "warn",
    "language":   "warn"
  },
  "top_improvements": [
    "The 4 dimensions form a taxonomy, not a story arc — the reader gets four parallel essays plus a closer. The report needs a single CxO arc that ties Forces → Impact → Horizons → Foundations into rising tension.",
    "Theme-cases mechanise Stake / Move / Cost-of-Inaction without a protagonist or a named obstacle, so the prose risks reading as a feature list. Recast each theme-case as a micro-story with protagonist, obstacle, stakes, move, payoff.",
    "There are no transitions between dimension sections and no callback in the closer. The Capability Imperative needs to land back on the opener's Why-Now, not just sum up."
  ]
}
```

**Edits applied:**

- Added a new **Storytelling Spine** section after Workflow Overview that
  assigns each dimension a story role (inciting incident, rising tension,
  decision threshold, capability test) and a reader question.
- Augmented the theme-case writer prompt (Step 2.1) with explicit
  `STORY_PROTAGONIST`, `STORY_OBSTACLE`, `STORY_MOMENT`, and
  `STORY_PAYOFF_HANDOFF` fields so the Stake / Move / Cost-of-Inaction
  beats become the load-bearing structure *underneath* a micro-story —
  not the surface.
- Added a bridge-sentence requirement to dimension composers (Step 2.2)
  with three transition templates (causal, contrastive, escalating).
- Added a Why-Now hook requirement to the executive summary (Step 2.3) and
  a callback requirement to the Capability Imperative (Step 2.5).

### Iteration 2

```json
{
  "overall_score": 78,
  "grade": "B-",
  "gates": {
    "structural": "pass",
    "critical":   "warn",
    "evidence":   "pass",
    "structure":  "pass",
    "language":   "warn"
  },
  "top_improvements": [
    "The protagonist exists but stays abstract — 'the CxO'. Name the operating leader by role and decision context.",
    "The three bridge templates are correct but the composer prompt risks producing them as a checklist. Make composers choose, and require variation across the four dimensions.",
    "Theme-cases would benefit from a one-line 'story moment' — a sensory or behavioural detail that grounds the abstract capability in lived reality."
  ]
}
```

**Edits applied:**

- Hardened the protagonist convention in the Storytelling Spine: "the head
  of after-sales watching warranty cost ratios drift" — never abstract.
  Mirrored in the Why-Now hook requirement in Step 2.3.
- Reframed the three bridge templates as patterns the composer
  *chooses among*, with an explicit "patterns must vary across the four
  dimensions" rule and a `Error Handling` row that warns if all four
  bridges share a template.
- Added a `STORY_MOMENT` field to the theme-case writer prompt, hard-bound
  to a specific `evidence_ref` from `EXAMPLE_REFERENCES` to prevent
  invention. Validation extended with `story_moment_evidence_ref` non-empty.

### Iteration 3 — convergence

```json
{
  "overall_score": 84,
  "grade": "B+",
  "gates": {
    "structural": "pass",
    "critical":   "pass",
    "evidence":   "pass",
    "structure":  "pass",
    "language":   "pass"
  },
  "top_improvements": [
    "Optional follow-up: also pull at least two STORY_PAYOFF_HANDOFF phrases into the Capability Imperative as recurring motifs, so the synthesis feels like the cases converging on one capability rather than four cases summarised. (Promoted to a hard requirement in Step 2.5.)"
  ]
}
```

The single optional follow-up was promoted into Step 2.5 as a hard
requirement. Loop terminated at iteration 3 with score 84/100, all gates
pass.

## How to re-run the loop

The same methodology can be re-applied whenever the storytelling guidance
drifts (new audience, new arc, new evidence pattern):

1. Snapshot the current SKILL.md and a representative sample report.
2. Run `cogni-narrative:narrative-reviewer` on the report (or, in a
   code-only review, on the SKILL.md itself treated as a meta-narrative
   about how the report should land). Persist the scorecard.
3. Apply the top three improvements to the *writer/composer prompts* and
   the *Storytelling Spine* in this SKILL.md — not to runtime behaviour.
4. Re-score. Terminate when the scorecard passes or when the same gate
   keeps failing across iterations (that's a signal the underlying inputs
   need attention, not the prose guidance).
5. Append the new iteration block below this one — this file is the audit
   trail.

## Why this is authoring-time, not runtime

An earlier draft considered baking the loop into trend-synthesis as a
runtime "Phase 2.8" that re-dispatched writers when a reviewer flagged
prose. That draft was discarded for two reasons:

- **Cost.** Each runtime review + targeted re-dispatch adds a turn of
  reviewer + 1–N writer agents. Hardening the SKILL.md once at authoring
  time is a one-time investment that pays back across every subsequent
  invocation.
- **Confounding signals.** When a runtime loop rewrites prose to chase a
  reviewer score, the writer agent can't tell whether weak prose is its
  fault (use the spine harder) or the inputs' fault (the value-model has a
  thin theme). Authoring-time review keeps that signal clean: when the
  guidance fails, the spine is the variable; at runtime, only the inputs
  are.

`/verify-trend-report` (a sibling skill in this plugin) handles
*post-generation* claim verification and structural review against
evidence — that loop *belongs* at runtime because the evidence binding has
to be checked per report. Storytelling shape, by contrast, is a property
of the instructions and only needs to be re-verified when the
instructions change.
