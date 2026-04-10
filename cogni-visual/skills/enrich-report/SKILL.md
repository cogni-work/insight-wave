---
name: enrich-report
description: >
  Post-process any completed markdown report (trend-report, research-report, or
  generic) into a themed, self-contained HTML file — optionally with interactive
  Chart.js data visualizations and Excalidraw concept diagrams embedded as inline
  SVG. Analyzes the report structure, identifies data-rich sections (statistics,
  tables, distributions, value chains, timelines, cost comparisons), generates
  themed charts and diagrams, and assembles a polished HTML deliverable with
  navigation sidebar — without changing the original markdown. Also supports
  exporting to PDF and DOCX formats via the `formats` parameter. This is the
  single output skill for all report formats — it replaces the deprecated
  cogni-research:export-report. Use this skill whenever the user has an existing
  text-only report and wants to make it visual or export it: "enrich report",
  "add charts to report", "visualize my report", "make the report visual",
  "turn this into a visual HTML", "export report", "save as PDF", "export to PDF",
  "export to Word", "export to DOCX", "download report", "convert report",
  "make it pretty", "publish report", "report mit Diagrammen anreichern",
  "Bericht visualisieren", "als PDF exportieren", "add data visualizations",
  "generate HTML version with charts", "I need charts in my trend report",
  "make this presentable with visuals". Also trigger when the user mentions
  tips-trend-report.md, output/report.md, or any markdown report that "needs
  visuals", "looks boring", "is text-only", or should become a "dashboard-style"
  or "themed HTML" output. This skill works on EXISTING reports (post-processing) —
  it does NOT create new reports (use research-report/trend-report), does NOT create
  slide decks (use story-to-slides), does NOT create posters or journey maps (use
  story-to-big-picture), does NOT create web landing pages (use story-to-web), does
  NOT create TIPS dashboards (use trends-dashboard), and does NOT polish prose
  (use cogni-copywriting).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, Skill
version: 1.0.0
---

# Enrich Report

## Purpose

Read a completed markdown report and produce a **self-contained HTML file** that presents the same content with interactive data visualizations and conceptual diagrams injected at semantically appropriate positions. The original markdown stays untouched — you are creating a visual rendition, not editing the source.

A great enriched report does not just decorate prose with random charts. Each visualization earns its place by making a data pattern visible that would otherwise require the reader to mentally parse numbers from text, or by making a conceptual relationship (like a T→I→P→S value chain) spatially comprehensible. If a section has no data worth charting and no concept worth diagramming, leave it as styled prose — over-enrichment is worse than no enrichment.

## Architecture

Two-track visualization pipeline:

1. **Data track** — Chart.js charts (bar, doughnut, radar, line, stacked bar) for statistics, distributions, comparisons, timelines. Themed with CSS custom properties from design-variables.
2. **Concept track** — Excalidraw MCP diagrams exported to inline SVG for T→I→P→S flows, relationship maps, strategic concept sketches. Themed with design-variable colors.

The HTML assembly uses a Python generator script (`scripts/generate-enriched-report.py`) that converts markdown to HTML and mounts visualizations at planned injection points — same architectural pattern as `cogni-trends/skills/trends-dashboard` and `cogni-portfolio/skills/portfolio-dashboard`.

**Theming** follows the 3-stage design-variables pattern from cogni-workspace:
1. User picks theme via `cogni-workspace:pick-theme`
2. LLM derives `design-variables.json` from theme.md
3. Python script injects CSS custom properties into HTML

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Report markdown file path |
| `output_path` | `{dir}/output/{stem}-enriched.html` | HTML output path |
| `report_type` | `auto` | Override detection: `trend-report`, `research-report`, `generic` |
| `language` | from frontmatter | `en` or `de` — affects chart labels, axis titles, summary card text |
| `theme` | interactive | Theme path, or omit to trigger `cogni-workspace:pick-theme` |
| `design_variables` | derived from theme | Pre-computed design-variables.json path (skips derivation) |
| `density` | `balanced` | Enrichment density: `none` (0 visuals, themed prose only), `minimal` (5-8), `balanced` (10-15), `rich` (15-22) |
| `formats` | `["html"]` | Output formats: `html`, `pdf`, `docx`. HTML is always produced first; PDF/DOCX are derived from it. |
| `interactive` | `true` | Interactive enrichment review checkpoint at Phase 3 |
| `enrichment_types` | all | Whitelist: e.g., `["kpi-dashboard", "tips-flow", "horizon-chart"]` |
| `skip_types` | none | Blacklist: e.g., `["summary-card"]` |

## Conventions

### Original content is sacred

The source markdown is never modified. Every word, every citation, every heading from the original appears in the HTML output. Visualizations are ADDED between sections — they supplement, never replace.

### Theme-driven visuals

All colors in Chart.js configs and Excalidraw elements reference the design-variables palette. No hardcoded hex values in visualization code. This means the same enriched report can be re-themed by changing the design-variables.json.

### Citation preservation

Every inline citation `[text](url)` from the source becomes a clickable `<a href="url">text</a>` in the HTML. The validation gate counts links: HTML count must be >= source count.

### Interactive checkpoint

Phase 3 presents the enrichment plan for user review before any visualization is generated. This prevents wasted computation on unwanted charts. When `interactive=false`, auto-approve all planned enrichments.

### German fidelity

German reports use real Unicode umlauts (ä ö ü ß), dot-separated thousands (2.661), and German chart axis labels. ASCII umlaut substitutions are a credibility failure.

### Density controls enrichment volume

The `density` parameter gates how many enrichments pass the scoring threshold:
- **none** — Zero visualizations. Produces a beautifully themed HTML with sidebar navigation, styled prose, and preserved citations — but no charts or diagrams. Use for "make it pretty" without visual noise, or as a clean base for PDF/DOCX export.
- **minimal** — Only "always-on" structural enrichments (KPI dashboard, primary value chain flows). 5-8 visuals.
- **balanced** — Structural + high-scoring content-detected enrichments. 10-15 visuals. Default.
- **rich** — Everything that scores above minimum threshold. 15-22 visuals. Best for workshop materials.

When `density=none`: skip Phases 1-4 (structural analysis, enrichment planning, interactive review, visualization generation). Go directly from Phase 0 to Phase 5 with an empty enrichment plan.

---

## Workflow

### Execution protocol

Each phase: verify the previous phase's output exists (entry gate), load the reference file for that phase, execute, state output summary. Reference files contain phase-specific rules — read them at the start of each phase, not all at once.

---

### Phase 0: Report Discovery & Setup

> Find the report, detect its type, set up theming.

**If `source_path` provided:** use directly, set `source_dir` to parent.

**Otherwise, search without asking:**
1. Glob from CWD (max 3 levels):
   - `**/tips-trend-report.md` (trend-report candidates)
   - `**/output/report.md`, `**/output/draft-v*.md` (research-report candidates)
2. For each candidate: read first 40 lines, extract frontmatter fields (`generated_by`, `title`, `language`, `total_themes`)
3. Present candidates via AskUserQuestion (max 4 options with filename, type guess, word count)
4. On empty response: auto-select top candidate. On no candidates: ask for path or stop.

**Report type detection** — read `references/01-report-detection.md`:

| Signal | Type |
|--------|------|
| `generated_by: trend-report` in frontmatter | `trend-report` |
| `total_themes:` + `total_claims:` in frontmatter | `trend-report` |
| H2 "Investment Thesis" + "Value Chains" content | `trend-report` |
| `project-config.json` with cogni-research fields in parent | `research-report` |
| H2 "Introduction" + "Conclusion" + "References" | `research-report` |
| Neither | `generic` |

**Theme setup:**
1. If `design_variables` path provided: load and validate against schema.
2. If `theme` path provided: derive design-variables.json from theme.md (read `cogni-workspace/references/design-variables-pattern.md` for derivation rules, validate against `schemas/design-variables.schema.json`).
3. Otherwise: invoke `cogni-workspace:pick-theme`, then derive.

Store: `report_type`, `source_path`, `source_dir`, `language`, `design_variables` (the JSON object).

---

### Phase 1: Structural Analysis

> Parse the report into a section tree with metadata for each block.

Read `references/02-section-analysis.md` for report-type-specific analysis rules.

1. Parse YAML frontmatter (store verbatim for later).
2. Build section tree from heading hierarchy (H1→H2→H3→H4).
3. For each section, extract:
   - `section_id` — slugified heading text
   - `heading` — original heading text
   - `depth` — heading level (1-4)
   - `line_start` / `line_end` — line range in source
   - `word_count` — body text words (excluding sub-headings)
   - `citation_count` — count of `[text](url)` patterns
   - `has_tables` — boolean
   - `numeric_claims` — extracted numbers with context: `{value, context, source_url}`
   - `data_structures` — detected tables (as arrays), bullet lists with numbers, T→I→P→S chain blocks

**Section ID generation (slugify):** The Python generator converts heading text to IDs by: lowercasing, stripping all non-alphanumeric/non-space/non-hyphen characters (including `×`, `€`, `%`, `–`, `—`, parentheses, quotes), collapsing whitespace and underscores to single hyphens, trimming leading/trailing hyphens. When building the enrichment plan, use this exact logic for `target_section` IDs — mismatched IDs cause enrichments to silently drop.

4. Run **report-type-specific analyzer** on top of generic parse:
   - **Trend-report analyzer:** tag sections as `executive-summary`, `headline-evidence`, `strategic-themes-table`, `theme-N`, `value-chain`, `solution-templates`, `strategic-actions`, `bridge`, `synthesis`, `emerging-signals`, `horizon-distribution`, `mece-validation`, `evidence-coverage`, `claims-registry`
   - **Research-report analyzer:** tag as `introduction`, `body-section`, `conclusion`, `references`. Check `.metadata/diagram-plan.json` for pre-planned positions.
   - **Generic analyzer:** tag as `section` with depth.

Output: section map (held in memory — not written to disk).

---

### Phase 2: Enrichment Planning

> Decide WHAT visualization goes WHERE. Produce a reviewable plan.

Read `references/03-enrichment-catalog.md` for enrichment types, triggers, and scoring.

**Three-layer decision engine:**

**Layer 1 — Structural rules (report-type-specific, always apply):**

For trend-report:
| Section tag | Enrichment | Track |
|------------|------------|-------|
| `headline-evidence` | `kpi-dashboard` | data |
| `value-chain` (each) | `tips-flow` | concept |
| `horizon-distribution` | `horizon-chart` | data |
| `mece-validation` | `distribution-doughnut` | data |
| `evidence-coverage` | `coverage-heatmap` | data |
| `strategic-themes-table` | `theme-radar` | data |

For research-report (content-pattern-driven — fires based on section content, not heading text):
| Content pattern | Enrichment | Track |
|----------------|------------|-------|
| `executive-summary` + 3+ numeric claims | `kpi-dashboard` | data |
| `has-data-table` (numeric table with 4+ rows) | `comparison-bar` | data |
| `has-comparison` (table or prose comparing entities) | `comparison-bar` | data |
| `has-timeline` (3+ chronological dates) | `timeline-chart` | data |
| `has-distribution` (proportional data ~100%) | `distribution-doughnut` | data |
| `stat-dense` (5+ numeric claims clustered) | `stat-chart` | data |
| `has-process` (sequential steps / causal chain) | `process-flow` | concept |
| `has-synthesis` (cross-section aggregation) | `relationship-map` | concept |
| `has-thesis` + section >800 words | `summary-card` | html |
| `methodology` + `has-process` | `process-flow` | concept |
| Pre-planned (diagram-plan.json) | per-plan type | concept |

**Layer 2 — Content pattern detection (generic, scored):**

Scan each section's text for patterns:
- 3+ numeric claims in close proximity → `stat-chart` candidate (data)
- Table with 4+ rows of numeric data → `comparison-bar` or `distribution-doughnut` candidate (data)
- Process/sequence language ("leads to", "triggers", "results in") → `process-flow` candidate (concept)
- Comparison language ("vs", "compared to", "while X, Y") → `comparison-bar` candidate (data)
- Temporal references (dates, quarters, deadlines, milestones) → `timeline-chart` candidate (data)
- Section >800 words with identifiable thesis sentence → `summary-card` candidate (html)
- Theme interconnection (mentions 2+ other theme names) → `relationship-map` candidate (concept)

**Layer 3 — Scoring and spacing:**

Each candidate gets a score (0-100) based on:
- Data density: more numbers/rows = higher (max 40 points)
- Content relevance: how well the data fits the visualization type (max 30 points)
- Section importance: H2 > H3 > H4 (max 15 points)
- Variety bonus: +15 if this type hasn't been used anywhere in the plan yet (first use of a type), +10 if not used in last 3 enrichments, -15 if same type as previous enrichment, -10 if this type already accounts for 40%+ of all planned enrichments (prevents any single type from dominating)

Apply filters:
- Minimum distance: no two enrichments within 300 words of each other
- Density cap: `minimal` keeps top 5-8, `balanced` keeps top 10-15, `rich` keeps top 15-22
- Type whitelist/blacklist from parameters
- **Appendix exclusion:** Never place enrichments inside appendix sections (Quellenregister, Claims Registry, References, Bibliography). These are data sources, not visualization hosts. Charts derived from appendix data belong in the last narrative section before the appendix.
- **Synthesis affinity:** Cross-theme aggregate charts (claims distribution, investment comparison across all themes) belong in the synthesis/closing section, placed after the paragraph containing the aggregate numbers.

**Theme consistency check (trend-report):**

After scoring, verify that every investment theme H2 section has at least 2 enrichments at `balanced` density:
1. A `summary-card` (key takeaway at the theme opening)
2. One data chart (best fit: `comparison-bar` for cost comparisons, `timeline-chart` for deadline-heavy themes, `stat-chart` for evidence clusters)

If a theme has fewer than 2, force-add from this baseline. Score force-added items at 50. This prevents the visual rhythm from breaking — all themes share the same internal structure, so they must share a consistent visual baseline. See `references/03-enrichment-catalog.md` "Theme Consistency Rule" for full details.

**Section consistency check (research-report):**

After scoring, verify that data-rich H2 sections (600+ words AND at least one content-pattern data tag: `has-data-table`, `stat-dense`, `has-comparison`, `has-timeline`, `has-distribution`) have at least 1 enrichment at `balanced` density:
1. A `summary-card` (if `has-thesis` detected — section >800 words with thesis sentence)
2. One data chart (highest-scoring match from content-pattern structural rules)

If a qualifying section has fewer enrichments than baseline, force-add. Score force-added `summary-card` at 40, data charts at 35. Sections without any content-pattern data tags are pure analytical prose — do NOT force enrichments. See `references/03-enrichment-catalog.md` "Section Consistency Rule" for full details.

**Data extraction completeness:** Every enrichment needs a non-empty `data` field containing the extracted values that Phase 4 will use to generate the visualization. An enrichment with `"data": {}` forces the Python generator to re-parse the markdown during HTML assembly, which is brittle and error-prone — extract the data during Phase 2 while the section content is being analyzed:
- `kpi-dashboard`: `stats[]` with value, label, source_url
- `comparison-bar`: `items[]` with label and value (from table rows or comparison pairs)
- `stat-chart`: `claims[]` with value, label, unit
- `timeline-chart`: `events[]` with date, label, category
- `distribution-doughnut`: `segments[]` with label, value, percentage
- `process-flow`: `steps[]` with label, sublabel, and `connections[]`
- `relationship-map`: `nodes[]` and `connections[]` with labels
- `summary-card`: `summary` text and `word_count`

If you cannot extract meaningful data for an enrichment, demote it (lower its score by 20) rather than leaving `data` empty.

**Injection line precision:** Every enrichment needs an `injection_after_line` value pointing to the specific source line after which it should appear. When multiple enrichments target the same section, spread them across different paragraphs — do NOT give them all the same line number. The Python generator uses these lines to interleave enrichments within the section content. If all enrichments share one line, they stack together at one position instead of being distributed through the prose.

**Output:** `enrichment-plan.json` (written to `{source_dir}/cogni-visual/enrichment-plan.json`):

```json
{
  "report_type": "trend-report",
  "source_path": "tips-trend-report.md",
  "density": "balanced",
  "total_enrichments": 12,
  "enrichments": [
    {
      "id": "enr-001",
      "type": "kpi-dashboard",
      "track": "data",
      "target_section": "executive-summary",
      "injection_after_line": 42,
      "description": "5 KPI cards for headline evidence numbers",
      "score": 95,
      "data": { "stats": [{"value": "€173B", "label": "Utility CAPEX 2026", "source": "ING Think"}] },
      "priority": "structural"
    }
  ]
}
```

---

### Phase 3: Interactive Review

> Let the user approve, modify, or skip enrichments before generation.

When `interactive=true`:
1. Present enrichment plan summary via AskUserQuestion:
   - Total enrichments planned, breakdown by track (data/concept) and type
   - Condensed list: enrichment type + target section + description
   - Options: "Approve all (Recommended)", "Approve with exclusions", "Adjust density", "Cancel"
2. If "Approve with exclusions": present checklist via AskUserQuestion (multiSelect).
3. On empty response: auto-approve all.

When `interactive=false`: auto-approve all, log plan.

---

### Phase 4: Visualization Generation

> Generate Chart.js configs and Excalidraw SVGs for each approved enrichment.

Read `references/04-chart-patterns.md` for Chart.js configuration templates.
**Data track (Chart.js):**

For each data-track enrichment:
1. Extract structured data from the section content (parse tables into arrays, extract numeric claims with labels).
2. Select Chart.js chart type from `04-chart-patterns.md` template.
3. Generate Chart.js configuration JSON:
   - `chart_id` — unique identifier matching `enr-XXX`
   - `type` — Chart.js type (bar, doughnut, radar, line, pie, polarArea)
   - `data` — labels and datasets with values
   - `options` — themed: colors from `var(--accent)`, `var(--primary)`, etc.; font-family from `var(--font-body)`; grid colors from `var(--border)`
4. Chart dimensions: max-width 720px, height auto by type (bar: 400px, doughnut: 350px, radar: 400px, line: 350px).

**Concept track (Excalidraw via concept-diagram agent):**

For each concept-track enrichment, sequentially:
1. Read the section content and extract the conceptual structure (e.g., T→I→P→S chain: trend name, implication names, possibility names, solution names).
2. Select `diagram_type` based on the enrichment type from the enrichment plan: `tips-flow` for T→I→P→S chains, `relationship-map` for theme interconnections, `process-flow` for sequential workflows, `concept-sketch` for layered/convergence/phase/matrix patterns.
3. Dispatch to `concept-diagram` agent with: `DIAGRAM_TYPE`, `DATA` (structured payload extracted from section), `DESIGN_VARIABLES` (from design-variables), `LANGUAGE`.
4. Collect SVG string from agent JSON response (`svg` field).
5. Write SVG to `{source_dir}/cogni-visual/svgs/enr-XXX.svg`.

Concept diagrams are dispatched sequentially (not in parallel) because all agents share one Excalidraw canvas — parallel clear/build/export would corrupt each other's work. Each diagram is 10-25 elements, so sequential execution is fast.

---

### Phase 5: HTML Assembly

> Merge report content + visualizations into themed HTML.

Read `references/06-html-structure.md` for HTML layout and CSS architecture.

Run the Python generator script:

```bash
python3 {SKILL_PATH}/scripts/generate-enriched-report.py \
  --source "{source_path}" \
  --enrichment-plan "{source_dir}/cogni-visual/enrichment-plan.json" \
  --chart-configs "{source_dir}/cogni-visual/chart-configs.json" \
  --svg-dir "{source_dir}/cogni-visual/svgs/" \
  --design-variables "{design_variables_path}" \
  --output "{output_path}" \
  --language "{language}"
```

Before calling the script:
1. Write `chart-configs.json` — array of all Chart.js configs from Phase 4.
2. Write SVG files to `{source_dir}/cogni-visual/svgs/enr-XXX.svg` — one per Excalidraw diagram.

The script:
1. Parses markdown → HTML sections (headings, paragraphs, tables, blockquotes, code blocks, inline citations → `<a>` links).
2. Injects CSS custom properties from design-variables.json into `:root {}`.
3. At each enrichment injection point (by line number from plan):
   - Data enrichments: `<div class="enrichment chart-container" data-type="..."><canvas id="enr-XXX"></canvas></div>`
   - Concept enrichments: `<div class="enrichment concept-diagram" data-type="...">` + inline SVG + `</div>`
   - Summary cards: `<div class="enrichment summary-card">` + styled content + `</div>`
4. Adds sticky navigation sidebar (generated from heading hierarchy).
5. Adds responsive CSS (max-width content, visualization breakpoints).
6. Appends Chart.js CDN script + initialization code per chart.
7. Injects Google Fonts import from design-variables.

---

### Phase 6: Validation & Output

> Verify the enriched HTML is complete and correct.

**Five validation gates:**

1. **Content completeness** — every H2 section heading from source appears in HTML (grep section IDs).
2. **Citation preservation** — count `<a href=` in HTML >= count of `[text](url)` in source markdown.
3. **Chart validity** — every `<canvas id="enr-XXX">` has a corresponding `new Chart('enr-XXX', ...)` in the script block.
4. **SVG integrity** — every inline `<svg` block is well-formed (has closing `</svg>`).
5. **Theme compliance** — no hardcoded `#hex` values in chart configs or enrichment containers (scan for hex outside `:root`).

If any gate fails: fix the specific issue and re-validate. Do not regenerate from scratch.

**Output:** Write the HTML file to `output_path`. Open it in the browser for the user.

Print summary:
- Enrichments injected: N (data: X, concept: Y, html: Z)
- Output: {output_path}
- Theme: {theme_name}
- Skipped: {any enrichments that failed generation, with reasons}

---

### Phase 7: Format Export (conditional)

> Convert the enriched HTML to PDF or DOCX when requested.

This phase only runs when `formats` includes `pdf` or `docx`. The HTML output from Phase 5/6 is always the starting point.

**PDF export:**

1. Read `references/07-citation-normalization.md` — not for HTML citations (which are already correct), but for understanding the citation landscape in case pre-processing is needed.
2. **Mermaid pre-rendering**: If the HTML contains `<pre class="mermaid">` blocks, these render client-side via JavaScript and will appear blank in static PDF conversion. Pre-render them before PDF generation:
   - Try `mmdc` (mermaid-cli): extract Mermaid source → render to SVG → replace in HTML
   - Fallback: use Excalidraw MCP (`mcp__excalidraw__create_from_mermaid` → `export_to_image`)
   - Last resort: leave as code blocks and note the limitation to the user
3. **Chart.js pre-rendering**: Chart.js `<canvas>` elements also require JavaScript. For PDF with charts, `document-skills:pdf` can execute JS during rendering. If using weasyprint (no JS), charts will be blank — inform the user and suggest `density=none` for chart-free PDF.
4. **Generate PDF**:
   - Preferred: `Skill(document-skills:pdf)` from the enriched HTML. Pass `design-variables.json` for theme token access.
   - Fallback: If weasyprint is available: `python3 -c "import weasyprint; weasyprint.HTML(filename='{html_path}').write_pdf('{pdf_path}')"`
   - Last resort: Inform user the HTML is available and suggest browser print-to-PDF
5. Output: `{output_dir}/{stem}-enriched.pdf`

**DOCX export:**

DOCX cannot represent interactive charts or inline SVG. Convert from the original markdown source (not the HTML) to preserve clean document structure.

1. Read `references/07-citation-normalization.md` for citation normalization patterns.
2. Normalize citations in the markdown: parse the `## References` section, replace inline citation patterns with numbered superscript markers, strip the original references section.
3. **Generate DOCX**:
   - Preferred: `Skill(document-skills:docx)` from the normalized markdown. Pass theme tokens: `heading_font` (fonts.headers), `body_font` (fonts.body), `accent_color` (colors.accent).
   - Fallback: If pandoc is available: `pandoc {md_path} -o {docx_path} --from markdown --to docx`
   - Last resort: Inform user and suggest `brew install pandoc` or `pip install pandoc`
4. Output: `{output_dir}/{stem}.docx`

**Report to user:**

After all requested formats are generated:
- List exported files with paths and file sizes
- Note which theme was applied
- Note any limitations (e.g., "PDF generated without charts — use browser print for charts" or "DOCX contains text only — charts are in the HTML version")

---

## Bundled Resources

| Reference | Loaded at | Purpose |
|-----------|-----------|---------|
| `references/01-report-detection.md` | Phase 0 | Report type detection heuristics and frontmatter patterns |
| `references/02-section-analysis.md` | Phase 1 | Section mapping rules per report type, data extraction patterns |
| `references/03-enrichment-catalog.md` | Phase 2 | Enrichment types, trigger conditions, scoring model, density thresholds |
| `references/04-chart-patterns.md` | Phase 4 | Chart.js config templates per chart type, themed with CSS variables |
| `references/05-excalidraw-patterns.md` | Phase 4 | Excalidraw element recipes for concept diagrams |
| `references/06-html-structure.md` | Phase 5 | HTML layout, CSS architecture, responsive breakpoints, script structure |
| `references/07-citation-normalization.md` | Phase 7 | Citation format detection and normalization for DOCX export |
| `schemas/design-variables.schema.json` | Phase 0 | JSON schema for design-variables validation |
| `schemas/enrichment-plan.schema.json` | Phase 2 | JSON schema for enrichment plan validation |
| `scripts/generate-enriched-report.py` | Phase 5 | Python HTML generator (markdown→HTML, theme injection, chart mounting) |
