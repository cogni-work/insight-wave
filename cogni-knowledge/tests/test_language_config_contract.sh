#!/usr/bin/env bash
# test_language_config_contract.sh — #309 P1.2-rest contract assertions:
# output_language as a first-class config/setup step.
#
# Two surfaces in one file (matching the test_finalize_contract.sh style):
#   1. knowledge-binding.py init writes the schema-0.1.1 research_defaults
#      block — populated from --market/--output-language when passed, and
#      back-compat-defaulted to dach/en when omitted.
#   2. knowledge-setup/knowledge-plan SKILL.md content-invariant grep tests
#      for the Step 2.5 / Step 0.5 resolution UX, so the contract cannot
#      silently regress.
#
# bash 3.2 + grep + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/knowledge-binding.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: knowledge-binding.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- 1. binding.py research_defaults round-trip -------------------------

# 1a. init WITH --market/--output-language persists research_defaults.
KB1="$WORK/kb-flagged"
mkdir -p "$KB1/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KB1/.cogni-wiki/config.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KB1" \
  --knowledge-slug t-fr \
  --knowledge-title "T FR" \
  --wiki-path "$KB1" \
  --market fr \
  --output-language fr \
  --prose-density executive \
  --tone analytical \
  --citation-format chicago \
  --target-words 4000 >/dev/null

if python3 -c "
import json
b = json.load(open('$KB1/.cogni-knowledge/binding.json'))
assert b['schema_version'] == '0.1.3', b['schema_version']
rd = b.get('research_defaults', {})
assert rd.get('market') == 'fr', rd
assert rd.get('output_language') == 'fr', rd
# #309 P2 writer-quality knobs persisted from flags (schema 0.1.3 since #409).
assert rd.get('prose_density') == 'executive', rd
assert rd.get('tone') == 'analytical', rd
assert rd.get('citation_format') == 'chicago', rd
assert rd.get('target_words') == 4000, rd
# research_defaults is a sibling block, NOT nested under curator_defaults.
assert 'output_language' not in b.get('curator_defaults', {}), 'must be a sibling block'
assert 'prose_density' not in b.get('curator_defaults', {}), 'must be a sibling block'
print('OK')
" | grep -q OK; then
  green "PASS: init with all flags writes research_defaults (market/language + 4 P2 knobs) + schema 0.1.3"
else
  red "FAIL: research_defaults not persisted from flags (or wrong schema/placement/knobs)"
  errors=$((errors + 1))
fi

# 1b. init WITHOUT the flags still writes the full DEFAULT block (back-compat).
KB2="$WORK/kb-default"
mkdir -p "$KB2/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KB2/.cogni-wiki/config.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KB2" \
  --knowledge-slug t-def \
  --knowledge-title "T DEF" \
  --wiki-path "$KB2" >/dev/null

if python3 -c "
import json
b = json.load(open('$KB2/.cogni-knowledge/binding.json'))
assert b['schema_version'] == '0.1.3', b['schema_version']
rd = b.get('research_defaults', {})
assert rd.get('market') == 'dach', rd
assert rd.get('output_language') == 'en', rd
# #309 P2: omitted knob flags fall back to the safe DEFAULT_RESEARCH_DEFAULTS.
assert rd.get('prose_density') == 'standard', rd
assert rd.get('tone') == 'objective', rd
assert rd.get('citation_format') == 'ieee', rd
assert rd.get('target_words') == 4000, rd  # #384: default retuned 5000 -> 4000
print('OK')
" | grep -q OK; then
  green "PASS: init without flags falls back to full default research_defaults block (back-compat)"
else
  red "FAIL: default research_defaults block missing or wrong"
  errors=$((errors + 1))
fi

# --- 2. knowledge-setup SKILL.md contract -------------------------------
SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"
if [ ! -f "$SETUP" ]; then
  red "FAIL: skills/knowledge-setup/SKILL.md not found"
  exit 1
fi
assert_grep '2.5' "$SETUP" "knowledge-setup: has a Step 2.5 language-defaults block"
assert_grep 'research_defaults' "$SETUP" "knowledge-setup: persists research_defaults"
assert_grep 'default_output_language' "$SETUP" "knowledge-setup: derives language default from the market"
assert_grep 'get-market-config.py' "$SETUP" "knowledge-setup: uses the canonical market-config helper"
assert_grep 'output-language' "$SETUP" "knowledge-setup: passes output-language into binding init"
# #309 P2: the four writer-quality knobs are flag-or-default (not prompted) and
# threaded into binding init.
assert_grep 'prose-density' "$SETUP" "knowledge-setup: accepts --prose-density (flag-or-default; #309 P2)"
assert_grep 'citation-format' "$SETUP" "knowledge-setup: accepts --citation-format (flag-or-default; #309 P2)"
assert_grep 'flag-or-default' "$SETUP" "knowledge-setup: documents the writer-quality knobs as flag-or-default, not prompted (#309 P2)"

# --- 3. knowledge-plan SKILL.md contract --------------------------------
PLAN="$PLUGIN_ROOT/skills/knowledge-plan/SKILL.md"
if [ ! -f "$PLAN" ]; then
  red "FAIL: skills/knowledge-plan/SKILL.md not found"
  exit 1
fi
assert_grep '0.5' "$PLAN" "knowledge-plan: has a Step 0.5 market+language resolution block"
assert_grep 'research_defaults' "$PLAN" "knowledge-plan: reads binding research_defaults as a fallback"
assert_grep 'default_output_language' "$PLAN" "knowledge-plan: falls back to the market's registry language"
assert_grep 'precedence' "$PLAN" "knowledge-plan: documents the resolution precedence"
# The silent unconditional 'default en' must be gone from the param row.
assert_not_grep 'Two-letter code, default .en' "$PLAN" "knowledge-plan: no silent unconditional 'default en'"
# #309 P2: Step 0.5 also resolves the four writer-quality knobs with the framing
# suggestion as a new lowest-precedence tier.
assert_grep 'prose_density' "$PLAN" "knowledge-plan: Step 0.5 resolves prose_density (#309 P2)"
assert_grep 'framing suggestion' "$PLAN" "knowledge-plan: framing suggestion is a precedence tier in Step 0.5 (#309 P2)"
assert_grep 'normalize_tone\|normalize_prose_density\|normalize_citation_format' "$PLAN" "knowledge-plan: references the _knowledge_lib normalizers (#309 P2)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
