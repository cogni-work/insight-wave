#!/usr/bin/env bash
# test_pdf_extract.sh — contract test for scripts/pdf-extract.py (#583).
#
# pypdf is an OPTIONAL dependency (it is NOT vendored). The CLI must:
#   1. return a `not_found` envelope for a missing path (deterministic, no pypdf);
#   2. resolve the workspace venv interpreter from COGNI_WORKSPACE_PYTHON_VENV
#      only when it is set AND its bin/python exists (the re-exec resolution);
#   3. map each extract_pdf_text reason to the standard {success,data,error}
#      envelope — including the pypdf_unavailable install hint.
#
# Tests 2 + 3 inject a FAKE extract_pdf_text / manipulate the env so the suite is
# host-independent (it never needs real pypdf installed). The script name has a
# hyphen, so it is loaded by path via importlib (the test_knowledge_lib.sh
# pattern). bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPTS_DIR/pdf-extract.py" ]; then
  red "FAIL: pdf-extract.py not found at $SCRIPTS_DIR/pdf-extract.py"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- Test 1: real subprocess, missing path → not_found (no pypdf needed) ------
NOT_FOUND_OUT=$(python3 "$SCRIPTS_DIR/pdf-extract.py" --path "$WORK/does-not-exist.pdf" || true)

OUT=$(python3 - "$SCRIPTS_DIR" "$WORK" "$NOT_FOUND_OUT" <<'PY'
import contextlib
import importlib.util
import io
import json
import os
import sys
from pathlib import Path

scripts = Path(sys.argv[1])
work = Path(sys.argv[2])
not_found_out = sys.argv[3]


def load(name, fname):
    spec = importlib.util.spec_from_file_location(name, scripts / fname)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def check(tag, fn):
    try:
        fn()
        print(f"{tag}: OK")
    except AssertionError as exc:
        print(f"{tag}: FAIL {exc}")


kl = load("_knowledge_lib", "_knowledge_lib.py")
pe = load("pdf_extract", "pdf-extract.py")


def _run_main(path, env_overrides=None):
    """Drive pe.main() with a given --path, capturing the JSON envelope + rc."""
    argv = sys.argv
    environ = dict(os.environ)
    try:
        sys.argv = ["pdf-extract.py", "--path", str(path)]
        # Clear venv + re-exec guard unless the case sets them.
        os.environ.pop("COGNI_WORKSPACE_PYTHON_VENV", None)
        os.environ.pop(pe._REEXEC_FLAG, None)
        for k, v in (env_overrides or {}).items():
            os.environ[k] = v
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = pe.main()
        return rc, json.loads(buf.getvalue())
    finally:
        sys.argv = argv
        os.environ.clear()
        os.environ.update(environ)


def assert_not_found_subprocess():
    # The real CLI invocation (Test 1) emitted a well-formed not_found envelope.
    env = json.loads(not_found_out)
    assert env["success"] is False, env
    assert env["data"]["reason"] == "not_found", env
    assert env["error"], "not_found must carry an error message"


def assert_venv_python_resolution():
    # Unset → None.
    os.environ.pop("COGNI_WORKSPACE_PYTHON_VENV", None)
    assert pe._venv_python() is None, "unset env must resolve to None"
    # Set but bin/python missing → None.
    empty = work / "venv-empty"
    (empty / "bin").mkdir(parents=True, exist_ok=True)
    os.environ["COGNI_WORKSPACE_PYTHON_VENV"] = str(empty)
    try:
        assert pe._venv_python() is None, "missing bin/python must resolve to None"
        # Set and bin/python present → returns that path.
        good = work / "venv-good"
        (good / "bin").mkdir(parents=True, exist_ok=True)
        (good / "bin" / "python").write_text("#!/bin/sh\n")
        os.environ["COGNI_WORKSPACE_PYTHON_VENV"] = str(good)
        assert pe._venv_python() == str(good / "bin" / "python"), pe._venv_python()
    finally:
        os.environ.pop("COGNI_WORKSPACE_PYTHON_VENV", None)


def assert_main_envelope_mapping():
    # main() checks is_file() before calling extract_pdf_text, so use a real
    # tempfile and FAKE extract_pdf_text — host-independent (no real pypdf).
    real = work / "input.bin"
    real.write_text("not really a pdf")
    R = kl.PdfExtractResult
    orig = pe.extract_pdf_text
    try:
        # ok → success:true, data carries text/pages/chars.
        pe.extract_pdf_text = lambda *a, **k: R("body text", 7, "ok")
        rc, env = _run_main(real)
        assert rc == 0 and env["success"] is True, env
        assert env["data"]["pages"] == 7 and env["data"]["chars"] == len("body text"), env
        assert env["data"]["text"] == "body text", env

        # no_text_layer → success:false, reason passed through.
        pe.extract_pdf_text = lambda *a, **k: R(None, 3, "no_text_layer", "image only")
        rc, env = _run_main(real)
        assert rc == 1 and env["success"] is False, env
        assert env["data"]["reason"] == "no_text_layer", env

        # extract_failed → success:false, reason passed through.
        pe.extract_pdf_text = lambda *a, **k: R(None, None, "extract_failed", "boom")
        rc, env = _run_main(real)
        assert rc == 1 and env["data"]["reason"] == "extract_failed", env

        # pypdf_unavailable (no venv configured) → install hint surfaced.
        pe.extract_pdf_text = lambda *a, **k: R(None, None, "pypdf_unavailable")
        rc, env = _run_main(real)
        assert rc == 1 and env["data"]["reason"] == "pypdf_unavailable", env
        assert "pip install pypdf" in env["error"], env
    finally:
        pe.extract_pdf_text = orig


check("not_found_subprocess", assert_not_found_subprocess)
check("venv_python_resolution", assert_venv_python_resolution)
check("main_envelope_mapping", assert_main_envelope_mapping)
PY
)

errors=0

grade() {
  local tag="$1" description="$2"
  local line
  line=$(printf '%s\n' "$OUT" | grep "^${tag}:" || true)
  case "$line" in
    "${tag}: OK")     green "PASS: $description" ;;
    "${tag}: FAIL "*) red   "FAIL: $description"; red "  ${line#${tag}: FAIL }"; errors=$((errors + 1)) ;;
    *)                red   "FAIL: $description (no result line for '$tag' — python subprocess crashed?)"
                      red   "  output: $OUT"; errors=$((errors + 1)) ;;
  esac
}

grade not_found_subprocess   "pdf-extract.py CLI — missing path returns success:false data.reason=not_found with an error (real subprocess, no pypdf needed)"
grade venv_python_resolution "_venv_python — COGNI_WORKSPACE_PYTHON_VENV unset→None, set-but-no-bin/python→None, set-with-bin/python→that path (workspace-venv re-exec resolution)"
grade main_envelope_mapping  "main() reason→envelope mapping — ok/no_text_layer/extract_failed/pypdf_unavailable, install hint on pypdf_unavailable (faked extract_pdf_text, host-independent)"

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All pdf-extract.py cases pass."
