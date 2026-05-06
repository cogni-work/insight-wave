#!/usr/bin/env bash
# wiki_status.sh — collect status facts for a cogni-wiki and emit JSON.
#
# Usage:
#   wiki_status.sh --wiki-root <path> [--skip-health]
#
# Output contract:
#   {"success": true|false, "data": { ... }, "error": "string"}
#
# Bash 3.2 compatible. stdlib only (grep, find, awk, sed, date, python3 for JSON).
#
# Rationale: a shell script is the right tool here because everything we need
# is file counting, date arithmetic, and grep over log.md. Delegating to python3
# only for JSON assembly keeps the shell portion trivial and portable.
#
# v0.0.27: also dispatches wiki-health/scripts/health.py once and folds the
# resulting errors / warnings / entries_count_drift / claim_drift_count into
# the JSON output under the `health` sub-object. Failures are non-fatal —
# `health.available` flips to false and the rest of the status block still
# works.

set -u

# ---------- arg parse ----------
usage() {
  cat <<'USAGE'
wiki_status.sh — collect status facts for a cogni-wiki and emit JSON.

Usage:
  wiki_status.sh --wiki-root <path> [--skip-health]
  wiki_status.sh -h | --help

Output contract:
  {"success": true|false, "data": { ... }, "error": "string"}
USAGE
}

WIKI_ROOT=""
SKIP_HEALTH=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --wiki-root)
      WIKI_ROOT="${2:-}"
      shift 2
      ;;
    --skip-health)
      SKIP_HEALTH=1
      shift
      ;;
    *)
      printf '{"success": false, "data": {}, "error": "unknown arg: %s"}\n' "$1"
      exit 1
      ;;
  esac
done

fail() {
  msg="$1"
  # Escape double quotes and backslashes for JSON.
  escaped=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"success": false, "data": {}, "error": "%s"}\n' "$escaped"
  exit 1
}

if [ -z "$WIKI_ROOT" ]; then
  fail "missing --wiki-root"
fi

if [ ! -f "$WIKI_ROOT/.cogni-wiki/config.json" ]; then
  fail "not a cogni-wiki: $WIKI_ROOT/.cogni-wiki/config.json not found"
fi

WIKI_DIR="$WIKI_ROOT/wiki"
LEGACY_PAGES_DIR="$WIKI_DIR/pages"
AUDITS_DIR="$WIKI_DIR/audits"
LOG_FILE="$WIKI_DIR/log.md"
RAW_DIR="$WIKI_ROOT/raw"
CONFIG_FILE="$WIKI_ROOT/.cogni-wiki/config.json"

# Per-type page directories (v0.0.28+). Order matches _wikilib.PAGE_TYPE_DIRS.
TYPE_DIRS="concepts entities summaries decisions interviews meetings learnings syntheses notes"

# Resolve script dir so we can find ../../wiki-health/scripts/health.py.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HEALTH_SCRIPT="$SCRIPT_DIR/../../wiki-health/scripts/health.py"

# ---------- pre-migration probe ----------
# Surface the migration nudge as a status field. Hard-failing in a SKILL that
# wraps this script would block the very session that is supposed to *fix* the
# problem, so we report instead. Every other consumer hard-fails via _wikilib.
schema_migration_pending=false
if [ -d "$LEGACY_PAGES_DIR" ]; then
  legacy_md_count=$(find "$LEGACY_PAGES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${legacy_md_count:-0}" -gt 0 ]; then
    schema_migration_pending=true
  fi
fi

# ---------- counts ----------
entries_count=0
lint_count=0
for type_dir in $TYPE_DIRS; do
  if [ -d "$WIKI_DIR/$type_dir" ]; then
    n=$(find "$WIKI_DIR/$type_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    entries_count=$((entries_count + ${n:-0}))
  fi
done
if [ -d "$AUDITS_DIR" ]; then
  lint_count=$(find "$AUDITS_DIR" -maxdepth 1 -type f -name 'lint-*.md' 2>/dev/null | wc -l | tr -d ' ')
fi

raw_file_count=0
if [ -d "$RAW_DIR" ]; then
  raw_file_count=$(find "$RAW_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
fi

# ---------- last lint date ----------
last_lint=""
days_since_lint=""
if [ -d "$AUDITS_DIR" ]; then
  # Latest lint filename by sort (YYYY-MM-DD sorts lexicographically).
  last_lint_file=$(ls -1 "$AUDITS_DIR"/lint-*.md 2>/dev/null | sort | tail -n 1)
  if [ -n "$last_lint_file" ]; then
    last_lint=$(basename "$last_lint_file" .md | sed 's/^lint-//')
    # Date arithmetic: macOS vs GNU. Try GNU first, fall back to BSD.
    if date -d "$last_lint" +%s >/dev/null 2>&1; then
      last_epoch=$(date -d "$last_lint" +%s)
    else
      last_epoch=$(date -j -f "%Y-%m-%d" "$last_lint" +%s 2>/dev/null || echo "")
    fi
    if [ -n "$last_epoch" ]; then
      now_epoch=$(date +%s)
      days_since_lint=$(( (now_epoch - last_epoch) / 86400 ))
    fi
  fi
fi

# ---------- 30-day log activity ----------
ingest_count_30d=0
query_count_30d=0
update_count_30d=0
synthesis_count_30d=0
health_count_30d=0
if [ -f "$LOG_FILE" ]; then
  # Compute cutoff date (30 days ago) in YYYY-MM-DD.
  if date -d "30 days ago" +%Y-%m-%d >/dev/null 2>&1; then
    cutoff=$(date -d "30 days ago" +%Y-%m-%d)
  else
    cutoff=$(date -v -30d +%Y-%m-%d 2>/dev/null || echo "")
  fi
  if [ -n "$cutoff" ]; then
    # Use awk to parse "## [YYYY-MM-DD] op | ..." lines where date >= cutoff.
    # We pass cutoff as a variable and compare lexicographically (safe for ISO dates).
    counts=$(awk -v cutoff="$cutoff" '
      /^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]/ {
        date = substr($0, 5, 10)
        if (date >= cutoff) {
          # Extract op token after the closing bracket.
          rest = substr($0, 16)
          sub(/^ */, "", rest)
          op = rest
          sub(/ .*/, "", op)
          if (op == "ingest") ingest++
          else if (op == "query") query++
          else if (op == "update") update++
          else if (op == "synthesis") synthesis++
          else if (op == "health") health++
        }
      }
      END {
        printf "%d %d %d %d %d", (ingest+0), (query+0), (update+0), (synthesis+0), (health+0)
      }
    ' "$LOG_FILE")
    ingest_count_30d=$(printf '%s' "$counts" | awk '{print $1}')
    query_count_30d=$(printf '%s' "$counts" | awk '{print $2}')
    update_count_30d=$(printf '%s' "$counts" | awk '{print $3}')
    synthesis_count_30d=$(printf '%s' "$counts" | awk '{print $4}')
    health_count_30d=$(printf '%s' "$counts" | awk '{print $5}')
  fi
fi

# ---------- recent log ----------
recent_log=""
if [ -f "$LOG_FILE" ]; then
  recent_log=$(grep -E '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]' "$LOG_FILE" 2>/dev/null | tail -n 10 || true)
fi

# ---------- open questions count (v0.0.30) ----------
# Count "- [ ]" checklist items in wiki/open_questions.md; 0 if absent.
open_questions_count=0
OPEN_QUESTIONS_FILE="$WIKI_DIR/open_questions.md"
if [ -f "$OPEN_QUESTIONS_FILE" ]; then
  open_questions_count=$(grep -cE '^- \[ \] ' "$OPEN_QUESTIONS_FILE" 2>/dev/null || echo 0)
fi

# ---------- orphan raw files (quick heuristic) ----------
orphan_raw_count=0
if [ -d "$RAW_DIR" ] && [ -d "$WIKI_DIR" ]; then
  # For every file in raw/, check whether any page's frontmatter or body
  # mentions its basename. Recurses across all per-type page directories.
  while IFS= read -r rawfile; do
    [ -z "$rawfile" ] && continue
    base=$(basename "$rawfile")
    if ! grep -rqF "$base" "$WIKI_DIR" 2>/dev/null; then
      orphan_raw_count=$((orphan_raw_count + 1))
    fi
  done <<EOF
$(find "$RAW_DIR" -maxdepth 1 -type f 2>/dev/null)
EOF
fi

# ---------- health preflight (v0.0.27) ----------
health_json=""
# Skip the health probe when a layout migration is pending — health.py would
# hard-fail with the migration error and we'd have nothing useful to show.
# The schema_migration_pending field tells the user what to do instead.
if [ "$SKIP_HEALTH" -eq 0 ] && [ -f "$HEALTH_SCRIPT" ] && [ "$schema_migration_pending" = "false" ]; then
  # health.py is stdlib-only and fast; capture its stdout. Failures are
  # non-fatal — we just leave health_json empty and the python assembler
  # below will set health.available=false.
  health_json=$(python3 "$HEALTH_SCRIPT" --wiki-root "$WIKI_ROOT" 2>/dev/null || true)
fi

# ---------- assemble JSON via python3 ----------
# Pass values via env to avoid shell-escape hell.
export WS_ENTRIES_COUNT="$entries_count"
export WS_LINT_COUNT="$lint_count"
export WS_RAW_FILE_COUNT="$raw_file_count"
export WS_ORPHAN_RAW_COUNT="$orphan_raw_count"
export WS_LAST_LINT="$last_lint"
export WS_DAYS_SINCE_LINT="$days_since_lint"
export WS_INGEST_30="$ingest_count_30d"
export WS_QUERY_30="$query_count_30d"
export WS_UPDATE_30="$update_count_30d"
export WS_SYNTHESIS_30="$synthesis_count_30d"
export WS_HEALTH_30="$health_count_30d"
export WS_RECENT_LOG="$recent_log"
export WS_CONFIG_FILE="$CONFIG_FILE"
export WS_HEALTH_JSON="$health_json"
export WS_SCHEMA_MIGRATION_PENDING="$schema_migration_pending"
export WS_OPEN_QUESTIONS_COUNT="$open_questions_count"

python3 - <<'PY'
import json
import os

def to_int_or_none(s):
    s = (s or "").strip()
    if not s:
        return None
    try:
        return int(s)
    except ValueError:
        return None

try:
    with open(os.environ["WS_CONFIG_FILE"], "r", encoding="utf-8") as f:
        cfg = json.load(f)
except Exception as e:
    print(json.dumps({"success": False, "data": {}, "error": f"config.json unreadable: {e}"}))
    raise SystemExit(1)

recent_log_raw = os.environ.get("WS_RECENT_LOG", "")
recent_log_lines = [line for line in recent_log_raw.splitlines() if line.strip()]

last_lint = os.environ.get("WS_LAST_LINT", "").strip() or None

# Parse the embedded health.py JSON if present.
health_block = {
    "available": False,
    "errors": None,
    "warnings": None,
    "entries_count_drift": None,
    "claim_drift_count": None,
    "claim_drift_date": None,
}
health_raw = os.environ.get("WS_HEALTH_JSON", "").strip()
if health_raw:
    try:
        parsed = json.loads(health_raw)
        if parsed.get("success"):
            stats = (parsed.get("data") or {}).get("stats") or {}
            health_block = {
                "available": True,
                "errors": int(stats.get("errors", 0) or 0),
                "warnings": int(stats.get("warnings", 0) or 0),
                "entries_count_drift": int(stats.get("entries_count_drift", 0) or 0),
                "claim_drift_count": int(stats.get("claim_drift_count", 0) or 0),
                "claim_drift_date": stats.get("claim_drift_date"),
            }
    except (json.JSONDecodeError, ValueError, TypeError):
        # Leave health_block in its "unavailable" state.
        pass

data = {
    "name": cfg.get("name"),
    "slug": cfg.get("slug"),
    "description": cfg.get("description"),
    "created": cfg.get("created"),
    "entries_count": int(os.environ.get("WS_ENTRIES_COUNT", "0") or 0),
    "lint_count": int(os.environ.get("WS_LINT_COUNT", "0") or 0),
    "raw_file_count": int(os.environ.get("WS_RAW_FILE_COUNT", "0") or 0),
    "orphan_raw_count": int(os.environ.get("WS_ORPHAN_RAW_COUNT", "0") or 0),
    "last_lint": last_lint,
    "days_since_lint": to_int_or_none(os.environ.get("WS_DAYS_SINCE_LINT", "")),
    "ingest_count_30d": int(os.environ.get("WS_INGEST_30", "0") or 0),
    "query_count_30d": int(os.environ.get("WS_QUERY_30", "0") or 0),
    "update_count_30d": int(os.environ.get("WS_UPDATE_30", "0") or 0),
    "synthesis_count_30d": int(os.environ.get("WS_SYNTHESIS_30", "0") or 0),
    "health_count_30d": int(os.environ.get("WS_HEALTH_30", "0") or 0),
    "recent_log": recent_log_lines,
    "schema_version": cfg.get("schema_version"),
    "schema_migration_pending": os.environ.get("WS_SCHEMA_MIGRATION_PENDING", "false") == "true",
    "open_questions_count": int(os.environ.get("WS_OPEN_QUESTIONS_COUNT", "0") or 0),
    "health": health_block,
}

print(json.dumps({"success": True, "data": data, "error": ""}))
PY
