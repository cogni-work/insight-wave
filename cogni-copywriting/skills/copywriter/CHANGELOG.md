# Changelog - Copywriter Skill

All notable changes to the copywriter skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.5.0] - 2026-05-26

> The skill internal bump 7.4.0 → 7.5.0 ships in plugin release 0.5.0.

### Added — Arc-mode translation EN↔DE (corporate-visions, jtbd-portfolio)

Lifts the arc-mode translation block (Slice 1's unconditional `arc_id` abort) for the **EN↔DE pair**, scoped to the two arcs with downstream DE localization today: **corporate-visions** and **jtbd-portfolio**. This is **Slice 2** of #255. FR/IT/PL/NL/ES arc-mode stays blocked (Slice 3 / #318): upstream `language-templates.md` defines arc headings only in EN/DE.

#### How it works

- **Conditional arc gate (Step 1 pre-check #3):** the unconditional `arc_id` abort becomes a three-way gate — *allow* when both ends are EN/DE and `arc_id` is in scope; *abort with a coverage message* for other arcs on an EN↔DE pair; *abort with the #318 message* when the pair involves FR/IT/PL/NL/ES.
- **Heading substitution (new in Step 2.5):** arc-element + bridge headings are **substituted**, not freely translated. The skill reads the **canonical target-language headings from the downstream mirror in `arc-preservation.md`** — it does **not** read cogni-narrative files at runtime (there is no stable path between two separately-installed plugins). Element identification is **positional** (the Nth arc-element H2 maps to element index N), because the upstream `arc-definition.md` (U2) and `language-templates.md` (U3) heading forms disagree and a real narrative's source headings may match neither; prefix-matching is only a sanity guard.
- **Validation (Step 5):** in translation+arc mode the "heading unchanged" rule is replaced by "headings match the `TARGET_LANG` canonical set byte-for-byte (umlauts required for `de`)"; H2 count + order must match the source (the absolute "exactly 6" rule no longer applies); per-element word count uses a relative-to-source band (`× factor × (1 ± 0.20)`, factor ≈ 1.20 →de / ≈ 0.83 →en).

### Fixed — arc-preservation.md DE headings reconciled to upstream (audit C3)

The downstream localized heading table disagreed with upstream `language-templates.md` for corporate-visions: `Warum Aendern` (ASCII, *wrong word*) vs. `Warum Wandel`, and `Warum Wir` vs. `Warum Sie`. Reconciled both to the upstream full forms and upgraded the table to hold the **full canonical EN+DE headings** for both in-scope arcs (the substitution source). Fixed the bridge heading `Weiterfuehrende Lektuere` → `Weiterführende Lektüre` (umlaut), and the German-character validation rule `ae, oe, ue, ss` → `ä, ö, ü, ß` — which had directly contradicted the skill's own German-character preservation principle. `audit-copywriter` C2/C3 now pass **for corporate-visions and jtbd-portfolio**; the pre-existing C1/C3 findings for the other 9 arcs (missing detection rows / missing DE) are unchanged and out of scope.

#### Changed Files

- `references/09-preservation-modes/arc-preservation.md` — localized table upgraded to full canonical EN+DE headings (corporate-visions + jtbd-portfolio) with element index; corporate-visions DE reconciled to upstream; bridge umlaut fix; native-vs-translation note; German-character rule + integration-example umlaut fix; **"What You Must Never Modify" rules and the Validation Checklist carved out for translation mode, and the buggy "H2 count — exactly 6" assertion replaced with "count + order unchanged from source"** (it false-rejected the 5-H2 italic-subtitle layout); `version` 2.0 → 2.1.
- `SKILL.md` — Step 1 pre-check #3 conditional arc gate (now also detects heading-pattern arcs without `arc_id`, and lets an invalid `TARGET_LANG` fall through to the accept-set check); Step 2.5 arc-heading-substitution sub-step (downstream mirror, positional identification, bridge sourced from the bridge list, abort-and-preserve guard when elements ≠ 4); Step 5 arc-aware validation made translation-mode-aware.
- `references/01-core-principles/translation-principles.md` — Translate/Preserve list: the heading line no longer says "arc-mode translation is blocked"; it now points to the Step 2.5 substitution carve-out (this file is loaded on every translation run).
- `references/00-index.md` — CHECK 0 now loads arc references alongside translation references for in-scope EN↔DE arc docs; `version` 8.3 → 8.4.
- `references/09-preservation-modes/arc-technique-map.md` — Post-Polish Validation translation-mode note (relative word band + heading check); `version` 2.0 → 2.1.
- `agents/copywriter.md`, `commands/copywrite.md` — replaced stale "arc-mode translation is blocked / aborts on `arc_id`" claims with the EN↔DE-supported (corporate-visions, jtbd-portfolio) substitution behavior.
- `copywriter-workspace/test-docs/arc-narrative.de.md` — NEW full-canonical-DE corporate-visions fixture for the DE→EN reverse test (`arc-narrative.md` is left untouched, as it is also an input to cogni-visual's story-to-web eval).
- Docs/version: `README.md`, `CLAUDE.md`, `.claude-plugin/plugin.json` (0.4.0 → 0.5.0), marketplace mirror.

#### Migration Notes

Non-breaking. Default `TARGET_LANG` unset preserves all existing polish behaviour exactly; native arc polish still validates headings as *unchanged*. Non-arc translation (Slice 1) is unaffected.

References #317 (Slice 2) · Part of #255. Arc-mode FR/IT/PL/NL/ES and broader arc coverage tracked in #318 (Slice 3).

## [7.4.0] - 2026-05-26

> The skill internal bump 7.3.3 → 7.4.0 ships in plugin release 0.4.0.

### Added — Translation languages FR/IT/PL/NL/ES (non-arc, EN/DE pivot)

Extends the EN↔DE translate-then-polish flow (v0.3.0) to French, Italian, Polish, Dutch, and Spanish for **non-arc** documents. This is **Slice 1** of #255; arc-mode translation and direct non-EN/DE pairs remain out of scope (see below).

#### What ships

- **20 new direction reference files** under `references/01-core-principles/`: `translation-{src}-to-{tgt}.md` for every pair with EN or DE on one end — `{en,de}→{fr,it,pl,nl,es}` (composition) and `{fr,it,pl,nl,es}→{en,de}` (decomposition). Composition files carry target-language register (FR vous / IT Lei / ES usted / NL u / PL Pan-Pani), diacritic-correctness tables, number/date/currency conventions, and a worked example. DE-pivot composition files cross-reference the matching EN-pivot file for the full target-production rules; X→de files cross-reference `translation-en-to-de.md` for German production.
- **Per-language readability** in `scripts/calculate_readability.py`: FR (Kandel-Moles), IT (Flesch-Vacca), ES (Szigriszt-Pazos/INFLESZ), NL (Flesch-Douma), PL (generic-Flesch fallback). A 7-way `detect_language`, a `count_syllables(word, lang, source_lang)` dispatcher, a `FLESCH_COEFFS` table, and a `FLESCH_TARGETS` table. **EN/DE coefficients, counters, and detector classification are unchanged** — the dispatcher routes `de`/`en` to the untouched `count_syllables_de`/`count_syllables_en`, so the #258/#261-protected cross-language scores stay byte-identical.
- **Deterministic dispatch**: `SKILL.md` Step 2.5 and `00-index.md` CHECK 0 now construct `translation-{source_lang}-to-{TARGET_LANG}.md` from the resolved languages instead of an IF-ladder. `translation-principles.md` gains a single-source-of-truth charset table and a 7×7 validity matrix.
- **Pivot guard**: new Step 1 pre-check #5 rejects directions where neither end is EN or DE (e.g. fr→it) with an actionable message. The accept-set check (#4) widens to `{de,en,fr,it,pl,nl,es}`. The `arc_id` abort (#3) stays blocking.
- **Pass rule unchanged**: Step 5 still uses the relative-to-source rule (`output_score ≥ source_score − 5`), scoring source and output on the target-language scale. New-language absolute bands are aspirational only; PL counting is a documented defensible approximation.

#### Cross-plugin invocation (#255 §3) — decision: explicit

Translation stays an **explicit** `/copywrite --translate=` step. Downstream adapters (`cogni-narrative narrative-adapt`, `cogni-marketing channel-adapter`, `cogni-portfolio customer-narrative-writer`) do **not** silently chain translation — this avoids hidden language-switches in pipelines. No code change; a recorded decision.

#### Changed Files

- **NEW** under `references/01-core-principles/`: 20 `translation-{src}-to-{tgt}.md` files (FR/IT/PL/NL/ES pivot directions).
- `references/01-core-principles/translation-principles.md` — Per-Language Charset Rules section; deterministic dispatch + 7×7 validity matrix replacing the EN↔DE-only direction list.
- `scripts/calculate_readability.py` — 7-way detector (EN/DE classification preserved); `count_syllables` dispatcher + `count_syllables_other`; `FLESCH_COEFFS` / `FLESCH_TARGETS` tables; CLI accepts `de|en|fr|it|pl|nl|es|auto`.
- `contracts/readability.yml` — 1.2.0 → 1.3.0; widened `--lang` enum and `detected_language`.
- `scripts/readability.sh` — 7-code formula-name display; widened usage/help.
- `SKILL.md` — `TARGET_LANG` param, Step 1 pre-checks (#4 widened, #5 pivot guard), Step 2.5 deterministic dispatch, Step 5 charset rules, bundled resources.
- `references/00-index.md` — CHECK 0 deterministic dispatch; File Inventory (+20 files); version 8.2 → 8.3.
- `agents/copywriter.md`, `commands/copywrite.md`, `skills/copy-json/SKILL.md` — widened accept-set, pivot/arc notes, shared charset pointer.
- `copywriter-workspace/test-docs/sample.{fr,it,es,nl,pl}.md` — new per-language sample docs.
- `copywriter-workspace/test-fixtures/readability-rule/` — new FR/ES relative-rule fixtures wired into `run.sh`.
- Docs/version: `README.md`, `CLAUDE.md`, `.claude-plugin/plugin.json` (0.3.3 → 0.4.0), marketplace mirror.

#### Migration Notes

Non-breaking. Default `TARGET_LANG` unset preserves all existing polish behaviour exactly; EN/DE scoring (including the v0.3.1–0.3.3 cross-language relative rule) is byte-identical because the syllable dispatcher delegates `de`/`en` to the original counters and the detector keeps EN/DE classification. Arc-mode translation and direct non-EN/DE pairs are explicitly blocked with actionable messages.

References #255 (Slice 1). Arc-mode (Slice 2 EN↔DE, Slice 3 FR/IT/PL/NL/ES) tracked as follow-up children of #255.

## [7.3.3] - 2026-05-19

> The skill internal bump 7.3.2 → 7.3.3 ships in plugin release 0.3.3.

### Fixed — Silent-e adjustment under-counted German -e-final words in cross-language mode

`count_syllables_en` in `scripts/calculate_readability.py` unconditionally subtracted 1 syllable for any word ending in `-e` (silent-`e`). That is correct English (`hope`, `time`, `gave`), but wrong on German prose where final `-e` is almost always pronounced (`Phase`, `Hilfe`, `Strategie`, `Industrie`, plus short function words like `die`, `eine` and plurals like `Pilotprojekte`). When Step 5 translation validation scores DE source text on the EN scale via `--lang en` (the cross-language pattern introduced in PR #257, v0.3.1), every `-e`-final German word lost 1 syllable. Under the EN Flesch formula's `−84.6·ASW` penalty, that **inflated** the EN-scaled source score and made the relative-to-source rule `output_score ≥ source_score − 5` artificially easier — same direction of bias as #258, different word set.

Fix: gate the silent-`e` adjustment on the detected source-prose language. `count_syllables_en` gains an optional `source_lang='en'` parameter; `calculate_flesch_score` always runs `detect_language` on the cleaned prose and passes the result through. The Flesch *formula* still runs on the requested target-language scale (`lang`); only the *syllable counter* now reflects the actual source-prose phonology (`source_lang`). When the two coincide (pure-EN, pure-DE) the behaviour is byte-identical to v0.3.2; the only callers whose scores shift are cross-language ones — exactly the bug.

Empirical impact on the anchor case from #261: scoring `test-docs/german-with-citations.md` with `--lang en` moves from `-13.6` (post-#258, v0.3.2) to `-32.1` post-fix — an 18.5-point downward correction. The issue estimated ~3–5 units; the measured shift is larger because the bug fires on every `-e`-final token (70 of 320 words), not only the visible content lemmas. Same direction of correction as #258, larger magnitude. Standing fixture `de-dense` margin widens from 25.8 to 44.3 (still PASS); `degraded` fixture and EN translation output are byte-identical (real-EN prose, silent-e still fires).

#### Changed Files

- `skills/copywriter/scripts/calculate_readability.py` — `count_syllables_en` gains `source_lang='en'` parameter; silent-`e` adjustment gated on `source_lang == 'en'`. `calculate_flesch_score` runs `detect_language` unconditionally and passes the result as `source_lang`.
- `skills/copywriter/references/01-core-principles/translation-principles.md` — new "Language-faithful syllable counting" paragraph in the "Readability in Translation Mode" section.
- `copywriter-workspace/test-fixtures/readability-rule/README.md` — sample-output block updated with post-fix measured values (`de-dense` `src=-32.1`, `margin=44.3`).
- `.claude-plugin/plugin.json` — `0.3.2` → `0.3.3`.
- `.claude-plugin/marketplace.json` (repo root) — cogni-copywriting entry `0.3.2` → `0.3.3`.
- `CHANGELOG.md` — this entry.

#### Migration Notes

Non-breaking. Single-language callers (the entire pre-0.3.1 calling pattern) see byte-identical scores — pure-English prose detects as `source_lang == 'en'` and the silent-`e` adjustment still fires unchanged; pure-German prose uses `count_syllables_de`, which never had the adjustment. The only callers whose scores shift are DE-in-EN-mode (Step 5 cross-language scoring) invocations — which is the entire point of the fix. The shift is downward (more accurate), making the relative rule slightly stricter for dense DE→EN translations. No downstream consumers to coordinate.

Closes #261.

## [7.3.2] - 2026-05-19

> The skill internal bump 7.3.1 → 7.3.2 ships in plugin release 0.3.2.

### Fixed — EN syllable counter under-counted German umlauts in cross-language mode

`count_syllables_en` in `scripts/calculate_readability.py` used the vowel set `"aeiouy"`, while its DE sibling `count_syllables_de` used `"aeiouyäöü"`. PR #257 (the relative-to-source readability rule, v0.3.1) introduced a *cross-language* invocation pattern in Step 5: when `TARGET_LANG` is set, both source and output are scored on the target-language scale via `--lang $TARGET_LANG`. For a DE→EN translation that means `count_syllables_en` runs over **German** prose — silently under-counting syllables in any word containing `ä/ö/ü` (e.g., `über` → 1 syllable instead of 2). The EN Flesch formula penalises syllables-per-word at `−84.6·ASW`, so under-counted syllables artificially **inflate** the EN-scaled Flesch score and make the relative rule `output_score ≥ source_score − 5` easier to clear — masking faithful-but-degraded translations.

Fix: align the EN vowel set with the DE counter (`"aeiouy"` → `"aeiouyäöü"`). Single-character-set extension; the existing `previous_was_vowel` loop and silent-`e` adjustment are untouched. Pure-English callers see no change (no umlauts to count); EN-only test doc `test-docs/english-memo.md` returns a byte-identical score post-fix.

Empirical impact on the anchor case from #256: scoring `test-docs/german-with-citations.md` with `--lang en` moves from `-6.7` to `-13.6` post-fix — a 6.9-point downward correction that more accurately reflects German syllable density and tightens the relative-rule threshold for DE→EN translations.

### Added — Standing test fixtures for the relative-to-source readability rule

New directory `copywriter-workspace/test-fixtures/readability-rule/` anchors both directions of the Step 5 translation validator with two fixtures:

- **Fixture 1 (`de-dense`, expect PASS):** canonical DE source `test-docs/german-with-citations.md` paired with a faithful EN translation `de-dense-source.en.md`. Demonstrates that the relative rule clears dense Mittelstand prose translations even when both scores sit far below the absolute EN 50–60 band.
- **Fixture 2 (`degraded`, expect FAIL):** synthesised clean EN (`en-clean-source.md`, Flesch 69.6) vs. synthesised degraded EN (`en-degraded-translation.md`, Flesch 48.1). Sanity-checks that real style degradation is caught by the rule.

The runner `run.sh` is bash 3.2 + Python stdlib only (no `jq`), scores each pair via `calculate_readability.py --lang en`, applies the rule, and exits 0 iff every fixture's actual verdict matches the expected verdict. Fixture 1 references the canonical DE source by path (no copy, no symlink — single source of truth). Any future regression in the syllable counter, the Flesch formula, paragraph segmentation, the Step 5 invocation, or the soft-floor threshold flips at least one verdict and exits non-zero.

#### Changed Files

- `skills/copywriter/scripts/calculate_readability.py` — `vowels = "aeiouy"` → `vowels = "aeiouyäöü"` on line 105 (EN syllable counter).
- `copywriter-workspace/test-fixtures/readability-rule/README.md` — fixture documentation, lineage to #258/#259, run instructions.
- `copywriter-workspace/test-fixtures/readability-rule/run.sh` — fixture runner (bash + Python stdlib).
- `copywriter-workspace/test-fixtures/readability-rule/de-dense-source.en.md` — faithful EN translation of the canonical DE source, all 6 citation markers + URLs preserved byte-identical.
- `copywriter-workspace/test-fixtures/readability-rule/en-clean-source.md` — synthesised EN at Flesch 69.6.
- `copywriter-workspace/test-fixtures/readability-rule/en-degraded-translation.md` — synthesised EN at Flesch 48.1 (same propositional content as the clean source, but nominalised + lengthened).
- `.claude-plugin/plugin.json` — `0.3.1` → `0.3.2`.
- `.claude-plugin/marketplace.json` (repo root) — cogni-copywriting entry `0.3.1` → `0.3.2`.
- `CHANGELOG.md` — this entry.

#### Migration Notes

Non-breaking. Single-language callers (the entire pre-0.3.1 calling pattern) see byte-identical scores because pure English text contains no umlauts. The only callers whose scores shift are DE-in-EN-mode (or future Phase-2 cross-language) invocations — which is the entire point of the fix. The shift is downward (more accurate), making the relative rule slightly stricter for dense DE→EN translations. No downstream consumers to coordinate.

Closes #258. Closes #259.

## [7.3.1] - 2026-05-19

> The skill internal bump 7.3.0 → 7.3.1 ships in plugin release 0.3.1.

### Fixed — Readability validation in translation mode

Step 5 enforced the absolute Flesch band (EN 50–60 / DE 30–50) regardless of source density, which rewarded unfaithful translation when the source already sat below band. The validator now uses a relative-to-source rule when `TARGET_LANG` is set: score source and output on the target-language scale and require `output_score ≥ source_score − 5`. The absolute band remains visible as an aspirational note (`in absolute band` / `below absolute band, faithful to source — pass`). Non-translation polish is unchanged.

Surfaced during the real-document test of v0.3.0 (PR #254): source `cogni-copywriting/copywriter-workspace/test-docs/german-with-citations.md` (Amstad 8.8 — already below the DE 30–50 band) translated faithfully to EN at Flesch 8.7 — a like-for-like score that the absolute-band rule rejected. The translation was correct; the spec was wrong.

#### Changed Files

- `skills/copywriter/SKILL.md` — Step 5 standard readability bullet scoped to non-translation; new fifth Translation-specific validation bullet ("Readability relative to source") with invocation + pass rule + reporting convention.
- `skills/copywriter/references/01-core-principles/translation-principles.md` — new `## Readability in Translation Mode` section between "Audience Expansion is Step 3's Job" and "Per-Direction References".
- `.claude-plugin/plugin.json` — `0.3.0` → `0.3.1`.
- `.claude-plugin/marketplace.json` (repo root) — cogni-copywriting entry `0.3.0` → `0.3.1`.
- `CHANGELOG.md` — this entry.

#### Reused mechanisms (no new code)

- `scripts/calculate_readability.py` already accepts `--lang de|en|auto` and applies the matching syllable counter + Flesch/Amstad formula. Step 5 now calls it twice with explicit `--lang $TARGET_LANG` (once on source, once on output) — Option A from #256. No script edit.
- `contracts/readability.yml` interface unchanged; no contract version bump.

#### Migration Notes

Non-breaking. Non-translation polish (no `TARGET_LANG`) keeps the absolute-band check. Faithful translations of dense B2B source that previously failed Step 5 now pass.

Closes #256.

## [7.3.0] - 2026-05-19

> Note: this `7.x.x` line tracks the **copywriter skill's internal versioning** (independent of the plugin's external `version` in `.claude-plugin/plugin.json`). The skill internal bump 7.2.0 → 7.3.0 ships in plugin release 0.3.0.

### Added - Translation Mode (EN↔DE)

The copywriter skill gains a translate-then-polish two-pass flow. Before this change, users with existing English content who needed German output (or vice versa) had no path inside the insight-wave ecosystem — every generation plugin assumes you regenerate in the target language from upstream. Regeneration is often not viable: source content was hand-edited, the originating project is closed, or teams collaborate across languages off a canonical English narrative.

#### New `TARGET_LANG` skill arg

`TARGET_LANG`: `de` | `en` (optional; default: unset, no translation).

Resolution hierarchy (mirrors the `AUDIENCE` precedent from v7.2.0):

1. Explicit `TARGET_LANG` skill arg
2. Document frontmatter `target_language:` field
3. Unset (no translation; skill polishes in source language only)

#### Two-pass model

- **Pass A — Translate (new Step 2.5)**: faithful semantic transfer from source to target language. Citations, URLs, frontmatter technical IDs, protected content, code blocks, and Power Position structure markers stay byte-identical. Acronyms pass through unchanged.
- **Pass B — Polish (existing Step 3)**: target-language style discipline. Wolf-Schneider rules for DE output (12-word clauses, Satzklammer breaking, Mittelfeld shortening, Floskel elimination); Flesch tuning and active-voice transformation for EN output. Audience-tuned acronym expansion runs here on the translated text.

This split gives clean diagnostics: meaning failures land in Pass A; style failures land in Pass B.

#### v1 scope and limits

- **Languages**: EN ↔ DE only. Other `TARGET_LANG` values abort with a clear message.
- **Arc mode blocked**: when document frontmatter contains `arc_id`, translation aborts. Arc-element heading texts require exact-match preservation (see `09-preservation-modes/arc-preservation.md` lines 87–97), and the EN/DE heading mapping integration with `cogni-narrative/skills/narrative/references/language-templates.md` is non-trivial. Deferred to Phase 2.
- **Source == target**: no-op. The skill logs a message and falls through to standard polish in the source language.

#### Changed Files

- **NEW** under `references/01-core-principles/`: `translation-principles.md` (two-pass philosophy, preserve-vs-translate list, citation anchoring), `translation-en-to-de.md` (Sie-form, umlaut traps, Satzklammer, compound nouns, gender resolution), `translation-de-to-en.md` (compound decomposition, sentence splitting, nominal→verbal style, number/date formatting).
- **Workflow surface**: `SKILL.md` (Step 1 `TARGET_LANG` + pre-checks, new Step 2.5 Translate Pass, Step 5 translation validation), `references/00-index.md` (CHECK 0 conditional load, v8.2), `agents/copywriter.md` (input + JSON output), `commands/copywrite.md` (`--translate=de|en`), `skills/copy-json/SKILL.md` (pass-through + direction-aware charset check).
- **Docs and version**: `CLAUDE.md`, `README.md`, `.claude-plugin/plugin.json` (0.2.3 → 0.3.0), marketplace mirror, `copywriter-workspace/eval_set.json` (translation query flipped to `should_trigger: true`).

#### Rationale

A separate translation plugin would fight the existing grain. cogni-copywriting already has every prerequisite: bilingual EN/DE awareness, Wolf-Schneider DE style discipline, language-aware Flesch/Amstad scoring, language detection in Step 3, the three preservation invariants (German chars / citations / protected content) that translation must honour anyway, and the proven `copy-json` delegate-with-a-mode adapter pattern. Extending the copywriter skill with a parallel parameter to `AUDIENCE` is the smallest architectural surface.

See #255 for the Phase 2 follow-up (FR/IT/PL/NL/ES + arc-mode translation).

#### Migration Notes

- **Non-breaking**: default `TARGET_LANG` unset preserves all existing polish behaviour exactly.
- **Existing `--lang` parameter unchanged**: it remains the *source*-language override for the language detector. `TARGET_LANG` is the new orthogonal *target* hint.
- **Phase 2 follow-up**: tracked as [#255](https://github.com/cogni-work/insight-wave/issues/255) covering FR/IT/PL/NL/ES translation directions and arc-mode translation (which requires heading-set substitution via `language-templates.md`).

---

## [7.2.0] - 2026-05-19

### Added - Audience-Tuned First-Mention Acronym Expansion

Acronym/abbreviation handling becomes a default polish discipline, sitting alongside Wolf-Schneider clarity, active voice, paragraph splitting, and bold anchoring in Step 3 of the workflow. Each acronym is expanded **once** on its first mention; subsequent mentions stay verbatim. The depth of expansion is tuned to the document's audience.

Before this change, the discipline had to be ordered as a second, separate polish pass — typical pain: the DACH security portfolio pitch series (5 pitches × Wolf-Schneider polish) needed 5 extra copywriter dispatches just for acronym expansion.

#### New `AUDIENCE` skill arg

`AUDIENCE`: `expert` | `mixed` | `lay` (default: `mixed`).

Resolution hierarchy (used by acronym handling and any future audience-aware discipline):

1. Explicit `AUDIENCE` skill arg
2. Document frontmatter `audience:` field
3. Default: `mixed`

#### Audience-tuned depth

| Audience | Behaviour |
|---|---|
| `expert` | Expand only genuinely technical/ambiguous acronyms (`SIEM`, `MTTI`, `B3S`). Regulation proper nouns like `NIS2`, `DSGVO`, `BSI`, `DORA` stay unaltered. |
| `mixed` *(default)* | Expand technical acronyms; explain common regulation acronyms once on first mention. |
| `lay` | Expand virtually every acronym plus a short plain-language gloss in the document language: `MDR (Managed Detection and Response — ein Dienstleister erkennt und stoppt Angriffe rund um die Uhr für Sie)`. |

#### Always-excluded tokens

- Proper nouns: `KRITIS-Dachgesetz`, `EU AI Act`, `B3S`, `ISO 27001`, `TISAX`, `DAX`
- Brand names: `Magenta Security`, `Open Telekom Cloud`, `Microsoft Entra ID`, `CrowdStrike Falcon`
- Audience-trivial tokens: `IT`/`EU`/`USD` always; `M365` for non-`lay`
- Arc/sales structure markers: `**IS**:`, `**DOES**:`, `**MEANS**:` and standalone arc-element labels (already preservation targets in `08-sales-techniques/power-positions.md` line 318)

Compound references like `§38 BSIG-NIS2` carry the explanation on the **compound**, not on the bare token.

#### Changed Files

- **NEW `references/01-core-principles/acronym-handling-principles.md`**: Detection heuristic, audience-tuned depth table, format convention, exclusions, compound-reference rule, arc/sales preservation cross-reference, validation criteria. DE+EN worked examples.
- **NEW `references/05-examples/example-acronyms-audience.md`**: Same source paragraph polished three times (`expert` / `mixed` / `lay`) demonstrating exclusions, lay-audience glosses, compound references, second-mention verbatim handling.
- **`SKILL.md`**: Step 1 adds `AUDIENCE` parameter and resolution-order paragraph. Step 3 "Both languages — formatting" adds item 6 (acronym handling). Step 5 validation checklist adds one bullet. Bundled Resources lists the new reference.
- **`references/00-index.md`**: Always-load core block in Standard and Arc modes now loads `acronym-handling-principles.md`. File Inventory entry added. Index version bumped to 8.1.
- **`agents/copywriter.md`**: New `AUDIENCE` input; passed through in the Step 2 skill invocation. No new JSON output field — acronym info (if surfaced) fits in existing `improvements[]`.
- **`CLAUDE.md`**: Copywriter Polish Flow Step 3 description and Key Conventions extended.

#### Rationale

This discipline is editorial-universal — as foundational as active voice or the Sie-Form for mixed B2B audiences — but was missing from the default polish loop. With audience-tuning, the discipline reads neither belehrend for experts (NIS2 not expanded in front of a KRITIS-CISO) nor opaque for lay readers (MDR carries a plain-language gloss for the SMB-Inhaber audience).

Closes #248.

#### Migration Notes

- **Non-breaking**: Default `AUDIENCE=mixed` matches the reasonable middle ground; callers and frontmatter consumers continue to work without changes.
- **For portfolio pitches**: `cogni-portfolio:portfolio-communicate` 0.9.49+ emits `audience:` and `personas:` in pitch frontmatter automatically — no manual backfill needed.

---

## [7.1.0] - 2026-02-25

### Fixed - Language-Aware Flesch Targets for German

The Flesch readability target of 50-60 was applied uniformly to both English and German text. The Amstad formula inherently produces lower scores for German due to compound words, making 50-60 unreachable for German business writing. Introduced language-aware targets.

#### Target Ranges

| Language | Formula | Old Target | New Target |
|----------|---------|-----------|-----------|
| English | Standard Flesch | 50-60 | 50-60 (unchanged) |
| German | Amstad (1978) | 50-60 | 30-50 |

#### Changed Files

- **calculate_readability.py**: Returns `flesch_target_min` and `flesch_target_max` fields based on detected language (EN: 50/60, DE: 30/50)
- **readability.sh**: All display and assessment logic uses dynamic thresholds from script output instead of hardcoded 50-60
- **SKILL.md**: Step 8 validation and script documentation updated to reference language-aware targets
- **contracts/readability.yml**: Added `flesch_target_min` and `flesch_target_max` to output schema
- **readability-principles.md**: German target updated from 50-60 to 30-50 with explanation of why German scores lower
- **copywrite.md**: `--flesch-target` parameter documentation updated to describe language-aware defaults

### Rationale

Research on the Amstad (1978) formula shows German business writing typically scores 30-50, not 50-60. German compound words like "Qualitaetssicherungssysteme" produce many syllables per word, which the Amstad formula cannot fully compensate for. A German Amstad score of 30-50 corresponds roughly to the readability level of an English text scoring 50-60.

### Migration Notes

- **Non-breaking**: English targets unchanged at 50-60
- **Improved German scoring**: German documents that previously failed (e.g., scoring 22-40) will now be assessed against realistic 30-50 target
- **New JSON fields**: `flesch_target_min` and `flesch_target_max` added to script output; consumers should use these instead of hardcoded values

---

## [7.0.0] - 2026-02-24

### Added - Arc-Aware Polishing Mode

#### New Reference: arc-technique-map.md

- **references/09-preservation-modes/arc-technique-map.md**: Per-arc, per-element technique strengthening rules
  - Technique map tables for all 5 arcs (corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation)
  - Element-specific Number Play variant selection (compound impact, ratio framing, comparative anchoring, etc.)
  - Element-specific polish rules (what to strengthen, what to preserve per element)
  - Cross-arc technique application table
  - Technique validation checklist

#### Rewritten Reference: arc-preservation.md

- **references/09-preservation-modes/arc-preservation.md**: Upgraded from blunt "don't touch headings" to arc-aware preservation
  - Arc detection logic: YAML frontmatter `arc_id`, pattern matching against known arc heading patterns
  - Structure preservation rules: FORBIDDEN vs ALLOWED modifications with arc-aware nuance
  - Technique-aware validation: verifies element techniques survived polishing
  - Integration patterns for cogni-narrative and cogni-trends
  - Localization support (EN/DE heading variants)

#### Enhanced SKILL.md Workflow

- **Step 1 (Parse Parameters)**: Added arc detection before framework loading. When arc detected, loads arc-preservation.md and arc-technique-map.md instead of messaging frameworks
- **Step 3 (Apply Structure)**: Skipped entirely in arc mode — the arc IS the structure
- **Step 5 (Apply Impact Techniques)**: Arc-aware mode applies techniques PER ELEMENT using the technique map, not generically across the whole document
- **Step 8 (Validate & Write)**: Added arc-specific technique validation checklist (heading integrity, technique integrity, word count targets, per-element citation counts)
- **Bundled Resources**: Added Arc Preservation section listing both new/updated references
- **Description**: Updated to mention arc-aware polishing of cogni-narrative stories
- **When to Use**: Added arc narrative polishing trigger

#### Updated 00-index.md

- **Loading Logic**: Arc detection takes priority over framework/deliverable loading
- **Tier 9**: New progressive disclosure tier for arc-aware preservation
- **Version**: Updated to 7.0

### Changed

- **Arc preservation philosophy**: From "preserve headings only" to "preserve structure AND strengthen element-specific techniques"
- **Impact technique application**: In arc mode, techniques are element-tuned (e.g., compound impact for Why Pay, forcing functions for Why Now) rather than generic
- **Validation**: Arc mode adds per-element technique validation on top of existing checks

### Rationale

cogni-narrative creates story arc narratives with specific narrative techniques per element (PSB for Why Change, Forcing Functions for Why Now, IS-DOES-MEANS for Why You, etc.). The previous arc-preservation mode treated all elements identically — "don't touch headings, improve body text." This was too blunt:

- The copywriter couldn't strengthen arc-specific techniques because it didn't know what they were
- Number Plays were applied generically, not tuned to element purpose
- No validation that arc techniques survived polishing

The new arc-aware mode gives the copywriter element-level intelligence: it knows Why Now needs forcing functions, Why Pay needs compound impact calculations, and Why You needs You-Phrasing in the DOES layer. This produces polished narratives that are both structurally sound AND technique-rich.

### Migration Notes

- **Non-breaking for standard mode**: All standard copywriting workflows (memos, emails, reports, etc.) are unchanged
- **Enhanced for arc mode**: Narratives with `arc_id` frontmatter now get element-specific technique strengthening
- **Backward compatible**: Old arc preservation constraints still work — the new system is a superset

---

## [6.2.0] - 2025-12-06

### Added - Citation Formatting Standards

#### New Reference: citation-formatting.md

- **references/03-formatting-standards/citation-formatting.md**: Comprehensive citation formatting standards
  - **Rule 1**: Move citations from section headers to specific claims (granular placement)
  - **Rule 2**: Citations in recommendation lists (Begruendung → Umsetzung pattern)
  - **Rule 3**: Superscript commas between consecutive citations for visual separation
  - Pattern recognition and replacement guidelines
  - Edge case handling (single, dual, multiple citations)
  - Validation checklist for citation quality
  - Optional automation script for batch processing

#### Enhanced SKILL.md Workflow

- **Step 6 (Validate & Write)**: Added citation formatting validation checkpoint
- **New workflow section**: "Apply citation formatting" with two-step process:
  1. Move citations to specific claims in Begruendung/Umsetzung sections
  2. Add superscript commas between consecutive citations using perl
- **Updated output summary**: Added "Citation Formatting" status line
- **Updated bundled resources**: Added Formatting Standards section with citation-formatting.md
- **Version updated**: 6.2 with changelog

### Changed

- **Citation placement philosophy**: From header-level to claim-level citations for improved academic rigor
- **Citation visual separation**: Consecutive citations now use superscript commas for consistency
- **Validation checklist**: Expanded to include citation formatting compliance

### Rationale

Research synthesis and TIPS-style documents benefit from precise citation placement and visual clarity:

- **Granular citations** enable readers to verify specific claims rather than entire sections
- **Superscript commas** maintain visual consistency and improve readability of citation sequences
- **Academic rigor** is enhanced when each claim has its own supporting evidence

These standards were developed through real-world application on German-language research reports (smarter-service trend analysis) and address common citation formatting challenges in multi-source documents.

### Technical Implementation

```bash
# Automatic superscript comma insertion
perl -pi -e 's/<\/sup><sup>/<\/sup><sup>,<\/sup> <sup>/g' document.md
```

**Pattern detection:**
- Before: `<sup>[15](path)</sup><sup>[16](path)</sup>`
- After: `<sup>[15](path)</sup><sup>,</sup> <sup>[16](path)</sup>`

### Migration Notes

- **Non-breaking change**: Citation formatting is applied only when citations are present
- **Backward compatible**: Documents without citations are unaffected
- **Opt-in enhancement**: Skill automatically detects and applies citation formatting
- **Manual override**: Users can skip citation formatting if needed

---

## [6.0.0] - 2025-12-03

### Breaking Changes

- **Removed diagram placeholder preservation** - Documents with `<diagram-placeholder>` tags are no longer specially handled. Copywriter now focuses purely on text copywriting.
- **Removed diagram parameters from agent** - `DIAGRAM_GENERATION` and `DIAGRAM_TYPES` parameters removed from copywriter agent.

### Removed

**From SKILL.md:**

- Line 18: Delegation reference to diagram-expert skill (`**Not for:** Diagrams or visualizations`)
- Lines 86-156: Entire "Placeholder & Figure Preservation" section (71 lines)
- Lines 223-228: Placeholder integrity validation from Step 6

**From copywriter.md (agent):**

- `DIAGRAM_GENERATION` and `DIAGRAM_TYPES` input parameters
- Diagram types validation step
- "Generate diagrams (if enabled)" from skill execution list
- `diagrams_generated` and `diagram_types` JSON output fields
- "Invalid diagram types" error recovery row

### Rationale

Complete separation between text copywriting and diagram generation. Copywriter skill now focuses 100% on traditional copywriting:

- Messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB)
- Persuasion techniques (number plays, power words, rhetorical devices)
- Document quality standards
- Executive impact optimization

Diagram functionality belongs exclusively in the diagram-expert skill.

### Migration Notes

- If you were using `DIAGRAM_GENERATION: true`, use the diagram-expert skill instead
- Documents with `<diagram-placeholder>` tags should be processed separately for diagram generation
- The copywriter skill remains focused on text quality and structure

---

## [5.0.0] - 2025-12-02

### Added - Impact Techniques Enhancement

#### New Reference Tier: 07-impact-techniques/

- **number-plays.md**: Quantification techniques for transforming vague claims into concrete, memorable data
  - Ratio framing (percentages → "X in Y" format)
  - Specific quantification (vague → precise numbers)
  - Comparative anchoring (raw numbers → familiar references)
  - Before/after contrasts with improvement calculations
  - Compound impact chains for cumulative effect
  - Rule of Three numbers for memorability

- **power-words.md**: Emotional trigger vocabulary organized by category
  - Urgency words (now, deadline, limited, immediate)
  - Exclusivity words (exclusive, insider, select, elite)
  - Trust words (proven, guaranteed, validated, certified)
  - Achievement words (breakthrough, transform, accelerate, unlock)
  - Strategic placement guidelines and density control (3-5 per page)

- **rhetorical-devices.md**: Structural persuasion techniques
  - Rule of Three (tricolon) patterns
  - Anaphora (repetition at start)
  - Antithesis (contrasting pairs)
  - Cadence (rhythmic flow) patterns
  - Device selection by purpose and placement guidelines

- **executive-impact.md**: C-suite and decision-maker optimization
  - 5 Executive Imperatives (lead with ask, quantify everything, respect time, decision clarity, signal credibility)
  - Board memo and executive summary templates
  - Decision request structures
  - Executive-appropriate vocabulary guidance

#### Enhanced SKILL.md

- Added Step 5 (Apply Impact Techniques) to workflow
- Added `impact_level` parameter (standard | high)
- Enhanced content requirements gathering for high-impact documents
- Added Impact Techniques Quick Reference section
- Expanded Quick Reference table with recommended techniques per deliverable
- Updated validation checklist with impact audit

#### Updated 00-index.md

- Added Tier 7: Impact Techniques section
- Updated loading logic for executive/high-impact documents
- Version bumped to 5.0

### Changed

- SKILL.md workflow expanded from 5 steps to 6 steps
- Description enhanced to include persuasion techniques
- Version updated to 5.0 (Impact Techniques Enhancement)

### Rationale

Business documents benefit from sophisticated persuasion techniques that go beyond structural frameworks. Research shows:
- Real numbers create 2x more engagement than percentages
- Strategic power words boost click-through rates by up to 121%
- 95% of decisions are driven by emotion, then rationalized
- Executives spend only 30-60 seconds on first-pass reading

The new impact techniques tier provides evidence-based guidance for creating documents that persuade, not just inform.

---

## [4.0.0] - 2025-12-02

### Changed - Further Simplification

#### Removed All Diagram Artifacts

- **07-diagram-templates/**: Entire directory removed (12 files)
- **scripts/generate-diagram.sh**: Removed
- **contracts/generate-diagram.yml**: Removed
- Copywriter is now 100% text-focused

#### Simplified SKILL.md

- Reduced from 254 lines to 146 lines (~43% reduction)
- Consolidated 7-step workflow to 5 steps
- Removed verbose TodoWrite expansion instructions
- Applied Anthropic metaprompt patterns for clarity
- Removed delegation references to diagram-expert

#### Updated References

- **00-index.md**: Updated to version 4.0
- Maintained 6-tier progressive disclosure (no changes needed)

### Rationale

Complete separation of concerns: copywriter handles text, diagram-expert handles visuals. No cross-references or delegation needed.

---

## [3.0.0] - 2025-12-02

### Changed - Initial Simplification

#### Removed Diagram from Workflow

- **SKILL.md**: Removed Step 5.5 (Generate Diagrams) and all diagram-related content
- **00-index.md**: Removed Tier 7 (Diagram Templates) section entirely
- **step-by-step-guide.md**: Removed Step 5.5 diagram generation and Step 6.7 diagram validation
- All diagram functionality moved to dedicated `diagram-expert` skill

#### Updated Files

- **SKILL.md**: Simplified from 356 lines to 254 lines (~29% reduction)
- **00-index.md**: Reduced from 6 tiers to 6 tiers (removed Tier 7)
- **step-by-step-guide.md**: Streamlined validation workflow

### Rationale

The copywriter skill is now focused purely on text-based business document creation. Diagram generation is a separate concern handled by the `diagram-expert` skill, which provides:

- Consulting-style SVG/HTML diagrams
- SWOT analysis, trend radars, 2x2 matrices
- Professional black & white design
- Obsidian compatibility

### Migration Notes

- **Breaking Change**: Diagram requests should now use `diagram-expert` skill
- Text-based document creation unchanged
- All 8 deliverable types still supported
- All 7 messaging frameworks still supported

---

## [2.0.0] - 2025-10-29

### Added - Major Enhancement Release

#### Examples (Tier 5)
- **example-memo-bluf.md**: Complete memo example using BLUF framework with quality metrics and analysis
- **example-email-scqa.md**: Business email example using SCQA framework with subject line analysis
- **example-brief-pyramid.md**: Executive brief example using Pyramid Principle with financial analysis
- **example-proposal-fab.md**: Consulting proposal example using FAB framework with ROI analysis

#### Templates (Tier 6)
- **template-memo.md**: Fillable memo template with writing tips and common pitfalls
- **template-email.md**: Business email template with subject line guidance and mobile optimization tips
- **template-brief.md**: Executive brief template with MECE framework guidance
- **template-proposal.md**: Business proposal template with comprehensive structure and best practices

#### Core Principles (Tier 1)
- **plain-language-principles.md**: Comprehensive plain language guide with government standards and word choice tables
- **readability-principles.md**: Detailed scannability guide with visual hierarchy, white space, and mobile optimization principles

#### Scripts & Tools
- **readability.sh**: Bash wrapper for calculate_readability.py with error handling, colored output, and user-friendly reporting
  - Validates Python 3 availability
  - Checks file existence and readability
  - Provides formatted output with target range validation
  - Displays overall quality assessment

#### Documentation
- **CHANGELOG.md**: Version tracking and change documentation
- Enhanced **Step 6 validation** in SKILL.md with comprehensive TodoWrite checklist integration
  - 6 validation sections (Metrics, Framework, Deliverable, Principles, Content, Polish)
  - Framework-specific requirements for all 7 frameworks
  - Deliverable-specific requirements for all 8 deliverable types
  - Example TodoWrite integration workflow

### Changed
- **SKILL.md**: Enhanced Step 6 from basic checklist to comprehensive validation workflow
- **Architecture**: Completed all 6 tiers of progressive disclosure system
- **Documentation**: Added detailed examples throughout validation sections

### Fixed
- Broken references in 00-index.md to plain-language-principles.md and readability-principles.md (files now exist)
- Missing examples directory (was empty, now contains 4 comprehensive examples)
- Missing templates directory (was empty, now contains 4 fillable templates)
- Incomplete validation workflow (now has complete TodoWrite integration)

## [1.0.0] - 2025-10-27

### Added - Initial Release

#### Core Structure
- **SKILL.md**: Main skill definition with 7-step workflow
- **00-index.md**: Master index with progressive disclosure loading logic

#### Core Principles (Tier 1)
- **clarity-principles.md**: Wolf-Schneider clarity rules
- **conciseness-principles.md**: Economy of language principles
- **active-voice-principles.md**: Active vs passive voice guidance

#### Messaging Frameworks (Tier 2)
- **bluf-framework.md**: Bottom Line Up Front (military/executive)
- **pyramid-framework.md**: McKinsey Pyramid Principle (consulting)
- **scqa-framework.md**: Situation-Complication-Question-Answer (narrative)
- **star-framework.md**: Situation-Task-Action-Result (case studies)
- **psb-framework.md**: Problem-Solution-Benefit (marketing)
- **fab-framework.md**: Feature-Advantage-Benefit (product)
- **inverted-pyramid-framework.md**: Journalism style (web content)

#### Formatting Standards (Tier 3)
- **markdown-basics.md**: Standard markdown syntax reference
- **visual-elements.md**: Tables, callouts, lists, emphasis
- **heading-hierarchy.md**: H1-H3 standards and scannable headers

#### Deliverable Types (Tier 4)
- **memos.md**: Internal communication structure
- **emails.md**: Email format and conventions
- **briefs.md**: Brief structure and length
- **reports.md**: Report organization and sections
- **proposals.md**: Proposal structure and persuasion
- **one-pagers.md**: Single-page layout and density
- **executive-summaries.md**: Summary structure and conciseness
- **business-letters.md**: Formal correspondence

#### Scripts
- **calculate_readability.py**: Python script for calculating Flesch score, paragraph metrics, visual elements, and header hierarchy

#### Architecture
- Progressive disclosure system design (Tiers 1-6)
- Modular reference architecture with no circular dependencies
- Loading logic based on deliverable type and framework selection

## Versioning Policy

### Version Numbers
- **Major (X.0.0)**: Breaking changes, complete architecture redesign
- **Minor (0.X.0)**: New deliverable types, frameworks, or major features
- **Patch (0.0.X)**: Bug fixes, documentation improvements, minor enhancements

### Release Cycle
- **Continuous**: Documentation and example improvements
- **As-needed**: New deliverable types or frameworks when demand emerges
- **Quarterly review**: Quality assessment and user feedback integration

## Upgrade Notes

### From 1.0.0 to 2.0.0

**Breaking Changes:** None

**New Features:**
- 4 complete examples in 05-examples/
- 4 fillable templates in 06-templates/
- 2 new core principle references
- Enhanced validation workflow with TodoWrite integration
- Bash wrapper for readability metrics

**Migration:** No migration needed. All existing workflows continue to function. New features are additive.

**Benefits:**
- **Progressive disclosure now complete**: All 6 tiers functional
- **Better validation**: Comprehensive checklist with TodoWrite tracking
- **Easier adoption**: Templates provide starting points for new users
- **Learning resource**: Examples demonstrate framework application

## Future Roadmap

### Planned for 3.0.0
- **Additional examples**: One-pager, report, business letter examples
- **Video tutorials**: Screen recordings of skill usage
- **Language variants**: British English vs American English guidance
- **Industry-specific adaptations**: Legal, healthcare, finance variants

### Under Consideration
- **AI readability improvements**: Automated suggestions for improving metrics
- **Integration tests**: Validate all examples meet stated quality metrics
- **Multi-language support**: Templates and examples in German, Spanish, French
- **Style guide generator**: Create custom style guides based on organization preferences

## Contributing

When adding new features:
1. Update appropriate tier (01-06 directories)
2. Add entry to CHANGELOG.md
3. Update 00-index.md if adding new deliverable or framework
4. Create examples demonstrating new features
5. Update SKILL.md if workflow changes
6. Increment version number appropriately

## Support & Documentation

- **Main Documentation**: SKILL.md
- **Quick Start**: 00-index.md
- **Examples**: references/05-examples/
- **Templates**: references/06-templates/
- **Architecture**: See SKILL.md "Progressive Disclosure Benefits" section

## License

Copyright 2025-2026. Part of cogni-workspace plugin.
