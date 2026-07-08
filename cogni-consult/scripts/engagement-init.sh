#!/usr/bin/env bash
# Create the cogni-consult engagement directory skeleton + consult-project.json.
# Idempotent: re-run is safe; consult-project.json existence is the completion marker.
# Usage: bash engagement-init.sh <engagement-slug> <engagement-name>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

SLUG="${1:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"
NAME="${2:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"

BASE_DIR="cogni-consult/${SLUG}"

# Idempotency keys on the manifest, not the bare directory, so an interrupted
# run (skeleton created, manifest never written) is repairable by re-running.
if [ -f "$BASE_DIR/consult-project.json" ]; then
  BASE_DIR="$BASE_DIR" python3 -c 'import json, os; print(json.dumps({"success": False, "data": {"path": os.environ["BASE_DIR"]}, "error": "engagement already initialized (consult-project.json exists)"}))'
  exit 0
fi

mkdir -p "$BASE_DIR"/{scope,action-fields,personas,sources,.metadata}

# Seed the two default advisor personas at scaffold time so personas/ is never
# empty — an empty personas/ silently degrades the design-thinking Empathize and
# Test stages to consultant-direct fallback. Idempotent: the existence guard
# never overwrites an enriched file (the same guarantee consult-personas holds)
# and, unlike `cp -n`, keeps a skipped copy exit-0 under `set -e` on GNU
# coreutils >= 9.2, so the re-run repair path survives. These templates
# carry source:"setup-default", so they do NOT satisfy the personas_gate; that
# gate tracks scope-seeded personas (or a .gate-waiver marker) and is derived in
# engagement-status.sh. Templates are resolved relative to this script, not CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONA_TEMPLATES="$SCRIPT_DIR/../references/personas"
for advisor in consulting-partner project-manager; do
  if [ ! -f "$PERSONA_TEMPLATES/$advisor.json" ]; then
    ADVISOR="$advisor" python3 -c 'import json, os; print(json.dumps({"success": False, "data": {}, "error": "persona template missing: references/personas/%s.json (plugin packaging incomplete)" % os.environ["ADVISOR"]}))'
    exit 1
  fi
  [ -f "$BASE_DIR/personas/$advisor.json" ] \
    || cp "$PERSONA_TEMPLATES/$advisor.json" "$BASE_DIR/personas/$advisor.json"
done

SLUG="$SLUG" NAME="$NAME" BASE_DIR="$BASE_DIR" python3 - <<'PY'
import json, os, datetime

base = os.environ["BASE_DIR"]
today = datetime.date.today().isoformat()
project = {
    "slug": os.environ["SLUG"],
    "name": os.environ["NAME"],
    "language": "en",
    "key_question": "",
    "action_fields": [],
    "workflow_state": {"scope": "pending"},
    "plugin_refs": {},
    "created": today,
    "updated": today,
}

for log, payload in [
    ("execution-log.json", {"transitions": []}),
    ("method-log.json", {"methods": []}),
    ("decision-log.json", {"decisions": []}),
]:
    with open(os.path.join(base, ".metadata", log), "w") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")

# Source inbox: a documented, consultant-facing drop location for raw material
# (see references/data-model.md). Self-documenting via its own README so a
# consultant who never reads the reference still knows what it is for.
with open(os.path.join(base, "sources", "README.md"), "w") as f:
    f.write(
        "# Source inbox\n\n"
        "Drop raw material to ground a deliverable here — LOI text, architecture\n"
        "specs, working notes, interview transcripts, prior board/decision notes,\n"
        "or any first-party document the scoping conversation did not capture.\n\n"
        "The design-thinking loop's Empathize stage offers two ways to use what\n"
        "you drop here:\n\n"
        "- **Ingest into the bound knowledge base** so every deliverable's research\n"
        "  finds it (via `cogni-knowledge:knowledge-ingest-source`).\n"
        "- **Read directly into a single deliverable's `sources[]`** evidence base,\n"
        "  when the material is deliverable-local and should not enter the shared base.\n"
    )

# Assumption registry: single source of truth for {{asm:id}} values (see
# references/data-model.md). Seeded empty, before the manifest, so a completed
# init always carries the registry the render resolver reads.
with open(os.path.join(base, "assumptions.json"), "w") as f:
    json.dump({"assumptions": []}, f, indent=2)
    f.write("\n")

# Manifest written last: its existence marks a completed init (see the
# idempotency check above).
with open(os.path.join(base, "consult-project.json"), "w") as f:
    json.dump(project, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(json.dumps({"success": True, "data": {"path": base, "slug": project["slug"]}, "error": ""}))
PY

# Front door: write the engagement-root README as the final step, after
# consult-project.json, so a consultant opening the directory always finds a
# wayfinding page (the generator's graceful-degradation branch renders the
# scaffold-only state). The generator prints its own JSON envelope on both
# success and failure, so its stdout is captured — discarded on success (this
# script's stdout stays a single JSON line, stderr stays quiet) and replayed
# to stderr on failure so the {"success": false, "error": ...} diagnostic is
# visible right after the warning — the front door is a convenience, never a
# scaffold gate.
if ! GEN_OUT="$(python3 "$SCRIPT_DIR/generate-engagement-readme.py" "$BASE_DIR")"; then
  echo "warning: engagement README front door generation failed; scaffold is otherwise complete" >&2
  printf '%s\n' "$GEN_OUT" >&2
fi
