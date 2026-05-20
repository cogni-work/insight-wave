#!/usr/bin/env bash
# test_batch_builder_metadata_config.sh - regression test for cogni-wiki F3.
#
# Asserts that batch_builder.py's discover_research() finds project-config
# at .metadata/project-config.json (cogni-research v0.7.x+) and falls back
# to the legacy <project>/project-config.json. Before F3, only the legacy
# path was probed and modern projects aborted.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$PLUGIN_ROOT/skills/wiki-ingest/scripts"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT_DIR/batch_builder.py" ]; then
  red "FAIL: batch_builder.py not found at $SCRIPT_DIR"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

mk_minimal_project() {
  local proj="$1" config_rel="$2"
  mkdir -p "$proj/$(dirname "$config_rel")"
  cat > "$proj/$config_rel" <<EOF
{
  "slug": "test",
  "topic": "test",
  "report_type": "detailed",
  "report_source": "web"
}
EOF
  # discover_research walks 00-sub-questions, 01-contexts, 02-sources,
  # 03-report-claims. Make them empty so the discovery returns success
  # with zero entries.
  mkdir -p "$proj/00-sub-questions/data" "$proj/01-contexts/data" \
           "$proj/02-sources/data" "$proj/03-report-claims/data"
}

# Case 1: cogni-research v0.7.x+ shape - config at .metadata/.
PROJ_MODERN="$WORK/modern-2026-05-20"
mk_minimal_project "$PROJ_MODERN" ".metadata/project-config.json"

OUT_MODERN=$(PYTHONPATH="$SCRIPT_DIR" python3 - 2>&1 <<PY || true
import sys, json
sys.path.insert(0, "$SCRIPT_DIR")
from pathlib import Path
# discover_research is called via the script's CLI; invoke it inline.
from batch_builder import discover_research

# Build a wiki_root - any dir works for this test since we pass the
# project directly via override.
entries, stats = discover_research(
    slug_or_path="modern",
    wiki_root=Path("$WORK"),
    research_root_override="$PROJ_MODERN",
    materialize=False,
)
print(json.dumps({"entries": len(entries), "project": stats.get("project")}))
PY
)
if echo "$OUT_MODERN" | grep -q '"project":'; then
  green "PASS: .metadata/project-config.json (modern) resolves"
else
  red "FAIL: .metadata/project-config.json (modern) did not resolve"
  red "  got: $OUT_MODERN"
  errors=$((errors + 1))
fi

# Case 2: Legacy shape - config at root.
PROJ_LEGACY="$WORK/cogni-research-legacy"
mk_minimal_project "$PROJ_LEGACY" "project-config.json"

OUT_LEGACY=$(PYTHONPATH="$SCRIPT_DIR" python3 - 2>&1 <<PY || true
import sys, json
sys.path.insert(0, "$SCRIPT_DIR")
from pathlib import Path
from batch_builder import discover_research
entries, stats = discover_research(
    slug_or_path="legacy",
    wiki_root=Path("$WORK"),
    research_root_override="$PROJ_LEGACY",
    materialize=False,
)
print(json.dumps({"entries": len(entries), "project": stats.get("project")}))
PY
)
if echo "$OUT_LEGACY" | grep -q '"project":'; then
  green "PASS: <project>/project-config.json (legacy) resolves via fallback"
else
  red "FAIL: <project>/project-config.json (legacy) did not resolve"
  red "  got: $OUT_LEGACY"
  errors=$((errors + 1))
fi

# Case 3: Neither path - must abort with the new failure message.
PROJ_NONE="$WORK/no-config"
mkdir -p "$PROJ_NONE"

OUT_NONE=$(PYTHONPATH="$SCRIPT_DIR" python3 - 2>&1 <<PY || true
import sys, json
sys.path.insert(0, "$SCRIPT_DIR")
from pathlib import Path
from batch_builder import discover_research
try:
    discover_research(
        slug_or_path="none",
        wiki_root=Path("$WORK"),
        research_root_override="$PROJ_NONE",
        materialize=False,
    )
    print("UNEXPECTED_SUCCESS")
except SystemExit:
    # fail() exits; that's the documented contract for missing config.
    print("EXPECTED_FAILURE")
PY
)
if echo "$OUT_NONE" | grep -q "missing project-config.json"; then
  green "PASS: missing config emits the new ambiguity-noting error"
elif echo "$OUT_NONE" | grep -q "EXPECTED_FAILURE"; then
  green "PASS: missing config aborts (exit via fail())"
else
  red "FAIL: missing-config case did not abort as expected"
  red "  got: $OUT_NONE"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All F3 batch_builder config-path cases pass."
