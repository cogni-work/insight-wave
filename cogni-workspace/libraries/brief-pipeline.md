---
library_id: brief-pipeline
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# Brief Pipeline — what the render chain expects of a brief

The contract each brief type meets before a renderer reads it, stated once per step with a per-type table for the values that differ. The three `story-to-*` producers that once ran these steps — `story-to-slides`, `story-to-web` (web and storyboard modes) and `story-to-infographic` — have retired, and nothing in this plugin produces a `presentation-brief.md`, `web-brief.md`, `storyboard-brief.md` or `infographic-brief.md` today: a brief is hand-authored against `libraries/presentation-brief-template.md` and the `EXAMPLE_*_BRIEF.md` worked examples, or supplied by a caller. `text-to-narrative` is not a producer of these shapes — its Phase 7 writes one `design-brief.md` for Claude Design, which the render chain never reads. What follows is the contract those authors and callers meet and the render chain — `render-html-slides`, the `pptx`, `html-slides`, `web` and `storyboard` agents, `/render-infographic` and `scripts/check-brief.py` — consumes. Where the three former producer copies of a rule differed, the stronger variant was kept and is marked.

## Source narrative

A brief is built from one narrative. The default is the `insight-summary.md` the brief lands beside — the artifact `text-to-narrative` writes, in the same shape the retired `narrative` skill wrote — but any markdown carrying an `arc_id:` frontmatter key serves. Two things in it bind the brief: the `arc_id` (see § Arc resolution) and the bold `**Sources**` paragraph after the fourth `##` section, which feeds only the per-unit Source fields and the closing references slide and never becomes a slide, section, poster or block of its own. Whoever authors or supplies the brief keeps the narrative's path: the stakeholder review below takes it as `source_narrative` for the assessor's completeness checks.

## Theme resolution

The **theme entry point** is the ecosystem's theme picker — today `cogni-workspace:manage-themes` Operation 11 (Select Theme), which scans the standard and workspace theme directories, presents an interactive AskUserQuestion and returns the absolute `theme_path` (to `theme.md`), `theme_name` and `theme_slug`. Renderers name the entry point through this section rather than in their own text, so folding the picker into another skill changes one line here. If the entry point is unavailable (cogni-workspace not installed), fall back to Glob scanning `$COGNI_WORKSPACE_ROOT/themes/*/theme.md` and present via AskUserQuestion manually.

**Path convention:** a `theme_path` written into brief frontmatter is the **absolute filesystem path** to the `theme.md` file, so the renderer can read it without path-resolution ambiguity. A caller-supplied path is recorded verbatim — never rewritten, relativised or re-resolved — so a caller that resolves the theme once can write the same path into every brief it supplies.

| Brief type | Theme in the brief | Consumed by the renderer? |
|------------|--------------------|---------------------------|
| slides | Optional. `theme` and `theme_path` are pass-through keys a brief may omit; the renderer chosen at render time (`render-html-slides`, the `pptx` or `html-slides` agent) resolves a theme through the entry point when the brief carries none. | The renderer resolves its own — pass-through only |
| web, storyboard | Required: an absolute `theme_path`. The `web` and `storyboard` agents read that `theme.md` to resolve typography, color roles and imagery direction. | Yes |
| infographic | Required: an absolute `theme_path`, by convention `/cogni-workspace/themes/{theme}/theme.md` with `smarter-service` as the default theme. The three `render-infographic-*` agents read it for the palette. | Yes |

(The four-step picker delegation and the fallback came from the slides and web copies, which were byte-identical; the path convention from the web copy; the pass-through row from the render-time theme decision.)

## Arc resolution

Execute the `## Arc Resolution Pseudocode` in `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` — it is the single statement of the priority order (`arc_id` parameter → source frontmatter `arc_id`, with the legacy `report_arc` alias → unset), the mapping lookup with its unknown-id warning, the `arc_context` store, and the `arc_definition_path` element extraction. A mapped `arc_type` overrides an `arc_type` supplied alongside it. The section roles a brief assigns afterwards are the closed set in that library's `## Arc Roles`. Every brief carries `arc_type` (one of the five visual types) in its frontmatter and `arc_id` only when the arc resolved; when the source carries no `arc_id`, the author or caller picks the `arc_type` from the narrative's headings.

| Brief type | Element names are used for |
|------------|----------------------------|
| slides | Methodology prep-slide phase labels |
| web | `section_label` values (with translations) |
| storyboard | poster station labels |
| infographic | — |

(The override rule and the translations came from the web copy.)

## Output-path resolution

A brief lives in the `cogni-visual/` folder beside its source narrative, and every renderer anchors its artifact paths on the project directory that *contains* that folder: `render-html-slides` resolves `brief_dir` to the parent of `cogni-visual/`, and the `web`, `storyboard` and `render-infographic-*` agents write only into the brief's own directory. Before writing a brief, run via Bash:

- If `output_path` is explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/{default filename}` and `mkdir -p "{source_dir}/cogni-visual"`

| Brief type | Default filename |
|------------|------------------|
| slides | `presentation-brief.md` |
| web | `web-brief.md` |
| storyboard | `storyboard-brief.md` |
| infographic | `infographic-brief.md` |

(The `mkdir -p` line was byte-identical in all three former copies; the storyboard filename came from the web copy.)

## Stakeholder review loop

> Structural validation catches schema and formatting issues, but cannot tell whether the brief will work for its audience, its presenter or reader, and as a visual communication. The `brief-review-assessor` agent evaluates from the three stakeholder perspectives matching the `brief_type` it is given — catching weak headlines that pass schema checks, layout monotony that passes variety rules, and CTA gaps that pass structural validation. Reviewing at the brief stage is efficient because changes are text edits, not re-renders.

Whoever authors or supplies a brief runs this loop before rendering. **Skip it** if `stakeholder_review=false`.

Launch the `brief-review-assessor` agent with `brief_type`, the brief content, `source_narrative` (the narrative path from § Source narrative), `audience_context` if provided, and `round: 1`. The verdict thresholds — accept, revise, reject, and the round-2 acceptance rule — are owned by `$CLAUDE_PLUGIN_ROOT/agents/brief-review-assessor.md` § Verdict Logic and are not restated here.

**On accept:** proceed to rendering.

**On revise:**
1. Apply CRITICAL improvements first, then HIGH improvements — edit the brief surgically (headlines, unit types, notes, CTAs, sequence as recommended)
2. Re-run `scripts/check-brief.py --type {brief_type}` to ensure structural integrity after the edits
3. Re-launch the assessor (`round: 2`)
4. If round 2 accepts: proceed
5. If round 2 still has issues: present the remaining issues to the user, then proceed

**On reject:** surface the verdict to the user via AskUserQuestion and let them decide whether to proceed, edit manually, or abandon.

**Headless reject** (`interactive=false`, which `stakeholder_review=true` no longer implies): a headless run reaches the reject branch with no user to ask. The AskUserQuestion is skipped per the standing convention, and the run must instead keep the brief, not render it, and surface the reject in the response — the verdict is still written to the review sibling, so the signal is recorded rather than lost — then continue. Never abort or error: a caller supplying several briefs treats one reject as that brief's outcome, not as a failure of the whole run.

**Verdict file:** write the review verdict beside the brief, deriving its name from the resolved `output_path` — replace the trailing `.md` with `.review.json`. The defaults yield `presentation-brief.review.json`, `web-brief.review.json`, `storyboard-brief.review.json` and `infographic-brief.review.json`; a caller-supplied `output_path` keeps its own stem.

| Brief type | `brief_type` | Brief content passed |
|------------|--------------|----------------------|
| slides | `slides` | the file at `output_path` |
| web | `web` | the brief, written to a `.draft` temp file if not yet written |
| storyboard | `storyboard` — the assessor loads the Print Designer / Target Audience / Exhibition Presenter trio | the brief, written to a `.draft` temp file if not yet written |
| infographic | `infographic` | the brief, written to a `.draft` temp file if not yet written |

(The revise ladder came from the slides copy, the generalised verdict-file rule and the `brief_type` branching from the web copy; the headless-reject paragraph was byte-identical in all three.)

## Caller-supplied overrides

Set by the caller that authors or supplies the brief; a hand-authored brief carries the defaults:

| Parameter | Default | Meaning | slides | web | infographic |
|-----------|---------|---------|--------|-----|-------------|
| `confidence_threshold` | `0.8` | Minimum confidence for automatic unit-type mapping | layout mapping | section-type mapping | — |
| `governing_thought` | auto-extracted | Pre-computed governing thought — validated rather than re-derived | frontmatter `governing_thought` | frontmatter `governing_thought` | frontmatter `governing_thought` (a plain parameter there) |
| `section_roles` | auto-detected | Pre-mapped section roles — validated rather than re-derived | per-slide `intent.role` | per-section `arc_role` | — |
| `buyer_appendix_path` | none | Path to buyer-appendix.md read as a supplementary source | Q&A prep in the speaker notes | the audience model behind the section copy | — |
| `design` | per `presentation-intent.md` | The deck's design intent (`register`, `dark_slides`, `speaker_notes`, `imagery`, `variations`) | frontmatter `design:` block | — | — |

(The slides table was the superset; the web table carried four of its rows with different step numbers.)
