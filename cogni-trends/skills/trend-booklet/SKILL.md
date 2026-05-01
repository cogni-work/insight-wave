---
name: trend-booklet
description: |
  Build a comprehensive browsable TIPS booklet that catalogs every trend-scout
  candidate (~60) organized by Smarter Service dimension → subcategory →
  horizon, with per-entry summary, key citations, theme back-references, and
  keywords. The booklet is the companion catalog to the canonical investment
  themes report (`/trend-synthesis`) — it surfaces *all* candidates including
  ones that didn't make it into a theme-case (orphans go in an appendix), so
  readers can see the full landscape behind the report's curated argument.
  Required pipeline: trend-scout → value-modeler → trend-research →
  trend-booklet (± trend-synthesis) → verify-trend-report. Use when: (1)
  `/trend-research` has completed, (2) the user mentions "trend booklet",
  "trend catalog", "all trends", "full trend list", "trend reference",
  "trend appendix", "complete trends overview", "reference catalog", or
  asks to see every candidate with its evidence. Always use this skill when
  the user wants a full-coverage catalog rather than the curated theme report.
  No web research — reads only the research manifest and per-dimension
  enriched evidence. Auto-recommends `/verify-trend-report` if not run yet,
  else `/trends-resume`.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
---

# Trend Booklet

Produce the comprehensive TIPS catalog `tips-trend-booklet.md` — every trend-scout candidate, organized dimension → subcategory → horizon, with summary, citations, theme back-references, and keywords. Companion artefact to the curated investment-themes report from `/trend-synthesis`.

## Purpose

Where `/trend-synthesis` produces a curated argument over a small set of investment themes, this skill produces the full reference catalog of all ~60 candidates so readers can see the complete landscape:

1. Locate the research output (gate on manifest existing; warn on drift)
2. Pick a density tier (compact / standard / exhaustive)
3. Build the per-candidate index with theme back-references
4. Format each dimension's entries via 4 parallel `cogni-trends:trend-booklet-formatter` agents
5. Assemble the final booklet (`tips-trend-booklet.md`) with an orphan appendix
6. Write the index sidecar (`tips-trend-booklet-index.json`) for downstream tooling
7. Auto-recommend `/verify-trend-report` (if claims not yet verified) or `/trends-resume`

No web research — evidence comes from `enriched-trends-{dimension}.json` produced by `/trend-research`.

## Language Support

Full German and English support. Inherits `language` from the research manifest. The booklet uses booklet-specific section headings (BOOKLET_TITLE, DIMENSION_HEADER, etc.) defined in [references/i18n/labels-en.md](references/i18n/labels-en.md) and [references/i18n/labels-de.md](references/i18n/labels-de.md).

## Prerequisites

- `/trend-research` completed with `.metadata/trend-research-output.json` present
- `tips-value-model.json` (used to compute theme back-references; orphan candidates fall back to the appendix)
- Downstream: `/verify-trend-report` (operates on `tips-trend-report.md`, not the booklet directly, but worth recommending if the user has run `/trend-synthesis` too)

## Context Independence

Reads ALL state from disk. **Context compaction is safe and recommended** before starting. Phase 2 dispatches 4 parallel formatter agents that self-load per-dimension evidence; the orchestrator only handles the index, assembly, and metadata.

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-trends` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (optional) | User's workspace directory |

## Shell Usage

Pure orchestrator. Shell commands needed:
- `bash scripts/build-booklet-index.sh` — build the per-candidate index
- `cat file1 file2 ... > output` — assemble the booklet from per-dimension formatter outputs
- `rm -f pattern` — cleanup of stale booklet artefacts on re-run

## References Index

Read references **only when needed** for the specific phase:

| Reference | Read when... |
|-----------|--------------|
| [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md) | Language detection (Phase 0.0) |
| [references/booklet-structure.md](references/booklet-structure.md) | Phase 2–3 — dimension/subcategory/horizon nesting + per-entry block template |
| [references/candidate-to-theme-backref.md](references/candidate-to-theme-backref.md) | Phase 1 — algorithm to walk value model and map candidates to themes |
| [references/booklet-length-tiers.md](references/booklet-length-tiers.md) | Phase 0 — compact / standard / exhaustive density definitions |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English booklet headings |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German booklet headings |

## Workflow Overview

```text
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
   │         │         │         │         │
   │         │         │         │         └ Update metadata, recommend /verify-trend-report or /trends-resume
   │         │         │         └ Assemble booklet + sidecar index, render orphan appendix
   │         │         └ 4 parallel formatter agents → .logs/booklet-{dimension}.md
   │         └ Build per-candidate index via build-booklet-index.sh → .logs/booklet-index.json
   └ Locate research output, drift check, density tier prompt, cleanup
```

---

### Phase 0: Discovery + Density Tier

#### Step 0.0: Detect Interaction Language

Read [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md). Set `INTERACTION_LANGUAGE`.

#### Step 0.1: Project Discovery

If `--project-path` was provided, use it. Otherwise run `discover-projects.sh --json`. Filter to projects with `.metadata/trend-research-output.json`. 0 → HALT ("Run /trend-research first"); 1 → auto-select; 2+ → AskUserQuestion.

#### Step 0.2: Load Research Manifest + Drift Check

Read `{PROJECT_PATH}/.metadata/trend-research-output.json`. Apply the same drift detection rules `trend-synthesis` uses (see `trend-research/references/research-manifest-schema.md § Drift Detection`):

- Recompute current `candidates_hash` and `value_model_hash`
- WARN on mismatch with the impact line; offer to re-run `/trend-research`
- Allow proceed on explicit confirmation — the booklet's catalog tolerates slightly stale evidence better than the synthesis report

#### Step 0.3: Pick Density Tier

Read [references/booklet-length-tiers.md](references/booklet-length-tiers.md) for tier definitions. The tier controls **per-entry word budgets** (summary length, max citations) and is independent from the synthesis report's length tier.

**Resume rule:** if `tips-project.json` already contains a `booklet_density` field, skip the question and continue with that value.

Otherwise present 3 options via AskUserQuestion:

- **compact** — 80-word summary + top 2 citations per entry (~30 pages of catalog)
- **standard** — 150-word summary + top 4 citations per entry (~60 pages)
- **exhaustive** — 300-word summary + all citations per entry (~120 pages)

Default is `standard`. Persist the choice to `tips-project.json`:

```json
{ "booklet_density": "standard" }
```

#### Step 0.4: Clean Up Stale Booklet Outputs

```bash
bash -O nullglob -c 'rm -f \
  "{PROJECT_PATH}/.logs/booklet-index.json" \
  "{PROJECT_PATH}/.logs/booklet-"*.md \
  "{PROJECT_PATH}/tips-trend-booklet.md" \
  "{PROJECT_PATH}/tips-trend-booklet-index.json"'
```

Research outputs are owned by `/trend-research`; synthesis outputs are owned by `/trend-synthesis`. Booklet cleanup touches only its own artefacts.

---

### Phase 1: Build Booklet Index

Run the index builder script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-booklet/scripts/build-booklet-index.sh" "${PROJECT_PATH}"
```

The script walks `tips-value-model.json` + `.metadata/trend-scout-output.json` + the 4 `enriched-trends-{dimension}.json` files (paths from the research manifest) and emits `.logs/booklet-index.json`. It emits the canonical `{"success": bool, "data": ..., "error": ...}` JSON envelope on stdout.

The index format and theme-backref algorithm are documented in:
- [references/booklet-structure.md](references/booklet-structure.md) — nested dimension / subcategory / horizon layout
- [references/candidate-to-theme-backref.md](references/candidate-to-theme-backref.md) — walking the value chains to map `candidate_ref → [theme_id, theme_name, role]`

Index shape (one entry per candidate, ~60 total):

```json
[
  {
    "candidate_ref": "externe-effekte/act/1",
    "name": "EU AI Act Compliance",
    "dimension": "externe-effekte",
    "subcategory": "regulation",
    "horizon": "act",
    "keywords": ["AI Act", "compliance", "..."],
    "claims_refs": ["claim_ee_001", "claim_ee_002"],
    "theme_backrefs": [
      { "theme_id": "it-001", "theme_name": "Intelligent Grid & Asset Optimization", "role": "trend" }
    ]
  },
  {
    "candidate_ref": "externe-effekte/observe/4",
    "name": "Orphan signal X",
    "dimension": "externe-effekte",
    "subcategory": "society",
    "horizon": "observe",
    "keywords": ["..."],
    "claims_refs": [],
    "theme_backrefs": []
  }
]
```

Orphan candidates (in `value_model.orphan_candidates` or with no `theme_backrefs`) carry `theme_backrefs: []` so the formatter places them in the appendix bucket.

Validate the script returned `success: true`. On failure, surface the `error` field and HALT.

---

### Phase 2: Format Dimension Sections (PARALLEL)

Dispatch 4 `cogni-trends:trend-booklet-formatter` agents in a single parallel message — one per Smarter Service dimension. Each agent reads:

- `enriched-trends-{dimension}.json` (path from the research manifest)
- The dimension's slice of `.logs/booklet-index.json`
- Booklet i18n labels (passed in the prompt)
- The density tier (`compact` | `standard` | `exhaustive`)

Each agent writes `.logs/booklet-{dimension}.md`.

```yaml
Per agent (4 parallel):
  subagent_type: "cogni-trends:trend-booklet-formatter"
  model: sonnet
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    DIMENSION: {dimension_slug}
    DIMENSION_INDEX: {1 | 2 | 3 | 4 — TIPS order}
    LANGUAGE: {LANGUAGE from manifest}
    DENSITY_TIER: {compact | standard | exhaustive}
    ENRICHED_TRENDS_PATH: {path from manifest.files.enriched_trends[dimension]}
    BOOKLET_INDEX_PATH: {PROJECT_PATH}/.logs/booklet-index.json
    LABELS: {JSON object with booklet i18n labels:
      DIMENSION_HEADER, SUBCATEGORY_HEADER, HORIZON_LABEL_ACT/PLAN/OBSERVE,
      ENTRY_SUMMARY_HEADER, ENTRY_CITATIONS_HEADER, ENTRY_THEMES_HEADER,
      ENTRY_KEYWORDS_HEADER}
```

#### Resume Check

Before dispatching for a dimension, check if `.logs/booklet-{dimension}.md` exists and is >2000 bytes. If so, skip — display `"Skipping booklet formatter (resume): {dimension}"`.

#### Validation

Each agent returns:

```json
{
  "ok": true,
  "dimension": "externe-effekte",
  "entries_formatted": 14,
  "orphans_in_dimension": 1,
  "booklet_file": ".logs/booklet-externe-effekte.md"
}
```

If `ok: false`: retry once. HALT on second failure. The 4 agents are independent; one failing does not block the others, but assembly (Phase 3) requires all four files.

---

### Phase 3: Assemble Booklet + Sidecar Index

#### Step 3.1: Write Booklet Header

Write `.logs/booklet-header.md` with YAML frontmatter and a brief intro paragraph:

```markdown
---
title: "{BOOKLET_TITLE}"
subtitle: "{BOOKLET_SUBTITLE}"
industry: {INDUSTRY_EN}
subsector: {SUBSECTOR_EN}
language: {LANGUAGE}
generated_by: trend-booklet
source_skills:
  - trend-scout
  - value-modeler
  - trend-research
booklet_density: {standard | compact | exhaustive}
total_candidates: 60
total_themes_referenced: {N}
total_orphans: {N}
generated_at: "{ISO-8601}"
---

# {BOOKLET_TITLE}

*{BOOKLET_SUBTITLE}*

{2-3 sentence intro paragraph: this booklet catalogs every trend-scout
candidate organized by Smarter Service dimension → subcategory → horizon.
Companion to `tips-trend-report.md` (the curated investment themes report).
Orphan candidates without a current investment theme appear in the appendix.}
```

Use i18n labels for `BOOKLET_TITLE`, `BOOKLET_SUBTITLE`, etc.

#### Step 3.2: Concatenate

Verify all files exist and concatenate in TIPS order:

```bash
FILES="{PROJECT_PATH}/.logs/booklet-header.md"
for DIM in externe-effekte digitale-wertetreiber neue-horizonte digitales-fundament; do
  FILES="$FILES {PROJECT_PATH}/.logs/booklet-${DIM}.md"
done
cat $FILES > "{PROJECT_PATH}/tips-trend-booklet.md"
```

The orphan appendix is rendered **inside each dimension's section** by the formatter (orphans in that dimension go under an `## {ORPHAN_APPENDIX_HEADER}` H2 at the end of the dimension's content). This keeps orphans dimension-local rather than as a single global appendix — readers see all candidates in their dimension context.

#### Step 3.3: Write Sidecar Index

Write `{PROJECT_PATH}/tips-trend-booklet-index.json` — the structured companion to the markdown:

```json
{
  "booklet_path": "tips-trend-booklet.md",
  "language": "{LANGUAGE}",
  "booklet_density": "standard",
  "total_candidates": 60,
  "total_themes_referenced": {N},
  "total_orphans": {N},
  "by_dimension": {
    "externe-effekte": { "candidates": 15, "orphans": 1, "file": ".logs/booklet-externe-effekte.md" },
    "digitale-wertetreiber": { ... },
    "neue-horizonte": { ... },
    "digitales-fundament": { ... }
  },
  "index": [ /* same shape as .logs/booklet-index.json */ ]
}
```

Downstream visualizers (`cogni-visual:enrich-report`, `cogni-trends:trends-dashboard`) can consume this sidecar instead of parsing the markdown.

---

### Phase 4: Finalize Metadata

#### Step 4.1: Update `tips-project.json` and Scout Output Metadata

Update `{PROJECT_PATH}/tips-project.json`:
```json
{
  "updated": "ISO-8601",
  "booklet_density": "{tier}"
}
```

Add to `{PROJECT_PATH}/.metadata/trend-scout-output.json`:

```json
{
  "trend_booklet_complete": true,
  "trend_booklet_path": "tips-trend-booklet.md",
  "trend_booklet_index_path": "tips-trend-booklet-index.json",
  "trend_booklet_density": "{tier}",
  "trend_booklet_total_candidates": 60,
  "trend_booklet_total_orphans": {N},
  "trend_booklet_generated_at": "ISO-8601"
}
```

The booklet does not write a `content_hash_at_booklet` because `verify-trend-report` operates on the synthesis report, not the booklet. Drift detection on the booklet runs at *next-invocation* time (Phase 0.2's manifest-hash check), which is sufficient.

#### Step 4.2: Display Summary + Auto-Recommend

```
Trend Booklet Complete
─────────────────────
Booklet:       {PROJECT_PATH}/tips-trend-booklet.md
Density:       {tier} ({per-entry budget summary})
Candidates:    60 entries across 4 dimensions
Orphans:       {N} (in dimension appendices)
Index sidecar: {PROJECT_PATH}/tips-trend-booklet-index.json

Next step → ...
```

Next-step logic:

- If `tips-trend-report.md` exists AND `verify_trend_report_complete != true`: recommend `/verify-trend-report`
- Else: recommend `/trends-resume`

This keeps the user moving toward the verified canonical report, falling back to the dashboard for re-orientation otherwise.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `.metadata/trend-research-output.json` missing | HALT: Run /trend-research first |
| Manifest hashes don't match current scout/value-model state | WARN; allow proceed on confirmation (catalog is more drift-tolerant than synthesis) |
| `tips-value-model.json` missing | HALT: Run value-modeler first — booklet needs theme back-references |
| <60 candidates in scout output | WARN: proceed but note coverage is incomplete; some dimensions may have empty buckets |
| `build-booklet-index.sh` returns `success: false` | HALT with the script's `error` field |
| Formatter agent returns `ok: false` | Retry once; HALT on second failure with dimension name |
| One dimension has 0 ACT-horizon candidates | Render the empty bucket with a one-line note (not a hard error) |
| One dimension has 0 candidates total | Render the empty section with a note (very unusual; surface the underlying scout-output gap) |

## Integration

**Upstream:**
- `trend-research` produces `.metadata/trend-research-output.json` and the per-dimension enriched-trends artefacts (required)
- `value-modeler` produces `tips-value-model.json` (required for theme back-references)

**Pipeline:** `trend-scout → value-modeler → trend-research → trend-booklet (± trend-synthesis) → verify-trend-report`

**Sibling:** `/trend-synthesis` consumes the same research manifest to produce the curated investment-themes report. The two skills are independent; either can run first. They produce different deliverables for different reader needs (curated argument vs. full reference catalog).

**Downstream consumers of the sidecar index:**
- `cogni-visual:enrich-report` — themed HTML rendering of the booklet
- `cogni-trends:trends-dashboard` — lists candidates in the dashboard view

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `booklet-index.json` — per-candidate index with theme back-references (intermediate)
- `booklet-{dimension}.md` — per-dimension formatter output (4 files)
- `booklet-header.md` — frontmatter + intro paragraph

Output files in `{PROJECT_PATH}/`:
- `tips-trend-booklet.md` — assembled final booklet
- `tips-trend-booklet-index.json` — structured sidecar index

| Issue | Check |
|-------|-------|
| Empty dimension section | Check trend-scout candidate distribution; some scout outputs lack PLAN/OBSERVE for one dimension |
| Theme back-references missing | Check `tips-value-model.json` value chains include all candidate refs |
| Orphan appendix unexpectedly large | Inspect `value_model.orphan_candidates` — value-modeler may have skipped MECE coverage |
| Per-entry summary too long/short | Verify `booklet_density` matches the agent's per-tier word budget |
