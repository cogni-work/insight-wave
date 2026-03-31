# Diagram Generation Reference

## Overview

Mermaid syntax reference for research reports. Diagrams in reports are handled downstream by `cogni-visual:enrich-report`, which analyzes report content and generates interactive charts and concept diagrams. This reference documents Mermaid diagram types and syntax guidelines for any manual diagram insertion or downstream processing.

## Supported Mermaid Diagram Types

| Type | Keyword | Best For |
|------|---------|----------|
| Flowchart | `flowchart LR` or `flowchart TD` | Process flows, decision trees, workflows |
| Sequence | `sequenceDiagram` | Interaction protocols, API flows, communication patterns |
| Class | `classDiagram` | Component relationships, system architecture |
| State | `stateDiagram-v2` | Lifecycle states, status transitions |
| Mindmap | `mindmap` | Topic decomposition, concept hierarchies |
| Pie | `pie` | Market share, distribution data, proportional comparisons |
| Timeline | `timeline` | Historical progressions, roadmaps, milestones |

## Content-to-Diagram Mapping

Use this table to select the right diagram type based on research content:

| Research Content Pattern | Diagram Type | Example |
|-------------------------|--------------|---------|
| Process descriptions, step-by-step workflows | Flowchart | Software deployment pipeline |
| Multi-party interactions, request/response | Sequence | API authentication flow |
| Component relationships, system structure | Class | Microservices architecture |
| Status transitions, lifecycle stages | State | Order processing states |
| Topic breakdown, categorical hierarchy | Mindmap | Research landscape overview |
| Proportional data, market shares | Pie | Cloud provider adoption |
| Chronological events, evolution over time | Timeline | Technology adoption milestones |
| Comparative analysis (non-proportional) | Flowchart (comparison layout) | Feature comparison across vendors |

## Mermaid Syntax Guidelines

Apply these guidelines when generating Mermaid code blocks:

### Theme Directive
Always start with the neutral theme for clean rendering across light/dark backgrounds:
```
%%{init: {'theme':'neutral'}}%%
```

### Node Count
Keep diagrams under **15 nodes** for readability. Complex systems should be simplified to their most important components — a diagram that needs scrolling defeats its purpose.

### Label Length
Node labels should be 2-5 words. Use abbreviations or short phrases. If a concept needs more explanation, put it in the caption text, not the diagram.

### Caption Format
Every diagram must be followed by an italicized caption on its own line:
```markdown
*Figure N: Description of what the diagram shows and why it matters.*
```

### Complete Example

````markdown
```mermaid
%%{init: {'theme':'neutral'}}%%
flowchart LR
    A[Data Collection] --> B[Preprocessing]
    B --> C{Quality Check}
    C -->|Pass| D[Model Training]
    C -->|Fail| B
    D --> E[Evaluation]
    E --> F[Deployment]
```
*Figure 1: Machine learning pipeline showing the iterative data quality loop that ensures training data meets minimum thresholds before model training begins.*
````

## Export Handling

### Markdown
Mermaid code blocks are preserved as-is. Obsidian, GitHub, and most modern tools render them natively.

### HTML
The enrich-report skill (cogni-visual) injects the Mermaid CDN script into the HTML when Mermaid blocks are detected:
```html
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<script>mermaid.initialize({startOnLoad: true, theme: 'neutral'});</script>
```
Fenced ` ```mermaid ` code blocks are converted to `<pre class="mermaid">` elements (not `<code>` — Mermaid.js expects `<pre class="mermaid">`).

### PDF / DOCX (pre-rendering required)
Mermaid must be pre-rendered to SVG or PNG before conversion:
1. **mermaid-cli** (`mmdc`): `mmdc -i diagram.mmd -o diagram.svg -t neutral` — fastest, best quality
2. **Excalidraw MCP**: `mcp__excalidraw__create_from_mermaid` + `mcp__excalidraw__export_to_image` — produces hand-drawn style
3. **Fallback**: Leave as styled code blocks with a note recommending `npm install -g @mermaid-js/mermaid-cli`

## Visual Upgrade Path

Mermaid diagrams provide basic inline visualization during report writing. For richer visual treatment after the report is complete:

**`cogni-visual:enrich-report`** — Post-processes the finished `output/report.md` into themed HTML with:
- Interactive Chart.js charts (bar, doughnut, radar, line, scatter) extracted from the report's numeric data, comparison tables, and statistical clusters
- Excalidraw SVG concept diagrams for process flows, relationship maps, and abstract concepts
- Themed design with CSS custom properties from cogni-workspace themes
- Navigation sidebar and responsive layout

enrich-report analyzes the entire report structure using content-pattern detection to identify data-rich sections that warrant interactive visualization. It works regardless of research topic — the enrichment intelligence is driven by content patterns (data tables, comparison structures, statistical clusters, process descriptions), not domain-specific keywords.

To trigger: Run `/enrich-report` after the report is finalized at `output/report.md`.

## Limitations

- Mermaid diagrams are text-based — they cannot represent photographs, artistic illustrations, or complex data visualizations
- Very complex diagrams (>20 nodes) become unreadable in report context
- Mermaid rendering may vary slightly between renderers (Obsidian vs GitHub vs CDN)
- For outline and resource report types, diagrams are skipped (these formats are too concise)
