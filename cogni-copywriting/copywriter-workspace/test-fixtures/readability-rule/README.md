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
silently shift the pass/fail boundary. The two fixtures below anchor
both directions of the rule.

Lineage: closes #258 (umlaut syllable counter under-count in
cross-language mode) + #259 (this fixture suite).

## Fixtures

| # | Direction | Source | Output | `--lang` | Expected |
|---|-----------|--------|--------|----------|----------|
| 1 | DE → EN translation, faithful | `test-docs/german-with-citations.md` (canonical DE source, shared with the test-docs corpus) | `de-dense-source.en.md` | `en` | **PASS** — dense Mittelstand prose scores far below the EN 50–60 band on either side, but the relative rule clears it |
| 2 | EN → EN "translation", degraded | `en-clean-source.md` (synth ≈ 70) | `en-degraded-translation.md` (synth ≈ 50) | `en` | **FAIL** — nominalised + lengthened sentences move the score by more than the 5-point soft floor |

Fixture 1 reuses the canonical DE source from `copywriter-workspace/test-docs/`
rather than copying it here — single source of truth, no symlink, no drift.
The fixtures directory only holds the new files.

## Run

```bash
bash cogni-copywriting/copywriter-workspace/test-fixtures/readability-rule/run.sh
```

Output is one line per fixture plus a summary, e.g.:

```
[de-dense] src=-13.6 out=7.2 margin=25.8 actual=PASS expect=PASS
[degraded] src=69.6 out=48.1 margin=-16.5 actual=FAIL expect=FAIL
Summary: 2 matched, 0 mismatched
```

Exit status is `0` iff every fixture's actual verdict matches the expected
verdict. Any regression in the rule's behaviour — syllable counter, formula,
or invocation pattern — flips at least one verdict and exits non-zero.

## Scope

- No CI wiring (deliberately out of scope for #259; a future cogni-dev
  validation skill or workflow can pick this up).
- No multi-language matrix. FR/IT/PL/NL/ES fixtures are deferred to the
  Phase-2 work tracked in #255.
