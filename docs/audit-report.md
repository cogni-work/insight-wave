# Documentation Drift Report
Generated: 2026-03-31
Repo: /Users/stephandehaas/GitHub/dev/insight-wave

## Summary

| Plugin | Components | Architecture | Descriptions | Dependencies | plugin.json | CLAUDE.md | Messaging | docs/ | Commercial | Doc Logic | Overall |
|--------|-----------|--------------|-------------|-------------|-------------|-----------|-----------|-------|------------|-----------|---------|
| cogni-claims | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-narrative | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-copywriting | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-workspace | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-trends | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-portfolio | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-visual | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-help | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-marketing | DRIFT | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-research | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-sales | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-consulting | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |

## cogni-claims

### Component Table Drift
- OK (5 components: 2 skills, 2 agents, 1 command — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (4 optional dependencies documented)

### plugin.json
- OK (v1.0.6, valid semver, description present)

### CLAUDE.md
- OK (below complexity threshold: 2 skills, 2 agents)

### Power Messaging
- OK (all four IS/DOES/MEANS layers present with specificity — problem table has 4 sourced evidence rows, MEANS has quantified benefit bullets)

### docs/
- OK (docs/plugin-guide/cogni-claims.md exists)

### Commercial Tone
- OK (cogni-work.ai link in Custom development and footer only)

### Documentation Logic Drift
- Pipeline suffix: `claims` registered in pipeline-registry.json but "What it does" items lack artifact trail (`→ cogni-claims/claims.json → consulting-deliver, synthesize`)
- Verdict: DRIFT

---

## cogni-narrative

### Component Table Drift
- OK (9 components: 3 skills, 3 agents, 3 commands — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (5 optional dependencies documented)

### plugin.json
- OK (v1.8.4, valid semver, description present)

### CLAUDE.md
- OK (present, meets complexity threshold: 3 skills, 3 agents)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names story arc engine, MEANS has "seven frameworks", "quality-gated" with specifics)

### docs/
- OK (docs/plugin-guide/cogni-narrative.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `narrative` registered in pipeline-registry.json but "What it does" item 1 lacks artifact trail (`→ insight-summary.md → story-to-slides, story-to-big-picture, story-to-web, why-change`)
- Pipeline suffix: `narrative-adapt` registered but "What it does" item 3 lacks artifact trail (`→ executive-brief.md, talking-points.md, one-pager.md → copywriter`)
- Verdict: DRIFT

---

## cogni-copywriting

### Component Table Drift
- OK (8 components: 4 skills, 2 agents, 2 commands — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (1 optional dependency documented: cogni-narrative)

### plugin.json
- OK (v0.2.17, valid semver, description present)

### CLAUDE.md
- OK (present)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names McKinsey Pyramid, MEANS has "arc-aware", "bilingual")

### docs/
- OK (docs/plugin-guide/cogni-copywriting.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- OK (no pipeline-registry entries for cogni-copywriting)

---

## cogni-workspace

### Component Table Drift
- OK (12 components: 4 skills, 1 hook, 7 scripts — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (prose format: "cogni-workspace has no plugin dependencies" — acceptable as foundation layer)

### plugin.json
- OK (v0.4.1, valid semver, description present)

### CLAUDE.md
- OK (present)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names "shared foundation layer", MEANS has "one command to set up", "safe updates with rollback")

### docs/
- OK (docs/plugin-guide/cogni-workspace.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- OK (no pipeline-registry entries for cogni-workspace)

---

## cogni-trends

### Component Table Drift
- OK (10 components: 6 skills, 4 agents — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (6 optional dependencies documented)

### plugin.json
- OK (v0.3.51, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 6 skills, 4 agents)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names "four-stage trend intelligence pipeline", MEANS has "32+ bilingual web searches", "framework-scored")

### docs/
- OK (docs/plugin-guide/cogni-trends.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `trend-scout` registered but "What it does" item 1 lacks artifact trail (`→ trend-candidates.md → value-modeler, trend-report`)
- Pipeline suffix: `value-modeler` registered but "What it does" item 2 lacks artifact trail (`→ tips-value-model.json → trend-report, story-to-big-block`)
- Pipeline suffix: `trend-report` registered but "What it does" item 3 lacks artifact trail (`→ tips-trend-report.md → enrich-report, claims` | final: branded HTML)
- Pipeline suffix: `trends-dashboard` registered but "What it does" item 4 lacks artifact trail (`→ tips-dashboard.html` | final: interactive dashboard)
- Verdict: DRIFT

---

## cogni-portfolio

### Component Table Drift
- OK (37 components: 20 skills, 17 agents — all match disk)

### Architecture Tree Drift
- OK (counts match: "20 portfolio skills", "17 delegation agents", "8 utility scripts")

### Description Alignment
- OK

### Dependency Table Drift
- OK (5 optional dependencies documented: cogni-claims, document-skills, cogni-trends, cogni-workspace, cogni-consulting)

### plugin.json
- OK (v0.9.44, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 20 skills, 17 agents, multi-phase workflow)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names "IS/DOES/MEANS (FAB) framework", MEANS has "portfolio positioning in days not weeks", "eight industry taxonomies", quantified impacts)

### docs/
- OK (docs/plugin-guide/cogni-portfolio.md exists)

### Commercial Tone
- OK ("pricing" appears only in domain context — solution pricing tiers)

### Documentation Logic Drift
- Pipeline suffix: `portfolio-setup` registered but "What it does" item 1 lacks artifact trail (`→ portfolio.json → features, markets, products, portfolio-scan`)
- Pipeline suffix: `features` registered but "What it does" item 2 lacks artifact trail (`→ features/*.json → propositions, solutions, packages`)
- Pipeline suffix: `markets` registered but "What it does" item 2 lacks artifact trail (`→ markets/*.json → propositions, solutions, customers`)
- Pipeline suffix: `propositions` registered but "What it does" item 3 lacks artifact trail (`→ propositions/{f}--{m}.json → solutions, packages, synthesize, compete`)
- Pipeline suffix: `solutions` registered but "What it does" item 4 lacks artifact trail (`→ solutions/{f}--{m}.json → packages, why-change, synthesize`)
- Pipeline suffix: `compete` registered but "What it does" item 5 lacks artifact trail
- Pipeline suffix: `customers` registered but "What it does" item 6 lacks artifact trail
- Pipeline suffix: `synthesize` registered but "What it does" item 8 lacks artifact trail
- Pipeline suffix: `portfolio-dashboard` registered but no dedicated "What it does" item with artifact trail
- Pipeline suffix: `portfolio-export` registered but item 8 lacks artifact trail
- Pipeline suffix: `portfolio-communicate`, `portfolio-architecture`, `portfolio-scan`, `products`, `packages` — all registered but lack artifact trails
- Verdict: DRIFT (15 registered skills without pipeline suffixes)

---

## cogni-visual

### Component Table Drift
- OK (26 components: 8 skills, 14 agents, 3 commands, 1 hook — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (7 dependencies documented: 3 required, 4 optional)

### plugin.json
- OK (v1.4.10, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 8 skills, 14 agents)

### Power Messaging
- OK (all four layers present — problem table with 3 rows including "1-2 days of formatting work", IS names "brief-based visual production pipeline", MEANS has "narrative to slides in minutes", "five visual formats")

### docs/
- OK (docs/plugin-guide/cogni-visual.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `story-to-slides` registered but "What it does" item 2 lacks artifact trail (`→ presentation-brief.md → pptx` | final: PowerPoint deck)
- Pipeline suffix: `story-to-big-picture` registered but "What it does" item 2 lacks artifact trail (`→ big-picture-brief.md → render-big-picture` | final: Excalidraw scene)
- Pipeline suffix: `story-to-big-block` registered but "What it does" item 2 lacks artifact trail
- Pipeline suffix: `story-to-web` registered but "What it does" item 2 lacks artifact trail
- Pipeline suffix: `story-to-storyboard` registered but "What it does" item 2 lacks artifact trail
- Pipeline suffix: `enrich-report` registered but "What it does" item 4 lacks artifact trail (`→ {report}-enriched.html` | final: branded interactive HTML)
- Pipeline suffix: `render-big-picture` registered but "What it does" item 3 lacks artifact trail
- Pipeline suffix: `render-big-block` registered but "What it does" item 3 lacks artifact trail
- Verdict: DRIFT (8 registered skills without pipeline suffixes)

---

## cogni-help

### Component Table Drift
- OK (17 components: 7 skills, 1 agent, 7 commands, 2+ scripts — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (prose format: "All ecosystem plugins are soft dependencies" — acceptable as meta-plugin)

### plugin.json
- OK (v0.2.15, valid semver, description present)

### CLAUDE.md
- OK (present, meets threshold: 7 skills, cross-plugin dependencies)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names "meta-plugin", MEANS has "productive in minutes", "12 courses")

### docs/
- OK (docs/plugin-guide/cogni-help.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Missing auto-section: `## Installation` required by section schema but absent from README
- Verdict: DRIFT

---

## cogni-marketing

### Component Table Drift
- ADDED: `/marketing-setup` (command) — exists on disk, missing from README table
- ADDED: `/content-strategy` (command) — exists on disk, missing from README table
- ADDED: `/thought-leadership` (command) — exists on disk, missing from README table
- ADDED: `/demand-gen` (command) — exists on disk, missing from README table
- ADDED: `/lead-gen` (command) — exists on disk, missing from README table
- ADDED: `/sales-enablement` (command) — exists on disk, missing from README table
- ADDED: `/abm` (command) — exists on disk, missing from README table
- ADDED: `/campaign` (command) — exists on disk, missing from README table
- ADDED: `/content-calendar` (command) — exists on disk, missing from README table
- ADDED: `/marketing-dashboard` (command) — exists on disk, missing from README table
- ADDED: `/marketing-resume` (command) — exists on disk, missing from README table

### Architecture Tree Drift
- OK (commands/ directory shown with "11 slash commands" annotation)

### Description Alignment
- OK

### Dependency Table Drift
- OK (6 dependencies documented: 2 required, 4 optional)

### plugin.json
- OK (v0.1.5, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 11 skills, 3 agents, multi-phase workflow)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, MEANS has "16 formats", "parallel generation", "bilingual")

### docs/
- OK (docs/plugin-guide/cogni-marketing.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `marketing-setup` registered but "What it does" item 1 lacks artifact trail (`→ marketing-project.json → content-strategy, campaign-builder`)
- Pipeline suffix: `content-strategy` registered but "What it does" item 2 lacks artifact trail (`→ content-matrix.json → campaign-builder, content-calendar`)
- Pipeline suffix: `campaign-builder` registered but "What it does" item 4 lacks artifact trail (`→ campaigns/*.json → content-calendar, marketing-dashboard`)
- Pipeline suffix: `marketing-dashboard` registered but "What it does" item 6 lacks artifact trail (`→ output/dashboard.html` | final: interactive dashboard)
- Verdict: DRIFT

---

## cogni-research

### Component Table Drift
- OK (13 components: 3 skills, 8 agents, 2 hooks — all match disk)

### Architecture Tree Drift
- OK (counts match: "3 orchestration skills", "8 research agents")

### Description Alignment
- OK

### Dependency Table Drift
- OK (3 optional dependencies documented: cogni-claims, cogni-visual, cogni-workspace)

### plugin.json
- OK (v0.6.11, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 3 skills, 8 agents, multi-phase workflow)

### Power Messaging
- OK (all four layers present — problem table with 5 rows including sourced evidence link, IS names "STORM-inspired editorial research pipeline", MEANS has "fast and parallel", "claims-verified", "three depth levels")

### docs/
- OK (docs/plugin-guide/cogni-research.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `research-report` registered but "What it does" items lack artifact trail (`→ research-report.md → enrich-report, claims, copywriter` | final: branded HTML)
- Verdict: DRIFT

---

## cogni-sales

### Component Table Drift
- OK (7 components: 1 skill, 2 agents, 1 command, 3 scripts — all match disk)

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK (6 dependencies documented: 2 required, 4 optional)

### plugin.json
- OK (v0.3.5, valid semver, description present)

### CLAUDE.md
- OK (present)

### Power Messaging
- OK (all four layers present — problem table with 4 rows, IS names "Corporate Visions Why Change methodology", MEANS has "deal-specific in hours", "methodology-disciplined")

### docs/
- OK (docs/plugin-guide/cogni-sales.md exists)

### Commercial Tone
- OK ("buy", "buyer", "pricing" appear only in domain context — sales methodology)

### Documentation Logic Drift
- Pipeline suffix: `why-change` registered but "What it does" items lack artifact trail (`→ sales-presentation.md → story-to-slides, copywriter` | final: presentation deck; `→ sales-proposal.md → copywriter` | final: formal proposal)
- Verdict: DRIFT

---

## cogni-consulting

### Component Table Drift
- OK (10 components: 8 skills, 1 agent, 1 hook — all match disk including consulting-define-workspace)

### Architecture Tree Drift
- OK (counts match: "8 engagement skills")

### Description Alignment
- OK

### Dependency Table Drift
- OK (7 optional dependencies documented)

### plugin.json
- OK (v0.1.7, valid semver, description present)

### CLAUDE.md
- OK (present, exceeds threshold: 8 skills, multi-phase workflow, 7 cross-plugin dependencies)

### Power Messaging
- OK (all four layers present — problem table with 3 rows, IS names "process orchestrator", MEANS has "Big-5 complexity with boutique team", "never lose context")

### docs/
- OK (docs/plugin-guide/cogni-consulting.md exists)

### Commercial Tone
- OK

### Documentation Logic Drift
- Pipeline suffix: `consulting-setup` registered but "What it does" item 1 lacks artifact trail (`→ consulting-project.json → consulting-discover`)
- Pipeline suffix: `consulting-discover` registered but "What it does" item 2 lacks artifact trail (`→ discover/synthesis.md → consulting-define`)
- Pipeline suffix: `consulting-define` registered but "What it does" item 3 lacks artifact trail (`→ define/problem-statement.md, define/hmw-questions.md → consulting-develop`)
- Pipeline suffix: `consulting-develop` registered but "What it does" item 4 lacks artifact trail (`→ develop/options/option-synthesis.md → consulting-deliver`)
- Pipeline suffix: `consulting-deliver` registered but "What it does" item 5 lacks artifact trail (`→ deliver/business-case.md, deliver/roadmap.md → consulting-export`)
- Pipeline suffix: `consulting-export` registered but "What it does" item 6 lacks artifact trail (`→ exports/*.pptx` | final: PPTX/DOCX/XLSX deliverables)
- Verdict: DRIFT

---

## Recommended Actions

### 1. Fix structural drift (cogni-marketing)
```
/doc-generate cogni-marketing --section=components
```
Add the 11 slash commands to the Components table.

### 2. Regenerate with current documentation logic (all plugins with Check 10 DRIFT)
```
/doc-generate cogni-claims
/doc-generate cogni-narrative
/doc-generate cogni-trends
/doc-generate cogni-portfolio
/doc-generate cogni-visual
/doc-generate cogni-help
/doc-generate cogni-marketing
/doc-generate cogni-research
/doc-generate cogni-sales
/doc-generate cogni-consulting
```
Adds pipeline suffixes to "What it does" items per pipeline-registry.json. Also fixes cogni-help's missing `## Installation` section.

### 3. Align descriptions (if needed after regeneration)
```
/doc-sync {plugin}
```
Run per-plugin if README first paragraph changes during regeneration.

### 4. No messaging fixes needed
All 12 plugins have OK messaging (IS/DOES/MEANS layers present with specificity).

### 5. No CLAUDE.md generation needed
All plugins that exceed complexity thresholds already have CLAUDE.md files.

### 6. No docs/ generation needed
All 12 plugins have plugin guides in docs/plugin-guide/. Five workflow guides exist in docs/workflows/.
