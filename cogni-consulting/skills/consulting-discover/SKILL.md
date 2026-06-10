---
name: consulting-discover
description: |
  Execute the Discover phase of a Double Diamond engagement — diverge to build a rich understanding
  of the problem landscape. Dispatches to cogni-knowledge, cogni-trends, and cogni-portfolio.
  Use whenever the user wants to research, explore, or investigate a topic within a diamond engagement.
  Trigger on: "start discovery", "research the landscape", "what do we know about",
  "gather evidence", "run the research", "investigate the market", "scan for trends",
  "competitive analysis", "who are the competitors", "what's happening in [industry]",
  "build the evidence base", "discover phase", "D1 diverge", "explore the problem",
  or any request for broad research within an active engagement. Also trigger when the user asks
  about a specific research method (desk research, stakeholder mapping, data audit, customer journey)
  in the context of an ongoing engagement.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill, TaskCreate, TaskUpdate
---

# Diamond Discover — Diverge to Understand

Build a rich, multi-perspective understanding of the problem landscape. This is the first phase of Diamond 1 — the goal is to cast a wide net before converging on a problem statement in the Define phase.

## Diamond Coach Protocol

Read `$CLAUDE_PLUGIN_ROOT/references/diamond-coach.md` and adopt the Diamond Coach persona.

**Discover opening**: "We're entering Discover — the divergent half of Diamond 1. The goal is to cast a wide net and build a rich evidence base before we narrow down. The quality of everything downstream — problem framing, solution design, business case — depends on what we uncover here. Let's make sure we're looking in the right places."

**Prerequisite gate**: Verify `consulting-project.json` exists and contains `vision_class`, `client`, and `desired_outcome`. If missing, redirect to `consulting-setup`: "We need an engagement set up before we can start discovering. Let's do that first."

**Iteration check**: If `phase_state["1-discover"].status` is `complete`, this is a re-entry. Read existing `1-discover/synthesis.md` and other artifacts. Say: "The Discover phase was completed previously. Let's build on what we have — what would you like to revisit or deepen?" Focus on the specific area rather than re-running the full workflow. When the consultant wants to deepen a topic, run the cogni-knowledge pipeline against the engagement's bound base (see the Research Routing Rule below) with a tightly framed research topic — do not use raw WebSearch. Since the base already holds the prior Discover research, prefer the rule's `--source wiki` re-run path (or `knowledge-query` to just recall what the base already covers), framed focused for a deep dive or broader if the topic is wide.

**Task list**: After loading context, create a task list scaled to engagement weight:

Standard engagement:
1. Load engagement context
2. Propose and confirm discovery methods
3. Execute plugin-powered methods
4. Execute guided methods
5. Synthesize discovery findings
6. Log methods and transition

Lightweight HMW (collapsed Discover+Define):
1. Map context and explore domain
2. Identify stakeholders and constraints
3. Sharpen HMW question
4. Write synthesis and problem statement

## Research Routing Rule

When research is needed — whether as a planned discovery method, a consultant request to "look into X", or to deepen a specific topic during iteration — **always dispatch the cogni-knowledge inverted pipeline**. Never use raw WebSearch for research within an engagement. cogni-knowledge deposits structured, citable syntheses into a bound knowledge base that **compounds across the whole engagement** — Define's assumption verification and Deliver's claims check read that synthesis, and each phase's research builds on the last instead of dying as a throwaway per-sprint report. (This rule is the canonical reference; the Define, Develop, and Deliver skills reroute the same way.)

**Bind the engagement to one knowledge base.** Once per engagement, dispatch `cogni-knowledge:knowledge-setup --knowledge-slug <slug-derived-from-engagement>` (market and output language from `consulting-project.json`) and record that slug in `plugin_refs.knowledge_base`. Every later research run, in any phase, binds to that base by passing the same `--knowledge-slug <plugin_refs.knowledge_base>`, so Discover/Define/Develop/Deliver share one compounding wiki.

**Run the pipeline** for a research topic:
- **New topic** (the base has no coverage yet): `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`.
- **Re-run on a populated base** (the topic is already covered): `knowledge-plan` → `knowledge-compose --source wiki` → `knowledge-verify` → `knowledge-finalize` — skips the web crawl and composes from what the base already holds.
- **Quick gap-check** (just need what the base already knows): `cogni-knowledge:knowledge-query --knowledge-slug <slug> --question "..."` — the shallow read rung, no web crawl, no new project.

**Frame the depth** (this replaces the former research `mode` parameter):
- focused single-topic dive (was `basic`) → `knowledge-plan … --target-words 3000` with 3–4 sub-questions, `--prose-density standard`
- broad multi-angle (was `detailed`) → `--target-words 4000` with 5–7 sub-questions
- exhaustive (was `deep`, e.g. digital-transformation / innovation) → `--target-words 6000+` (or split into two plans), `--prose-density executive`

**Preserve the storage contract.** After `knowledge-finalize`, copy (or symlink) the finalized synthesis `wiki/syntheses/<slug>.md` into the engagement's phase directory so downstream phases find it at a stable path:
- Standard desk research → `1-discover/research/summary.md`
- Topic-specific deep dives (e.g., "research the Drama Triangle framework") → `1-discover/research/` with a descriptive slug
- Research requested during iteration re-entry → same `1-discover/research/` path, a new knowledge run alongside the existing ones

The only exception is a quick fact-check during conversation (e.g., confirming a date or name) — that's fine as a single WebSearch. Anything requiring multiple queries or producing content that feeds into engagement artifacts must go through cogni-knowledge.

## Core Concept

Discover is about breadth, not depth. The consultant and client often arrive with assumptions about what the problem is. This phase deliberately widens the lens — through desk research, trend analysis, competitive mapping, stakeholder input, and data audits — to surface insights that challenge or enrich those initial assumptions.

The key principle: **diverge before converging**. Premature closure is the enemy of good consulting. Discover builds the evidence base that Define will synthesize.

The Diamond Coach actively maintains divergent mode throughout Discover — see "Phase-Mode Coaching" in diamond-coach.md. When solution ideas emerge (design choices, workshop structures, implementation plans), the coach parks them for Develop and redirects to evidence gathering. Discovery outputs are evidence artifacts (themes, tensions, assumptions), never solution artifacts (designs, recommendations, plans).

## Workflow

### 1. Load Engagement Context

Read consulting-project.json. Extract: engagement name, vision class, desired outcome, scope, constraints, industry, language.

**Load personas**: Read all files in `personas/`. If personas exist from Setup, present them to the consultant: "We identified these people during setup — they are the lens through which we'll evaluate everything we discover. Let's keep them in view." List each persona's name and core tension. If no personas exist, note this and continue — persona creation can happen during guided methods.

Update phase state to in-progress:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" 1-discover in-progress
```

### 2. Propose Discovery Methods

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the vision class's recommended Discover methods. Also read any method files referenced.

Present the proposed discovery plan, typically 3-5 activities:

**Plugin-powered methods** (automated via insight-wave ecosystem):

| Method | Plugin | What It Produces |
|---|---|---|
| Desk research | cogni-knowledge | Compounding wiki synthesis with cited sources (depth set via `--target-words`, per the Research Routing Rule) |
| Industry trend scan | cogni-trends | 60 trend candidates across 4 dimensions × 3 horizons |
| Competitive baseline | cogni-portfolio | Competitor landscape and market segmentation |

**Guided methods** (interactive prompts with consultant):

| Method | What It Produces |
|---|---|
| Stakeholder mapping | Influence/interest matrix, interview agenda |
| Data audit | Available data inventory, quality assessment, gaps |
| Customer journey analysis | As-is journey map with pain points |
| Empathy mapping | Enriched personas with Think/Feel/Say/Do |

**Method mix check**: Before presenting, verify the proposed plan includes at least one internal-facing method (stakeholder mapping, data audit) alongside any external-facing methods (desk research, competitive, trends, customer journey). Discovery that looks only outward misses internal capability constraints, stakeholder dynamics, and data readiness — all of which shape what the Define phase can actually work with. If the vision class recommendations are all external, add stakeholder mapping as a default internal complement.

Ask: "Which methods do you want to use for Discovery? I recommend all plugin-powered methods plus [1-2 guided methods based on vision class]. You can add, remove, or reorder."

### 3. Execute Plugin Methods

For each confirmed plugin method, dispatch to the appropriate plugin:

**Desk Research (cogni-knowledge)** — per the Research Routing Rule above:
- Frame the research topic from the engagement's desired outcome and scope
- Suggest depth: `--target-words 4000` (5–7 sub-questions) for most vision classes, `--target-words 6000+` / `--prose-density executive` for digital-transformation or innovation-portfolio
- Bind the base first if `plugin_refs.knowledge_base` is unset; the market and output language come from that base's `knowledge-setup` defaults (matching the engagement scope)
- Run the pipeline against the bound base by passing `--knowledge-slug <plugin_refs.knowledge_base>` to `knowledge-plan` (`knowledge-plan → … → knowledge-finalize`, or the `--source wiki` re-run path if the base already covers the topic)
- After `knowledge-finalize`, copy or symlink the synthesis `wiki/syntheses/<slug>.md` to `1-discover/research/summary.md`

**Industry Trend Scan (cogni-trends)**:
- Frame the industry from the engagement context
- Dispatch `trend-scout` with the industry and language settings
- After scouting completes, store the project path in `plugin_refs.tips_project`
- Copy or symlink the trend summary to `1-discover/trends/`

**Competitive Baseline (cogni-portfolio)**:
- If a portfolio project doesn't exist yet, run `portfolio-setup` with the client context
- Then dispatch `portfolio-scan` or `compete` depending on scope
- Store the project path in `plugin_refs.portfolio_project`
- Copy or symlink competitive summary to `1-discover/competitive/`

**Persona import from portfolio**: After dispatching `portfolio-scan` or `compete`, check if `customers/{market-slug}.json` files exist in the portfolio project. If so, and if personas were not already imported during Setup, offer to import buyer profiles as persona seeds using the mapping in `$CLAUDE_PLUGIN_ROOT/references/persona-schema.md`. Remind the consultant that buyer profiles describe who buys — the engagement may design for different people.

Between each plugin dispatch, check with the consultant: "Research complete. Review before moving to trend analysis?"

### 4. Execute Guided Methods

For each confirmed guided method, read the method file from `$CLAUDE_PLUGIN_ROOT/references/methods/` and walk the consultant through it interactively.

**Stakeholder Mapping** (`references/methods/stakeholder-mapping.md`):
- Guide the consultant through identifying stakeholders
- Build an influence/interest matrix together
- Draft interview questions aligned to the engagement vision
- Save outputs to `1-discover/stakeholder-map.md`
- **Persona enrichment**: After the stakeholder map is complete, cross-reference with existing personas. For stakeholders marked "directly affected" who match an existing persona, enrich the persona with influence level, engagement strategy, and interview insights. For affected stakeholders not yet represented as personas, propose creating a new one: "This stakeholder group is directly affected but we don't have a persona for them yet. Should we create one?" Write enriched personas back to `personas/{slug}.json`, promote `maturity` to `"researched"`, and append to `phase_log`.

**Data Audit** (`references/methods/data-audit.md`):
- Inventory available data sources with the consultant
- Assess quality, recency, and relevance
- Identify critical gaps
- Save outputs to `1-discover/data-audit.md`

**Customer Journey Analysis** (when used):
- **Persona enrichment**: After the journey map is complete, map pain points and emotions to the relevant personas. Populate the persona's `empathy_map` (especially `feels` and `does` quadrants) and `needs` fields with journey-specific findings. This is the primary mechanism for building empathy map data from evidence rather than assumption.

**Empathy Mapping** (`references/methods/empathy-mapping.md`):
- Recommended when personas exist from Setup and other guided methods have produced evidence to ground them
- Walk the consultant through Think/Feel/Say/Do for each persona
- Surfaces gaps in understanding and say-do contradictions
- Updates persona files directly — no separate artifact needed
- Particularly valuable for digital-transformation, cost-optimization, and innovation-portfolio

### 5. Synthesize Discovery

After all methods complete, produce a discovery synthesis:

1. Read all outputs in `1-discover/` (research summary, trend candidates, competitive data, stakeholder map, data audit)
2. Identify 5-10 key themes that emerge across sources
3. For each theme, cite the specific sources that support it — not just the method name, but the file and section (e.g., `*Sources: research/summary.md §Market Size, competitive/summary.md §Market Gaps*`). This traceability matters because the Sponsor needs to verify claims for board briefings, and the Define-phase analyst needs to follow evidence trails back to their origin. Vague attribution ("desk research shows...") erodes trust.
4. Note surprises — findings that challenge initial assumptions
5. Flag tensions — contradictions or trade-offs between sources, stating which sources disagree and why the disagreement matters
6. Extract assumptions — for each theme, surface the key assumptions it relies on. Frame them as testable hypotheses: *"Assumption: mid-market buyers prioritize speed over features — to be tested via stakeholder interviews in Define."* The Define phase needs an explicit assumptions register, not just a theme list. Without it, themes are treated as facts rather than hypotheses, and the engagement builds on unverified ground.
7. **Persona check** — Review whether we're learning about the right people. Are there affected groups we missed during Setup that Discovery revealed? Should any persona hypothesis be retired because research shows they're not central? Should new personas be created from discovery findings? If personas were enriched during guided methods, note their current maturity. This check ensures the engagement's empathy lens is correctly focused before Define narrows the problem.
8. Prioritize themes — rank the themes by evidence strength (how many sources support them, how robust the data is) and engagement relevance (how directly the theme connects to the desired outcome). Present the top 3 as "high-confidence, high-impact" themes the engagement should bet on. This helps the consultant and sponsor focus energy where it matters most.
9. Write `1-discover/synthesis.md` with sections: Key Themes (with source citations and assumptions), Surprises, Tensions, Assumptions to Test, Persona Status, and Phase Transition Assessment

**Example synthesis structure**:
```markdown
### Theme 1: [Specific insight, not a category]
[Evidence-based description integrating multiple sources]
*Sources: research/summary.md §3, competitive/summary.md §Market Gaps, stakeholder-map.md §High Influence*
*Assumption: [testable hypothesis this theme relies on]*
*Priority: HIGH — supported by 3 sources, directly addresses desired outcome*
```

Present the synthesis to the consultant for review and refinement.

### 6. Log Methods and Transition

Update the method log:

```bash
# For each method used, append to .metadata/method-log.json
```

Update `consulting-project.json` with any new `plugin_refs`.

Apply the Diamond Coach closing protocol: summarize what was accomplished (specific artifacts and key findings), note any gaps or thin areas, and preview what Define will do with these outputs.

Ask the consultant: "Discovery phase complete. The synthesis surfaces [N] key themes. Ready to converge in the Define phase, or do you want to explore any theme further?"

If ready to converge, mark Discover complete and suggest `consulting-define`:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" 1-discover complete
```

## Discovery for how-might-we

For `how-might-we` engagements, the discovery approach adapts to the HMW's complexity (assessed during setup).

### Lightweight HMW (collapsed Discover+Define)

For simple, bounded challenges (workshop design, team exercise, meeting redesign), Discover and Define run as a single conversation. Engage with the domain immediately — don't stay abstract.

**Mode discipline**: Even in collapsed Discover+Define, divergent exploration comes before convergent framing. Follow the "Lightweight HMW Mode Discipline" section in diamond-coach.md — explicitly name the mode switch when transitioning from context mapping to HMW sharpening. Solution ideas that emerge during steps 1-2 go to a parking lot, not into the synthesis.

1. **Context mapping with domain engagement** — Ask the consultant about the situation, but reference the actual subject matter. For a Drama Triangle workshop: "What patterns are the consultants seeing — rescuer dynamics with clients, persecutor escalations in steering committees? How familiar are they with Transactional Analysis?" This shows domain understanding and surfaces better design inputs than generic questions.
2. **Stakeholder + constraints** — Quick: who's involved, what are the boundaries? Keep it to a few questions, not a formal mapping exercise.
3. **HMW sharpening** (Define, inline) — Based on the context, propose 2-3 refined versions of the HMW question. Let the consultant pick. Write a brief problem statement.
4. **Skip desk research** unless the consultant asks for it. When the consultant does ask for research (e.g., "research the framework", "look into best practices for X", "I need evidence on Y"), run the cogni-knowledge pipeline (Research Routing Rule above) as a focused single-topic run (`--target-words 3000`, `--prose-density standard`) on the engagement's bound base, then copy the synthesis to `1-discover/research/summary.md`. Do not use raw WebSearch — the research routing rule applies to all engagement weights.

Save a combined `1-discover/synthesis.md` and `2-define/problem-statement.md` and `2-define/hmw-questions.md`. Then mark **both** Discover and Define as complete — this is critical for tracking:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" 1-discover complete
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" 2-define complete
```

Apply the Diamond Coach closing protocol: summarize what was accomplished in the collapsed Discover+Define, then preview Develop. Move directly to Develop.

### Medium HMW

Standard 4 phases, but each is shorter. **Recommend cogni-knowledge** — run a focused desk research sprint to ground the design in evidence (e.g., "best practices for X", "what approaches exist for Y"). Frame the research topic tightly from the HMW question.

Use the guided exploration from the lightweight path for context mapping, then add:
- Run the cogni-knowledge pipeline (Research Routing Rule above) at `--target-words 3000` (focused) or `4000` (broader) depending on scope
- Bind/reuse the engagement base via `plugin_refs.knowledge_base` and copy the synthesis to `1-discover/research/summary.md`

### Heavy HMW

Use the standard Discover workflow (steps 1-6 above). Recommend cogni-knowledge (broad run, `--target-words 4000+`) and consider cogni-portfolio if competitive context matters. This path is close to other vision classes but framed around the HMW question.

### Synthesis for all HMW variants

Instead of the full 8-step synthesis, produce a discovery summary scaled to complexity:
- **Lightweight**: Context paragraph, constraints, refined HMW (fits in `1-discover/synthesis.md`)
- **Medium**: Context, research highlights, stakeholders, constraints, assumptions to test
- **Heavy**: Full synthesis with themes, source citations, and assumptions register

Save to `1-discover/synthesis.md` using the same path so downstream skills find it.

## Method Adaptation

For vision-class-specific method recommendations, read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md`.

## When Things Go Thin

- **Plugin returns thin results** (fewer than 3 substantive findings): Note the gap explicitly in the synthesis and flag it for the consultant. Thin evidence in one area can be compensated by strength in another, but the consultant should know. Offer to retry with adjusted parameters (broader scope, different market framing) or substitute a guided method.
- **Consultant disengages from a guided method**: Some methods (stakeholder mapping, data audit) need active input. If the consultant gives minimal responses, capture what's available and move on — a partial output is better than a blocked engagement.
- **Consultant starts solving during Discover**: If the consultant shifts into solution mode (proposing workshop designs, suggesting implementations, evaluating options), acknowledge the idea, note it in a "Parking Lot" section of the synthesis, and redirect: "Good idea — I've captured it for Develop. Let's keep exploring the problem space. What else might be going on?"
- **Prior phase was skipped**: Setup should be complete, but if the consultant jumped straight to Discovery, gather the minimum context needed (client, vision class, scope) and create consulting-project.json inline.

## Important Notes

- The transition to Define is the consultant's call — they may want to explore further or revisit a finding before converging. Ask, don't assume.
- Sequential dispatch lets findings from each source inform the next — research shapes trend framing, trends inform competitive lens. If the consultant is time-pressed, parallel dispatch works but note the trade-off.
- If a plugin method fails or produces thin results, note the gap and continue — the Define phase can work with incomplete information, and the gap itself is a finding worth recording.
- Update consulting-project.json after each significant step
- **Communication Language**: Use the engagement's language setting for all interactions
