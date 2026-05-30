#!/usr/bin/env bash
# test_binding_project_path.sh - regression test for A2 + v0.0.3 schema bump.
#
# Asserts:
#   - knowledge-binding.py init writes schema_version 0.0.3 with
#     curator_defaults and bootstraps the fetch-cache directory.
#     (fetch_cache_dir and last_fetch_refresh are deliberately omitted —
#     derivable / no consumer; explicit negative assertions below.)
#   - append-project --project-path writes the project_path field on the
#     entry (absolute, resolved).
#   - append-project without --project-path writes project_path: "" (legacy
#     compat - cycle-guard falls back to .parent.parent derivation).
#   - cmd_read on a hand-crafted legacy 0.0.1 binding (no project_path
#     field, schema_version 0.0.1) does not error.
#   - cmd_read on a hand-crafted legacy 0.0.2 binding (project_path
#     present, no new v0.1.0 fields) does not error.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/knowledge-binding.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: knowledge-binding.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

# Set up a minimal wiki + knowledge root + research project.
KB="$WORK/kb"
WIKI="$KB"
mkdir -p "$WIKI/.cogni-wiki"
cat > "$WIKI/.cogni-wiki/config.json" <<'JSON'
{"name": "Test", "slug": "test", "schema_version": "0.0.5"}
JSON

PROJ="$WORK/test-2026-05-20"
mkdir -p "$PROJ/.metadata" "$PROJ/output"
echo '{"slug": "test", "report_source": "web"}' > "$PROJ/.metadata/project-config.json"
touch "$PROJ/output/report.md"

# 1. init - schema_version should be 0.1.1 (the additive research_defaults
# bump, #309 P1.2-rest v0.1.35; on top of the M12 0.1.0 re-alignment).
python3 "$SCRIPT" init \
  --knowledge-root "$KB" \
  --knowledge-slug test-kb \
  --knowledge-title "Test KB" \
  --wiki-path "$WIKI" >/dev/null

SCHEMA=$(python3 -c "import json; print(json.load(open('$KB/.cogni-knowledge/binding.json'))['schema_version'])")
if [ "$SCHEMA" = "0.1.1" ]; then
  green "PASS: init writes schema_version 0.1.1"
else
  red "FAIL: schema_version expected 0.1.1, got '$SCHEMA'"
  errors=$((errors + 1))
fi

if [ -d "$KB/.cogni-knowledge/fetch-cache" ]; then
  green "PASS: init bootstraps fetch-cache/ directory"
else
  red "FAIL: fetch-cache/ not bootstrapped at $KB/.cogni-knowledge/fetch-cache"
  errors=$((errors + 1))
fi

if python3 -c "
import json
b = json.load(open('$KB/.cogni-knowledge/binding.json'))
cd = b.get('curator_defaults', {})
assert cd.get('max_candidates_per_sq') == 12, cd
assert cd.get('score_threshold') == 0.5, cd
assert cd.get('fetch_cache_max_age_days') == 30, cd
# fetch_cache_dir and last_fetch_refresh deliberately omitted from binding —
# the cache path is derivable from knowledge_root (see fetch-cache-design.md).
assert 'fetch_cache_dir' not in b, 'fetch_cache_dir should be derived, not stored'
assert 'last_fetch_refresh' not in b, 'last_fetch_refresh has no producer yet — add when knowledge-fetch lands'
print('OK')
" | grep -q OK; then
  green "PASS: init writes curator_defaults; omits derivable/unused fields"
else
  red "FAIL: curator_defaults missing or wrong on init output"
  errors=$((errors + 1))
fi

# 2. append-project --project-path -> entry has project_path field with abs path.
python3 "$SCRIPT" append-project \
  --knowledge-root "$KB" \
  --knowledge-slug test-kb \
  --research-slug test-2026 \
  --report-path "$PROJ/output/report.md" \
  --project-path "$PROJ" \
  --report-source web >/dev/null

ENTRY_PROJECT_PATH=$(python3 -c "
import json
b = json.load(open('$KB/.cogni-knowledge/binding.json'))
print(b['research_projects'][0].get('project_path', ''))
")
PROJ_RESOLVED=$(python3 -c "from pathlib import Path; print(Path('$PROJ').resolve())")
if [ "$ENTRY_PROJECT_PATH" = "$PROJ_RESOLVED" ]; then
  green "PASS: append-project --project-path writes resolved abs path"
else
  red "FAIL: expected '$PROJ_RESOLVED', got '$ENTRY_PROJECT_PATH'"
  errors=$((errors + 1))
fi

# 3. append-project WITHOUT --project-path -> entry has project_path: "".
PROJ2="$WORK/test2-2026-05-20"
mkdir -p "$PROJ2/.metadata" "$PROJ2/output"
echo '{"slug": "test2"}' > "$PROJ2/.metadata/project-config.json"
touch "$PROJ2/output/report.md"
python3 "$SCRIPT" append-project \
  --knowledge-root "$KB" \
  --knowledge-slug test-kb \
  --research-slug test2-2026 \
  --report-path "$PROJ2/output/report.md" \
  --report-source web >/dev/null

ENTRY2=$(python3 -c "
import json
b = json.load(open('$KB/.cogni-knowledge/binding.json'))
entry = [e for e in b['research_projects'] if e['slug'] == 'test2-2026'][0]
print('|'.join([entry.get('project_path', 'MISSING'), entry['report_path']]))
")
EMPTY_PP="${ENTRY2%%|*}"
if [ "$EMPTY_PP" = "" ]; then
  green "PASS: append-project without --project-path writes empty string (legacy compat)"
else
  red "FAIL: expected empty project_path, got '$EMPTY_PP'"
  errors=$((errors + 1))
fi

# 4. Read on a hand-crafted legacy 0.0.1 binding (no project_path) - must not error.
LEGACY_KB="$WORK/legacy-kb"
WIKI2="$LEGACY_KB"
mkdir -p "$WIKI2/.cogni-wiki"
echo '{"name": "Test", "slug": "test", "schema_version": "0.0.5"}' > "$WIKI2/.cogni-wiki/config.json"
mkdir -p "$LEGACY_KB/.cogni-knowledge"
cat > "$LEGACY_KB/.cogni-knowledge/binding.json" <<'JSON'
{
  "knowledge_slug": "legacy-kb",
  "knowledge_title": "Legacy KB",
  "wiki_path": "WIKI_PLACEHOLDER",
  "research_projects": [
    {
      "slug": "old-project",
      "deposited_at": "2026-04-01",
      "report_path": "/tmp/cogni-research-old-project/output/report.md",
      "report_source": "web"
    }
  ],
  "topic_lineage": {"covered_themes": [], "open_themes": []},
  "created": "2026-04-01",
  "schema_version": "0.0.1"
}
JSON
# Patch in the wiki path so the binding is internally consistent.
sed -i.bak "s|WIKI_PLACEHOLDER|$WIKI2|" "$LEGACY_KB/.cogni-knowledge/binding.json"
rm -f "$LEGACY_KB/.cogni-knowledge/binding.json.bak"

READ_OUT=$(python3 "$SCRIPT" read --knowledge-root "$LEGACY_KB")
if echo "$READ_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
b = d['data']['binding']
assert b['schema_version'] == '0.0.1', b['schema_version']
assert 'project_path' not in b['research_projects'][0], b['research_projects'][0]
print('OK')
" | grep -q OK; then
  green "PASS: legacy 0.0.1 binding reads back without error and without project_path"
else
  red "FAIL: legacy 0.0.1 binding read failed"
  red "  got: $READ_OUT"
  errors=$((errors + 1))
fi

# 5. Read on a hand-crafted legacy 0.0.2 binding (project_path present, no v0.1.0 fields).
LEGACY02_KB="$WORK/legacy02-kb"
WIKI3="$LEGACY02_KB"
mkdir -p "$WIKI3/.cogni-wiki"
echo '{"name": "Test", "slug": "test", "schema_version": "0.0.5"}' > "$WIKI3/.cogni-wiki/config.json"
mkdir -p "$LEGACY02_KB/.cogni-knowledge"
cat > "$LEGACY02_KB/.cogni-knowledge/binding.json" <<'JSON'
{
  "knowledge_slug": "legacy02-kb",
  "knowledge_title": "Legacy 0.0.2 KB",
  "wiki_path": "WIKI3_PLACEHOLDER",
  "research_projects": [
    {
      "slug": "old-project-2",
      "deposited_at": "2026-04-15",
      "report_path": "/tmp/old-project-2/output/report.md",
      "report_source": "wiki",
      "project_path": "/tmp/old-project-2"
    }
  ],
  "topic_lineage": {"covered_themes": [], "open_themes": []},
  "created": "2026-04-15",
  "schema_version": "0.0.2"
}
JSON
sed -i.bak "s|WIKI3_PLACEHOLDER|$WIKI3|" "$LEGACY02_KB/.cogni-knowledge/binding.json"
rm -f "$LEGACY02_KB/.cogni-knowledge/binding.json.bak"

READ_OUT2=$(python3 "$SCRIPT" read --knowledge-root "$LEGACY02_KB")
if echo "$READ_OUT2" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
b = d['data']['binding']
assert b['schema_version'] == '0.0.2', b['schema_version']
assert b['research_projects'][0]['project_path'] == '/tmp/old-project-2', b['research_projects'][0]
assert 'fetch_cache_dir' not in b, list(b.keys())
print('OK')
" | grep -q OK; then
  green "PASS: legacy 0.0.2 binding reads back without error and preserves project_path"
else
  red "FAIL: legacy 0.0.2 binding read failed"
  red "  got: $READ_OUT2"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All binding cases pass (A2 + v0.0.3 schema bump)."
