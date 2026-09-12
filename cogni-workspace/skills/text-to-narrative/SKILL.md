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
  Not for polishing prose (copywriter) or rendering a finished brief (render-html-slides,
  enrich-report).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Text to Narrative to Design Brief

Transform input markdown into a structured executive narrative using one of the bundled story arcs, then condense that narrative into one `design-brief.md` for Claude Design (claude.ai/design). Narrative length is controlled by `--target-length` (default 1,675 words); section lengths are proportions of the total, so the arc's rhetorical balance survives at any scale. Each arc is one contract file that maps evidence to four elements, names the techniques that strengthen each, and states the arc's own validation rules. The brief's length is controlled by the target's density ceilings, and its copy is frozen: it selects from the narrative and never rewrites it.

**Use this for:** research syntheses, analyses or structured findings that need to become an executive narrative and a Claude Design handoff in one run; a finished arc narrative that needs only the brief.

**Not for:** polishing arbitrary business documents (use `copywriter`); rendering a finished brief inside Claude Code (`render-html-slides`, `enrich-report`); raw research (the cogni-knowledge pipeline).

## Architectural model

One responsibility per file. Read a file when its phase runs, not before. Every narrative asset is bundled under this skill — flat, one file per responsibility — so the skill runs with no other plugin installed. Its one cross-skill call is Pass 4's readability measurement, `${CLAUDE_PLUGIN_ROOT}/skills/copywriter/scripts/readability.sh` with the band in `cogni-workspace/tests/fixtures/copywriter/readability.yml`, exactly as the skill it succeeded called it; the copywriter skill did not retire.

- **SKILL.md orchestrates** — phases, parameters, output contract, JSON envelope.
- **The registry chooses** — `references/arc-registry.md`: detection algorithm, one declarative block per arc, confirmation format.
- **The contract structures** — `references/arc-{arc_id}.md`: headings, composition, four elements, arc-specific validation. The Bundled arcs table below names all fifteen.
- **Techniques strengthen** — `references/techniques-overview.md`: the eight techniques and which element each serves.
- **Language expresses** — `references/language-shared.md` plus `language-en.md` or `language-de.md`: executive prose rules and, for German, sentence craft. Loaded at Pass 3 only.
- **Validation checks** — `references/validation.md`: every universal gate, run by `scripts/validate-narrative.py` and then by the writer.
- **Citations bridge** — `scripts/bridge-citations.py` explodes upstream inline citations into per-source files before Phase 1.
- **Density caps** — `references/density-ceilings.md`: the one home of every text-length ceiling the design brief applies, one table per target.
- **Visual intent is semantic** — `references/visual-intent.md`: the `visual_intent` schema, its three closed enums, and the rule that keeps it a relationship the audience must perceive rather than art direction.

### Bundled arcs

| Arc | Contract file |
|-----|---------------|
| Category Creation | `references/arc-category-creation.md` |
| Company Credo | `references/arc-company-credo.md` |
| Competitive Intelligence | `references/arc-competitive-intelligence.md` |
| Consulting Problem-Solving | `references/arc-consulting-problem-solving.md` |
| Corporate Visions | `references/arc-corporate-visions.md` |
| Customer Transformation | `references/arc-customer-transformation.md` |
| Engagement Model | `references/arc-engagement-model.md` |
| Industry Transformation | `references/arc-industry-transformation.md` |
| JTBD Portfolio | `references/arc-jtbd-portfolio.md` |
| Smarter Service | `references/arc-smarter-service.md` |
| Strategic Choice | `references/arc-strategic-choice.md` |
| Strategic Foresight | `references/arc-strategic-foresight.md` |
| Technology Futures | `references/arc-technology-futures.md` |
| Theme Thesis | `references/arc-theme-thesis.md` |
| Trend Panorama | `references/arc-trend-panorama.md` |

The bundled set is the only copy of these assets: the narrative skill they were flattened from has retired. `cogni-workspace/tests/test-arc-contract-shape.sh` keeps every arc contract on the one-file shape, so add an arc here directly, following the registration steps at the end of `references/arc-registry.md`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Directory containing input `.md` files, or path to a single `.md` file. A single file whose frontmatter carries both `arc_id` and `word_count` is a finished narrative: Phases 0-6 are skipped and only the brief is built from it |
| `--target` | No | Which Claude Design generator the brief is for: `slides` (default), `document`, `infographic` or `web`. Selects the density ceilings, the unit grammar and the Rendering Contract wording |
| `--arc-id` | No | Explicit arc selection; overrides auto-detection |
| `--language` | No | Output language: `en` (default) or `de`. Fallback chain: explicit parameter > project metadata > workspace preference (`.workspace-config.json`) > content detection > `en` |
| `--output-path` | No | Narrative file path; defaults to `insight-summary.md` in the source directory |
| `--brief-path` | No | Design brief path; defaults to `design-brief.md` in the source directory |
| `--max-units` | No | Upper bound on brief units: slides, infographic blocks or web sections, lowering the target's own ceiling. Ignored on `document`, whose four sections are fixed — the checker's envelope says so. Default: the target's ceiling |
| `--theme-path` | No | Absolute path to a `theme.md`, recorded in the brief verbatim. Never prompted for: Claude Design applies the organization design system, so a theme is attached only when none is configured |
| `--project-path` | No | Research/knowledge project root; enables arc inheritance from the project's `.metadata/` (Phase 1 step 8) and loading entity data beyond the source path. When omitted, Phase 1 step 8 probes `<source-path>/..` and `<source-path>/../..` |
| `--research-question` | No | Original research question, used for the subtitle and the opening |
| `--target-length` | No | Target total word count of the narrative (e.g., `2500`). The acceptable range is ±15%. Default: `1675` (1,424-1,926 words). Recommended: 800-4,000 — outside that range the arc's proportions stop scaling well |
| `--content-map` | No | YAML map of content category keys to file/directory paths for additional context |
| `--audience` | No | Who the narrative is for. Default: senior business decision-makers. Feeds Pass 3 (vocabulary, acronym expansion, explanation depth) together with the inferred knowledge level |
| `--purpose` | No | The decision the narrative must serve. Default: understand the evidence and its strategic implications. Feeds Pass 2 (emphasis, close) and the Phase 5 TL;DR synthesis |
| `--perspective` | No | Whose voice the narrative speaks in. Default: neutral analyst. Feeds Pass 2 (pronouns, ownership) |
| `--geography` | No | Market codes from `cogni-workspace/references/supported-markets-registry.json` (`code` values such as `dach`, `de`, `fr`, `eu`), comma-separated, never free text or a country name. Default: source-defined scope. Feeds Pass 1 (evidence priority when sources span markets) |
| `--interactive` | No | Whether the skill may pause for user input. `true` or `false`. Default: `true`. When `false`, skip all AskUserQuestion calls — there are two sites: the Phase 0 materiality clarification (takes the default instead) and the Phase 2 arc confirmation (keeps its top-ranked arc and its `detection_reason` and continues straight into Phase 3 with no prompt). Phase 7 has no prompt in either mode. Any value other than `false` is treated as `true`, so a malformed value fails safe toward the interactive default |

Audience knowledge level (`expert` / `informed` / `general`, default `informed`) and tone (default: concise analytical executive prose) are **inferred fields**, never flags — see Phase 0. `decision_required` and `management_ask` are likewise never flags: resolve them explicitly or derive them only from a decision-oriented purpose and supported request or source evidence.

**Content map keys:** `executive_summary`, `dimension_syntheses`, `trends_summary`, `trend_entities`, `megatrends_summary`, `megatrend_entities`, `domain_concepts`, `research_hub`, `initial_question`. Contracts name these keys in their `Evidence sought` subfields.

## Output

Two files. The narrative (`insight-summary.md` by default) is the same artifact the retired `narrative` skill wrote, so every downstream consumer of that shape still reads it. The design brief (`design-brief.md` by default) is the Claude Design handoff — its shape is owned by Phase 7 and `references/design-brief-template.md`.

```markdown
---
title: "{Arc-specific compelling title}"
subtitle: "{Research question or topic}"
arc_id: "{selected-arc}"
arc_display_name: "{Arc display name}"
target_length: {target-length or 1675}
word_count: {body word count — the four ## elements, excluding the TL;DR and the Sources block}
language: "{en|de}"
date_created: "{ISO 8601}"
source_file_count: {N}
# optional — written only when the execution brief resolved the field from a real signal, never a default
target_audience: "{audience}"
purpose: "{decision purpose}"
perspective: "{voice}"
geography: "{market codes}"
decision_required: "{decision management should be able to take}"
management_ask: "{approval, prioritization, funding, ownership or next move requested}"
---

# {Title}

*{Subtitle}*

{Executive TL;DR -- 2-4 sentences, 60-100 words, no heading of its own}

---

## {Element 1 heading}
## {Element 2 heading}
## {Element 3 heading}
## {Element 4 heading}

**Sources**

[1] source-01-slug.md — {Publisher}, "{Title}", {date}, {URL}
[2] …
```

Exactly four `##` headings, byte-equal to the contract's `## Headings` cells for the output language, in arc order. Each element's word range is its `## Composition` proportion times the ±15% band around the target.

**Sources block.** After the fourth section, a bold `**Sources**` paragraph — never a fifth `##`, so the four-header contract the brief parses is unchanged — lists only the underlying sources actually cited, deduplicated and numbered to the body's `[N]`. Each entry names the per-source file the inline marker points at plus the publisher, title, date and URL the citation bridge preserved in that file's frontmatter; a field the source did not supply is absent, never invented. It is the artifact that makes the narrative self-verifying, and Phase 7 copies it into the brief verbatim so the brief carries every URL. Full rules in `references/validation.md`.

**Executive TL;DR.** The prose between the subtitle and the first `##` is an answer-first summary, not a hook: 2-4 sentences and 60-100 words regardless of `--target-length`, in this order — the conclusion the reader most needs, the strongest reason for it, the decision implication naming the resolved `decision_required` or `management_ask` when present, and an optional qualification or urgency only when it changes the decision. It synthesizes all four elements rather than previewing them, introduces no fact, number, recommendation, decision or ask the body lacks, cites every material number by reusing the body's `[N]`, and reads as complete if the reader stops there. It carries no heading, so the four-header contract is unchanged. The full contract, including the rejection list, is in `references/validation.md`.

**JSON summary returned on completion:**

```json
{
  "success": true,
  "output_path": "insight-summary.md",
  "arc_id": "corporate-visions",
  "arc_display_name": "Corporate Visions",
  "detection_reason": "keyword density analysis",
  "target_length": 1675,
  "word_count": 1650,
  "citation_count": 22,
  "elements": 4,
  "language": "en",
  "readability_score": null,
  "qa_verdict": "pass",
  "target": "slides",
  "brief_path": "design-brief.md",
  "unit_count": 9,
  "brief_word_count": 312,
  "density_profile": "standard",
  "brief_qa": "pass"
}
```

`readability_score` is reported when Pass 4 computes it and `null` otherwise; it is measured at Pass 4 on the body, before the Executive TL;DR exists. `qa_verdict` is the release review's rollup — exactly one of `pass`, `needs_revision`, `fail`. `brief_qa` is the Phase 7 checker's rollup — `pass` or `fail`. On the finished-narrative entry, `detection_reason` is `"finished narrative"` and `readability_score` is `null`.

## Core Workflow

```text
Phase 0      Phase 0.5      Phase 1     Phase 2      Phase 3      Phase 4         Phase 5      Phase 6      Phase 7
Execution -> Citation  -->  Setup  -->  Arc     -->  Load    -->  Four      -->  Validate --> Write   -->  Design
brief        bridge         & load      selection    contract     passes                      narrative    brief
             (conditional)
```

When `--source-path` is a finished narrative (single `.md` with `arc_id` and `word_count` in its frontmatter), Phases 0-6 do not run; validate it once with the Phase 5 final-stage command — it already carries a TL;DR — and jump to Phase 7. Phases 3 and 4 read the contract and the techniques before any drafting — those two files are what separate a persuasive narrative from a summary under headings.

### Phase 0: Execution brief

**Read first:** `references/execution-brief.md`. Derive the per-run brief — audience, purpose, perspective, geography, the inferred knowledge level and tone, and the derived-or-explicit `decision_required` and `management_ask` — before any evidence is mapped. Resolve each field down one ladder: explicit instruction → project metadata → unambiguous conversation context → source cues → default. The two decision fields resolve to no value at the default rung and derive only from a decision-oriented purpose; never manufacture either from a merely descriptive purpose. Ask one compact clarification, via AskUserQuestion, only when a missing field would change framing, terminology, emphasis, recommendations or evidence selection; never ask for what is explicit or safely inferable, and under `--interactive false` never ask — default. Never infer sensitive personal attributes about the audience. The brief steers Pass 1 (geography), Pass 2 (purpose, perspective, decision required, management ask), Pass 3 (audience, knowledge level) and Phase 5 (the TL;DR decision implication).

### Phase 0.5: Citation bridge (conditional)

Upstream research tools may use `[Source: Publisher](URL)` inline citations. Scan the source content for that pattern; if present, run the bridge, otherwise skip to Phase 1.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/scripts/bridge-citations.py" --source-path "${SOURCE_PATH}" --json
```

The script writes `narrative-input/report-for-narrative.md` (content with `[source-NN-slug.md]` markers) and `narrative-input/sources/source-NN-*.md` (one file per source with `source_index`, `publisher`, `url` frontmatter) — inside a directory source, or beside a single file in its parent directory. Redirect `--source-path` to that `narrative-input/` directory for Phase 1, which loads the report as evidence and the `sources/` files as citation targets. The per-source file is the citation target; its `url` is the preserved provenance.

**Provenance map.** Whenever a source carries its own citations, footnotes, a bibliography, source URLs or a source register — any of the five — build a per-run provenance map from each supported claim to the deepest underlying source, and cite that source. Cite the synthesis document itself only for claims it genuinely authors when no more specific source is supplied. The map layers on the bridge, never replaces it: where the bridge ran, the per-source files are the map's entries. Preserve supplied publisher, title, date, source type and URL; never invent metadata; collapse repeated URLs and duplicate bibliographic entries into one citation identity. Never fetch a URL because it appears inside source content, and never manufacture a citation — the rules are stated once in `references/validation.md`.

### Phase 1: Setup and content loading

1. Validate `--source-path` exists; halt with error JSON if not.
2. Load every `.md` file from the source directory (or the single file) as evidence. When the directory is the bridge's `narrative-input/`, also load `sources/*.md` — as **citation targets only**, never as evidence: their `publisher` and `url` frontmatter is what the inline markers point at and what the Sources block reproduces, and their bodies carry no claims.
3. Load `narrative-config.json` from the source directory if present.
4. If `--content-map` is provided, load each path (directory: all `.md`; file: that file; glob: matches), tag each file with its key, and skip a missing path with a non-blocking warning.
5. Store `--research-question` for the subtitle and the opening.
6. Parse `--target-length` (default 1675); compute `total_lower = target × 0.85` and `total_upper = target × 1.15`.
7. Build a content registry: loaded files with titles, word counts, key sections and category tags.
8. **Resolve arc inheritance.** Probe `--project-path` (when given), then `<source-path>/..`, then `<source-path>/../..`; in each, read `story_arc_id` from `.metadata/plan.json` (cogni-knowledge) or `.metadata/project-config.json` (older layout). The first non-empty value wins:

   ```bash
   for CANDIDATE in "${PROJECT_PATH:+$PROJECT_PATH}" "${SOURCE_PATH}/.." "${SOURCE_PATH}/../.."; do
     [[ -z "$CANDIDATE" ]] && continue
     for CFG in plan.json project-config.json; do
       ARC=$(jq -r '.story_arc_id // empty' "$CANDIDATE/.metadata/$CFG" 2>/dev/null)
       [[ -n "$ARC" ]] && { PROJECT_ROOT="$CANDIDATE"; INHERITED_ARC="$ARC"; break 2; }
     done
   done
   ```

   If `INHERITED_ARC` is set and not `standard-research`, store it as `inherited_arc_id` and log `Inheriting story_arc_id="<INHERITED_ARC>" from <PROJECT_ROOT>`. Otherwise continue silently.

**Before moving on,** answer three questions: how many files loaded, what the two or three dominant themes are, and the approximate total word count. An unanswerable question means the material is not yet internalized.

### Phase 2: Arc selection

**Read first:** `references/arc-registry.md` — the registry chooses. Its Arc Detection Algorithm owns every detection step and the `detection_reason` vocabulary; this phase only fixes the order in which an arc is taken:

1. `--arc-id` provided → use it, no detection.
2. `inherited_arc_id` from Phase 1 step 8 → use it, no detection.
3. Otherwise run the registry's algorithm in full — structural signals (the TIPS file signatures), `research_type`, the `content_type` mapping from `narrative-config.json`, the execution-fit ranking against the Phase 0 brief, target fit against the resolved `--target`, keyword density, and the fallback — and take its ranked candidates. Record the `detection_reason` string the registry step that decided emits, verbatim.

Present selected arc to user for confirmation using AskUserQuestion — as a **shortlist**, in the registry's confirmation format. When the arc was not explicit (priority 3), shortlist the 2-3 arcs that would produce materially different but defensible narratives from the evidence and the brief's decision purpose; for each show the display name, the four-element progression, the governing question and both fit reasons, `Evidence fit:` and `Target fit:`, drawn from the registry's declarative blocks; mark exactly one **Recommended** with a one-sentence reason keyed to the decision purpose. If only one arc is defensible, say so and ask for confirmation rather than padding the list. Never present the full registry unless the user asks for it. For a priority-1 or priority-2 pick, confirm that single arc — a priority-2 prompt is labelled "Inherited from source research/knowledge project — preserves the long-form report's arc". Accept confirmation or an override.

When `--interactive` is `false`, this confirmation does not run -- take the top-ranked arc selected above, store it with its `detection_reason` unchanged, retain the top two alternatives with their `target_fit` sentences in the run summary, and continue to Phase 3.

Store: `arc_id`, `arc_display_name`, `detection_reason`. An unknown `arc_id` halts with the registry's arc list.

### Phase 3: Load the contract

Read two files, in full, before writing anything:

1. `references/arc-{arc_id}.md` — the arc contract, all seven sections: Intent, Selection, Headings, Composition, Elements, Validation, See Also. The drafting passes lean on Headings, Composition, Elements and Validation; Intent and Selection are what tell you whether the arc fits the brief at all.
2. `references/techniques-overview.md` — the eight techniques and the application matrix.

Every arc carries `contract: 2` and the same seven sections — `cogni-workspace/tests/test-arc-contract-shape.sh` keeps every bundled contract on that shape — so there is no other file to read for an arc. The language references are not loaded here — Pass 3 loads them.

**After reading,** name the four elements in order with their proportions, and say which techniques the matrix assigns to each. Re-read until both come without looking.

### Phase 4: Four passes

Draft in four passes. Each pass has one job; doing two at once is how a narrative ends up structurally right and rhetorically flat. **The draft lives in one file from Pass 1 on:** Pass 1 writes it to `--output-path` (`OUTPUT_PATH`, default `insight-summary.md` in the source directory), and Passes 2-4, Phase 5 and Phase 6 edit that same file in place — there is no separate draft path.

**Pass 1 — evidence draft.** For each element in order: map the loaded content to the element using its `Evidence sought`; when the sources span markets, weight the evidence by the brief's `--geography`; classify each material claim as `direct`, `triangulated`, `proxy` or `interpretation` (use `mixed` only when a unit deliberately combines statuses), and never upgrade evidence strength beyond what the supplied material supports; draft the body from that evidence, every quantitative claim carrying `<sup>[N](source-file.md)</sup>`, numbers assigned by first appearance in the body and reused for a reused source; hold the element's word range. Write the four elements only — no title, no opening yet — to `OUTPUT_PATH`.

**Pass 2 — argument edit.** Apply each element's `Argument move` and `Techniques`; enforce its `Hard rules`; build the transitions from `## Composition`; write the closing per the closing pattern, so that emphasis, implications and close serve the brief's `--purpose`, pronouns and ownership follow its `--perspective`, and the closing implication makes the resolved `decision_required` or `management_ask` explicit when present without inventing either when absent. Then — last, from the finished elements — write the title (arc-specific, never "Insight Summary"). Finally assemble the `**Sources**` block from the provenance map: one entry per cited `[N]`, in number order, carrying the per-source file and its preserved metadata. Pass 2 ends with the body stable and **no Executive TL;DR written**: the TL;DR is synthesized in Phase 5 from a body that has already cleared body-stage validation, and gate T0 is what makes that order enforceable rather than aspirational.

**Pass 3 — language edit.** Now, and not earlier, read `references/language-shared.md` and `references/language-{language}.md` (`language-en.md` or `language-de.md`). Localize the four headings from `## Headings` for the output language and make the prose read as executive prose per those two files: one idea per sentence, concrete actors and verbs, specificity over intensifiers, no corporate fog; for `de`, the sentence craft in `language-de.md` — Satzklammer, Mittelfeld, Funktionsverbgefüge, Nominalstil, anglicisms — and proper umlauts and ß throughout. Tune vocabulary, acronym expansion and explanation depth to the brief's `--audience` and inferred knowledge level.

**Pass 4 — rhythm and readability.** Vary sentence length; make transitions consequential rather than topical; run `language-shared.md`'s final editorial pass. Then measure:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/copywriter/scripts/readability.sh" --file "${OUTPUT_PATH}" --lang "${LANGUAGE}" --json
```

Compare `flesch_score` with the language's target band in `cogni-workspace/tests/fixtures/copywriter/readability.yml`. On a miss, revise once — the script's sub-metrics point at the passages — and measure again; report the final score as `readability_score` whatever the outcome. Count words per element against `## Composition` and adjust by adding evidence to a thin element or trimming redundant transitions, never evidence.

#### Why exactly 4 sections matters

The output uses exactly four `##` headings matching the arc's element names. Phase 7 parses these four elements to derive the brief's units, and so does every other consumer of the narrative shape; renaming, adding or merging sections breaks that pipeline.

### Phase 5: Validation

The deterministic gates run in two stages, because the Executive TL;DR is synthesized from a body that has already been graded.

**Stage 1 — the body.** Grade the four elements before any TL;DR exists:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/scripts/validate-narrative.py" \
  --narrative "${OUTPUT_PATH}" --stage body --contract "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/arc-${ARC_ID}.md" --json
```

This adds gate T0 (no TL;DR prose above the first `##`), counts E1's citation markers in the body alone — so the floor of 15 is met by the elements' own evidence, never by TL;DR repeats — and withholds T1 and T2, which have nothing to grade yet.

**Stage 2 — synthesize the TL;DR, then run the whole contract.** Once stage 1 is green, write the Executive TL;DR as a synthesis pass over the validated body, per the generation rule in `references/validation.md`, applying to it the same `references/language-shared.md` / `references/language-{language}.md` rules Pass 3 applied to the body — for `de`, that includes the opening-sentence rules `language-de.md` names for the TL;DR's first sentence — and Pass 4's rhythm pass over the result. Then run the final stage, which adds T1 and T2 and counts TL;DR markers in E1:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/scripts/validate-narrative.py" \
  --narrative "${OUTPUT_PATH}" --contract "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/arc-${ARC_ID}.md" --json
```

When a fix changes the body after the TL;DR exists, discard the TL;DR and re-synthesize it from the changed body rather than patching it, then re-run the final stage.

Then read `references/validation.md` and check its judged gates plus the contract's `## Validation` section. Fix any failure and re-run everything — a fix can break a gate that passed. A structural failure is fixed by rewriting against `## Composition`, never by renaming headings. **Attempt bound:** at most three fix-and-re-validate cycles, spanning both stages rather than three per stage. If a deterministic gate is still red after the third, abandon the run — report `qa_verdict: "fail"` and the error JSON with `phase: "5"` naming the gate — rather than looping.

**Release review (after the gates are green).** Run the banded self-review defined in `references/validation.md`: five dimensions — strategic reasoning, arc integrity, executive language, decision usefulness, execution fit — each `strong` / `adequate` / `weak`, rolled up to `pass`, `needs_revision` (revise once, review once more, then report) or `fail` (a gate could not be cleared and the run was abandoned). The review diagnoses and never rewrites the draft; the revision step acts on its findings. Its rollup is the JSON summary's `qa_verdict`.

### Phase 6: Write output

1. The narrative is already at `OUTPUT_PATH` (Pass 1 wrote it; every later step edited it in place). Finalize the frontmatter: `word_count` is the four-element body count the validator reported as `word_count` — the TL;DR and the Sources block are not body words — and gate C3 checks the two agree.
2. Verify the file exists and re-read it once, end to end.
3. Continue to Phase 7; the JSON summary is returned once the brief is written.

### Phase 7: Design brief

**Read first:** `references/design-brief-template.md` in full — the frontmatter schema, the five contract clauses in both languages, the unit grammar per target and the derivation rules. Then:

1. Read `references/density-ceilings.md` and take the `## {target}` table. A missing table halts with error JSON `phase: "7"` naming the path. Every key and value of that table is written into the brief's `density.ceilings` unchanged — the brief carries its own numbers.
2. Reload the finished narrative from `OUTPUT_PATH` (or from `--source-path` on the finished-narrative entry) and split it as the validator does: the Executive TL;DR above the first `##`, the four `##` elements in order, the `**Sources**` block after the fourth.
3. Derive the units for `--target` by the template's rule — slides: a BLUF opening on the TL;DR, one or two per element, a metric unit, a close, a sources unit; document: the summary lead and exactly four sections; infographic: headline, subline, three to five hero numbers, three to eight blocks, a CTA; web: hero, six to ten sections, a CTA. **Copy is frozen:** every line on the brief is a verbatim selection from the narrative with `<sup>[N](file)</sup>` reduced to `[N]`; compress by selecting a shorter sentence, clause or phrase, never by rewriting; on the slides target, overflow goes to `talk_track`; elsewhere it is dropped. Numbers stay exactly as the narrative wrote them. **Visual intent:** every copy-bearing slides unit carries a `visual_intent` block per `references/visual-intent.md` — required on slides except the trailing source register, recommended on infographic and web where the relationship is not obvious from `type`, and never written on `document`.
4. Promote three to six `key_figures`, each verbatim and ending `(src: [N])`; pick `climax`; fill `design:` from a caller override or the template's defaults (slides and web only); record `--theme-path` verbatim when given.
5. Write the brief to `--brief-path` (default `design-brief.md` beside the narrative): frontmatter, title and subtitle, the localized `# Rendering Contract` / `# Rendering-Vertrag` with its five clauses, the target's preamble keys, the units, the CTA where the target has one, the four `note:` lines, and the narrative's `**Sources**` block verbatim.
6. Validate:

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/scripts/check-design-brief.py" \
     --brief "${BRIEF_PATH}" --narrative "${OUTPUT_PATH}" --json
   ```

   Pass `--max-units` through when the caller set it; on `document` the checker ignores it and records that in its `notes`. Fix every `fail` finding by re-selecting, never by rewriting, and re-run — a fix can break a check that passed. **Attempt bound:** at most three fix-and-re-run cycles; if a check is still red after the third, keep the brief on disk, report `brief_qa: "fail"` and the error JSON with `phase: "7"` naming the check. Exit 2 means the brief could not be graded — the ceilings reference or the narrative is unreadable — and halts with the script's `error`, never as a finding.
7. Print the handoff. Every path printed here is absolute — never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT` or relative:

   ```
   ─── File to attach in claude.ai/design ───

   Design brief ({target}): {absolute_brief_path}

   Hand the brief to Claude Design at claude.ai/design — the organization
   design system applies, so attach theme.md only when none is configured.
   ──────────────────────────────────────────
   ```

8. Return the JSON summary: the narrative fields from Phases 1-6, plus `target`, `brief_path`, `unit_count` and `brief_word_count` as the checker reported them, `density_profile`, and `brief_qa`.

Phase 7 asks nothing in either interactive mode: every choice it makes is a selection from a finished narrative, and a selection the user wants changed is a re-run with a different `--target`, `--max-units` or narrative.

## Error Handling

On any unrecoverable failure, return `{"success": false, "error": "...", "phase": "..."}`.

| Phase | Failure | Action |
|-------|---------|--------|
| 1 | Source path not found, or no `.md` files in it | Halt with error |
| 1 | Unknown `--target` value | Halt naming the four valid targets |
| 2 | Unknown `arc_id` | Halt with the registry's arc list |
| 3 | Arc contract or techniques file missing | Halt with the missing path |
| 4 | Transformation fails | Halt with error JSON |
| 5 | A gate fails | Report, fix, re-validate all gates — at most three cycles, then abandon with `qa_verdict: "fail"` |
| 7 | The ceilings reference carries no table for `--target`, or the template is missing | Halt with the missing path |
| 7 | The checker exits 2 | Halt with the checker's `error` — the brief could not be graded |
| 7 | A check is still red after three cycles | Keep the brief, report `brief_qa: "fail"` and the error JSON naming the check |

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
