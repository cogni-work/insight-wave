---
name: narrative
description: "Transform structured content into compelling executive narratives using story arc frameworks. Use this skill whenever the user asks to create a narrative, write a narrative, transform content into a story arc, apply a specific arc framework (corporate visions, technology futures, competitive intelligence, strategic foresight, industry transformation, trend panorama), generate an insight summary, or summarize research findings as a narrative. Also trigger when other plugins need arc-driven narrative generation, when the user mentions TIPS trend narratives, or when they have research output they want turned into an executive-readable story. Even if the user just says 'make this readable for executives' or 'turn these findings into something presentable,' this skill is the right choice."
---

# Narrative Transformation

Transform input markdown files into a structured executive narrative using one of 6 story arc frameworks. The narrative length is controlled by `--target-length` (default ~1,675 words), with section lengths expressed as proportions of the total to preserve the arc's rhetorical balance at any scale. Each arc provides a distinct rhetorical progression -- mapping source evidence to arc elements, applying narrative techniques, and producing a citation-grounded insight summary.

**Use this for:**
- Transforming research syntheses, analyses, or structured findings into executive narratives
- Applying a specific story arc framework (Corporate Visions, Technology Futures, etc.)
- Generating an insight summary from a set of markdown files

**Not for:**
- Editing existing narratives (use copywriter skill)
- Creating slides from narratives (use story-to-slides skill)
- Raw research or data collection (use deeper-research skills)

---

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Directory containing input `.md` files, or path to a single `.md` file |
| `--arc-id` | No | Explicit arc selection; overrides auto-detection |
| `--language` | No | Output language: `en` (default) or `de`. Fallback chain: explicit parameter > project metadata > workspace preference (`.workspace-config.json`) > content detection > `en` |
| `--output-path` | No | Output file path; defaults to `insight-summary.md` in source directory |
| `--project-path` | No | Research project directory; enables loading entity data beyond source path |
| `--research-question` | No | Original research question for narrative hook framing |
| `--target-length` | No | Target total word count as a single number (e.g., `2500`). System applies +/-15% band to derive the acceptable range. Default: `1675` (yields ~1,424-1,926 words). Recommended: 800-4,000 — outside this range, arc rhetorical structure may not scale well |
| `--content-map` | No | YAML map of content category keys to file/directory paths for additional context |

**Content map keys:** `executive_summary`, `dimension_syntheses`, `trends_summary`, `trend_entities`, `megatrends_summary`, `megatrend_entities`, `domain_concepts`, `research_hub`, `initial_question`

---

## Output

A single markdown file (`insight-summary.md` by default):

```markdown
---
title: "{Arc-Specific Compelling Title}"
subtitle: "{Research Question or Topic}"
arc_id: "{selected-arc}"
arc_display_name: "{Arc Display Name}"
target_length: {target-length or 1675}
word_count: {actual word count}
language: "{en|de}"
date_created: "{ISO 8601}"
source_file_count: {N}
---

# {Title}

*{Subtitle}*

{Opening paragraph with narrative hook -- proportion of target}

---

## {Element 1 Header}

{proportion of target words with evidence grounding}

## {Element 2 Header}

{proportion of target words with evidence grounding}

## {Element 3 Header}

{proportion of target words with evidence grounding}

## {Element 4 Header}

{proportion of target words with evidence grounding}
```

**Word count target:** determined by `--target-length` (default 1,675). Each section's word range = its arc proportion x the target's +/-15% band. See the arc definition loaded in Phase 3 for per-element proportions.

**JSON summary returned on completion:**

```json
{
  "success": true,
  "output_path": "insight-summary.md",
  "arc_id": "corporate-visions",
  "arc_display_name": "Corporate Visions",
  "target_length": 1675,
  "word_count": 1650,
  "citation_count": 22,
  "elements": 4,
  "language": "en"
}
```

---

## Core Workflow

```text
Phase 1      Phase 2        Phase 3          Phase 4            Phase 5       Phase 6
Setup  --->  Arc      --->  Pattern   --->   Transformation --> Validation -> Write
& Load       Selection      Loading          (arc-specific)
```

The quality of each phase depends on the previous one. In particular, Phases 3 and 4 require reading reference files before doing anything -- the arc patterns and narrative techniques are what differentiate a good narrative from a generic summary. Skipping those reads is the single biggest cause of poor output.

---

### Phase 1: Setup & Content Loading

1. Validate `--source-path` exists. If not found, halt with error JSON.
2. Load all `.md` files from source directory using Read tool.
3. Load `narrative-config.json` from source directory if present.
4. If `--content-map` provided, load additional files from each path:
   - Directory paths: load all `.md` files
   - File paths: load that specific file
   - Glob patterns: expand and load matches
   - Tag each file with its content-map key
   - Skip non-existent paths with warning (non-blocking)
5. If `--research-question` provided, store it for hook construction.
6. Parse `--target-length` if provided (single integer). Compute the acceptable range: `total_lower = target * 0.85`, `total_upper = target * 1.15`. If omitted, default to `target = 1675` (range 1424-1926). Store `target_length`, `total_lower`, `total_upper`.
7. Build a mental CONTENT_REGISTRY: list of loaded files with titles, word counts, key sections, category tags.

**Before moving on,** make sure you can answer: How many files loaded? What are the 2-3 dominant themes? What is the approximate total word count? If you can't answer these, you haven't internalized the source material yet.

---

### Phase 2: Arc Selection

**Read first:** [references/story-arc/arc-registry.md](references/story-arc/arc-registry.md)

The arc registry contains the detection algorithm, keyword sets, and content-type mappings. Read it before selecting an arc -- the detection logic lives there, not here.

**Selection priority:**
1. If `--arc-id` provided, use it directly
2. If `narrative-config.json` contains `content_type`, apply detection algorithm from arc-registry
3. If neither, analyze loaded content for keyword density using detection algorithm
4. Fallback: `corporate-visions`

Present selected arc to user for confirmation using AskUserQuestion. Show the detected arc with detection reason and offer alternatives. Accept user confirmation or override.

Store: `arc_id`, `arc_display_name`, `detection_reason`

---

### Phase 3: Load Arc Patterns

This phase is about loading the rhetorical framework into context. The narrative techniques and arc-specific patterns are what make the difference between "information organized under headings" and "a persuasive executive narrative." Read both files before writing anything.

**Read these two files:**

1. `references/story-arc/{arc_id}/arc-definition.md` -- element definitions, word targets, quality gates, transition patterns
2. `references/narrative-techniques/techniques-overview.md` -- 8 narrative techniques with arc application matrix

The 4 individual element pattern files (`{element}-patterns.md`) are NOT loaded here. Their guidance is already embedded in the arc-specific Phase 4b workflow file. Loading both would create ~1,500 lines of overlapping material that dilutes rather than reinforces.

**After reading,** you should be able to name all 4 arc elements in order with their word targets, and know which narrative techniques apply to which elements from the technique-arc matrix. If you can't, re-read.

---

### Phase 4: Narrative Transformation

**Read first:** `references/phase-workflows/phase-4b-synthesis-{arc_id}.md` (if it exists)

This file contains detailed sub-steps, extended thinking prompts, and quality gates specific to the selected arc. If it exists, follow its workflow -- it's more detailed and arc-aware than the summary below.

#### Why exactly 4 sections matters

The output uses exactly 4 `##` section headers matching the selected arc's element names. This isn't arbitrary -- downstream visualization tools (story-to-slides, story-to-big-picture, story-to-storyboard, story-to-web) parse these 4 elements to create matching visual segments. Creative renaming or adding extra sections breaks this pipeline. See `references/language-templates.md` section "Insight Summary (Arc Element Headers)" for the exact header text per arc and language.

#### Summary workflow (when no arc-specific file exists)

For each of the 4 arc elements:

1. **Map source content** to element using arc-definition source content mapping
2. **Apply transformation patterns** from loaded pattern files
3. **Apply narrative techniques** (PSB, IS-DOES-MEANS, Number Plays, etc.) per the technique-arc matrix
4. **Construct element:**
   - Arc-specific header (localized if `de`)
   - Evidence-grounded body text
   - Inline citations: `<sup>[N](source-file.md)</sup>` format
   - Word count within computed proportional range (+/-10% tolerance)
5. **Build transitions** between elements using arc-definition transition patterns

Assemble the full narrative:

1. Generate an arc-specific compelling title -- not "Insight Summary" or anything generic
2. Write hook paragraph (arc's hook proportion of target) using arc's hook construction pattern
3. Assemble 4 elements with transitions
4. Write closing using arc's closing pattern

---

### Phase 5: Validation

Check these gates in priority order. If the structural gate fails, fix it before checking anything else -- the other gates are meaningless if the structure is wrong.

**Structural gate (check first):**

- Exactly 4 `##` headers in narrative body (below frontmatter)
- Headers match arc's exact element names (language-specific)
- Headers in correct arc sequence
- No extra `##` headers

If this fails, rewrite using the template rather than renaming sections. Content generated for the wrong structure reads wrong even with correct headers.

**Content gates:**

- Total word count within target range (`total_lower` to `total_upper`, computed from `--target-length`)
- Title is arc-specific (not generic)
- Hook present (within hook proportion of target)
- Element word counts within computed proportional ranges (+/-10% of section midpoint). Compute each section's range: `[proportion * total_lower, proportion * total_upper]` using proportions from the arc definition loaded in Phase 3
- Arc-specific techniques applied (check arc quality gates in arc-definition)
- Smooth transitions between elements
- Frontmatter contains all required fields (including `target_length`)

**Evidence gates:**

- Citations: minimum 15, format `<sup>[N](file.md)</sup>`
- Every quantitative claim has a citation
- No fabricated references -- all cite loaded source files

**Language gates (if `de`):**

- Proper umlauts throughout (ä, ö, ü, ß)
- Zero ASCII fallbacks (ae, oe, ue, ss) in body text

If any gate fails, fix the specific issue and re-validate all gates (fixes can break other things).

---

### Phase 6: Write Output

1. Write narrative to output path (default: `insight-summary.md` in source directory)
2. Verify file created with correct word count
3. Return JSON summary (see Output section above)

---

## Available Story Arcs

| Arc ID | Elements | Best For |
|--------|----------|----------|
| `corporate-visions` | Why Change -> Why Now -> Why You -> Why Pay | Market research, B2B, sales enablement |
| `technology-futures` | Emerging -> Converging -> Possible -> Required | Innovation, R&D, technology trends |
| `competitive-intelligence` | Landscape -> Shifts -> Positioning -> Implications | Competitive analysis, threat assessment |
| `strategic-foresight` | Signals -> Scenarios -> Strategies -> Decisions | Long-range planning, scenario analysis |
| `industry-transformation` | Forces -> Friction -> Evolution -> Leadership | Industry analysis, regulatory impact |
| `trend-panorama` | Forces -> Impact -> Horizons -> Foundations (TIPS) | Trend-scout output, TIPS trend reports |

See [references/story-arc/arc-registry.md](references/story-arc/arc-registry.md) for detection signals, word targets, and extension guidelines.

---

## German Language Rules

When `language: de`, all generated text uses proper Unicode umlauts. ASCII transliterations in body text (fuer, ueber, Aenderung) are wrong because they look unprofessional and break German grammar conventions.

| Context | Use | Example |
|---------|-----|---------|
| Body text, headings, titles | Proper umlauts (ä, ö, ü, ß) | "für", "Änderung", "größte" |
| File names and slugs | ASCII transliterations | "ue", "ae", "oe", "ss" |
| YAML keys | ASCII only | `arc_id`, `entity_type` |

Common failures to scan for after generation: "fuer" (should be "für"), "ueber" ("über"), "Aenderung" ("Änderung"), "groesste" ("größte"), "Fuehrung" ("Führung").

See [references/language-templates.md](references/language-templates.md) for localized headers per arc.

---

## Citation Strategy

- Cite input source files only -- fabricated references undermine credibility entirely
- Format: `Claim text<sup>[N](source-file.md)</sup>`
- Every quantitative claim needs a citation -- unsupported numbers feel made up
- Target: 15-25 total citations, sequentially numbered from 1

---

## Narrative Techniques

See [references/narrative-techniques/techniques-overview.md](references/narrative-techniques/techniques-overview.md) for the full library:

| Technique | Purpose |
|-----------|---------|
| Pyramid Principle | Answer First architecture |
| PSB | Problem-Solution-Benefit for unconsidered needs |
| IS-DOES-MEANS | Power Position structure |
| Number Plays | 6 quantification techniques |
| Forcing Functions | Urgency through external pressures |
| Contrast Structure | Cognitive dissonance patterns |
| You-Phrasing | Direct address to reader |
| Compound Impact | Cost of inaction stacking |

---

## Error Handling

On any unrecoverable failure, return error JSON:

```json
{
  "success": false,
  "error": "Description of what went wrong",
  "phase": "Phase where failure occurred"
}
```

| Phase | Failure | Action |
|-------|---------|--------|
| 1 | Source path not found | Halt with error |
| 1 | No `.md` files in source | Halt with error |
| 2 | Unknown `arc_id` | Halt with available arcs list |
| 3 | Arc pattern files missing | Halt with missing file list |
| 4 | Transformation fails | Halt with error JSON |
| 5 | Validation fails | Report failures, fix, re-validate |

---

## Bundled Resources

| File | Purpose | Load When |
|------|---------|-----------|
| `references/story-arc/arc-registry.md` | Arc index, detection algorithm, extension guide | Phase 2 |
| `references/story-arc/{arc_id}/arc-definition.md` | Element definitions, word targets, quality gates | Phase 3 |
| `references/narrative-techniques/techniques-overview.md` | 8 narrative techniques with arc application matrix | Phase 3 |
| `references/phase-workflows/phase-4b-synthesis-{arc_id}.md` | Arc-specific transformation workflow | Phase 4 |
| `references/phase-workflows/shared-steps.md` | Entity counting, output template, validation, write steps | Phase 4 (via phase-4b) |
| `references/language-templates.md` | Localized headers for en/de | Phase 4 (if `de`) |
