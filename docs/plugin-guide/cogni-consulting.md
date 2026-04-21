# cogni-consulting

**Plugin guide** — for canonical positioning see the [cogni-consulting README](../../cogni-consulting/README.md).

---

## Overview

cogni-consulting is a process orchestrator. It does not write research, model trends, or generate slides — other plugins do that. What cogni-consulting does is manage the engagement: which phase you are in, which methods have been selected, which plugins have been dispatched, and what has been decided and why.

The underlying methodology is the Double Diamond: two diverge-converge cycles that move from problem exploration to solution delivery. Diamond 1 diverges through broad research (Discover) then converges on a clear problem statement (Define). Diamond 2 diverges into solution options (Develop) then converges on validated, deliverable-ready outcomes (Deliver). Each phase gate is advisory — the plugin tells you when a phase looks ready to close, but you decide.

For a boutique consultancy or solo practitioner, the value is in coordination. Running a strategic options analysis typically requires dispatching research, trend scouting, competitive analysis, assumption verification, proposition modeling, and claims validation — and keeping all of that state coherent across multiple sessions. cogni-consulting handles the state and sequencing; you supply the judgment.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Double Diamond** | The engagement methodology: Discover (D1 diverge) → Define (D1 converge) → Develop (D2 diverge) → Deliver (D2 converge) |
| **Vision class** | The engagement type — one of 8 options that determines recommended methods, dispatched plugins, and deliverable format |
| **Engagement** | A single client or project — lives in `cogni-consulting/{slug}/` with its own phase directories |
| **Phase state** | Each phase tracks: `pending` → `in-progress` → `complete` |
| **Phase analyst** | The agent that assesses phase readiness and recommends methods from the 16-method library |
| **Method** | A named consulting technique (e.g., stakeholder mapping, affinity clustering, lean canvas) — proposed per phase, selected by the consultant |
| **Plugin ref** | A path pointer in `consulting-project.json` to a project created by another plugin — no data is copied, only referenced |
| **Decision log** | Persistent record of key decisions with rationale and evidence references |

### The 8 vision classes

Selecting the right vision class during setup determines the entire downstream flow:

| Vision class | Use when |
|-------------|---------|
| `strategic-options` | Evaluating multiple strategic paths for a client |
| `business-case` | Building a cost/benefit case for a specific initiative |
| `gtm-roadmap` | Planning a go-to-market sequence for a product or service |
| `cost-optimization` | Identifying and quantifying cost reduction opportunities |
| `digital-transformation` | Mapping a transition to new digital operating models |
| `innovation-portfolio` | Assessing and prioritizing an innovation pipeline |
| `market-entry` | Analyzing and planning entry into a new market or segment |
| `business-model-hypothesis` | Testing a new business model using Lean Canvas methods |

The `business-model-hypothesis` class uses Lean Canvas methods (authoring, refinement, stress-test) in place of traditional proposition modeling.

### Data model

Each engagement produces four persistent records:

| File | Contents |
|------|---------|
| `consulting-project.json` | Engagement config: slug, vision class, phase states, plugin refs |
| `.metadata/execution-log.json` | Phase transitions with timestamps and triggers |
| `.metadata/method-log.json` | Methods proposed per phase and which ones were selected |
| `.metadata/decision-log.json` | Key decisions with rationale and evidence references |

---

## Getting Started

Describe the engagement in natural language:

```
I need to evaluate strategic options for expanding our cloud services portfolio in the DACH mid-market
```

cogni-consulting will:
1. Identify `strategic-options` as the vision class from your description
2. Ask you to confirm the engagement scope and name
3. Scaffold the project directory structure at `cogni-consulting/{slug}/`
4. Recommend which plugins to dispatch for the Discover phase
5. Wait for your confirmation before dispatching anything

If you want to be explicit about the setup step:

```
consulting-setup
```

---

## Capabilities

### `consulting-setup` — Vision framing and engagement scaffolding

The entry point for every new engagement. Captures the vision class, engagement name, client context, scope, and language. Creates the directory structure and `consulting-project.json`.

If an engagement already exists for the same client or topic, the skill redirects you to `consulting-resume` rather than creating a duplicate.

```
consulting-setup
```

```
Start a new consulting project for Acme on digital transformation
```

---

### `consulting-discover` — D1 diverge: research, trends, competitive baseline

Dispatches to cogni-research, cogni-trends, and cogni-portfolio to build the evidence base. Which plugins are dispatched depends on the vision class — a `market-entry` engagement uses research and trends differently than a `cost-optimization` engagement.

The phase-analyst agent recommends methods from the 16-method library for this phase. You select which to apply.

```
consulting-discover
```

```
Start discovery — research the landscape and find relevant trends
```

Output lands in `cogni-consulting/{slug}/discover/` with a synthesis document that the Define phase reads.

| Plugin dispatched | What it does in Discover |
|------------------|--------------------------|
| cogni-research | Desk research on the topic domain |
| cogni-trends | Trend scouting relevant to the engagement scope |
| cogni-portfolio | Competitive baseline and capability mapping |

---

### `consulting-define` — D1 converge: assumption verification and problem synthesis

Reads the Discover synthesis, verifies key assumptions via cogni-claims, guides affinity clustering of themes, and produces a problem statement and How Might We questions.

The problem statement and HMW questions become the brief for Diamond 2. Getting this framing right is the most consequential step in the engagement.

```
consulting-define
```

```
Let's move to Define — I think we have enough research to frame the problem
```

| Plugin dispatched | What it does in Define |
|------------------|------------------------|
| cogni-claims | Verifies assumptions from the Discover synthesis against their cited sources |

---

### `consulting-develop` — D2 diverge: option generation and proposition modeling

Reads the problem statement and HMW questions from Define, generates solution options, and models propositions via cogni-trends value-modeler and cogni-portfolio.

The core principle in this phase: generate before evaluating. Multiple options are produced before any scoring happens. Develop creates the option space; Deliver evaluates it.

A proposition quality gate runs in step 4b — propositions that fail high-weight criteria are excluded from Option Synthesis by default. You can explicitly reinstate excluded propositions if you want to carry them forward.

```
consulting-develop
```

```
Generate options — what could we do to address the problem?
```

| Plugin dispatched | What it does in Develop |
|------------------|-------------------------|
| cogni-trends | Value modeling — maps trends to solution opportunities |
| cogni-portfolio | Proposition modeling — builds and evaluates option propositions |

---

### `consulting-deliver` — D2 converge: scoring, business case, roadmap

Evaluates options against feasibility and impact criteria, runs final claims verification, constructs the business case, and produces the roadmap. This is the phase that produces the executive-ready artifacts.

```
consulting-deliver
```

```
Let's finalize — score the options and build the business case
```

| Plugin dispatched | What it does in Deliver |
|------------------|-------------------------|
| cogni-claims | Final quality gate — verifies claims in the business case before packaging |
| cogni-portfolio | portfolio-verify — validates proposition quality against scoring criteria |

---

### `consulting-resume` — Multi-session re-entry

The default skill for returning to an existing engagement. Reads the current engagement state and shows where you left off — current phase, completed outputs, outstanding decisions — then recommends the most valuable next step.

When you mention an existing client or engagement name without specifying a phase, this skill runs first to orient you before routing to the appropriate phase skill.

```
consulting-resume
```

```
Where are we on the Acme engagement?
```

```
Continue the cloud strategy project
```

---

### `consulting-export` — Deliverable package generation

Reads all phase outputs and dispatches to cogni-visual and document-skills to produce the deliverable package in the formats defined during setup.

```
consulting-export
```

```
Generate the final deliverable package as slides and a Word doc
```

```
I need to present this to the board — create the deck
```

You can generate the full package or a single deliverable:

```
Just the executive summary as a PPTX
```

| Plugin dispatched | What it produces |
|------------------|-----------------|
| cogni-visual | Slide decks, infographics, themed HTML reports |
| document-skills | PPTX, DOCX, XLSX formatted documents |

---

## Integration Points

### Upstream — plugins that cogni-consulting dispatches

| Plugin | Phase | Skill invoked |
|--------|-------|--------------|
| cogni-research | Discover | `research-report` |
| cogni-trends | Discover | `trend-scout` |
| cogni-trends | Develop | `value-modeler` |
| cogni-portfolio | Discover | `portfolio-scan`, `compete` |
| cogni-portfolio | Develop | `propositions`, `solutions` |
| cogni-portfolio | Deliver | `portfolio-verify` |
| cogni-claims | Define | `claims` (verify mode) |
| cogni-claims | Deliver | `claims` (verify mode) |
| cogni-visual | Export | `story-to-slides` |
| document-skills | Export | PPTX, DOCX, XLSX generation |

### Standalone value without plugins

cogni-consulting provides value even without any of the above plugins installed. The engagement structure, phase management, method recommendations, and decision logging all work standalone. Each plugin integration adds depth at its corresponding phase.

---

## Common Workflows

### Workflow 1: Full strategic options engagement

1. Describe the engagement to start setup: `consulting-setup`
2. Select `strategic-options` as the vision class
3. Run Discover: `consulting-discover` — dispatches research, trends, competitive baseline
4. Review the Discover synthesis; run `consulting-define` to frame the problem statement
5. Review the problem statement; run `consulting-develop` to generate options
6. Review the options; run `consulting-deliver` to score, build the business case, and produce the roadmap
7. Run `consulting-export` to generate the client-ready deliverable package

This is the full Double Diamond workflow described in [../workflows/consulting-engagement.md](../workflows/consulting-engagement.md).

### Workflow 2: Resume an engagement in a new session

When returning to an engagement after a gap:

```
Continue the Acme cloud engagement
```

`consulting-resume` reads `consulting-project.json`, shows the current phase and outstanding items, and recommends the next action. You confirm and continue.

No context reconstruction needed — the engagement state machine records what has been decided and why.

### Workflow 3: Run a business model hypothesis engagement

The `business-model-hypothesis` vision class uses Lean Canvas methods instead of traditional proposition modeling:

1. `consulting-setup` → select `business-model-hypothesis`
2. `consulting-discover` — research validates the market problem and customer segments
3. `consulting-define` — converges on the core customer problem and jobs-to-be-done
4. `consulting-develop` — runs Lean Canvas authoring and refinement instead of portfolio propositions
5. `consulting-deliver` — stress-tests the canvas against personas, builds the business case
6. `consulting-export` — produces the canvas document and supporting analysis

Canvas reference materials are in `cogni-consulting/references/canvas-format.md`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `consulting-setup` creates a duplicate engagement | An engagement already exists for this client/topic | Run `consulting-resume` instead; if you genuinely need a new engagement with a similar name, use a more specific slug |
| Phase skill complains that the previous phase is not complete | The phase-gate-guard hook is enforcing phase ordering | Review the previous phase outputs; run the phase to completion or explicitly proceed past the gate — the gates are advisory, not blocking (except the Develop proposition quality gate) |
| Plugin dispatch fails silently | The dispatched plugin is not installed in this workspace | Run `workspace-status` to check the plugin registry; install the missing plugin and run `manage-workspace` |
| `consulting-export` produces empty slides | Phase output files are missing or empty in the phase directories | Check that Deliver phase ran to completion; verify that `deliver/business-case.md` and `deliver/roadmap.md` exist |
| Re-opening an engagement shows wrong phase status | `consulting-project.json` was manually edited or corrupted | Run `consulting-resume` — it reads all available evidence (file presence, timestamps) to infer the actual state rather than relying solely on the JSON |
| Method recommendations feel wrong for my domain | The phase-analyst recommends from a 16-method library that may not cover all domains | You can select any method manually; the recommendations are suggestions, not requirements |

---

## Extending This Plugin

cogni-consulting's most useful extension points are:

- **New vision classes** — the 8 current classes cover common strategic consulting scenarios; industry-specific engagement types (healthcare, fintech, public sector) would benefit from dedicated vision classes with tailored method selections and deliverable maps
- **New consulting methods** — the 16-method library in `references/methods/` covers standard approaches; new methods follow the YAML frontmatter format in the existing files
- **New deliverable templates** — `references/deliverable-map.md` maps vision classes to deliverables; new template types require corresponding cogni-visual or document-skills support
- **Phase gate customization** — the phase-gate-guard hook in `hooks/phase-gate-guard.sh` currently warns on all gates and blocks on the Develop proposition quality gate; different clients may need different gate behaviors

See the [insight-wave contribution guide](https://github.com/cogni-work/insight-wave/blob/main/CONTRIBUTING.md) for guidelines.
