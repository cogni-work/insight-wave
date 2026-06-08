#!/usr/bin/env python3
"""
pdf-extract.py — pure-Python PDF text-layer extraction CLI.

The poppler-less fallback surface for the source-curator's Phase-4 PDF branch:
when the Read tool cannot rasterize a saved PDF in this runtime, this CLI tries a
pure-Python text-layer extraction (via the vendored pypdf) before the curator
records the honest `pdf_render_unavailable` outcome.

Usage:
  python3 pdf-extract.py --path <file.pdf> [--min-chars 200]

On success (the PDF has a text layer clearing the non-trivial-text gate):
  {"success": true, "data": {"text": "...", "pages": <n>, "chars": <n>}, "error": ""}

When the PDF is image-only / zero-text-layer (extraction below the gate), or on
any extraction failure:
  {"success": false, "data": {"reason": "no_text_layer" | "extract_failed" | "not_found"}, "error": "..."}

A `success: false` result is the caller's signal to fall through to
`pdf_render_unavailable`. Stdlib + the vendored pypdf only — no pip dependency.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import pdf_extract_text  # noqa: E402


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract a PDF's text layer via vendored pypdf.")
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

    text = pdf_extract_text(pdf_path, min_chars=args.min_chars)
    if text is None:
        # Distinguish "extractor ran, too little real text" from a hard failure
        # only as far as the caller needs: either way it falls through to
        # pdf_render_unavailable. pdf_extract_text already swallowed any parse
        # error, so a None here means "no usable text layer".
        return _emit(
            False,
            {"reason": "no_text_layer"},
            "No usable text layer extracted (image-only PDF or extraction failed).",
        )

    # Recover the page count cheaply from the vendored reader for the envelope.
    pages: int | None
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
        import pypdf  # type: ignore

        pages = len(pypdf.PdfReader(str(pdf_path)).pages)
    except Exception:
        pages = None

    return _emit(True, {"text": text, "pages": pages, "chars": len(text)}, "")


if __name__ == "__main__":
    sys.exit(main())
