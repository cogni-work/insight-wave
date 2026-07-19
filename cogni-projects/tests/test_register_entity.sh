#!/usr/bin/env bash
# Test register-entity.py's atomic manifest + execution-log writes.
#
# Covers the atomicity contract (a mid-write failure never truncates a live
# file, and leaves no temp debris), the failure envelope's nothing-written-vs-
# partial distinction, and the happy-path / idempotency guarantees.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
# The failure is simulated by monkeypatching os.replace to raise OSError —
# never `ulimit -f`, whose SIGXFSZ terminates the process before the handler
# runs and leaves the .tmp debris the contract forbids.
#
# Usage: bash cogni-projects/tests/test-register-entity.sh
# Exits non-zero on any assertion failure.

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SCRIPTS_DIR="$SCRIPTS_DIR" WORK="$WORK" python3 - <<'PY'
import contextlib
import importlib.util
import io
import json
import os
import shutil
import sys

SCRIPTS_DIR = os.environ["SCRIPTS_DIR"]
WORK = os.environ["WORK"]

# register-entity.py is not an importable module name (hyphen), so load it by
# file location — the same idiom the script itself uses for validate-entities.py.
_spec = importlib.util.spec_from_file_location(
    "register_entity", os.path.join(SCRIPTS_DIR, "register-entity.py")
)
reg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(reg)

failures = 0


def check(tag, cond, detail=""):
    global failures
    if cond:
        print("PASS: " + tag)
    else:
        failures += 1
        print("FAIL: " + tag + (" — " + detail if detail else ""))


def make_portfolio(name):
    root = os.path.join(WORK, name)
    os.makedirs(os.path.join(root, "consultants"))
    os.makedirs(os.path.join(root, ".metadata"))
    manifest = {
        "slug": "test", "name": "Test Portfolio", "language": "en",
        "consultants": [], "projects": [], "assignments": [],
        "workflow_state": {"portfolio": "initialized"},
        "created": "2026-01-01", "updated": "2026-01-01",
    }
    with open(os.path.join(root, "projects-portfolio.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return root


def make_consultant(root, slug, name):
    path = os.path.join(root, "consultants", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "---\n"
            "type: consultant\n"
            "slug: %s\n"
            "name: %s\n"
            "seniority: senior\n"
            "skills: [cloud, data]\n"
            "---\n\n# %s\n" % (slug, name, name)
        )
    return path


def register(root, entity_file):
    """Run register-entity.main and return (exit_code, parsed_envelope)."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = reg.main([root, entity_file])
    return code, json.loads(buf.getvalue().strip().splitlines()[-1])


def tmp_debris(root):
    seen = []
    for d in (root, os.path.join(root, ".metadata")):
        if os.path.isdir(d):
            seen += [f for f in os.listdir(d) if f.endswith(".tmp")]
    return seen


# --- Happy path: a fresh entity registers as "created" -----------------------
root = make_portfolio("happy")
ana = make_consultant(root, "ana-silva", "Ana Silva")
code, env = register(root, ana)
check("happy: success is True", env.get("success") is True, str(env))
check("happy: action is created", env.get("data", {}).get("action") == "created", str(env))
manifest = json.load(open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8"))
check("happy: consultants array length 1", len(manifest["consultants"]) == 1)
check("happy: no tmp debris on success", tmp_debris(root) == [], str(tmp_debris(root)))

# --- Idempotency: re-registering the same slug flips to "updated" ------------
code, env = register(root, ana)
check("idempotency: action flips to updated", env.get("data", {}).get("action") == "updated", str(env))
manifest = json.load(open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8"))
check("idempotency: array still length 1", len(manifest["consultants"]) == 1)

# --- European names round-trip without ASCII escaping ------------------------
bjoern = make_consultant(root, "bjoern-mueller", u"Björn Müller")
code, env = register(root, bjoern)
raw = open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8").read()
check("encoding: umlaut stored literally", u"Björn Müller" in raw, "not found in manifest")
check("encoding: no \\u escapes in manifest", "\\u" not in raw)

# --- Failure path: os.replace raises → nothing written, no corruption --------
root2 = make_portfolio("replace-fail")
carlos = make_consultant(root2, "carlos-diaz", "Carlos Diaz")
before = open(os.path.join(root2, "projects-portfolio.json"), "rb").read()

orig_replace = os.replace


def boom(src, dst):
    raise OSError(27, "File too large")


try:
    os.replace = boom
    code, env = register(root2, carlos)
finally:
    os.replace = orig_replace

check("replace-fail: success is False", env.get("success") is False, str(env))
check(
    "replace-fail: message says nothing written",
    "nothing was written" in env.get("error", ""),
    str(env),
)
after = open(os.path.join(root2, "projects-portfolio.json"), "rb").read()
check("replace-fail: manifest byte-identical", before == after)
check("replace-fail: no tmp debris", tmp_debris(root2) == [], str(tmp_debris(root2)))
# The pre-existing manifest is still parseable — the whole point of the fix.
try:
    json.load(open(os.path.join(root2, "projects-portfolio.json"), encoding="utf-8"))
    parseable = True
except ValueError:
    parseable = False
check("replace-fail: manifest still parses", parseable)

# --- Real OSError from the filesystem: .metadata is a file, not a dir --------
root3 = make_portfolio("notadir")
dana = make_consultant(root3, "dana-koch", "Dana Koch")
shutil.rmtree(os.path.join(root3, ".metadata"))
open(os.path.join(root3, ".metadata"), "w").close()  # now a regular file
before3 = open(os.path.join(root3, "projects-portfolio.json"), "rb").read()
code, env = register(root3, dana)
check("notadir: success is False", env.get("success") is False, str(env))
after3 = open(os.path.join(root3, "projects-portfolio.json"), "rb").read()
check("notadir: manifest intact", before3 == after3)
check("notadir: no tmp debris", tmp_debris(root3) == [], str(tmp_debris(root3)))

print()
if failures:
    print("%d check(s) failed." % failures)
    sys.exit(1)
print("All checks passed.")
PY