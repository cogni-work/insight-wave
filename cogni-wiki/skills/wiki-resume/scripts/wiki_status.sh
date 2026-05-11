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
#
# v0.0.35: also folds `<wiki-root>/.cogni-wiki/queue/{pending,running,done,
# failed}/` counts into a `queue` sub-object (T3.1 from issue #212). The
# block degrades gracefully when the queue dir is absent (`available: false`)
# so wikis that never run wiki-ingest --enqueue see a no-op.
#
# v0.0.39: extends the `queue` sub-object with three drainer-hint fields
# (T3.2 from issue #232) — `oldest_pending_age_hours`, `last_next_at`,
# `last_next_age_hours` — plus the `drainer_hint_threshold_hours` config
# value (default 24, read from .cogni-wiki/config.json). Rule 5a in
# wiki-resume's decision tree consumes these to fire the "set up a
# scheduled drainer" nudge only when the queue is genuinely stalled
# (pending older than threshold, no recent --next within threshold) rather
# than the v0.0.35 unconditional pending>0 trigger.

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
# One pass over the wiki tree into a temp file, then per-raw fixed-string
# checks against that. Replaces the previous O(raw_files × wiki_pages × bytes)
# recursive grep that re-walked $WIKI_DIR for every raw file.
orphan_raw_count=0
if [ -d "$RAW_DIR" ] && [ -d "$WIKI_DIR" ]; then
  WIKI_BLOB=$(mktemp)
  find "$WIKI_DIR" -type f -name '*.md' -exec cat {} + > "$WIKI_BLOB" 2>/dev/null
  while IFS= read -r rawfile; do
    [ -z "$rawfile" ] && continue
    base=$(basename "$rawfile")
    if ! grep -qF -- "$base" "$WIKI_BLOB" 2>/dev/null; then
      orphan_raw_count=$((orphan_raw_count + 1))
    fi
  done <<EOF
$(find "$RAW_DIR" -maxdepth 1 -type f 2>/dev/null)
EOF
  rm -f "$WIKI_BLOB"
fi

# ---------- queue snapshot (v0.0.35, T3.1) ----------
# Counts under <wiki-root>/.cogni-wiki/queue/{pending,running,done,failed}/.
# Degrades to "available: false" when the queue dir is absent — every wiki
# that has never run `wiki-ingest --enqueue` falls into that branch and gets
# a no-op block. We do NOT shell out to wiki_queue.py --status here; the
# counts are file-listing only, no JSON parsing, and we want this script to
# stay fast even on wikis that have queued thousands of jobs over time.
QUEUE_DIR="$WIKI_ROOT/.cogni-wiki/queue"
queue_available=false
queue_pending=0
queue_running=0
queue_done=0
queue_failed=0
queue_running_started_at=""
queue_oldest_pending_id=""
# v0.0.39 (T3.2): three drainer-hint fields. All emit as "" when undefined
# and the python assembler converts "" → null.
queue_oldest_pending_age_hours=""
queue_last_next_at=""
queue_last_next_age_hours=""
if [ -d "$QUEUE_DIR" ]; then
  queue_available=true
  for state in pending running done failed; do
    d="$QUEUE_DIR/$state"
    if [ -d "$d" ]; then
      n=$(find "$d" -maxdepth 1 -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
      case "$state" in
        pending) queue_pending="${n:-0}" ;;
        running) queue_running="${n:-0}" ;;
        done)    queue_done="${n:-0}" ;;
        failed)  queue_failed="${n:-0}" ;;
      esac
    fi
  done
  # Oldest pending id (lex-sort = chronological because the id prefix is the
  # Unix-second enqueue timestamp).
  oldest_pending_file=$(ls -1 "$QUEUE_DIR/pending"/*.json 2>/dev/null | sort | head -n 1)
  if [ -n "$oldest_pending_file" ]; then
    queue_oldest_pending_id=$(basename "$oldest_pending_file" .json)
    # v0.0.39 (T3.2): derive oldest_pending_age_hours from the id prefix. The
    # id format is `{unix_timestamp:010d}-{sha1[:8]}` (see wiki_queue.py); the
    # leading 10-digit decimal is unix seconds. Convert to hours via float
    # arithmetic in python (bash 3.2 has no float division).
    queue_oldest_pending_age_hours=$(python3 -c "
import time, sys
try:
    id_prefix = sys.argv[1].split('-', 1)[0]
    ts = int(id_prefix)
    age_s = max(0, time.time() - ts)
    print(f'{age_s / 3600.0:.4f}')
except Exception:
    pass
" "$queue_oldest_pending_id" 2>/dev/null)
  fi
  # started_at of the oldest job currently in running/ (gives operators a
  # "is it stuck?" hint without the v0.0.35 lock surface adding lease/PID).
  oldest_running_file=$(ls -1 "$QUEUE_DIR/running"/*.json 2>/dev/null | sort | head -n 1)
  if [ -n "$oldest_running_file" ]; then
    queue_running_started_at=$(python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    v = d.get('started_at') or ''
    print(v)
except Exception:
    pass
" "$oldest_running_file" 2>/dev/null)
  fi
  # v0.0.39 (T3.2): last_next_at — the ISO timestamp of the newest finished
  # job across done/ ∪ failed/. Heuristic: the newest finished_at on any job
  # in either bucket is the last time --next reached a terminal state. We
  # parse `finished_at` from the job JSON (canonical) and fall back to the
  # file mtime when the field is missing (older job files predating T3.2's
  # finished_at stamping). Bounded scan: 200 newest files per bucket — plenty
  # for the "is the drainer recent?" question, cheap on wikis with thousands
  # of historical jobs.
  if [ -d "$QUEUE_DIR/done" ] || [ -d "$QUEUE_DIR/failed" ]; then
    queue_last_next_at=$(python3 -c "
import os, json, sys
from datetime import datetime, timezone

best_ts = None  # epoch seconds
best_iso = ''
for bucket in ('done', 'failed'):
    d = os.path.join(sys.argv[1], bucket)
    if not os.path.isdir(d):
        continue
    try:
        names = sorted(
            (n for n in os.listdir(d) if n.endswith('.json')),
            reverse=True,
        )[:200]
    except OSError:
        continue
    for name in names:
        path = os.path.join(d, name)
        try:
            with open(path, 'r', encoding='utf-8') as fh:
                job = json.load(fh)
        except (OSError, json.JSONDecodeError):
            job = {}
        iso = (job.get('finished_at') or '').strip()
        if iso:
            try:
                # Tolerate both '...Z' and '+00:00' shapes.
                ts = datetime.fromisoformat(iso.replace('Z', '+00:00')).timestamp()
            except ValueError:
                ts = None
        else:
            ts = None
        if ts is None:
            try:
                ts = os.path.getmtime(path)
                # Convert mtime to ISO for display.
                iso = datetime.fromtimestamp(ts, tz=timezone.utc).isoformat().replace('+00:00', 'Z')
            except OSError:
                continue
        if best_ts is None or ts > best_ts:
            best_ts = ts
            best_iso = iso
print(best_iso)
" "$QUEUE_DIR" 2>/dev/null)
    if [ -n "$queue_last_next_at" ]; then
      queue_last_next_age_hours=$(python3 -c "
import sys
from datetime import datetime, timezone
iso = sys.argv[1].replace('Z', '+00:00')
try:
    ts = datetime.fromisoformat(iso).timestamp()
    age_s = max(0, datetime.now(tz=timezone.utc).timestamp() - ts)
    print(f'{age_s / 3600.0:.4f}')
except Exception:
    pass
" "$queue_last_next_at" 2>/dev/null)
    fi
  fi
fi

# v0.0.39 (T3.2): drainer_hint_threshold_hours — config-driven, default 24.
# Read once from .cogni-wiki/config.json; integer or float both acceptable.
queue_drainer_hint_threshold_hours=$(python3 -c "
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
    v = cfg.get('drainer_hint_threshold_hours', 24)
    print(float(v))
except Exception:
    print(24.0)
" "$CONFIG_FILE" 2>/dev/null)
[ -z "$queue_drainer_hint_threshold_hours" ] && queue_drainer_hint_threshold_hours="24.0"

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
export WS_QUEUE_AVAILABLE="$queue_available"
export WS_QUEUE_PENDING="$queue_pending"
export WS_QUEUE_RUNNING="$queue_running"
export WS_QUEUE_DONE="$queue_done"
export WS_QUEUE_FAILED="$queue_failed"
export WS_QUEUE_OLDEST_PENDING_ID="$queue_oldest_pending_id"
export WS_QUEUE_RUNNING_STARTED_AT="$queue_running_started_at"
# v0.0.39 (T3.2)
export WS_QUEUE_OLDEST_PENDING_AGE_HOURS="$queue_oldest_pending_age_hours"
export WS_QUEUE_LAST_NEXT_AT="$queue_last_next_at"
export WS_QUEUE_LAST_NEXT_AGE_HOURS="$queue_last_next_age_hours"
export WS_QUEUE_DRAINER_HINT_THRESHOLD_HOURS="$queue_drainer_hint_threshold_hours"

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
    "queue": {
        "available": os.environ.get("WS_QUEUE_AVAILABLE", "false") == "true",
        "pending": int(os.environ.get("WS_QUEUE_PENDING", "0") or 0),
        "running": int(os.environ.get("WS_QUEUE_RUNNING", "0") or 0),
        "done": int(os.environ.get("WS_QUEUE_DONE", "0") or 0),
        "failed": int(os.environ.get("WS_QUEUE_FAILED", "0") or 0),
        "oldest_pending_id": os.environ.get("WS_QUEUE_OLDEST_PENDING_ID", "") or None,
        "running_started_at": os.environ.get("WS_QUEUE_RUNNING_STARTED_AT", "") or None,
        # v0.0.39 (T3.2): drainer-hint fields. Floats or null.
        "oldest_pending_age_hours": (
            float(os.environ["WS_QUEUE_OLDEST_PENDING_AGE_HOURS"])
            if os.environ.get("WS_QUEUE_OLDEST_PENDING_AGE_HOURS", "").strip()
            else None
        ),
        "last_next_at": os.environ.get("WS_QUEUE_LAST_NEXT_AT", "") or None,
        "last_next_age_hours": (
            float(os.environ["WS_QUEUE_LAST_NEXT_AGE_HOURS"])
            if os.environ.get("WS_QUEUE_LAST_NEXT_AGE_HOURS", "").strip()
            else None
        ),
        "drainer_hint_threshold_hours": float(
            os.environ.get("WS_QUEUE_DRAINER_HINT_THRESHOLD_HOURS", "24") or 24
        ),
    },
}

print(json.dumps({"success": True, "data": data, "error": ""}))
PY
