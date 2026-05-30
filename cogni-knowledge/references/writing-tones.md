# Writing Tones Reference

> **Forked** from `cogni-research/references/writing-tones.md` (point-in-time copy; drift acceptable, same posture as the `wiki-composer` / `wiki-reviewer` agent forks). cogni-knowledge has no `researcher_role` knob, so the upstream "Tone Interaction with Researcher Role" section is dropped — only the 15-tone catalog + default survive.

Available writing tones for the `wiki-composer` (Phase 5) draft. The tone shapes vocabulary, sentence structure, and rhetorical approach throughout the synthesis. It is resolved in `knowledge-plan` Step 0.5 (precedence: `--tone` flag > `binding.research_defaults.tone` > `objective`), written into `plan.json::tone`, and threaded to the composer as `TONE` by `knowledge-compose`.

## Tone Catalog

| Tone | Description | Best For |
|------|-------------|----------|
| **objective** | Balanced, evidence-based, neutral stance | Default — general research |
| **formal** | Academic register, passive voice, hedged claims | Academic/institutional audiences |
| **analytical** | Data-driven, structured argument, quantitative emphasis | Market analysis, technical assessment |
| **persuasive** | Builds a case, uses rhetorical structure, strong conclusions | Strategy recommendations, proposals |
| **informative** | Clear explanations, accessible language, educational | Explainers, onboarding docs |
| **explanatory** | Step-by-step reasoning, analogies, progressive complexity | Technical deep dives |
| **descriptive** | Rich detail, comprehensive characterization, thorough | Landscape surveys, state-of-the-art |
| **critical** | Evaluative, weighs pros/cons, identifies limitations | Technology evaluation, competitive analysis |
| **comparative** | Side-by-side analysis, contrast-driven, tabular where useful | Vendor comparison, option analysis |
| **speculative** | Forward-looking, scenario-based, explores possibilities | Futures, trends, foresight |
| **narrative** | Story-driven, chronological flow, human-centered | Case studies, historical analysis |
| **optimistic** | Highlights opportunities, positive framing, solution-oriented | Innovation reports, opportunity scans |
| **simple** | Short sentences, plain language, minimal jargon | Executive summaries, broad audiences |
| **casual** | Conversational, direct, approachable | Internal memos, blog-style |
| **executive** | Concise, decision-oriented, bottom-line-first emphasis | C-suite briefings, board updates, steering committee reports |

## Default

When no tone is specified: **objective**.

## Tone composes orthogonally with prose density

`tone` is a **rhetorical register** (concise / persuasive / narrative / executive — how the prose reads); `prose_density` is a **structural discipline** (whether `target_words` is a floor or a ceiling, plus BLUF + Pyramid + citation cadence under `executive`). They compose independently — `tone=analytical, prose_density=executive` produces a data-driven argument with BLUF + Pyramid; `tone=narrative, prose_density=executive` produces a story-driven argument with the same structural discipline. The rhetorical register changes; the structural discipline does not. Never fold one into the other: `tone=executive` (a register) is distinct from `prose_density=executive` (a structural ceiling).
