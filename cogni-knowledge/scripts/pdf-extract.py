#!/usr/bin/env python3
"""
pdf-extract.py — pure-Python PDF text-layer extraction CLI.

The poppler-less fallback surface for the source-curator's Phase-4 PDF branch:
when the Read tool cannot rasterize a saved PDF in this runtime, this CLI tries a
pure-Python text-layer extraction (via the optional pypdf dependency) before the
curator records the honest `pdf_render_unavailable` outcome.

Usage:
  python3 pdf-extract.py --path <file.pdf> [--min-chars 200]

pypdf resolution:
  1. the interpreter running this script (host `pip install pypdf`);
  2. if pypdf is not importable here and ``COGNI_WORKSPACE_PYTHON_VENV`` points to a
     venv whose ``bin/python`` exists, **re-exec this script under that interpreter**
     so pypdf runs with the venv's own clean ``sys.path``. (We re-exec rather than
     bolt the venv's site-packages onto the host path: pypdf optionally imports the
     compiled ``cryptography``, and mixing a venv's packages with the host's can
     raise a non-``Exception`` panic — the venv interpreter keeps it isolated.)

On success (the PDF has a text layer clearing the non-trivial-text gate):
  {"success": true, "data": {"text": "...", "pages": <n>, "chars": <n>}, "error": ""}

On failure, `data.reason` distinguishes the cases the curator branches on:
  - "pypdf_unavailable" — pypdf is not importable (host nor the workspace venv);
    `error` carries the install hint. Curator → fallback_attempted: false.
  - "no_text_layer"     — pypdf ran but the PDF is image-only / scanned (below the
    gate). Curator → fallback_attempted: true.
  - "extract_failed"    — pypdf ran but parsing raised. Curator → fallback_attempted: true.
  - "not_found"         — the path is not a file.

A `success: false` result is the caller's signal to fall through to
`pdf_render_unavailable`. Stdlib + the optional pypdf dependency only — pypdf is
not vendored; absence is never a hard error (see README §"Optional dependencies").
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import load_pypdf  # noqa: E402

# Guard env var: set on the re-exec'd child so it never re-execs again.
_REEXEC_FLAG = "COGNI_PDF_EXTRACT_VENV_REEXEC"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def _venv_python() -> str | None:
    """Return the workspace venv's python if configured and present, else None."""
    venv = os.environ.get("COGNI_WORKSPACE_PYTHON_VENV", "").strip()
    if not venv:
        return None
    candidate = Path(venv) / "bin" / "python"
    return str(candidate) if candidate.is_file() else None


def _reexec_in_venv(venv_python: str) -> int:
    """Re-run this script under the venv interpreter, passing stdout/exit through."""
    child_env = dict(os.environ, **{_REEXEC_FLAG: "1"})
    proc = subprocess.run(
        [venv_python, str(Path(__file__).resolve()), *sys.argv[1:]],
        capture_output=True,
        text=True,
        env=child_env,
    )
    # The child already emitted the JSON envelope on stdout; pass it through verbatim.
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    elif proc.returncode != 0:
        # Child crashed before emitting (should not happen — load_pypdf is fail-soft).
        return _emit(False, {"reason": "pypdf_unavailable"},
                     "pypdf workspace venv present but extraction failed to run")
    return proc.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract a PDF's text layer via the optional pypdf dependency.")
    parser.add_argument("--path", required=True, help="Path to the PDF file.")
    parser.add_argument(
        "--min-chars",
        type=int,
        default=200,
        help="Non-trivial-text gate: below this many extracted chars the PDF is "
        "treated as image-only (success: false). Default 200.",
    )
    args = parser.parse_args()

    pdf_path = Path(args.path)
    if not pdf_path.is_file():
        return _emit(False, {"reason": "not_found"}, f"PDF not found: {args.path}")

    pypdf = load_pypdf()
    if pypdf is None:
        # Not importable in this interpreter. If a workspace venv is configured and
        # we are not already the re-exec'd child, retry under the venv interpreter.
        if not os.environ.get(_REEXEC_FLAG):
            venv_python = _venv_python()
            if venv_python:
                return _reexec_in_venv(venv_python)
        return _emit(
            False,
            {"reason": "pypdf_unavailable"},
            "pypdf not available — run /cogni-workspace:manage-workspace, or pip install pypdf",
        )

    # Parse once: the same reader yields both the page count (for the envelope)
    # and the extracted text — no second PdfReader pass.
    try:
        reader = pypdf.PdfReader(str(pdf_path))
        pages = len(reader.pages)
        parts: list[str] = []
        for page in reader.pages:
            try:
                parts.append(page.extract_text() or "")
            except Exception:
                continue
        text = "\n".join(parts).strip()
    except Exception as exc:
        return _emit(False, {"reason": "extract_failed"}, f"pypdf parse failed: {exc}")

    if len(text) < args.min_chars:
        return _emit(
            False,
            {"reason": "no_text_layer"},
            "No usable text layer extracted (image-only / scanned PDF).",
        )

    return _emit(True, {"text": text, "pages": pages, "chars": len(text)}, "")


if __name__ == "__main__":
    sys.exit(main())
