---
name: consulting-develop
description: |
  Execute the Develop phase of a Double Diamond engagement — diverge to generate and explore solution
  options. Dispatches to cogni-trends value-modeler and cogni-portfolio for proposition modeling.
  Use whenever the user wants to brainstorm solutions, generate options, or explore alternatives
  within a diamond engagement. Trigger on: "generate options", "what could we do", "solution ideas",
  "brainstorm solutions", "develop phase", "explore alternatives", "scenario planning",
  "model the propositions", "what are our options", "create strategic choices",
  "develop solutions", "D2 diverge", "option generation", "how could we solve this",
  "let's get creative", "value modeling", "solution space", or any request to generate solution
  options after a problem has been defined. Also trigger when the user proposes a specific solution —
  this skill ensures it's evaluated alongside alternatives rather than adopted uncritically.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Task
---

# Diamond Develop — Diverge to Create Options

Generate and explore solution options that address the problem statement from Define. This is the first phase of Diamond 2 — the goal is to create a rich option space before converging on the best path in Deliver.

## Core Concept

Develop is the creative engine of the engagement. With a clear problem statement and HMW questions from Define, this phase generates multiple possible solutions — not just the obvious one. Good consulting surfaces options the client hadn't considered, challenges "we've always done it this way" thinking, and creates genuine strategic choices.

The key principle: **generate before evaluating**. Evaluating during generation kills options prematurely — an idea that sounds weak in isolation may become the strongest when combined with another. Develop creates the option space; Deliver evaluates it.

## Prerequisites

- Define phase should be complete (problem statement and HMW questions exist)
- Read `define/problem-statement.md` and `define/hmw-questions.md` as the brief for this phase

## Workflow

### 1. Load Context

Read consulting-project.json, `define/problem-statement.md`, and `define/hmw-questions.md`.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop in-progress
```

### 2. Propose Develop Methods

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the vision class's recommended Develop methods.

**Plugin-powered methods**:

| Method | Plugin | What It Produces |
|---|---|---|
| Value modeling | cogni-trends | TIPS paths from trends to solutions, ranked by business relevance |
| Proposition modeling | cogni-portfolio | IS/DOES/MEANS messaging for Feature × Market pairs |
| Solution design | cogni-portfolio | Implementation phases and pricing tiers |

**Guided methods**:

| Method | What It Produces | Reference |
|---|---|---|
| Scenario planning | 2-4 future scenarios with implications | `references/methods/scenario-planning.md` |
| Opportunity scoring | Scored option matrix with criteria | `references/methods/opportunity-scoring.md` |
| Lean canvas authoring | Research-backed business model hypothesis | `references/methods/lean-canvas-authoring.md` |
| Lean canvas refinement | Iterative canvas improvement | `references/methods/lean-canvas-refinement.md` |

**Note**: Lean canvas methods are recommended for `business-model-hypothesis`, `market-entry`, `innovation-portfolio`, and `gtm-roadmap` vision classes. For `business-model-hypothesis`, the lean canvas IS the primary Develop output (replacing proposition modeling and option synthesis). Read `$CLAUDE_PLUGIN_ROOT/references/methods/lean-canvas-authoring.md` for the full guided workflow.

**Note**: For `how-might-we` engagements, guided ideation IS the primary Develop method — skip value modeling (step 3) and proposition modeling (step 4/4b) entirely. See the "Lightweight Develop" section below.

Ask: "Which methods do you want for option generation? I recommend [2-3 based on vision class]. You can adjust."

### 3. Value Modeling (cogni-trends)

If the engagement has a tips project from Discovery (check `plugin_refs.tips_project`):

1. Dispatch `cogni-trends:value-modeler` on the existing trend candidates
2. The value modeler translates trend candidates into TIPS paths (Trend → Implication → Possibility → Solution)
3. Solutions are ranked by business relevance score
4. Store value model outputs in `develop/options/tips-solutions.md`

If no tips project exists, offer to run `trend-scout` first or skip this method.

### 4. Proposition Modeling (cogni-portfolio)

If the engagement has a portfolio project (check `plugin_refs.portfolio_project`):

1. Ensure features and markets are defined (from Discovery competitive baseline)
2. Dispatch `cogni-portfolio:propositions` for Feature × Market pairs
3. Each proposition generates IS (what it is), DOES (what advantage it creates), MEANS (what benefit the buyer gets)
4. Optionally dispatch `cogni-portfolio:solutions` for implementation phasing
5. Store proposition summaries in `develop/propositions/`

If no portfolio exists, offer to set one up or skip.

### 4b. Proposition Quality Gate

If step 4 produced propositions (i.e., `develop/propositions/` has content), run a mandatory quality review before continuing. This gate catches vague messaging, unsupported market claims, and broken IS-DOES-MEANS chains before they contaminate Option Synthesis. If no propositions were generated (portfolio was skipped), skip this step.

#### 4b-i. Launch Parallel Persona Review

Launch 2 Task agents in parallel (same turn). Each agent reads:

- `develop/propositions/` directory
- `define/problem-statement.md` (for buyer pain point traceability)
- Discovery competitive baseline (e.g., `discover/competitive/summary.md`)
- `consulting-project.json`
- Their persona profile from `$CLAUDE_PLUGIN_ROOT/skills/consulting-develop/references/personas/`

| Persona | Profile | Primary Focus |
|---|---|---|
| Proposition Analyst | `personas/proposition-analyst.md` | IS/DOES/MEANS messaging quality, differentiation, buyer relevance |
| Market Validator | `personas/market-validator.md` | Segment precision, competitive position, evidence grounding |

**Task prompt template**:

> You are a {PERSONA_NAME} reviewing the Feature x Market propositions of a Double Diamond consulting engagement. Read your persona profile at {PERSONA_PATH} for your evaluation criteria, mindset, and tone.
>
> Read these artifacts:
> - Propositions: {PROJECT_DIR}/develop/propositions/ (all files)
> - Problem statement: {PROJECT_DIR}/define/problem-statement.md
> - Competitive baseline: {PROJECT_DIR}/discover/competitive/summary.md (if exists)
> - Engagement config: {PROJECT_DIR}/consulting-project.json
>
> Evaluate each proposition against your 5 criteria. For each criterion, assign PASS/WARN/FAIL with specific evidence. When evaluating competitive distinctness or market positioning, you MUST cross-reference the competitive baseline and cite specific competitors by name. Calculate your weighted score per proposition. Then generate 3-5 questions and identify your most critical concern.
>
> Respond in {LANGUAGE} (technical terms in English).

**Agent configuration**: Use a fast model (haiku or sonnet), Read tool only.

#### 4b-ii. Evaluate and Decide

After both persona agents complete, read `$CLAUDE_PLUGIN_ROOT/skills/consulting-develop/references/proposition-review-protocol.md` and apply:

1. Calculate per-persona scores for each proposition
2. Assign per-proposition status:
   - **APPROVED**: All criteria PASS or WARN — enters Option Synthesis
   - **CONDITIONAL**: Minor issues noted — enters Option Synthesis with improvements logged
   - **BLOCKED**: Any FAIL on a criterion weighted >= 25% — excluded from Option Synthesis
3. Identify cross-proposition themes using semantic matching
4. Resolve conflicts: Proposition Analyst wins on messaging quality, Market Validator wins on market fit

#### 4b-iii. Iterate (if needed)

If any propositions are BLOCKED:

1. Identify specific revisions needed (e.g., sharpen IS statement, add competitive evidence to DOES, narrow market segment)
2. Apply revisions to the affected propositions in `develop/propositions/`
3. Re-run only the persona(s) that flagged FAIL — don't repeat the full review
4. Maximum 2 iteration rounds

After round 2, any still-BLOCKED propositions are **excluded** from Option Synthesis. Present the exclusion list to the consultant:

> **Proposition quality gate results:**
> - N propositions APPROVED
> - N propositions CONDITIONAL (improvements noted)
> - N propositions BLOCKED and excluded
>
> Blocked propositions: [list with one-line reason each]
>
> You can reinstate any blocked proposition with an explicit rationale. Otherwise, Option Synthesis will proceed with the approved and conditional propositions only.

If the consultant reinstates a blocked proposition, log the override with their rationale in the decision log.

Save results to `develop/proposition-review.md`.

### 5. Scenario Planning (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/scenario-planning.md` and guide the consultant:

1. Identify 2 critical uncertainties from the problem statement
2. Create a 2×2 matrix using these uncertainties as axes
3. Name and describe 4 resulting scenarios
4. For each scenario, assess: implications for the client, required capabilities, risk profile
5. Map existing options from value modeling against scenarios

Save to `develop/scenarios/scenario-matrix.md`.

### 6. Option Synthesis

After all methods complete, synthesize the options. Use only APPROVED and CONDITIONAL propositions from the quality gate (step 4b) — BLOCKED propositions are excluded unless the consultant reinstated them.

1. Consolidate solutions from TIPS value modeling, approved portfolio propositions, and scenario analysis
2. Group into 3-7 distinct strategic options
3. For each option, capture:
   - **Name**: Short, descriptive label
   - **Description**: What this option entails
   - **Source**: Which method surfaced it (TIPS, portfolio, scenario)
   - **Alignment**: Which HMW question(s) it addresses
   - **Key assumptions**: What must be true for this to work
   - **Quality gate notes** (if sourced from a CONDITIONAL proposition): List the outstanding improvements flagged in step 4b that have not yet been addressed. These carry forward as known limitations until Deliver resolves them.
4. Present the option space to the consultant for review

Save to `develop/options/option-synthesis.md`.

**Example option entry** (digital-transformation engagement for field service):
> **Option 3: "Mobile-First Field Platform"**
> Build a unified mobile app replacing 4 legacy field tools. Technicians get real-time job scheduling, parts inventory, and customer history in one interface.
> *Source*: TIPS value modeling (mobile workforce trend) + portfolio proposition (field service × mid-market)
> *Alignment*: HMW #1 (reduce time-to-resolution) and HMW #3 (improve first-visit fix rate)
> *Key assumptions*: Field technicians have reliable mobile connectivity; legacy systems expose APIs for integration.

Present options as equals — ranking happens in Deliver with structured criteria and consultant judgment.

### 7. Stakeholder Review

Before transitioning to Deliver, stress-test the option space through multi-persona review. This closed-loop quality gate catches issues with feasibility, creative breadth, user grounding, and strategic alignment before the engagement commits to evaluating specific options.

#### 7a. Launch Parallel Persona Review

Launch 4 Task agents in parallel (same turn), one per persona. Each agent reads:

- `develop/options/option-synthesis.md`
- `develop/options/tips-solutions.md` (if exists)
- `develop/propositions/` directory (if exists)
- `develop/scenarios/scenario-matrix.md` (if exists)
- `define/problem-statement.md` and `define/hmw-questions.md` (for alignment checking)
- `consulting-project.json`
- The persona's own profile from `$CLAUDE_PLUGIN_ROOT/skills/consulting-develop/references/personas/`

**Personas and their focus**:

| Persona | Profile | Primary Focus |
|---|---|---|
| Engagement Sponsor | `personas/engagement-sponsor.md` | Strategic alignment, fundability, genuine choice |
| Solution Architect | `personas/solution-architect.md` | Technical feasibility, architectural distinctness, constraint adherence |
| Innovation Strategist | `personas/innovation-strategist.md` | Creative breadth, assumption challenge, cross-pollination |
| End-User Advocate | `personas/end-user-advocate.md` | User value, adoption realism, user-facing risk |

Each persona evaluates 5 weighted criteria (weights sum to 100%), assigns PASS/WARN/FAIL verdicts, calculates a weighted score, generates 3-5 stakeholder questions, identifies their most critical improvement, and lists 2-3 key assumptions to test.

**Task prompt template**:

> You are a {PERSONA_NAME} reviewing the Develop phase outputs of a Double Diamond consulting engagement. Read your persona profile at {PERSONA_PATH} for your evaluation criteria, mindset, and tone.
>
> Read these artifacts:
> - Option synthesis: {PROJECT_DIR}/develop/options/option-synthesis.md
> - TIPS solutions: {PROJECT_DIR}/develop/options/tips-solutions.md (if exists)
> - Propositions: {PROJECT_DIR}/develop/propositions/ (if exists)
> - Scenario matrix: {PROJECT_DIR}/develop/scenarios/scenario-matrix.md (if exists)
> - Problem statement: {PROJECT_DIR}/define/problem-statement.md
> - HMW questions: {PROJECT_DIR}/define/hmw-questions.md
> - Engagement config: {PROJECT_DIR}/consulting-project.json
>
> Evaluate the option space against your 5 criteria. For each criterion, assign PASS/WARN/FAIL with specific evidence. Calculate your weighted score. Then generate 3-5 questions, identify your most critical improvement, and list 2-3 key assumptions.
>
> Respond in {LANGUAGE} (technical terms in English).

#### 7b. Synthesize & Decide

After all 4 persona agents complete, read `$CLAUDE_PLUGIN_ROOT/skills/consulting-develop/references/review-protocol.md` and apply:

1. Calculate per-persona weighted scores
2. Identify cross-cutting themes using semantic matching rules
3. Apply priority escalation rules (3+ personas = CRITICAL; specific persona pairs = CRITICAL)
4. Route themes to specific Develop artifacts
5. Resolve conflicts using the tiebreaker hierarchy: Sponsor > End-User Advocate > Solution Architect > Innovation Strategist
6. Merge recommendations by artifact

#### 7c. Iterate (if needed)

If CRITICAL themes are found:

1. Identify specific revisions needed for each affected artifact
2. Apply revisions (e.g., add a stretch option, improve source traceability, add user value articulation)
3. Re-run only the persona(s) that flagged CRITICAL issues — don't repeat the full review
4. Maximum 2 iteration rounds — prevents infinite loops
5. After round 2, present any remaining issues to the consultant for decision regardless of severity

Save review results to `develop/review-summary.md`.

### 8. Log and Transition

Update method log and decision log.

Present the Develop summary:

> **Develop phase complete.**
> - TIPS solutions generated: N (top 3: ...)
> - Propositions modeled: N Feature × Market pairs
> - Proposition quality gate: N approved, N conditional, N blocked [N reinstated by consultant]
> - Scenarios mapped: 4 (2×2 matrix)
> - Strategic options synthesized: N
> - Review: [PASSED / PASSED with observations / PASSED after N revision rounds]
>
> Ready to move to Deliver? The final phase will evaluate options, verify claims, build the business case, and generate deliverables.

Mark Develop complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop complete
```

## Develop for how-might-we

For `how-might-we` engagements, replace the plugin-powered pipeline with a guided ideation session. This is the creative heart of the engagement — the consultant designs the solution interactively.

**Engage with the domain, not just the process.** The ideation should reflect knowledge of the subject matter. For a Drama Triangle workshop: propose specific exercise formats (role-play triads, case-based fishbowl, Empowerment Dynamic shift practice). For a B2C product: reference relevant business models, distribution patterns, pricing approaches. Domain-specific suggestions spark better ideas than generic "brainstorm solutions" prompts.

**Workflow (scales with complexity):**

1. **Load context** — Read the refined HMW question(s) from `define/hmw-questions.md` and the discovery synthesis. If desk research was run, read the research summary for domain grounding.
2. **Run guided ideation** — Read `$CLAUDE_PLUGIN_ROOT/references/methods/guided-ideation.md` and facilitate:
   - Diverge: generate 10-20 ideas, using domain-specific creative constraints (not just generic "what if budget were zero?" but "what if participants had to teach each other instead of learning from a facilitator?")
   - Cluster: group ideas into 3-6 themes
   - Converge: select top 2-3 ideas based on impact, feasibility, and energy
   - Sketch: flesh each into a domain-appropriate solution design
3. **Optional scenario planning** — Useful for medium/heavy HMWs. Skip for lightweight.
4. **Write option synthesis** — Capture options in `develop/options/option-synthesis.md`. For lightweight HMWs, 1-2 strong options is enough. For heavy HMWs, aim for 3-5.
5. **Skip the full persona review** — Confirm directly with the consultant.

**For collapsed lightweight HMWs**: Develop and Deliver run as one session. After ideation, move directly to the solution brief and action plan without a phase transition.

Save ideation artifacts to `develop/ideation/` and the synthesis to `develop/options/option-synthesis.md`.

## Method Adaptation

For vision-class-specific method recommendations, read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md`.

## When Things Go Thin

- **Only 1-2 options emerge**: The divergence was too narrow. Before accepting a thin option space, try these prompts with the consultant: "What would a competitor do?", "What if budget were unlimited?", "What's the opposite of our first option?", "What would we recommend if the constraint on [X] didn't exist?" These reframing questions often unlock options that were implicitly excluded.
- **Plugin returns no usable solutions**: If value modeling or proposition modeling produces generic or irrelevant output, the input framing may need adjustment. Re-read the problem statement — is it specific enough to generate differentiated solutions? Sometimes the best response is to refine the HMW questions rather than forcing the plugin.
- **Consultant fixates on one option early**: This is natural but undermines the divergent purpose of this phase. Acknowledge the preferred option explicitly, then say: "Let's develop 2-3 more alternatives so we can compare properly in Deliver. Even if this option wins, the comparison strengthens the recommendation."

## Important Notes

- Record why certain options were generated (the reasoning, not just the option) — this traceability matters in Deliver when building the business case
- Cross-reference: if a TIPS solution and a portfolio proposition point to the same thing, note the convergence — it's a signal of robustness
- Scenario planning is particularly valuable for high-uncertainty vision classes where the future state is contested
- If the consultant wants to revisit the problem statement based on what options emerge, that's healthy — the diamond process supports iteration within phases
