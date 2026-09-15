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
if run "$TMP/source.md" "$TMP/source.md" --mode standard --entities 'Acme GmbH' --claims 'Claim Alpha'; then pass cwr-01-preservation-green; else fail cwr-01-preservation-green; fi
for spec in 'citation|[P1-1](https://example.com/evidence)' 'url|https://example.com/evidence' 'number|€12.5' 'entity|Acme GmbH' 'claim|Claim Alpha' 'assumption|{{asm:grid-ready}}' 'figure|Figure 2' 'embed|![[assets/grid.svg]]' 'table|| Dimension | Act | Plan | Observe |' 'diagram|<diagram-placeholder id="grid">keep</diagram-placeholder>'; do
  name=${spec%%|*}; needle=${spec#*|}
  python3 - "$TMP/source.md" "$TMP/mutant.md" "$needle" <<'PY'
import pathlib, sys
source=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
pathlib.Path(sys.argv[2]).write_text(source.replace(sys.argv[3], "", 1), encoding="utf-8")
PY
  if run "$TMP/source.md" "$TMP/mutant.md" --mode standard --entities 'Acme GmbH' --claims 'Claim Alpha'; then fail "cwr-02-$name-red"; else pass "cwr-02-$name-red"; fi
done
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --entities 'Acme GmbH' --claims 'Claim Alpha'; then pass cwr-03-compress-reduces; else fail cwr-03-compress-reduces; fi
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --arc; then fail cwr-04-compress-arc-rejected; else pass cwr-04-compress-arc-rejected; fi
if run "$TMP/source.md" "$TMP/compressed.md" --mode compress --target-lang de; then fail cwr-05-compress-translate-rejected; else pass cwr-05-compress-translate-rejected; fi
for lang in de en fr it pl nl es; do
  if run "$TMP/source.md" "$TMP/source.md" --mode translate --target-lang "$lang" --entities 'Acme GmbH' --claims 'Claim Alpha'; then pass "cwr-06-language-$lang"; else fail "cwr-06-language-$lang"; fi
done
[ "$failures" -eq 0 ] || exit 1
