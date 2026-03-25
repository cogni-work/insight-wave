---
name: Lean Canvas Stress-Test
phase: deliver
type: convergent
inputs: [lean-canvas-document, discovery-synthesis, engagement-constraints]
outputs: [stress-test-report, refined-lean-canvas-document]
duration_estimate: "30-60 min (parallel persona agents + synthesis)"
requires_plugins: []
---

# Lean Canvas Stress-Test

Run a Lean Canvas through parallel persona-based evaluation to surface blind spots that a single-perspective review would miss. Each persona evaluates the canvas against 5 weighted criteria specific to their role, then a synthesis step identifies cross-cutting themes and prioritizes improvements.

## When to Use

- When the engagement has produced a Lean Canvas and needs to validate it before finalizing
- Essential for: business-model-hypothesis
- Valuable for: market-entry, innovation-portfolio

## Guided Prompt Sequence

### Step 1: Load the Canvas

Read `develop/lean-canvas.md`. Verify it has the expected lean canvas structure (9 numbered sections). If YAML frontmatter is missing, infer section status using the rules in `$CLAUDE_PLUGIN_ROOT/references/canvas-format.md`.

Also load engagement context:
- `define/problem-statement.md`
- `discover/competitive/summary.md` (if exists)
- `consulting-project.json`

### Step 2: Select Personas

Four built-in canvas stress-test personas:

| Persona | Perspective | Reference |
|---|---|---|
| **Investor** | Fundability — market, economics, defensibility | `$CLAUDE_PLUGIN_ROOT/references/personas/canvas/investor.md` |
| **Target Customer** | Desirability — problem fit, willingness to pay, switching costs | `$CLAUDE_PLUGIN_ROOT/references/personas/canvas/target-customer.md` |
| **Technical Co-founder** | Buildability — feasibility, architecture, MVP scope | `$CLAUDE_PLUGIN_ROOT/references/personas/canvas/technical-cofounder.md` |
| **Operations & Finance** | Viability — costs, margins, operational scaling | `$CLAUDE_PLUGIN_ROOT/references/personas/canvas/operations-finance.md` |

**Default**: Run all 4 personas. If the consultant requests a subset, run only those.

**Single-persona mode**: When the consultant's phrasing implies one perspective, run only that persona. Omit Cross-Cutting Themes; add a "Deeper Analysis" subsection instead.

**Multi-persona mode**: Confirm personas before launching.

### Step 3: Launch Parallel Persona Analysis

Launch one Task agent per selected persona. Each agent reads the canvas file, its persona profile, and the section reference via file paths.

**For each persona, launch a Task with this prompt:**

```
You are a {PERSONA_NAME} evaluating a Lean Canvas. Read the files below, then evaluate the canvas strictly from your perspective.

FILES TO READ (use Read tool):
1. Canvas: {project-dir}/develop/lean-canvas.md
2. Your persona profile: {absolute path to references/personas/canvas/{persona}.md}
3. Section reference: {absolute path to references/lean-canvas-sections.md}

INSTRUCTIONS:
1. Read all 3 files
2. Adopt the tone described in your persona profile
3. Evaluate each of your 5 criteria, assigning PASS / WARN / FAIL
4. For each criterion, provide specific evidence from the canvas (quote or reference the relevant section)
5. Calculate your weighted score: PASS=1.0, WARN=0.5, FAIL=0. Multiply each verdict by criterion weight and sum
6. Generate 3-5 questions that a real {PERSONA_NAME} would ask after reading this canvas
7. Identify the single most important improvement from your perspective
8. List 2-3 key assumptions you'd want validated

OUTPUT FORMAT (Markdown):

## {PERSONA_NAME} Evaluation

### Criteria Assessment

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| {criterion 1} | {weight}% | {PASS/WARN/FAIL} | {specific evidence from canvas} |
| ... | ... | ... | ... |

**Score**: {weighted score}/1.0

### Top Questions
1. {Question}
2. ...

### Critical Improvement
{The single most important thing to fix}

### Key Assumptions
- {Assumption} — {one-line rationale}
- ...
```

**Agent configuration**: Use a fast model (haiku or sonnet). Read tool only. Launch all persona agents in the same turn for parallel execution.

### Step 4: Synthesize Results

Once all persona agents return, synthesize using `$CLAUDE_PLUGIN_ROOT/references/methods/lean-canvas-synthesis-protocol.md`.

**Process:**
1. Collect all persona results
2. Identify cross-cutting themes using semantic matching
3. Apply priority escalation (3+ personas = CRITICAL; 2 personas = HIGH; customer + any = CRITICAL)
4. Route themes to canvas sections
5. Resolve conflicts using tiebreaker hierarchy (customer > investor > technical > operations)
6. Merge recommendations by section
7. Separate "fix in canvas" from "validate externally"

### Step 4b: Wild-Card Risks

Identify 2-3 risks outside persona criteria that matter to the canvas author:
- Licensing or regulatory risks
- Adoption barriers
- Concentration risks
- Ecosystem dependencies
- Market timing risks

### Step 5: Present the Report

Output the stress-test report using the structure in the synthesis protocol (Output Structure section):
- Per-persona scores with weighted scores
- Cross-cutting themes (CRITICAL -> HIGH -> OPTIONAL, max 3 per level)
- Wild-card risks
- Prioritized questions
- Validation roadmap mapping assumptions to downstream skills
- Suggested next steps

Save the report to `deliver/canvas-stress-test.md`.

### Step 6: Apply Improvements (Optional)

If the consultant wants to apply improvements:
1. Confirm which recommendations to apply
2. Edit `develop/lean-canvas.md` sections as confirmed
3. Bump version, update date and status
4. Append evolution log entry noting stress-test findings
5. Save the updated canvas

## Integration with Deliver Workflow

After the stress-test, the engagement continues with other Deliver methods:
- **Opportunity scoring** can use the stress-test scores to evaluate the canvas viability
- **Claims verification** (cogni-claims) can verify factual assertions in the canvas
- **Executive summary** synthesizes the canvas with the stress-test verdict

The canvas stress-test verdict feeds into the engagement's final recommendation:
- High scores across personas -> recommend proceeding to portfolio/execution
- Mixed scores -> recommend targeted validation before committing resources
- Low scores -> recommend pivoting or killing the hypothesis

## Output Format

Save report as `deliver/canvas-stress-test.md`. Updated canvas (if improvements applied) saved to `develop/lean-canvas.md`.

## Important Notes

- Persona evaluations should be honest, even if harsh
- The target-customer persona is most important for early-stage canvases
- Don't fabricate market data — flag gaps for validation via cogni-portfolio
- For Draft-maturity canvases, expect mostly FAIL results — this is useful signal
