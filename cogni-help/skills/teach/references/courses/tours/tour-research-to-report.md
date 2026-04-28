# Tour: Research to Report

**Duration**: 60 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-research → cogni-narrative → cogni-visual
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-research`, `/cogni-help:cheatsheet cogni-narrative`, or `/cogni-help:cheatsheet cogni-visual`; see also `docs/plugin-guide/cogni-research.md`, `docs/plugin-guide/cogni-narrative.md`, `docs/plugin-guide/cogni-visual.md`.
**Audience**: Analysts producing presentations from original research

---

This tour walks the full research-to-presentation pipeline as one continuous workflow.
You author a research question, generate a sourced report, shape it into an executive
narrative, and render the result as a deliverable — without re-explaining each plugin
in isolation. If a plugin in the chain is unfamiliar, accept the inline-summary
fallback offered at the start of the tour or skim the matching cheatsheet first.

## Module 1: Pipeline Overview & Question Framing

### Theory (5 min)

The research-to-report pipeline chains three plugins: `cogni-research` produces a
sourced report from a question, `cogni-narrative` reshapes the report into a story
arc, and `cogni-visual` renders the narrative as slides or a web deliverable. Each
plugin owns one transformation; the deliverable quality is the product of all three.

Three decisions frame the tour:

| Decision | Options | Default for tour |
|----------|---------|------------------|
| Research depth | basic / detailed / deep / outline / resource | detailed |
| Source mode | web / local / hybrid | web |
| Story arc | SCQA / Minto Pyramid / Hero's Journey | SCQA (problem-solution) |

A sharp question is the highest-leverage input. "What are AI trends?" produces a
generic report; "Which generative AI capabilities have moved from research to
production-grade in the last 18 months in the DACH manufacturing sector?" produces
a useful one.

### Demo

Walk through framing one research question end-to-end:
1. Pick a topic the learner cares about (a market, a technology, a competitor).
2. Tighten it: add a time horizon, a region, and a target audience.
3. Decide depth (basic for a quick scan, detailed for a client deliverable, deep for
   strategic intelligence) and source mode (web for current signals, hybrid when
   internal documents add depth).
4. Pick the story arc up front — SCQA fits problem-solution narratives, Minto fits
   recommendation-first executive briefings.

### Exercise

Have the learner draft a research question for their own context, then test it against
the sharpening checklist: time horizon? region? audience? specific enough to fail?
If it can't be wrong, it's not specific enough.

### Quiz

1. **Multiple choice**: Which depth fits a 10-page market analysis with full citations?
   - a) basic — b) detailed — c) deep — d) outline
   **Answer**: b (detailed; basic is too short, deep is overkill, outline is framework only)

2. **Hands-on**: Sharpen "What are renewable energy trends?" into a question a
   `detailed` report could answer in 5 sub-questions.

### Recap

- The pipeline is research → narrative → visual; pick depth, source mode, and arc upfront
- A sharp, falsifiable question is the highest-leverage input
- SCQA suits problem-solution narratives, Minto suits exec recommendations

---

## Module 2: Generate the Research Report (cogni-research)

### Theory (6 min)

`cogni-research` is a STORM-inspired multi-agent editorial workflow. Behind the
single command, specialized agents decompose the question into sub-questions,
research them in parallel, write sections, verify claims, and review the draft.
Claims are auto-logged to `cogni-claims` with provenance — you can trace any
sentence to a source.

Five report types: basic (3-5K words, 5 sub-questions), detailed (5-10K, 5-10
sections), deep (recursive tree exploration, 8-15K), outline (1-2K framework only),
resource (1.5-3K bibliography). Three source modes: web, local, hybrid.

For DACH, set language to DE — the curated authority sources (fraunhofer.de,
bitkom.org, vdma.org, destatis.de) replace the EN/US default set.

### Demo

Run `/research-report` against the question framed in Module 1:
1. Configure depth (detailed), tone (analytical), citation format (APA), language (EN or DE).
2. Pick a project storage location.
3. Watch the pipeline: question decomposition → parallel research → claim logging →
   section writing → review.
4. Open the produced `report.md` in Obsidian or VS Code — show the inline citations
   and the per-source markdown files.

### Exercise

Run `/research-report` with the learner's own question at `basic` depth (faster than
detailed for a teaching pass). When it finishes, ask the learner to find one claim,
trace it to its source markdown file, and confirm the original source supports it.

### Quiz

1. Why does cogni-research log claims to cogni-claims during research instead of after?
   **Answer**: Provenance is fresh at write time; back-filling provenance later is
   error-prone. Claims-during-research enables the correction-cascade pattern.

2. **Hands-on**: Open the `report.md` from the demo, copy the `[Source: …]` format
   inline citation, and find the matching file under `sources/`.

### Recap

- Five report types — basic / detailed / deep / outline / resource — pick by deliverable scope
- Three source modes — web / local / hybrid
- Claims auto-logged with provenance, verified during the research loop
- DACH/EU markets get curated authority sources via `language` setting

---

## Module 3: Shape the Narrative (cogni-narrative)

### Theory (6 min)

The research report has all the facts but not the story. `cogni-narrative` applies a
story arc framework — SCQA, Minto Pyramid, Why Change, Hero's Journey, and others —
to rebuild the report as an executive narrative. The arc determines order: SCQA leads
with situation, Minto leads with the recommendation.

Citations are preserved end-to-end. A `bridge-citations.py` step converts inline
`[Source: Publisher](URL)` citations into per-source markdown files before narrative
Phase 1; the narrative reads them as entities, so every claim in the polished
narrative still traces to a source.

For research-to-report, SCQA is the typical default — research is naturally
problem-led and the audience needs context before recommendations.

### Demo

Run `/narrate` on the report from Module 2:
1. Pick the SCQA arc.
2. Watch narrative Phase 1 (extract claims and sources), Phase 2 (compose), Phase 3 (review).
3. Open `narrative.md` — note how the claims are reorganized into Situation /
   Complication / Question / Answer order.
4. Run `/narrative-review` to score the arc compliance, BLUF, and citation density.

### Exercise

Compare the research report's Module 1 (introduction) to the narrative's Situation
section. The same facts; different sequence. Ask: which version would an executive
read first?

### Quiz

1. **Multiple choice**: For a 5-page recommendation memo to a CFO, which arc fits best?
   - a) SCQA — b) Minto Pyramid — c) Hero's Journey — d) Why Change
   **Answer**: b (Minto leads with the recommendation; CFOs want the answer first)

2. **Hands-on**: Re-run `/narrate` with the Minto arc instead of SCQA. Compare opening lines.

### Recap

- The story arc determines the deliverable's reading order
- SCQA fits problem-solution; Minto fits exec recommendations
- Citations bridge from research to narrative — provenance survives
- `/narrative-review` scores arc compliance and citation density

---

## Module 4: Render the Deliverable (cogni-visual)

### Theory (5 min)

`cogni-visual` renders the polished narrative as a slide deck (`/render-html-slides`
or `/render-slides` for PPTX), a scrollable web narrative (`/story-to-web`), an
infographic (`/story-to-infographic`), or a printed storyboard (`/story-to-storyboard`).

The renderer reads the story arc from the narrative's frontmatter and maps each arc
section to slide layouts with assertion headlines. The active workspace theme drives
colors, fonts, and design variables — no per-deliverable styling needed.

For exec audiences with limited time, prefer slides. For a leave-behind asset that
the audience will browse asynchronously, prefer the web narrative.

### Demo

Run `/render-html-slides` on the narrative from Module 3:
1. Pick a slide count appropriate for the audience (10-15 for execs).
2. Watch slide layout selection — each arc section gets matched to title, content,
   pull-quote, or comparison layouts.
3. Open the resulting `slides.html` in a browser and walk through with arrow keys.

### Exercise

Render the same narrative twice — once as slides, once as a web narrative
(`/story-to-web`). Ask the learner which they'd send to a client and why.

### Quiz

1. Why does cogni-visual ignore manual styling instructions and read the workspace theme instead?
   **Answer**: Theme inheritance keeps every deliverable visually consistent across
   plugins. Per-deliverable styling produces drift.

2. **Hands-on**: Switch the workspace theme via `/pick-theme` and re-render. Note
   that nothing in the narrative needed to change.

### Recap

- Slides for exec audiences, web narrative for leave-behinds, infographic for one-pagers
- Theme inheritance from cogni-workspace — no per-deliverable styling
- Slide layouts auto-mapped from the story arc's sections

---

## Module 5: End-to-End Recap & Iteration

### Theory (4 min)

The research-to-report tour produces three durable artifacts: a sourced research
report, an arc-shaped narrative, and a rendered deliverable. Each is reusable —
the report seeds future narratives, the narrative seeds future visuals, the
visuals seed future client conversations.

When iterating: corrections to claims propagate. Edit a source via `cogni-claims`,
and the staleness cascade marks the narrative and slide deck for refresh. Don't
manually re-edit downstream artifacts when the upstream source changes.

Common pitfalls: skipping the narrative step (data-heavy slides, no story);
mismatching depth to deliverable (deep research for a 5-slide deck wastes time);
bypassing claims verification on imported content.

### Demo

Walk the learner backwards through their three artifacts:
1. Open the slide deck — point at one assertion headline.
2. Open the narrative — find the matching section.
3. Open the research report — find the cited source.

Show how `cogni-claims` would mark a downstream artifact stale if the source were
edited.

### Exercise

Have the learner identify the deliverable they would actually need for an upcoming
real engagement (client brief, internal sync, board update). Recommend a depth/arc
combination based on audience. Don't run it — the planning is the exercise.

### Quiz

1. Why is the narrative step often skipped, and what breaks when it is?
   **Answer**: Slides go directly from data to layout; story shape is lost. Audiences
   see organized facts but no insight.

2. **Hands-on**: Pick one of these audiences — board, sales team, prospect, internal
   ops — and name the depth + arc + render format you'd choose for each.

### Recap

- The pipeline produces three durable artifacts; each seeds future work
- Corrections cascade via cogni-claims — don't hand-edit downstream
- Match depth to scope: don't deep-research a 5-slide deck
- Skipping the narrative step trades insight for organized data

---

## Tour Complete

Next steps:
- Run the pipeline against a real engagement question
- Try `/research-report` at `deep` depth for a strategic intelligence dossier
- Combine with `tour-trends-to-solutions` for trend-to-content pipelines
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/research-to-report.md`
- See the narrative tutorial: `docs/workflows/research-to-report.md`
