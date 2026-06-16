#!/usr/bin/env bash
# Guarded, logged dt_stage advance for one cogni-consult deliverable.
#
# Validates a design-thinking stage transition before applying it: the target
# must be a member of the empathize->define->ideate->prototype->test set, and
# the move must be permitted — a single-step forward advance, an idempotent
# same-stage re-set, or a re-entry to any earlier stage (the loop may iterate).
# A forward jump that skips a stage is rejected. On a permitted move it writes
# dt_stage into the deliverable's field.json via an idempotent read-modify-write
# and appends a per-stage move entry to .metadata/stage-log.json (created if
# absent). Degrades gracefully on a legacy field.json whose deliverable carries
# no dt_stage: the prior stage is unknown, so any valid target is accepted and
# the move is logged with from=null.
#
# Per-stage moves live in a dedicated stage log, NOT the execution log — the
# execution log records state transitions only (pending/in-progress/complete).
#
# Usage: bash dt-stage-advance.sh <engagement-dir> <field-slug> <deliverable-slug> <target-stage>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

ENGAGEMENT_DIR="${1:?Usage: bash dt-stage-advance.sh <engagement-dir> <field-slug> <deliverable-slug> <target-stage>}"
FIELD_SLUG="${2:?Usage: bash dt-stage-advance.sh <engagement-dir> <field-slug> <deliverable-slug> <target-stage>}"
DELIVERABLE_SLUG="${3:?Usage: bash dt-stage-advance.sh <engagement-dir> <field-slug> <deliverable-slug> <target-stage>}"
TARGET_STAGE="${4:?Usage: bash dt-stage-advance.sh <engagement-dir> <field-slug> <deliverable-slug> <target-stage>}"

ENGAGEMENT_DIR="$ENGAGEMENT_DIR" FIELD_SLUG="$FIELD_SLUG" \
DELIVERABLE_SLUG="$DELIVERABLE_SLUG" TARGET_STAGE="$TARGET_STAGE" python3 - <<'PY'
import json, os, datetime

STAGES = ["empathize", "define", "ideate", "prototype", "test"]

engagement_dir = os.environ["ENGAGEMENT_DIR"]
field_slug = os.environ["FIELD_SLUG"]
deliverable_slug = os.environ["DELIVERABLE_SLUG"]
target = os.environ["TARGET_STAGE"]


def fail(error, **data):
    print(json.dumps({"success": False, "data": data, "error": error}))
    raise SystemExit(0)


# 1. Target must be a valid stage name (rejects a misspelled or unknown stage).
if target not in STAGES:
    fail(f"invalid target stage '{target}' (expected one of: {', '.join(STAGES)})",
         target=target)

field_path = os.path.join(engagement_dir, "action-fields", field_slug, "field.json")

# 2. Read the field manifest (single source of truth for dt_stage).
try:
    with open(field_path) as f:
        field = json.load(f)
except FileNotFoundError:
    fail(f"field manifest not found: {field_path}", path=field_path)
except (json.JSONDecodeError, OSError) as exc:
    fail(f"unreadable field manifest: {field_path}: {exc}", path=field_path)

deliverables = field.get("deliverables")
if not isinstance(deliverables, list):
    fail(f"malformed field manifest: deliverables must be a list ({field_path})",
         path=field_path)

# 3. Locate the deliverable entry by slug.
entry = next((d for d in deliverables
             if isinstance(d, dict) and d.get("slug") == deliverable_slug), None)
if entry is None:
    fail(f"deliverable '{deliverable_slug}' not found in field '{field_slug}'",
         path=field_path, deliverable=deliverable_slug)

# 4. Validate the transition. A legacy entry with no dt_stage has an unknown
#    prior stage — accept any valid target and log from=null.
current = entry.get("dt_stage")
if current is not None and current not in STAGES:
    # An already-corrupt stored value: don't trust it for ordering. Treat as
    # unknown so the guarded write can repair it to a valid target.
    current = None

if current is None:
    pass  # graceful degradation: prior stage unknown, any valid target allowed
else:
    ci, ti = STAGES.index(current), STAGES.index(target)
    if ti > ci + 1:
        fail(f"illegal stage jump '{current}' -> '{target}': forward moves must "
             f"advance one stage at a time (skips a stage)",
             current=current, target=target)
    # ti == ci (idempotent re-set), ti == ci + 1 (single-step forward), and
    # ti < ci (re-entry to an earlier stage, loop iteration) are all permitted.

# 5. Apply via idempotent read-modify-write — preserve every other field.
entry["dt_stage"] = target
tmp_path = field_path + ".tmp"
with open(tmp_path, "w") as f:
    json.dump(field, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp_path, field_path)

# 6. Append the per-stage move to the dedicated stage log (create if absent).
meta_dir = os.path.join(engagement_dir, ".metadata")
os.makedirs(meta_dir, exist_ok=True)
stage_log_path = os.path.join(meta_dir, "stage-log.json")
try:
    with open(stage_log_path) as f:
        stage_log = json.load(f)
    if not isinstance(stage_log, dict) or not isinstance(stage_log.get("moves"), list):
        stage_log = {"moves": []}
except FileNotFoundError:
    stage_log = {"moves": []}
except (json.JSONDecodeError, OSError):
    stage_log = {"moves": []}

move = {
    "action_field": field_slug,
    "deliverable": deliverable_slug,
    "from": current,
    "to": target,
    "timestamp": datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "triggered_by": "consult-design-thinking",
}
stage_log["moves"].append(move)
with open(stage_log_path, "w") as f:
    json.dump(stage_log, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(json.dumps({
    "success": True,
    "data": {
        "action_field": field_slug,
        "deliverable": deliverable_slug,
        "from": current,
        "to": target,
        "path": field_path,
        "stage_log": stage_log_path,
    },
    "error": "",
}))
PY
