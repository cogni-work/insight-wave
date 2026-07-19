#!/usr/bin/env bash
# Create the cogni-projects portfolio directory skeleton + projects-portfolio.json.
# Idempotent: re-run is safe; projects-portfolio.json existence is the completion marker.
# Usage: bash portfolio-init.sh <portfolio-slug> <portfolio-name>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

SLUG="${1:?Usage: bash portfolio-init.sh <portfolio-slug> <portfolio-name>}"
NAME="${2:?Usage: bash portfolio-init.sh <portfolio-slug> <portfolio-name>}"

BASE_DIR="cogni-projects/${SLUG}"

# Idempotency keys on the manifest, not the bare directory, so an interrupted
# run (skeleton created, manifest never written) is repairable by re-running.
# A re-run returns {"success": false, ... "already initialized"} and exits 0 —
# a clean "nothing to do" signal, never an error state — and overwrites nothing.
if [ -f "$BASE_DIR/projects-portfolio.json" ]; then
  BASE_DIR="$BASE_DIR" python3 -c 'import json, os; print(json.dumps({"success": False, "data": {"path": os.environ["BASE_DIR"]}, "error": "portfolio already initialized (projects-portfolio.json exists)"}))'
  exit 0
fi

mkdir -p "$BASE_DIR"/{consultants,projects,assignments,.metadata}

SLUG="$SLUG" NAME="$NAME" BASE_DIR="$BASE_DIR" python3 - <<'PY'
import json, os, datetime, tempfile

base = os.environ["BASE_DIR"]
today = datetime.date.today().isoformat()


def _intended_mode(path):
    # The mode a plain open(path, "w") would leave: an existing target keeps its
    # own, a new one gets 0o666 masked by the umask. Reading the umask requires
    # setting it, so restore it at once — this script is single-threaded.
    try:
        return os.stat(path).st_mode & 0o777
    except OSError:
        cur = os.umask(0)
        os.umask(cur)
        return 0o666 & ~cur


def _atomic_write_json(path, data, ensure_ascii):
    # json.dump to a temp file in the target's own directory, then os.replace it
    # over the target — an atomic rename on the same filesystem. A bare
    # open(path, "w") truncates in place before json.dump streams, so a mid-write
    # failure would leave a half-written file; os.replace leaves either the old
    # file or the complete new one, never a truncation. Unlink the temp on
    # failure so no debris is left behind.
    #
    # The fchmod is load-bearing: mkstemp always creates at 0600 regardless of
    # umask and os.replace carries that onto the target, so without it every
    # seeded log and the manifest would tighten from the 0644 the pre-atomic
    # writer produced. Setting it on the temp fd means the file is never
    # visible at 0600.
    mode = _intended_mode(path)
    fd, tmp = tempfile.mkstemp(
        prefix="." + os.path.basename(path) + ".",
        suffix=".tmp",
        dir=os.path.dirname(path) or ".",
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=ensure_ascii)
            f.write("\n")
            os.fchmod(f.fileno(), mode)
        os.replace(tmp, path)
    except OSError:
        if os.path.exists(tmp):
            try:
                os.unlink(tmp)
            except OSError:
                pass
        raise


# Seed the metadata logs before the manifest so a completed init always carries
# the audit trail the later staffing/backfilling skills append to.
for log, payload in [
    ("execution-log.json", {"transitions": []}),
    ("staffing-log.json", {"matches": []}),
    ("decision-log.json", {"decisions": []}),
]:
    _atomic_write_json(os.path.join(base, ".metadata", log), payload, ensure_ascii=True)

# Root manifest written LAST: its existence marks a completed init (see the
# idempotency check above). Entity arrays start empty — later children
# (data model + entity-authoring, staffing match engine) populate them.
project = {
    "slug": os.environ["SLUG"],
    "name": os.environ["NAME"],
    "language": "en",
    "consultants": [],
    "projects": [],
    "assignments": [],
    "workflow_state": {"portfolio": "initialized"},
    "plugin_refs": {},
    "created": today,
    "updated": today,
}
_atomic_write_json(os.path.join(base, "projects-portfolio.json"), project, ensure_ascii=False)

print(json.dumps({"success": True, "data": {"path": base, "slug": project["slug"]}, "error": ""}))
PY
