---
name: text-to-narrative
description: >-
  Turn text into an arc-driven executive narrative and hand it to Claude Design as one
  self-contained design brief. Runs arc selection, the arc contract and four drafting passes
  from its own bundled copy of the narrative assets, then writes design-brief.md for one
  target (slides, document, infographic or web): density-capped units, the Rendering
  Contract, the presentation-intent layer and a Sources block, with copy frozen from the
  narrative. Use this skill whenever the user asks to "create a narrative",
  "write a narrative", "transform content into a story arc", "generate an insight summary",
  "turn text into a narrative", "text to narrative", "write a design brief",
  "brief for Claude Design", "narrative for Claude Design", "hand this to Claude Design",
  "Text in ein Narrativ verwandeln" or "Design-Brief für Claude Design erstellen".
  Not for polishing prose (copywriter), and not a renderer: Claude Design renders the
  brief, and no local render chain exists in this plugin any more.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

<!-- compatibility-delegate: cogni-publishing -->

# Text to Narrative Compatibility Route

Dispatch `cogni-publishing:text-to-narrative` with the user's request and arguments unchanged. Return its result unchanged; keep no narrative, validation, or rendering logic here.

If `cogni-publishing` is not installed, stop and tell the user to install that plugin. Do not recurse into this workspace route or attempt a reduced local workflow.

Compatibility pointers retained for unmigrated readers: `arc-category-creation.md`, `arc-company-credo.md`, `arc-competitive-intelligence.md`, `arc-consulting-problem-solving.md`, `arc-corporate-visions.md`, `arc-customer-transformation.md`, `arc-engagement-model.md`, `arc-industry-transformation.md`, `arc-jtbd-portfolio.md`, `arc-registry.md`, `arc-smarter-service.md`, `arc-strategic-choice.md`, `arc-strategic-foresight.md`, `arc-technology-futures.md`, `arc-theme-thesis.md`, `arc-trend-panorama.md`, `density-ceilings.md`, `design-brief-template.md`, `execution-brief.md`, `language-de.md`, `language-en.md`, `language-shared.md`, `techniques-overview.md`, `validation.md`, and `visual-intent.md`. Each pointer names its canonical publishing target; do not treat it as implementation content.
