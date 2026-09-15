#!/usr/bin/env bash
# Executable copywriter preservation, multilingual, isolation and compression contract.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$HERE/.." && pwd)"
CHECK="$PLUGIN/skills/copywriter/scripts/check-copywriter-output.py"
FIXTURE="$PLUGIN/tests/fixtures/copywriter/editorial-regressions.json"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
failures=0
pass(){ printf 'PASS: %s\n' "$1"; }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

python3 - "$FIXTURE" "$TMP/source.md" "$TMP/compressed.md" <<'PY'
import json, pathlib, sys
d=json.load(open(sys.argv[1], encoding="utf-8"))
pathlib.Path(sys.argv[2]).write_text(d["source"], encoding="utf-8")
pathlib.Path(sys.argv[3]).write_text(d["compressed"], encoding="utf-8")
PY

run(){ env -i HOME="$TMP/home" PATH="$PATH" PYTHONDONTWRITEBYTECODE=1 python3 "$CHECK" "$@" >/dev/null 2>&1; }
mode_output(){ if [ "$1" = compress ]; then printf '%s\n' "$TMP/compressed.md"; else printf '%s\n' "$TMP/source.md"; fi; }
mode_args(){ if [ "$1" = translate ]; then printf '%s\n' '--source-lang en --target-lang en'; fi; }

for mode in polish translate review compress; do
  output=$(mode_output "$mode")
  # shellcheck disable=SC2046
  if run "$TMP/source.md" "$output" --mode "$mode" $(mode_args "$mode") --entities 'Acme GmbH' --claims 'Claim Alpha'; then
    pass "cwr-01-$mode-green"
  else
    fail "cwr-01-$mode-green"
  fi
  for spec in 'citation|[P1-1](https://example.com/evidence)' 'url|https://example.com/evidence' 'number|€12.5' 'entity|Acme GmbH' 'claim|Claim Alpha' 'assumption|{{asm:grid-ready}}' 'figure|Figure 2' 'embed|![[assets/grid.svg]]' 'table|| Dimension | Act | Plan | Observe |' 'diagram|<diagram-placeholder id="grid">keep</diagram-placeholder>'; do
    name=${spec%%|*}; needle=${spec#*|}
    python3 - "$output" "$TMP/mutant.md" "$needle" <<'PY'
import pathlib, sys
source=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
pathlib.Path(sys.argv[2]).write_text(source.replace(sys.argv[3], "", 1), encoding="utf-8")
PY
    # shellcheck disable=SC2046
    if run "$TMP/source.md" "$TMP/mutant.md" --mode "$mode" $(mode_args "$mode") --entities 'Acme GmbH' --claims 'Claim Alpha'; then
      fail "cwr-02-$mode-$name-red"
    else
      pass "cwr-02-$mode-$name-red"
    fi
  done
done
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --entities 'Acme GmbH' --claims 'Claim Alpha'; then pass cwr-03-compress-reduces; else fail cwr-03-compress-reduces; fi
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --arc; then fail cwr-04-compress-arc-rejected; else pass cwr-04-compress-arc-rejected; fi
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --target-lang de; then fail cwr-05-compress-translate-rejected; else pass cwr-05-compress-translate-rejected; fi

python3 - "$FIXTURE" "$TMP" <<'PY'
import json, pathlib, sys
d=json.load(open(sys.argv[1], encoding="utf-8"))
root=pathlib.Path(sys.argv[2])
for case in d["language_cases"]:
    text=d["source"] + "\n\n## " + case["heading"] + "\n\n" + case["sentence"] + "\n"
    (root / f"language-{case['target']}.md").write_text(text, encoding="utf-8")
PY
while IFS=$'\t' read -r source_lang target_lang heading required; do
  output="$TMP/language-$target_lang.md"
  if run "$TMP/source.md" "$output" --mode translate --source-lang "$source_lang" --target-lang "$target_lang" \
      --expected-headings "$heading" --required-chars "$required" --entities 'Acme GmbH' --claims 'Claim Alpha'; then
    pass "cwr-06-language-$target_lang"
  else
    fail "cwr-06-language-$target_lang"
  fi
  if [ -n "$required" ]; then
    first=${required:0:1}
    python3 - "$output" "$TMP/language-mutant.md" "$first" <<'PY'
import pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
pathlib.Path(sys.argv[2]).write_text(text.replace(sys.argv[3], ""), encoding="utf-8")
PY
    if run "$TMP/source.md" "$TMP/language-mutant.md" --mode translate --source-lang "$source_lang" --target-lang "$target_lang" \
        --expected-headings "$heading" --required-chars "$required" --entities 'Acme GmbH' --claims 'Claim Alpha'; then
      fail "cwr-07-diacritic-$target_lang-red"
    else
      pass "cwr-07-diacritic-$target_lang-red"
    fi
  fi
done < <(python3 - "$FIXTURE" <<'PY'
import json, sys
for c in json.load(open(sys.argv[1], encoding="utf-8"))["language_cases"]:
    print("\t".join((c["source"], c["target"], c["heading"], c["required"])))
PY
)

if run "$TMP/source.md" "$TMP/source.md" --mode translate --source-lang fr --target-lang it; then
  fail cwr-08-direct-nonpivot-red
else
  pass cwr-08-direct-nonpivot-red
fi

for spec in 'citation|[P1-1](https://example.com/evidence)' 'number|€12.5' 'entity|Acme GmbH' 'claim|Claim Alpha'; do
  name=${spec%%|*}; needle=${spec#*|}
  python3 - "$TMP/compressed.md" "$TMP/compress-mutant.md" "$needle" <<'PY'
import pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
pathlib.Path(sys.argv[2]).write_text(text.replace(sys.argv[3], "", 1), encoding="utf-8")
PY
  if run "$TMP/source.md" "$TMP/compress-mutant.md" --mode compress --entities 'Acme GmbH' --claims 'Claim Alpha'; then
    fail "cwr-09-compress-$name-red"
  else
    pass "cwr-09-compress-$name-red"
  fi
done
[ "$failures" -eq 0 ] || exit 1
