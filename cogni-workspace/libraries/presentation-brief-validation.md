---
library_id: presentation-brief-validation
version: 1.0.0
created: 2026-09-07
---

# Validation Checklist

## Purpose

Validate a presentation brief in two halves: the mechanizable half runs as a script, the reasoning half is argued through. Layer 1 is `check-brief.py`; Layers 2–5 are the judgment calls a model must make, with the rules shared by every brief type stated once in `$CLAUDE_PLUGIN_ROOT/libraries/brief-validation-core.md` and only the slides-specific rules kept here.

## How to Use

1. Run the checker (Layer 1) and fix every `fail` before reading further.
2. Read `brief-validation-core.md` § Core principle, § Severity and § Protocol, and apply them to Layers 2–5: anticipate, check, repair; stop on the first failure, fix, re-check.
3. Record the result in the report format at the end.

---

## Layer 1: Schema Compliance (mechanized)

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/check-brief.py" --type slides "{brief_path}"
```

Exit 0 when clean, 1 with findings, 2 when the brief cannot be parsed; one `{success, data, error}` envelope whose `data.findings[]` names the check, the slide and the defect. A `fail` is CRITICAL; a `warn` is advisory (`--strict` promotes it). Nothing in this layer is verified by eye.

| Check | What it enforces |
|-------|------------------|
| `fm-core-keys`, `fm-type-version`, `fm-theme-path`, `fm-confidence` | frontmatter complete for the brief's own version (`4.1`, or legacy `4.0`); `theme_path`, when present, ends in `/theme.md`; `climax` present exactly when a slide carries `emphasis: climax` |
| `unit-fenced`, `unit-numbering` | one fenced `yaml` block per `## Slide N:`, numbered from 1 without gaps |
| `layout-enum`, `layout-required-fields`, `layout-unknown-fields` | the closed layout set below; the required fields of each layout per `pptx-layouts.md`; no invented top-level field |
| `no-color-fields` | no `Background`, `Text-Color`, `Icon-Color`, `Role`, `Intensity`, `Mood` at any depth (`intent.role` is permitted) |
| `diagram-constraints` | Mermaid shape and node/lane/task ceilings per diagram layout |
| `render-contract-section` | the localized `# Rendering Contract` with its five clauses sits between the frontmatter and `## Slide 1` |
| `idm-labels-localized` | IS/DOES/MEANS badges match the language (`IST`/`MACHT`/`BEDEUTET` for `de`) |
| `headline-length`, `jargon-client-facing` | headline length ceiling; no methodology vocabulary on client-facing slides |
| `density-idm`, `density-bullets`, `density-banner` | the Step 7.5 word budgets: IS 15 / DOES 20 / MEANS 15, bullets ≤10 words and ≤5 per field, banner ≤12 |
| `notes-sections`, `notes-no-sup`, `notes-words` | both `>>` sections when notes are present; plain links in notes; the 150–450 word target (warn) |
| `cite-format`, `cite-sequence`, `cite-zones`, `cite-references-complete` | `<sup>[N](url)</sup>` in body fields, numbered 1..K, absent from the exclusion zones, and every N on the references slide |
| `deck-bookends`, `deck-count`, `deck-variety`, `deck-consecutive`, `deck-prep-slides`, `deck-references-last` | title-slide first, closing-slide last before references; content slides 5..`max_slides`; layout variety; no three consecutive slides on one layout; the Methodology slide as Slide 2 with the INTERNAL banner; the references slide last |
| `cta-summary-consistent`, `metadata-block` | `primary_cta` is one of the proposals and every CTA type is in the taxonomy; a Generation Metadata block is present (warn) |

### Closed layout set

The checker's `layout-enum` accepts exactly these eleven names. `tests/test-brief-layout-sync.sh` pins this list to the `## Layout N:` headings in `pptx-layouts.md`, the HTML renderer's dispatcher and the checker's own enum — add a layout in all four or in none.

- `title-slide`
- `stat-card-with-context`
- `four-quadrants`
- `two-columns-equal`
- `is-does-means`
- `three-options`
- `timeline-steps`
- `layered-architecture`
- `process-flow`
- `gantt-chart`
- `closing-slide`

---

## Layer 2: Message Quality

Read `brief-validation-core.md` § Assertion headlines and apply the title-only test, the "About:" test, uniqueness and completeness to every `## Slide N:` heading. Slides-specific:

```text
  1. CHECK the title-banner test
     → Cover the slide body AND the Bottom-Banner. Does the headline alone say WHAT
       is happening AND WHY it matters? Models consistently produce weak headlines and
       patch them with banners — the output looks plausible until this test is applied.
     → FAIL if: the Banner carries the "so what" the title is missing
     → FIX: Fold the banner's consequence into the title per 05a step 5

  2. CHECK MECE sequence
     → Mutually Exclusive: are two slides arguing the SAME point? (merge or cut)
     → Collectively Exhaustive: is a major argument of the governing thought MISSING? (add)
     → WHY: Overlap dilutes focus; a gap is what a skeptical audience probes in Q&A.
     → FAIL if: overlapping or missing arguments

  3. CHECK hero number isolation
     → On stat-card-with-context slides: exactly ONE hero number in Hero-Stat-Box.Number;
       supporting numbers in Sublabel or Context-Box (brief-validation-core.md § Number plays)
     → FAIL if: multiple hero-weight numbers on one slide

  4. CHECK pyramid structure
     → Governing thought (title slide subtitle) → arguments → evidence
     → FAIL if: a slide is disconnected from the main argument — re-frame or cut
```

**Pass criteria:** every heading is an assertion that survives the title-banner test; the title sequence tells the full story; MECE verified; hero numbers isolated; pyramid visible.

---

## Layer 3: Copywriting Quality

Read `brief-validation-core.md` § Number plays and § Bullets and body text — number plays applied, bullets parallel and phrase-shaped, no hedging, no placeholders. The word budgets, the headline ceiling and the notes structure are Layer 1's. Slides-specific:

```text
  1. CHECK speaker-notes coaching (content slides with notes)
     → [Energy] tag is the first element of the ">> WHAT YOU SAY" section on every content slide
     → Q&A depth: the relevant stakeholder objections are covered (Rich mode: 3-5 items)
     → Notes coach rather than script: a presenter internalizes 200-400 words; above
       ~450 they become a teleprompter (the count itself is check-brief.py's notes-words)
     → FAIL if: [Energy] tag missing, or Q&A prep absent on a slide whose audience will probe it
     → FIX: Regenerate using presenter-prep.md sub-step 3 rules

  2. CHECK phrase notation survives the budget
     → A box or bullet that fits its word count but reads as a full sentence still
       creates a read-along competition — compress per 05a-slide-copywriting.md
```

**Pass criteria:** number plays applied; bullets phrase-shaped and parallel; no hedging; notes coach with [Energy] and Q&A prep on every content slide.

---

## Layer 4: Presentation Logic

Bookends, slide count, layout variety, the prep-slide positions and the references-slide position are Layer 1's. Reason through:

```text
  1. CHECK story arc flow
     → Expected trajectory (arc-taxonomy.md § Arc Roles):
       tension builds (problem/urgency/evidence) → release (solution/proof) → momentum (CTA)
     → FAIL if: solution appears before any problem/evidence slide
     → FAIL if: proof appears before the solution it proves
     → FIX: Reorder to follow the arc flow from Step 4

  2. CHECK the internal prep slides' content
     → Methodology (Slide 2): Detail-Grid has 3-4 key concepts per pipeline node;
       PEAK/RELEASE pacing guide present in Speaker-Notes
     → Buying Center (Slide 3, Rich audience mode only): each quadrant has Label (role),
       Sublabel (title), Bullets (lead-with + key messages)
     → FAIL if: a prep slide is present but hollow
     → FIX: Generate using presenter-prep.md rules

  3. CHECK the solution overview slide (why-change arc only)
     → Present BEFORE the first Power Position (is-does-means) slide, on two-columns-equal
       ("What We Propose" | "How It Maps to Your Needs"), drawn from the 03-why-you
       Executive Summary — not from the Power Positions themselves
     → FAIL if: Power Position slides appear without a preceding solution overview
```

**Pass criteria:** arc flow logical; prep slides carry their content; solution overview precedes Power Positions (why-change arc).

---

## Layer 5: Content Integrity

Read `brief-validation-core.md` § Completeness against the source, § Language consistency and § Source preservation. Citation format, numbering, exclusion zones, references completeness and label localization are Layer 1's. Slides-specific:

```text
  1. CHECK section coverage
     → Every major narrative section (from the Step 4 role mapping) has at least one slide
     → FAIL if: an entire narrative section has no corresponding slide

  2. CHECK Power Positions coverage (why-change arc only)
     → Every Power Position from power-positions.md has a slide (is-does-means or two-columns-equal)
     → FAIL if: a Power Position has no slide

  3. CHECK IS/DOES/MEANS semantic correctness (why-change arc only)
     → IS-Box describes what the SOLUTION is (positioning) — FAIL if it describes the problem
     → DOES-Box states capabilities with measurable outcomes — FAIL if it restates IS
     → MEANS-Box gives technology/methodology proof — FAIL if it carries business impact metrics
     → FIX: Apply the transformation table from 03-story-arc-analysis.md

  4. CHECK Source fields
     → A slide whose body carries a URL-bearing citation has a Source field naming the
       primary source (presentation-brief-template.md § Citation Handling Rules)
     → FAIL if: a cited slide has no Source, or a Source names a URL the narrative does not carry
```

**Pass criteria:** all sections represented; statistics preserved; Power Positions covered and semantically correct; the right claims carry the citations; characters preserved.

---

## Self-Validation Checklist

Before marking Step 9 complete, verify ALL items:

- [ ] `check-brief.py --type slides` exits 0 on the written brief; every `warn` was read
- [ ] Every slide heading is an assertion that passes the title-only and title-banner tests
- [ ] No overlapping or missing arguments (MECE); pyramid structure visible
- [ ] Number plays applied; hero numbers isolated; bullets phrase-shaped and parallel; no hedging
- [ ] Speaker notes coach: [Energy] tag first in "WHAT YOU SAY", Q&A prep per content slide
- [ ] Story arc flow: tension → release → momentum
- [ ] Prep slides carry Detail-Grid concepts, PEAK/RELEASE pacing and (Rich mode) stakeholder cards
- [ ] Solution overview precedes the first Power Position slide (why-change arc only)
- [ ] All major narrative sections and high-confidence statistics represented
- [ ] Power Positions covered; IS = positioning, DOES = capabilities + outcomes, MEANS = technical proof
- [ ] Source fields on cited slides; no invented URL; German characters and URL characters preserved

**ANY ❌: STOP. Fix the failing check before proceeding.**

---

## Validation Report Format

```yaml
validation_report:
  layers:
    schema_compliance: {pass/fail}      # check-brief.py exit code
    message_quality: {pass/fail}
    copywriting_quality: {pass/fail}
    presentation_logic: {pass/fail}
    content_integrity: {pass/fail}
  slides_validated: {count}
  issues_found: {count}
  issues_fixed: {count}
```
