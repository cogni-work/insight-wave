#!/usr/bin/env bash
# test_scheduled_drainer.sh — assertions for the T3.2 scheduled-drainer
# in-process shape (cogni-wiki v0.0.39+, issue #232).
#
# T3.2 ships four reference deployment shapes for periodically calling
# `wiki-ingest --next`: GitHub Actions, Cloud Routine, local cron, and
# /loop. Only /loop is testable in-process (the other three are external
# schedulers and are integration-tested by their own runtimes). This
# script exercises the /loop-equivalent dispatch path — alternating
# `--next` and `--complete --success` against a fixture queue — which is
# exactly what a /loop tick + the orchestrator's ingest pipeline would do
# in production.
#
# Covers:
#   1.  Empty queue: --next noop=queue_empty (must exit 0, must not page).
#   2.  Bootstrap 3 jobs, drain them one at a time with --next + --complete.
#       Assert pending decreases, done increases, every --complete advances.
#   3.  Final --next on drained queue: noop=queue_empty again (idempotent).
#   4.  wiki_status.sh queue-block fields populate correctly after the drain
#       (drainer-hint fields: oldest_pending_age_hours=null, last_next_at
#       non-null and recent, threshold defaults to 24).
#   5.  Threshold override via .cogni-wiki/config.json round-trips through
#       wiki_status.sh as drainer_hint_threshold_hours.

set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUEUE_PY="$PLUGIN_ROOT/skills/wiki-ingest/scripts/wiki_queue.py"
STATUS_SH="$PLUGIN_ROOT/skills/wiki-resume/scripts/wiki_status.sh"

if [ ! -x "$QUEUE_PY" ]; then
  chmod +x "$QUEUE_PY" 2>/dev/null || true
fi

FAILS=0
PASS=0

note()    { printf "\n[note] %s\n"  "$*"; }
ok()      { printf "[ok]   %s\n"    "$*"; PASS=$((PASS+1)); }
fail()    { printf "[FAIL] %s\n"    "$*"; FAILS=$((FAILS+1)); }
section() { printf "\n========== %s ==========\n" "$*"; }

WIKI_ROOT="$(mktemp -d)"
trap 'rm -rf "$WIKI_ROOT"' EXIT

# Bootstrap a v0.0.5 wiki by hand (no dependency on wiki-setup).
mkdir -p "$WIKI_ROOT/.cogni-wiki" "$WIKI_ROOT/raw" "$WIKI_ROOT/wiki"
for d in concepts entities summaries decisions interviews meetings learnings syntheses notes audits; do
  mkdir -p "$WIKI_ROOT/wiki/$d"
done
cat > "$WIKI_ROOT/.cogni-wiki/config.json" <<JSON
{
  "name": "test-scheduled-drainer",
  "slug": "test-scheduled-drainer",
  "description": "T3.2 smoke fixture",
  "created": "2026-05-11",
  "entries_count": 0,
  "last_lint": null,
  "schema_version": "0.0.5"
}
JSON
echo "# log" > "$WIKI_ROOT/wiki/log.md"
echo "# index" > "$WIKI_ROOT/wiki/index.md"

# Helper: run the queue script and print its JSON output.
q() { python3 "$QUEUE_PY" --wiki-root "$WIKI_ROOT" "$@"; }

# Helper: extract a JSON field from $1 (single-line JSON or pretty-printed).
jget() {
  python3 -c "import json,sys; d=json.loads(sys.stdin.read()); keys=sys.argv[1].split('.'); v=d
for k in keys:
 v = v[k] if isinstance(v, dict) else (v[int(k)] if isinstance(v, list) else None)
print(v if v is not None else '')" "$1"
}

# Helper: run wiki_status.sh, return JSON.
status() {
  bash "$STATUS_SH" --wiki-root "$WIKI_ROOT" --skip-health
}

# ------------------------------------------------------------------
section "1. Empty queue: --next is noop=queue_empty (drainer no-op contract)"
out=$(q --next)
action=$(printf '%s' "$out" | jget data.action)
reason=$(printf '%s' "$out" | jget data.reason)
# Verify the dispatcher returns success:true on noop (so a scheduled drainer
# that finds an empty queue does NOT page the operator).
success_field=$(printf '%s' "$out" | jget success)
[ "$action" = "noop" ] && [ "$reason" = "queue_empty" ] && [ "$success_field" = "True" ] \
  && ok "--next on empty queue: success=true, action=noop, reason=queue_empty (drainer-safe)" \
  || fail "--next noop contract broken: success=$success_field action=$action reason=$reason; full output: $out"

# ------------------------------------------------------------------
section "2. Drain 3 jobs via alternating --next + --complete --success"
echo "# src1" > "$WIKI_ROOT/raw/src1.md"
echo "# src2" > "$WIKI_ROOT/raw/src2.md"
echo "# src3" > "$WIKI_ROOT/raw/src3.md"
q --enqueue --source raw/src1.md --type summary >/dev/null
q --enqueue --source raw/src2.md --type summary >/dev/null
q --enqueue --source raw/src3.md --type summary >/dev/null

# Sanity check: 3 pending, 0 running, 0 done_total, 0 failed.
# Note: wiki_queue.py --status uses `done_total`/`done_recent` (the queue script's
# native shape); wiki_status.sh's queue block flattens to `done` (the all-time
# count). This test uses the wiki_queue.py shape because we're calling it
# directly.
out=$(q --status)
[ "$(printf '%s' "$out" | jget data.pending)" = "3" ] \
  && [ "$(printf '%s' "$out" | jget data.running)" = "0" ] \
  && [ "$(printf '%s' "$out" | jget data.done_total)" = "0" ] \
  && ok "after 3 enqueues: pending=3, running=0, done_total=0" \
  || fail "pre-drain state wrong: $out"

# Tick 1: --next, --complete --success. Mimics one /loop tick in production
# where the orchestrator picks a job, runs the ingest pipeline, then marks
# it done.
for tick in 1 2 3; do
  out=$(q --next)
  action=$(printf '%s' "$out" | jget data.action)
  picked_id=$(printf '%s' "$out" | jget data.job.id)
  if [ "$action" = "pick" ] && [ -n "$picked_id" ]; then
    ok "tick $tick: --next picked $picked_id"
  else
    fail "tick $tick: --next did not pick a job (action=$action id=$picked_id)"
    continue
  fi

  out=$(q --complete --job-id "$picked_id" --success)
  outcome=$(printf '%s' "$out" | jget data.outcome)
  if [ "$outcome" = "done" ]; then
    ok "tick $tick: --complete --success advanced to done"
  else
    fail "tick $tick: --complete --success failed: outcome=$outcome; full: $out"
  fi

  # Verify counts after each tick. `done_total` is the cumulative count from
  # wiki_queue.py --status; `done_recent` is the 30-day window.
  out=$(q --status)
  expected_done=$tick
  expected_pending=$((3 - tick))
  actual_done=$(printf '%s' "$out" | jget data.done_total)
  actual_pending=$(printf '%s' "$out" | jget data.pending)
  actual_running=$(printf '%s' "$out" | jget data.running)
  if [ "$actual_done" = "$expected_done" ] && [ "$actual_pending" = "$expected_pending" ] && [ "$actual_running" = "0" ]; then
    ok "tick $tick: counts correct (pending=$actual_pending, running=$actual_running, done_total=$actual_done)"
  else
    fail "tick $tick: counts wrong; expected pending=$expected_pending done_total=$expected_done running=0; got pending=$actual_pending done_total=$actual_done running=$actual_running"
  fi
done

# ------------------------------------------------------------------
section "3. Final --next on drained queue is idempotent noop"
out=$(q --next)
action=$(printf '%s' "$out" | jget data.action)
reason=$(printf '%s' "$out" | jget data.reason)
[ "$action" = "noop" ] && [ "$reason" = "queue_empty" ] \
  && ok "post-drain --next is noop=queue_empty (idempotent — must not page)" \
  || fail "post-drain --next did not noop cleanly: action=$action reason=$reason"

# ------------------------------------------------------------------
section "4. wiki_status.sh drainer-hint fields populate after the drain"
out=$(status)
# After the drain, pending=0 → oldest_pending_age_hours should be null.
oldest_age=$(printf '%s' "$out" | jget data.queue.oldest_pending_age_hours)
[ -z "$oldest_age" ] || [ "$oldest_age" = "None" ] || [ "$oldest_age" = "null" ] \
  && ok "queue.oldest_pending_age_hours is null when pending=0" \
  || fail "expected oldest_pending_age_hours null after drain, got: '$oldest_age'"

# last_next_at should be non-null (we just drained 3 jobs).
last_next_at=$(printf '%s' "$out" | jget data.queue.last_next_at)
[ -n "$last_next_at" ] && [ "$last_next_at" != "None" ] && [ "$last_next_at" != "null" ] \
  && ok "queue.last_next_at populated after drain: $last_next_at" \
  || fail "expected last_next_at populated after drain, got: '$last_next_at'"

# last_next_age_hours should be very small (just finished).
last_age=$(printf '%s' "$out" | jget data.queue.last_next_age_hours)
# Compare as float < 1.0 — we just drained, so age should be seconds, not hours.
age_under_threshold=$(python3 -c "
import sys
try:
    v = float(sys.argv[1])
    print('yes' if v < 1.0 else 'no')
except (ValueError, IndexError):
    print('parse-error')
" "$last_age" 2>/dev/null)
[ "$age_under_threshold" = "yes" ] \
  && ok "queue.last_next_age_hours under 1h immediately after drain (got $last_age)" \
  || fail "expected last_next_age_hours < 1.0 immediately after drain, got: '$last_age'"

# drainer_hint_threshold_hours defaults to 24 when not in config.
threshold=$(printf '%s' "$out" | jget data.queue.drainer_hint_threshold_hours)
[ "$threshold" = "24.0" ] \
  && ok "queue.drainer_hint_threshold_hours defaults to 24.0" \
  || fail "expected default threshold 24.0, got: '$threshold'"

# ------------------------------------------------------------------
section "5. Threshold override round-trips through wiki_status.sh"
# Drop the override into config.json.
python3 -c "
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d['drainer_hint_threshold_hours'] = 1.5
json.dump(d, open(p, 'w'))
" "$WIKI_ROOT/.cogni-wiki/config.json"

out=$(status)
threshold=$(printf '%s' "$out" | jget data.queue.drainer_hint_threshold_hours)
[ "$threshold" = "1.5" ] \
  && ok "queue.drainer_hint_threshold_hours overridden to 1.5 via config" \
  || fail "expected override threshold 1.5, got: '$threshold'"

# ------------------------------------------------------------------
section "Summary"
printf "%d passed, %d failed\n" "$PASS" "$FAILS"
[ "$FAILS" = "0" ] && exit 0 || exit 1
