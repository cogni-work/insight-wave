#!/usr/bin/env bash
# Standing-fixtures runner for the relative-to-source readability rule
# (Step 5 translation validation, introduced in cogni-copywriting v0.3.1).
#
# Rule under test: output_score >= source_score - SOFT_FLOOR, with both
# files scored on the target-language Flesch scale via
# `calculate_readability.py --lang <target>`.
#
# Exits 0 iff every fixture's actual verdict matches its expected verdict.
# Closes #258 (umlaut syllable counter) + #259 (this fixture suite).
# Extended for #255 Slice 1 with FR composition + ES decomposition fixtures
# that exercise the FR (Kandel-Moles) formula and ES source detection.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../../.." && pwd)"
SCRIPT="$REPO_ROOT/cogni-copywriting/skills/copywriter/scripts/calculate_readability.py"
SOFT_FLOOR=5

DE_SOURCE="$REPO_ROOT/cogni-copywriting/copywriter-workspace/test-docs/german-with-citations.md"
EN_TRANSLATION="$HERE/de-dense-source.en.md"
EN_CLEAN="$HERE/en-clean-source.md"
EN_DEGRADED="$HERE/en-degraded-translation.md"
# #255 Slice 1 fixtures
FR_OUTPUT="$HERE/en-clean-source.fr.md"   # faithful, polished FR of EN_CLEAN
ES_SOURCE="$HERE/es-clean-source.md"      # clean ES source
ES_OUTPUT="$HERE/es-clean-source.en.md"   # faithful EN of the ES source

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: calculate_readability.py not found at $SCRIPT" >&2
  exit 2
fi
for f in "$DE_SOURCE" "$EN_TRANSLATION" "$EN_CLEAN" "$EN_DEGRADED" "$FR_OUTPUT" "$ES_SOURCE" "$ES_OUTPUT"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: fixture missing: $f" >&2
    exit 2
  fi
done

read_score() {
  local file="$1" lang="$2"
  python3 "$SCRIPT" "$file" --lang "$lang" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["flesch_score"])'
}

# run_fixture LABEL SOURCE OUTPUT LANG EXPECTED
# Returns 0 on match, 1 on mismatch. Prints a one-line summary either way.
run_fixture() {
  local label="$1" source="$2" output="$3" lang="$4" expected="$5"
  local src_score out_score margin actual
  src_score="$(read_score "$source" "$lang")"
  out_score="$(read_score "$output" "$lang")"
  margin="$(python3 -c "print(round(${out_score} - (${src_score} - ${SOFT_FLOOR}), 2))")"
  if python3 -c "import sys; sys.exit(0 if ${out_score} >= ${src_score} - ${SOFT_FLOOR} else 1)"; then
    actual="PASS"
  else
    actual="FAIL"
  fi
  printf '[%s] src=%s out=%s margin=%s actual=%s expect=%s\n' \
    "$label" "$src_score" "$out_score" "$margin" "$actual" "$expected"
  [[ "$actual" == "$expected" ]]
}

matched=0
mismatched=0

# Fixture 1: faithful DE -> EN translation should pass the relative rule
# even though both scores sit far below the absolute EN 50-60 band.
if run_fixture "de-dense" "$DE_SOURCE" "$EN_TRANSLATION" "en" "PASS"; then
  matched=$((matched + 1))
else
  mismatched=$((mismatched + 1))
fi

# Fixture 2: clean EN source vs degraded EN "translation" should fail
# the rule, sanity-checking that real style degradation is caught.
if run_fixture "degraded" "$EN_CLEAN" "$EN_DEGRADED" "en" "FAIL"; then
  matched=$((matched + 1))
else
  mismatched=$((mismatched + 1))
fi

# Fixture 3 (#255): composition EN -> FR. EN source and a faithful, polished
# FR rendering both scored on the FR (Kandel-Moles) scale should pass the rule.
if run_fixture "en-to-fr" "$EN_CLEAN" "$FR_OUTPUT" "fr" "PASS"; then
  matched=$((matched + 1))
else
  mismatched=$((mismatched + 1))
fi

# Fixture 4 (#255): decomposition ES -> EN. Dense ES source and a faithful EN
# translation both scored on the EN scale should pass the rule.
if run_fixture "es-to-en" "$ES_SOURCE" "$ES_OUTPUT" "en" "PASS"; then
  matched=$((matched + 1))
else
  mismatched=$((mismatched + 1))
fi

echo "Summary: $matched matched, $mismatched mismatched"
[[ $mismatched -eq 0 ]]
