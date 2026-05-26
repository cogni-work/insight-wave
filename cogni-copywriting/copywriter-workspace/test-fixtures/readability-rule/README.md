# Readability-rule fixtures

Standing anchor cases for the relative-to-source readability rule introduced
in PR #257 (cogni-copywriting v0.3.1):

> `output_score >= source_score - 5`, where both files are scored on the
> **target-language** Flesch scale via
> `calculate_readability.py --lang $TARGET_LANG`.

The rule is exercised by Step 5 translation validation in
`skills/copywriter/SKILL.md`. Without standing fixtures, a future edit to
the syllable counter, the Flesch formula constants, paragraph
segmentation, the Step 5 invocation, or the soft-floor threshold could
silently shift the pass/fail boundary. The fixtures below anchor
both directions of the rule and (from #255 Slice 1) the new-language formulas.

Lineage: closes #258 (umlaut syllable counter under-count in
cross-language mode) + #259 (this fixture suite). Extended for #255 Slice 1
(fixtures 3–4) to cover the FR (Kandel-Moles) formula and ES source detection.

## Fixtures

| # | Direction | Source | Output | `--lang` | Expected |
|---|-----------|--------|--------|----------|----------|
| 1 | DE → EN translation, faithful | `test-docs/german-with-citations.md` (canonical DE source, shared with the test-docs corpus) | `de-dense-source.en.md` | `en` | **PASS** — dense Mittelstand prose scores far below the EN 50–60 band on either side, but the relative rule clears it |
| 2 | EN → EN "translation", degraded | `en-clean-source.md` (synth ≈ 70) | `en-degraded-translation.md` (synth ≈ 50) | `en` | **FAIL** — nominalised + lengthened sentences move the score by more than the 5-point soft floor |
| 3 | EN → FR composition, faithful + polished | `en-clean-source.md` | `en-clean-source.fr.md` | `fr` | **PASS** — EN scored on the FR (Kandel-Moles) scale runs high (English is less syllable-dense than French); a polished short-sentence FR rendering still clears the floor |
| 4 | ES → EN decomposition, faithful | `es-clean-source.md` (clean ES, detects as `es`) | `es-clean-source.en.md` | `en` | **PASS** — dense ES on the EN scale sits low; a faithful EN translation clears the relative rule comfortably |

Fixture 1 reuses the canonical DE source from `copywriter-workspace/test-docs/`
rather than copying it here — single source of truth, no symlink, no drift.
The fixtures directory holds the other files.

Fixture 3 is deliberately a *polished* (short-sentence) FR rendering: Step 5
scores the post-Pass-B output, not the raw Pass-A draft. Composition into a
more syllable-dense language inflates the source's target-scale baseline, so a
faithful output must be tightened to clear the floor — exactly what Pass B does.

## Run

```bash
bash cogni-copywriting/copywriter-workspace/test-fixtures/readability-rule/run.sh
```

Output is one line per fixture plus a summary, e.g.:

```
[de-dense] src=-32.1 out=7.2 margin=44.3 actual=PASS expect=PASS
[degraded] src=69.6 out=48.1 margin=-16.5 actual=FAIL expect=FAIL
[en-to-fr] src=85.8 out=96.4 margin=15.6 actual=PASS expect=PASS
[es-to-en] src=14.0 out=71.2 margin=62.2 actual=PASS expect=PASS
Summary: 4 matched, 0 mismatched
```

Exit status is `0` iff every fixture's actual verdict matches the expected
verdict. Any regression in the rule's behaviour — syllable counter, formula,
or invocation pattern — flips at least one verdict and exits non-zero.

## Scope

- No CI wiring (deliberately out of scope for #259; a future cogni-dev
  validation skill or workflow can pick this up).
- Partial multi-language coverage. #255 Slice 1 adds FR (composition) and ES
  (decomposition) fixtures; IT/PL/NL composition and the remaining decomposition
  directions are exercised by the per-language sample docs in `test-docs/` and
  can be promoted to standing fixtures as needed.
