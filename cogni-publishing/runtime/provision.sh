#!/usr/bin/env bash
# Provision the pinned design-render measurement runtime into this directory.
#
# Operator-run, once per machine: design-render.py, the skills and the test suites never run this.
# It installs exactly what package-lock.json pins — playwright-core with its sha512 integrity — then
# the Chrome Headless Shell build that playwright-core version pins, into browsers/ here, and records
# the interpreter it used in .provisioned.json. design-render resolves the runtime only from that
# record and re-verifies the interpreter version and the lockfile digest on every measurement, so a
# global node, npx or browser on PATH is never what runs.
#
# Needs node >= 20 and npm on PATH (or NODE=/path/to/node), and network access to the npm registry
# and the Playwright browser CDN. node_modules/, browsers/ and .provisioned.json are gitignored.
#
# Stdout carries exactly one JSON envelope — the provisioning record on success, a success:false
# envelope on failure. Install progress from npm and the browser download goes to stderr.
set -euo pipefail

fail() {  # fail <fixed message> — the message carries no quotes, so it needs no JSON escaping
  printf '{"success": false, "data": {}, "error": "provision: %s"}\n' "$1"
  exit 1
}

here="$(cd "$(dirname "$0")" && pwd)"
node_bin="${NODE:-$(command -v node || true)}"
[ -n "$node_bin" ] || fail "node >= 20 is required (set NODE=/path/to/node)"
node_bin="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$node_bin")"
npm_bin="$(dirname "$node_bin")/npm"
[ -x "$npm_bin" ] || npm_bin="$(command -v npm || true)"
[ -n "$npm_bin" ] || fail "npm is required beside node or on PATH"

cd "$here"
"$npm_bin" ci --ignore-scripts --no-audit --no-fund >&2 || fail "npm ci failed; see stderr"
PLAYWRIGHT_BROWSERS_PATH="$here/browsers" "$node_bin" node_modules/playwright-core/cli.js install --only-shell chromium >&2 \
  || fail "browser install failed; see stderr"

python3 - "$here" "$node_bin" "$("$node_bin" --version)" <<'PY'
import datetime, hashlib, json, sys
from pathlib import Path
here, node_bin, node_version = sys.argv[1:]
root = Path(here)
lock = root / "package-lock.json"
record = {
    "node_path": node_bin,
    "node_version": node_version,
    "lock_sha256": "sha256:" + hashlib.sha256(lock.read_bytes()).hexdigest(),
    "playwright_core": json.loads((root / "node_modules" / "playwright-core" / "package.json").read_text())["version"],
    "browsers": "browsers",
    "provisioned_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
(root / ".provisioned.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"success": True, "data": record, "error": None}))
PY
