#!/usr/bin/env bash
# test_queue.sh — assertions for the persistent ingest queue (T3.1, v0.0.35+).
#
# Covers:
#   1.  Pre-migration probe (legacy wiki/pages/ → hard-fail).
#   2.  Empty queue: --status zeros, --next noop=queue_empty.
#   3.  --enqueue writes a complete pending job.
#   4.  Two consecutive enqueues produce distinct ids.
#   5.  Same-second enqueue uniqueness (sha1+nanos suffix).
#   6.  --next moves pending→running, stamps started_at.
#   7.  Second --next while running busy → noop=running_busy.
#   8.  --complete --success moves running→done; next pick advances.
#   9.  --complete --failure stores last_error + appends queue|failed log line.
#   10. --retry moves failed→pending, increments attempts.
#   11. Priority ordering: higher priority picked first.
#   12. Future scheduled_at → noop=all_scheduled_future.
#   13. Concurrent --next from two subshells: exactly one wins.
#   14. Error paths: --retry on non-failed, --complete on non-running.

set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUEUE_PY="$PLUGIN_ROOT/skills/wiki-ingest/scripts/wiki_queue.py"

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

# Bootstrap a v0.0.5 wiki by hand (we don't depend on wiki-setup here).
mkdir -p "$WIKI_ROOT/.cogni-wiki" "$WIKI_ROOT/raw" "$WIKI_ROOT/wiki"
for d in concepts entities summaries decisions interviews meetings learnings syntheses notes audits; do
  mkdir -p "$WIKI_ROOT/wiki/$d"
done
cat > "$WIKI_ROOT/.cogni-wiki/config.json" <<JSON
{
  "name": "test-queue",
  "slug": "test-queue",
  "description": "test fixture",
  "created": "2026-05-09",
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

# ------------------------------------------------------------------
section "1. Pre-migration probe"
# Plant a legacy wiki/pages/ flat layout — every queue mode must hard-fail.
mkdir -p "$WIKI_ROOT/wiki/pages"
echo "# legacy" > "$WIKI_ROOT/wiki/pages/legacy-stub.md"
out=$(q --status 2>&1 || true)
echo "$out" | grep -q '"success": false' && echo "$out" | grep -q "pre-migration" \
  && ok "pre-migration probe rejects --status" \
  || fail "pre-migration probe should reject --status; got: $out"
rm -rf "$WIKI_ROOT/wiki/pages"

# ------------------------------------------------------------------
section "2. Empty queue"
out=$(q --status)
[ "$(printf '%s' "$out" | jget data.pending)" = "0" ] \
  && [ "$(printf '%s' "$out" | jget data.running)" = "0" ] \
  && [ "$(printf '%s' "$out" | jget data.failed)" = "0" ] \
  && ok "--status reports zeros on empty queue" \
  || fail "--status zeros: $out"

out=$(q --next)
[ "$(printf '%s' "$out" | jget data.action)" = "noop" ] \
  && [ "$(printf '%s' "$out" | jget data.reason)" = "queue_empty" ] \
  && ok "--next on empty queue is noop=queue_empty" \
  || fail "--next on empty queue: $out"

# ------------------------------------------------------------------
section "3. --enqueue writes a complete job"
echo "# src1" > "$WIKI_ROOT/raw/src1.md"
out=$(q --enqueue --source raw/src1.md --type summary --tags "alpha,beta")
job_id_1=$(printf '%s' "$out" | jget data.job.id)
[ -n "$job_id_1" ] && [ -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$job_id_1.json" ] \
  && ok "--enqueue creates pending/$job_id_1.json" \
  || fail "--enqueue did not create pending file; got: $out"

job=$(cat "$WIKI_ROOT/.cogni-wiki/queue/pending/$job_id_1.json")
v=$(printf '%s' "$job" | jget version)
src=$(printf '%s' "$job" | jget source)
ptype=$(printf '%s' "$job" | jget type)
priority=$(printf '%s' "$job" | jget priority)
[ "$v" = "1" ] && [ "$src" = "raw/src1.md" ] && [ "$ptype" = "summary" ] && [ "$priority" = "50" ] \
  && ok "job has version=1, correct source/type, default priority=50" \
  || fail "job fields wrong: version=$v source=$src type=$ptype priority=$priority"

# ------------------------------------------------------------------
section "4. Two enqueues produce distinct ids"
echo "# src2" > "$WIKI_ROOT/raw/src2.md"
out=$(q --enqueue --source raw/src2.md --type note)
job_id_2=$(printf '%s' "$out" | jget data.job.id)
[ "$job_id_1" != "$job_id_2" ] \
  && ok "two ids are distinct: $job_id_1 vs $job_id_2" \
  || fail "ids collided: $job_id_1 == $job_id_2"

# ------------------------------------------------------------------
section "5. Same-second enqueue uniqueness"
echo "# src3" > "$WIKI_ROOT/raw/src3.md"
echo "# src4" > "$WIKI_ROOT/raw/src4.md"
out_a=$(q --enqueue --source raw/src3.md)
out_b=$(q --enqueue --source raw/src4.md)
id_a=$(printf '%s' "$out_a" | jget data.job.id)
id_b=$(printf '%s' "$out_b" | jget data.job.id)
[ "$id_a" != "$id_b" ] \
  && ok "same-second enqueue ids differ ($id_a vs $id_b)" \
  || fail "same-second ids collided: $id_a == $id_b"

# Drop src3 and src4 from pending so subsequent assertions reason about a
# smaller queue. Direct file removal — only allowed in tests.
rm -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$id_a.json"
rm -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$id_b.json"

# ------------------------------------------------------------------
section "6. --next moves pending → running, stamps started_at"
out=$(q --next)
action=$(printf '%s' "$out" | jget data.action)
picked_id=$(printf '%s' "$out" | jget data.job.id)
started_at=$(printf '%s' "$out" | jget data.job.started_at)
[ "$action" = "pick" ] && [ -n "$picked_id" ] && [ -n "$started_at" ] \
  && [ -f "$WIKI_ROOT/.cogni-wiki/queue/running/$picked_id.json" ] \
  && [ ! -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$picked_id.json" ] \
  && ok "--next picked $picked_id, moved to running/, stamped started_at=$started_at" \
  || fail "--next pick failed: action=$action id=$picked_id started_at=$started_at file=$([ -f "$WIKI_ROOT/.cogni-wiki/queue/running/$picked_id.json" ] && echo yes || echo no)"

# ------------------------------------------------------------------
section "7. Second --next while running busy → noop=running_busy"
out=$(q --next)
[ "$(printf '%s' "$out" | jget data.action)" = "noop" ] \
  && [ "$(printf '%s' "$out" | jget data.reason)" = "running_busy" ] \
  && ok "second --next correctly returns running_busy" \
  || fail "second --next did not return running_busy: $out"

# ------------------------------------------------------------------
section "8. --complete --success moves running → done, next pick advances"
out=$(q --complete --job-id "$picked_id" --success)
outcome=$(printf '%s' "$out" | jget data.outcome)
finished_at=$(printf '%s' "$out" | jget data.job.finished_at)
[ "$outcome" = "done" ] && [ -n "$finished_at" ] \
  && [ -f "$WIKI_ROOT/.cogni-wiki/queue/done/$picked_id.json" ] \
  && [ ! -f "$WIKI_ROOT/.cogni-wiki/queue/running/$picked_id.json" ] \
  && ok "--complete --success moved $picked_id to done/, finished_at=$finished_at" \
  || fail "--complete --success failed: outcome=$outcome finished_at=$finished_at"

out=$(q --next)
next_id=$(printf '%s' "$out" | jget data.job.id)
[ -n "$next_id" ] && [ "$next_id" != "$picked_id" ] \
  && ok "subsequent --next advanced to $next_id" \
  || fail "subsequent --next did not advance: $out"

# ------------------------------------------------------------------
section "9. --complete --failure stores last_error + appends queue|failed log"
out=$(q --complete --job-id "$next_id" --failure --error "step 6 backlink failed")
outcome=$(printf '%s' "$out" | jget data.outcome)
last_err=$(printf '%s' "$out" | jget data.job.last_error)
[ "$outcome" = "failed" ] && [ "$last_err" = "step 6 backlink failed" ] \
  && [ -f "$WIKI_ROOT/.cogni-wiki/queue/failed/$next_id.json" ] \
  && ok "--complete --failure moved $next_id to failed/" \
  || fail "--complete --failure: outcome=$outcome last_error=$last_err"

grep -q "queue | failed $next_id" "$WIKI_ROOT/wiki/log.md" \
  && ok "log.md gained 'queue | failed' line" \
  || fail "log.md missing queue|failed line; tail: $(tail -3 "$WIKI_ROOT/wiki/log.md")"

# ------------------------------------------------------------------
section "10. --retry moves failed → pending, increments attempts"
out=$(q --retry --job-id "$next_id")
attempts=$(printf '%s' "$out" | jget data.job.attempts)
[ "$attempts" = "1" ] \
  && [ -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$next_id.json" ] \
  && [ ! -f "$WIKI_ROOT/.cogni-wiki/queue/failed/$next_id.json" ] \
  && ok "--retry moved $next_id back to pending/, attempts=1" \
  || fail "--retry: attempts=$attempts; file=$([ -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$next_id.json" ] && echo pending || echo missing)"

# Drain the queue so subsequent priority test starts clean.
out=$(q --next); pid=$(printf '%s' "$out" | jget data.job.id)
[ -n "$pid" ] && q --complete --job-id "$pid" --success >/dev/null

# ------------------------------------------------------------------
section "11. Priority: higher priority picked first"
echo "# low" > "$WIKI_ROOT/raw/low.md"
echo "# hi"  > "$WIKI_ROOT/raw/hi.md"
q --enqueue --source raw/low.md --priority 50 >/dev/null
q --enqueue --source raw/hi.md  --priority 80 >/dev/null
out=$(q --next)
picked_src=$(printf '%s' "$out" | jget data.job.source)
picked_id=$(printf '%s' "$out" | jget data.job.id)
[ "$picked_src" = "raw/hi.md" ] \
  && ok "priority 80 picked before priority 50" \
  || fail "priority order broken: picked $picked_src first"
q --complete --job-id "$picked_id" --success >/dev/null
# Drain the leftover priority-50 job.
out=$(q --next); pid=$(printf '%s' "$out" | jget data.job.id)
[ -n "$pid" ] && q --complete --job-id "$pid" --success >/dev/null

# ------------------------------------------------------------------
section "12. scheduled_at in the future → noop=all_scheduled_future"
echo "# fut" > "$WIKI_ROOT/raw/fut.md"
q --enqueue --source raw/fut.md --scheduled-at "2099-01-01T00:00:00Z" >/dev/null
out=$(q --next)
[ "$(printf '%s' "$out" | jget data.action)" = "noop" ] \
  && [ "$(printf '%s' "$out" | jget data.reason)" = "all_scheduled_future" ] \
  && ok "future-scheduled job not picked, reason=all_scheduled_future" \
  || fail "future scheduled_at: $out"
# Clean up that pending job so the next test starts empty.
fut_id=$(ls "$WIKI_ROOT/.cogni-wiki/queue/pending/" | head -1 | sed 's/\.json$//')
rm -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$fut_id.json"

# ------------------------------------------------------------------
section "13. Concurrent --next from two subshells: exactly one wins"
echo "# c1" > "$WIKI_ROOT/raw/c1.md"
q --enqueue --source raw/c1.md >/dev/null

# Use a temp file to capture both outputs, race them.
TMP_A=$(mktemp); TMP_B=$(mktemp)
( q --next > "$TMP_A" 2>&1 ) &
( q --next > "$TMP_B" 2>&1 ) &
wait

a=$(cat "$TMP_A"); b=$(cat "$TMP_B")
rm -f "$TMP_A" "$TMP_B"

# Count "pick" and "noop" outcomes.
picks=0; noops=0
for out in "$a" "$b"; do
  action=$(printf '%s' "$out" | jget data.action)
  [ "$action" = "pick" ] && picks=$((picks+1))
  [ "$action" = "noop" ] && noops=$((noops+1))
done
[ "$picks" = "1" ] && [ "$noops" = "1" ] \
  && ok "concurrent --next: 1 pick + 1 noop (lock contract honoured)" \
  || fail "concurrent --next: picks=$picks noops=$noops; a=$a; b=$b"

# Drain the running job so the failed-state test below starts clean.
running_id=$(ls "$WIKI_ROOT/.cogni-wiki/queue/running/" | head -1 | sed 's/\.json$//')
[ -n "$running_id" ] && q --complete --job-id "$running_id" --success >/dev/null

# ------------------------------------------------------------------
section "14. Error paths: --retry on non-failed; --complete on non-running"
# Enqueue, leave in pending — try to retry.
echo "# err1" > "$WIKI_ROOT/raw/err1.md"
out=$(q --enqueue --source raw/err1.md)
err_id=$(printf '%s' "$out" | jget data.job.id)

out=$(q --retry --job-id "$err_id" 2>&1 || true)
echo "$out" | grep -q '"success": false' && echo "$out" | grep -q "pending" \
  && ok "--retry on pending job emits success:false" \
  || fail "--retry on pending should fail; got: $out"

# --complete --success on a non-running id (the same pending one).
out=$(q --complete --job-id "$err_id" --success 2>&1 || true)
echo "$out" | grep -q '"success": false' \
  && ok "--complete --success on pending id emits success:false" \
  || fail "--complete on non-running should fail; got: $out"

# Verify no filesystem mutation: still in pending/.
[ -f "$WIKI_ROOT/.cogni-wiki/queue/pending/$err_id.json" ] \
  && [ ! -f "$WIKI_ROOT/.cogni-wiki/queue/running/$err_id.json" ] \
  && [ ! -f "$WIKI_ROOT/.cogni-wiki/queue/failed/$err_id.json" ] \
  && ok "error paths did not mutate filesystem" \
  || fail "error paths mutated filesystem"

# ------------------------------------------------------------------
section "Summary"
printf "%d passed, %d failed\n" "$PASS" "$FAILS"
[ "$FAILS" = "0" ] && exit 0 || exit 1
