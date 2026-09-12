# Density Ceilings

The one home of every text-length ceiling Phase 7 applies when it condenses the narrative into a design brief. Each `## {target}` table is read at run time by `scripts/check-design-brief.py`, keyed by the brief's `target`, and copied verbatim into the brief's `density.ceilings` so the brief carries its own numbers; the checker and the writer resolve a ceiling **here** and nowhere else.

Every number was carried from the place the ecosystem stated it before this skill existed — the `Home` column names it. The homes that survive are `scripts/check-brief.py`, this skill's own `scripts/validate-narrative.py` and the arc contracts, and the render-chain libraries the `story-to-*` producers left behind when they retired; `cogni-workspace/tests/test-brief-density-sync.sh` fails when a value here and a surviving home disagree. A row marked *sole home* was carried from a producer file that retired with its skill, so this table is now the only statement of that number and the suite lists the key as untracked by design.

`Counts` says what the ceiling counts. Words are whitespace-delimited tokens; characters are Unicode code points; lines are `- ` list items; units are the brief's numbered `##` sections.

## slides

A Claude Design presentation. On-slide copy is scanned in about three seconds before the presenter speaks, so a point is a phrase, never a sentence.

| Key | Ceiling | Counts | Home |
|-----|---------|--------|------|
| `headline_chars_max` | 110 | characters of a `## Slide N:` headline | `scripts/check-brief.py` `HEADLINE_MAX` |
| `slide_points_max_lines` | 4 | `slide_points` lines per slide | sole home — carried from the retired story-to-slides outline script |
| `slide_point_words_max` | 10 | words per `slide_points` line | `scripts/check-brief.py` `BULLET_WORDS_MAX` |
| `slide_point_words_max_table` | 20 | words per `slide_points` line when `type: table` | `scripts/check-brief.py` `IDM_BUDGET` DOES-Box |
| `talk_track_words_min` | 150 | words of `talk_track` on an element slide | `scripts/check-brief.py` `NOTES_WORDS_MIN` |
| `talk_track_words_max` | 450 | words of `talk_track` on any slide | `scripts/check-brief.py` `NOTES_WORDS_MAX` |
| `units_min` | 5 | slides | `scripts/check-brief.py` `DECK_MIN_CONTENT` |
| `units_max_default` | 15 | slides, unless `--max-units` lowers it | `scripts/check-brief.py` `DECK_MAX_DEFAULT` |

## document

A Claude Design document or report. The narrative's own length band applies: the four elements travel complete, and the executive summary is the narrative's TL;DR, which does not scale with the body.

| Key | Ceiling | Counts | Home |
|-----|---------|--------|------|
| `target_length_default` | 1675 | words of the four section bodies, when the narrative carries no `target_length` | `scripts/validate-narrative.py` `DEFAULT_TARGET` |
| `band_lower` | 0.85 | multiplier on the target for the body-word floor | `scripts/validate-narrative.py` gate C1 |
| `band_upper` | 1.15 | multiplier on the target for the body-word ceiling | `scripts/validate-narrative.py` gate C1 |
| `summary_words_min` | 60 | words of `executive_summary` | `scripts/validate-narrative.py` `TLDR_WORDS` |
| `summary_words_max` | 100 | words of `executive_summary` | `scripts/validate-narrative.py` `TLDR_WORDS` |
| `summary_sentences_min` | 2 | sentences of `executive_summary` | `scripts/validate-narrative.py` `TLDR_SENTENCES` |
| `summary_sentences_max` | 4 | sentences of `executive_summary` | `scripts/validate-narrative.py` `TLDR_SENTENCES` |
| `sections` | 4 | `## Section N:` units, exactly | the arc contracts' `## Elements`, four `### N.` sections each |

## infographic

A Claude Design infographic. A 2,000-word narrative becomes 80-150 words: hero numbers, labels of a few words, one assertion headline. The standard row applies; `profile: dense` raises the two `_dense` ceilings for a magazine-density page.

| Key | Ceiling | Counts | Home |
|-----|---------|--------|------|
| `headline_words_max` | 12 | words of `headline` | `libraries/infographic-block-copywriting.md` title block |
| `subline_words_max` | 15 | words of `subline` | `libraries/infographic-block-copywriting.md` title block |
| `hero_numbers_min` | 3 | `hero_numbers` lines | sole home — carried from the retired story-to-infographic distillation rules |
| `hero_numbers_max` | 5 | `hero_numbers` lines | sole home — carried from the retired story-to-infographic distillation rules |
| `hero_label_words_max` | 4 | words of a hero number's label | `libraries/infographic-block-copywriting.md` kpi-card Hero-Label |
| `blocks_min` | 3 | `## Block N:` units | `libraries/infographic-style-presets.md` universal floor |
| `blocks_max` | 8 | `## Block N:` units, standard profile | `libraries/infographic-style-presets.md` density table |
| `blocks_max_dense` | 14 | `## Block N:` units, dense profile | `libraries/infographic-style-presets.md` density table |
| `point_words_max` | 6 | words per `points` line | sole home — carried from the retired story-to-infographic distillation rules |
| `words_max` | 150 | on-brief words in total, standard profile | `libraries/infographic-style-presets.md` density table |
| `words_max_dense` | 250 | on-brief words in total, dense profile | `libraries/infographic-style-presets.md` density table |

## web

A Claude Design web page or poster. Each section is read in about five seconds while scrolling, so a body is two or three sentences and a headline is an assertion.

| Key | Ceiling | Counts | Home |
|-----|---------|--------|------|
| `hero_headline_words_max` | 10 | words of `hero.headline` | `libraries/web-section-copywriting.md` Headline Rules |
| `hero_subline_words_max` | 25 | words of `hero.subline` | `libraries/web-section-copywriting.md` Body Text Constraints |
| `section_headline_words_max` | 12 | words of a `## Section N:` headline | `libraries/web-section-copywriting.md` Headline Rules |
| `headline_chars_max` | 70 | characters of any headline | `libraries/web-section-copywriting.md` Headline Rules |
| `section_body_words_max` | 50 | words of a section `body` | `libraries/web-section-copywriting.md` Body Text Constraints |
| `bullet_words_max` | 8 | words per `bullets` line | `libraries/web-section-copywriting.md` Body Text Constraints |
| `quote_words_max` | 30 | words of a `quote` | `libraries/web-section-copywriting.md` Body Text Constraints |
| `attribution_words_max` | 10 | words of an `attribution` | `libraries/web-section-copywriting.md` Body Text Constraints |
| `sections_min` | 6 | `## Section N:` units | `libraries/web-section-architecture.md` section count |
| `sections_max` | 10 | `## Section N:` units | `libraries/web-section-architecture.md` section count |
