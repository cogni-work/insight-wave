---
name: text-to-narrative
description: >-
  This compatibility skill routes requests for an arc-driven executive narrative and frozen
  design brief to cogni-publishing, whose local renderer produces slides, documents,
  infographics, or web output; Claude Design is optional. Use it when users ask to "create a narrative",
  "write a narrative", "transform content into a story arc", "generate an insight summary",
  "turn text into a narrative", "text to narrative", "write a design brief",
  "brief for Claude Design", "narrative for Claude Design", "hand this to Claude Design",
  "Text in ein Narrativ verwandeln" or "Design-Brief für Claude Design erstellen".
  Not for polishing prose (copywriter), and not a local implementation.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
---

<!-- compatibility-delegate: cogni-publishing -->

# Text to Narrative Compatibility Route

Dispatch `cogni-publishing:text-to-narrative` with the user's request and arguments unchanged. Return its result unchanged; keep no narrative, validation, or rendering logic here.

If `cogni-publishing` is not installed, stop and tell the user to install that plugin. Do not recurse into this workspace route or attempt a reduced local workflow.

Compatibility pointers retained for unmigrated readers: `arc-category-creation.md`, `arc-company-credo.md`, `arc-competitive-intelligence.md`, `arc-consulting-problem-solving.md`, `arc-corporate-visions.md`, `arc-customer-transformation.md`, `arc-engagement-model.md`, `arc-industry-transformation.md`, `arc-jtbd-portfolio.md`, `arc-registry.md`, `arc-smarter-service.md`, `arc-strategic-choice.md`, `arc-strategic-foresight.md`, `arc-technology-futures.md`, `arc-theme-thesis.md`, `arc-trend-panorama.md`, `density-ceilings.md`, `design-brief-template.md`, `execution-brief.md`, `language-de.md`, `language-en.md`, `language-shared.md`, `techniques-overview.md`, `validation.md`, and `visual-intent.md`. Each pointer names its canonical publishing target; do not treat it as implementation content.
