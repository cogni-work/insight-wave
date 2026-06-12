# Evaluation Criteria — cogni-consult vs cogni-consulting

cogni-consult exists to be evaluated against cogni-consulting (Double Diamond)
on real engagements. This file defines the six comparison criteria that
evaluation uses, each with a concrete, observable pass signal. The criteria
are derived from the plugin's own testable claims (research compounds,
deliverable-level state, acting personas challenge before delivery, fair
comparison on never-shared engagement directories) so the evaluation measures
what the plugin promises, not what a generic rubric happens to ask.

**What this file does not decide.** A completed evaluation produces evidence,
nothing more — the replace/archive decision for cogni-consulting is a separate
human go/no-go gate, and cogni-consulting stays untouched during the
comparison. The canonical statement of that gate policy lives in the
evaluation write-up
([`docs/contributing/cogni-consult-evaluation.md`](../../docs/contributing/cogni-consult-evaluation.md)).

## How the criteria are applied

One brief, two runs: the same engagement brief is run end-to-end through each
plugin, and each criterion below is scored side-by-side from the artifacts
and session notes of both runs.

## The six criteria

### 1. Deliverable quality

Whether the artifacts a client would actually receive are evidence-grounded,
actionable, and challenge-hardened.

**Observe:** the completed deliverable artifacts
(`action-fields/{field-slug}/{deliverable-slug}.md` vs the Double Diamond
phase outputs for the same brief).

**Pass signal:** every completed cogni-consult deliverable carries YAML
frontmatter with `sources[]` lineage (knowledge-base claims via `kb_ref`) and
a `## Persona Challenges` section in which every challenge is dispositioned;
and a blind side-by-side read of the same-brief deliverable pair rates the
cogni-consult artifact equal or better on evidence grounding and
actionability.

### 2. Scope sharpness

Whether the SMART key question, the five scoping dimensions, and the
action-field WBS produce a scope that is sharp enough to work from — the
Quality Signals in `references/methods/scope-dimensions.md` made binding.

**Observe:** `scope/key-question.md` after consult-scope completes, and
whether the WBS holds up during execution.

**Pass signal:** all four Quality Signals in
`references/methods/scope-dimensions.md` hold, confirmed downstream by every
deliverable landing in exactly one field with no mid-engagement re-scoping.

### 3. Persona-challenge usefulness

Whether acting personas change the work, rather than decorating it. The
comparison baseline is cogni-consulting's quality-gate personas, which
evaluate at phase gates but do not act.

**Observe:** the `## Persona Challenges` sections, persona `work_log`
entries, and the artifact diffs before/after persona review.

**Pass signal:** for each reviewed deliverable, at least one persona
challenge is accepted and produces a concrete revision to the artifact before
it counts as complete — challenges are neither uniformly rejected (noise) nor
uniformly accepted without edits (rubber stamp).

### 4. Research depth and compounding

Whether the one-base-per-engagement knowledge spine measurably compounds:
later research builds on earlier syntheses instead of re-crawling.

**Observe:** the bound knowledge base, the per-field `research/` directories,
and the pipeline rung each research run used (per
`references/research-routing.md`).

**Pass signal:** a later deliverable's empathize-stage `knowledge-query`
returns relevant hits from an earlier deliverable's research (the quick
gap-check or `--source wiki` rung suffices where a fresh engagement would
have needed a full crawl), and every research-backed claim in a deliverable
carries a `kb_ref` resolving to a page in the engagement's base.

### 5. Consultant effort and flow

Whether the consultant spends the session on content decisions instead of
process plumbing.

**Observe:** session notes from both runs — interruptions, manual state
repairs, workarounds, dead ends.

**Pass signal:** a deliverable travels empathize→test without any manual
edit to `field.json` / `consult-project.json` or other process workaround,
and the session notes record zero consultant interventions whose purpose was
fixing engagement state rather than improving content.

### 6. Re-entry and resume clarity

Whether a cold session can orient and continue without archaeology.

**Observe:** a consult-resume invocation after at least one day away from
the engagement, compared with cogni-consulting's resume on the same-brief
run.

**Pass signal:** the resume dashboard correctly shows which deliverables are
mid-loop, which await persona review, and what to pick up next, and its
single next-action recommendation matches what the consultant would have
chosen — all without opening any state file by hand.

## Scoring

Each criterion is scored **pass / partial / fail** for each plugin, with a
one-paragraph rationale citing artifacts. A criterion with no observable
evidence (for example, a run that never reached persona review) is scored
**not exercised**, never inferred. The protocol and the filled scorecard live
in
[`docs/contributing/cogni-consult-evaluation.md`](../../docs/contributing/cogni-consult-evaluation.md);
this file stays the stable definition the scorecard points back to.
