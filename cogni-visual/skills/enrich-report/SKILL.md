---
name: enrich-report
description: >
  Use this skill whenever the user has an existing markdown report and wants it
  transformed into a polished visual deliverable. This is the go-to skill for
  turning any completed .md report into themed HTML with interactive Chart.js
  charts, an infographic header, sidebar navigation, and inline SVG concept
  diagrams — or exporting it to PDF or DOCX. Trigger for any request that
  involves an already-written report needing visual enrichment, format
  conversion, or presentable output: adding charts or diagrams to a report,
  making a report look good or presentable, generating an HTML version of a
  report, exporting a report as PDF or Word, enriching a report with
  visualizations, or converting a text-only report into a themed deliverable.
  Also trigger for German equivalents (Bericht visualisieren, als PDF
  exportieren, Diagramme hinzufuegen). The key signal is that the user already
  has a finished report file and wants to make it visual or export it — this
  skill post-processes existing content, it never creates new reports from
  scratch (that is cogni-research or cogni-trends), never creates slides (that
  is story-to-slides), and never rewrites prose (that is cogni-copywriting).
---

# Enrich Report

## Purpose

Read a completed markdown report and produce a **self-contained HTML file** that presents the same content with interactive data visualizations and conceptual diagrams injected at semantically appropriate positions. The original markdown stays untouched — you are creating a visual rendition, not editing the source.

A great enriched report does not just decorate prose with random charts. Each visualization earns its place by making a data pattern visible that would otherwise require the reader to mentally parse numbers from text, or by making a conceptual relationship (like a T→I→P→S value chain) spatially comprehensible. If a section has no data worth charting and no concept worth diagramming, leave it as styled prose — over-enrichment is worse than no enrichment.

## Two-Zone Architecture

The enriched report uses a two-zone layout — an infographic header for visual data storytelling, and a prose body for deep reading:

1. **Infographic header** — A page-filling editorial visual executive summary at the top of the HTML. Contains KPI cards, 1-2 charts, optional pull-quote, optional comparison pair. Distilled from the complete report using story-to-infographic editorial-preset principles. Designed to be scanned in 60 seconds. This is where ALL the data visualization lives.
2. **Report body** — The full prose report with sidebar navigation below the infographic. Every paragraph, citation, table, blockquote, list, and subsection heading from the source markdown appears verbatim. Very sparse illustrations only (3-5 max at `balanced` density): process-flows, concept diagrams, or key comparison charts — only where a visual genuinely aids comprehension of a specific passage.

This matches the consulting deliverable pattern: executive one-pager up front, detailed report below. The infographic satisfies the desire for visuals; the report body stays clean and readable.

## Architecture

The pipeline splits creative and deterministic work between an LLM agent and a Python script:

- **`report-html-writer` (opus agent)** — writes the complete self-contained HTML: CSS, Chart.js configs, inline SVG diagrams, sidebar navigation, and all report prose. Receives a clean context (source markdown, enrichment plan, design variables) so it can focus on contextual chart design and content-preserving markdown-to-HTML conversion. Two visualization tracks:
  - **Data track** — Chart.js charts (bar, doughnut, radar, line, scatter, combo) with multi-dataset configs, themed colors from design-variables.
  - **Concept track** — LLM-crafted inline SVG (no Excalidraw dependency) for flows, relationship maps, concept sketches. Uses `${CLAUDE_PLUGIN_ROOT}/libraries/svg-patterns.md` recipes.

- **`generate-enriched-report.py --post-process` (Python script)** — handles deterministic post-processing after the agent writes the HTML:
  - Flipbook assembly (when `--layout flipbook`) — transforms scroll HTML into paginated two-page spreads
  - Infographic injection (HTML fragment > PNG base64 > JSON fallback)
  - Content preservation validation (word count >= 80%, heading count, citation count)
  - Enrichment plan validation (density caps, type restrictions)

This division matters because chart design benefits from LLM creativity (contextual axis labels, multi-dataset scenario modeling, chart type selection), while infographic embedding and content verification need deterministic correctness.

**Content preservation** — every paragraph, citation, table, blockquote, and heading from the source markdown appears verbatim in the HTML output. Enrichments are injected *between* existing prose, never replacing it. The validation gate enforces a hard floor: HTML word count >= 80% of source, with H2 and citation counts matching. This matters because the enriched report is a *visual rendition* of the source — readers who know the original will notice missing content.

**Visual subordination** — in the report body, content max-width is 860px while enrichment max-width is 720px (centered). Charts max 300px height. This size difference signals that text is the backbone and visuals are insets. Dashboard patterns (hero banners, KPI grids, section-lead summaries) belong in the infographic header, not the report body.

**Theming** follows the 3-stage design-variables pattern from cogni-workspace:
1. User picks theme via `cogni-workspace:pick-theme`
2. LLM derives `design-variables.json` from theme.md
3. All colors in Chart.js configs and SVGs reference the design-variables palette — the same report can be re-themed by swapping the JSON

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Report markdown file path |
| `output_path` | layout-aware (see below) | HTML output path. Default: `{dir}/output/{stem}-enriched.html` for scroll, `{dir}/output/{stem}-enriched-flipbook.html` for flipbook. Explicit value overrides the convention. |
| `report_type` | `auto` | Override detection: `trend-report`, `research-report`, `generic` |
| `language` | from frontmatter | `en` or `de` — affects chart labels, axis titles, summary card text |
| `theme` | interactive | Theme path, or omit to trigger `cogni-workspace:pick-theme` |
| `design_variables` | derived from theme | Pre-computed design-variables.json path (skips derivation) |
| `layout` | `scroll` | HTML layout mode: `scroll` (sidebar + continuous scroll — classic), `flipbook` (two-page spread with 3D page-curl animation — magazine-like reading experience). |
| `density` | `balanced` | Report-body enrichment density: `none` (0 visuals, themed prose only), `minimal` (1-2), `balanced` (3-5), `rich` (5-8). The infographic header is always generated regardless of density. |
| `formats` | `["html"]` | Output formats: `html`, `pdf`, `docx`. HTML is always produced first; PDF/DOCX are derived from it. |
| `interactive` | `true` | Interactive enrichment review checkpoint at Phase 3 |
| `enrichment_types` | all | Whitelist: e.g., `["kpi-dashboard", "tips-flow", "horizon-chart"]` |
| `skip_types` | none | Blacklist: e.g., `["summary-card"]` |

## Conventions

### German fidelity

German reports use real Unicode umlauts (ä ö ü ß), dot-separated thousands (2.661), and German chart axis labels. ASCII substitutions (ae/oe/ue) undermine credibility with German-speaking readers who immediately notice them.

### Density controls report-body enrichment volume

The `density` parameter gates how many **report-body** enrichments pass through. The infographic header is always generated regardless of density.

- **none** — Infographic header + themed prose only. No inline charts or diagrams in the report body. Good for "make it pretty" or as a clean base for PDF/DOCX export.
- **minimal** — 1-2 report-body illustrations. Only where essential for comprehension.
- **balanced** — 3-5 report-body illustrations. Default. Sparse and purposeful.
- **rich** — 5-8 report-body illustrations. For workshop materials or visual-heavy reading.

When `density=none`: skip Phase 2b (enrichment planning). Still run Phase 2a (infographic distillation). Go to Phase 4 with an empty enrichment plan but valid infographic data.

The Python script enforces density caps deterministically — even if the enrichment plan exceeds the limit, the script trims to the cap and logs what was dropped.

---

## Workflow

### Execution protocol

Each phase: verify the previous phase's output exists (entry gate), load the reference file for that phase, execute, state output summary. Reference files contain phase-specific rules — read them at the start of each phase, not all at once.

---

### Phase 0: Report Discovery & Setup

> Find the report, detect its type, set up theming.

**If `source_path` provided:** use directly, then resolve `source_dir` to the **project root** — the directory that contains `cogni-visual/`, `output/`, and other project subdirectories. This matters because cogni-research and cogni-trends projects store the report inside `output/` but the visual artifacts (infographic, enrichment plan, design variables) live in `cogni-visual/` at the project root level, not inside `output/`.

Resolution logic:
1. Set `candidate = parent(source_path)` (e.g., `.../project-slug/output/`)
2. If `candidate` ends with `output` or `output/` AND `parent(candidate)/cogni-visual/` exists: set `source_dir = parent(candidate)` (project root)
3. Else if `candidate/cogni-visual/` exists: set `source_dir = candidate`
4. Else: set `source_dir = candidate` (fallback — create `cogni-visual/` here during Phase 2a)

This ensures the skill finds pre-existing infographic artifacts regardless of whether the report is at the project root or nested in `output/`.

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

**Layout selection:**
If `layout` was not provided as a parameter, ask the user via AskUserQuestion:
- Header: "Layout"
- Question: "How should the enriched report be presented?"
- Options:
  1. "Scroll (Recommended)" — "Classic sidebar + continuous scroll. Best for long reading sessions and printing."
  2. "Flipbook" — "Magazine-style two-page spread with 3D page-turning. Best for executive presentations and visual impact."
- Default (empty response): `scroll`

**Output path resolution:**
If `output_path` was not explicitly provided:
- `scroll`: `{source_dir}/output/{stem}-enriched.html`
- `flipbook`: `{source_dir}/output/{stem}-enriched-flipbook.html`

This naming convention lets both layouts coexist on disk without overwriting each other. An explicit `output_path` parameter overrides the convention.

Store: `report_type`, `source_path`, `source_dir`, `language`, `layout`, `output_path`, `design_variables` (the JSON object).

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

### Phase 2a: Infographic Brief Generation (story-to-infographic pipeline)

> Detect existing infographic artifacts from a prior story-to-infographic run, or generate from scratch.

This phase produces a DIN A4 portrait infographic (Economist data-page style). Before generating anything, check for pre-existing artifacts — the user may have already run `story-to-infographic` + `/render-infographic` on this report for a higher-quality infographic (10-step distillation with 4-layer validation and reviewer agent, vs. the simplified inline distillation below).

**Step 2a.0 — Artifact detection (check before generating):**

Check for rendered infographic artifacts in `{source_dir}/cogni-visual/` only (the canonical location for all visual working artifacts):
- `{source_dir}/cogni-visual/infographic-fragment.html` (HTML fragment — highest quality, responsive, selectable text)
- `{source_dir}/cogni-visual/infographic-preview.png` (PNG — pixel-perfect fallback)

**Migration (v0.16.11):** If `infographic-preview.png` is not found, also check for the legacy filename `preview.png` in `{source_dir}/cogni-visual/`. If found, rename it to `infographic-preview.png` and continue.

1. **Rendered artifacts exist:** `{source_dir}/cogni-visual/infographic-fragment.html` OR `{source_dir}/cogni-visual/infographic-preview.png`
   - If any file exists: **skip all of Phase 2a**. The infographic is already rendered.
   - Tell the user: "Reusing existing infographic artifacts (skipping distillation + render)."
   - Store the path to the best artifact found (HTML fragment preferred over PNG).
   - If `{source_dir}/cogni-visual/infographic-brief.md` also exists, read its `style_preset` from YAML frontmatter and note it: "Detected style_preset: {preset}." This is informational only — do not block or re-generate based on preset.
   - `infographic-data.json` is NOT required when rendered artifacts exist — the post-processor uses the HTML fragment (highest quality) or PNG directly.
   - Proceed to Phase 2b.

2. **Brief exists but no render:** `{source_dir}/cogni-visual/infographic-brief.md` exists but no rendered artifact (fragment HTML or PNG) was found
   - The brief was generated (by story-to-infographic or a prior interrupted run) but never rendered.
   - Tell the user: "Found existing infographic-brief.md without rendered output. Dispatching renderer."
   - Dispatch the `render-infographic-pencil` agent with the brief:
     - Input: `{source_dir}/cogni-visual/infographic-brief.md`
     - Output .pen: `{source_dir}/cogni-visual/infographic.pen`
     - Export PNG: `{source_dir}/cogni-visual/infographic-preview.png`
     - Export HTML fragment: `{source_dir}/cogni-visual/infographic-fragment.html` (generated by Step 5b of the agent — best-effort, the PNG is the minimum)
   - If Pencil MCP is not available: ask the user to open Pencil. If they decline, fall through to path 3 below to generate `infographic-data.json` for the HTML fallback.
   - Proceed to Phase 2b.

3. **Neither exists:** Run the full distillation below (Step 2a.1 + Step 2a.2).

**Step 2a.1 — Generate infographic brief (only if path 3):**

Read `references/08-infographic-distillation.md` for distillation principles.

Scan the entire report and produce an `infographic-brief.md` following the story-to-infographic v1.2 schema (see `cogni-visual/libraries/EXAMPLE_ECONOMIST_BRIEF.md` for format reference):

- **Frontmatter:** `type: infographic-brief`, `version: "1.2"`, `style_preset: "economist"`, `layout_type: "stat-heavy"`, `orientation: "portrait"`, `dimensions: "1584x2240"` (DIN A4 portrait at 2x), `language`, `theme_path`, `palette_override: "theme"`, `voice_tone: "analytical"`
- **Content blocks (10-14):** title, kpi-card (hero number), stat-rows, chart (1-2), text-blocks, pull-quote, comparison-pair, CTA, footer — all following the block-type YAML format from story-to-infographic

Distillation rules:
1. **Governing assertion** — the report's thesis as a self-contained sentence (verb + quantified consequence)
2. **3-5 hero numbers** — transformation magnitudes first, then scale, time, unique specifics
3. **1-2 chart candidates** — the most impactful data tables or stat clusters
4. **Pull-quote (0-1)** — strongest qualitative insight, max 25 words
5. **Comparison pair (0-1)** — Handeln vs. Nichthandeln, before/after, or international comparison

Apply the 60-second read test. Write brief to `{source_dir}/cogni-visual/infographic-brief.md`.

Also write `infographic-data.json` (the structured subset used by the HTML fallback renderer) to `{source_dir}/cogni-visual/infographic-data.json`. Validate against `schemas/infographic-data.schema.json`.

**Step 2a.2 — Render infographic via Pencil MCP (only if path 2 or 3):**

Dispatch the `render-infographic-pencil` agent (editorial family, Economist preset) with the brief:
- Input: `{source_dir}/cogni-visual/infographic-brief.md`
- Output .pen: `{source_dir}/cogni-visual/infographic.pen`
- Export PNG: `{source_dir}/cogni-visual/infographic-preview.png`
- Export HTML fragment: `{source_dir}/cogni-visual/infographic-fragment.html` (Step 5b of the agent — best-effort)

The agent uses Pencil MCP tools (`open_document`, `batch_design`, `export_nodes`) to render the brief as a pixel-precise editorial data page. The PNG is exported at 2x scale for retina clarity. After the PNG export, the agent reads the .pen design tree back and generates an embeddable HTML fragment (same tree-walking approach as the web.md agent). The HTML fragment is the highest-quality integration path — native HTML with Pencil's editorial precision, selectable text, and responsive layout — but it is best-effort; the PNG is the minimum viable output.

**If Pencil MCP is not available** (not open, not installed): Ask the user to open Pencil. Do NOT silently fall back to the HTML-based infographic — the Pencil-rendered version is the intended output quality. If the user declines, fall back to the HTML infographic from `infographic-data.json` and note the limitation.

**Output artifacts (vary by path):**

| Path | infographic-brief.md | infographic.pen | infographic-preview.png | infographic-fragment.html | infographic-data.json |
|------|---------------------|----------------|------------------------|--------------------------|----------------------|
| 1 (render exists) | pre-existing | pre-existing | pre-existing (reused) | pre-existing or absent | not needed |
| 2 (brief only) | pre-existing | generated | generated | generated (best-effort) | not generated |
| 3 (from scratch) | generated | generated | generated | generated (best-effort) | generated |

**Three-tier infographic priority in Phase 4:** The post-processor uses the highest-quality artifact available: HTML fragment (native responsive HTML with Pencil's editorial precision, selectable text, responsive layout) > PNG (pixel-perfect base64 with magazine peek strip + lightbox) > JSON fallback (template-generated inline HTML). The HTML fragment is preferred because it preserves text selectability, link clickability, and responsive layout from Pencil's tree-walk conversion.

---

### Phase 2b: Sparse Enrichment Planning

> Plan very sparse report-body illustrations. The infographic already covers data storytelling.

Read `references/03-enrichment-catalog.md` — it contains the complete enrichment type catalog, structural rules per report type, content-pattern detection triggers, scoring model (0-100 with data density, content relevance, section importance, and variety bonuses), spacing rules, theme/section consistency checks, and density thresholds. Follow it as the authoritative reference for this phase.

The high-level decision flow:

1. **Layer 1 — Structural rules** fire based on section tags from Phase 1 (report-type-specific). See the catalog's structural rules tables.
2. **Layer 2 — Content pattern detection** scans section text for numeric clusters, process language, comparison language, temporal references. See the catalog's content-pattern triggers.
3. **Layer 3 — Scoring and filtering** ranks candidates, applies table-proximity demotion, minimum distance (300 words), density caps, type whitelist/blacklist, appendix exclusion, and synthesis affinity. See the catalog's scoring reference.
4. **Consistency checks** ensure visual rhythm across sections — theme consistency (trend-report) and section consistency (research-report). See the catalog's consistency rules.

**Key editorial principles** (the "why" behind the scoring model):
- **Table-proximity demotion:** Charts that restate data from an adjacent markdown table waste space. A chart earns its place by revealing patterns the table cannot — cross-section comparisons, time-series trends, scenario projections. Demote by 30 points or skip when chart data duplicates a table.
- **Appendix exclusion:** Reference sections (Quellenregister, Claims Registry, References) are data sources, not visualization hosts. Charts derived from appendix data belong in the last narrative section before the appendix.

**Chart config authoring:** For every data-track enrichment, write a complete Chart.js config in `chart_config` — a JSON object with `type`, `data`, and `options`. The `report-html-writer` agent embeds these verbatim, so you have full creative control: multiple datasets, combo types, dual axes, fills, annotations. Use hex values from `design_variables.colors` for all chart colors. The `data` field is also required alongside `chart_config` as structured metadata for validation and fallback.

**Injection line precision:** Every enrichment needs `injection_after_line` pointing to a specific source line. When multiple enrichments target the same section, spread them across different paragraphs — stacking them at one line number clusters visuals instead of distributing them through the prose.

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
      "priority": "structural",
      "chart_config": {
        "type": "bar",
        "data": {
          "labels": ["2021", "2023", "2025", "2026", "2030"],
          "datasets": [
            {"label": "Conservative", "data": [9.2, 10.2, 11.8, 14.8, 20.7], "backgroundColor": "#007C9240", "borderColor": "#007C92", "borderWidth": 2, "borderRadius": 4},
            {"label": "Aggressive", "data": [9.2, 10.2, 11.8, 14.8, 66.5], "backgroundColor": "#E2007420", "borderColor": "#E20074", "borderWidth": 2, "borderDash": [6, 3], "borderRadius": 4}
          ]
        },
        "options": {"responsive": true, "plugins": {"legend": {"position": "bottom"}}, "scales": {"y": {"beginAtZero": true, "title": {"display": true, "text": "USD Billion"}}}}
      }
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

### Phase 4: HTML Assembly

> Dispatch the `report-html-writer` agent to produce the complete HTML file with Chart.js charts, inline SVGs, and sidebar navigation, then inject the infographic and validate content preservation.

HTML writing is the quality-critical step in the pipeline — it requires producing themed, responsive, content-preserving HTML with rich Chart.js configs and inline SVG diagrams. This work is delegated to the dedicated `report-html-writer` opus agent, which receives a clean context with only the inputs it needs (source markdown, enrichment plan, design variables, and reference files). The agent writes scroll-mode HTML for both layouts. For flipbook mode, the agent adds cover markers and lazy chart init, then the Python post-processor transforms the scroll HTML into the flipbook layout (block wrapping, pagination engine, cover extraction, flipbook CSS/JS). This two-phase assembly keeps the agent's output focused on creative work (chart design, SVG crafting, content conversion) while deterministic flipbook infrastructure is handled by the script.

**Dispatch the `report-html-writer` agent:**

```
Agent(report-html-writer):
  SOURCE_PATH: {source_path}
  OUTPUT_PATH: {output_path}
  ENRICHMENT_PLAN_PATH: {source_dir}/cogni-visual/enrichment-plan.json
  DESIGN_VARIABLES_PATH: {design_variables_path}
  LANGUAGE: {language}
  LAYOUT: {layout}
  INFOGRAPHIC_IMAGE: {actual_png_path_from_phase_2a}
  INFOGRAPHIC_HTML: {actual_html_fragment_path_from_phase_2a}
  INFOGRAPHIC_DATA: {source_dir}/cogni-visual/infographic-data.json
  SCRIPT_PATH: {SKILL_PATH}/scripts/generate-enriched-report.py
```

Omit `INFOGRAPHIC_IMAGE`, `INFOGRAPHIC_HTML`, or `INFOGRAPHIC_DATA` if the corresponding artifact does not exist from Phase 2a.

**Expected response:** JSON with `ok`, `output_path`, `enrichments` (total/data/concept/html counts), `preservation` (source vs HTML word counts, heading counts, citation counts), and `post_processor` (infographic tier used, validation pass/fail).

**If `ok` is false:** Read the error, fix the underlying issue (missing enrichment plan, invalid design variables, post-processor script error), and re-dispatch.

**If `preservation.ratio` < 0.80:** The HTML has lost narrative content. Check which sections are missing and re-dispatch with a note about the missing sections.

---

### Phase 5: Validation & Output

> Verify the enriched HTML is complete and correct.

**Six validation gates:**

1. **Content completeness** — every H2 section heading from source appears in HTML (grep section IDs or heading text).
2. **Citation preservation** — count `<a href=` in HTML >= count of `[text](url)` in source markdown.
3. **Chart validity** — every `<canvas` element has a corresponding `new Chart(...)` in the script block.
4. **SVG integrity** — every inline `<svg` block is well-formed (has closing `</svg>`).
5. **Infographic presence** — the HTML contains the infographic (grep for `infographic` class or `ig-lightbox` id). If missing, the post-processor failed — re-run or inject manually.
6. **Content preservation** — HTML word count (excluding infographic and chart containers) >= 80% of source word count, and HTML `<h2>` count >= source `##` count.

If any gate fails: fix the specific issue and re-validate. Do not regenerate from scratch.

**Output:** Write the HTML file to `output_path`. Open it in the browser for the user.

Print summary:
- Enrichments injected: N (data: X, concept: Y, html: Z)
- Output: {output_path}
- Layout: {layout}
- Theme: {theme_name}
- Skipped: {any enrichments that failed generation, with reasons}

---

### Phase 5b: Visual Quality Review (conditional)

> Visually inspect the rendered HTML to catch layout, theming, and rendering issues that automated validation cannot detect — broken Chart.js initialization, theme colors not applied, text overflow, sidebar missing, enrichments clustered together, infographic header failures.

This phase uses Browser MCP to navigate to the enriched HTML, take screenshots at three viewport positions, and evaluate what a human reader would see. It extends the screenshot-based visual review pattern to the full enriched report.

**When Browser MCP is available:** Dispatch the `enriched-report-reviewer` agent:

```
Agent(enriched-report-reviewer):
  HTML_PATH: {output_path}
  DESIGN_VARIABLES_PATH: {design_variables_path}
  ENRICHMENT_PLAN_PATH: {source_dir}/cogni-visual/enrichment-plan.json
```

The agent takes 3 screenshots (infographic header, report body, chart-heavy section), evaluates 10 quality gates (scored 0-10), and returns structured JSON with gate scores and fix recommendations.

**Decision logic:**
- Score >= 8.0: **ACCEPT** — proceed to Phase 6.
- Score < 8.0 on first pass: **FIX** — the agent applies targeted corrections to intermediate artifacts (`design-variables.json`, `enrichment-plan.json`), re-runs `generate-enriched-report.py`, and re-evaluates. Maximum 2 review passes.
- Score < 8.0 on second pass: **ACCEPT WITH WARNINGS** — proceed to Phase 6 with known issues logged.

**When Browser MCP is unavailable:** Skip Phase 5b entirely. The 6 automated validation gates from Phase 5 remain the quality floor. Log: "Visual review skipped — Browser MCP not available."

---

### Phase 5c: Alternative Layout Offer (conditional)

> Offer to generate the other layout style so the user can have both versions.

This phase runs when `interactive=true` (default) and the primary HTML was written successfully.

**Determine alternative:**
- If current `layout` == `scroll`: alternative is `flipbook`, alternative path is `{source_dir}/output/{stem}-enriched-flipbook.html`
- If current `layout` == `flipbook`: alternative is `scroll`, alternative path is `{source_dir}/output/{stem}-enriched.html`

**Skip if alternative already exists** on disk — both layouts are already available. Print: "Both layouts available: {output_path} and {alt_output_path}" and proceed to Phase 6.

**Ask via AskUserQuestion:**
- Header: "Alternative Layout"
- Question: "The {layout} version is ready. Would you also like a {alternative} version?"
- Options:
  1. "Yes" — "Reuses the same theme, enrichment plan, and infographic. Only re-runs HTML assembly and validation."
  2. "No thanks"
- Default (empty response): skip

**If accepted:**
1. Set `alt_output_path` to the alternative path derived above.
2. Re-dispatch the `report-html-writer` agent with the SAME inputs as Phase 4, except:
   - `OUTPUT_PATH`: `{alt_output_path}`
   - `LAYOUT`: `{alternative}`
   All other parameters (SOURCE_PATH, ENRICHMENT_PLAN_PATH, DESIGN_VARIABLES_PATH, LANGUAGE, INFOGRAPHIC_*, SCRIPT_PATH) remain identical.
3. Run Phase 5 validation gates on the alternative output.
4. Run Phase 5b visual review on the alternative output (if Browser MCP is available).
5. Print: "Both layouts generated: {output_path} ({layout}) and {alt_output_path} ({alternative})"

Do NOT re-run Phases 0-3. The enrichment plan, design variables, and infographic artifacts are layout-independent — only the HTML assembly and post-processing differ.

---

### Phase 6: Format Export (conditional)

> Convert the enriched HTML to PDF or DOCX when requested.

This phase only runs when `formats` includes `pdf` or `docx`. The HTML output from Phase 4/5 is always the starting point. If both layouts were generated in Phase 5c, export from the primary layout only.

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
5. Output: `{output_dir}/{stem}-enriched.pdf` (scroll) or `{output_dir}/{stem}-enriched-flipbook.pdf` (flipbook). Mirror the layout suffix from the HTML filename.

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
- If both layouts were generated (Phase 5c), list both HTML paths with their layout labels
- Note which theme was applied
- Note any limitations (e.g., "PDF generated without charts — use browser print for charts" or "DOCX contains text only — charts are in the HTML version")

---

## Bundled Resources

| Reference | Loaded at | Purpose |
|-----------|-----------|---------|
| `references/01-report-detection.md` | Phase 0 | Report type detection heuristics and frontmatter patterns |
| `references/02-section-analysis.md` | Phase 1 | Section mapping rules per report type, data extraction patterns |
| `references/03-enrichment-catalog.md` | Phase 2b | Enrichment types, trigger conditions, scoring model, density thresholds |
| `references/04-chart-patterns.md` | — (script) | Chart.js config templates (used internally by Python script, not by LLM) |
| `references/08-infographic-distillation.md` | Phase 2a | Infographic distillation principles, hero number selection, 60-second read test |
| `${CLAUDE_PLUGIN_ROOT}/libraries/svg-patterns.md` | Phase 4 | SVG element recipes for inline concept diagrams (shared library — also used by concept-diagram-svg agent) |
| `references/06-html-structure.md` | Phase 4 | HTML layout reference — sidebar + continuous scroll, CSS architecture, responsive breakpoints. Used by the agent for both scroll and flipbook modes (agent always writes scroll HTML). |
| `references/07-flipbook-structure.md` | — (script) | Flipbook architecture documentation. CSS and JS are embedded in the Python post-processor as constants; the agent does not read this file. |
| `references/07-citation-normalization.md` | Phase 6 | Citation format detection and normalization for DOCX export |
| `schemas/design-variables.schema.json` | Phase 0 | JSON schema for design-variables validation |
| `schemas/enrichment-plan.schema.json` | Phase 2b | JSON schema for enrichment plan validation |
| `schemas/infographic-data.schema.json` | Phase 2a | JSON schema for infographic data validation |
| `scripts/generate-enriched-report.py` | Phase 4 | Python post-processor (flipbook assembly when `--layout flipbook`, infographic injection, content validation) |
